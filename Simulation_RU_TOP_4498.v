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

    wire                                AMC_SPI_SDI;
    wire                                AMC_SPI_SCLK;
    wire                                AMC_SPI_CS_L;
    wire                                AMC_SPI_SDO;

    // RFIC SPI / UART
    wire                                RFIC_SPI_CS;
    wire                                RFIC_SPI_MISO;
    wire                                RFIC_SPI_MOSI;
    wire                                RFIC_SPI_SCK;
    wire                                RFIC_UART_IN;
    wire                                RFIC_UART_OUT;

    wire    [3:0]                       UDE_ETH_RXD;
    wire    [3:0]                       UDE_ETH_TXD;
    wire    [3:0]                       w_dummy_txd;
    wire                                UDE_ETH_COL;
    wire                                UDE_ETH_CRS;
    wire                                UDE_ETH_TXC;
    wire                                UDE_ETH_TXEN;
    wire                                UDE_ETH_RXC;
    wire                                UDE_ETH_RXDV;
    wire                                UDE_ETH_RXER;
    wire                                UDE_ETH_MDC;
    wire                                UDE_ETH_MDIO;

    assign UDE_ETH_RXD  = 4'h0;
    assign UDE_ETH_COL  = 1'b0;
    assign UDE_ETH_CRS  = 1'b0;
    assign UDE_ETH_TXC  = 1'b0;
    assign UDE_ETH_RXC  = 1'b0;
    assign UDE_ETH_RXDV = 1'b0;
    assign UDE_ETH_RXER = 1'b0;

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
    wire    [63:0]                      mac0_rx_data;
    wire    [7:0]                       mac0_rx_keep;
    wire                                mac0_rx_last;
    wire                                mac0_rx_valid;

    wire    [63:0]                      mac0_tx_data;
    wire    [7:0]                       mac0_tx_keep;
    wire                                mac0_tx_last;
    wire                                mac0_tx_ready;
    wire                                mac0_tx_valid;

    wire                                dma_block_reset;
    wire                                mac_sys_reset;
    wire    [1:0]                       w_rx_wdt_reset;

    wire                                w_emio_gpio;
    wire                                w_emio_wdt1;

    wire                                w_clk_cpuif;
    wire                                w_fclk_nrst;
    wire                                w_axi_rstn;

    wire    [1-1 : 0]                   frame_sync_cpu_top;
    wire    [9:0]                       w_cpu_sfn_num;

    wire                                w_fh_qpll_reset;
    wire    [1:0]                       w_fh_qpll_lock;

    wire    [1:0]                       w_ecpri_gt_reset_rx_done;
    wire    [1:0]                       w_ecpri_gt_reset_tx_done;
    wire    [1:0]                       w_ecpri_gt_rxlpmen;
    wire    [4:0]                       w_ecpri_gt_txdiffctrl[1:0];
    wire    [4:0]                       w_ecpri_txprecursor  [1:0];
    wire    [4:0]                       w_ecpri_txpostcusor  [1:0];

    wire                                l0_deframer_clk;
    wire                                l1_deframer_clk;

    wire    [1:0]                       w_stat_rx_block_lock;
    wire    [1:0]                       w_stat_rx_local_fault;
    wire    [1:0]                       w_stat_rx_status;

    wire                                w_uart_ret_txd;
    wire                                w_uart_ret_rxd;
    wire                                w_uart_ook0_txd;
    wire                                w_uart_ook0_rxd;
    wire                                w_uart_ook1_txd;
    wire                                w_uart_ook1_rxd;

    wire                                ptp_1pps_cpu_top;

    wire    [19:0]                      w_cpu_addr;
    wire                                w_cpu_cs;
    wire                                w_cpu_rden;
    wire    [31:0]                      w_cpu_rdata;
    wire    [31:0]                      w_cpu_wdata;
    wire                                w_cpu_wren;

    // JESD AXI interconnect: master side driven by the BD, slave side idle
    wire    [31:0]                      w_axi_jesd_araddr;
    wire    [1:0]                       w_axi_jesd_arburst;
    wire    [3:0]                       w_axi_jesd_arcache;
    wire    [7:0]                       w_axi_jesd_arlen;
    wire    [0:0]                       w_axi_jesd_arlock;
    wire    [2:0]                       w_axi_jesd_arprot;
    wire    [3:0]                       w_axi_jesd_arqos;
    wire                                w_axi_jesd_arready;
    wire    [3:0]                       w_axi_jesd_arregion;
    wire    [2:0]                       w_axi_jesd_arsize;
    wire                                w_axi_jesd_arvalid;
    wire    [31:0]                      w_axi_jesd_awaddr;
    wire    [1:0]                       w_axi_jesd_awburst;
    wire    [3:0]                       w_axi_jesd_awcache;
    wire    [7:0]                       w_axi_jesd_awlen;
    wire    [0:0]                       w_axi_jesd_awlock;
    wire    [2:0]                       w_axi_jesd_awprot;
    wire    [3:0]                       w_axi_jesd_awqos;
    wire                                w_axi_jesd_awready;
    wire    [3:0]                       w_axi_jesd_awregion;
    wire    [2:0]                       w_axi_jesd_awsize;
    wire                                w_axi_jesd_awvalid;
    wire                                w_axi_jesd_bready;
    wire    [1:0]                       w_axi_jesd_bresp;
    wire                                w_axi_jesd_bvalid;
    wire    [31:0]                      w_axi_jesd_rdata;
    wire                                w_axi_jesd_rlast;
    wire                                w_axi_jesd_rready;
    wire    [1:0]                       w_axi_jesd_rresp;
    wire                                w_axi_jesd_rvalid;
    wire    [31:0]                      w_axi_jesd_wdata;
    wire                                w_axi_jesd_wlast;
    wire                                w_axi_jesd_wready;
    wire    [3:0]                       w_axi_jesd_wstrb;
    wire                                w_axi_jesd_wvalid;



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

    assign mac_sys_reset   = 1'b0;
    assign w_fh_qpll_reset   = 1'b0;

    assign dma_block_reset = 1'b0;
    assign w_rx_wdt_reset    = 2'b00;

    assign w_ecpri_gt_rxlpmen[0]   = 1'b1;
    assign w_ecpri_gt_rxlpmen[1]   = 1'b1;
    assign w_ecpri_gt_txdiffctrl[0] = 5'b11000;
    assign w_ecpri_gt_txdiffctrl[1] = 5'b11000;
    assign w_ecpri_txprecursor[0]   = 5'd0;
    assign w_ecpri_txprecursor[1]   = 5'd0;
    assign w_ecpri_txpostcusor[0]   = 5'd0;
    assign w_ecpri_txpostcusor[1]   = 5'd0;

    assign mac0_tx_data  = 64'd0;
    assign mac0_tx_keep  = 8'd0;
    assign mac0_tx_last  = 1'b0;
    assign mac0_tx_valid = 1'b0;



    mpsoc_ps_system_wrapper RU_MPSoC (
        .AMC_SPI_io0_io                (AMC_SPI_SDI                          ), // output
        .AMC_SPI_io1_io                (AMC_SPI_SDO                          ), // input
        .AMC_SPI_sck_io                (AMC_SPI_SCLK                         ), // output
        .AMC_SPI_ss_io                 (AMC_SPI_CS_L                         ), // output
        .CLK_122P88                    (w_clk_sysx4                         ), // input
        .CLK_245P76                    (w_clk_sysx8                         ), // input
        .DACOUT                        (PWM_FROM_FPGA                       ), // output
        .DL_CU_AXIS_0_tdata            (mac0_rx_data              ), // output [63:0]
        .DL_CU_AXIS_0_tkeep            (mac0_rx_keep              ), // output [7:0]
        .DL_CU_AXIS_0_tlast            (mac0_rx_last              ), // output
        .DL_CU_AXIS_0_tvalid           (mac0_rx_valid             ), // output
        .DL_CU_AXIS_1_tdata            (                                    ), // Not used, // output [63:0]
        .DL_CU_AXIS_1_tkeep            (                                    ), // Not used, // output [7:0]
        .DL_CU_AXIS_1_tlast            (                                    ), // Not used, // output
        .DL_CU_AXIS_1_tvalid           (                                    ), // Not used, // output
        .DMA_BLOCK_RESET               (dma_block_reset                   ), // input
        .EMIO_GPIO_0                   (w_emio_gpio                         ), //w_emio_gpio                        ), // output
        .EMIO_WDT1                     (w_emio_wdt1                         ), //w_emio_wdt1                        ), // output
        .FCLK_CLK0                     (w_clk_cpuif                         ), // output
        .FCLK_NRST                     (w_fclk_nrst                         ), // output
        .FH_QPLL_LOCK0                 (w_fh_qpll_lock[0]                   ), // output
        .FH_QPLL_LOCK1                 (w_fh_qpll_lock[1]                   ), // output
        .FH_QPLL_RESET                 (w_fh_qpll_reset                     ), // input
        .FRAME_SYNC                    (frame_sync_cpu_top[0]            ), // output
        .GMII_ENET0_col                (UDE_ETH_COL                         ), // input
        .GMII_ENET0_crs                (UDE_ETH_CRS                         ), // input
        .GMII_ENET0_rx_clk             (UDE_ETH_RXC                         ), // input
        .GMII_ENET0_rx_dv              (UDE_ETH_RXDV                        ), // input
        .GMII_ENET0_rx_er              (UDE_ETH_RXER                        ), // input
        .GMII_ENET0_rxd                ({4'h0, UDE_ETH_RXD}                 ), // input  [7:0]
        .GMII_ENET0_speed_mode         (                                    ), // output [2:0]
        .GMII_ENET0_tx_clk             (UDE_ETH_TXC                         ), // input
        .GMII_ENET0_tx_en              (UDE_ETH_TXEN                        ), // output
        .GMII_ENET0_tx_er              (                                    ), // output
        .GMII_ENET0_txd                ({w_dummy_txd, UDE_ETH_TXD}          ), // output [7:0]
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
        .JESD_AXI_INTERCONNECT_araddr  (w_axi_jesd_araddr  ), //output [31:0]
        .JESD_AXI_INTERCONNECT_arburst (w_axi_jesd_arburst ), //output [1:0]
        .JESD_AXI_INTERCONNECT_arcache (w_axi_jesd_arcache ), //output [3:0]
        .JESD_AXI_INTERCONNECT_arlen   (w_axi_jesd_arlen   ), //output [7:0]
        .JESD_AXI_INTERCONNECT_arlock  (w_axi_jesd_arlock  ), //output [0:0]
        .JESD_AXI_INTERCONNECT_arprot  (w_axi_jesd_arprot  ), //output [2:0]
        .JESD_AXI_INTERCONNECT_arqos   (w_axi_jesd_arqos   ), //output [3:0]
        .JESD_AXI_INTERCONNECT_arready (w_axi_jesd_arready), //input  [0:0]
        .JESD_AXI_INTERCONNECT_arregion(w_axi_jesd_arregion), //output [3:0]
        .JESD_AXI_INTERCONNECT_arsize  (w_axi_jesd_arsize  ), //output [2:0]
        .JESD_AXI_INTERCONNECT_arvalid (w_axi_jesd_arvalid ), //output [0:0]
        .JESD_AXI_INTERCONNECT_awaddr  (w_axi_jesd_awaddr  ), //output [31:0]
        .JESD_AXI_INTERCONNECT_awburst (w_axi_jesd_awburst ), //output [1:0]
        .JESD_AXI_INTERCONNECT_awcache (w_axi_jesd_awcache ), //output [3:0]
        .JESD_AXI_INTERCONNECT_awlen   (w_axi_jesd_awlen   ), //output [7:0]
        .JESD_AXI_INTERCONNECT_awlock  (w_axi_jesd_awlock  ), //output [0:0]
        .JESD_AXI_INTERCONNECT_awprot  (w_axi_jesd_awprot  ), //output [2:0]
        .JESD_AXI_INTERCONNECT_awqos   (w_axi_jesd_awqos   ), //output [3:0]
        .JESD_AXI_INTERCONNECT_awready (w_axi_jesd_awready), //input  [0:0]
        .JESD_AXI_INTERCONNECT_awregion(w_axi_jesd_awregion), //output [3:0]
        .JESD_AXI_INTERCONNECT_awsize  (w_axi_jesd_awsize  ), //output [2:0]
        .JESD_AXI_INTERCONNECT_awvalid (w_axi_jesd_awvalid ), //output [0:0]
        .JESD_AXI_INTERCONNECT_bready  (w_axi_jesd_bready  ), //output [0:0]
        .JESD_AXI_INTERCONNECT_bresp   (w_axi_jesd_bresp  ), //input  [1:0]
        .JESD_AXI_INTERCONNECT_bvalid  (w_axi_jesd_bvalid ), //input  [0:0]
        .JESD_AXI_INTERCONNECT_rdata   (w_axi_jesd_rdata  ), //input  [31:0]
        .JESD_AXI_INTERCONNECT_rlast   (w_axi_jesd_rlast  ), //input  [0:0]
        .JESD_AXI_INTERCONNECT_rready  (w_axi_jesd_rready  ), //output [0:0]
        .JESD_AXI_INTERCONNECT_rresp   (w_axi_jesd_rresp  ), //input  [1:0]
        .JESD_AXI_INTERCONNECT_rvalid  (w_axi_jesd_rvalid ), //input  [0:0]
        .JESD_AXI_INTERCONNECT_wdata   (w_axi_jesd_wdata   ), //output [31:0]
        .JESD_AXI_INTERCONNECT_wlast   (w_axi_jesd_wlast   ), //output [0:0]
        .JESD_AXI_INTERCONNECT_wready  (w_axi_jesd_wready ), //input  [0:0]
        .JESD_AXI_INTERCONNECT_wstrb   (w_axi_jesd_wstrb   ), //output [3:0]
        .JESD_AXI_INTERCONNECT_wvalid  (w_axi_jesd_wvalid  ), //output [0:0]
        .L0_DEFRAMER_CLK               (l0_deframer_clk                   ), // output
        .L1_DEFRAMER_CLK               (l1_deframer_clk                   ), // output
        .MAC_SYS_RESET                 (mac_sys_reset                     ), // input
        .MDIO_ENET0_mdc                (UDE_ETH_MDC                         ), // output
        .MDIO_ENET0_mdio_io            (UDE_ETH_MDIO                        ), // inout
        .MODE_CHANGE_10G_25G_0         (1'b0                                ), // input
        .MODE_CHANGE_10G_25G_1         (1'b0                                ), // Not Used, input
        .PDM_TEST_EN                   (1'b0                                ), // Not Used, input
        .PLL_100to250_locked           (                                    ),  // output
        .PLL_122p88to100_locked        (                                    ), // output
        .PTP_1PPS                      (ptp_1pps_cpu_top                          ), // output
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
        .STAT_RX_STATUS_0              (w_stat_rx_status[0]                 ), // output
        .STAT_RX_STATUS_1              (w_stat_rx_status[1]                 ), // output
        .UART_OOK_0_rxd                (w_uart_ook0_rxd                     ),  //  input     
        .UART_OOK_0_txd                (w_uart_ook0_txd                     ),  //  output   
        .UART_OOK_1_rxd                (w_uart_ook1_rxd                     ),  //  input    
        .UART_OOK_1_txd                (w_uart_ook1_txd                     ),  //  output   
        .UART_RET_rxd                  (w_uart_ret_rxd                      ), // input
        .UART_RET_txd                  (w_uart_ret_txd                      ), // output
        .UART_RFIC_rxd                 (RFIC_UART_IN                        ),  //  input  
        .UART_RFIC_txd                 (RFIC_UART_OUT                       ),  //  output
        .UL_UL_AXIS_0_tdata            (mac0_tx_data              ), // input [63:0]
        .UL_UL_AXIS_0_tkeep            (mac0_tx_keep              ), // input [7:0]
        .UL_UL_AXIS_0_tlast            (mac0_tx_last              ), // input
        .UL_UL_AXIS_0_tready           (mac0_tx_ready             ), // output
        .UL_UL_AXIS_0_tvalid           (mac0_tx_valid             ), // input
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
        .user_wr                       (w_cpu_wren                          )  // output
    );
	
	
	
	
	
	
endmodule


