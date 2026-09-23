////////////////////////////////////////////////////////////////////////////////
//
// Copyright(c) 2019 Samsung Electronics Inc. All rights reserved
//
//  Project      : ATnT HRU micro
//  Module       : ref_sync_gen
//  Author       : jyzoo.lee@samsung.com
//  Description  : reference sync generator 
//
//  Revision History
//  ------------+---------------+-----------------------------------------------
//     Date     |   Author      |   Description
//  ------------+---------------+-----------------------------------------------
//   2019.06.26 |jyzoo.lee      | 245.76MHz Ref Sync Gen Inital Release
//  ------------+---------------+-----------------------------------------------
//   2019.08.05 |jyzoo.lee      | Extended Subframe -> frame, 240k Support
//  ------------+---------------+-----------------------------------------------
//   2019.08.21 |jyzoo.lee      | Retard value parameter -> input port
//  ------------+---------------+-----------------------------------------------
//   2019.11.21 |jyzoo.lee      | fix logic of retarded sync for pnr logic delay
//  ------------+---------------+-----------------------------------------------
//   2019.12.02 |jyzoo.lee      | Reset Removed 
//  ------------+---------------+-----------------------------------------------
//   2019.12.13 |jyzoo.lee      | Bug Fix 
//  ------------+---------------+-----------------------------------------------
//
////////////////////////////////////////////////////////////////////////////////

module ref_sync_gen_3_75kHz
#(
    parameter   MU              =   0 
)(
         input   wire                i_clk           
        ,input   wire   [21:0]       i_retard
        ,input   wire                i_frame_sync           
        ,input   wire                i_en            
        ,output  wire                o_frame_sync           
        ,output  wire                o_subfrm_sync          
        ,output  wire                o_slot_sync            
        ,output  wire                o_symbol_sync          
        ,output  wire                o_symbol_ch_sync  
        ,output  wire   [3:0]        o_subframe
        ,output  wire   [7:0]        o_slot                 
        ,output  wire   [3:0]        o_symbol               
);

localparam      LEN_SUB_FRAME       =  245760                ;
localparam      NUM_SLOT_SUBFRM_MU  =  8'd9                  ;     
localparam      NUM_SYMBOL_SLOT     =  14                    ;
localparam      LEN_LCP_SYM         =  (256+8192+2304)*8     ;     
localparam      LEN_NCP_SYM         =  (256+8192)*8          ;     
// KTY localparam      LEN_LCP_SLOT_SYM    =  245760         ;     
// KTY localparam      LEN_NCP_SLOT_SYM    =  245760         ;     

// KTY
localparam      LEN_SLOT            =  122880                ;
localparam      LEN_LCP_SYM_CH      =  ((352+4096)*2)/2      ;// 17664/Path_NUM ?? ; 
localparam      LEN_NCP_SYM_CH      =  ((288+4096)*2)/2      ;// 17536/Path_NUM ?? ; 

//retard sync
reg r_frame_sync_retard_en  ;
reg [21:0]r_frame_sync_retard_cnt ;
always@(posedge i_clk) begin
    if(i_frame_sync) begin
        r_frame_sync_retard_en <=  1'd1     ;
    end 
    else if(r_frame_sync_retard_cnt==i_retard) begin
        r_frame_sync_retard_en <=  1'd0     ;
    end
end

always@(posedge i_clk) begin
    if(i_frame_sync) begin
        r_frame_sync_retard_cnt <=  22'd0    ;
    end
    else if(r_frame_sync_retard_en) begin
        r_frame_sync_retard_cnt <= (r_frame_sync_retard_cnt==i_retard) ? 22'd0 : r_frame_sync_retard_cnt+1'd1    ;
    end
end

reg r_frame_sync_retard ;
reg rr_frame_sync_retard ;
always@(posedge i_clk) begin
    r_frame_sync_retard <= (i_retard>1) ? (r_frame_sync_retard_en&&r_frame_sync_retard_cnt==i_retard-2) : i_frame_sync ;
    rr_frame_sync_retard <= r_frame_sync_retard ;
end

reg [17:0]  r_smp_subfrm_cnt ;
reg [3:0]   r_subframe;
reg [7:0]   r_slot    ;
always@(posedge i_clk) begin
    if(r_frame_sync_retard) begin
        r_smp_subfrm_cnt   <=    18'd0 ;    
        r_subframe         <=    4'd0 ;
        r_slot             <=    8'd0 ;
    end
    else begin
        r_smp_subfrm_cnt   <=    (r_smp_subfrm_cnt==LEN_SUB_FRAME-1) ? 18'd0 : r_smp_subfrm_cnt + 1'd1 ;    
        r_subframe         <=    (r_smp_subfrm_cnt==LEN_SUB_FRAME-1) ? (r_subframe==9) ? 4'd0 : r_subframe + 1'd1 : r_subframe ; 
        r_slot             <=    (r_smp_subfrm_cnt==LEN_SUB_FRAME-1) ?  8'd0 : (r_smp_subfrm_cnt==LEN_SLOT-1) ? r_slot + 1'd1 : r_slot ;
    end
end

//reg [14:0]  r_smp_slot_cnt ;
//wire [2:0] w_slot_lcp   ;
//assign  w_slot_lcp  =   (MU==3)  ?   {1'd0,r_slot[2:0]} :   r_slot[3:0] ;
//
//always@(posedge i_clk) begin
//    if(r_frame_sync_retard) begin
//        r_smp_slot_cnt   <=    15'd0 ;    
//    end
//    else begin
//        if(w_slot_lcp==3'd0) begin
//            r_smp_slot_cnt   <=    (r_smp_slot_cnt==LEN_LCP_SLOT_SYM-1) ? 15'd0 : r_smp_slot_cnt + 1'd1 ;    
//        end
//        else if(r_slot==NUM_SLOT_SUBFRM_MU) begin
//            r_smp_slot_cnt   <=     r_smp_slot_cnt + 1'd1 ;    
//        end
//        else begin
//            r_smp_slot_cnt   <=    (r_smp_slot_cnt==LEN_NCP_SLOT_SYM-1) ? 15'd0 : r_smp_slot_cnt + 1'd1 ;    
//        end
//    end
//end

//always@(posedge i_clk) begin
//    if(r_frame_sync_retard) begin
//        r_slot   <=    8'd0   ;    
//    end
//    else begin
//        if(w_slot_lcp==3'd0) begin
//            if(r_smp_slot_cnt==LEN_LCP_SLOT_SYM-1) begin
//                r_slot <= r_slot + 1'd1 ;
//            end
//        end
//        else if(r_slot!=NUM_SLOT_SUBFRM_MU)begin
//            if(r_smp_slot_cnt==LEN_NCP_SLOT_SYM-1) begin
//                r_slot <= r_slot + 1'd1 ;
//            end
//        end
//    end
//end

reg [14:0]  r_smp_symbol_cnt ;
reg [3:0]   r_symbol    ;
//always@(posedge i_clk) begin
//    if(r_frame_sync_retard) begin
//        r_smp_symbol_cnt   <=    12'd0 ;    
//    end
//    else begin
//        if(w_slot_lcp==3'd0&&r_symbol==4'd0) begin
//            r_smp_symbol_cnt   <=    (r_smp_symbol_cnt==LEN_LCP_SYM-1) ? 12'd0 :r_smp_symbol_cnt + 1'd1 ;    
//        end
//        else if(r_slot!=NUM_SLOT_SUBFRM_MU||r_symbol!=NUM_SYMBOL_SLOT-1) begin
//            r_smp_symbol_cnt   <=    (r_smp_symbol_cnt==LEN_NCP_SYM-1) ? 12'd0 :r_smp_symbol_cnt + 1'd1 ;    
//        end
//        else begin
//            r_smp_symbol_cnt   <=    r_smp_symbol_cnt + 1'd1 ;    
//        end
//    end
//end

always@(posedge i_clk) begin
    if(r_frame_sync_retard) begin
        r_smp_symbol_cnt   <=    12'd0 ;    
    end
    else begin
        if(r_symbol==4'd6) begin
            r_smp_symbol_cnt   <=    (r_smp_symbol_cnt==LEN_LCP_SYM-1) ? 12'd0 :r_smp_symbol_cnt + 1'd1 ;    
        end
        else begin
            r_smp_symbol_cnt   <=    (r_smp_symbol_cnt==LEN_NCP_SYM-1) ? 12'd0 :r_smp_symbol_cnt + 1'd1 ;     
        end
    end
end

//// KTY
//reg [14:0]  r_smp_symbol_ch_cnt ;
//always@(posedge i_clk) begin
//    if(r_frame_sync_retard) begin
//        r_smp_symbol_cnt    <=    12'd0 ;    
//        r_smp_symbol_ch_cnt <=    12'd0 ;  
//    end
//    else begin
//// 15kHz        if(r_symbol==4'd0||r_symbol==4'd7) begin
//        if(r_symbol==4'd0) begin
//            r_smp_symbol_cnt   <=    (r_smp_symbol_cnt==LEN_LCP_SYM-1) ? 12'd0 :r_smp_symbol_cnt + 1'd1 ;    
//            r_smp_symbol_ch_cnt <=   (r_smp_symbol_ch_cnt==LEN_LCP_SYM_CH-1) ? 12'd0 :r_smp_symbol_ch_cnt + 1'd1 ;  
//        end
//        else begin
//            r_smp_symbol_cnt   <=    (r_smp_symbol_cnt==LEN_NCP_SYM-1) ? 12'd0 :r_smp_symbol_cnt + 1'd1 ;     
//            r_smp_symbol_ch_cnt <=   (r_smp_symbol_ch_cnt==LEN_NCP_SYM_CH-1) ? 12'd0 :r_smp_symbol_ch_cnt + 1'd1 ;  
//        end
//    end
//end


//always@(posedge i_clk) begin
//    if(r_frame_sync_retard) begin
//        r_symbol   <=    4'd0  ;    
//    end
//    else begin
//        if(w_slot_lcp==3'd0&&r_symbol==4'd0) begin
//            if(r_smp_symbol_cnt==LEN_LCP_SYM-1) begin
//                r_symbol  <= (r_symbol==NUM_SYMBOL_SLOT-1) ? 4'd0 : r_symbol + 1'd1 ;    
//            end
//        end
//        else if(r_slot!=NUM_SLOT_SUBFRM_MU||r_symbol!=NUM_SYMBOL_SLOT-1) begin
//            if(r_smp_symbol_cnt==LEN_NCP_SYM-1) begin
//                r_symbol  <= (r_symbol==NUM_SYMBOL_SLOT-1) ? 4'd0 : r_symbol + 1'd1 ;    
//            end
//        end
//    end
//end

always@(posedge i_clk) begin
    if(r_frame_sync_retard) begin
        r_symbol   <=    4'd0  ;    
    end
    else begin
// 15kHz        if(r_symbol==4'd0||r_symbol==4'd7) begin
        if(r_symbol==4'd6) begin
            if(r_smp_symbol_cnt==LEN_LCP_SYM-1) begin
                r_symbol  <= 4'd0 ;    
            end
        end
        else begin
            if(r_smp_symbol_cnt==LEN_NCP_SYM-1) begin
                r_symbol  <= r_symbol + 1'd1 ;    
            end
        end
    end
end

wire [3:0] w_slot ;
assign  w_slot            =   (MU==3)  ?   {1'd0,r_slot[2:0]} :   r_slot[3:0] ;

assign  o_frame_sync      =   i_retard>1 ? (r_frame_sync_retard_cnt==i_retard) : rr_frame_sync_retard ; //r_frame_sync_retard+1clk
//assign  o_subfrm_sync   =   i_en&&w_slot==4'd0&&r_smp_subfrm_cnt==18'd0 ;
assign  o_subfrm_sync     =   i_en&&r_smp_subfrm_cnt==18'd0    ;
//assign  o_slot_sync     =   i_en&&r_symbol==8'd0&&r_smp_slot_cnt==15'd0 ;
assign  o_slot_sync       =   i_en&&r_symbol==8'd0&&(r_smp_subfrm_cnt==18'd0||r_smp_subfrm_cnt==LEN_SLOT) ; 
assign  o_symbol_sync     =   i_en&&r_smp_symbol_cnt==12'd0 ;
// KTY
assign  o_symbol_ch_sync  =   1'd0 ; //i_en&&r_smp_symbol_ch_cnt==12'd0 ;
assign  o_subframe        =   r_subframe ;
assign  o_slot            =   r_slot ;
assign  o_symbol          =   r_symbol ;

endmodule
