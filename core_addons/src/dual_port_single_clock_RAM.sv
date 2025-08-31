module dual_port_single_clock_RAM
#(parameter RDATA_WIDTH=8, parameter RADDR_WIDTH=6)
(
	input clk,
	input we_a, we_b,
	input [(RDATA_WIDTH-1):0] data_a, data_b,
	input [(RADDR_WIDTH-1):0] addr_a, addr_b,
	output logic [(RDATA_WIDTH-1):0] q_a, q_b
);

	// объявление памяти
	logic [RDATA_WIDTH-1:0] ram[2**RADDR_WIDTH-1:0];

	always @ (posedge clk)
	begin
		// Порт A 
		if (we_a) 
		begin
			ram[addr_a] <= data_a;
			q_a <= data_a;
		end
		else 
		begin
			q_a <= ram[addr_a];
		end 
	end

	always @ (posedge clk)
	begin
		// Порт B 
		if (we_b) 
		begin
			ram[addr_b] <= data_b;
			q_b <= data_b;
		end
		else 
		begin
			q_b <= ram[addr_b];
		end 
	end

endmodule
