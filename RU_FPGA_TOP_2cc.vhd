----------------------------------------------------------------------------------
-- Company       : Samsung Electronics
-- Engineer      :
--
-- Create Date   : 2017.02.10
-- Design Name   :
-- Module Name   : RU_FPGA_TOP - arc_RU_FPGA_TOP
-- Project Name  : XTMD_07, UQ FD-MIMO DSP FPGA,
-- Target Devices: XCZU9EG-L1FFVB1156I-ES1, Zynq-UltraScale+, Xilinx
-- Tool versions : Vivado 2016.4, Xilinx
-- Description   :
--
-- Dependencies  :
--
-- Revision      : 16.11.03 - v00. First Release, Included belows
--

----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

library work;
use work.ARRAY_TYPE.all;
use work.RU_FPGA_FNC.all;
use work.RU_FPGA_CONFIG.all;

entity RU_FPGA_TOP is
    port(
        --**************************************************
        -- INTERFACE
        --**************************************************
        DFPGA_RST                           : out   std_logic;
        --    FPGA_INTERRUPT                      : in    std_logic;
        FPGA_FUNCTION_FAIL_IN               : in    std_logic;

        SIG_SUS_OUT                         : out   std_logic_vector(2 downto 0);

        --**************************************************
        -- Clock
        --**************************************************
        FPGA_REF_CLK                        : in    std_logic; -- 122.88MHz
        REF_CLK_OUT                         : out   std_logic; -- External Clock PLL reference clock out
        --    CLK_125MHz                          : in    std_logic; -- 125MHz
        SYSTEM_TIMER_CLK                    : in    std_logic;

        MGT_REF_CLK_0                       : in    std_logic; -- 161 MHz (ORAN)
        MGT_REF_CLK_1                       : in    std_logic; -- 184.32 MHz (CPRI) -- NOT USE 
        MGT_REF_CLK_2                       : in    std_logic; -- 122.88 MHz (SBIF) -- NOT USE 
        MGT_REF_CLK_3                       : in    std_logic; -- 122.88 MHz (JESD204)
        MGT_REF_CLK_4                       : in    std_logic; -- 125 MHz (AXI)

        PWM_FROM_MFPGA                      : out   std_logic;
        TCXO_OUT_PLL                        : in    std_logic;

        --eCPRI PHY
        ECPRI_GT_REF_CLK_0_N        : in    std_logic;
        ECPRI_GT_REF_CLK_0_P        : in    std_logic;

        --CLK_50MHz                           : in    std_logic; -- 50 MHz
        --**************************************************
        -- PLL (LMK04828)
        --**************************************************
        CLK_PLL_LOS                         : in    std_logic;
        CLK_PLL_LD                          : in    std_logic;

        --**************************************************
        -- Optic module
        --**************************************************

        OTRX_TX_FAULT                       : in    std_logic_vector(1 downto 0);
        OTRX_DISABLE                        : out   std_logic_vector(1 downto 0);
        OTRX_MOD_ABS                        : in    std_logic_vector(1 downto 0);
        OTRX_LOS                            : in    std_logic_vector(1 downto 0);
        OTRX_BH_RS0                          : out   std_logic_vector(1 downto 0);
        OTRX_BH_RS1                          : out   std_logic_vector(1 downto 0);

        --------------------------------------------------------------------------------
        -- UDE (DP83848)
        --------------------------------------------------------------------------------
        UDE_ETH_TXD                         : out   std_logic_vector(3 downto 0);
        UDE_ETH_RXD                         : in    std_logic_vector(3 downto 0);
        UDE_ETH_COL                         : in    std_logic;
        UDE_ETH_CRS                         : in    std_logic;
        UDE_ETH_TXC                         : in    std_logic;
        UDE_ETH_TXEN                        : out   std_logic;
        UDE_ETH_RXC                         : in    std_logic;
        UDE_ETH_RXDV                        : in    std_logic;
        UDE_ETH_RXER                        : in    std_logic;
        UDE_ETH_TXER                        : out    std_logic;

        UDE_ETH_nRESET                      : out   std_logic;
        UDE_ETH_25MHz                       : out   std_logic;
        UDE_ETH_MDC                         : out   std_logic;
        UDE_ETH_MDIO                        : inout std_logic;

        --**************************************************
        -- DU SerDes
        --**************************************************

        RU_DU_P                             : out   std_logic_vector(1 downto 0);
        RU_DU_N                             : out   std_logic_vector(1 downto 0);

        DU_RU_P                             : in    std_logic_vector(1 downto 0);
        DU_RU_N                             : in    std_logic_vector(1 downto 0);

        --**************************************************
        -- RFIC Traffic I/Q
        --**************************************************
        JESD_SERIAL_TX_OUT_P                : out std_logic_vector((JESD_TX_LINK_NUM*JESD_TX_LANE_NUM-1) downto 0);   -- JESD204B Serial TX P
        JESD_SERIAL_TX_OUT_N                : out std_logic_vector((JESD_TX_LINK_NUM*JESD_TX_LANE_NUM-1) downto 0);   -- JESD204B Serial TX N

        JESD_SERIAL_FB_IN_P                 : in  std_logic_vector((JESD_FB_LINK_NUM*JESD_FB_LANE_NUM-1) downto 0);   -- JESD204B Serial FB P
        JESD_SERIAL_FB_IN_N                 : in  std_logic_vector((JESD_FB_LINK_NUM*JESD_FB_LANE_NUM-1) downto 0);   -- JESD204B Serial FB N

        JESD_SERIAL_RX_IN_P                 : in  std_logic_vector((JESD_RX_LINK_NUM*JESD_RX_LANE_NUM-1) downto 0);   -- JESD204B Serial RX P
        JESD_SERIAL_RX_IN_N                 : in  std_logic_vector((JESD_RX_LINK_NUM*JESD_RX_LANE_NUM-1) downto 0);   -- JESD204B Serial RX N

        --**************************************************
        -- RFIC Interface
        --**************************************************
        --TX_B13_A_SW_OUT                     : out std_logic;
        --TX_B13_B_SW_OUT                     : out std_logic;
        --TX_B13_C_SW_OUT                     : out std_logic;
        --TX_B13_D_SW_OUT                     : out std_logic;

        JESD_SYNC_TX_IN                     : in    std_logic_vector(JESD_TX_LINK_NUM-1 downto 0);
        JESD_SYSREF_TX_OUT                  : out   std_logic_vector(JESD_TX_LINK_NUM-1 downto 0);
        JESD_SYNC_FB_OUT                    : out   std_logic_vector(JESD_FB_LINK_NUM-1 downto 0);
        JESD_SYSREF_FB_OUT                  : out   std_logic_vector(JESD_FB_LINK_NUM-1 downto 0);
        JESD_SYNC_RX_OUT                    : out   std_logic_vector(JESD_RX_LINK_NUM-1 downto 0);
        JESD_SYSREF_RX_OUT                  : out   std_logic_vector(JESD_RX_LINK_NUM-1 downto 0);

        RFIC_GPIO_IN                        : in    std_logic_array19(RFIC_NUM-1 downto 0);
        RFIC_GPIO_OUT                       : out   std_logic_array19(RFIC_NUM-1 downto 0);

        RFIC_RST_CTRL                       : out   std_logic_vector(RFIC_NUM-1 downto 0);
        RFIC_TRI_ENB                        : out   std_logic_vector(RFIC_NUM-1 downto 0);
        --    RFIC_GP_INTERRUPT                   : in    std_logic_vector(RFIC_NUM-1 downto 0);
        RFIC_GP_INTERRUPT                   : in    std_logic_vector(1 downto 0);
        --RFIC_TX_EN                          : out   std_logic_vector(RFIC_NUM-1 downto 0);
        --RFIC_RX_EN                          : out   std_logic_vector(RFIC_NUM-1 downto 0);
        --RFIC_FB_EN                          : out   std_logic_array2(RFIC_NUM-1 downto 0);

        --**************************************************
        -- SPI Interface
        --**************************************************
        O_SPI_SCK_IO                          : out   std_logic_vector(SPI_NUM-2 downto 0);
        O_SPI_SS_IO                           : out   std_logic_vector(SPI_NUM-2 downto 0);
        O_SPI_MOSI_IO                         : out   std_logic_vector(SPI_NUM-2 downto 0);
        I_SPI_MISO_IO                         : in    std_logic_vector(SPI_NUM-2 downto 0);

        --**************************************************
        -- AMC7812B uni-direction SPI
        --**************************************************
        AMC_SPI_CS1_OUT                     : out   std_logic;
        AMC_SPI_CS2_OUT                     : out   std_logic;
        AMC_SPI_CLK                         : out   std_logic;
        AMC_SPI_M_OUT                       : out   std_logic;
        AMC_SPI_M_IN                        : in    std_logic;

        --**************************************************
        -- I2C Interface
        --**************************************************
        IIC_SCL_IO                          : inout std_logic_vector(IIC_NUM-1 downto 0);
        IIC_SDA_IO                          : inout std_logic_vector(IIC_NUM-1 downto 0);

        --**************************************************
        -- External Device Interface
        --**************************************************
        -- ispPAC Control
        FPGA_PWR_STATUS                     : in    std_logic;
        ISPPAC_CTRL                         : out   std_logic_vector( 2 downto 0);

        -- UDA
        UDA_IN                              : in  std_logic_vector(3 downto 0);

        -- FB Switch
        RFIC_TX_EN_OUT                      : out std_logic;
        RFIC_FB_EN_0_OUT                    : out std_logic;
        RFIC_FB_EN_1_OUT                    : out std_logic;
        RFIC_FB2_TX_SEL0_OUT                : out std_logic;
        RFIC_FB3_TX_SEL0_OUT                : out std_logic;
        RFIC_FB2_TX_SEL1_OUT                : out std_logic;
        RFIC_FB3_TX_SEL1_OUT                : out std_logic;

        RFIC_RX_EN_OUT                      : out std_logic;
        CTRL_PATH1_OUT                      : out std_logic;
        CTRL_PATH2_OUT                      : out std_logic;
        ENA_PATH12_OUT                      : out std_logic;
        CTRL_PATH3_OUT                      : out std_logic;
        CTRL_PATH4_OUT                      : out std_logic;
        ENA_PATH34_OUT                      : out std_logic;

        TX_SW_0_OUT                         : out std_logic;
        TX_SW_1_OUT                         : out std_logic;
        TX_SW_2_OUT                         : out std_logic;
        TX_SW_3_OUT                         : out std_logic;
        RF_RX_SW_CTRL                       : out std_logic;
        --    RX_SW_OUT                           : out std_logic;
        TX_RF_LDO_ONOFF                     : out std_logic;
        RX_RF_LDO_ONOFF                     : out std_logic;

        -- PA Control Interface
        B13_AMP_EN_OUT                      : out std_logic_vector(TX_ANT_NUM-1 downto 0);

        -- RET, BIAS-T Control Interface
        OOK_B13_A_TXIN                       : out   std_logic;                          -- C17
        OOK_B13_A_RXOUT                      : in    std_logic;                          -- D17
        OOK_B13_A_DIR                        : in    std_logic;                          -- E18
        OOK_B13_A_DIRMD1                     : out   std_logic;                          -- D19
        OOK_B13_A_DIRMD2                     : out   std_logic;                          -- E17
        BIAS_T_B13_A_ONOFF                   : out   std_logic;                          -- E19
        CLK_OOK_B13_A_8M704                  : out   std_logic;                          -- F18

        OOK_B13_C_TXIN                       : out   std_logic;                          -- F17
        OOK_B13_C_RXOUT                      : in    std_logic;                          -- G19
        OOK_B13_C_DIR                        : in    std_logic;                          -- G18
        OOK_B13_C_DIRMD1                     : out   std_logic;                          -- L17
        OOK_B13_C_DIRMD2                     : out   std_logic;                          -- K17
        BIAS_T_B13_C_ONOFF                   : out   std_logic;                          -- K18
        CLK_OOK_B13_C_8M704                  : out   std_logic;                          -- L18

        RET_UART_TXD_OUT                    : out   std_logic;                          -- H17
        RET_DE                              : out   std_logic;                          -- J17
        RET_nRE                             : out   std_logic;                          -- H19
        RET_UART_RXD_IN                     : in    std_logic;                          -- H18

        RET_ONOFF                           : out   std_logic;

        EXT_EN_5p0V_OUT                     : out   std_logic;

        UV_ALARM_IN                         : in    std_logic;
        TRX_DC_NORMAL_IN                    : in    std_logic;
        PWR55_NORMAL_IN                     : in    std_logic;

        -- Power Monitoring
        PG_0P85V_MFPGA                      : in    std_logic;                          -- AK1
        PG_1P8V_MFPGA                       : in    std_logic;                          -- AL2
        PG_0P85V_MFPGA_PSMGT                : in    std_logic;                          -- AL3
        PG_1P2V_MFPGA_PSPLL                 : in    std_logic;                          -- AN1
        PG_1P8V_MFPGA_MGT                   : in    std_logic;                          -- AM1
        PG_1P2V_DDR4                        : in    std_logic;                          -- AP3
        PG_3P3V_CLK                         : in    std_logic;                          -- AN3
        PG_3P3V                             : in    std_logic;                          -- AP2
        PG_0P9V_MFPGA_MGT                   : in    std_logic;                          -- AN2
        PG_1P2V_MFPGA_MGT                   : in    std_logic;                          -- AP1
        PG_1P0V_RFIC0_DIGITAL               : in    std_logic;                          -- AM3
        PG_1P3V_RFIC0_ANALOG                : in    std_logic;                          -- AK4
        PG_1p8V_RFIC_VDD                    : in  std_logic;
        --------------------------------
        -- AMC RESET
        --------------------------------
        AMP_AMC_RST1_OUT                : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
        AMP_AMC_RST2_OUT                : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use

        --------------------------------
        -- RX Attenuation
        --------------------------------
        RXATT_B13_AB_DI_OUT                 : out std_logic;
        RXATT_B13_AB_CLK_OUT                : out std_logic;
        RXATT_B13_A_LE_OUT                  : out std_logic;
        RXATT_B13_B_LE_OUT                  : out std_logic;

        RXATT_B13_CD_DI_OUT                 : out std_logic;
        RXATT_B13_CD_CLK_OUT                : out std_logic;
        RXATT_B13_C_LE_OUT                  : out std_logic;
        RXATT_B13_D_LE_OUT                  : out std_logic;

        TXATT_B13_AB_DI_OUT                 : out std_logic;
        TXATT_B13_AB_CLK_OUT                : out std_logic;
        TXATT_B13_A_LE_OUT                  : out std_logic;
        TXATT_B13_B_LE_OUT                  : out std_logic;

        TXATT_B13_CD_DI_OUT                 : out std_logic;
        TXATT_B13_CD_CLK_OUT                : out std_logic;
        TXATT_B13_C_LE_OUT                  : out std_logic;
        TXATT_B13_D_LE_OUT                  : out std_logic;
        --------------------------------
        -- XADC monitoring
        --------------------------------
        RET_MON_N_IN                        : in  std_logic;
        RET_MON_P_IN                        : in  std_logic;

        RET_CURRENT_MON_N_IN                : in  std_logic;
        RET_CURRENT_MON_P_IN                : in  std_logic;

        --------------------------------
        --PSU I2C RST
        --------------------------------
        E_MFPGA_PSU_I2C_SW_RST              : out   std_logic;
        FPGA_PSB_AMP_48V_ONOFF          : out std_logic;
        --------------------------------
        --PSU VER
        --------------------------------    
        PSU_VER                             : in    std_logic;

        --**************************************************
        --BIAST enable
        --**************************************************
        BIAST_3P3V_EN                       : out    std_logic;
        --**************************************************
        -- FPGA ID
        --**************************************************
        FPGA_ID                             : in    std_logic_vector(3 downto 0);
        FPGA_PCB_VER                        : in  std_logic_vector(2 downto 0);

        --**************************************************
        -- PMA Init
        --**************************************************
        PMA_INIT                            : out   std_logic_vector(3 downto 0);

        SLAVE_C2C_LINK_STATUS               : in    std_logic;
        SLAVE_C2C_CHANNEL_UP                : in    std_logic;

        --**************************************************
        -- LED CONTROL
        --**************************************************
        --    LED_RED_OUT                         : out std_logic_vector(LED_NUM-1 downto 0);
        --    LED_GREEN_OUT                       : out std_logic_vector(LED_NUM-1 downto 0);
        LED_ANT_RED                         : out std_logic;
        LED_ANT_BLUE                        : out std_logic;
        LED_ANT_GREEN                       : out std_logic;
        LED_FAN_RED                         : out std_logic;
        LED_FAN_BLUE                        : out std_logic;
        LED_FAN_GREEN                       : out std_logic;
        LED_OPT_RED                         : out std_logic;
        LED_OPT_BLUE                        : out std_logic;
        LED_OPT_GREEN                       : out std_logic;
        LED_SYS_RED                         : out std_logic;
        LED_SYS_BLUE                        : out std_logic;
        LED_SYS_GREEN                       : out std_logic;


        FRAME_SYNC_C2C                      : out std_logic;                    -- active high(10ms -PROC_DLY @ 245.76 MHz)@SFN_NUM#
        SFN_NUM_C2C                         : out std_logic_vector(11 downto 0);                     -- active high(10ms -PROC_DLY @ 245.76 MHz)@SFN_NUM#0
        --------------------------------------------------------------------------------
        -- etc control
        --------------------------------------------------------------------------------
        RU_1PPS                             : out std_logic;
        OUT_1PPS                            : out std_logic;

        TP_CON                              : out std_logic;
        EQUIP_TDD                           : out std_logic
    );
end RU_FPGA_TOP;

architecture arc_RU_FPGA_TOP of RU_FPGA_TOP is

    component SYSCTRL_TOP is
        port(
            ----------------------------------------------------------------------
            ----  External System PLL
            ----------------------------------------------------------------------
            FPGA_ID                             : in  std_logic_vector(3 downto 0);
            FPGA_PCB_VER                        : in  std_logic_vector(2 downto 0);
            ----------------------------------------------------------------------
            ----  PSU_VER
            ----------------------------------------------------------------------    
            PSU_VER                             : in  std_logic;

            --**************************************************
            --BIAST enable
            --**************************************************
            BIAST_3P3V_EN                       : out    std_logic;

            ----------------------------------------------------------------------
            TCXO_OUT_PLL                        : in  std_logic;

            ----------------------------------------------------------------------
            ----  External System PLL
            ----------------------------------------------------------------------
            EXT_SYSPLL_LOCK_IN                  : in  std_logic_vector( 2 downto 0);
            EXT_SYSPLL_LOS_IN                   : in  std_logic;
            EXT_SYSCLK_IN                       : in  std_logic;
            FPGA_SYSCLK_FB_IN                   : in  std_logic;
            FPGA_SYSCLK_FB_OUT                  : out std_logic;
            MGT_REFCLK0_IN                      : in  std_logic;                              -- AURORORA
            MGT_REFCLK1_IN                      : in  std_logic;                              -- CPRI CB_DB
            MGT_REFCLK2_IN                      : in  std_logic;                              -- SBIF
            MGT_REFCLK3_IN                      : in  std_logic;                              -- JESD
            MGT_REFCLK4_IN                      : in  std_logic;                              -- AURORORA

            PTP_REF_CLK                             : in  std_logic; -- PTP Reference clock
            CLK_PTP                                 : out std_logic; -- 156.25 MHz

            ----------------------------------------------------------------------
            --  CPU-TOP
            ----------------------------------------------------------------------
            CLK_CPUIF                           : in  std_logic;
            RST_CPUIF                           : in  std_logic;

            ----------------------------------------------------------------------
            --  CPUIF-TOP
            ----------------------------------------------------------------------
            ADDR_CPUIF_SYSCTRL_IN               : in  std_logic_vector(15 downto 0);
            WDATA_CPUIF_SYSCTRL_IN              : in  std_logic_vector(31 downto 0);
            RDATA_CPUIF_SYSCTRL_OUT             : out std_logic_vector(31 downto 0);
            WREN_CPUIF_SYSCTRL_IN               : in  std_logic;
            RDEN_CPUIF_SYSCTRL_IN               : in  std_logic;
            RDVAL_CPUIF_SYSCTRL_OUT             : out std_logic;

            ------------------------------------------------------------------------
            --  SBIFPHY_TOP  --## DSP_FPGA_ONLY_PORT
            ------------------------------------------------------------------------
            --    RST_SBIFPHY                         : out std_logic_vector( SBIF_NUM-1 downto 0);
            REFCLK_SSERDES_OUT                  : out std_logic_vector(SSREF_NUM-1 downto 0);

            --------------------------------------------------------------------------
            --  SBIF_TOP  --## DSP_FPGA_ONLY_PORT
            --------------------------------------------------------------------------
            CLK_SYS                             : out std_logic;                              -- 30.72  MHz
            CLK_SYSX2                           : out std_logic;                              -- 61.44  MHz
            CLK_SYSX3                           : out std_logic;                              -- 92.16  MHz
            CLK_SYSX4                           : out std_logic;                              -- 122.88 MHz
            CLK_SYSX5                           : out std_logic;                              -- 153.6  MHz
            CLK_SYSX6                           : out std_logic;                              -- 184.32 MHz
            CLK_SYSX8                           : out std_logic;                              -- 245.76 MHz
            CLK_SYSX10                          : out std_logic;                              -- 307.2  MHz
            CLK_SYSX12                          : out std_logic;                              -- 368.64 MHz
            CLK_SYSX16                          : out std_logic;                              -- 491.52 MHz
            CLK_SYSX20                          : out std_logic;                              -- 614.4  MHz

            --------------------------------------------------------------------
            CLK_TCXO_X1                         : out std_logic;
            CLK_TCXO_X4                         : out std_logic;
            CLK_TCXO_X8                         : out std_logic;
            --------------------------------------------------------------------
            --  CPRIPHY_TOP --CTRL FPGA
            --------------------------------------------------------------------
            CLK_SBIF                            : out std_logic_vector(PIM_SBIF_NUM -1 downto 0);
            CLK_SBIFXH                          : out std_logic_vector(PIM_SBIF_NUM -1 downto 0);
            CLK_SBIFX2                          : out std_logic_vector(PIM_SBIF_NUM -1 downto 0);

            REFCLK_CSERDES_OUT                  : out std_logic_vector(CSREF_NUM-1 downto 0);
            REFCLK_OSERDES_OUT                  : out std_logic_vector(EPHY_NUM- 1 downto 0);
            REFCLK_SEL_IN                       : in  std_logic_vector( 3 downto 0);
            --------------------------------------------------------------------------
            --  ECPRI_MMCM --CTRL FPGA
            --------------------------------------------------------------------------

            SYSTEM_TIMER_MMCM_RST               : out   std_logic;
            SYSTEM_TIMER_MMCM_LOCK              : in    std_logic;

            ----------------------------------------------------------------------
            --  CPRI_TOP  --CTRL_FPGA
            ----------------------------------------------------------------------
            RST_IQCOMP                          : out std_logic_vector(IQCOMP_NUM-1 downto 0);
            RST_ETHMUX                          : out std_logic;
            CLK_MII                             : out std_logic;                              -- 25  MHz
            CLK_MIIX2                           : out std_logic;                              -- 50  MHz
            CLK_MIIX4                           : out std_logic;                              -- 100 MHz
            CLK_MIIX8                           : out std_logic;                              -- 200 MHz
            RX_BFN_STRB_IN                      : in  std_logic_vector( CPRI_NUM-1 downto 0); -- strobe delay
            RX_BFN_NR_IN                        : in  std_logic_array12(CPRI_NUM-1 downto 0); -- strobe delay
            TX_BFN_STRB_OUT                     : out std_logic_vector( CPRI_NUM-1 downto 0); -- strobe delay
            TX_BFN_NR_OUT                       : out std_logic_array12(CPRI_NUM-1 downto 0); -- strobe delay
            RU_ID_OUT                           : out std_logic_vector( 3 downto 0);
            RU_FF_OUT                           : out std_logic;
            VSS_RMT_RST_CPRI_IN                 : in  std_logic_vector(CPRI_NUM-1 downto 0);
            IS_MASTER_CPRI_IN                   : in  std_logic_vector(CPRI_NUM-1 downto 0);
            LINE_RCF_START_IN                   : in  std_logic_vector(CPRI_NUM-1 downto 0);
            LINE_RCF_RATE_IN                    : in  std_logic_array8(CPRI_NUM-1 downto 0);
            LINE_RCF_CLKTYPE_IN                 : in  std_logic_array8(CPRI_NUM-1 downto 0);
            LINE_RCF_WIDTH_IN                   : in  std_logic_array8(CPRI_NUM-1 downto 0);

            ----------------------------------------------------------------------
            --  SBIF_TOP  --## CTRL_FPGA_ONLY_PORT BBCTRL-TOP
            ----------------------------------------------------------------------
            RX_BFN_STRB_OUT                     : out std_logic_vector( CPRI_NUM-1 downto 0); -- strobe delay  -- free running
            RX_BFN_NR_OUT                       : out std_logic_array12(CPRI_NUM-1 downto 0);
            RX_TDD_OUT                          : out std_logic_vector( CPRI_NUM-1 downto 0);
            TX_TDD_IN                           : in  std_logic_vector( CPRI_NUM-1 downto 0); -- from analog input tdd
            TX_BFN_STRB_IN                      : in  std_logic_vector( CPRI_NUM-1 downto 0); -- from analog input strobe

            REFCLK_ASERDES_OUT                  : out std_logic_vector(ASREF_NUM-1 downto 0);

            ----------------------------------------------------------------------
            --  BBCTRL-TOP
            ----------------------------------------------------------------------
            INNER_DL_TDD_AND_CTRL_OUT           : out std_logic; -- don't used in verizon
            INNER_DL_TDD_OR_CTRL_OUT            : out std_logic; -- don't used in verizon

            ----------------------------------------------------------------------
            --  DSP-TOP  --## DSP_FPGA_ONLY_PORT
            ----------------------------------------------------------------------
            INT_SYSPLL_LOCK_OUT                 : out std_logic;
            RST_BBCTRL                          : out std_logic;
            RST_DDUC                            : out std_logic;
            RST_CFR                             : out std_logic;
            RST_DPD                             : out std_logic;

            ----------------------------------------------------------------------
            --  DCIF-TOP --## DSP_FPGA_ONLY_PORT
            ----------------------------------------------------------------------
            RST_DCIF                            : out std_logic;
            REFCLK_JSERDES_OUT                  : out std_logic_vector(JSREF_NUM-1 downto 0);

            ----------------------------------------------------------------------
            -- RX_TDD relation ## DSP FPGA
            ---------------------------------------------------------------------
            DL_1PPS_BFN_STROBE_IN               : in  std_logic;--from JESD OUT STROBE(equip tdd same)
            INNER_RX_TDD_OUT                    : out std_logic;--to JESD RX TDD   -- don't used in verizon
            INNER_RX_BFN_STROBE_OUT             : out std_logic;--to JESD RX STROBE
            DFPGA_TDD                           : out std_logic; -- don't used in verizon  --to JESD RX STROBE

            ----------------------------------------------------------------------
            --  MISC-TOP
            ----------------------------------------------------------------------
            -- CTRL_FPGA
            WATCHDOG_CLR                        : in  std_logic;
            HWWDT_FLAG_OUT                      : out std_logic;
            LED_CTRL_OUT                        : out std_logic_array4(LED_NUM-1 downto 0);
            FUNC_FAIL_TRIG_IN                   : in  std_logic_vector(1 downto 0);
            VSS_RMT_RST_OUT                     : out std_logic;

            ------------------------------------------------------------------------
            --  PIM_reset
            ------------------------------------------------------------------------
            RST_PIM                             : out std_logic;
            RST_PIM_SBIF                        : out std_logic;
            RST_PIM_SBIF_PHY                    : out std_logic;

            ------------------------------------------------------------------------
            -- NR SSB Parameter
            ------------------------------------------------------------------------
            NR_SSB_PERIOD                       : out std_logic_vector(4 downto 0);
            NR_SSB_OFFSET                       : out std_logic_vector(3 downto 0);
            SECTOR_MODE                         : out std_logic_vector(1 downto 0);
            eMTC_SEL                            : out std_logic_vector(1 downto 0);

            -- DSP_FPGA
            TDD_CTRL_OUT                        : out std_logic_vector(31 downto 0); -- don't used in verizon
            OOK_CLK                             : out std_logic;           -- 8.704
            RST_MISC                            : out std_logic;
            CLK_MISC0                           : out std_logic;                              -- user defind clock ??  25 MHz
            CLK_MISC1                           : out std_logic;                              -- user defind clock ??  50 MHz
            CLK_MISC2                           : out std_logic;                              -- user defind clock ?? 100 MHz
            CLK_MISC3                           : out std_logic;                              -- user defind clock ?? 200 MHz

            --    SYSCTRL_ECPRIPHY_RST                : out std_logic_vector( ECPRIPHY_NUM -1 downto 0 )  ; 
            SYSCTRL_ORAN_FRAMER_RST             : out std_logic_vector( DL_NUM_CC    -1 downto 0 )  ;
            SYSCTRL_ORAN_DEFRAMER_RST           : out std_logic_vector( UL_NUM_CC    -1 downto 0 )  ;
            SYSCTRL_LPHY_TOP_RST                : out std_logic_vector( DL_NUM_CC    -1 downto 0 )  ;
            SYSCTRL_DLFE_RST                    : out std_logic_vector( DL_NUM_CC    -1 downto 0 )  ;
            SYSCTRL_ULFE_RST                    : out std_logic_vector( UL_NUM_CC    -1 downto 0 )  ;
            SYSCTRL_RAFE_RST                    : out std_logic_vector( UL_NUM_CC    -1 downto 0 )  ;
            SYSCTRL_AURORA_RST                  : out std_logic;

            DL_CC0_SYNC_ADVANCE                 : out std_logic_vector(21 downto 0);
            DL_CC1_SYNC_ADVANCE                 : out std_logic_vector(21 downto 0);
            UL_CC0_SYNC_RETARD                  : out std_logic_vector(21 downto 0);
            UL_CC1_SYNC_RETARD                  : out std_logic_vector(21 downto 0);
            N_TA_OFFSET_CC0                     : out  std_logic_vector(15 downto 0);
            N_TA_OFFSET_CC1                     : out  std_logic_vector(15 downto 0);

            TP_CON_SEL                          : out std_logic_vector(7 downto 0);

            FRAME_SYNC_C2C                      : out std_logic;                    -- active high(10ms -PROC_DLY @ 245.76 MHz)@SFN_NUM#0
            SFN_NUM_C2C                         : out std_logic_vector(11 downto 0)                     -- active high(10ms -PROC_DLY @ 245.76 MHz)@SFN_NUM#0
        );
    end component;

    component CPU_TOP
        port (
            -- User CS interface
            CLK_122P88M_IN               :in    std_logic;
            CLK_CPU_OUT                 : out   std_logic;
            RST_CPU_OUT                 : out   std_logic;
            ADDR_CPU_OUT                : out   std_logic_vector(19 downto 0);
            CS_CPU_OUT                  : out   std_logic;
            RDEN_CPU_OUT                : out   std_logic;
            RDATA_CPU_IN                : in    std_logic_vector(31 downto 0);
            WDATA_CPU_OUT               : out   std_logic_vector(31 downto 0);
            WREN_CPU_OUT                : out   std_logic;

            CLK_50M_OUT                 : out   std_logic;

            -- MII Interface
            GMII_COL_IN                 : in    std_logic_vector(0 downto 0);
            GMII_CRS_IN                 : in    std_logic_vector(0 downto 0);
            GMII_RXCLK_IN               : in    std_logic_vector(0 downto 0);
            GMII_RXDV_IN                : in    std_logic_vector(0 downto 0);
            GMII_RXER_IN                : in    std_logic_vector(0 downto 0);
            GMII_RXD_IN                 : in    std_logic_array8(0 downto 0);
            GMII_TXCLK_IN               : in    std_logic_vector(0 downto 0);
            GMII_TXEN_OUT               : out   std_logic_vector(0 downto 0);
            GMII_TXER_OUT               : out   std_logic_vector(0 downto 0);
            GMII_TXD_OUT                : out   std_logic_array8(0 downto 0);

            -- Ethernet Physical MDIO interface
            MDIO_ETHERNET_MDC           : out   std_logic;
            MDIO_ETHERNET_MDIO_IO       : inout std_logic;

            -- I2C IP interface
            --IIC
            IIC_SIT5356_SCL             : inout std_logic;                      -- TCXO
            IIC_SIT5356_SDA             : inout std_logic;
            AMC_SPI_CLK                 : out std_logic;
            AMC_SPI_CS                  : out std_logic;
            AMC_SPI_DI                  : out std_logic;
            AMC_SPI_DO                  : in  std_logic;
            SPI0_BRAM_ADDR              : in  STD_LOGIC_VECTOR(31 downto 0);
            SPI0_BRAM_CLK               : in  STD_LOGIC;
            SPI0_BRAM_DIN               : in  STD_LOGIC_VECTOR(31 downto 0);
            SPI0_BRAM_DOUT              : out STD_LOGIC_VECTOR(31 downto 0);
            SPI0_BRAM_EN                : in  STD_LOGIC;
            SPI0_BRAM_RST               : in  STD_LOGIC;
            SPI0_BRAM_WE                : in  STD_LOGIC_VECTOR(3 downto 0);
            FPGA_RFIC_SPI1_SCLK         : out std_logic;
            FPGA_RFIC_SPI1_CSB          : out std_logic;
            FPGA_RFIC_SPI1_SDIO         : out std_logic;
            FPGA_RFIC_SPI1_SDO          : in  std_logic;
            FPGA_RFIC_SPI2_SCLK         : out std_logic;
            FPGA_RFIC_SPI2_CSB          : out std_logic;
            FPGA_RFIC_SPI2_SDIO         : out std_logic;
            FPGA_RFIC_SPI2_SDO          : in  std_logic;

            --JESD IF
            JESD204B_M_AXI_0_araddr     : out STD_LOGIC_VECTOR( 31 downto 0 );
            JESD204B_M_AXI_0_arburst    : out STD_LOGIC_VECTOR( 1 downto 0 );
            JESD204B_M_AXI_0_arcache    : out STD_LOGIC_VECTOR( 3 downto 0 );
            JESD204B_M_AXI_0_arlen      : out STD_LOGIC_VECTOR( 7 downto 0 );
            JESD204B_M_AXI_0_arlock     : out STD_LOGIC_VECTOR( 0 to 0 );
            JESD204B_M_AXI_0_arprot     : out STD_LOGIC_VECTOR( 2 downto 0 );
            JESD204B_M_AXI_0_arqos      : out STD_LOGIC_VECTOR( 3 downto 0 );
            JESD204B_M_AXI_0_arready    : in STD_LOGIC;
            JESD204B_M_AXI_0_arregion   : out STD_LOGIC_VECTOR( 3 downto 0 );
            JESD204B_M_AXI_0_arsize     : out STD_LOGIC_VECTOR( 2 downto 0 );
            JESD204B_M_AXI_0_arvalid    : out STD_LOGIC;
            JESD204B_M_AXI_0_awaddr     : out STD_LOGIC_VECTOR( 31 downto 0 );
            JESD204B_M_AXI_0_awburst    : out STD_LOGIC_VECTOR( 1 downto 0 );
            JESD204B_M_AXI_0_awcache    : out STD_LOGIC_VECTOR( 3 downto 0 );
            JESD204B_M_AXI_0_awlen      : out STD_LOGIC_VECTOR( 7 downto 0 );
            JESD204B_M_AXI_0_awlock     : out STD_LOGIC_VECTOR( 0 to 0 );
            JESD204B_M_AXI_0_awprot     : out STD_LOGIC_VECTOR( 2 downto 0 );
            JESD204B_M_AXI_0_awqos      : out STD_LOGIC_VECTOR( 3 downto 0 );
            JESD204B_M_AXI_0_awready    : in STD_LOGIC;
            JESD204B_M_AXI_0_awregion   : out STD_LOGIC_VECTOR( 3 downto 0 );
            JESD204B_M_AXI_0_awsize     : out STD_LOGIC_VECTOR( 2 downto 0 );
            JESD204B_M_AXI_0_awvalid    : out STD_LOGIC;
            JESD204B_M_AXI_0_bready     : out STD_LOGIC;
            JESD204B_M_AXI_0_bresp      : in STD_LOGIC_VECTOR( 1 downto 0 );
            JESD204B_M_AXI_0_bvalid     : in STD_LOGIC;
            JESD204B_M_AXI_0_rdata      : in STD_LOGIC_VECTOR( 31 downto 0 );
            JESD204B_M_AXI_0_rlast      : in STD_LOGIC;
            JESD204B_M_AXI_0_rready     : out STD_LOGIC;
            JESD204B_M_AXI_0_rresp      : in STD_LOGIC_VECTOR( 1 downto 0 );
            JESD204B_M_AXI_0_rvalid     : in STD_LOGIC;
            JESD204B_M_AXI_0_wdata      : out STD_LOGIC_VECTOR( 31 downto 0 );
            JESD204B_M_AXI_0_wlast      : out STD_LOGIC;
            JESD204B_M_AXI_0_wready     : in STD_LOGIC;
            JESD204B_M_AXI_0_wstrb      : out STD_LOGIC_VECTOR( 3 downto 0 );
            JESD204B_M_AXI_0_wvalid     : out STD_LOGIC;

            --SYNCE & OCXO
            CLK_OCXO_BUFG_I             : in    std_logic;
            CLK_OCXO_BUFG_O             : out   std_logic;
            PTP_1PPS                    : out   std_logic;
            PTP_EVEN                    : out   std_logic;
            FRAME_SYNC                  : out   STD_LOGIC;
            SFN_NUM                     : out   STD_LOGIC_VECTOR ( 9 downto 0 );
            RESET_MMCM_250M             : in    std_logic;
            DACOUT                      : out   std_logic;
            CLK_245P76_0                : in    std_logic;

            CLK_TIMER                   : in STD_LOGIC;

            --eCPRI PHY
            --        ECPRI_GT_REF_CLK_0_N        : in    std_logic;
            --        ECPRI_GT_REF_CLK_0_P        : in    std_logic;
            --        ECPRI_GT_REF_CLK_1_N        : in    std_logic;
            --        ECPRI_GT_REF_CLK_1_P        : in    std_logic;
            gt_refclk_0                 : in STD_LOGIC;
            gt_refclk_1                 : in STD_LOGIC;

            ECPRI_GT_RX_N_0               : in    std_logic;
            ECPRI_GT_RX_P_0               : in    std_logic;
            ECPRI_GT_TX_N_0               : out   std_logic;
            ECPRI_GT_TX_P_0               : out   std_logic;

            ECPRI_GT_RX_N_1               : in    std_logic;
            ECPRI_GT_RX_P_1               : in    std_logic;
            ECPRI_GT_TX_N_1               : out   std_logic;
            ECPRI_GT_TX_P_1               : out   std_logic;

            --PHY status    --PHY status
            ECPRI_GT_RESET_RX_DONE_0      : out   std_logic;
            ECPRI_GT_RESET_TX_DONE_0      : out   std_logic;
            ECPRI_STAT_RX_BLOCK_LOCK_0    : out   std_logic;
            ECPRI_STAT_RX_LOCAL_FAULT_0   : out   std_logic;
            ECPRI_STAT_RX_RATE_10G_25GN_0 : out   std_logic;
            ECPRI_STAT_RX_REMOTE_FAULT_0  : out   std_logic;

            ECPRI_GT_RESET_RX_DONE_1      : out   std_logic;
            ECPRI_GT_RESET_TX_DONE_1      : out   std_logic;
            ECPRI_STAT_RX_BLOCK_LOCK_1    : out   std_logic;
            ECPRI_STAT_RX_LOCAL_FAULT_1   : out   std_logic;
            ECPRI_STAT_RX_RATE_10G_25GN_1 : out   std_logic;
            ECPRI_STAT_RX_REMOTE_FAULT_1  : out   std_logic;

            --PHY control
            ECPRI_GT_RXLPMEN_0            : in    std_logic;
            ECPRI_GT_TXDIFFCTRL_0         : in    std_logic_vector(4 downto 0);
            ECPRI_TXPRECURSOR_0           : in    std_logic_vector(4 downto 0);
            ECPRI_TXPOSTCUSOR_0           : in    std_logic_vector(4 downto 0);

            ECPRI_GT_RXLPMEN_1            : in    std_logic;
            ECPRI_GT_TXDIFFCTRL_1         : in    std_logic_vector(4 downto 0);
            ECPRI_TXPRECURSOR_1           : in    std_logic_vector(4 downto 0);
            ECPRI_TXPOSTCUSOR_1           : in    std_logic_vector(4 downto 0);

            MODE_CHANGE_25N_10H_0         : in    std_logic;                     -- Low : 25G, High : 10G
            MODE_CHANGE_25N_10H_1         : in    std_logic;                     -- Low : 25G, High : 10G

            RX_WDT_RESET_0                : in    std_logic;
            RX_WDT_RESET_1                : in    std_logic;
            MAC_SYS_RESET               : in    std_logic;
            DMA_BLOCK_RESET             : in    std_logic;

            -- ORAN IF
            CLK_MAC_RX_0                  : out   std_logic;
            CLK_MAC_RX_1                  : out   std_logic;

            MAC_RX_VALID_0                : out   std_logic_vector(1 downto 0);
            MAC_RX_LAST_0                 : out   std_logic_vector(1 downto 0);
            MAC_RX_KEEP_0                 : out   std_logic_array8(1 downto 0);
            MAC_RX_DATA_0                 : out   std_logic_array64(1 downto 0);

            MAC_RX_VALID_1                : out   std_logic_vector(1 downto 0);
            MAC_RX_LAST_1                 : out   std_logic_vector(1 downto 0);
            MAC_RX_KEEP_1                 : out   std_logic_array8(1 downto 0);
            MAC_RX_DATA_1                 : out   std_logic_array64(1 downto 0);

            MAC_TX_READY_0                : out   std_logic_vector(0 downto 0);
            MAC_TX_VALID_0                : in    std_logic_vector(0 downto 0);
            MAC_TX_LAST_0                 : in    std_logic_vector(0 downto 0);
            MAC_TX_KEEP_0                 : in    std_logic_array8(0 downto 0);
            MAC_TX_DATA_0                 : in    std_logic_array64(0 downto 0);

            MAC_TX_READY_1                : out   std_logic_vector(0 downto 0);
            MAC_TX_VALID_1                : in    std_logic_vector(0 downto 0);
            MAC_TX_LAST_1                 : in    std_logic_vector(0 downto 0);
            MAC_TX_KEEP_1                 : in    std_logic_array8(0 downto 0);
            MAC_TX_DATA_1                 : in    std_logic_array64(0 downto 0);

            -- SW Reset Monitoring for Signal Suspension
            EMIO_GPIO                   : out   STD_LOGIC_VECTOR (94 downto 0);--( 0 to 0 );
            EMIO_WDT1                   : out   STD_LOGIC;

            UART_RET_rxd : in STD_LOGIC;
            UART_RET_txd : out STD_LOGIC
        );
    end component;

    signal s_UART_RET_rxd : STD_LOGIC;
    signal s_UART_RET_txd : STD_LOGIC;

    component CPUIF_TOP
    port(
       RST_CPUIF                 : in  std_logic;
       CLK_CPUIF                 : in  std_logic;
                                 
       ADDR_FPGA_IN              : in  std_logic_vector(19 downto 0);
       WDATA_FPGA_IN             : in  std_logic_vector(31 downto 0);
       RDATA_FPGA_OUT            : out std_logic_vector(31 downto 0);
       CS_FPGA_IN                : in  std_logic;
       WREN_FPGA_IN              : in  std_logic;
       RDEN_FPGA_IN              : in  std_logic;
                                 
       HW_WATCHDOG_CLR_OUT       : out std_logic;  -- HW Watchdog Clear, Active High.
    
       ADDR_SYSCTRL_OUT          : out std_logic_vector(15 downto 0);
       WDATA_SYSCTRL_OUT         : out std_logic_vector(31 downto 0);
       RDATA_SYSCTRL_IN          : in  std_logic_vector(31 downto 0);
       WREN_SYSCTRL_OUT          : out std_logic;
       RDEN_SYSCTRL_OUT          : out std_logic;
       RDVAL_SYSCTRL_IN          : in  std_logic;
    
       --ECPRIPHY
       ADDR_CPRIPHY_OUT          : out std_logic_vector(15 downto 0);
       WDATA_CPRIPHY_OUT         : out std_logic_vector(31 downto 0);
       RDATA_CPRIPHY_IN          : in  std_logic_vector(31 downto 0);
       WREN_CPRIPHY_OUT          : out std_logic;
       RDEN_CPRIPHY_OUT          : out std_logic;
       RDVAL_CPRIPHY_IN          : in  std_logic;
    
       --ORAN                             
       ADDR_CPRI_OUT             : out std_logic_vector(15 downto 0);
       WDATA_CPRI_OUT            : out std_logic_vector(31 downto 0);
       RDATA_CPRI_IN             : in  std_logic_vector(31 downto 0);
       WREN_CPRI_OUT             : out std_logic;
       RDEN_CPRI_OUT             : out std_logic;
       RDVAL_CPRI_IN             : in  std_logic;
     
       ADDR_LPHY_TOP_OUT         : out std_logic_vector(19 downto 0);
       WDATA_LPHY_TOP_OUT        : out std_logic_vector(31 downto 0);
       RDATA_LPHY_TOP_IN         : in  std_logic_vector(31 downto 0);
       WREN_LPHY_TOP_OUT         : out std_logic;
       RDEN_LPHY_TOP_OUT         : out std_logic;
       RDVAL_LPHY_TOP_IN         : in  std_logic;
                                    
       ADDR_BBCTRL_OUT           : out std_logic_vector(15 downto 0);
       WDATA_BBCTRL_OUT          : out std_logic_vector(31 downto 0);
       RDATA_BBCTRL_IN           : in  std_logic_vector(31 downto 0);
       WREN_BBCTRL_OUT           : out std_logic;
       RDEN_BBCTRL_OUT           : out std_logic;
       RDVAL_BBCTRL_IN           : in  std_logic;
                                    
       ADDR_DSP_OUT              : out std_logic_vector(15 downto 0);
       WDATA_DSP_OUT             : out std_logic_vector(31 downto 0);
       RDATA_DSP_IN              : in  std_logic_vector(31 downto 0);
       WREN_DSP_OUT              : out std_logic;
       RDEN_DSP_OUT              : out std_logic;
       RDVAL_DSP_IN              : in  std_logic;
                                    
       ADDR_DCIF_OUT             : out std_logic_vector(15 downto 0);
       WDATA_DCIF_OUT            : out std_logic_vector(31 downto 0);
       RDATA_DCIF_IN             : in  std_logic_vector(31 downto 0);
       WREN_DCIF_OUT             : out std_logic;
       RDEN_DCIF_OUT             : out std_logic;
       RDVAL_DCIF_IN             : in  std_logic;
                                    
       ADDR_MISC_OUT             : out std_logic_vector(15 downto 0);
       WDATA_MISC_OUT            : out std_logic_vector(31 downto 0);
       RDATA_MISC_IN             : in  std_logic_vector(31 downto 0);
       WREN_MISC_OUT             : out std_logic;
       RDEN_MISC_OUT             : out std_logic;
       RDVAL_MISC_IN             : in  std_logic;
                                    
       ADDR_SBIF_OUT             : out std_logic_vector(15 downto 0);
       WDATA_SBIF_OUT            : out std_logic_vector(31 downto 0);
       RDATA_SBIF_IN             : in  std_logic_vector(31 downto 0);
       WREN_SBIF_OUT             : out std_logic;
       RDEN_SBIF_OUT             : out std_logic;
       RDVAL_SBIF_IN             : in  std_logic;
       
       ADDR_PIM_SBIF_OUT         : out std_logic_vector(15 downto 0);
       WDATA_PIM_SBIF_OUT        : out std_logic_vector(31 downto 0);
       RDATA_PIM_SBIF_IN         : in  std_logic_vector(31 downto 0);
       WREN_PIM_SBIF_OUT         : out std_logic;
       RDEN_PIM_SBIF_OUT         : out std_logic;
       RDVAL_PIM_SBIF_IN         : in  std_logic;
                                    
       ADDR_SBIFPHY_OUT          : out std_logic_vector(15 downto 0);
       WDATA_SBIFPHY_OUT         : out std_logic_vector(31 downto 0);
       RDATA_SBIFPHY_IN          : in  std_logic_vector(31 downto 0);
       WREN_SBIFPHY_OUT          : out std_logic;
       RDEN_SBIFPHY_OUT          : out std_logic;
       RDVAL_SBIFPHY_IN          : in  std_logic;
       
       ADDR_PIM_SBIFPHY_OUT      : out std_logic_vector(15 downto 0);
       WDATA_PIM_SBIFPHY_OUT     : out std_logic_vector(31 downto 0);
       RDATA_PIM_SBIFPHY_IN      : in  std_logic_vector(31 downto 0);
       WREN_PIM_SBIFPHY_OUT      : out std_logic;
       RDEN_PIM_SBIFPHY_OUT      : out std_logic;
       RDVAL_PIM_SBIFPHY_IN      : in  std_logic;
                                    
       ADDR_ANNEX_OUT            : out std_logic_vector(15 downto 0);
       WDATA_ANNEX_OUT           : out std_logic_vector(31 downto 0);
       RDATA_ANNEX_IN            : in  std_logic_vector(31 downto 0);
       WREN_ANNEX_OUT            : out std_logic;
       RDEN_ANNEX_OUT            : out std_logic;
       RDVAL_ANNEX_IN            : in  std_logic;
                                    
       ADDR_DPD_OUT              : out std_logic_vector(15 downto 0);
       WDATA_DPD_OUT             : out std_logic_vector(31 downto 0);
       RDATA_DPD_IN              : in  std_logic_vector(31 downto 0);
       WREN_DPD_OUT              : out std_logic;
       RDEN_DPD_OUT              : out std_logic;
       RDVAL_DPD_IN              : in  std_logic;
                                    
       DBG_SIG_OUT                : out std_logic_vector(31 downto 0)
    );
    end component;
    
    -- RF4440d oran 
--    component O_RAN_TOP 
--        generic (
--            CELL_NUM_DL                 : natural :=  2;                            
--            CELL_NUM_UL                 : natural :=  2; 
--            PATH_NUM                    : natural :=  4                             
--        );
--        port (
--    --------------------------------------------------------------------------------
--    -- Clock & Reset
--    --------------------------------------------------------------------------------
    
--            CLK_CPUIF                   : in  std_logic;
--            RST_CPUIF                   : in  std_logic;
    
--            ARESET_RX                   : in  std_logic_vector(0 downto 0);
--            ARESET_TX                   : in  std_logic_vector(0 downto 0);
    
--            CLK_MAC_RX                  : in  std_logic;                            -- 156.25/390.625-MHz
--            CLK_MAC_TX                  : in  std_logic;                            -- 156.25/390.625-MHz
--            CLK_BUS                     : in  std_logic;                            -- 245.76-MHz
    
--    --------------------------------------------------------------------------------
--    -- Sync
--    --------------------------------------------------------------------------------
    
--            FRAME_SYNC                  : in  std_logic;                            -- should be aligned with 1PPS
--            BFN_NUM_IN                  : in  std_logic_vector(11 downto 0); 
    
--            DL_CC_SYNC_ADVANCE          : in  std_logic_vector(CELL_NUM_DL*22-1 downto 0);
--            UL_CC_SYNC_RETARD           : in  std_logic_vector(CELL_NUM_UL*22-1 downto 0);
--            N_TA_OFFSET                 : in  std_logic_vector(CELL_NUM_DL*16-1 downto 0);
    
--    --------------------------------------------------------------------------------
--    -- CPU interface
--    --------------------------------------------------------------------------------
    
--            ADDR_CPUIF_IN               : in  std_logic_vector(15 downto 0);
--            WDATA_CPUIF_IN              : in  std_logic_vector(31 downto 0);
--            RDATA_CPUIF_OUT             : out std_logic_vector(31 downto 0);
--            WREN_CPUIF_IN               : in  std_logic;
--            RDEN_CPUIF_IN               : in  std_logic;
--            RDVAL_CPUIF_OUT             : out std_logic;
    
--    --------------------------------------------------------------------------------
--    -- MAC#0
--    --------------------------------------------------------------------------------
    
--            MAC0_RX_VALID               : in  std_logic;
--            MAC0_RX_LAST                : in  std_logic;
--            MAC0_RX_KEEP                : in  std_logic_vector(7 downto 0);
--            MAC0_RX_DATA                : in  std_logic_vector(63 downto 0);
    
--            MAC0_TX_READY               : in  std_logic;
--            MAC0_TX_VALID               : out std_logic;
--            MAC0_TX_LAST                : out std_logic;
--            MAC0_TX_KEEP                : out std_logic_vector(7 downto 0);
--            MAC0_TX_DATA                : out std_logic_vector(63 downto 0);
    
--    --------------------------------------------------------------------------------
--    -- External port (Aurora)
--    --------------------------------------------------------------------------------
    
--            EXT_RU_RX_TVALID            : out std_logic;
--            EXT_RU_RX_TLAST             : out std_logic;
--            EXT_RU_RX_TKEEP             : out std_logic_vector(7 downto 0);
--            EXT_RU_RX_TDATA             : out std_logic_vector(63 downto 0);
    
--            EXT_RU_TX_TREADY            : out std_logic;
--            EXT_RU_TX_TVALID            : in  std_logic;
--            EXT_RU_TX_TLAST             : in  std_logic;
--            EXT_RU_TX_TKEEP             : in  std_logic_vector(7 downto 0);
--            EXT_RU_TX_TDATA             : in  std_logic_vector(63 downto 0);
    
--    --------------------------------------------------------------------------------
--    -- DLFE
--    --------------------------------------------------------------------------------
    
--            DLFE_CC_SYSTEM_MODE         : in  std_logic_vector(CELL_NUM_DL*1-1 downto 0);  
--            DLFE_CC_K0                  : in  std_logic_vector(CELL_NUM_DL*12-1 downto 0);
--            DLFE_CC_nRE                 : in  std_logic_vector(CELL_NUM_DL*12-1 downto 0);  
--            DLFE_CC_nFFT                : in  std_logic_vector(CELL_NUM_DL*2-1 downto 0);                                    
--            DLFE_CC_BFN_NUM_OUT         : out std_logic_vector(CELL_NUM_DL*12-1 downto 0);
--            DLFE_CC_FRAME_SYNC          : out std_logic_vector(CELL_NUM_DL*1-1 downto 0);
--            DLFE_CC_FRAME_INDEX         : out std_logic_vector(CELL_NUM_DL*8-1 downto 0);
--            DLFE_CC_FRAME_STRUCTURE     : out std_logic_vector(CELL_NUM_DL*8-1 downto 0);
--            DLFE_CC_SYSTEM_MODE_DSS     : out std_logic_vector(CELL_NUM_DL*PATH_NUM*1-1 downto 0); 
--            DLFE_CC_VALID               : out std_logic_vector(CELL_NUM_DL*PATH_NUM*1-1 downto 0);                       
--            DLFE_CC_RE_MASK             : out std_logic_vector(CELL_NUM_DL*PATH_NUM*1-1 downto 0);
--            DLFE_CC_DATA                : out std_logic_vector(CELL_NUM_DL*PATH_NUM*32-1 downto 0); 
    
--    --------------------------------------------------------------------------------
--    -- ULFE
--    --------------------------------------------------------------------------------
    
--            ULFE_CC_FRAME_ID            : in  std_logic_vector(CELL_NUM_UL*8-1 downto 0);  
--            ULFE_CC_SUBFRAME_ID         : in  std_logic_vector(CELL_NUM_UL*4-1 downto 0);  
--            ULFE_CC_SLOT_ID             : in  std_logic_vector(CELL_NUM_UL*6-1 downto 0);  
--            ULFE_CC_SYMBOL_ID           : in  std_logic_vector(CELL_NUM_UL*6-1 downto 0);  
--            ULFE_CC_START_RE            : in  std_logic_vector(CELL_NUM_UL*PATH_NUM*16-1 downto 0); 
--            ULFE_CC_VALID               : in  std_logic_vector(CELL_NUM_UL*PATH_NUM*1-1 downto 0);  
--            ULFE_CC_START               : in  std_logic_vector(CELL_NUM_UL*PATH_NUM*1-1 downto 0);  
--            ULFE_CC_LAST                : in  std_logic_vector(CELL_NUM_UL*PATH_NUM*1-1 downto 0);  
--            ULFE_CC_DATA                : in  std_logic_vector(CELL_NUM_UL*PATH_NUM*32-1 downto 0);
    
--    --------------------------------------------------------------------------------
--    -- RAFE
--    --------------------------------------------------------------------------------
    
--            RAFE_CC_FRAME_ID            : in  std_logic_vector(CELL_NUM_UL*8-1 downto 0);
--            RAFE_CC_SUBFRAME_ID         : in  std_logic_vector(CELL_NUM_UL*4-1 downto 0);
--            RAFE_CC_SLOT_ID             : in  std_logic_vector(CELL_NUM_UL*6-1 downto 0);
--            RAFE_CC_SYMBOL_ID           : in  std_logic_vector(CELL_NUM_UL*6-1 downto 0);
--            RAFE_CC_START_RE            : in  std_logic_vector(CELL_NUM_UL*PATH_NUM*16-1 downto 0);
--            RAFE_CC_VALID               : in  std_logic_vector(CELL_NUM_UL*PATH_NUM*1-1 downto 0); 
--            RAFE_CC_START               : in  std_logic_vector(CELL_NUM_UL*PATH_NUM*1-1 downto 0); 
--            RAFE_CC_LAST                : in  std_logic_vector(CELL_NUM_UL*PATH_NUM*1-1 downto 0); 
--            RAFE_CC_DATA                : in  std_logic_vector(CELL_NUM_UL*PATH_NUM*32-1 downto 0);
                                                                            
--            RAFE_CC_FRAME_SYNC          : out std_logic_vector(CELL_NUM_UL*1-1 downto 0);                    
--            RAFE_CC_FILTER_INDEX        : out std_logic_vector(CELL_NUM_UL*PATH_NUM*4-1 downto 0); 
--            RAFE_CC_TIME_OFFSET         : out std_logic_vector(CELL_NUM_UL*PATH_NUM*16-1 downto 0); 
--            RAFE_CC_FRAME_STRUCTURE     : out std_logic_vector(CELL_NUM_UL*PATH_NUM*8-1 downto 0); 
--            RAFE_CC_CPLENGTH            : out std_logic_vector(CELL_NUM_UL*PATH_NUM*16-1 downto 0); 
--            RAFE_CC_FREQ_OFFSET         : out std_logic_vector(CELL_NUM_UL*PATH_NUM*24-1 downto 0);
--            RAFE_CC_START_PRBC          : out std_logic_vector(CELL_NUM_UL*PATH_NUM*10-1 downto 0);
--            RAFE_CC_NUM_PSYMBOL         : out std_logic_vector(CELL_NUM_UL*PATH_NUM*4-1 downto 0);
--            RAFE_CC_NUM_PRBC            : out std_logic_vector(CELL_NUM_UL*PATH_NUM*8-1 downto 0);
--            RAFE_CC_NUM_RO              : out std_logic_vector(CELL_NUM_UL*PATH_NUM*3-1 downto 0);
    
--    --------------------------------------------------------------------------------
--    -- eMTC PRACH
--    --------------------------------------------------------------------------------
    
--            eMTC_CC_FRAME_ID            : in  std_logic_vector(CELL_NUM_eMTC*8-1 downto 0);
--            eMTC_CC_SUBFRAME_ID         : in  std_logic_vector(CELL_NUM_eMTC*4-1 downto 0);
--            eMTC_CC_SLOT_ID             : in  std_logic_vector(CELL_NUM_eMTC*6-1 downto 0);
--            eMTC_CC_SYMBOL_ID           : in  std_logic_vector(CELL_NUM_eMTC*6-1 downto 0);
--            eMTC_CC_START_RE            : in  std_logic_vector(CELL_NUM_eMTC*PATH_NUM*16-1 downto 0);
--            eMTC_CC_VALID               : in  std_logic_vector(CELL_NUM_eMTC*PATH_NUM*1-1 downto 0); 
--            eMTC_CC_START               : in  std_logic_vector(CELL_NUM_eMTC*PATH_NUM*1-1 downto 0); 
--            eMTC_CC_LAST                : in  std_logic_vector(CELL_NUM_eMTC*PATH_NUM*1-1 downto 0); 
--            eMTC_CC_DATA                : in  std_logic_vector(CELL_NUM_eMTC*PATH_NUM*32-1 downto 0);
    
--            eMTC_CC_FRAME_SYNC          : out std_logic_vector(CELL_NUM_eMTC*1-1 downto 0);                    
--            eMTC_CC_FILTER_INDEX        : out std_logic_vector(CELL_NUM_eMTC*PATH_NUM*4-1 downto 0); 
--            eMTC_CC_TIME_OFFSET         : out std_logic_vector(CELL_NUM_eMTC*PATH_NUM*16-1 downto 0); 
--            eMTC_CC_FRAME_STRUCTURE     : out std_logic_vector(CELL_NUM_eMTC*PATH_NUM*8-1 downto 0); 
--            eMTC_CC_CPLENGTH            : out std_logic_vector(CELL_NUM_eMTC*PATH_NUM*16-1 downto 0); 
--            eMTC_CC_FREQ_OFFSET         : out std_logic_vector(CELL_NUM_eMTC*PATH_NUM*24-1 downto 0); 
--            eMTC_CC_START_PRBC          : out std_logic_vector(CELL_NUM_eMTC*PATH_NUM*10-1 downto 0); 
--            eMTC_CC_NUM_PSYMBOL         : out std_logic_vector(CELL_NUM_eMTC*PATH_NUM*4-1 downto 0); 
--            eMTC_CC_NUM_PRBC            : out std_logic_vector(CELL_NUM_eMTC*PATH_NUM*8-1 downto 0);
--            eMTC_CC_NUM_RO              : out std_logic_vector(CELL_NUM_eMTC*PATH_NUM*3-1 downto 0); 
    
--    --------------------------------------------------------------------------------
--    -- NB-IoT
--    --------------------------------------------------------------------------------
    
--            NBIOT_CC_FRAME_ID           : in  std_logic_vector(CELL_NUM_NBIOT*8-1 downto 0);
--            NBIOT_CC_SUBFRAME_ID        : in  std_logic_vector(CELL_NUM_NBIOT*4-1 downto 0);
--            NBIOT_CC_SLOT_ID            : in  std_logic_vector(CELL_NUM_NBIOT*6-1 downto 0);
--            NBIOT_CC_SYMBOL_ID          : in  std_logic_vector(CELL_NUM_NBIOT*6-1 downto 0);
--            NBIOT_CC_START_RE           : in  std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*16-1 downto 0);
--            NBIOT_CC_VALID              : in  std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*1-1 downto 0); 
--            NBIOT_CC_START              : in  std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*1-1 downto 0); 
--            NBIOT_CC_LAST               : in  std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*1-1 downto 0); 
--            NBIOT_CC_DATA               : in  std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*32-1 downto 0);
    
--            NBIOT_CC_FRAME_SYNC         : out std_logic_vector(CELL_NUM_NBIOT*1-1 downto 0);                    
--            NBIOT_CC_FILTER_INDEX       : out std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*4-1 downto 0); 
--            NBIOT_CC_TIME_OFFSET        : out std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*16-1 downto 0); 
--            NBIOT_CC_FRAME_STRUCTURE    : out std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*8-1 downto 0); 
--            NBIOT_CC_CPLENGTH           : out std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*16-1 downto 0); 
--            NBIOT_CC_FREQ_OFFSET        : out std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*24-1 downto 0); 
--            NBIOT_CC_START_PRBC         : out std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*10-1 downto 0); 
--            NBIOT_CC_NUM_PSYMBOL        : out std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*4-1 downto 0); 
--            NBIOT_CC_NUM_PRBC           : out std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*8-1 downto 0);
--            NBIOT_CC_NUM_RO             : out std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*3-1 downto 0) 
--        );
--    end component;

    -- KDDI B oran
    
    component ORAN_TOP is
    generic (
        CELL_NUM_eMTC               : natural :=  1
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK_CPUIF                   : in  std_logic;                            -- 100MHz
        RST_CPUIF                   : in  std_logic;

        ARESET_RX                   : in  std_logic_vector(3 downto 0);         -- RX(DL) Reset per Cell
        ARESET_TX                   : in  std_logic_vector(3 downto 0);         -- TX(UL) Reset per Cell

        CLK_MAC_RX                  : in  std_logic;                            -- 156.25/390.625-MHz
        CLK_MAC_TX                  : in  std_logic;                            -- 156.25/390.625-MHz
        CLK_BUS                     : in  std_logic;                            -- 245.76-MHz

--------------------------------------------------------------------------------
-- Sync
--------------------------------------------------------------------------------

        TICK_1PPS                   : in  std_logic;                            -- 8-clocks@CLK_BUS
        FRAME_SYNC                  : in  std_logic;                            -- should be aligned with 1PPS
        FRAME_NUM                   : in  std_logic_vector(11 downto 0);

--        SBIF_CHIPSYNC               : in  std_logic;
--        SBIF_DATA                   : out std_logic_vector(15 downto 0);

        DL_CC0_SYNC_ADVANCE         : in  std_logic_vector(21 downto 0);
        UL_CC0_SYNC_RETARD          : in  std_logic_vector(21 downto 0);
        DL_CC1_SYNC_ADVANCE         : in  std_logic_vector(21 downto 0);   -- MJANG added
        UL_CC1_SYNC_RETARD          : in  std_logic_vector(21 downto 0);   -- MJANG added
--        DL_CC2_SYNC_ADVANCE         : in  std_logic_vector(21 downto 0);   -- MJANG added
--        UL_CC2_SYNC_RETARD          : in  std_logic_vector(21 downto 0);   -- MJANG added
--        DL_CC3_SYNC_ADVANCE         : in  std_logic_vector(21 downto 0);   -- MJANG added
--        UL_CC3_SYNC_RETARD          : in  std_logic_vector(21 downto 0);   -- MJANG added

        TDD_CC0_SYMBOL_SYNC         : out std_logic;                       -- MJANG modified
        TDD_CC0_SYMBOL_INDEX        : out std_logic_vector(3 downto 0);    -- MJANG modified
        TDD_CC0_DL_EN               : out std_logic_vector(1 downto 0);    -- MJANG modified
        TDD_CC0_UL_EN               : out std_logic_vector(1 downto 0);    -- MJANG modified

        TDD_CC1_SYMBOL_SYNC         : out std_logic;                       -- MJANG added
        TDD_CC1_SYMBOL_INDEX        : out std_logic_vector(3 downto 0);    -- MJANG added
        TDD_CC1_DL_EN               : out std_logic_vector(1 downto 0);    -- MJANG added
        TDD_CC1_UL_EN               : out std_logic_vector(1 downto 0);    -- MJANG added

--        TDD_CC2_SYMBOL_SYNC         : out std_logic;                       -- MJANG added
--        TDD_CC2_SYMBOL_INDEX        : out std_logic_vector(3 downto 0);    -- MJANG added
--        TDD_CC2_DL_EN               : out std_logic_vector(1 downto 0);    -- MJANG added
--        TDD_CC2_UL_EN               : out std_logic_vector(1 downto 0);    -- MJANG added

--        TDD_CC3_SYMBOL_SYNC         : out std_logic;                       -- MJANG added
--        TDD_CC3_SYMBOL_INDEX        : out std_logic_vector(3 downto 0);    -- MJANG added
--        TDD_CC3_DL_EN               : out std_logic_vector(1 downto 0);    -- MJANG added
--        TDD_CC3_UL_EN               : out std_logic_vector(1 downto 0);    -- MJANG added

        N_TA_OFFSET_CC0             : in  std_logic_vector(15 downto 0);
        N_TA_OFFSET_CC1             : in  std_logic_vector(15 downto 0);
--        N_TA_OFFSET_CC2             : in  std_logic_vector(15 downto 0);
--        N_TA_OFFSET_CC3             : in  std_logic_vector(15 downto 0);

--------------------------------------------------------------------------------
-- CPU interface
--------------------------------------------------------------------------------

        ADDR_CPUIF_IN               : in  std_logic_vector(15 downto 0);
        WDATA_CPUIF_IN              : in  std_logic_vector(31 downto 0);
        RDATA_CPUIF_OUT             : out std_logic_vector(31 downto 0);
        WREN_CPUIF_IN               : in  std_logic;
        RDEN_CPUIF_IN               : in  std_logic;
        RDVAL_CPUIF_OUT             : out std_logic;

--------------------------------------------------------------------------------
-- MAC#0
--------------------------------------------------------------------------------

        MAC0_RX_VALID               : in  std_logic;
        MAC0_RX_LAST                : in  std_logic;
        MAC0_RX_KEEP                : in  std_logic_vector(7 downto 0);
        MAC0_RX_DATA                : in  std_logic_vector(63 downto 0);

        MAC0_TX_READY               : in  std_logic;
        MAC0_TX_VALID               : out std_logic;
        MAC0_TX_LAST                : out std_logic;
        MAC0_TX_KEEP                : out std_logic_vector(7 downto 0);
        MAC0_TX_DATA                : out std_logic_vector(63 downto 0);

--------------------------------------------------------------------------------
-- MAC#1
--------------------------------------------------------------------------------

        MAC1_RX_VALID               : in  std_logic;
        MAC1_RX_LAST                : in  std_logic;
        MAC1_RX_KEEP                : in  std_logic_vector(7 downto 0);
        MAC1_RX_DATA                : in  std_logic_vector(63 downto 0);

        MAC1_TX_READY               : in  std_logic;
        MAC1_TX_VALID               : out std_logic;
        MAC1_TX_LAST                : out std_logic;
        MAC1_TX_KEEP                : out std_logic_vector(7 downto 0);
        MAC1_TX_DATA                : out std_logic_vector(63 downto 0);

--------------------------------------------------------------------------------
-- DLFE
--------------------------------------------------------------------------------

        -- MJANG Modified
        DLFE_CC0_SYSTEM_MODE        : in  std_logic;
        DLFE_CC0_K0                 : in  std_logic_vector(11 downto 0);
        DLFE_CC0_nRE                : in  std_logic_vector(11 downto 0);
        DLFE_CC0_nFFT               : in  std_logic_vector(1 downto 0);
        DLFE_CC0_FRAME_SYNC         : out std_logic;
        DLFE_CC0_FRAME_INDEX        : out std_logic_vector(7 downto 0);
        DLFE_CC0_VALID              : out std_logic_vector(DL_NUM_ANT-1 downto 0);
        DLFE_CC0_RE_MASK            : out std_logic_vector(DL_NUM_ANT-1 downto 0);
        DLFE_CC0_DATA               : out std_logic_vector(DL_NUM_ANT*32-1 downto 0);

        -- MJANG Added
        DLFE_CC1_SYSTEM_MODE        : in  std_logic;
        DLFE_CC1_K0                 : in  std_logic_vector(11 downto 0);
        DLFE_CC1_nRE                : in  std_logic_vector(11 downto 0);
        DLFE_CC1_nFFT               : in  std_logic_vector(1 downto 0);
        DLFE_CC1_FRAME_SYNC         : out std_logic;
        DLFE_CC1_FRAME_INDEX        : out std_logic_vector(7 downto 0);
        DLFE_CC1_VALID              : out std_logic_vector(DL_NUM_ANT-1 downto 0);
        DLFE_CC1_RE_MASK            : out std_logic_vector(DL_NUM_ANT-1 downto 0);
        DLFE_CC1_DATA               : out std_logic_vector(DL_NUM_ANT*32-1 downto 0);

--        -- MJANG Added
--        DLFE_CC2_SYSTEM_MODE        : in  std_logic;
--        DLFE_CC2_K0                 : in  std_logic_vector(11 downto 0);
--        DLFE_CC2_nRE                : in  std_logic_vector(11 downto 0);
--        DLFE_CC2_nFFT               : in  std_logic_vector(1 downto 0);
--        DLFE_CC2_FRAME_SYNC         : out std_logic;
--        DLFE_CC2_FRAME_INDEX        : out std_logic_vector(7 downto 0);
--        DLFE_CC2_VALID              : out std_logic_vector(2-1 downto 0);
--        DLFE_CC2_RE_MASK            : out std_logic_vector(2-1 downto 0);
--        DLFE_CC2_DATA               : out std_logic_vector(2*32-1 downto 0);

--        -- MJANG Added
--        DLFE_CC3_SYSTEM_MODE        : in  std_logic;
--        DLFE_CC3_K0                 : in  std_logic_vector(11 downto 0);
--        DLFE_CC3_nRE                : in  std_logic_vector(11 downto 0);
--        DLFE_CC3_nFFT               : in  std_logic_vector(1 downto 0);
--        DLFE_CC3_FRAME_SYNC         : out std_logic;
--        DLFE_CC3_FRAME_INDEX        : out std_logic_vector(7 downto 0);
--        DLFE_CC3_VALID              : out std_logic_vector(2-1 downto 0);
--        DLFE_CC3_RE_MASK            : out std_logic_vector(2-1 downto 0);
--        DLFE_CC3_DATA               : out std_logic_vector(2*32-1 downto 0);

--------------------------------------------------------------------------------
-- ULFE
--------------------------------------------------------------------------------

        -- MJANG Modified
        ULFE_CC0_FRAME_ID           : in  std_logic_vector(7 downto 0);
        ULFE_CC0_SUBFRAME_ID        : in  std_logic_vector(3 downto 0);
        ULFE_CC0_SLOT_ID            : in  std_logic_vector(5 downto 0);
        ULFE_CC0_SYMBOL_ID          : in  std_logic_vector(5 downto 0);
        ULFE_CC0_START_RE           : in  std_logic_vector(UL_NUM_ANT*16-1 downto 0);
        ULFE_CC0_VALID              : in  std_logic_vector(UL_NUM_ANT-1 downto 0);
        ULFE_CC0_START              : in  std_logic_vector(UL_NUM_ANT-1 downto 0);
        ULFE_CC0_LAST               : in  std_logic_vector(UL_NUM_ANT-1 downto 0);
        ULFE_CC0_DATA               : in  std_logic_vector(UL_NUM_ANT*32-1 downto 0);

        -- MJANG Added
        ULFE_CC1_FRAME_ID           : in  std_logic_vector(7 downto 0);
        ULFE_CC1_SUBFRAME_ID        : in  std_logic_vector(3 downto 0);
        ULFE_CC1_SLOT_ID            : in  std_logic_vector(5 downto 0);
        ULFE_CC1_SYMBOL_ID          : in  std_logic_vector(5 downto 0);
        ULFE_CC1_START_RE           : in  std_logic_vector(UL_NUM_ANT*16-1 downto 0);
        ULFE_CC1_VALID              : in  std_logic_vector(UL_NUM_ANT-1 downto 0);
        ULFE_CC1_START              : in  std_logic_vector(UL_NUM_ANT-1 downto 0);
        ULFE_CC1_LAST               : in  std_logic_vector(UL_NUM_ANT-1 downto 0);
        ULFE_CC1_DATA               : in  std_logic_vector(UL_NUM_ANT*32-1 downto 0);

--        -- MJANG Added
--        ULFE_CC2_FRAME_ID           : in  std_logic_vector(7 downto 0);
--        ULFE_CC2_SUBFRAME_ID        : in  std_logic_vector(3 downto 0);
--        ULFE_CC2_SLOT_ID            : in  std_logic_vector(5 downto 0);
--        ULFE_CC2_SYMBOL_ID          : in  std_logic_vector(5 downto 0);
--        ULFE_CC2_START_RE           : in  std_logic_vector(2*16-1 downto 0);
--        ULFE_CC2_VALID              : in  std_logic_vector(2-1 downto 0);
--        ULFE_CC2_START              : in  std_logic_vector(2-1 downto 0);
--        ULFE_CC2_LAST               : in  std_logic_vector(2-1 downto 0);
--        ULFE_CC2_DATA               : in  std_logic_vector(2*32-1 downto 0);

--        -- MJANG Added
--        ULFE_CC3_FRAME_ID           : in  std_logic_vector(7 downto 0);
--        ULFE_CC3_SUBFRAME_ID        : in  std_logic_vector(3 downto 0);
--        ULFE_CC3_SLOT_ID            : in  std_logic_vector(5 downto 0);
--        ULFE_CC3_SYMBOL_ID          : in  std_logic_vector(5 downto 0);
--        ULFE_CC3_START_RE           : in  std_logic_vector(2*16-1 downto 0);
--        ULFE_CC3_VALID              : in  std_logic_vector(2-1 downto 0);
--        ULFE_CC3_START              : in  std_logic_vector(2-1 downto 0);
--        ULFE_CC3_LAST               : in  std_logic_vector(2-1 downto 0);
--        ULFE_CC3_DATA               : in  std_logic_vector(2*32-1 downto 0);

--------------------------------------------------------------------------------
-- RAFE
--------------------------------------------------------------------------------

        -- MJANG Modified
        RAFE_CC0_FRAMES_SYNC        : out std_logic;
        RAFE_CC0_FILTER_INDEX       : out std_logic_vector(UL_NUM_ANT*4-1 downto 0);
        RAFE_CC0_TIME_OFFSET        : out std_logic_vector(UL_NUM_ANT*16-1 downto 0);
        RAFE_CC0_FRAME_STRUCTURE    : out std_logic_vector(UL_NUM_ANT*8-1 downto 0);
        RAFE_CC0_CPLENGTH           : out std_logic_vector(UL_NUM_ANT*16-1 downto 0);
        RAFE_CC0_FREQ_OFFSET        : out std_logic_vector(UL_NUM_ANT*24-1 downto 0);
        RAFE_CC0_START_PRBC         : out std_logic_vector(UL_NUM_ANT*10-1 downto 0);
        RAFE_CC0_NUM_PRBC           : out std_logic_vector(UL_NUM_ANT*8-1 downto 0);
        RAFE_CC0_NUM_PSYMBOL        : out std_logic_vector(UL_NUM_ANT*4-1 downto 0);
        RAFE_CC0_NUM_RO             : out std_logic_vector(UL_NUM_ANT*3-1 downto 0);
        RAFE_CC0_FRAME_ID           : in  std_logic_vector(7 downto 0);
        RAFE_CC0_SUBFRAME_ID        : in  std_logic_vector(3 downto 0);
        RAFE_CC0_SLOT_ID            : in  std_logic_vector(5 downto 0);
        RAFE_CC0_SYMBOL_ID          : in  std_logic_vector(5 downto 0);
        RAFE_CC0_START_RE           : in  std_logic_vector(UL_NUM_ANT*16-1 downto 0);
        RAFE_CC0_VALID              : in  std_logic_vector(UL_NUM_ANT-1 downto 0);
        RAFE_CC0_START              : in  std_logic_vector(UL_NUM_ANT-1 downto 0);
        RAFE_CC0_LAST               : in  std_logic_vector(UL_NUM_ANT-1 downto 0);
        RAFE_CC0_DATA               : in  std_logic_vector(UL_NUM_ANT*32-1 downto 0);

        -- MJANG Added
        RAFE_CC1_FRAMES_SYNC        : out std_logic;
        RAFE_CC1_FILTER_INDEX       : out std_logic_vector(UL_NUM_ANT*4-1 downto 0);
        RAFE_CC1_TIME_OFFSET        : out std_logic_vector(UL_NUM_ANT*16-1 downto 0);
        RAFE_CC1_FRAME_STRUCTURE    : out std_logic_vector(UL_NUM_ANT*8-1 downto 0);
        RAFE_CC1_CPLENGTH           : out std_logic_vector(UL_NUM_ANT*16-1 downto 0);
        RAFE_CC1_FREQ_OFFSET        : out std_logic_vector(UL_NUM_ANT*24-1 downto 0);
        RAFE_CC1_START_PRBC         : out std_logic_vector(UL_NUM_ANT*10-1 downto 0);
        RAFE_CC1_NUM_PRBC           : out std_logic_vector(UL_NUM_ANT*8-1 downto 0);
        RAFE_CC1_NUM_PSYMBOL        : out std_logic_vector(UL_NUM_ANT*4-1 downto 0);
        RAFE_CC1_NUM_RO             : out std_logic_vector(UL_NUM_ANT*3-1 downto 0);
        RAFE_CC1_FRAME_ID           : in  std_logic_vector(7 downto 0);
        RAFE_CC1_SUBFRAME_ID        : in  std_logic_vector(3 downto 0);
        RAFE_CC1_SLOT_ID            : in  std_logic_vector(5 downto 0);
        RAFE_CC1_SYMBOL_ID          : in  std_logic_vector(5 downto 0);
        RAFE_CC1_START_RE           : in  std_logic_vector(UL_NUM_ANT*16-1 downto 0);
        RAFE_CC1_VALID              : in  std_logic_vector(UL_NUM_ANT-1 downto 0);
        RAFE_CC1_START              : in  std_logic_vector(UL_NUM_ANT-1 downto 0);
        RAFE_CC1_LAST               : in  std_logic_vector(UL_NUM_ANT-1 downto 0);
        RAFE_CC1_DATA               : in  std_logic_vector(UL_NUM_ANT*32-1 downto 0)

--        -- MJANG Added
--        RAFE_CC2_FRAMES_SYNC        : out std_logic;
--        RAFE_CC2_FILTER_INDEX       : out std_logic_vector(2*4-1 downto 0);
--        RAFE_CC2_TIME_OFFSET        : out std_logic_vector(2*16-1 downto 0);
--        RAFE_CC2_FRAME_STRUCTURE    : out std_logic_vector(2*8-1 downto 0);
--        RAFE_CC2_CPLENGTH           : out std_logic_vector(2*16-1 downto 0);
--        RAFE_CC2_FREQ_OFFSET        : out std_logic_vector(2*24-1 downto 0);
--        RAFE_CC2_START_PRBC         : out std_logic_vector(2*10-1 downto 0);
--        RAFE_CC2_NUM_PRBC           : out std_logic_vector(2*8-1 downto 0);
--        RAFE_CC2_NUM_PSYMBOL        : out std_logic_vector(2*4-1 downto 0);
--        RAFE_CC2_NUM_RO             : out std_logic_vector(2*3-1 downto 0);
--        RAFE_CC2_FRAME_ID           : in  std_logic_vector(7 downto 0);
--        RAFE_CC2_SUBFRAME_ID        : in  std_logic_vector(3 downto 0);
--        RAFE_CC2_SLOT_ID            : in  std_logic_vector(5 downto 0);
--        RAFE_CC2_SYMBOL_ID          : in  std_logic_vector(5 downto 0);
--        RAFE_CC2_START_RE           : in  std_logic_vector(2*16-1 downto 0);
--        RAFE_CC2_VALID              : in  std_logic_vector(2-1 downto 0);
--        RAFE_CC2_START              : in  std_logic_vector(2-1 downto 0);
--        RAFE_CC2_LAST               : in  std_logic_vector(2-1 downto 0);
--        RAFE_CC2_DATA               : in  std_logic_vector(2*32-1 downto 0);

--        -- MJANG Added
--        RAFE_CC3_FRAMES_SYNC        : out std_logic;
--        RAFE_CC3_FILTER_INDEX       : out std_logic_vector(2*4-1 downto 0);
--        RAFE_CC3_TIME_OFFSET        : out std_logic_vector(2*16-1 downto 0);
--        RAFE_CC3_FRAME_STRUCTURE    : out std_logic_vector(2*8-1 downto 0);
--        RAFE_CC3_CPLENGTH           : out std_logic_vector(2*16-1 downto 0);
--        RAFE_CC3_FREQ_OFFSET        : out std_logic_vector(2*24-1 downto 0);
--        RAFE_CC3_START_PRBC         : out std_logic_vector(2*10-1 downto 0);
--        RAFE_CC3_NUM_PRBC           : out std_logic_vector(2*8-1 downto 0);
--        RAFE_CC3_NUM_PSYMBOL        : out std_logic_vector(2*4-1 downto 0);
--        RAFE_CC3_NUM_RO             : out std_logic_vector(2*3-1 downto 0);
--        RAFE_CC3_FRAME_ID           : in  std_logic_vector(7 downto 0);
--        RAFE_CC3_SUBFRAME_ID        : in  std_logic_vector(3 downto 0);
--        RAFE_CC3_SLOT_ID            : in  std_logic_vector(5 downto 0);
--        RAFE_CC3_SYMBOL_ID          : in  std_logic_vector(5 downto 0);
--        RAFE_CC3_START_RE           : in  std_logic_vector(2*16-1 downto 0);
--        RAFE_CC3_VALID              : in  std_logic_vector(2-1 downto 0);
--        RAFE_CC3_START              : in  std_logic_vector(2-1 downto 0);
--        RAFE_CC3_LAST               : in  std_logic_vector(2-1 downto 0);
--        RAFE_CC3_DATA               : in  std_logic_vector(2*32-1 downto 0);

--------------------------------------------------------------------------------
-- eMTC PRACH
--------------------------------------------------------------------------------

--        eMTC_CC0_FRAME_SYNC          : out std_logic;
--        eMTC_CC0_FILTER_INDEX        : out std_logic_vector(2*4-1 downto 0);
--        eMTC_CC0_TIME_OFFSET         : out std_logic_vector(2*16-1 downto 0);
--        eMTC_CC0_FRAME_STRUCTURE     : out std_logic_vector(2*8-1 downto 0);
--        eMTC_CC0_CPLENGTH            : out std_logic_vector(2*16-1 downto 0);
--        eMTC_CC0_FREQ_OFFSET         : out std_logic_vector(2*24-1 downto 0);
--        eMTC_CC0_START_PRBC          : out std_logic_vector(2*10-1 downto 0);
--        eMTC_CC0_NUM_PRBC            : out std_logic_vector(2*8-1 downto 0);
--        eMTC_CC0_NUM_PSYMBOL         : out std_logic_vector(2*4-1 downto 0);
--        eMTC_CC0_NUM_RO              : out std_logic_vector(2*3-1 downto 0);
--        eMTC_CC0_FRAME_ID            : in  std_logic_vector(8-1   downto 0);
--        eMTC_CC0_SUBFRAME_ID         : in  std_logic_vector(4-1   downto 0);
--        eMTC_CC0_SLOT_ID             : in  std_logic_vector(6-1   downto 0);
--        eMTC_CC0_SYMBOL_ID           : in  std_logic_vector(6-1   downto 0);
--        eMTC_CC0_START_RE            : in  std_logic_vector(2*16-1 downto 0);
--        eMTC_CC0_VALID               : in  std_logic_vector(2*1 -1 downto 0);
--        eMTC_CC0_START               : in  std_logic_vector(2*1 -1 downto 0);
--        eMTC_CC0_LAST                : in  std_logic_vector(2*1 -1 downto 0);
--        eMTC_CC0_DATA                : in  std_logic_vector(2*32-1 downto 0);

--        eMTC_CC1_FRAME_SYNC          : out std_logic;
--        eMTC_CC1_FILTER_INDEX        : out std_logic_vector(2*4-1 downto 0);
--        eMTC_CC1_TIME_OFFSET         : out std_logic_vector(2*16-1 downto 0);
--        eMTC_CC1_FRAME_STRUCTURE     : out std_logic_vector(2*8-1 downto 0);
--        eMTC_CC1_CPLENGTH            : out std_logic_vector(2*16-1 downto 0);
--        eMTC_CC1_FREQ_OFFSET         : out std_logic_vector(2*24-1 downto 0);
--        eMTC_CC1_START_PRBC          : out std_logic_vector(2*10-1 downto 0);
--        eMTC_CC1_NUM_PRBC            : out std_logic_vector(2*8-1 downto 0);
--        eMTC_CC1_NUM_PSYMBOL         : out std_logic_vector(2*4-1 downto 0);
--        eMTC_CC1_NUM_RO              : out std_logic_vector(2*3-1 downto 0);
--        eMTC_CC1_FRAME_ID            : in  std_logic_vector(8-1   downto 0);
--        eMTC_CC1_SUBFRAME_ID         : in  std_logic_vector(4-1   downto 0);
--        eMTC_CC1_SLOT_ID             : in  std_logic_vector(6-1   downto 0);
--        eMTC_CC1_SYMBOL_ID           : in  std_logic_vector(6-1   downto 0);
--        eMTC_CC1_START_RE            : in  std_logic_vector(2*16-1 downto 0);
--        eMTC_CC1_VALID               : in  std_logic_vector(2*1 -1 downto 0);
--        eMTC_CC1_START               : in  std_logic_vector(2*1 -1 downto 0);
--        eMTC_CC1_LAST                : in  std_logic_vector(2*1 -1 downto 0);
--        eMTC_CC1_DATA                : in  std_logic_vector(2*32-1 downto 0);

--        eMTC_CC2_FRAME_SYNC          : out std_logic;
--        eMTC_CC2_FILTER_INDEX        : out std_logic_vector(2*4-1 downto 0);
--        eMTC_CC2_TIME_OFFSET         : out std_logic_vector(2*16-1 downto 0);
--        eMTC_CC2_FRAME_STRUCTURE     : out std_logic_vector(2*8-1 downto 0);
--        eMTC_CC2_CPLENGTH            : out std_logic_vector(2*16-1 downto 0);
--        eMTC_CC2_FREQ_OFFSET         : out std_logic_vector(2*24-1 downto 0);
--        eMTC_CC2_START_PRBC          : out std_logic_vector(2*10-1 downto 0);
--        eMTC_CC2_NUM_PRBC            : out std_logic_vector(2*8-1 downto 0);
--        eMTC_CC2_NUM_PSYMBOL         : out std_logic_vector(2*4-1 downto 0);
--        eMTC_CC2_NUM_RO              : out std_logic_vector(2*3-1 downto 0);
--        eMTC_CC2_FRAME_ID            : in  std_logic_vector(8-1   downto 0);
--        eMTC_CC2_SUBFRAME_ID         : in  std_logic_vector(4-1   downto 0);
--        eMTC_CC2_SLOT_ID             : in  std_logic_vector(6-1   downto 0);
--        eMTC_CC2_SYMBOL_ID           : in  std_logic_vector(6-1   downto 0);
--        eMTC_CC2_START_RE            : in  std_logic_vector(2*16-1 downto 0);
--        eMTC_CC2_VALID               : in  std_logic_vector(2*1 -1 downto 0);
--        eMTC_CC2_START               : in  std_logic_vector(2*1 -1 downto 0);
--        eMTC_CC2_LAST                : in  std_logic_vector(2*1 -1 downto 0);
--        eMTC_CC2_DATA                : in  std_logic_vector(2*32-1 downto 0);

--        eMTC_CC3_FRAME_SYNC          : out std_logic;
--        eMTC_CC3_FILTER_INDEX        : out std_logic_vector(2*4-1 downto 0);
--        eMTC_CC3_TIME_OFFSET         : out std_logic_vector(2*16-1 downto 0);
--        eMTC_CC3_FRAME_STRUCTURE     : out std_logic_vector(2*8-1 downto 0);
--        eMTC_CC3_CPLENGTH            : out std_logic_vector(2*16-1 downto 0);
--        eMTC_CC3_FREQ_OFFSET         : out std_logic_vector(2*24-1 downto 0);
--        eMTC_CC3_START_PRBC          : out std_logic_vector(2*10-1 downto 0);
--        eMTC_CC3_NUM_PRBC            : out std_logic_vector(2*8-1 downto 0);
--        eMTC_CC3_NUM_PSYMBOL         : out std_logic_vector(2*4-1 downto 0);
--        eMTC_CC3_NUM_RO              : out std_logic_vector(2*3-1 downto 0);
--        eMTC_CC3_FRAME_ID            : in  std_logic_vector(8-1   downto 0);
--        eMTC_CC3_SUBFRAME_ID         : in  std_logic_vector(4-1   downto 0);
--        eMTC_CC3_SLOT_ID             : in  std_logic_vector(6-1   downto 0);
--        eMTC_CC3_SYMBOL_ID           : in  std_logic_vector(6-1   downto 0);
--        eMTC_CC3_START_RE            : in  std_logic_vector(2*16-1 downto 0);
--        eMTC_CC3_VALID               : in  std_logic_vector(2*1 -1 downto 0);
--        eMTC_CC3_START               : in  std_logic_vector(2*1 -1 downto 0);
--        eMTC_CC3_LAST                : in  std_logic_vector(2*1 -1 downto 0);
--        eMTC_CC3_DATA                : in  std_logic_vector(2*32-1 downto 0);

    );
	end component ORAN_TOP;

    signal  w_dlfe_system_mode           : std_logic_vector(1 downto 0);
    signal  w_dlfe_k0                   : std_logic_array12(3 downto 0);
    signal  w_dlfe_nre                  : std_logic_array12(3 downto 0);
    signal  w_dlfe_nfft                 : std_logic_array2(3 downto 0);
    signal  w_dlfe_frame_sync            : std_logic_vector(1 downto 0);
    signal  w_dlfe_frame_index          : std_logic_array8(3 downto 0);
    signal  w_dlfe_valid                : std_logic_array4(3 downto 0);
    signal  w_dlfe_re_mask              : std_logic_array4(3 downto 0);
    signal  w_dlfe_data                 : std_logic_array128(3 downto 0);
	
    signal  w_ulfe_frame_id             : std_logic_array8(3 downto 0);
    signal  w_ulfe_subframe_id          : std_logic_array4(3 downto 0);
    signal  w_ulfe_slot_id              : std_logic_array6(3 downto 0);
    signal  w_ulfe_symbol_id            : std_logic_array6(5 downto 0);
    signal  w_ulfe_start_re             : std_logic_array64(31 downto 0);
    signal  w_ulfe_valid                : std_logic_array4(1 downto 0);
    signal  w_ulfe_start                : std_logic_array4(1 downto 0);
    signal  w_ulfe_last                 : std_logic_array4(1 downto 0);
    signal  w_ulfe_data                 : std_logic_array128(63 downto 0);
	
    signal  w_rafe_frames_sync          : std_logic_vector(3 downto 0);
    signal  w_rafe_filter_index         : std_logic_array16(3 downto 0);
    signal  w_rafe_time_offset          : std_logic_array64(3 downto 0);
    signal  w_rafe_frame_structure      : std_logic_array32(3 downto 0);
    signal  w_rafe_cplength             : std_logic_array64(3 downto 0);
    signal  w_rafe_freq_offset          : std_logic_array96(3 downto 0);
    signal  w_rafe_start_prbc	       : std_logic_array40(3 downto 0);
    signal  w_rafe_num_psymbol          : std_logic_array16(3 downto 0);
    signal  w_rafe_num_ro               : std_logic_array12(3 downto 0);
    signal  w_rafe_num_prbc             : std_logic_array32(3 downto 0);
    signal  w_rafe_frame_id             : std_logic_array8(3 downto 0);
    signal  w_rafe_subframe_id          : std_logic_array4(3 downto 0);
    signal  w_rafe_slot_id              : std_logic_array6(3 downto 0);
    signal  w_rafe_symbol_id            : std_logic_array6(3 downto 0);
    signal  w_rafe_start_re             : std_logic_array64(3 downto 0);
    signal  w_rafe_valid                : std_logic_array4(3 downto 0);
    signal  w_rafe_start                : std_logic_array4(3 downto 0);
    signal  w_rafe_last                 : std_logic_array4(3 downto 0);
    signal  w_rafe_data                 : std_logic_array128(3 downto 0);
    
--    -- rf4440d lphy
--    component LPHY_TOP
--    port (
--        --//--- From SYSCTRL-TOP
--        i_core_clk              :   in std_logic                                                          ; --core clock 245.76MHz 
--        i_core_arst_lphy_top    :   in std_logic_vector ( DL_MAX_CC-1                            downto 0); --lphy_top active high async reset 
--        i_core_arst_dlfe        :   in std_logic_vector ( DL_MAX_CC-1                            downto 0); --dlfe active high async reset 
--        i_core_arst_ulfe        :   in std_logic_vector ( UL_MAX_CC-1                            downto 0); --ulfe active high async reset 
--        i_core_arst_rafe        :   in std_logic_vector ( UL_MAX_CC-1                            downto 0); --rafe active high async reset 
    
--        --//--- From/To CPU IF
--        i_cpu_clk               :   in std_logic                                                          ; --CPU Interface clock 100MHz
--        i_cpu_arst              :   in std_logic                                                          ; --CPU Interface async reset
--        i_cpu_cs                :   in std_logic_vector ( 0                                      downto 0); --CPU Interface chip sync
--        i_cpu_addr              :   in std_logic_vector ( CPUIF_ADDR_BW +4 -1                    downto 0); --CPU Interface address of lphy_top registers
--        i_cpu_wren              :   in std_logic_vector ( 0                                      downto 0); --CPU Interface write enable of lphy_top registers 
--        i_cpu_wdata             :   in std_logic_vector ( CPUIF_DATA_BW-1                        downto 0); --CPU Interface write data of lphy_top registers 
--        i_cpu_rden              :   in std_logic_vector ( 0                                      downto 0); --CPU Interface read enable of lphy_top registers 
--        o_cpu_rdata             :   out std_logic_vector( CPUIF_DATA_BW-1                        downto 0); --CPU Interface read data of lphy_top registers 
--        o_cpu_rd_valid          :   out std_logic_vector( 0                                      downto 0); --CPU Interface read data vaild of lphy_top registers 
    
--        --//--- From/To ORAN_TOP(DL)
--        i_din_frame_sync       :   in std_logic_vector (  01*DL_MAX_CC-1                         downto 0); --ccx dl input frame sync (1 pulse of 245.76MHz every 10ms)
--        i_din_frame_idx        :   in std_logic_vector (  08*DL_MAX_CC-1                         downto 0); --ccx dl input frame index (oran)
--        i_din_en               :   in std_logic_vector (  01*DL_NUM_LAYER*DL_MAX_CC-1            downto 0); --ccx dl input u-plane data valid (oran)
--        i_din_re_mask          :   in std_logic_vector (  01*DL_NUM_LAYER*DL_MAX_CC-1            downto 0); --ccx dl input re mask (oran)
--    --    i_din_sys_mode_dss     :   in std_logic_vector (  01*DL_NUM_LAYER*DL_MAX_CC-1            downto 0); --ccx dl input system mode bitmap for dss (oran) 
--        i_din_iq               :   in std_logic_vector (  2*TOP_DIO_BW*DL_NUM_LAYER*DL_MAX_CC-1  downto 0); --ccx dl input u-plane data (oran)      
--        o_dout_dl_sys_mode     :   out std_logic_vector(  01*DL_MAX_CC-1                         downto 0); --ccx dl output system mode   
--        o_dout_dl_ntone        :   out std_logic_vector(  12*DL_MAX_CC-1                         downto 0); --ccx dl output ntone   
--        o_dout_dl_fft_type     :   out std_logic_vector(  02*DL_MAX_CC-1                         downto 0); --ccx dl output fft_type
--        o_dout_dl_k0           :   out std_logic_vector(  12*DL_MAX_CC-1                         downto 0); --ccx dl output k0  
                                                                                                
--        --//--- To ORAN_TOP (PUxCH)
    
--    --    i_uin_symbol_idx       :   in  std_logic_vector(  4*UL_MAX_CC-1                          downto 0);                               
--    --    i_uin_en_technology    :   in  std_logic_vector(  UL_MAX_CC-1                            downto 0);                            
--    --    i_uin_technology_dss   :   in  std_logic_vector(  UL_MAX_CC-1                            downto 0);                               
    
    
--         o_uout_frame_idx      :   out std_logic_vector(  08*UL_MAX_CC-1                         downto 0);  --ccx ul output frame index (oran)       
--         o_uout_subfrm_idx     :   out std_logic_vector(  04*UL_MAX_CC-1                         downto 0);  --ccx ul output subframe index (oran)
--         o_uout_slot_idx       :   out std_logic_vector(  06*UL_MAX_CC-1                         downto 0);  --ccx ul output slot index (oran)
--         o_uout_symbol_idx     :   out std_logic_vector(  06*UL_MAX_CC-1                         downto 0);  --ccx ul output symbol index (oran)
--         o_uout_start_re_idx   :   out std_logic_vector(  16*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx ul output start re index (oran)
--         o_uout_en             :   out std_logic_vector(  01*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx ul output u-plane data valid (oran)
--         o_uout_start_re       :   out std_logic_vector(  01*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx ul output start re indicator (oran)    
--         o_uout_last_re        :   out std_logic_vector(  01*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx ul output last re indicator (oran)
--         o_uout_iq             :   out std_logic_vector(  2*TOP_DIO_BW*UL_NUM_PATH*UL_MAX_CC-1   downto 0);  --ccx ul output u-plane data (oran)
    
--        --//--- From/To ORAN_TOP (PRACH)
--    --     i_rin_frame_sync      :   in std_logic_vector (  01*UL_MAX_CC-1                         downto 0);	 --ccx prach input frame sync (1 pulse of 245.76MHz every 10ms)
--         i_rin_filter_idx      :   in std_logic_vector (  04*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach input filter index
--         i_rin_time_offset     :   in std_logic_vector (  16*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach input time offset
--         i_rin_frame_struct    :   in std_logic_vector (  08*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach input frame structure
--         i_rin_cp_length       :   in std_logic_vector (  16*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach input cp length
--         i_rin_freq_offset     :   in std_logic_vector (  24*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach input frequency offset
--         i_rin_start_prbc      :   in std_logic_vector (  10*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach input start PRBC 
--         i_rin_num_psymbol     :   in std_logic_vector (  04*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach input preamble symbol number
--         i_rin_num_ro          :   in std_logic_vector (  03*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach input occasion number
--         i_rin_num_prbc        :   in std_logic_vector (  08*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --//ccx prach input c-plane physical rb size 
--         o_rout_frame_idx      :   out std_logic_vector(  08*UL_MAX_CC-1                         downto 0);  --ccx prach output frame index (oran)  
--         o_rout_subfrm_idx     :   out std_logic_vector(  04*UL_MAX_CC-1                         downto 0);  --ccx prach output subframe index (oran)
--         o_rout_slot_idx       :   out std_logic_vector(  06*UL_MAX_CC-1                         downto 0);  --ccx prach output slot index (oran)
--         o_rout_symbol_idx     :   out std_logic_vector(  06*UL_MAX_CC-1                         downto 0);  --ccx prach output symbol index (oran)
--         o_rout_start_re_idx   :   out std_logic_vector(  16*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach output start re index (oran)
--         o_rout_en             :   out std_logic_vector(  01*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach output u-plane data valid (oran)
--         o_rout_start_re       :   out std_logic_vector(  01*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach output start re indicator (oran)    
--         o_rout_last_re        :   out std_logic_vector(  01*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach output last re indicator (oran)
--         o_rout_iq             :   out std_logic_vector(  2*TOP_DIO_BW*UL_NUM_PATH*UL_MAX_CC-1   downto 0);  --ccx prach output u-plane data (oran)  
    
--        --//--- To BBCTRL(DL)
--        o_dout_frame_sync      :   out std_logic_vector(  01*DL_MAX_CC-1                         downto 0);  --ccx dl output frame sync (1 pulse of 245.76MHz every 10ms)
--        o_dout_en              :   out std_logic_vector(  01*DL_NUM_ANT*DL_MAX_CC-1              downto 0);  --ccx dl output td data valid 
--        o_dout_i               :   out std_logic_vector(  TOP_DIO_BW*DL_NUM_ANT*DL_MAX_CC-1      downto 0);  --ccx dl output td in-phase sample
--        o_dout_q               :   out std_logic_vector(  TOP_DIO_BW*DL_NUM_ANT*DL_MAX_CC-1      downto 0);  --ccx dl output td quadrature sample
                                                                                           
--        --//--- FROM BBCTRL(UL)                                                            
--        i_uin_frame_sync       :   in std_logic_vector (  01*UL_MAX_CC-1                         downto 0);  --ccx ul input frame sync (1 pulse of 245.76MHz every 10ms)
--        i_uin_en               :   in std_logic_vector (  01*UL_NUM_ANT*UL_MAX_CC-1              downto 0);  --ccx ul input td data valid 
--        i_uin_i                :   in std_logic_vector (  TOP_DIO_BW*UL_NUM_ANT*UL_MAX_CC-1      downto 0);  --ccx ul input td in-phase sample
--        i_uin_q                :   in std_logic_vector (  TOP_DIO_BW*UL_NUM_ANT*UL_MAX_CC-1      downto 0);  --ccx ul input td quadrature sample
    
--        --- From/To ORAN_TOP (NPRACH,NPUSCH)
--        i_nin_filter_idx      :   in std_logic_vector  ( 04*NB_NUM_PATH*NB_MAX_CC-1              downto 0);	 --//ccx ul nprach,npuxch input filter index
--        i_nin_time_offset     :   in std_logic_vector  ( 16*NB_NUM_PATH*NB_MAX_CC-1              downto 0);  --//ccx ul nprach,npuxch input time offset
--        i_nin_frame_struct    :   in std_logic_vector  ( 08*NB_NUM_PATH*NB_MAX_CC-1              downto 0);  --//ccx ul nprach,npuxch input frame structure
--        i_nin_cp_length       :   in std_logic_vector  ( 16*NB_NUM_PATH*NB_MAX_CC-1              downto 0);  --//ccx ul nprach,npuxch input cp length
--        i_nin_num_psymbol     :   in std_logic_vector  ( 04*NB_NUM_PATH*NB_MAX_CC-1              downto 0);  --//ccx ul nprach,npuxch input preamble symbol number
--        i_nin_freq_offset     :   in std_logic_vector  ( 24*NB_NUM_PATH*NB_MAX_CC-1              downto 0);  --//ccx ul nprach,npuxch input frequency offset
--        i_nin_num_ro          :   in std_logic_vector  ( 03*NB_NUM_PATH*NB_MAX_CC-1              downto 0);  --//ccx ul nprach,npuxch input occasion number
--        i_nin_num_prbc        :   in std_logic_vector  ( 08*NB_NUM_PATH*NB_MAX_CC-1              downto 0);  --//ccx ul nprach,npuxch input c-plane physical rb size 
--        i_nin_start_prbc      :   in std_logic_vector  ( 10*NB_NUM_PATH*NB_MAX_CC-1              downto 0);  --//ccx ul nprach,npuxch input
--        o_nout_nco_valid      :   out std_logic_vector ( 01*2-1                                  downto 0);  --//ccx ul nprach,npuxch output frame index (oran)  
--        o_nout_frame_struct   :   out std_logic_vector ( 08*2-1                                  downto 0);  --//ccx ul nprach,npuxch output frame index (oran)  
--        o_nout_freq_offset    :   out std_logic_vector ( 24*2-1                                  downto 0);  --//ccx ul nprach,npuxch output frame index (oran)  
--        o_nout_frame_idx      :   out std_logic_vector ( 08*NB_MAX_CC-1                          downto 0);  --//ccx ul nprach,npuxch output frame index (oran)  
--        o_nout_subfrm_idx     :   out std_logic_vector ( 04*NB_MAX_CC-1                          downto 0);  --//ccx ul nprach,npuxch output subframe index (oran)
--        o_nout_slot_idx       :   out std_logic_vector ( 06*NB_MAX_CC-1                          downto 0);  --//ccx ul nprach,npuxch output slot index (oran)
--        o_nout_symbol_idx     :   out std_logic_vector ( 06*NB_MAX_CC-1                          downto 0);  --//ccx ul nprach,npuxch output symbol index (oran)
--        o_nout_start_re_idx   :   out std_logic_vector ( 16*NB_NUM_PATH*NB_MAX_CC-1              downto 0);  --//ccx ul nprach,npuxch output start re index (oran)
--        o_nout_en             :   out std_logic_vector ( 01*NB_NUM_PATH*NB_MAX_CC-1              downto 0);  --//ccx ul nprach,npuxch output u-plane data valid (oran)
--        o_nout_start_re       :   out std_logic_vector ( 01*NB_NUM_PATH*NB_MAX_CC-1              downto 0);  --//ccx ul nprach,npuxch output start re indicator (oran)    
--        o_nout_last_re        :   out std_logic_vector ( 01*NB_NUM_PATH*NB_MAX_CC-1              downto 0);  --//ccx ul nprach,npuxch output last re indicator (oran)
--        o_nout_iq             :   out std_logic_vector ( 2*TOP_DIO_BW*NB_NUM_PATH*NB_MAX_CC-1    downto 0);  --//ccx ul nprach,npuxch output u-plane data (oran) 
    
--        --- FROM BBCTRL (UL NB-IoT)
--        i_nin_frame_sync      :   in  std_logic_vector ( 01*2-1                          downto 0);  --//ccx ul nprach,npuxch input frame sync (1 pulse of 245.76MHz every 10ms)
--        i_nin_en              :   in  std_logic_vector ( 01*NB_NUM_ANT*2-1               downto 0);  --//ccx ul nprach,npuxch input td data valid 
--        i_nin_i               :   in  std_logic_vector ( TOP_DIO_BW*NB_NUM_ANT*2-1       downto 0);  --//ccx ul nprach,npuxch input td in-phase sample
--        i_nin_q               :   in  std_logic_vector ( TOP_DIO_BW*NB_NUM_ANT*2-1       downto 0);  --//ccx ul nprach,npuxch input td quadrature sample
     
--        i_min_filter_idx      :   in  std_logic_vector ( 04*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach input filter index
--        i_min_time_offset     :   in  std_logic_vector ( 16*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach input time offset
--        i_min_frame_struct    :   in  std_logic_vector ( 08*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach input frame structure
--        i_min_cp_length       :   in  std_logic_vector ( 16*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach input cp length
--        i_min_freq_offset     :   in  std_logic_vector ( 24*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach input frequency offset
--        i_min_num_psymbol     :   in  std_logic_vector ( 04*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach input preamble symbol number
--        i_min_num_ro          :   in  std_logic_vector ( 03*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach input occasion number
--        i_min_num_prbc        :   in  std_logic_vector ( 08*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach input c-plane physical rb size 
        
--        o_mout_frame_idx      :   out std_logic_vector ( 08*MT_MAX_CC-1                          downto 0);  --//ccx emtc prach output frame index (oran)  
--        o_mout_subfrm_idx     :   out std_logic_vector ( 04*MT_MAX_CC-1                          downto 0);  --//ccx emtc prach output subframe index (oran)
--        o_mout_slot_idx       :   out std_logic_vector ( 06*MT_MAX_CC-1                          downto 0);  --//ccx emtc prach output slot index (oran)
--        o_mout_symbol_idx     :   out std_logic_vector ( 06*MT_MAX_CC-1                          downto 0);  --//ccx emtc prach output symbol index (oran)
--        o_mout_start_re_idx   :   out std_logic_vector ( 16*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach output start re index (oran)
--        o_mout_en             :   out std_logic_vector ( 01*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach output u-plane data valid (oran)
--        o_mout_start_re       :   out std_logic_vector ( 01*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach output start re indicator (oran)    
--        o_mout_last_re        :   out std_logic_vector ( 01*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach output last re indicator (oran)
--        o_mout_iq             :   out std_logic_vector ( 2*TOP_DIO_BW*MT_NUM_PATH*MT_MAX_CC-1    downto 0);  --//ccx emtc prach output u-plane data (oran)  
--        --//--- FROM BBCTRL (UL eMTC)
--        i_min_frame_sync      :   in  std_logic_vector (01*MT_MAX_CC-1                           downto 0);  --//ccx ul emtc prach input frame sync (1 pulse of 245.76MHz every 10ms)
--        i_min_en              :   in  std_logic_vector (01*MT_NUM_ANT*MT_MAX_CC-1                downto 0);  --//ccx ul emtc prach input td data valid 
--        i_min_i               :   in  std_logic_vector (TOP_DIO_BW*MT_NUM_ANT*MT_MAX_CC-1        downto 0);  --//ccx ul emtc prach input td in-phase sample
--        i_min_q               :   in  std_logic_vector (TOP_DIO_BW*MT_NUM_ANT*MT_MAX_CC-1        downto 0)   -- //ccx ul emtc prach input td quadrature sample
    
--    );
--    end component ;

    -- kkdi lphy
    component BB_TOP
	generic (		
		NUM_CC              : integer  := DL_NUM_CC          ;
		MAX_CC              : integer  := DL_MAX_CC          ;
		DL_NUM_LAYER        : integer  := DL_NUM_LAYER    ;
		DL_NUM_ANT          : integer  := DL_NUM_ANT      ;
		UL_NUM_PATH         : integer  := UL_NUM_PATH     ;
		UL_NUM_ANT          : integer  := UL_NUM_ANT      ;
		TOP_DIO_BW          : integer  := 16              ;
		CPUIF_ADDR_BW       : integer  := 16              ;
		CPUIF_DATA_BW       : integer  := 32
	);
	port (
		--- From SYSCTRL_TOP
		i_core_clk  			: in std_logic;
		i_core_arst_bbtop       : in std_logic_vector(MAX_CC-1 downto 0);
		i_core_arst_dlfe        : in std_logic_vector(MAX_CC-1 downto 0);
		i_core_arst_ulfe        : in std_logic_vector(MAX_CC-1 downto 0);
		i_core_arst_rafe        : in std_logic_vector(MAX_CC-1 downto 0);

		--- From/To CPU IF
		i_cpu_clk  				:in	std_logic;
		i_cpu_arst              :in std_logic;
		i_bb_cpu_cs             :in	std_logic_vector(0 downto 0);
		i_bb_cpu_addr           :in std_logic_vector(CPUIF_ADDR_BW-1 downto 0);
		i_bb_cpu_wren           :in	std_logic_vector(0 downto 0);
		i_bb_cpu_wdata          :in std_logic_vector(CPUIF_DATA_BW-1 downto 0);
		i_bb_cpu_rden           :in	std_logic_vector(0 downto 0);
		o_bb_cpu_rdata          :out std_logic_vector(CPUIF_DATA_BW-1 downto 0);
		o_bb_cpu_rd_valid       :out std_logic_vector(0 downto 0);

		--- From/To ORAN_TOP(DL)
		i_din_frame_sync  		: in std_logic_vector(01*MAX_CC-1 downto 0);
		i_din_frame_idx         : in std_logic_vector(08*MAX_CC-1 downto 0);
		i_din_en                : in std_logic_vector(01*DL_NUM_LAYER*MAX_CC-1 downto 0);
		i_din_re_mask           : in std_logic_vector(01*DL_NUM_LAYER*MAX_CC-1 downto 0);
		i_din_iq                : in std_logic_vector(2*TOP_DIO_BW*DL_NUM_LAYER*MAX_CC-1 downto 0);
		o_dout_dl_sys_mode      : out std_logic_vector(01*MAX_CC-1 downto 0);
		o_dout_dl_ntone   		: out std_logic_vector(12*MAX_CC-1 downto 0);
		o_dout_dl_fft_type      : out std_logic_vector(02*MAX_CC-1 downto 0);
		o_dout_dl_k0            : out std_logic_vector(12*MAX_CC-1 downto 0);

		--- To ORAN_TOP (PUxCH)
		o_uout_frame_sync		: out std_logic_vector(01*MAX_CC-1 downto 0);
		o_uout_frame_idx        : out std_logic_vector(08*MAX_CC-1 downto 0);
		o_uout_subfrm_idx       : out std_logic_vector(04*MAX_CC-1 downto 0);
		o_uout_slot_idx         : out std_logic_vector(06*MAX_CC-1 downto 0);
		o_uout_symbol_idx       : out std_logic_vector(06*MAX_CC-1 downto 0);
		o_uout_start_re_idx     : out std_logic_vector(16*UL_NUM_PATH*MAX_CC-1 downto 0);
		o_uout_en               : out std_logic_vector(1*UL_NUM_PATH*MAX_CC-1 downto 0);
		o_uout_start_re         : out std_logic_vector(1*UL_NUM_PATH*MAX_CC-1 downto 0);
		o_uout_last_re          : out std_logic_vector(1*UL_NUM_PATH*MAX_CC-1 downto 0);
		o_uout_iq               : out std_logic_vector(2*TOP_DIO_BW*UL_NUM_PATH*MAX_CC-1 downto 0);

		--- From/To ORAN_TOP (PRACH)
		i_rin_frame_sync   		: in std_logic_vector(01*MAX_CC-1 downto 0);
		i_rin_filter_idx        : in std_logic_vector(04*UL_NUM_PATH*MAX_CC-1 downto 0);
		i_rin_time_offset       : in std_logic_vector(16*UL_NUM_PATH*MAX_CC-1 downto 0);
		i_rin_frame_struct      : in std_logic_vector(08*UL_NUM_PATH*MAX_CC-1 downto 0);
		i_rin_cp_length         : in std_logic_vector(16*UL_NUM_PATH*MAX_CC-1 downto 0);
		i_rin_freq_offset       : in std_logic_vector(24*UL_NUM_PATH*MAX_CC-1 downto 0);
		i_rin_num_psymbol       : in std_logic_vector(04*UL_NUM_PATH*MAX_CC-1 downto 0);
		i_rin_num_ro            : in std_logic_vector(03*UL_NUM_PATH*MAX_CC-1 downto 0);
		i_rin_num_prbc          : in std_logic_vector(08*UL_NUM_PATH*MAX_CC-1 downto 0);
		i_rin_start_prbc        : in std_logic_vector(10*UL_NUM_PATH*MAX_CC-1 downto 0);
		
		o_rout_frame_sync 		: out std_logic_vector(MAX_CC-1 downto 0);
		o_rout_frame_idx        : out std_logic_vector(08*MAX_CC-1 downto 0);
		o_rout_subfrm_idx       : out std_logic_vector(04*MAX_CC-1 downto 0);
		o_rout_slot_idx         : out std_logic_vector(06*MAX_CC-1 downto 0);
		o_rout_symbol_idx       : out std_logic_vector(06*MAX_CC-1 downto 0);
		o_rout_start_re_idx     : out std_logic_vector(16*UL_NUM_PATH*MAX_CC-1 downto 0);
		o_rout_en               : out std_logic_vector(1*UL_NUM_PATH*MAX_CC-1 downto 0);
		o_rout_start_re         : out std_logic_vector(1*UL_NUM_PATH*MAX_CC-1 downto 0);
		o_rout_last_re          : out std_logic_vector(1*UL_NUM_PATH*MAX_CC-1 downto 0);
		o_rout_iq               : out std_logic_vector(2*TOP_DIO_BW*UL_NUM_PATH*MAX_CC-1 downto 0);

		--- To BBCTRL(DL)
		o_dout_frame_sync		: out std_logic_vector(1*NUM_CC-1 downto 0);
		o_dout_en               : out std_logic_vector(01*DL_NUM_ANT*MAX_CC-1 downto 0);
		o_dout_i                : out std_logic_vector(TOP_DIO_BW*DL_NUM_ANT*MAX_CC-1 downto 0);
		o_dout_q                : out std_logic_vector(TOP_DIO_BW*DL_NUM_ANT*MAX_CC-1 downto 0);

		--- FROM BBCTRL(UL)
		i_uin_frame_sync 		: in std_logic_vector(01*NUM_CC-1 downto 0);
		i_uin_en                : in std_logic_vector(01*UL_NUM_ANT*MAX_CC-1 downto 0);
		i_uin_i                 : in std_logic_vector(TOP_DIO_BW*UL_NUM_ANT*MAX_CC-1 downto 0);
		i_uin_q                 : in std_logic_vector(TOP_DIO_BW*UL_NUM_ANT*MAX_CC-1 downto 0);
		
		o_dbg_uin_frame_sync    : out std_logic;
        o_dbg_uin_en            : out std_logic;
        o_dbg_uin_i             : out std_logic_vector(TOP_DIO_BW-1 downto 0);
        o_dbg_uin_q             : out std_logic_vector(TOP_DIO_BW-1 downto 0)
	);
	end component;
	
	signal s_i_din_frame_idx         : std_logic_vector(08*DL_MAX_CC-1 downto 0);
	signal s_i_din_en                : std_logic_vector(01*DL_NUM_LAYER*DL_MAX_CC-1 downto 0);
	signal s_i_din_re_mask           : std_logic_vector(01*DL_NUM_LAYER*DL_MAX_CC-1 downto 0);
	signal s_i_din_iq                : std_logic_vector(2*TOP_DIO_BW*DL_NUM_LAYER*DL_MAX_CC-1 downto 0);
	signal s_o_dout_dl_ntone   		 : std_logic_vector(12*DL_MAX_CC-1 downto 0);
	signal s_o_dout_dl_fft_type      : std_logic_vector(02*DL_MAX_CC-1 downto 0);
	signal s_o_dout_dl_k0            : std_logic_vector(12*DL_MAX_CC-1 downto 0);
	
	--- To ORAN_TOP (PUxCH)
	signal s_o_uout_frame_sync		 : std_logic_vector(01*UL_MAX_CC-1 downto 0);
	signal s_o_uout_frame_idx        : std_logic_vector(08*UL_MAX_CC-1 downto 0);
	signal s_o_uout_subfrm_idx       : std_logic_vector(04*UL_MAX_CC-1 downto 0);
	signal s_o_uout_slot_idx         : std_logic_vector(06*UL_MAX_CC-1 downto 0);
	signal s_o_uout_symbol_idx       : std_logic_vector(06*UL_MAX_CC-1 downto 0);
	signal s_o_uout_start_re_idx     : std_logic_vector(16*UL_NUM_PATH*UL_MAX_CC-1 downto 0);
	signal s_o_uout_en               : std_logic_vector(1*UL_NUM_PATH*UL_MAX_CC-1 downto 0);
	signal s_o_uout_start_re         : std_logic_vector(1*UL_NUM_PATH*UL_MAX_CC-1 downto 0);
	signal s_o_uout_last_re          : std_logic_vector(1*UL_NUM_PATH*UL_MAX_CC-1 downto 0);
	signal s_o_uout_iq               : std_logic_vector(2*TOP_DIO_BW*UL_NUM_PATH*UL_MAX_CC-1 downto 0);

	--- From/To ORAN_TOP (PRACH)
	signal s_i_rin_frame_sync        : std_logic_vector(01*UL_MAX_CC-1 downto 0);
	signal s_i_rin_filter_idx        : std_logic_vector(04*UL_NUM_PATH*UL_MAX_CC-1 downto 0);
	signal s_i_rin_time_offset       : std_logic_vector(16*UL_NUM_PATH*UL_MAX_CC-1 downto 0);
	signal s_i_rin_frame_struct      : std_logic_vector(08*UL_NUM_PATH*UL_MAX_CC-1 downto 0);
	signal s_i_rin_cp_length         : std_logic_vector(16*UL_NUM_PATH*UL_MAX_CC-1 downto 0);
	signal s_i_rin_freq_offset       : std_logic_vector(24*UL_NUM_PATH*UL_MAX_CC-1 downto 0);
	signal s_i_rin_num_psymbol       : std_logic_vector(04*UL_NUM_PATH*UL_MAX_CC-1 downto 0);
	signal s_i_rin_num_ro            : std_logic_vector(03*UL_NUM_PATH*UL_MAX_CC-1 downto 0);
	signal s_i_rin_num_prbc          : std_logic_vector(08*UL_NUM_PATH*UL_MAX_CC-1 downto 0);
	signal s_i_rin_start_prbc        : std_logic_vector(10*UL_NUM_PATH*UL_MAX_CC-1 downto 0);

	signal s_o_rout_frame_sync 		 : std_logic_vector(UL_MAX_CC-1 downto 0);
	signal s_o_rout_frame_idx        : std_logic_vector(08*UL_MAX_CC-1 downto 0);
	signal s_o_rout_subfrm_idx       : std_logic_vector(04*UL_MAX_CC-1 downto 0);
	signal s_o_rout_slot_idx         : std_logic_vector(06*UL_MAX_CC-1 downto 0);
	signal s_o_rout_symbol_idx       : std_logic_vector(06*UL_MAX_CC-1 downto 0);
	signal s_o_rout_start_re_idx     : std_logic_vector(16*UL_NUM_PATH*UL_MAX_CC-1 downto 0);
	signal s_o_rout_en               : std_logic_vector(1*UL_NUM_PATH*UL_MAX_CC-1 downto 0);
	signal s_o_rout_start_re         : std_logic_vector(1*UL_NUM_PATH*UL_MAX_CC-1 downto 0);
	signal s_o_rout_last_re          : std_logic_vector(1*UL_NUM_PATH*UL_MAX_CC-1 downto 0);
	signal s_o_rout_iq               : std_logic_vector(2*TOP_DIO_BW*UL_NUM_PATH*UL_MAX_CC-1 downto 0);


	component OTRX_DBG is
    port(
        PTP_1PPS                           : in    std_logic;
        OTRX_DISABLE_CPU                   : in    std_logic_vector(2 -1 downto 0);
        OTRX_DISABLE                       : out   std_logic_vector(2 -1 downto 0);
        OTRX_TX_FAULT                      : in    std_logic_vector(2 -1 downto 0);
        OTRX_MOD_ABS                       : in    std_logic_vector(2 -1 downto 0);
        OTRX_LOS                           : in    std_logic_vector(2 -1 downto 0)
    );
	end component OTRX_DBG;

    component ECPRIPHY_TOP
        port (
            --------------------------------------------------------------------------------
            -- Pin
            --------------------------------------------------------------------------------

            OTRX_DEL_IN                 : in  std_logic_vector(1 downto 0);
            OTRX_LOS_IN                 : in  std_logic_vector(1 downto 0);
            OTRX_TXFAULT_IN             : in  std_logic_vector(1 downto 0);
            OTRX_TXDIS_OUT              : out std_logic_vector(1 downto 0);
            OTRX_BH_RS_OUT              : out std_logic_array2(1 downto 0);

            --------------------------------------------------------------------------------
            -- SYSCTRL_TOP
            --------------------------------------------------------------------------------

            --------------------------------------------------------------------------------
            -- CPU_TOP
            --------------------------------------------------------------------------------
            ECPRI_GT_RESET_RX_DONE      : in  std_logic_vector(1 downto 0);
            ECPRI_GT_RESET_TX_DONE      : in  std_logic_vector(1 downto 0);
            ECPRI_STAT_RX_BLOCK_LOCK    : in  std_logic_vector(1 downto 0);
            ECPRI_STAT_RX_LOCAL_FAULT   : in  std_logic_vector(1 downto 0);
            ECPRI_STAT_RX_RATE_10G_25GN : in  std_logic_vector(1 downto 0);
            ECPRI_STAT_RX_REMOTE_FAULT  : in  std_logic_vector(1 downto 0);
            ECPRI_GT_RXLPMEN            : out std_logic_vector(1 downto 0);
            ECPRI_GT_TXDIFFCTRL         : out std_logic_array5(1 downto 0);
            ECPRI_TXPRECURSOR           : out std_logic_array5(1 downto 0);
            ECPRI_TXPOSTCUSOR           : out std_logic_array5(1 downto 0);
            MODE_CHANGE_25N_10H         : out std_logic_vector(1 downto 0);                     -- Low : 25G, High : 10G
            RX_WDT_RESET                : out std_logic_vector(1 downto 0);
            MAC_SYS_RESET               : out std_logic;
            DMA_BLOCK_RESET             : out std_logic;
            --------------------------------------------------------------------------------
            -- PROPAGATION signal
            --------------------------------------------------------------------------------
            ECPRI_FAULT_PROPA           : out std_logic_vector(2 downto 0);                     --[2]: BLOCK UNLOCK, [1]:REMOTE FAULT, [0]:LOCAL FAULT        

            --------------------------------------------------------------------------------
            -- CPU_TOP
            --------------------------------------------------------------------------------

            CLK_CPUIF                   : in  std_logic;
            RST_CPUIF                   : in  std_logic;

            --------------------------------------------------------------------------------
            -- CPUIF_TOP
            --------------------------------------------------------------------------------

            ADDR_CPUIF_IN               : in  std_logic_vector(15 downto 0);
            WDATA_CPUIF_IN              : in  std_logic_vector(31 downto 0);
            RDATA_CPUIF_OUT             : out std_logic_vector(31 downto 0);
            WREN_CPUIF_IN               : in  std_logic;
            RDEN_CPUIF_IN               : in  std_logic;
            RDVAL_CPUIF_OUT             : out std_logic
        );
    end component ;

    component BBCTRL_TOP is
        port (
            --------------------------------------------------------------------------------
            -- SYSCTRL_TOP
            --------------------------------------------------------------------------------

            RST_BBCTRL                  : in  std_logic;

            CLK_SYS                     : in  std_logic;
            CLK_SYSX2                   : in  std_logic;
            CLK_SYSX3                   : in  std_logic;
            CLK_SYSX4                   : in  std_logic;
            CLK_SYSX5                   : in  std_logic;
            CLK_SYSX6                   : in  std_logic;
            CLK_SYSX8                   : in  std_logic;
            CLK_SYSX10                  : in  std_logic;
            CLK_SYSX12                  : in  std_logic;
            CLK_SYSX16                  : in  std_logic;
            CLK_SYSX20                  : in  std_logic;

            --------------------------------------------------------------------------------
            -- CPU_TOP
            --------------------------------------------------------------------------------

            RST_CPUIF                   : in  std_logic;
            CLK_CPUIF                   : in  std_logic;

            I_1PPS_CPU                  : in  std_logic;
            I_BFN_STRB_CPU              : in  std_logic;
            I_BFN_CPU                   : in  std_logic_vector(10 downto 0);

            --------------------------------------------------------------------------------
            -- CPUIF_TOP
            --------------------------------------------------------------------------------

            WREN_CPUIF_IN               : in  std_logic;
            RDEN_CPUIF_IN               : in  std_logic;
            ADDR_CPUIF_IN               : in  std_logic_vector(15 downto 0);
            WDATA_CPUIF_IN              : in  std_logic_vector(31 downto 0);
            RDATA_CPUIF_OUT             : out std_logic_vector(31 downto 0);
            RDVAL_CPUIF_OUT             : out std_logic;

            --------------------------------------------------------------------------------
            -- BB_TOP
            --------------------------------------------------------------------------------

            I_DL_FSYNC                  :in  std_logic_vector(   DL_CC_NUM-1 downto 0);    -- 1 clock frame(10ms) sync  
            I_DL_TDD                    :in  std_logic_vector(   DL_CC_NUM-1 downto 0);
            I_DL_VLD                    :in  std_logic_vector( DL_CC_NUM*4-1 downto 0);    -- valid signal for valid data.   
            I_DL_DATA_I                 :in  std_logic_array16(DL_CC_NUM*4-1 downto 0);    -- 16b idata path per one ant path.      
            I_DL_DATA_Q                 :in  std_logic_array16(DL_CC_NUM*4-1 downto 0);    -- 16b qdata path per one ant path.  

            O_UL_FSYNC                  :out std_logic_vector(   UL_CC_NUM-1 downto 0);    -- 1 clock frame(10ms) sync   
            O_UL_TDD                    :out std_logic_vector(   UL_CC_NUM-1 downto 0);
            O_UL_VLD                    :out std_logic_vector( UL_CC_NUM*4-1 downto 0);    -- valid signal for valid data.   
            O_UL_DATA_I                 :out std_logic_array16(UL_CC_NUM*4-1 downto 0);    -- 16b idata path per one ant path.  
            O_UL_DATA_Q                 :out std_logic_array16(UL_CC_NUM*4-1 downto 0);    -- 16b qdata path per one ant path.  

            --------------------------------------------------------------------------------
            -- PIM_SBIF_TOP
            --------------------------------------------------------------------------------

            PIM_SBIF_RX_ENB_IN          : in  std_logic_vector(PIM_SBIF_NUM-1 downto 0);
            PIM_SBIF_RX_I_IN            : in  std_logic_array16(PIM_SBIF_NUM-1 downto 0);
            PIM_SBIF_RX_Q_IN            : in  std_logic_array16(PIM_SBIF_NUM-1 downto 0);

            PIM_SBIF_TX_VLD_OUT         : out std_logic_vector(PIM_SBIF_NUM-1 downto 0);
            PIM_SBIF_TX_I_OUT           : out std_logic_array16(PIM_SBIF_NUM-1 downto 0);
            PIM_SBIF_TX_Q_OUT           : out std_logic_array16(PIM_SBIF_NUM-1 downto 0);

            PIM_SBIF_TX_SYNC            : out std_logic;
            PIM_SBIF_TX_1PPS            : out std_logic;
            PIM_SBIF_TX_BFN_STRB        : out std_logic;
            PIM_SBIF_TX_BFN             : out std_logic_vector(10 downto 0);

            --------------------------------------------------------------------------------
            -- DSP_TOP
            --------------------------------------------------------------------------------

            DL_BFN_OK                   : out std_logic;

            DL_AIRTECH_OUT              : out std_logic_array4(DL_BBIQARY_NUM-1 downto 0);
            DL_CHBW_OUT                 : out std_logic_array4(DL_BBIQARY_NUM-1 downto 0);
            DL_TDD_OUT                  : out std_logic;
            DL_40MS_OUT                 : out std_logic;
            DL_BFN_STRB_OUT             : out std_logic;
            DL_BFN_OUT                  : out std_logic_vector(11 downto 0);
            DL_SYNC_OUT                 : out std_logic_vector(DL_BBIQARY_NUM-1 downto 0);
            DL_IQ_OUT                   : out std_logic_array16(DL_BBIQARY_NUM-1 downto 0);

            UL_AIRTECH_OUT              : out std_logic_array4(UL_BBIQARY_NUM-1 downto 0);
            UL_CHBW_OUT                 : out std_logic_array4(UL_BBIQARY_NUM-1 downto 0);
            UL_TDD_IN                   : in  std_logic;
            UL_BFN_STRB_IN              : in  std_logic;
            UL_SYNC_IN                  : in  std_logic_vector(UL_BBIQARY_NUM-1 downto 0);
            UL_IQ_IN                    : in  std_logic_array16(UL_BBIQARY_NUM-1 downto 0);

            PIM_SYNC_IN                 : in  std_logic_vector(PIM_SBIF_NUM-1 downto 0);
            PIM_I_IN                    : in  std_logic_array15(PIM_SBIF_NUM-1 downto 0);
            PIM_Q_IN                    : in  std_logic_array15(PIM_SBIF_NUM-1 downto 0);

            PIM_SYNC_OUT                : out std_logic_vector(PIM_SBIF_NUM-1 downto 0);
            PIM_I_OUT                   : out std_logic_array15(PIM_SBIF_NUM-1 downto 0);
            PIM_Q_OUT                   : out std_logic_array15(PIM_SBIF_NUM-1 downto 0);

            --------------------------------------------------------------------------------
            -- MISC_TOP
            --------------------------------------------------------------------------------

            DUMP_BFN_STRB_OUT           : out std_logic_vector(1 downto 0);
            DUMP_DATA_OUT               : out std_logic_array32(1 downto 0);
            DUMP_DVLD_OUT               : out std_logic_vector(1 downto 0);

            -- fb_sw_new
            FBSW_CNT                    : in  std_logic_vector(3 downto 0);
            FBSW_SSB_IND_FLAG           : in  std_logic;
            FBSW_MEAS_UPDATE            : in  std_logic
        );
    end component;

    component DSP_TOP is
        port(
            -- ***********************
            -- SYSCTRL-TOP Interface
            -- ***********************
            -- Internal PLL Lock
            INT_SYSPLL_LOCK_IN                  : in  std_logic;                                    -- Internal System PLL Lock

            -- System Reset & Clock
            RST_DDUC                            : in  std_logic;                                    -- DDUC_TOP Reset, '1': Reset
            RST_CFR                             : in  std_logic;                                    -- CFR_TOP Reset,  '1': Reset
            RST_DPD                             : in  std_logic;                                    -- DPD_TOP Reset,  '1': Reset
            RST_PIM                             : in  std_logic;

            CLK_SYS                             : in  std_logic;                                    -- System Clock :  30.72 MHz
            CLK_SYSX2                           : in  std_logic;                                    --  2x(CLK_SYS) :  61.44 MHz
            CLK_SYSX3                           : in  std_logic;                                    --  3x(CLK_SYS) :  92.16 MHz
            CLK_SYSX4                           : in  std_logic;                                    --  4x(CLK_SYS) : 122.88 MHz
            CLK_SYSX5                           : in  std_logic;                                    --  5x(CLK_SYS) : 153.60 MHz
            CLK_SYSX6                           : in  std_logic;                                    --  6x(CLK_SYS) : 184.32 MHz
            CLK_SYSX8                           : in  std_logic;                                    --  8x(CLK_SYS) : 245.76 MHz
            CLK_SYSX10                          : in  std_logic;                                    -- 10x(CLK_SYS) : 307.20 MHz
            CLK_SYSX12                          : in  std_logic;                                    -- 12x(CLK_SYS) : 368.64 MHz
            CLK_SYSX16                          : in  std_logic;                                    -- 16x(CLK_SYS) : 491.52 MHz
            CLK_SYSX20                          : in  std_logic;                                    -- 20x(CLK_SYS) : 614.40 MHz

            -- ***********************
            -- CPU-TOP Interface
            -- ***********************
            -- CPU Reset & Clock
            RST_CPUIF                           : in  std_logic;                                    -- CPUIF Reset, '1': Reset
            CLK_CPUIF                           : in  std_logic;                                    -- CPUIF Clock, Faster than iclk/oclk

            RST_DPDIF                           : in  std_logic;                                    -- CPUIF Reset, '1': Reset
            CLK_DPDIF                           : in  std_logic;                                    -- CPUIF Clock, Faster than iclk/oclk

            -- ***********************
            -- CPUIFTOP Interface
            -- ***********************
            -- CPUIF DSP Common
            ADDR_CPUIF_IN                       : in  std_logic_vector( ADDR_WIDTH-1 downto 0);     -- CPUIF Address Input, WORD Address
            WDATA_CPUIF_IN                      : in  std_logic_vector(WDATA_WIDTH-1 downto 0);     -- CPUIF Data Input
            RDATA_CPUIF_OUT                     : out std_logic_vector(RDATA_WIDTH-1 downto 0);     -- CPUIF DATA Output
            WREN_CPUIF_IN                       : in  std_logic;                                    -- CPUIF Write Enable,    '1': Active, Synchronous with iclk
            RDEN_CPUIF_IN                       : in  std_logic;                                    -- CPUIF Read Enable,     '1': Active,
            RDVLD_CPUIF_OUT                     : out std_logic;                                    -- CPUIF Read Data Valid, '1': Active, Synchronous with clk_cpu

            -- CPUIF DPD
            ADDR_DPDIF_IN                       : in  std_logic_vector( ADDR_WIDTH-1 downto 0);     -- CPUIF Address Input, WORD Address
            WDATA_DPDIF_IN                      : in  std_logic_vector(WDATA_WIDTH-1 downto 0);     -- CPUIF Data Input
            RDATA_DPDIF_OUT                     : out std_logic_vector(RDATA_WIDTH-1 downto 0);     -- CPUIF DATA Output
            WREN_DPDIF_IN                       : in  std_logic;                                    -- CPUIF Write Enable,    '1': Active, Synchronous with iclk
            RDEN_DPDIF_IN                       : in  std_logic;                                    -- CPUIF Read Enable,     '1': Active,
            RDVLD_DPDIF_OUT                     : out std_logic;                                    -- CPUIF Read Data Valid, '1': Active, Synchronous with clk_cpu

            -- ***********************
            -- BBCTRL-TOP Interface
            -- ***********************
            -- System Information
            DL_AIRTECH_IN                       : in  std_logic_array4( DL_BBIQARY_NUM-1 downto 0); -- System Type, 0x0: LTE, 0x1:UMTS
            DL_CHBW_IN                          : in  std_logic_array4( DL_BBIQARY_NUM-1 downto 0); -- Bandwidth,   0x0: 5M,  0x1: 10M, 0x2: 15M, 0x3: 20M

            UL_AIRTECH_IN                       : in  std_logic_array4( UL_BBIQARY_NUM-1 downto 0); -- System Type, 0x0: LTE, 0x1:UMTS
            UL_CHBW_IN                          : in  std_logic_array4( UL_BBIQARY_NUM-1 downto 0); -- Bandwidth,   0x0: 5M,  0x1: 10M, 0x2: 15M, 0x3: 20M

            -- TDD & BFN Strobe
            DL_BFN_STRB_IN                      : in  std_logic;                                    -- Downlink 10ms Frame Sync Strobe
            DL_SSB_STRB_IN                      : in  std_logic;                                    -- Downlink SSB period Strobe (20/40/80/160msec)
            DL_TDD_IN                           : in  std_logic;                                    -- Downlink TDD Strobe

            UL_BFN_STRB_OUT                     : out std_logic;                                    -- Delayed Uplink 10ms Frame Sync Strobe as UL Path Latency
            UL_TDD_OUT                          : out std_logic;                                    -- Delayed Uplink TDD Strobe as UL Path Latency

            BCF_ENB_IN                          : in  std_logic;

            -- Traffic IQ
            DL_SYNC_IN                          : in  std_logic_vector( DL_BBIQARY_NUM-1 downto 0); -- DUC IQ Data Sync
            DL_IQ_IN                            : in  std_logic_array16(DL_BBIQARY_NUM-1 downto 0); -- DUC IQ Data

            UL_SYNC_OUT                         : out std_logic_vector( UL_BBIQARY_NUM-1 downto 0); -- DDC IQ Data Sync
            UL_IQ_OUT                           : out std_logic_array16(UL_BBIQARY_NUM-1 downto 0); -- DDC IQ Data

            -- ***********************
            -- DACIF_TOP Interface
            -- ***********************
            -- TDD & BFN Strobe
            DL_BFN_STRB_OUT                     : out std_logic;                                    -- Delayed Downlink 10ms Frame Sync Strobe as DL Path Latency
            DL_SSB_STRB_OUT                     : out std_logic;                                    -- Delayed Downlink 10ms Frame Sync Strobe as DL Path Latency
            DL_TDD_OUT                          : out std_logic;                                    -- Delayed Downlink TDD Strobe as DL Path Latency

            FB_BFN_STRB_IN                      : in  std_logic;                                    -- Feedback 10ms Frame Sync Strobe
            FB_TDD_IN                           : in  std_logic;                                    -- Feedback TDD Strobe
            FB_SSB_STRB_IN                      : in  std_logic;                                    -- 40ms sync signal for SSB power measurement

            UL_BFN_STRB_IN                      : in  std_logic;                                    -- Uplink 10ms Frame Sync Strobe
            UL_TDD_IN                           : in  std_logic;                                    -- Uplink TDD Strobe

            BCF_ENB_OUT                         : out std_logic;

            -- Traffic IQ
            DL_SYNC_OUT                         : out std_logic_vector( TX_ANT_NUM-1 downto 0);     -- DSP-TOP output IQ sample valid
            DL_I_OUT                            : out std_logic_array16(TX_ANT_NUM-1 downto 0);     -- DSP-TOP output I data
            DL_Q_OUT                            : out std_logic_array16(TX_ANT_NUM-1 downto 0);     -- DSP-TOP output Q data

            FB_SYNC_IN                          : in  std_logic_vector( FB_PATH_NUM-1 downto 0);    -- Feedback Path IQ sample valid
            FB_I_IN                             : in  std_logic_array16(FB_PATH_NUM-1 downto 0);    -- Feedback Path I data
            FB_Q_IN                             : in  std_logic_array16(FB_PATH_NUM-1 downto 0);    -- Feedback Path Q data

            UL_SYNC_IN                          : in  std_logic_vector( RX_ANT_NUM-1 downto 0);     -- DSP-TOP Input IQ sample valid
            UL_I_IN                             : in  std_logic_array16(RX_ANT_NUM-1 downto 0);     -- DSP-TOP Input I data
            UL_Q_IN                             : in  std_logic_array16(RX_ANT_NUM-1 downto 0);     -- DSP-TOP Input Q data

            I_NBIOT_NCO_VALID_CC0               : in  std_logic;
            I_NBIOT_NCO_VALID_CC1               : in  std_logic;
            I_NBIOT_ORAN_FR_STRUCT_CC0          : in  std_logic_vector(7 downto 0);
            I_NBIOT_ORAN_FR_STRUCT_CC1          : in  std_logic_vector(7 downto 0);
            I_NBIOT_FREQ_OFFSET_CC0             : in  std_logic_vector(23 downto 0);
            I_NBIOT_FREQ_OFFSET_CC1             : in  std_logic_vector(23 downto 0);

            -- ***************************
            -- SBIF_TOP Interface for PIM
            -- ***************************
            PIM_SYNC_IN                         : in  std_logic_vector( PIM_SBIF_NUM-1 downto 0);
            PIM_I_IN                            : in  std_logic_array15(PIM_SBIF_NUM-1 downto 0);
            PIM_Q_IN                            : in  std_logic_array15(PIM_SBIF_NUM-1 downto 0);

            PIM_SYNC_OUT                        : out std_logic_vector( PIM_SBIF_NUM-1 downto 0);
            PIM_I_OUT                           : out std_logic_array15(PIM_SBIF_NUM-1 downto 0);
            PIM_Q_OUT                           : out std_logic_array15(PIM_SBIF_NUM-1 downto 0);

            -- ***********************
            -- MISC-TOP Interface
            -- ***********************
            FBSW_SSB_IND_FLAG_DSP               : in  std_logic;

            -- Feedback Switch
            FBSW_START_TRIG_IN                  : in  std_logic;                                    -- Start Pulse of Feedback Switch Period
            FBSW_CNT_IN                         : in  std_logic_vector( 4 downto 0);                -- Feedback Switch Counter
            FBSW_AUTO_MODE_DONE_IN              : in  std_logic_vector( FB_PATH_NUM-1 downto 0);    -- Feedback Switch Automode Done Flag, '0': Auto Mode
            FBSW_PWR_MSR_UDT_IN                 : in  std_logic;                                    -- Feedback Switch Measure Done, Feedback Power Measure Update Enable
            FBSW_MANUAL_MODE_IN                 : in  std_logic;                                    -- Feedback Switch Manual Mode, '1': Manual Mode
            FBSW_SC_PATH_SEL_IN                 : in  std_logic_vector( 4 downto 0);
            PWR_MSR_FB_SYNC_IN                  : in  std_logic;                                    -- Feedback Power Measure Feedback Sync / 20ms sync
            PWR_MSR_EN_IN                       : in  std_logic;                                    -- Feedback Power Measure Enable

            -- Signal Suspension
            SIG_SUS_FLAG_OUT                    : out std_logic_vector( TX_ANT_NUM-1 downto 0);     -- OPD Detect Flag
            SIG_SUS_DLOFF_IN                    : in  std_logic_vector( TX_ANT_NUM-1 downto 0);     -- Wave-Stop Flag

            -- IQ/Clock Status
            DL_IQ_ISZERO_OUT                    : out std_logic_vector( TX_ANT_NUM-1 downto 0);     -- '1': IQ is Zero, '0': IQ is Non-Zero
            DL_CLK_ISZERO_OUT                   : out std_logic_vector( TX_ANT_NUM-1 downto 0);     --

            -- Test Pattern (Reserved)
            TEST_DATA_IN                        : in  std_logic_array32(1 downto 0);                -- ETM Generator of Fixed Pattern Generator, Test Data for Clock Domain#0/#1
            TEST_DENB_OUT                       : out std_logic_vector( 1 downto 0);                -- Test Pattern Memory Read Enable

            -- Dump
            DUMP_BFN_STRB_OUT                   : out std_logic_vector( 1 downto 0);                -- Delayed 10ms Frame Sync Strobe for DUMP
            DUMP_DVLD_OUT                       : out std_logic_vector( 1 downto 0);                -- Dump Sample Valid
            DUMP_DATA_OUT                       : out std_logic_array32(1 downto 0);                -- Dump Sample

            -- ***********************
            -- TOP Port Interface
            -- ***********************
            -- FPGA ID
            FPGA_ID_IN                          : in  std_logic_vector( 2 downto 0);                -- FPGA HardWare ID

            -- Debugging Port(Reserved)
            DBG_SIG_OUT                         : out std_logic_array32(1 downto 0)                 -- For Block Debugging, Reserved Output
        );
    end component;

    component DCIF_TOP is
        GENERIC
(
            SIMULATION_ON                           : boolean   := false
        );
        port(
            -- Clock
            RST_DCIF                                : in  std_logic;
            --        CLK_SYS                                 : in  std_logic;  --30.72M
            --        CLK_SYSX2                               : in  std_logic;
            --        CLK_SYSX3                               : in  std_logic;
            CLK_SYSX4                               : in  std_logic;  --122.88M
            --        CLK_SYSX5                               : in  std_logic;
            --        CLK_SYSX6                               : in  std_logic;
            CLK_SYSX8                               : in  std_logic;  --245.76M
            --        CLK_SYSX10                              : in  std_logic;
            --        CLK_SYSX12                              : in  std_logic;
            --        CLK_SYSX16                              : in  std_logic;
            --        CLK_SYSX20                              : in  std_logic;
            REFCLK_SERDES_IN                        : in  std_logic; --_vector(JSERDES_QUAD_NUM-1 downto 0);        
            --CPU Interface
            RST_CPUIF                               : in  std_logic;                     -- cpuif reset, '1': Reset
            CLK_CPUIF                               : in  std_logic;                     -- cpuif clock, faster than iclk/oclk
            ADDR_CPUIF_IN                           : in  std_logic_vector(15 downto 0); -- cpuif address input, word address.
            WDATA_CPUIF_IN                          : in  std_logic_vector(31 downto 0); -- cpuif data input
            RDATA_CPUIF_OUT                         : out std_logic_vector(31 downto 0); -- cpuif data output
            WREN_CPUIF_IN                           : in  std_logic;                     -- cpuif write enable, '1': active, synchronous with iclk
            RDEN_CPUIF_IN                           : in  std_logic;                     -- cpuif read enable, '1': active.
            RDVAL_CPUIF_OUT                         : out std_logic;                     -- cpuif read data valid, '1': active, synchronous with clk_cpu.
            ------------------------------------------------------------------------------------------
            -- RFIC Interface
            ------------------------------------------------------------------------------------------
            JESD_SERIAL_TX_OUT_P                    : out std_logic_vector((JESD_TX_LINK_NUM*JESD_TX_LANE_NUM-1) downto 0);   -- JESD204B Serial TX P
            JESD_SERIAL_TX_OUT_N                    : out std_logic_vector((JESD_TX_LINK_NUM*JESD_TX_LANE_NUM-1) downto 0);   -- JESD204B Serial TX N
            JESD_SYSREF_TX_OUT                      : out std_logic_vector((JESD_TX_LINK_NUM-1) downto 0);                    -- RFIC TX SYSREF OUT
            JESD_SYNC_TX_IN                         : in  std_logic_vector((JESD_TX_LINK_NUM-1) downto 0);

            JESD_SERIAL_RX_IN_P                     : in  std_logic_vector((JESD_RX_LINK_NUM*JESD_RX_LANE_NUM-1) downto 0);   -- JESD204B Serial RX P
            JESD_SERIAL_RX_IN_N                     : in  std_logic_vector((JESD_RX_LINK_NUM*JESD_RX_LANE_NUM-1) downto 0);   -- JESD204B Serial RX N
            JESD_SYNC_RX_OUT                        : out std_logic_vector((JESD_RX_LINK_NUM-1) downto 0);
            JESD_SYSREF_RX_OUT                      : out std_logic_vector((JESD_RX_LINK_NUM-1) downto 0);

            JESD_SERIAL_FB_IN_P                     : in  std_logic_vector((JESD_FB_LINK_NUM*JESD_FB_LANE_NUM-1) downto 0);   -- JESD204B Serial RX P
            JESD_SERIAL_FB_IN_N                     : in  std_logic_vector((JESD_FB_LINK_NUM*JESD_FB_LANE_NUM-1) downto 0);   -- JESD204B Serial RX N
            JESD_SYNC_FB_OUT                        : out std_logic_vector((JESD_FB_LINK_NUM-1) downto 0);
            JESD_SYSREF_FB_OUT                      : out std_logic_vector((JESD_FB_LINK_NUM-1) downto 0);
            ------------------------------------------------------------------------------------------
            -- JESD IP AXI Interface
            ------------------------------------------------------------------------------------------
            JESD204B_AXI_ACLK                       : in STD_LOGIC;
            JESD204B_AXI_ARESETN                    : in STD_LOGIC;
            JESD204B_AXI_araddr                     : in STD_LOGIC_VECTOR ( 31 downto 0 );
            JESD204B_AXI_arburst                    : in STD_LOGIC_VECTOR ( 1 downto 0 );
            JESD204B_AXI_arcache                    : in STD_LOGIC_VECTOR ( 3 downto 0 );
            JESD204B_AXI_arlen                      : in STD_LOGIC_VECTOR ( 7 downto 0 );
            JESD204B_AXI_arlock                     : in STD_LOGIC_VECTOR ( 0 to 0 );
            JESD204B_AXI_arprot                     : in STD_LOGIC_VECTOR ( 2 downto 0 );
            JESD204B_AXI_arqos                      : in STD_LOGIC_VECTOR ( 3 downto 0 );
            JESD204B_AXI_arready                    : out STD_LOGIC;
            JESD204B_AXI_arregion                   : in STD_LOGIC_VECTOR ( 3 downto 0 );
            JESD204B_AXI_arsize                     : in STD_LOGIC_VECTOR ( 2 downto 0 );
            JESD204B_AXI_arvalid                    : in STD_LOGIC;
            JESD204B_AXI_awaddr                     : in STD_LOGIC_VECTOR ( 31 downto 0 );
            JESD204B_AXI_awburst                    : in STD_LOGIC_VECTOR ( 1 downto 0 );
            JESD204B_AXI_awcache                    : in STD_LOGIC_VECTOR ( 3 downto 0 );
            JESD204B_AXI_awlen                      : in STD_LOGIC_VECTOR ( 7 downto 0 );
            JESD204B_AXI_awlock                     : in STD_LOGIC_VECTOR ( 0 to 0 );
            JESD204B_AXI_awprot                     : in STD_LOGIC_VECTOR ( 2 downto 0 );
            JESD204B_AXI_awqos                      : in STD_LOGIC_VECTOR ( 3 downto 0 );
            JESD204B_AXI_awready                    : out STD_LOGIC;
            JESD204B_AXI_awregion                   : in STD_LOGIC_VECTOR ( 3 downto 0 );
            JESD204B_AXI_awsize                     : in STD_LOGIC_VECTOR ( 2 downto 0 );
            JESD204B_AXI_awvalid                    : in STD_LOGIC;
            JESD204B_AXI_bready                     : in STD_LOGIC;
            JESD204B_AXI_bresp                      : out STD_LOGIC_VECTOR ( 1 downto 0 );
            JESD204B_AXI_bvalid                     : out STD_LOGIC;
            JESD204B_AXI_rdata                      : out STD_LOGIC_VECTOR ( 31 downto 0 );
            JESD204B_AXI_rlast                      : out STD_LOGIC;
            JESD204B_AXI_rready                     : in STD_LOGIC;
            JESD204B_AXI_rresp                      : out STD_LOGIC_VECTOR ( 1 downto 0 );
            JESD204B_AXI_rvalid                     : out STD_LOGIC;
            JESD204B_AXI_wdata                      : in STD_LOGIC_VECTOR ( 31 downto 0 );
            JESD204B_AXI_wlast                      : in STD_LOGIC;
            JESD204B_AXI_wready                     : out STD_LOGIC;
            JESD204B_AXI_wstrb                      : in STD_LOGIC_VECTOR ( 3 downto 0 );
            JESD204B_AXI_wvalid                     : in STD_LOGIC;
            ------------------------------------------------------------------------------------------
            -- DUMP Interface
            ------------------------------------------------------------------------------------------
            --        DUMP_BFN_STRB_OUT                       : out std_logic_vector(1 downto 0);
            --        DUMP_DVLD_OUT                           : out std_logic_vector(1 downto 0); -- Dump valid
            --        DUMP_DATA_OUT                           : out std_logic_array32(1 downto 0); -- Dump data
            DUMP_BFN_STRB_OUT                       : out std_logic;
            DUMP_DVLD_OUT                           : out std_logic; -- Dump valid
            DUMP_DATA_OUT                           : out std_logic_vector(31 downto 0); -- Dump data

            ------------------------------------------------------------------------------------------
            -- DSP-TOP IF
            ------------------------------------------------------------------------------------------
            --DL data
            --        DL_SYNC_IN                              : in  std_logic_vector(TX_ANT_NUM-1 downto 0);
            --        DL_I_EVEN_IN                            : in  std_logic_array16(TX_ANT_NUM-1 downto 0);
            --        DL_Q_EVEN_IN                            : in  std_logic_array16(TX_ANT_NUM-1 downto 0);
            --        DL_I_ODD_IN                             : in  std_logic_array16(TX_ANT_NUM-1 downto 0);
            --        DL_Q_ODD_IN                             : in  std_logic_array16(TX_ANT_NUM-1 downto 0);
            DL_I_IN                                 : in  std_logic_array16((TX_ANT_NUM-1) downto 0);
            DL_Q_IN                                 : in  std_logic_array16((TX_ANT_NUM-1) downto 0);

            --FB data
            FB_SYNC_OUT                             : out std_logic_vector(FB_PATH_NUM-1 downto 0);
            FB_I_OUT                                : out std_logic_array16(FB_PATH_NUM-1 downto 0);
            FB_Q_OUT                                : out std_logic_array16(FB_PATH_NUM-1 downto 0);
            --        FB_I_EVEN_OUT                           : out std_logic_array16(FB_PATH_NUM-1 downto 0);
            --        FB_Q_EVEN_OUT                           : out std_logic_array16(FB_PATH_NUM-1 downto 0);
            --        FB_I_ODD_OUT                            : out std_logic_array16(FB_PATH_NUM-1 downto 0);
            --        FB_Q_ODD_OUT                            : out std_logic_array16(FB_PATH_NUM-1 downto 0);

            --UL data
            UL_SYNC_OUT                             : out std_logic_vector((RX_ANT_NUM-1) downto 0);
            UL_VALID_OUT                            : out std_logic;
            UL_I_OUT                                : out std_logic_array16((RX_ANT_NUM-1) downto 0); --245.76 Mhz / 122.88Msps
            UL_Q_OUT                                : out std_logic_array16((RX_ANT_NUM-1) downto 0);

            -- TEST
            --        TEST_DATA_IN                            : in  std_logic_array32(1 downto 0);
            TEST_DATA_IN                            : in  std_logic_vector(31 downto 0);
            --        TEST_DENB_OUT                           : out std_logic_vector(1 downto 0);
            TEST_DENB_OUT                           : out std_logic;

            -- Flag gen
            SIG_SUS_DLFLAG_OUT                      : out std_logic_vector((JESD_TX_LINK_NUM-1) downto 0);
            SIG_SUS_FBFLAG_OUT                      : out std_logic_vector((JESD_FB_LINK_NUM-1) downto 0);
            SIG_SUS_ULFLAG_OUT                      : out std_logic_vector((JESD_RX_LINK_NUM-1) downto 0);

            -- TDD/BFN
            DL_SSB_STRB_IN                          : in  std_logic;
            DL_SSB_STRB_OUT                         : out std_logic;
            DL_BFN_STRB_IN                          : in  std_logic;
            DL_BFN_STRB_OUT                         : out std_logic;
            DL_TDD_IN                               : in  std_logic;
            DL_TDD_OUT                              : out std_logic;
            DL_BCF_ENB_IN                           : in  std_logic;
            DL_BCF_ENB_OUT                          : out std_logic;

            UL_BFN_STRB_IN                          : in  std_logic;
            UL_BFN_STRB_OUT                         : out std_logic;
            UL_TDD_IN                               : in  std_logic;
            UL_TDD_OUT                              : out std_logic;
            UL_BCF_ENB_IN                           : in  std_logic;
            UL_BCF_ENB_OUT                          : out std_logic;

            FB_SSB_STRB_IN                          : in  std_logic;
            FB_SSB_STRB_OUT                         : out std_logic;
            FB_BFN_STRB_IN                          : in  std_logic;
            FB_BFN_STRB_OUT                         : out std_logic;
            FB_TDD_IN                               : in  std_logic;
            FB_TDD_OUT                              : out std_logic;

            --        DBG_SIG_OUT                             : out std_logic_array32(1 downto 0)

            --add sangjun1.ryu 200507
            UL_BFN_STRB_OUT_TP_SOURCE               : out std_logic;
            TP_UL_PATTERN_PATH_SEL_IN               : in std_logic_vector(15 downto 0);
            TP_UL_PATTERN_BFN_SEL_DCIF_IN           : in std_logic;

            TP_GEN_BFN_DCIF_IN                      : in std_logic;
            TP_GEN_GAIN_IDATA_DCIF_IN               : in std_logic_vector(15 downto 0);
            TP_GEN_GAIN_QDATA_DCIF_IN               : in std_logic_vector(15 downto 0)    );
    end component;

    component MISC_TOP is
        port(
            --CPU_TOP
            CLK_CPUIF                       : in  std_logic                                     ;
            RST_CPUIF                       : in  std_logic                                     ;

            AXI_TIMEOUT_IN                  : in  std_logic                                     ;

            DMA_RDCLK_OUT                   : out std_logic                                     ;
            DMA_RDRDY_IN                    : in  std_logic                                     ;
            DMA_RDEPT_IN                    : in  std_logic                                     ;
            DMA_RDFULL_IN                   : in  std_logic                                     ;
            DMA_RDEN_OUT                    : out std_logic                                     ;
            DMA_RDATA_IN                    : in  std_logic_vector(31 downto 0)                 ;

            DMA_WRCLK_OUT                   : out std_logic                                     ;
            DMA_WRRDY_IN                    : in  std_logic                                     ;
            DMA_WREPT_IN                    : in  std_logic                                     ;
            DMA_WRFULL_IN                   : in  std_logic                                     ;
            DMA_WREN_OUT                    : out std_logic                                     ;
            DMA_WDATA_OUT                   : out std_logic_vector(31 downto 0)                 ;

            --CPUIF_TOP
            ADDR_CPUIF_IN                   : in  std_logic_vector(15 downto 0)                 ;
            RDATA_CPUIF_OUT                 : out std_logic_vector(31 downto 0)                 ;
            RDEN_CPUIF_IN                   : in  std_logic                                     ;
            RDVAL_CPUIF_OUT                 : out std_logic                                     ;
            WDATA_CPUIF_IN                  : in  std_logic_vector(31 downto 0)                 ;
            WREN_CPUIF_IN                   : in  std_logic                                     ;

            --SYSCTRL_TOP
            TDD_CTRL_IN                     : in  std_logic_vector(31 downto 0)                 ;
            CLK_MISC0                       : in  std_logic                                     ; --  25.00 MHz
            CLK_MISC1                       : in  std_logic                                     ; -- 100.00 MHz
            CLK_MISC2                       : in  std_logic                                     ; -- 150.00 MHz
            CLK_MISC3                       : in  std_logic                                     ; -- 200.00 MHz
            RST_MISC                        : in  std_logic                                     ;

            CLK_SYS                         : in  std_logic                                     ; --  30.72 MHz
            CLK_SYSX2                       : in  std_logic                                     ; --  61.44 MHz
            CLK_SYSX3                       : in  std_logic                                     ; --  92.16 MHz
            CLK_SYSX4                       : in  std_logic                                     ; -- 122.88 MHz
            CLK_SYSX5                       : in  std_logic                                     ; -- 153.60 MHz
            CLK_SYSX6                       : in  std_logic                                     ; -- 184.32 MHz
            CLK_SYSX8                       : in  std_logic                                     ; -- 245.76 MHz
            CLK_SYSX10                      : in  std_logic                                     ; -- 307.20 MHz
            CLK_SYSX12                      : in  std_logic                                     ; -- 368.64 MHz
            CLK_SYSX16                      : in  std_logic                                     ; -- 491.52 MHz
            CLK_SYSX20                      : in  std_logic                                     ; -- 614.14 MHz

            TCXO_CLK_X1                     : in std_logic;
            TCXO_CLK_X4                     : in std_logic;
            TCXO_CLK_X8                     : in std_logic;
            PWM_FROM_FPGA_OUT               : out std_logic;
            RX_BFN_STRB_SYSCTRL_IN          : in  std_logic_vector(CPRI_NUM-1 downto 0)         ; -- connected to SADUMP
            TX_BFN_STRB_SYSCTRL_IN          : in  std_logic_vector(CPRI_NUM-1 downto 0)         ; -- connected to SADUMP
            RX_BFN_STRB_CPRI_IN             : in  std_logic_vector(CPRI_NUM-1 downto 0)         ; -- connected to SADUMP

            --CPRIPHY_TOP
            SIG_SUS_FLAG_CPRIPHY_IN         : in  std_logic_vector(CPRI_NUM-1 downto 0)         ; -- connected to SADUMP
            SIG_SUS_DLOFF_CPRIPHY_OUT       : out std_logic_vector(CPRI_NUM-1 downto 0)         ; -- connected to SADUMP

            DUMP_BFN_STRB_CPRIPHY_IN        : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP
            DUMP_DATA_CPRIPHY_IN            : in  std_logic_array32(1 downto 0)                 ; -- connected to SADUMP
            DUMP_DVLD_CPRIPHY_IN            : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP
            TEST_DATA_CPRIPHY_OUT           : out std_logic_array32(1 downto 0)                 ; -- connected to SADUMP
            TEST_ENB_CPRIPHY_IN             : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP

            --CPRI_TOP
            SIG_SUS_FLAG_CPRI_IN            : in  std_logic_vector(CPRI_NUM-1 downto 0)         ; -- connected to SADUMP
            IS_MASTER_CPRI_IN               : in  std_logic_vector(CPRI_NUM-1 downto 0)         ; -- connected to SADUMP

            DUMP_BFN_STRB_CPRI_IN           : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP
            DUMP_DATA_CPRI_IN               : in  std_logic_array32(1 downto 0)                 ; -- connected to SADUMP
            DUMP_DVLD_CPRI_IN               : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP
            TEST_DATA_CPRI_OUT              : out std_logic_array32(1 downto 0)                 ; -- connected to SADUMP
            TEST_ENB_CPRI_IN                : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP

            --SBIF_TOP
            SIG_SUS_FLAG_SBIF_IN            : in  std_logic_vector(SBIF_NUM-1 downto 0)         ; -- connected to SADUMP
            SIG_SUS_DLOFF_SBIF_OUT          : out std_logic_vector(SBIF_NUM-1 downto 0)         ; -- connected to SADUMP

            DUMP_BFN_STRB_SBIF_IN           : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP
            DUMP_DATA_SBIF_IN               : in  std_logic_array32(1 downto 0)                 ; -- connected to SADUMP
            DUMP_DVLD_SBIF_IN               : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP
            TEST_DATA_SBIF_OUT              : out std_logic_array32(1 downto 0)                 ; -- connected to SADUMP
            TEST_ENB_SBIF_IN                : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP

            --SBIFPHY_TOP
            SIG_SUS_FLAG_SBIFPHY_IN         : in  std_logic_vector(SBIF_NUM-1 downto 0)         ; -- connected to SADUMP
            SIG_SUS_DLOFF_SBIFPHY_OUT       : out std_logic_vector(SBIF_NUM-1 downto 0)         ; -- connected to SADUMP

            DUMP_BFN_STRB_SBIFPHY_IN        : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP
            DUMP_DATA_SBIFPHY_IN            : in  std_logic_array32(1 downto 0)                 ; -- connected to SADUMP
            DUMP_DVLD_SBIFPHY_IN            : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP
            TEST_DATA_SBIFPHY_OUT           : out std_logic_array32(1 downto 0)                 ; -- connected to SADUMP
            TEST_ENB_SBIFPHY_IN             : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP

            -- BBCTRL_TOP
            SIG_SUS_FLAG_BBCTRL_IN          : in  std_logic_vector(DL_BBIQARY_NUM-1 downto 0)   ; -- connected to SADUMP
            SIG_SUS_DLOFF_BBCTRL_OUT        : out std_logic_vector(CPRI_NUM-1 downto 0)         ; -- connected to SADUMP

            DUMP_BFN_STRB_BBCTRL_IN         : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP
            DUMP_DATA_BBCTRL_IN             : in  std_logic_array32(1 downto 0)                 ; -- connected to SADUMP
            DUMP_DVLD_BBCTRL_IN             : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP
            TEST_DATA_BBCTRL_OUT            : out std_logic_array32(1 downto 0)                 ; -- connected to SADUMP
            TEST_ENB_BBCTRL_IN              : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP

            -- DSP_TOP
            SIG_SUS_FLAG_DSP_IN             : in  std_logic_vector(TX_ANT_NUM-1 downto 0)       ; -- connected to SADUMP
            SIG_SUS_DLOFF_DSP_OUT           : out std_logic_vector(TX_ANT_NUM-1 downto 0)       ; -- connected to SADUMP

            DUMP_BFN_STRB_DSP_IN            : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP
            DUMP_DATA_DSP_IN                : in  std_logic_array32(1 downto 0)                 ; -- connected to SADUMP
            DUMP_DVLD_DSP_IN                : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP
            TEST_DATA_DSP_OUT               : out std_logic_array32(1 downto 0)                 ; -- connected to SADUMP
            TEST_ENB_DSP_IN                 : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP

            DL_IQ_ISZERO_IN                 : in  std_logic_vector(TX_ANT_NUM-1 downto 0)       ; -- connected to SADUMP
            DL_CLK_ISZERO_IN                : in  std_logic_vector(TX_ANT_NUM-1 downto 0)       ; -- connected to SADUMP

            -- DCIF_TOP
            SIG_SUS_FBFLAG_DCIF_IN          : in  std_logic_vector(JESD_FB_LINK_NUM-1 downto 0) ; -- connected to SADUMP
            SIG_SUS_ULFLAG_DCIF_IN          : in  std_logic_vector(JESD_RX_LINK_NUM-1 downto 0) ; -- connected to SADUMP
            SIG_SUS_DLFLAG_DCIF_IN          : in  std_logic_vector(JESD_TX_LINK_NUM-1 downto 0) ; -- connected to SADUMP

            DUMP_BFN_STRB_DCIF_IN           : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP
            DUMP_DATA_DCIF_IN               : in  std_logic_array32(1 downto 0)                 ; -- connected to SADUMP
            DUMP_DVLD_DCIF_IN               : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP
            TEST_DATA_DCIF_OUT              : out std_logic_array32(1 downto 0)                 ; -- connected to SADUMP
            TEST_ENB_DCIF_IN                : in  std_logic_vector( 1 downto 0)                 ; -- connected to SADUMP

            DL_BFN_STRB_DCIF_IN             : in  std_logic                                     ;
            DL_SSB_STRB_DCIF_IN             : in  std_logic                                     ;
            DL_TDD_DCIF_IN                  : in  std_logic                                     ;
            DL_BFN_STRB_1PPS_OUT            : out std_logic                                     ;

            UL_BFN_STRB_1PPS_IN             : in  std_logic                                     ;
            UL_TDD_1PPS_IN                  : in  std_logic                                     ;
            UL_BFN_STRB_DCIF_OUT            : out std_logic                                     ;
            UL_TDD_DCIF_OUT                 : out std_logic                                     ;

            FB_BFN_STRB_DCIF_OUT            : out std_logic                                     ;
            FB_SSB_STRB_DCIF_OUT            : out std_logic                                     ;
            FB_TDD_DCIF_OUT                 : out std_logic                                     ;

            -- SIG_SUS_TOP
            SIG_SUS_DLOFF_OTRX_OUT          : out std_logic                                     ;
            EXT_SYSPLL_LOCK_IN              : in  std_logic                                     ;
            INT_SYSPLL_LOCK_IN              : in  std_logic                                     ;
            VSS_RMT_RST_CPRI_IN             : in  std_logic                                     ;
            HWWDT_FLAG_IN                   : in  std_logic                                     ;
            SWWDT_FLAG_IN                   : in  std_logic                                     ;
            --------------------------------
            -- Feedback Switch
            --------------------------------
            FBSW_START_TRIG_OUT             : out std_logic;
            FBSW_CNT_245P76M_OUT            : out std_logic_vector(4 downto 0)                  ;
            FBSW_AUTO_MODE_DONE_OUT         : out std_logic_vector(RFIC_NUM-1 downto 0)         ;
            FBSW_PWR_MSR_UPT_OUT            : out std_logic                                     ; -- tick per every 10ms.  clock domain : 122.88MHz
            -- new port
            SSB_OFFSET                      : in  std_logic_vector(1 downto 0)                  ;
            SYNC_1PPS_10MS_IN               : in  std_logic;
            SYNC_1PPS_SFN_IN                : in  std_logic_vector(3 downto 0);

            CPRI_CONN_OK                    : in  std_logic                                     ;
            SSB_EXIST_OUT                   : out std_logic                                     ;
            FBSW_SC_PATH_SEL_EN_OUT         : out std_logic                                     ;
            FBSW_SC_PATH_SEL_OUT            : out std_logic_vector(4 downto 0);
            PWR_MSR_FB_SYNC_OUT             : out std_logic                                     ;
            PWR_MSR_EN_OUT                  : out std_logic                                     ;
            --------------------------------
            -- Ports on Schemetics
            -------------------------------    -
            --------------------------------
            -- RF TX Switch Control
            --------------------------------

            RFIC_TX_EN_OUT                  : out std_logic                                     ;
            RFIC_FB_EN_0_OUT                : out std_logic                                     ;
            RFIC_FB_EN_1_OUT                : out std_logic                                     ;
            RFIC_FB2_TX_SEL0_OUT            : out std_logic                                     ;
            RFIC_FB3_TX_SEL0_OUT            : out std_logic                                     ;
            RFIC_FB2_TX_SEL1_OUT            : out std_logic                                     ;
            RFIC_FB3_TX_SEL1_OUT            : out std_logic                                     ;

            RFIC_RX_EN_OUT                  : out std_logic                                     ;
            CTRL_PATH1_OUT                  : out std_logic                                     ;
            CTRL_PATH2_OUT                  : out std_logic                                     ;
            ENA_PATH12_OUT                  : out std_logic                                     ;
            CTRL_PATH3_OUT                  : out std_logic                                     ;
            CTRL_PATH4_OUT                  : out std_logic                                     ;
            ENA_PATH34_OUT                  : out std_logic                                     ;

            TX_SW_0_OUT                     : out std_logic                                     ;
            TX_SW_1_OUT                     : out std_logic                                     ;
            TX_SW_2_OUT                     : out std_logic                                     ;
            TX_SW_3_OUT                     : out std_logic                                     ;
            RF_RX_SW_CTRL                   : out std_logic;

            --    RX_SW_OUT                       : out std_logic;
            TX_RF_LDO_ONOFF                 : out std_logic;
            RX_RF_LDO_ONOFF                 : out std_logic;
            FPGA_PSB_AMP_48V_ONOFF          : out std_logic;
            --TX_B13_A_SW_OUT                 : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            --TX_B13_B_SW_OUT                 : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            --TX_B13_C_SW_OUT                 : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            --TX_B13_D_SW_OUT                 : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use

            ISPPAC_CTRL_OUT                 : out std_logic_vector(2 downto 0)                  ; -- ZUFPGA : use       / KUFPGA : don't use
            UDA_IN                          : in  std_logic_vector(3 downto 0)                  ; -- ZUFPGA : use       / KUFPGA : don't use

            --B13_FBSW_CTRL_PATH1_OUT         : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            --B13_FBSW_CTRL_PATH2_OUT         : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            --B13_FBSW_ENA_PATH12_OUT         : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            --B13_FBSW_CTRL_PATH3_OUT         : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            --B13_FBSW_CTRL_PATH4_OUT         : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            --B13_FBSW_ENA_PATH34_OUT         : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use

            B13_AMP_EN_OUT                  : out std_logic_vector(TX_ANT_NUM-1 downto 0)       ; -- ZUFPGA : use       / KUFPGA : use

            OOK_B13_A_TXIN                  : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use
            OOK_B13_A_RXOUT                 : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use
            OOK_B13_A_DIR_IN                : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use
            OOK_B13_A_DIRMD1_OUT            : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use
            OOK_B13_A_DIRMD2_OUT            : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use
            BIAS_T_B13_A_ONOFF_OUT          : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use

            OOK_B13_C_TXIN                  : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use
            OOK_B13_C_RXOUT                 : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use
            OOK_B13_C_DIR_IN                : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use
            OOK_B13_C_DIRMD1_OUT            : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use
            OOK_B13_C_DIRMD2_OUT            : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use
            BIAS_T_B13_C_ONOFF_OUT          : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use

            LED_CTRL_SYSCTRL_IN             : in  std_logic_array4(LED_NUM-1 downto 0)          ;
            --    LED_RED_OUT                     : out std_logic_vector(LED_NUM-1 downto 0)          ; -- ZUFPGA : use       / KUFPGA : don't use
            --    LED_GREEN_OUT                   : out std_logic_vector(LED_NUM-1 downto 0)          ; -- ZUFPGA : use       / KUFPGA : don't use

            LED_ANT_RED                     : out std_logic;
            LED_ANT_BLUE                    : out std_logic;
            LED_ANT_GREEN                   : out std_logic;

            LED_FAN_RED                     : out std_logic;
            LED_FAN_BLUE                    : out std_logic;
            LED_FAN_GREEN                   : out std_logic;

            LED_OPT_RED                     : out std_logic;
            LED_OPT_BLUE                    : out std_logic;
            LED_OPT_GREEN                   : out std_logic;

            LED_SYS_RED                     : out std_logic;
            LED_SYS_BLUE                    : out std_logic;
            LED_SYS_GREEN                   : out std_logic;

            UDE_ETH_nRESET                  : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use

            EXT_EN_5p0V_OUT                 : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use
            RET_ONOFF_OUT                   : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use

            RET_UART_TXD_OUT                : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use
            RET_DE_OUT                      : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use
            RET_nRE_OUT                     : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use
            RET_UART_RXD_IN                 : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use

            UART0_MP_IN                     : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use
            UART0_MP_OUT                    : out  std_logic                                    ; -- ZUFPGA : use       / KUFPGA : don't use
            UART1_MP_IN                     : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use
            UART1_MP_OUT                    : out  std_logic                                    ; -- ZUFPGA : use       / KUFPGA : don't use
            UART2_MP_IN                     : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use
            UART2_MP_OUT                    : out  std_logic                                    ; -- ZUFPGA : use       / KUFPGA : don't use

            CLK_PLL_LOS_IN                  : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use
            CLK_PLL_LD_IN                   : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            CLK_PLL_LD_RSVD_IN              : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            CLK_PLL_RESET_OUT               : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use

            UV_ALARM_IN                     : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            TRX_DC_NORMAL_IN                : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            FPGA_PWR_STATUS_IN              : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            PWR55_NORMAL_IN                 : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : dont' use

            PG_0P85V_MFPGA                  : in  std_logic;                          -- AK1
            PG_1P8V_MFPGA                   : in  std_logic;                          -- AL2
            PG_0P85V_MFPGA_PSMGT            : in  std_logic;                          -- AL3
            PG_1P2V_MFPGA_PSPLL             : in  std_logic;                          -- AN1
            PG_1P8V_MFPGA_MGT               : in  std_logic;                          -- AM1
            PG_1P2V_DDR4                    : in  std_logic;                          -- AP3
            PG_3P3V_CLK                     : in  std_logic;                          -- AN3
            PG_3P3V                         : in  std_logic;                          -- AP2
            PG_0P9V_MFPGA_MGT               : in  std_logic;                          -- AN2
            PG_1P2V_MFPGA_MGT               : in  std_logic;                          -- AP1
            PG_1P0V_RFIC0_DIGITAL           : in  std_logic;                          -- AM3
            PG_1P3V_RFIC0_ANALOG            : in  std_logic;                          -- AK4
            PG_1p8V_RFIC_VDD                : in  std_logic;

            AMP_AMC_RST1_OUT                : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            AMP_AMC_RST2_OUT                : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use

            --    RFIC_B13_TX_EN_OUT              : out std_logic_vector(RFIC_NUM-1 downto 0)         ; -- ZUFPGA : use       / KUFPGA : use
            RFIC_B13_RESETB_OUT             : out std_logic_vector(RFIC_NUM-1 downto 0)         ; -- ZUFPGA : use       / KUFPGA : use
            RFIC_TRI_ENB                    : out std_logic_vector(RFIC_NUM-1 downto 0)         ;
            --RFIC_B13_GP_INTERRUPT_IN        : in  std_logic_vector(RFIC_NUM-1 downto 0)         ; -- ZUFPGA : use       / KUFPGA : use
            RFIC_B13_GP_INTERRUPT_IN        : in  std_logic_vector(1 downto 0)         ; -- ZUFPGA : use       / KUFPGA : use

            RFIC_GPIO_IN                    : in  std_logic_array19(RFIC_NUM-1 downto 0)        ; -- ZUFPGA : use       / KUFPGA : use
            RFIC_GPIO_OUT                   : out std_logic_array19(RFIC_NUM-1 downto 0)        ; -- ZUFPGA : use       / KUFPGA : use

            RFIC_AB_EN_OUT                  : out std_logic_vector(2 downto 0)                  ; -- ZUFPGA : don't use / KUFPGA : use
            RF_B13_AB_EN_OUT                : out std_logic                                     ; -- ZUFPGA : don't use / KUFPGA : use
            RF_B13_CD_EN_OUT                : out std_logic                                     ; -- ZUFPGA : don't use / KUFPGA : use

            -- RFIC DMA
            RFIC_SPI_BUF_RST                : out std_logic_vector(RFIC_NUM-1 downto 0);
            RFIC_SPI_BUF_CLK                : out std_logic_vector(RFIC_NUM-1 downto 0);
            RFIC_SPI_BUF_ADDR               : out std_logic_array32(RFIC_NUM-1 downto 0);
            RFIC_SPI_BUF_DIN                : out std_logic_array32(RFIC_NUM-1 downto 0);
            RFIC_SPI_BUF_DOUT               : in  std_logic_array32(RFIC_NUM-1 downto 0);
            RFIC_SPI_BUF_EN                 : out std_logic_vector(RFIC_NUM-1 downto 0);
            RFIC_SPI_BUF_WE                 : out std_logic_array4(RFIC_NUM-1 downto 0);

            RFIC_SPI_IP_SS                  : in  std_logic_vector(RFIC_NUM-1 downto 0);
            RFIC_SPI_IP_SCLK                : in  std_logic_vector(RFIC_NUM-1 downto 0);
            RFIC_SPI_IP_MOSI                : in  std_logic_vector(RFIC_NUM-1 downto 0);
            RFIC_SPI_IP_MISO                : out std_logic_vector(RFIC_NUM-1 downto 0);

            RFIC_SPI_RTL_SS                 : out std_logic_vector(RFIC_NUM-1 downto 0);
            RFIC_SPI_RTL_SCLK               : out std_logic_vector(RFIC_NUM-1 downto 0);
            RFIC_SPI_RTL_MOSI               : out std_logic_vector(RFIC_NUM-1 downto 0);
            RFIC_SPI_RTL_MISO               : in  std_logic_vector(RFIC_NUM-1 downto 0);

            KUFPGA_SIG_SUSPENSION_OUT       : out std_logic_vector(1 downto 0)                  ; -- ZUFPGA : RESERVED  / KUFPGA : RESERVED
            KUFPGA_FUNCTION_FAIL_IN         : in  std_logic                                     ; -- ZUFPGA :  IN       / KUFPGA :  OUT
            KUFPGA_RESET_OUT                : out std_logic                                     ; -- ZUFPGA :  OUT      / KUFPGA :  IN
            FUNCTION_FAIL_OUT               : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use

            --------------------------------
            -- RX Attenuation
            --------------------------------
            RXATT_B13_AB_CLK_OUT             : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            RXATT_B13_AB_DI_OUT              : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            RXATT_B13_A_LE_OUT               : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            RXATT_B13_B_LE_OUT               : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use

            RXATT_B13_CD_CLK_OUT             : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            RXATT_B13_CD_DI_OUT              : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            RXATT_B13_C_LE_OUT               : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            RXATT_B13_D_LE_OUT               : out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use

            TXATT_B13_AB_DI_OUT                 : out   std_logic;
            TXATT_B13_AB_CLK_OUT                : out   std_logic;
            TXATT_B13_A_LE_OUT                  : out   std_logic;
            TXATT_B13_B_LE_OUT                  : out   std_logic;

            TXATT_B13_CD_DI_OUT                 : out   std_logic;
            TXATT_B13_CD_CLK_OUT                : out   std_logic;
            TXATT_B13_C_LE_OUT                  : out   std_logic;
            TXATT_B13_D_LE_OUT                  : out   std_logic;
            --------------------------------
            -- XADC monitoring
            --------------------------------
            RET_MON_N_IN                    : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use
            RET_MON_P_IN                    : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use

            RET_CURRENT_MON_N_IN            : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use
            RET_CURRENT_MON_P_IN            : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use

            B13_LNA_A_CURRENT_SENSOR_N_IN   : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            B13_LNA_A_CURRENT_SENSOR_P_IN   : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            B13_LNA_B_CURRENT_SENSOR_N_IN   : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            B13_LNA_B_CURRENT_SENSOR_P_IN   : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            B13_LNA_C_CURRENT_SENSOR_N_IN   : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            B13_LNA_C_CURRENT_SENSOR_P_IN   : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            B13_LNA_D_CURRENT_SENSOR_N_IN   : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            B13_LNA_D_CURRENT_SENSOR_P_IN   : in  std_logic                                     ; -- ZUFPGA : use       / KUFPGA : use
            E_MFPGA_PSU_I2C_SW_RST          : out std_logic
        );
    end component;

    -- SYSCTRL-TOP Moduel Interface Signals
    signal clk_sys                               : std_logic;                                     -- to all each modules, System Clock :  30.72 MHz
    signal clk_sysx2                             : std_logic;                                     -- to all each modules,  2x(CLK_SYS) :  61.44 MHz
    signal clk_sysx3                             : std_logic;                                     -- to all each modules,  3x(CLK_SYS) :  92.16 MHz
    signal clk_sysx4                             : std_logic;                                     -- to all each modules,  4x(CLK_SYS) : 122.88 MHz
    signal clk_sysx5                             : std_logic;                                     -- to all each modules,  5x(CLK_SYS) : 153.60 MHz
    signal clk_sysx6                             : std_logic;                                     -- to all each modules,  6x(CLK_SYS) : 184.32 MHz
    signal clk_sysx8                             : std_logic;                                     -- to all each modules,  8x(CLK_SYS) : 245.76 MHz
    signal clk_sysx10                            : std_logic;                                     -- to all each modules, 10x(CLK_SYS) : 307.20 MHz
    signal clk_sysx12                            : std_logic;                                     -- to all each modules, 12x(CLK_SYS) : 368.64 MHz
    signal clk_sysx16                            : std_logic;                                     -- to all each modules, 16x(CLK_SYS) : 491.52 MHz
    signal clk_sysx20                            : std_logic;                                     -- to all each modules, 20x(CLK_SYS) : 614.40 MHz

    signal clk_tcxo_x1                           : std_logic;
    signal clk_tcxo_x4                           : std_logic;
    signal clk_tcxo_x8                           : std_logic;

    signal clk_sbif                              : std_logic_vector(PIM_SBIF_NUM-1 downto 0);        -- to SBIFPHY_TOP
    signal clk_sbifxh                            : std_logic_vector(PIM_SBIF_NUM-1 downto 0);        -- to SBIFPHY_TOP
    signal clk_sbifx2                            : std_logic_vector(PIM_SBIF_NUM-1 downto 0);        -- to SBIFPHY_TOP

    signal rst_iqcomp                            : std_logic_vector(IQCOMP_NUM-1 downto 0);       -- to CPRI_TOP
    signal rst_ethmux                            : std_logic;                                     -- to CPRI_TOP
    signal clk_mii                               : std_logic;                                     -- to CPRI_TOP
    signal clk_miix2                             : std_logic;                                     -- to CPRI_TOP
    signal clk_miix4                             : std_logic;                                     -- to CPRI_TOP
    signal clk_miix8                             : std_logic;                                     -- to CPRI_TOP

    signal clk_misc0                             : std_logic;                                     -- to MISC-TOP
    signal clk_misc1                             : std_logic;                                     -- to MISC-TOP
    signal clk_misc2                             : std_logic;                                     -- to MISC-TOP
    signal clk_misc3                             : std_logic;                                     -- to MISC-TOP

    signal clk_ook_out                           : std_logic;

    signal ru_id_sysctrl                         : std_logic_vector( 3 downto 0);                 -- to CPRI_TOP
    signal ru_ff_sysctrl                         : std_logic;                                     -- to CPRI_TOP

    signal refclk_sserdes                        : std_logic_vector(SSREF_NUM-1 downto 0);        -- to SBIFPHY_TOP
    signal refclk_cserdes                        : std_logic_vector(CSREF_NUM-1 downto 0);
    signal refclk_oserdes                        : std_logic_vector(EPHY_NUM -1 downto 0);

    signal inner_rx_tdd_sysctrl                  : std_logic;                                     -- MISC-TOP
    signal inner_rx_bfn_strobe_sysctrl           : std_logic;                                     -- MISC-TOP

    signal int_syspll_lock                       : std_logic;                                     -- to all each modules

    signal rst_bbctrl                            : std_logic;                                     -- to BBCTRL-TOP
    signal rst_dduc                              : std_logic;                                     -- to DSP-TOP
    signal rst_cfr                               : std_logic;                                     -- to DSP-TOP
    signal rst_dpd                               : std_logic;                                     -- to DSP-TOP
    signal rst_misc                              : std_logic;                                     -- to MISC-TOP
    signal rst_dcif                              : std_logic;                                     -- to DCIF-TOP

    signal rst_pim                               : std_logic;
    signal rst_pim_sbif                          : std_logic;
    signal rst_pim_sbif_phy                      : std_logic;

    signal rx_bfn_strb_sysctrl                   : std_logic_vector( CPRI_NUM-1 downto 0);        -- to BBCTRL-TOP
    signal rx_bfn_nr_sysctrl                     : std_logic_array12(CPRI_NUM-1 downto 0);        -- to BBCTRL-TOP
    signal rx_tdd_sysctrl                        : std_logic_vector( CPRI_NUM-1 downto 0);        -- to BBCTRL-TOP
    signal tx_bfn_strb_sysctrl                   : std_logic_vector( CPRI_NUM-1 downto 0);        -- to CPRI_TOP/BBCTRL-TOP
    signal tx_bfn_nr_sysctrl                     : std_logic_array12(CPRI_NUM-1 downto 0);        -- to CPRI_TOP/BBCTRL-TOP

    signal tx_bfn_strb_sbif_top                  : std_logic_vector( SBIF_NUM-1 downto 0);        -- to CPRI_TOP/BBCTRL-TOP

    signal refclk_jserdes                        : std_logic_vector(JSREF_NUM-1 downto 0);        -- to DCIF-TOP

    signal hwwdt_flag_sysctrl                    : std_logic;                 -- to MISC-TOP
    signal led_ctrl_sysctrl                      : std_logic_array4(LED_NUM-1 downto 0);          -- to MISC-TOP
    signal tdd_ctrl                              : std_logic_vector(31 downto 0);                 -- to MISC-TOP

    signal vss_rmt_rst_sysctrl                   : std_logic;                                     -- to MISC-TOP

    signal nr_ssb_period_sysctrl                 : std_logic_vector(4 downto 0);
    signal nr_ssb_offset_sysctrl                 : std_logic_vector(3 downto 0);
    signal sector_mode_sysctrl                   : std_logic_vector(1 downto 0);
    signal emtc_sel_sysctrl                      : std_logic_vector(1 downto 0);
    signal rst_cpuif                             : std_logic;                                     -- to all each modules
    signal clk_cpuif                             : std_logic;                                     -- to all each modules

    signal addr_fpga                             : std_logic_vector(19 downto 0);                 -- to CPUIFTOP
    signal wdata_fpga                            : std_logic_vector(31 downto 0);                 -- to CPUIFTOP
    signal rdata_fpga                            : std_logic_vector(31 downto 0);                 -- to CPUIFTOP
    signal cs_fpga                               : std_logic;                                     -- to CPUIFTOP
    signal wren_fpga                             : std_logic;                                     -- to CPUIFTOP
    signal rden_fpga                             : std_logic;                                     -- to CPUIFTOP
    signal clk_50m                               : std_logic;

    signal d_rxprberr_cpu                        : std_logic_vector( 2 downto 0);                 -- to ANNEX_TOP
    signal d_c2c_config_err_cpu                  : std_logic_vector( 2 downto 0);                 -- to ANNEX_TOP
    signal d_c2c_link_status_cpu                 : std_logic_vector( 2 downto 0);                 -- to ANNEX_TOP
    signal d_c2c_multi_bit_err_cpu               : std_logic_vector( 2 downto 0);                 -- to ANNEX_TOP
    signal d_c2c_link_err2_cpu                   : std_logic;                                     -- to ANNEX_TOP
    signal d_gt_pll_lock_cpu                     : std_logic_vector( 2 downto 0);                 -- to ANNEX_TOP
    signal d_ch_up_cpu                           : std_logic_vector( 2 downto 0);                 -- to ANNEX_TOP
    signal d_lane_up_cpu                         : std_logic_vector( 2 downto 0);                 -- to ANNEX_TOP

    signal i_biast0_uart_rxd                     : std_logic;
    signal i_biast0_uart_txd                     : std_logic;
    signal i_biast1_uart_rxd                     : std_logic;
    signal i_biast1_uart_txd                     : std_logic;
    signal i_ret_uart_rxd                        : std_logic;
    signal i_ret_uart_txd                        : std_logic;

    signal dma_rdclk                             : std_logic;
    signal dma_rdata                             : std_logic_vector(31 downto 0);
    signal dma_rdept                             : std_logic;
    signal dma_rdfull                            : std_logic;
    signal dma_rden                              : std_logic;
    signal dma_rdrdy                             : std_logic;

    signal dma_wrclk                             : std_logic;
    signal dma_wdata                             : std_logic_vector(31 downto 0);
    signal dma_wrept                             : std_logic;
    signal dma_wrfull                            : std_logic;
    signal dma_wren                              : std_logic;
    signal dma_wrrdy                             : std_logic;

    -- CPUIFTOP Module Interface Signals
    signal addr_cpuif_sysctrl                    : std_logic_vector( ADDR_WIDTH-1 downto 0);      -- to SYSCTRLTOP
    signal wdata_cpuif_sysctrl                   : std_logic_vector(WDATA_WIDTH-1 downto 0);      -- to SYSCTRLTOP
    signal rdata_cpuif_sysctrl                   : std_logic_vector(RDATA_WIDTH-1 downto 0);      -- to SYSCTRLTOP
    signal wren_cpuif_sysctrl                    : std_logic;                                     -- to SYSCTRLTOP
    signal rden_cpuif_sysctrl                    : std_logic;                                     -- to SYSCTRLTOP
    signal rdval_cpuif_sysctrl                   : std_logic;                                     -- to SYSCTRLTOP

    signal addr_cpuif_ecpriphy                   : std_logic_vector( ADDR_WIDTH-1 downto 0);      -- to ECPRIPHYTOP
    signal wdata_cpuif_ecpriphy                  : std_logic_vector(WDATA_WIDTH-1 downto 0);      -- to ECPRIPHYTOP
    signal rdata_cpuif_ecpriphy                  : std_logic_vector(RDATA_WIDTH-1 downto 0);      -- to ECPRIPHYTOP
    signal wren_cpuif_ecpriphy                   : std_logic;                                     -- to ECPRIPHYTOP
    signal rden_cpuif_ecpriphy                   : std_logic;                                     -- to ECPRIPHYTOP
    signal rdval_cpuif_ecpriphy                  : std_logic;                                     -- to ECPRIPHYTOP

    signal addr_cpuif_cpri                       : std_logic_vector( ADDR_WIDTH-1 downto 0);      -- to ORANTOP
    signal wdata_cpuif_cpri                      : std_logic_vector(WDATA_WIDTH-1 downto 0);      -- to ORANTOP
    signal rdata_cpuif_cpri                      : std_logic_vector(RDATA_WIDTH-1 downto 0);      -- to ORANTOP
    signal wren_cpuif_cpri                       : std_logic;                                     -- to ORANTOP
    signal rden_cpuif_cpri                       : std_logic;                                     -- to ORANTOP
    signal rdval_cpuif_cpri                      : std_logic;                                     -- to ORANTOP

    signal addr_cpuif_lphy_top                   : std_logic_vector( ADDR_WIDTH+4 -1 downto 0) :=(others =>'0');      -- to lphy_topTOP
    signal wdata_cpuif_lphy_top                  : std_logic_vector(WDATA_WIDTH-1 downto 0);      -- to lphy_topTOP
    signal rdata_cpuif_lphy_top                  : std_logic_vector(RDATA_WIDTH-1 downto 0);      -- to lphy_topTOP
    signal wren_cpuif_lphy_top                   : std_logic;                                     -- to lphy_topTOP
    signal rden_cpuif_lphy_top                   : std_logic;                                     -- to lphy_topTOP
    signal rdval_cpuif_lphy_top                  : std_logic;                                     -- to lphy_topTOP

    signal addr_cpuif_bbctrl                     : std_logic_vector( ADDR_WIDTH-1 downto 0);      -- to BBCTRL-TOP
    signal wdata_cpuif_bbctrl                    : std_logic_vector(WDATA_WIDTH-1 downto 0);      -- to BBCTRL-TOP
    signal rdata_cpuif_bbctrl                    : std_logic_vector(RDATA_WIDTH-1 downto 0);      -- to BBCTRL-TOP
    signal wren_cpuif_bbctrl                     : std_logic;                                     -- to BBCTRL-TOP
    signal rden_cpuif_bbctrl                     : std_logic;                                     -- to BBCTRL-TOP
    signal rdval_cpuif_bbctrl                    : std_logic;                                     -- to BBCTRL-TOP

    signal addr_cpuif_dsp                        : std_logic_vector( ADDR_WIDTH-1 downto 0);      -- to DSP-TOP
    signal wdata_cpuif_dsp                       : std_logic_vector(WDATA_WIDTH-1 downto 0);      -- to DSP-TOP
    signal rdata_cpuif_dsp                       : std_logic_vector(RDATA_WIDTH-1 downto 0);      -- to DSP-TOP
    signal wren_cpuif_dsp                        : std_logic;                                     -- to DSP-TOP
    signal rden_cpuif_dsp                        : std_logic;                                     -- to DSP-TOP
    signal rdval_cpuif_dsp                       : std_logic;                                     -- to DSP-TOP

    signal addr_cpuif_dcif                       : std_logic_vector( ADDR_WIDTH-1 downto 0);      -- to DCIF-TOP
    signal wdata_cpuif_dcif                      : std_logic_vector(WDATA_WIDTH-1 downto 0);      -- to DCIF-TOP
    signal rdata_cpuif_dcif                      : std_logic_vector(RDATA_WIDTH-1 downto 0);      -- to DCIF-TOP
    signal wren_cpuif_dcif                       : std_logic;                                     -- to DCIF-TOP
    signal rden_cpuif_dcif                       : std_logic;                                     -- to DCIF-TOP
    signal rdval_cpuif_dcif                      : std_logic;                                     -- to DCIF-TOP

    signal addr_cpuif_misc                       : std_logic_vector( ADDR_WIDTH-1 downto 0);      -- to MISC-TOP
    signal wdata_cpuif_misc                      : std_logic_vector(WDATA_WIDTH-1 downto 0);      -- to MISC-TOP
    signal rdata_cpuif_misc                      : std_logic_vector(RDATA_WIDTH-1 downto 0);      -- to MISC-TOP
    signal wren_cpuif_misc                       : std_logic;                                     -- to MISC-TOP
    signal rden_cpuif_misc                       : std_logic;                                     -- to MISC-TOP
    signal rdval_cpuif_misc                      : std_logic;                                     -- to MISC-TOP

    signal addr_cpuif_sbif                       : std_logic_vector( ADDR_WIDTH-1 downto 0);      -- to SBIF-TOP
    signal wdata_cpuif_sbif                      : std_logic_vector(WDATA_WIDTH-1 downto 0);      -- to SBIF-TOP
    signal rdata_cpuif_sbif                      : std_logic_vector(RDATA_WIDTH-1 downto 0);      -- to SBIF-TOP
    signal wren_cpuif_sbif                       : std_logic;                                     -- to SBIF-TOP
    signal rden_cpuif_sbif                       : std_logic;                                     -- to SBIF-TOP
    signal rdval_cpuif_sbif                      : std_logic;                                     -- to SBIF-TOP

    signal addr_cpuif_pim_sbif                   : std_logic_vector( ADDR_WIDTH-1 downto 0);      -- to PIM_SBIF-TOP
    signal wdata_cpuif_pim_sbif                  : std_logic_vector(WDATA_WIDTH-1 downto 0);      -- to PIM_SBIF-TOP
    signal rdata_cpuif_pim_sbif                  : std_logic_vector(RDATA_WIDTH-1 downto 0);      -- to PIM_SBIF-TOP
    signal wren_cpuif_pim_sbif                   : std_logic;                                     -- to PIM_SBIF-TOP
    signal rden_cpuif_pim_sbif                   : std_logic;                                     -- to PIM_SBIF-TOP
    signal rdval_cpuif_pim_sbif                  : std_logic;                                     -- to PIM_SBIF-TOP

    signal addr_cpuif_sbifphy                    : std_logic_vector( ADDR_WIDTH-1 downto 0);      -- to SBIFPHY-TOP
    signal wdata_cpuif_sbifphy                   : std_logic_vector(WDATA_WIDTH-1 downto 0);      -- to SBIFPHY-TOP
    signal rdata_cpuif_sbifphy                   : std_logic_vector(RDATA_WIDTH-1 downto 0);      -- to SBIFPHY-TOP
    signal wren_cpuif_sbifphy                    : std_logic;                                     -- to SBIFPHY-TOP
    signal rden_cpuif_sbifphy                    : std_logic;                                     -- to SBIFPHY-TOP
    signal rdval_cpuif_sbifphy                   : std_logic;                                     -- to SBIFPHY-TOP

    signal addr_cpuif_pim_sbifphy                : std_logic_vector( ADDR_WIDTH-1 downto 0);      -- to PIM_SBIFPHY-TOP
    signal wdata_cpuif_pim_sbifphy               : std_logic_vector(WDATA_WIDTH-1 downto 0);      -- to PIM_SBIFPHY-TOP
    signal rdata_cpuif_pim_sbifphy               : std_logic_vector(RDATA_WIDTH-1 downto 0);      -- to PIM_SBIFPHY-TOP
    signal wren_cpuif_pim_sbifphy                : std_logic;                                     -- to PIM_SBIFPHY-TOP
    signal rden_cpuif_pim_sbifphy                : std_logic;                                     -- to PIM_SBIFPHY-TOP
    signal rdval_cpuif_pim_sbifphy               : std_logic;                                     -- to PIM_SBIFPHY-TOP

    signal addr_cpuif_annex                      : std_logic_vector( ADDR_WIDTH-1 downto 0);      -- to ANNEX-TOP
    signal wdata_cpuif_annex                     : std_logic_vector(WDATA_WIDTH-1 downto 0);      -- to ANNEX-TOP
    signal rdata_cpuif_annex                     : std_logic_vector(RDATA_WIDTH-1 downto 0);      -- to ANNEX-TOP
    signal wren_cpuif_annex                      : std_logic;                                     -- to ANNEX-TOP
    signal rden_cpuif_annex                      : std_logic;                                     -- to ANNEX-TOP
    signal rdval_cpuif_annex                     : std_logic;                                     -- to ANNEX-TOP

    signal addr_cpuif_dpd                        : std_logic_vector( ADDR_WIDTH-1 downto 0);      -- to DSP-TOP
    signal wdata_cpuif_dpd                       : std_logic_vector(WDATA_WIDTH-1 downto 0);      -- to DSP-TOP
    signal rdata_cpuif_dpd                       : std_logic_vector(RDATA_WIDTH-1 downto 0);      -- to DSP-TOP
    signal wren_cpuif_dpd                        : std_logic;                                     -- to DSP-TOP
    signal rden_cpuif_dpd                        : std_logic;                                     -- to DSP-TOP
    signal rdval_cpuif_dpd                       : std_logic;                                     -- to DSP-TOP

    signal hw_watchdog_clr_cpuif                 : std_logic;
    signal dbg_sig_cpuif                         : std_logic_vector(31 downto 0);                 -- to FPGA-TOP

    -- SBIFPHY Module Interface Signals
    signal serdes_rxerr_sbifphy                  : std_logic_array4( SBIF_NUM-1 downto 0);        -- to SBIF-TOP
    signal serdes_rxisk_sbifphy                  : std_logic_array4( SBIF_NUM-1 downto 0);        -- to SBIF-TOP
    signal serdes_rxd_sbifphy                    : std_logic_array32(SBIF_NUM-1 downto 0);        -- to SBIF-TOP

    signal sig_sus_flag_sbifphy                  : std_logic_vector( SBIF_NUM-1 downto 0);        -- to MISC-TOP

    signal dump_bfn_strb_sbifphy                 : std_logic_vector( 1 downto 0);                 -- to MISC-TOP
    signal dump_data_sbifphy                     : std_logic_array32(1 downto 0);                 -- to MISC-TOP
    signal dump_dvld_sbifphy                     : std_logic_vector( 1 downto 0);                 -- to MISC-TOP
    signal test_enb_sbifphy                      : std_logic_vector( 1 downto 0);                 -- to MISC-TOP

    signal dbg_sig_sbifphy                       : std_logic_array32(1 downto 0);                 -- to FPGA-TOP

    -- SBIF Module Interface Signals
    signal serdes_rxcomma_realign_sbif           : std_logic_vector( SBIF_NUM-1 downto 0);        -- to SBIFPHY-TOP
    signal serdes_txisk_sbif                     : std_logic_array4( SBIF_NUM-1 downto 0);        -- to SBIFPHY-TOP
    signal serdes_txd_sbif                       : std_logic_array32(SBIF_NUM-1 downto 0);        -- to SBIFPHY-TOP

    signal rx_bfn_strb_sbif                      : std_logic_vector( CPRI_NUM-1 downto 0);        -- to CPRI-TOP

    signal tx_i_sbif                             : std_logic_array16(CPRI_NUM-1 downto 0);
    signal tx_q_sbif                             : std_logic_array16(CPRI_NUM-1 downto 0);

    signal comp_ce_sbif                          : std_logic_vector( CPRI_NUM-1 downto 0);        -- to CPRI-TOP

    signal sig_sus_flag_sbif                     : std_logic_vector( SBIF_NUM-1 downto 0);        -- to MISC-TOP
    signal dump_bfn_strb_sbif                    : std_logic_vector( 1 downto 0);                 -- to MISC-TOP
    signal dump_data_sbif                        : std_logic_array32(1 downto 0);                 -- to MISC-TOP
    signal dump_dvld_sbif                        : std_logic_vector( 1 downto 0);                 -- to MISC-TOP

    signal test_enb_sbif                         : std_logic_vector( 1 downto 0);                 -- to MISC-TOP

    signal dbg_sig_sbif                          : std_logic_array32( 1 downto 0);                 -- to FPGA-TOP

    -- CPRIPHY Module Interface Signals
    signal serdes_rxisk_cpriphy                  : std_logic_array4(CPRI_NUM-1 downto 0);
    signal serdes_rxd_cpriphy                    : std_logic_array32(CPRI_NUM-1 downto 0);
    signal serdes_rxerr_cpriphy                  : std_logic_array4(CPRI_NUM-1 downto 0);
    signal serdes_txisk_cpri                     : std_logic_array4(CPRI_NUM-1 downto 0);
    signal serdes_txd_cpri                       : std_logic_array32(CPRI_NUM-1 downto 0);
    signal refclk_sel                            : std_logic_vector(3 downto 0);
    signal serdes_rxcomma_realign_cpri           : std_logic_vector(CPRI_NUM-1 downto 0);
    
    signal qplllock                              : std_logic;
    signal qplloutclk                            : std_logic;
    signal qplloutrefclk                         : std_logic;
    signal qpllrefclklost                        : std_logic;
    
    signal dbg_sig_cpriphy                       : std_logic_array32(1 downto 0);
    
    signal sig_sus_flag_cpriphy                  : std_logic_vector(CPRI_NUM-1 downto 0);
    signal sig_sus_dloff_cpriphy                 : std_logic_vector(CPRI_NUM-1 downto 0);
    signal dump_bfn_strb_cpriphy                 : std_logic_vector(1 downto 0);
    signal dump_data_cpriphy                     : std_logic_array32(1 downto 0);
    signal dump_dvld_cpriphy                     : std_logic_vector(1 downto 0);
    signal test_data_cpriphy                     : std_logic_array32(1 downto 0);
    signal test_denb_cpriphy                     : std_logic_vector(1 downto 0);
    
    -- CPRI Module Interface Signals
    signal rx_bfn_strb_cpri                      : std_logic_vector( CPRI_NUM-1 downto 0);        -- to SYSCTRL-TOP
    signal rx_bfn_nr_cpri                        : std_logic_array12(CPRI_NUM-1 downto 0);        -- to SYSCTRL-TOP
    
    signal tx_bfn_strb_sbif                      : std_logic_vector( CPRI_NUM-1 downto 0);        -- to SBIF_TOP
    
    signal comp_i_iqcomp                         : std_logic_array16(CPRI_NUM-1 downto 0);        -- to SBIF_TOP
    signal comp_q_iqcomp                         : std_logic_array16(CPRI_NUM-1 downto 0);        -- to SBIF_TOP
    
    signal vss_rmt_rst_cpri                      : std_logic_vector(CPRI_NUM-1 downto 0);         -- to SYSCTRL-TOP/BBCTRL-TOP
    signal vss_serdes_lb_cpri                    : std_logic_vector(CPRI_NUM-1 downto 0);
    signal is_master_cpri                        : std_logic_vector(CPRI_NUM-1 downto 0);         -- to SYSCTRL-TOP/BBCTRL-TOP
    signal line_rcf_start_cpri                   : std_logic_vector(CPRI_NUM-1 downto 0);         -- to SYSCTRL-TOP/BBCTRL-TOP
    signal line_rcf_rate_cpri                    : std_logic_array8(CPRI_NUM-1 downto 0);         -- to SYSCTRL-TOP/BBCTRL-TOP
    signal line_rcf_clktype_cpri                 : std_logic_array8(CPRI_NUM-1 downto 0);         -- to SYSCTRL-TOP/BBCTRL-TOP
    signal line_rcf_width_cpri                   : std_logic_array8(CPRI_NUM-1 downto 0);         -- to SYSCTRL-TOP/BBCTRL-TOP
    
    signal iqcomp_logic_bypass                   : std_logic_vector( CPRI_NUM-1 downto 0);        -- to BBCTRL-TOP
    signal vss_active_sel_cpri                   : std_logic_vector( CPRI_NUM-1 downto 0);        -- to BBCTRL-TOP
    signal cpri_los_cpri                         : std_logic_vector( CPRI_NUM-1 downto 0);        -- to BBCTRL-TOP
    signal cpri_lof_cpri                         : std_logic_vector( CPRI_NUM-1 downto 0);        -- to BBCTRL-TOP
    signal rx_vld_cpri                           : std_logic_vector( CPRI_NUM-1 downto 0);        -- to BBCTRL-TOP
    signal rx_i_cpri                             : std_logic_array16(CPRI_NUM-1 downto 0);        -- to BBCTRL-TOP
    signal rx_q_cpri                             : std_logic_array16(CPRI_NUM-1 downto 0);        -- to BBCTRL-TOP
    signal tx_enb_cpri                           : std_logic_vector( CPRI_NUM-1 downto 0);        -- to BBCTRL-TOP
    
    signal dump_bfn_strb_cpri                    : std_logic_vector( 1 downto 0);                 -- to MISC-TOP
    signal dump_data_cpri                        : std_logic_array32(1 downto 0);                 -- to MISC-TOP
    signal dump_dvld_cpri                        : std_logic_vector( 1 downto 0);                 -- to MISC-TOP
    signal test_enb_cpri                         : std_logic_vector( 1 downto 0);                 -- to MISC-TOP
    
    signal sig_sus_flag_cpri                     : std_logic_vector(CPRI_NUM-1 downto 0);         -- to MISC-TOP
    
    signal dbg_sig_cpri                          : std_logic_array32( 1 downto 0);                -- to FPGA_TOP
    
    -- SBIF <-> BBCTRL Interface Signals
    signal sbif_rx_bfn_strb_sbif                 : std_logic_vector(SBIF_NUM-1 downto 0);
    signal sbif_tx_enb_bbctrl                    : std_logic_vector(SBIF_NUM-1 downto 0);
    signal sbif_tx_i_sbif                        : std_logic_array16(SBIF_NUM-1 downto 0);
    signal sbif_tx_q_sbif                        : std_logic_array16(SBIF_NUM-1 downto 0);
    
    signal sbif_tx_bfn_strb_bbctrl               : std_logic_vector(SBIF_NUM-1 downto 0);
    signal sbif_tx_bfn_nr_bbctrl                 : std_logic_array12(SBIF_NUM-1 downto 0);
    signal sbif_tx_vld_bbctrl                    : std_logic_vector(SBIF_NUM-1 downto 0);
    signal sbif_tx_i_bbctrl                      : std_logic_array16(SBIF_NUM-1 downto 0);
    signal sbif_tx_q_bbctrl                      : std_logic_array16(SBIF_NUM-1 downto 0);
    
    signal sbif_lof                              : std_logic_vector(SBIF_NUM-1 downto 0);
    
    -- PIM SBIF PHY Signals
    signal dbg_sig_pim_sbifphy                   : std_logic_array32(1 downto 0);                 -- to FPGA_TOP
    
    -- PIM SBIF <-> BBCTRL Interface Signals     
    signal rx_enb_pim_sbif                       : std_logic_vector(PIM_SBIF_NUM-1 downto 0);
    signal rx_idata_pim_sbif                     : std_logic_array16(PIM_SBIF_NUM-1 downto 0);
    signal rx_qdata_pim_sbif                     : std_logic_array16(PIM_SBIF_NUM-1 downto 0);
    
    signal tx_vld_pim_sbif                       : std_logic_vector(PIM_SBIF_NUM-1 downto 0);
    signal tx_idata_pim_sbif                     : std_logic_array16(PIM_SBIF_NUM-1 downto 0);
    signal tx_qdata_pim_sbif                     : std_logic_array16(PIM_SBIF_NUM-1 downto 0);
    
    signal serdes_rxcomma_realign_pimsbif        : std_logic_vector(PIM_SBIF_NUM-1 downto 0);
    signal serdes_rxerr_pimsbif                  : std_logic_array4(PIM_SBIF_NUM-1 downto 0);
    signal serdes_rxisk_pimsbif                  : std_logic_array4(PIM_SBIF_NUM-1 downto 0);
    signal serdes_rxd_pimsbif                    : std_logic_array32(PIM_SBIF_NUM-1 downto 0);
    signal serdes_txisk_pimsbif                  : std_logic_array4(PIM_SBIF_NUM-1 downto 0);
    signal serdes_txd_pimsbif                    : std_logic_array32(PIM_SBIF_NUM-1 downto 0);
    
    signal gmii_rxd_in                           : std_logic_vector(7 downto 0);
    signal gmii_txd_out                          : std_logic_vector(7 downto 0);
    
    -- BBCTRL-TOP Module Interface Signals
    signal tx_tdd_bbctrl                         : std_logic_vector( CPRI_NUM-1 downto 0);        -- to SYSCTRL
    signal tx_bfn_strb_bbctrl                    : std_logic_vector( CPRI_NUM-1 downto 0);        -- to SYSCTRL
    
    signal refclk_aserdes                        : std_logic_vector(ASREF_NUM-1 downto 0);        -- to SYSCTRL
    
    signal tx_i_bbctrl                           : std_logic_array16(CPRI_NUM-1 downto 0);        -- to CPRI_TOP
    signal tx_q_bbctrl                           : std_logic_array16(CPRI_NUM-1 downto 0);        -- to CPRI_TOP
    
    signal dl_airtech_bbctrl                     : std_logic_array4( DL_BBIQARY_NUM-1 downto 0);  -- to DSP-TOP
    signal dl_chbw_bbctrl                        : std_logic_array4( DL_BBIQARY_NUM-1 downto 0);  -- to DSP-TOP
    signal dl_tdd_bbctrl                         : std_logic;                                     -- to DSP-TOP
    signal dl_bfn_bbctrl_strb                    : std_logic;                                     -- to DSP-TOP
    signal dl_bfn_nr_modulo_bbctrl               : std_logic_vector(11 downto 0);
    signal dl_ssb_bbctrl_strb                    : std_logic;                                     -- to DSP-TOP
    signal dl_sync_bbctrl                        : std_logic_vector( DL_BBIQARY_NUM-1 downto 0);  -- to DSP-TOP
    signal dl_iq_bbctrl                          : std_logic_array16(DL_BBIQARY_NUM-1 downto 0);  -- to DSP-TOP
    
    signal dl_bfn_nr_ok_bbctrl                   : std_logic;                                     -- to MISC-TOP
    
    signal ul_airtech_bbctrl                     : std_logic_array4( UL_BBIQARY_NUM-1 downto 0);  -- to DSP-TOP
    signal ul_chbw_bbctrl                        : std_logic_array4( UL_BBIQARY_NUM-1 downto 0);  -- to DSP-TOP
    
    signal sig_sus_flag_bbctrl                   : std_logic_vector(DL_BBIQARY_NUM-1 downto 0);   -- to MISC-TOP
    signal sig_sus_dloff_bbctrl                  : std_logic_vector(CPRI_NUM-1 downto 0);         -- to MISC-TOP
                                                                                                  -- to MISC-TOP
    signal dump_bfn_strb_bbctrl                  : std_logic_vector( 1 downto 0);                 -- to MISC-TOP
    signal dump_data_bbctrl                      : std_logic_array32(1 downto 0);                 -- to MISC-TOP
    signal dump_dvld_bbctrl                      : std_logic_vector( 1 downto 0);                 -- to MISC-TOP
    signal test_enb_bbctrl                       : std_logic_vector( 1 downto 0);                 -- to MISC-TOP
    
    signal dbg_sig_bbctrl                        : std_logic_array32(1 downto 0);                 -- to FPGA_TOP
    
    -- BBCTRL <-> DSP PIM Signals Interface
    signal trans_pim_sync                        : std_logic_vector(PIM_SBIF_NUM-1 downto 0);
    signal trans_pim_idata                       : std_logic_array15(PIM_SBIF_NUM-1 downto 0);
    signal trans_pim_qdata                       : std_logic_array15(PIM_SBIF_NUM-1 downto 0);
    
    signal rcv_pim_sync                          : std_logic_vector(PIM_SBIF_NUM-1 downto 0);
    signal rcv_pim_idata                         : std_logic_array15(PIM_SBIF_NUM-1 downto 0);
    signal rcv_pim_qdata                         : std_logic_array15(PIM_SBIF_NUM-1 downto 0);
    
    -- DSP-TOP Module Interface Signals
    signal ul_tdd_dsp                            : std_logic;                                     -- to BBCTRL-TOP
    signal ul_bfn_strb_dsp                       : std_logic;                                     -- to BBCTRL-TOP
    signal ul_sync_dsp                           : std_logic_vector( UL_BBIQARY_NUM-1 downto 0);  -- to BBCTRL-TOP
    signal ul_iq_dsp                             : std_logic_array16(UL_BBIQARY_NUM-1 downto 0);  -- to BBCTRL-TOP
    
    signal sig_sus_flag_dsp                      : std_logic_vector( TX_ANT_NUM-1 downto 0);      -- to MISC-TOP
    
    signal dl_iq_iszero_dsp                      : std_logic_vector( TX_ANT_NUM-1 downto 0);      -- to MISC-TOP
    signal dl_clk_iszero_dsp                     : std_logic_vector( TX_ANT_NUM-1 downto 0);      -- to MISC-TOP
    
    signal dl_bfn_strb_dsp                       : std_logic;                                     -- to DCIF-TOP
    signal dl_tdd_dsp                            : std_logic;                                     -- to DCIF-TOP
    signal dl_ssb_strb_dsp                       : std_logic;                                     -- to DCIF-TOP
    
    signal dl_sync_dsp                           : std_logic_vector( TX_ANT_NUM-1 downto 0);      -- to DCIF-TOP
    signal dl_i_dsp                              : std_logic_array16(TX_ANT_NUM-1 downto 0);      -- to DCIF-TOP
    signal dl_q_dsp                              : std_logic_array16(TX_ANT_NUM-1 downto 0);      -- to DCIF-TOP
    
    signal test_denb_dsp                         : std_logic_vector( 1 downto 0);                 -- to MISC-TOP
    
    signal dump_bfn_strb_dsp                     : std_logic_vector( 1 downto 0);                 -- to MISC-TOP
    signal dump_dvld_dsp                         : std_logic_vector( 1 downto 0);                 -- to MISC-TOP
    signal dump_data_dsp                         : std_logic_array32(1 downto 0);                 -- to MISC-TOP
    
    signal dbg_sig_dsp                           : std_logic_array32(1 downto 0);                 -- to FPGA_TOP
    
    -- DCIF-TOP Module Interface Signals
    signal dl_bfn_strb_dcif                      : std_logic;                                     -- to DCIF-TOP
    signal dl_tdd_dcif                           : std_logic;                                     -- to DCIF-TOP
    signal dl_ssb_strb_dcif                      : std_logic;
    
    signal fb_bfn_strb_dcif                      : std_logic;                                     -- to DSP-TOP
    signal fb_tdd_dcif                           : std_logic;                                     -- to DSP-TOP
    signal fb_ssb_strb_dcif                      : std_logic;                                     -- to DSP-TOP
    
    signal fb_sync_dcif                          : std_logic_vector( FB_PATH_NUM-1 downto 0);     -- to DSP-TOP
    signal fb_i_dcif                             : std_logic_array16(FB_PATH_NUM-1 downto 0);     -- to DSP-TOP
    signal fb_q_dcif                             : std_logic_array16(FB_PATH_NUM-1 downto 0);     -- to DSP-TOP
    
    signal ul_bfn_strb_dcif                      : std_logic;                                     -- to DSP-TOP
    signal ul_tdd_dcif                           : std_logic;                                     -- to DSP-TOP
    
    signal ul_sync_dcif                          : std_logic_vector( RX_ANT_NUM-1 downto 0);      -- to DSP-TOP
    --signal ul_valid_dcif                         : std_logic;                                     -- to DSP-TOP
    signal ul_i_dcif                             : std_logic_array16(RX_ANT_NUM-1 downto 0);      -- to DSP-TOP
    signal ul_q_dcif                             : std_logic_array16(RX_ANT_NUM-1 downto 0);      -- to DSP-TOP
    
    signal s_nbiot_nco_valid_cc0                 : std_logic;
    signal s_nbiot_nco_valid_cc1                 : std_logic;
    signal s_nbiot_freq_offset_cc0               : std_logic_vector(23 downto 0);
    signal s_nbiot_freq_offset_cc1               : std_logic_vector(23 downto 0);
    
    signal sig_sus_dlflag_dcif                   : std_logic_vector(JESD_TX_LINK_NUM-1 downto 0);      -- to MISC-TOP
    signal sig_sus_fbflag_dcif                   : std_logic_vector(JESD_FB_LINK_NUM-1 downto 0);      -- to MISC-TOP
    signal sig_sus_ulflag_dcif                   : std_logic_vector(JESD_RX_LINK_NUM-1 downto 0);      -- to MISC-TOP
    
    signal dump_bfn_strb_dcif                    : std_logic_vector( 1 downto 0);                 -- to MISC-TOP
    signal dump_data_dcif                        : std_logic_array32(1 downto 0);                 -- to MISC-TOP
    signal dump_dvld_dcif                        : std_logic_vector( 1 downto 0);                 -- to MISC-TOP
    
    signal test_denb_dcif                        : std_logic_vector( 1 downto 0);                 -- to MISC-TOP
    
    signal dbg_sig_dcif                          : std_logic_array32(1 downto 0);                 -- to FPGA_TOP
    
    -- MISC-TOP Module Interface Signals
    signal dl_bfn_strb_1pps_misc                 : std_logic;                                     -- to SYSCTRL-TOP
    
    signal ul_bfn_strb_misc                      : std_logic;                                     -- to DCIF-TOP
    signal ul_tdd_misc                           : std_logic;                                     -- to DCIF-TOP
    
    signal fb_bfn_strb_misc                      : std_logic;                                     -- to DCIF-TOP
    signal fb_ssb_strb_misc                      : std_logic;                                     -- to DCIF-TOP
    signal fb_tdd_misc                           : std_logic;                                     -- to DCIF-TOP
    
    signal sig_sus_dloff_sbifphy                 : std_logic_vector(SBIF_NUM-1 downto 0);         -- to SBIFPHY_TOP
    signal sig_sus_dloff_sbif                    : std_logic_vector(SBIF_NUM-1 downto 0);         -- to SBIF_TOP
    signal test_data_cpri                        : std_logic_array32(1 downto 0);                 -- to CPRI_TOP
    signal test_denb_cpri                        : std_logic_vector(1 downto 0);
    signal sig_sus_dloff_dsp                     : std_logic_vector(TX_ANT_NUM-1 downto 0);       -- to DSP-TOP
    signal test_data_sbifphy                     : std_logic_array32(1 downto 0);                 -- to SBIF-TOP
    signal test_data_sbif                        : std_logic_array32(1 downto 0);                 -- to SBIF-TOP
    signal test_data_bbctrl                      : std_logic_array32(1 downto 0);                 -- to BBCTRL-TOP
    signal test_data_dsp                         : std_logic_array32(1 downto 0);                 -- to DSP-TOP
    signal test_data_dcif                        : std_logic_array32(1 downto 0);                 -- to DCIF-TOP
    
    signal fbsw_start_trig_misc                  : std_logic;                                     -- to DSP-TOP
    signal fbsw_cnt_misc                         : std_logic_vector( 4 downto 0);                 -- to DSP-TOP
    signal fbsw_auto_mode_done_misc              : std_logic_vector(RFIC_NUM-1 downto 0);      -- to DSP-TOP
    signal fbsw_auto_mode_done_dsp               : std_logic_vector(FB_PATH_NUM-1 downto 0);      -- to DSP-TOP
    signal fbsw_pwr_msr_upt_misc                 : std_logic;                                     -- to DSP-TOP
    signal fbsw_manual_mode_misc                 : std_logic;                                     -- to DSP-TOP
    signal fbsw_sc_path_sel                      : std_logic_vector(4 downto 0);                  -- to DSP-TOP
    signal pwr_msr_fb_sync                       : std_logic;
    signal pwr_msr_en                            : std_logic;
    signal fbsw_ssb_ind                          : std_logic;
    
    signal dbg_sig_misc                          : std_logic_array32( 1 downto 0);                 -- to FPGA_TOP
    
    signal sig_sus_dloff_otrx                    : std_logic;
    signal function_fail_misc                    : std_logic;
    signal ru_func_fail                          : std_logic_vector(1 downto 0);
    
    -- ANNEX_TOP Module Interface Signals
    signal c2c_ctrl_pma_init                     : std_logic;                                     -- to CPU-TOP
    signal aurora_power_down                     : std_logic_vector( 3 downto 0);                 -- to CPU-TOP
    
    signal core_sts_gt_pll_lock                  : std_logic_vector( 3 downto 0);                 -- to CPU-TOP
    signal core_sts_gt_qpllreset                 : std_logic_vector( 3 downto 0);                 -- to CPU-TOP
    signal core_sts_hard_err                     : std_logic_vector( 3 downto 0);                 -- to CPU-TOP
    signal core_sts_lane_up                      : std_logic_vector( 3 downto 0);                 -- to CPU-TOP
    signal core_sts_soft_err                     : std_logic_vector( 3 downto 0);                 -- to CPU-TOP
    
    signal axi_c2c_config_error                  : std_logic_vector( 3 downto 0);                 -- to CPU-TOP
    signal axi_c2c_link_error                    : std_logic_vector( 3 downto 0);                 -- to CPU-TOP
    signal axi_c2c_link_status                   : std_logic_vector( 3 downto 0);                 -- to CPU-TOP
    signal axi_c2c_multibit_err                  : std_logic_vector( 3 downto 0);                 -- to CPU-TOP
    
    signal aurora_txdiffctrl                     : std_logic_array5( 3 downto 0);                 -- to CPU-TOP
    signal aurora_txpolarity                     : std_logic_vector( 3 downto 0);                 -- to CPU-TOP
    signal aurora_txpostcursor                   : std_logic_array5( 3 downto 0);                 -- to CPU-TOP
    signal aurora_loopback                       : std_logic_array3( 3 downto 0);                 -- to CPU-TOP
    signal aurora_rxlpmen                        : std_logic_vector( 3 downto 0);                 -- to CPU-TOP
    
    signal i_axi_timeout                         : std_logic;
    
    signal rfic_spi_buf_rst_misc                 : std_logic_vector( RFIC_NUM-1 downto 0);        -- to CPU-TOP
    signal rfic_spi_buf_clk_misc                 : std_logic_vector( RFIC_NUM-1 downto 0);        -- to CPU-TOP
    signal rfic_spi_buf_addr_misc                : std_logic_array32(RFIC_NUM-1 downto 0);        -- to CPU-TOP
    signal rfic_spi_buf_din_misc                 : std_logic_array32(RFIC_NUM-1 downto 0);        -- to CPU-TOP
    signal rfic_spi_buf_dout_cpu                 : std_logic_array32(RFIC_NUM-1 downto 0);        -- to MISC-TOP
    signal rfic_spi_buf_en_misc                  : std_logic_vector( RFIC_NUM-1 downto 0);        -- to CPU-TOP
    signal rfic_spi_buf_we_misc                  : std_logic_array4( RFIC_NUM-1 downto 0);        -- to CPU-TOP
    
    signal rfic_spi_ip_ss_cpu                    : std_logic_vector(RFIC_NUM-1 downto 0);         -- to MISC-TOP
    signal rfic_spi_ip_sclk_cpu                  : std_logic_vector(RFIC_NUM-1 downto 0);         -- to MISC-TOP
    signal rfic_spi_ip_mosi_cpu                  : std_logic_vector(RFIC_NUM-1 downto 0);         -- to MISC-TOP
    signal rfic_spi_ip_miso_misc                 : std_logic_vector(RFIC_NUM-1 downto 0);         -- to CPU-TOP
    
    signal jesd_axi_resetn                       : std_logic;
    
    signal JESD_AXI_INTERCONNECT_araddr_cpu   : STD_LOGIC_VECTOR ( 31 downto 0 );
    signal JESD_AXI_INTERCONNECT_arburst_cpu  : STD_LOGIC_VECTOR ( 1 downto 0 );
    signal JESD_AXI_INTERCONNECT_arcache_cpu  : STD_LOGIC_VECTOR ( 3 downto 0 );
    signal JESD_AXI_INTERCONNECT_arlen_cpu    : STD_LOGIC_VECTOR ( 7 downto 0 );
    signal JESD_AXI_INTERCONNECT_arlock_cpu   : STD_LOGIC_VECTOR ( 0 to 0 );
    signal JESD_AXI_INTERCONNECT_arprot_cpu   : STD_LOGIC_VECTOR ( 2 downto 0 );
    signal JESD_AXI_INTERCONNECT_arqos_cpu    : STD_LOGIC_VECTOR ( 3 downto 0 );
    signal JESD_AXI_INTERCONNECT_arready_dcif : STD_LOGIC;
    signal JESD_AXI_INTERCONNECT_arregion_cpu : STD_LOGIC_VECTOR ( 3 downto 0 );
    signal JESD_AXI_INTERCONNECT_arsize_cpu   : STD_LOGIC_VECTOR ( 2 downto 0 );
    signal JESD_AXI_INTERCONNECT_arvalid_cpu  : STD_LOGIC;
    signal JESD_AXI_INTERCONNECT_awaddr_cpu   : STD_LOGIC_VECTOR ( 31 downto 0 );
    signal JESD_AXI_INTERCONNECT_awburst_cpu  : STD_LOGIC_VECTOR ( 1 downto 0 );
    signal JESD_AXI_INTERCONNECT_awcache_cpu  : STD_LOGIC_VECTOR ( 3 downto 0 );
    signal JESD_AXI_INTERCONNECT_awlen_cpu    : STD_LOGIC_VECTOR ( 7 downto 0 );
    signal JESD_AXI_INTERCONNECT_awlock_cpu   : STD_LOGIC_VECTOR ( 0 to 0 );
    signal JESD_AXI_INTERCONNECT_awprot_cpu   : STD_LOGIC_VECTOR ( 2 downto 0 );
    signal JESD_AXI_INTERCONNECT_awqos_cpu    : STD_LOGIC_VECTOR ( 3 downto 0 );
    signal JESD_AXI_INTERCONNECT_awready_dcif : STD_LOGIC;
    signal JESD_AXI_INTERCONNECT_awregion_cpu : STD_LOGIC_VECTOR ( 3 downto 0 );
    signal JESD_AXI_INTERCONNECT_awsize_cpu   : STD_LOGIC_VECTOR ( 2 downto 0 );
    signal JESD_AXI_INTERCONNECT_awvalid_cpu  : STD_LOGIC;
    signal JESD_AXI_INTERCONNECT_bready_cpu   : STD_LOGIC;
    signal JESD_AXI_INTERCONNECT_bresp_dcif   : STD_LOGIC_VECTOR ( 1 downto 0 );
    signal JESD_AXI_INTERCONNECT_bvalid_dcif  : STD_LOGIC;
    signal JESD_AXI_INTERCONNECT_rdata_dcif   : STD_LOGIC_VECTOR ( 31 downto 0 );
    signal JESD_AXI_INTERCONNECT_rlast_dcif   : STD_LOGIC;
    signal JESD_AXI_INTERCONNECT_rready_cpu   : STD_LOGIC;
    signal JESD_AXI_INTERCONNECT_rresp_dcif   : STD_LOGIC_VECTOR ( 1 downto 0 );
    signal JESD_AXI_INTERCONNECT_rvalid_dcif  : STD_LOGIC;
    signal JESD_AXI_INTERCONNECT_wdata_cpu    : STD_LOGIC_VECTOR ( 31 downto 0 );
    signal JESD_AXI_INTERCONNECT_wlast_cpu    : STD_LOGIC;
    signal JESD_AXI_INTERCONNECT_wready_dcif  : STD_LOGIC;
    signal JESD_AXI_INTERCONNECT_wstrb_cpu    : STD_LOGIC_VECTOR ( 3 downto 0 );
    signal JESD_AXI_INTERCONNECT_wvalid_cpu   : STD_LOGIC;
    
    signal ecpri_gt_reset_rx_done             : std_logic_vector(1 downto 0);
    signal ecpri_gt_reset_tx_done             : std_logic_vector(1 downto 0);
    signal ecpri_stat_rx_block_lock           : std_logic_vector(1 downto 0);
    signal ecpri_stat_rx_local_fault          : std_logic_vector(1 downto 0);
    signal ecpri_stat_rx_remote_fault         : std_logic_vector(1 downto 0);
    
    signal ecpri_stat_rx_rate_10g_25gn        : std_logic_vector(1 downto 0);
    signal ecpri_stat_rx_status               : std_logic_vector(1 downto 0);
    signal ecpri_gt_rxlpmen                   : std_logic_vector(1 downto 0);
    signal ecpri_gt_txdiffctrl                : std_logic_array5(1 downto 0);
    signal ecpri_txprecursor                  : std_logic_array5(1 downto 0);
    signal ecpri_txpostcusor                  : std_logic_array5(1 downto 0);
    signal mode_change_25n_10h                : std_logic_vector(1 downto 0); -- Low : 25G, High : 10G
    signal rx_wdt_reset                       : std_logic_vector(1 downto 0);
    signal mac_sys_reset                      : std_logic;
    signal dma_block_reset                    : std_logic;
    signal sysctrl_oran_framer_rst            : std_logic_vector( DL_NUM_CC    -1 downto 0 )  ; 
    signal sysctrl_oran_deframer_rst          : std_logic_vector( UL_NUM_CC    -1 downto 0 )  ;
    signal sysctrl_lphy_top_rst               : std_logic_vector( DL_NUM_CC    -1 downto 0 )  ; 
    signal sysctrl_dlfe_rst                   : std_logic_vector( DL_NUM_CC    -1 downto 0 )  ; 
    signal sysctrl_ulfe_rst                   : std_logic_vector( UL_NUM_CC    -1 downto 0 )  ; 
    signal sysctrl_rafe_rst                   : std_logic_vector( UL_NUM_CC    -1 downto 0 )  ; 
    signal sysctrl_aurora_rst                 : std_logic; 
    
    signal s_din_frame_sync                   : std_logic_vector (  01*DL_MAX_CC-1                         downto 0); --ccx dl input frame sync (1 pulse of 245.76MHz every 10ms)
    signal s_din_frame_idx                    : std_logic_vector (  08*DL_MAX_CC-1                         downto 0); --ccx dl input frame index (oran)
    signal s_dlfe_cc_system_mode_dss          : std_logic_vector(CELL_NUM*PATH_NUM*1-1 downto 0); 
    
    signal s_din_en                           : std_logic_vector (  01*DL_NUM_LAYER*DL_MAX_CC-1            downto 0); --ccx dl input u-plane data valid (oran)
    signal s_din_re_mask                      : std_logic_vector (  01*DL_NUM_LAYER*DL_MAX_CC-1            downto 0); --ccx dl input re mask (oran)
    signal s_din_sys_mode_dss                 : std_logic_vector (  01*DL_NUM_LAYER*DL_MAX_CC-1            downto 0); --ccx dl input system mode bitmap for dss (oran) 
    signal s_din_iq                           : std_logic_vector (  2*TOP_DIO_BW*DL_NUM_LAYER*DL_MAX_CC-1  downto 0); --ccx dl input u-plane data (oran)      
    signal s_dout_dl_sys_mode                 : std_logic_vector (  01*DL_MAX_CC-1                         downto 0); --ccx dl output system mode   
    signal s_dout_dl_ntone                    : std_logic_vector (  12*DL_MAX_CC-1                         downto 0); --ccx dl output ntone   
    signal s_dout_dl_fft_type                 : std_logic_vector (  02*DL_MAX_CC-1                         downto 0); --ccx dl output fft_type
    signal s_dout_dl_k0                       : std_logic_vector (  12*DL_MAX_CC-1                         downto 0); --ccx dl output k0  
    
    signal s_uout_frame_idx                   : std_logic_vector (  08*UL_MAX_CC-1                         downto 0);  --ccx ul output frame index (oran)       
    signal s_uout_subfrm_idx                  : std_logic_vector (  04*UL_MAX_CC-1                         downto 0);  --ccx ul output subframe index (oran)
    signal s_uout_slot_idx                    : std_logic_vector (  06*UL_MAX_CC-1                         downto 0);  --ccx ul output slot index (oran)
    signal s_uout_symbol_idx                  : std_logic_vector (  06*UL_MAX_CC-1                         downto 0);  --ccx ul output symbol index (oran)
    signal s_uout_start_re_idx                : std_logic_vector (  16*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx ul output start re index (oran)
    signal s_uout_en                          : std_logic_vector (  01*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx ul output u-plane data valid (oran)
    signal s_uout_start_re                    : std_logic_vector (  01*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx ul output start re indicator (oran)    
    signal s_uout_last_re                     : std_logic_vector (  01*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx ul output last re indicator (oran)
    signal s_uout_iq                          : std_logic_vector (  2*TOP_DIO_BW*UL_NUM_PATH*UL_MAX_CC-1   downto 0);  --ccx ul output u-plane data (oran)
    
    signal s_rin_frame_sync                   : std_logic_vector (  01*UL_MAX_CC-1                         downto 0);  --ccx prach input frame sync (1 pulse of 245.76MHz every 10ms)
    signal s_rin_filter_idx                   : std_logic_vector (  04*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach input filter index
    signal s_rin_time_offset                  : std_logic_vector (  16*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach input time offset
    signal s_rin_frame_struct                 : std_logic_vector (  08*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach input frame structure
    signal s_rin_cp_length                    : std_logic_vector (  16*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach input cp length
    signal s_rin_freq_offset                  : std_logic_vector (  24*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach input frequency offset
    signal s_rin_start_prbc                   : std_logic_vector (  10*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach input frequency offset
    signal s_rin_num_psymbol                  : std_logic_vector (  04*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach input preamble symbol number
    signal s_rin_num_ro                       : std_logic_vector (  03*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach input occasion number
    signal s_rin_num_prbc                     : std_logic_vector (  08*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach input c-plane physical rb size 
    signal s_rout_frame_idx                   : std_logic_vector (  08*UL_MAX_CC-1                         downto 0);  --ccx prach output frame index (oran)  
    signal s_rout_subfrm_idx                  : std_logic_vector (  04*UL_MAX_CC-1                         downto 0);  --ccx prach output subframe index (oran)
    signal s_rout_slot_idx                    : std_logic_vector (  06*UL_MAX_CC-1                         downto 0);  --ccx prach output slot index (oran)
    signal s_rout_symbol_idx                  : std_logic_vector (  06*UL_MAX_CC-1                         downto 0);  --ccx prach output symbol index (oran)
    signal s_rout_start_re_idx                : std_logic_vector (  16*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach output start re index (oran)
    signal s_rout_en                          : std_logic_vector (  01*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach output u-plane data valid (oran)
    signal s_rout_start_re                    : std_logic_vector (  01*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach output start re indicator (oran)    
    signal s_rout_last_re                     : std_logic_vector (  01*UL_NUM_PATH*UL_MAX_CC-1             downto 0);  --ccx prach output last re indicator (oran)
    signal s_rout_iq                          : std_logic_vector (  2*TOP_DIO_BW*UL_NUM_PATH*UL_MAX_CC-1   downto 0);  --ccx prach output u-plane data (oran)  
    
    signal s_dout_frame_sync                  : std_logic_vector (  01*DL_MAX_CC-1                         downto 0);  --ccx dl output frame sync (1 pulse of 245.76MHz every 10ms)
    signal s_dout_en                          : std_logic_vector (  01*DL_NUM_ANT*DL_MAX_CC-1              downto 0);  --ccx dl output td data valid 
    signal s_dout_i                           : std_logic_vector (  TOP_DIO_BW*DL_NUM_ANT*DL_MAX_CC-1      downto 0);  --ccx dl output td in-phase sample
    signal s_dout_q                           : std_logic_vector (  TOP_DIO_BW*DL_NUM_ANT*DL_MAX_CC-1      downto 0);  --ccx dl output td quadrature sample
    signal s_dout_i_array                     : std_logic_array16(             DL_NUM_ANT*DL_MAX_CC-1      downto 0);
    signal s_dout_q_array                     : std_logic_array16(             DL_NUM_ANT*DL_MAX_CC-1      downto 0);
    
    signal s_uin_i_array                      : std_logic_array16(             UL_NUM_ANT*UL_CC_NUM -1     downto 0):= ( others => (others => '0' ) );
    signal s_uin_q_array                      : std_logic_array16(             UL_NUM_ANT*UL_CC_NUM -1     downto 0):= ( others => (others => '0' ) );
    
    signal s_uin_frame_sync                   : std_logic_vector ( 01*UL_CC_NUM-1                          downto 0);  --ccx ul input frame sync (1 pulse of 245.76MHz every 10ms)
    signal s_uin_en                           : std_logic_vector ( 01*UL_NUM_ANT*UL_CC_NUM-1               downto 0);  --ccx ul input td data valid
    signal s_uin_i                            : std_logic_vector ( TOP_DIO_BW*UL_NUM_ANT*UL_MAX_CC -1      downto 0);  --ccx ul input td in-phase sample
    signal s_uin_q                            : std_logic_vector ( TOP_DIO_BW*UL_NUM_ANT*UL_MAX_CC -1      downto 0);  --ccx ul input td quadrature sample
    signal s_mux_uin_frame_sync               : std_logic_vector ( 01*UL_MAX_CC-1                          downto 0);  --ccx ul input frame sync (1 pulse of 245.76MHz every 10ms)
    signal s_mux_uin_en                       : std_logic_vector ( 01*UL_NUM_ANT*UL_MAX_CC-1               downto 0);  --ccx ul input td data valid
    signal s_mux_uin_i                        : std_logic_vector ( TOP_DIO_BW*UL_NUM_ANT*UL_MAX_CC -1      downto 0);  --ccx ul input td in-phase sample
    signal s_mux_uin_q                        : std_logic_vector ( TOP_DIO_BW*UL_NUM_ANT*UL_MAX_CC -1      downto 0);  --ccx ul input td quadrature sample
    
    
    signal s_nin_filter_idx                   : std_logic_vector ( CELL_NUM_NBIOT*PATH_NUM*4 -1            downto 0);  --//ccx ul nprach,npuxch input filter index
    signal s_nin_time_offset                  : std_logic_vector ( CELL_NUM_NBIOT*PATH_NUM*16-1            downto 0);  --//ccx ul nprach,npuxch input time offset
    signal s_nin_frame_struct                 : std_logic_vector ( CELL_NUM_NBIOT*PATH_NUM*8 -1            downto 0);  --//ccx ul nprach,npuxch input frame structure
    signal s_nin_cp_length                    : std_logic_vector ( CELL_NUM_NBIOT*PATH_NUM*16-1            downto 0);  --//ccx ul nprach,npuxch input cp length
    signal s_nin_freq_offset                  : std_logic_vector ( CELL_NUM_NBIOT*PATH_NUM*24-1            downto 0);  --//ccx ul nprach,npuxch input frequency offset
    signal s_nin_start_prbc                   : std_logic_vector ( CELL_NUM_NBIOT*PATH_NUM*10-1            downto 0);  --//ccx ul nprach,npuxch input frequency offset
    signal s_nin_num_psymbol                  : std_logic_vector ( CELL_NUM_NBIOT*PATH_NUM*4 -1            downto 0);  --//ccx ul nprach,npuxch input preamble symbol number
    signal s_nin_num_prbc                     : std_logic_vector ( CELL_NUM_NBIOT*PATH_NUM*8 -1            downto 0);  --//ccx ul nprach,npuxch input c-plane physical rb size 
    signal s_nin_num_ro                       : std_logic_vector ( CELL_NUM_NBIOT*PATH_NUM*3 -1            downto 0);
    
    signal s_nout_nco_valid                   : std_logic_vector( 1 * 2 -1 downto 0);
    signal s_nout_frame_struct                : std_logic_vector( 8 * 2 -1 downto 0);
    signal s_nout_freq_offset                 : std_logic_vector(24 * 2 -1 downto 0);
    signal s_nout_frame_idx                   : std_logic_vector(CELL_NUM_NBIOT*8-1 downto 0);
    signal s_nout_subfrm_idx                  : std_logic_vector(CELL_NUM_NBIOT*4-1 downto 0);
    signal s_nout_slot_idx                    : std_logic_vector(CELL_NUM_NBIOT*6-1 downto 0);
    signal s_nout_symbol_idx                  : std_logic_vector(CELL_NUM_NBIOT*6-1 downto 0);
    signal s_nout_start_re_idx                : std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*16-1 downto 0);
    signal s_nout_en                          : std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*1-1 downto 0); 
    signal s_nout_start_re                    : std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*1-1 downto 0); 
    signal s_nout_last_re                     : std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*1-1 downto 0); 
    signal s_nout_iq                          : std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*32-1 downto 0);
    
    signal s_nin_frame_sync                   : std_logic_vector( 01*NB_MAX_CC-1                     downto 0);  --//ccx ul nprach,npuxch input frame sync (1 pulse of 245.76MHz every 10ms)
    signal s_nin_en                           : std_logic_vector( 01*NB_NUM_ANT*NB_MAX_CC-1          downto 0);  --//ccx ul nprach,npuxch input td data valid 
    signal s_nin_i                            : std_logic_vector( TOP_DIO_BW*NB_NUM_ANT*NB_MAX_CC-1  downto 0);  --//ccx ul nprach,npuxch input td in-phase sample
    signal s_nin_q                            : std_logic_vector( TOP_DIO_BW*NB_NUM_ANT*NB_MAX_CC-1  downto 0);  --//ccx ul nprach,npuxch input td quadrature sample
    
    signal s_mux_nin_frame_sync               : std_logic_vector( 01*2-1                     downto 0);  --//ccx ul nprach,npuxch input frame sync (1 pulse of 245.76MHz every 10ms)
    signal s_mux_nin_en                       : std_logic_vector( 01*NB_NUM_ANT*2-1          downto 0);  --//ccx ul nprach,npuxch input td data valid 
    signal s_mux_nin_i                        : std_logic_vector( TOP_DIO_BW*NB_NUM_ANT*2-1  downto 0);  --//ccx ul nprach,npuxch input td in-phase sample
    signal s_mux_nin_q                        : std_logic_vector( TOP_DIO_BW*NB_NUM_ANT*2-1  downto 0);  --//ccx ul nprach,npuxch input td quadrature sample
    
    
    signal s_min_filter_idx                   : std_logic_vector ( 04*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach input filter index
    signal s_min_time_offset                  : std_logic_vector ( 16*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach input time offset
    signal s_min_frame_struct                 : std_logic_vector ( 08*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach input frame structure
    signal s_min_cp_length                    : std_logic_vector ( 16*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach input cp length
    signal s_min_freq_offset                  : std_logic_vector ( 24*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach input frequency offset
    signal s_min_start_prbc                   : std_logic_vector ( 10*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach input frequency offset
    signal s_min_num_psymbol                  : std_logic_vector ( 04*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach input preamble symbol number
    signal s_min_num_ro                       : std_logic_vector ( 03*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach input occasion number
    signal s_min_num_prbc                     : std_logic_vector ( 08*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach input c-plane physical rb size 
    signal s_mout_frame_idx                   : std_logic_vector ( 08*MT_MAX_CC-1                          downto 0);  --//ccx emtc prach output frame index (oran)  
    signal s_mout_subfrm_idx                  : std_logic_vector ( 04*MT_MAX_CC-1                          downto 0);  --//ccx emtc prach output subframe index (oran)
    signal s_mout_slot_idx                    : std_logic_vector ( 06*MT_MAX_CC-1                          downto 0);  --//ccx emtc prach output slot index (oran)
    signal s_mout_symbol_idx                  : std_logic_vector ( 06*MT_MAX_CC-1                          downto 0);  --//ccx emtc prach output symbol index (oran)
    signal s_mout_start_re_idx                : std_logic_vector ( 16*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach output start re index (oran)
    signal s_mout_en                          : std_logic_vector ( 01*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach output u-plane data valid (oran)
    signal s_mout_start_re                    : std_logic_vector ( 01*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach output start re indicator (oran)    
    signal s_mout_last_re                     : std_logic_vector ( 01*MT_NUM_PATH*MT_MAX_CC-1              downto 0);  --//ccx emtc prach output last re indicator (oran)
    signal s_mout_iq                          : std_logic_vector ( 2*TOP_DIO_BW*MT_NUM_PATH*MT_MAX_CC-1    downto 0);  --//ccx emtc prach output u-plane data (oran)  
    
    signal s_min_frame_sync                   : std_logic_vector(01*MT_MAX_CC-1                            downto 0); --//ccx ul emtc prach input frame sync (1 pulse of 245.76MHz every 10ms)
    signal s_min_en                           : std_logic_vector(01*MT_NUM_ANT*MT_MAX_CC-1                 downto 0); --//ccx ul emtc prach input td data valid 
    signal s_min_i                            : std_logic_vector(TOP_DIO_BW*MT_NUM_ANT*MT_MAX_CC-1         downto 0); --//ccx ul emtc prach input td in-phase sample
    signal s_min_q                            : std_logic_vector(TOP_DIO_BW*MT_NUM_ANT*MT_MAX_CC-1         downto 0); --//ccx ul emtc prach input td quadrature sample
    
    
    
    signal frame_sync_cpu_top                 : std_logic_vector (  CPRI_NUM-1                             downto 0);
    signal sfn_num_cpu_top                    : std_logic_vector (11 downto 0):=(others =>'0');
    signal sfn_num_cpu_top_array              : std_logic_array11(CC_NUM -1 downto 0);
    signal ptp_1pps_cpu_top                   : std_logic;
    signal l0_deframer_clk                    : std_logic; 
    signal otrx_bh_rs_r                       : std_logic_array2(1 downto 0) := (others => (others => '0'));
    
    signal w_otrx_txdis					      : std_logic_vector(1 downto 0) ;
    
    signal dl_cc_sync_advance                 : std_logic_vector(22 * DL_MAX_CC -1 downto 0);
    signal ul_cc_sync_retard                  : std_logic_vector(22 * UL_MAX_CC -1 downto 0);
    signal n_ta_offset                        : std_logic_vector(DL_MAX_CC*16-1 downto 0);
    signal mac0_rx_valid                      : std_logic_vector(1 downto 0);
    signal mac0_rx_last                       : std_logic_vector(1 downto 0);
    signal mac0_rx_keep                       : std_logic_array8(1 downto 0);
    signal mac0_rx_data                       : std_logic_array64(1 downto 0);
    
    signal mac0_tx_ready                      : std_logic;
    signal mac0_tx_valid                      : std_logic;
    signal mac0_tx_last                       : std_logic;
    signal mac0_tx_keep                       : std_logic_vector(7 downto 0);
    signal mac0_tx_data                       : std_logic_vector(63 downto 0);
    
    signal ext_ru_tx_tdata                    : std_logic_vector ( 63 DOWNTO 0 );
    signal ext_ru_tx_tkeep                    : std_logic_vector ( 7 DOWNTO 0 );
    signal ext_ru_tx_tlast                    : std_logic;
    signal ext_ru_tx_tready                   : std_logic;
    signal ext_ru_tx_tvalid                   : std_logic;
    
    signal ext_ru_rx_tdata                    : std_logic_vector ( 63 DOWNTO 0 );
    signal ext_ru_rx_tkeep                    : std_logic_vector ( 7 DOWNTO 0 );
    signal ext_ru_rx_tlast                    : std_logic;
    
    signal ext_ru_rx_tvalid                   : std_logic;
    
    signal pim_sbif_tx_sync                   : std_logic;
    signal pim_sbif_tx_sync_vec               : std_logic_vector(PIM_SBIF_NUM -1 downto 0);
    signal pim_sbif_tx_1pps                   : std_logic;
    signal pim_sbif_tx_bfn_strb               : std_logic;
    signal pim_sbif_tx_bfn_strb_vec           : std_logic_vector(PIM_SBIF_NUM -1 downto 0);
    signal pim_sbif_tx_bfn                    : std_logic_vector(10 downto 0);
    signal pl_clk_50m                         : std_logic;
    signal w_clk_ptp                         : std_logic;
    
    signal ecpri_fail                         : std_logic;
    
    signal sw_wdt_det                         : std_logic;
    signal sw_wdt_latch                       : std_logic;
    signal emio_gpio_o_0                      : STD_LOGIC_VECTOR ( 94 downto 0 );
    signal emio_wdt1_rst_o_0                  : STD_LOGIC;
    
    
    signal system_timer_mmcm_rst              : std_logic;
    signal system_timer_mmcm_lock             : std_logic;
    
    signal tp_con_sel                         : std_logic_vector(7 downto 0);
    signal  w_bbul_idata                        :   std_logic_vector(127 downto 0);
    signal  w_bbul_qdata                        :   std_logic_vector(127 downto 0);
    
    --------
    
    
    
--attribute MARK_DEBUG : string;

-------------------------- downlink --------------------

----  -- lphy input
-- attribute MARK_DEBUG of w_dlfe_frame_sync   : signal is "TRUE";
-- attribute MARK_DEBUG of s_i_din_en          : signal is "TRUE";
---- attribute MARK_DEBUG of s_i_din_re_mask     : signal is "TRUE";
-- attribute MARK_DEBUG of s_i_din_iq          : signal is "TRUE";

----  -- lphy output
-- attribute MARK_DEBUG of s_dout_frame_sync   : signal is "TRUE";
-- attribute MARK_DEBUG of s_dout_en           : signal is "TRUE";
-- attribute MARK_DEBUG of s_dout_i            : signal is "TRUE";
-- attribute MARK_DEBUG of s_dout_q            : signal is "TRUE";
  
---- -- bbctrl output                  
-- attribute MARK_DEBUG of dl_bfn_bbctrl_strb  : signal is "TRUE";                  
-- attribute MARK_DEBUG of dl_sync_bbctrl      : signal is "TRUE";    
-- attribute MARK_DEBUG of dl_iq_bbctrl        : signal is "TRUE";
 
------ dsp output
-- attribute MARK_DEBUG of  dl_bfn_strb_dsp    : signal is "TRUE";
-- attribute MARK_DEBUG of  dl_i_dsp           : signal is "TRUE";
-- attribute MARK_DEBUG of  dl_q_dsp           : signal is "TRUE";
    
-------------------------- downlink --------------------

-------------------------- uplink --------------------


----   --dcif OUTPUT                                                                                           
--    attribute MARK_DEBUG of ul_sync_dcif     : signal is "TRUE";
--    attribute MARK_DEBUG of ul_i_dcif        : signal is "TRUE";
--    attribute MARK_DEBUG of ul_q_dcif        : signal is "TRUE";
--    attribute MARK_DEBUG of ul_bfn_strb_dcif : signal is "TRUE";

----    --FB data                                
--    attribute MARK_DEBUG of fb_sync_dcif     : signal is "TRUE";
--    attribute MARK_DEBUG of fb_i_dcif        : signal is "TRUE";
--    attribute MARK_DEBUG of fb_q_dcif        : signal is "TRUE";
--    attribute MARK_DEBUG of fb_bfn_strb_dcif : signal is "TRUE";

----    -- DSP OUTPUT UPLINK	             
--    attribute MARK_DEBUG of ul_sync_dsp      : signal is "TRUE";
--    attribute MARK_DEBUG of ul_iq_dsp        : signal is "TRUE";
--    attribute MARK_DEBUG of ul_bfn_strb_dsp  : signal is "TRUE";

----    -- BBCTRL OUTPUT                         
--    attribute MARK_DEBUG of s_uin_frame_sync : signal is "TRUE";
--    attribute MARK_DEBUG of s_uin_en         : signal is "TRUE";
--    attribute MARK_DEBUG of s_uin_i_array    : signal is "TRUE";
--    attribute MARK_DEBUG of s_uin_q_array    : signal is "TRUE";


------------------------ uplink --------------------

--attribute MARK_DEBUG of ptp_1pps_cpu_top : signal is "TRUE";  
--attribute MARK_DEBUG of w_otrx_txdis     : signal is "TRUE";  
--attribute MARK_DEBUG of OTRX_DISABLE     : signal is "TRUE";  
--attribute MARK_DEBUG of OTRX_TX_FAULT    : signal is "TRUE";  
--attribute MARK_DEBUG of OTRX_MOD_ABS     : signal is "TRUE";  
--attribute MARK_DEBUG of OTRX_LOS         : signal is "TRUE"; 

  
begin

    UDE_ETH_25MHz       <= clk_mii;
    CLK_OOK_B13_A_8M704 <= clk_ook_out;
    CLK_OOK_B13_C_8M704 <= clk_ook_out;
    
    ru_func_fail        <= FPGA_FUNCTION_FAIL_IN & function_fail_misc;
    
    SIG_SUS_OUT(0)      <= PWR55_NORMAL_IN;
    SIG_SUS_OUT(1)      <= vss_rmt_rst_sysctrl;
    SIG_SUS_OUT(2)      <= hwwdt_flag_sysctrl or sw_wdt_latch;
    
    RU_1PPS             <= ptp_1pps_cpu_top; -- when mux_sel(0) = '0' else equip_tdd_sel;
    OUT_1PPS            <= ptp_1pps_cpu_top;
    
    TP_CON              <= frame_sync_cpu_top(0)                 when tp_con_sel = x"00" else
                           s_din_frame_sync(0)                   when tp_con_sel = x"01" else
                           s_dout_frame_sync(0)                  when tp_con_sel = x"02" else
                           dl_sync_bbctrl(0)                     when tp_con_sel = x"03" else
                           dl_sync_dsp(0)                        when tp_con_sel = x"04" else
                           frame_sync_cpu_top(0);

    EQUIP_TDD           <= '1'; --equip_tdd_sel;
--    equip_tdd_sel     <= equip_10m  when mux_sel(1) = '0' else equip_tdd_out;
    
-- ***************************************************************************
-- ** U0 : SYSCTRL-TOP                                                      **
-- ***************************************************************************
    U0_SYSCTRL_TOP : SYSCTRL_TOP
    port map(
    --------------------------------------------------------------------------
    ----  FPGA_ID
    --------------------------------------------------------------------------
        FPGA_ID                             => FPGA_ID               ,
        FPGA_PCB_VER                        => FPGA_PCB_VER, --: in  std_logic_vector(2 downto 0);    
    --------------------------------------------------------------------------
    ----  PSU VER
    --------------------------------------------------------------------------
        PSU_VER                             => PSU_VER                       ,--      : in  std_logic;
    --**************************************************
    --BIAST enable
    --**************************************************
        BIAST_3P3V_EN                       => BIAST_3P3V_EN                 ,--      : out    std_logic;
        TCXO_OUT_PLL                        => TCXO_OUT_PLL                  ,--      : in  std_logic;
    --------------------------------------------------------------------------
    ----  External System PLL
    --------------------------------------------------------------------------
        EXT_SYSPLL_LOCK_IN(0)               => CLK_PLL_LD                    , --: in  std_logic_vector( 2 downto 0);
--        EXT_SYSPLL_LOCK_IN(1)               => '0'                           ,
        EXT_SYSPLL_LOCK_IN(1)               => '1'                           ,
        EXT_SYSPLL_LOCK_IN(2)               => '1'                           ,
        EXT_SYSPLL_LOS_IN                   => CLK_PLL_LOS                   , --: in  std_logic;
        EXT_SYSCLK_IN                       => FPGA_REF_CLK                  ,
        FPGA_SYSCLK_FB_IN                   => '0'                           ,
        FPGA_SYSCLK_FB_OUT                  => open                          ,
        MGT_REFCLK0_IN                      => '0', --MGT_REF_CLK_0                 ,
        MGT_REFCLK1_IN                      => MGT_REF_CLK_1                 ,
        MGT_REFCLK2_IN                      => MGT_REF_CLK_2                 ,
        MGT_REFCLK3_IN                      => MGT_REF_CLK_3                 ,
        MGT_REFCLK4_IN                      => MGT_REF_CLK_4                 ,
        PTP_REF_CLK                         => SYSTEM_TIMER_CLK              ,
        CLK_PTP                             => w_clk_ptp                     ,  
    --------------------------------------------------------------------------
    --  CPUTOP
    --------------------------------------------------------------------------
        CLK_CPUIF                           => clk_cpuif                     ,
        RST_CPUIF                           => rst_cpuif                     ,

    --------------------------------------------------------------------------
    --  CPUIF-TOP
    --------------------------------------------------------------------------
        ADDR_CPUIF_SYSCTRL_IN               => addr_cpuif_sysctrl            ,
        WDATA_CPUIF_SYSCTRL_IN              => wdata_cpuif_sysctrl           ,
        RDATA_CPUIF_SYSCTRL_OUT             => rdata_cpuif_sysctrl           ,
        WREN_CPUIF_SYSCTRL_IN               => wren_cpuif_sysctrl            ,
        RDEN_CPUIF_SYSCTRL_IN               => rden_cpuif_sysctrl            ,
        RDVAL_CPUIF_SYSCTRL_OUT             => rdval_cpuif_sysctrl           ,

    --------------------------------------------------------------------------
    --  SBIFPHY_TOP  --## DSP_FPGA_ONLY_PORT
    --------------------------------------------------------------------------
--        RST_SBIFPHY                         => rst_sbifphy                   ,
        REFCLK_SSERDES_OUT                  => refclk_sserdes                ,

    --------------------------------------------------------------------------
    --  SBIF_TOP  --## DSP_FPGA_ONLY_PORT
    --------------------------------------------------------------------------
        CLK_SYS                             => clk_sys                       ,
        CLK_SYSX2                           => clk_sysx2                     ,
        CLK_SYSX3                           => clk_sysx3                     ,
        CLK_SYSX4                           => clk_sysx4                     ,
        CLK_SYSX5                           => clk_sysx5                     ,
        CLK_SYSX6                           => clk_sysx6                     ,
        CLK_SYSX8                           => clk_sysx8                     ,
        CLK_SYSX10                          => clk_sysx10                    ,
        CLK_SYSX12                          => clk_sysx12                    ,
        CLK_SYSX16                          => clk_sysx16                    ,
        CLK_SYSX20                          => clk_sysx20                    ,

        CLK_TCXO_X1                         => CLK_TCXO_X1                   , -- : out std_logic;
        CLK_TCXO_X4                         => CLK_TCXO_X4                   , -- : out std_logic;
        CLK_TCXO_X8                         => CLK_TCXO_X8                   , --: out std_logic;    

    --------------------------------------------------------------------------
    --  CPRIPHY_TOP --CTRL FPGA
    --------------------------------------------------------------------------
        CLK_SBIF                            => clk_sbif                      ,
        CLK_SBIFXH                          => clk_sbifxh                    ,
        CLK_SBIFX2                          => clk_sbifx2                    ,

        REFCLK_CSERDES_OUT                  => refclk_cserdes                ,
        REFCLK_OSERDES_OUT                  => refclk_oserdes                ,
        REFCLK_SEL_IN                       => refclk_sel                    ,
    --------------------------------------------------------------------------
    --  ECPRI_MMCM --CTRL FPGA
    --------------------------------------------------------------------------
 
        SYSTEM_TIMER_MMCM_RST               => system_timer_mmcm_rst              ,--: out  std_logic;
        SYSTEM_TIMER_MMCM_LOCK              => system_timer_mmcm_lock             ,--: in   std_logic;

    --------------------------------------------------------------------------
    --  CPRI_TOP  --CTRL_FPGA
    --------------------------------------------------------------------------
        RST_IQCOMP                          => rst_iqcomp                    ,
        RST_ETHMUX                          => rst_ethmux                    ,
        CLK_MII                             => clk_mii                       ,
        CLK_MIIX2                           => clk_miix2                     ,
        CLK_MIIX4                           => clk_miix4                     ,
        CLK_MIIX8                           => clk_miix8                     ,
        RX_BFN_STRB_IN(0)                   => frame_sync_cpu_top(0)         ,
        RX_BFN_NR_IN(0)                     => sfn_num_cpu_top(11 downto 0)  , 
        TX_BFN_STRB_OUT                     => tx_bfn_strb_sysctrl           ,
        TX_BFN_NR_OUT                       => open , --tx_bfn_nr_sysctrl             ,
        RU_ID_OUT                           => ru_id_sysctrl                 ,
        RU_FF_OUT                           => ru_ff_sysctrl                 ,
        VSS_RMT_RST_CPRI_IN                 => vss_rmt_rst_cpri              ,
        IS_MASTER_CPRI_IN                   => is_master_cpri                , -- no uesd in verizon
        LINE_RCF_START_IN                   => line_rcf_start_cpri           , -- no uesd in verizon
        LINE_RCF_RATE_IN                    => line_rcf_rate_cpri            , -- no uesd in verizon
        LINE_RCF_CLKTYPE_IN                 => line_rcf_clktype_cpri         , -- no uesd in verizon
        LINE_RCF_WIDTH_IN                   => line_rcf_width_cpri           , -- no uesd in verizon

    --------------------------------------------------------------------------
    --  SBIF_TOP  --## CTRL_FPGA_ONLY_PORT BBCTRL-TOP
    --------------------------------------------------------------------------
        RX_BFN_STRB_OUT                     => rx_bfn_strb_sysctrl           ,
        RX_BFN_NR_OUT                       => rx_bfn_nr_sysctrl             ,
        RX_TDD_OUT                          => rx_tdd_sysctrl                ,   -- don't used in verizon
        TX_TDD_IN                           => (others => '1')               ,   -- tx_tdd_bbctrl                 ,   -- don't used in verizon
        TX_BFN_STRB_IN                      => (others => '0')               ,
        REFCLK_ASERDES_OUT                  => refclk_aserdes                ,
    ----------------------------------------------------------------------
    --  BBCTRL-TOP
    ----------------------------------------------------------------------
        INNER_DL_TDD_AND_CTRL_OUT           => open                          , --: out std_logic;          -- don't used in verizon
        INNER_DL_TDD_OR_CTRL_OUT            => open                          , --: out std_logic;          -- don't used in verizon
    --------------------------------------------------------------------------
    --  DSP-TOP  --## DSP_FPGA_ONLY_PORT
    --------------------------------------------------------------------------
        INT_SYSPLL_LOCK_OUT                 => int_syspll_lock               ,
        RST_BBCTRL                          => rst_bbctrl                    ,
        RST_DDUC                            => rst_dduc                      ,
        RST_CFR                             => rst_cfr                       ,
        RST_DPD                             => rst_dpd                       ,
    --------------------------------------------------------------------------
    --  DCIF-TOP --## DSP_FPGA_ONLY_PORT
    --------------------------------------------------------------------------
        RST_DCIF                            => rst_dcif                      ,
        REFCLK_JSERDES_OUT                  => refclk_jserdes                ,
    ----------------------------------------------------------------------
    -- RX_TDD relation ## DSP FPGA
    ---------------------------------------------------------------------
        DL_1PPS_BFN_STROBE_IN               => dl_bfn_strb_1pps_misc         ,
        INNER_RX_TDD_OUT                    => inner_rx_tdd_sysctrl          ,
        INNER_RX_BFN_STROBE_OUT             => inner_rx_bfn_strobe_sysctrl   ,
        DFPGA_TDD                           => open                          ,
    --------------------------------------------------------------------------
    --  MISC-TOP
    --------------------------------------------------------------------------
    -- CTRL_FPGA
        WATCHDOG_CLR                        => hw_watchdog_clr_cpuif         , --: in  std_logic;
        HWWDT_FLAG_OUT                      => hwwdt_flag_sysctrl            ,
        LED_CTRL_OUT                        => led_ctrl_sysctrl              ,
        FUNC_FAIL_TRIG_IN                   => ru_func_fail                  , --(others => '0')               ,
        VSS_RMT_RST_OUT                     => vss_rmt_rst_sysctrl           ,

        RST_PIM                             => rst_pim                       ,      -- need to check
        RST_PIM_SBIF                        => rst_pim_sbif                  ,      -- need to check
        RST_PIM_SBIF_PHY                    => rst_pim_sbif_phy              ,      -- need to check
    ------------------------------------------------------------------------
    -- NR SSB Parameter
    ------------------------------------------------------------------------
        NR_SSB_PERIOD                       => nr_ssb_period_sysctrl         , --: out std_logic_vector(4 downto 0);
        NR_SSB_OFFSET                       => nr_ssb_offset_sysctrl         , --: out std_logic_vector(3 downto 0);
        SECTOR_MODE                         => sector_mode_sysctrl           , --: out std_logic_vector(1 downto 0); 
        eMTC_SEL                            => emtc_sel_sysctrl              , --: out std_logic_vector(1 downto 0); 
    -- DSP_FPGA
        TDD_CTRL_OUT                        => tdd_ctrl                      ,
        OOK_CLK                             => clk_ook_out                   , --: out std_logic;           -- 8.704
        RST_MISC                            => rst_misc                      ,
        CLK_MISC0                           => clk_misc0                     ,
        CLK_MISC1                           => clk_misc1                     ,
        CLK_MISC2                           => clk_misc2                     ,
        CLK_MISC3                           => clk_misc3                     ,
--        SYSCTRL_ECPRIPHY_RST                => sysctrl_ecpriphy_rst          , --: out std_logic_vector( ECPRIPHY_NUM -1 downto 0 )  ; 
        SYSCTRL_ORAN_FRAMER_RST             => sysctrl_oran_framer_rst       , --: out std_logic_vector( DL_NUM_CC    -1 downto 0 )  ; 
        SYSCTRL_ORAN_DEFRAMER_RST           => sysctrl_oran_deframer_rst     , --: out std_logic_vector( UL_NUM_CC    -1 downto 0 )  ; 
        SYSCTRL_LPHY_TOP_RST                => sysctrl_lphy_top_rst          , --: out std_logic; 
        SYSCTRL_DLFE_RST                    => sysctrl_dlfe_rst              , --: out std_logic_vector( DL_NUM_CC    -1 downto 0 )  ; 
        SYSCTRL_ULFE_RST                    => sysctrl_ulfe_rst              , --: out std_logic_vector( UL_NUM_CC    -1 downto 0 )  ; 
        SYSCTRL_RAFE_RST                    => sysctrl_rafe_rst              , --: out std_logic_vector( UL_NUM_CC    -1 downto 0 )  ; 
        SYSCTRL_AURORA_RST                  => sysctrl_aurora_rst            , --: out std_logic 

        DL_CC0_SYNC_ADVANCE                 => dl_cc_sync_advance(22*1 -1 downto 0) , --: out std_logic_vector(21 downto 0);
        DL_CC1_SYNC_ADVANCE                 => dl_cc_sync_advance(22*2 -1 downto 22), --: out std_logic_vector(21 downto 0);
        UL_CC0_SYNC_RETARD                  => ul_cc_sync_retard(22*1 -1 downto 0)  , --: out std_logic_vector(21 downto 0);
        UL_CC1_SYNC_RETARD                  => open                                 ,--ul_cc_sync_retard(22*2 -1 downto 22)  --: out std_logic_vector(21 downto 0);
        N_TA_OFFSET_CC0                     => n_ta_offset(16 -1 downto 0)         , --: out  std_logic_vector(CELL_NUM_DL*16-1 downto 0);
        N_TA_OFFSET_CC1                     => n_ta_offset(32 -1 downto 16)        , --: out
        TP_CON_SEL                          => tp_con_sel                               ,--: out std_logic_vector(7 downto 0);
        
        FRAME_SYNC_C2C                      => FRAME_SYNC_C2C                       ,--: out std_logic                     -- active high(10ms -PROC_DLY @ 245.76 MHz)@SFN_NUM#0
        SFN_NUM_C2C                         => SFN_NUM_C2C                           --: out std_logic                     -- active high(10ms -PROC_DLY @ 245.76 MHz)@SFN_NUM#0
    );

    --OTRX_DISABLE(1)      <= ptp_1pps_cpu_top ;
    
	U7_OTRX_1PPS : OTRX_DBG 
    port map (
        PTP_1PPS             => 	ptp_1pps_cpu_top, 
        OTRX_DISABLE_CPU     => 	w_otrx_txdis  , 
        OTRX_DISABLE         => 	OTRX_DISABLE  , 
        OTRX_TX_FAULT        => 	OTRX_TX_FAULT , 
        OTRX_MOD_ABS         => 	OTRX_MOD_ABS  , 
        OTRX_LOS             => 	OTRX_LOS        
    ); 
       
    OTRX_BH_RS0          <= otrx_bh_rs_r(0);
    OTRX_BH_RS1          <= otrx_bh_rs_r(1);
    
    U1_ECPRIPHY_TOP : ECPRIPHY_TOP
    port map (
--------------------------------------------------------------------------------
-- Pin
--------------------------------------------------------------------------------

        OTRX_DEL_IN                         => OTRX_MOD_ABS                  , --: in  std_logic_vector(1 downto 0);
        OTRX_LOS_IN                         => OTRX_LOS                      , --: in  std_logic_vector(1 downto 0);
        OTRX_TXFAULT_IN                     => OTRX_TX_FAULT                 , --: in  std_logic_vector(1 downto 0);
        OTRX_TXDIS_OUT                      => w_otrx_txdis               , --: out std_logic_vector(1 downto 0);
        OTRX_BH_RS_OUT                      => otrx_bh_rs_r                  , --: out std_logic_array2(1 downto 0);

--------------------------------------------------------------------------------
-- CPU-TOP
--------------------------------------------------------------------------------
        ECPRI_GT_RESET_RX_DONE              => ecpri_gt_reset_rx_done     , --: in  std_logic;
        ECPRI_GT_RESET_TX_DONE              => ecpri_gt_reset_tx_done     , --: in  std_logic;
        ECPRI_STAT_RX_BLOCK_LOCK            => ecpri_stat_rx_block_lock   , --: in  std_logic;
        ECPRI_STAT_RX_LOCAL_FAULT           => ecpri_stat_rx_local_fault  , --: in  std_logic;
        ECPRI_STAT_RX_REMOTE_FAULT          => ecpri_stat_rx_remote_fault ,
--        ECPRI_STAT_RX_STATUS                => ECPRI_STAT_RX_STATUS     (0)  , --: in  std_logic;
        ECPRI_STAT_RX_RATE_10G_25GN         => ecpri_stat_rx_rate_10g_25gn , --in  std_logic_vector(1 downto 0); -- deleted (10G only)
        ECPRI_GT_RXLPMEN                    => ecpri_gt_rxlpmen           , --: out std_logic;
        ECPRI_GT_TXDIFFCTRL                 => ecpri_gt_txdiffctrl        , --: out std_logic_vector(4 downto 0);
        ECPRI_TXPRECURSOR                   => ecpri_txprecursor          , --: out std_logic_vector(4 downto 0);
        ECPRI_TXPOSTCUSOR                   => ecpri_txpostcusor          , --: out std_logic_vector(4 downto 0);
        MODE_CHANGE_25N_10H                 => mode_change_25n_10h        , --: out std_logic_vector(1 downto 0); -- deleted (10G only)
        RX_WDT_RESET                        => rx_wdt_reset               , --: out std_logic;
        MAC_SYS_RESET                       => mac_sys_reset              , --: out std_logic;
        DMA_BLOCK_RESET                     => dma_block_reset            , --: out std_logic;

--------------------------------------------------------------------------------
-- CPU-TOP
--------------------------------------------------------------------------------

        CLK_CPUIF                           => clk_cpuif                     , --: in  std_logic;
        RST_CPUIF                           => rst_cpuif                     , --: in  std_logic;

--------------------------------------------------------------------------------
-- CPUIF-TOP
--------------------------------------------------------------------------------
        ADDR_CPUIF_IN                       => addr_cpuif_ecpriphy           , --: in  std_logic_vector(15 downto 0);
        WDATA_CPUIF_IN                      => wdata_cpuif_ecpriphy          , --: in  std_logic_vector(31 downto 0);
        RDATA_CPUIF_OUT                     => rdata_cpuif_ecpriphy          , --: out std_logic_vector(31 downto 0);
        WREN_CPUIF_IN                       => wren_cpuif_ecpriphy           , --: in  std_logic;
        RDEN_CPUIF_IN                       => rden_cpuif_ecpriphy           , --: in  std_logic;
        RDVAL_CPUIF_OUT                     => rdval_cpuif_ecpriphy           --: out std_logic
    );
    
    UDE_ETH_TXD       <= gmii_txd_out(3 downto 0);    
    gmii_rxd_in       <= x"0" & UDE_ETH_RXD;
    
    U_MPSoC_CPU_TOP : CPU_TOP
    port map(
        CLK_122P88M_IN              => clk_sysx4                               ,--: in    std_logic;
        CLK_CPU_OUT                 => clk_cpuif                               ,--: out   std_logic;
        RST_CPU_OUT                 => rst_cpuif                               ,--: out   std_logic;
        ADDR_CPU_OUT                => addr_fpga                               ,--: out   std_logic_vector(19 downto 0);
        CS_CPU_OUT                  => cs_fpga                                 ,--: out   std_logic;
        RDEN_CPU_OUT                => rden_fpga                               ,--: out   std_logic;
        RDATA_CPU_IN                => rdata_fpga                              ,--: in    std_logic_vector(31 downto 0);
        WDATA_CPU_OUT               => wdata_fpga                              ,--: out   std_logic_vector(31 downto 0);
        WREN_CPU_OUT                => wren_fpga                               ,--: out   std_logic;

        CLK_50M_OUT                 => clk_50m                                  ,--: out   std_logic;
        CLK_TIMER                   => w_clk_ptp                                ,-- input
        gt_refclk_0                 => MGT_REF_CLK_0                            , --: in STD_LOGIC;
        gt_refclk_1                 => MGT_REF_CLK_0                            , --: in STD_LOGIC;
        GMII_COL_IN(0)              => UDE_ETH_COL                              ,--: in    std_logic_vector(0 downto 0);
        GMII_CRS_IN(0)              => UDE_ETH_CRS                              ,--: in    std_logic_vector(0 downto 0);
        GMII_RXCLK_IN(0)            => UDE_ETH_RXC                              ,--: in    std_logic_vector(0 downto 0);
        GMII_RXDV_IN(0)             => UDE_ETH_RXDV                             ,--: in    std_logic_vector(0 downto 0);
        GMII_RXER_IN(0)             => UDE_ETH_RXER                             ,--: in    std_logic_vector(0 downto 0);
        GMII_RXD_IN(0)              => gmii_rxd_in                              ,--: in    std_logic_array8(0 downto 0);
        GMII_TXCLK_IN(0)            => UDE_ETH_TXC                              ,--: in    std_logic_vector(0 downto 0);
        GMII_TXEN_OUT(0)            => UDE_ETH_TXEN                             ,--: out   std_logic_vector(0 downto 0);
        GMII_TXER_OUT(0)            => UDE_ETH_TXER                             ,--: out   std_logic_vector(0 downto 0);
        GMII_TXD_OUT(0)             => gmii_txd_out                             ,--: out   std_logic_array8(0 downto 0);

        MDIO_ETHERNET_MDC           => UDE_ETH_MDC                              ,--: out   std_logic;
        MDIO_ETHERNET_MDIO_IO       => UDE_ETH_MDIO                             ,--: inout std_logic;

        IIC_SIT5356_SCL             => IIC_SCL_IO(0)                            ,--: inout std_logic;
        IIC_SIT5356_SDA             => IIC_SDA_IO(0)                            ,--: inout std_logic;
        
        AMC_SPI_CLK                 => AMC_SPI_CLK                              ,--: out std_logic;
        AMC_SPI_CS                  => AMC_SPI_CS1_OUT                          ,--: out std_logic;
        AMC_SPI_DI                  => AMC_SPI_M_OUT                            ,--: out std_logic;
        AMC_SPI_DO                  => AMC_SPI_M_IN                             ,--: in  std_logic;
        
        SPI0_BRAM_ADDR              => rfic_spi_buf_addr_misc(0)                            ,--: in  STD_LOGIC_VECTOR(31 downto 0);
        SPI0_BRAM_CLK               => rfic_spi_buf_clk_misc(0)                    ,--: in  STD_LOGIC;
        SPI0_BRAM_DIN               => rfic_spi_buf_din_misc(0)                    ,--: in  STD_LOGIC_VECTOR(31 downto 0);
        SPI0_BRAM_DOUT              => rfic_spi_buf_dout_cpu(0)                    ,--: out STD_LOGIC_VECTOR(31 downto 0);
        SPI0_BRAM_EN                => rfic_spi_buf_en_misc(0)                     ,--: in  STD_LOGIC;
        SPI0_BRAM_RST               => rfic_spi_buf_rst_misc(0)                    ,--: in  STD_LOGIC;
        SPI0_BRAM_WE                => rfic_spi_buf_we_misc(0)                     ,--: in  STD_LOGIC_VECTOR(3 downto 0);

    -- check sau
        FPGA_RFIC_SPI1_SCLK         =>  rfic_spi_ip_sclk_cpu(0), --                   ,--: out std_logic;
        FPGA_RFIC_SPI1_CSB          =>  rfic_spi_ip_ss_cpu(0), --                   ,--: out std_logic;
        FPGA_RFIC_SPI1_SDIO         =>  rfic_spi_ip_mosi_cpu(0), --                   ,--: out std_logic;
        FPGA_RFIC_SPI1_SDO          =>  rfic_spi_ip_miso_misc(0),--                   ,--: in  std_logic;
        
        FPGA_RFIC_SPI2_SCLK         =>  O_SPI_SCK_IO(1)  , --                    ,--: out std_logic;
        FPGA_RFIC_SPI2_CSB          =>  O_SPI_SS_IO(1)   , --                    ,--: out std_logic;
        FPGA_RFIC_SPI2_SDIO         =>  O_SPI_MOSI_IO(1) , --                    ,--: out std_logic;
        FPGA_RFIC_SPI2_SDO          =>  I_SPI_MISO_IO(1) , --                    ,--: in  std_logic;

        JESD204B_M_AXI_0_araddr     => JESD_AXI_INTERCONNECT_araddr_cpu          ,--: out STD_LOGIC_VECTOR( 31 downto 0 );
        JESD204B_M_AXI_0_arburst    => JESD_AXI_INTERCONNECT_arburst_cpu         ,--: out STD_LOGIC_VECTOR( 1 downto 0 );
        JESD204B_M_AXI_0_arcache    => JESD_AXI_INTERCONNECT_arcache_cpu         ,--: out STD_LOGIC_VECTOR( 3 downto 0 );
        JESD204B_M_AXI_0_arlen      => JESD_AXI_INTERCONNECT_arlen_cpu           ,--: out STD_LOGIC_VECTOR( 7 downto 0 );
        JESD204B_M_AXI_0_arlock     => JESD_AXI_INTERCONNECT_arlock_cpu          ,--: out STD_LOGIC_VECTOR( 0 to 0 );
        JESD204B_M_AXI_0_arprot     => JESD_AXI_INTERCONNECT_arprot_cpu          ,--: out STD_LOGIC_VECTOR( 2 downto 0 );
        JESD204B_M_AXI_0_arqos      => JESD_AXI_INTERCONNECT_arqos_cpu           ,--: out STD_LOGIC_VECTOR( 3 downto 0 );
        JESD204B_M_AXI_0_arready    => JESD_AXI_INTERCONNECT_arready_dcif        ,--: in STD_LOGIC;
        JESD204B_M_AXI_0_arregion   => JESD_AXI_INTERCONNECT_arregion_cpu        ,--: out STD_LOGIC_VECTOR( 3 downto 0 );
        JESD204B_M_AXI_0_arsize     => JESD_AXI_INTERCONNECT_arsize_cpu          ,--: out STD_LOGIC_VECTOR( 2 downto 0 );
        JESD204B_M_AXI_0_arvalid    => JESD_AXI_INTERCONNECT_arvalid_cpu         ,--: out STD_LOGIC;
        JESD204B_M_AXI_0_awaddr     => JESD_AXI_INTERCONNECT_awaddr_cpu          ,--: out STD_LOGIC_VECTOR( 31 downto 0 );
        JESD204B_M_AXI_0_awburst    => JESD_AXI_INTERCONNECT_awburst_cpu         ,--: out STD_LOGIC_VECTOR( 1 downto 0 );
        JESD204B_M_AXI_0_awcache    => JESD_AXI_INTERCONNECT_awcache_cpu         ,--: out STD_LOGIC_VECTOR( 3 downto 0 );
        JESD204B_M_AXI_0_awlen      => JESD_AXI_INTERCONNECT_awlen_cpu           ,--: out STD_LOGIC_VECTOR( 7 downto 0 );
        JESD204B_M_AXI_0_awlock     => JESD_AXI_INTERCONNECT_awlock_cpu          ,--: out STD_LOGIC_VECTOR( 0 to 0 );
        JESD204B_M_AXI_0_awprot     => JESD_AXI_INTERCONNECT_awprot_cpu          ,--: out STD_LOGIC_VECTOR( 2 downto 0 );
        JESD204B_M_AXI_0_awqos      => JESD_AXI_INTERCONNECT_awqos_cpu           ,--: out STD_LOGIC_VECTOR( 3 downto 0 );
        JESD204B_M_AXI_0_awready    => JESD_AXI_INTERCONNECT_awready_dcif        ,--: in STD_LOGIC;
        JESD204B_M_AXI_0_awregion   => JESD_AXI_INTERCONNECT_awregion_cpu        ,--: out STD_LOGIC_VECTOR( 3 downto 0 );
        JESD204B_M_AXI_0_awsize     => JESD_AXI_INTERCONNECT_awsize_cpu          ,--: out STD_LOGIC_VECTOR( 2 downto 0 );
        JESD204B_M_AXI_0_awvalid    => JESD_AXI_INTERCONNECT_awvalid_cpu         ,--: out STD_LOGIC;
        JESD204B_M_AXI_0_bready     => JESD_AXI_INTERCONNECT_bready_cpu          ,--: out STD_LOGIC;
        JESD204B_M_AXI_0_bresp      => JESD_AXI_INTERCONNECT_bresp_dcif          ,--: in STD_LOGIC_VECTOR( 1 downto 0 );
        JESD204B_M_AXI_0_bvalid     => JESD_AXI_INTERCONNECT_bvalid_dcif         ,--: in STD_LOGIC;
        JESD204B_M_AXI_0_rdata      => JESD_AXI_INTERCONNECT_rdata_dcif          ,--: in STD_LOGIC_VECTOR( 31 downto 0 );
        JESD204B_M_AXI_0_rlast      => JESD_AXI_INTERCONNECT_rlast_dcif          ,--: in STD_LOGIC;
        JESD204B_M_AXI_0_rready     => JESD_AXI_INTERCONNECT_rready_cpu          ,--: out STD_LOGIC;
        JESD204B_M_AXI_0_rresp      => JESD_AXI_INTERCONNECT_rresp_dcif          ,--: in STD_LOGIC_VECTOR( 1 downto 0 );
        JESD204B_M_AXI_0_rvalid     => JESD_AXI_INTERCONNECT_rvalid_dcif         ,--: in STD_LOGIC;
        JESD204B_M_AXI_0_wdata      => JESD_AXI_INTERCONNECT_wdata_cpu           ,--: out STD_LOGIC_VECTOR( 31 downto 0 );
        JESD204B_M_AXI_0_wlast      => JESD_AXI_INTERCONNECT_wlast_cpu           ,--: out STD_LOGIC;
        JESD204B_M_AXI_0_wready     => JESD_AXI_INTERCONNECT_wready_dcif         ,--: in STD_LOGIC;
        JESD204B_M_AXI_0_wstrb      => JESD_AXI_INTERCONNECT_wstrb_cpu           ,--: out STD_LOGIC_VECTOR( 3 downto 0 );
        JESD204B_M_AXI_0_wvalid     => JESD_AXI_INTERCONNECT_wvalid_cpu          ,--: out STD_LOGIC;

        CLK_OCXO_BUFG_I             => TCXO_OUT_PLL                             ,--: in    std_logic;
        CLK_OCXO_BUFG_O             => REF_CLK_OUT                              ,--: out   std_logic;

        PTP_1PPS                    => ptp_1pps_cpu_top                         ,--: out   std_logic;
        PTP_EVEN                    => open                                     ,--: out   std_logic;
        FRAME_SYNC                  => frame_sync_cpu_top(0)                    ,--: out   STD_LOGIC;
        SFN_NUM                     => sfn_num_cpu_top(9 downto 0)              ,--: out   STD_LOGIC_VECTOR ( 9 downto 0 );
        RESET_MMCM_250M             => '0'                                      ,--: in    std_logic;
        DACOUT                      => PWM_FROM_MFPGA                           ,--: out   std_logic;
        CLK_245P76_0                => clk_sysx8                                ,--: in    std_logic;
                
--        ECPRI_GT_REF_CLK_0_N        => ECPRI_GT_REF_CLK_0_N                      ,--: in    std_logic;
--        ECPRI_GT_REF_CLK_0_P        => ECPRI_GT_REF_CLK_0_P                      ,--: in    std_logic;
--        ECPRI_GT_REF_CLK_1_N        => ECPRI_MGT_REF_CLK_1_N                   ,--: in    std_logic;
--        ECPRI_GT_REF_CLK_1_P        => ECPRI_MGT_REF_CLK_1_P                   ,--: in    std_logic;
        ECPRI_GT_RX_N_0               => DU_RU_N(0)                               ,--: in    std_logic;
        ECPRI_GT_RX_P_0               => DU_RU_P(0)                               ,--: in    std_logic;
        ECPRI_GT_TX_N_0               => RU_DU_N(0)                               ,--: out   std_logic;
        ECPRI_GT_TX_P_0               => RU_DU_P(0)                               ,--: out   std_logic;

        ECPRI_GT_RX_N_1               => DU_RU_N(1)                               ,--: in    std_logic;
        ECPRI_GT_RX_P_1               => DU_RU_P(1)                               ,--: in    std_logic;
        ECPRI_GT_TX_N_1               => RU_DU_N(1)                               ,--: out   std_logic;
        ECPRI_GT_TX_P_1               => RU_DU_P(1)                               ,--: out   std_logic;


        ECPRI_GT_RESET_RX_DONE_0      => ecpri_gt_reset_rx_done(0)                ,--: out   std_logic;
        ECPRI_GT_RESET_TX_DONE_0      => ecpri_gt_reset_tx_done(0)                ,--: out   std_logic;
        ECPRI_STAT_RX_BLOCK_LOCK_0    => ecpri_stat_rx_block_lock(0)              ,--: out   std_logic;
        ECPRI_STAT_RX_LOCAL_FAULT_0   => ecpri_stat_rx_local_fault(0)             ,--: out   std_logic;
        ECPRI_STAT_RX_RATE_10G_25GN_0 => ecpri_stat_rx_rate_10g_25gn(0)           ,--: out   std_logic;
        ECPRI_STAT_RX_REMOTE_FAULT_0  => ecpri_stat_rx_remote_fault(0)            ,--: out   std_logic;
        
        ECPRI_GT_RESET_RX_DONE_1      => ecpri_gt_reset_rx_done(1)                ,--: out   std_logic;
        ECPRI_GT_RESET_TX_DONE_1      => ecpri_gt_reset_tx_done(1)                ,--: out   std_logic;
        ECPRI_STAT_RX_BLOCK_LOCK_1    => ecpri_stat_rx_block_lock(1)              ,--: out   std_logic;
        ECPRI_STAT_RX_LOCAL_FAULT_1   => ecpri_stat_rx_local_fault(1)             ,--: out   std_logic;
        ECPRI_STAT_RX_RATE_10G_25GN_1 => ecpri_stat_rx_rate_10g_25gn(1)           ,--: out   std_logic;
        ECPRI_STAT_RX_REMOTE_FAULT_1  => ecpri_stat_rx_remote_fault(1)            ,--: out   std_logic;

        ECPRI_GT_RXLPMEN_0            => ecpri_gt_rxlpmen(0)                      ,--: in    std_logic_vector(1 downto 0);
        ECPRI_GT_TXDIFFCTRL_0         => ecpri_gt_txdiffctrl(0)                   ,--: in    std_logic_array5(1 downto 0);
        ECPRI_TXPRECURSOR_0           => ecpri_txprecursor(0)                     ,--: in    std_logic_array5(1 downto 0);
        ECPRI_TXPOSTCUSOR_0           => ecpri_txpostcusor(0)                     ,--: in    std_logic_array5(1 downto 0);

        MODE_CHANGE_25N_10H_0         => mode_change_25n_10h(0)                   ,--: in    std_logic_vector(1 downto 0);
        
        ECPRI_GT_RXLPMEN_1            => ecpri_gt_rxlpmen(1)                      ,--: in    std_logic_vector(1 downto 0);
        ECPRI_GT_TXDIFFCTRL_1         => ecpri_gt_txdiffctrl(1)                   ,--: in    std_logic_array5(1 downto 0);
        ECPRI_TXPRECURSOR_1           => ecpri_txprecursor(1)                     ,--: in    std_logic_array5(1 downto 0);
        ECPRI_TXPOSTCUSOR_1           => ecpri_txpostcusor(1)                     ,--: in    std_logic_array5(1 downto 0);

        MODE_CHANGE_25N_10H_1         => mode_change_25n_10h(1)                   ,--: in    std_logic_vector(1 downto 0);

        RX_WDT_RESET_0                => rx_wdt_reset(0)                          ,--: in    std_logic;
        RX_WDT_RESET_1                => rx_wdt_reset(1)                          ,--: in    std_logic;
        MAC_SYS_RESET                 => mac_sys_reset                            ,--: in    std_logic;
        DMA_BLOCK_RESET               => dma_block_reset                          ,--: in    std_logic;

        CLK_MAC_RX_0                  => l0_deframer_clk                               ,--: out   std_logic;
        CLK_MAC_RX_1                  => open, --l0_deframer_clk                               ,--: out   std_logic;

        MAC_RX_VALID_0                => mac0_rx_valid                             ,--: out   std_logic_vector(1 downto 0);
        MAC_RX_LAST_0                 => mac0_rx_last                              ,--: out   std_logic_vector(1 downto 0);
        MAC_RX_KEEP_0                 => mac0_rx_keep                              ,--: out   std_logic_array8(1 downto 0);
        MAC_RX_DATA_0                 => mac0_rx_data                              ,--: out   std_logic_array64(1 downto 0);

        MAC_TX_READY_0(0)             => mac0_tx_ready                             ,--: out   std_logic_vector(3 downto 0);
        MAC_TX_VALID_0(0)             => mac0_tx_valid                             ,--: in    std_logic_vector(3 downto 0);
        MAC_TX_LAST_0(0)              => mac0_tx_last                              ,--: in    std_logic_vector(3 downto 0);
        MAC_TX_KEEP_0(0)              => mac0_tx_keep                              ,--: in    std_logic_array8(3 downto 0);
        MAC_TX_DATA_0(0)              => mac0_tx_data                              ,--: in    std_logic_array64(3 downto 0)
        
        MAC_RX_VALID_1                => open, --mac0_rx_valid                     ,--: out   std_logic_vector(1 downto 0);
        MAC_RX_LAST_1                 => open, --mac0_rx_last                      ,--: out   std_logic_vector(1 downto 0);
        MAC_RX_KEEP_1                 => open, --mac0_rx_keep                      ,--: out   std_logic_array8(1 downto 0);
        MAC_RX_DATA_1                 => open, --mac0_rx_data                      ,--: out   std_logic_array64(1 downto 0);

        MAC_TX_READY_1(0)             => open, --mac0_tx_ready                     ,--: out   std_logic_vector(3 downto 0);
        MAC_TX_VALID_1(0)             => '0', --mac0_tx_valid                      ,--: in    std_logic_vector(3 downto 0);
        MAC_TX_LAST_1(0)              => '0', --mac0_tx_last                       ,--: in    std_logic_vector(3 downto 0);
        MAC_TX_KEEP_1(0)              => (others => '0'), --mac0_tx_keep                              ,--: in    std_logic_array8(3 downto 0);
        MAC_TX_DATA_1(0)              => (others => '0'), --mac0_tx_data                              ,--: in    std_logic_array64(3 downto 0)

        -- SW Reset Monitoring for Signal Suspension
        EMIO_GPIO                   => emio_gpio_o_0                               ,--: out   std_logic_vector ( 0 to 0 );
        EMIO_WDT1                   => emio_wdt1_rst_o_0                           ,     --: out   std_logic
        
        UART_RET_rxd                => s_UART_RET_rxd,   
        UART_RET_txd                => s_UART_RET_txd
    );   

    process (rst_cpuif, clk_cpuif)
    begin
        if (rst_cpuif = '1') then
            sw_wdt_det   <= '0';
            sw_wdt_latch <= '0';
        elsif (clk_cpuif = '1' and clk_cpuif'event) then
            sw_wdt_det <= emio_wdt1_rst_o_0 or emio_gpio_o_0(0);
            if sw_wdt_det = '1' then
                sw_wdt_latch <= '1';
            end if;
        end if;
    end process;

--SIG_SUS_OUT(3) <= sw_wdt_latch;


--    U2_ORAN_TOP : O_RAN_TOP
--        generic map (
--            CELL_NUM_DL                         => 2,  -- : natural :=  2;                            
--            CELL_NUM_UL                         => 2,  -- : natural :=  1; 
--            PATH_NUM                            => 4   -- : natural :=  4                             
--        )
--        port map(
--    --------------------------------------------------------------------------------
--    -- Clock & Reset
--    --------------------------------------------------------------------------------
--            CLK_CPUIF                           => clk_cpuif                    , --: in  std_logic;
--            RST_CPUIF                           => rst_cpuif                    , --: in  std_logic;
--            ARESET_RX (0)                       => sysctrl_oran_deframer_rst(0) , --: in  std_logic_vector(0 downto 0);
--            ARESET_TX (0)                       => sysctrl_oran_framer_rst(0)   , --: in  std_logic_vector(0 downto 0);
--            CLK_MAC_RX                          => l0_deframer_clk              , --: in  std_logic;                            -- 156.25/390.625-MHz
--            CLK_MAC_TX                          => l0_deframer_clk              , --: in  std_logic;                            -- 156.25/390.625-MHz
--            CLK_BUS                             => clk_sysx8                    , --: in  std_logic;                            -- 245.76-MHz
--    --------------------------------------------------------------------------------
--    -- Sync
--    --------------------------------------------------------------------------------
    
--            FRAME_SYNC                          => frame_sync_cpu_top(0)        , --: in  std_logic;                            -- should be aligned with 1PPS 
--    --        BFN_NUM_IN                          => (others =>'0')               , --: in  std_logic_vector(11 downto 0);
--            BFN_NUM_IN                          => sfn_num_cpu_top              , --: in  std_logic_vector(11 downto 0);
    
--            DL_CC_SYNC_ADVANCE                  => dl_cc_sync_advance           , --: in  std_logic_vector(CELL_NUM*22-1 downto 0);
--            UL_CC_SYNC_RETARD                   => ul_cc_sync_retard            , --: in  std_logic_vector(CELL_NUM*22-1 downto 0);
--            N_TA_OFFSET                         => n_ta_offset                  , --: in  std_logic_vector(CELL_NUM_DL*16-1 downto 0);
    
--    --------------------------------------------------------------------------------
--    -- CPU interface
--    --------------------------------------------------------------------------------
    
--            ADDR_CPUIF_IN                       => addr_cpuif_cpri              , --: in  std_logic_vector(15 downto 0);
--            WDATA_CPUIF_IN                      => wdata_cpuif_cpri             , --: in  std_logic_vector(31 downto 0);
--            RDATA_CPUIF_OUT                     => rdata_cpuif_cpri             , --: out std_logic_vector(31 downto 0);
--            WREN_CPUIF_IN                       => wren_cpuif_cpri              , --: in  std_logic;
--            RDEN_CPUIF_IN                       => rden_cpuif_cpri              , --: in  std_logic;
--            RDVAL_CPUIF_OUT                     => rdval_cpuif_cpri             , --: out std_logic;
    
--    --------------------------------------------------------------------------------
--    -- MAC#0
--    --------------------------------------------------------------------------------
    
--            MAC0_RX_VALID                       => mac0_rx_valid(0)                , --: in  std_logic;
--            MAC0_RX_LAST                        => mac0_rx_last(0)                 , --: in  std_logic;
--            MAC0_RX_KEEP                        => mac0_rx_keep(0)                 , --: in  std_logic_vector(7 downto 0);
--            MAC0_RX_DATA                        => mac0_rx_data(0)                 , --: in  std_logic_vector(63 downto 0);
                                                                                
--            MAC0_TX_READY                       => mac0_tx_ready                , --: in  std_logic;
--            MAC0_TX_VALID                       => mac0_tx_valid                , --: out std_logic;
--            MAC0_TX_LAST                        => mac0_tx_last                 , --: out std_logic;
--            MAC0_TX_KEEP                        => mac0_tx_keep                 , --: out std_logic_vector(7 downto 0);
--            MAC0_TX_DATA                        => mac0_tx_data                 , --: out std_logic_vector(63 downto 0);
    
--    --------------------------------------------------------------------------------
--    -- External port (Aurora)
--    --------------------------------------------------------------------------------
    
--            EXT_RU_RX_TVALID                    => ext_ru_rx_tvalid             , --: out std_logic;
--            EXT_RU_RX_TLAST                     => ext_ru_rx_tlast              , --: out std_logic;
--            EXT_RU_RX_TKEEP                     => ext_ru_rx_tkeep              , --: out std_logic_vector(7 downto 0);
--            EXT_RU_RX_TDATA                     => ext_ru_rx_tdata              , --: out std_logic_vector(63 downto 0);
                                                                                
--            EXT_RU_TX_TREADY                    => ext_ru_tx_tready             , --: out std_logic;
--            EXT_RU_TX_TVALID                    => ext_ru_tx_tvalid             , --: in  std_logic;
--            EXT_RU_TX_TLAST                     => ext_ru_tx_tlast              , --: in  std_logic;
--            EXT_RU_TX_TKEEP                     => ext_ru_tx_tkeep              , --: in  std_logic_vector(7 downto 0);
--            EXT_RU_TX_TDATA                     => ext_ru_tx_tdata              , --: in  std_logic_vector(63 downto 0);
    
--    --------------------------------------------------------------------------------
--    -- DLFE
--    --------------------------------------------------------------------------------
    
--            DLFE_CC_SYSTEM_MODE                 => s_dout_dl_sys_mode           , --: in  std_logic_vector(CELL_NUM*1-1 downto 0);  
--            DLFE_CC_K0                          => s_dout_dl_k0                 , --: in  std_logic_vector(CELL_NUM*12-1 downto 0);
--            DLFE_CC_nRE                         => s_dout_dl_ntone              , --: in  std_logic_vector(CELL_NUM*12-1 downto 0);  
--            DLFE_CC_nFFT                        => s_dout_dl_fft_type           , --: in  std_logic_vector(CELL_NUM*2-1 downto 0);                                    
--            DLFE_CC_BFN_NUM_OUT                 => open                         , --: out std_logic_vector(CELL_NUM*12-1 downto 0);
--            DLFE_CC_FRAME_SYNC                  => s_din_frame_sync             , --: out std_logic_vector(CELL_NUM*1-1 downto 0);
--            DLFE_CC_FRAME_INDEX                 => s_din_frame_idx              , --: out std_logic_vector(CELL_NUM*8-1 downto 0);
--            DLFE_CC_FRAME_STRUCTURE             => open                         , --: out std_logic_vector(CELL_NUM*8-1 downto 0);
--            DLFE_CC_SYSTEM_MODE_DSS             => s_dlfe_cc_system_mode_dss    , --: out std_logic_vector(CELL_NUM*PATH_NUM*1-1 downto 0); 
--            DLFE_CC_VALID                       => s_din_en                     , --: out std_logic_vector(CELL_NUM*PATH_NUM*1-1 downto 0);                       
--            DLFE_CC_RE_MASK                     => s_din_re_mask                , --: out std_logic_vector(CELL_NUM*PATH_NUM*1-1 downto 0);
--            DLFE_CC_DATA                        => s_din_iq                     , --: out std_logic_vector(CELL_NUM*PATH_NUM*32-1 downto 0); 
    
--    --------------------------------------------------------------------------------
--    -- ULFE
--    --------------------------------------------------------------------------------
    
--            ULFE_CC_FRAME_ID                    => s_uout_frame_idx      , --: in  std_logic_vector(CELL_NUM*8-1 downto 0);  
--            ULFE_CC_SUBFRAME_ID                 => s_uout_subfrm_idx     , --: in  std_logic_vector(CELL_NUM*4-1 downto 0);  
--            ULFE_CC_SLOT_ID                     => s_uout_slot_idx       , --: in  std_logic_vector(CELL_NUM*6-1 downto 0);  
--            ULFE_CC_SYMBOL_ID                   => s_uout_symbol_idx     , --: in  std_logic_vector(CELL_NUM*6-1 downto 0);  
--            ULFE_CC_START_RE                    => s_uout_start_re_idx   , --: in  std_logic_vector(CELL_NUM*PATH_NUM*16-1 downto 0); 
--            ULFE_CC_VALID                       => s_uout_en             , --: in  std_logic_vector(CELL_NUM*PATH_NUM*1-1 downto 0);  
--            ULFE_CC_START                       => s_uout_start_re       , --: in  std_logic_vector(CELL_NUM*PATH_NUM*1-1 downto 0);  
--            ULFE_CC_LAST                        => s_uout_last_re        , --: in  std_logic_vector(CELL_NUM*PATH_NUM*1-1 downto 0);  
--            ULFE_CC_DATA                        => s_uout_iq             , --: in  std_logic_vector(CELL_NUM*PATH_NUM*32-1 downto 0);
    
--    --------------------------------------------------------------------------------
--    -- RAFE
--    --------------------------------------------------------------------------------
    
--            RAFE_CC_FRAME_ID                    => s_rout_frame_idx      , --: in  std_logic_vector(CELL_NUM*8-1 downto 0);
--            RAFE_CC_SUBFRAME_ID                 => s_rout_subfrm_idx     , --: in  std_logic_vector(CELL_NUM*4-1 downto 0);
--            RAFE_CC_SLOT_ID                     => s_rout_slot_idx       , --: in  std_logic_vector(CELL_NUM*6-1 downto 0);
--            RAFE_CC_SYMBOL_ID                   => s_rout_symbol_idx     , --: in  std_logic_vector(CELL_NUM*6-1 downto 0);
--            RAFE_CC_START_RE                    => s_rout_start_re_idx   , --: in  std_logic_vector(CELL_NUM*PATH_NUM*16-1 downto 0);
--            RAFE_CC_VALID                       => s_rout_en             , --: in  std_logic_vector(CELL_NUM*PATH_NUM*1-1 downto 0); 
--            RAFE_CC_START                       => s_rout_start_re       , --: in  std_logic_vector(CELL_NUM*PATH_NUM*1-1 downto 0); 
--            RAFE_CC_LAST                        => s_rout_last_re        , --: in  std_logic_vector(CELL_NUM*PATH_NUM*1-1 downto 0); 
--            RAFE_CC_DATA                        => s_rout_iq             , --: in  std_logic_vector(CELL_NUM*PATH_NUM*32-1 downto 0);
    
--            RAFE_CC_FRAME_SYNC                  => s_rin_frame_sync      , --: out std_logic_vector(CELL_NUM*1-1 downto 0);                    
--            RAFE_CC_FILTER_INDEX                => s_rin_filter_idx      , --: out std_logic_vector(CELL_NUM*PATH_NUM*4-1 downto 0); 
--            RAFE_CC_TIME_OFFSET                 => s_rin_time_offset     , --: out std_logic_vector(CELL_NUM*PATH_NUM*16-1 downto 0); 
--            RAFE_CC_FRAME_STRUCTURE             => s_rin_frame_struct    , --: out std_logic_vector(CELL_NUM*PATH_NUM*8-1 downto 0); 
--            RAFE_CC_CPLENGTH                    => s_rin_cp_length       , --: out std_logic_vector(CELL_NUM*PATH_NUM*16-1 downto 0); 
--            RAFE_CC_FREQ_OFFSET                 => s_rin_freq_offset     , --: out std_logic_vector(CELL_NUM*PATH_NUM*24-1 downto 0);
--            RAFE_CC_START_PRBC                  => s_rin_start_prbc      , --: out std_logic_vector(CELL_NUM_UL*PATH_NUM*10-1 downto 0);
--            RAFE_CC_NUM_PSYMBOL                 => s_rin_num_psymbol     , --: out std_logic_vector(CELL_NUM*PATH_NUM*4-1 downto 0);
--            RAFE_CC_NUM_PRBC                    => s_rin_num_prbc        , --: out std_logic_vector(CELL_NUM_UL*PATH_NUM*8-1 downto 0);
--            RAFE_CC_NUM_RO                      => s_rin_num_ro          , --: out std_logic_vector(CELL_NUM*PATH_NUM*3-1 downto 0) 
--    --------------------------------------------------------------------------------
--    -- eMTC PRACH
--    --------------------------------------------------------------------------------
    
--            eMTC_CC_FRAME_ID                    => s_mout_frame_idx      ,--: in  std_logic_vector(CELL_NUM_eMTC*8-1 downto 0);
--            eMTC_CC_SUBFRAME_ID                 => s_mout_subfrm_idx     ,--: in  std_logic_vector(CELL_NUM_eMTC*4-1 downto 0);
--            eMTC_CC_SLOT_ID                     => s_mout_slot_idx       ,--: in  std_logic_vector(CELL_NUM_eMTC*6-1 downto 0);
--            eMTC_CC_SYMBOL_ID                   => s_mout_symbol_idx     ,--: in  std_logic_vector(CELL_NUM_eMTC*6-1 downto 0);
--            eMTC_CC_START_RE                    => s_mout_start_re_idx   ,--: in  std_logic_vector(CELL_NUM_eMTC*PATH_NUM*16-1 downto 0);
--            eMTC_CC_VALID                       => s_mout_en             ,--: in  std_logic_vector(CELL_NUM_eMTC*PATH_NUM*1-1 downto 0); 
--            eMTC_CC_START                       => s_mout_start_re       ,--: in  std_logic_vector(CELL_NUM_eMTC*PATH_NUM*1-1 downto 0); 
--            eMTC_CC_LAST                        => s_mout_last_re        ,--: in  std_logic_vector(CELL_NUM_eMTC*PATH_NUM*1-1 downto 0); 
--            eMTC_CC_DATA                        => s_mout_iq             ,--: in  std_logic_vector(CELL_NUM_eMTC*PATH_NUM*32-1 downto 0);
    
--            eMTC_CC_FRAME_SYNC                  => open                  ,--: out std_logic_vector(CELL_NUM_eMTC*1-1 downto 0);                    
--            eMTC_CC_FILTER_INDEX                => s_min_filter_idx      ,--: out std_logic_vector(CELL_NUM_eMTC*PATH_NUM*4-1 downto 0); 
--            eMTC_CC_TIME_OFFSET                 => s_min_time_offset     ,--: out std_logic_vector(CELL_NUM_eMTC*PATH_NUM*16-1 downto 0); 
--            eMTC_CC_FRAME_STRUCTURE             => s_min_frame_struct    ,--: out std_logic_vector(CELL_NUM_eMTC*PATH_NUM*8-1 downto 0); 
--            eMTC_CC_CPLENGTH                    => s_min_cp_length       ,--: out std_logic_vector(CELL_NUM_eMTC*PATH_NUM*16-1 downto 0); 
--            eMTC_CC_FREQ_OFFSET                 => s_min_freq_offset     ,--: out std_logic_vector(CELL_NUM_eMTC*PATH_NUM*24-1 downto 0);
--            eMTC_CC_START_PRBC                  => open, --s_min_start_prbc      ,--: out std_logic_vector(CELL_NUM_eMTC*PATH_NUM*10-1 downto 0);
--            eMTC_CC_NUM_PSYMBOL                 => s_min_num_psymbol     ,--: out std_logic_vector(CELL_NUM_eMTC*PATH_NUM*4-1 downto 0); 
--            eMTC_CC_NUM_PRBC                    => s_min_num_prbc        ,--: out std_logic_vector(CELL_NUM_eMTC*PATH_NUM*8-1 downto 0);
--            eMTC_CC_NUM_RO                      => s_min_num_ro          ,--: out std_logic_vector(CELL_NUM_eMTC*PATH_NUM*3-1 downto 0); 
    
--    --------------------------------------------------------------------------------
--    -- NB-IoT
--    --------------------------------------------------------------------------------
    
--            NBIOT_CC_FRAME_ID                   =>  s_nout_frame_idx     , --: in  std_logic_vector(CELL_NUM_NBIOT*8-1 downto 0);
--            NBIOT_CC_SUBFRAME_ID                =>  s_nout_subfrm_idx    , --: in  std_logic_vector(CELL_NUM_NBIOT*4-1 downto 0);
--            NBIOT_CC_SLOT_ID                    =>  s_nout_slot_idx      , --: in  std_logic_vector(CELL_NUM_NBIOT*6-1 downto 0);
--            NBIOT_CC_SYMBOL_ID                  =>  s_nout_symbol_idx    , --: in  std_logic_vector(CELL_NUM_NBIOT*6-1 downto 0);
--            NBIOT_CC_START_RE                   =>  s_nout_start_re_idx  , --: in  std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*16-1 downto 0);
--            NBIOT_CC_VALID                      =>  s_nout_en            , --: in  std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*1-1 downto 0); 
--            NBIOT_CC_START                      =>  s_nout_start_re      , --: in  std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*1-1 downto 0); 
--            NBIOT_CC_LAST                       =>  s_nout_last_re       , --: in  std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*1-1 downto 0); 
--            NBIOT_CC_DATA                       =>  s_nout_iq            , --: in  std_logic_vector(CELL_NUM_NBIOT*PATH_NUM*32-1 downto 0);
    
--            NBIOT_CC_FRAME_SYNC                 =>  open                 , --: out std_logic_vector(CELL_NUM_UL*1-1 downto 0);                      
--            NBIOT_CC_FILTER_INDEX               =>  s_nin_filter_idx     , --: out std_logic_vector(CELL_NUM_UL*PATH_NUM*4-1 downto 0);             
--            NBIOT_CC_TIME_OFFSET                =>  s_nin_time_offset    , --: out std_logic_vector(CELL_NUM_UL*PATH_NUM*16-1 downto 0);            
--            NBIOT_CC_FRAME_STRUCTURE            =>  s_nin_frame_struct   , --: out std_logic_vector(CELL_NUM_UL*PATH_NUM*8-1 downto 0);             
--            NBIOT_CC_CPLENGTH                   =>  s_nin_cp_length      , --: out std_logic_vector(CELL_NUM_UL*PATH_NUM*16-1 downto 0);            
--            NBIOT_CC_FREQ_OFFSET                =>  s_nin_freq_offset    , --: out std_logic_vector(CELL_NUM_UL*PATH_NUM*24-1 downto 0);            
--            NBIOT_CC_START_PRBC                 =>  s_nin_start_prbc     , --: out std_logic_vector(CELL_NUM_UL*PATH_NUM*10-1 downto 0);            
--            NBIOT_CC_NUM_PSYMBOL                =>  s_nin_num_psymbol    , --: out std_logic_vector(CELL_NUM_UL*PATH_NUM*4-1 downto 0);             
--            NBIOT_CC_NUM_PRBC                   =>  s_nin_num_prbc       , --: out std_logic_vector(CELL_NUM_UL*PATH_NUM*8-1 downto 0);             
--            NBIOT_CC_NUM_RO                     =>  s_nin_num_ro           --: out std_logic_vector(CELL_NUM_UL*PATH_NUM*3-1 downto 0)              
--        );
    
    -- 2240
    -- 4498 ORAN_TOP (B05_ORAN_2cc_4t4r base : 2CC x 4ANT), NB-IoT/eMTC removed
    U05_O_RAN : ORAN_TOP
    generic map(
        CELL_NUM_eMTC               =>  0
    )
    port map(
    ----//----------------------------------------------------------------------
    ----//-- Clock & Reset
    ----//----------------------------------------------------------------------
        CLK_CPUIF                   =>  clk_cpuif                           ,
        RST_CPUIF                   =>  rst_cpuif                           ,

        ARESET_RX(1 downto 0)       =>  sysctrl_oran_deframer_rst           ,
        ARESET_RX(3 downto 2)       =>  "00"                                ,  -- Not used (2CC)
        ARESET_TX(1 downto 0)       =>  sysctrl_oran_framer_rst             ,
        ARESET_TX(3 downto 2)       =>  "00"                                ,  -- Not used (2CC)

        CLK_MAC_RX                  =>  l0_deframer_clk                     ,
        CLK_MAC_TX                  =>  l0_deframer_clk                     ,
        CLK_BUS                     =>  clk_sysx8                           ,

    ----//----------------------------------------------------------------------
    ----//-- Sync
    ----//----------------------------------------------------------------------
        TICK_1PPS                   =>  ptp_1pps_cpu_top                    ,  -- U2_ORAN_TOP : '0'
        FRAME_SYNC                  =>  frame_sync_cpu_top(0)               ,
        FRAME_NUM                   =>  sfn_num_cpu_top                     ,  -- "00" & w_cpu_sfn_num

        DL_CC0_SYNC_ADVANCE         =>  dl_cc_sync_advance(22*1-1 downto 0) ,
        UL_CC0_SYNC_RETARD          =>  ul_cc_sync_retard(22*1-1 downto 0)  ,
        DL_CC1_SYNC_ADVANCE         =>  dl_cc_sync_advance(22*2-1 downto 22),
        UL_CC1_SYNC_RETARD          =>  ul_cc_sync_retard(22*2-1 downto 22) ,

        TDD_CC0_SYMBOL_SYNC         =>  open                                ,  -- Not used
        TDD_CC0_SYMBOL_INDEX        =>  open                                ,  -- Not used
        TDD_CC0_DL_EN               =>  open                                ,  -- Not used
        TDD_CC0_UL_EN               =>  open                                ,  -- Not used
        TDD_CC1_SYMBOL_SYNC         =>  open                                ,  -- Not used
        TDD_CC1_SYMBOL_INDEX        =>  open                                ,  -- Not used
        TDD_CC1_DL_EN               =>  open                                ,  -- Not used
        TDD_CC1_UL_EN               =>  open                                ,  -- Not used

        N_TA_OFFSET_CC0             =>  n_ta_offset(15 downto 0)            ,
        N_TA_OFFSET_CC1             =>  n_ta_offset(31 downto 16)           ,

    ----//----------------------------------------------------------------------
    ----//-- CPU interface
    ----//----------------------------------------------------------------------
        ADDR_CPUIF_IN               =>  addr_cpuif_cpri                     ,
        WDATA_CPUIF_IN              =>  wdata_cpuif_cpri                    ,
        RDATA_CPUIF_OUT             =>  rdata_cpuif_cpri                    ,
        WREN_CPUIF_IN               =>  wren_cpuif_cpri                     ,
        RDEN_CPUIF_IN               =>  rden_cpuif_cpri                     ,
        RDVAL_CPUIF_OUT             =>  rdval_cpuif_cpri                    ,

    ----//----------------------------------------------------------------------
    ----//-- MAC#0
    ----//----------------------------------------------------------------------
        MAC0_RX_VALID               =>  mac0_rx_valid(0)                    ,
        MAC0_RX_LAST                =>  mac0_rx_last(0)                     ,
        MAC0_RX_KEEP                =>  mac0_rx_keep(0)                     ,
        MAC0_RX_DATA                =>  mac0_rx_data(0)                     ,

        MAC0_TX_READY               =>  mac0_tx_ready                       ,
        MAC0_TX_VALID               =>  mac0_tx_valid                       ,
        MAC0_TX_LAST                =>  mac0_tx_last                        ,
        MAC0_TX_KEEP                =>  mac0_tx_keep                        ,
        MAC0_TX_DATA                =>  mac0_tx_data                        ,

    ----//----------------------------------------------------------------------
    ----//-- MAC#1
    ----//----------------------------------------------------------------------
        MAC1_RX_VALID               =>  mac0_rx_valid(0)                    ,
        MAC1_RX_LAST                =>  mac0_rx_last(0)                     ,
        MAC1_RX_KEEP                =>  mac0_rx_keep(0)                     ,
        MAC1_RX_DATA                =>  mac0_rx_data(0)                     ,

        MAC1_TX_READY               =>  '0'                                 ,  -- Not used
        MAC1_TX_VALID               =>  open                                ,
        MAC1_TX_LAST                =>  open                                ,
        MAC1_TX_KEEP                =>  open                                ,
        MAC1_TX_DATA                =>  open                                ,

    ----//----------------------------------------------------------------------
    ----//-- DLFE
    ----//----------------------------------------------------------------------
        DLFE_CC0_SYSTEM_MODE        =>  w_dlfe_system_mode(0)               ,
        DLFE_CC0_K0                 =>  w_dlfe_k0(0)                        ,
        DLFE_CC0_nRE                =>  w_dlfe_nre(0)                       ,
        DLFE_CC0_nFFT               =>  w_dlfe_nfft(0)                      ,
        DLFE_CC0_FRAME_SYNC         =>  w_dlfe_frame_sync(0)                ,
        DLFE_CC0_FRAME_INDEX        =>  w_dlfe_frame_index(0)               ,
        DLFE_CC0_VALID              =>  w_dlfe_valid(0)                     ,
        DLFE_CC0_RE_MASK            =>  w_dlfe_re_mask(0)                   ,
        DLFE_CC0_DATA               =>  w_dlfe_data(0)                      ,

        DLFE_CC1_SYSTEM_MODE        =>  w_dlfe_system_mode(1)               ,
        DLFE_CC1_K0                 =>  w_dlfe_k0(1)                        ,
        DLFE_CC1_nRE                =>  w_dlfe_nre(1)                       ,
        DLFE_CC1_nFFT               =>  w_dlfe_nfft(1)                      ,
        DLFE_CC1_FRAME_SYNC         =>  w_dlfe_frame_sync(1)                ,
        DLFE_CC1_FRAME_INDEX        =>  w_dlfe_frame_index(1)               ,
        DLFE_CC1_VALID              =>  w_dlfe_valid(1)                     ,
        DLFE_CC1_RE_MASK            =>  w_dlfe_re_mask(1)                   ,
        DLFE_CC1_DATA               =>  w_dlfe_data(1)                      ,

    ----//----------------------------------------------------------------------
    ----//-- ULFE
    ----//----------------------------------------------------------------------
        ULFE_CC0_FRAME_ID           =>  w_ulfe_frame_id(0)                  ,
        ULFE_CC0_SUBFRAME_ID        =>  w_ulfe_subframe_id(0)               ,
        ULFE_CC0_SLOT_ID            =>  w_ulfe_slot_id(0)                   ,
        ULFE_CC0_SYMBOL_ID          =>  w_ulfe_symbol_id(0)                 ,
        ULFE_CC0_START_RE           =>  w_ulfe_start_re(0)                  ,
        ULFE_CC0_VALID              =>  w_ulfe_valid(0)                     ,
        ULFE_CC0_START              =>  w_ulfe_start(0)                     ,
        ULFE_CC0_LAST               =>  w_ulfe_last(0)                      ,
        ULFE_CC0_DATA               =>  w_ulfe_data(0)                      ,

        ULFE_CC1_FRAME_ID           =>  w_ulfe_frame_id(1)                  ,
        ULFE_CC1_SUBFRAME_ID        =>  w_ulfe_subframe_id(1)               ,
        ULFE_CC1_SLOT_ID            =>  w_ulfe_slot_id(1)                   ,
        ULFE_CC1_SYMBOL_ID          =>  w_ulfe_symbol_id(1)                 ,
        ULFE_CC1_START_RE           =>  w_ulfe_start_re(1)                  ,
        ULFE_CC1_VALID              =>  w_ulfe_valid(1)                     ,
        ULFE_CC1_START              =>  w_ulfe_start(1)                     ,
        ULFE_CC1_LAST               =>  w_ulfe_last(1)                      ,
        ULFE_CC1_DATA               =>  w_ulfe_data(1)                      ,

    ----//----------------------------------------------------------------------
    ----//-- RAFE
    ----//----------------------------------------------------------------------
        RAFE_CC0_FRAMES_SYNC        =>  w_rafe_frames_sync(0)               ,
        RAFE_CC0_FILTER_INDEX       =>  w_rafe_filter_index(0)              ,
        RAFE_CC0_TIME_OFFSET        =>  w_rafe_time_offset(0)               ,
        RAFE_CC0_FRAME_STRUCTURE    =>  w_rafe_frame_structure(0)           ,
        RAFE_CC0_CPLENGTH           =>  w_rafe_cplength(0)                  ,
        RAFE_CC0_FREQ_OFFSET        =>  w_rafe_freq_offset(0)               ,
        RAFE_CC0_START_PRBC         =>  w_rafe_start_prbc(0)                ,
        RAFE_CC0_NUM_PRBC           =>  w_rafe_num_prbc(0)                  ,
        RAFE_CC0_NUM_PSYMBOL        =>  w_rafe_num_psymbol(0)               ,
        RAFE_CC0_NUM_RO             =>  w_rafe_num_ro(0)                    ,
        RAFE_CC0_FRAME_ID           =>  w_rafe_frame_id(0)                  ,
        RAFE_CC0_SUBFRAME_ID        =>  w_rafe_subframe_id(0)               ,
        RAFE_CC0_SLOT_ID            =>  w_rafe_slot_id(0)                   ,
        RAFE_CC0_SYMBOL_ID          =>  w_rafe_symbol_id(0)                 ,
        RAFE_CC0_START_RE           =>  w_rafe_start_re(0)                  ,
        RAFE_CC0_VALID              =>  w_rafe_valid(0)                     ,
        RAFE_CC0_START              =>  w_rafe_start(0)                     ,
        RAFE_CC0_LAST               =>  w_rafe_last(0)                      ,
        RAFE_CC0_DATA               =>  w_rafe_data(0)                      ,

        RAFE_CC1_FRAMES_SYNC        =>  w_rafe_frames_sync(1)               ,
        RAFE_CC1_FILTER_INDEX       =>  w_rafe_filter_index(1)              ,
        RAFE_CC1_TIME_OFFSET        =>  w_rafe_time_offset(1)               ,
        RAFE_CC1_FRAME_STRUCTURE    =>  w_rafe_frame_structure(1)           ,
        RAFE_CC1_CPLENGTH           =>  w_rafe_cplength(1)                  ,
        RAFE_CC1_FREQ_OFFSET        =>  w_rafe_freq_offset(1)               ,
        RAFE_CC1_START_PRBC         =>  w_rafe_start_prbc(1)                ,
        RAFE_CC1_NUM_PRBC           =>  w_rafe_num_prbc(1)                  ,
        RAFE_CC1_NUM_PSYMBOL        =>  w_rafe_num_psymbol(1)               ,
        RAFE_CC1_NUM_RO             =>  w_rafe_num_ro(1)                    ,
        RAFE_CC1_FRAME_ID           =>  w_rafe_frame_id(1)                  ,
        RAFE_CC1_SUBFRAME_ID        =>  w_rafe_subframe_id(1)               ,
        RAFE_CC1_SLOT_ID            =>  w_rafe_slot_id(1)                   ,
        RAFE_CC1_SYMBOL_ID          =>  w_rafe_symbol_id(1)                 ,
        RAFE_CC1_START_RE           =>  w_rafe_start_re(1)                  ,
        RAFE_CC1_VALID              =>  w_rafe_valid(1)                     ,
        RAFE_CC1_START              =>  w_rafe_start(1)                     ,
        RAFE_CC1_LAST               =>  w_rafe_last(1)                      ,
        RAFE_CC1_DATA               =>  w_rafe_data(1)
    );
          s_i_rin_frame_sync         <=  w_rafe_frames_sync(1) & w_rafe_frames_sync(0)    ;
	s_i_din_frame_idx          <=  w_dlfe_frame_index(1) & w_dlfe_frame_index(0)   	;--, --//ccx dl input frame index (oran)
    s_i_din_en                 <=  w_dlfe_valid(1) & w_dlfe_valid(0)                ;--, --//ccx dl input u-plane data valid (oran)
    s_i_din_re_mask            <=  w_dlfe_re_mask(1) & w_dlfe_re_mask(0)      	 	;--, --//ccx dl input re mask (oran)
    s_i_din_iq                 <=  w_dlfe_data(1) & w_dlfe_data(0)       			;--, --//ccx dl input u-plane data (oran)
    w_dlfe_nre(0)              <= s_o_dout_dl_ntone(11 downto 0)                    ;
    w_dlfe_nre(1)              <= s_o_dout_dl_ntone(23 downto 12)                   ;--, --//ccx dl output ntone
--    s_o_dout_dl_ntone          <=  w_dlfe_nre(1) & w_dlfe_nre(0)            		;--, --//ccx dl output ntone
    w_dlfe_nfft(0)              <= s_o_dout_dl_fft_type(1 downto 0)                    ;
    w_dlfe_nfft(1)              <= s_o_dout_dl_fft_type(3 downto 2)                   ;--, --//ccx dl output ntone
--    s_o_dout_dl_fft_type       <=  w_dlfe_nfft(1) & w_dlfe_nfft(0)           		;--, --//ccx dl output fft_type
    w_dlfe_k0(0)              <= s_o_dout_dl_k0(11 downto 0)                    ;
    w_dlfe_k0(1)              <= s_o_dout_dl_k0(23 downto 12)                   ;--, --//ccx dl output ntone
--    s_o_dout_dl_k0             <=  w_dlfe_k0(1) & w_dlfe_k0(0)            			;--, --//ccx dl output k0
    
    ----//--- To ORAN_TOP (PUxCH)  
    w_ulfe_frame_id(0)              <= s_o_uout_frame_idx(7 downto 0)  ;                           
    w_ulfe_frame_id(1)              <= s_o_uout_frame_idx(15 downto 8) ;                                      
--    s_o_uout_frame_idx         <=  w_ulfe_frame_id(1) &  w_ulfe_frame_id(0)	       	;--, --//ccx ul output frame index (oran)
    w_ulfe_subframe_id(0)              <= s_o_uout_subfrm_idx(3 downto 0)  ;                           
    w_ulfe_subframe_id(1)              <= s_o_uout_subfrm_idx(7 downto 4) ;
--    s_o_uout_subfrm_idx        <=  w_ulfe_subframe_id(1) & w_ulfe_subframe_id(0)    ;--, --//ccx ul output subframe index (oran)
    w_ulfe_slot_id(0)              <= s_o_uout_slot_idx(5 downto 0)  ;                           
    w_ulfe_slot_id(1)              <= s_o_uout_slot_idx(11 downto 6) ;
--    s_o_uout_slot_idx          <=  w_ulfe_slot_id(1) & w_ulfe_slot_id(0)       		;--, --//ccx ul output slot index (oran)
    w_ulfe_symbol_id(0)              <= s_o_uout_symbol_idx(5 downto 0)  ;                           
    w_ulfe_symbol_id(1)              <= s_o_uout_symbol_idx(11 downto 6) ;
--    s_o_uout_symbol_idx        <=  w_ulfe_symbol_id(1) &  w_ulfe_symbol_id(0)      	;--, --//ccx ul output symbol index (oran)
    w_ulfe_start_re(0)              <= s_o_uout_start_re_idx(63 downto 0)  ;                           
    w_ulfe_start_re(1)              <= s_o_uout_start_re_idx(127 downto 64) ;
--    s_o_uout_start_re_idx      <=  w_ulfe_start_re(1) & w_ulfe_start_re(0)       	;--, --//ccx ul output start re index (oran)
    w_ulfe_valid(0)              <= s_o_uout_en(3 downto 0)  ;                           
    w_ulfe_valid(1)              <= s_o_uout_en(7 downto 4) ;
--    s_o_uout_en                <=  w_ulfe_valid(1) & w_ulfe_valid(0)          		;--, --//ccx ul output u-plane data valid (oran)
    w_ulfe_start(0)              <= s_o_uout_start_re(3 downto 0)  ;                           
    w_ulfe_start(1)              <= s_o_uout_start_re(7 downto 4) ;
--    s_o_uout_start_re          <=  w_ulfe_start(1) & w_ulfe_start(0)          		;--, --//ccx ul output start re indicator (oran)
    w_ulfe_last(0)              <= s_o_uout_last_re(3 downto 0)  ;                           
    w_ulfe_last(1)              <= s_o_uout_last_re(7 downto 4) ;
--    s_o_uout_last_re           <=  w_ulfe_last(1) & w_ulfe_last(0)           		;--, --//ccx ul output last re indicator (oran)
    w_ulfe_data(0)              <= s_o_uout_iq(127 downto 0)  ;                           
    w_ulfe_data(1)              <= s_o_uout_iq(255 downto 128) ;
--    s_o_uout_iq                <=  w_ulfe_data(1) & w_ulfe_data(0)          		;--, --//ccx ul output u-plane data (oran)
																   
    ----//--- From/To ORAN_TOP (PRACH)                             
    s_i_rin_filter_idx         <=  w_rafe_filter_index(1) & w_rafe_filter_index(0)   	;--, --//ccx prach input filter index
    s_i_rin_time_offset        <=  w_rafe_time_offset(1) & w_rafe_time_offset(0)    	;--, --//ccx prach input time offset
    s_i_rin_frame_struct       <=  w_rafe_frame_structure(1) & w_rafe_frame_structure(0);--, --//ccx prach input frame structure
    s_i_rin_cp_length          <=  w_rafe_cplength(1) & w_rafe_cplength(0)       		;--, --//ccx prach input cp length
    s_i_rin_freq_offset        <=  w_rafe_freq_offset(1) & w_rafe_freq_offset(0)    	;--, --//ccx prach input frequency offset
    s_i_rin_num_psymbol        <=  w_rafe_num_psymbol(1) & w_rafe_num_psymbol(0)    	;--, --//ccx prach input preamble symbol number
    s_i_rin_num_ro             <=  w_rafe_num_ro(1) & w_rafe_num_ro(0)         			;--, --//ccx prach input occasion number
    s_i_rin_num_prbc           <=  w_rafe_num_prbc(1) & w_rafe_num_prbc(0)       		;--, --//ccx prach input c-plane physical rb size
    s_i_rin_start_prbc         <=  w_rafe_start_prbc(1) & w_rafe_start_prbc(0)     		;--,                                              
    
    w_rafe_frame_id(0)              <= s_o_rout_frame_idx(7 downto 0)  ;                           
    w_rafe_frame_id(1)              <= s_o_rout_frame_idx(15 downto 8) ;
--    s_o_rout_frame_idx         <=  w_rafe_frame_id(1) & w_rafe_frame_id(0)       		;--, --//ccx prach output frame index (oran)
    w_rafe_subframe_id(0)              <= s_o_rout_subfrm_idx(3 downto 0)  ;                           
    w_rafe_subframe_id(1)              <= s_o_rout_subfrm_idx(7 downto 4) ;
--    s_o_rout_subfrm_idx        <=  w_rafe_subframe_id(1) & w_rafe_subframe_id(0)    	;--, --//ccx prach output subframe index (oran)
    w_rafe_slot_id(0)              <= s_o_rout_slot_idx(5 downto 0)  ;                           
    w_rafe_slot_id(1)              <= s_o_rout_slot_idx(11 downto 6) ;
--    s_o_rout_slot_idx          <=  w_rafe_slot_id(1) & w_rafe_slot_id(0)        		;--, --//ccx prach output slot index (oran)
    w_rafe_symbol_id(0)              <= s_o_rout_symbol_idx(5 downto 0)  ;                           
    w_rafe_symbol_id(1)              <= s_o_rout_symbol_idx(11 downto 6) ;
--    s_o_rout_symbol_idx        <=  w_rafe_symbol_id(1) & w_rafe_symbol_id(0)     		;--, --//ccx prach output symbol index (oran)
    w_rafe_start_re(0)              <= s_o_rout_start_re_idx(63 downto 0)  ;                           
    w_rafe_start_re(1)              <= s_o_rout_start_re_idx(127 downto 64) ;
--    s_o_rout_start_re_idx      <=  w_rafe_start_re(1) & w_rafe_start_re(0)       		;--, --//ccx prach output start re index (oran)
    w_rafe_valid(0)              <= s_o_rout_en(3 downto 0)  ;                           
    w_rafe_valid(1)              <= s_o_rout_en(7 downto 4) ;
--    s_o_rout_en                <=  w_rafe_valid(1) & w_rafe_valid(0)         			;--, --//ccx prach output u-plane data valid (oran)
    w_rafe_start(0)              <= s_o_rout_start_re(3 downto 0)  ;                           
    w_rafe_start(1)              <= s_o_rout_start_re(7 downto 4) ;
--    s_o_rout_start_re          <=  w_rafe_start(1) & w_rafe_start(0)          			;--, --//ccx prach output start re indicator (oran)
    w_rafe_last(0)              <= s_o_rout_last_re(3 downto 0)  ;                           
    w_rafe_last(1)              <= s_o_rout_last_re(7 downto 4) ;
--    s_o_rout_last_re           <=  w_rafe_last(1) & w_rafe_last(0)           			;--, --//ccx prach output last re indicator (oran)
    w_rafe_data(0)              <= s_o_rout_iq(127 downto 0)  ;                           
    w_rafe_data(1)              <= s_o_rout_iq(255 downto 128) ;
--    s_o_rout_iq                <=  w_rafe_data(1) & w_rafe_data(0)           			;--, --//ccx prach output u-plane data (oran)	


--    s_i_rin_frame_sync         <=  w_rafe_frames_sync(1) & w_rafe_frames_sync(0)    ;
--	s_i_din_frame_idx          <=  w_dlfe_frame_index(1) & w_dlfe_frame_index(0)   	;--, --//ccx dl input frame index (oran)
--    s_i_din_en                 <=  w_dlfe_valid(1) & w_dlfe_valid(0)                ;--, --//ccx dl input u-plane data valid (oran)
--    s_i_din_re_mask            <=  w_dlfe_re_mask(1) & w_dlfe_re_mask(0)      	 	;--, --//ccx dl input re mask (oran)
--    s_i_din_iq                 <=  w_dlfe_data(1) & w_dlfe_data(0)       			;--, --//ccx dl input u-plane data (oran)
--    s_o_dout_dl_ntone          <=  w_dlfe_nre(1) & w_dlfe_nre(0)            		;--, --//ccx dl output ntone
--    s_o_dout_dl_fft_type       <=  w_dlfe_nfft(1) & w_dlfe_nfft(0)           		;--, --//ccx dl output fft_type
--    s_o_dout_dl_k0             <=  w_dlfe_k0(1) & w_dlfe_k0(0)            			;--, --//ccx dl output k0
    
--    ----//--- To ORAN_TOP (PUxCH)                                  
--    s_o_uout_frame_idx         <=  w_ulfe_frame_id(1) &  w_ulfe_frame_id(0)	       	;--, --//ccx ul output frame index (oran)
--    s_o_uout_subfrm_idx        <=  w_ulfe_subframe_id(1) & w_ulfe_subframe_id(0)    ;--, --//ccx ul output subframe index (oran)
--    s_o_uout_slot_idx          <=  w_ulfe_slot_id(1) & w_ulfe_slot_id(0)       		;--, --//ccx ul output slot index (oran)
--    s_o_uout_symbol_idx        <=  w_ulfe_symbol_id(1) &  w_ulfe_symbol_id(0)      	;--, --//ccx ul output symbol index (oran)
--    s_o_uout_start_re_idx      <=  w_ulfe_start_re(1) & w_ulfe_start_re(0)       	;--, --//ccx ul output start re index (oran)
--    s_o_uout_en                <=  w_ulfe_valid(1) & w_ulfe_valid(0)          		;--, --//ccx ul output u-plane data valid (oran)
--    s_o_uout_start_re          <=  w_ulfe_start(1) & w_ulfe_start(0)          		;--, --//ccx ul output start re indicator (oran)
--    s_o_uout_last_re           <=  w_ulfe_last(1) & w_ulfe_last(0)           		;--, --//ccx ul output last re indicator (oran)
--    s_o_uout_iq                <=  w_ulfe_data(1) & w_ulfe_data(0)          		;--, --//ccx ul output u-plane data (oran)
																   
--    ----//--- From/To ORAN_TOP (PRACH)                             
--    s_i_rin_filter_idx         <=  w_rafe_filter_index(1) & w_rafe_filter_index(0)   	;--, --//ccx prach input filter index
--    s_i_rin_time_offset        <=  w_rafe_time_offset(1) & w_rafe_time_offset(0)    	;--, --//ccx prach input time offset
--    s_i_rin_frame_struct       <=  w_rafe_frame_structure(1) & w_rafe_frame_structure(0);--, --//ccx prach input frame structure
--    s_i_rin_cp_length          <=  w_rafe_cplength(1) & w_rafe_cplength(0)       		;--, --//ccx prach input cp length
--    s_i_rin_freq_offset        <=  w_rafe_freq_offset(1) & w_rafe_freq_offset(0)    	;--, --//ccx prach input frequency offset
--    s_i_rin_num_psymbol        <=  w_rafe_num_psymbol(1) & w_rafe_num_psymbol(0)    	;--, --//ccx prach input preamble symbol number
--    s_i_rin_num_ro             <=  w_rafe_num_ro(1) & w_rafe_num_ro(0)         			;--, --//ccx prach input occasion number
--    s_i_rin_num_prbc           <=  w_rafe_num_prbc(1) & w_rafe_num_prbc(0)       		;--, --//ccx prach input c-plane physical rb size
--    s_i_rin_start_prbc         <=  w_rafe_start_prbc(1) & w_rafe_start_prbc(0)     		;--,                                              
--    s_o_rout_frame_idx         <=  w_rafe_frame_id(1) & w_rafe_frame_id(0)       		;--, --//ccx prach output frame index (oran)
--    s_o_rout_subfrm_idx        <=  w_rafe_subframe_id(1) & w_rafe_subframe_id(0)    	;--, --//ccx prach output subframe index (oran)
--    s_o_rout_slot_idx          <=  w_rafe_slot_id(1) & w_rafe_slot_id(0)        		;--, --//ccx prach output slot index (oran)
--    s_o_rout_symbol_idx        <=  w_rafe_symbol_id(1) & w_rafe_symbol_id(0)     		;--, --//ccx prach output symbol index (oran)
--    s_o_rout_start_re_idx      <=  w_rafe_start_re(1) & w_rafe_start_re(0)       		;--, --//ccx prach output start re index (oran)
--    s_o_rout_en                <=  w_rafe_valid(1) & w_rafe_valid(0)         			;--, --//ccx prach output u-plane data valid (oran)
--    s_o_rout_start_re          <=  w_rafe_start(1) & w_rafe_start(0)          			;--, --//ccx prach output start re indicator (oran)
--    s_o_rout_last_re           <=  w_rafe_last(1) & w_rafe_last(0)           			;--, --//ccx prach output last re indicator (oran)
--    s_o_rout_iq                <=  w_rafe_data(1) & w_rafe_data(0)           			;--, --//ccx prach output u-plane data (oran)	
    
    -- kkdi b lphy 
 	U3_LPHY_TOP : BB_TOP 
    generic map (		
		NUM_CC              => DL_NUM_CC          ,
		MAX_CC              => DL_MAX_CC          ,
		DL_NUM_LAYER        => DL_NUM_LAYER       ,
		DL_NUM_ANT          => DL_NUM_ANT         ,
		UL_NUM_PATH         => UL_NUM_PATH     ,
		UL_NUM_ANT          => UL_NUM_ANT      ,
		TOP_DIO_BW          => 16              ,
		CPUIF_ADDR_BW       => 20              ,
		CPUIF_DATA_BW       => 32
	)
	port map (
        i_core_clk                =>  clk_sysx8            , --//core clock 245.76MHz
        i_core_arst_bbtop         =>  sysctrl_lphy_top_rst   , --//lphy_top active high async reset
        i_core_arst_dlfe          =>  sysctrl_dlfe_rst     , --//dlfe active high async reset
        i_core_arst_ulfe          =>  sysctrl_ulfe_rst     , --//ulfe active high async reset
        i_core_arst_rafe          =>  sysctrl_rafe_rst     , --//rafe active high async reset
                                                                                  
        ----//--- From/To CPU IF                                                      
        i_cpu_clk                 =>  clk_cpuif           , --//CPU Interface clock 100MHz
        i_cpu_arst                =>  rst_cpuif           , --//CPU Interface async reset
        i_bb_cpu_cs               =>  (others => '1')       , --//CPU Interface chip sync
        i_bb_cpu_addr             =>  addr_cpuif_lphy_top     , --//CPU Interface address of lphy_top registers
        i_bb_cpu_wren(0)          =>  wren_cpuif_lphy_top     , --//CPU Interface write enable of lphy_top registers
        i_bb_cpu_wdata            =>  wdata_cpuif_lphy_top    , --//CPU Interface write data of lphy_top registers
        i_bb_cpu_rden(0)          =>  rden_cpuif_lphy_top     , --//CPU Interface read enable of lphy_top registers
        o_bb_cpu_rdata            =>  rdata_cpuif_lphy_top    , --//CPU Interface read data of lphy_top registers
        o_bb_cpu_rd_valid(0)      =>  rdval_cpuif_lphy_top    , --//CPU Interface read data vaild of lphy_top registers

        ----//--- From/To ORAN_TOP(DL)
        i_din_frame_sync         =>  w_dlfe_frame_sync         						 , --//ccx dl input frame sync (1 pulse of 245.76MHz every 10ms)
        i_din_frame_idx          =>  s_i_din_frame_idx     ,
        i_din_en                 =>  s_i_din_en            ,
        i_din_re_mask            =>  s_i_din_re_mask       ,
        i_din_iq                 =>  s_i_din_iq            ,
        o_dout_dl_sys_mode       =>  w_dlfe_system_mode    ,
        o_dout_dl_ntone          =>  s_o_dout_dl_ntone     ,
        o_dout_dl_fft_type       =>  s_o_dout_dl_fft_type  ,
        o_dout_dl_k0             =>  s_o_dout_dl_k0        ,
                                                            
        ----//--- To ORAN_TOP (PUxCH)                 
        o_uout_frame_sync        =>  s_o_uout_frame_sync   ,        
        o_uout_frame_idx         =>  s_o_uout_frame_idx    ,
        o_uout_subfrm_idx        =>  s_o_uout_subfrm_idx   ,
        o_uout_slot_idx          =>  s_o_uout_slot_idx     ,
        o_uout_symbol_idx        =>  s_o_uout_symbol_idx   ,
        o_uout_start_re_idx      =>  s_o_uout_start_re_idx ,
        o_uout_en                =>  s_o_uout_en           ,
        o_uout_start_re          =>  s_o_uout_start_re     ,
        o_uout_last_re           =>  s_o_uout_last_re      ,
        o_uout_iq                =>  s_o_uout_iq           ,
                                                            
        ----//--- From/To ORAN_TOP (PRACH)                 
        i_rin_frame_sync         =>  s_i_rin_frame_sync    ,
        i_rin_filter_idx         =>  s_i_rin_filter_idx    ,
        i_rin_time_offset        =>  s_i_rin_time_offset   ,
        i_rin_frame_struct       =>  s_i_rin_frame_struct  ,
        i_rin_cp_length          =>  s_i_rin_cp_length     ,
        i_rin_freq_offset        =>  s_i_rin_freq_offset   ,
        i_rin_num_psymbol        =>  s_i_rin_num_psymbol   ,
        i_rin_num_ro             =>  s_i_rin_num_ro        ,
        i_rin_num_prbc           =>  s_i_rin_num_prbc      ,
        i_rin_start_prbc         =>  s_i_rin_start_prbc    ,
        o_rout_frame_idx         =>  s_o_rout_frame_idx    ,
        o_rout_subfrm_idx        =>  s_o_rout_subfrm_idx   ,
        o_rout_slot_idx          =>  s_o_rout_slot_idx     ,
        o_rout_symbol_idx        =>  s_o_rout_symbol_idx   ,
        o_rout_start_re_idx      =>  s_o_rout_start_re_idx ,
        o_rout_en                =>  s_o_rout_en           ,
        o_rout_start_re          =>  s_o_rout_start_re     ,
        o_rout_last_re           =>  s_o_rout_last_re      ,
        o_rout_iq                =>  s_o_rout_iq           ,
                                                                           
        ----//--- To BBCTRL(DL)                                        
        o_dout_frame_sync        =>  s_dout_frame_sync  , 
        o_dout_en                =>  s_dout_en     , 
        o_dout_i                 =>  s_dout_i     , 
        o_dout_q                 =>  s_dout_q     , 
																	   
        ----//--- FROM BBCTRL(UL)                                      
        i_uin_frame_sync         =>  s_uin_frame_sync, --w_bbul_bfn_strb  ,  -- change to frame sync from cpu_top
        i_uin_en                 =>  s_uin_en     , 
        i_uin_i                  =>  w_bbul_idata     , 
        i_uin_q                  =>  w_bbul_qdata     ,
        
        o_dbg_uin_frame_sync    =>   open, --o_dbg_uin_frame_sync ,  
        o_dbg_uin_en            =>   open, --o_dbg_uin_en         ,
        o_dbg_uin_i             =>   open, --o_dbg_uin_i          ,
        o_dbg_uin_q             =>   open --o_dbg_uin_q      

    );
--    -- rf4440d lphy
--    U3_LPHY_TOP : LPHY_TOP
--    port map(
--        --//--- From SYSCTRL_TOP
--        i_core_clk                              => clk_sysx8                     , --:   in std_logic                                                          ; --core clock 245.76MHz 
--        i_core_arst_lphy_top                    => sysctrl_lphy_top_rst          , --:   in std_logic_vector (DL_MAX_CC-1                          downto 0); --lphy-top active high async reset 
--        i_core_arst_dlfe                        => sysctrl_dlfe_rst              , --:   in std_logic_vector (DL_MAX_CC-1                          downto 0); --dlfe active high async reset 
--        i_core_arst_ulfe                        => sysctrl_ulfe_rst              , --:   in std_logic_vector (UL_MAX_CC-1                          downto 0); --ulfe active high async reset 
--        i_core_arst_rafe                        => sysctrl_rafe_rst              , --:   in std_logic_vector (UL_MAX_CC-1                          downto 0); --rafe active high async reset 
    
--        --//--- From/To CPU IF
--        i_cpu_clk                               => clk_cpuif                     , --:   in std_logic                                                       ; --CPU Interface clock 100MHz
--        i_cpu_arst                              => rst_cpuif                     , --:   in std_logic                                                       ; --CPU Interface async reset
--        i_cpu_cs(0)                             => '1'                           , --:   in std_logic_vector (0                                    downto 0); --CPU Interface chip sync
--        i_cpu_addr                              => addr_cpuif_lphy_top           , --:   in std_logic_vector (CPUIF_ADDR_BW-1                      downto 0); --CPU Interface address of lphy-top registers
--        i_cpu_wren(0)                           => wren_cpuif_lphy_top           , --:   in std_logic_vector (0                                    downto 0); --CPU Interface write enable of lphy-top registers 
--        i_cpu_wdata                             => wdata_cpuif_lphy_top          , --:   in std_logic_vector (CPUIF_DATA_BW-1                      downto 0); --CPU Interface write data of lphy-top registers 
--        i_cpu_rden(0)                           => rden_cpuif_lphy_top           , --:   in std_logic_vector (0                                    downto 0); --CPU Interface read enable of lphy-top registers 
--        o_cpu_rdata                             => rdata_cpuif_lphy_top          , --:   out std_logic_vector(CPUIF_DATA_BW-1                      downto 0); --CPU Interface read data of lphy-top registers 
--        o_cpu_rd_valid(0)                       => rdval_cpuif_lphy_top          , --:   out std_logic_vector(0                                    downto 0); --CPU Interface read data vaild of lphy-top registers 
    
--        --//--- From/To ORAN_TOP(DL)
--        i_din_frame_sync                        => s_din_frame_sync              , --:   in std_logic_vector (01*DL_MAX_CC-1                       downto 0); --ccx dl input frame sync (1 pulse of 245.76MHz every 10ms)
     
--        i_din_frame_idx                         => s_din_frame_idx               , --:   in std_logic_vector (08*DL_MAX_CC-1                       downto 0); --ccx dl input frame index (oran)
--        i_din_en                                => s_din_en                      , --:   in std_logic_vector (01*DL_NUM_LAYER*DL_MAX_CC-1          downto 0); --ccx dl input u-plane data valid (oran)
--        i_din_re_mask                           => s_din_re_mask                 , --:   in std_logic_vector (01*DL_NUM_LAYER*DL_MAX_CC-1          downto 0); --ccx dl input re mask (oran)
--    --    i_din_sys_mode_dss                      => s_dlfe_cc_system_mode_dss     , --:   in std_logic_vector (01*DL_NUM_LAYER*DL_MAX_CC-1          downto 0); --ccx dl input system mode bitmap for dss (oran) 
--        i_din_iq                                => s_din_iq                      , --:   in std_logic_vector (2*TOP_DIO_BW*DL_NUM_LAYER*DL_MAX_CC-1downto 0); --ccx dl input u-plane data (oran)      
--        o_dout_dl_sys_mode                      => s_dout_dl_sys_mode            , --:   out std_logic_vector(01*DL_MAX_CC-1                       downto 0); --ccx dl output system mode   
--        o_dout_dl_ntone                         => s_dout_dl_ntone               , --:   out std_logic_vector(12*DL_MAX_CC-1                       downto 0); --ccx dl output ntone   
--        o_dout_dl_fft_type                      => s_dout_dl_fft_type            , --:   out std_logic_vector(02*DL_MAX_CC-1                       downto 0); --ccx dl output fft_type
--        o_dout_dl_k0                            => s_dout_dl_k0                  , --:   out std_logic_vector(12*DL_MAX_CC-1                       downto 0); --ccx dl output k0  
                                                                                                
--        --//--- To ORAN_TOP (PUxCH)
--    --    i_uin_symbol_idx                        => (others => '0')               , --:   in  std_logic_vector(  4*UL_MAX_CC-1                          downto 0);                               
--    --    i_uin_en_technology                     => (others => '0')               , --:   in  std_logic_vector(  UL_MAX_CC-1                            downto 0);                            
--    --    i_uin_technology_dss                    => (others => '0')               , --:   in  std_logic_vector(  UL_MAX_CC-1                            downto 0);                               
    
--        o_uout_frame_idx                        => s_uout_frame_idx              , --:   out std_logic_vector(08*UL_MAX_CC-1                       downto 0);  --ccx ul output frame index (oran)       
--        o_uout_subfrm_idx                       => s_uout_subfrm_idx             , --:   out std_logic_vector(04*UL_MAX_CC-1                       downto 0);  --ccx ul output subframe index (oran)
--        o_uout_slot_idx                         => s_uout_slot_idx               , --:   out std_logic_vector(06*UL_MAX_CC-1                       downto 0);  --ccx ul output slot index (oran)
--        o_uout_symbol_idx                       => s_uout_symbol_idx             , --:   out std_logic_vector(06*UL_MAX_CC-1                       downto 0);  --ccx ul output symbol index (oran)
--        o_uout_start_re_idx                     => s_uout_start_re_idx           , --:   out std_logic_vector(16*UL_NUM_PATH*UL_MAX_CC-1           downto 0);  --ccx ul output start re index (oran)
--        o_uout_en                               => s_uout_en                     , --:   out std_logic_vector(01*UL_NUM_PATH*UL_MAX_CC-1           downto 0);  --ccx ul output u-plane data valid (oran)
--        o_uout_start_re                         => s_uout_start_re               , --:   out std_logic_vector(01*UL_NUM_PATH*UL_MAX_CC-1           downto 0);  --ccx ul output start re indicator (oran)    
--        o_uout_last_re                          => s_uout_last_re                , --:   out std_logic_vector(01*UL_NUM_PATH*UL_MAX_CC-1           downto 0);  --ccx ul output last re indicator (oran)
--        o_uout_iq                               => s_uout_iq                     , --:   out std_logic_vector(2*TOP_DIO_BW*UL_NUM_PATH*UL_MAX_CC-1 downto 0);  --ccx ul output u-plane data (oran)
    
--        --//--- From/To ORAN_TOP (PRACH)
--      --  i_rin_frame_sync                        => s_rin_frame_sync              , --:   in std_logic_vector (01*UL_MAX_CC-1                       downto 0);  --ccx prach input frame sync (1 pulse of 245.76MHz every 10ms)
--        i_rin_filter_idx                        => s_rin_filter_idx              , --:   in std_logic_vector (04*UL_NUM_PATH*UL_MAX_CC-1           downto 0);  --ccx prach input filter index
--        i_rin_time_offset                       => s_rin_time_offset             , --:   in std_logic_vector (16*UL_NUM_PATH*UL_MAX_CC-1           downto 0);  --ccx prach input time offset
--        i_rin_frame_struct                      => s_rin_frame_struct            , --:   in std_logic_vector (08*UL_NUM_PATH*UL_MAX_CC-1           downto 0);  --ccx prach input frame structure
--        i_rin_cp_length                         => s_rin_cp_length               , --:   in std_logic_vector (16*UL_NUM_PATH*UL_MAX_CC-1           downto 0);  --ccx prach input cp length
--        i_rin_freq_offset                       => s_rin_freq_offset             , --:   in std_logic_vector (24*UL_NUM_PATH*UL_MAX_CC-1           downto 0);  --ccx prach input frequency offset
--        i_rin_start_prbc                        => s_rin_start_prbc              , --:   in std_logic_vector (10*UL_NUM_PATH*UL_MAX_CC-1           downto 0);  --ccx prach input start_prbc
--        i_rin_num_psymbol                       => s_rin_num_psymbol             , --:   in std_logic_vector (04*UL_NUM_PATH*UL_MAX_CC-1           downto 0);  --ccx prach input preamble symbol number
--        i_rin_num_ro                            => s_rin_num_ro                  , --:   in std_logic_vector (03*UL_NUM_PATH*UL_MAX_CC-1           downto 0);  --ccx prach input occasion number
--        i_rin_num_prbc                          => s_rin_num_prbc                , --//ccx prach input c-plane physical rb size 
--        o_rout_frame_idx                        => s_rout_frame_idx              , --:   out std_logic_vector(08*UL_MAX_CC-1                       downto 0);  --ccx prach output frame index (oran)  
--        o_rout_subfrm_idx                       => s_rout_subfrm_idx             , --:   out std_logic_vector(04*UL_MAX_CC-1                       downto 0);  --ccx prach output subframe index (oran)
--        o_rout_slot_idx                         => s_rout_slot_idx               , --:   out std_logic_vector(06*UL_MAX_CC-1                       downto 0);  --ccx prach output slot index (oran)
--        o_rout_symbol_idx                       => s_rout_symbol_idx             , --:   out std_logic_vector(06*UL_MAX_CC-1                       downto 0);  --ccx prach output symbol index (oran)
--        o_rout_start_re_idx                     => s_rout_start_re_idx           , --:   out std_logic_vector(16*UL_NUM_PATH*UL_MAX_CC-1           downto 0);  --ccx prach output start re index (oran)
--        o_rout_en                               => s_rout_en                     , --:   out std_logic_vector(01*UL_NUM_PATH*UL_MAX_CC-1           downto 0);  --ccx prach output u-plane data valid (oran)
--        o_rout_start_re                         => s_rout_start_re               , --:   out std_logic_vector(01*UL_NUM_PATH*UL_MAX_CC-1           downto 0);  --ccx prach output start re indicator (oran)    
--        o_rout_last_re                          => s_rout_last_re                , --:   out std_logic_vector(01*UL_NUM_PATH*UL_MAX_CC-1           downto 0);  --ccx prach output last re indicator (oran)
--        o_rout_iq                               => s_rout_iq                     , --:   out std_logic_vector(2*TOP_DIO_BW*UL_NUM_PATH*UL_MAX_CC-1 downto 0);  --ccx prach output u-plane data (oran)  
--        --//--- To BBCTRL(DL)
--        o_dout_frame_sync                       => s_dout_frame_sync             , --:   out std_logic_vector(01*DL_MAX_CC-1                       downto 0);  --ccx dl output frame sync (1 pulse of 245.76MHz every 10ms)
--        o_dout_en                               => s_dout_en                     , --:   out std_logic_vector(01*DL_NUM_ANT*DL_MAX_CC-1            downto 0);  --ccx dl output td data valid 
--        o_dout_i                                => s_dout_i                      , --:   out std_logic_vector(TOP_DIO_BW*DL_NUM_ANT*DL_MAX_CC-1    downto 0);  --ccx dl output td in-phase sample
--        o_dout_q                                => s_dout_q                      , --:   out std_logic_vector(TOP_DIO_BW*DL_NUM_ANT*DL_MAX_CC-1    downto 0);  --ccx dl output td quadrature sample
--        --//--- FROM BBCTRL(UL)                                                            
--        i_uin_frame_sync                        => s_mux_uin_frame_sync           , --:  in std_logic_vector (01*UL_MAX_CC-1                       downto 0);  --ccx ul input frame sync (1 pulse of 245.76MHz every 10ms)
--        i_uin_en                                => s_mux_uin_en                   , --:  in std_logic_vector (01*UL_NUM_ANT*UL_MAX_CC-1            downto 0);  --ccx ul input td data valid 
--        i_uin_i                                 => s_mux_uin_i                    , --:  in std_logic_vector (TOP_DIO_BW*UL_NUM_ANT*UL_MAX_CC-1    downto 0);  --ccx ul input td in-phase sample
--        i_uin_q                                 => s_mux_uin_q                    , --:  in std_logic_vector (TOP_DIO_BW*UL_NUM_ANT*UL_MAX_CC-1    downto 0)   --ccx ul input td quadrature sample
--        --- From/To ORAN_TOP (NPRACH,NPUSCH)
--        i_nin_filter_idx                        => s_nin_filter_idx               , --:  in std_logic_vector (04*NB_NUM_PATH*NB_MAX_CC-1           downto 0);	 --//ccx ul nprach,npuxch input filter index
--        i_nin_time_offset                       => s_nin_time_offset              , --:  in std_logic_vector (16*NB_NUM_PATH*NB_MAX_CC-1           downto 0);  --//ccx ul nprach,npuxch input time offset
--        i_nin_frame_struct                      => s_nin_frame_struct             , --:  in std_logic_vector (08*NB_NUM_PATH*NB_MAX_CC-1           downto 0);  --//ccx ul nprach,npuxch input frame structure
--        i_nin_cp_length                         => s_nin_cp_length                , --:  in std_logic_vector (16*NB_NUM_PATH*NB_MAX_CC-1           downto 0);  --//ccx ul nprach,npuxch input cp length
--        i_nin_num_psymbol                       => s_nin_num_psymbol              , --:  in std_logic_vector (04*NB_NUM_PATH*NB_MAX_CC-1           downto 0);  --//ccx ul nprach,npuxch input preamble symbol number
--        i_nin_freq_offset                       => s_nin_freq_offset              , --:  in std_logic_vector (24*NB_NUM_PATH*NB_MAX_CC-1           downto 0);  --//ccx ul nprach,npuxch input frequency offset
--        i_nin_num_ro                            => s_nin_num_ro                   , --:  in std_logic_vector (03*NB_NUM_PATH*NB_MAX_CC-1           downto 0);  --//ccx ul nprach,npuxch input frequency offset
--        i_nin_num_prbc                          => s_nin_num_prbc                 , --:  in std_logic_vector (08*NB_NUM_PATH*NB_MAX_CC-1           downto 0);  --//ccx ul nprach,npuxch input c-plane physical rb size
--        i_nin_start_prbc                        => s_nin_start_prbc               , --:  in std_logic_vector (10*NB_NUM_PATH*NB_MAX_CC-1           downto 0);              //ccx ul nprach,npuxch input
--        o_nout_nco_valid                        => s_nout_nco_valid               ,
--        o_nout_frame_struct                     => s_nout_frame_struct            ,
--        o_nout_freq_offset                      => s_nout_freq_offset             ,
--        o_nout_frame_idx                        => s_nout_frame_idx               , --:  out std_logic_vector(08*NB_MAX_CC-1                       downto 0);  --//ccx ul nprach,npuxch output frame index (oran)  
--        o_nout_subfrm_idx                       => s_nout_subfrm_idx              , --:  out std_logic_vector(04*NB_MAX_CC-1                       downto 0);  --//ccx ul nprach,npuxch output subframe index (oran)
--        o_nout_slot_idx                         => s_nout_slot_idx                , --:  out std_logic_vector(06*NB_MAX_CC-1                       downto 0);  --//ccx ul nprach,npuxch output slot index (oran)
--        o_nout_symbol_idx                       => s_nout_symbol_idx              , --:  out std_logic_vector(06*NB_MAX_CC-1                       downto 0);  --//ccx ul nprach,npuxch output symbol index (oran)
--        o_nout_start_re_idx                     => s_nout_start_re_idx            , --:  out std_logic_vector(16*NB_NUM_PATH*NB_MAX_CC-1           downto 0);  --//ccx ul nprach,npuxch output start re index (oran)
--        o_nout_en                               => s_nout_en                      , --:  out std_logic_vector(01*NB_NUM_PATH*NB_MAX_CC-1           downto 0);  --//ccx ul nprach,npuxch output u-plane data valid (oran)
--        o_nout_start_re                         => s_nout_start_re                , --:  out std_logic_vector(01*NB_NUM_PATH*NB_MAX_CC-1           downto 0);  --//ccx ul nprach,npuxch output start re indicator (oran)    
--        o_nout_last_re                          => s_nout_last_re                 , --:  out std_logic_vector(01*NB_NUM_PATH*NB_MAX_CC-1           downto 0);  --//ccx ul nprach,npuxch output last re indicator (oran)
--        o_nout_iq                               => s_nout_iq                      , --:  out std_logic_vector(2*TOP_DIO_BW*NB_NUM_PATH*NB_MAX_CC-1 downto 0)   --//ccx ul nprach,npuxch output u-plane data (oran)  
    
--        --- FROM BBCTRL (UL NB-IoT)
--        i_nin_frame_sync                        => s_mux_nin_frame_sync           ,--:   in  std_logic_vector ( 01*NB_MAX_CC-1                     downto 0);  --//ccx ul nprach,npuxch input frame sync (1 pulse of 245.76MHz every 10ms)
--        i_nin_en                                => s_mux_nin_en                   ,--:   in  std_logic_vector ( 01*NB_NUM_ANT*NB_MAX_CC-1          downto 0);  --//ccx ul nprach,npuxch input td data valid 
--        i_nin_i                                 => s_mux_nin_i                    ,--:   in  std_logic_vector ( TOP_DIO_BW*NB_NUM_ANT*NB_MAX_CC-1  downto 0);  --//ccx ul nprach,npuxch input td in-phase sample
--        i_nin_q                                 => s_mux_nin_q                    ,--:   in  std_logic_vector ( TOP_DIO_BW*NB_NUM_ANT*NB_MAX_CC-1  downto 0);  --//ccx ul nprach,npuxch input td quadrature sample
    
    
    
--    --   //--- From/To ORAN_TOP (eMTC PRACH)
--         i_min_filter_idx                       => s_min_filter_idx               , --:  [04*MT_NUM_PATH*MT_MAX_CC-1:0]             //ccx emtc prach input filter index
--         i_min_time_offset                      => s_min_time_offset              , --:  [16*MT_NUM_PATH*MT_MAX_CC-1:0]             //ccx emtc prach input time offset
--         i_min_frame_struct                     => s_min_frame_struct             , --:  [08*MT_NUM_PATH*MT_MAX_CC-1:0]             //ccx emtc prach input frame structure
--         i_min_cp_length                        => s_min_cp_length                , --:  [16*MT_NUM_PATH*MT_MAX_CC-1:0]             //ccx emtc prach input cp length
--         i_min_freq_offset                      => s_min_freq_offset              , --:  [24*MT_NUM_PATH*MT_MAX_CC-1:0]             //ccx emtc prach input frequency offset
--         i_min_num_psymbol                      => s_min_num_psymbol              , --:  [04*MT_NUM_PATH*MT_MAX_CC-1:0]             //ccx emtc prach input preamble symbol number
--         i_min_num_ro                           => s_min_num_ro                   , --:  [03*MT_NUM_PATH*MT_MAX_CC-1:0]             //ccx emtc prach input occasion number
--         i_min_num_prbc                         => s_min_num_prbc                 , --:  [08*MT_NUM_PATH*MT_MAX_CC-1:0]             //ccx emtc prach input c-plane physical rb size 
    
--         o_mout_frame_idx                       => s_mout_frame_idx               , --:  [08*MT_MAX_CC-1:0]                         //ccx emtc prach output frame index (oran)  
--         o_mout_subfrm_idx                      => s_mout_subfrm_idx              , --:  [04*MT_MAX_CC-1:0]                         //ccx emtc prach output subframe index (oran)
--         o_mout_slot_idx                        => s_mout_slot_idx                , --:  [06*MT_MAX_CC-1:0]                         //ccx emtc prach output slot index (oran)
--         o_mout_symbol_idx                      => s_mout_symbol_idx              , --:  [06*MT_MAX_CC-1:0]                         //ccx emtc prach output symbol index (oran)
--         o_mout_start_re_idx                    => s_mout_start_re_idx            , --:  [16*MT_NUM_PATH*MT_MAX_CC-1:0]             //ccx emtc prach output start re index (oran)
--         o_mout_en                              => s_mout_en                      , --:  [01*MT_NUM_PATH*MT_MAX_CC-1:0]             //ccx emtc prach output u-plane data valid (oran)
--         o_mout_start_re                        => s_mout_start_re                , --:  [01*MT_NUM_PATH*MT_MAX_CC-1:0]             //ccx emtc prach output start re indicator (oran)    
--         o_mout_last_re                         => s_mout_last_re                 , --:  [01*MT_NUM_PATH*MT_MAX_CC-1:0]             //ccx emtc prach output last re indicator (oran)
--         o_mout_iq                              => s_mout_iq                      , --:  [2*TOP_DIO_BW*MT_NUM_PATH*MT_MAX_CC-1:0]   //ccx emtc prach output u-plane data (oran)  
    
--         i_min_frame_sync                       => s_min_frame_sync               , --:in std_logic_vector(01*MT_MAX_CC-1                    downto 0);//ccx ul emtc prach input frame sync (1 pulse of 245.76MHz every 10ms)
--         i_min_en                               => s_min_en                       , --:in std_logic_vector(01*MT_NUM_ANT*MT_MAX_CC-1         downto 0);//ccx ul emtc prach input td data valid 
--         i_min_i                                => s_min_i                        , --:in std_logic_vector(TOP_DIO_BW*MT_NUM_ANT*MT_MAX_CC-1 downto 0);//ccx ul emtc prach input td in-phase sample
--         i_min_q                                => s_min_q                          --:in std_logic_vector(TOP_DIO_BW*MT_NUM_ANT*MT_MAX_CC-1 downto 0)//ccx ul emtc prach input td quadrature sample
--    );
    
    U_arry_1 : 
    for I in 0 to (DL_MAX_CC * DL_NUM_ANT - 1) generate 
        s_dout_i_array(I)                       <= s_dout_i(TOP_DIO_BW * I + TOP_DIO_BW -1 downto TOP_DIO_BW * I  )   ;
        s_dout_q_array(I)                       <= s_dout_q(TOP_DIO_BW * I + TOP_DIO_BW -1 downto TOP_DIO_BW * I  )   ;
    end generate;
    
     w_bbul_idata(15 downto 0)       <= s_uin_i_array(0);
     w_bbul_idata(31 downto 16)      <= s_uin_i_array(1);
     w_bbul_idata(47 downto 32)      <= s_uin_i_array(2);
     w_bbul_idata(63 downto 48)      <= s_uin_i_array(3);
     
     w_bbul_idata(79 downto 64)       <= s_uin_i_array(4);
     w_bbul_idata(95 downto 80)      <= s_uin_i_array(5);
     w_bbul_idata(111 downto 96)      <= s_uin_i_array(6);
     w_bbul_idata(127 downto 112)      <= s_uin_i_array(7);
     
     w_bbul_qdata(15 downto 0)       <= s_uin_q_array(0);
     w_bbul_qdata(31 downto 16)      <= s_uin_q_array(1);
     w_bbul_qdata(47 downto 32)      <= s_uin_q_array(2);
     w_bbul_qdata(63 downto 48)      <= s_uin_q_array(3);
                                              
     w_bbul_qdata(79 downto 64)      <= s_uin_q_array(4);
     w_bbul_qdata(95 downto 80)      <= s_uin_q_array(5);
     w_bbul_qdata(111 downto 96)     <= s_uin_q_array(6);
     w_bbul_qdata(127 downto 112)    <= s_uin_q_array(7);
                                                         

    
--    U_arry_sector_sync : 
--    for i in 0 to (UL_MAX_CC * UL_NUM_ANT -1) generate      
    
--        process(CLK_SYSX8)
--        begin
--            if (CLK_SYSX8'event and CLK_SYSX8 = '1') then
--                s_mux_uin_frame_sync  (0                        )                                                              <= s_uin_frame_sync(0                         ) ; 
--                s_mux_uin_en          (i / UL_MAX_CC            )                                                              <= s_uin_en        (i / UL_MAX_CC             ) ;  
--                s_mux_uin_i           (TOP_DIO_BW * (i/UL_MAX_CC)  + TOP_DIO_BW -1 downto TOP_DIO_BW * (i/UL_MAX_CC))          <= s_uin_i_array   (i / UL_MAX_CC             ) ;
--                s_mux_uin_q           (TOP_DIO_BW * (i/UL_MAX_CC)  + TOP_DIO_BW -1 downto TOP_DIO_BW * (i/UL_MAX_CC))          <= s_uin_q_array   (i / UL_MAX_CC             ) ;           
--            end if;
--        end process;
--    end generate;
    
--    U_arry_sector_sync : 
--    for i in 0          to (UL_MAX_CC * UL_NUM_ANT -1) generate  
--    -- ul_max_cc  : 2
--    -- ul_num_ant : 4
--    -- ul_cc_num  : 4
    
--        process(CLK_SYSX8)
--        begin
--            if (CLK_SYSX8'event and CLK_SYSX8 = '1') then
--                if sector_mode_sysctrl (0) = '1' then
--                    -- LPHY CELL 0 <= BBCTRL CELL 1 ANT 4R (0,1,2,3)
--                    s_mux_uin_frame_sync  (0                        )                                                              <= s_uin_frame_sync(1                         ) ; 
--                    s_mux_uin_en          (i / UL_MAX_CC            )                                                              <= s_uin_en        (i / UL_MAX_CC + UL_NUM_ANT) ;  
--                    s_mux_uin_i           (TOP_DIO_BW * (i/UL_MAX_CC)  + TOP_DIO_BW -1 downto TOP_DIO_BW * (i/UL_MAX_CC))          <= s_uin_i_array   (i / UL_MAX_CC + UL_NUM_ANT) ;
--                    s_mux_uin_q           (TOP_DIO_BW * (i/UL_MAX_CC)  + TOP_DIO_BW -1 downto TOP_DIO_BW * (i/UL_MAX_CC))          <= s_uin_q_array   (i / UL_MAX_CC + UL_NUM_ANT) ;
--                else
--                    -- LPHY CELL 0 <= BBCTRL CELL 0 ANT 4R (0,1,2,3)
--                    s_mux_uin_frame_sync  (0                        )                                                              <= s_uin_frame_sync(0                         ) ; 
--                    s_mux_uin_en          (i / UL_MAX_CC            )                                                              <= s_uin_en        (i / UL_MAX_CC             ) ;  
--                    s_mux_uin_i           (TOP_DIO_BW * (i/UL_MAX_CC)  + TOP_DIO_BW -1 downto TOP_DIO_BW * (i/UL_MAX_CC))          <= s_uin_i_array   (i / UL_MAX_CC             ) ;
--                    s_mux_uin_q           (TOP_DIO_BW * (i/UL_MAX_CC)  + TOP_DIO_BW -1 downto TOP_DIO_BW * (i/UL_MAX_CC))          <= s_uin_q_array   (i / UL_MAX_CC             ) ;
--                end if;           
--            end if;
--        end process;
    
--    --    process(CLK_SYSX8)
--    --    begin
--    --        if (CLK_SYSX8'event and CLK_SYSX8 = '1') then
--    --            if sector_mode_sysctrl (1) = '1' then
--    --                -- LPHY CELL 1 <= BBCTRL CELL 0 ANT 4R (0,1,2,3)
--    --                s_mux_uin_frame_sync  (1                         )                                                              <= s_uin_frame_sync(0                          ) ; 
--    --                s_mux_uin_en          (i / UL_MAX_CC + UL_NUM_ANT)                                                              <= s_uin_en        (i / UL_MAX_CC              ) ;  
--    --                s_mux_uin_i           (TOP_DIO_BW * (i/UL_MAX_CC)  + TOP_DIO_BW -1 + 64 downto TOP_DIO_BW * (i/UL_MAX_CC) + 64) <= s_uin_i_array   (i / UL_MAX_CC              ) ;
--    --                s_mux_uin_q           (TOP_DIO_BW * (i/UL_MAX_CC)  + TOP_DIO_BW -1 + 64 downto TOP_DIO_BW * (i/UL_MAX_CC) + 64) <= s_uin_q_array   (i / UL_MAX_CC              ) ;
--    --            else
--    --                -- LPHY CELL 1 <= BBCTRL CELL 1 ANT 4R (0,1,2,3)
--    --                s_mux_uin_frame_sync  (1                         )                                                              <= s_uin_frame_sync(1                         ) ; 
--    --                s_mux_uin_en          (i / UL_MAX_CC + UL_NUM_ANT)                                                              <= s_uin_en        (i / UL_MAX_CC + UL_NUM_ANT) ;  
--    --                s_mux_uin_i           (TOP_DIO_BW * (i/UL_MAX_CC)  + TOP_DIO_BW -1 + 64 downto TOP_DIO_BW * (i/UL_MAX_CC) + 64) <= s_uin_i_array   (i / UL_MAX_CC + UL_NUM_ANT) ;
--    --                s_mux_uin_q           (TOP_DIO_BW * (i/UL_MAX_CC)  + TOP_DIO_BW -1 + 64 downto TOP_DIO_BW * (i/UL_MAX_CC) + 64) <= s_uin_q_array   (i / UL_MAX_CC + UL_NUM_ANT) ;
--    --            end if;           
--    --        end if;
--    --    end process;
    
--    end generate ;
    
--    U_arry_eMTC : 
--    for i in 0          to (UL_MAX_CC * UL_NUM_ANT -1) generate  
--    -- ul_max_cc  : 2
--    -- ul_num_ant : 4
--    -- ul_cc_num  : 4
    
--        process(CLK_SYSX8)
--        begin
--            if (CLK_SYSX8'event and CLK_SYSX8 = '1') then
--                if emtc_sel_sysctrl (0) = '1' then
--                    -- LPHY CELL 0 <= BBCTRL CELL 1 ANT 4R (0,1,2,3)
--                    s_min_frame_sync     (0                        )                                                       <= s_uin_frame_sync(1                         ); 
--                    s_min_en             (i / UL_MAX_CC            )                                                       <= s_uin_en        (i / UL_MAX_CC + UL_NUM_ANT);  
--                    s_min_i              (TOP_DIO_BW * (i/UL_MAX_CC)  + TOP_DIO_BW -1 downto TOP_DIO_BW * (i/UL_MAX_CC))   <= s_uin_i_array   (i / UL_MAX_CC + UL_NUM_ANT);
--                    s_min_q              (TOP_DIO_BW * (i/UL_MAX_CC)  + TOP_DIO_BW -1 downto TOP_DIO_BW * (i/UL_MAX_CC))   <= s_uin_q_array   (i / UL_MAX_CC + UL_NUM_ANT);
--                else
--                    -- LPHY CELL 0 <= BBCTRL CELL 0 ANT 4R (0,1,2,3)
--                   s_min_frame_sync     (0                        )                                                       <= s_uin_frame_sync (0                        ); 
--                    s_min_en             (i / UL_MAX_CC            )                                                       <= s_uin_en         (i / UL_MAX_CC            );  
--                    s_min_i              (TOP_DIO_BW * (i/UL_MAX_CC)  + TOP_DIO_BW -1 downto TOP_DIO_BW * (i/UL_MAX_CC))   <= s_uin_i_array    (i / UL_MAX_CC            );
--                    s_min_q              (TOP_DIO_BW * (i/UL_MAX_CC)  + TOP_DIO_BW -1 downto TOP_DIO_BW * (i/UL_MAX_CC))   <= s_uin_q_array    (i / UL_MAX_CC            );
    
--                end if;           
--            end if;
--        end process;
    
--    end generate ;

---- ul_cc_num  : 4
---- NB_MAX_CC  : 3
--    process(CLK_SYSX8)
--    begin
--        if (CLK_SYSX8'event and CLK_SYSX8 = '1') then
--                --NBIoT#0
--                s_mux_nin_frame_sync     (0)                  <= s_uin_frame_sync (2 ); 
--                s_mux_nin_en             (3 downto 0)         <= s_uin_en         (11 downto 8 );  
--                s_mux_nin_i              (64-1 downto 0)      <= s_uin_i_array    (11) & s_uin_i_array  (10) & s_uin_i_array   (9)  & s_uin_i_array    (8);
--                s_mux_nin_q              (64-1 downto 0)      <= s_uin_q_array    (11) & s_uin_q_array  (10) & s_uin_q_array   (9)  & s_uin_q_array    (8);

--                --NBIoT#2
--                s_mux_nin_frame_sync     (1)                  <= s_uin_frame_sync (3 ); 
--                s_mux_nin_en             (7 downto 4)         <= s_uin_en         (15 downto 12 );  
--                s_mux_nin_i              (128-1 downto 64)    <= s_uin_i_array    (15) & s_uin_i_array  (14) & s_uin_i_array   (13)  & s_uin_i_array    (12);
--                s_mux_nin_q              (128-1 downto 64)    <= s_uin_q_array    (15) & s_uin_q_array  (14) & s_uin_q_array   (13)  & s_uin_q_array    (12);


--                --NBIoT#2
----                s_mux_nin_frame_sync     (2)                  <= s_uin_frame_sync (2 ); 
----                s_mux_nin_en             (11 downto 8)        <= s_uin_en         (11 downto 8 );  
----                s_mux_nin_i              (192-1 downto 128)   <= s_uin_i_array    (11) & s_uin_i_array  (10) & s_uin_i_array   (9)  & s_uin_i_array    (8);
----                s_mux_nin_q              (192-1 downto 128)   <= s_uin_q_array    (11) & s_uin_q_array  (10) & s_uin_q_array   (9)  & s_uin_q_array    (8);
--            end if;           
--    end process;


    U4_BBCTRL_TOP : BBCTRL_TOP
        port map(
    --------------------------------------------------------------------------------
    -- SYSCTRL-TOP
    --------------------------------------------------------------------------------
    
            RST_BBCTRL                          => rst_bbctrl                    , --: in  std_logic;
    
            CLK_SYS                             => clk_sys                       , --: in  std_logic;
            CLK_SYSX2                           => clk_sysx2                     , --: in  std_logic;
            CLK_SYSX3                           => clk_sysx3                     , --: in  std_logic;
            CLK_SYSX4                           => clk_sysx4                     , --: in  std_logic;
            CLK_SYSX5                           => clk_sysx5                     , --: in  std_logic;
            CLK_SYSX6                           => clk_sysx6                     , --: in  std_logic;
            CLK_SYSX8                           => clk_sysx8                     , --: in  std_logic;
            CLK_SYSX10                          => clk_sysx10                    , --: in  std_logic;
            CLK_SYSX12                          => clk_sysx12                    , --: in  std_logic;
            CLK_SYSX16                          => clk_sysx16                    , --: in  std_logic;
            CLK_SYSX20                          => clk_sysx20                    , --: in  std_logic;
    
    --------------------------------------------------------------------------------
    -- CPU-TOP
    --------------------------------------------------------------------------------
    
            RST_CPUIF                           => rst_cpuif                     , --: in  std_logic;
            CLK_CPUIF                           => clk_cpuif                     , --: in  std_logic;
    
            I_1PPS_CPU                          => ptp_1pps_cpu_top              , -- : in  std_logic;
            I_BFN_STRB_CPU                      => frame_sync_cpu_top(0)         , -- : in  std_logic;
            I_BFN_CPU                           => sfn_num_cpu_top(10 downto 0)  , -- : in  std_logic_vector(10 downto 0);
    
    --------------------------------------------------------------------------------
    -- CPUIF_TOP
    --------------------------------------------------------------------------------
    
            WREN_CPUIF_IN                      => wren_cpuif_bbctrl              , --: in  std_logic;
            RDEN_CPUIF_IN                      => rden_cpuif_bbctrl              , --: in  std_logic;
            ADDR_CPUIF_IN                      => addr_cpuif_bbctrl              , --: in  std_logic_vector(15 downto 0);
            WDATA_CPUIF_IN                     => wdata_cpuif_bbctrl             , --: in  std_logic_vector(31 downto 0);
            RDATA_CPUIF_OUT                    => rdata_cpuif_bbctrl             , --: out std_logic_vector(31 downto 0);
            RDVAL_CPUIF_OUT                    => rdval_cpuif_bbctrl             , --: out std_logic;
    
    --------------------------------------------------------------------------------
    -- BB-TOP
    --------------------------------------------------------------------------------
    
            I_DL_FSYNC                         => s_dout_frame_sync              , --:in  std_logic_vector( DL_CC_NUM-1 downto 0);    -- 1 clock frame(10ms) sync  
            I_DL_TDD                           => (others => '1')                , --:in  std_logic_vector( DL_CC_NUM-1 downto 0);      
            I_DL_VLD                           => s_dout_en                      , --:in  std_logic_vector( DL_CC_NUM*4-1 downto 0);    -- valid signal for valid data.   
    
            I_DL_DATA_I                        => s_dout_i_array                 , --:in  std_logic_array16(DL_CC_NUM*4-1 downto 0);    -- 16b idata path per one ant path.      
            I_DL_DATA_Q                        => s_dout_q_array                 , --:in  std_logic_array16(DL_CC_NUM*4-1 downto 0);    -- 16b qdata path per one ant path.  
    
            O_UL_FSYNC                         => s_uin_frame_sync               , --:out std_logic_vector( UL_CC_NUM-1 downto 0);    -- 1 clock frame(10ms) sync   
            O_UL_TDD                           => open                           , --:out std_logic_vector( UL_CC_NUM-1 downto 0);       
            O_UL_VLD                           => s_uin_en                       , --:out std_logic_vector( UL_CC_NUM*4-1 downto 0);    -- valid signal for valid data.   
            O_UL_DATA_I                        => s_uin_i_array                  , --:out std_logic_array16(UL_CC_NUM*4-1 downto 0);    -- 16b idata path per one ant path.  
            O_UL_DATA_Q                        => s_uin_q_array                  , --:out std_logic_array16(UL_CC_NUM*4-1 downto 0);    -- 16b qdata path per one ant path.  
    
    --------------------------------------------------------------------------------
    -- PIM-SBIF_TOP
    --------------------------------------------------------------------------------
    
            PIM_SBIF_RX_ENB_IN                 => rx_enb_pim_sbif                , --: in  std_logic_vector(PIM_SBIF_NUM-1 downto 0);
            PIM_SBIF_RX_I_IN                   => rx_idata_pim_sbif              , --: in  std_logic_array16(PIM_SBIF_NUM-1 downto 0);
            PIM_SBIF_RX_Q_IN                   => rx_qdata_pim_sbif              , --: in  std_logic_array16(PIM_SBIF_NUM-1 downto 0);
    
            PIM_SBIF_TX_VLD_OUT                => open                           , --: out std_logic_vector(PIM_SBIF_NUM-1 downto 0);
            PIM_SBIF_TX_I_OUT                  => tx_idata_pim_sbif              , --: out std_logic_array16(PIM_SBIF_NUM-1 downto 0);
            PIM_SBIF_TX_Q_OUT                  => tx_qdata_pim_sbif              , --: out std_logic_array16(PIM_SBIF_NUM-1 downto 0);
    
            PIM_SBIF_TX_SYNC                   => pim_sbif_tx_sync               , --: out std_logic;
            PIM_SBIF_TX_1PPS                   => pim_sbif_tx_1pps               , --: out std_logic;
            PIM_SBIF_TX_BFN_STRB               => pim_sbif_tx_bfn_strb           , --: out std_logic;
            PIM_SBIF_TX_BFN                    => pim_sbif_tx_bfn                , --: out std_logic_vector(10 downto 0);
    
    --------------------------------------------------------------------------------
    -- DSP-TOP
    --------------------------------------------------------------------------------
            DL_BFN_OK                          => dl_bfn_nr_ok_bbctrl            , --: out std_logic;
    
            DL_AIRTECH_OUT                     => dl_airtech_bbctrl              , --: out std_logic_array4(DL_BBIQARY_NUM-1 downto 0);
            DL_CHBW_OUT                        => dl_chbw_bbctrl                 , --: out std_logic_array4(DL_BBIQARY_NUM-1 downto 0);
            DL_TDD_OUT                         => open                           , --: out std_logic;
            DL_40MS_OUT                        => dl_ssb_bbctrl_strb             , --: out std_logic;
            DL_BFN_STRB_OUT                    => dl_bfn_bbctrl_strb             , --: out std_logic;
            DL_BFN_OUT                         => dl_bfn_nr_modulo_bbctrl        , --: out std_logic_vector(11 downto 0);
            DL_SYNC_OUT                        => dl_sync_bbctrl                 , --: out std_logic_vector(DL_BBIQARY_NUM-1 downto 0);
            DL_IQ_OUT                          => dl_iq_bbctrl                   , --: out std_logic_array16(DL_BBIQARY_NUM-1 downto 0);
    
            UL_AIRTECH_OUT                     => ul_airtech_bbctrl              , --: out std_logic_array4(UL_BBIQARY_NUM-1 downto 0);
            UL_CHBW_OUT                        => ul_chbw_bbctrl                 , --: out std_logic_array4(UL_BBIQARY_NUM-1 downto 0);
            UL_TDD_IN                          => '1'                            , --ul_tdd_dsp                     , --: in  std_logic;
            UL_BFN_STRB_IN                     => ul_bfn_strb_dsp                , --: in  std_logic;
            UL_SYNC_IN                         => ul_sync_dsp                    , --: in  std_logic_vector(UL_BBIQARY_NUM-1 downto 0);
            UL_IQ_IN                           => ul_iq_dsp                      , --: in  std_logic_array16(UL_BBIQARY_NUM-1 downto 0);
    
            PIM_SYNC_IN                        => trans_pim_sync                 , --: in  std_logic_vector(PIM_SBIF_NUM-1 downto 0);
            PIM_I_IN                           => trans_pim_idata                , --: in  std_logic_array15(PIM_SBIF_NUM-1 downto 0);
            PIM_Q_IN                           => trans_pim_qdata                , --: in  std_logic_array15(PIM_SBIF_NUM-1 downto 0);
    
            PIM_SYNC_OUT                       => rcv_pim_sync                   , --: out std_logic_vector(PIM_SBIF_NUM-1 downto 0);
            PIM_I_OUT                          => rcv_pim_idata                  , --: out std_logic_array15(PIM_SBIF_NUM-1 downto 0);
            PIM_Q_OUT                          => rcv_pim_qdata                  , --: out std_logic_array15(PIM_SBIF_NUM-1 downto 0);
    
    --------------------------------------------------------------------------------
    -- MISC-TOP
    --------------------------------------------------------------------------------
    
            DUMP_BFN_STRB_OUT                 => dump_bfn_strb_bbctrl           ,
            DUMP_DATA_OUT                     => dump_data_bbctrl               ,
            DUMP_DVLD_OUT                     => dump_dvld_bbctrl               ,
    
         -- fb_sw_new
            FBSW_CNT                          => fbsw_cnt_misc(3 downto 0)      , --: in  std_logic_vector(3 downto 0);
            FBSW_SSB_IND_FLAG                 => fbsw_ssb_ind                   , --: in  std_logic; 
            FBSW_MEAS_UPDATE                  => fbsw_pwr_msr_upt_misc          
    );
    
    --fbsw_auto_mode_done_dsp  <= fbsw_auto_mode_done_misc & fbsw_auto_mode_done_misc;
    fbsw_auto_mode_done_dsp  <= fbsw_auto_mode_done_misc;

-- ***************************************************************************
-- ** U4 : DSP-TOP                                                          **
-- ***************************************************************************
    U5_DSP_TOP : DSP_TOP
    port map(
            -- ***********************
            -- SYSCTRL-TOP Interface
            -- ***********************
            -- Internal PLL Lock
            INT_SYSPLL_LOCK_IN                  => int_syspll_lock               ,

            -- System Reset & Clock
            RST_DDUC                            => rst_dduc                      ,
            RST_CFR                             => rst_cfr                       ,
            RST_DPD                             => rst_dpd                       ,
            RST_PIM                             => rst_pim                       ,      --: in  std_logic;

            CLK_SYS                             => clk_sys                       ,
            CLK_SYSX2                           => clk_sysx2                     ,
            CLK_SYSX3                           => clk_sysx3                     ,
            CLK_SYSX4                           => clk_sysx4                     ,
            CLK_SYSX5                           => clk_sysx5                     ,
            CLK_SYSX6                           => clk_sysx6                     ,
            CLK_SYSX8                           => clk_sysx8                     ,
            CLK_SYSX10                          => clk_sysx10                    ,
            CLK_SYSX12                          => clk_sysx12                    ,
            CLK_SYSX16                          => clk_sysx16                    ,
            CLK_SYSX20                          => clk_sysx20                    ,

            -- ***********************
            -- CPU-TOP Interface
            -- ***********************
            -- CPU Reset & Clock
            RST_CPUIF                           => rst_cpuif                     ,
            CLK_CPUIF                           => clk_cpuif                     ,

            RST_DPDIF                           => rst_cpuif                     , -- rst_dpdif
            CLK_DPDIF                           => clk_cpuif                     , -- clk_dpdif

            -- ***********************
            -- CPUIF_TOP Interface
            -- ***********************
            -- CPUIF DSP Common
            ADDR_CPUIF_IN                       => addr_cpuif_dsp                ,
            WDATA_CPUIF_IN                      => wdata_cpuif_dsp               ,
            RDATA_CPUIF_OUT                     => rdata_cpuif_dsp               ,
            WREN_CPUIF_IN                       => wren_cpuif_dsp                ,
            RDEN_CPUIF_IN                       => rden_cpuif_dsp                ,
            RDVLD_CPUIF_OUT                     => rdval_cpuif_dsp               ,

            -- CPUIF DPD
            ADDR_DPDIF_IN                       => addr_cpuif_dpd                ,
            WDATA_DPDIF_IN                      => wdata_cpuif_dpd               ,
            RDATA_DPDIF_OUT                     => rdata_cpuif_dpd               ,
            WREN_DPDIF_IN                       => wren_cpuif_dpd                ,
            RDEN_DPDIF_IN                       => rden_cpuif_dpd                ,
            RDVLD_DPDIF_OUT                     => rdval_cpuif_dpd               ,

            -- ***********************
            -- BBCTRL-TOP Interface
            -- ***********************
            -- System Information
            DL_AIRTECH_IN                       => dl_airtech_bbctrl             ,
            DL_CHBW_IN                          => dl_chbw_bbctrl                ,

            UL_AIRTECH_IN                       => ul_airtech_bbctrl             ,
            UL_CHBW_IN                          => ul_chbw_bbctrl                ,

            -- TDD & BFN Strobe
            DL_BFN_STRB_IN                      => dl_bfn_bbctrl_strb            ,
            DL_SSB_STRB_IN                      => dl_ssb_bbctrl_strb            , --: in  std_logic;  -- Downlink SSB period Strobe (20/40/80/160msec)
            DL_TDD_IN                           => '1'                           , --dl_tdd_bbctrl                 ,

            UL_BFN_STRB_OUT                     => ul_bfn_strb_dsp               ,
            UL_TDD_OUT                          => open                          , --ul_tdd_dsp

            BCF_ENB_IN                          => '0'                           , --: in  std_logic;

            -- Traffic IQ
            DL_SYNC_IN                          => dl_sync_bbctrl                ,
            DL_IQ_IN                            => dl_iq_bbctrl                  ,

            UL_SYNC_OUT                         => ul_sync_dsp                   ,
            UL_IQ_OUT                           => ul_iq_dsp                     ,

            -- ***********************
            -- DCIF-TOP Interface
            -- ***********************
            -- TDD & BFN Strobe
            DL_BFN_STRB_OUT                     => dl_bfn_strb_dsp               ,
            DL_TDD_OUT                          => open                          , -- dl_tdd_dsp
            DL_SSB_STRB_OUT                     => dl_ssb_strb_dsp               ,

            FB_BFN_STRB_IN                      => fb_bfn_strb_dcif              ,
            FB_TDD_IN                           => fb_tdd_dcif                   ,
            FB_SSB_STRB_IN                      => fb_ssb_strb_dcif              ,

            UL_BFN_STRB_IN                      => ul_bfn_strb_dcif              ,
            UL_TDD_IN                           => ul_tdd_dcif                   ,

            BCF_ENB_OUT                         => open                          , --: out std_logic;

            -- Traffic IQ
            DL_SYNC_OUT                         => dl_sync_dsp                   ,
            DL_I_OUT                            => dl_i_dsp                      ,
            DL_Q_OUT                            => dl_q_dsp                      ,

            FB_SYNC_IN                          => fb_sync_dcif                  ,
            --        FB_I_IN                             => fb_i_even_dcif                ,
            --        FB_Q_IN                             => fb_q_even_dcif                     ,
            FB_I_IN                             => fb_i_dcif                     ,
            FB_Q_IN                             => fb_q_dcif                     ,

            UL_SYNC_IN                          => ul_sync_dcif                  ,
            UL_I_IN                             => ul_i_dcif                     ,
            UL_Q_IN                             => ul_q_dcif                     ,

            I_NBIOT_NCO_VALID_CC0               => s_nout_nco_valid    ( 0          ), --: in  std_logic;
            I_NBIOT_NCO_VALID_CC1               => s_nout_nco_valid    ( 1          ), --: in  std_logic; 3*4*2
            I_NBIOT_ORAN_FR_STRUCT_CC0          => s_nout_frame_struct ( 7 downto  0),--: in  std_logic_vector(7 downto 0);
            I_NBIOT_ORAN_FR_STRUCT_CC1          => s_nout_frame_struct (15 downto  8),--: in  std_logic_vector(7 downto 0);
            I_NBIOT_FREQ_OFFSET_CC0             => s_nout_freq_offset  (23 downto  0),--: in  std_logic_vector(23 downto 0);
            I_NBIOT_FREQ_OFFSET_CC1             => s_nout_freq_offset  (47 downto 24),--: in  std_logic_vector(23 downto 0);
            -- ***************************
            -- SBIF_TOP Interface for PIM
            -- ***************************
            PIM_SYNC_IN                         => (others=>'0')                , --rcv_pim_sync                  , --
            PIM_I_IN                            => (others=>(others=>'0'))      , --rcv_pim_idata                 , --
            PIM_Q_IN                            => (others=>(others=>'0'))      , --rcv_pim_qdata                 , --

            PIM_SYNC_OUT                        => open                         , --trans_pim_sync                , --
            PIM_I_OUT                           => open                         , --trans_pim_idata               , --
            PIM_Q_OUT                           => open                         , --trans_pim_qdata               , --

            -- ***********************
            -- MISC-TOP Interface
            -- ***********************
            FBSW_SSB_IND_FLAG_DSP               => fbsw_ssb_ind                  , --: in  std_logic; 


            -- Feedback Switch
            FBSW_START_TRIG_IN                  => fbsw_start_trig_misc          ,
            FBSW_CNT_IN                         => fbsw_cnt_misc                 ,
            FBSW_AUTO_MODE_DONE_IN              => fbsw_auto_mode_done_dsp       ,
            FBSW_PWR_MSR_UDT_IN                 => fbsw_pwr_msr_upt_misc         ,
            FBSW_MANUAL_MODE_IN                 => fbsw_manual_mode_misc         ,
            FBSW_SC_PATH_SEL_IN                 => fbsw_sc_path_sel              ,

            PWR_MSR_FB_SYNC_IN                  => pwr_msr_fb_sync             ,
            PWR_MSR_EN_IN                       => pwr_msr_en                  ,

            -- Signal Suspension
            SIG_SUS_FLAG_OUT                    => sig_sus_flag_dsp              ,
            SIG_SUS_DLOFF_IN                    => sig_sus_dloff_dsp             ,

            -- IQ/Clock Status
            DL_IQ_ISZERO_OUT                    => dl_iq_iszero_dsp              ,
            DL_CLK_ISZERO_OUT                   => dl_clk_iszero_dsp             ,

            -- Test Pattern (Reserved)
            TEST_DATA_IN                        => test_data_dsp                 ,
            TEST_DENB_OUT                       => test_denb_dsp                 ,

            -- Dump
            DUMP_BFN_STRB_OUT                   => dump_bfn_strb_dsp             ,
            DUMP_DVLD_OUT                       => dump_dvld_dsp                 ,
            DUMP_DATA_OUT                       => dump_data_dsp                 ,

            -- ***********************
            -- TOP Port Interface
            -- ***********************
            -- FPGA ID
            FPGA_ID_IN                          => (others => '0')               ,

            -- Debugging Port(Reserved)
            DBG_SIG_OUT                         => dbg_sig_dsp
        );


    jesd_axi_resetn  <= not rst_dcif;

    --fbsw_auto_mode_done_dsp  <= fbsw_auto_mode_done_misc & fbsw_auto_mode_done_misc;
    fbsw_auto_mode_done_dsp  <= fbsw_auto_mode_done_misc;
    
-- ***************************************************************************
-- ** U6 : DCIF-TOP                                                         **
-- ***************************************************************************
    U6_DCIF_TOP : DCIF_TOP
    GENERIC map
    (
        SIMULATION_ON                       => false                          --: boolean   := false
    )
    port map(
        -- PLL Monitor
--        EXT_SYSPLL_LOCK_IN                  => CLK_PLL_LD                    ,
--        INT_SYSPLL_LOCK_IN                  => int_syspll_lock               ,

        -- Clock
        RST_DCIF                            => rst_dcif                      ,
--        CLK_SYS                             => clk_sys                       ,
--        CLK_SYSX2                           => clk_sysx2                     ,
--        CLK_SYSX3                           => clk_sysx3                     ,
        CLK_SYSX4                           => clk_sysx4                     ,
--        CLK_SYSX5                           => clk_sysx5                     ,
--        CLK_SYSX6                           => clk_sysx6                     ,
        CLK_SYSX8                           => clk_sysx8                     ,
--        CLK_SYSX10                          => clk_sysx10                    ,
--        CLK_SYSX12                          => clk_sysx12                    ,
--        CLK_SYSX16                          => clk_sysx16                    ,
--        CLK_SYSX20                          => clk_sysx20                    ,

        REFCLK_SERDES_IN                    => refclk_jserdes  (0)           ,

        --CPU Interface
        RST_CPUIF                           => rst_cpuif                     ,
        CLK_CPUIF                           => clk_cpuif                     ,
        ADDR_CPUIF_IN                       => addr_cpuif_dcif               ,
        WDATA_CPUIF_IN                      => wdata_cpuif_dcif              ,
        RDATA_CPUIF_OUT                     => rdata_cpuif_dcif              ,
        WREN_CPUIF_IN                       => wren_cpuif_dcif               ,
        RDEN_CPUIF_IN                       => rden_cpuif_dcif               ,
        RDVAL_CPUIF_OUT                     => rdval_cpuif_dcif              ,

        -- RFIC Interface
        JESD_SERIAL_RX_IN_P                 => JESD_SERIAL_RX_IN_P           ,
        JESD_SERIAL_RX_IN_N                 => JESD_SERIAL_RX_IN_N           ,
        JESD_SYNC_RX_OUT                    => JESD_SYNC_RX_OUT              ,
        JESD_SYSREF_RX_OUT                  => JESD_SYSREF_RX_OUT            ,
 
        JESD_SERIAL_TX_OUT_P                => JESD_SERIAL_TX_OUT_P          ,
        JESD_SERIAL_TX_OUT_N                => JESD_SERIAL_TX_OUT_N          ,
        JESD_SYSREF_TX_OUT                  => JESD_SYSREF_TX_OUT            ,
        JESD_SYNC_TX_IN                     => JESD_SYNC_TX_IN               ,

        JESD_SERIAL_FB_IN_P                 => JESD_SERIAL_FB_IN_P           ,
        JESD_SERIAL_FB_IN_N                 => JESD_SERIAL_FB_IN_N           ,
        JESD_SYNC_FB_OUT                    => JESD_SYNC_FB_OUT              ,
        JESD_SYSREF_FB_OUT                  => JESD_SYSREF_FB_OUT            ,

       ------------------------------------------------------------------------------------------
        -- JESD IP AXI Interface
        ------------------------------------------------------------------------------------------
        JESD204B_AXI_ACLK                   => clk_cpuif                                 ,--: in STD_LOGIC;
        JESD204B_AXI_ARESETN                => jesd_axi_resetn                           ,--: in STD_LOGIC;
        JESD204B_AXI_araddr                 => JESD_AXI_INTERCONNECT_araddr_cpu          ,--: in STD_LOGIC_VECTOR ( 31 downto 0 );
        JESD204B_AXI_arburst                => JESD_AXI_INTERCONNECT_arburst_cpu         ,--: in STD_LOGIC_VECTOR ( 1 downto 0 );
        JESD204B_AXI_arcache                => JESD_AXI_INTERCONNECT_arcache_cpu         ,--: in STD_LOGIC_VECTOR ( 3 downto 0 );
        JESD204B_AXI_arlen                  => JESD_AXI_INTERCONNECT_arlen_cpu           ,--: in STD_LOGIC_VECTOR ( 7 downto 0 );
        JESD204B_AXI_arlock                 => JESD_AXI_INTERCONNECT_arlock_cpu          ,--: in STD_LOGIC_VECTOR ( 0 to 0 );
        JESD204B_AXI_arprot                 => JESD_AXI_INTERCONNECT_arprot_cpu          ,--: in STD_LOGIC_VECTOR ( 2 downto 0 );
        JESD204B_AXI_arqos                  => JESD_AXI_INTERCONNECT_arqos_cpu           ,--: in STD_LOGIC_VECTOR ( 3 downto 0 );
        JESD204B_AXI_arready                => JESD_AXI_INTERCONNECT_arready_dcif        ,--: out STD_LOGIC;
        JESD204B_AXI_arregion               => JESD_AXI_INTERCONNECT_arregion_cpu        ,--: in STD_LOGIC_VECTOR ( 3 downto 0 );
        JESD204B_AXI_arsize                 => JESD_AXI_INTERCONNECT_arsize_cpu          ,--: in STD_LOGIC_VECTOR ( 2 downto 0 );
        JESD204B_AXI_arvalid                => JESD_AXI_INTERCONNECT_arvalid_cpu         ,--: in STD_LOGIC;
        JESD204B_AXI_awaddr                 => JESD_AXI_INTERCONNECT_awaddr_cpu          ,--: in STD_LOGIC_VECTOR ( 31 downto 0 );
        JESD204B_AXI_awburst                => JESD_AXI_INTERCONNECT_awburst_cpu         ,--: in STD_LOGIC_VECTOR ( 1 downto 0 );
        JESD204B_AXI_awcache                => JESD_AXI_INTERCONNECT_awcache_cpu         ,--: in STD_LOGIC_VECTOR ( 3 downto 0 );
        JESD204B_AXI_awlen                  => JESD_AXI_INTERCONNECT_awlen_cpu           ,--: in STD_LOGIC_VECTOR ( 7 downto 0 );
        JESD204B_AXI_awlock                 => JESD_AXI_INTERCONNECT_awlock_cpu          ,--: in STD_LOGIC_VECTOR ( 0 to 0 );
        JESD204B_AXI_awprot                 => JESD_AXI_INTERCONNECT_awprot_cpu          ,--: in STD_LOGIC_VECTOR ( 2 downto 0 );
        JESD204B_AXI_awqos                  => JESD_AXI_INTERCONNECT_awqos_cpu           ,--: in STD_LOGIC_VECTOR ( 3 downto 0 );
        JESD204B_AXI_awready                => JESD_AXI_INTERCONNECT_awready_dcif        ,--: out STD_LOGIC;
        JESD204B_AXI_awregion               => JESD_AXI_INTERCONNECT_awregion_cpu        ,--: in STD_LOGIC_VECTOR ( 3 downto 0 );
        JESD204B_AXI_awsize                 => JESD_AXI_INTERCONNECT_awsize_cpu          ,--: in STD_LOGIC_VECTOR ( 2 downto 0 );
        JESD204B_AXI_awvalid                => JESD_AXI_INTERCONNECT_awvalid_cpu         ,--: in STD_LOGIC;
        JESD204B_AXI_bready                 => JESD_AXI_INTERCONNECT_bready_cpu          ,--: in STD_LOGIC;
        JESD204B_AXI_bresp                  => JESD_AXI_INTERCONNECT_bresp_dcif          ,--: out STD_LOGIC_VECTOR ( 1 downto 0 );
        JESD204B_AXI_bvalid                 => JESD_AXI_INTERCONNECT_bvalid_dcif         ,--: out STD_LOGIC;
        JESD204B_AXI_rdata                  => JESD_AXI_INTERCONNECT_rdata_dcif          ,--: out STD_LOGIC_VECTOR ( 31 downto 0 );
        JESD204B_AXI_rlast                  => JESD_AXI_INTERCONNECT_rlast_dcif          ,--: out STD_LOGIC;
        JESD204B_AXI_rready                 => JESD_AXI_INTERCONNECT_rready_cpu          ,--: in STD_LOGIC;
        JESD204B_AXI_rresp                  => JESD_AXI_INTERCONNECT_rresp_dcif          ,--: out STD_LOGIC_VECTOR ( 1 downto 0 );
        JESD204B_AXI_rvalid                 => JESD_AXI_INTERCONNECT_rvalid_dcif         ,--: out STD_LOGIC;
        JESD204B_AXI_wdata                  => JESD_AXI_INTERCONNECT_wdata_cpu           ,--: in STD_LOGIC_VECTOR ( 31 downto 0 );
        JESD204B_AXI_wlast                  => JESD_AXI_INTERCONNECT_wlast_cpu           ,--: in STD_LOGIC;
        JESD204B_AXI_wready                 => JESD_AXI_INTERCONNECT_wready_dcif         ,--: out STD_LOGIC;
        JESD204B_AXI_wstrb                  => JESD_AXI_INTERCONNECT_wstrb_cpu           ,--: in STD_LOGIC_VECTOR ( 3 downto 0 );
        JESD204B_AXI_wvalid                 => JESD_AXI_INTERCONNECT_wvalid_cpu        ,--: in STD_LOGIC;


        -- DUMP Interface
        DUMP_BFN_STRB_OUT                   => dump_bfn_strb_dcif(0)            ,
        DUMP_DVLD_OUT                       => dump_dvld_dcif(0)                ,
        DUMP_DATA_OUT                       => dump_data_dcif(0)                ,

        --DL data
--        DL_SYNC_IN                          => dl_sync_dsp                 ,
        DL_I_IN                             => dl_i_dsp                      ,
        DL_Q_IN                             => dl_q_dsp                      ,

        --FB data
        FB_SYNC_OUT                         => fb_sync_dcif                   ,
        FB_I_OUT                            => fb_i_dcif                    ,
        FB_Q_OUT                            => fb_q_dcif                    ,
--        FB_I_EVEN_OUT                       => fb_i_even_dcif                 ,--: out std_logic_array16(FB_PATH_NUM-1 downto 0);
--        FB_Q_EVEN_OUT                       => fb_q_even_dcif                 ,--: out std_logic_array16(FB_PATH_NUM-1 downto 0);
--        FB_I_ODD_OUT                        => fb_i_odd_dcif                  ,--: out std_logic_array16(FB_PATH_NUM-1 downto 0);
--        FB_Q_ODD_OUT                        => fb_q_odd_dcif                  ,--: out std_logic_array16(FB_PATH_NUM-1 downto 0);

        --UL data
        UL_SYNC_OUT                         => ul_sync_dcif                  ,
        UL_VALID_OUT                    => open                          ,--    : out std_logic;
        UL_I_OUT                            => ul_i_dcif                     ,
        UL_Q_OUT                            => ul_q_dcif                     ,

        -- TEST
        TEST_DATA_IN                        => test_data_dcif(0)             ,
        TEST_DENB_OUT                       => test_denb_dcif(0)             ,

        -- Flag gen
        SIG_SUS_DLFLAG_OUT                  => sig_sus_dlflag_dcif           ,
        SIG_SUS_FBFLAG_OUT                  => sig_sus_fbflag_dcif           ,
        SIG_SUS_ULFLAG_OUT                  => sig_sus_ulflag_dcif           ,

        -- TDD/BFN
        DL_SSB_STRB_IN                      => dl_ssb_strb_dsp               ,
        DL_SSB_STRB_OUT                     => dl_ssb_strb_dcif              ,
        DL_BFN_STRB_IN                      => dl_bfn_strb_dsp               ,
        DL_BFN_STRB_OUT                     => dl_bfn_strb_dcif              ,
        DL_TDD_IN                           => '1'                           , --dl_tdd_dsp                    ,
        DL_TDD_OUT                          => dl_tdd_dcif                   ,
        DL_BCF_ENB_IN                       => '0'                           , --: in  std_logic;
        DL_BCF_ENB_OUT                      => open                          , --: out std_logic;

--        UL_SSB_STRB_IN                      => '0'                           ,
--        UL_SSB_STRB_OUT                     => open                          ,
        UL_BFN_STRB_IN                      => ul_bfn_strb_misc              ,
        UL_BFN_STRB_OUT                     => ul_bfn_strb_dcif              ,
        UL_TDD_IN                           => '1'                           , --ul_tdd_misc                   ,
        UL_TDD_OUT                          => ul_tdd_dcif                   ,
        UL_BCF_ENB_IN                       => '0'                           , --
        UL_BCF_ENB_OUT                      => open                          , --: out std_logic;


        FB_SSB_STRB_IN                      => fb_ssb_strb_misc              ,
        FB_SSB_STRB_OUT                     => fb_ssb_strb_dcif              ,
        FB_BFN_STRB_IN                      => fb_bfn_strb_misc              ,
        FB_BFN_STRB_OUT                     => fb_bfn_strb_dcif              ,
        FB_TDD_IN                           => '1'                           , --fb_tdd_misc                   ,
        FB_TDD_OUT                          => fb_tdd_dcif                   ,

--        DBG_SIG_OUT                         => dbg_sig_dcif
        UL_BFN_STRB_OUT_TP_SOURCE           => open                          ,--: out std_logic;
        TP_UL_PATTERN_PATH_SEL_IN           => (others => '0')               ,--: in std_logic_vector(15 downto 0);
        TP_UL_PATTERN_BFN_SEL_DCIF_IN       => '0'                           ,--: in std_logic;

        TP_GEN_BFN_DCIF_IN                  => '0'                           ,--: in std_logic;
        TP_GEN_GAIN_IDATA_DCIF_IN           => (others => '0')               ,--: in std_logic_vector(15 downto 0);
        TP_GEN_GAIN_QDATA_DCIF_IN           => (others => '0')                --: in std_logic_vector(15 downto 0)

        );

-- ***************************************************************************
-- ** U6 : MISC-TOP                                                         **
-- ***************************************************************************

    ecpri_fail <= (not ecpri_stat_rx_block_lock (0)) or ecpri_stat_rx_local_fault(0)  ; 

    UF_MISC_TOP : MISC_TOP
    port map(
        --CPU-TOP
        CLK_CPUIF                           => clk_cpuif                     ,
        RST_CPUIF                           => rst_cpuif                     ,

        AXI_TIMEOUT_IN                      => i_axi_timeout                 ,

        DMA_RDCLK_OUT                       => dma_rdclk                     ,
        DMA_RDRDY_IN                        => dma_rdrdy                     ,
        DMA_RDEPT_IN                        => dma_rdept                     ,
        DMA_RDFULL_IN                       => dma_rdfull                    ,
        DMA_RDEN_OUT                        => dma_rden                      ,
        DMA_RDATA_IN                        => dma_rdata                     ,
        DMA_WRCLK_OUT                       => dma_wrclk                     ,
        DMA_WRRDY_IN                        => dma_wrrdy                     ,
        DMA_WREPT_IN                        => dma_wrept                     ,
        DMA_WRFULL_IN                       => dma_wrfull                    ,
        DMA_WREN_OUT                        => dma_wren                      ,
        DMA_WDATA_OUT                       => dma_wdata                     ,

        --CPUIF-TOP
        ADDR_CPUIF_IN                       => addr_cpuif_misc               ,
        RDATA_CPUIF_OUT                     => rdata_cpuif_misc              ,
        RDEN_CPUIF_IN                       => rden_cpuif_misc               ,
        RDVAL_CPUIF_OUT                     => rdval_cpuif_misc              ,
        WDATA_CPUIF_IN                      => wdata_cpuif_misc              ,
        WREN_CPUIF_IN                       => wren_cpuif_misc               ,

        --SYSCTRLTOP
        TDD_CTRL_IN                         => tdd_ctrl                      ,
        CLK_MISC0                           => clk_misc0                     ,
        CLK_MISC1                           => clk_misc1                     ,
        CLK_MISC2                           => clk_misc2                     ,
        CLK_MISC3                           => clk_misc3                     ,
        RST_MISC                            => rst_misc                      ,

        CLK_SYS                             => clk_sys                       ,
        CLK_SYSX2                           => clk_sysx2                     ,
        CLK_SYSX3                           => clk_sysx3                     ,
        CLK_SYSX4                           => clk_sysx4                     ,
        CLK_SYSX5                           => clk_sysx5                     ,
        CLK_SYSX6                           => clk_sysx6                     ,
        CLK_SYSX8                           => clk_sysx8                     ,
        CLK_SYSX10                          => clk_sysx10                    ,
        CLK_SYSX12                          => clk_sysx12                    ,
        CLK_SYSX16                          => clk_sysx16                    ,
        CLK_SYSX20                          => clk_sysx20                    ,

        TCXO_CLK_X1                         => clk_tcxo_x1                   , --: in std_logic;
        TCXO_CLK_X4                         => clk_tcxo_x4                   , --: in std_logic;
        TCXO_CLK_X8                         => clk_tcxo_x8                   , --: in std_logic; 

        RX_BFN_STRB_SYSCTRL_IN(0)           => w_dlfe_frame_sync(0), --s_din_frame_sync(0)           , --rx_bfn_strb_sysctrl           ,
        TX_BFN_STRB_SYSCTRL_IN              => tx_bfn_strb_sysctrl           ,
        RX_BFN_STRB_CPRI_IN                 => rx_bfn_strb_cpri              ,

        SIG_SUS_FLAG_CPRIPHY_IN(0)          => ecpri_fail                    ,
        SIG_SUS_DLOFF_CPRIPHY_OUT           => sig_sus_dloff_cpriphy         ,

        DUMP_BFN_STRB_CPRIPHY_IN            => dump_bfn_strb_cpriphy         ,
        DUMP_DATA_CPRIPHY_IN                => dump_data_cpriphy             ,
        DUMP_DVLD_CPRIPHY_IN                => dump_dvld_cpriphy             ,
        TEST_DATA_CPRIPHY_OUT               => test_data_cpriphy             ,
        TEST_ENB_CPRIPHY_IN                 => test_denb_cpriphy             ,

        --CPRI_TOP
        SIG_SUS_FLAG_CPRI_IN                => sig_sus_flag_cpri             ,
        IS_MASTER_CPRI_IN                   => is_master_cpri                ,

        DUMP_BFN_STRB_CPRI_IN               => dump_bfn_strb_cpri            ,
        DUMP_DATA_CPRI_IN                   => dump_data_cpri                ,
        DUMP_DVLD_CPRI_IN                   => dump_dvld_cpri                ,
        TEST_DATA_CPRI_OUT                  => test_data_cpri                ,
        TEST_ENB_CPRI_IN                    => test_denb_cpri                ,
  		FPGA_PSB_AMP_48V_ONOFF              => FPGA_PSB_AMP_48V_ONOFF        ,
        --SBIF_TOP
        SIG_SUS_FLAG_SBIF_IN                => sig_sus_flag_sbif             ,
        SIG_SUS_DLOFF_SBIF_OUT              => sig_sus_dloff_sbif            ,

        DUMP_BFN_STRB_SBIF_IN               => dump_bfn_strb_sbif            ,
        DUMP_DATA_SBIF_IN                   => dump_data_sbif                ,
        DUMP_DVLD_SBIF_IN                   => dump_dvld_sbif                ,
        TEST_DATA_SBIF_OUT                  => test_data_sbif                ,
        TEST_ENB_SBIF_IN                    => test_enb_sbif                 ,

        --SBIFPHY_TOP
        SIG_SUS_FLAG_SBIFPHY_IN             => sig_sus_flag_sbifphy          ,
        SIG_SUS_DLOFF_SBIFPHY_OUT           => sig_sus_dloff_sbifphy         ,

        DUMP_BFN_STRB_SBIFPHY_IN            => dump_bfn_strb_sbifphy         ,
        DUMP_DATA_SBIFPHY_IN                => dump_data_sbifphy             ,
        DUMP_DVLD_SBIFPHY_IN                => dump_dvld_sbifphy             ,
        TEST_DATA_SBIFPHY_OUT               => test_data_sbifphy             ,
        TEST_ENB_SBIFPHY_IN                 => test_enb_sbifphy              ,

        -- BBCTRL-TOP
        SIG_SUS_FLAG_BBCTRL_IN              => sig_sus_flag_bbctrl           ,
        SIG_SUS_DLOFF_BBCTRL_OUT            => sig_sus_dloff_bbctrl          ,

        DUMP_BFN_STRB_BBCTRL_IN             => dump_bfn_strb_bbctrl          ,
        DUMP_DATA_BBCTRL_IN                 => dump_data_bbctrl              ,
        DUMP_DVLD_BBCTRL_IN                 => dump_dvld_bbctrl              ,
        TEST_DATA_BBCTRL_OUT                => test_data_bbctrl              ,
        TEST_ENB_BBCTRL_IN                  => test_enb_bbctrl               ,

        -- DSP-TOP
        SIG_SUS_FLAG_DSP_IN                 => sig_sus_flag_dsp              ,
        SIG_SUS_DLOFF_DSP_OUT               => sig_sus_dloff_dsp             ,

        DUMP_BFN_STRB_DSP_IN                => dump_bfn_strb_dsp             ,
        DUMP_DATA_DSP_IN                    => dump_data_dsp                 ,
        DUMP_DVLD_DSP_IN                    => dump_dvld_dsp                 ,
        TEST_DATA_DSP_OUT                   => test_data_dsp                 ,
        TEST_ENB_DSP_IN                     => test_denb_dsp                 ,

        DL_IQ_ISZERO_IN                     => dl_iq_iszero_dsp              ,
        DL_CLK_ISZERO_IN                    => dl_clk_iszero_dsp             ,

        -- DCIF_TOP
        SIG_SUS_FBFLAG_DCIF_IN              => (others => '0'), --  sig_sus_fbflag_dcif           ,
        SIG_SUS_ULFLAG_DCIF_IN              => (others => '0'),--sig_sus_ulflag_dcif           ,
        SIG_SUS_DLFLAG_DCIF_IN              => sig_sus_dlflag_dcif           ,

        DUMP_BFN_STRB_DCIF_IN               => dump_bfn_strb_dcif            ,
        DUMP_DATA_DCIF_IN                   => dump_data_dcif                ,
        DUMP_DVLD_DCIF_IN                   => dump_dvld_dcif                ,
        TEST_DATA_DCIF_OUT                  => test_data_dcif                ,
        TEST_ENB_DCIF_IN                    => test_denb_dcif                ,

        DL_BFN_STRB_DCIF_IN                 => dl_bfn_strb_dcif              ,
        DL_SSB_STRB_DCIF_IN                 => dl_ssb_strb_dcif              ,--: in  std_logic;
        DL_TDD_DCIF_IN                      => '1'                           ,--dl_tdd_dcif                   ,
        DL_BFN_STRB_1PPS_OUT                => dl_bfn_strb_1pps_misc         ,

        UL_BFN_STRB_1PPS_IN                 => frame_sync_cpu_top(0)         ,-- inner_rx_bfn_strobe_sysctrl   ,
        UL_TDD_1PPS_IN                      => inner_rx_tdd_sysctrl          ,
        UL_BFN_STRB_DCIF_OUT                => ul_bfn_strb_misc              ,
        UL_TDD_DCIF_OUT                     => ul_tdd_misc                   ,

        FB_BFN_STRB_DCIF_OUT                => fb_bfn_strb_misc              ,
        FB_SSB_STRB_DCIF_OUT                => fb_ssb_strb_misc              ,
        FB_TDD_DCIF_OUT                     => fb_tdd_misc                   ,

        -- SIG_SUS_TOP
        SIG_SUS_DLOFF_OTRX_OUT              => sig_sus_dloff_otrx            , --: out std_logic;
        EXT_SYSPLL_LOCK_IN                  => CLK_PLL_LD                    , --: in  std_logic;
        INT_SYSPLL_LOCK_IN                  => int_syspll_lock               , --: in  std_logic;
        VSS_RMT_RST_CPRI_IN                 => vss_rmt_rst_sysctrl           , --: in  std_logic;
        HWWDT_FLAG_IN                       => hwwdt_flag_sysctrl            , --: in  std_logic;
        SWWDT_FLAG_IN                       => sw_wdt_latch                  , --: in  std_logic;
        -- Feedback Switch Information
        FBSW_START_TRIG_OUT                 => fbsw_start_trig_misc          ,
        FBSW_CNT_245P76M_OUT                => fbsw_cnt_misc                 , --: out std_logic_vector(5 downto 0)                  ;
        FBSW_AUTO_MODE_DONE_OUT             => fbsw_auto_mode_done_misc      ,
        FBSW_PWR_MSR_UPT_OUT                => fbsw_pwr_msr_upt_misc         ,
        -- new port
        SSB_OFFSET                          => nr_ssb_offset_sysctrl(1 downto 0), -- : in  std_logic_vector(1 downto 0);
		SYNC_1PPS_10MS_IN                   => frame_sync_cpu_top(0)         , --: in  std_logic;
        SYNC_1PPS_SFN_IN                    => sfn_num_cpu_top(3 downto 0)   , --: in  std_logic_vector(3 downto 0);

        CPRI_CONN_OK                        => dl_bfn_nr_ok_bbctrl           , -- : in  std_logic                   ;
        SSB_EXIST_OUT                       => fbsw_ssb_ind                  , -- : out std_logic                   ;
        FBSW_SC_PATH_SEL_EN_OUT             => open                          , --: out std_logic                   ;
        FBSW_SC_PATH_SEL_OUT                => fbsw_sc_path_sel              ,
		PWR_MSR_FB_SYNC_OUT                 => pwr_msr_fb_sync               , --: out std_logic                   ;
        PWR_MSR_EN_OUT                      => pwr_msr_en                    , --: out std_logic                   ;

        --------------------------------
        -- Ports on Schemetics
        --------------------------------
        --------------------------------
        -- RF TX Switch Control
        --------------------------------

        RFIC_TX_EN_OUT                      => RFIC_TX_EN_OUT                  , --: out std_logic;
        RFIC_FB_EN_0_OUT                    => RFIC_FB_EN_0_OUT                , --: out std_logic;
        RFIC_FB_EN_1_OUT                    => RFIC_FB_EN_1_OUT                , --: out std_logic;
        RFIC_FB2_TX_SEL0_OUT                => RFIC_FB2_TX_SEL0_OUT            , --: out std_logic;
        RFIC_FB3_TX_SEL0_OUT                => RFIC_FB3_TX_SEL0_OUT            , --: out std_logic;
        RFIC_FB2_TX_SEL1_OUT                => RFIC_FB2_TX_SEL1_OUT            , --: out std_logic;
        RFIC_FB3_TX_SEL1_OUT                => RFIC_FB3_TX_SEL1_OUT            , --: out std_logic;

        RFIC_RX_EN_OUT                      => RFIC_RX_EN_OUT                  , --: out std_logic;
        CTRL_PATH1_OUT                      => CTRL_PATH1_OUT                  , --: out std_logic;
        CTRL_PATH2_OUT                      => CTRL_PATH2_OUT                  , --: out std_logic;
        ENA_PATH12_OUT                      => ENA_PATH12_OUT                  , --: out std_logic;
        CTRL_PATH3_OUT                      => CTRL_PATH3_OUT                  , --: out std_logic;
        CTRL_PATH4_OUT                      => CTRL_PATH4_OUT                  , --: out std_logic;
        ENA_PATH34_OUT                      => ENA_PATH34_OUT                  , --: out std_logic;

        TX_SW_0_OUT                         => TX_SW_0_OUT                     , --: out std_logic;
        TX_SW_1_OUT                         => TX_SW_1_OUT                     , --: out std_logic;
        TX_SW_2_OUT                         => TX_SW_2_OUT                     , --: out std_logic;
        TX_SW_3_OUT                         => TX_SW_3_OUT                     , --: out std_logic;
        RF_RX_SW_CTRL                       => RF_RX_SW_CTRL                   ,
--        RX_SW_OUT                           => RX_SW_OUT                       , --: out std_logic;
        TX_RF_LDO_ONOFF                     => TX_RF_LDO_ONOFF                          ,--: out std_logic;
        RX_RF_LDO_ONOFF                     => RX_RF_LDO_ONOFF                          ,--: out std_logic;
        
        --TX_B13_A_SW_OUT                     => TX_B13_A_SW_OUT               , --: out std_logic;
        --TX_B13_B_SW_OUT                     => TX_B13_B_SW_OUT               , --: out std_logic;
        --TX_B13_C_SW_OUT                     => TX_B13_C_SW_OUT               , --: out std_logic;
        --TX_B13_D_SW_OUT                     => TX_B13_D_SW_OUT               , --: out std_logic;

        ISPPAC_CTRL_OUT                     => ISPPAC_CTRL                   ,
        UDA_IN                              => UDA_IN                        , --: in  std_logic_vector(3 downto 0)
        
        B13_AMP_EN_OUT                      => B13_AMP_EN_OUT                , --: out std_logic_vector(TX_ANT_NUM-1 downto 0);

        OOK_B13_A_TXIN                      => OOK_B13_A_TXIN                , --: out std_logic;
        OOK_B13_A_RXOUT                     => OOK_B13_A_RXOUT               , --: in  std_logic;
        OOK_B13_A_DIR_IN                    => OOK_B13_A_DIR                 , --: in  std_logic;
        OOK_B13_A_DIRMD1_OUT                => OOK_B13_A_DIRMD1              , --: out std_logic;
        OOK_B13_A_DIRMD2_OUT                => OOK_B13_A_DIRMD2              , --: out std_logic;
        BIAS_T_B13_A_ONOFF_OUT              => BIAS_T_B13_A_ONOFF            , --: out std_logic;

        OOK_B13_C_TXIN                      => OOK_B13_C_TXIN                , --: out std_logic;
        OOK_B13_C_RXOUT                     => OOK_B13_C_RXOUT               , --: in  std_logic;
        OOK_B13_C_DIR_IN                    => OOK_B13_C_DIR                 , --: in  std_logic;
        OOK_B13_C_DIRMD1_OUT                => OOK_B13_C_DIRMD1              , --: out std_logic;
        OOK_B13_C_DIRMD2_OUT                => OOK_B13_C_DIRMD2              , --: out std_logic;
        BIAS_T_B13_C_ONOFF_OUT              => BIAS_T_B13_C_ONOFF            , --: out std_logic;

        RET_ONOFF_OUT                       => RET_ONOFF                     , --: out std_logic;

        LED_CTRL_SYSCTRL_IN                 => led_ctrl_sysctrl              ,
--        LED_RED_OUT                         => LED_RED_OUT                   ,
--        LED_GREEN_OUT                       => LED_GREEN_OUT                 ,

        LED_ANT_RED                         => LED_ANT_RED                              ,--: out std_logic;
        LED_ANT_BLUE                        => LED_ANT_BLUE                             ,--: out std_logic;
        LED_ANT_GREEN                       => LED_ANT_GREEN                            ,--: out std_logic;
        
        LED_FAN_RED                         => LED_FAN_RED                              ,--: out std_logic;
        LED_FAN_BLUE                        => LED_FAN_BLUE                             ,--: out std_logic;        
        LED_FAN_GREEN                       => LED_FAN_GREEN                            ,--: out std_logic;        
        
        LED_OPT_BLUE                        => LED_OPT_BLUE                             ,--: out std_logic;
        LED_OPT_RED                         => LED_OPT_RED                              ,--: out std_logic;
        LED_OPT_GREEN                       => LED_OPT_GREEN                            ,--: out std_logic;
        
        LED_SYS_RED                         => LED_SYS_RED                              ,--: out std_logic;        
        LED_SYS_BLUE                        => LED_SYS_BLUE                             ,--: out std_logic;
        LED_SYS_GREEN                       => LED_SYS_GREEN                            ,--: out std_logic;
        
        UDE_ETH_nRESET                      => UDE_ETH_nRESET                , --: out std_logic;
        EXT_EN_5p0V_OUT                     => EXT_EN_5p0V_OUT               , --: out std_logic;
        
        RET_UART_RXD_IN                     => RET_UART_RXD_IN               , --: in  std_logic;
        RET_nRE_OUT                         => RET_nRE                       , --: out std_logic;
        RET_DE_OUT                          => RET_DE                        , --: out std_logic;
        RET_UART_TXD_OUT                    => RET_UART_TXD_OUT              , --: out std_logic;
        
        UART0_MP_IN                         => s_UART_RET_txd                , --: in  std_logic;        
        UART0_MP_OUT                        => s_UART_RET_rxd                , --: out  std_logic;
        UART1_MP_IN                         => i_biast0_uart_txd             , --: in  std_logic;
        UART1_MP_OUT                        => i_biast0_uart_rxd             , --: out  std_logic;
        UART2_MP_IN                         => i_biast1_uart_txd             , --: in  std_logic;
        UART2_MP_OUT                        => i_biast1_uart_rxd             , --: out  std_logic;

        CLK_PLL_LOS_IN                      => '0'                           , --: in  std_logic;
        CLK_PLL_LD_IN                       => CLK_PLL_LD                    , --: in  std_logic;
        CLK_PLL_LD_RSVD_IN                  => '0'                           , --: in  std_logic ;
        CLK_PLL_RESET_OUT                   => open                          , --: out std_logic;

        UV_ALARM_IN                         => UV_ALARM_IN                   , --: in  std_logic;
        TRX_DC_NORMAL_IN                    => TRX_DC_NORMAL_IN              , --: in  std_logic;
        FPGA_PWR_STATUS_IN                  => FPGA_PWR_STATUS               , --: in  std_logic;
        PWR55_NORMAL_IN                     => PWR55_NORMAL_IN               , --: in  std_logic;

        PG_0P85V_MFPGA                      => PG_0P85V_MFPGA                ,
        PG_1P8V_MFPGA                       => PG_1P8V_MFPGA                 ,
        PG_0P85V_MFPGA_PSMGT                => PG_0P85V_MFPGA_PSMGT          ,
        PG_1P2V_MFPGA_PSPLL                 => PG_1P2V_MFPGA_PSPLL           ,
        PG_1P8V_MFPGA_MGT                   => PG_1P8V_MFPGA_MGT             ,
        PG_1P2V_DDR4                        => PG_1P2V_DDR4                  ,
        PG_3P3V_CLK                         => PG_3P3V_CLK                   ,
        PG_3P3V                             => PG_3P3V                       ,
        PG_0P9V_MFPGA_MGT                   => PG_0P9V_MFPGA_MGT             ,
        PG_1P2V_MFPGA_MGT                   => PG_1P2V_MFPGA_MGT             ,
        PG_1P0V_RFIC0_DIGITAL               => PG_1P0V_RFIC0_DIGITAL         ,
        PG_1P3V_RFIC0_ANALOG                => PG_1P3V_RFIC0_ANALOG          ,
        PG_1p8V_RFIC_VDD                    => PG_1p8V_RFIC_VDD                         ,--: in  std_logic;
        
        AMP_AMC_RST1_OUT                    => AMP_AMC_RST1_OUT              , --: out std_logic;
        AMP_AMC_RST2_OUT                    => AMP_AMC_RST2_OUT              , --: out std_logic;

--        RFIC_B13_TX_EN_OUT                  => RFIC_TX_EN                    , --: out std_logic_array2(RFIC_NUM-1 downto 0);
        RFIC_B13_RESETB_OUT                 => RFIC_RST_CTRL                 , --: out std_logic_vector(RFIC_NUM-1 downto 0);
        RFIC_TRI_ENB                        => RFIC_TRI_ENB                  , --: out std_logic_vector(RFIC_NUM-1 downto 0)         ;
        RFIC_B13_GP_INTERRUPT_IN            => RFIC_GP_INTERRUPT             , --: in  std_logic_vector(RFIC_NUM-1 downto 0);

        RFIC_GPIO_IN                        => RFIC_GPIO_IN                  , --: in  std_logic_array19(RFIC_NUM-1 downto 0);
        RFIC_GPIO_OUT                       => RFIC_GPIO_OUT                 , --: out std_logic_array19(RFIC_NUM-1 downto 0);

        RFIC_AB_EN_OUT                      => open                          , --: out std_logic_vector(2 downto 0); -- ZUFPGA : don't use / KUFPGA :       use
        RF_B13_AB_EN_OUT                    => open                          , --: out std_logic; -- ZUFPGA : don't use / KUFPGA :use
        RF_B13_CD_EN_OUT                    => open                          , --: out std_logic; -- ZUFPGA : don't use / KUFPGA :use

        -- RFIC DMA
        RFIC_SPI_BUF_RST                    => rfic_spi_buf_rst_misc         ,
        RFIC_SPI_BUF_CLK                    => rfic_spi_buf_clk_misc         ,
        RFIC_SPI_BUF_ADDR                   => rfic_spi_buf_addr_misc        ,
        RFIC_SPI_BUF_DIN                    => rfic_spi_buf_din_misc         ,
        RFIC_SPI_BUF_DOUT                   => rfic_spi_buf_dout_cpu         ,
        RFIC_SPI_BUF_EN                     => rfic_spi_buf_en_misc          ,
        RFIC_SPI_BUF_WE                     => rfic_spi_buf_we_misc          ,

        RFIC_SPI_IP_SS                      => rfic_spi_ip_ss_cpu            ,
        RFIC_SPI_IP_SCLK                    => rfic_spi_ip_sclk_cpu          ,
        RFIC_SPI_IP_MOSI                    => rfic_spi_ip_mosi_cpu          ,
        RFIC_SPI_IP_MISO                    => rfic_spi_ip_miso_misc         ,

        RFIC_SPI_RTL_SS(0)                  => O_SPI_SS_IO(0)                  ,
        RFIC_SPI_RTL_SCLK(0)                => O_SPI_SCK_IO(0)                 ,
        RFIC_SPI_RTL_MOSI(0)                => O_SPI_MOSI_IO(0)                ,
        RFIC_SPI_RTL_MISO(0)                => I_SPI_MISO_IO(0)                ,

		KUFPGA_SIG_SUSPENSION_OUT           => open                          , --: out std_logic_vector(1 downto 0)                  ; -- ZUFPGA : RESERVED  / KUFPGA : RESERVED
        KUFPGA_FUNCTION_FAIL_IN             => FPGA_FUNCTION_FAIL_IN         , --: in  std_logic;
        KUFPGA_RESET_OUT                    => DFPGA_RST                     , --: out std_logic                                     ;
        FUNCTION_FAIL_OUT                   => function_fail_misc            , --: out std_logic                                     ; -- ZUFPGA : use       / KUFPGA : don't use

        --------------------------------
        -- RX Attenuation
        --------------------------------
        RXATT_B13_AB_DI_OUT                 => RXATT_B13_AB_DI_OUT           , --: out std_logic;
        RXATT_B13_AB_CLK_OUT                => RXATT_B13_AB_CLK_OUT          , --: out std_logic;
        RXATT_B13_A_LE_OUT                  => RXATT_B13_A_LE_OUT            , --: out std_logic;
        RXATT_B13_B_LE_OUT                  => RXATT_B13_B_LE_OUT            , --: out std_logic;

        RXATT_B13_CD_DI_OUT                 => RXATT_B13_CD_DI_OUT           , --: out std_logic;
        RXATT_B13_CD_CLK_OUT                => RXATT_B13_CD_CLK_OUT          , --: out std_logic;
        RXATT_B13_C_LE_OUT                  => RXATT_B13_C_LE_OUT            , --: out std_logic;
        RXATT_B13_D_LE_OUT                  => RXATT_B13_D_LE_OUT            , --: out std_logic;

        TXATT_B13_AB_DI_OUT                 => TXATT_B13_AB_DI_OUT           , --: out std_logic;
        TXATT_B13_AB_CLK_OUT                => TXATT_B13_AB_CLK_OUT          , --: out std_logic;
        TXATT_B13_A_LE_OUT                  => TXATT_B13_A_LE_OUT            , --: out std_logic;
        TXATT_B13_B_LE_OUT                  => TXATT_B13_B_LE_OUT            , --: out std_logic;

        TXATT_B13_CD_DI_OUT                 => TXATT_B13_CD_DI_OUT           , --: out std_logic;
        TXATT_B13_CD_CLK_OUT                => TXATT_B13_CD_CLK_OUT          , --: out std_logic;
        TXATT_B13_C_LE_OUT                  => TXATT_B13_C_LE_OUT            , --: out std_logic;
        TXATT_B13_D_LE_OUT                  => TXATT_B13_D_LE_OUT            , --: out std_logic;
        --------------------------------
    -- XADC monitoring
    --------------------------------
        RET_MON_N_IN                        => RET_MON_N_IN                  , --: in  std_logic; -- ZUFPGA : use/ KUFPGA : don't use
        RET_MON_P_IN                        => RET_MON_P_IN                  , --: in  std_logic; -- ZUFPGA : use/ KUFPGA : don't use

        RET_CURRENT_MON_N_IN                => RET_CURRENT_MON_N_IN          , --: in  std_logic; -- ZUFPGA : use/ KUFPGA : don't use
        RET_CURRENT_MON_P_IN                => RET_CURRENT_MON_P_IN          , --: in  std_logic; -- ZUFPGA : use/ KUFPGA : don't use

        B13_LNA_A_CURRENT_SENSOR_N_IN       => '0'                           , --: in  std_logic;
        B13_LNA_A_CURRENT_SENSOR_P_IN       => '0'                           , --: in  std_logic;
        B13_LNA_B_CURRENT_SENSOR_N_IN       => '0'                           , --: in  std_logic;
        B13_LNA_B_CURRENT_SENSOR_P_IN       => '0'                           , --: in  std_logic;
        B13_LNA_C_CURRENT_SENSOR_N_IN       => '0'                           , --: in  std_logic;
        B13_LNA_C_CURRENT_SENSOR_P_IN       => '0'                           , --: in  std_logic;
        B13_LNA_D_CURRENT_SENSOR_N_IN       => '0'                           , --: in  std_logic;
        B13_LNA_D_CURRENT_SENSOR_P_IN       => '0'                           , --: in  std_logic;
        E_MFPGA_PSU_I2C_SW_RST              => E_MFPGA_PSU_I2C_SW_RST          --: out std_logic
    );

    U_CPUIF_TOP : CPUIF_TOP
    port map(
        RST_CPUIF                           => rst_cpuif                     ,
        CLK_CPUIF                           => clk_cpuif                     ,

        ADDR_FPGA_IN                        => addr_fpga                     ,
        WDATA_FPGA_IN                       => wdata_fpga                    ,
        RDATA_FPGA_OUT                      => rdata_fpga                    ,
        CS_FPGA_IN                          => cs_fpga                       ,
        WREN_FPGA_IN                        => wren_fpga                     ,
        RDEN_FPGA_IN                        => rden_fpga                     ,

        HW_WATCHDOG_CLR_OUT                 => hw_watchdog_clr_cpuif         ,

        ADDR_SYSCTRL_OUT                    => addr_cpuif_sysctrl            ,
        WDATA_SYSCTRL_OUT                   => wdata_cpuif_sysctrl           ,
        RDATA_SYSCTRL_IN                    => rdata_cpuif_sysctrl           ,
        WREN_SYSCTRL_OUT                    => wren_cpuif_sysctrl            ,
        RDEN_SYSCTRL_OUT                    => rden_cpuif_sysctrl            ,
        RDVAL_SYSCTRL_IN                    => rdval_cpuif_sysctrl           ,

        --ECPRIPHY
        ADDR_CPRIPHY_OUT                    => addr_cpuif_ecpriphy           ,
        WDATA_CPRIPHY_OUT                   => wdata_cpuif_ecpriphy          ,
        RDATA_CPRIPHY_IN                    => rdata_cpuif_ecpriphy          ,
        WREN_CPRIPHY_OUT                    => wren_cpuif_ecpriphy           ,
        RDEN_CPRIPHY_OUT                    => rden_cpuif_ecpriphy           ,
        RDVAL_CPRIPHY_IN                    => rdval_cpuif_ecpriphy          ,

        --ORAN
	    ADDR_CPRI_OUT                       => addr_cpuif_cpri               ,
        WDATA_CPRI_OUT                      => wdata_cpuif_cpri              ,
        RDATA_CPRI_IN                       => rdata_cpuif_cpri              ,
        WREN_CPRI_OUT                       => wren_cpuif_cpri               ,
        RDEN_CPRI_OUT                       => rden_cpuif_cpri               ,
        RDVAL_CPRI_IN                       => rdval_cpuif_cpri              ,
        --LPHY
        ADDR_LPHY_TOP_OUT                   => addr_cpuif_lphy_top( ADDR_WIDTH +4 -1 downto 0)           ,
        WDATA_LPHY_TOP_OUT                  => wdata_cpuif_lphy_top          ,
        RDATA_LPHY_TOP_IN                   => rdata_cpuif_lphy_top          ,
        WREN_LPHY_TOP_OUT                   => wren_cpuif_lphy_top           ,
        RDEN_LPHY_TOP_OUT                   => rden_cpuif_lphy_top           ,
        RDVAL_LPHY_TOP_IN                   => rdval_cpuif_lphy_top          ,
        --BBCTRL
        ADDR_BBCTRL_OUT                     => addr_cpuif_bbctrl             ,
        WDATA_BBCTRL_OUT                    => wdata_cpuif_bbctrl            ,
        RDATA_BBCTRL_IN                     => rdata_cpuif_bbctrl            ,
        WREN_BBCTRL_OUT                     => wren_cpuif_bbctrl             ,
        RDEN_BBCTRL_OUT                     => rden_cpuif_bbctrl             ,
        RDVAL_BBCTRL_IN                     => rdval_cpuif_bbctrl            ,

        ADDR_DSP_OUT                        => addr_cpuif_dsp                ,
        WDATA_DSP_OUT                       => wdata_cpuif_dsp               ,
        RDATA_DSP_IN                        => rdata_cpuif_dsp               ,
        WREN_DSP_OUT                        => wren_cpuif_dsp                ,
        RDEN_DSP_OUT                        => rden_cpuif_dsp                ,
        RDVAL_DSP_IN                        => rdval_cpuif_dsp               ,

        ADDR_DCIF_OUT                       => addr_cpuif_dcif               ,
        WDATA_DCIF_OUT                      => wdata_cpuif_dcif              ,
        RDATA_DCIF_IN                       => rdata_cpuif_dcif              ,
        WREN_DCIF_OUT                       => wren_cpuif_dcif               ,
        RDEN_DCIF_OUT                       => rden_cpuif_dcif               ,
        RDVAL_DCIF_IN                       => rdval_cpuif_dcif              ,

        ADDR_MISC_OUT                       => addr_cpuif_misc               ,
        WDATA_MISC_OUT                      => wdata_cpuif_misc              ,
        RDATA_MISC_IN                       => rdata_cpuif_misc              ,
        WREN_MISC_OUT                       => wren_cpuif_misc               ,
        RDEN_MISC_OUT                       => rden_cpuif_misc               ,
        RDVAL_MISC_IN                       => rdval_cpuif_misc              ,

        ADDR_SBIF_OUT                       => addr_cpuif_sbif               ,
        WDATA_SBIF_OUT                      => wdata_cpuif_sbif              ,
        RDATA_SBIF_IN                       => rdata_cpuif_sbif              ,
        WREN_SBIF_OUT                       => wren_cpuif_sbif               ,
        RDEN_SBIF_OUT                       => rden_cpuif_sbif               ,
        RDVAL_SBIF_IN                       => rdval_cpuif_sbif              ,

        ADDR_PIM_SBIF_OUT                   => addr_cpuif_pim_sbif           , --: out std_logic_vector(15 downto 0);
        WDATA_PIM_SBIF_OUT                  => wdata_cpuif_pim_sbif          , --: out std_logic_vector(31 downto 0);
        RDATA_PIM_SBIF_IN                   => rdata_cpuif_pim_sbif          , --: in  std_logic_vector(31 downto 0);
        WREN_PIM_SBIF_OUT                   => wren_cpuif_pim_sbif           , --: out std_logic;
        RDEN_PIM_SBIF_OUT                   => rden_cpuif_pim_sbif           , --: out std_logic;
        RDVAL_PIM_SBIF_IN                   => rdval_cpuif_pim_sbif          , --: in  std_logic;

        ADDR_SBIFPHY_OUT                    => addr_cpuif_sbifphy            ,
        WDATA_SBIFPHY_OUT                   => wdata_cpuif_sbifphy           ,
        RDATA_SBIFPHY_IN                    => rdata_cpuif_sbifphy           ,
        WREN_SBIFPHY_OUT                    => wren_cpuif_sbifphy            ,
        RDEN_SBIFPHY_OUT                    => rden_cpuif_sbifphy            ,
        RDVAL_SBIFPHY_IN                    => rdval_cpuif_sbifphy           ,

        ADDR_PIM_SBIFPHY_OUT                => addr_cpuif_pim_sbifphy        , --: out std_logic_vector(15 downto 0);
        WDATA_PIM_SBIFPHY_OUT               => wdata_cpuif_pim_sbifphy       , --: out std_logic_vector(31 downto 0);
        RDATA_PIM_SBIFPHY_IN                => rdata_cpuif_pim_sbifphy       , --: in  std_logic_vector(31 downto 0);
        WREN_PIM_SBIFPHY_OUT                => wren_cpuif_pim_sbifphy        , --: out std_logic;
        RDEN_PIM_SBIFPHY_OUT                => rden_cpuif_pim_sbifphy        , --: out std_logic;
        RDVAL_PIM_SBIFPHY_IN                => rdval_cpuif_pim_sbifphy       , --: in  std_logic;

        ADDR_ANNEX_OUT                      => addr_cpuif_annex              ,
        WDATA_ANNEX_OUT                     => wdata_cpuif_annex             ,
        RDATA_ANNEX_IN                      => rdata_cpuif_annex             ,
        WREN_ANNEX_OUT                      => wren_cpuif_annex              ,
        RDEN_ANNEX_OUT                      => rden_cpuif_annex              ,
        RDVAL_ANNEX_IN                      => rdval_cpuif_annex             ,

        ADDR_DPD_OUT                        => addr_cpuif_dpd                ,
        WDATA_DPD_OUT                       => wdata_cpuif_dpd               ,
        RDATA_DPD_IN                        => rdata_cpuif_dpd               ,
        WREN_DPD_OUT                        => wren_cpuif_dpd                ,
        RDEN_DPD_OUT                        => rden_cpuif_dpd                ,
        RDVAL_DPD_IN                        => rdval_cpuif_dpd               ,

        DBG_SIG_OUT                         => dbg_sig_cpuif
    );
	
end arc_RU_FPGA_TOP;
