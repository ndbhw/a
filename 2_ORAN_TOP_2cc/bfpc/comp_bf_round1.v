// *****************************************************************************
// Copyright (c) 2011 SAMSUNG Electronics, All rights reserved
//------------------------------------------------------------------------------
//-- Project name : xRAN
//-- Filename     : comp_bf_round.v
//-- Author       : Youchul Shin
//-- Email        : youchul.shing@samsung.com
//-- Description  : sign round (truncation)
//----------------------------------------------------------------------
//--     Date    |     By           |  Version | Change Description
//----------------------------------------------------------------------
//--  02-20-2019 | Youchul Shin     |    0.1   | Original Version
//----------------------------------------------------------------------
// *****************************************************************************

module comp_bf_round1(
  data_in,
  data_out
);

//------------- Parameter definition -----------
parameter  IN_WIDTH  = 16;
parameter  TR_WIDTH  = 1;

//------------- Local para definition ----------
localparam  OUT_WIDTH = IN_WIDTH - TR_WIDTH + 1;

//---------------- Port definition -------------
input  wire    [IN_WIDTH-1:0]   data_in;
output wire    [OUT_WIDTH-1:0]  data_out;

assign  data_out = f_round(data_in);

// --------------- Function Block ----------------
// Symmetric Rounding
function [OUT_WIDTH-1:0] f_round;
  input  [IN_WIDTH-1:0] i_data;
  reg                   round_up;
  
  begin
    if (i_data[IN_WIDTH-1] == 1'b1) begin
      round_up = 0;
    end
    else begin
      round_up = i_data[TR_WIDTH-1];
    end
                                                        
    f_round = {i_data[IN_WIDTH-1],i_data[IN_WIDTH-1:TR_WIDTH]} + {{OUT_WIDTH-1{1'b0}},round_up};
  end
endfunction

endmodule
    