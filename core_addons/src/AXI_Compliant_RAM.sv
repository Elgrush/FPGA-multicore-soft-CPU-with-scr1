module AXI_Compliant_RAM
#(parameter RDATA_WIDTH=8, parameter RADDR_WIDTH=6)
(
	input clk,

	// AXI slave interface
    // Channel AR
	input  ar_addr_i,
	input  ar_valid_i,
	output ar_ready_o,

    // Channel R
    output r_data_o,
	output r_valid_o,
	input  r_ready_i,
	output r_last_o,
    output r_resp_o,

    // Channel AW
	input  aw_addr_i,
	input  aw_valid_i,
	output aw_ready_o

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

	// Объявление памяти
	logic [RDATA_WIDTH-1:0] ram[2**RADDR_WIDTH-1:0];
    logic [RADDR_WIDTH-1:0] ram_address_w, ram_address_r;
    logic [RDATA_WIDTH-1:0] ram_data_w, ran_data_r;
    logic [$clog2(RDATA_WIDTH)-1:0] record_counter_w, record_counter_r;

	enum {AXI_FSM_IDLE, AXI_FSM_ADDRESS, AXI_FSM_MEMORY, AXI_FSM_WRITE_RESPONCE} 
    axi_fsm_state_w, axi_fsm_state_w_next;

	enum {AXI_FSM_IDLE, AXI_FSM_ADDRESS, AXI_FSM_MEMORY} 
    axi_fsm_state_r, axi_fsm_state_r_next; 

    always_ff @( posedge clk or negedge rst_n ) begin : StateSwitchBlock
        if(!rst_n) begin
            axi_fsm_state_w <= AXI_FSM_IDLE;
        end else begin
            axi_fsm_state_w <= axi_fsm_state_w_next;
        end
    end : StateSwitchBlock

    always_ff @( posedge clk or negedge rst_n ) begin : NextStateBlock
        if(!rst_n) begin
            axi_fsm_state_w_next <= AXI_FSM_IDLE;
        end else begin
            axi_fsm_state_w_next <= axi_fsm_state_w;
            case (axi_fsm_state_w)
                AXI_FSM_ADDRESS : 
                    if(ar_valid_i) begin
                        ram_address_w[record_counter_w] <= ar_addr_i;
                        record_counter_w <= record_counter_w + 1'b1;
                        if(record_counter_w + 1'b1 == RADDR_WIDTH) begin
                            record_counter_w <= '0;
                            axi_fsm_state_w_next <= AXI_FSM_MEMORY;
                        end
                    end
                AXI_FSM_MEMORY :
                    if(w_valid_i) begin
                        ram_data_w[record_counter_w] <= w_data_i;
                        record_counter_w <= record_counter_w + 1'b1;
                        if(record_counter_w + 1'b1 == RDATA_WIDTH) begin
                            record_counter_w <= '0;
                            ram[ram_address_w] <= ram_data_w;
                            if(w_last_i) begin
                                axi_fsm_state_w_next <= AXI_FSM_WRITE_RESPONCE;
                            end
                        end
                    end
                AXI_FSM_WRITE_RESPONCE : // TODO write
                default: // AKA IDLE state
                    ram_address_w[0] <= ar_addr_i;
                    record_counter_w <= 1'b1;
                    if(ar_valid_i) axi_fsm_state_w_next <= AXI_FSM_ADDRESS;
            endcase
        end
    end : NextStateBlock

    always_comb begin : FSMOutputBlock
        ar_ready_o = 1'b0;
        w_ready_o  = 1'b0;
        b_val_o    = 1'b0;
        case (axi_fsm_state_w)
            AXI_FSM_MEMORY : w_ready_o = 1'b1;
            AXI_FSM_WRITE_RESPONCE: b_val_o = 1'b1;
            default: // AKA IDLE state with ADDRESS state
                ar_ready_o = 1'b1;
        endcase
    end : FSMOutputBlock

endmodule : AXI_Compliant_RAM
