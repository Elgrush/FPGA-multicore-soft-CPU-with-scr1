`ifndef CORE_PERIFERY_TOP
`define CORE_PERIFERY_TOP

`include "scr1_arch_description.svh"
`include "scr1_memif.svh"
`include "noc_enable.svh"
`include "noc.svh"
`include "noc_XY.svh"
`include "queue.svh"
`include "router.svh"

module core_perifery_top #(
    parameter int NODE_ID = 0, 
    X = 3, Y = 3) (
    input   logic                                   rst_n,                  // Regular Reset signal
    input   logic                                   clk,                    // System clock

`ifdef NOC_ENABLE
    // Collector
    input  logic [`NOC_FLIT_WIDTH - 1 : 0]          input_data,

    // Splitter

    output logic [`NOC_FLIT_WIDTH - 1 : 0]          output_data,
    input  logic                                    network_ready,

`endif // NOC_ENABLE

	// Instruction Memory Interface
    input   logic                                   imem2core_req_ack_i,        // IMEM request acknowledge
    output  logic                                   core2imem_req_o,            // IMEM request
    output  type_scr1_mem_cmd_e                     core2imem_cmd_o,            // IMEM command
    output  logic [`SCR1_IMEM_AWIDTH-1:0]           core2imem_addr_o,           // IMEM address
    input   logic [`SCR1_IMEM_DWIDTH-1:0]           imem2core_rdata_i,          // IMEM read data
    input   type_scr1_mem_resp_e                    imem2core_resp_i,           // IMEM response

    // Data Memory Interface
    input   logic                                   dmem2core_req_ack_i,        // DMEM request acknowledge
    output  logic                                   core2dmem_req_o,            // DMEM request
    output  type_scr1_mem_cmd_e                     core2dmem_cmd_o,            // DMEM command
    output  type_scr1_mem_width_e                   core2dmem_width_o,          // DMEM data width
    output  logic [`SCR1_DMEM_AWIDTH-1:0]           core2dmem_addr_o,           // DMEM address
    output  logic [`SCR1_DMEM_DWIDTH-1:0]           core2dmem_wdata_o,          // DMEM write data
    input   logic [`SCR1_DMEM_DWIDTH-1:0]           dmem2core_rdata_i,          // DMEM read data
    input   type_scr1_mem_resp_e                    dmem2core_resp_i            // DMEM response
	 
);

  // Collector
  logic COL2ALU_valid;
  logic [`NOC_MAX_PAYLOAD - 1:0]                    COL2ALU_packet;
  logic ALU2COL_send_signal;

  // Splitter
  logic [`NOC_MAX_PAYLOAD - 1:0]                    ALU2SPL_packet;
  logic [$clog2(`NOC_NODE_COUNT) - 1 : 0]           ALU2SPL_node_dest;
  logic                                             ALU2SPL_valid;
  logic [`NOC_PACKET_ID_WIDTH - 1 : 0]              ALU2SPL_packet_id;
  logic                                             SPL2ALU_ready;

  scr1_core_top core (
    // Control
    .pwrup_rst_n(rst_n),            // Power-Up Reset
    .rst_n(rst_n),                  // Regular Reset signal
    .cpu_rst_n(rst_n),              // CPU Reset (Core Reset)
    .test_mode(1'b0),               // Test mode
    .test_rst_n(rst_n),             // Test mode's reset
    .clk(clk),                      // System clock

`ifdef NOC_ENABLE
    // Collector
    .COL2ALU_valid_i(COL2ALU_valid),
    .COL2ALU_packet_i(COL2ALU_packet),
    .ALU2COL_send_signal_o(ALU2COL_send_signal),

    // Splitter
    .ALU2SPL_packet_o(ALU2SPL_packet),
    .ALU2SPL_node_dest_o(ALU2SPL_node_dest),
    .ALU2SPL_valid_o(ALU2SPL_valid),
    .ALU2SPL_packet_id_o(ALU2SPL_packet_id),
    .SPL2ALU_ready_i(SPL2ALU_ready),

`endif // NOC_ENABLE

    // Instruction Memory Interface
    .imem2core_req_ack_i(imem2core_req_ack_i),
    .core2imem_req_o(core2imem_req_o),
    .core2imem_cmd_o(core2imem_cmd_o),
    .core2imem_addr_o(core2imem_addr_o),
    .imem2core_rdata_i(imem2core_rdata_i),
    .imem2core_resp_i(imem2core_resp_i),

    // Data Memory Interface
    .dmem2core_req_ack_i(dmem2core_req_ack_i),
    .core2dmem_req_o(core2dmem_req_o),
    .core2dmem_cmd_o(core2dmem_cmd_o),
    .core2dmem_width_o(core2dmem_width_o),
    .core2dmem_addr_o(core2dmem_addr_o),
    .core2dmem_wdata_o(core2dmem_wdata_o),
    .dmem2core_rdata_i(dmem2core_rdata_i),
    .dmem2core_resp_i(dmem2core_resp_i)

  );

collector #(
    .NODE_ID(NODE_ID), 
    .X(X), .Y(Y)) col  (
    .ce(1'b1),
    .clk(clk), .rst_n(rst_n),
    .input_data(input_data),
    .valid_in(input_data[0]),
    .valid_out(COL2ALU_valid),
    .packet_out(COL2ALU_packet),
    .send_signal(ALU2COL_send_signal)
);

splitter #(
    .NODE_ID(NODE_ID), 
    .X(X), .Y(Y)) spl  (
    .ce(1'b1),
    .clk(clk), .rst_n(rst_n),
    
    .packet_in(ALU2SPL_packet),
    .node_dest(ALU2SPL_node_dest),
    .valid_in(ALU2SPL_valid),
    .packet_id(ALU2SPL_packet_id),
	  .network_ready(network_ready),

    .output_data(output_data),
    .splitter_ready(SPL2ALU_ready)
);

endmodule

`endif //CORE_PERIFERY_TOP
