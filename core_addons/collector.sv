`include "packet_type.svh"
`include "scr1_memif.svh"   //For data widths

module collector #( 
    parameter int NODE_COUNT = 8, PACKET_ID_WIDTH = 5,
    BUFFER_SIZE = 8, INPUT_WIDTH = 31,
    MAX_PAYLOAD = 32, FLIT_PAYLOAD = 8,
    BYTE = 8
    ) (
        
    input  logic                                clk, rst_n, ce,
    input  logic [INPUT_WIDTH - 1 : 0]          input_data,
    input  logic                                valid_in,

    output logic                                valid_out,
    output logic [MAX_PAYLOAD - 1:0]            packet_out,
    output logic [$clog2(NODE_COUNT) - 1:0]     node_start_out,
    output logic [$clog2(NODE_COUNT) - 1:0]     node_dest_out,
    output logic [PACKET_ID_WIDTH - 1:0]        packet_id_out,
    output type_packet_type                     packet_type_out,
    output type_scr1_mem_width_e                mem_width_out,
    input  logic                                send_signal
);

    localparam int NODE_W = $clog2(NODE_COUNT);

    localparam FLIT_COUNT_MAX_WIDTH = $clog2(MAX_PAYLOAD / FLIT_PAYLOAD + (MAX_PAYLOAD % FLIT_PAYLOAD != 0));
    logic [FLIT_COUNT_MAX_WIDTH - 1 : 0] FLIT_AMENDMENT;

    logic [FLIT_COUNT_MAX_WIDTH - 1 : 0] FLIT_COUNT_SINGLE      =    1;
    logic [FLIT_COUNT_MAX_WIDTH - 1 : 0] FLIT_COUNT_BYTE_1      =    MAX_PAYLOAD / BYTE     + (MAX_PAYLOAD % (BYTE    ) != 0);
    logic [FLIT_COUNT_MAX_WIDTH - 1 : 0] FLIT_COUNT_BYTE_2      =    MAX_PAYLOAD / BYTE * 2 + (MAX_PAYLOAD % (BYTE * 2) != 0);
    logic [FLIT_COUNT_MAX_WIDTH - 1 : 0] FLIT_COUNT_BYTE_4      =    MAX_PAYLOAD / BYTE * 4 + (MAX_PAYLOAD % (BYTE * 4) != 0);
    logic [FLIT_COUNT_MAX_WIDTH - 1 : 0] FLIT_COUNT_BYTE_5      =    MAX_PAYLOAD / BYTE * 5 + (MAX_PAYLOAD % (BYTE * 5) != 0);
    logic [FLIT_COUNT_MAX_WIDTH - 1 : 0] FLIT_COUNT_BYTE_6      =    MAX_PAYLOAD / BYTE * 6 + (MAX_PAYLOAD % (BYTE * 6) != 0);
    logic [FLIT_COUNT_MAX_WIDTH - 1 : 0] FLIT_COUNT_BYTE_8      =    MAX_PAYLOAD / BYTE * 8 + (MAX_PAYLOAD % (BYTE * 8) != 0);

    logic FLIT_COUNT_MAX = FLIT_COUNT_BYTE_8;

    //Computing flit count
    always_comb begin
        case (packet_type)
            DMEM_RESP_WRITTEN, DMEM_RESP_BAD, IMEM_RESP_BAD :   FLIT_AMENDMENT = FLIT_COUNT_SINGLE; // 0 bytes
            IMEM_REQ_READ, DMEM_REQ_READ, IMEM_RESP_DATA    :   FLIT_AMENDMENT = FLIT_COUNT_BYTE_4; // 4 byte address
            //Handling IMEM responses
            default : begin
                case (mem_width)
                    SCR1_MEM_WIDTH_BYTE                     :   FLIT_AMENDMENT = FLIT_COUNT_BYTE_5; // 4 byte address and 1 byte data
                    SCR1_MEM_WIDTH_HWORD                    :   FLIT_AMENDMENT = FLIT_COUNT_BYTE_6; // 4 byte address and 2 byte data
                    default:   // SCR1_MEM_WIDTH_WORD
                                                                FLIT_AMENDMENT = FLIT_COUNT_BYTE_8; // 4 byte address and 4 byte data
                endcase;
            end
        endcase
    end


    typedef struct  {
        logic [FLIT_PAYLOAD - 1:0]      data[FLIT_COUNT];
        logic [FLIT_COUNT_MAX - 1:0]        received_mask;
        logic [31:0]                    timestamp;
        logic [NODE_W - 1:0]            node_start;
        logic [NODE_W - 1:0]            node_dest;
        logic [PACKET_ID_WIDTH - 1:0]   packet_id;
        type_packet_type                packet_type;
        type_scr1_mem_width_e           mem_width;
        logic valid;
    } packet_entry_t;

    packet_entry_t buffer[BUFFER_SIZE];
    logic [31:0] global_time;

    // Распаковка флита
    wire valid_bit;
    wire [NODE_W-1:0]                          node_dest;
    wire [$clog2(FLIT_COUNT) - 1:0]            byte_index;
    wire [PAYLOAD-1:0]                         data_byte;
    wire [PACKET_ID_WIDTH-1:0]                 packet_id;
    wire [NODE_W-1:0]                          node_start;
    type_packet_type                           packet_type;
    type_scr1_mem_width_e                      mem_width;

    // Tepacking flit
    assign {valid_bit, node_dest, packet_type, mem_width, data_byte, packet_id, node_start, byte_index} = input_data;

    // TODO Count the amendment

    integer i, j;
    logic [$clog2(BUFFER_SIZE):0] match_index, replace_index;
    logic match_found, free_found;
    logic [2:0] min_count;
    logic [31:0] min_time;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < BUFFER_SIZE; i++) buffer[i].valid <= 0;
            global_time <= 0;
            valid_out <= 0;
        end else if (ce && valid_in) begin
            valid_out <= 0;
            global_time <= global_time + 1;
            match_found = 0;
            free_found  = 0;
         
            if (send_signal) begin
                for (i = 0; i < BUFFER_SIZE; i++) begin
                    if (&{!valid_out, buffer[i].valid, (&buffer[i].received_mask)})
                    begin
                        valid_out <= 1;
                        packet_out <= {buffer[i].data[0], buffer[i].data[1],
                                        buffer[i].data[2], buffer[i].data[3]};
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
                for (i = 0; i < BUFFER_SIZE; i++) begin
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
                    for (i = 0; i < BUFFER_SIZE; i++) begin
                        if (!buffer[i].valid && !free_found) begin
                            replace_index = i;
                            free_found = 1;
                        end
                    end
                    if (!free_found) begin
                        min_count = 4;
                        min_time = 32'hFFFFFFFF;
                        for (i = 0; i < BUFFER_SIZE; i++) begin
                            logic [2:0] count;
                            count = 0;
                            for (int b = 0; b < 4; b++) begin
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