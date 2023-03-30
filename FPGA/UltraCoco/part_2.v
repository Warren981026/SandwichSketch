/*
 * @Filename: 
 * @Author: ws
 * @Description: implement part_1 bucket's function
 * @Date: 2023-02-15 15:11:48
 * @LastEditTime: 2023-02-17 11:54:24
 * @Company: 662
 */

module part_2
    #(parameter RAM_PTR=10,
                HASH_BASE=0)(
    /****************clock****************/
     input wire         clk
    ,input wire         rst_n

    /************input element************/
    ,input wire [95:0]  hash_e_f  
    ,input wire         valid

    /***********output element************/
    ,output reg [63:0]  e_f_nxt
    ,output reg         valid_nxt
);


/*******************ram*******************/
//a port:read; b port:write
reg     [RAM_PTR-1:0]   ram_addr_a;
reg     [63:0]          ram_data_a;
reg                     ram_wren_a;
reg                     ram_rden_a;
wire    [63:0]          ram_out_a;
reg     [RAM_PTR-1:0]   ram_addr_b;
reg     [63:0]          ram_data_b;
reg                     ram_wren_b;
reg                     ram_rden_b;
wire    [63:0]          ram_out_b;

/*************control signal*************/
reg     [95:0]  hash_e_f2;
reg             valid2;
reg     [95:0]  hash_e_f3;
reg             valid3;
reg     [95:0]  hash_e_f4;
reg             valid4;

reg     [63:0]  ram_data;

/**************main logic***************/
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        e_f_nxt <= 64'b0;
        valid_nxt <= 1'b0;

        ram_addr_a <= {(RAM_PTR){1'b0}};
        ram_data_a <= 64'b0;
        ram_wren_a <= 1'b0;
        ram_rden_a <= 1'b0;
        ram_addr_b <= {(RAM_PTR){1'b0}};
        ram_data_b <= 64'b0;
        ram_wren_b <= 1'b0;
        ram_rden_b <= 1'b0;

        hash_e_f2 <= 96'b0;
        valid2 <= 1'b0;
        hash_e_f3 <= 96'b0;
        valid3 <= 1'b0;
        hash_e_f4 <= 96'b0;
        valid4 <= 1'b0;

        ram_data <= 64'b0;
    end

    else begin
        hash_e_f2 <= hash_e_f;
        valid2 <= valid;
        hash_e_f3 <= hash_e_f2;
        valid3 <= valid2;
        hash_e_f4 <= hash_e_f3;
        valid4 <= valid3;

        ram_data <= ram_out_a;

        if(valid)begin
            ram_addr_a <= hash_e_f[HASH_BASE+RAM_PTR-1+64:HASH_BASE+64];
            ram_data_a <= 64'b0;
            ram_wren_a <= 1'b0;
            ram_rden_a <= 1'b1;
        end
        else begin
            ram_addr_a <= {(RAM_PTR){1'b0}};
            ram_data_a <= 64'b0;
            ram_wren_a <= 1'b0;
            ram_rden_a <= 1'b0;            
        end

        if(valid4)begin
            //empty
            if(ram_data==64'b0)begin
                ram_addr_b <= hash_e_f4[HASH_BASE+RAM_PTR-1+64:HASH_BASE+64];
                ram_data_b <= hash_e_f4[63:0];
                ram_wren_b <= 1'b1;
                ram_rden_b <= 1'b0;

                e_f_nxt <= 64'b0;
                valid_nxt <= 1'b0;
            end

            //e==ID
            else if(ram_data[63:32] == hash_e_f4[63:32])begin
                ram_addr_b <= hash_e_f4[HASH_BASE+RAM_PTR-1+64:HASH_BASE+64];
                ram_data_b <= hash_e_f4[63:0] + ram_data[31:0];
                ram_wren_b <= 1'b1;
                ram_rden_b <= 1'b0;

                e_f_nxt <= 64'b0;
                valid_nxt <= 1'b0;              
            end

            else begin
                if(hash_e_f4[31:0] > ram_data[31:0])begin
                    ram_addr_b <= hash_e_f4[HASH_BASE+RAM_PTR-1+64:HASH_BASE+64];
                    ram_data_b <= hash_e_f4[63:0];
                    ram_wren_b <= 1'b1;
                    ram_rden_b <= 1'b0;

                    e_f_nxt <= ram_data;
                    valid_nxt <= 1'b1;                                         
                end

                else begin
                    ram_addr_b <= {(RAM_PTR){1'b0}};
                    ram_data_b <= 64'b0;
                    ram_wren_b <= 1'b0;
                    ram_rden_b <= 1'b0;

                    e_f_nxt <= hash_e_f4[63:0];
                    valid_nxt <= 1'b1;                    
                end
            end
        end
        else begin
            ram_addr_b <= {(RAM_PTR){1'b0}};
            ram_data_b <= 64'b0;
            ram_wren_b <= 1'b0;
            ram_rden_b <= 1'b0;

            e_f_nxt <= 64'b0;
            valid_nxt <= 1'b0;           
        end        
    end
end

/**************generate ram**************/
`ifdef RAM_0_3125
    ram_8192_64 ram_8192_64_inst(
		 .clka				(clk				    )	//a clock, a port is used for read
        ,.ena				(ram_rden_a	            )	//enable
        ,.wea				(!ram_rden_a			)	//ena==1, wea=1:write; wea=0:read
        ,.addra				(ram_addr_a				)	//read address
        ,.dina				(64'b0				    )
        ,.douta				(ram_out_a              )   //read data from ram
        ,.clkb				(clk				    )	//a clock, a port is used for write
        ,.enb				(ram_wren_b             )   //enable
        ,.web				(ram_wren_b             )   //ena==1, wea=1:write; wea=0:read
        ,.addrb				(ram_addr_b				)   //write address
        ,.dinb				(ram_data_b             )   //write data to ram
        ,.doutb				(                       )
	);
`elsif RAM_0_625
    ram_16384_64 ram_16384_64_inst(
		 .clka				(clk				    )	//a clock, a port is used for read
        ,.ena				(ram_rden_a	            )	//enable
        ,.wea				(!ram_rden_a			)	//ena==1, wea=1:write; wea=0:read
        ,.addra				(ram_addr_a				)	//read address
        ,.dina				(64'b0				    )
        ,.douta				(ram_out_a              )   //read data from ram
        ,.clkb				(clk				    )	//a clock, a port is used for write
        ,.enb				(ram_wren_b             )   //enable
        ,.web				(ram_wren_b             )   //ena==1, wea=1:write; wea=0:read
        ,.addrb				(ram_addr_b				)   //write address
        ,.dinb				(ram_data_b             )   //write data to ram
        ,.doutb				(                       )
	);
`elsif RAM_1_25
    ram_32768_64 ram_32768_64_inst(
		 .clka				(clk				    )	//a clock, a port is used for read
        ,.ena				(ram_rden_a	            )	//enable
        ,.wea				(!ram_rden_a			)	//ena==1, wea=1:write; wea=0:read
        ,.addra				(ram_addr_a				)	//read address
        ,.dina				(64'b0				    )
        ,.douta				(ram_out_a              )   //read data from ram
        ,.clkb				(clk				    )	//a clock, a port is used for write
        ,.enb				(ram_wren_b             )   //enable
        ,.web				(ram_wren_b             )   //ena==1, wea=1:write; wea=0:read
        ,.addrb				(ram_addr_b				)   //write address
        ,.dinb				(ram_data_b             )   //write data to ram
        ,.doutb				(                       )
	);
`elsif RAM_2_5
    ram_65536_64 ram_65536_64_inst(
		 .clka				(clk				    )	//a clock, a port is used for read
        ,.ena				(ram_rden_a	            )	//enable
        ,.wea				(!ram_rden_a			)	//ena==1, wea=1:write; wea=0:read
        ,.addra				(ram_addr_a				)	//read address
        ,.dina				(64'b0				    )
        ,.douta				(ram_out_a              )   //read data from ram
        ,.clkb				(clk				    )	//a clock, a port is used for write
        ,.enb				(ram_wren_b             )   //enable
        ,.web				(ram_wren_b             )   //ena==1, wea=1:write; wea=0:read
        ,.addrb				(ram_addr_b				)   //write address
        ,.dinb				(ram_data_b             )   //write data to ram
        ,.doutb				(                       )
	);
`else
    ram_16_64 ram_16_64_inst(
		 .clka				(clk				    )	//a clock, a port is used for read
        ,.ena				(ram_rden_a	            )	//enable
        ,.wea				(!ram_rden_a			)	//ena==1, wea=1:write; wea=0:read
        ,.addra				(ram_addr_a				)	//read address
        ,.dina				(64'b0				    )
        ,.douta				(ram_out_a              )   //read data from ram
        ,.clkb				(clk				    )	//a clock, a port is used for write
        ,.enb				(ram_wren_b             )   //enable
        ,.web				(ram_wren_b             )   //ena==1, wea=1:write; wea=0:read
        ,.addrb				(ram_addr_b				)   //write address
        ,.dinb				(ram_data_b             )   //write data to ram
        ,.doutb				(                       )
	);
`endif

endmodule