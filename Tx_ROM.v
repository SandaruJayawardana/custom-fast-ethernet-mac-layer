// Quartus Prime Verilog Template
// Single Port ROM

module Tx_ROM
#(parameter DATA_WIDTH=8, parameter ADDR_WIDTH=7)
(
	input [(ADDR_WIDTH-1):0] addr,
	input clk, 
	output reg [(DATA_WIDTH-1):0] q
);
	(* ramstyle = "M9K" *) reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];
	initial
	begin 
		rom[0]=8'b01010101;
		rom[1]=8'b01010101;
		rom[2]=8'b01010101;
		rom[3]=8'b01010101;
		rom[4]=8'b01010101;
		rom[5]=8'b01010101;
		rom[6]=8'b01010101;
		rom[7]=8'b11010101;
	end

	always @ (posedge clk)
	begin
		q <= rom[addr];
	end

endmodule
