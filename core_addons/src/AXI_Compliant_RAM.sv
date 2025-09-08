module AXI_Compliant_RAM
#(parameter RDATA_WIDTH=8, parameter RADDR_WIDTH=6)
(
	input clk,

	// AXI slave interface
    // Channel AR
	input  ar_addr_i,
	input  ar_valid_i,
	output ar_ready_o,

	// Channel W
	input  w_data_i,
	input  w_valid_i,
	output w_ready_o,
	input  w_last_i,

	// Channel B
	output b_rep_o,
	output b_val_o,
	input  b_ready_i

);

	// Jбъявление памяти
	logic [RDATA_WIDTH-1:0] ram[2**RADDR_WIDTH-1:0];

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

endmodule : AXI_Compliant_RAM
