// *********************************************************************************
// Copyright (c) 2011 SAMSUNG Electronics, All rights reserved
//----------------------------------------------------------------------------------
//-- Project name : ORAN
//-- Filename     : comp_bf.v
//-- Author       : Youchul Shin
//-- Email        : youchul.shing@samsung.com
//-- Description  : Block floating compresssion module
//----------------------------------------------------------------------------------
//--     Date    |     By           |  Version | Change Description
//----------------------------------------------------------------------------------
//--  02-21-2019 | Youchul Shin     |    0.1   | Original Version
//----------------------------------------------------------------------------------
//--  11-22-2019 | Taeyoup Kim      |    0.2   | 1. udiqwidth extension 
//--             |                  |          | 2. find_exp algorithm correction 
//----------------------------------------------------------------------------------
//--  12-05-2019 | Taeyoup Kim      |    0.3   | udiqwidth extension : 15 ~ 7 bit
//----------------------------------------------------------------------------------
//--  09-17-2020 | Taeyoup Kim      |    0.3   | 1. i_comp_exp_offset added 
//----------------------------------------------------------------------------------
// *********************************************************************************
// latency : 19 clk
module comp_bf (
  input wire        clk_245                ,
  input wire        rst                    ,

  input wire        i_bf_comp_enable       ,
  input wire [15:0] i_bf_comp_data_i       , //sign extended bit
  input wire [15:0] i_bf_comp_data_q       , //sign extended bit
  input wire        i_bf_comp_rb_start_tic ,
  input wire [3:0]  i_bf_comp_udiqwidth    , //compress sample : 7~15
  input wire [4:0]  i_bf_comp_exp_offset   ,

  output reg        o_bf_comp_valid        ,
  output reg [15:0] o_bf_comp_data_i       ,
  output reg [15:0] o_bf_comp_data_q       ,
  output reg        o_bf_comp_exp_valid    ,
  output reg [3:0]  o_bf_comp_udiqwidth    ,
  output reg [3:0]  o_bf_comp_exp
);

localparam DLY_SIZE = 18;

//=========================================================
// signal
//=========================================================
integer i;
reg        r_bf_comp_enable_d       [0:DLY_SIZE-1];
reg [15:0] r_bf_comp_data_i_d       [0:DLY_SIZE-2];
reg [15:0] r_bf_comp_data_q_d       [0:DLY_SIZE-2];
reg        r_bf_comp_rb_start_tic;

reg [3:0]  r_bf_comp_udiqwidth_d    [0:DLY_SIZE-1];

reg        r_bf_comp_rb_end_tic;
reg        r_en_12;
reg [3:0]  r_cnt_12;

reg [3:0]  r_bf_comp_offset;  

wire       w_bf_comp_exp_valid;
reg        r_bf_comp_exp_valid;
wire [3:0] w_bf_comp_exp;
reg  [3:0] r_bf_comp_exp;

wire [15:0] w_round_1_i;
wire [15:0] w_round_1_q;
wire [14:0] w_round_2_i;
wire [14:0] w_round_2_q;
wire [13:0] w_round_3_i;
wire [13:0] w_round_3_q;
wire [12:0] w_round_4_i;
wire [12:0] w_round_4_q;
wire [11:0] w_round_5_i;
wire [11:0] w_round_5_q;
wire [10:0] w_round_6_i;
wire [10:0] w_round_6_q;
wire [9:0]  w_round_7_i;
wire [9:0]  w_round_7_q;
wire [8:0]  w_round_8_i;
wire [8:0]  w_round_8_q;
wire [7:0]  w_round_9_i;
wire [7:0]  w_round_9_q;

wire [5:0]  i_expTemp;
wire [4:0]  i_bf_comp_exp_offset_inv;

reg [15:0]  r_bf_comp_round_data_i;
reg [15:0]  r_bf_comp_round_data_q;

wire [6:0]  w_ssat_7_i;
wire [6:0]  w_ssat_7_q;
wire [7:0]  w_ssat_8_i;
wire [7:0]  w_ssat_8_q;
wire [8:0]  w_ssat_9_i;
wire [8:0]  w_ssat_9_q;
wire [9:0]  w_ssat_10_i;
wire [9:0]  w_ssat_10_q;
wire [10:0] w_ssat_11_i;
wire [10:0] w_ssat_11_q;
wire [11:0] w_ssat_12_i;
wire [11:0] w_ssat_12_q;
wire [12:0] w_ssat_13_i;
wire [12:0] w_ssat_13_q;
wire [13:0] w_ssat_14_i;
wire [13:0] w_ssat_14_q;
wire [14:0] w_ssat_15_i;
wire [14:0] w_ssat_15_q;


always @(posedge clk_245)
begin
    r_bf_comp_enable_d[0]   <= i_bf_comp_enable;
    r_bf_comp_rb_start_tic  <= i_bf_comp_rb_start_tic;
end

always @(posedge clk_245)
begin
    for(i=1;i<DLY_SIZE;i=i+1) begin
      r_bf_comp_enable_d[i]       <= r_bf_comp_enable_d[i-1];
    end
end

//IQ data
always @(posedge clk_245)
begin
  if(i_bf_comp_enable) begin
    r_bf_comp_data_i_d[0] <= i_bf_comp_data_i;
    r_bf_comp_data_q_d[0] <= i_bf_comp_data_q;
  end
end

always @(posedge clk_245)
begin
    for(i=1;i<DLY_SIZE-1;i=i+1) begin
    r_bf_comp_data_i_d[i] <= r_bf_comp_data_i_d[i-1];
    r_bf_comp_data_q_d[i] <= r_bf_comp_data_q_d[i-1];
    end
end

//udiqwidth
always @(posedge clk_245)
begin
  if(i_bf_comp_rb_start_tic) begin
    r_bf_comp_udiqwidth_d[0] <= i_bf_comp_udiqwidth;
  end
end

always @(posedge clk_245)
begin
    for(i=1;i<DLY_SIZE;i=i+1) begin
        r_bf_comp_udiqwidth_d[i]       <= r_bf_comp_udiqwidth_d[i-1];
    end
end

//=========================================================
// creat PRB end tic signal
//=========================================================

always @(posedge clk_245)
begin
  if(i_bf_comp_rb_start_tic)begin
    r_en_12 <= 1;
  end
  else if(r_cnt_12 == 11) begin
    r_en_12 <= 0;
  end
end

always @(posedge clk_245)
begin
  if(i_bf_comp_rb_start_tic) begin
    r_cnt_12 <= 0;
  end
  else begin
    r_cnt_12 <= r_cnt_12 + 1;
  end
end


always @(posedge clk_245)
begin
  if((r_en_12)&&(r_cnt_12 == 11)) begin
    r_bf_comp_rb_end_tic <= 1;
  end
  else begin
    r_bf_comp_rb_end_tic <= 0;
  end
end

//=========================================================
// creat exp offset
//=========================================================
always @(posedge clk_245)                       
begin                                           
  if(i_bf_comp_rb_start_tic) begin         
    case (i_bf_comp_udiqwidth)                  
       7 : r_bf_comp_offset <=  6;
       8 : r_bf_comp_offset <=  7;
       9 : r_bf_comp_offset <=  8;              
      10 : r_bf_comp_offset <=  9;              
      11 : r_bf_comp_offset <= 10;              
      12 : r_bf_comp_offset <= 11;              
      13 : r_bf_comp_offset <= 12;              
      14 : r_bf_comp_offset <= 13;              
      15 : r_bf_comp_offset <= 14;                  
      default : r_bf_comp_offset <= 15;         
    endcase                                     
  end                                           
end                                   


//=========================================================
// Find Exp
// latency : 16 clk -> find latency 5 + (12-1) (RE number)
//=========================================================
comp_bf_find_exp U_COMP_BF_FIND_EXP (
  .clk_245         ( clk_245),
  .rst             ( rst),
  .i_enable        ( r_bf_comp_enable_d[0]       ),
  .i_data_i        ( r_bf_comp_data_i_d[0]       ),
  .i_data_q        ( r_bf_comp_data_q_d[0]       ),
  .i_rb_start_tic  ( r_bf_comp_rb_start_tic      ), 
  .i_rb_end_tic    ( r_bf_comp_rb_end_tic        ),
  .i_offset        ( r_bf_comp_offset            ),
  .o_exp_valid     ( w_bf_comp_exp_valid         ),
  .o_exp           ( w_bf_comp_exp               )
);

//=========================================================
// >> exp R (round)
// exp : 0 ~ 9
//=========================================================
//exp = 1
comp_bf_round1 #(.IN_WIDTH(16), .TR_WIDTH(1)) U_COMP_BF_ROUND_1_I (
  .data_in     ( r_bf_comp_data_i_d[16]),
  .data_out    ( w_round_1_i           )
);

comp_bf_round1 #(.IN_WIDTH(16), .TR_WIDTH(1)) U_COMP_BF_ROUND_1_Q (
  .data_in     ( r_bf_comp_data_q_d[16]),
  .data_out    ( w_round_1_q           )
);

//exp = 2
comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(2)) U_COMP_BF_ROUND_2_I (
  .data_in     ( r_bf_comp_data_i_d[16]),
  .data_out    ( w_round_2_i           )
);

comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(2)) U_COMP_BF_ROUND_2_Q (
  .data_in     ( r_bf_comp_data_q_d[16]),
  .data_out    ( w_round_2_q           )
);

//exp = 3
comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(3)) U_COMP_BF_ROUND_3_I (
  .data_in     ( r_bf_comp_data_i_d[16]),
  .data_out    ( w_round_3_i           )
);

comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(3)) U_COMP_BF_ROUND_3_Q (
  .data_in     ( r_bf_comp_data_q_d[16]),
  .data_out    ( w_round_3_q           )
);

//exp = 4
comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(4)) U_COMP_BF_ROUND_4_I (
  .data_in     ( r_bf_comp_data_i_d[16]),
  .data_out    ( w_round_4_i           )
);

comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(4)) U_COMP_BF_ROUND_4_Q (
  .data_in     ( r_bf_comp_data_q_d[16]),
  .data_out    ( w_round_4_q           )
);

//exp = 5
comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(5)) U_COMP_BF_ROUND_5_I (
  .data_in     ( r_bf_comp_data_i_d[16]),
  .data_out    ( w_round_5_i           )
);

comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(5)) U_COMP_BF_ROUND_5_Q (
  .data_in     ( r_bf_comp_data_q_d[16]),
  .data_out    ( w_round_5_q           )
);

//exp = 6
comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(6)) U_COMP_BF_ROUND_6_I (
  .data_in     ( r_bf_comp_data_i_d[16]),
  .data_out    ( w_round_6_i           )
);

comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(6)) U_COMP_BF_ROUND_6_Q (
  .data_in     ( r_bf_comp_data_q_d[16]),
  .data_out    ( w_round_6_q           )
);

//exp = 7
comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(7)) U_COMP_BF_ROUND_7_I (
  .data_in     ( r_bf_comp_data_i_d[16]),
  .data_out    ( w_round_7_i           )
);

comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(7)) U_COMP_BF_ROUND_7_Q (
  .data_in     ( r_bf_comp_data_q_d[16]),
  .data_out    ( w_round_7_q           )
);

//exp = 8
comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(8)) U_COMP_BF_ROUND_8_I (
  .data_in     ( r_bf_comp_data_i_d[16]),
  .data_out    ( w_round_8_i           )
);

comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(8)) U_COMP_BF_ROUND_8_Q (
  .data_in     ( r_bf_comp_data_q_d[16]),
  .data_out    ( w_round_8_q           )
);

//exp = 9
comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(9)) U_COMP_BF_ROUND_9_I (
  .data_in     ( r_bf_comp_data_i_d[16]),
  .data_out    ( w_round_9_i           )
);

comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(9)) U_COMP_BF_ROUND_9_Q (
  .data_in     ( r_bf_comp_data_q_d[16]),
  .data_out    ( w_round_9_q           )
);

assign i_expTemp = $signed({1'b0, w_bf_comp_exp}) + $signed(i_bf_comp_exp_offset);
assign i_bf_comp_exp_offset_inv = (~i_bf_comp_exp_offset) + 1 ; 

//ROUND DATA-I
always @(posedge clk_245)
begin
  if(r_bf_comp_enable_d[16]) begin
  	if (i_expTemp[5] == 1'b0) begin
       case (w_bf_comp_exp)
         0 : r_bf_comp_round_data_i <= r_bf_comp_data_i_d[16];
         1 : r_bf_comp_round_data_i <= w_round_1_i;
         2 : r_bf_comp_round_data_i <= { {1{w_round_2_i[14]}}, w_round_2_i };
         3 : r_bf_comp_round_data_i <= { {2{w_round_3_i[13]}}, w_round_3_i };
         4 : r_bf_comp_round_data_i <= { {3{w_round_4_i[12]}}, w_round_4_i };
         5 : r_bf_comp_round_data_i <= { {4{w_round_5_i[11]}}, w_round_5_i };
         6 : r_bf_comp_round_data_i <= { {5{w_round_6_i[10]}}, w_round_6_i };
         7 : r_bf_comp_round_data_i <= { {6{w_round_7_i[9]}}, w_round_7_i };
         8 : r_bf_comp_round_data_i <= { {7{w_round_8_i[8]}}, w_round_8_i };
         9 : r_bf_comp_round_data_i <= { {8{w_round_9_i[7]}}, w_round_9_i };
         default : r_bf_comp_round_data_i <= r_bf_comp_data_i_d[16];
       endcase
    end
    else begin
       case (i_bf_comp_exp_offset_inv)
         0 : r_bf_comp_round_data_i <= r_bf_comp_data_i_d[16];
         1 : r_bf_comp_round_data_i <= w_round_1_i;
         2 : r_bf_comp_round_data_i <= { {1{w_round_2_i[14]}}, w_round_2_i };
         3 : r_bf_comp_round_data_i <= { {2{w_round_3_i[13]}}, w_round_3_i };
         4 : r_bf_comp_round_data_i <= { {3{w_round_4_i[12]}}, w_round_4_i };
         5 : r_bf_comp_round_data_i <= { {4{w_round_5_i[11]}}, w_round_5_i };
         6 : r_bf_comp_round_data_i <= { {5{w_round_6_i[10]}}, w_round_6_i };
         7 : r_bf_comp_round_data_i <= { {6{w_round_7_i[9]}}, w_round_7_i };
         8 : r_bf_comp_round_data_i <= { {7{w_round_8_i[8]}}, w_round_8_i };
         9 : r_bf_comp_round_data_i <= { {8{w_round_9_i[7]}}, w_round_9_i };
         default : r_bf_comp_round_data_i <= r_bf_comp_data_i_d[16];
       endcase
    end
  end
end

//ROUND DATA-Q
always @(posedge clk_245)
begin
  if(r_bf_comp_enable_d[16]) begin
  	if (i_expTemp[5] == 1'b0) begin
       case (w_bf_comp_exp)
         0 : r_bf_comp_round_data_q <= r_bf_comp_data_q_d[16];
         1 : r_bf_comp_round_data_q <= w_round_1_q;
         2 : r_bf_comp_round_data_q <= { {1{w_round_2_q[14]}}, w_round_2_q };
         3 : r_bf_comp_round_data_q <= { {2{w_round_3_q[13]}}, w_round_3_q };
         4 : r_bf_comp_round_data_q <= { {3{w_round_4_q[12]}}, w_round_4_q };
         5 : r_bf_comp_round_data_q <= { {4{w_round_5_q[11]}}, w_round_5_q };
         6 : r_bf_comp_round_data_q <= { {5{w_round_6_q[10]}}, w_round_6_q };
         7 : r_bf_comp_round_data_q <= { {6{w_round_7_q[9]}}, w_round_7_q };
         8 : r_bf_comp_round_data_q <= { {7{w_round_8_q[8]}}, w_round_8_q };
         9 : r_bf_comp_round_data_q <= { {8{w_round_9_q[7]}}, w_round_9_q };
        default : r_bf_comp_round_data_q <= r_bf_comp_data_q_d[16];
      endcase
    end                                
    else begin                         
       case (i_bf_comp_exp_offset_inv) 
         0 : r_bf_comp_round_data_q <= r_bf_comp_data_q_d[16];
         1 : r_bf_comp_round_data_q <= w_round_1_q;
         2 : r_bf_comp_round_data_q <= { {1{w_round_2_q[14]}}, w_round_2_q };
         3 : r_bf_comp_round_data_q <= { {2{w_round_3_q[13]}}, w_round_3_q };
         4 : r_bf_comp_round_data_q <= { {3{w_round_4_q[12]}}, w_round_4_q };
         5 : r_bf_comp_round_data_q <= { {4{w_round_5_q[11]}}, w_round_5_q };
         6 : r_bf_comp_round_data_q <= { {5{w_round_6_q[10]}}, w_round_6_q };
         7 : r_bf_comp_round_data_q <= { {6{w_round_7_q[9]}}, w_round_7_q };
         8 : r_bf_comp_round_data_q <= { {7{w_round_8_q[8]}}, w_round_8_q };
         9 : r_bf_comp_round_data_q <= { {8{w_round_9_q[7]}}, w_round_9_q };
        default : r_bf_comp_round_data_q <= r_bf_comp_data_q_d[16];
      endcase
    end 
  end
end

//=========================================================
// Sat*udiqWidth (ssat)
// udiqWidth : 7 ~ 15
//=========================================================

//udiqWidth = 7
comp_bf_ssat #(.IN_WIDTH(16), .OUT_WIDTH(7)) U_COMP_BF_SSAT_7_I (
  .data_in     ( r_bf_comp_round_data_i ),
  .data_out    ( w_ssat_7_i            )
);

comp_bf_ssat #(.IN_WIDTH(16), .OUT_WIDTH(7)) U_COMP_BF_SSAT_7_Q (
  .data_in     ( r_bf_comp_round_data_q ),
  .data_out    ( w_ssat_7_q            )
);

//udiqWidth = 8
comp_bf_ssat #(.IN_WIDTH(16), .OUT_WIDTH(8)) U_COMP_BF_SSAT_8_I (
  .data_in     ( r_bf_comp_round_data_i ),
  .data_out    ( w_ssat_8_i            )
);

comp_bf_ssat #(.IN_WIDTH(16), .OUT_WIDTH(8)) U_COMP_BF_SSAT_8_Q (
  .data_in     ( r_bf_comp_round_data_q ),
  .data_out    ( w_ssat_8_q            )
);

//udiqWidth = 9
comp_bf_ssat #(.IN_WIDTH(16), .OUT_WIDTH(9)) U_COMP_BF_SSAT_9_I (
  .data_in     ( r_bf_comp_round_data_i ),
  .data_out    ( w_ssat_9_i            )
);

comp_bf_ssat #(.IN_WIDTH(16), .OUT_WIDTH(9)) U_COMP_BF_SSAT_9_Q (
  .data_in     ( r_bf_comp_round_data_q ),
  .data_out    ( w_ssat_9_q            )
);

//udiqWidth = 10
comp_bf_ssat #(.IN_WIDTH(16), .OUT_WIDTH(10)) U_COMP_BF_SSAT_10_I (
  .data_in     ( r_bf_comp_round_data_i ),
  .data_out    ( w_ssat_10_i            )
);

comp_bf_ssat #(.IN_WIDTH(16), .OUT_WIDTH(10)) U_COMP_BF_SSAT_10_Q (
  .data_in     ( r_bf_comp_round_data_q ),
  .data_out    ( w_ssat_10_q            )
);

//udiqWidth = 11
comp_bf_ssat #(.IN_WIDTH(16), .OUT_WIDTH(11)) U_COMP_BF_SSAT_11_I (
  .data_in     ( r_bf_comp_round_data_i ),
  .data_out    ( w_ssat_11_i            )
);

comp_bf_ssat #(.IN_WIDTH(16), .OUT_WIDTH(11)) U_COMP_BF_SSAT_11_Q (
  .data_in     ( r_bf_comp_round_data_q ),
  .data_out    ( w_ssat_11_q            )
);

//udiqWidth = 12
comp_bf_ssat #(.IN_WIDTH(16), .OUT_WIDTH(12)) U_COMP_BF_SSAT_12_I (
  .data_in     ( r_bf_comp_round_data_i ),
  .data_out    ( w_ssat_12_i            )
);

comp_bf_ssat #(.IN_WIDTH(16), .OUT_WIDTH(12)) U_COMP_BF_SSAT_12_Q (
  .data_in     ( r_bf_comp_round_data_q ),
  .data_out    ( w_ssat_12_q            )
);

//udiqWidth = 13
comp_bf_ssat #(.IN_WIDTH(16), .OUT_WIDTH(13)) U_COMP_BF_SSAT_13_I (
  .data_in     ( r_bf_comp_round_data_i ),
  .data_out    ( w_ssat_13_i            )
);

comp_bf_ssat #(.IN_WIDTH(16), .OUT_WIDTH(13)) U_COMP_BF_SSAT_13_Q (
  .data_in     ( r_bf_comp_round_data_q ),
  .data_out    ( w_ssat_13_q            )
);

//udiqWidth = 14
comp_bf_ssat #(.IN_WIDTH(16), .OUT_WIDTH(14)) U_COMP_BF_SSAT_14_I (
  .data_in     ( r_bf_comp_round_data_i ),
  .data_out    ( w_ssat_14_i            )
);

comp_bf_ssat #(.IN_WIDTH(16), .OUT_WIDTH(14)) U_COMP_BF_SSAT_14_Q (
  .data_in     ( r_bf_comp_round_data_q ),
  .data_out    ( w_ssat_14_q            )
);

//udiqWidth = 15
comp_bf_ssat #(.IN_WIDTH(16), .OUT_WIDTH(15)) U_COMP_BF_SSAT_15_I (
  .data_in     ( r_bf_comp_round_data_i ),
  .data_out    ( w_ssat_15_i            )
);

comp_bf_ssat #(.IN_WIDTH(16), .OUT_WIDTH(15)) U_COMP_BF_SSAT_15_Q (
  .data_in     ( r_bf_comp_round_data_q ),
  .data_out    ( w_ssat_15_q            )
);

//ssat DATA-I
always @(posedge clk_245)
begin
  if(r_bf_comp_enable_d[17]) begin
    case (r_bf_comp_udiqwidth_d[17])
       7 : o_bf_comp_data_i <= { {9{w_ssat_7_i[6]}},  w_ssat_7_i };
       8 : o_bf_comp_data_i <= { {8{w_ssat_8_i[7]}},  w_ssat_8_i };
       9 : o_bf_comp_data_i <= { {7{w_ssat_9_i[8]}},  w_ssat_9_i };
      10 : o_bf_comp_data_i <= { {6{w_ssat_10_i[9]}},  w_ssat_10_i };
      11 : o_bf_comp_data_i <= { {5{w_ssat_11_i[10]}}, w_ssat_11_i };
      12 : o_bf_comp_data_i <= { {4{w_ssat_12_i[11]}}, w_ssat_12_i };
      13 : o_bf_comp_data_i <= { {3{w_ssat_13_i[12]}}, w_ssat_13_i };
      14 : o_bf_comp_data_i <= { {2{w_ssat_14_i[13]}}, w_ssat_14_i };
      15 : o_bf_comp_data_i <= { {1{w_ssat_15_i[14]}}, w_ssat_15_i };
      default : o_bf_comp_data_i <= r_bf_comp_round_data_i;
    endcase
  end
end

//ssat DATA-Q
always @(posedge clk_245)
begin
  if(r_bf_comp_enable_d[17]) begin
    case (r_bf_comp_udiqwidth_d[17])
       7 : o_bf_comp_data_q <= { {9{w_ssat_7_q[6]}},  w_ssat_7_q };
       8 : o_bf_comp_data_q <= { {8{w_ssat_8_q[7]}},  w_ssat_8_q };
       9 : o_bf_comp_data_q <= { {7{w_ssat_9_q[8]}},  w_ssat_9_q };
      10 : o_bf_comp_data_q <= { {6{w_ssat_10_q[9]}},  w_ssat_10_q };
      11 : o_bf_comp_data_q <= { {5{w_ssat_11_q[10]}}, w_ssat_11_q };
      12 : o_bf_comp_data_q <= { {4{w_ssat_12_q[11]}}, w_ssat_12_q };
      13 : o_bf_comp_data_q <= { {3{w_ssat_13_q[12]}}, w_ssat_13_q };
      14 : o_bf_comp_data_q <= { {2{w_ssat_14_q[13]}}, w_ssat_14_q };
      15 : o_bf_comp_data_q <= { {1{w_ssat_15_q[14]}}, w_ssat_15_q };
      default : o_bf_comp_data_q <= r_bf_comp_round_data_q;
    endcase
  end
end

//=========================================================
// output signal expect DATA-IQ
// sync. with output data and vlaid signal
//=========================================================
//data valid
always @(posedge clk_245)
begin
    o_bf_comp_valid <= r_bf_comp_enable_d[17];
    o_bf_comp_udiqwidth <= r_bf_comp_udiqwidth_d[17]; 
end

//exponent
always @(posedge clk_245)
begin
    r_bf_comp_exp_valid    <= w_bf_comp_exp_valid;
    o_bf_comp_exp_valid    <= r_bf_comp_exp_valid;

  	if (i_expTemp[5] == 1'b0) begin
       r_bf_comp_exp    <= i_expTemp[3:0];
    end
    else begin
       r_bf_comp_exp    <= 0;
    end  	
    o_bf_comp_exp    <= r_bf_comp_exp;
end

endmodule