/*
 * @Filename: 
 * @Author: ws
 * @Description: CocoSketch top module
 * @Date: 2023-02-25 09:18:59
 * @LastEditTime: 2023-02-25 09:31:35
 * @Company: 662
 */

module CocoSketch_top(
    /****************clock****************/
     input wire         clk
    ,input wire         rst_n

    /************input element************/
    ,input wire [63:0]  e_f
    ,input wire         valid               //represent whether e&f is valid

    /***********output element************/
    ,output wire        flag                //if element is inserted in part_3，flag=1    
);

`ifdef RAM_0_0625   //0.0625MB, ptr=13
    localparam  RAM_PTR = 13;
    localparam  HASH_BASE = 0; 

`elsif RAM_0_125    //0.125MB, ptr=14
    localparam  RAM_PTR = 14;
    localparam  HASH_BASE = 0;  

`elsif RAM_0_25     //0.25MB, ptr=15
    localparam  RAM_PTR = 15;
    localparam  HASH_BASE = 0;  
                  
`elsif RAM_0_5      //0.5MB, ptr=16
    localparam  RAM_PTR = 16;
    localparam  HASH_BASE = 0;
    
`else
    localparam  RAM_PTR = 4;
    localparam  HASH_BASE = 0;
`endif

wire    [95:0]  hashef_crc_x;
wire            valid_crc_x;

CRC32h_32bit CRC32_inst(
    .clk                (clk)
    ,.reset_n           (rst_n)
    ,.data              (e_f)
    ,.datavalid         (valid)
    ,.data_nxt          (hashef_crc_x)
    ,.crcvalid          (valid_crc_x)
);

operation 
#(
     .RAM_PTR           (RAM_PTR)
    ,.HASH_BASE         (HASH_BASE)
)
operation_inst(
     .clk               (clk)
    ,.rst_n             (rst_n)
    ,.hash_e_f          (hashef_crc_x)
    ,.valid             (valid_crc_x)
    ,.flag              (flag)
);

endmodule
