// Quartus Prime Verilog Template
// True Dual Port RAM with single clock

module ram_E0
#(parameter DATA_WIDTH=16, parameter ADDR_WIDTH=3)
(
	input [(DATA_WIDTH-1):0] data_a, data_b,
	input [(ADDR_WIDTH-1):0] addr_a, addr_b,
	input we_a, we_b, clk,
	output reg [(DATA_WIDTH-1):0] q_a, q_b
);


initial 
	begin : INIT
			
			ram[0]=16'b0000000010000100;
			
			//ram[2]=16'b0000000010000100;
			ram[3]=16'b0000000000000001;
			ram[4]=16'b0110000000010110;
			
			ram[5]=16'b0100001000011010;
			
			ram[6]=16'b0001110000000000;
			
			ram[7]=16'b0100000000011010;
			
			ram[2]=16'b0000000010000101;//ram;
			
			//ram[5]=16'b0100000000011010;
			//ram[6]=16'b0000000001001001;//ram[6]=16'b0000000010000101;ram[6]=16'b0000000010000101;
	end 

	// Declare the RAM variable
	(* ramstyle = "M9K" *) reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];

	// Port A 
	always @ (posedge clk)
	begin
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

	// Port B 
	always @ (posedge clk)
	begin
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
