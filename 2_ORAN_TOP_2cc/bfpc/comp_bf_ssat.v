// *****************************************************************************
// Copyright (c) 2011 SAMSUNG Electronics, All rights reserved
//------------------------------------------------------------------------------
//-- Project name : xRAN
//-- Filename     : comp_bf_ssat.v
//-- Author       : Youchul Shin
//-- Email        : youchul.shing@samsung.com
//-- Description  : sign saturate
//----------------------------------------------------------------------
//--     Date    |     By           |  Version | Change Description
//----------------------------------------------------------------------
//--  02-20-2019 | Youchul Shin     |    0.1   | Original Version
//----------------------------------------------------------------------
// *****************************************************************************

module comp_bf_ssat (
  data_in,
  data_out
);

//------------- Parameter definition -----------
parameter IN_WIDTH   = 16;
parameter OUT_WIDTH  = 10;

//---------------- Local Parameters -------------
//localparam SIGNWIDTH = IN_WIDTH - OUT_WIDTH;

//---------------- Port definition -------------
input  wire [IN_WIDTH-1:0]  data_in;
output wire [OUT_WIDTH-1:0] data_out;

assign  data_out = f_ssat(data_in);

// --------------- Function Block ----------------
function [OUT_WIDTH-1:0] f_ssat;
  input  [IN_WIDTH-1:0] i_data;

  begin
    if (i_data[IN_WIDTH-1] == 1'b0) begin // positive
      if (|i_data[IN_WIDTH-2:OUT_WIDTH-1]) begin // positive max
        f_ssat = {1'b0, {(OUT_WIDTH-1){1'b1}}};
      end
      else begin
        f_ssat = i_data[OUT_WIDTH-1:0];
      end
    end
    else begin  // negative
      if (&i_data[IN_WIDTH-2:OUT_WIDTH-1]) begin // negative normal
        if (i_data[OUT_WIDTH-2:0]==0) begin     // ex) ffff8000 -> sat to 16bit, it should be 8001
          f_ssat = {i_data[OUT_WIDTH-1:1], 1'b1};
        end
        else begin
          f_ssat = i_data[OUT_WIDTH-1:0];
        end
      end
      else begin
        f_ssat = {1'b1, {(OUT_WIDTH-2){1'b0}}, 1'b1};
      end
    end
  end
endfunction

endmodule