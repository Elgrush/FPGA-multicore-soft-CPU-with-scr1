`include "noc_enable.svh"

module collector #(
    parameter int NODE_ID = 0, 
    X = 3, Y = 3) (
    input  logic                                    clk, rst_n, ce,
    input  logic [`NOC_FLIT_WIDTH - 1 : 0]          input_data,
    input  logic                                    valid_in,

    output logic                                    valid_out,
    output logic [`NOC_MAX_PAYLOAD - 1:0]           packet_out,
    output logic [$clog2(`NOC_NODE_COUNT) - 1:0]    node_start_out,
    output logic [$clog2(`NOC_NODE_COUNT) - 1:0]    node_dest_out,
    output logic [`NOC_PACKET_ID_WIDTH - 1:0]       packet_id_out,
    input  logic                                    send_signal     // I hereby proclaim this input as "dump it gate" by the decree of Terie The Terrible
);

    localparam FLIT_COUNT = `NOC_MAX_PAYLOAD / `NOC_FLIT_PAYLOAD + (`NOC_MAX_PAYLOAD % `NOC_FLIT_PAYLOAD != 0);
	 
    localparam FLIT_COUNT_MAX_WIDTH = $clog2(FLIT_COUNT);
	
    localparam NODE_W = $clog2(`NOC_NODE_COUNT);

    typedef struct  {
        logic [`NOC_FLIT_PAYLOAD - 1:0]              data [FLIT_COUNT-1 : 0];
        logic [FLIT_COUNT - 1:0]      received_mask;
        logic [31:0]                            timestamp;
        logic [NODE_W - 1:0]                    node_start;
        logic [NODE_W - 1:0]                    node_dest;
        logic [`NOC_PACKET_ID_WIDTH - 1:0]           packet_id;
        logic valid;
    } packet_entry_t;

    packet_entry_t buffer[`COLLECTOR_BUFFER_SIZE - 1 : 0];
    logic [31:0] global_time;

    // Распаковка флита
    wire valid_bit;
    wire [NODE_W-1:0]                          node_dest;
    wire [$clog2(FLIT_COUNT) - 1:0]            byte_index;
    wire [`NOC_FLIT_PAYLOAD-1:0]                    data_byte;
    wire [`NOC_PACKET_ID_WIDTH-1:0]                 packet_id;
    wire [NODE_W-1:0]                          node_start;

    // Tepacking flit
    assign {valid_bit, node_dest, data_byte, packet_id, node_start, byte_index} = input_data;

    integer i, j;
    logic [$clog2(`COLLECTOR_BUFFER_SIZE):0] match_index, replace_index;
    logic match_found, free_found;
    logic [2:0] min_count;
    logic [31:0] min_time;
	 
    wire [FLIT_COUNT - 1 : 0][`NOC_FLIT_PAYLOAD - 1 : 0]  packet_out_wire [`COLLECTOR_BUFFER_SIZE - 1 : 0];

	 generate
		  genvar gen_i, gen_j;
        for (gen_i = 0; gen_i < `COLLECTOR_BUFFER_SIZE; gen_i = gen_i + 1) begin : packet_out_wire_i
            for (gen_j = 0; gen_j < FLIT_COUNT; gen_j = gen_j + 1) begin : packet_out_wire_j
                assign packet_out_wire[gen_i][gen_j] = buffer[gen_i].data[gen_j];
            end
        end
     endgenerate


    always_ff @(posedge clk or negedge rst_n) begin
	 
			replace_index = 0;
			match_index = 0;
	 
        if (!rst_n) begin
            for (i = 0; i < `COLLECTOR_BUFFER_SIZE; i++) buffer[i].valid <= 0;
            global_time <= '0;
            valid_out <= '0;
        end else if (ce) begin
            valid_out <= 0;
            global_time <= global_time + 1;
            match_found = 0;
            free_found  = 0;

            if(!valid_out || send_signal) begin
                valid_out <= 0;
                for (i = 0; i < `COLLECTOR_BUFFER_SIZE; i++) begin
                    if (!valid_out && buffer[i].valid && (&buffer[i].received_mask))
                    begin
                        valid_out <= 1;
                        packet_out <= packet_out_wire[i];
                        node_start_out <= buffer[i].node_start;
                        node_dest_out  <= buffer[i].node_dest;
                        packet_id_out  <= packet_id;
                        for (j = 0; j < i; j = j + 1) begin
                            buffer[j].valid <= buffer[j].valid;
                        end
                        buffer[i].valid <= 0;
                    end
                end
            end
            
            if (valid_bit) begin
                for (i = 0; i < `COLLECTOR_BUFFER_SIZE; i++) begin
                    if (buffer[i].valid &&
                        buffer[i].node_start == node_start &&
                        buffer[i].packet_id == packet_id) begin
                        match_index = i;
                        match_found = 1;
                    end
                end
                if (match_found) begin
                    buffer[match_index].data[byte_index] <= data_byte;
                    buffer[match_index].received_mask[byte_index] <= 1'b1;
                    buffer[match_index].timestamp <= global_time;

                    
                end else begin
                    for (i = 0; i < `COLLECTOR_BUFFER_SIZE; i++) begin
                        if (!buffer[i].valid && !free_found) begin
                            replace_index = i;
                            free_found = 1;
                        end
                    end
                    if (!free_found) begin
                        min_count = 4;
                        min_time = 32'hFFFFFFFF;
                        for (i = 0; i < `COLLECTOR_BUFFER_SIZE; i++) begin
                            logic [FLIT_COUNT_MAX_WIDTH-1:0] count;
                            count = 0;
                            for (int b = 0; b < FLIT_COUNT; b++) begin
                                count += buffer[i].received_mask[b];
                            end
                            if (buffer[i].valid && count < min_count) begin
                                min_count = count;
                                min_time  = buffer[i].timestamp;
                                replace_index = i;
                            end else if (buffer[i].valid && count == min_count &&
                                        buffer[i].timestamp < min_time) begin
                                min_time = buffer[i].timestamp;
                                replace_index = i;
                            end
                        end
                    end

                    buffer[replace_index].valid           <= 1;
                    buffer[replace_index].received_mask   <= 0;
                    buffer[replace_index].data[byte_index]<= data_byte;
                    buffer[replace_index].received_mask[byte_index] <= 1;
                    buffer[replace_index].node_start      <= node_start;
                    buffer[replace_index].node_dest       <= node_dest;
                    buffer[replace_index].packet_id       <= packet_id;
                    buffer[replace_index].timestamp       <= global_time;
                end
            end
        end else begin
            valid_out <= 0;
        end
    end

endmodule