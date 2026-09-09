`timescale 1fs/1fs

module RU_TOP(
    input  wire gt0_rxp,
    input  wire gt0_rxn,
    output wire gt0_txp,
    output wire gt0_txn,
    input  wire gt1_rxp,
    input  wire gt1_rxn,
    output wire gt1_txp,
    output wire gt1_txn


    );

    //--------------------------------------------------------------------------
    // Top-level pins of RU_FPGA_TOP emulated locally
    //--------------------------------------------------------------------------
    wire                                MGT_REF_CLK_0;      // GTY REF CLK 161.1328125 MHz

    // DU SerDes
    wire    [1:0]                       RU_DU_P;
    wire    [1:0]                       RU_DU_N;
    wire    [1:0]                       DU_RU_P;
    wire    [1:0]                       DU_RU_N;

    wire                                PWM_FROM_FPGA;

    // AMP_AMC SPI
    wire                                FPGA_AMP_AMC_SPI_SDI;
    wire                                FPGA_AMP_AMC_SPI_SCLK;
    wire                                FPGA_AMP_AMC_SPI_CS_L;
    wire                                AMP_FPGA_AMC_SPI_SDO;

    // RFIC SPI / UART
    wire                                RFIC_SPI_CS;
    wire                                RFIC_SPI_MISO;
    wire                                RFIC_SPI_MOSI;
    wire                                RFIC_SPI_SCK;
    wire                                RFIC_UART_IN;
    wire                                RFIC_UART_OUT;

    //--------------------------------------------------------------------------
    // OPTIC
    //--------------------------------------------------------------------------

    assign DU_RU_P[0] = gt0_rxp;
    assign DU_RU_N[0] = gt0_rxn;
    assign gt0_txp    = RU_DU_P[0];
    assign gt0_txn    = RU_DU_N[0];
    assign DU_RU_P[1] = gt1_rxp;
    assign DU_RU_N[1] = gt1_rxn;
    assign gt1_txp    = RU_DU_P[1];
    assign gt1_txn    = RU_DU_N[1];

    //--------------------------------------------------------------------------
    // Clocks driving the block design
    //--------------------------------------------------------------------------
    wire                                w_clk_sysx4;        // CLK_122P88
    wire                                w_clk_sysx8;        // CLK_245P76
    wire                                w_clk_ptp;          // PTP_MMCM_CLK

    //--------------------------------------------------------------------------
    // U01_MPSoC_CPU - wire define
    //--------------------------------------------------------------------------
    wire    [63:0]                      w_dl_oran_axis_0_tdata;
    wire    [7:0]                       w_dl_oran_axis_0_tkeep;
    wire                                w_dl_oran_axis_0_tlast;
    wire                                w_dl_oran_axis_0_tvalid;

    wire    [63:0]                      w_ul_oran_axis_0_tdata;
    wire    [7:0]                       w_ul_oran_axis_0_tkeep;
    wire                                w_ul_oran_axis_0_tlast;
    wire                                w_ul_oran_axis_0_tready;
    wire                                w_ul_oran_axis_0_tvalid;

    wire                                w_dma_block_reset;
    wire                                w_mac_sys_reset;
    wire    [1:0]                       w_rx_wdt_reset;

    wire                                w_emio_gpio;
    wire                                w_emio_wdt1;

    wire                                w_clk_cpuif;
    wire                                w_fclk_nrst;
    wire                                w_axi_rstn;

    wire                                w_cpu_frame_sync;
    wire    [9:0]                       w_cpu_sfn_num;

    wire                                w_fh_qpll_reset;
    wire    [1:0]                       w_fh_qpll_lock;

    wire    [1:0]                       w_ecpri_gt_reset_rx_done;
    wire    [1:0]                       w_ecpri_gt_reset_tx_done;
    wire    [1:0]                       w_ecpri_gt_rxlpmen;
    wire    [4:0]                       w_ecpri_gt_txdiffctrl[1:0];
    wire    [4:0]                       w_ecpri_txprecursor  [1:0];
    wire    [4:0]                       w_ecpri_txpostcusor  [1:0];

    wire                                w_l0_deframer_clk;
    wire                                w_l1_deframer_clk;

    wire    [1:0]                       w_stat_rx_block_lock;
    wire    [1:0]                       w_stat_rx_local_fault;
    wire    [1:0]                       w_stat_rx_remote_fault;
    wire    [1:0]                       w_stat_rx_status;

    wire                                w_uart_ret_txd;
    wire                                w_uart_ret_rxd;
    wire                                w_uart_ook0_txd;
    wire                                w_uart_ook0_rxd;
    wire                                w_uart_ook1_txd;
    wire                                w_uart_ook1_rxd;

    wire                                w_ptp_1pps;

    wire    [19:0]                      w_cpu_addr;
    wire                                w_cpu_cs;
    wire                                w_cpu_rden;
    wire    [31:0]                      w_cpu_rdata;
    wire    [31:0]                      w_cpu_wdata;
    wire                                w_cpu_wren;

    wire    [31:0]                      w_statistic_op_none_cnt_l1;
    wire    [31:0]                      w_statistic_op_one_step_cnt_l1;
    wire    [31:0]                      w_statistic_op_twop_step_cnt_l1;
    wire    [31:0]                      w_tx_ptp_config_dump_l1;

    // JESD AXI interconnect: master side driven by the BD, slave side idle
    wire    [31:0]                      w_jesd_axi_interconnect_araddr_cpu;
    wire    [1:0]                       w_jesd_axi_interconnect_arburst_cpu;
    wire    [3:0]                       w_jesd_axi_interconnect_arcache_cpu;
    wire    [7:0]                       w_jesd_axi_interconnect_arlen_cpu;
    wire    [0:0]                       w_jesd_axi_interconnect_arlock_cpu;
    wire    [2:0]                       w_jesd_axi_interconnect_arprot_cpu;
    wire    [3:0]                       w_jesd_axi_interconnect_arqos_cpu;
    wire                                w_jesd_axi_interconnect_arready_dcif;
    wire    [3:0]                       w_jesd_axi_interconnect_arregion_cpu;
    wire    [2:0]                       w_jesd_axi_interconnect_arsize_cpu;
    wire                                w_jesd_axi_interconnect_arvalid_cpu;
    wire    [31:0]                      w_jesd_axi_interconnect_awaddr_cpu;
    wire    [1:0]                       w_jesd_axi_interconnect_awburst_cpu;
    wire    [3:0]                       w_jesd_axi_interconnect_awcache_cpu;
    wire    [7:0]                       w_jesd_axi_interconnect_awlen_cpu;
    wire    [0:0]                       w_jesd_axi_interconnect_awlock_cpu;
    wire    [2:0]                       w_jesd_axi_interconnect_awprot_cpu;
    wire    [3:0]                       w_jesd_axi_interconnect_awqos_cpu;
    wire                                w_jesd_axi_interconnect_awready_dcif;
    wire    [3:0]                       w_jesd_axi_interconnect_awregion_cpu;
    wire    [2:0]                       w_jesd_axi_interconnect_awsize_cpu;
    wire                                w_jesd_axi_interconnect_awvalid_cpu;
    wire                                w_jesd_axi_interconnect_bready_cpu;
    wire    [1:0]                       w_jesd_axi_interconnect_bresp_dcif;
    wire                                w_jesd_axi_interconnect_bvalid_dcif;
    wire    [31:0]                      w_jesd_axi_interconnect_rdata_dcif;
    wire                                w_jesd_axi_interconnect_rlast_dcif;
    wire                                w_jesd_axi_interconnect_rready_cpu;
    wire    [1:0]                       w_jesd_axi_interconnect_rresp_dcif;
    wire                                w_jesd_axi_interconnect_rvalid_dcif;
    wire    [31:0]                      w_jesd_axi_interconnect_wdata_cpu;
    wire                                w_jesd_axi_interconnect_wlast_cpu;
    wire                                w_jesd_axi_interconnect_wready_dcif;
    wire    [3:0]                       w_jesd_axi_interconnect_wstrb_cpu;
    wire                                w_jesd_axi_interconnect_wvalid_cpu;



    BD_CLK_wrapper i_bd_clk
    (
        .clk_100          (),
        .clk_122p88       (w_clk_sysx4),
        .clk_156p25       (),
        .clk_156p25_N     (),
        .clk_156p25_P     (),
        .clk_161p1328     (MGT_REF_CLK_0),
        .clk_161p1328_N   (),
        .clk_161p1328_P   (),
        .clk_245p76       (w_clk_sysx8),
        .clk_30p72        (),
        .clk_61p44        ()
    );

    wire                                PTP_REF_CLK;

    assign PTP_REF_CLK = MGT_REF_CLK_0;
    assign w_clk_ptp   = PTP_REF_CLK;

    assign w_mac_sys_reset   = 1'b0;
    assign w_fh_qpll_reset   = 1'b0;

    assign w_dma_block_reset = 1'b0;
    assign w_rx_wdt_reset    = 2'b00;

    assign w_ecpri_gt_rxlpmen[0]   = 1'b1;
    assign w_ecpri_gt_rxlpmen[1]   = 1'b1;
    assign w_ecpri_gt_txdiffctrl[0] = 5'b11000;
    assign w_ecpri_gt_txdiffctrl[1] = 5'b11000;
    assign w_ecpri_txprecursor[0]   = 5'd0;
    assign w_ecpri_txprecursor[1]   = 5'd0;
    assign w_ecpri_txpostcusor[0]   = 5'd0;
    assign w_ecpri_txpostcusor[1]   = 5'd0;

    assign w_ul_oran_axis_0_tdata  = 64'd0;
    assign w_ul_oran_axis_0_tkeep  = 8'd0;
    assign w_ul_oran_axis_0_tlast  = 1'b0;
    assign w_ul_oran_axis_0_tvalid = 1'b0;



    RU_BD_wrapper RU_MPSoC (
        .AMC_SPI_io0_io                (FPGA_AMP_AMC_SPI_SDI                ), // output
        .AMC_SPI_io1_io                (AMP_FPGA_AMC_SPI_SDO                ), // input
        .AMC_SPI_sck_io                (FPGA_AMP_AMC_SPI_SCLK               ), // output
        .AMC_SPI_ss_io                 (FPGA_AMP_AMC_SPI_CS_L               ), // output
        .CLK_122P88                    (w_clk_sysx4                         ), // input
        .CLK_245P76                    (w_clk_sysx8                         ), // input
        .DACOUT                        (PWM_FROM_FPGA                       ), // output
        .DL_CU_AXIS_0_tdata            (w_dl_oran_axis_0_tdata              ), // output [63:0]
        .DL_CU_AXIS_0_tkeep            (w_dl_oran_axis_0_tkeep              ), // output [7:0]
        .DL_CU_AXIS_0_tlast            (w_dl_oran_axis_0_tlast              ), // output
        .DL_CU_AXIS_0_tvalid           (w_dl_oran_axis_0_tvalid             ), // output
        .DL_CU_AXIS_1_tdata            (                                    ), // Not used, // output [63:0]
        .DL_CU_AXIS_1_tkeep            (                                    ), // Not used, // output [7:0]
        .DL_CU_AXIS_1_tlast            (                                    ), // Not used, // output
        .DL_CU_AXIS_1_tvalid           (                                    ), // Not used, // output
        .DMA_BLOCK_RESET               (w_dma_block_reset                   ), // input
        .EMIO_GPIO_0                   (w_emio_gpio                         ), //w_emio_gpio                        ), // output
        .EMIO_WDT1                     (w_emio_wdt1                         ), //w_emio_wdt1                        ), // output
        .FCLK_CLK0                     (w_clk_cpuif                         ), // output
        .FCLK_NRST                     (w_fclk_nrst                         ), // output
        .FH_QPLL_LOCK0                 (w_fh_qpll_lock[0]                   ), // output
        .FH_QPLL_LOCK1                 (w_fh_qpll_lock[1]                   ), // output
        .FH_QPLL_RESET                 (w_fh_qpll_reset                     ), // input
        .FRAME_SYNC                    (w_cpu_frame_sync                    ), // output
        .GSM_SYNC_SEL                  (                                    ), // Not used, output
        .GT_REFCLK                     (MGT_REF_CLK_0                       ), // input
        .GT_RESET_RX_DONE_OUT_0        (w_ecpri_gt_reset_rx_done[0]         ), // output
        .GT_RESET_RX_DONE_OUT_1        (w_ecpri_gt_reset_rx_done[1]         ), // output
        .GT_RESET_TX_DONE_OUT_0        (w_ecpri_gt_reset_tx_done[0]         ), // output
        .GT_RESET_TX_DONE_OUT_1        (w_ecpri_gt_reset_tx_done[1]         ), // output
        .GT_RX_0_gt_port_0_n           (DU_RU_N[0]                          ), // input
        .GT_RX_0_gt_port_0_p           (DU_RU_P[0]                          ), // input
        .GT_RX_1_gt_port_0_n           (DU_RU_N[1]                          ), // input
        .GT_RX_1_gt_port_0_p           (DU_RU_P[1]                          ), // input
        .GT_TX_0_gt_port_0_n           (RU_DU_N[0]                          ), // output
        .GT_TX_0_gt_port_0_p           (RU_DU_P[0]                          ), // output
        .GT_TX_1_gt_port_0_n           (RU_DU_N[1]                          ), // output
        .GT_TX_1_gt_port_0_p           (RU_DU_P[1]                          ), // output
        .JESD_AXI_INTERCONNECT_araddr  (w_jesd_axi_interconnect_araddr_cpu  ), //output [31:0]
        .JESD_AXI_INTERCONNECT_arburst (w_jesd_axi_interconnect_arburst_cpu ), //output [1:0]
        .JESD_AXI_INTERCONNECT_arcache (w_jesd_axi_interconnect_arcache_cpu ), //output [3:0]
        .JESD_AXI_INTERCONNECT_arlen   (w_jesd_axi_interconnect_arlen_cpu   ), //output [7:0]
        .JESD_AXI_INTERCONNECT_arlock  (w_jesd_axi_interconnect_arlock_cpu  ), //output [0:0]
        .JESD_AXI_INTERCONNECT_arprot  (w_jesd_axi_interconnect_arprot_cpu  ), //output [2:0]
        .JESD_AXI_INTERCONNECT_arqos   (w_jesd_axi_interconnect_arqos_cpu   ), //output [3:0]
        .JESD_AXI_INTERCONNECT_arready (w_jesd_axi_interconnect_arready_dcif), //input  [0:0]
        .JESD_AXI_INTERCONNECT_arregion(w_jesd_axi_interconnect_arregion_cpu), //output [3:0]
        .JESD_AXI_INTERCONNECT_arsize  (w_jesd_axi_interconnect_arsize_cpu  ), //output [2:0]
        .JESD_AXI_INTERCONNECT_arvalid (w_jesd_axi_interconnect_arvalid_cpu ), //output [0:0]
        .JESD_AXI_INTERCONNECT_awaddr  (w_jesd_axi_interconnect_awaddr_cpu  ), //output [31:0]
        .JESD_AXI_INTERCONNECT_awburst (w_jesd_axi_interconnect_awburst_cpu ), //output [1:0]
        .JESD_AXI_INTERCONNECT_awcache (w_jesd_axi_interconnect_awcache_cpu ), //output [3:0]
        .JESD_AXI_INTERCONNECT_awlen   (w_jesd_axi_interconnect_awlen_cpu   ), //output [7:0]
        .JESD_AXI_INTERCONNECT_awlock  (w_jesd_axi_interconnect_awlock_cpu  ), //output [0:0]
        .JESD_AXI_INTERCONNECT_awprot  (w_jesd_axi_interconnect_awprot_cpu  ), //output [2:0]
        .JESD_AXI_INTERCONNECT_awqos   (w_jesd_axi_interconnect_awqos_cpu   ), //output [3:0]
        .JESD_AXI_INTERCONNECT_awready (w_jesd_axi_interconnect_awready_dcif), //input  [0:0]
        .JESD_AXI_INTERCONNECT_awregion(w_jesd_axi_interconnect_awregion_cpu), //output [3:0]
        .JESD_AXI_INTERCONNECT_awsize  (w_jesd_axi_interconnect_awsize_cpu  ), //output [2:0]
        .JESD_AXI_INTERCONNECT_awvalid (w_jesd_axi_interconnect_awvalid_cpu ), //output [0:0]
        .JESD_AXI_INTERCONNECT_bready  (w_jesd_axi_interconnect_bready_cpu  ), //output [0:0]
        .JESD_AXI_INTERCONNECT_bresp   (w_jesd_axi_interconnect_bresp_dcif  ), //input  [1:0]
        .JESD_AXI_INTERCONNECT_bvalid  (w_jesd_axi_interconnect_bvalid_dcif ), //input  [0:0]
        .JESD_AXI_INTERCONNECT_rdata   (w_jesd_axi_interconnect_rdata_dcif  ), //input  [31:0]
        .JESD_AXI_INTERCONNECT_rlast   (w_jesd_axi_interconnect_rlast_dcif  ), //input  [0:0]
        .JESD_AXI_INTERCONNECT_rready  (w_jesd_axi_interconnect_rready_cpu  ), //output [0:0]
        .JESD_AXI_INTERCONNECT_rresp   (w_jesd_axi_interconnect_rresp_dcif  ), //input  [1:0]
        .JESD_AXI_INTERCONNECT_rvalid  (w_jesd_axi_interconnect_rvalid_dcif ), //input  [0:0]
        .JESD_AXI_INTERCONNECT_wdata   (w_jesd_axi_interconnect_wdata_cpu   ), //output [31:0]
        .JESD_AXI_INTERCONNECT_wlast   (w_jesd_axi_interconnect_wlast_cpu   ), //output [0:0]
        .JESD_AXI_INTERCONNECT_wready  (w_jesd_axi_interconnect_wready_dcif ), //input  [0:0]
        .JESD_AXI_INTERCONNECT_wstrb   (w_jesd_axi_interconnect_wstrb_cpu   ), //output [3:0]
        .JESD_AXI_INTERCONNECT_wvalid  (w_jesd_axi_interconnect_wvalid_cpu  ), //output [0:0]
        .L0_DEFRAMER_CLK               (w_l0_deframer_clk                   ), // output
        .L1_DEFRAMER_CLK               (w_l1_deframer_clk                   ), // output
        .MAC_SYS_RESET                 (w_mac_sys_reset                     ), // input
        .MODE_CHANGE_10G_25G_0         (1'b0                                ), // input
        .MODE_CHANGE_10G_25G_1         (1'b0                                ), // Not Used, input
        .PDM_TEST_EN                   (1'b0                                ), // Not Used, input
        .PLL_100to250_locked           (                                    ),  // output
        .PLL_122p88to100_locked        (                                    ), // output
        .PTP_1PPS                      (w_ptp_1pps                          ), // output
        .PTP_EVEN                      (                                    ), // output
        .PTP_MMCM_CLK                  (w_clk_ptp                           ), // input
        .RESET_MMCM_250M               (1'b0                                ), // input
        .RFIC_SPI_io0_io               (RFIC_SPI_MOSI                       ), // output                  
        .RFIC_SPI_io1_io               (RFIC_SPI_MISO                       ), // input 
        .RFIC_SPI_sck_io               (RFIC_SPI_SCK                        ), // output
        .RFIC_SPI_ss_io                (RFIC_SPI_CS                         ), // output [0:0]
        .RX_WDT_RESET_0                (w_rx_wdt_reset[0]                   ), // input
        .RX_WDT_RESET_1                (w_rx_wdt_reset[1]                   ), // input
        .SFN_NUM                       (w_cpu_sfn_num                       ), // output [9:0]
        .SLAVE_IRQ                     (1'b0                                ), // Not Used
        .STAT_RX_BLOCK_LOCK_0          (w_stat_rx_block_lock[0]             ), // output
        .STAT_RX_BLOCK_LOCK_1          (w_stat_rx_block_lock[1]             ), // output
        .STAT_RX_LOCAL_FAULT_0         (w_stat_rx_local_fault[0]            ), // output
        .STAT_RX_LOCAL_FAULT_1         (w_stat_rx_local_fault[1]            ), // output
        .STAT_RX_RATE_10G_25GN_0       (                                    ), // output        // Not used. 10G only
        .STAT_RX_RATE_10G_25GN_1       (                                    ), // output        // Not used. 10G only
        .STAT_RX_REMOTE_FAULT_0        (w_stat_rx_remote_fault[0]           ), // output
        .STAT_RX_REMOTE_FAULT_1        (w_stat_rx_remote_fault[1]           ), // output
        .STAT_RX_STATUS_0              (w_stat_rx_status[0]                 ), // output
        .STAT_RX_STATUS_1              (w_stat_rx_status[1]                 ), // output
        .UART_OOK_0_rxd                (w_uart_ook0_rxd                     ),  //  input     
        .UART_OOK_0_txd                (w_uart_ook0_txd                     ),  //  output   
        .UART_OOK_1_rxd                (w_uart_ook1_rxd                     ),  //  input    
        .UART_OOK_1_txd                (w_uart_ook1_txd                     ),  //  output   
        .UART_RET_rxd                  (w_uart_ret_rxd                      ), // input
        .UART_RET_txd                  (w_uart_ret_txd                      ), // output
        .UART_RFIC_rxd                 (RFIC_UART_OUT                       ),  //  input  
        .UART_RFIC_txd                 (RFIC_UART_IN                        ),  //  output
        .UL_UL_AXIS_0_tdata            (w_ul_oran_axis_0_tdata              ), // input [63:0]
        .UL_UL_AXIS_0_tkeep            (w_ul_oran_axis_0_tkeep              ), // input [7:0]
        .UL_UL_AXIS_0_tlast            (w_ul_oran_axis_0_tlast              ), // input
        .UL_UL_AXIS_0_tready           (w_ul_oran_axis_0_tready             ), // output
        .UL_UL_AXIS_0_tvalid           (w_ul_oran_axis_0_tvalid             ), // input
        .UL_UP_AXIS_1_tdata            (64'h0                               ), // Not Used, input  [63:0]
        .UL_UP_AXIS_1_tkeep            (8'h0                                ), // Not Used, input  [7:0]
        .UL_UP_AXIS_1_tlast            (1'b0                                ), // Not Used, input
        .UL_UP_AXIS_1_tready           (                                    ), // Not Used, output
        .UL_UP_AXIS_1_tvalid           (1'b0                                ), // Not Used, input
        .data_from_user0               (w_cpu_rdata                         ), // input  [31:0]
        .data_to_user                  (w_cpu_wdata                         ), // output [31:0]
        .gt_rxlpmen_in_0               (w_ecpri_gt_rxlpmen[0]               ), // input
        .gt_rxlpmen_in_1               (w_ecpri_gt_rxlpmen[1]               ), // input
        .gt_txdiffctrl_in_0            (w_ecpri_gt_txdiffctrl[0]            ), // input  [4:0]   // 2d array wire used
        .gt_txdiffctrl_in_1            (w_ecpri_gt_txdiffctrl[1]            ), // input  [4:0]   // 2d array wire used
        .gt_txpostcursor_in_0          (w_ecpri_txpostcusor[0]              ), // input  [4:0]   // 2d array wire used
        .gt_txpostcursor_in_1          (w_ecpri_txpostcusor[1]              ), // input  [4:0]   // 2d array wire used
        .gt_txprecursor_in_0           (w_ecpri_txprecursor[0]              ), // input  [4:0]   // 2d array wire used
        .gt_txprecursor_in_1           (w_ecpri_txprecursor[1]              ), // input  [4:0]   // 2d array wire used
        .pl_axi_rstn                   (w_axi_rstn                          ), // output
        .pl_clk1_50m                   (                                    ), // Not Used, output
        .sysreset_0                    (                                    ), // Not Used, output
        .user_add                      (w_cpu_addr                          ), // output [19:0]
        .user_clk                      (                                    ), // Not Used, output
        .user_cs                       (w_cpu_cs                            ), // output
        .user_rd                       (w_cpu_rden                          ), // output
        .user_wr                       (w_cpu_wren                          ), // output
        .statistic_op_none_cnt_l1      (w_statistic_op_none_cnt_l1          ),
        .statistic_op_one_step_cnt_l1  (w_statistic_op_one_step_cnt_l1      ),
        .statistic_op_twop_step_cnt_l1 (w_statistic_op_twop_step_cnt_l1     ),
        .tx_ptp_config_dump_l1         (w_tx_ptp_config_dump_l1             )
        
    );
	
	
	
	
	
	
endmodule


