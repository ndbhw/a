module  pcap_read_timing
(
 
    input wire  clk_156p25_sim,
    input wire  clk_x8,
    input wire  rst_x8,
    
    output wire L0_DEFRAMER_CLK,
    output wire tick_1pps,
    output wire frame_sync,
    output wire [11:0] frame_num,
     
    output wire mac_rx_valid,
    output wire mac_rx_last ,
    output wire [7:0] mac_rx_keep ,
    output wire [63:0]mac_rx_data 
    

);

    localparam MAX_axc_U = 3*8 ;//6*4;
    localparam MAX_axc_C = 1*8 ;//1*4;
    
    
assign L0_DEFRAMER_CLK = clk_156p25_sim;
    

reg ready_pcap;
reg [15:0] d_ready_pcap;
reg run_ready ;

reg [15:0] cnt_axc;
reg [15:0] cnt_axc_C;
reg [15:0] MAX_cnt_axc;

wire CU_symbol_sync;
wire [3:0] CU_symbol;

wire [63:0] w_m_tdata;
wire [7:0] w_m_tkeep;
wire w_m_tlast;
wire w_m_valid;
wire rise_m_tlast;
wire [1:0] CU_check;

wire [63:0] w_pcap_time;

reg [7:0] d_m_tlast;

wire clk_x8_frame_sync;

wire [14:0]  w_smp_symbol_cnt ;

wire frame_sync2;


    pulse_frame_sync_clkx8 gen_pulse_frame_sync(
        .clk           (clk_x8), 
        .rst           (rst_x8), 
        .sim_frame_sync(clk_x8_frame_sync)
    );



assign rise_m_tlast = (~d_m_tlast[0])&w_m_tlast;

always @(posedge clk_x8) begin
    d_m_tlast <= {d_m_tlast[6:0],w_m_tlast};
    
  //  d_ready_pcap <= {d_ready_pcap[14:0],ready_pcap};
end

always @(posedge clk_156p25_sim) begin

    d_ready_pcap <= {d_ready_pcap[14:0],ready_pcap};
end


//pcap_reader  pcap_reader_CHECK(
//   .clk            (clk_156p25_sim),
//   .rst            (rst_x8),
//   .ready          (32'd1)
//);

pcap_reader  pcap_reader_inst(
   .clk            (clk_156p25_sim),
   .rst            (rst_x8),
   .ready          (d_ready_pcap[0]),
   .m_tdata (w_m_tdata),
   .m_tkeep  (w_m_tkeep),
   .m_tlast        (w_m_tlast),
   .o_m_valid        (w_m_valid),
   .pcap_time      (w_pcap_time),
   .CU_check (CU_check)
);


ref_symbol_gen CU_symbol_gen
(
     .i_clk                 ( clk_x8      )          
    ,.i_mu                  ( 32'd1              )
    ,.i_retard              ( 32'd1              )
    ,.i_frame_sync          ( clk_x8_frame_sync)          
    ,.i_en                  ( 1'd1             )          
    ,.o_frame_sync          (   )   
    ,.o_subfrm_sync         (   )   
    ,.o_slot_sync           (   )   
    ,.o_symbol_sync         (CU_symbol_sync)   
    ,.o_subfrm              (   )          
    ,.o_slot                (   )          
    ,.o_symbol              (CU_symbol)
    ,.o_smp_symbol_cnt      (w_smp_symbol_cnt)         
);

reg first_run;

    always @(posedge clk_x8) begin
        if(rst_x8 == 1'b1) begin
            ready_pcap <= 1'b0;
            cnt_axc_C <= 32'd0;       
            run_ready <= 1'b0;
            MAX_cnt_axc <= 32'd0;
            cnt_axc <= 32'd0;
            first_run <= 1'b0;
        end
        else begin
        
            if(CU_check == 32'd1 )
                MAX_cnt_axc <= MAX_axc_C;
            else if(CU_check == 32'd2)
                MAX_cnt_axc <= MAX_axc_U;
        
            //if(w_pcap_time==32'd0) begin
            if(first_run == 1'b0) begin
                if(CU_symbol== 32'd12) begin
                    if(cnt_axc_C<MAX_axc_C) begin
                        ready_pcap <= 1'b1;           
                    end
                    else begin
                        ready_pcap <= 1'b0;
                        first_run <= 1'b1;
                    end             
                end  
                if((rise_m_tlast==1'b1) && (cnt_axc_C<MAX_axc_C))
                    cnt_axc_C <= cnt_axc_C + 32'd1;           
            end
            else begin
                if(CU_symbol == 32'd0)
                    run_ready <= 1'b1;
                
                if(run_ready == 1'b1) begin
    ////////////////////////////////////////////
                

                                                 
                    if(cnt_axc<MAX_cnt_axc) begin
                        ready_pcap <= 1'b1;           
                    end
                    else begin
                        ready_pcap <= 1'b0;
                    end             
                 
                    if((rise_m_tlast==1'b1) && (cnt_axc<MAX_cnt_axc))
                        cnt_axc <= cnt_axc + 32'd1; 
                            
                    if(CU_symbol_sync == 1'b1)
                        cnt_axc <= 32'd0;
                
                    if((CU_symbol ==  32'd11) && (w_smp_symbol_cnt == 32'd7600))
                        cnt_axc <= 32'd0;
    ////////////////////////////////////////////          
                end
            end       
        end
    end

   assign mac_rx_valid = w_m_valid  ;
   assign mac_rx_last  = w_m_tlast  ;
   assign mac_rx_keep  = w_m_tkeep  ;
   assign mac_rx_data  = w_m_tdata  ;

   assign frame_num = 32'd0;
   
   
   
   
    reg [31:0] cnt_gen_frame_sync;
    reg en_gen_frame_sync;
    wire frame_sync1;
    
    always @(posedge clk_156p25_sim) begin
        if((rst_x8)||(first_run==1'b0)) begin
            en_gen_frame_sync <= 1'b0;
            cnt_gen_frame_sync <= 32'd0;
        
        end
        else begin
            if(cnt_gen_frame_sync > 32'd1000+32'd10098+32'd30-32'd70) begin
                en_gen_frame_sync <= 1'b1;
            end
            else begin
                cnt_gen_frame_sync <= cnt_gen_frame_sync + 32'd1;
            end
        
        end
    
    end
    
    
    oran_timing_emulator frame_syn (
        .oran_clk       (clk_156p25_sim       ),
        .oran_rst       (rst_x8       ),
         
        .oran_enable    (en_gen_frame_sync    ),
        
        .oran_tick_1pps (tick_1pps),
        .oran_frame_sync(frame_sync1),
        .oran_frame_num ( ),
                         
        .oran_subf_tick ( ),
        .oran_subf_index(),
        .oran_symb_tick ( ),
        .oran_symb_index()
    );
    
    
    reg [31:0] cnt_gen_frame_sync2;
    reg en_gen_frame_sync2;
    
    
    always @(posedge clk_156p25_sim) begin
        if((rst_x8)||(first_run==1'b0)) begin
            en_gen_frame_sync2 <= 1'b0;
            cnt_gen_frame_sync2 <= 32'd0;
        
        end
        else begin
            if(cnt_gen_frame_sync2 > 32'd1000+32'd10098+32'd30-32'd10000) begin
                en_gen_frame_sync2 <= 1'b1;
            end
            else begin
                cnt_gen_frame_sync2 <= cnt_gen_frame_sync2 + 32'd1;
            end
        
        end
    
    end
    
    
    oran_timing_emulator frame_syn2 (
        .oran_clk       (clk_156p25_sim       ),
        .oran_rst       (rst_x8       ),
         
        .oran_enable    (en_gen_frame_sync2    ),
        
        .oran_tick_1pps (),
        .oran_frame_sync(frame_sync2),
        .oran_frame_num ( ),
                         
        .oran_subf_tick ( ),
        .oran_subf_index(),
        .oran_symb_tick ( ),
        .oran_symb_index()
    );  
    
    
    assign frame_sync = frame_sync1 ;//| frame_sync2;

endmodule