// *********************************************************************************
// Copyright (c) 2011 SAMSUNG Electronics, All rights reserved
//----------------------------------------------------------------------------------
//-- Project name : xRAN
//-- Filename     : comp_bf_abs.v
//-- Author       : Youchul Shin
//-- Email        : youchul.shing@samsung.com
//-- Description  : sign abs
//----------------------------------------------------------------------------------
//--     Date    |     By           |  Version | Change Description
//----------------------------------------------------------------------------------
//--  02-20-2019 | Youchul Shin     |    0.1   | Original Version
//----------------------------------------------------------------------------------
//--  11-22-2019 | Taeyoup Kim      |    0.2   | 1. udiqwidth extension 
//--             |                  |          | 2. find_exp algorithm correction 
//----------------------------------------------------------------------------------
// *********************************************************************************

module comp_bf_abs (
  data_in,
  data_out
);

//------------- Parameter definition -----------
parameter  IN_WIDTH  = 16;
parameter  OUT_WIDTH = 16;

//---------------- Port definition -------------
input  wire [IN_WIDTH-1:0]   data_in;
output wire [OUT_WIDTH-1:0]  data_out;

assign  data_out = f_abs(data_in);

// --------------- Function Block ----------------
function [OUT_WIDTH-1:0] f_abs;
  input [IN_WIDTH-1:0] i_data;
  
  begin
    if(i_data[IN_WIDTH-1] == 1'b1) begin
      f_abs = (~i_data) + 1 ; 
    end
    else begin
      f_abs = i_data ;
    end
  end
  
endfunction

endmodule