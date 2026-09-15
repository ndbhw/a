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

    wire    [94:0]                      w_emio_gpio;
    wire                                w_emio_wdt1;

    wire                                w_clk_cpuif;
    wire                                w_fclk_nrst;

    wire                                w_cpu_frame_sync;
    wire    [9:0]                       w_cpu_sfn_num;

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

    wire                                w_ptp_1pps;

    wire    [19:0]                      w_cpu_addr;
    wire                                w_cpu_cs;
    wire                                w_cpu_rden;
    wire    [31:0]                      w_cpu_rdata;
    wire    [31:0]                      w_cpu_wdata;
    wire                                w_cpu_wren;

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

    assign w_mac_sys_reset   = 1'b0;

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

    wire                                w_gmii_col      = 1'b0;
    wire                                w_gmii_crs      = 1'b0;
    wire                                w_gmii_rx_clk   = 1'b0;
    wire                                w_gmii_rx_dv    = 1'b0;
    wire                                w_gmii_rx_er    = 1'b0;
    wire    [7:0]                       w_gmii_rxd      = 8'h0;
    wire                                w_gmii_tx_clk   = 1'b0;
    wire                                MDIO_ETHERNET_MDIO_IO;

    wire                                IIC_SIT5356_SCL;
    wire                                IIC_SIT5356_SDA;

    wire    [31:0]                      w_spi0_bram_addr = 32'h0;
    wire                                w_spi0_bram_clk  = 1'b0;
    wire    [31:0]                      w_spi0_bram_din  = 32'h0;
    wire                                w_spi0_bram_en   = 1'b0;
    wire                                w_spi0_bram_rst  = 1'b0;
    wire    [3:0]                       w_spi0_bram_we   = 4'h0;

    wire                                w_spi_rfic2_miso = 1'b0;

    wire                                w_clk_ocxo_i     = 1'b0;
    wire                                w_clk_timer      = 1'b0;



    mpsoc_ps_system_wrapper RU_MPSoC (
        .SPI_AMC7836_MOSI_0_0          (FPGA_AMP_AMC_SPI_SDI                ), // output
        .SPI_AMC7836_MISO_0_0          (AMP_FPGA_AMC_SPI_SDO                ), // input
        .SPI_AMC7836_SCK_0_0           (FPGA_AMP_AMC_SPI_SCLK               ), // output
        .SPI_AMC7836_SS_0_0            (FPGA_AMP_AMC_SPI_CS_L               ), // output [0:0]
        .CLK_122P88M_0                 (w_clk_sysx4                         ), // input
        .CLK_245P76_0                  (w_clk_sysx8                         ), // input
        .DACOUT                        (PWM_FROM_FPGA                       ), // output
        .M00_AXIS_0_tdata              (w_dl_oran_axis_0_tdata              ), // output [63:0]
        .M00_AXIS_0_tkeep              (w_dl_oran_axis_0_tkeep              ), // output [7:0]
        .M00_AXIS_0_tlast              (w_dl_oran_axis_0_tlast              ), // output [0:0]
        .M00_AXIS_0_tvalid             (w_dl_oran_axis_0_tvalid             ), // output [0:0]
        .M01_AXIS_0_tdata              (                                    ), // Not used, // output [63:0]
        .M01_AXIS_0_tkeep              (                                    ), // Not used, // output [7:0]
        .M01_AXIS_0_tlast              (                                    ), // Not used, // output [0:0]
        .M01_AXIS_0_tvalid             (                                    ), // Not used, // output [0:0]
        .M00_AXIS_1_tdata              (                                    ), // Not used, // output [63:0]
        .M00_AXIS_1_tkeep              (                                    ), // Not used, // output [7:0]
        .M00_AXIS_1_tlast              (                                    ), // Not used, // output [0:0]
        .M00_AXIS_1_tvalid             (                                    ), // Not used, // output [0:0]
        .M01_AXIS_1_tdata              (                                    ), // Not used, // output [63:0]
        .M01_AXIS_1_tkeep              (                                    ), // Not used, // output [7:0]
        .M01_AXIS_1_tlast              (                                    ), // Not used, // output [0:0]
        .M01_AXIS_1_tvalid             (                                    ), // Not used, // output [0:0]
        .DMA_BLOCK_RESET               (w_dma_block_reset                   ), // input
        .EMIO_GPIO                     (w_emio_gpio                         ), // output [94:0]
        .EMIO_WDT1                     (w_emio_wdt1                         ), // output
        .FCLK_CLK                      (w_clk_cpuif                         ), // output
        .FCLK_50M                      (                                    ), // Not used, output
        .FCLK_NRST                     (w_fclk_nrst                         ), // output
        .FRAME_SYNC_0                  (w_cpu_frame_sync                    ), // output
        .gt_refclk_0                   (MGT_REF_CLK_0                       ), // input
        .gt_refclk_1                   (MGT_REF_CLK_0                       ), // input
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
        .JESD204B_M_AXI_0_araddr       (w_jesd_axi_interconnect_araddr_cpu  ), //output [31:0]
        .JESD204B_M_AXI_0_arburst      (w_jesd_axi_interconnect_arburst_cpu ), //output [1:0]
        .JESD204B_M_AXI_0_arcache      (w_jesd_axi_interconnect_arcache_cpu ), //output [3:0]
        .JESD204B_M_AXI_0_arlen        (w_jesd_axi_interconnect_arlen_cpu   ), //output [7:0]
        .JESD204B_M_AXI_0_arlock       (w_jesd_axi_interconnect_arlock_cpu  ), //output [0:0]
        .JESD204B_M_AXI_0_arprot       (w_jesd_axi_interconnect_arprot_cpu  ), //output [2:0]
        .JESD204B_M_AXI_0_arqos        (w_jesd_axi_interconnect_arqos_cpu   ), //output [3:0]
        .JESD204B_M_AXI_0_arready      (w_jesd_axi_interconnect_arready_dcif), //input
        .JESD204B_M_AXI_0_arregion     (w_jesd_axi_interconnect_arregion_cpu), //output [3:0]
        .JESD204B_M_AXI_0_arsize       (w_jesd_axi_interconnect_arsize_cpu  ), //output [2:0]
        .JESD204B_M_AXI_0_arvalid      (w_jesd_axi_interconnect_arvalid_cpu ), //output
        .JESD204B_M_AXI_0_awaddr       (w_jesd_axi_interconnect_awaddr_cpu  ), //output [31:0]
        .JESD204B_M_AXI_0_awburst      (w_jesd_axi_interconnect_awburst_cpu ), //output [1:0]
        .JESD204B_M_AXI_0_awcache      (w_jesd_axi_interconnect_awcache_cpu ), //output [3:0]
        .JESD204B_M_AXI_0_awlen        (w_jesd_axi_interconnect_awlen_cpu   ), //output [7:0]
        .JESD204B_M_AXI_0_awlock       (w_jesd_axi_interconnect_awlock_cpu  ), //output [0:0]
        .JESD204B_M_AXI_0_awprot       (w_jesd_axi_interconnect_awprot_cpu  ), //output [2:0]
        .JESD204B_M_AXI_0_awqos        (w_jesd_axi_interconnect_awqos_cpu   ), //output [3:0]
        .JESD204B_M_AXI_0_awready      (w_jesd_axi_interconnect_awready_dcif), //input
        .JESD204B_M_AXI_0_awregion     (w_jesd_axi_interconnect_awregion_cpu), //output [3:0]
        .JESD204B_M_AXI_0_awsize       (w_jesd_axi_interconnect_awsize_cpu  ), //output [2:0]
        .JESD204B_M_AXI_0_awvalid      (w_jesd_axi_interconnect_awvalid_cpu ), //output
        .JESD204B_M_AXI_0_bready       (w_jesd_axi_interconnect_bready_cpu  ), //output
        .JESD204B_M_AXI_0_bresp        (w_jesd_axi_interconnect_bresp_dcif  ), //input  [1:0]
        .JESD204B_M_AXI_0_bvalid       (w_jesd_axi_interconnect_bvalid_dcif ), //input
        .JESD204B_M_AXI_0_rdata        (w_jesd_axi_interconnect_rdata_dcif  ), //input  [31:0]
        .JESD204B_M_AXI_0_rlast        (w_jesd_axi_interconnect_rlast_dcif  ), //input
        .JESD204B_M_AXI_0_rready       (w_jesd_axi_interconnect_rready_cpu  ), //output
        .JESD204B_M_AXI_0_rresp        (w_jesd_axi_interconnect_rresp_dcif  ), //input  [1:0]
        .JESD204B_M_AXI_0_rvalid       (w_jesd_axi_interconnect_rvalid_dcif ), //input
        .JESD204B_M_AXI_0_wdata        (w_jesd_axi_interconnect_wdata_cpu   ), //output [31:0]
        .JESD204B_M_AXI_0_wlast        (w_jesd_axi_interconnect_wlast_cpu   ), //output
        .JESD204B_M_AXI_0_wready       (w_jesd_axi_interconnect_wready_dcif ), //input
        .JESD204B_M_AXI_0_wstrb        (w_jesd_axi_interconnect_wstrb_cpu   ), //output [3:0]
        .JESD204B_M_AXI_0_wvalid       (w_jesd_axi_interconnect_wvalid_cpu  ), //output
        .L0_DEFRAMER_CLK               (w_l0_deframer_clk                   ), // output
        .L0_DEFRAMER_CLK1              (w_l1_deframer_clk                   ), // output
        .MAC_SYS_RESET                 (w_mac_sys_reset                     ), // input
        .MODE_CHANGE_25N_10H_0         (1'b0                                ), // input
        .MODE_CHANGE_25N_10H_1         (1'b0                                ), // Not Used, input
        .PTP_1PPS                      (w_ptp_1pps                          ), // output
        .PTP_EVEN                      (                                    ), // output
        .RESET_MMCM_250M               (1'b0                                ), // input
        .SPI_RFIC1_MOSI_0_0            (RFIC_SPI_MOSI                       ), // output
        .SPI_RFIC1_MISO_0_0            (RFIC_SPI_MISO                       ), // input
        .SPI_RFIC1_SCK_0_0             (RFIC_SPI_SCK                        ), // output
        .SPI_RFIC1_SS_0_0              (RFIC_SPI_CS                         ), // output [0:0]
        .SPI_RFIC2_MOSI_0_0            (                                    ), // Not Used, output
        .SPI_RFIC2_MISO_0_0            (w_spi_rfic2_miso                    ), // Not Used, input
        .SPI_RFIC2_SCK_0_0             (                                    ), // Not Used, output
        .SPI_RFIC2_SS_0_0              (                                    ), // Not Used, output [0:0]
        .RX_WDT_RESET_0                (w_rx_wdt_reset[0]                   ), // input  [0:0]
        .RX_WDT_RESET_1                (w_rx_wdt_reset[1]                   ), // input  [0:0]
        .SFN_NUM_0                     (w_cpu_sfn_num                       ), // output [9:0]
        .STAT_RX_BLOCK_LOCK_0          (w_stat_rx_block_lock[0]             ), // output
        .STAT_RX_BLOCK_LOCK_1          (w_stat_rx_block_lock[1]             ), // output
        .STAT_RX_LOCAL_FAULT_0         (w_stat_rx_local_fault[0]            ), // output
        .STAT_RX_LOCAL_FAULT_1         (w_stat_rx_local_fault[1]            ), // output
        .STAT_RX_RATE_10G_25GN_0       (                                    ), // output        // Not used. 10G only
        .STAT_RX_RATE_10G_25GN_1       (                                    ), // output        // Not used. 10G only
        .STAT_RX_REMOTE_FAULT_0        (w_stat_rx_remote_fault[0]           ), // output
        .STAT_RX_REMOTE_FAULT_1        (w_stat_rx_remote_fault[1]           ), // output
        .STAT_RX_STATUS_0_0            (w_stat_rx_status[0]                 ), // output
        .STAT_RX_STATUS_0_1            (w_stat_rx_status[1]                 ), // output
        .UART_RET_rxd                  (w_uart_ret_rxd                      ), // input
        .UART_RET_txd                  (w_uart_ret_txd                      ), // output
        .S00_AXIS_0_tdata              (w_ul_oran_axis_0_tdata              ), // input [63:0]
        .S00_AXIS_0_tkeep              (w_ul_oran_axis_0_tkeep              ), // input [7:0]
        .S00_AXIS_0_tlast              (w_ul_oran_axis_0_tlast              ), // input
        .S00_AXIS_0_tready             (w_ul_oran_axis_0_tready             ), // output
        .S00_AXIS_0_tvalid             (w_ul_oran_axis_0_tvalid             ), // input
        .S00_AXIS_1_tdata              (64'h0                               ), // Not Used, input  [63:0]
        .S00_AXIS_1_tkeep              (8'h0                                ), // Not Used, input  [7:0]
        .S00_AXIS_1_tlast              (1'b0                                ), // Not Used, input
        .S00_AXIS_1_tready             (                                    ), // Not Used, output
        .S00_AXIS_1_tvalid             (1'b0                                ), // Not Used, input
        .DATA_FROM_USER                (w_cpu_rdata                         ), // input  [31:0]
        .DATA_TO_USER                  (w_cpu_wdata                         ), // output [31:0]
        .ECPRI_GT_RXLPMEN_0            (w_ecpri_gt_rxlpmen[0]               ), // input  [0:0]
        .ECPRI_GT_RXLPMEN_1            (w_ecpri_gt_rxlpmen[1]               ), // input  [0:0]
        .ECPRI_GT_TXDIFFCTRL_0         (w_ecpri_gt_txdiffctrl[0]            ), // input  [4:0]   // 2d array wire used
        .ECPRI_GT_TXDIFFCTRL_1         (w_ecpri_gt_txdiffctrl[1]            ), // input  [4:0]   // 2d array wire used
        .ECPRI_TXPOSTCUSOR_0           (w_ecpri_txpostcusor[0]              ), // input  [4:0]   // 2d array wire used
        .ECPRI_TXPOSTCUSOR_1           (w_ecpri_txpostcusor[1]              ), // input  [4:0]   // 2d array wire used
        .ECPRI_TXPRECURSOR_0           (w_ecpri_txprecursor[0]              ), // input  [4:0]   // 2d array wire used
        .ECPRI_TXPRECURSOR_1           (w_ecpri_txprecursor[1]              ), // input  [4:0]   // 2d array wire used
        .SYSRESET_0                    (                                    ), // Not Used, output [0:0]
        .USER_ADD                      (w_cpu_addr                          ), // output [19:0]
        .USER_CLK                      (                                    ), // Not Used, output
        .USER_CS                       (w_cpu_cs                            ), // output
        .USER_RD                       (w_cpu_rden                          ), // output
        .USER_WR                       (w_cpu_wren                          ), // output
        .CLK_OCXO_BUFG_I               (w_clk_ocxo_i                        ), // input  [0:0]
        .CLK_OCXO_BUFG_O               (                                    ), // Not Used, output [0:0]
        .CLK_TIMER                     (w_clk_timer                         ), // input
        .GMII_UDE_PL_col               (w_gmii_col                          ), // Not Used, input
        .GMII_UDE_PL_crs               (w_gmii_crs                          ), // Not Used, input
        .GMII_UDE_PL_rx_clk            (w_gmii_rx_clk                       ), // Not Used, input
        .GMII_UDE_PL_rx_dv             (w_gmii_rx_dv                        ), // Not Used, input
        .GMII_UDE_PL_rx_er             (w_gmii_rx_er                        ), // Not Used, input
        .GMII_UDE_PL_rxd               (w_gmii_rxd                          ), // Not Used, input  [7:0]
        .GMII_UDE_PL_speed_mode        (                                    ), // Not Used, output [2:0]
        .GMII_UDE_PL_tx_clk            (w_gmii_tx_clk                       ), // Not Used, input
        .GMII_UDE_PL_tx_en             (                                    ), // Not Used, output
        .GMII_UDE_PL_tx_er             (                                    ), // Not Used, output
        .GMII_UDE_PL_txd               (                                    ), // Not Used, output [7:0]
        .MDIO_UDE_PL_mdc               (                                    ), // Not Used, output
        .MDIO_UDE_PL_mdio_io           (MDIO_ETHERNET_MDIO_IO               ), // Not Used, inout
        .IIC_SIT5356_scl_io            (IIC_SIT5356_SCL                     ), // Not Used, inout
        .IIC_SIT5356_sda_io            (IIC_SIT5356_SDA                     ), // Not Used, inout
        .MISC_RTL_SPI0_BRAM_IF_0_0_addr(w_spi0_bram_addr                    ), // Not Used, input  [31:0]
        .MISC_RTL_SPI0_BRAM_IF_0_0_clk (w_spi0_bram_clk                     ), // Not Used, input
        .MISC_RTL_SPI0_BRAM_IF_0_0_din (w_spi0_bram_din                     ), // Not Used, input  [31:0]
        .MISC_RTL_SPI0_BRAM_IF_0_0_dout(                                    ), // Not Used, output [31:0]
        .MISC_RTL_SPI0_BRAM_IF_0_0_en  (w_spi0_bram_en                      ), // Not Used, input
        .MISC_RTL_SPI0_BRAM_IF_0_0_rst (w_spi0_bram_rst                     ), // Not Used, input
        .MISC_RTL_SPI0_BRAM_IF_0_0_we  (w_spi0_bram_we                      )  // Not Used, input  [3:0]

    );
	
	
	
	
	
	
endmodule


