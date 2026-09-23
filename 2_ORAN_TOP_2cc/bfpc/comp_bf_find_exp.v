// *********************************************************************************
// Copyright (c) 2011 SAMSUNG Electronics, All rights reserved
//----------------------------------------------------------------------------------
//-- Project name : ORAN
//-- Filename     : comp_bf_find_exp.v
//-- Author       : Youchul Shin
//-- Email        : youchul.shing@samsung.com
//-- Description  : find exponent in Block floating compresssion mode
//----------------------------------------------------------------------
//--     Date    |     By           |  Version | Change Description
//----------------------------------------------------------------------
//--  02-20-2019 | Youchul Shin     |    0.1   | Original Version
//----------------------------------------------------------------------------------
//--  11-22-2019 | Taeyoup Kim      |    0.2   | 1. udiqwidth extension : 15 ~ 9 bit
//--             |                  |          | 2. find_exp algorithm correction 
//----------------------------------------------------------------------------------
//--  12-05-2019 | Taeyoup Kim      |    0.3   | udiqwidth extension : 15 ~ 7 bit
//----------------------------------------------------------------------------------
// *********************************************************************************
// latency : 5clk
module comp_bf_find_exp (
  input wire        clk_245        ,
  input wire        rst            ,

  input wire        i_enable       ,
  input wire [15:0] i_data_i       , //sign extended bit
  input wire [15:0] i_data_q       , //sign extended bit
  input wire        i_rb_start_tic ,
  input wire        i_rb_end_tic   ,
  input wire [3:0]  i_offset       , //6~14

  output reg        o_exp_valid    ,
  output reg [3:0]  o_exp           //0~9 in this project
);

//=========================================================
// signal
//=========================================================
reg r_enable;
reg r_enable_d1;

reg r_rb_start_tic;
reg r_rb_start_tic_d1;

reg r_rb_end_tic;
reg r_rb_end_tic_d1;
reg r_rb_end_tic_d2;

reg [3:0] r_offset;      
reg [3:0] r_offset_d1;   
reg [3:0] r_offset_d2;   

wire [15:0] w_abs_data_i;
wire [15:0] w_abs_data_q;

reg [15:0] r_abs_data_i;
reg [15:0] r_abs_data_q;

reg [15:0] r_z;
reg [15:0] r_max_z;

reg [3:0] r_exp;

//=========================================================
// input data check
//=========================================================
always @(posedge clk_245)
begin
    r_enable     <= i_enable;
    r_enable_d1  <= r_enable;

    r_rb_start_tic    <= i_rb_start_tic;
    r_rb_start_tic_d1 <= r_rb_start_tic;

    r_rb_end_tic    <= i_rb_end_tic;
    r_rb_end_tic_d1 <= r_rb_end_tic;
    r_rb_end_tic_d2 <= r_rb_end_tic_d1;

    r_offset    <= i_offset;
    r_offset_d1 <= r_offset;
    r_offset_d2 <= r_offset_d1;
end

//=========================================================
// abs
//=========================================================
comp_bf_abs #(.IN_WIDTH(16), .OUT_WIDTH(16)) U_COMP_BF_ABS_I (
  .data_in    ( i_data_i     ),
  .data_out   ( w_abs_data_i )
);

comp_bf_abs #(.IN_WIDTH(16), .OUT_WIDTH(16)) U_COMP_BF_ABS_Q (
  .data_in    ( i_data_q     ),
  .data_out   ( w_abs_data_q )
);

always @(posedge clk_245)
begin
    r_abs_data_i <= w_abs_data_i - i_data_i[15];   
    r_abs_data_q <= w_abs_data_q - i_data_q[15];   
end

//=====================================================================================
// select z
// (|re()| - sign re() > |im()| - sign im()) ? |re()| - sign re() : |im()| - sign im()
//=====================================================================================
always @(posedge clk_245)
begin
    if(r_abs_data_i > r_abs_data_q) begin
      r_z <= r_abs_data_i;   
    end
    else begin
      r_z <= r_abs_data_q;   
    end
end

//=========================================================
// find max_z
//=========================================================
always @(posedge clk_245)
begin
  if(r_rb_start_tic_d1 ) begin
    r_max_z <= r_z;
  end
  else if(r_enable_d1) begin
    if(r_max_z > r_z) begin
      r_max_z <= r_max_z;
    end
    else begin
      r_max_z <= r_z;
    end
  end
end

//=========================================================
// find exp
//=========================================================
always @(posedge clk_245)           
begin                               
  if(r_rb_end_tic_d1) begin    
    if(r_max_z[14]) begin           
      r_exp <= 15;                  
    end                             
    else if(r_max_z[13]) begin      
      r_exp <= 14;                  
    end                             
    else if(r_max_z[12]) begin      
      r_exp <= 13;                  
    end                             
    else if(r_max_z[11]) begin      
      r_exp <= 12;                  
    end                             
    else if(r_max_z[10]) begin      
      r_exp <= 11;                  
    end                             
    else if(r_max_z[9]) begin       
      r_exp <= 10;                  
    end                             
    else if(r_max_z[8]) begin       
      r_exp <= 9;                   
    end                             
    else if(r_max_z[7]) begin       
      r_exp <= 8;                   
    end  
    else if(r_max_z[6]) begin       
      r_exp <= 7;                   
    end  
    else begin                      
      r_exp <= 0;                   
    end                         
  end                           
end                             
                                

//=========================================================
// exp output
//=========================================================
always @(posedge clk_245)                     
begin                                         
  if(r_rb_end_tic_d2) begin              
    if(r_exp > r_offset_d2) begin             
      o_exp <= r_exp - r_offset_d2;           
    end                                       
    else begin                                
      o_exp <= 0;                             
    end                                       
  end                                         
end                                           

always @(posedge clk_245)
begin
    o_exp_valid <= r_rb_end_tic_d2;
end

endmodule