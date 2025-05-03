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
    input[0:`PL-1] inputs[0:`REN-1], output[0:`PL-1] outputs[0:`REN-1],
    input signals_in[0:`REN-1], output signals_out[0:`REN-1],
    input[`CS-1:0] router_X, input[`CS-1:0] router_Y

);

//TODO
    
endmodule