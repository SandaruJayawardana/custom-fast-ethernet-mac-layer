
module TX_Ethernet(
	input clk,
	input reset_n,
	
	//TX_phy
	output reg Tx_EN_wire,
	output reg Tx_ER_wire,
	input Tx_clk,
	output reg [3:0] Tx_data,
	
	//MAC
	input count_addr,
	input receive_mac,
	input [7:0] data,
	input [1:0] mode,
	input [4:0] packet_no,
	output [7:0] packet_data,
	output reg [3:0] jitter_count_tx_0,
	output reg available_packet_data=1'b1,
	
	//RX
	input receive_tx,
	input crc_correct_wire
	);
	reg Tx_ER;
	reg Tx_EN;
	
	reg last_Tx_ER;
	wire posedge_det;
	reg even_nible;
	
	reg last_receive_tx;
	reg crc_correct=1'b0;
	
	always @(posedge clk)
		begin
			casex({mode[1],crc_correct_wire,(last_receive_tx && ~receive_tx)})
				3'b0xx:crc_correct<=1'b0;
				3'b1x0:crc_correct<=crc_correct;
				3'b111:crc_correct<=1'b1;
				3'b101:crc_correct<=1'b0;
				default:crc_correct<=crc_correct;
			endcase
		end
	
	
	
	reg [11:0] count_10u = 12'b0;
	//ram
	reg [3:0] ram_addr_mac;
	reg [3:0] ram_addr_tx;
	reg count_addr_tx;
	
	wire ram_wEnable;
	wire [7:0] ram_out;
	wire count_addr_not_equal;
	
	//assign ram_wEnable=(receive_tx && !(count_addr_tx==count_addr))? 1'b1:1'b0;
	//assign packet_data=ram_out;
	
	assign count_addr_not_equal=(count_addr_tx!=count_addr)? 1'b1:1'b0;
	assign ram_wEnable=receive_tx && count_addr_not_equal;
	
	TX_RAM rx_ram(.data(data),.read_addr(ram_addr_tx),.write_addr(ram_addr_mac),.we(ram_wEnable),.clk(clk),.q(ram_out));
	
	always @(posedge clk or negedge reset_n)
		begin
			if (!reset_n)
				begin
					ram_addr_mac<=4'b0;
					count_addr_tx<=1'b0;
					
				end
			else
				begin
					casex({count_addr_not_equal,receive_tx})
						2'b11:
							begin
								ram_addr_mac<=ram_addr_mac+4'b1;
								count_addr_tx<=~count_addr_tx;
							end
						2'b01:
							begin
								ram_addr_mac<=ram_addr_mac;
								count_addr_tx<=count_addr_tx;
							end
						2'bx0:
							begin
								count_addr_tx<=1'b0;
								if((ram_addr_mac==ram_addr_tx) && even_nible && posedge_det)
									begin
										ram_addr_mac<=4'b0;
									end
								else
									begin
										ram_addr_mac<=ram_addr_mac;
									end
							end
						default:
							begin
								ram_addr_mac<=4'b0;
								count_addr_tx<=1'b0;
							end
					endcase		
				end
		end
	
	//rom
	reg [6:0] rom_in;
	wire [7:0] rom_out;
	Tx_ROM tx_rom(.addr(rom_in),.clk(clk),.q(rom_out));
	
	//meta satbility neg edge identifier
		
	reg met_1;
	reg met_2;
	reg rx_posedge;
	
	wire and_in_0;
	wire and_in_1;
	
	
	always @(posedge clk)
		begin
			met_1<=Tx_clk;
			met_2<=met_1;
			rx_posedge<=met_2;
		end
	
	and and1(and_in_0, ~rx_posedge, 1'b1);
	and and2(and_in_1, met_2, 1'b1);
	and and3(posedge_det,and_in_1,and_in_0);
	
	//main state machine and data path
	reg [2:0] state;
	reg Tx_byte_sel;
	reg start_watch_time_status,last_start_watch_time_status;
	
	always @(posedge clk)
		begin	
			last_start_watch_time_status<= start_watch_time_status;
			case({last_start_watch_time_status,start_watch_time_status})
				2'b01:
					begin
						jitter_count_tx_0<=1'b1;
					end
				2'b11:
					begin	
						jitter_count_tx_0<=jitter_count_tx_0+1'b1;
					end
				default:
					begin
						jitter_count_tx_0<=jitter_count_tx_0;
					end
			endcase
		end
	
	wire [7:0] Tx_byte;
	
	parameter ideal=3'd0, normal_mode_even=3'd1, normal_mode_odd=3'd2, master_mode_init=3'd3, master_slave_mode_even=3'd4, master_slave_mode_odd=3'd5, slave_mode_init=3'd6;
	
	assign Tx_byte=(Tx_byte_sel)? ram_out:rom_out;
	
	always @(negedge Tx_clk)
		begin
			Tx_EN_wire<=Tx_EN;
			Tx_ER_wire<=Tx_ER;
			case(even_nible)
				1'b0:Tx_data<=Tx_byte[3:0];
				1'b1:Tx_data<=Tx_byte[7:4];
				default:Tx_data<=Tx_data;
			endcase
		end
		
	always @(posedge clk or negedge reset_n)
		begin
			if(!reset_n)
				begin
					rom_in<=7'b0;
					Tx_byte_sel<=1'b0;
					Tx_EN<=1'b0;
					Tx_ER<=1'b0;
					even_nible<=1'b0;
					state<=4'b0;
					ram_addr_tx<=4'b0;
					last_Tx_ER<=1'b0;
					available_packet_data<=1'b1;
					start_watch_time_status<=1'b0;
				end
			else
				begin
					case(state)
						ideal:
							begin
								last_Tx_ER<=1'b0;
								rom_in<=7'b0;
								Tx_byte_sel<=1'b0;//0-rom 1-ram
								Tx_ER<=1'b0;
								ram_addr_tx<=4'b0;
								even_nible<=1'b0;
								casex({mode,receive_mac,posedge_det}) // 11- slave mode 10-master mode 01-normal mode
									4'b11xx:
										begin
											state<=slave_mode_init;
											Tx_EN<=1'b0;
											available_packet_data<=1'b0;
											start_watch_time_status<=1'b0;
										end
									4'b10xx:
										begin	
											state<=master_mode_init;
											Tx_EN<=1'b0;
											available_packet_data<=1'b0;
											start_watch_time_status<=1'b0;
										end
									4'b0111:
										begin	
											state<=normal_mode_odd;
											Tx_EN<=1'b1;
											available_packet_data<=1'b1;
											start_watch_time_status<=1'b1;
										end
									default:
										begin
											state<=ideal;
											Tx_EN<=1'b0;
											available_packet_data<=available_packet_data;
											start_watch_time_status<=1'b0;
										end
								endcase
							end
						normal_mode_odd:
							begin
								last_Tx_ER<=1'b0;
								rom_in<=rom_in;
								ram_addr_tx<=ram_addr_tx;
								Tx_ER<=1'b0;
								Tx_EN<=1'b1;
								Tx_byte_sel<=Tx_byte_sel;
								available_packet_data<=available_packet_data;
								if (posedge_det)
									begin
										state<=normal_mode_even;
										even_nible<=1'b1;
										start_watch_time_status<=1'b0;
									end
								else
									begin	
										state<=state;
										even_nible<=1'b0;
										start_watch_time_status<=1'b1;
									end
							end
						normal_mode_even:
							begin
								last_Tx_ER<=1'b0;
								Tx_ER<=1'b0;
								available_packet_data<=available_packet_data;
								start_watch_time_status<=1'b0;
								casex ({posedge_det,(rom_in==7'd7),(ram_addr_tx==ram_addr_mac)})
									3'b10x:
										begin
											state<=normal_mode_odd;
											even_nible<=1'b0;
											rom_in<=rom_in+7'b1;
											ram_addr_tx<=4'b0;
											Tx_byte_sel<=1'b0;
											Tx_EN<=1'b1;
										end
									3'b110:
										begin
											state<=normal_mode_odd;//ram should be filled with addr 1 upward. 0 can't be used to to start the ram storing process. ram 0 should be start with sfd. but no need to store that in 0 location
											even_nible<=1'b0;
											rom_in<=rom_in;
											ram_addr_tx<=ram_addr_tx+4'b1;
											Tx_byte_sel<=1'b1;
											Tx_EN<=1'b1;
										end
									3'b111:
										begin
											state<=ideal;
											even_nible<=1'b0;
											rom_in<=7'b0;
											ram_addr_tx<=4'b0;
											Tx_byte_sel<=1'b0;
											Tx_EN<=1'b0;
										end
									default:
										begin
											state<=state;
											even_nible<=1'b1;
											rom_in<=rom_in;
											ram_addr_tx<=ram_addr_tx;
											Tx_byte_sel<=Tx_byte_sel;
											Tx_EN<=1'b1;
										end
								endcase
							end
						master_mode_init:
							begin
								Tx_byte_sel<=1'b0;
								ram_addr_tx<=4'bx;
								last_Tx_ER<=last_Tx_ER;
								even_nible<=1'b0;
								available_packet_data<=available_packet_data;
								start_watch_time_status<=1'b0;
								casex ({mode[1],count_10u[11],posedge_det})	
										3'b111:
											begin
												Tx_EN<=1'b1;
												Tx_ER<=1'b0;//(~last_Tx_ER && ~crc_correct);
												state<=master_slave_mode_odd;
											end
										3'b0xx:
											begin
												Tx_EN<=1'b0;
												Tx_ER<=1'b0;
												state<=ideal;
											end
										default:
											begin
												Tx_EN<=1'b0;
												Tx_ER<=1'b0;
												state<=state;
											end
								endcase
							end
						master_slave_mode_odd:
							begin
								ram_addr_tx<=4'bx;
								Tx_byte_sel<=1'b0;
								Tx_EN<=1'b1;
								Tx_ER<=Tx_ER;
								rom_in<=rom_in;
								last_Tx_ER<=last_Tx_ER;
								available_packet_data<=available_packet_data;
								start_watch_time_status<=1'b0;
								if (posedge_det)
									begin
										state<=master_slave_mode_even;
										even_nible<=1'b1;
									end
								else
									begin
										state<=state;
										even_nible<=1'b0;
									end
							end
						master_slave_mode_even:
							begin
								
								Tx_byte_sel<=1'b0;
								ram_addr_tx<=4'bx;
								available_packet_data<=available_packet_data;
								start_watch_time_status<=1'b0;
								case ({posedge_det,(rom_in==7'd71)})//correct value is 71
									2'b10:
										begin
											state<=master_slave_mode_odd;
											even_nible<=1'b0;
											rom_in<=rom_in+7'b1;
											Tx_EN<=1'b1;
											Tx_ER<=Tx_ER;
											last_Tx_ER<=last_Tx_ER;
										end
									2'b11:
										begin
											state<=slave_mode_init;
											even_nible<=1'b0;
											Tx_EN<=1'b0;
											rom_in<=7'b0;
											Tx_ER<=1'b0;
											last_Tx_ER<=Tx_ER;
										end
									default:
										begin
											state<=state;
											even_nible<=1'b1;
											rom_in<=rom_in;
											Tx_EN<=1'b1;
											Tx_ER<=Tx_ER;
											last_Tx_ER<=last_Tx_ER;
										end
								endcase
							end
						slave_mode_init:
							begin
								last_Tx_ER<=last_Tx_ER;
								even_nible<=1'b0;
								Tx_EN<=1'b0;
								rom_in<=7'b0;
								Tx_ER<=1'b0;
								Tx_byte_sel<=1'b0;
								ram_addr_tx<=4'bx;
								available_packet_data<=available_packet_data;
								start_watch_time_status<=1'b0;
								casex ({mode[1],receive_tx})	
									3'b11:
										begin
											state<=master_mode_init;
										end
									3'b0x:
										begin
											state<=ideal;
										end
									default:
										begin
											state<=state;
										end
								endcase
							end
						default:
							begin
								rom_in<=7'b0;
								Tx_byte_sel<=1'b0;
								Tx_EN<=1'b0;
								Tx_ER<=1'b0;
								even_nible<=1'b0;
								state<=4'b0;
								ram_addr_tx<=4'b0;
								last_Tx_ER<=1'b0;
								available_packet_data<=available_packet_data;
								start_watch_time_status<=1'b0;
							end
					endcase
				end
		end

			
	//time counter
	wire clock_start;
	
	reg [12:0] count_prop=13'b0;
	reg [23:0] tot_time_10u;
	reg [27:0] tot_time_prop;
	reg [15:0] iteration_count=16'b0;
	reg last_mode_bit_1;
	
	
	assign clock_start=(mode[1] && even_nible && (rom_in==7'd7) && posedge_det)? 1'b1:1'b0;
	
	always @(posedge clk)
		begin
			last_mode_bit_1<=mode[1];
			last_receive_tx<=receive_tx;
		end
		
	always @(posedge clk)
		begin
			if (~last_receive_tx && receive_tx)
				begin
					count_10u<=11'b1;// this has error of +5ns
				end
			else
				begin
					count_10u<=count_10u+11'b1;
				end
		end
	
	always @(posedge clk)
		begin
			if (clock_start)
				begin
					count_prop<=12'b1;// this has error of +5ns
				end
			else
				begin
					count_prop<=count_prop+12'b1;
				end
		end
	
	always @(posedge clk)
		begin
			casex ({(~Tx_ER && crc_correct),(!last_mode_bit_1 && mode[1]),clock_start})
				3'b101:
					begin
						iteration_count<=iteration_count+16'b1;
						tot_time_prop<=tot_time_prop+count_prop;
						tot_time_10u<=tot_time_10u+count_10u;
					end
				3'bx1x:
					begin
						iteration_count<=16'b0;
						tot_time_prop<=28'b0;
						tot_time_10u<=24'b0;
					end
				default:
					begin
						iteration_count<=iteration_count;
						tot_time_prop<=tot_time_prop;
						tot_time_10u<=tot_time_10u;
					end
			endcase
		end
	
	//timming data
	wire [7:0] data_wire [8:0];
	assign data_wire[0]=iteration_count[7:0];
	assign data_wire[1]=iteration_count[15:8];
	assign data_wire[2]=tot_time_10u[7:0];
	assign data_wire[3]=tot_time_10u[15:8];
	assign data_wire[4]=tot_time_10u[23:16];
	assign data_wire[5]=tot_time_prop[7:0];
	assign data_wire[6]=tot_time_prop[15:8];
	assign data_wire[7]=tot_time_prop[23:16];
	assign data_wire[8]={4'b0,tot_time_prop[27:24]};
	
	assign packet_data=data_wire[packet_no[3:0]];
endmodule

