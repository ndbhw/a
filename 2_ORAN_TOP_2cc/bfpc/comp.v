// *********************************************************************************
// Copyright (c) 2011 SAMSUNG Electronics, All rights reserved
//----------------------------------------------------------------------------------
//-- Project name : ORAN
//-- Filename     : comp.v
//-- Author       : Youchul Shin
//-- Email        : youchul.shing@samsung.com
//-- Description  : compresssion top module
//----------------------------------------------------------------------------------
//--     Date    |     By           |  Version | Change Description
//----------------------------------------------------------------------------------
//--  02-22-2019 | Youchul Shin     |    0.1   | Original Version
//----------------------------------------------------------------------------------
//--  11-22-2019 | Taeyoup Kim      |    0.2   | 1. udiqwidth extension 
//--             |                  |          | 2. find_exp algorithm correction 
//----------------------------------------------------------------------------------
//--  09-17-2020 | Taeyoup Kim      |    0.3   | 1. i_comp_gain_offset added 
//--             |                  |          | 2. i_comp_scale_gain_offset added
//--             |                  |          | 3. i_comp_exp_offset added
//----------------------------------------------------------------------------------
//--  05-20-2021 | Taeyoup Kim      |    0.4   | multiplier output pipeline 
//----------------------------------------------------------------------------------
// *********************************************************************************
//latency : 24 clk
module comp (
  input wire        clk_245                  ,
  input wire        rst                      ,
  input wire [1:0]  i_comp_mode              , //0:bypass, 1:block floating, 2:modulation compress
  input wire [10:0] i_comp_gain_offset       , //UL scaling for BFPC
  input wire [3:0]  i_comp_scale_gain_offset , //UL scaling for BFPC
  input wire [4:0]  i_comp_exp_offset        , //UL scaling for BFPC
                                             
  //compress input                           
  input wire        i_comp_enable            ,
  input wire [15:0] i_comp_data_i            , //sign extended bit
  input wire [15:0] i_comp_data_q            , //sign extended bit
                                             
  input wire        i_comp_rb_start_tic      , //RB start tic
  input wire [3:0]  i_comp_udiqwidth         , //compress sample : 9~15
  //input wire [11:0] i_re_idx                 //re index : 0~3275(=273RBx12RE-1)
  input wire [7:0]  i_comp_frame_id          ,
  input wire [3:0]  i_comp_subframe_id       ,
  input wire [5:0]  i_comp_slot_id           ,
  input wire [3:0]  i_comp_symbol_id         ,
  input wire [15:0] i_comp_user              , //user parameter
                                             
  //compress output                          
  output reg        o_comp_valid             ,
  output reg [15:0] o_comp_data_i            ,
  output reg [15:0] o_comp_data_q            ,
  output reg        o_comp_rb_start_tic      ,
  output reg [3:0]  o_comp_exp               ,
  output reg [1:0]  o_comp_mode              ,
  output reg [3:0]  o_comp_udiqwidth         ,
                                             
  output reg [7:0]  o_comp_frame_id          ,
  output reg [3:0]  o_comp_subframe_id       ,
  output reg [5:0]  o_comp_slot_id           ,
  output reg [3:0]  o_comp_symbol_id         ,
  output reg [15:0] o_comp_user
);

localparam DLY_SIZE = 23;
//=========================================================
// signal
//=========================================================

wire [3:0]  w_bf_comp_udiqwidth;
reg  [3:0]  w_bf_comp_udiqwidth_d0;
reg  [3:0]  w_bf_comp_udiqwidth_d1;
reg  [3:0]  w_bf_comp_udiqwidth_d2;
reg i_comp_enable_d0; 
reg i_comp_enable_d1;     
reg i_comp_enable_d2; 
reg i_comp_rb_start_tic_d0; 
reg i_comp_rb_start_tic_d1;
reg i_comp_rb_start_tic_d2;

reg r_bf_comp_enable;
reg r_bf_comp_rb_start_tic;

wire        w_bf_comp_valid;
wire [15:0] w_bf_comp_data_i;
wire [15:0] w_bf_comp_data_q;
wire        w_bf_comp_exp_valid;
wire [3:0]  w_bf_comp_exp;
wire [3:0]  w_comp_udiqwidth;

reg [26:0] i_comp_data_i_d0;
reg [26:0] i_comp_data_i_d1; 
(* keep="true" *) reg [26:0] i_comp_data_i_r;
reg [26:0] i_comp_data_q_d0; 
reg [26:0] i_comp_data_q_d1; 
(* keep="true" *) reg [26:0] i_comp_data_q_r;

wire [21:0] w_round_6_i;
wire [21:0] w_round_6_q;
wire [20:0] w_round_7_i;
wire [20:0] w_round_7_q;
wire [19:0] w_round_8_i;
wire [19:0] w_round_8_q;
wire [18:0] w_round_9_i;
wire [18:0] w_round_9_q;
wire [17:0] w_round_10_i;
wire [17:0] w_round_10_q;
wire [16:0] w_round_11_i;
wire [16:0] w_round_11_q;
wire [15:0] w_round_12_i;
wire [15:0] w_round_12_q;

reg [21:0]  r_bf_comp_round_data_i;
reg [21:0]  r_bf_comp_round_data_q;

integer i;
wire [15:0] r_comp_data_i; 
wire [15:0] r_comp_data_q; 
reg [1:0]  r_comp_mode_d         [0:DLY_SIZE-1];
reg [3:0]  r_comp_udiqwidth;

reg [7:0]  r_comp_frame_id_d    [0:DLY_SIZE-1];
reg [3:0]  r_comp_subframe_id_d [0:DLY_SIZE-1];
reg [5:0]  r_comp_slot_id_d     [0:DLY_SIZE-1];
reg [3:0]  r_comp_symbol_id_d   [0:DLY_SIZE-1];
reg [15:0] r_comp_user_d        [0:DLY_SIZE-1];


assign w_bf_comp_udiqwidth = (i_comp_mode == 1) ? i_comp_udiqwidth : 0 ;

//data enable and prb start tic singal
always @(posedge clk_245)
begin
     i_comp_enable_d0       <= i_comp_enable;
     i_comp_rb_start_tic_d0 <= i_comp_rb_start_tic;
end

// + 1 latency because of ul scaling
always @(posedge clk_245)
begin
     i_comp_enable_d1       <= i_comp_enable_d0;
     i_comp_rb_start_tic_d1 <= i_comp_rb_start_tic_d0;
end

// + 2 multiplier output pipeline 
always @(posedge clk_245)
begin
     i_comp_enable_d2       <= i_comp_enable_d1;      
     i_comp_rb_start_tic_d2 <= i_comp_rb_start_tic_d1;

     r_bf_comp_enable       <= i_comp_enable_d2;      
     r_bf_comp_rb_start_tic <= i_comp_rb_start_tic_d2;
end

//parameter
always @(posedge clk_245)
begin
  if(i_comp_rb_start_tic) begin
    w_bf_comp_udiqwidth_d0 <= w_bf_comp_udiqwidth;
  end
end

// + 1 latency because of ul scaling
always @(posedge clk_245)
begin
    w_bf_comp_udiqwidth_d1 <= w_bf_comp_udiqwidth_d0;
end

// + 2 multiplier output pipeline 
always @(posedge clk_245)
begin
     w_bf_comp_udiqwidth_d2 <= w_bf_comp_udiqwidth_d1;
     r_comp_udiqwidth       <= w_bf_comp_udiqwidth_d2;
end

always @(posedge clk_245)
begin
  if(i_comp_rb_start_tic) begin
    r_comp_mode_d[0] <= i_comp_mode;
  end
end

always @(posedge clk_245)
begin
    for(i=1;i<DLY_SIZE;i=i+1) begin
      r_comp_mode_d[i] <= r_comp_mode_d[i-1];
    end
end

//=========================================================
// gainOffset (multiplication) 16 * 11 -> 27 bit 
//=========================================================

//IQ data
always @(posedge clk_245)
begin
  if(i_comp_enable) begin
    i_comp_data_i_d0 <= $signed(i_comp_data_i)*$signed({1'b0, i_comp_gain_offset});
    i_comp_data_q_d0 <= $signed(i_comp_data_q)*$signed({1'b0, i_comp_gain_offset});
  end
end

//=========================================================
// Multiplier Output Pipeline (+ 2 clk) 
//=========================================================

//IQ data
always @(posedge clk_245)
begin
    i_comp_data_i_d1 <= i_comp_data_i_d0;
    i_comp_data_q_d1 <= i_comp_data_q_d0;

    i_comp_data_i_r <= i_comp_data_i_d1;
    i_comp_data_q_r <= i_comp_data_q_d1;
end

//=========================================================
// scaleGainOffset (6 ~ 12 Round) 27 -> 22 bit 
//=========================================================

//scaleGainOffset  = 6
comp_bf_round #(.IN_WIDTH(27), .TR_WIDTH(6)) U_COMP_BF_ROUND_6_I (
  .data_in     ( i_comp_data_i_r       ),
  .data_out    ( w_round_6_i           )
);

comp_bf_round #(.IN_WIDTH(27), .TR_WIDTH(6)) U_COMP_BF_ROUND_6_Q (
  .data_in     ( i_comp_data_q_r       ),
  .data_out    ( w_round_6_q           )
);

//scaleGainOffset  = 7
comp_bf_round #(.IN_WIDTH(27), .TR_WIDTH(7)) U_COMP_BF_ROUND_7_I (
  .data_in     ( i_comp_data_i_r       ),
  .data_out    ( w_round_7_i           )
);

comp_bf_round #(.IN_WIDTH(27), .TR_WIDTH(7)) U_COMP_BF_ROUND_7_Q (
  .data_in     ( i_comp_data_q_r       ),
  .data_out    ( w_round_7_q           )
);

//scaleGainOffset  = 8
comp_bf_round #(.IN_WIDTH(27), .TR_WIDTH(8)) U_COMP_BF_ROUND_8_I (
  .data_in     ( i_comp_data_i_r       ),
  .data_out    ( w_round_8_i           )
);

comp_bf_round #(.IN_WIDTH(27), .TR_WIDTH(8)) U_COMP_BF_ROUND_8_Q (
  .data_in     ( i_comp_data_q_r       ),
  .data_out    ( w_round_8_q           )
);

//scaleGainOffset  = 9
comp_bf_round #(.IN_WIDTH(27), .TR_WIDTH(9)) U_COMP_BF_ROUND_9_I (
  .data_in     ( i_comp_data_i_r       ),
  .data_out    ( w_round_9_i           )
);

comp_bf_round #(.IN_WIDTH(27), .TR_WIDTH(9)) U_COMP_BF_ROUND_9_Q (
  .data_in     ( i_comp_data_q_r       ),
  .data_out    ( w_round_9_q           )
);

//scaleGainOffset  = 10
comp_bf_round #(.IN_WIDTH(27), .TR_WIDTH(10)) U_COMP_BF_ROUND_10_I (
  .data_in     ( i_comp_data_i_r       ),
  .data_out    ( w_round_10_i          )
);

comp_bf_round #(.IN_WIDTH(27), .TR_WIDTH(10)) U_COMP_BF_ROUND_10_Q (
  .data_in     ( i_comp_data_q_r       ),
  .data_out    ( w_round_10_q          )
);

//scaleGainOffset  = 11
comp_bf_round #(.IN_WIDTH(27), .TR_WIDTH(11)) U_COMP_BF_ROUND_11_I (
  .data_in     ( i_comp_data_i_r       ),
  .data_out    ( w_round_11_i           )
);

comp_bf_round #(.IN_WIDTH(27), .TR_WIDTH(11)) U_COMP_BF_ROUND_11_Q (
  .data_in     ( i_comp_data_q_r       ),
  .data_out    ( w_round_11_q           )
);

//scaleGainOffset  = 12
comp_bf_round #(.IN_WIDTH(27), .TR_WIDTH(12)) U_COMP_BF_ROUND_12_I (
  .data_in     ( i_comp_data_i_r       ),
  .data_out    ( w_round_12_i          )
);

comp_bf_round #(.IN_WIDTH(27), .TR_WIDTH(12)) U_COMP_BF_ROUND_12_Q (
  .data_in     ( i_comp_data_q_r       ),
  .data_out    ( w_round_12_q          )
);

//ROUND DATA-I
always @(posedge clk_245)
begin
  if(i_comp_enable_d2) begin   
    case (i_comp_scale_gain_offset)
       6 : r_bf_comp_round_data_i <= w_round_6_i;
       7 : r_bf_comp_round_data_i <= { {1{w_round_7_i[20]}}, w_round_7_i };
       8 : r_bf_comp_round_data_i <= { {2{w_round_8_i[19]}}, w_round_8_i };
       9 : r_bf_comp_round_data_i <= { {3{w_round_9_i[18]}}, w_round_9_i };
      10 : r_bf_comp_round_data_i <= { {4{w_round_10_i[17]}}, w_round_10_i };
      11 : r_bf_comp_round_data_i <= { {5{w_round_11_i[16]}}, w_round_11_i };
      12 : r_bf_comp_round_data_i <= { {6{w_round_12_i[15]}}, w_round_12_i };
      default : r_bf_comp_round_data_i <= i_comp_data_i_r;
    endcase
  end
end

//ROUND DATA-Q
always @(posedge clk_245)
begin
  if(i_comp_enable_d2) begin 
    case (i_comp_scale_gain_offset)
       6 : r_bf_comp_round_data_q <= w_round_6_q;
       7 : r_bf_comp_round_data_q <= { {1{w_round_7_q[20]}}, w_round_7_q };
       8 : r_bf_comp_round_data_q <= { {2{w_round_8_q[19]}}, w_round_8_q };
       9 : r_bf_comp_round_data_q <= { {3{w_round_9_q[18]}}, w_round_9_q };
      10 : r_bf_comp_round_data_q <= { {4{w_round_10_q[17]}}, w_round_10_q };
      11 : r_bf_comp_round_data_q <= { {5{w_round_11_q[16]}}, w_round_11_q };
      12 : r_bf_comp_round_data_q <= { {6{w_round_12_q[15]}}, w_round_12_q };
      default : r_bf_comp_round_data_q <= i_comp_data_q_r;
    endcase
  end
end

//=========================================================
// Sat*16 (ssat)
//=========================================================

comp_bf_ssat #(.IN_WIDTH(22), .OUT_WIDTH(16)) U_COMP_BF_SSAT_16_I (
  .data_in     ( r_bf_comp_round_data_i ),
  .data_out    ( r_comp_data_i          )
);

comp_bf_ssat #(.IN_WIDTH(22), .OUT_WIDTH(16)) U_COMP_BF_SSAT_16_Q (
  .data_in     ( r_bf_comp_round_data_q ),
  .data_out    ( r_comp_data_q          )
);

//time information
always @(posedge clk_245)
begin
  if(i_comp_rb_start_tic) begin
    r_comp_frame_id_d[0]    <= i_comp_frame_id;
    r_comp_subframe_id_d[0] <= i_comp_subframe_id;
    r_comp_slot_id_d[0]     <= i_comp_slot_id;
    r_comp_symbol_id_d[0]   <= i_comp_symbol_id;
    r_comp_user_d[0]        <= i_comp_user;
  end
end

always @(posedge clk_245)
begin
    for(i=1;i<DLY_SIZE;i=i+1) begin
        r_comp_frame_id_d[i]    <= r_comp_frame_id_d[i-1];
        r_comp_subframe_id_d[i] <= r_comp_subframe_id_d[i-1];
        r_comp_slot_id_d[i]     <= r_comp_slot_id_d[i-1];
        r_comp_symbol_id_d[i]   <= r_comp_symbol_id_d[i-1];
        r_comp_user_d[i]        <= r_comp_user_d[i-1];
    end
end

//=========================================================
// block floating compression mode ( mode = 1 )
//=========================================================
comp_bf U_COMP_BF (
  .clk_245                 ( clk_245                ),
  .rst                     ( rst                    ),

  .i_bf_comp_enable        ( r_bf_comp_enable       ),
  .i_bf_comp_data_i        ( r_comp_data_i          ),  
  .i_bf_comp_data_q        ( r_comp_data_q          ),  
  .i_bf_comp_rb_start_tic  ( r_bf_comp_rb_start_tic ),
  .i_bf_comp_udiqwidth     ( r_comp_udiqwidth       ),
  .i_bf_comp_exp_offset    ( i_comp_exp_offset      ),
  .o_bf_comp_valid         ( w_bf_comp_valid        ),
  .o_bf_comp_data_i        ( w_bf_comp_data_i       ),
  .o_bf_comp_data_q        ( w_bf_comp_data_q       ),
  .o_bf_comp_exp_valid     ( w_bf_comp_exp_valid    ),
  .o_bf_comp_udiqwidth     ( w_comp_udiqwidth       ),
  .o_bf_comp_exp           ( w_bf_comp_exp          )
);

//=========================================================
// compress output data
//=========================================================


always @(posedge clk_245)
begin
     o_comp_valid        <= w_bf_comp_valid;
     o_comp_data_i       <= w_bf_comp_data_i;
     o_comp_data_q       <= w_bf_comp_data_q;
     o_comp_rb_start_tic <= w_bf_comp_exp_valid;
     o_comp_exp          <= w_bf_comp_exp;
     o_comp_mode         <= r_comp_mode_d[DLY_SIZE-1];
     o_comp_udiqwidth    <= w_comp_udiqwidth;
end

//=========================================================
// timer information output
//=========================================================


always @(posedge clk_245)
begin
  	o_comp_frame_id    <= r_comp_frame_id_d[DLY_SIZE-1];
    o_comp_subframe_id <= r_comp_subframe_id_d[DLY_SIZE-1];
    o_comp_slot_id     <= r_comp_slot_id_d[DLY_SIZE-1];
    o_comp_symbol_id   <= r_comp_symbol_id_d[DLY_SIZE-1];
    o_comp_user        <= r_comp_user_d[DLY_SIZE-1];
end


endmodule