`include "noc_enable.svh"
`include "../mesh_3x3/inc/noc_XY.svh"

module splitter #(
    parameter int NODE_ID = 0, 
    X = 3, Y = 3) (

    input  logic                                    clk, ce, rst_n,
    input  logic [`NOC_MAX_PAYLOAD - 1 : 0]         packet_in,
    input  logic [$clog2(`NOC_NODE_COUNT) - 1 : 0]  node_dest,
    input  logic                                    valid_in,
    input  logic [`NOC_PACKET_ID_WIDTH - 1 : 0]     packet_id,
    input  logic                                    network_ready,

    output logic [`NOC_FLIT_WIDTH - 1 : 0]          output_data,
    output logic                                    valid_out,
    output logic                                    splitter_ready
);

    localparam FLIT_COUNT = `NOC_MAX_PAYLOAD / `NOC_FLIT_PAYLOAD + (`NOC_MAX_PAYLOAD % `NOC_FLIT_PAYLOAD != 0);
	 
    localparam FLIT_COUNT_MAX_WIDTH = $clog2(FLIT_COUNT);

    logic [2*$clog2(`NOC_NODE_COUNT) - 1:0] NOC_ADDRESSES[`NOC_NODE_COUNT-1:0];

    struct packed{ 
        logic [$clog2(`NOC_NODE_COUNT) - 1 : 0] node_queue;
        logic [`NOC_PACKET_ID_WIDTH - 1 : 0]    id_queue;
    }   queue [0 : `SPLITTER_QUEUE_DEPTH - 1];

    logic [`NOC_MAX_PAYLOAD - 1 : 0] packet_queue [0 : `SPLITTER_QUEUE_DEPTH - 1];

    logic [FLIT_COUNT_MAX_WIDTH - 1 : 0] byte_counter;
    logic [$clog2(`SPLITTER_QUEUE_DEPTH) - 1 : 0] head, tail; 
    logic [$clog2(`SPLITTER_QUEUE_DEPTH) : 0] count; 
    logic [$clog2(`NOC_NODE_COUNT) - 1 : 0] node_in;
    assign node_in = NODE_ID[$clog2(`NOC_NODE_COUNT) - 1 : 0];
    int i;

    generate
        genvar gen_i;
        for (gen_i = 0; gen_i < `NOC_NODE_COUNT; gen_i = gen_i + 1) begin : address_array_gen
				wire [$clog2(`X)-1: 0] c1;
				wire [$clog2(`X)-1: 0] c2;
				if(gen_i == 0) begin
					assign c1 = '0;
					assign c2 = '0;
				end else begin
					assign c1 = gen_i%`X;
					assign c2 = gen_i/`X;
				end

            assign NOC_ADDRESSES[gen_i] = {c1, c2};
        end
    endgenerate

    assign node_dest_encoded = NOC_ADDRESSES[node_dest];
	
	assign splitter_ready = count != `SPLITTER_QUEUE_DEPTH;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head <= '0;
            tail <= '0;
            count <= '0;
            byte_counter <= '0;
            valid_out <= '0;
            output_data <= '0;
        end else if (ce) begin
            if (valid_in && count < `SPLITTER_QUEUE_DEPTH) begin
                packet_queue[tail] <= packet_in;
                queue[tail]        <= {node_dest_encoded, packet_id};
                tail <= (tail + 1) % `SPLITTER_QUEUE_DEPTH;
                count <= count + 1;
            end

            if (count > 0 & network_ready) begin
                output_data <= {1'b1, queue[head].node_queue, {`NOC_FLIT_PAYLOAD{1'b0}}, queue[head].id_queue, node_in, byte_counter};
                for(i=0; i < `NOC_FLIT_PAYLOAD; i = i + 1)
                    output_data[FLIT_COUNT_MAX_WIDTH + $clog2(`NOC_NODE_COUNT) + `NOC_PACKET_ID_WIDTH + i] 
                    <= packet_queue[head][byte_counter*`NOC_FLIT_PAYLOAD+i];
                
                // In and out simultaneously
                if(byte_counter == FLIT_COUNT - 1) begin
                    head  <= (head == `SPLITTER_QUEUE_DEPTH - 1) ? 0 : head + 1;
                    count <= count -  !(valid_in && count < `SPLITTER_QUEUE_DEPTH);
                end

                valid_out <= 1;
                byte_counter <= (byte_counter == FLIT_COUNT - 1) ? 0 : byte_counter + 1;
            end else if (!network_ready) begin // TODO Decoding should happen actualy
            valid_out <= 1;
			end else begin
                valid_out <= 0;
                output_data <= 0;
            end
        end
    end

endmodule
