module RX_Ethernet(
	//input
	input clk,
	input reset_n,
	//RX_phy
	input Rx_DV_wire,
	input Rx_clk,
	input [3:0] Rx_data_wire,
	
	//MAC
	output reg count_addr,
	output reg receive_mac,
	output [7:0] data,

	
	//TX
	output receive_tx,
	//output reg crc_correct=1'b0
	output crc_correct
	);
	reg [2:0] state;
	reg [3:0] nible;
	reg [5:0] count_crc;
	reg [5:0] rom_in;
	wire [7:0] rom_out;
	reg [3:0] Rx_data;
	reg Rx_DV;
//	reg last_receive_mac;
//	always @(posedge clk)
//		begin
//			last_receive_mac<=receive_mac;
//		end
	// Meta stability pose edge identifier
	
	reg met_1;
	reg met_2;
	reg rx_posedge;
	
	wire and_in_0;
	wire and_in_1;
	wire posedge_det;
	
	always @(posedge clk)
		begin
			met_1<=Rx_clk;
			met_2<=met_1;
			rx_posedge<=met_2;
		end
	
	and and1(and_in_0, ~rx_posedge, 1'b1);
	and and2(and_in_1, met_2, 1'b1);
	and and3(posedge_det,and_in_1,and_in_0);
	
	//assign
	assign receive_tx=receive_mac;
	assign data={Rx_data,nible};
	
//	always @(posedge clk)
//		begin
//			casex({(count_crc==6'd63),(last_receive_mac && ~receive_mac)})
//				2'bx0:crc_correct<=crc_correct;
//				2'b11:crc_correct<=1'b1;
//				2'b01:crc_correct<=1'b0;
//				default:crc_correct<=crc_correct;
//			endcase
//		end

	assign crc_correct=(count_crc==6'd63)? 1'b1:1'b0;

	//ROM
	Rx_ROM rx_rom(.addr(rom_in),.clk(clk),.q(rom_out));
	
	//rx_data store
	
	always @(posedge Rx_clk)
		begin
			Rx_data<=Rx_data_wire;
			Rx_DV<=Rx_DV_wire;
		end
	
	//data path and state machine
	reg [3:0] error_count;
	
	parameter ideal=3'd0,data_receive=3'd1, start_frame_odd_nib=3'd2, start_frame_even_nib=3'd3, hold_data=3'd4;
	
	always @(posedge clk or negedge reset_n)
		begin
			if(!reset_n)
				begin
					count_addr<=1'b0;
					rom_in<=6'b0;
					count_crc<=6'b0;
					nible<=4'b0;
					state<=3'b0;
					receive_mac<=1'b0;
					error_count<=4'b0;
				end
			else
				begin
					case(state)
						ideal:
							begin
								error_count<=4'b0;
								count_addr<=1'b0;
								rom_in<=6'b0;
								count_crc<=count_crc;
								nible<=4'b0;
								receive_mac<=1'b0;
								if({posedge_det,Rx_DV}==2'b11)
									begin
										state<=data_receive;
									end
								else
									begin
										state<=state;
									end
							end
						data_receive:
							begin
								
								rom_in<=6'b0;
								//nible<=4'b0;
								casex({posedge_det,Rx_DV,(Rx_data==4'b1101),(error_count==4'b1111)})//casex({({posedge_det,Rx_DV}==2'b11),(Rx_data==4'b1101),(error_count==4'b1111)})
									4'b111x:
										begin
											count_addr<=~count_addr;
											count_crc<=6'b0;
											state<=start_frame_odd_nib;
											error_count<=4'b0;
											receive_mac<=1'b1;
											nible<=nible;
										end
									4'b1100:
										begin
											count_addr<=1'b0;
											count_crc<=count_crc;
											state<=state;
											error_count<=error_count+4'b1;
											receive_mac<=1'b0;
											nible<=Rx_data;
										end
									4'b1101:
										begin
											count_addr<=~count_addr;
											count_crc<=6'b0;
											state<=start_frame_odd_nib;//state<=state;//start_frame_odd_nib;
											error_count<=4'b0;
											receive_mac<=1'b1;//receive_mac<=1'b0;//receive_mac<=1'b1;
											nible<=nible;
										end
									4'bx0xx:
										begin
											count_addr<=1'b0;
											count_crc<=6'b0;
											state<=ideal;//start_frame_odd_nib;
											error_count<=4'b0;
											receive_mac<=1'b0;
											nible<=4'b0;
										end
									default:
										begin
											count_addr<=1'b0;
											count_crc<=count_crc;
											state<=state;
											error_count<=error_count;
											receive_mac<=1'b0;
											nible<=nible;
										end
								endcase
							end
						start_frame_odd_nib:
							begin
								error_count<=4'b0;
								count_addr<=count_addr;
								rom_in<=rom_in;
								count_crc<=count_crc;
								case({posedge_det,Rx_DV})
									2'b11:
										begin
											nible<=Rx_data;
											state<=start_frame_even_nib;
											receive_mac<=1'b1;
										end
									2'b10://x0 or 10
										begin
											nible<=nible;
											state<=ideal;
											receive_mac<=1'b0;
										end
									default:
										begin
											nible<=nible;
											state<=state;
											receive_mac<=1'b1;
										end
								endcase
							end
						start_frame_even_nib:
							begin
								error_count<=4'b0;
								case({posedge_det,Rx_DV})
									2'b11:
										begin
											count_addr<=~count_addr;
											rom_in<=rom_in+6'b1;
											if (rom_out==data)
												begin
													count_crc<=count_crc+6'b1;
												end
											else
												begin
													count_crc<=count_crc;
												end
											nible<=nible;
											state<=start_frame_odd_nib;
											receive_mac<=1'b1;
										end
									2'b10://10 or x0
										begin
											count_addr<=count_addr;
											rom_in<=rom_in;
											count_crc<=count_crc;
											nible<=nible;
											state<=ideal;
											receive_mac<=1'b0;
										end
									default:
										begin
											count_addr<=count_addr;
											rom_in<=rom_in;
											count_crc<=count_crc;
											nible<=nible;
											state<=state;
											receive_mac<=1'b1;
										end
								endcase
							end
						default:
							begin
								error_count<=4'b0;
								count_addr<=1'b0;
								rom_in<=6'b0;
								count_crc<=6'b0;
								nible<=4'b0;
								state<=ideal;
								receive_mac<=1'b0;
							end
					endcase
				end
		end		
	
	endmodule
	//RAM
	//Rx_RAM rx_ram(.data(ram_data_in),.read_addr(ram_read_addr),.write_addr(ram_write_addr),.we(ram_wEnable),.clk(clk),.q(ram_read_data));
		