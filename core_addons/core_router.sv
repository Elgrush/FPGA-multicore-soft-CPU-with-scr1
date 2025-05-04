`include "scr1_arch_description.svh"
`include "scr1_arch_types.svh"

module core_router #(
    parameter int NODE_ID = 0, NODE_COUNT = 9, SPLITTER_DEPTH = 8, COLLECTOR_DEPTH = 8, parameter int PACKET_ID_WIDTH = 5
) (
    //Basic
    input clk, rst_n,

    //Core integration
    input  logic                                lsu2dmem_req_i,             // Data memory request
    input  type_scr1_mem_cmd_e                  lsu2dmem_cmd_i,             // Data memory command (READ/WRITE)
    input  type_scr1_mem_width_e                lsu2dmem_width_i,           // Data memory data width
    input  logic [`SCR1_DMEM_AWIDTH-1:0]        lsu2dmem_addr_i,            // Data memory address
    input  logic [`SCR1_DMEM_DWIDTH-1:0]        lsu2dmem_wdata_i,           // Data memory write data
    output logic                                dmem2lsu_req_ack_o,         // Data memory request acknowledge
    output logic [`SCR1_DMEM_DWIDTH-1:0]        dmem2lsu_rdata_o,           // Data memory read data
    output type_scr1_mem_resp_e                 dmem2lsu_resp_o             // Data memory response

    //Network integration
    input logic [1 + 2*$clog2(NODE_COUNT) + 17 + PACKET_ID_WIDTH - 1 + 2 : 0] flitIn,
    output logic readFromNoc,

    output logic [1 + 2*$clog2(NODE_COUNT) + 17 + PACKET_ID_WIDTH - 1 + 2 : 0] flitOut,
    input logic writeToNoc

);

    //TODO
    splitter #(
            .NODE_ID(NODE_ID), .NODE_COUNT(NODE_COUNT), .QUEUE_DEPTH(SPLITTER_DEPTH), .PACKET_ID_WIDTH(PACKET_ID_WIDTH)
        ) spl (
            .clk(clk), .ce(1'b1), .rst_n(rst_n),
            .packet_in(packetOut),
            .node_dest(nodeDest),
            .valid_in(validControllerSplitter),
            .packet_id(packetId),
            .output_data(flitOut),
            .valid_out(), .ack(dmem2lsu_req_ack_o)
        );

        packet_collector #( 
            .NODE_COUNT(NODE_COUNT), .PACKET_ID_WIDTH(PACKET_ID_WIDTH), .BUFFER_SIZE(COLLECTOR_DEPTH)
        ) pc (
            .clk(clk), .rst_n(rst_n), .ce(1'b1),
            .input_data(flitIn),
            .valid_in(1'b1),

            .valid_out(validCollectorRam),
            .packet_out(packetIn),
            .node_start_out(nodeStart),
            .node_dest_out(),
            .packet_id_out(),
            .send_signal(readFromCollector)
        );
 

endmodule