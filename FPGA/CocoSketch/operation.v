/*
 * @Filename: 
 * @Author: ws
 * @Description: operate for value & key part
 * @Date: 2023-02-24 22:27:45
 * @LastEditTime: 2023-02-25 10:46:45
 * @Company: 662
 */

module operation
    #(parameter RAM_PTR=10,
                HASH_BASE=0)(
    /****************clock****************/
     input wire         clk
    ,input wire         rst_n

    /************input element************/
    ,input wire [95:0]  hash_e_f  
    ,input wire         valid

    /***********output element************/
    ,output reg         flag
);


/*******************ram*******************/
//a port:only read; b port:only write
//X_value: operate value_part's RAM
reg     [RAM_PTR-1:0]   ram_addr_value_a;
reg     [31:0]          ram_data_value_a;
reg                     ram_wren_value_a;
reg                     ram_rden_value_a;
wire    [31:0]          ram_out_value_a;
reg     [RAM_PTR-1:0]   ram_addr_value_b;
reg     [31:0]          ram_data_value_b;
reg                     ram_wren_value_b;
reg                     ram_rden_value_b;
wire    [31:0]          ram_out_value_b;
//X_value: operate key_part's RAM
reg     [RAM_PTR-1:0]   ram_addr_key_a;
reg     [31:0]          ram_data_key_a;
reg                     ram_wren_key_a;
reg                     ram_rden_key_a;
wire    [31:0]          ram_out_key_a;
reg     [RAM_PTR-1:0]   ram_addr_key_b;
reg     [31:0]          ram_data_key_b;
reg                     ram_wren_key_b;
reg                     ram_rden_key_b;
wire    [31:0]          ram_out_key_b;

/*************control signal*************/
reg     [95:0]  hash_e_f2;
reg             valid2;
reg     [95:0]  hash_e_f3;
reg             valid3;
reg     [95:0]  hash_e_f4;
reg             valid4;

reg     [31:0]  random_number;
reg     [31:0]  ram_data_value;

/**************main logic***************/
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        flag <= 1'b0;

        ram_addr_value_a <= {(RAM_PTR){1'b0}};
        ram_data_value_a <= 32'b0;
        ram_wren_value_a <= 1'b0;
        ram_rden_value_a <= 1'b0;
        ram_addr_value_b <= {(RAM_PTR){1'b0}};
        ram_data_value_b <= 32'b0;
        ram_wren_value_b <= 1'b0;
        ram_rden_value_b <= 1'b0;
        ram_addr_key_a <= {(RAM_PTR){1'b0}};
        ram_data_key_a <= 32'b0;
        ram_wren_key_a <= 1'b0;
        ram_rden_key_a <= 1'b0;
        ram_addr_key_b <= {(RAM_PTR){1'b0}};
        ram_data_key_b <= 32'b0;
        ram_wren_key_b <= 1'b0;
        ram_rden_key_b <= 1'b0;

        hash_e_f2 <= 96'b0;
        valid2 <= 1'b0;
        hash_e_f3 <= 96'b0;
        valid3 <= 1'b0;
        hash_e_f4 <= 96'b0;
        valid4 <= 1'b0;

        random_number <= 32'b0;
        ram_data_value <= 32'b0;
        //ram_data_key <= 32'b0;
    end

    else begin
        hash_e_f2 <= hash_e_f;
        valid2 <= valid;
        hash_e_f3 <= hash_e_f2;
        valid3 <= valid2;
        hash_e_f4 <= hash_e_f3;
        valid4 <= valid3;

        ram_data_value <= ram_out_value_a;

        if(valid)begin
            ram_addr_value_a <= hash_e_f[HASH_BASE+RAM_PTR-1+64:HASH_BASE+64];
            ram_data_value_a <= 32'b0;
            ram_wren_value_a <= 1'b0;
            ram_rden_value_a <= 1'b1;
            ram_addr_key_a <= hash_e_f[HASH_BASE+RAM_PTR-1+64:HASH_BASE+64];
            ram_data_key_a <= 32'b0;
            ram_wren_key_a <= 1'b0;
            ram_rden_key_a <= 1'b1;
        end
        else begin
            ram_addr_value_a <= {(RAM_PTR){1'b0}};
            ram_data_value_a <= 32'b0;
            ram_wren_value_a <= 1'b0;
            ram_rden_value_a <= 1'b0;
            ram_addr_key_a <= {(RAM_PTR){1'b0}};
            ram_data_key_a <= 32'b0;
            ram_wren_key_a <= 1'b0;
            ram_rden_key_a <= 1'b0;              
        end

        if(valid3)begin
            //empty
            if(32'b0 == ram_out_key_a)begin
                random_number <= 32'b0;
            end
            else begin
                random_number <= (hash_e_f3[31:0]>>2) + ram_data_value;
            end
        end
        else begin
            random_number <= 32'b0;
        end

        if(valid4)begin
            flag <= 1'b1;

            //operate value_part
            ram_addr_value_b <= hash_e_f4[HASH_BASE+RAM_PTR-1+64:HASH_BASE+64];
            ram_data_value_b <= hash_e_f4[31:0] + ram_data_value;
            ram_wren_value_b <= 1'b1;
            ram_rden_value_b <= 1'b0;

            //operate key_part
            if(random_number <= (hash_e_f4[31:0]+ram_data_value))begin
                ram_addr_key_b <= hash_e_f4[HASH_BASE+RAM_PTR-1+64:HASH_BASE+64];
                ram_data_key_b <= hash_e_f4[63:32];
                ram_wren_key_b <= 1'b1;
                ram_rden_key_b <= 1'b0;
            end
            else begin
                ram_addr_key_b <= {(RAM_PTR){1'b0}};
                ram_data_key_b <= 32'b0;
                ram_wren_key_b <= 1'b0;
                ram_rden_key_b <= 1'b0;
            end           
        end
        else begin
            ram_addr_value_b <= {(RAM_PTR){1'b0}};
            ram_data_value_b <= 32'b0;
            ram_wren_value_b <= 1'b0;
            ram_rden_value_b <= 1'b0;
            ram_addr_key_b <= {(RAM_PTR){1'b0}};
            ram_data_key_b <= 32'b0;
            ram_wren_key_b <= 1'b0;
            ram_rden_key_b <= 1'b0;

            flag <= 1'b0;           
        end        
    end
end

/**************generate ram**************/
`ifdef RAM_0_0625
    ram_8192_32 ram_8192_32_value(
		 .clka				(clk				    )	//a clock, a port is used for read
        ,.ena				(ram_rden_value_a	    )	//enable
        ,.wea				(!ram_rden_value_a		)	//ena==1, wea=1:write; wea=0:read
        ,.addra				(ram_addr_value_a		)	//read address
        ,.dina				(32'b0				    )
        ,.douta				(ram_out_value_a        )   //read data from ram
        ,.clkb				(clk				    )	//a clock, a port is used for write
        ,.enb				(ram_wren_value_b       )   //enable
        ,.web				(ram_wren_value_b       )   //ena==1, wea=1:write; wea=0:read
        ,.addrb				(ram_addr_value_b		)   //write address
        ,.dinb				(ram_data_value_b       )   //write data to ram
        ,.doutb				(                       )
	);
    ram_8192_32 ram_8192_32_key(
		 .clka				(clk				    )	//a clock, a port is used for read
        ,.ena				(ram_rden_key_a	        )	//enable
        ,.wea				(!ram_rden_key_a		)	//ena==1, wea=1:write; wea=0:read
        ,.addra				(ram_addr_key_a		    )	//read address
        ,.dina				(32'b0				    )
        ,.douta				(ram_out_key_a          )   //read data from ram
        ,.clkb				(clk				    )	//a clock, a port is used for write
        ,.enb				(ram_wren_key_b         )   //enable
        ,.web				(ram_wren_key_b         )   //ena==1, wea=1:write; wea=0:read
        ,.addrb				(ram_addr_key_b		    )   //write address
        ,.dinb				(ram_data_key_b         )   //write data to ram
        ,.doutb				(                       )
	);
`elsif RAM_0_125
    ram_16384_32 ram_16384_32_value(
		 .clka				(clk				    )	//a clock, a port is used for read
        ,.ena				(ram_rden_value_a	    )	//enable
        ,.wea				(!ram_rden_value_a		)	//ena==1, wea=1:write; wea=0:read
        ,.addra				(ram_addr_value_a		)	//read address
        ,.dina				(32'b0				    )
        ,.douta				(ram_out_value_a        )   //read data from ram
        ,.clkb				(clk				    )	//a clock, a port is used for write
        ,.enb				(ram_wren_value_b       )   //enable
        ,.web				(ram_wren_value_b       )   //ena==1, wea=1:write; wea=0:read
        ,.addrb				(ram_addr_value_b		)   //write address
        ,.dinb				(ram_data_value_b       )   //write data to ram
        ,.doutb				(                       )
	);
    ram_16384_32 ram_16384_32_key(
		 .clka				(clk				    )	//a clock, a port is used for read
        ,.ena				(ram_rden_key_a	        )	//enable
        ,.wea				(!ram_rden_key_a		)	//ena==1, wea=1:write; wea=0:read
        ,.addra				(ram_addr_key_a		    )	//read address
        ,.dina				(32'b0				    )
        ,.douta				(ram_out_key_a          )   //read data from ram
        ,.clkb				(clk				    )	//a clock, a port is used for write
        ,.enb				(ram_wren_key_b         )   //enable
        ,.web				(ram_wren_key_b         )   //ena==1, wea=1:write; wea=0:read
        ,.addrb				(ram_addr_key_b		    )   //write address
        ,.dinb				(ram_data_key_b         )   //write data to ram
        ,.doutb				(                       )
	);
`elsif RAM_0_25
    ram_32768_32 ram_32768_32_value(
		 .clka				(clk				    )	//a clock, a port is used for read
        ,.ena				(ram_rden_value_a	    )	//enable
        ,.wea				(!ram_rden_value_a		)	//ena==1, wea=1:write; wea=0:read
        ,.addra				(ram_addr_value_a		)	//read address
        ,.dina				(32'b0				    )
        ,.douta				(ram_out_value_a        )   //read data from ram
        ,.clkb				(clk				    )	//a clock, a port is used for write
        ,.enb				(ram_wren_value_b       )   //enable
        ,.web				(ram_wren_value_b       )   //ena==1, wea=1:write; wea=0:read
        ,.addrb				(ram_addr_value_b		)   //write address
        ,.dinb				(ram_data_value_b       )   //write data to ram
        ,.doutb				(                       )
	);
    ram_32768_32 ram_32768_32_key(
		 .clka				(clk				    )	//a clock, a port is used for read
        ,.ena				(ram_rden_key_a	        )	//enable
        ,.wea				(!ram_rden_key_a		)	//ena==1, wea=1:write; wea=0:read
        ,.addra				(ram_addr_key_a		    )	//read address
        ,.dina				(32'b0				    )
        ,.douta				(ram_out_key_a          )   //read data from ram
        ,.clkb				(clk				    )	//a clock, a port is used for write
        ,.enb				(ram_wren_key_b         )   //enable
        ,.web				(ram_wren_key_b         )   //ena==1, wea=1:write; wea=0:read
        ,.addrb				(ram_addr_key_b		    )   //write address
        ,.dinb				(ram_data_key_b         )   //write data to ram
        ,.doutb				(                       )
	);
`elsif RAM_0_5
    ram_65536_32 ram_65536_32_value(
		 .clka				(clk				    )	//a clock, a port is used for read
        ,.ena				(ram_rden_value_a	    )	//enable
        ,.wea				(!ram_rden_value_a		)	//ena==1, wea=1:write; wea=0:read
        ,.addra				(ram_addr_value_a		)	//read address
        ,.dina				(32'b0				    )
        ,.douta				(ram_out_value_a        )   //read data from ram
        ,.clkb				(clk				    )	//a clock, a port is used for write
        ,.enb				(ram_wren_value_b       )   //enable
        ,.web				(ram_wren_value_b       )   //ena==1, wea=1:write; wea=0:read
        ,.addrb				(ram_addr_value_b		)   //write address
        ,.dinb				(ram_data_value_b       )   //write data to ram
        ,.doutb				(                       )
	);
    ram_65536_32 ram_65536_32_key(
		 .clka				(clk				    )	//a clock, a port is used for read
        ,.ena				(ram_rden_key_a	        )	//enable
        ,.wea				(!ram_rden_key_a		)	//ena==1, wea=1:write; wea=0:read
        ,.addra				(ram_addr_key_a		    )	//read address
        ,.dina				(32'b0				    )
        ,.douta				(ram_out_key_a          )   //read data from ram
        ,.clkb				(clk				    )	//a clock, a port is used for write
        ,.enb				(ram_wren_key_b         )   //enable
        ,.web				(ram_wren_key_b         )   //ena==1, wea=1:write; wea=0:read
        ,.addrb				(ram_addr_key_b		    )   //write address
        ,.dinb				(ram_data_key_b         )   //write data to ram
        ,.doutb				(                       )
	);
`else
    ram_16_32 ram_16_32_value(
		 .clka				(clk				    )	//a clock, a port is used for read
        ,.ena				(ram_rden_value_a	    )	//enable
        ,.wea				(!ram_rden_value_a		)	//ena==1, wea=1:write; wea=0:read
        ,.addra				(ram_addr_value_a		)	//read address
        ,.dina				(32'b0				    )
        ,.douta				(ram_out_value_a        )   //read data from ram
        ,.clkb				(clk				    )	//a clock, a port is used for write
        ,.enb				(ram_wren_value_b       )   //enable
        ,.web				(ram_wren_value_b       )   //ena==1, wea=1:write; wea=0:read
        ,.addrb				(ram_addr_value_b		)   //write address
        ,.dinb				(ram_data_value_b       )   //write data to ram
        ,.doutb				(                       )
	);
    ram_16_32 ram_16_32_key(
		 .clka				(clk				    )	//a clock, a port is used for read
        ,.ena				(ram_rden_key_a	        )	//enable
        ,.wea				(!ram_rden_key_a		)	//ena==1, wea=1:write; wea=0:read
        ,.addra				(ram_addr_key_a		    )	//read address
        ,.dina				(32'b0				    )
        ,.douta				(ram_out_key_a          )   //read data from ram
        ,.clkb				(clk				    )	//a clock, a port is used for write
        ,.enb				(ram_wren_key_b         )   //enable
        ,.web				(ram_wren_key_b         )   //ena==1, wea=1:write; wea=0:read
        ,.addrb				(ram_addr_key_b		    )   //write address
        ,.dinb				(ram_data_key_b         )   //write data to ram
        ,.doutb				(                       )
	);
`endif

endmodule

