`include "noc_enable.svh"
`include "../mesh_3x3/inc/noc_XY.svh"
`include "splitter.sv"

module splitter_tb;
    logic                                    clk, ce, rst_n = '0;
    logic [`NOC_MAX_PAYLOAD - 1 : 0]         packet_in = '0;
    logic [$clog2(`NOC_NODE_COUNT) - 1 : 0]  node_dest = '0;
    logic                                    valid_in;
    logic [`NOC_PACKET_ID_WIDTH - 1 : 0]     packet_id = '0;
	logic 								    network_ready = '0;

    logic [`NOC_FLIT_WIDTH - 1 : 0]          output_data = '0;
    logic                                    valid_out = '0;
    logic 								    splitter_ready = '0;

    assign valid_in = packet_in[`NOC_MAX_PAYLOAD - 1];

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        node_dest = 4;
        network_ready = 1'b1;
        ce = 1'b1;
        rst_n = 1'b0;
        
        #10
        rst_n = 1'b1;
    end

    initial begin
        packet_id = '0;

        forever #5 packet_id++;
    end
	
	initial begin
        packet_in = '0;
		packet_in[`NOC_MAX_PAYLOAD - 1] = 1'b1;
		

        forever #5 packet_in++;
    end
	
	initial begin
		#1000 $stop;
	end


    splitter spl(
    clk, ce, rst_n,
    packet_in,
    node_dest,
    valid_in,
    packet_id,
	network_ready,

    output_data,
    valid_out,
    splitter_ready
    );


endmodule

