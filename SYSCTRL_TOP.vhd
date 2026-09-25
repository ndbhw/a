----------------------------------------------------------------------------------
-- Company: SEC                                                                     
-- Engineer:                                                                      
--                                                                                
-- Create Date: 2016-09-26 AM 9:52:19                                    
-- Design Name: jinoo.bae                                                                  
-- Module Name: SYSCTRL_TOP - Behavioral                                        
-- Project Name: FD-MIMO                                                                
-- Target Devices: ZYNQ035_2LI                                                               
-- Tool versions: vivado20162                                                                 
-- Description:                                                                   
--                                                                                
-- Dependencies:                                                                  
--                                                                                
-- Revision:                                                                      
-- Revision 0.01 - File Created                                                   
-- Additional Comments:                                                           
--                                                                                
----------------------------------------------------------------------------------
library ieee;                                                                     
use ieee.std_logic_1164.all;                                    
use ieee.std_logic_arith.all;                                   
use ieee.std_logic_unsigned.all;
use work.ARRAY_TYPE.all;
use work.RU_FPGA_FNC.all;
use work.RU_FPGA_CONFIG.all;                                                                                                                                                                                               
                               
library UNISIM;
use UNISIM.VComponents.all;                               
                                                                  
ENTITY SYSCTRL_TOP IS
PORT (                 
----------------------------------------------------------------------
----  External System PLL   
----------------------------------------------------------------------
    FPGA_ID                                 : in  std_logic_vector(3 downto 0);
    FPGA_PCB_VER                        : in  std_logic_vector(2 downto 0);    

----------------------------------------------------------------------
----  PSU_VER
----------------------------------------------------------------------    
    PSU_VER                                 : in  std_logic;

----------------------------------------------------------------------
--BIAST enable
----------------------------------------------------------------------
    BIAST_3P3V_EN                           : out    std_logic;

----------------------------------------------------------------------
    TCXO_OUT_PLL                            : in  std_logic;
----------------------------------------------------------------------
----  External System PLL   
----------------------------------------------------------------------
    EXT_SYSPLL_LOCK_IN                      : in  std_logic_vector(2 downto 0);           
    EXT_SYSPLL_LOS_IN                       : in  std_logic;           
    EXT_SYSCLK_IN                           : in  std_logic;     

    PTP_REF_CLK                             : in  std_logic; -- PTP Reference clock
    CLK_PTP                                 : out std_logic; -- 156.25 MHz
      
    FPGA_SYSCLK_FB_IN                       : in  std_logic;
    FPGA_SYSCLK_FB_OUT                      : out std_logic;
    MGT_REFCLK0_IN                          : in  std_logic;          -- ORAN CLK
    MGT_REFCLK1_IN                          : in  std_logic;          -- CPRI CB_DB
    MGT_REFCLK2_IN                          : in  std_logic;          -- SBIF
    MGT_REFCLK3_IN                          : in  std_logic;          -- JESD
    MGT_REFCLK4_IN                          : in  std_logic;          -- AURORORA
----------------------------------------------------------------------
--  CPU_TOP    
----------------------------------------------------------------------
    CLK_CPUIF                               : in  std_logic;
    RST_CPUIF                               : in  std_logic;
    
----------------------------------------------------------------------
--  CPUIF_TOP 
----------------------------------------------------------------------
    ADDR_CPUIF_SYSCTRL_IN                   : in  std_logic_vector(15 downto 0);  
    WDATA_CPUIF_SYSCTRL_IN                  : in  std_logic_vector(31 downto 0);  
    RDATA_CPUIF_SYSCTRL_OUT                 : out std_logic_vector(31 downto 0);  
    WREN_CPUIF_SYSCTRL_IN                   : in  std_logic;                      
    RDEN_CPUIF_SYSCTRL_IN                   : in  std_logic;                      
    RDVAL_CPUIF_SYSCTRL_OUT                 : out std_logic;                      

------------------------------------------------------------------------                  
--  SBIFPHY_TOP  --## DSP_FPGA_ONLY_PORT                                                                      
------------------------------------------------------------------------                  
--    RST_SBIFPHY                             : out std_logic_vector(SBIF_NUM - 1 downto 0);   
    REFCLK_SSERDES_OUT                      : out std_logic_vector(SSREF_NUM - 1 downto 0);    

--------------------------------------------------------------------------    
--  SBIF_TOP  --## DSP_FPGA_ONLY_PORT
--------------------------------------------------------------------------
--    RST_SBIF                                : out std_logic_vector(SBIF_NUM - 1 downto 0);   
    CLK_SYS                                 : out std_logic;           -- 30.72  MHz                 
    CLK_SYSX2                               : out std_logic;           -- 61.44  MHz
    CLK_SYSX3                               : out std_logic;           -- 92.16  MHz
    CLK_SYSX4                               : out std_logic;           -- 122.88 MHz
    CLK_SYSX5                               : out std_logic;           -- 153.6  MHz
    CLK_SYSX6                               : out std_logic;           -- 184.32 MHz
    CLK_SYSX8                               : out std_logic;           -- 245.76 MHz
    CLK_SYSX10                              : out std_logic;           -- 307.2  MHz
    CLK_SYSX12                              : out std_logic;           -- 368.64 MHz
    CLK_SYSX16                              : out std_logic;           -- 491.52 MHz
    CLK_SYSX20                              : out std_logic;           -- 614.4  MHz
--------------------------------------------------------------------
    CLK_TCXO_X1                             : out std_logic;
    CLK_TCXO_X4                             : out std_logic;
    CLK_TCXO_X8                             : out std_logic;    

    CLK_SBIF                                : out std_logic_vector(PIM_SBIF_NUM  - 1 downto 0);
    CLK_SBIFXH                              : out std_logic_vector(PIM_SBIF_NUM  - 1 downto 0);
    CLK_SBIFX2                              : out std_logic_vector(PIM_SBIF_NUM  - 1 downto 0);
    
    REFCLK_CSERDES_OUT                      : out std_logic_vector(CSREF_NUM - 1 downto 0);
    REFCLK_OSERDES_OUT                      : out std_logic_vector(EPHY_NUM  - 1 downto 0);
    REFCLK_SEL_IN                           : in  std_logic_vector(3 downto 0);
    
    --------------------------------------------------------------------------
    --  ECPRI_MMCM --CTRL FPGA
    --------------------------------------------------------------------------
 
    SYSTEM_TIMER_MMCM_RST                   : out   std_logic;
    SYSTEM_TIMER_MMCM_LOCK                  : in    std_logic;
 
    RST_IQCOMP                              : out std_logic_vector(IQCOMP_NUM - 1 downto 0);    
    RST_ETHMUX                              : out std_logic;
    CLK_MII                                 : out std_logic;               -- 25  MHz
    CLK_MIIX2                               : out std_logic;               -- 50  MHz
    CLK_MIIX4                               : out std_logic;               -- 100 MHz
    CLK_MIIX8                               : out std_logic;               -- 200 MHz
    RX_BFN_STRB_IN                          : in  std_logic_vector(CPRI_NUM - 1 downto 0);    -- strobe delay 
    RX_BFN_NR_IN                            : in  std_logic_array12(CPRI_NUM - 1 downto 0);   -- strobe delay 
    TX_BFN_STRB_OUT                         : out std_logic_vector(CPRI_NUM - 1 downto 0);    -- strobe delay 
    TX_BFN_NR_OUT                           : out std_logic_array12(CPRI_NUM - 1 downto 0);   -- strobe delay 
    RU_ID_OUT                               : out std_logic_vector(3 downto 0);      
    RU_FF_OUT                               : out std_logic;
    VSS_RMT_RST_CPRI_IN                     : in  std_logic_vector(CPRI_NUM - 1 downto 0);
    IS_MASTER_CPRI_IN                       : in  std_logic_vector(CPRI_NUM - 1 downto 0);     -- no uesd in verizon 
    LINE_RCF_START_IN                       : in  std_logic_vector(CPRI_NUM - 1 downto 0);     -- no uesd in verizon 
    LINE_RCF_RATE_IN                        : in  std_logic_array8(CPRI_NUM - 1 downto 0);     -- no uesd in verizon 
    LINE_RCF_CLKTYPE_IN                     : in  std_logic_array8(CPRI_NUM - 1 downto 0);     -- no uesd in verizon 
    LINE_RCF_WIDTH_IN                       : in  std_logic_array8(CPRI_NUM - 1 downto 0);     -- no uesd in verizon  
   
----------------------------------------------------------------------    
--  SBIF_TOP  --## CTRL_FPGA_ONLY_PORT BBCTRL_TOP
----------------------------------------------------------------------
    RX_BFN_STRB_OUT                         : out std_logic_vector(CPRI_NUM - 1 downto 0);   -- strobe delay  -- free running  
    RX_BFN_NR_OUT                           : out std_logic_array12(CPRI_NUM - 1 downto 0); 
    RX_TDD_OUT                              : out std_logic_vector(CPRI_NUM - 1 downto 0);                                     -- don't used in verizon 
    TX_TDD_IN                               : in  std_logic_vector(CPRI_NUM - 1 downto 0);  -- from analog input tdd           -- don't used in verizon 
    TX_BFN_STRB_IN                          : in  std_logic_vector(CPRI_NUM - 1 downto 0);  -- from analog input strobe 

    REFCLK_ASERDES_OUT                      : out std_logic_vector(ASREF_NUM - 1 downto 0);  

----------------------------------------------------------------------    
--  BBCTRL_TOP  
---------------------------------------------------------------------- 
    INNER_DL_TDD_AND_CTRL_OUT               : out std_logic;          -- don't used in verizon 
    INNER_DL_TDD_OR_CTRL_OUT                : out std_logic;          -- don't used in verizon 

----------------------------------------------------------------------    
--  DSP_TOP  --## DSP_FPGA_ONLY_PORT
---------------------------------------------------------------------- 
    INT_SYSPLL_LOCK_OUT                     : out std_logic;
    RST_BBCTRL                              : out std_logic;
--    RST_DSP                                 : out std_logic; 
    RST_DDUC                                : out std_logic;
    RST_CFR                                 : out std_logic;
    RST_DPD                                 : out std_logic;

----------------------------------------------------------------------    
--  DCIP_TOP --## DSP_FPGA_ONLY_PORT
----------------------------------------------------------------------     
    RST_DCIF                                : out std_logic;
    REFCLK_JSERDES_OUT                      : out std_logic_vector(JSREF_NUM - 1 downto 0);  

----------------------------------------------------------------------    
-- RX_TDD relation ## DSP FPGA 
---------------------------------------------------------------------
    DL_1PPS_BFN_STROBE_IN                   : in  std_logic;                                  --from JESD OUT STROBE(equip tdd same)
    INNER_RX_TDD_OUT                        : out std_logic;                                  --to JESD RX TDD   -- don't used in verizon 
    INNER_RX_BFN_STROBE_OUT                 : out std_logic;                                  --to JESD RX STROBE 
    DFPGA_TDD                               : out std_logic;                                 -- don't used in verizon 


----------------------------------------------------------------------    
--  MISC_TOP 
----------------------------------------------------------------------
-- CTRL_FPGA    
    WATCHDOG_CLR                            : in  std_logic;
    HWWDT_FLAG_OUT                          : out std_logic;   
    LED_CTRL_OUT                            : out std_logic_array4(LED_NUM - 1 downto 0);
    FUNC_FAIL_TRIG_IN                       : in  std_logic_vector(1 downto 0);
    VSS_RMT_RST_OUT                         : out std_logic;
    
------------------------------------------------------------------------                  
--  PIM_reset
------------------------------------------------------------------------                  
    RST_PIM                                 : out std_logic; 
    RST_PIM_SBIF                            : out std_logic; 
    RST_PIM_SBIF_PHY                        : out std_logic; 

------------------------------------------------------------------------
-- NR SSB Parameter
------------------------------------------------------------------------
    NR_SSB_PERIOD                           : out std_logic_vector(4 downto 0);
    NR_SSB_OFFSET                           : out std_logic_vector(3 downto 0);
    
    SECTOR_MODE                             : out std_logic_vector(1 downto 0);
    eMTC_SEL                                : out std_logic_vector(1 downto 0); 


-- DSP_FPGA
    TDD_CTRL_OUT                            : out std_logic_vector(31 downto 0);             -- don't used in verizon 
    OOK_CLK                                 : out std_logic;           -- 8.704
    RST_MISC                                : out std_logic;
    CLK_MISC0                               : out std_logic;           -- user defind clock ??  25  MHz
    CLK_MISC1                               : out std_logic;           -- user defind clock ?? 50 MHz
    CLK_MISC2                               : out std_logic;           -- user defind clock ?? 100 MHz
    CLK_MISC3                               : out std_logic;           -- user defind clock ??  200 MHz

	SYSCTRL_ORAN_FRAMER_RST                 : out std_logic_vector( DL_NUM_CC    -1 downto 0 )  ; 
    SYSCTRL_ORAN_DEFRAMER_RST               : out std_logic_vector( UL_NUM_CC    -1 downto 0 )  ; 
    SYSCTRL_LPHY_TOP_RST                    : out std_logic_vector( DL_NUM_CC    -1 downto 0 )  ; 
	SYSCTRL_DLFE_RST                        : out std_logic_vector( DL_NUM_CC    -1 downto 0 )  ; 
    SYSCTRL_ULFE_RST                        : out std_logic_vector( UL_NUM_CC    -1 downto 0 )  ; 
    SYSCTRL_RAFE_RST                        : out std_logic_vector( UL_NUM_CC    -1 downto 0 )  ; 
    SYSCTRL_AURORA_RST                      : out std_logic;

	DL_CC0_SYNC_ADVANCE                     : out std_logic_vector(21 downto 0);
    DL_CC1_SYNC_ADVANCE                     : out std_logic_vector(21 downto 0);
    UL_CC0_SYNC_RETARD                      : out std_logic_vector(21 downto 0);
    UL_CC1_SYNC_RETARD                      : out std_logic_vector(21 downto 0);
    N_TA_OFFSET_CC0                         : out std_logic_vector(15 downto 0);
    N_TA_OFFSET_CC1                         : out std_logic_vector(15 downto 0);
    TP_CON_SEL                              : out std_logic_vector(7 downto 0);

    FRAME_SYNC_C2C                          : out std_logic;                    -- active high(10ms -PROC_DLY @ 245.76 MHz)@SFN_NUM#0
    SFN_NUM_C2C                             : out std_logic_vector(11 downto 0)
);                                                                                                                          
END SYSCTRL_TOP;                                                                          
                                                                                         
ARCHITECTURE SYSCTRL_TOP_ARC of SYSCTRL_TOP IS                                             

------------------------------------------------------------------------------
--  Output     Output      Phase    Duty Cycle   Pk-to-Pk     Phase
--   Clock     Freq (MHz)  (degrees)    (%)     Jitter (ps)  Error (ps)
------------------------------------------------------------------------------

--
------------------------------------------------------------------------------
-- Input Clock   Freq (MHz)    Input Jitter (UI)
------------------------------------------------------------------------------
-- __primary__________122.88____________0.010

component DATA_PLL 
port (
  -- Clock in ports
    CLK_IN1                                 : in  std_logic;
   -- CLKFB_IN                                : in  std_logic;
  -- Clock out ports
    CLK_OUT1                                : out std_logic;
    CLK_OUT2                                : out std_logic;
    --CLK_OUT3                                : out std_logic;
--    CLK_OUT4                                : out std_logic;
--    CLK_OUT5                                : out std_logic;
--    CLK_OUT6                                : out std_logic;  -- 61.44MHz
  --  CLKFB_OUT                               : out std_logic;
  -- Status and control signals
    RESET                                   : in  std_logic;
    LOCKED                                  : out std_logic
 );
end component;

component CPU_MII_PLL 
port (
  -- Clock in ports
    CLK_IN1                                 : in  std_logic;
  -- Clock out ports                        
    CLK_OUT1                                : out std_logic;
    CLK_OUT2                                : out std_logic;
  -- Status and control signals
    RESET                                   : in  std_logic;
    LOCKED                                  : out std_logic
 );
end component;

component CLK_OOK is
port
 (-- Clock in ports
  CLK_IN1                                   : in     std_logic;
  -- Clock out ports
  CLK_OUT1                                  : out    std_logic;
  -- Status and control signals
  RESET                                     : in     std_logic;
  LOCKED                                    : out    std_logic
 );
end component;

component RST_SYNC
generic (
    DLY_NUM        : natural := 4;    -- Number of delay.
    MAX_FANOUT_NUM : integer := 200   -- Number of maximum fanout
);
port (
    RST_IN  : in  std_logic;          -- Active high asynchronous reset
    CLK     : in  std_logic;          -- clock to be sync'ed to
    RST_OUT : out std_logic           -- "Synchronised" reset signal
);         
end component;

component GLBFS 
port (  
    RESET                                   : in  std_logic;
    PLL_LOCK                                : in  std_logic; -- sys_pll lock
    CLK                                     : in  std_logic; -- sys_hclk,122.88MHz
    BFN_STRB                                : in  std_logic; 
    BFN_NR                                  : in  std_logic_vector(11 downto 0); 

    BFN_FAIL                                : out std_logic;
    BFN_NR_FAIL                             : out std_logic;
                                            
    T80MS                                   : out std_logic; -- active high
    T10MS                                   : out std_logic; -- active high
    BFN_STRB_OUT                            : out std_logic; -- active high
    BFN_NR_OUT                              : out std_logic_vector(11 downto 0)
    );
end component;

component TDD_STRB_CNTDLY 
port(
    RST                                 : in  std_logic; -- Active high reset
    CLK                                 : in  std_logic; -- Clock
                                        
    BLK_BYPASS_IN                       : in  std_logic; -- '0' normal mode, '1' bypass mode
    DLYCNT_IN                           : in  std_logic_vector(11 downto 0); -- Delay Count value, Resolution : 1/(clock frequency)
                                        
    BFN_STROBE_IN                       : in  std_logic;
    TDD_STROBE_IN                       : in  std_logic;
                                        
    BFNSTRB_DLY_OUT                     : out std_logic;
    TDDSTRB_DLY_OUT                     : out std_logic
    );
end component;

component WATCHDOG is
port(
    RESET                               : in  std_logic;                        -- Synchronous Reset        
    CLK                                 : in  std_logic;                        -- 100MHz Clock
                                        
    WATCHDOG_EN                         : in  std_logic;                        -- Async. Watchdog Enable
    WATCHDOG_CLR                        : in  std_logic;                        -- Async. Watchdog Clear
    WDT_TIMER_SEC                       : in  std_logic_vector(15 downto 0);    -- Watchdog timer (unit : second)
    CPU_FAIL                            : out std_logic
);
end component;

component SYNC_C2C is
    port(
        RESET                               : in  std_logic;
        SYSCLK                              : in  std_logic;                     -- 245.76MHz
        SFN_SCALE                           : in  std_logic_vector(3 downto 0);
        FRAME_SYNC                          : in  std_logic;                    -- active high, 1 pulse @3.84 MHz
        SFN_NUM                             : in  std_logic_vector(11 downto 0); 
        SFN_NUM_C2C                         : out std_logic_vector(11 downto 0);
        TICK_10MS                           : out std_logic;                     -- active high(10ms -PROC_DLY @ 245.76 MHz)@SFN_NUM#0
        PROC_DLY                            : out std_logic_vector(31 downto 0);

        SYNC_ERR_CNT_CLR                    : in  std_logic;
        SYNC_ERR                            : out std_logic;
        SYNC_ERR_CNT                        : out std_logic_vector(15 downto 0)
    );
end component;

component PTP_MMCM
    port (
        -- Clock in ports
        CLK_IN1 : in std_logic;
        -- Clock out ports
        CLK_OUT1 : out std_logic;
        CLK_OUT2 : out std_logic;
        -- Status and control signals
        RESET  : in  std_logic;
        LOCKED : out std_logic
    );
end component;
      
component CPUIF_SYSCTRL
generic(
        LED_NUM                         : natural:= 4;
        CPRI_NUM                        : natural:= 6;
        IQCOMP_NUM                      : natural:= 6;
        SBIF_NUM                        : natural:= 6;
        TX_ANT_NUM                      : natural:= 8;
        CSREF_NUM                       : natural:= 6;
        JSREF_NUM                       : natural:= 6;
        SSREF_NUM                       : natural:= 6;
        C_SYSCTRL_IMG_DATE              : STD_LOGIC_VECTOR(31 DOWNTO 0):= X"2021_0604"; 
        C_SYSCTRL_IMG_VER               : STD_LOGIC_VECTOR(31 DOWNTO 0):= X"0000_0001"; 
        C_SYSCTRL_SYSTEM_INFO0          : STD_LOGIC_VECTOR(31 DOWNTO 0):= X"0000_0002";     -- air_tech[3:0]
        C_SYSCTRL_SYSTEM_INFO1          : STD_LOGIC_VECTOR(31 DOWNTO 0):= X"0000_0000";     -- freq_band[7:0]
        C_SYSCTRL_SYSTEM_INFO2          : STD_LOGIC_VECTOR(31 DOWNTO 0):= X"0000_0000";     -- freq_band[7:0]
        C_SYSCTRL_SYSTEM_INFO3          : STD_LOGIC_VECTOR(31 DOWNTO 0):= X"0232_3206";     -- fb_path_num, rx_ant_num, tx_ant_num,cpri_num
        C_SYSCTRL_PBA_INFO              : STD_LOGIC_VECTOR(31 DOWNTO 0):= X"0000_0000"; 
        C_SYSCTRL_DEV_INFO              : STD_LOGIC_VECTOR(31 DOWNTO 0):= X"0000_0000";
        C_SYSCTRL_MODULE_INFO           : STD_LOGIC_VECTOR(31 DOWNTO 0):= X"0000_0001";     
        C_SYSCTRL_MODULE_DATE           : STD_LOGIC_VECTOR(31 DOWNTO 0):= X"2016_1010"
    );                                                                 
port(
    FPGA_ID                                 : in  std_logic_vector(3 downto 0);
    FPGA_PCB_VER                        : in  std_logic_vector(2 downto 0);    

    PSU_VER                                 : in  std_logic;
    
    BIAST_3P3V_EN                           : out std_logic;

-- COMMON_FPGA
    CLK_CPUIF                               : in  std_logic;
    RST_CPUIF                               : in  std_logic;

    ADDR_CPUIF_SYSCTRL                      : in  std_logic_vector(15 downto 0);  
    WDATA_CPUIF_SYSCTRL                     : in  std_logic_vector(31 downto 0);  
    RDATA_CPUIF_SYSCTRL                     : out std_logic_vector(31 downto 0);  
    WREN_CPUIF_SYSCTRL                      : in  std_logic;                      
    RDEN_CPUIF_SYSCTRL                      : in  std_logic;                      
    RDVAL_CPUIF_SYSCTRL                     : out std_logic;                      

-- COMMON_FPGA
    SYSCTRL_IPLL_RST                        : out std_logic_vector(2 downto 0);   
    
-- CTRL_FPGA 
    SYSCTRL_IQCOMP_RST                      : out std_logic_vector(IQCOMP_NUM - 1 downto 0);
    SYSCTRL_ETHMUX_RST                      : out std_logic;
    SYSCTRL_SBIF_RST                        : out std_logic_vector(SBIF_NUM - 1 downto 0);
    SYSCTRL_SBIFPHY_RST                     : out std_logic_vector(SBIF_NUM - 1 downto 0);

    SYSCTRL_PIM_RST                         : out std_logic;
    SYSCTRL_PIM_SBIF_RST                    : out std_logic;
    SYSCTRL_PIM_SBIF_PHY_RST                : out std_logic;    

-- DSP_FPGA
    SYSCTRL_BBCTRL_RST                      : out std_logic;
--    SYSCTRL_DSP_RST                         : out std_logic;
    SYSCTRL_DDUC_RST                        : out std_logic;
    SYSCTRL_CFR_RST                         : out std_logic;
    SYSCTRL_DPD_RST                         : out std_logic;
    SYSCTRL_DCIF_RST                        : out std_logic;

-- CTRL_FPGA 
    VSS_RMT_RST_CPRI                        : in  std_logic_vector(CPRI_NUM - 1 downto 0);
    SYSCTRL_FUNC_FAIL_TRIG                  : in  std_logic_vector(1 downto 0);   -- need to check 
    
-- COMMON_FPGA     
    SYSCTRL_CLK_FAIL_TRIG                   : in  std_logic_vector(31 downto 0);
    EXT_SYSPLL_INTERRUPT_IN                 : in  std_logic;

-- CTRL_FPGA
    SYSCTRL_LED_CTRL                        : out std_logic_array4(LED_NUM -1 downto 0); 
    SYSCTRL_HW_WDT_CTRL                     : out std_logic_vector(31 downto 0); 
        
-- CTRL_FPGA     
    SYSCTRL_BFN_STRB_CTRL                   : out std_logic_array32(CPRI_NUM -1 downto 0);
       
    DL_INNER_FRAME_OFFSET                   : out std_logic_array19(CPRI_NUM - 1 downto 0);
    DL_INNER_ON                             : out std_logic_array15(CPRI_NUM - 1 downto 0);
    DL_INNER_OFF                            : out std_logic_array15(CPRI_NUM - 1 downto 0);
    
    -- UL Nta offset
    UL_INNER_FRAME_OFFSET                   : out std_logic_vector(18 downto 0);    -- UL-DL frame timing(624 Ts)     
    UL_INNER_ON                             : out std_logic_vector(14 downto 0);
    UL_INNER_OFF                            : out std_logic_vector(14 downto 0);

    TDD_AND_CTRL                            : out std_logic_array32(1 downto 0);
    TDD_OR_CTRL                             : out std_logic_array32(1 downto 0);

    RX_BFN_FAIL                             : in  std_logic_vector(CPRI_NUM - 1 downto 0);
    RX_ABN_CNT                              : in  std_logic_array8(CPRI_NUM - 1 downto 0);
       
    SYSCTRL_TDD_CTRL                        : out std_logic_vector(31 downto 0);
    
    VSS_RMT_RST                             : out std_logic;
    
    NR_SSB_PERIOD                           : out std_logic_vector(4 downto 0);
    NR_SSB_OFFSET                           : out std_logic_vector(3 downto 0);
    SECTOR_MODE                             : out std_logic_vector(1 downto 0); 
    eMTC_SEL                                : out std_logic_vector(1 downto 0);
-- COMMON_FPGA      
    SYSCTRL_RUID                            : out std_logic_vector(3 downto 0);
    SYSCTRL_RU_FF                           : out std_logic;                   
                                     
    SYSCTRL_MISC_RST                        : out std_logic;

--    SYSCTRL_ECPRIPHY_RST                    : out std_logic_vector( ECPRIPHY_NUM -1 downto 0 )  ;
    SYSCTRL_ORAN_FRAMER_RST                 : out std_logic_vector( DL_NUM_CC    -1 downto 0 )  ; 
    SYSCTRL_ORAN_DEFRAMER_RST               : out std_logic_vector( UL_NUM_CC    -1 downto 0 )  ; 
    SYSCTRL_LPHY_TOP_RST                    : out std_logic_vector( DL_NUM_CC    -1 downto 0 )  ;
	SYSCTRL_DLFE_RST                        : out std_logic_vector( DL_NUM_CC    -1 downto 0 )  ; 
    SYSCTRL_ULFE_RST                        : out std_logic_vector( UL_NUM_CC    -1 downto 0 )  ; 
    SYSCTRL_RAFE_RST                        : out std_logic_vector( UL_NUM_CC    -1 downto 0 )  ; 
    SYSCTRL_AURORA_RST                      : out std_logic ;

	DL_CC0_SYNC_ADVANCE                     : out std_logic_vector(21 downto 0);
    DL_CC1_SYNC_ADVANCE                     : out std_logic_vector(21 downto 0);
    UL_CC0_SYNC_RETARD                      : out std_logic_vector(21 downto 0);
    UL_CC1_SYNC_RETARD                      : out std_logic_vector(21 downto 0);
    N_TA_OFFSET_CC0                         : out std_logic_vector(15 downto 0);
    N_TA_OFFSET_CC1                         : out std_logic_vector(15 downto 0);
    
    TP_CON_SEL                              : out std_logic_vector(7 downto 0);
    
    SFN_SCALE                               : out std_logic_vector(3 downto 0);
    C2C_SYNC_PROC_DLY                       : in  std_logic_vector(31 downto 0);
    SYNC_ERR_CNT_CLR                        : out std_logic;
    SYNC_ERR                                : in  std_logic;
    SYNC_ERR_CNT                            : in  std_logic_vector(15 downto 0)
    );
end component;

component TDD_TX_GEN
    generic(
        latency                : natural := 5   --5
    ); 
port(
    RESET                                   : in  std_logic;
    CLK                                     : in  std_logic;                        -- 245.76MHZ
    
    IN_BFN_STROBE                           : in  std_logic;                        -- recoved 
    
----------------------------------------------------------------------
--  output signal 
----------------------------------------------------------------------
    OUT_TX_TDD                              : out std_logic;
    OUT_BFN_STROBE                          : out std_logic;

    BFN_FAIL                                : out std_logic;
    BFN_ABNORMAL_CNT                        : out std_logic_vector(7 downto 0);
    
--------------------------------------------------------------------------------
-- Main MPI
--------------------------------------------------------------------------------   
    UL_DL_CONFIG                            : in  std_logic_vector(2 downto 0);     -- Uplink-downlink configuration    
    SSF_CONFIG                              : in  std_logic_vector(3 downto 0);     -- DwPTS/UpPTS configuration    
    DL_CP_EXTENDED                          : in  std_logic;
    
    DL_OFFSET                               : in  std_logic_vector(18 downto 0);
    DL_TDD_ON                               : in  std_logic_vector(14 downto 0);
    DL_TDD_OFF                              : in  std_logic_vector(14 downto 0)
    );
end component;        

--component TCXO_PLL 
--    port (
--        CLK_IN1                         : in  std_logic; 
--        CLK_OUT1                        : out std_logic; 
--        CLK_OUT2                        : out std_logic; 
--        CLK_OUT3                        : out std_logic; 
--        RESET                           : in  std_logic;
--        LOCKED                          : out std_logic
--    );
--end component ;


-- signal define                                                                               
signal internal_pll_rst                           : std_logic_vector(2 downto 0);

signal ptp_mmcm_clk_out1 : std_logic;
signal ptp_mmcm_clk_out2 : std_logic;
signal clk_156p25m       : std_logic;
signal clk_10m           : std_logic;
signal ptp_mmcm_locked   : std_logic;

signal clk_30p72m                                 : std_logic;
signal clk_122p88m                                : std_logic;
signal clk_245p76m                                : std_logic;
signal clk_153p6m                                 : std_logic;
signal clk_307p2m                                 : std_logic;
signal clk_61p44m                                 : std_logic;
signal data_pll_locked                            : std_logic;    

signal clk_25m                                    : std_logic;
signal clk_200m                                   : std_logic;
signal cpu_mii_pll_locked                         : std_logic;

signal clk_8p704m                                 : std_logic;
signal ook_pll_locked                             : std_logic;

signal cpuif_245p76_sync_reset                    : std_logic;

signal select_bfn_rx_strobe                       : std_logic;

signal clk_fail_r                                 : std_logic_vector(31 downto 0) := x"0000_0000";

signal rx_bfn_strobe                              : std_logic_vector(CPRI_NUM - 1 downto 0);
signal rx_bfn_nr                                  : std_logic_array12(CPRI_NUM - 1 downto 0);

signal select_reg_bfn_strb                        : std_logic_vector(CPRI_NUM - 1 downto 0);
signal select_each_bfn_strb                       : std_logic_vector(CPRI_NUM - 1 downto 0);

signal select_tx_bfn_strb                         : std_logic_vector(CPRI_NUM - 1 downto 0);
signal selected_bfn_rx_strobe_dly                 : std_logic_vector(CPRI_NUM - 1 downto 0); 

signal hwwdt_flag_r                               : std_logic_vector(31 downto 0);

signal sysctrl_bfn_strb_ctrl_r                    : std_logic_array32(CPRI_NUM - 1 downto 0);
signal dl_inner_frame_offset                      : std_logic_array19(CPRI_NUM - 1 downto 0);

signal rx_bfn_fail                                : std_logic_vector(CPRI_NUM - 1 downto 0);
signal rx_abn_cnt                                 : std_logic_array8(CPRI_NUM - 1 downto 0);

signal clk_tcxox4                                 : std_logic := '0';
signal clk_tcxox4_bufg                            : std_logic := '0';
signal clk_tcxox8                                 : std_logic := '0';
signal clk_tcxox8_bufg                            : std_logic := '0';
signal clk_tcxox1                                 : std_logic := '0';
signal clk_tcxox1_bufg                            : std_logic := '0';
signal tcxo_pll_locked                            : std_logic;
signal clk_tcxo_pll_bufg                          : std_logic := '0';
        
signal sfn_scale                                  : std_logic_vector(3 downto 0);
signal c2c_sync_proc_dly                          : std_logic_vector(31 downto 0);
signal sync_err_cnt_clr                           : std_logic;
signal sync_err                                   : std_logic;
signal sync_err_cnt                               : std_logic_vector(15 downto 0);

BEGIN
--    SYSTEM_TIMER_MMCM_RST  <= internal_pll_rst(2) ;
----------------------------------------------------------------------
-- Traffic CLOCK_GEN mapping 
----------------------------------------------------------------------
    U_TRAFFIC_CLK_GEN : DATA_PLL 
    port map (
        CLK_IN1                         => EXT_SYSCLK_IN         ,    --: in  std_logic;    --122.88                    
        --CLKFB_IN                        => FPGA_SYSCLK_FB_IN     ,  --: in  std_logic;    -- need to check 
        CLK_OUT1                        => clk_122p88m           ,    --: out std_logic;    --122.88
        CLK_OUT2                        => clk_245p76m           ,    --: out std_logic;    --245.76  
--        CLK_OUT3                        => clk_30p72m            ,    --: out std_logic;    --30.72 
--        CLK_OUT6                        => clk_61p44m            ,    --        : out std_logic;  -- 61.44MHz
        --CLKFB_OUT                       => FPGA_SYSCLK_FB_OUT    ,    --: out std_logic;
        RESET                           => internal_pll_rst(0)   ,    --: in  std_logic;
        LOCKED                          => data_pll_locked            --: out std_logic
    );

--    u_CLK_1588 : TCXO_PLL
--    port map(
--        clk_out1                    => clk_tcxox4                              ,--: out std_logic;
--        clk_out2                    => clk_tcxox8                              ,--: out std_logic;
--        clk_out3                    => clk_tcxox1                              ,--: out std_logic;
--        reset                       => internal_pll_rst(2)                          ,--: in  std_logic;
--        locked                      => tcxo_pll_locked                         ,--: out std_logic;
--        clk_in1                     => clk_tcxo_pll_bufg                             --: in  std_logic
--    );

--    u_CLK_TCXO_OUT_PLL_BUFG  : BUFG port map(clk_tcxo_pll_bufg, TCXO_OUT_PLL);

    CLK_TCXO_X4 <= clk_tcxox4;
    CLK_TCXO_X8 <= clk_tcxox8;
    CLK_TCXO_X1 <= clk_tcxox1;


    U_PS_RST_SYNC_245P76M : RST_SYNC 
    generic map(
        DLY_NUM                         => 4                     ,    --: natural := 4; 
        MAX_FANOUT_NUM                  => 200                
    )    
    port map(
         RST_IN                         => RST_CPUIF, 
         CLK                            => clk_245p76m, 
         RST_OUT                        => cpuif_245p76_sync_reset
    ); 

    CLK_PTP <= clk_156p25m;

    U_REFCLK_OSERDES_ASSIGN : for I in 0 to (EPHY_NUM - 1) generate --CPRI
        REFCLK_OSERDES_OUT(I) <= MGT_REFCLK0_IN;      
    end generate;
 
    U_REFCLK_CSERDES_ASSIGN : for I in 0 to (CSREF_NUM - 1) generate --CPRI
        REFCLK_CSERDES_OUT(I) <= MGT_REFCLK1_IN;      
    end generate;

    U_REFCLK_SSERDES_ASSIGN : for I in 0 to (SSREF_NUM - 1) generate --SBIF
        REFCLK_SSERDES_OUT(I) <= MGT_REFCLK2_IN;      
    end generate;
    
    U_REFCLK_JSERDES_ASSIGN : for I in 0 to (JSREF_NUM - 1) generate --JESD
        REFCLK_JSERDES_OUT(I) <= MGT_REFCLK3_IN;      
    end generate;
    
    U_REFCLK_ASERDES_ASSIGN : for I in 0 to (ASREF_NUM - 1) generate --AXI
        REFCLK_ASERDES_OUT(I) <= MGT_REFCLK4_IN;      
    end generate;                

    CLK_SYS    <= '0';        -- 30.72  MHz                 
    CLK_SYSX2  <= '0';--clk_61p44m;        -- 61.44  MHz
    CLK_SYSX3  <= '0';               -- 92.16  MHz
    CLK_SYSX4  <= clk_122p88m;       -- 122.88 MHz
    CLK_SYSX5  <= '0';--clk_153p6m;        -- 153.6  MHz
    CLK_SYSX6  <= '0';               -- 184.32 MHz
    CLK_SYSX8  <= clk_245p76m;       -- 245.76 MHz
    CLK_SYSX10 <= '0';--clk_307p2m;        -- 307.2  MHz
    CLK_SYSX12 <= '0';               -- 368.64 MHz
    CLK_SYSX16 <= '0';               -- 491.52 MHz
    CLK_SYSX20 <= '0';               -- 614.4  MHz

--- CTRL_FPGA                         
    U_SBIFPHY_Assign : for I in 0 to (PIM_SBIF_NUM-1) generate
        CLK_SBIF(I)   <= clk_245p76m;                             
        CLK_SBIFXH(I) <= '0';                            
        CLK_SBIFX2(I) <= '0';                            
    end generate;

    U_BFN_RX_ASSIGN_GEN0 : if (CPRI_NUM - 1) = 0 generate                                 
        select_bfn_rx_strobe <=  rx_bfn_strobe(0) when REFCLK_SEL_IN = x"0" else 
                                 rx_bfn_strobe(0);
    end generate;                            
    
    U_BFN_RX_ASSIGN_GEN1 : if (CPRI_NUM - 1) = 1 generate 
        select_bfn_rx_strobe <=  rx_bfn_strobe(0) when REFCLK_SEL_IN = x"0" else 
                                 rx_bfn_strobe(1) when REFCLK_SEL_IN = x"1" else 
                                 rx_bfn_strobe(0);
    end generate;                            
    
    U_BFN_RX_ASSIGN_GEN2 : if (CPRI_NUM - 1) = 2 generate 
        select_bfn_rx_strobe <=  rx_bfn_strobe(0) when REFCLK_SEL_IN = x"0" else 
                                 rx_bfn_strobe(1) when REFCLK_SEL_IN = x"1" else 
                                 rx_bfn_strobe(2) when REFCLK_SEL_IN = x"2" else 
                                 rx_bfn_strobe(0);
    end generate;                            
    
    U_BFN_RX_ASSIGN_GEN3 : if (CPRI_NUM - 1) = 3 generate 
        select_bfn_rx_strobe <=  rx_bfn_strobe(0) when REFCLK_SEL_IN = x"0" else 
                                 rx_bfn_strobe(1) when REFCLK_SEL_IN = x"1" else 
                                 rx_bfn_strobe(2) when REFCLK_SEL_IN = x"2" else 
                                 rx_bfn_strobe(3) when REFCLK_SEL_IN = x"3" else 
                                 rx_bfn_strobe(0);
    end generate;                            
    
    U_BFN_RX_ASSIGN_GEN4 : if (CPRI_NUM - 1) = 4 generate 
        select_bfn_rx_strobe <=  rx_bfn_strobe(0) when REFCLK_SEL_IN = x"0" else 
                                 rx_bfn_strobe(1) when REFCLK_SEL_IN = x"1" else 
                                 rx_bfn_strobe(2) when REFCLK_SEL_IN = x"2" else 
                                 rx_bfn_strobe(3) when REFCLK_SEL_IN = x"3" else 
                                 rx_bfn_strobe(4) when REFCLK_SEL_IN = x"4" else 
                                 rx_bfn_strobe(0);
    end generate;                            
    
    U_BFN_RX_ASSIGN_GEN5 : if (CPRI_NUM - 1) = 5 generate 
        select_bfn_rx_strobe <=  rx_bfn_strobe(0) when REFCLK_SEL_IN = x"0" else 
                                 rx_bfn_strobe(1) when REFCLK_SEL_IN = x"1" else 
                                 rx_bfn_strobe(2) when REFCLK_SEL_IN = x"2" else 
                                 rx_bfn_strobe(3) when REFCLK_SEL_IN = x"3" else 
                                 rx_bfn_strobe(4) when REFCLK_SEL_IN = x"4" else 
                                 rx_bfn_strobe(5) when REFCLK_SEL_IN = x"5" else 
                                 rx_bfn_strobe(0);
    end generate;                            

   OOK_CLK   <= clk_8p704m; 

   CLK_MII   <= clk_25m;                      
   CLK_MIIX2 <= '0';                -- 50  MHz
   CLK_MIIX4 <= '0';                -- 100 MHz
   CLK_MIIX8 <= '0';                -- 200 MHz


TDD_CTRL_OUT      <= x"0000_0000";
DFPGA_TDD         <= '0';
----------------------------------------------------------------------    
--  SBIF_TOP  --## CTRL_FPGA_ONLY_PORT
----------------------------------------------------------------------
-- COMMON_FPGA
    U_STROBE_ASSIGN_N_TDD_GEN : for I in 0 to (CPRI_NUM - 1) generate
    
        u_sync_adv_blk : TDD_TX_GEN
        generic map(
            latency                => 5  --: natural := 5   --5
        )
        port map(
        RESET                                   => cpuif_245p76_sync_reset ,  --: in  std_logic;
        CLK                                     => clk_245p76m             ,  --: in  std_logic;                        -- 245.76MHZ
    
        IN_BFN_STROBE                           => rx_bfn_strobe(I)        ,  --: in  std_logic;                        -- recoved 
    
        ----------------------------------------------------------------------
        --  output signal 
        ----------------------------------------------------------------------
        OUT_TX_TDD                              => open                    ,  --: out std_logic;
        OUT_BFN_STROBE                          => RX_BFN_STRB_OUT(I)      ,  --: out std_logic;

        BFN_FAIL                                => open                    ,  --: out std_logic;
        BFN_ABNORMAL_CNT                        => open                    ,  --: out std_logic_vector(7 downto 0);
    
        --------------------------------------------------------------------------------
        -- Main MPI
        --------------------------------------------------------------------------------   
        UL_DL_CONFIG                            => (others => '0')         ,  --: in  std_logic_vector(2 downto 0);     -- Uplink-downlink configuration    
        SSF_CONFIG                              => (others => '0')         ,  --: in  std_logic_vector(3 downto 0);     -- DwPTS/UpPTS configuration    
        DL_CP_EXTENDED                          => '0'                     ,  --: in  std_logic;
    
        DL_OFFSET                               => dl_inner_frame_offset(I),  --: in  std_logic_vector(18 downto 0);
        DL_TDD_ON                               => (others => '0')         ,  --: in  std_logic_vector(14 downto 0);
        DL_TDD_OFF                              => (others => '0')            --: in  std_logic_vector(14 downto 0)
        );
        --RX_BFN_STRB_OUT(I) <= rx_bfn_strobe(I);
        RX_BFN_NR_OUT(I)   <= rx_bfn_nr(I);        
    end generate;

        INNER_RX_BFN_STROBE_OUT <= DL_1PPS_BFN_STROBE_IN;           -- external port frem jesd output or include ananlog delay.
            
----------------------------------------------------------------------                  
-- INNER TDD relation
----------------------------------------------------------------------    
    INNER_DL_TDD_AND_CTRL_OUT <= '0';
    INNER_DL_TDD_OR_CTRL_OUT <= '0';

U_INNET_TX_AND_OR_GEN : for I in 0 to (CPRI_NUM - 1) generate 
        RX_TDD_OUT(I)  <= '0';
    end generate;

    INNER_RX_TDD_OUT  <= '0';

--------------------------------------------------------------------------    
------  DSP_TOP  --## DSP_FPGA_ONLY_PORT
-------------------------------------------------------------------------- 
    INT_SYSPLL_LOCK_OUT  <= (data_pll_locked and cpu_mii_pll_locked);  

----------------------------------------------------------------------    
--  MISC_TOP 
--------------------------------------------------------------------

     U_WATCHDOG : WATCHDOG
     port map(
         RESET                       => RST_CPUIF                    ,--: in  std_logic;                        -- Synchronous Reset     
         CLK                         => CLK_CPUIF                    ,--: in  std_logic;                        -- 100MHz Clock
     
         WATCHDOG_EN                 => hwwdt_flag_r(16)             ,--: in  std_logic;                        -- Async. Watchdog Enable
         WATCHDOG_CLR                => WATCHDOG_CLR                 ,--: in  std_logic;                        -- Async. Watchdog Clear
         WDT_TIMER_SEC               => hwwdt_flag_r(15 downto 0)    ,--: in  std_logic_vector(15 downto 0);    -- Watchdog timer (unit : second)
         CPU_FAIL                    => HWWDT_FLAG_OUT                --: out std_logic
     );
   
-- DSP_FPGA
    CLK_MISC0  <= clk_25M;       -- 25  MHz
    CLK_MISC1  <= '0';           -- 50 MHz  
    CLK_MISC2  <= '0';           -- 100 MHz 
    CLK_MISC3  <= clk_200m;      --  200 MHz

   clk_fail_r(3 downto 0)   <= (not ptp_mmcm_locked) & (not EXT_SYSPLL_LOCK_IN);                             -- external PLL unlock
    clk_fail_r(11 downto 8)  <= "0000";                                -- external LOS    -- in B13 zeor
    clk_fail_r(19 downto 16) <= "0" & (not ook_pll_locked)  & (not cpu_mii_pll_locked) & (not data_pll_locked); -- internal PLL unlock
    clk_fail_r(27 downto 24) <= x"0";                                                     -- internal LOS      
                                                 -- internal LOS      


u_sync_c2c : SYNC_C2C 
    port map(
        RESET                          => cpuif_245p76_sync_reset     ,--     : in  std_logic;
        SYSCLK                         => clk_245p76m                 ,--     : in  std_logic;                     -- 245.76MHz
        SFN_SCALE                      => sfn_scale                   ,--     : in  std_logic_vector(3 downto 0);
        FRAME_SYNC                     => RX_BFN_STRB_IN (0)          ,--     : in  std_logic;                    -- active high, 1 pulse @3.84 MHz
        SFN_NUM                        => RX_BFN_NR_IN   (0)          ,--     : in  std_logic_vector(11 downto 0);  
        TICK_10MS                      => FRAME_SYNC_C2C              ,--     : out std_logic;                     -- active high(10ms -PROC_DLY @ 245.76 MHz)@SFN_NUM#0
        SFN_NUM_C2C                    => SFN_NUM_C2C                 ,--     : out std_logic_vector(11 downto 0);
        PROC_DLY                       => c2c_sync_proc_dly           ,--     : out std_logic_vector(31 downto 0);

        SYNC_ERR_CNT_CLR               => sync_err_cnt_clr            ,--     : in  std_logic;
        SYNC_ERR                       => sync_err                    ,--     : out std_logic;
        SYNC_ERR_CNT                   => sync_err_cnt                 --     : out std_logic_vector(15 downto 0)
    );

    U_CPUIF_SYSCTRL : CPUIF_SYSCTRL
    generic map(
        LED_NUM                             => LED_NUM                                    , --: natural:= 4;
        CPRI_NUM                            => CPRI_NUM                                   , --: natural:= 6;
        IQCOMP_NUM                          => IQCOMP_NUM                                 , --: natural:= 6;
        SBIF_NUM                            => SBIF_NUM                                   , --: natural:= 6;
        TX_ANT_NUM                          => TX_ANT_NUM                                 , --: natural:= 8;
        CSREF_NUM                           => CSREF_NUM                                  , --: natural:= 6;
        JSREF_NUM                           => JSREF_NUM                                  , --: natural:= 6;
        SSREF_NUM                           => SSREF_NUM                                  , --: natural:= 6;
        C_SYSCTRL_IMG_DATE                  => C_SYSCTRL_IMG_DATE                         , --: STD_LOGIC_VECTOR(31 DOWNTO 0):= X"2016_1010"; 
        C_SYSCTRL_IMG_VER                   => C_SYSCTRL_IMG_VER                          , --: STD_LOGIC_VECTOR(31 DOWNTO 0):= X"0000_0001"; 
        C_SYSCTRL_SYSTEM_INFO0              => C_SYSCTRL_SYSTEM_INFO0                     , --: STD_LOGIC_VECTOR(31 DOWNTO 0):= X"0000_0002";     -- air_tech[3:0]
        C_SYSCTRL_SYSTEM_INFO1              => C_SYSCTRL_SYSTEM_INFO1                     , --: STD_LOGIC_VECTOR(31 DOWNTO 0):= X"0000_0000";     -- freq_band[7:0]
        C_SYSCTRL_SYSTEM_INFO2              => C_SYSCTRL_SYSTEM_INFO2                     , --: STD_LOGIC_VECTOR(31 DOWNTO 0):= X"0000_0000";     -- freq_band[7:0]
        C_SYSCTRL_SYSTEM_INFO3              => C_SYSCTRL_SYSTEM_INFO3                     , --: STD_LOGIC_VECTOR(31 DOWNTO 0):= X"0232_3206";     -- fb_path_num, rx_ant_num, tx_ant_num,cpri_num
        C_SYSCTRL_PBA_INFO                  => C_SYSCTRL_PBA_INFO                         , --: STD_LOGIC_VECTOR(31 DOWNTO 0):= X"0000_0000"; 
        C_SYSCTRL_DEV_INFO                  => C_SYSCTRL_DEV_INFO                         , --: STD_LOGIC_VECTOR(31 DOWNTO 0):= X"0000_0000";
        C_SYSCTRL_MODULE_INFO               => C_SYSCTRL_MODULE_INFO                      , --: STD_LOGIC_VECTOR(31 DOWNTO 0):= X"0000_0001";     
        C_SYSCTRL_MODULE_DATE               => C_SYSCTRL_MODULE_DATE                        --: STD_LOGIC_VECTOR(31 DOWNTO 0):= X"2016_1010"
        )                                                                 
    port map(   
        FPGA_ID                             => FPGA_ID                                    , --: in  std_logic_vector(1 downto 0);
        FPGA_PCB_VER                        => FPGA_PCB_VER, --: in  std_logic_vector(2 downto 0);    

		PSU_VER                             => PSU_VER                                    , --: in  std_logic;
        
        BIAST_3P3V_EN                       => BIAST_3P3V_EN                              , --: out std_logic;
   
    -- COMMON_FPGA
        CLK_CPUIF                           => CLK_CPUIF                                  , --: in  std_logic;
        RST_CPUIF                           => RST_CPUIF                                  , --: in  std_logic;

        ADDR_CPUIF_SYSCTRL                  => ADDR_CPUIF_SYSCTRL_IN                      , --: in  std_logic_vector(15 downto 0);  
        WDATA_CPUIF_SYSCTRL                 => WDATA_CPUIF_SYSCTRL_IN                     , --: in  std_logic_vector(31 downto 0);  
        RDATA_CPUIF_SYSCTRL                 => RDATA_CPUIF_SYSCTRL_OUT                    , --: out std_logic_vector(31 downto 0);  
        WREN_CPUIF_SYSCTRL                  => WREN_CPUIF_SYSCTRL_IN                      , --: in  std_logic;                      
        RDEN_CPUIF_SYSCTRL                  => RDEN_CPUIF_SYSCTRL_IN                      , --: in  std_logic;                      
        RDVAL_CPUIF_SYSCTRL                 => RDVAL_CPUIF_SYSCTRL_OUT                    , --: out std_logic;                      

    -- COMMON_FPGA
        SYSCTRL_IPLL_RST                    => internal_pll_rst                           , --: out std_logic_vector(1 downto 0);   

    -- CTRL_FPGA
        SYSCTRL_IQCOMP_RST                  => RST_IQCOMP                                 , --: out std_logic_vector(IQCOMP_NUM - 1 downto 0);
        SYSCTRL_ETHMUX_RST                  => RST_ETHMUX                                 , --: out std_logic;
        SYSCTRL_SBIF_RST                    => open ,--RST_SBIF                                   , --: out std_logic_vector(SBIF_NUM - 1 downto 0);
        SYSCTRL_SBIFPHY_RST                 => open ,--RST_SBIFPHY                                , --: out std_logic_vector(SBIF_NUM - 1 downto 0);

        SYSCTRL_PIM_RST                     => RST_PIM                                    , --: out std_logic;
        SYSCTRL_PIM_SBIF_RST                => RST_PIM_SBIF                               , --: out std_logic;
        SYSCTRL_PIM_SBIF_PHY_RST            => RST_PIM_SBIF_PHY                           , --: out std_logic;

    -- DSP_FPGA
        SYSCTRL_BBCTRL_RST                  => RST_BBCTRL                                 , --: out std_logic;
--        SYSCTRL_DSP_RST                     => RST_DSP                                     ,--: out std_logic;
        SYSCTRL_DDUC_RST                    => RST_DDUC                                   , --: out std_logic;
        SYSCTRL_CFR_RST                     => RST_CFR                                    , --: out std_logic;
        SYSCTRL_DPD_RST                     => RST_DPD                                    , --: out std_logic;
        SYSCTRL_DCIF_RST                    => RST_DCIF                                   , --: out std_logic;

    -- CTRL_FPGA
        VSS_RMT_RST_CPRI                    => VSS_RMT_RST_CPRI_IN                        , --: in  std_logic_vector(CPRI_NUM - 1 downto 0);
        SYSCTRL_FUNC_FAIL_TRIG              => FUNC_FAIL_TRIG_IN                          , --: in  std_logic_vector(3 downto 0);   -- need to check 
                                                                                     
    -- COMMON_FPGA                                                                   
        SYSCTRL_CLK_FAIL_TRIG               => clk_fail_r                                 , --: in  std_logic_vector(31 downto 0);    
        EXT_SYSPLL_INTERRUPT_IN             => EXT_SYSPLL_LOS_IN,
                                                                                     
    -- CTRL_FPGA                                                                     
        SYSCTRL_LED_CTRL                    => LED_CTRL_OUT                               , --: out std_logic_array4(LED_NUM -1 downto 0); 
        SYSCTRL_HW_WDT_CTRL                 => hwwdt_flag_r                               , --: out std_logic_vector(31 downto 0); 
                                                                                     
    -- CTRL_FPGA                                                                     
        SYSCTRL_BFN_STRB_CTRL               => sysctrl_bfn_strb_ctrl_r                    , --: out std_logic_array32(CPRI_NUM -1 downto 0);

        DL_INNER_FRAME_OFFSET               => dl_inner_frame_offset                      , --: out std_logic_array19(CPRI_NUM - 1 downto 0); -- don't used in verizon 
        DL_INNER_ON                         => open                                       , --: out std_logic_array15(CPRI_NUM - 1 downto 0); -- don't used in verizon 
        DL_INNER_OFF                        => open                                       , --: out std_logic_array15(CPRI_NUM - 1 downto 0); -- don't used in verizon 
                                                                                          
        -- UL Nta offset                                                                  
        UL_INNER_FRAME_OFFSET               => open                                       , --: out std_logic_vector(18 downto 0);    -- UL-DL frame timing(624 Ts)     -- don't used in verizon 
        UL_INNER_ON                         => open                                       , --: out std_logic_vector(14 downto 0); -- don't used in verizon 
        UL_INNER_OFF                        => open                                       , --: out std_logic_vector(14 downto 0); -- don't used in verizon 
                                                                                          
        TDD_AND_CTRL                        => open                                       , --: out std_logic_array32(1 downto 0);
        TDD_OR_CTRL                         => open                                       , --: out std_logic_array32(1 downto 0);

        RX_BFN_FAIL                         => rx_bfn_fail                                , --: in  std_logic_vector(CPRI_NUM - 1 downto 0); -- don't used in verizon 
        RX_ABN_CNT                          => rx_abn_cnt                                 , --: in  std_logic_array8(CPRI_NUM - 1 downto 0); -- don't used in verizon  
                                                                                          
        SYSCTRL_TDD_CTRL                    => open                                       , --: out std_logic_vector(31 downto 0);
        
        NR_SSB_PERIOD                       => NR_SSB_PERIOD                              , --: out std_logic_vector(4 downto 0);
        NR_SSB_OFFSET                       => NR_SSB_OFFSET                              , --: out std_logic_vector(3 downto 0);
        SECTOR_MODE                         => SECTOR_MODE                                , --: out std_logic_vector(1 downto 0); 
        eMTC_SEL                            => eMTC_SEL                                   , --: out std_logic_vector(1 downto 0); 

                                                                                       
        VSS_RMT_RST                         => VSS_RMT_RST_OUT                            , --: out std_logic;
                                                                                       
    -- COMMON_FPGA                                                                     
        SYSCTRL_RUID                        => RU_ID_OUT                                  , --: out std_logic_vector(3 downto 0);
        SYSCTRL_RU_FF                       => RU_FF_OUT                                  , --: out std_logic;
        SYSCTRL_MISC_RST                    => RST_MISC                                   , --: out std_logic   
 
--        SYSCTRL_ECPRIPHY_RST                => SYSCTRL_ECPRIPHY_RST                       , --: out std_logic_vector( ECPRIPHY_NUM -1 downto 0 )  ;
        SYSCTRL_ORAN_FRAMER_RST             => SYSCTRL_ORAN_FRAMER_RST                    , --: out std_logic_vector( DL_NUM_CC    -1 downto 0 )  ; 
        SYSCTRL_ORAN_DEFRAMER_RST           => SYSCTRL_ORAN_DEFRAMER_RST                  , --: out std_logic_vector( UL_NUM_CC    -1 downto 0 )  ; 
        SYSCTRL_LPHY_TOP_RST                => SYSCTRL_LPHY_TOP_RST                       , --: out std_logic; 
		SYSCTRL_DLFE_RST                    => SYSCTRL_DLFE_RST                           , --: out std_logic_vector( DL_NUM_CC    -1 downto 0 )  ; 
        SYSCTRL_ULFE_RST                    => SYSCTRL_ULFE_RST                           , --: out std_logic_vector( UL_NUM_CC    -1 downto 0 )  ; 
        SYSCTRL_RAFE_RST                    => SYSCTRL_RAFE_RST                           , --: out std_logic_vector( UL_NUM_CC    -1 downto 0 )  ; 
        SYSCTRL_AURORA_RST                  => SYSCTRL_AURORA_RST                         , --: out std_logic

		DL_CC0_SYNC_ADVANCE                 => DL_CC0_SYNC_ADVANCE                        , --: out std_logic_vector(21 downto 0);
        DL_CC1_SYNC_ADVANCE                 => DL_CC1_SYNC_ADVANCE                        , --: out std_logic_vector(21 downto 0);
        UL_CC0_SYNC_RETARD                  => UL_CC0_SYNC_RETARD                         , --: out std_logic_vector(21 downto 0);
        UL_CC1_SYNC_RETARD                  => UL_CC1_SYNC_RETARD                         , --: out std_logic_vector(21 downto 0)
        N_TA_OFFSET_CC0                     => N_TA_OFFSET_CC0                            , --: out std_logic_vector(15 downto 0);
        N_TA_OFFSET_CC1                     => N_TA_OFFSET_CC1                            , --: out std_logic_vector(15 downto 0);
        TP_CON_SEL                          => TP_CON_SEL                               ,--: out std_logic_vector(7 downto 0);
        
        SFN_SCALE                           => sfn_scale                                  , --: out std_logic_vector(3 downto 0);
        C2C_SYNC_PROC_DLY                   => c2c_sync_proc_dly                          , --: in  std_logic_vector(31 downto 0);
        SYNC_ERR_CNT_CLR                    => sync_err_cnt_clr                           , --: out std_logic;
        SYNC_ERR                            => sync_err                                   , --: in  std_logic;
        SYNC_ERR_CNT                        => sync_err_cnt                                 --: in  std_logic_vector(15 downto 0)
        );            

END SYSCTRL_TOP_ARC;                                                           
                                                                              
