module top(
    GPIO_0, GPIO_1,
    SW, KEY, LEDR, LEDG,
    HEX0, HEX1, HEX2, HEX3,
    CLOCK_24, CLOCK_27, CLOCK_50,/* EXT_CLOCK,
    PS2_CLK, PS2_DAT,
    UART_RXD, UART_TXD,
    TDI, TDO,
    VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS,
    I2C_SCLK, I2C_SDAT,
    AUD_ADCLRCK, AUD_ADCDAT, AUD_DACLRCK, AUD_DACDAT, AUD_XCK, AUD_BCLK,
    DRAM_ADDR, DRAM_BA_0, DRAM_BA_1, DRAM_CAS_N, DRAM_CKE, DRAM_CLK, DRAM_CS_N, DRAM_DQ, DRAM_LDQM, DRAM_RAS_N, DRAM_UDQM, DRAM_WE_N,
    FL_ADDR, FL_DQ, FL_OE_N, FL_RST_N, FL_WE_N, 
    SRAM_ADDR, SRAM_CE_N, SRAM_DQ, SRAM_LB_N, SRAM_OE_N, SRAM_UB_N, SRAM_WE_N,
    */
);

inout logic GPIO_0[35:0];
inout logic GPIO_1[35:0];

input logic SW[9:0];
input logic KEY[3:0];
output logic LEDR[7:0];
output logic LEDG[7:0];

output logic HEX0[6:0];
output logic HEX1[6:0];
output logic HEX2[6:0];
output logic HEX3[6:0];

input logic CLOCK_24[1:0];
input logic CLOCK_27[1:0];
input logic CLOCK_50;
    
endmodule
