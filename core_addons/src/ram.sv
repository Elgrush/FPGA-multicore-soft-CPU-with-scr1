module ram #(
    parameter WORD = 16,    // Width of one word in bytes 
              SIZE = 256    // Width of memory in words
) (
    // Common
    input logic clk,
    input logic rst_n,
    input en,

    //First memory access port
    input  logic [WORD-1 : 0]    data_in_1_i,
    input  logic [SIZE-1 : 0]    addr_1_i,
    input  logic                 write_1_i,
    output logic [WORD-1 : 0]    data_out_1_o

    //Second memory access port
    input  logic [WORD-1 : 0]    data_in_2_i,
    input  logic [SIZE-1 : 0]    addr_2_i,
    input  logic                 write_2_i,
    output logic [WORD-1 : 0]    data_out_2_o

);

logic [WORD-1 : 0]  ram [SIZE-1 : 0];


always_ff @( posedge (clk & en) or negedge rst_n ) begin
    if(!rst_n) begin
        ram <= '0;
    end else begin
        if(write_1_i) begin
            ram[addr_1_i] <= data_in_1_i;
        end

        if(write_2_i) begin
            ram[addr_2_i] <= data_in_2_i;
        end

        //If 2 write - second wins

        data_out_1_o <= ram[addr_1_i];
        data_out_2_o <= ram[addr_2_i];
    end
end
    
endmodule