`include "scr1_arch_description.svh"
`include "memory.svh"

module imem_controler
#(parameter TDATA_WIDTH=`NOC_MAX_PAYLOAD + $clog2(`NOC_NODE_COUNT) + `NOC_FLIT_WIDTH)
(
    input clk, rst_n,

    // RAM access
    output logic                                     mem_we_o,
	output logic [(RDATA_WIDTH-1):0]                 mem_data_o,
	output logic [(RADDR_WIDTH-1):0]                 mem_addr_o,
	input  logic [(RDATA_WIDTH-1):0]                 mem_data_i,

	// Instruction Memory Interface
    output   logic                                   imem2core_req_ack_0,        // IMEM request acknowledge
    input    logic                                   core2imem_req_i,            // IMEM request
    input    type_scr1_mem_cmd_e                     core2imem_cmd_i,            // IMEM command
    input    logic [`SCR1_IMEM_AWIDTH-1:0]           core2imem_addr_i,           // IMEM address
    output   logic [`SCR1_IMEM_DWIDTH-1:0]           imem2core_rdata_o,          // IMEM read data
    output   type_scr1_mem_resp_e                    imem2core_resp_o            // IMEM response

    // AXI stream Interface
    input    logic                                   TVALID_i,
    output   logic                                   TVALID_o,

    input    logic                                   TREADY_i,
    output   logic                                   TREADY_o,

    input    logic [`TDATA_WIDTH-1:0]                TDATA_i,
    output   logic [`TDATA_WIDTH-1:0]                TDATA_o,
     
    input    logic [`TDATA_WIDTH/8-1:0]              TDATA_WIDTH_i,
    output   logic [`TDATA_WIDTH/8-1:0]              TDATA_WIDTH_o,

    input    logic [`TDATA_WIDTH/8-1:0]              TSTRB_i,
    output   logic [`TDATA_WIDTH/8-1:0]              TSTRB_o,

);

    always_ff @( posedge clk or negedge rst_n ) begin: AXIBlock
        if(!rst_n) begin
            TVALID_o      <= '0;
            TREADY_o      <= '0;
            TDATA_o       <= '0;
            TDATA_WIDTH_o <= '0;
            TSTRB_o       <= '0;
        end else begin
            //TODO
        end
    end

    always_ff @( posedge clk or negedge rst_n ) begin: RamBlock
        if(!rst_n) begin
            mem_we_o      <= '0;
            mem_data_o    <= '0;
            mem_addr_o    <= '0;
        end else begin
            //TODO
        end
    end


endmodule : imem_controler
