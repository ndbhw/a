// *********************************************************************************
// Copyright (c) 2011 SAMSUNG Electronics, All rights reserved
//----------------------------------------------------------------------------------
//-- Project name : ORAN
//-- Filename     : decomp.v
//-- Author       : Youchul Shin
//-- Email        : youchul.shing@samsung.com
//-- Description  : decompresssion top module
//----------------------------------------------------------------------------------
//--     Date    |     By           |  Version | Change Description
//----------------------------------------------------------------------------------
//--  02-22-2019 | Youchul Shin     |    0.1   | Original Version
//----------------------------------------------------------------------------------
//--  11-22-2019 | Taeyoup Kim      |    0.2   | 1. udiqwidth extension 
//--             |                  |          | 2. find_exp algorithm correction 
//----------------------------------------------------------------------------------
//--  12-05-2019 | Taeyoup Kim      |    0.3   | udiqwidth extension : 15 ~ 7 bit
//----------------------------------------------------------------------------------
//--  09-17-2020 | Taeyoup Kim      |    0.4   | i_decomp_exp_offset added
//----------------------------------------------------------------------------------
// *********************************************************************************
//latency : 1 clk
module decomp (
  input wire        clk_245               ,
  input wire        rst                   ,
  input wire [1:0]  i_decomp_mode         , //0:bypass, 1:block floating, 2:modulation compress

  //decompress input 
  input wire        i_decomp_enable       ,
  input wire [15:0] i_decomp_data_i       , //sign extended bit
  input wire [15:0] i_decomp_data_q       , //sign extended bit

  input wire        i_decomp_rb_start_tic ,
  input wire [3:0]  i_decomp_exp          , //for BF decomp
  input wire [4:0]  i_decomp_exp_offset   , //for BF decomp
    //input wire        i_mc_csf            //for MC decomp
  //input wire [2:0]  i_modulation          ,
  //input wire [14:0] i_mod_comp_scaler     ,
  //input wire [11:0] i_mc_scale_remask     ,
  //input wire [12:0] i_mc_scale_offset     ,
  input wire [7:0]  i_decomp_frame_id     ,
  input wire [3:0]  i_decomp_subframe_id  ,
  input wire [5:0]  i_decomp_slot_id      ,
  input wire [5:0]  i_decomp_symbol_id    ,
  input wire [19:0] i_decomp_user         ,

  //decompress output
  output reg        o_decomp_valid        , 
  output reg [15:0] o_decomp_data_i       , 
  output reg [15:0] o_decomp_data_q       , 
  output reg        o_decomp_rb_start_tic , 
  output reg [1:0]  o_decomp_mode         ,

  output reg [7:0]  o_decomp_frame_id     ,
  output reg [3:0]  o_decomp_subframe_id  ,
  output reg [5:0]  o_decomp_slot_id      ,
  output reg [5:0]  o_decomp_symbol_id    ,
  output reg [19:0] o_decomp_user         
);

wire [5:0] shift_value;
wire [5:0] shift_value_R;

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
wire [6:0]  w_round_10_i;
wire [6:0]  w_round_10_q;

//=========================================================
// block floating decompression mode ( mode = 1 )
//=========================================================


always @(posedge clk_245)
begin
     o_decomp_valid        <= i_decomp_enable;                    
     o_decomp_rb_start_tic <= i_decomp_rb_start_tic;
     o_decomp_mode         <= i_decomp_mode;
end


//=========================================================
// << exp
//=========================================================

assign shift_value   = $signed({1'b0, i_decomp_exp}) - $signed(i_decomp_exp_offset);
assign shift_value_R = (~shift_value) + 1 ; 

//shift_value_R = 1
comp_bf_round1 #(.IN_WIDTH(16), .TR_WIDTH(1)) U_COMP_BF_ROUND_1_I (
  .data_in     ( i_decomp_data_i       ),
  .data_out    ( w_round_1_i           )
);

comp_bf_round1 #(.IN_WIDTH(16), .TR_WIDTH(1)) U_COMP_BF_ROUND_1_Q (
  .data_in     ( i_decomp_data_q       ),
  .data_out    ( w_round_1_q           )
);

//shift_value_R = 2
comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(2)) U_COMP_BF_ROUND_2_I (
  .data_in     ( i_decomp_data_i       ),
  .data_out    ( w_round_2_i           )
);

comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(2)) U_COMP_BF_ROUND_2_Q (
  .data_in     ( i_decomp_data_q       ),
  .data_out    ( w_round_2_q           )
);

//shift_value_R = 3
comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(3)) U_COMP_BF_ROUND_3_I (
  .data_in     ( i_decomp_data_i       ),
  .data_out    ( w_round_3_i           )
);

comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(3)) U_COMP_BF_ROUND_3_Q (
  .data_in     ( i_decomp_data_q       ),
  .data_out    ( w_round_3_q           )
);

//shift_value_R = 4
comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(4)) U_COMP_BF_ROUND_4_I (
  .data_in     ( i_decomp_data_i       ),
  .data_out    ( w_round_4_i           )
);

comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(4)) U_COMP_BF_ROUND_4_Q (
  .data_in     ( i_decomp_data_q       ),
  .data_out    ( w_round_4_q           )
);

//shift_value_R = 5
comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(5)) U_COMP_BF_ROUND_5_I (
  .data_in     ( i_decomp_data_i       ),
  .data_out    ( w_round_5_i           )
);

comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(5)) U_COMP_BF_ROUND_5_Q (
  .data_in     ( i_decomp_data_q       ),
  .data_out    ( w_round_5_q           )
);

//shift_value_R = 6
comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(6)) U_COMP_BF_ROUND_6_I (
  .data_in     ( i_decomp_data_i       ),
  .data_out    ( w_round_6_i           )
);

comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(6)) U_COMP_BF_ROUND_6_Q (
  .data_in     ( i_decomp_data_q       ),
  .data_out    ( w_round_6_q           )
);

//shift_value_R = 7
comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(7)) U_COMP_BF_ROUND_7_I (
  .data_in     ( i_decomp_data_i       ),
  .data_out    ( w_round_7_i           )
);

comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(7)) U_COMP_BF_ROUND_7_Q (
  .data_in     ( i_decomp_data_q       ),
  .data_out    ( w_round_7_q           )
);

//shift_value_R = 8
comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(8)) U_COMP_BF_ROUND_8_I (
  .data_in     ( i_decomp_data_i       ),
  .data_out    ( w_round_8_i           )
);

comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(8)) U_COMP_BF_ROUND_8_Q (
  .data_in     ( i_decomp_data_q       ),
  .data_out    ( w_round_8_q           )
);

//shift_value_R = 9
comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(9)) U_COMP_BF_ROUND_9_I (
  .data_in     ( i_decomp_data_i       ),
  .data_out    ( w_round_9_i           )
);

comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(9)) U_COMP_BF_ROUND_9_Q (
  .data_in     ( i_decomp_data_q       ),
  .data_out    ( w_round_9_q           )
);

//shift_value_R = 10
comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(10)) U_COMP_BF_ROUND_10_I (
  .data_in     ( i_decomp_data_i       ),
  .data_out    ( w_round_10_i          )
);

comp_bf_round #(.IN_WIDTH(16), .TR_WIDTH(10)) U_COMP_BF_ROUND_10_Q (
  .data_in     ( i_decomp_data_q       ),
  .data_out    ( w_round_10_q          )
);


//data_I
always @(posedge clk_245)
begin
  if(i_decomp_enable) begin
    if(shift_value[5] == 1'b0) begin
      case (shift_value[3:0])
           1 : o_decomp_data_i <= {i_decomp_data_i[14:0],  1'b0};
           2 : o_decomp_data_i <= {i_decomp_data_i[13:0],  2'b0};
           3 : o_decomp_data_i <= {i_decomp_data_i[12:0],  3'b0};
           4 : o_decomp_data_i <= {i_decomp_data_i[11:0],  4'b0};
           5 : o_decomp_data_i <= {i_decomp_data_i[10:0],  5'b0};
           6 : o_decomp_data_i <= {i_decomp_data_i[ 9:0],  6'b0};
           7 : o_decomp_data_i <= {i_decomp_data_i[ 8:0],  7'b0};
           8 : o_decomp_data_i <= {i_decomp_data_i[ 7:0],  8'b0};
           9 : o_decomp_data_i <= {i_decomp_data_i[ 6:0],  9'b0};        
          10 : o_decomp_data_i <= {i_decomp_data_i[ 5:0], 10'b0};
          11 : o_decomp_data_i <= {i_decomp_data_i[ 4:0], 11'b0};
          12 : o_decomp_data_i <= {i_decomp_data_i[ 3:0], 12'b0};
          13 : o_decomp_data_i <= {i_decomp_data_i[ 2:0], 13'b0};
          14 : o_decomp_data_i <= {i_decomp_data_i[ 1:0], 14'b0};
          15 : o_decomp_data_i <= {i_decomp_data_i   [0], 15'b0};
          default : o_decomp_data_i <= i_decomp_data_i;
      endcase
    end
    else begin
      case (shift_value_R[3:0])
           1 : o_decomp_data_i <= w_round_1_i;                          
           2 : o_decomp_data_i <= { {1{w_round_2_i[14]}}, w_round_2_i };
           3 : o_decomp_data_i <= { {2{w_round_3_i[13]}}, w_round_3_i };
           4 : o_decomp_data_i <= { {3{w_round_4_i[12]}}, w_round_4_i };
           5 : o_decomp_data_i <= { {4{w_round_5_i[11]}}, w_round_5_i };
           6 : o_decomp_data_i <= { {5{w_round_6_i[10]}}, w_round_6_i };
           7 : o_decomp_data_i <= { {6{w_round_7_i [9]}}, w_round_7_i }; 
           8 : o_decomp_data_i <= { {7{w_round_8_i [8]}}, w_round_8_i }; 
           9 : o_decomp_data_i <= { {8{w_round_9_i [7]}}, w_round_9_i };       
          10 : o_decomp_data_i <= { {9{w_round_10_i[6]}}, w_round_10_i};
          default : o_decomp_data_i <= i_decomp_data_i;
      endcase    
    end
  end
end


//data_Q
always @(posedge clk_245)
begin
  if(i_decomp_enable) begin
    if(shift_value[5] == 1'b0) begin
      case (shift_value[3:0])
           1 : o_decomp_data_q <= {i_decomp_data_q[14:0],  1'b0};
           2 : o_decomp_data_q <= {i_decomp_data_q[13:0],  2'b0};
           3 : o_decomp_data_q <= {i_decomp_data_q[12:0],  3'b0};
           4 : o_decomp_data_q <= {i_decomp_data_q[11:0],  4'b0};
           5 : o_decomp_data_q <= {i_decomp_data_q[10:0],  5'b0};
           6 : o_decomp_data_q <= {i_decomp_data_q[ 9:0],  6'b0};
           7 : o_decomp_data_q <= {i_decomp_data_q[ 8:0],  7'b0};
           8 : o_decomp_data_q <= {i_decomp_data_q[ 7:0],  8'b0};
           9 : o_decomp_data_q <= {i_decomp_data_q[ 6:0],  9'b0};
          10 : o_decomp_data_q <= {i_decomp_data_q[ 5:0], 10'b0};
          11 : o_decomp_data_q <= {i_decomp_data_q[ 4:0], 11'b0};
          12 : o_decomp_data_q <= {i_decomp_data_q[ 3:0], 12'b0};
          13 : o_decomp_data_q <= {i_decomp_data_q[ 2:0], 13'b0};
          14 : o_decomp_data_q <= {i_decomp_data_q[ 1:0], 14'b0};
          15 : o_decomp_data_q <= {i_decomp_data_q   [0], 15'b0};
          default : o_decomp_data_q <= i_decomp_data_q;
    endcase
    end
    else begin
      case (shift_value_R[3:0])
           1 : o_decomp_data_q <= w_round_1_q;                          
           2 : o_decomp_data_q <= { {1{w_round_2_q[14]}}, w_round_2_q };
           3 : o_decomp_data_q <= { {2{w_round_3_q[13]}}, w_round_3_q };
           4 : o_decomp_data_q <= { {3{w_round_4_q[12]}}, w_round_4_q };
           5 : o_decomp_data_q <= { {4{w_round_5_q[11]}}, w_round_5_q };
           6 : o_decomp_data_q <= { {5{w_round_6_q[10]}}, w_round_6_q };
           7 : o_decomp_data_q <= { {6{w_round_7_q [9]}}, w_round_7_q }; 
           8 : o_decomp_data_q <= { {7{w_round_8_q [8]}}, w_round_8_q }; 
           9 : o_decomp_data_q <= { {8{w_round_9_q [7]}}, w_round_9_q };       
          10 : o_decomp_data_q <= { {9{w_round_10_q[6]}}, w_round_10_q};
          default : o_decomp_data_q <= i_decomp_data_q;
      endcase  
    end
  end
end


//=========================================================
// timer information output
//=========================================================
//time information

always @(posedge clk_245)
begin
  	o_decomp_frame_id    <= i_decomp_frame_id;     
    o_decomp_subframe_id <= i_decomp_subframe_id;  
    o_decomp_slot_id     <= i_decomp_slot_id;      
    o_decomp_symbol_id   <= i_decomp_symbol_id;    
    o_decomp_user        <= i_decomp_user;         
end


endmodule