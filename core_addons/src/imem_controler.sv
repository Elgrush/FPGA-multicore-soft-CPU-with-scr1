`include "scr1_arch_description.svh"
`include "memory.svh"
`include "AXI.svh"

module imem_controler #(parameter NODE_ID = 0)(
    input clk, rst_n,

    // RAM access
    output logic                                     mem_we_o,
	output logic [(`RDATA_WIDTH-1):0]                mem_data_o,
	output logic [(`RADDR_WIDTH-1):0]                mem_addr_o,
	input  logic [(`RDATA_WIDTH-1):0]                mem_data_i,

	// Instruction Memory Interface
    output   logic                                   imem2core_req_ack_o,        // IMEM request acknowledge
    input    logic                                   core2imem_req_i,            // IMEM request
    input    type_scr1_mem_cmd_e                     core2imem_cmd_i,            // IMEM command
    input    logic [`SCR1_IMEM_AWIDTH-1:0]           core2imem_addr_i,           // IMEM address
    output   logic [`SCR1_IMEM_DWIDTH-1:0]           imem2core_rdata_o,          // IMEM read data
    output   type_scr1_mem_resp_e                    imem2core_resp_o            // IMEM response

    // AXI stream Interface
    input    logic                                   tValid_i,
    output   logic                                   tValid_o,

    input    logic                                   tReady_i,
    output   logic                                   tReady_o,

    input    TPACKAGE                                tPackage_i,
    output   TPACKAGE                                TPACKAGE_o,

);

	enum {AXI_FSM_IDLE, AXI_FSM_ADDRESS, AXI_FSM_MEMORY, AXI_FSM_WRITE_RESPONCE} axi_fsm_state, axi_fsm_state_next;

    always_ff @( posedge clk or negedge rst_n ) begin : StateSwitchBlock
        if(!rst_n) begin
            axi_fsm_state <= AXI_FSM_IDLE;
        end else begin
            axi_fsm_state <= axi_fsm_state_next;
        end
    end : StateSwitchBlock

    always_ff @( posedge clk or negedge rst_n ) begin : NextStateBlock
        if(!rst_n) begin
            axi_fsm_state_next <= AXI_FSM_IDLE;
        end else begin
            axi_fsm_state_next <= axi_fsm_state;
            case (axi_fsm_state)
                : 
                default: 
            endcase
        end
    end : NextStateBlock

endmodule : imem_controler
