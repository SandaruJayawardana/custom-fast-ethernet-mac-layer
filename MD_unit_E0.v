module MD_unit_E0(
	inout MDIO,
	
	input clk_in,
	
	input reset_n,
	
	output reg clk_25,
	
	output reg ready,
	
	output IRQ_link_down
	 
	);
	
		
	
	(* keep *) wire RW_request;// 0- write, 1- read
	
	(* keep *) wire new_addr;
	(* keep *) wire [2:0] addr;
	(* keep *) wire  [15:0] output_reg;
	
	assign RW_request=1'b1;
	assign new_addr=1'b1;
	assign addr=3'b1;
	
	reg [4:0] states;
	reg [15:0] input_data_store;
	reg w_enable;
	reg w_bit;
	reg [4:0] count;
	reg mdio_store;
	reg portA_wEnable;
	wire [15:0] portA_rData;
	wire we_b;
	wire [15:0] data_b;
	reg [2:0] portA_addr;
	
	
	ram_E0 r(.data_a(input_data_store), .data_b(data_b),.addr_a(portA_addr), .addr_b(addr), .we_a(portA_wEnable), .we_b(we_b), .clk(clk_in), .q_a(portA_rData), .q_b(output_reg));
	
	 
	reg [3:0] count_clk;
	
	always @(posedge clk_in)
		begin
			count_clk<=count_clk+4'b1;
		end
		
	always @(posedge clk_in)
		begin
			if (count_clk==4'b1111)
				begin
					clk_25<=~clk_25;
				end
			else
				begin
					clk_25<=clk_25;
				end
		end


	
	
	parameter reset=5'd00, ideal=5'b1, default_read_init=5'd2, default_read=5'd3, default_read_TA_1=5'd4, default_read_TA_2=5'd5, data_in=5'd6, write_back=5'd7, write_end=5'd8; 
	parameter custom_write_init=5'd9, custom_write=5'd10, data_write=5'd11, data_write_end=5'd12, custom_read_init=5'd13, custom_read=5'd14, coustom_read_addr_1=5'd15, coustom_read_addr_2=5'd16, default_read_TA_3=5'd17;
	parameter default_write_init=5'd18, default_write=5'd19, reset_default_settings=5'd20,data_write_end_a=5'd21,data_write_a=5'd22,default_write_a=5'd23,default_write_init_a=5'd24,reset_default_settings_intermediate=5'd25;
	parameter data_write_intermediate=5'd26,data_write_end_intermediate=5'd27;
	
	assign MDIO=(w_enable==1'b1)? w_bit:1'bz;
	
	
	DFFE IRQ_reg (
				.d(~input_data_store[2]), 
				.clk(clk_in), 
				//.clrn(<active_low_clear>), 
				//.prn(<active_low_preset>), 
				.ena(portA_wEnable), 
				.q(IRQ_link_down)
				);

	
	always @(posedge clk_25)
		begin
			mdio_store<=MDIO;
		end
	
	always @(negedge clk_25 or negedge reset_n)
		begin
			if (reset_n==1'b0)
				begin
					count<=5'b0;
					states<=reset_default_settings;
					w_enable<=1'b0;
					w_bit<=1'b1;
					ready<=1'b0;
					portA_addr<=3'b0;
					portA_wEnable<=1'b0;
					input_data_store<=16'b0;
				end
			else
				begin
					case(states)
						reset_default_settings:
							begin 
								ready<=1'b0;
								w_enable<=1'b0;
								count <=count+5'b1;
								
								portA_wEnable<=1'b0;
								portA_addr<=3'bX;
								w_bit<=1'b1;
								input_data_store<=16'bx;
								if (count==5'b11111)
									begin
										states<=default_write_init;
									end
								else
									begin
										states<=reset_default_settings;
									end
							end
						reset:
							begin 
								ready<=1'b0;
								w_enable<=1'b0;
								w_bit<=1'bx;
								count <=count+5'b1;
								
								portA_wEnable<=1'b0;
								portA_addr<=3'bX;
								input_data_store<=16'bx;
								if (count==5'b11111)
									begin
										states<=ideal;
									end
								else
									begin
										states<=reset;
									end
							end
						ideal:
							begin
								ready<=1'b0;
								w_enable<=1'b0;
								w_bit<=1'bx;
								count <=5'bx;
								
								portA_wEnable<=1'b0;
								portA_addr<=3'bX;
								input_data_store<=16'bx;
								case({new_addr,RW_request})
									2'b00:states<=custom_write_init;
									2'b01:states<=custom_read_init;
									default:states<=default_read_init;
								endcase
							end
						default_read_init:
							begin
								portA_addr<=3'b100;
								//w_bit<=1'b0;
								w_enable<=1'b1;
								states<=default_read;
								count<=5'b0;
								
								ready<=1'b0;
								w_bit<=1'b1;
								portA_wEnable<=1'b0;
								input_data_store<=16'bx;
							end
						default_read:
							begin
								count<=count+5'b1;
								w_bit<=portA_rData[count[3:0]];
								
								ready<=1'b0;
								w_enable<=1'b1;
								portA_wEnable<=1'b0;
								portA_addr<=portA_addr;
								input_data_store<=16'bx;
								
								if (count==5'd13)
									begin
										
										//w_enable<=0;
										states<=default_read_TA_1;
										//default_read_reg<=1'b1;
									end
								else
									begin
										states<=default_read;
									end
							end
						default_read_TA_1:
							begin
								w_enable<=1'b0;
								count<=5'bx;
								states<=default_read_TA_2;
								input_data_store<=16'bx;
								
								ready<=1'b0;
								w_bit<=1'bx;
								portA_wEnable<=1'b0;
								portA_addr<=3'bx;
							end
						default_read_TA_2:
							begin
								states<=default_read_TA_3;
								
								w_enable<=1'b0;
								count<=5'bx;
								ready<=1'b0;
								w_bit<=1'bx;
								portA_wEnable<=1'b0;
								portA_addr<=3'bx;
								input_data_store<=16'bx;
							end
						default_read_TA_3:
							begin
								states<=data_in;
								
								w_enable<=1'b0;
								count<=5'b0;
								ready<=1'b0;
								w_bit<=1'bx;
								portA_wEnable<=1'b0;
								portA_addr<=3'bx;
								input_data_store<=16'bx;
							end
						data_in:
							begin
								count<=count+5'b1;
								input_data_store[15:1]<=input_data_store[14:0];
								input_data_store[0]<=mdio_store;
								
								w_enable<=1'b0;
								ready<=1'b0;
								w_bit<=1'bx;
								portA_wEnable<=1'b0;
								portA_addr<=3'bx;
								
								if (count==5'd15)
									begin
										states<=write_back;
									end
								else
									begin
										states<=data_in;
									end
							end
						write_back:
							begin
								count<=5'bx;
								w_enable<=1'b0;
								ready<=1'b0;
								w_bit<=1'bx;
								input_data_store<=input_data_store;
								
								if(new_addr==1'b1)
									begin
										portA_addr<=3'b1;
									end
								else
									begin
										portA_addr<=addr;
									end
								portA_wEnable<=1'b1;
								states<=write_end;
							end
						write_end:
							begin
								w_enable<=1'b0;
								w_bit<=1'bx;
								portA_addr<=3'bx;
								count<=5'b0;
								input_data_store<=16'bx;
								
								ready<=1'b1;
								portA_wEnable<=1'b0;
								states<=reset;
							end
						custom_write_init:
							begin
								portA_addr<=3'b101;
								//w_bit<=1'b0;
								w_enable<=1'b1;
								states<=custom_write;
								count<=5'b0;
								input_data_store<=16'bx;
								
								w_bit<=1'b1;
								ready<=1'b0;
								portA_wEnable<=1'b0;
							end
						custom_write:
							begin
								count<=count+5'b1;
								w_bit<=portA_rData[count[3:0]];
								input_data_store<=16'bx;
								
								w_enable<=1'b1;
								ready<=1'b0;
								portA_wEnable<=1'b0;
								if (count==5'd15)
									begin
										portA_addr<=3'b0;
										states<=data_write;
										//default_read_reg<=1'b1;
									end
								else
									begin
										portA_addr<=portA_addr;
										states<=custom_write;
									end
							end
						data_write:
							begin
								w_enable<=1'b1;
								ready<=1'b0;
								portA_wEnable<=1'b0;
								portA_addr<=portA_addr;
								input_data_store<=16'bx;
								
								count<=count+5'b1;
								w_bit<=portA_rData[count[3:0]];
								if (count==5'd31)
									begin
										states<=data_write_end;
										//default_read_reg<=1'b1;
										
									end
								else
									begin
										states<=data_write;
									end
							end
						data_write_end:
							begin
								w_enable<=1'b0;
								ready<=1'b1;
								states<=reset;
								input_data_store<=16'bx;
								
								count<=5'b0;
								portA_wEnable<=1'b0;
								portA_addr<=3'bx;
								w_bit<=1'bx;
							end
						custom_read_init:
							begin
								portA_addr<=3'b100;
								//w_bit<=1'b0;
								w_enable<=1'b1;
								states<=custom_read;
								count<=5'b0;
								input_data_store<=16'bx;
								
								portA_wEnable<=1'b0;
								w_bit<=1'b1;
								ready<=1'b0;
							end
						custom_read:
							begin	
								count<=count+5'b1;
								w_bit<=portA_rData[count[3:0]];
								input_data_store<=16'bx;
								
								ready<=1'b0;
								portA_addr<=portA_addr;
								w_enable<=1'b1;
								portA_wEnable<=1'b0;
								if (count==5'd11)
									begin
										states<=coustom_read_addr_1;
										//default_read_reg<=1'b1;
									end
								else
									begin
										states<=custom_read;
									end
							end
						coustom_read_addr_1:
							begin
								count<=5'bx;
								ready<=1'b0;
								portA_addr<=3'bx;
								w_enable<=1'b1;
								portA_wEnable<=1'b0;
								input_data_store<=16'bx;
								
								w_bit<=addr[1];
								states<=coustom_read_addr_2;
							end
						coustom_read_addr_2:
							begin
								count<=5'bx;
								ready<=1'b0;
								portA_addr<=3'bx;
								w_enable<=1'b1;
								portA_wEnable<=1'b0;
								input_data_store<=16'bx;
								
								w_bit<=addr[0];
								states<=default_read_TA_1;
							end
						default_write_init:
							begin
								ready<=1'b0;
								portA_wEnable<=1'b0;
								input_data_store<=16'bx;
								
								portA_addr<=3'b101;
								w_bit<=1'b1;
								w_enable<=1'b1;
								states<=default_write;
								count<=5'b0;
							end
						default_write:
							begin
								count<=count+5'b1;
								w_bit<=portA_rData[count[3:0]];
								input_data_store<=16'bx;
								
								w_enable<=1'b1;
								ready<=1'b0;
								portA_wEnable<=1'b0;
								
								if (count==5'd15)
									begin
										portA_addr<=3'b110;
										states<=data_write_intermediate;
										//default_read_reg<=1'b1;
									end
								else
									begin
										portA_addr<=portA_addr;
										states<=default_write;
									end
							end
						
						data_write_intermediate:
							begin
								w_enable<=1'b1;
								ready<=1'b0;
								portA_wEnable<=1'b0;
								portA_addr<=portA_addr;
								input_data_store<=16'bx;
								
								count<=count+5'b1;
								w_bit<=portA_rData[count[3:0]];
								if (count==5'd31)
									begin
										states<=data_write_end_intermediate;
										//default_read_reg<=1'b1;
										
									end
								else
									begin
										states<=data_write_intermediate;
									end
							end
						data_write_end_intermediate:
							begin
								w_enable<=1'b0;
								ready<=1'b1;
								states<=reset_default_settings_intermediate;
								input_data_store<=16'bx;
								
								count<=5'b0;
								portA_wEnable<=1'b0;
								portA_addr<=3'bx;
								w_bit<=1'bx;
							end
						reset_default_settings_intermediate:
							begin 
								ready<=1'b0;
								w_enable<=1'b0;
								count <=count+5'b1;
								
								portA_wEnable<=1'b0;
								portA_addr<=3'bX;
								w_bit<=1'b1;
								input_data_store<=16'bx;
								if (count==5'b11111)
									begin
										states<=default_write_init_a;
									end
								else
									begin
										states<=reset_default_settings_intermediate;
									end
							end
						default_write_init_a:
							begin
								ready<=1'b0;
								portA_wEnable<=1'b0;
								input_data_store<=16'bx;
								
								portA_addr<=3'b111;
								w_bit<=1'b1;
								w_enable<=1'b1;
								states<=default_write_a;
								count<=5'b0;
							end
						default_write_a:
							begin
								count<=count+5'b1;
								w_bit<=portA_rData[count[3:0]];
								input_data_store<=16'bx;
								
								w_enable<=1'b1;
								ready<=1'b0;
								portA_wEnable<=1'b0;
								
								if (count==5'd15)
									begin
										portA_addr<=3'b10;
										states<=data_write_a;
										//default_read_reg<=1'b1;
									end
								else
									begin
										portA_addr<=portA_addr;
										states<=default_write_a;
									end
							end
						data_write_a:
							begin
								w_enable<=1'b1;
								ready<=1'b0;
								portA_wEnable<=1'b0;
								portA_addr<=portA_addr;
								input_data_store<=16'bx;
								
								count<=count+5'b1;
								w_bit<=portA_rData[count[3:0]];
								if (count==5'd31)
									begin
										states<=data_write_end_a;
										//default_read_reg<=1'b1;
										
									end
								else
									begin
										states<=data_write_a;
									end
							end
						data_write_end_a:
							begin
								w_enable<=1'b0;
								ready<=1'b1;
								states<=reset;
								input_data_store<=16'bx;
								
								count<=5'b0;
								portA_wEnable<=1'b0;
								portA_addr<=3'bx;
								w_bit<=1'bx;
							end
						default: 
							begin
								states<=reset;
								count<=5'b0;
								portA_wEnable<=1'b0;
								ready<=1'b0;
								w_enable<=1'b0;
								w_bit<=1'bx;
								portA_addr<=3'bx;
								input_data_store<=16'bx;
							end
					endcase
				end
		end
	
endmodule
