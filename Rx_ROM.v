// Quartus Prime Verilog Template
// Single Port ROM

module Rx_ROM
#(parameter DATA_WIDTH=8, parameter ADDR_WIDTH=6)
(
	input [(ADDR_WIDTH-1):0] addr,
	input clk, 
	output reg [(DATA_WIDTH-1):0] q
);

	// Declare the ROM variable
	(* ramstyle = "M9K" *) reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];

	// Initialize the ROM with $readmemb.  Put the memory contents
	// in the file single_port_rom_init.txt.  Without this file,
	// this design will not compile.

	// See Verilog LRM 1364-2001 Section 17.2.8 for details on the
	// format of this file, or see the "Using $readmemb and $readmemh"
	// template later in this section.

	initial
	begin
		rom[0]=8'b00010010;
		rom[1]=8'b00110100;
		rom[2]=8'b01010110;
		rom[3]=8'b01010110;
		rom[4]=8'b01111000;
		rom[5]=8'b01111000;
		rom[6]=8'b01111000;
		rom[7]=8'b01111000;
		rom[8]=8'b01111000;
		rom[9]=8'b01111000;
		rom[10]=8'b01111000;
		rom[11]=8'b01111000;
		rom[12]=8'b01111000;
		rom[13]=8'b01111000;
		rom[14]=8'b01111000;
		rom[15]=8'b01111000;
		rom[16]=8'b01111000;
		rom[17]=8'b01111000;
		rom[18]=8'b01111000;
		rom[19]=8'b01111000;
		rom[20]=8'b01111000;
		rom[21]=8'b01111000;
		rom[22]=8'b01111000;
		rom[23]=8'b01111000;
		rom[24]=8'b01111000;
		rom[25]=8'b01111000;
		rom[26]=8'b01111000;
		rom[27]=8'b01111000;
		rom[28]=8'b01111000;
		rom[29]=8'b01111000;
		rom[30]=8'b01111000;
		rom[31]=8'b01111000;
		rom[32]=8'b01111000;
		rom[33]=8'b01111000;
		rom[34]=8'b01111000;
		rom[35]=8'b01111000;
		rom[36]=8'b01111000;
		rom[37]=8'b01111000;
		rom[38]=8'b01111000;
		rom[39]=8'b01111000;
		rom[40]=8'b01111000;
		rom[41]=8'b01111000;
		rom[42]=8'b01111000;
		rom[43]=8'b01111000;
		rom[44]=8'b01111000;
		rom[45]=8'b01111000;
		rom[46]=8'b01111000;
		rom[47]=8'b01111000;
		rom[48]=8'b01111000;
		rom[49]=8'b01111000;
		rom[50]=8'b01111000;
		rom[51]=8'b01111000;
		rom[52]=8'b01111000;
		rom[53]=8'b01111000;
		rom[54]=8'b01111000;
		rom[55]=8'b01111000;
		rom[56]=8'b01111000;
		rom[57]=8'b00010001;
		rom[58]=8'b00100010;
		rom[59]=8'b01000100;
		rom[60]=8'b00010001;
		rom[61]=8'b01111000;
		rom[62]=8'b01111000;
		rom[63]=8'b01111000;

		//$readmemb("RX_ROM_data.txt", rom);
	end

	always @ (posedge clk)
	begin
		q <= rom[addr];
	end

endmodule
