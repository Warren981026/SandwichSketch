// ****************************************************************************
// Copyright		: 	NUDT.
// ============================================================================
// FILE NAME		:	CRC32_32bit.v
// CREATE DATE		:	2021-11-4
// AUTHOR			:	xiongzhiting
// AUTHOR'S EMAIL	:	
// AUTHOR'S TEL		:	
// ============================================================================
// RELEASE 	HISTORY		-------------------------------------------------------
// VERSION 			DATE				AUTHOR				DESCRIPTION
// 0.0	   		2021-11-4			xiongzhiting			Original Verison
// ============================================================================
// KEYWORDS 		: 	CRC32 Hash algorithm
// ----------------------------------------------------------------------------
// PURPOSE 			: 	hash algorithm
// ----------------------------------------------------------------------------
// ============================================================================
// REUSE ISSUES
// Reset Strategy	:	Async clear,active low
// Clock Domains	:	clk
// Critical TiminG	:	N/A
// Instantiations	:	N/A
// Synthesizable	:	N/A
// Others			:	N/A
// ****************************************************************************
module CRC32h_32bit(
	input		wire				clk,
	input		wire				reset_n,
	//-----------input key-------------//    
	input		wire	[63:0]		data,
	input		wire				datavalid,
	//-----------output hash value----//
    output      reg     [95:0]      data_nxt,
	output		reg					crcvalid
);
   
//----------------------reg--------------------------//
	wire		[31:0]	checksum_w;
	reg			[31:0]	checksum_reg;
	reg					crcvalid_reg;
	reg			[64:0]	ef_reg;

/************************************code**********************************/ 
always @ (posedge clk or negedge reset_n)
begin
    if (!reset_n)
    begin
        data_nxt[95:64] <= 32'hffffffff;
        data_nxt[63:0]  <= 64'b0;
		checksum_reg	<= 32'hffffffff;
        crcvalid_reg	<= 1'b0;
		crcvalid		<= 1'b0;
		ef_reg			<= 64'b0;
    end
    else begin
        ef_reg          <= data[63:0];
        data_nxt[63:0]  <= ef_reg;

		if(datavalid)
		begin//1 cycle, get the value of data
			checksum_reg	<= checksum_w;
			data_nxt[95:64]	<= checksum_reg;
			crcvalid		<= crcvalid_reg;
			crcvalid_reg	<= 1'b1;

		end
		else//data transmit is over
		begin
			checksum_reg	<= 32'hffffffff;
			data_nxt[95:64]	<= checksum_reg;
			crcvalid		<= crcvalid_reg;
			crcvalid_reg	<= 1'b0;

		end
	end
end
	wire		[31:0]	checksum_tmp;

	assign		checksum_w	= ~{checksum_tmp[24],checksum_tmp[25]	,checksum_tmp[26]	,checksum_tmp[27]	,checksum_tmp[28]	,checksum_tmp[29]	,checksum_tmp[30]	,checksum_tmp[31],
								checksum_tmp[16],checksum_tmp[17]	,checksum_tmp[18]	,checksum_tmp[19]	,checksum_tmp[20]	,checksum_tmp[21]	,checksum_tmp[22]	,checksum_tmp[23],
								checksum_tmp[8]	,checksum_tmp[9]	,checksum_tmp[10]	,checksum_tmp[11]	,checksum_tmp[12]	,checksum_tmp[13]	,checksum_tmp[14]	,checksum_tmp[15],
								checksum_tmp[0]	,checksum_tmp[1]	,checksum_tmp[2]	,checksum_tmp[3]	,checksum_tmp[4]	,checksum_tmp[5]	,checksum_tmp[6]	,checksum_tmp[7]};
	wire		[31:0]	data_tmp;
assign data_tmp = {
					data[24+32]	 ,data[25+32]	,data[26+32]	,data[27+32]	,data[28+32]	,data[29+32]	,data[30+32]	,data[31+32],
					data[16+32]	 ,data[17+32]	,data[18+32]	,data[19+32]	,data[20+32]	,data[21+32]	,data[22+32]	,data[23+32],
					data[8+32] 	 ,data[9+32]	,data[10+32]	,data[11+32]	,data[12+32]	,data[13+32]	,data[14+32]	,data[15+32],
					data[0+32] 	 ,data[1+32]	,data[2+32]	,data[3+32]	,data[4+32]	,data[5+32]	,data[6+32]	,data[7+32]
                   };	
CRC32_D32 CRC32_D32_inst(.data_in(data_tmp),.crc_last(32'hffffffff),.crc_out(checksum_tmp));
endmodule
