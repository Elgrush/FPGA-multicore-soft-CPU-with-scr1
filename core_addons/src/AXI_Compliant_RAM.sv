module AXI_Compliant_RAM
#(parameter RDATA_WIDTH=8, parameter RADDR_WIDTH=6)
(
	input clk,

	// AXI slave interface
    // Channel AR
	input  logic ar_addr_i,
	input  logic ar_valid_i,
	output logic ar_ready_o,

    // Channel R
    output logic r_data_o,
	output logic r_valid_o,
	input  logic r_ready_i,
	output logic r_last_o,
    output logic r_resp_o,

    // Channel AW
	input  logic aw_addr_i,
	input  logic aw_valid_i,
	output logic aw_ready_o

	// Channel W
	input  logic w_data_i,
	input  logic w_valid_i,
	output logic w_ready_o,
	input  logic w_last_i,

	// Channel B
	output logic b_rep_o,
	output logic b_val_o,
	input  logic b_ready_i

);

	// Объявление памяти
	logic [RDATA_WIDTH-1:0] ram[2**RADDR_WIDTH-1:0];
    logic [RADDR_WIDTH-1:0] ram_address_w, ram_address_r;
    logic [RDATA_WIDTH-1:0] ram_data_w, ran_data_r;
    logic [$clog2(RDATA_WIDTH)-1:0] record_counter_w, record_counter_r;

	enum {AXI_FSM_IDLE_W, AXI_FSM_ADDRESS_W, AXI_FSM_MEMORY_W, AXI_FSM_WRITE_RESPONSE_W} 
    axi_fsm_state_w, axi_fsm_state_w_next;

	enum {AXI_FSM_IDLE_R, AXI_FSM_ADDRESS_R, AXI_FSM_MEMORY_R} 
    axi_fsm_state_r, axi_fsm_state_r_next; 

    always_ff @( posedge clk or negedge rst_n ) begin : StateSwitchBlock
        if(!rst_n) begin
            axi_fsm_state_w <= AXI_FSM_IDLE_W;
        end else begin
            axi_fsm_state_w <= axi_fsm_state_w_next;
        end
    end : StateSwitchBlock

    always_ff @( posedge clk or negedge rst_n ) begin : NextStateBlock
        if(!rst_n) begin
            axi_fsm_state_w_next <= AXI_FSM_IDLE_W;
            b_val_o <= 1'b0;
        end else begin
            axi_fsm_state_w_next <= axi_fsm_state_w;
            case (axi_fsm_state_w)
                AXI_FSM_ADDRESS_W : 
                    if(ar_valid_i) begin
                        ram_address_w[record_counter_w] <= ar_addr_i;
                        record_counter_w <= record_counter_w + 1'b1;
                        if(record_counter_w + 1'b1 == RADDR_WIDTH) begin
                            record_counter_w <= '0;
                            axi_fsm_state_w_next <= AXI_FSM_MEMORY_W;
                        end
                    end
                AXI_FSM_MEMORY_W :
                    if(w_valid_i) begin
                        ram_data_w[record_counter_w] <= w_data_i;
                        record_counter_w <= record_counter_w + 1'b1;
                        if(record_counter_w + 1'b1 == RDATA_WIDTH) begin
                            record_counter_w <= '0;
                            ram[ram_address_w] <= ram_data_w;
                            if(w_last_i) begin
                                axi_fsm_state_w_next <= AXI_FSM_WRITE_RESPONSE_W;
                            end
                        end
                    end
                AXI_FSM_WRITE_RESPONSE_W :
                    if(b_ready_i) begin
                        // TODO read synrtacore type response
                    end
                default: // AKA IDLE state
                    ram_address_w[0] <= ar_addr_i;
                    record_counter_w <= 1'b1;
                    if(ar_valid_i) axi_fsm_state_w_next <= AXI_FSM_ADDRESS_W;
            endcase
        end
    end : NextStateBlock

    always_comb begin : FSMOutputBlock
        ar_ready_o = 1'b0;
        w_ready_o  = 1'b0;
        case (axi_fsm_state_w)
            AXI_FSM_MEMORY_W : w_ready_o = 1'b1;
            AXI_FSM_WRITE_RESPONSE_W: b_val_o = 1'b1;
            default: // AKA IDLE state with ADDRESS state
                ar_ready_o = 1'b1;
        endcase
    end : FSMOutputBlock

endmodule : AXI_Compliant_RAM
