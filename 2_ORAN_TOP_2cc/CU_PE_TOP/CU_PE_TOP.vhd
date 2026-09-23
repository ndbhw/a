--================================================================================
-- Filename     : CU_PE_TOP.vhd (C/U Plane Processing Engine)
-- Author       : Taeyoup Kim (taeyoup.kim@samsung.com)
-- Description  : O-RAN C-Plane (DL/UL) Parameter Parsing and Rx window management
--                O-RAN U-Plane (DL)    IQ Data Alignment and Rx window management
----------------------------------------------------------------------------------
--     Date    |     By           |  Version | Description
----------------------------------------------------------------------------------
--  08-07-2020 | Taeyoup Kim      |    1.0   | Original Version
----------------------------------------------------------------------------------
--  02-08-2022 | MoonHyeok Jang   |    1.1   | Modified for RF2221D Project
--================================================================================
-- Copyright (c) 2020 SAMSUNG. All rights reserved.
--================================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


    entity CU_PE_TOP is
    generic (
    VENDOR                      : string  := "XILINX";
    Category                    : string  :=      "A";
    eCPRI_HDR                   : boolean :=     TRUE;
    iFFT_k0_SHIFT               : boolean :=     TRUE;
    iFFT_ZERO_PADDING           : boolean :=     TRUE;
    SCS                         : natural :=       15;
    SECTION_NUM                 : natural :=      128;
    Max_RB_NUM                  : natural :=      110;
    iFFT_WIDTH                  : natural :=       11;
    SYMBOL_NUM                  : natural :=        7;
    CH_NUM                      : natural :=        2; -- Layer/Path @ module
    DL_LAYER_NUM                : natural :=        4;
    UL_RX_NUM                   : natural :=        4;
    CELL_NUM_eMTC               : natural :=        1;
    PATH_NUM                    : natural :=        2; -- Layer/Path @ cell
    Opt_BF_Support              : natural :=        0  -- Mandatory: 0, Optional: 1
    );
    port (

    CLK                         : in  std_logic;

    nRE                         : in  std_logic_vector(11 downto 0);
    nFFT                        : in  std_logic_vector( 1 downto 0);
    -- 1 clk pulse, should be aligned with 1PPS
    FRAME_SYNC                  : in  std_logic;

    DL_SYNC_ADVANCE             : in  std_logic_vector(21 downto 0);
    UL_SYNC_RETARD              : in  std_logic_vector(21 downto 0);

    -- FSU CPRI NR only mode
    BFN_NUM_IN                  : in  std_logic_vector(11 downto 0);
    BFN_NUM_OUT                 : out std_logic_vector(11 downto 0);

    --------------------------------------------------------------------------------
    -- ORAN_TOP
    --------------------------------------------------------------------------------

    UP_ONLY_DL_MODE             : in  std_logic;

    -- DL/UL C-Plane
    ECPRI_RX_C_CH_IDX           : in  std_logic_vector( 3 downto 0);
    ECPRI_RX_C_VALID            : in  std_logic;
    ECPRI_RX_C_LAST             : in  std_logic;
    ECPRI_RX_C_KEEP             : in  std_logic_vector( 3 downto 0);
    ECPRI_RX_C_DATA             : in  std_logic_vector(31 downto 0);

    -- DL U-Plane
    RB_CH_IDX                   : in  std_logic_vector( 3 downto 0);
    RB_FRAME_ID                 : in  std_logic_vector( 7 downto 0);
    RB_SUBFRAME_ID              : in  std_logic_vector( 3 downto 0);
    RB_SLOT_ID                  : in  std_logic_vector( 5 downto 0);
    RB_SYMBOL_ID                : in  std_logic_vector( 5 downto 0);
    RB_SECTION_ID               : in  std_logic_vector(11 downto 0);
    RE_NUMBER                   : in  std_logic_vector(11 downto 0);

    RB_VALID                    : in  std_logic;
    RB_START                    : in  std_logic;
    RB_LAST                     : in  std_logic;
    RB_TICK                     : in  std_logic;
    RB_DATA_I                   : in  std_logic_vector(15 downto 0);
    RB_DATA_Q                   : in  std_logic_vector(15 downto 0);

    --------------------------------------------------------------------------------
    -- DLFE/ULFE/RAFE
    --------------------------------------------------------------------------------

    SYSTEM_MODE                 : in  std_logic;                     -- 0: LTE, 1: NR
    K0                          : in  std_logic_vector(11 downto 0);
    DL_FRAME_SYNC               : out std_logic;
    DL_FRAME_INDEX              : out std_logic_vector( 7 downto 0);
    DL_FRAME_STRUCTURE          : out std_logic_vector( 7 downto 0);
    DL_MuSu_nLayer              : out std_logic_vector( 4 downto 0); -- just for Optional BF
    DL_VALID                    : out std_logic_vector((Opt_BF_Support*(DL_LAYER_NUM - CH_NUM) + CH_NUM)*01 - 1 downto 0);
    DL_RE_MASK                  : out std_logic_vector((Opt_BF_Support*(DL_LAYER_NUM - CH_NUM) + CH_NUM)*01 - 1 downto 0);
    DL_BEAMID                   : out std_logic_vector((Opt_BF_Support*(DL_LAYER_NUM - CH_NUM) + CH_NUM)*15 - 1 downto 0);
    DL_DATA                     : out std_logic_vector(CH_NUM*32 - 1 downto 0);

    -- RAFE
    UL_FRAME_SYNC               : out std_logic;
    UL_FILTER_INDEX             : out std_logic_vector( 4*CH_NUM-1 downto 0);
    UL_TIME_OFFSET              : out std_logic_vector(16*CH_NUM-1 downto 0);
    UL_FRAME_STRUCTURE          : out std_logic_vector( 8*CH_NUM-1 downto 0);
    UL_CPLENGTH                 : out std_logic_vector(16*CH_NUM-1 downto 0);
    UL_FREQ_OFFSET              : out std_logic_vector(24*CH_NUM-1 downto 0);
    UL_START_PRBC               : out std_logic_vector(10*CH_NUM-1 downto 0);
    UL_NUM_PRBC                 : out std_logic_vector( 8*CH_NUM-1 downto 0);
    UL_NUM_PSYMBOL              : out std_logic_vector( 4*CH_NUM-1 downto 0);
    UL_NUM_RO                   : out std_logic_vector( 3*CH_NUM-1 downto 0);

--    UL_eMTC_FILTER_INDEX        : out std_logic_vector( 4*CELL_NUM_eMTC*PATH_NUM-1 downto 0);
--    UL_eMTC_TIME_OFFSET         : out std_logic_vector(16*CELL_NUM_eMTC*PATH_NUM-1 downto 0);
--    UL_eMTC_FRAME_STRUCTURE     : out std_logic_vector( 8*CELL_NUM_eMTC*PATH_NUM-1 downto 0);
--    UL_eMTC_CPLENGTH            : out std_logic_vector(16*CELL_NUM_eMTC*PATH_NUM-1 downto 0);
--    UL_eMTC_FREQ_OFFSET         : out std_logic_vector(24*CELL_NUM_eMTC*PATH_NUM-1 downto 0);
--    UL_eMTC_START_PRBC          : out std_logic_vector(10*CELL_NUM_eMTC*PATH_NUM-1 downto 0);
--    UL_eMTC_NUM_PRBC            : out std_logic_vector( 8*CELL_NUM_eMTC*PATH_NUM-1 downto 0);
--    UL_eMTC_NUM_PSYMBOL         : out std_logic_vector( 4*CELL_NUM_eMTC*PATH_NUM-1 downto 0);
--    UL_eMTC_NUM_RO              : out std_logic_vector( 3*CELL_NUM_eMTC*PATH_NUM-1 downto 0);

    --------------------------------------------------------------------------------
    --  SYSCTRL
    --------------------------------------------------------------------------------

    SYMBOL_SYNC                 : out std_logic;
    SYMBOL_INDEX                : out std_logic_vector(3 downto 0);
    TDD_DL_EN                   : out std_logic_vector((Opt_BF_Support*(DL_LAYER_NUM - CH_NUM) + CH_NUM)*01 - 1 downto 0);
    TDD_UL_EN                   : out std_logic_vector((Opt_BF_Support*(UL_RX_NUM - CH_NUM) + CH_NUM)*01 - 1 downto 0);

    --------------------------------------------------------------------------------
    --  2G/4G DSS
    --------------------------------------------------------------------------------

    BLANKINGPATTERNID_VALID     : out std_logic;
    BLANKINGPATTERNID           : out std_logic_vector(7 downto 0)
    );
    end CU_PE_TOP;


architecture BEHAVE of CU_PE_TOP is


    component SYNC_GEN is
    generic (
    SCS                         : natural := 15
    );
    port (
    I_CLK                       : in  std_logic;
    I_NFFT                      : in  std_logic_vector( 1 downto 0);
    I_RETARD                    : in  std_logic_vector(21 downto 0);
    I_FRAME_SYNC                : in  std_logic;
    I_EN                        : in  std_logic;
    O_FRAME_SYNC                : out std_logic;
    O_SUBFRM_SYNC               : out std_logic;
    O_SLOT_SYNC                 : out std_logic;
    O_SYMBOL_SYNC               : out std_logic;
    O_SYMBOL_CH_SYNC            : out std_logic;
    O_SUBFRAME                  : out std_logic_vector( 3 downto 0);
    O_SLOT                      : out std_logic_vector( 7 downto 0);
    O_SYMBOL                    : out std_logic_vector( 3 downto 0)
    );
    end component;

    component SIZE_TAILOR is
    port (
    CLK                         : in std_logic;
    nRE                         : in std_logic_vector(11 downto 0);
    nFFT                        : in std_logic_vector(1 downto 0);
    RE_SIZE                     : out natural range 0 to 3276;
    RB_SIZE                     : out natural range 0 to 273;
    BW_iFFT_WIDTH               : out natural range 0 to 12
    );
    end component;

    component CP_PARSER is
    generic (
    eCPRI_HDR                   : boolean := FALSE
    );
    port (
    CLK                         : in std_logic;
    ECPRI_RX_C_CH_IDX           : in std_logic_vector(  3 downto 0);
    ECPRI_RX_C_VALID            : in std_logic;
    ECPRI_RX_C_LAST             : in std_logic;
    ECPRI_RX_C_KEEP             : in std_logic_vector(  3 downto 0);
    ECPRI_RX_C_DATA             : in std_logic_vector( 31 downto 0);
    CP_UPDATE                   : out std_logic;
    CP_CH_IDX                   : out std_logic_vector(  3 downto 0);
    CP_PARAMETER                : out std_logic_vector(191+(15*3)+6+16 downto 0);
    CP_BLANKINGPATTERNID        : out std_logic_vector(  7 downto 0)
    );
    end component;

    component CP_MODULE is
    generic (
    VENDOR                      : string  := "XILINX";
    Category                    : string  :=      "B";
    ADD_LATENCY                 : natural :=        4; -- available for XILINX
    iFFT_k0_SHIFT               : boolean :=     TRUE;
    iFFT_ZERO_PADDING           : boolean :=    FALSE;
    SCS                         : natural :=       30;
    SECTION_NUM                 : natural :=      256;
    Max_RB_NUM                  : natural :=      273;
    iFFT_WIDTH                  : natural :=       12;
    CH_NUM                      : natural :=        2; -- Layer/Path @ module
    DL_LAYER_NUM                : natural :=        4;
    UL_RX_NUM                   : natural :=        8;
    CELL_NUM_eMTC               : natural :=        1;
    PATH_NUM                    : natural :=        4; -- Layer/Path @ cell
    Opt_BF_Support              : natural :=        1  -- Mandatory: 0, Optional: 1
    );
    port (
    CLK                         : in std_logic;

    BW_iFFT_WIDTH               : in natural range 0 to 12;
    RB_SIZE                     : in natural range 0 to 273;
    RE_SIZE                     : in natural range 0 to 3276;

    TDD_DL_EN                   : in std_logic_vector((Opt_BF_Support*(DL_LAYER_NUM - CH_NUM) + CH_NUM)*01 - 1 downto 0);
    UP_ONLY_DL_MODE             : in std_logic;
    CP_UPDATE                   : in std_logic;
    CP_CH_IDX                   : in std_logic_vector(  3 downto 0);
    CP_PARAMETER                : in std_logic_vector(191+(15*3)+6+16 downto 0);
    DL_ADV_SBF_SYNC             : in std_logic;
    DL_ADV_SLOT_SYNC            : in std_logic;
    DL_ADV_SLOT_IDX             : in std_logic_vector( 7 downto 0); -- SCS 15kHz : 0 ~ 9 (per Frame)
    DL_ADV_SYMBOL_SYNC          : in std_logic;
    DL_ADV_SYMBOL_CH_SYNC       : in std_logic;
    DL_ADV_SYMBOL_IDX           : in std_logic_vector( 3 downto 0); -- 0~13
    UL_RTD_SBF_SYNC             : in std_logic;
    UL_RTD_SBF_IDX              : in std_logic_vector( 3 downto 0); -- 0~9
    UL_RTD_SLOT_SYNC            : in std_logic;
    UL_RTD_SLOT_IDX             : in std_logic_vector( 7 downto 0); -- SCS 15kHz : 0 ~ 9 (per Frame)
    UL_RTD_SYMBOL_SYNC          : in std_logic;
    UL_RTD_SYMBOL_IDX           : in std_logic_vector( 3 downto 0); -- 0~13
    SYSTEM_MODE                 : in std_logic;                    -- 0: LTE, 1: NR
    K0                          : in std_logic_vector( 11 downto 0);
    DL_FRAME_INDEX              : out std_logic_vector(  7 downto 0);
    DL_FRAME_STRUCTURE          : out std_logic_vector(  7 downto 0);
    DL_MuSu_nLayer              : out std_logic_vector(  4 downto 0); -- just for Optional BF
    DL_VALID                    : out std_logic_vector((Opt_BF_Support*(DL_LAYER_NUM - CH_NUM) + CH_NUM)*01 - 1 downto 0);
    DL_RE_MASK                  : out std_logic_vector((Opt_BF_Support*(DL_LAYER_NUM - CH_NUM) + CH_NUM)*01 - 1 downto 0);
    DL_BEAMID                   : out std_logic_vector((Opt_BF_Support*(DL_LAYER_NUM - CH_NUM) + CH_NUM)*15 - 1 downto 0);
    UL_FILTER_INDEX             : out std_logic_vector( 4*CH_NUM-1 downto 0);
    UL_TIME_OFFSET              : out std_logic_vector(16*CH_NUM-1 downto 0);
    UL_FRAME_STRUCTURE          : out std_logic_vector( 8*CH_NUM-1 downto 0);
    UL_CPLENGTH                 : out std_logic_vector(16*CH_NUM-1 downto 0);
    UL_FREQ_OFFSET              : out std_logic_vector(24*CH_NUM-1 downto 0);
    UL_START_PRBC               : out std_logic_vector(10*CH_NUM-1 downto 0);
    UL_NUM_PRBC                 : out std_logic_vector( 8*CH_NUM-1 downto 0);
    UL_NUM_PSYMBOL              : out std_logic_vector( 4*CH_NUM-1 downto 0);
    UL_NUM_RO                   : out std_logic_vector( 3*CH_NUM-1 downto 0)
--    UL_eMTC_FILTER_INDEX        : out std_logic_vector( 4*CELL_NUM_eMTC*PATH_NUM-1 downto 0);
--    UL_eMTC_TIME_OFFSET         : out std_logic_vector(16*CELL_NUM_eMTC*PATH_NUM-1 downto 0);
--    UL_eMTC_FRAME_STRUCTURE     : out std_logic_vector( 8*CELL_NUM_eMTC*PATH_NUM-1 downto 0);
--    UL_eMTC_CPLENGTH            : out std_logic_vector(16*CELL_NUM_eMTC*PATH_NUM-1 downto 0);
--    UL_eMTC_FREQ_OFFSET         : out std_logic_vector(24*CELL_NUM_eMTC*PATH_NUM-1 downto 0);
--    UL_eMTC_START_PRBC          : out std_logic_vector(10*CELL_NUM_eMTC*PATH_NUM-1 downto 0);
--    UL_eMTC_NUM_PRBC            : out std_logic_vector( 8*CELL_NUM_eMTC*PATH_NUM-1 downto 0);
--    UL_eMTC_NUM_PSYMBOL         : out std_logic_vector( 4*CELL_NUM_eMTC*PATH_NUM-1 downto 0);
--    UL_eMTC_NUM_RO              : out std_logic_vector( 3*CELL_NUM_eMTC*PATH_NUM-1 downto 0);
    );
    end component;

    component UP_MODULE is
    generic (
    VENDOR                      : string  := "XILINX";
    iFFT_k0_SHIFT               : boolean :=     TRUE;
    iFFT_ZERO_PADDING           : boolean :=    FALSE;
    SCS                         : natural :=       30;
    iFFT_WIDTH                  : natural :=       12;
    SYMBOL_NUM                  : natural :=        7;
    CH_NUM                      : natural :=        2  -- Layer/Path @ module
    );
    port (
    CLK                         : in std_logic;
    BW_iFFT_WIDTH               : in natural range 0 to 12;
    RE_SIZE                     : in natural range 0 to 3276;
    RB_CH_IDX                   : in std_logic_vector( 3 downto 0);
    RB_FRAME_ID                 : in std_logic_vector( 7 downto 0);
    RB_SUBFRAME_ID              : in std_logic_vector( 3 downto 0);
    RB_SLOT_ID                  : in std_logic_vector( 5 downto 0);
    RB_SYMBOL_ID                : in std_logic_vector( 5 downto 0);
    RB_SECTION_ID               : in std_logic_vector(11 downto 0);
    RE_NUMBER                   : in std_logic_vector(11 downto 0);
    RB_VALID                    : in std_logic;
    RB_START                    : in std_logic;
    RB_LAST                     : in std_logic;
    RB_TICK                     : in std_logic;
    RB_DATA_I                   : in std_logic_vector(15 downto 0);
    RB_DATA_Q                   : in std_logic_vector(15 downto 0);
    DL_ADV_SBF_SYNC             : in std_logic;
    DL_ADV_SBF_IDX              : in std_logic_vector( 3 downto 0); -- 0~9
    DL_ADV_SLOT_SYNC            : in std_logic;
    DL_ADV_SLOT_IDX             : in std_logic_vector( 7 downto 0); -- SCS 15kHz : 0 ~ 9 (per Frame)
    DL_ADV_SYMBOL_SYNC          : in std_logic;
    DL_ADV_SYMBOL_CH_SYNC       : in std_logic;
    DL_ADV_SYMBOL_IDX           : in std_logic_vector( 3 downto 0); -- 0~13
    SYSTEM_MODE                 : in std_logic;                     -- 0: LTE, 1: NR
    K0                          : in std_logic_vector(11 downto 0);
    DL_DATA                     : out std_logic_vector(CH_NUM*32 - 1 downto 0)
    );
    end component;

    signal dl_adv_frame_sync    : std_logic;
    signal dl_adv_sbf_sync      : std_logic;
    signal dl_adv_sbf_idx       : std_logic_vector( 3 downto 0);
    signal dl_adv_slot_sync     : std_logic;
    signal dl_adv_slot_idx      : std_logic_vector( 7 downto 0);
    signal dl_adv_symbol_sync   : std_logic;
    signal dl_adv_symbol_ch_sync: std_logic;
    signal dl_adv_symbol_idx    : std_logic_vector( 3 downto 0);
    signal ul_rtd_frame_sync    : std_logic;
    signal ul_rtd_sbf_sync      : std_logic;
    signal ul_rtd_sbf_idx       : std_logic_vector( 3 downto 0);
    signal ul_rtd_slot_sync     : std_logic;
    signal ul_rtd_slot_idx      : std_logic_vector( 7 downto 0);
    signal ul_rtd_symbol_sync   : std_logic;
    signal ul_rtd_symbol_idx    : std_logic_vector( 3 downto 0);
    signal dl_adv_frame_sync_d  : std_logic_vector( 5+4 downto 0);
    signal dl_frame_idx         : std_logic_vector( 7 downto 0);
    signal ul_rtd_frame_sync_d  : std_logic;
    signal cp_update            : std_logic;
    signal cp_ch_idx            : std_logic_vector(  3 downto 0);
    signal cp_parameter         : std_logic_vector(191+(15*3)+6+16 downto 0);

    signal cp_blankingpatternid : std_logic_vector( 7 downto 0);

    signal i_re_size            : natural range 0 to 3276 := 0;
    signal i_rb_size            : natural range 0 to 273 := 0;
    signal i_bw_ifft_width      : natural range 0 to 12 := 0;
    signal i_dl_data            : std_logic_vector(CH_NUM*32 - 1 downto 0);
    signal tdd_dl_enable        : std_logic_vector((Opt_BF_Support*(DL_LAYER_NUM - CH_NUM) + CH_NUM)*01 - 1 downto 0) := (others => '1');

    -- just for simulation
    signal DL_DATA_I0, DL_DATA_Q0, DL_DATA_I1, DL_DATA_Q1, DL_DATA_I2, DL_DATA_Q2, DL_DATA_I3, DL_DATA_Q3 : std_logic_vector(15 downto 0) := (others => '0');
    signal DL_DATA_I4, DL_DATA_Q4, DL_DATA_I5, DL_DATA_Q5, DL_DATA_I6, DL_DATA_Q6, DL_DATA_I7, DL_DATA_Q7 : std_logic_vector(15 downto 0) := (others => '0');

    signal s_re_valid : std_logic_vector((Opt_BF_Support*(DL_LAYER_NUM - CH_NUM) + CH_NUM)*01 - 1 downto 0);

begin

    DL_VALID    <= s_re_valid;
    DL_RE_MASK  <= s_re_valid;

    u_DL_FRAME_GEN_X : if VENDOR = "XILINX" generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           dl_adv_frame_sync_d <= dl_adv_frame_sync_d(4+4 downto 0) & dl_adv_frame_sync;
           if (dl_adv_frame_sync_d(4+4) = '1') then
              BFN_NUM_OUT    <= BFN_NUM_IN + '1';
              DL_FRAME_INDEX <= BFN_NUM_IN(7 downto 0) + '1';
           end if;
        end if;
    end process;
    DL_FRAME_SYNC <= dl_adv_frame_sync_d(5+4);
    end generate;

    u_DL_FRAME_GEN_I : if VENDOR = "INTEL" generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           dl_adv_frame_sync_d <= dl_adv_frame_sync_d(4+4 downto 0) & dl_adv_frame_sync;
           if (dl_adv_frame_sync_d(4) = '1') then
              BFN_NUM_OUT    <= BFN_NUM_IN + '1';
              DL_FRAME_INDEX <= BFN_NUM_IN(7 downto 0) + '1';
           end if;
        end if;
    end process;
    DL_FRAME_SYNC <= dl_adv_frame_sync_d(5);
    end generate;
    DL_DATA       <= i_dl_data;

    TDD_DL_EN     <= tdd_dl_enable;

    -- just for simulation
    u_DL_DATA0_GEN : if CH_NUM > 0 generate
       DL_DATA_I0 <= i_dl_data(31+32*0 downto 16+32*0);
       DL_DATA_Q0 <= i_dl_data(15+32*0 downto  0+32*0);
    end generate;

    u_DL_DATA1_GEN : if CH_NUM > 1 generate
       DL_DATA_I1 <= i_dl_data(31+32*1 downto 16+32*1);
       DL_DATA_Q1 <= i_dl_data(15+32*1 downto  0+32*1);
    end generate;

    u_DL_DATA2_GEN : if CH_NUM > 2 generate
       DL_DATA_I2 <= i_dl_data(31+32*2 downto 16+32*2);
       DL_DATA_Q2 <= i_dl_data(15+32*2 downto  0+32*2);
    end generate;

    u_DL_DATA3_GEN : if CH_NUM > 3 generate
       DL_DATA_I3 <= i_dl_data(31+32*3 downto 16+32*3);
       DL_DATA_Q3 <= i_dl_data(15+32*3 downto  0+32*3);
    end generate;

    u_DL_DATA4_GEN : if CH_NUM > 4 generate
       DL_DATA_I4 <= i_dl_data(31+32*4 downto 16+32*4);
       DL_DATA_Q4 <= i_dl_data(15+32*4 downto  0+32*4);
    end generate;

    u_DL_DATA5_GEN : if CH_NUM > 5 generate
       DL_DATA_I5 <= i_dl_data(31+32*5 downto 16+32*5);
       DL_DATA_Q5 <= i_dl_data(15+32*5 downto  0+32*5);
    end generate;

    u_DL_DATA6_GEN : if CH_NUM > 6 generate
       DL_DATA_I6 <= i_dl_data(31+32*6 downto 16+32*6);
       DL_DATA_Q6 <= i_dl_data(15+32*6 downto  0+32*6);
    end generate;

    u_DL_DATA7_GEN : if CH_NUM > 7 generate
       DL_DATA_I7 <= i_dl_data(31+32*7 downto 16+32*7);
       DL_DATA_Q7 <= i_dl_data(15+32*7 downto  0+32*7);
    end generate;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           ul_rtd_frame_sync_d <= ul_rtd_frame_sync;
        end if;
    end process;

    UL_FRAME_SYNC <= ul_rtd_frame_sync_d;

    DL_SYNC_GEN : SYNC_GEN
    generic map(
    SCS                         => SCS
    )
    port map(
    I_CLK                       => CLK,
    I_NFFT                      => nFFT,
    I_RETARD                    => DL_SYNC_ADVANCE,
    I_FRAME_SYNC                => FRAME_SYNC,
    I_EN                        => '1',
    O_FRAME_SYNC                => dl_adv_frame_sync,
    O_SUBFRM_SYNC               => dl_adv_sbf_sync,
    O_SLOT_SYNC                 => dl_adv_slot_sync,
    O_SYMBOL_SYNC               => dl_adv_symbol_sync,
    O_SYMBOL_CH_SYNC            => dl_adv_symbol_ch_sync,
    O_SUBFRAME                  => dl_adv_sbf_idx,
    O_SLOT                      => dl_adv_slot_idx,
    O_SYMBOL                    => dl_adv_symbol_idx
    );

    UL_SYNC_GEN : SYNC_GEN
    generic map(
    SCS                         => SCS
    )
    port map(
    I_CLK                       => CLK,
    I_NFFT                      => nFFT,
    I_RETARD                    => UL_SYNC_RETARD,
    I_FRAME_SYNC                => FRAME_SYNC,
    I_EN                        => '1',
    O_FRAME_SYNC                => ul_rtd_frame_sync,
    O_SUBFRM_SYNC               => ul_rtd_sbf_sync,
    O_SLOT_SYNC                 => ul_rtd_slot_sync,
    O_SYMBOL_SYNC               => ul_rtd_symbol_sync,
    O_SYMBOL_CH_SYNC            => open,
    O_SUBFRAME                  => ul_rtd_sbf_idx,
    O_SLOT                      => ul_rtd_slot_idx,
    O_SYMBOL                    => ul_rtd_symbol_idx
    );

    u_SIZE_TAILOR : SIZE_TAILOR
    port map(
    CLK                         => CLK,
    nRE                         => nRE,
    nFFT                        => nFFT,
    RE_SIZE                     => i_re_size,
    RB_SIZE                     => i_rb_size,
    BW_iFFT_WIDTH               => i_bw_ifft_width
    );

    u_CP_PARSER : CP_PARSER
    generic map(
    eCPRI_HDR                   => eCPRI_HDR
    )
    port map(
    CLK                         => CLK,
    ECPRI_RX_C_CH_IDX           => ECPRI_RX_C_CH_IDX,
    ECPRI_RX_C_VALID            => ECPRI_RX_C_VALID,
    ECPRI_RX_C_LAST             => ECPRI_RX_C_LAST,
    ECPRI_RX_C_KEEP             => ECPRI_RX_C_KEEP,
    ECPRI_RX_C_DATA             => ECPRI_RX_C_DATA,
    CP_UPDATE                   => cp_update,
    CP_CH_IDX                   => cp_ch_idx,
    CP_PARAMETER                => cp_parameter,
    CP_BLANKINGPATTERNID        => cp_blankingpatternid
    );

    u_CP_MODULE : CP_MODULE
    generic map(
    VENDOR                      => VENDOR,
    Category                    => Category,
    ADD_LATENCY                 => 4,
    iFFT_k0_SHIFT               => iFFT_k0_SHIFT,
    iFFT_ZERO_PADDING           => iFFT_ZERO_PADDING,
    SCS                         => SCS,
    SECTION_NUM                 => SECTION_NUM,
    Max_RB_NUM                  => Max_RB_NUM,
    iFFT_WIDTH                  => iFFT_WIDTH,
    CH_NUM                      => CH_NUM,
    DL_LAYER_NUM                => DL_LAYER_NUM,
    UL_RX_NUM                   => UL_RX_NUM,
    CELL_NUM_eMTC               => CELL_NUM_eMTC,
    PATH_NUM                    => PATH_NUM,
    Opt_BF_Support              => Opt_BF_Support
    )
    port map(
    CLK                         => CLK,
    BW_iFFT_WIDTH               => i_bw_ifft_width,
    RB_SIZE                     => i_rb_size,
    RE_SIZE                     => i_re_size,

    TDD_DL_EN                   => (others => '1'), --tdd_dl_enable,
    UP_ONLY_DL_MODE             => UP_ONLY_DL_MODE,
    CP_UPDATE                   => cp_update,
    CP_CH_IDX                   => cp_ch_idx,
    CP_PARAMETER                => cp_parameter,
    DL_ADV_SBF_SYNC             => dl_adv_sbf_sync,
    DL_ADV_SLOT_SYNC            => dl_adv_slot_sync,
    DL_ADV_SLOT_IDX             => dl_adv_slot_idx,
    DL_ADV_SYMBOL_SYNC          => dl_adv_symbol_sync,
    DL_ADV_SYMBOL_CH_SYNC       => dl_adv_symbol_ch_sync,
    DL_ADV_SYMBOL_IDX           => dl_adv_symbol_idx,
    UL_RTD_SBF_SYNC             => ul_rtd_sbf_sync,
    UL_RTD_SBF_IDX              => ul_rtd_sbf_idx,
    UL_RTD_SLOT_SYNC            => ul_rtd_slot_sync,
    UL_RTD_SLOT_IDX             => ul_rtd_slot_idx,
    UL_RTD_SYMBOL_SYNC          => ul_rtd_symbol_sync,
    UL_RTD_SYMBOL_IDX           => ul_rtd_symbol_idx,
    SYSTEM_MODE                 => SYSTEM_MODE,
    K0                          => K0,
    DL_FRAME_INDEX              => dl_frame_idx,
    DL_FRAME_STRUCTURE          => DL_FRAME_STRUCTURE,
    DL_MuSu_nLayer              => DL_MuSu_nLayer,
    --    DL_VALID                    => DL_VALID,                 
    --    DL_RE_MASK                  => DL_RE_MASK,               
    DL_VALID                    => s_re_valid,                 
    DL_RE_MASK                  => open,
    DL_BEAMID                   => DL_BEAMID,
    UL_FILTER_INDEX             => UL_FILTER_INDEX,
    UL_TIME_OFFSET              => UL_TIME_OFFSET,
    UL_FRAME_STRUCTURE          => UL_FRAME_STRUCTURE,
    UL_CPLENGTH                 => UL_CPLENGTH,
    UL_FREQ_OFFSET              => UL_FREQ_OFFSET,
    UL_START_PRBC               => UL_START_PRBC,
    UL_NUM_PRBC                 => UL_NUM_PRBC,
    UL_NUM_PSYMBOL              => UL_NUM_PSYMBOL,
    UL_NUM_RO                   => UL_NUM_RO
--    UL_eMTC_FILTER_INDEX        => UL_eMTC_FILTER_INDEX,
--    UL_eMTC_TIME_OFFSET         => UL_eMTC_TIME_OFFSET,
--    UL_eMTC_FRAME_STRUCTURE     => UL_eMTC_FRAME_STRUCTURE,
--    UL_eMTC_CPLENGTH            => UL_eMTC_CPLENGTH,
--    UL_eMTC_FREQ_OFFSET         => UL_eMTC_FREQ_OFFSET,
--    UL_eMTC_START_PRBC          => UL_eMTC_START_PRBC,
--    UL_eMTC_NUM_PRBC            => UL_eMTC_NUM_PRBC,
--    UL_eMTC_NUM_PSYMBOL         => UL_eMTC_NUM_PSYMBOL,
--    UL_eMTC_NUM_RO              => UL_eMTC_NUM_RO,
    );

    u_UP_MODULE : UP_MODULE
    generic map(
    VENDOR                      => VENDOR,
    iFFT_k0_SHIFT               => iFFT_k0_SHIFT,
    iFFT_ZERO_PADDING           => iFFT_ZERO_PADDING,
    SCS                         => SCS,
    iFFT_WIDTH                  => iFFT_WIDTH,
    SYMBOL_NUM                  => SYMBOL_NUM,
    CH_NUM                      => CH_NUM
    )
    port map(
    CLK                         => CLK,
    BW_iFFT_WIDTH               => i_bw_ifft_width,
    RE_SIZE                     => i_re_size,
    RB_CH_IDX                   => RB_CH_IDX,
    RB_FRAME_ID                 => RB_FRAME_ID,
    RB_SUBFRAME_ID              => RB_SUBFRAME_ID,
    RB_SLOT_ID                  => RB_SLOT_ID,
    RB_SYMBOL_ID                => RB_SYMBOL_ID,
    RB_SECTION_ID               => RB_SECTION_ID,
    RE_NUMBER                   => RE_NUMBER,
    RB_VALID                    => RB_VALID,
    RB_START                    => RB_START,
    RB_LAST                     => RB_LAST,
    RB_TICK                     => RB_TICK,
    RB_DATA_I                   => RB_DATA_I,
    RB_DATA_Q                   => RB_DATA_Q,
    DL_ADV_SBF_SYNC             => dl_adv_sbf_sync,
    DL_ADV_SBF_IDX              => dl_adv_sbf_idx,
    DL_ADV_SLOT_SYNC            => dl_adv_slot_sync,
    DL_ADV_SLOT_IDX             => dl_adv_slot_idx,
    DL_ADV_SYMBOL_SYNC          => dl_adv_symbol_sync,
    DL_ADV_SYMBOL_CH_SYNC       => dl_adv_symbol_ch_sync,
    DL_ADV_SYMBOL_IDX           => dl_adv_symbol_idx,
    SYSTEM_MODE                 => SYSTEM_MODE,
    K0                          => K0,
    DL_DATA                     => i_dl_data
    );

    BLANKINGPATTERNID_VALID     <=  cp_update and cp_parameter(31) ;
    BLANKINGPATTERNID           <=  cp_blankingpatternid           ;

end BEHAVE;
