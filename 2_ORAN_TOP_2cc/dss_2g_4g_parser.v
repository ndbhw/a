// ***************************************************************************** 
// 
// Copyright (C) 2022, Samsung Electronics Co., LTD. All Right Reserved.
//
// Department  : FPGA Part/H/W R&D Group
// Author      : MoonHyeok Jang (mmhh.jang@samsung.com)
// 
// *****************************************************************************
// Function    : dss_2g_4g_parser
// Description : 2g_4g_dss_param_parser
// *****************************************************************************
// Revision History                                                           
// *****************************************************************************
// [2022.10.12, v0.00, mmhh.jang] Initial Release
// *****************************************************************************


module dss_2g_4g_parser
(
    // CLK
    input   wire    [1                     -1: 0]   i_clk                     ,  // 245.76MHz

    // Registers
    input   wire    [1                     -1: 0]   i_reg_dss_param_test_en   ,

    // ChipSync (From DLFE SBIF)
    input   wire    [1                     -1: 0]   i_chipsync                ,

    // C-Plane Data
    input   wire    [1                     -1: 0]   i_cc0_blankingpatternid_valid ,
    input   wire    [8                     -1: 0]   i_cc0_blankingpatternid       ,
    input   wire    [1                     -1: 0]   i_cc1_blankingpatternid_valid ,
    input   wire    [8                     -1: 0]   i_cc1_blankingpatternid       ,

    // To SBIF
    output  reg     [16                    -1: 0]   o_sbif_data                   ,

    // Monitoring Registers
    output  wire    [32                    -1: 0]   o_reg_cc0_coeff_vld_cnt       ,
    output  wire    [32                    -1: 0]   o_reg_cc1_coeff_vld_cnt       ,

    output  wire    [32                    -1: 0]   o_reg_cc0_coeff_idx_mon       ,
    output  wire    [32                    -1: 0]   o_reg_cc1_coeff_idx_mon
);

    localparam    LEN_120MS =  460800 ; // 2457600*12/64


    /////////////////////////////////////////////////////
    // Input Registering
    /////////////////////////////////////////////////////
    reg    [1      -1: 0]   r_cc0_blankingpatternid_valid  = 0; 
    reg    [8      -1: 0]   r_cc0_blankingpatternid        = 0; 
    reg    [1      -1: 0]   r_cc1_blankingpatternid_valid  = 0; 
    reg    [8      -1: 0]   r_cc1_blankingpatternid        = 0; 

    always @ (posedge i_clk) begin
        r_cc0_blankingpatternid_valid  <=  i_cc0_blankingpatternid_valid   ; 
        r_cc0_blankingpatternid        <=  i_cc0_blankingpatternid         ;
        r_cc1_blankingpatternid_valid  <=  i_cc1_blankingpatternid_valid   ;
        r_cc1_blankingpatternid        <=  i_cc1_blankingpatternid         ;
    end
    /////////////////////////////////////////////////////


    /////////////////////////////////////////////////////
    // Save Pattern ID (Coefficient IDX)
    /////////////////////////////////////////////////////
    reg   [1   -1: 0]   r_cc0_coeff_vld   = 0;
    reg   [4   -1: 0]   r_cc0_coeff_idx   = 0;

    reg   [1   -1: 0]   r_cc1_coeff_vld   = 0;
    reg   [4   -1: 0]   r_cc1_coeff_idx   = 0;    

    always @ (posedge i_clk) begin
        if (r_cc0_blankingpatternid_valid & |r_cc0_blankingpatternid[3:0]) begin
            r_cc0_coeff_vld      <= 1;
            r_cc0_coeff_idx      <= r_cc0_blankingpatternid[3:0];
        end
        else if (i_chipsync) begin
            r_cc0_coeff_vld      <= 0;    
            r_cc0_coeff_idx      <= 0;
        end
    end

    always @ (posedge i_clk) begin
        if (r_cc1_blankingpatternid_valid & |r_cc1_blankingpatternid[3:0]) begin
            r_cc1_coeff_vld      <= 1;
            r_cc1_coeff_idx      <= r_cc1_blankingpatternid[3:0];
        end
        else if (i_chipsync) begin
            r_cc1_coeff_vld      <= 0;    
            r_cc1_coeff_idx      <= 0;
        end
    end
    /////////////////////////////////////////////////////


    /////////////////////////////////////////////////////
    // Test Pattern (1->2->3->1->2->3->...)
    /////////////////////////////////////////////////////
    reg   [19 -1: 0] r_chipsync_cnt  = 0;
    reg   [2  -1: 0] r_120ms_cnt     = 1;

    reg   [1   -1: 0]   r_cc0_test_coeff_vld   = 0;
    reg   [4   -1: 0]   r_cc0_test_coeff_idx   = 0;

    reg   [1   -1: 0]   r_cc1_test_coeff_vld   = 0;
    reg   [4   -1: 0]   r_cc1_test_coeff_idx   = 0;        

    always @ (posedge i_clk) begin
        if (i_chipsync) begin
            if (r_chipsync_cnt == LEN_120MS - 1) begin
                r_chipsync_cnt   <= 0;
            end
            else begin
                r_chipsync_cnt   <= r_chipsync_cnt + 1;
            end
        end
    end

    always @ (posedge i_clk) begin
        if (i_chipsync) begin
            if (r_chipsync_cnt == LEN_120MS - 1) begin
                if (r_120ms_cnt == 2'd3) begin
                    r_120ms_cnt   <= 1;
                end
                else begin
                    r_120ms_cnt   <= r_120ms_cnt + 1;
                end
            end
        end
    end

    always @ (posedge i_clk) begin
        if (r_chipsync_cnt == 0) begin
            r_cc0_test_coeff_vld   <= 1;
            r_cc0_test_coeff_idx   <= {2'b00, r_120ms_cnt};

            r_cc1_test_coeff_vld   <= 1;
            r_cc1_test_coeff_idx   <= {2'b00, r_120ms_cnt};            
        end
        else begin
            r_cc0_test_coeff_vld   <= 0;
            r_cc0_test_coeff_idx   <= 0;

            r_cc1_test_coeff_vld   <= 0;
            r_cc1_test_coeff_idx   <= 0;                    
        end
    end
    /////////////////////////////////////////////////////


    /////////////////////////////////////////////////////
    // Output Mapping
    /////////////////////////////////////////////////////
    always @ (posedge i_clk) begin
        if (i_chipsync) begin
            if (i_reg_dss_param_test_en) begin
                o_sbif_data    <=  {3'b000, r_cc1_test_coeff_vld, r_cc1_test_coeff_idx, 3'b000, r_cc0_test_coeff_vld, r_cc0_test_coeff_idx} ;
            end
            else begin
                o_sbif_data    <=  {3'b000, r_cc1_coeff_vld, r_cc1_coeff_idx, 3'b000, r_cc0_coeff_vld, r_cc0_coeff_idx} ;
            end
        end
        else begin
            o_sbif_data       <= 0;
        end
    end
    /////////////////////////////////////////////////////


    /////////////////////////////////////////////////////
    // Monitoring Register
    /////////////////////////////////////////////////////
    reg    [32   -1: 0]     r_cc0_coeff_vld_cnt = 0;
    reg    [32   -1: 0]     r_cc1_coeff_vld_cnt = 0;

    reg    [8*4  -1: 0]     r_cc0_coeff_idx_mon = 0;
    reg    [8*4  -1: 0]     r_cc1_coeff_idx_mon = 0;

    always @ (posedge i_clk) begin
        if (o_sbif_data[4]) begin
            r_cc0_coeff_vld_cnt  <= r_cc0_coeff_vld_cnt + 1;
        end
    end

    always @ (posedge i_clk) begin
        if (o_sbif_data[12]) begin
            r_cc1_coeff_vld_cnt  <= r_cc1_coeff_vld_cnt + 1;
        end
    end

    always @ (posedge i_clk) begin
        if (o_sbif_data[4]) begin
            r_cc0_coeff_idx_mon[3 : 0]  <= o_sbif_data[3:0]            ;
            r_cc0_coeff_idx_mon[7 : 4]  <= r_cc0_coeff_idx_mon[3:0]    ;
            r_cc0_coeff_idx_mon[11: 8]  <= r_cc0_coeff_idx_mon[7:4]    ;
            r_cc0_coeff_idx_mon[15:12]  <= r_cc0_coeff_idx_mon[11:8]   ;
            r_cc0_coeff_idx_mon[19:16]  <= r_cc0_coeff_idx_mon[15:12]  ;
            r_cc0_coeff_idx_mon[23:20]  <= r_cc0_coeff_idx_mon[19:16]  ;
            r_cc0_coeff_idx_mon[27:24]  <= r_cc0_coeff_idx_mon[23:20]  ;
            r_cc0_coeff_idx_mon[31:28]  <= r_cc0_coeff_idx_mon[27:24]  ;
        end
    end    

    always @ (posedge i_clk) begin
        if (o_sbif_data[12]) begin
            r_cc1_coeff_idx_mon[3 : 0]  <= o_sbif_data[11:8]           ;
            r_cc1_coeff_idx_mon[7 : 4]  <= r_cc1_coeff_idx_mon[3:0]    ;
            r_cc1_coeff_idx_mon[11: 8]  <= r_cc1_coeff_idx_mon[7:4]    ;
            r_cc1_coeff_idx_mon[15:12]  <= r_cc1_coeff_idx_mon[11:8]   ;
            r_cc1_coeff_idx_mon[19:16]  <= r_cc1_coeff_idx_mon[15:12]  ;
            r_cc1_coeff_idx_mon[23:20]  <= r_cc1_coeff_idx_mon[19:16]  ;
            r_cc1_coeff_idx_mon[27:24]  <= r_cc1_coeff_idx_mon[23:20]  ;
            r_cc1_coeff_idx_mon[31:28]  <= r_cc1_coeff_idx_mon[27:24]  ;
        end
    end    

    assign  o_reg_cc0_coeff_vld_cnt =   r_cc0_coeff_vld_cnt ;
    assign  o_reg_cc1_coeff_vld_cnt =   r_cc1_coeff_vld_cnt ;
                                                           
    assign  o_reg_cc0_coeff_idx_mon =   r_cc0_coeff_idx_mon ;
    assign  o_reg_cc1_coeff_idx_mon =   r_cc1_coeff_idx_mon ;
    /////////////////////////////////////////////////////


endmodule
