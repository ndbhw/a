////////////////////////////////////////////////////////////////////////////////// 
//
// CONFIDENTIAL AND SAMSUNG PROPRIETARY
//
// NATIONAL CORE TECHNOLOGY INCLUDED 
//
// Copyright(c) 2020 Samsung Electronics Inc. All rights reserved
//
//  Project      : ATnT HRU, VzW FSU, DCM RT4419
//  Module       : ref_vsync_gen
//  Author       : jyzoo.lee@samsung.com
//  Description  : reference sync generator for ORAN 
//
//  Revision History
//  ------------+---------------+-----------------------------------------------
//     Date     |   Author      |   Description
//  ------------+---------------+-----------------------------------------------
//   2020.05.22 | jyzoo.lee     | initial release
//  ------------+---------------+-----------------------------------------------
//   2020.06.02 | jyzoo.lee     | Subframe Index Support
//  ------------+---------------+-----------------------------------------------
//   2020.06.11 | jyzoo.lee     | 15k Bug Fix
//  ------------+---------------+-----------------------------------------------
//   2020.09.11 | jyzoo.lee     | add internal enable resync
//  ------------+---------------+-----------------------------------------------
//   2020.11.17 | jyzoo.lee     | Add option to change slot increment type
//  ------------+---------------+-----------------------------------------------
//   2020.04.16 | jyzoo.lee     | 60k Bug Fix
//  ------------+---------------+-----------------------------------------------
//   2020.06.21 | jyzoo.lee     | Fix Bug when SLOT_INC_TYPE is Subframe
//  ------------+---------------+-----------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////

module ref_symbol_gen
#(
    parameter  SLOT_INC_TYPE   =   "FRAME"
)(
        input   wire                i_clk           
    ,   input   wire   [2:0]        i_mu 
    ,   input   wire   [21:0]       i_retard
    ,   input   wire                i_frame_sync           
    ,   input   wire                i_en            
    ,   output  wire                o_frame_sync           
    ,   output  wire                o_subfrm_sync          
    ,   output  wire                o_slot_sync            
    ,   output  wire                o_symbol_sync          
    ,   output  wire   [3:0]        o_subfrm                 
    ,   output  wire   [7:0]        o_slot                 
    ,   output  wire   [3:0]        o_symbol
    ,   output  wire   [14:0]       o_smp_symbol_cnt               
);

localparam      MU_SCS_015K             =   3'd0            ;
localparam      MU_SCS_030K             =   3'd1            ;
localparam      MU_SCS_060K             =   3'd2            ;
localparam      MU_SCS_120K             =   3'd3            ;
localparam      MU_SCS_240K             =   3'd4            ;
localparam      LEN_SUB_FRAME           =   18'd245760      ;       
localparam      NUM_SUBFRM_FRAME        =   4'd10           ;       
localparam      NUM_SYM_SLOT            =   4'd14           ;       

reg [0:0]   r_frame_sync        ;
reg [7:0]   r_num_slot_frame    ;
reg [14:0]  r_len_lcp_sym       ;
reg [14:0]  r_len_ncp_sym       ;
reg [17:0]  r_len_lcp_slot      ;
reg [17:0]  r_len_ncp_slot      ;
always@(posedge i_clk) begin
    r_frame_sync    <=  i_frame_sync ;
    if(i_frame_sync) begin
        case(i_mu)
            MU_SCS_015K : begin r_num_slot_frame <= 8'd10-1'd1  ; r_len_lcp_sym <= 15'd17664; r_len_ncp_sym <= 15'd17536; r_len_lcp_slot <= 18'd17792+18'd17536*(NUM_SYM_SLOT-1'd1) ; r_len_ncp_slot <= 18'd17536*NUM_SYM_SLOT ; end
            MU_SCS_030K : begin r_num_slot_frame <= 8'd20-1'd1  ; r_len_lcp_sym <= 15'd8896 ; r_len_ncp_sym <= 15'd8768 ; r_len_lcp_slot <= 18'd8896 +18'd8768 *(NUM_SYM_SLOT-1'd1) ; r_len_ncp_slot <= 18'd8768 *NUM_SYM_SLOT ; end
            MU_SCS_060K : begin r_num_slot_frame <= 8'd40-1'd1  ; r_len_lcp_sym <= 15'd4512 ; r_len_ncp_sym <= 15'd4384 ; r_len_lcp_slot <= 18'd4512 +18'd4384 *(NUM_SYM_SLOT-1'd1) ; r_len_ncp_slot <= 18'd4384 *NUM_SYM_SLOT ; end
            MU_SCS_120K : begin r_num_slot_frame <= 8'd80-1'd1  ; r_len_lcp_sym <= 15'd2320 ; r_len_ncp_sym <= 15'd2192 ; r_len_lcp_slot <= 18'd2320 +18'd2192 *(NUM_SYM_SLOT-1'd1) ; r_len_ncp_slot <= 18'd2192 *NUM_SYM_SLOT ; end
            MU_SCS_240K : begin r_num_slot_frame <= 8'd160-1'd1 ; r_len_lcp_sym <= 15'd1224 ; r_len_ncp_sym <= 15'd1096 ; r_len_lcp_slot <= 18'd1224 +18'd1096 *(NUM_SYM_SLOT-1'd1) ; r_len_ncp_slot <= 18'd1096 *NUM_SYM_SLOT ; end
            default     : begin r_num_slot_frame <= 8'd80-1'd1  ; r_len_lcp_sym <= 15'd2320 ; r_len_ncp_sym <= 15'd2192 ; r_len_lcp_slot <= 18'd2320 +18'd2192 *(NUM_SYM_SLOT-1'd1) ; r_len_ncp_slot <= 18'd2192 *NUM_SYM_SLOT ; end
        endcase
    end
end
reg [7:0]   NUM_SLOT_FRAME  ;
reg [14:0]  LEN_LCP_SYM     ;
reg [14:0]  LEN_NCP_SYM     ;
reg [17:0]  LEN_LCP_SLOT    ;
reg [17:0]  LEN_NCP_SLOT    ;
always@(posedge i_clk) begin
    if(r_frame_sync) begin
        NUM_SLOT_FRAME  <=  r_num_slot_frame    ;
        LEN_LCP_SYM     <=  r_len_lcp_sym       ;
        LEN_NCP_SYM     <=  r_len_ncp_sym       ;
        LEN_LCP_SLOT    <=  r_len_lcp_slot      ;
        LEN_NCP_SLOT    <=  r_len_ncp_slot      ;
    end
end

//retard sync
reg [21:0]  r_retard ;
always@(posedge i_clk) begin
    if(i_frame_sync) begin
        r_retard    <= i_retard ;
    end 
end
reg r_frame_sync_retard_en  ;
reg [21:0]r_frame_sync_retard_cnt ;
always@(posedge i_clk) begin
    if(i_frame_sync) begin
        r_frame_sync_retard_en <=  i_en     ;
    end 
    else if(r_frame_sync_retard_cnt==r_retard) begin
        r_frame_sync_retard_en <=  1'd0     ;
    end
end

always@(posedge i_clk) begin
    if(i_frame_sync) begin
        r_frame_sync_retard_cnt <=  22'd0    ;
    end
    else if(r_frame_sync_retard_en) begin
        r_frame_sync_retard_cnt <= (r_frame_sync_retard_cnt==r_retard) ? 22'd0 : r_frame_sync_retard_cnt+1'd1    ;
    end
end

reg r_frame_sync_retard ;
reg rr_frame_sync_retard ;
always@(posedge i_clk) begin
    if(i_retard>1) begin
        r_frame_sync_retard <=  r_frame_sync_retard_en&&(r_frame_sync_retard_cnt==r_retard-2) ;
    end
    else begin
        r_frame_sync_retard <=  i_frame_sync ;
    end
    rr_frame_sync_retard <= r_frame_sync_retard ;
end
reg r_en ;
always@(posedge i_clk) begin
    if(r_frame_sync_retard) begin
        r_en <= 1'd1     ;
    end 
    else begin
        if(i_retard>1) begin
            if(r_frame_sync_retard_en&&(r_frame_sync_retard_cnt==r_retard-2)) begin
                r_en <= 1'd0     ;
            end
        end
        else begin
            if(i_frame_sync) begin
                r_en <= 1'd0     ;
            end
        end
    end
end
reg [17:0]  r_smp_subfrm_cnt ;
always@(posedge i_clk) begin
    if(r_frame_sync_retard) begin
        r_smp_subfrm_cnt   <=    18'd0 ;    
    end
    else begin
        r_smp_subfrm_cnt   <=    (r_smp_subfrm_cnt==LEN_SUB_FRAME-1) ? 18'd0 : r_smp_subfrm_cnt + 1'd1 ;    
    end
end

reg [3:0]  r_subfrm ;
always@(posedge i_clk) begin
    if(r_frame_sync_retard) begin
        r_subfrm    <=  4'd0 ;    
    end
    else if(r_smp_subfrm_cnt==LEN_SUB_FRAME-1) begin
        r_subfrm    <=  r_subfrm==NUM_SUBFRM_FRAME-1'd1 ? 4'd0 : r_subfrm + 1'd1 ;    
    end
end

reg [17:0]  r_smp_slot_cnt  ;
reg [7:0]   r_slot          ; 
reg [2:0]   r_slot_lcp      ;
always@(*) begin
    case(i_mu) 
        MU_SCS_015K : r_slot_lcp = 3'd0                 ;
        MU_SCS_030K : r_slot_lcp = 3'd0                 ;
        MU_SCS_060K : r_slot_lcp = {2'd0,r_slot[0:0]}   ;
        MU_SCS_120K : r_slot_lcp = {1'd0,r_slot[1:0]}   ;
        MU_SCS_240K : r_slot_lcp = r_slot[2:0] ;
        default     : r_slot_lcp = {1'd0,r_slot[1:0]}   ;
    endcase
end

always@(posedge i_clk) begin
    if(r_frame_sync_retard) begin
        r_smp_slot_cnt <= 18'd0 ;    
    end
    else begin
        if(r_slot_lcp==3'd0) begin
            r_smp_slot_cnt <= (r_smp_slot_cnt==LEN_LCP_SLOT-1) ? 18'd0 : r_smp_slot_cnt + 1'd1 ;    
        end
        else if(r_slot==NUM_SLOT_FRAME) begin
            r_smp_slot_cnt <= r_smp_slot_cnt + 1'd1 ;    
        end
        else begin
            r_smp_slot_cnt <= (r_smp_slot_cnt==LEN_NCP_SLOT-1) ? 18'd0 : r_smp_slot_cnt + 1'd1 ;    
        end
    end
end

always@(posedge i_clk) begin
    if(r_frame_sync_retard) begin
        r_slot   <=    8'd0   ;    
    end
    else if(r_en) begin
        if(r_slot_lcp==3'd0) begin
            if(r_smp_slot_cnt==LEN_LCP_SLOT-1) begin
                r_slot <= r_slot + 1'd1 ;
            end
        end
        else if(r_slot!=NUM_SLOT_FRAME)begin
            if(r_smp_slot_cnt==LEN_NCP_SLOT-1) begin
                r_slot <= r_slot + 1'd1 ;
            end
        end
    end
    else begin
        r_slot   <=    8'd0   ;    
    end
end

reg [14:0]  r_smp_symbol_cnt ;
reg [3:0]   r_symbol    ;
always@(posedge i_clk) begin
    if(r_frame_sync_retard) begin
        r_smp_symbol_cnt   <=    15'd0 ;    
    end
    else begin
        if(r_slot_lcp==3'd0&&(r_symbol==4'd0||(r_symbol==4'd7&&(~|i_mu)))) begin
            r_smp_symbol_cnt   <=    (r_smp_symbol_cnt==LEN_LCP_SYM-1) ? 12'd0 :r_smp_symbol_cnt + 1'd1 ;    
        end
        else begin
            r_smp_symbol_cnt   <=    (r_smp_symbol_cnt==LEN_NCP_SYM-1) ? 12'd0 :r_smp_symbol_cnt + 1'd1 ;    
        end
    end
end

always@(posedge i_clk) begin
    if(r_frame_sync_retard) begin
        r_symbol   <=    4'd0  ;    
    end
    else begin
        if(r_slot_lcp==3'd0&&(r_symbol==4'd0||(r_symbol==4'd7&&(~|i_mu)))) begin
            if(r_smp_symbol_cnt==LEN_LCP_SYM-1) begin
                r_symbol  <= (r_symbol==NUM_SYM_SLOT-1) ? 4'd0 : r_symbol + 1'd1 ;    
            end
        end
        else begin
            if(r_smp_symbol_cnt==LEN_NCP_SYM-1) begin
                r_symbol  <= (r_symbol==NUM_SYM_SLOT-1) ? 4'd0 : r_symbol + 1'd1 ;    
            end
        end
    end
end

reg [3:0]   r_slot_subfrm   ;
always@(posedge i_clk) begin
    case(i_mu) 
        MU_SCS_015K : r_slot_subfrm <= 4'd0                  ;
        MU_SCS_030K : r_slot_subfrm <= {3'd0,r_slot[0:0]}    ;
        MU_SCS_060K : r_slot_subfrm <= {2'd0,r_slot[1:0]}    ;
        MU_SCS_120K : r_slot_subfrm <= {1'd0,r_slot[2:0]}    ;
        MU_SCS_240K : r_slot_subfrm <= r_slot[3:0]           ;
        default     : r_slot_subfrm <= 4'd0                  ;
    endcase
end

assign  o_frame_sync    =   r_retard>1 ? (r_frame_sync_retard_cnt==r_retard) : rr_frame_sync_retard ; //r_frame_sync_retard+1clk
assign  o_subfrm_sync   =   r_en&&r_smp_subfrm_cnt==18'd0    ;
assign  o_slot_sync     =   r_en&&r_symbol==8'd0&&r_smp_slot_cnt==18'd0    ;
assign  o_symbol_sync   =   r_en&&r_smp_symbol_cnt==15'd0    ;
assign  o_subfrm        =   r_subfrm    ;
assign  o_slot          =   SLOT_INC_TYPE == "SUBFRAME" ?  {4'd0,r_slot_subfrm} : r_slot    ;
assign  o_symbol        =   r_symbol    ;

assign  o_smp_symbol_cnt = r_smp_symbol_cnt ;

endmodule
