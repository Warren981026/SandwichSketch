/*
 * @Filename: 
 * @Author: ws
 * @Description: top module
 * @Date: 2023-02-15 15:06:23
 * @LastEditTime: 2023-02-16 22:39:30
 * @Company: 662
 */

module ultrauss_top(
    /****************clock****************/
     input wire         clk
    ,input wire         rst_n

    /************input element************/
    ,input wire [63:0]  e_f
    ,input wire         valid               //represent whether e&f is valid

    /***********output element************/
    ,output wire        flag                //if element is inserted in part_3£¬flag=1
);

/**************generate ram**************/
`ifdef RAM_0_3125   //0.3125MB, ptr=13
    localparam  RAM_PTR_0 = 13,
                RAM_PTR_1 = 13,
                RAM_PTR_2 = 13,
                RAM_PTR_3 = 13,
                RAM_PTR_4 = 13;
    localparam  HASH_BASE_0 = 0,
                HASH_BASE_1 = 5,
                HASH_BASE_2 = 10,
                HASH_BASE_3 = 15,
                HASH_BASE_4 = 19; 

`elsif RAM_0_625    //0.625MB, ptr=14
    localparam  RAM_PTR_0 = 14,
                RAM_PTR_1 = 14,
                RAM_PTR_2 = 14,
                RAM_PTR_3 = 14,
                RAM_PTR_4 = 14;
    localparam  HASH_BASE_0 = 0,
                HASH_BASE_1 = 5,
                HASH_BASE_2 = 10,
                HASH_BASE_3 = 14,
                HASH_BASE_4 = 18;  

`elsif RAM_1_25     //1.25MB, ptr=15
    localparam  RAM_PTR_0 = 15,
                RAM_PTR_1 = 15,
                RAM_PTR_2 = 15,
                RAM_PTR_3 = 15,
                RAM_PTR_4 = 15;
    localparam  HASH_BASE_0 = 0,
                HASH_BASE_1 = 5,
                HASH_BASE_2 = 9,
                HASH_BASE_3 = 13,
                HASH_BASE_4 = 17;  
                  
`elsif RAM_2_5      //2.5MB, ptr=16
    localparam  RAM_PTR_0 = 16,
                RAM_PTR_1 = 16,
                RAM_PTR_2 = 16,
                RAM_PTR_3 = 16,
                RAM_PTR_4 = 16;
    localparam  HASH_BASE_0 = 0,
                HASH_BASE_1 = 4,
                HASH_BASE_2 = 8,
                HASH_BASE_3 = 12,
                HASH_BASE_4 = 16;
    
`else
    localparam  RAM_PTR_0 = 4,
                RAM_PTR_1 = 4,
                RAM_PTR_2 = 4,
                RAM_PTR_3 = 4,
                RAM_PTR_4 = 4;
    localparam  HASH_BASE_0 = 0,
                HASH_BASE_1 = 4,
                HASH_BASE_2 = 8,
                HASH_BASE_3 = 12,
                HASH_BASE_4 = 16;
`endif


wire    [63:0]  ef_x_crc[0:4];
wire            valid_x_crc[0:4];
wire    [95:0]  hashef_crc_x[0:4];
wire            valid_crc_x[0:4];

assign  ef_x_crc[0] = e_f;
assign  valid_x_crc[0] = valid;


generate 
    genvar i;
    for(i=0; i<5; i=i+1)begin: CRC_inst
        CRC32h_32bit CRC32_inst(
            .clk                (clk)
            ,.reset_n           (rst_n)
            ,.data              (ef_x_crc[i])
            ,.datavalid         (valid_x_crc[i])
            ,.data_nxt          (hashef_crc_x[i])
            ,.crcvalid          (valid_crc_x[i])
        );
    end
endgenerate


part_1 
#(
     .RAM_PTR           (RAM_PTR_0)
    ,.HASH_BASE         (HASH_BASE_0)
)
part_1_level_1(
     .clk               (clk)
    ,.rst_n             (rst_n)
    ,.hash_e_f          (hashef_crc_x[0])
    ,.valid             (valid_crc_x[0])
    ,.e_f_nxt           (ef_x_crc[1])
    ,.valid_nxt         (valid_x_crc[1])
);


part_1 
#(
     .RAM_PTR           (RAM_PTR_1)
    ,.HASH_BASE         (HASH_BASE_1)
)
part_1_level_2(
     .clk               (clk)
    ,.rst_n             (rst_n)
    ,.hash_e_f          (hashef_crc_x[1])
    ,.valid             (valid_crc_x[1])
    ,.e_f_nxt           (ef_x_crc[2])
    ,.valid_nxt         (valid_x_crc[2])
);


part_2 
#(
     .RAM_PTR           (RAM_PTR_2)
    ,.HASH_BASE         (HASH_BASE_2)
)
part_2_level_1(
     .clk               (clk)
    ,.rst_n             (rst_n)
    ,.hash_e_f          (hashef_crc_x[2])
    ,.valid             (valid_crc_x[2])
    ,.e_f_nxt           (ef_x_crc[3])
    ,.valid_nxt         (valid_x_crc[3])
);


part_2 
#(
     .RAM_PTR           (RAM_PTR_3)
    ,.HASH_BASE         (HASH_BASE_3)
)
part_2_level_2(
     .clk               (clk)
    ,.rst_n             (rst_n)
    ,.hash_e_f          (hashef_crc_x[3])
    ,.valid             (valid_crc_x[3])
    ,.e_f_nxt           (ef_x_crc[4])
    ,.valid_nxt         (valid_x_crc[4])
);


part_3 
#(
     .RAM_PTR           (RAM_PTR_4)
    ,.HASH_BASE         (HASH_BASE_4)
)
part3_inst(
     .clk               (clk)
    ,.rst_n             (rst_n)
    ,.hash_e_f          (hashef_crc_x[4])
    ,.valid             (valid_crc_x[4])
    ,.flag              (flag)
);


endmodule