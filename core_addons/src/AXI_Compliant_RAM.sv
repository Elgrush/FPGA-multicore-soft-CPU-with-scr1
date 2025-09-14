module AXI_Compliant_RAM
#(parameter RDATA_WIDTH=8, parameter RADDR_WIDTH=6, parameter CONTROL_WIDTH=2)
(
	input clk, rst_n,

    axi_if.s

);

	// Объявление памяти
	logic [RDATA_WIDTH-1:0] ram[2**RADDR_WIDTH-1:0];

    logic [RADDR_WIDTH + CONTROL_WIDTH - 1:0] ar_buffer, aw_buffer;
    logic [$clog2(RADDR_WIDTH + CONTROL_WIDTH)-1:0] aw_counter, ar_counter;

    localparam[$clog2(RADDR_WIDTH + CONTROL_WIDTH)-1:0] ADDRESS_COUNTER_FULL_VALUE = RADDR_WIDTH+CONTROL_WIDTH-1;

    logic [RDATA_WIDTH - 1:0] r_buffer, w_buffer;
    logic [$clog2(RDATA_WIDTH) - 1:0] r_counter, w_counter;

    logic w_last;

    localparam[$clog2(RDATA_WIDTH)-1:0] DATA_COUNTER_FULL_VALUE = RDATA_WIDTH-1;

    enum { INPUTTING, FULL } ar_state, ar_state_next;
    enum { INPUTTING, FULL } aw_state, aw_state_next;

    enum { INPUTTING, FULL } r_state, r_state_next;
    enum { INPUTTING, FULL } w_state, w_state_next;

    enum { INPUTTING, FULL } b_state, b_state_next;

    always_ff @( posedge clk or negedge rst_n ) begin : StateSwitchBlock
        if(!rst_n) begin            
            ar_state <= INPUTTING;
            ar_state_next <= INPUTTING;
 
            aw_state <= INPUTTING;
            aw_state_next <= INPUTTING;
 
            r_state <= INPUTTING;
            r_state_next <= INPUTTING;

            w_state <= INPUTTING;
            w_state_next <= INPUTTING;

            b_state <= INPUTTING;
            b_state_next <= INPUTTING;
        end else begin
            ar_state <= ar_state_next;
            aw_state <= aw_state_next;
            r_state <= r_state_next;
            w_state <= w_state_next;
            b_state <= b_state_next;
        end
    end : StateSwitchBlock

    always_comb begin : FSMOutputBlock
        case (aw_state)
            FULL:
                aw_ready_o = 1'b0;
            default:
                aw_ready_o = 1'b1;
        endcase : aw_state

        case (w_state)
            FULL:
                w_ready_o = 1'b0;
            default:
                w_ready_o = 1'b1;
        endcase : w_state

        case (b_state)
            FULL:
                b_ready_o = 1'b0;
            default:
                b_ready_o = 1'b1;
        endcase : b_state

        case (ar_state)
            FULL:
                ar_ready_o = 1'b0;
            default:
                ar_ready_o = 1'b1;
        endcase : ar_state

        case (r_state)
            FULL:
                r_ready_o = 1'b0;
            default:
                r_ready_o = 1'b1;
        endcase : r_state
    end : FSMOutputBlock

    always_ff @( posedge clk or negedge rst_n ) begin : LogicBlock
        if(!rst_n) begin            
            ar_buffer  <= '0;
            ar_counter <= '0;

            aw_state   <= '0;
            aw_counter <= '0;
            
            r_state    <= '0;
            r_counter  <= '0;
            
            w_state    <= '0;
            w_counter  <= '0;
            w_last     <= '0;
            
            b_state    <= '0;
            b_counter  <= '0;
        end else begin
            case (aw_state)
                INPUTTING:
                    if(aw_valid_i) begin
                        aw_buffer[aw_counter] <= aw_addr_i;
                        aw_counter <= aw_counter + 1'b1;
                        if(aw_counter == ADDRESS_COUNTER_FULL_VALUE) begin
                            aw_state_next <= FULL;
                            aw_counter <= '0;
                        end
                    end
                default: // FULL
            endcase : aw_state

            case (ar_state)
                INPUTTING:
                    if(ar_valid_i) begin
                        ar_buffer[ar_counter] <= ar_addr_i;
                        ar_counter <= ar_counter + 1'b1;
                        if(ar_counter == ADDRESS_COUNTER_FULL_VALUE) begin
                            ar_state_next <= FULL;
                            ar_counter <= '0;
                        end
                    end
                default: // FULL
            endcase : ar_state

            case (w_state)
                INPUTTING:
                    if(w_valid_i) begin
                        w_buffer[ar_counter] <= w_data_i;
                        w_counter <= w_counter + 1'b1;
                        if(w_counter == DATA_COUNTER_FULL_VALUE) begin
                            w_state_next <= FULL;
                            w_counter <= '0;
                        end
                    end
                default: // FULL
                    if(aw_state == FULL) begin
                        //
                    end
            endcase : w_state

        end
    end : LogicBlock

endmodule : AXI_Compliant_RAM
