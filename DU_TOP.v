`timescale 1fs/1fs
//////////////////////////////////////////////////////////////////////////////////
// Module Name: DU_TOP
// Description: DU emulation. Self-contained: generates its own reference clocks
//              and reset, wraps the Ethernet core support layer, and streams
//              incrementing-counter frames out of the GT serial pins forever.
//////////////////////////////////////////////////////////////////////////////////

(* DowngradeIPIdentifiedWarnings="yes" *)
module DU_TOP
(
    input  wire gt_rxp_in,
    input  wire gt_rxn_in,
    output wire gt_txp_out,
    output wire gt_txn_out,

    output wire rx_gt_locked_led,
    output wire rx_block_lock_led

    // output wire        rx_axis_tvalid,
    // output wire [63:0] rx_axis_tdata,
    // output wire        rx_axis_tlast,
    // output wire [7:0]  rx_axis_tkeep,
    // output wire        rx_axis_tuser
);

  // wire gt_rxp_in;
  // wire gt_rxn_in;
  
  wire        rx_axis_tvalid;
  wire [63:0] rx_axis_tdata;
  wire        rx_axis_tlast ; 
  wire [7:0]  rx_axis_tkeep ; 
  wire        rx_axis_tuser;  
  
  
  // assign gt_rxp_in = gt_txp_out;
  // assign gt_rxn_in = gt_txn_out;

  //// Frame size in bytes, header included.
  parameter integer PKT_LENGTH = 256;
  //// Idle beats inserted between two frames.
  parameter integer IFG_CYCLES = 4;

  ////--------------------------------------------------------------------------
  //// Clock and reset generation
  ////--------------------------------------------------------------------------
  wire        gt_refclk_p;
  wire        gt_refclk_n;
  wire        dclk;
  reg         sys_reset;

  wire        clk_122p88;
  wire        clk_156p25;
  wire [0:0]  clk_156p25_p;
  wire [0:0]  clk_156p25_n;
  wire        clk_161p1328;
  wire [0:0]  clk_161p1328_p;
  wire [0:0]  clk_161p1328_n;
  wire        clk_245p76;
  wire        clk_30p72;
  wire        clk_61p44;

  BD_CLK_wrapper i_bd_clk
  (
    .clk_100          (dclk),
    .clk_122p88       (clk_122p88),
    .clk_156p25       (clk_156p25),
    .clk_156p25_N     (clk_156p25_n),
    .clk_156p25_P     (clk_156p25_p),
    .clk_161p1328     (clk_161p1328),
    .clk_161p1328_N   (clk_161p1328_n),
    .clk_161p1328_P   (clk_161p1328_p),
    .clk_245p76       (clk_245p76),
    .clk_30p72        (clk_30p72),
    .clk_61p44        (clk_61p44)
  );

  assign gt_refclk_p = clk_161p1328_p[0];
  assign gt_refclk_n = clk_161p1328_n[0];

  initial begin
    sys_reset = 1'b1;
    repeat (20) @(posedge dclk);
    sys_reset = 1'b0;
    $display("INFO @%0t : DU sys_reset released", $time);
  end

  //// Progress reporting
  initial begin
    wait (rx_gt_locked_led);
    $display("INFO @%0t : DU GT LOCKED", $time);
    wait (rx_block_lock_led);
    $display("INFO @%0t : DU RX BLOCK LOCKED", $time);
  end

  //// Clocks and resets produced by the core
  wire        tx_clk_out_0;
  wire        rx_clk_out_0;
  wire        rx_core_clk_0;
  wire        user_tx_reset_0;
  wire        user_rx_reset_0;
  wire        gt_refclk_out;

  assign rx_core_clk_0 = rx_clk_out_0;

  //// TX AXI-Stream driven by the local generator
  wire        tx_axis_tready_0;
  reg         tx_axis_tvalid_0;
  reg  [63:0] tx_axis_tdata_0;
  reg         tx_axis_tlast_0;
  reg  [7:0]  tx_axis_tkeep_0;
  wire        tx_axis_tuser_0;

  //// RX AXI-Stream brought out for observation
  wire        rx_axis_tvalid_0;
  wire [63:0] rx_axis_tdata_0;
  wire        rx_axis_tlast_0;
  wire [7:0]  rx_axis_tkeep_0;
  wire        rx_axis_tuser_0;
  wire [55:0] rx_preambleout_0;

  wire        stat_rx_block_lock_0;
  wire        stat_rx_status_0;

  assign rx_axis_tvalid = rx_axis_tvalid_0;
  assign rx_axis_tdata  = rx_axis_tdata_0;
  assign rx_axis_tlast  = rx_axis_tlast_0;
  assign rx_axis_tkeep  = rx_axis_tkeep_0;
  assign rx_axis_tuser  = rx_axis_tuser_0;

  assign rx_gt_locked_led  = ~user_rx_reset_0;
  assign rx_block_lock_led = stat_rx_block_lock_0 & stat_rx_status_0;

  assign tx_axis_tuser_0 = 1'b0;

  ////--------------------------------------------------------------------------
  //// Frame generator: incrementing 64-bit counter payload, runs forever.
  ////--------------------------------------------------------------------------
  localparam [47:0] DEST_ADDR   = 48'hFF_FF_FF_FF_FF_FF;
  localparam [47:0] SOURCE_ADDR = 48'h14_FE_B5_DD_9A_82;
  localparam [15:0] LENGTH_TYPE = 16'h0600;

  localparam integer BEATS_PER_PKT = (PKT_LENGTH + 7) / 8;

  localparam [1:0] ST_IDLE = 2'd0,
                   ST_HDR  = 2'd1,
                   ST_DATA = 2'd2,
                   ST_END  = 2'd3;

  reg [1:0]  state;
  reg [15:0] beat_cnt;
  reg [15:0] ifg_cnt;
  reg [63:0] data_cnt;
  reg [31:0] pkt_cnt;

  //// Hold off traffic until the link is up, the same way the example design
  //// gates its generator with pktgen_enable after block lock is reached.
  reg link_up_meta;
  reg link_up_sync;

  always @(posedge tx_clk_out_0) begin
    if (user_tx_reset_0) begin
      link_up_meta <= 1'b0;
      link_up_sync <= 1'b0;
    end
    else begin
      link_up_meta <= stat_rx_block_lock_0 & stat_rx_status_0;
      link_up_sync <= link_up_meta;
    end
  end

  always @(posedge tx_clk_out_0) begin
    if (user_tx_reset_0) begin
      state            <= ST_IDLE;
      tx_axis_tvalid_0 <= 1'b0;
      tx_axis_tdata_0  <= 64'd0;
      tx_axis_tlast_0  <= 1'b0;
      tx_axis_tkeep_0  <= 8'hFF;
      beat_cnt         <= 16'd0;
      ifg_cnt          <= 16'd0;
      data_cnt         <= 64'd1;
      pkt_cnt          <= 32'd0;
    end
    else begin
      case (state)
        ST_IDLE: begin
          tx_axis_tvalid_0 <= 1'b0;
          tx_axis_tlast_0  <= 1'b0;
          if (|ifg_cnt) begin
            ifg_cnt <= ifg_cnt - 16'd1;
          end
          else if (link_up_sync) begin
            //// Beat 0: DA[47:0] + SA[47:32]
            tx_axis_tvalid_0 <= 1'b1;
            tx_axis_tkeep_0  <= 8'hFF;
            tx_axis_tdata_0  <= {DEST_ADDR, SOURCE_ADDR[47:32]};
            beat_cnt         <= 16'd1;
            state            <= ST_HDR;
          end
        end

        ST_HDR: begin
          if (tx_axis_tready_0) begin
            //// Beat 1: SA[31:0] + type + first counter bytes
            tx_axis_tdata_0 <= {SOURCE_ADDR[31:0], LENGTH_TYPE, data_cnt[15:0]};
            data_cnt        <= data_cnt + 64'd1;
            beat_cnt        <= beat_cnt + 16'd1;
            state           <= ST_DATA;
          end
        end

        ST_DATA: begin
          if (tx_axis_tready_0) begin
            tx_axis_tdata_0 <= data_cnt;
            data_cnt        <= data_cnt + 64'd1;
            beat_cnt        <= beat_cnt + 16'd1;
            if (beat_cnt >= (BEATS_PER_PKT - 1)) begin
              tx_axis_tlast_0 <= 1'b1;
              tx_axis_tkeep_0 <= 8'hFF;
              state           <= ST_END;
            end
          end
        end

        ST_END: begin
          if (tx_axis_tready_0) begin
            tx_axis_tvalid_0 <= 1'b0;
            tx_axis_tlast_0  <= 1'b0;
            pkt_cnt          <= pkt_cnt + 32'd1;
            ifg_cnt          <= IFG_CYCLES[15:0];
            state            <= ST_IDLE;
          end
        end

        default: state <= ST_IDLE;
      endcase
    end
  end

  //// Report each frame handed to the core.
  always @(posedge tx_clk_out_0) begin
    if (!user_tx_reset_0 && tx_axis_tvalid_0 && tx_axis_tlast_0 && tx_axis_tready_0)
      $display("INFO @%0t : DU TX packet %0d sent, last beat = %h",
               $time, pkt_cnt + 32'd1, tx_axis_tdata_0);
  end

  ////--------------------------------------------------------------------------
  //// Ethernet core + GT
  ////--------------------------------------------------------------------------
  xxv_ethernet_DU_core_support i_core_support
  (
    .gt_rxp_in_0                       (gt_rxp_in),
    .gt_rxn_in_0                       (gt_rxn_in),
    .gt_txp_out_0                      (gt_txp_out),
    .gt_txn_out_0                      (gt_txn_out),
    .tx_clk_out_0                      (tx_clk_out_0),
    .rx_core_clk_0                     (rx_core_clk_0),
    .rx_clk_out_0                      (rx_clk_out_0),

    //// AXI4-Lite left idle
    .s_axi_aclk_0                      (dclk),
    .s_axi_aresetn_0                   (~sys_reset),
    .s_axi_awaddr_0                    (32'd0),
    .s_axi_awvalid_0                   (1'b0),
    .s_axi_awready_0                   (),
    .s_axi_wdata_0                     (32'd0),
    .s_axi_wstrb_0                     (4'd0),
    .s_axi_wvalid_0                    (1'b0),
    .s_axi_wready_0                    (),
    .s_axi_bresp_0                     (),
    .s_axi_bvalid_0                    (),
    .s_axi_bready_0                    (1'b0),
    .s_axi_araddr_0                    (32'd0),
    .s_axi_arvalid_0                   (1'b0),
    .s_axi_arready_0                   (),
    .s_axi_rdata_0                     (),
    .s_axi_rresp_0                     (),
    .s_axi_rvalid_0                    (),
    .s_axi_rready_0                    (1'b0),
    .pm_tick_0                         (1'b0),
    .user_reg0_0                       (),
    .rxrecclkout_0                     (),

    .rx_reset_0                        (1'b0),
    .user_rx_reset_0                   (user_rx_reset_0),

    .rx_axis_tvalid_0                  (rx_axis_tvalid_0),
    .rx_axis_tdata_0                   (rx_axis_tdata_0),
    .rx_axis_tlast_0                   (rx_axis_tlast_0),
    .rx_axis_tkeep_0                   (rx_axis_tkeep_0),
    .rx_axis_tuser_0                   (rx_axis_tuser_0),
    .rx_preambleout_0                  (rx_preambleout_0),

    //// PTP unused
    .tx_ptp_1588op_in_0                (2'b00),
    .tx_ptp_tag_field_in_0             (16'd0),
    .tx_ptp_tstamp_valid_out_0         (),
    .tx_ptp_tstamp_tag_out_0           (),
    .tx_ptp_tstamp_out_0               (),
    .rx_ptp_tstamp_valid_out_0         (),
    .rx_ptp_tstamp_out_0               (),
    .ctl_rx_systemtimerin_0            (80'd0),
    .ctl_tx_systemtimerin_0            (80'd0),

    //// RX stats
    .stat_rx_block_lock_0              (stat_rx_block_lock_0),
    .stat_rx_framing_err_valid_0       (),
    .stat_rx_framing_err_0             (),
    .stat_rx_hi_ber_0                  (),
    .stat_rx_valid_ctrl_code_0         (),
    .stat_rx_bad_code_0                (),
    .stat_rx_total_packets_0           (),
    .stat_rx_total_good_packets_0      (),
    .stat_rx_total_bytes_0             (),
    .stat_rx_total_good_bytes_0        (),
    .stat_rx_packet_small_0            (),
    .stat_rx_jabber_0                  (),
    .stat_rx_packet_large_0            (),
    .stat_rx_oversize_0                (),
    .stat_rx_undersize_0               (),
    .stat_rx_toolong_0                 (),
    .stat_rx_fragment_0                (),
    .stat_rx_packet_64_bytes_0         (),
    .stat_rx_packet_65_127_bytes_0     (),
    .stat_rx_packet_128_255_bytes_0    (),
    .stat_rx_packet_256_511_bytes_0    (),
    .stat_rx_packet_512_1023_bytes_0   (),
    .stat_rx_packet_1024_1518_bytes_0  (),
    .stat_rx_packet_1519_1522_bytes_0  (),
    .stat_rx_packet_1523_1548_bytes_0  (),
    .stat_rx_bad_fcs_0                 (),
    .stat_rx_packet_bad_fcs_0          (),
    .stat_rx_stomped_fcs_0             (),
    .stat_rx_packet_1549_2047_bytes_0  (),
    .stat_rx_packet_2048_4095_bytes_0  (),
    .stat_rx_packet_4096_8191_bytes_0  (),
    .stat_rx_packet_8192_9215_bytes_0  (),
    .stat_rx_bad_preamble_0            (),
    .stat_rx_bad_sfd_0                 (),
    .stat_rx_got_signal_os_0           (),
    .stat_rx_test_pattern_mismatch_0   (),
    .stat_rx_truncated_0               (),
    .stat_rx_local_fault_0             (),
    .stat_rx_remote_fault_0            (),
    .stat_rx_internal_local_fault_0    (),
    .stat_rx_received_local_fault_0    (),
    .stat_rx_unicast_0                 (),
    .stat_rx_multicast_0               (),
    .stat_rx_broadcast_0               (),
    .stat_rx_vlan_0                    (),
    .stat_rx_inrangeerr_0              (),
    .stat_rx_status_0                  (stat_rx_status_0),

    .stat_tx_ptp_fifo_read_error_0     (),
    .stat_tx_ptp_fifo_write_error_0    (),
    .tx_period_ns_0                    (),
    .rx_period_ns_0                    (),

    .tx_reset_0                        (1'b0),
    .user_tx_reset_0                   (user_tx_reset_0),

    //// TX user interface
    .tx_axis_tready_0                  (tx_axis_tready_0),
    .tx_axis_tvalid_0                  (tx_axis_tvalid_0),
    .tx_axis_tdata_0                   (tx_axis_tdata_0),
    .tx_axis_tlast_0                   (tx_axis_tlast_0),
    .tx_axis_tkeep_0                   (tx_axis_tkeep_0),
    .tx_axis_tuser_0                   (tx_axis_tuser_0),
    .tx_unfout_0                       (),
    .tx_preamblein_0                   (56'd0),

    .ctl_tx_send_rfi_0                 (1'b0),
    .ctl_tx_send_lfi_0                 (1'b0),
    .ctl_tx_send_idle_0                (1'b0),

    //// TX stats
    .stat_tx_total_packets_0           (),
    .stat_tx_total_bytes_0             (),
    .stat_tx_total_good_packets_0      (),
    .stat_tx_total_good_bytes_0        (),
    .stat_tx_packet_64_bytes_0         (),
    .stat_tx_packet_65_127_bytes_0     (),
    .stat_tx_packet_128_255_bytes_0    (),
    .stat_tx_packet_256_511_bytes_0    (),
    .stat_tx_packet_512_1023_bytes_0   (),
    .stat_tx_packet_1024_1518_bytes_0  (),
    .stat_tx_packet_1519_1522_bytes_0  (),
    .stat_tx_packet_1523_1548_bytes_0  (),
    .stat_tx_packet_small_0            (),
    .stat_tx_packet_large_0            (),
    .stat_tx_packet_1549_2047_bytes_0  (),
    .stat_tx_packet_2048_4095_bytes_0  (),
    .stat_tx_packet_4096_8191_bytes_0  (),
    .stat_tx_packet_8192_9215_bytes_0  (),
    .stat_tx_bad_fcs_0                 (),
    .stat_tx_frame_error_0             (),
    .stat_tx_local_fault_0             (),
    .stat_tx_unicast_0                 (),
    .stat_tx_multicast_0               (),
    .stat_tx_broadcast_0               (),
    .stat_tx_vlan_0                    (),

    //// GT debug ports tied off
    .gt_dmonitorout_0                  (),
    .gt_eyescandataerror_0             (),
    .gt_eyescanreset_0                 (1'b0),
    .gt_eyescantrigger_0               (1'b0),
    .gt_pcsrsvdin_0                    (16'd0),
    .gt_rxbufreset_0                   (1'b0),
    .gt_rxbufstatus_0                  (),
    .gt_rxcdrhold_0                    (1'b0),
    .gt_rxcommadeten_0                 (1'b0),
    .gt_rxdfeagchold_0                 (1'b0),
    .gt_rxdfelpmreset_0                (1'b0),
    .gt_rxlatclk_0                     (1'b0),
    .gt_rxlpmen_0                      (1'b1),
    .gt_rxpcsreset_0                   (1'b0),
    .gt_rxpmareset_0                   (1'b0),
    .gt_rxpolarity_0                   (1'b0),
    .gt_rxprbscntreset_0               (1'b0),
    .gt_rxprbserr_0                    (),
    .gt_rxprbssel_0                    (4'd0),
    .gt_rxrate_0                       (3'd0),
    .gt_rxslide_in_0                   (1'b0),
    .gt_rxstartofseq_0                 (),
    .gt_txbufstatus_0                  (),
    .gt_txinhibit_0                    (1'b0),
    .gt_txlatclk_0                     (1'b0),
    .gt_txmaincursor_0                 (7'h50),
    .gt_txpcsreset_0                   (1'b0),
    .gt_txpmareset_0                   (1'b0),
    .gt_txpolarity_0                   (1'b0),
    .gt_txpostcursor_0                 (5'd0),
    .gt_txprbsforceerr_0               (1'b0),
    .gt_txelecidle_0                   (1'b0),
    .gt_txprbssel_0                    (4'd0),
    .gt_txprecursor_0                  (5'd0),
    .gt_txdiffctrl_0                   (5'b11000),
    .gt_drpdo_0                        (),
    .gt_drprdy_0                       (),
    .gt_drpen_0                        (1'b0),
    .gt_drpwe_0                        (1'b0),
    .gt_drpaddr_0                      (10'd0),
    .gt_drpdi_0                        (16'd0),
    .gt_drpclk_0                       (dclk),
    .gt_drprst_0                       (1'b0),
    .gtwiz_reset_tx_datapath_0         (1'b0),
    .gtwiz_reset_rx_datapath_0         (1'b0),

    //// Mode switch / GT PLL select tied for fixed 10G operation.
    //// Values mirror the 10G branch of xxv_ethernet_DU_trans_debug (QPLL1);
    //// the DRP-based 10G<->25G switching of the example design is not used here.
    .axi_ctl_core_mode_switch_0        (),
    .ctl_rx_rate_10g_25gn_0            (1'b1),      // 1'b1 = 10G, 1'b0 = 25G
    .gt_drp_done_0                     (1'b0),      // GT reset request pulse - must stay low
    .txpllclksel_in_0                  (2'b10),     // QPLL1 (10G)
    .rxpllclksel_in_0                  (2'b10),
    .txsysclksel_in_0                  (2'b11),     // QPLL1 (10G)
    .rxsysclksel_in_0                  (2'b11),
    .rxdfecfokfcnum_in_0               (4'b1101),
    .rxafecfoken_in_0                  (1'b1),

    .gtpowergood_out_0                 (),
    .txoutclksel_in_0                  (3'b101),
    .rxoutclksel_in_0                  (3'b101),

    .gt_refclk_p                       (gt_refclk_p),
    .gt_refclk_n                       (gt_refclk_n),
    .gt_refclk_out                     (gt_refclk_out),
    .sys_reset                         (sys_reset),
    .dclk                              (dclk)
  );

endmodule
