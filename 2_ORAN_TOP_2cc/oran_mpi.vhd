--------------------------------------------------------------------------------
--
-- Copyright (C) 2024, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2024.03.11
--------------------------------------------------------------------------------
-- Function description
--   -. CPU interface
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2024.03.11) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.ARRAY_TYPE.ALL;
use WORK.PKG_ORAN.ALL;
use WORK.PKG_ORAN_ARRAY.ALL;

entity ORAN_MPI is
    generic (
        IMPL_PDxCH                  : boolean := true;
        IMPL_SSB                    : boolean := false;
        IMPL_H_MATRIX               : boolean := false;
        IMPL_PUxCH                  : boolean := true;
        IMPL_PRACH                  : boolean := true;
        IMPL_SRS                    : boolean := false;
        IMPL_RIM_RS                 : boolean := false;
        IMPL_NB_IoT                 : boolean := true;

        MAX_CC_DL                   : natural := 2;
        MAX_CC_UL                   : natural := 1;
        MAX_PDxCH                   : natural := 4;                             -- 1 ~ 64
        MAX_SSB                     : natural := 0;                             -- 1 ~ 64
        MAX_H_MATRIX                : natural := 0;                             -- 1 ~ 64
        MAX_PUxCH                   : natural := 4;                             -- 1 ~ 64
        MAX_PRACH                   : natural := 4;                             -- 1 ~ 64
        MAX_SRS                     : natural := 0;                             -- 1 ~ 64
        MAX_RIM_RS                  : natural := 0;                             -- 1 ~ 64
        MAX_NB_IoT                  : natural := 1;                             -- 1 ~ 64

        MAX_PE                      : natural := 4                              -- 1 ~ 8
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;                            -- 100-MHz
        RST                         : in  std_logic;

--------------------------------------------------------------------------------
-- Debug
--------------------------------------------------------------------------------

        USER_DEBUG0                 : out std_logic_vector(31 downto 0);
        USER_DEBUG1                 : out std_logic_vector(31 downto 0);
        USER_DEBUG2                 : out std_logic_vector(31 downto 0);
        USER_DEBUG3                 : out std_logic_vector(31 downto 0);

        IGNORE_FRAME_ID_PUxCH_RX    : in  std_logic_array8(7 downto 0);
        IGNORE_FRAME_ID_PUxCH_TX    : in  std_logic_array8(7 downto 0);
        IGNORE_FRAME_ID_PRACH0_RX   : in  std_logic_array8(7 downto 0);
        IGNORE_FRAME_ID_PRACH0_TX   : in  std_logic_array8(7 downto 0);
        IGNORE_FRAME_ID_PRACH1_RX   : in  std_logic_array8(7 downto 0);
        IGNORE_FRAME_ID_PRACH1_TX   : in  std_logic_array8(7 downto 0);
        IGNORE_FRAME_ID_NBIOT0_RX   : in  std_logic_array8(7 downto 0);
        IGNORE_FRAME_ID_NBIOT0_TX   : in  std_logic_array8(7 downto 0);
        IGNORE_FRAME_ID_NBIOT1_RX   : in  std_logic_array8(7 downto 0);
        IGNORE_FRAME_ID_NBIOT1_TX   : in  std_logic_array8(7 downto 0);
--        IGNORE_FRAME_ID_NBIOT2_RX   : in  std_logic_array8(7 downto 0);
--        IGNORE_FRAME_ID_NBIOT2_TX   : in  std_logic_array8(7 downto 0);

--------------------------------------------------------------------------------
-- TX/RX links (BIT_WIDTH * MAX_DIMENSION * MAX_DATA_TYPE = n * 64 * 8)
--------------------------------------------------------------------------------

        DL_UPLANE_ONLY_EN           : out std_logic;

        DL_PARAM_ID_EN              : out std_logic_array64(7 downto 0);
        DL_PARAM_ID                 : out std_logic_array64_array16(7 downto 0);
        DL_PE_INDEX                 : out std_logic_array64_array8(7 downto 0);
        DL_COMP_MODE                : out std_logic_array64(7 downto 0);
        DL_IQ_WIDTH                 : out std_logic_array64_array4(7 downto 0);
        DL_COMP_METHOD              : out std_logic_array64_array4(7 downto 0);
        DL_SCS_CONFIG               : out std_logic_array64_array4(7 downto 0);
        DL_FFT_SIZE                 : out std_logic_array64_array4(7 downto 0);
        DL_PRB_PER_SYMBOL           : out std_logic_array64_array10(7 downto 0);
        DL_COMP_EXP_OFFSET          : out std_logic_array64_array5(7 downto 0);

        UL_PARAM_ID_EN              : out std_logic_array64(7 downto 0);
        UL_PARAM_ID                 : out std_logic_array64_array16(7 downto 0);
        UL_PE_INDEX                 : out std_logic_array64_array8(7 downto 0);
        UL_COMP_MODE                : out std_logic_array64(7 downto 0);
        UL_IQ_WIDTH                 : out std_logic_array64_array4(7 downto 0);
        UL_COMP_METHOD              : out std_logic_array64_array4(7 downto 0);
        UL_SCS_CONFIG               : out std_logic_array64_array4(7 downto 0);
        UL_FFT_SIZE                 : out std_logic_array64_array4(7 downto 0);
        UL_PRB_PER_SYMBOL           : out std_logic_array64_array10(7 downto 0);
        UL_PRB_PER_MTU              : out std_logic_array64_array10(7 downto 0);
        UL_COMP_EXP_OFFSET          : out std_logic_array64_array5(7 downto 0);
        UL_COMP_GAIN_OFFSET         : out std_logic_array64_array11(7 downto 0);
        UL_COMP_SCALE_GAIN_OFFSET   : out std_logic_array64_array4(7 downto 0);

--------------------------------------------------------------------------------
-- Processing element lists (BIT_WIDTH * MAX_PE = n * 8)
--------------------------------------------------------------------------------

        PARAM_RU_MAC                : out std_logic_array48(7 downto 0);
        PARAM_PORT_INDEX            : out std_logic_array3(7 downto 0);
        PARAM_DU_MAC                : out std_logic_array48(7 downto 0);
        PARAM_VLAN0_EN              : out std_logic_vector(7 downto 0);
        PARAM_VLAN0_VID             : out std_logic_array12(7 downto 0);
        PARAM_VLAN1_EN              : out std_logic_vector(7 downto 0);
        PARAM_VLAN1_VID             : out std_logic_array12(7 downto 0);

        CAPTURE_PERIOD              : out std_logic_array8(7 downto 0);

        T2A_MAX_DL_CP_RX            : out std_logic_array5_array22(7 downto 0);
        T2A_MIN_DL_CP_RX            : out std_logic_array5_array22(7 downto 0);
        T2A_MAX_DL_UP_RX            : out std_logic_array5_array22(7 downto 0);
        T2A_MIN_DL_UP_RX            : out std_logic_array5_array22(7 downto 0);
        T2A_MAX_UL_CP_RX            : out std_logic_array5_array22(7 downto 0);
        T2A_MIN_UL_CP_RX            : out std_logic_array5_array22(7 downto 0);

        STAT_CNT_CLEAR              : out std_logic_vector(7 downto 0);

        CNT_RX_CORRUPT                                          : in std_logic_array64(7 downto 0); 
        CNT_RX_SECTIONID                                        : in std_logic_array64(7 downto 0); 
        CNT_RX_PCID_eCPRIVERSION_PAYLOADVERSION                 : in std_logic_array64(7 downto 0); 
        CNT_RX_PCID                                             : in std_logic_array64(7 downto 0); 
        CNT_RX_eCPRIVERSION                                     : in std_logic_array64(7 downto 0); 
        CNT_RX_PAYLOADVERSION                                   : in std_logic_array64(7 downto 0);  
       
        DL_CP_SCS0_RX_ON_TIME       : in  std_logic_array64(7 downto 0);
        DL_CP_SCS0_RX_EARLY         : in  std_logic_array64(7 downto 0);
        DL_CP_SCS0_RX_LATE          : in  std_logic_array64(7 downto 0);
        DL_CP_SCS0_RX_NDM           : in  std_logic_array64(7 downto 0);
        DL_CP_SCS1_RX_ON_TIME       : in  std_logic_array64(7 downto 0);
        DL_CP_SCS1_RX_EARLY         : in  std_logic_array64(7 downto 0);
        DL_CP_SCS1_RX_LATE          : in  std_logic_array64(7 downto 0);
        DL_CP_SCS1_RX_NDM           : in  std_logic_array64(7 downto 0);
        DL_CP_SCS2_RX_ON_TIME       : in  std_logic_array64(7 downto 0);
        DL_CP_SCS2_RX_EARLY         : in  std_logic_array64(7 downto 0);
        DL_CP_SCS2_RX_LATE          : in  std_logic_array64(7 downto 0);
        DL_CP_SCS2_RX_NDM           : in  std_logic_array64(7 downto 0);
        DL_CP_SCS3_RX_ON_TIME       : in  std_logic_array64(7 downto 0);
        DL_CP_SCS3_RX_EARLY         : in  std_logic_array64(7 downto 0);
        DL_CP_SCS3_RX_LATE          : in  std_logic_array64(7 downto 0);
        DL_CP_SCS3_RX_NDM           : in  std_logic_array64(7 downto 0);
        DL_CP_SCS4_RX_ON_TIME       : in  std_logic_array64(7 downto 0);
        DL_CP_SCS4_RX_EARLY         : in  std_logic_array64(7 downto 0);
        DL_CP_SCS4_RX_LATE          : in  std_logic_array64(7 downto 0);
        DL_CP_SCS4_RX_NDM           : in  std_logic_array64(7 downto 0);

        DL_UP_SCS0_RX_ON_TIME       : in  std_logic_array64(7 downto 0);
        DL_UP_SCS0_RX_EARLY         : in  std_logic_array64(7 downto 0);
        DL_UP_SCS0_RX_LATE          : in  std_logic_array64(7 downto 0);
        DL_UP_SCS0_RX_NDM           : in  std_logic_array64(7 downto 0);
        DL_UP_SCS1_RX_ON_TIME       : in  std_logic_array64(7 downto 0);
        DL_UP_SCS1_RX_EARLY         : in  std_logic_array64(7 downto 0);
        DL_UP_SCS1_RX_LATE          : in  std_logic_array64(7 downto 0);
        DL_UP_SCS1_RX_NDM           : in  std_logic_array64(7 downto 0);
        DL_UP_SCS2_RX_ON_TIME       : in  std_logic_array64(7 downto 0);
        DL_UP_SCS2_RX_EARLY         : in  std_logic_array64(7 downto 0);
        DL_UP_SCS2_RX_LATE          : in  std_logic_array64(7 downto 0);
        DL_UP_SCS2_RX_NDM           : in  std_logic_array64(7 downto 0);
        DL_UP_SCS3_RX_ON_TIME       : in  std_logic_array64(7 downto 0);
        DL_UP_SCS3_RX_EARLY         : in  std_logic_array64(7 downto 0);
        DL_UP_SCS3_RX_LATE          : in  std_logic_array64(7 downto 0);
        DL_UP_SCS3_RX_NDM           : in  std_logic_array64(7 downto 0);
        DL_UP_SCS4_RX_ON_TIME       : in  std_logic_array64(7 downto 0);
        DL_UP_SCS4_RX_EARLY         : in  std_logic_array64(7 downto 0);
        DL_UP_SCS4_RX_LATE          : in  std_logic_array64(7 downto 0);
        DL_UP_SCS4_RX_NDM           : in  std_logic_array64(7 downto 0);

        UL_CP_SCS0_RX_ON_TIME       : in  std_logic_array64(7 downto 0);
        UL_CP_SCS0_RX_EARLY         : in  std_logic_array64(7 downto 0);
        UL_CP_SCS0_RX_LATE          : in  std_logic_array64(7 downto 0);
        UL_CP_SCS0_RX_NDM           : in  std_logic_array64(7 downto 0);
        UL_CP_SCS1_RX_ON_TIME       : in  std_logic_array64(7 downto 0);
        UL_CP_SCS1_RX_EARLY         : in  std_logic_array64(7 downto 0);
        UL_CP_SCS1_RX_LATE          : in  std_logic_array64(7 downto 0);
        UL_CP_SCS1_RX_NDM           : in  std_logic_array64(7 downto 0);
        UL_CP_SCS2_RX_ON_TIME       : in  std_logic_array64(7 downto 0);
        UL_CP_SCS2_RX_EARLY         : in  std_logic_array64(7 downto 0);
        UL_CP_SCS2_RX_LATE          : in  std_logic_array64(7 downto 0);
        UL_CP_SCS2_RX_NDM           : in  std_logic_array64(7 downto 0);
        UL_CP_SCS3_RX_ON_TIME       : in  std_logic_array64(7 downto 0);
        UL_CP_SCS3_RX_EARLY         : in  std_logic_array64(7 downto 0);
        UL_CP_SCS3_RX_LATE          : in  std_logic_array64(7 downto 0);
        UL_CP_SCS3_RX_NDM           : in  std_logic_array64(7 downto 0);
        UL_CP_SCS4_RX_ON_TIME       : in  std_logic_array64(7 downto 0);
        UL_CP_SCS4_RX_EARLY         : in  std_logic_array64(7 downto 0);
        UL_CP_SCS4_RX_LATE          : in  std_logic_array64(7 downto 0);
        UL_CP_SCS4_RX_NDM           : in  std_logic_array64(7 downto 0);

        UL_CP_TX_TOTAL              : in  std_logic_array64(7 downto 0);
        UL_UP_TX_TOTAL              : in  std_logic_array64(7 downto 0);

--------------------------------------------------------------------------------
-- DSS
--------------------------------------------------------------------------------

        DSS_PARAM_TEST_PATTERN_EN   : out std_logic;

        I_CC0_COEFF_VLD_CNT         : in  std_logic_vector(31 downto 0);
        I_CC1_COEFF_VLD_CNT         : in  std_logic_vector(31 downto 0);

        I_CC0_COEFF_IDX_MON         : in  std_logic_vector(31 downto 0);
        I_CC1_COEFF_IDX_MON         : in  std_logic_vector(31 downto 0);

--------------------------------------------------------------------------------
-- Statistics (Debug)
--------------------------------------------------------------------------------

        RX_PE_VALID                 : in  std_logic_array32(7 downto 0);
        RX_INVALID_DST_MAC          : in  std_logic_array32(7 downto 0);
        RX_INVALID_SRC_MAC          : in  std_logic_array32(7 downto 0);
        RX_INVALID_VLAN_VID         : in  std_logic_array32(7 downto 0);
        RX_DISCONTINUE              : in  std_logic_array32(7 downto 0);
        RX_BYTE_SIZE                : in  std_logic_array32(7 downto 0);
        RX_BYTE_ALIGN               : in  std_logic_array32(7 downto 0);

        RX_DL_CP_POSITION           : in  std_logic_array64(7 downto 0);
        RX_DL_UP_POSITION           : in  std_logic_array64(7 downto 0);
        RX_UL_CP_POSITION           : in  std_logic_array64(7 downto 0);

        USAGE_RX_CP_BUFFER          : in  std_logic_array32(7 downto 0);
        USAGE_RX_UP_BUFFER          : in  std_logic_array32(7 downto 0);

        CNT_RX_CP                   : in  std_logic_array32(7 downto 0);
        CNT_RX_UP                   : in  std_logic_array32(7 downto 0);
        CNT_RX_CP_LOST              : in  std_logic_array32(7 downto 0);
        CNT_RX_UP_LOST              : in  std_logic_array32(7 downto 0);

        USAGE_TX0_UP_BUFFER         : in  std_logic_array32(7 downto 0);
        USAGE_TX1_UP_BUFFER         : in  std_logic_array32(7 downto 0);
        USAGE_TX2_UP_BUFFER         : in  std_logic_array32(7 downto 0);
        USAGE_TX3_UP_BUFFER         : in  std_logic_array32(7 downto 0);
        USAGE_TX4_UP_BUFFER         : in  std_logic_array32(7 downto 0);
--        USAGE_TX5_UP_BUFFER         : in  std_logic_array32(7 downto 0);

        CNT_TX0                     : in  std_logic_array32(7 downto 0);
        CNT_TX1                     : in  std_logic_array32(7 downto 0);
        CNT_TX2                     : in  std_logic_array32(7 downto 0);
        CNT_TX3                     : in  std_logic_array32(7 downto 0);
        CNT_TX4                     : in  std_logic_array32(7 downto 0);
--        CNT_TX5                     : in  std_logic_array32(7 downto 0);
        CNT_TX0_LOST                : in  std_logic_array32(7 downto 0);
        CNT_TX1_LOST                : in  std_logic_array32(7 downto 0);
        CNT_TX2_LOST                : in  std_logic_array32(7 downto 0);
        CNT_TX3_LOST                : in  std_logic_array32(7 downto 0);
        CNT_TX4_LOST                : in  std_logic_array32(7 downto 0);
--        CNT_TX5_LOST                : in  std_logic_array32(7 downto 0);

        DET_DL_CP0_FAULT_ID_31      : in  std_logic_array16(7 downto 0);
        DET_DL_CP1_FAULT_ID_31      : in  std_logic_array16(7 downto 0);
        DET_DL_CP2_FAULT_ID_31      : in  std_logic_array16(7 downto 0);
        DET_DL_CP3_FAULT_ID_31      : in  std_logic_array16(7 downto 0);
        DET_DL_CP4_FAULT_ID_31      : in  std_logic_array16(7 downto 0);
        DET_DL_CP5_FAULT_ID_31      : in  std_logic_array16(7 downto 0);
        DET_DL_CP6_FAULT_ID_31      : in  std_logic_array16(7 downto 0);
        DET_DL_CP7_FAULT_ID_31      : in  std_logic_array16(7 downto 0);
        DET_UL_CP0_FAULT_ID_31      : in  std_logic_array16(7 downto 0);
        DET_UL_CP1_FAULT_ID_31      : in  std_logic_array16(7 downto 0);
        DET_UL_CP2_FAULT_ID_31      : in  std_logic_array16(7 downto 0);
        DET_UL_CP3_FAULT_ID_31      : in  std_logic_array16(7 downto 0);
        DET_UL_CP4_FAULT_ID_31      : in  std_logic_array16(7 downto 0);
        DET_UL_CP5_FAULT_ID_31      : in  std_logic_array16(7 downto 0);
        DET_UL_CP6_FAULT_ID_31      : in  std_logic_array16(7 downto 0);
        DET_UL_CP7_FAULT_ID_31      : in  std_logic_array16(7 downto 0);

        STATUS_TX0_CQ_FSM           : in  std_logic_array8(7 downto 0);
        CNT_TX0_CQ_FSM_BUSY         : in  std_logic_array32(7 downto 0);
        CNT_TX0_CQ_CONV_FULL        : in  std_logic_array32(7 downto 0);
        CNT_TX0_CPSEC_SYMBOL0       : in  std_logic_array32(7 downto 0);
        CNT_TX0_CPSEC_SYMBOL1       : in  std_logic_array32(7 downto 0);
        CNT_TX0_CPSEC_SYMBOL2       : in  std_logic_array32(7 downto 0);
        CNT_TX0_CPSEC_SYMBOL3       : in  std_logic_array32(7 downto 0);
        CNT_TX0_CPSEC_SYMBOL4       : in  std_logic_array32(7 downto 0);
        CNT_TX0_CPSEC_SYMBOL5       : in  std_logic_array32(7 downto 0);
        CNT_TX0_CPSEC_SYMBOL6       : in  std_logic_array32(7 downto 0);
        CNT_TX0_CPSEC_SYMBOL7       : in  std_logic_array32(7 downto 0);
        CNT_TX0_CPSEC_SYMBOL8       : in  std_logic_array32(7 downto 0);
        CNT_TX0_CPSEC_SYMBOL9       : in  std_logic_array32(7 downto 0);
        CNT_TX0_CPSEC_SYMBOL10      : in  std_logic_array32(7 downto 0);
        CNT_TX0_CPSEC_SYMBOL11      : in  std_logic_array32(7 downto 0);
        CNT_TX0_CPSEC_SYMBOL12      : in  std_logic_array32(7 downto 0);
        CNT_TX0_CPSEC_SYMBOL13      : in  std_logic_array32(7 downto 0);
        CNT_TX0_UPPKT_SYMBOL0       : in  std_logic_array32(7 downto 0);
        CNT_TX0_UPPKT_SYMBOL1       : in  std_logic_array32(7 downto 0);
        CNT_TX0_UPPKT_SYMBOL2       : in  std_logic_array32(7 downto 0);
        CNT_TX0_UPPKT_SYMBOL3       : in  std_logic_array32(7 downto 0);
        CNT_TX0_UPPKT_SYMBOL4       : in  std_logic_array32(7 downto 0);
        CNT_TX0_UPPKT_SYMBOL5       : in  std_logic_array32(7 downto 0);
        CNT_TX0_UPPKT_SYMBOL6       : in  std_logic_array32(7 downto 0);
        CNT_TX0_UPPKT_SYMBOL7       : in  std_logic_array32(7 downto 0);
        CNT_TX0_UPPKT_SYMBOL8       : in  std_logic_array32(7 downto 0);
        CNT_TX0_UPPKT_SYMBOL9       : in  std_logic_array32(7 downto 0);
        CNT_TX0_UPPKT_SYMBOL10      : in  std_logic_array32(7 downto 0);
        CNT_TX0_UPPKT_SYMBOL11      : in  std_logic_array32(7 downto 0);
        CNT_TX0_UPPKT_SYMBOL12      : in  std_logic_array32(7 downto 0);
        CNT_TX0_UPPKT_SYMBOL13      : in  std_logic_array32(7 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL0     : in  std_logic_array32(7 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL1     : in  std_logic_array32(7 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL2     : in  std_logic_array32(7 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL3     : in  std_logic_array32(7 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL4     : in  std_logic_array32(7 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL5     : in  std_logic_array32(7 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL6     : in  std_logic_array32(7 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL7     : in  std_logic_array32(7 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL8     : in  std_logic_array32(7 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL9     : in  std_logic_array32(7 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL10    : in  std_logic_array32(7 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL11    : in  std_logic_array32(7 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL12    : in  std_logic_array32(7 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL13    : in  std_logic_array32(7 downto 0);
        USAGE_TX0_CQ_SYMBOL0        : in  std_logic_array32(7 downto 0);
        USAGE_TX0_CQ_SYMBOL1        : in  std_logic_array32(7 downto 0);
        USAGE_TX0_CQ_SYMBOL2        : in  std_logic_array32(7 downto 0);
        USAGE_TX0_CQ_SYMBOL3        : in  std_logic_array32(7 downto 0);
        USAGE_TX0_CQ_SYMBOL4        : in  std_logic_array32(7 downto 0);
        USAGE_TX0_CQ_SYMBOL5        : in  std_logic_array32(7 downto 0);
        USAGE_TX0_CQ_SYMBOL6        : in  std_logic_array32(7 downto 0);
        USAGE_TX0_CQ_SYMBOL7        : in  std_logic_array32(7 downto 0);
        USAGE_TX0_CQ_SYMBOL8        : in  std_logic_array32(7 downto 0);
        USAGE_TX0_CQ_SYMBOL9        : in  std_logic_array32(7 downto 0);
        USAGE_TX0_CQ_SYMBOL10       : in  std_logic_array32(7 downto 0);
        USAGE_TX0_CQ_SYMBOL11       : in  std_logic_array32(7 downto 0);
        USAGE_TX0_CQ_SYMBOL12       : in  std_logic_array32(7 downto 0);
        USAGE_TX0_CQ_SYMBOL13       : in  std_logic_array32(7 downto 0);

        STATUS_TX1_CQ_FSM           : in  std_logic_array8(7 downto 0);
        CNT_TX1_CQ_FSM_BUSY         : in  std_logic_array32(7 downto 0);
        CNT_TX1_CQ_CONV_FULL        : in  std_logic_array32(7 downto 0);
        CNT_TX1_CPSEC_SYMBOL0       : in  std_logic_array32(7 downto 0);
        CNT_TX1_CPSEC_SYMBOL1       : in  std_logic_array32(7 downto 0);
        CNT_TX1_CPSEC_SYMBOL2       : in  std_logic_array32(7 downto 0);
        CNT_TX1_CPSEC_SYMBOL3       : in  std_logic_array32(7 downto 0);
        CNT_TX1_CPSEC_SYMBOL4       : in  std_logic_array32(7 downto 0);
        CNT_TX1_CPSEC_SYMBOL5       : in  std_logic_array32(7 downto 0);
        CNT_TX1_CPSEC_SYMBOL6       : in  std_logic_array32(7 downto 0);
        CNT_TX1_CPSEC_SYMBOL7       : in  std_logic_array32(7 downto 0);
        CNT_TX1_CPSEC_SYMBOL8       : in  std_logic_array32(7 downto 0);
        CNT_TX1_CPSEC_SYMBOL9       : in  std_logic_array32(7 downto 0);
        CNT_TX1_CPSEC_SYMBOL10      : in  std_logic_array32(7 downto 0);
        CNT_TX1_CPSEC_SYMBOL11      : in  std_logic_array32(7 downto 0);
        CNT_TX1_CPSEC_SYMBOL12      : in  std_logic_array32(7 downto 0);
        CNT_TX1_CPSEC_SYMBOL13      : in  std_logic_array32(7 downto 0);
        CNT_TX1_UPPKT_SYMBOL0       : in  std_logic_array32(7 downto 0);
        CNT_TX1_UPPKT_SYMBOL1       : in  std_logic_array32(7 downto 0);
        CNT_TX1_UPPKT_SYMBOL2       : in  std_logic_array32(7 downto 0);
        CNT_TX1_UPPKT_SYMBOL3       : in  std_logic_array32(7 downto 0);
        CNT_TX1_UPPKT_SYMBOL4       : in  std_logic_array32(7 downto 0);
        CNT_TX1_UPPKT_SYMBOL5       : in  std_logic_array32(7 downto 0);
        CNT_TX1_UPPKT_SYMBOL6       : in  std_logic_array32(7 downto 0);
        CNT_TX1_UPPKT_SYMBOL7       : in  std_logic_array32(7 downto 0);
        CNT_TX1_UPPKT_SYMBOL8       : in  std_logic_array32(7 downto 0);
        CNT_TX1_UPPKT_SYMBOL9       : in  std_logic_array32(7 downto 0);
        CNT_TX1_UPPKT_SYMBOL10      : in  std_logic_array32(7 downto 0);
        CNT_TX1_UPPKT_SYMBOL11      : in  std_logic_array32(7 downto 0);
        CNT_TX1_UPPKT_SYMBOL12      : in  std_logic_array32(7 downto 0);
        CNT_TX1_UPPKT_SYMBOL13      : in  std_logic_array32(7 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL0     : in  std_logic_array32(7 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL1     : in  std_logic_array32(7 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL2     : in  std_logic_array32(7 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL3     : in  std_logic_array32(7 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL4     : in  std_logic_array32(7 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL5     : in  std_logic_array32(7 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL6     : in  std_logic_array32(7 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL7     : in  std_logic_array32(7 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL8     : in  std_logic_array32(7 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL9     : in  std_logic_array32(7 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL10    : in  std_logic_array32(7 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL11    : in  std_logic_array32(7 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL12    : in  std_logic_array32(7 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL13    : in  std_logic_array32(7 downto 0);
        USAGE_TX1_CQ_SYMBOL0        : in  std_logic_array32(7 downto 0);
        USAGE_TX1_CQ_SYMBOL1        : in  std_logic_array32(7 downto 0);
        USAGE_TX1_CQ_SYMBOL2        : in  std_logic_array32(7 downto 0);
        USAGE_TX1_CQ_SYMBOL3        : in  std_logic_array32(7 downto 0);
        USAGE_TX1_CQ_SYMBOL4        : in  std_logic_array32(7 downto 0);
        USAGE_TX1_CQ_SYMBOL5        : in  std_logic_array32(7 downto 0);
        USAGE_TX1_CQ_SYMBOL6        : in  std_logic_array32(7 downto 0);
        USAGE_TX1_CQ_SYMBOL7        : in  std_logic_array32(7 downto 0);
        USAGE_TX1_CQ_SYMBOL8        : in  std_logic_array32(7 downto 0);
        USAGE_TX1_CQ_SYMBOL9        : in  std_logic_array32(7 downto 0);
        USAGE_TX1_CQ_SYMBOL10       : in  std_logic_array32(7 downto 0);
        USAGE_TX1_CQ_SYMBOL11       : in  std_logic_array32(7 downto 0);
        USAGE_TX1_CQ_SYMBOL12       : in  std_logic_array32(7 downto 0);
        USAGE_TX1_CQ_SYMBOL13       : in  std_logic_array32(7 downto 0);

        STATUS_TX2_CQ_FSM           : in  std_logic_array8(7 downto 0);
        CNT_TX2_CQ_FSM_BUSY         : in  std_logic_array32(7 downto 0);
        CNT_TX2_CQ_CONV_FULL        : in  std_logic_array32(7 downto 0);
        CNT_TX2_CPSEC_SYMBOL0       : in  std_logic_array32(7 downto 0);
        CNT_TX2_CPSEC_SYMBOL1       : in  std_logic_array32(7 downto 0);
        CNT_TX2_CPSEC_SYMBOL2       : in  std_logic_array32(7 downto 0);
        CNT_TX2_CPSEC_SYMBOL3       : in  std_logic_array32(7 downto 0);
        CNT_TX2_CPSEC_SYMBOL4       : in  std_logic_array32(7 downto 0);
        CNT_TX2_CPSEC_SYMBOL5       : in  std_logic_array32(7 downto 0);
        CNT_TX2_CPSEC_SYMBOL6       : in  std_logic_array32(7 downto 0);
        CNT_TX2_CPSEC_SYMBOL7       : in  std_logic_array32(7 downto 0);
        CNT_TX2_CPSEC_SYMBOL8       : in  std_logic_array32(7 downto 0);
        CNT_TX2_CPSEC_SYMBOL9       : in  std_logic_array32(7 downto 0);
        CNT_TX2_CPSEC_SYMBOL10      : in  std_logic_array32(7 downto 0);
        CNT_TX2_CPSEC_SYMBOL11      : in  std_logic_array32(7 downto 0);
        CNT_TX2_CPSEC_SYMBOL12      : in  std_logic_array32(7 downto 0);
        CNT_TX2_CPSEC_SYMBOL13      : in  std_logic_array32(7 downto 0);
        CNT_TX2_UPPKT_SYMBOL0       : in  std_logic_array32(7 downto 0);
        CNT_TX2_UPPKT_SYMBOL1       : in  std_logic_array32(7 downto 0);
        CNT_TX2_UPPKT_SYMBOL2       : in  std_logic_array32(7 downto 0);
        CNT_TX2_UPPKT_SYMBOL3       : in  std_logic_array32(7 downto 0);
        CNT_TX2_UPPKT_SYMBOL4       : in  std_logic_array32(7 downto 0);
        CNT_TX2_UPPKT_SYMBOL5       : in  std_logic_array32(7 downto 0);
        CNT_TX2_UPPKT_SYMBOL6       : in  std_logic_array32(7 downto 0);
        CNT_TX2_UPPKT_SYMBOL7       : in  std_logic_array32(7 downto 0);
        CNT_TX2_UPPKT_SYMBOL8       : in  std_logic_array32(7 downto 0);
        CNT_TX2_UPPKT_SYMBOL9       : in  std_logic_array32(7 downto 0);
        CNT_TX2_UPPKT_SYMBOL10      : in  std_logic_array32(7 downto 0);
        CNT_TX2_UPPKT_SYMBOL11      : in  std_logic_array32(7 downto 0);
        CNT_TX2_UPPKT_SYMBOL12      : in  std_logic_array32(7 downto 0);
        CNT_TX2_UPPKT_SYMBOL13      : in  std_logic_array32(7 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL0     : in  std_logic_array32(7 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL1     : in  std_logic_array32(7 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL2     : in  std_logic_array32(7 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL3     : in  std_logic_array32(7 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL4     : in  std_logic_array32(7 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL5     : in  std_logic_array32(7 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL6     : in  std_logic_array32(7 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL7     : in  std_logic_array32(7 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL8     : in  std_logic_array32(7 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL9     : in  std_logic_array32(7 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL10    : in  std_logic_array32(7 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL11    : in  std_logic_array32(7 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL12    : in  std_logic_array32(7 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL13    : in  std_logic_array32(7 downto 0);
        USAGE_TX2_CQ_SYMBOL0        : in  std_logic_array32(7 downto 0);
        USAGE_TX2_CQ_SYMBOL1        : in  std_logic_array32(7 downto 0);
        USAGE_TX2_CQ_SYMBOL2        : in  std_logic_array32(7 downto 0);
        USAGE_TX2_CQ_SYMBOL3        : in  std_logic_array32(7 downto 0);
        USAGE_TX2_CQ_SYMBOL4        : in  std_logic_array32(7 downto 0);
        USAGE_TX2_CQ_SYMBOL5        : in  std_logic_array32(7 downto 0);
        USAGE_TX2_CQ_SYMBOL6        : in  std_logic_array32(7 downto 0);
        USAGE_TX2_CQ_SYMBOL7        : in  std_logic_array32(7 downto 0);
        USAGE_TX2_CQ_SYMBOL8        : in  std_logic_array32(7 downto 0);
        USAGE_TX2_CQ_SYMBOL9        : in  std_logic_array32(7 downto 0);
        USAGE_TX2_CQ_SYMBOL10       : in  std_logic_array32(7 downto 0);
        USAGE_TX2_CQ_SYMBOL11       : in  std_logic_array32(7 downto 0);
        USAGE_TX2_CQ_SYMBOL12       : in  std_logic_array32(7 downto 0);
        USAGE_TX2_CQ_SYMBOL13       : in  std_logic_array32(7 downto 0);

        STATUS_TX3_CQ_FSM           : in  std_logic_array8(7 downto 0);
        CNT_TX3_CQ_FSM_BUSY         : in  std_logic_array32(7 downto 0);
        CNT_TX3_CQ_CONV_FULL        : in  std_logic_array32(7 downto 0);
        CNT_TX3_CPSEC_SYMBOL0       : in  std_logic_array32(7 downto 0);
        CNT_TX3_CPSEC_SYMBOL1       : in  std_logic_array32(7 downto 0);
        CNT_TX3_CPSEC_SYMBOL2       : in  std_logic_array32(7 downto 0);
        CNT_TX3_CPSEC_SYMBOL3       : in  std_logic_array32(7 downto 0);
        CNT_TX3_CPSEC_SYMBOL4       : in  std_logic_array32(7 downto 0);
        CNT_TX3_CPSEC_SYMBOL5       : in  std_logic_array32(7 downto 0);
        CNT_TX3_CPSEC_SYMBOL6       : in  std_logic_array32(7 downto 0);
        CNT_TX3_CPSEC_SYMBOL7       : in  std_logic_array32(7 downto 0);
        CNT_TX3_CPSEC_SYMBOL8       : in  std_logic_array32(7 downto 0);
        CNT_TX3_CPSEC_SYMBOL9       : in  std_logic_array32(7 downto 0);
        CNT_TX3_CPSEC_SYMBOL10      : in  std_logic_array32(7 downto 0);
        CNT_TX3_CPSEC_SYMBOL11      : in  std_logic_array32(7 downto 0);
        CNT_TX3_CPSEC_SYMBOL12      : in  std_logic_array32(7 downto 0);
        CNT_TX3_CPSEC_SYMBOL13      : in  std_logic_array32(7 downto 0);
        CNT_TX3_UPPKT_SYMBOL0       : in  std_logic_array32(7 downto 0);
        CNT_TX3_UPPKT_SYMBOL1       : in  std_logic_array32(7 downto 0);
        CNT_TX3_UPPKT_SYMBOL2       : in  std_logic_array32(7 downto 0);
        CNT_TX3_UPPKT_SYMBOL3       : in  std_logic_array32(7 downto 0);
        CNT_TX3_UPPKT_SYMBOL4       : in  std_logic_array32(7 downto 0);
        CNT_TX3_UPPKT_SYMBOL5       : in  std_logic_array32(7 downto 0);
        CNT_TX3_UPPKT_SYMBOL6       : in  std_logic_array32(7 downto 0);
        CNT_TX3_UPPKT_SYMBOL7       : in  std_logic_array32(7 downto 0);
        CNT_TX3_UPPKT_SYMBOL8       : in  std_logic_array32(7 downto 0);
        CNT_TX3_UPPKT_SYMBOL9       : in  std_logic_array32(7 downto 0);
        CNT_TX3_UPPKT_SYMBOL10      : in  std_logic_array32(7 downto 0);
        CNT_TX3_UPPKT_SYMBOL11      : in  std_logic_array32(7 downto 0);
        CNT_TX3_UPPKT_SYMBOL12      : in  std_logic_array32(7 downto 0);
        CNT_TX3_UPPKT_SYMBOL13      : in  std_logic_array32(7 downto 0);
        CNT_TX3_CQ_FULL_SYMBOL0     : in  std_logic_array32(7 downto 0);
        CNT_TX3_CQ_FULL_SYMBOL1     : in  std_logic_array32(7 downto 0);
        CNT_TX3_CQ_FULL_SYMBOL2     : in  std_logic_array32(7 downto 0);
        CNT_TX3_CQ_FULL_SYMBOL3     : in  std_logic_array32(7 downto 0);
        CNT_TX3_CQ_FULL_SYMBOL4     : in  std_logic_array32(7 downto 0);
        CNT_TX3_CQ_FULL_SYMBOL5     : in  std_logic_array32(7 downto 0);
        CNT_TX3_CQ_FULL_SYMBOL6     : in  std_logic_array32(7 downto 0);
        CNT_TX3_CQ_FULL_SYMBOL7     : in  std_logic_array32(7 downto 0);
        CNT_TX3_CQ_FULL_SYMBOL8     : in  std_logic_array32(7 downto 0);
        CNT_TX3_CQ_FULL_SYMBOL9     : in  std_logic_array32(7 downto 0);
        CNT_TX3_CQ_FULL_SYMBOL10    : in  std_logic_array32(7 downto 0);
        CNT_TX3_CQ_FULL_SYMBOL11    : in  std_logic_array32(7 downto 0);
        CNT_TX3_CQ_FULL_SYMBOL12    : in  std_logic_array32(7 downto 0);
        CNT_TX3_CQ_FULL_SYMBOL13    : in  std_logic_array32(7 downto 0);
        USAGE_TX3_CQ_SYMBOL0        : in  std_logic_array32(7 downto 0);
        USAGE_TX3_CQ_SYMBOL1        : in  std_logic_array32(7 downto 0);
        USAGE_TX3_CQ_SYMBOL2        : in  std_logic_array32(7 downto 0);
        USAGE_TX3_CQ_SYMBOL3        : in  std_logic_array32(7 downto 0);
        USAGE_TX3_CQ_SYMBOL4        : in  std_logic_array32(7 downto 0);
        USAGE_TX3_CQ_SYMBOL5        : in  std_logic_array32(7 downto 0);
        USAGE_TX3_CQ_SYMBOL6        : in  std_logic_array32(7 downto 0);
        USAGE_TX3_CQ_SYMBOL7        : in  std_logic_array32(7 downto 0);
        USAGE_TX3_CQ_SYMBOL8        : in  std_logic_array32(7 downto 0);
        USAGE_TX3_CQ_SYMBOL9        : in  std_logic_array32(7 downto 0);
        USAGE_TX3_CQ_SYMBOL10       : in  std_logic_array32(7 downto 0);
        USAGE_TX3_CQ_SYMBOL11       : in  std_logic_array32(7 downto 0);
        USAGE_TX3_CQ_SYMBOL12       : in  std_logic_array32(7 downto 0);
        USAGE_TX3_CQ_SYMBOL13       : in  std_logic_array32(7 downto 0);

        STATUS_TX4_CQ_FSM           : in  std_logic_array8(7 downto 0);
        CNT_TX4_CQ_FSM_BUSY         : in  std_logic_array32(7 downto 0);
        CNT_TX4_CQ_CONV_FULL        : in  std_logic_array32(7 downto 0);
        CNT_TX4_CPSEC_SYMBOL0       : in  std_logic_array32(7 downto 0);
        CNT_TX4_CPSEC_SYMBOL1       : in  std_logic_array32(7 downto 0);
        CNT_TX4_CPSEC_SYMBOL2       : in  std_logic_array32(7 downto 0);
        CNT_TX4_CPSEC_SYMBOL3       : in  std_logic_array32(7 downto 0);
        CNT_TX4_CPSEC_SYMBOL4       : in  std_logic_array32(7 downto 0);
        CNT_TX4_CPSEC_SYMBOL5       : in  std_logic_array32(7 downto 0);
        CNT_TX4_CPSEC_SYMBOL6       : in  std_logic_array32(7 downto 0);
        CNT_TX4_CPSEC_SYMBOL7       : in  std_logic_array32(7 downto 0);
        CNT_TX4_CPSEC_SYMBOL8       : in  std_logic_array32(7 downto 0);
        CNT_TX4_CPSEC_SYMBOL9       : in  std_logic_array32(7 downto 0);
        CNT_TX4_CPSEC_SYMBOL10      : in  std_logic_array32(7 downto 0);
        CNT_TX4_CPSEC_SYMBOL11      : in  std_logic_array32(7 downto 0);
        CNT_TX4_CPSEC_SYMBOL12      : in  std_logic_array32(7 downto 0);
        CNT_TX4_CPSEC_SYMBOL13      : in  std_logic_array32(7 downto 0);
        CNT_TX4_UPPKT_SYMBOL0       : in  std_logic_array32(7 downto 0);
        CNT_TX4_UPPKT_SYMBOL1       : in  std_logic_array32(7 downto 0);
        CNT_TX4_UPPKT_SYMBOL2       : in  std_logic_array32(7 downto 0);
        CNT_TX4_UPPKT_SYMBOL3       : in  std_logic_array32(7 downto 0);
        CNT_TX4_UPPKT_SYMBOL4       : in  std_logic_array32(7 downto 0);
        CNT_TX4_UPPKT_SYMBOL5       : in  std_logic_array32(7 downto 0);
        CNT_TX4_UPPKT_SYMBOL6       : in  std_logic_array32(7 downto 0);
        CNT_TX4_UPPKT_SYMBOL7       : in  std_logic_array32(7 downto 0);
        CNT_TX4_UPPKT_SYMBOL8       : in  std_logic_array32(7 downto 0);
        CNT_TX4_UPPKT_SYMBOL9       : in  std_logic_array32(7 downto 0);
        CNT_TX4_UPPKT_SYMBOL10      : in  std_logic_array32(7 downto 0);
        CNT_TX4_UPPKT_SYMBOL11      : in  std_logic_array32(7 downto 0);
        CNT_TX4_UPPKT_SYMBOL12      : in  std_logic_array32(7 downto 0);
        CNT_TX4_UPPKT_SYMBOL13      : in  std_logic_array32(7 downto 0);
        CNT_TX4_CQ_FULL_SYMBOL0     : in  std_logic_array32(7 downto 0);
        CNT_TX4_CQ_FULL_SYMBOL1     : in  std_logic_array32(7 downto 0);
        CNT_TX4_CQ_FULL_SYMBOL2     : in  std_logic_array32(7 downto 0);
        CNT_TX4_CQ_FULL_SYMBOL3     : in  std_logic_array32(7 downto 0);
        CNT_TX4_CQ_FULL_SYMBOL4     : in  std_logic_array32(7 downto 0);
        CNT_TX4_CQ_FULL_SYMBOL5     : in  std_logic_array32(7 downto 0);
        CNT_TX4_CQ_FULL_SYMBOL6     : in  std_logic_array32(7 downto 0);
        CNT_TX4_CQ_FULL_SYMBOL7     : in  std_logic_array32(7 downto 0);
        CNT_TX4_CQ_FULL_SYMBOL8     : in  std_logic_array32(7 downto 0);
        CNT_TX4_CQ_FULL_SYMBOL9     : in  std_logic_array32(7 downto 0);
        CNT_TX4_CQ_FULL_SYMBOL10    : in  std_logic_array32(7 downto 0);
        CNT_TX4_CQ_FULL_SYMBOL11    : in  std_logic_array32(7 downto 0);
        CNT_TX4_CQ_FULL_SYMBOL12    : in  std_logic_array32(7 downto 0);
        CNT_TX4_CQ_FULL_SYMBOL13    : in  std_logic_array32(7 downto 0);
        USAGE_TX4_CQ_SYMBOL0        : in  std_logic_array32(7 downto 0);
        USAGE_TX4_CQ_SYMBOL1        : in  std_logic_array32(7 downto 0);
        USAGE_TX4_CQ_SYMBOL2        : in  std_logic_array32(7 downto 0);
        USAGE_TX4_CQ_SYMBOL3        : in  std_logic_array32(7 downto 0);
        USAGE_TX4_CQ_SYMBOL4        : in  std_logic_array32(7 downto 0);
        USAGE_TX4_CQ_SYMBOL5        : in  std_logic_array32(7 downto 0);
        USAGE_TX4_CQ_SYMBOL6        : in  std_logic_array32(7 downto 0);
        USAGE_TX4_CQ_SYMBOL7        : in  std_logic_array32(7 downto 0);
        USAGE_TX4_CQ_SYMBOL8        : in  std_logic_array32(7 downto 0);
        USAGE_TX4_CQ_SYMBOL9        : in  std_logic_array32(7 downto 0);
        USAGE_TX4_CQ_SYMBOL10       : in  std_logic_array32(7 downto 0);
        USAGE_TX4_CQ_SYMBOL11       : in  std_logic_array32(7 downto 0);
        USAGE_TX4_CQ_SYMBOL12       : in  std_logic_array32(7 downto 0);
        USAGE_TX4_CQ_SYMBOL13       : in  std_logic_array32(7 downto 0);

--        STATUS_TX5_CQ_FSM           : in  std_logic_array8(7 downto 0);
--        CNT_TX5_CQ_FSM_BUSY         : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CQ_CONV_FULL        : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CPSEC_SYMBOL0       : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CPSEC_SYMBOL1       : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CPSEC_SYMBOL2       : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CPSEC_SYMBOL3       : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CPSEC_SYMBOL4       : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CPSEC_SYMBOL5       : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CPSEC_SYMBOL6       : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CPSEC_SYMBOL7       : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CPSEC_SYMBOL8       : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CPSEC_SYMBOL9       : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CPSEC_SYMBOL10      : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CPSEC_SYMBOL11      : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CPSEC_SYMBOL12      : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CPSEC_SYMBOL13      : in  std_logic_array32(7 downto 0);
--        CNT_TX5_UPPKT_SYMBOL0       : in  std_logic_array32(7 downto 0);
--        CNT_TX5_UPPKT_SYMBOL1       : in  std_logic_array32(7 downto 0);
--        CNT_TX5_UPPKT_SYMBOL2       : in  std_logic_array32(7 downto 0);
--        CNT_TX5_UPPKT_SYMBOL3       : in  std_logic_array32(7 downto 0);
--        CNT_TX5_UPPKT_SYMBOL4       : in  std_logic_array32(7 downto 0);
--        CNT_TX5_UPPKT_SYMBOL5       : in  std_logic_array32(7 downto 0);
--        CNT_TX5_UPPKT_SYMBOL6       : in  std_logic_array32(7 downto 0);
--        CNT_TX5_UPPKT_SYMBOL7       : in  std_logic_array32(7 downto 0);
--        CNT_TX5_UPPKT_SYMBOL8       : in  std_logic_array32(7 downto 0);
--        CNT_TX5_UPPKT_SYMBOL9       : in  std_logic_array32(7 downto 0);
--        CNT_TX5_UPPKT_SYMBOL10      : in  std_logic_array32(7 downto 0);
--        CNT_TX5_UPPKT_SYMBOL11      : in  std_logic_array32(7 downto 0);
--        CNT_TX5_UPPKT_SYMBOL12      : in  std_logic_array32(7 downto 0);
--        CNT_TX5_UPPKT_SYMBOL13      : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CQ_FULL_SYMBOL0     : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CQ_FULL_SYMBOL1     : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CQ_FULL_SYMBOL2     : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CQ_FULL_SYMBOL3     : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CQ_FULL_SYMBOL4     : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CQ_FULL_SYMBOL5     : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CQ_FULL_SYMBOL6     : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CQ_FULL_SYMBOL7     : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CQ_FULL_SYMBOL8     : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CQ_FULL_SYMBOL9     : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CQ_FULL_SYMBOL10    : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CQ_FULL_SYMBOL11    : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CQ_FULL_SYMBOL12    : in  std_logic_array32(7 downto 0);
--        CNT_TX5_CQ_FULL_SYMBOL13    : in  std_logic_array32(7 downto 0);
--        USAGE_TX5_CQ_SYMBOL0        : in  std_logic_array32(7 downto 0);
--        USAGE_TX5_CQ_SYMBOL1        : in  std_logic_array32(7 downto 0);
--        USAGE_TX5_CQ_SYMBOL2        : in  std_logic_array32(7 downto 0);
--        USAGE_TX5_CQ_SYMBOL3        : in  std_logic_array32(7 downto 0);
--        USAGE_TX5_CQ_SYMBOL4        : in  std_logic_array32(7 downto 0);
--        USAGE_TX5_CQ_SYMBOL5        : in  std_logic_array32(7 downto 0);
--        USAGE_TX5_CQ_SYMBOL6        : in  std_logic_array32(7 downto 0);
--        USAGE_TX5_CQ_SYMBOL7        : in  std_logic_array32(7 downto 0);
--        USAGE_TX5_CQ_SYMBOL8        : in  std_logic_array32(7 downto 0);
--        USAGE_TX5_CQ_SYMBOL9        : in  std_logic_array32(7 downto 0);
--        USAGE_TX5_CQ_SYMBOL10       : in  std_logic_array32(7 downto 0);
--        USAGE_TX5_CQ_SYMBOL11       : in  std_logic_array32(7 downto 0);
--        USAGE_TX5_CQ_SYMBOL12       : in  std_logic_array32(7 downto 0);
--        USAGE_TX5_CQ_SYMBOL13       : in  std_logic_array32(7 downto 0);

--------------------------------------------------------------------------------
-- CPU
--------------------------------------------------------------------------------

        WREN_CPUIF_IN               : in  std_logic;
        RDEN_CPUIF_IN               : in  std_logic;
        ADDR_CPUIF_IN               : in  std_logic_vector(15 downto 0);    
        WDATA_CPUIF_IN              : in  std_logic_vector(31 downto 0);
        RDATA_CPUIF_OUT             : out std_logic_vector(31 downto 0);
        RDVAL_CPUIF_OUT             : out std_logic
    );
end ORAN_MPI;

architecture BEHAVE of ORAN_MPI is

    constant DL                     : natural := MAX_CC_DL;
    constant UL                     : natural := MAX_CC_UL;
    constant D0                     : natural := MAX_PDxCH;
    constant D1                     : natural := MAX_SSB;
    constant D2                     : natural := MAX_H_MATRIX;
    constant U0                     : natural := MAX_PUxCH;
    constant U1                     : natural := MAX_PRACH;
    constant U2                     : natural := MAX_SRS;
    constant U3                     : natural := MAX_RIM_RS;
    constant U4                     : natural := MAX_NB_IoT;

    signal we_buf                   : std_logic;
    signal we                       : std_logic_vector(31 downto 0);
    signal we_long                  : std_logic_vector(31 downto 0);
    signal oe_buf                   : std_logic;
    signal oe                       : std_logic_vector(31 downto 0);
    signal oe_long                  : std_logic_vector(31 downto 0);
    signal addr                     : std_logic_vector(15 downto 0);
    signal addr_msb                 : std_logic_vector(4 downto 0);
    signal addr_lsb                 : std_logic_vector(7 downto 0);
    signal read_data                : std_logic_array32(31 downto 0) := (others => (others => '0'));
    signal read_valid               : std_logic_vector(3 downto 0);

    component MPI_REG_WO is
    generic (
        IMPL_INDEX                  : natural := 0;
        IMPL_MAP                    : std_logic_vector(63 downto 0);

        BIT_WIDTH                   : natural := 32;
        REG_ADDR                    : std_logic_vector(7 downto 0) := (others => '0');
        REG_DATA                    : std_logic_vector(31 downto 0) := (others => '0')
    );
    port (
        RESET                       : in  std_logic;
        CLK                         : in  std_logic;

        ACTIVE                      : in  std_logic;
        EN                          : in  std_logic;
        ADDR                        : in  std_logic_vector(7 downto 0);
        DATA_IN                     : in  std_logic_vector(31 downto 0);
        DATA_OUT                    : out std_logic_vector(BIT_WIDTH-1 downto 0)
    );
    end component;

    component MPI_REG_RC is
    generic (
        BIT_WIDTH                   : natural := 32;
        REG_ADDR                    : std_logic_vector(7 downto 0) := (others => '0')
    );
    port (
        RESET                       : in  std_logic;
        CLK                         : in  std_logic;

        EN                          : in  std_logic;
        ADDR                        : in  std_logic_vector(7 downto 0);
        DATA_IN                     : in  std_logic_vector(BIT_WIDTH-1 downto 0);
        DATA_OUT                    : out std_logic_vector(BIT_WIDTH-1 downto 0);
        FLAG_OUT                    : out std_logic_vector(BIT_WIDTH-1 downto 0)
    );
    end component;

    component MPI_REG_WC is
    generic (
        REG_ADDR                    : std_logic_vector(7 downto 0) := (others => '0')
    );
    port (
        RESET                       : in  std_logic;
        CLK                         : in  std_logic;

        EN                          : in  std_logic;
        ADDR                        : in  std_logic_vector(7 downto 0);
        DATA_OUT                    : out std_logic
    );
    end component;

    component MPI_REG_RD8 is
    generic (
        OUTPUT_REG                  : boolean := true;
        INDEX_VALUE                 : natural := 8;
        DATA_BIT                    : natural := 32
    );
    port (
        CLK                         : in  std_logic;

        INDEX                       : in  std_logic_vector(2 downto 0);
        INPUT                       : in  std_logic_array32(7 downto 0);
        OUTPUT                      : out std_logic_vector(31 downto 0)
    );
    end component;

    component MPI_REG_RD64 is
    generic (
        OUTPUT_REG                  : boolean := true;
        INDEX_VALUE                 : natural := 64;
        DATA_BIT                    : natural := 32
    );
    port (
        CLK                         : in  std_logic;

        INDEX                       : in  std_logic_vector(5 downto 0);
        INPUT                       : in  std_logic_array32(63 downto 0);
        OUTPUT                      : out std_logic_vector(31 downto 0)
    );
    end component;

    -- ..._w : write
    -- ..._r : read
    -- ..._c : CDC
    -- ..._s : status
    -- ..._f : flag

                                                                        ----    ----    ----    ----    ----    ----    ----    ----
                                                                            ----    ----    ----    ----    ----    ----    ----    ----
    constant MAP_ONE                : std_logic_vector(63 downto 0) := "0000000000000000000000000000000000000000000000000000000000000001";
    constant MAP_ALL                : std_logic_vector(63 downto 0) := "1111111111111111111111111111111111111111111111111111111111111111";
    constant MAP_PDxCH              : std_logic_vector(63 downto 0) := "1111111111111111111111111111111111111111111111111111111111111111";
--    constant MAP_SSB                : std_logic_vector(63 downto 0) := "0000000000000000000000000000000000000000000000000000000000000001";
    constant MAP_PUxCH              : std_logic_vector(63 downto 0) := "1111111111111111111111111111111111111111111111111111111111111111";
    constant MAP_PRACH              : std_logic_vector(63 downto 0) := "1111111111111111111111111111111111111111111111111111111111111111";
--    constant MAP_SRS                : std_logic_vector(63 downto 0) := "0000000000000000000000000000000000000000000000000000000000000001";
    constant MAP_NB_IOT             : std_logic_vector(63 downto 0) := "1111111111111111111111111111111111111111111111111111111111111111";

    signal user_debug0_r            : std_logic_vector(31 downto 0);
    signal user_debug1_r            : std_logic_vector(31 downto 0);
    signal user_debug2_r            : std_logic_vector(31 downto 0);
    signal user_debug3_r            : std_logic_vector(31 downto 0);
--    signal ignore_frame_id_puxch_r  : std_logic_vector(31 downto 0);
--    signal ignore_frame_id_prach_r  : std_logic_array32(1 downto 0);

    signal dl_uplane_only_en_w      : std_logic_vector(31 downto 0);
    signal dl_uplane_only_en_r      : std_logic_vector(31 downto 0) := (others => '0');

    signal set_dl_data_type_w       : std_logic_vector(2 downto 0);
    signal set_dl_data_type_r       : std_logic_vector(2 downto 0);
    signal max_dl_index_r           : std_logic_vector(31 downto 0) := (others => '0');
    signal set_dl_index_w           : std_logic_vector(15 downto 0);
    signal set_dl_index_r           : std_logic_vector(5 downto 0);

    signal set_ul_data_type_w       : std_logic_vector(2 downto 0);
    signal set_ul_data_type_r       : std_logic_vector(2 downto 0);
    signal max_ul_index_r           : std_logic_vector(31 downto 0) := (others => '0');
    signal set_ul_index_w           : std_logic_vector(15 downto 0);
    signal set_ul_index_r           : std_logic_vector(5 downto 0);

    signal sts_dl_data_type_w       : std_logic_vector(2 downto 0);
    signal sts_dl_data_type_r       : std_logic_vector(2 downto 0);
    signal sts_dl_index_w           : std_logic_vector(15 downto 0);
    signal sts_dl_index_r           : std_logic_vector(5 downto 0);

    signal sts_ul_data_type_w       : std_logic_vector(2 downto 0);
    signal sts_ul_data_type_r       : std_logic_vector(2 downto 0);
    signal sts_ul_index_w           : std_logic_vector(15 downto 0);
    signal sts_ul_index_r           : std_logic_vector(5 downto 0);

    signal max_pe_index_r           : std_logic_vector(31 downto 0);
    signal set_pe_index_w           : std_logic_vector(2 downto 0);
    signal set_pe_index_r           : std_logic_vector(2 downto 0);
    signal sts_pe_index_w           : std_logic_vector(2 downto 0);
    signal sts_pe_index_r           : std_logic_vector(2 downto 0);

    signal active_pdxch             : std_logic_vector(63 downto 0) := (others => '0');
--    signal active_ssb               : std_logic_vector(63 downto 0) := (others => '0');
    signal active_puxch             : std_logic_vector(63 downto 0) := (others => '0');
    signal active_prach             : std_logic_vector(63 downto 0) := (others => '0');
--    signal active_srs               : std_logic_vector(63 downto 0) := (others => '0');
    signal active_nbiot             : std_logic_vector(63 downto 0) := (others => '0');
    signal active_set_pe            : std_logic_vector(63 downto 0) := (others => '0');
    signal active_sts_pe            : std_logic_vector(63 downto 0) := (others => '0');

    signal dl_eaxc_id_w             : std_logic_array64_array32(7 downto 0) := (others => (others => (others => '0')));
    signal dl_eaxc_id_r0            : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_eaxc_id_r1            : std_logic_vector(31 downto 0);
    signal dl_comp_mode_w           : std_logic_array64_array32(7 downto 0) := (others => (others => (others => '0')));
    signal dl_comp_mode_r0          : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_comp_mode_r1          : std_logic_vector(31 downto 0);
    signal dl_frame_structure_w     : std_logic_array64_array32(7 downto 0) := (others => (others => (others => '0')));
    signal dl_frame_structure_r0    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_frame_structure_r1    : std_logic_vector(31 downto 0);
    signal dl_prb_per_symbol_w      : std_logic_array64_array32(7 downto 0) := (others => (others => (others => '0')));
    signal dl_prb_per_symbol_r0     : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_prb_per_symbol_r1     : std_logic_vector(31 downto 0);
    signal dl_pe_index_w            : std_logic_array64_array32(7 downto 0) := (others => (others => (others => '0')));
    signal dl_pe_index_r0           : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_pe_index_r1           : std_logic_vector(31 downto 0);
    signal dl_comp_exp_offset_w     : std_logic_array64_array32(7 downto 0) := (others => (others => (others => '0')));
    signal dl_comp_exp_offset_r0    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_comp_exp_offset_r1    : std_logic_vector(31 downto 0);

    signal ul_eaxc_id_w             : std_logic_array64_array32(7 downto 0) := (others => (others => (others => '0')));
    signal ul_eaxc_id_r0            : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_eaxc_id_r1            : std_logic_vector(31 downto 0);
    signal ul_comp_mode_w           : std_logic_array64_array32(7 downto 0) := (others => (others => (others => '0')));
    signal ul_comp_mode_r0          : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_comp_mode_r1          : std_logic_vector(31 downto 0);
    signal ul_frame_structure_w     : std_logic_array64_array32(7 downto 0) := (others => (others => (others => '0')));
    signal ul_frame_structure_r0    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_frame_structure_r1    : std_logic_vector(31 downto 0);
    signal ul_prb_per_symbol_w      : std_logic_array64_array32(7 downto 0) := (others => (others => (others => '0')));
    signal ul_prb_per_symbol_r0     : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_prb_per_symbol_r1     : std_logic_vector(31 downto 0);
    signal ul_prb_per_mtu_w         : std_logic_array64_array32(7 downto 0) := (others => (others => (others => '0')));
    signal ul_prb_per_mtu_r0        : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_prb_per_mtu_r1        : std_logic_vector(31 downto 0);
    signal ul_pe_index_w            : std_logic_array64_array32(7 downto 0) := (others => (others => (others => '0')));
    signal ul_pe_index_r0           : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_pe_index_r1           : std_logic_vector(31 downto 0);
    signal ul_comp_exp_offset_w     : std_logic_array64_array32(7 downto 0) := (others => (others => (others => '0')));
    signal ul_comp_exp_offset_r0    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_comp_exp_offset_r1    : std_logic_vector(31 downto 0);
    signal ul_comp_gain_offset_w    : std_logic_array64_array32(7 downto 0) := (others => (others => (others => '0')));
    signal ul_comp_gain_offset_r0   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_comp_gain_offset_r1   : std_logic_vector(31 downto 0);
    signal ul_comp_scale_gain_offset_w  : std_logic_array64_array32(7 downto 0) := (others => (others => (others => '0')));
    signal ul_comp_scale_gain_offset_r0 : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_comp_scale_gain_offset_r1 : std_logic_vector(31 downto 0);

    signal dss_test_en_w            : std_logic_vector(0 downto 0);
    signal dss_test_en_r            : std_logic_vector(31 downto 0) := (others => '0');
    signal coeff_vld_cnt_r          : std_logic_array32(1 downto 0);
    signal coeff_idx_mon_r          : std_logic_array32(1 downto 0);

    signal l0_mac_47_to_32_w        : std_logic_vector(31 downto 0);
    signal l0_mac_31_to_0_w         : std_logic_vector(31 downto 0);
    signal l1_mac_47_to_32_w        : std_logic_vector(31 downto 0);
    signal l1_mac_31_to_0_w         : std_logic_vector(31 downto 0);
    signal l2_mac_47_to_32_w        : std_logic_vector(31 downto 0);
    signal l2_mac_31_to_0_w         : std_logic_vector(31 downto 0);
    signal l3_mac_47_to_32_w        : std_logic_vector(31 downto 0);
    signal l3_mac_31_to_0_w         : std_logic_vector(31 downto 0);

    signal du_mac_47_to_32_w        : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal du_mac_47_to_32_r        : std_logic_vector(31 downto 0);
    signal du_mac_31_to_0_w         : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal du_mac_31_to_0_r         : std_logic_vector(31 downto 0);
    signal ru_mac_47_to_32_w        : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ru_mac_47_to_32_r        : std_logic_vector(31 downto 0);
    signal ru_mac_31_to_0_w         : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ru_mac_31_to_0_r         : std_logic_vector(31 downto 0);
    signal vlan0_vid_w              : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal vlan0_vid_r              : std_logic_vector(31 downto 0);
--    signal vlan1_vid_w              : std_logic_array32(7 downto 0) := (others => (others => '0'));
--    signal vlan1_vid_r              : std_logic_vector(31 downto 0);

    signal capture_period_w         : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal capture_period_r         : std_logic_vector(31 downto 0);

    signal t2a_max0_dl_cp_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_max0_dl_cp_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_max1_dl_cp_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_max1_dl_cp_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_max2_dl_cp_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_max2_dl_cp_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_max3_dl_cp_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_max3_dl_cp_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_max4_dl_cp_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_max4_dl_cp_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_min0_dl_cp_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_min0_dl_cp_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_min1_dl_cp_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_min1_dl_cp_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_min2_dl_cp_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_min2_dl_cp_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_min3_dl_cp_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_min3_dl_cp_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_min4_dl_cp_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_min4_dl_cp_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_max0_dl_up_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_max0_dl_up_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_max1_dl_up_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_max1_dl_up_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_max2_dl_up_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_max2_dl_up_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_max3_dl_up_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_max3_dl_up_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_max4_dl_up_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_max4_dl_up_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_min0_dl_up_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_min0_dl_up_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_min1_dl_up_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_min1_dl_up_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_min2_dl_up_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_min2_dl_up_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_min3_dl_up_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_min3_dl_up_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_min4_dl_up_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_min4_dl_up_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_max0_ul_cp_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_max0_ul_cp_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_max1_ul_cp_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_max1_ul_cp_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_max2_ul_cp_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_max2_ul_cp_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_max3_ul_cp_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_max3_ul_cp_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_max4_ul_cp_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_max4_ul_cp_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_min0_ul_cp_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_min0_ul_cp_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_min1_ul_cp_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_min1_ul_cp_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_min2_ul_cp_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_min2_ul_cp_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_min3_ul_cp_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_min3_ul_cp_rx_r      : std_logic_vector(31 downto 0);
    signal t2a_min4_ul_cp_rx_w      : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal t2a_min4_ul_cp_rx_r      : std_logic_vector(31 downto 0);

    signal rx_total_u_w             : std_logic_array64(7 downto 0) := (others => (others => '0'));
    signal rx_total_c_w             : std_logic_array64(7 downto 0) := (others => (others => '0'));

    signal rx_total_w               : std_logic_array64(7 downto 0) := (others => (others => '0'));
    signal rx_total_upper_w         : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal rx_total_lower_w         : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal rx_total_upper_r         : std_logic_vector(31 downto 0);
    signal rx_total_lower_r         : std_logic_vector(31 downto 0);
    signal rx_on_time_u_w           : std_logic_array64(7 downto 0) := (others => (others => '0'));
    signal rx_on_time_u_upper_w     : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal rx_on_time_u_lower_w     : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal rx_on_time_u_upper_r     : std_logic_vector(31 downto 0);
    signal rx_on_time_u_lower_r     : std_logic_vector(31 downto 0);
    signal rx_early_u_w             : std_logic_array64(7 downto 0) := (others => (others => '0'));
    signal rx_early_u_upper_w       : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal rx_early_u_lower_w       : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal rx_early_u_upper_r       : std_logic_vector(31 downto 0);
    signal rx_early_u_lower_r       : std_logic_vector(31 downto 0);
    signal rx_late_u_w              : std_logic_array64(7 downto 0) := (others => (others => '0'));
    signal rx_late_u_upper_w        : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal rx_late_u_lower_w        : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal rx_late_u_upper_r        : std_logic_vector(31 downto 0);
    signal rx_late_u_lower_r        : std_logic_vector(31 downto 0);

    signal rx_on_time_c_w           : std_logic_array64(7 downto 0) := (others => (others => '0'));
    signal rx_on_time_c_upper_w     : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal rx_on_time_c_lower_w     : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal rx_on_time_c_upper_r     : std_logic_vector(31 downto 0);
    signal rx_on_time_c_lower_r     : std_logic_vector(31 downto 0);
    signal rx_early_c_w             : std_logic_array64(7 downto 0) := (others => (others => '0'));
    signal rx_early_c_upper_w       : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal rx_early_c_lower_w       : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal rx_early_c_upper_r       : std_logic_vector(31 downto 0);
    signal rx_early_c_lower_r       : std_logic_vector(31 downto 0);
    signal rx_late_c_w              : std_logic_array64(7 downto 0) := (others => (others => '0'));
    signal rx_late_c_upper_w        : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal rx_late_c_lower_w        : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal rx_late_c_upper_r        : std_logic_vector(31 downto 0);
    signal rx_late_c_lower_r        : std_logic_vector(31 downto 0);

    signal s_w_cnt_rx_corrupt_upper								: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal s_w_cnt_rx_corrupt_lower								: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal s_w_cnt_rx_corrupt_sectionid_upper						: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal s_w_cnt_rx_corrupt_sectionid_lower						: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal s_w_cnt_rx_corrupt_pcid_ecpriv_payloadv_upper			: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal s_w_cnt_rx_corrupt_pcid_ecpriv_payloadv_lower			: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal s_w_cnt_rx_corrupt_ecpriv_upper						: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal s_w_cnt_rx_corrupt_ecpriv_lower						: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal s_w_cnt_rx_corrupt_pcid_upper							: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal s_w_cnt_rx_corrupt_pcid_lower							: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal s_w_cnt_rx_corrupt_payloadv_upper						: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal s_w_cnt_rx_corrupt_payloadv_lower						: std_logic_array32(7 downto 0) := (others => (others => '0'));

    signal s_r_cnt_rx_corrupt_upper								: std_logic_vector(31 downto 0);
    signal s_r_cnt_rx_corrupt_lower								: std_logic_vector(31 downto 0);
    signal s_r_cnt_rx_corrupt_sectionid_upper					: std_logic_vector(31 downto 0);
    signal s_r_cnt_rx_corrupt_sectionid_lower					: std_logic_vector(31 downto 0);
    signal s_r_cnt_rx_corrupt_pcid_ecpriv_payloadv_upper		: std_logic_vector(31 downto 0);
    signal s_r_cnt_rx_corrupt_pcid_ecpriv_payloadv_lower		: std_logic_vector(31 downto 0);
    signal s_r_cnt_rx_corrupt_ecpriv_upper						: std_logic_vector(31 downto 0);
    signal s_r_cnt_rx_corrupt_ecpriv_lower						: std_logic_vector(31 downto 0);
    signal s_r_cnt_rx_corrupt_pcid_upper						: std_logic_vector(31 downto 0);
    signal s_r_cnt_rx_corrupt_pcid_lower						: std_logic_vector(31 downto 0);
    signal s_r_cnt_rx_corrupt_payloadv_upper					: std_logic_vector(31 downto 0);
    signal s_r_cnt_rx_corrupt_payloadv_lower					: std_logic_vector(31 downto 0);

    signal dl_cp_rx_on_time0_upper_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_on_time0_lower_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_on_time0_upper_r: std_logic_vector(31 downto 0);
    signal dl_cp_rx_on_time0_lower_r: std_logic_vector(31 downto 0);
    signal dl_cp_rx_on_time1_upper_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_on_time1_lower_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_on_time1_upper_r: std_logic_vector(31 downto 0);
    signal dl_cp_rx_on_time1_lower_r: std_logic_vector(31 downto 0);
    signal dl_cp_rx_on_time2_upper_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_on_time2_lower_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_on_time2_upper_r: std_logic_vector(31 downto 0);
    signal dl_cp_rx_on_time2_lower_r: std_logic_vector(31 downto 0);
    signal dl_cp_rx_on_time3_upper_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_on_time3_lower_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_on_time3_upper_r: std_logic_vector(31 downto 0);
    signal dl_cp_rx_on_time3_lower_r: std_logic_vector(31 downto 0);
    signal dl_cp_rx_on_time4_upper_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_on_time4_lower_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_on_time4_upper_r: std_logic_vector(31 downto 0);
    signal dl_cp_rx_on_time4_lower_r: std_logic_vector(31 downto 0);
    signal dl_cp_rx_early0_upper_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_early0_lower_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_early0_upper_r  : std_logic_vector(31 downto 0);
    signal dl_cp_rx_early0_lower_r  : std_logic_vector(31 downto 0);
    signal dl_cp_rx_early1_upper_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_early1_lower_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_early1_upper_r  : std_logic_vector(31 downto 0);
    signal dl_cp_rx_early1_lower_r  : std_logic_vector(31 downto 0);
    signal dl_cp_rx_early2_upper_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_early2_lower_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_early2_upper_r  : std_logic_vector(31 downto 0);
    signal dl_cp_rx_early2_lower_r  : std_logic_vector(31 downto 0);
    signal dl_cp_rx_early3_upper_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_early3_lower_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_early3_upper_r  : std_logic_vector(31 downto 0);
    signal dl_cp_rx_early3_lower_r  : std_logic_vector(31 downto 0);
    signal dl_cp_rx_early4_upper_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_early4_lower_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_early4_upper_r  : std_logic_vector(31 downto 0);
    signal dl_cp_rx_early4_lower_r  : std_logic_vector(31 downto 0);
    signal dl_cp_rx_late0_upper_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_late0_lower_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_late0_upper_r   : std_logic_vector(31 downto 0);
    signal dl_cp_rx_late0_lower_r   : std_logic_vector(31 downto 0);
    signal dl_cp_rx_late1_upper_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_late1_lower_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_late1_upper_r   : std_logic_vector(31 downto 0);
    signal dl_cp_rx_late1_lower_r   : std_logic_vector(31 downto 0);
    signal dl_cp_rx_late2_upper_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_late2_lower_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_late2_upper_r   : std_logic_vector(31 downto 0);
    signal dl_cp_rx_late2_lower_r   : std_logic_vector(31 downto 0);
    signal dl_cp_rx_late3_upper_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_late3_lower_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_late3_upper_r   : std_logic_vector(31 downto 0);
    signal dl_cp_rx_late3_lower_r   : std_logic_vector(31 downto 0);
    signal dl_cp_rx_late4_upper_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_late4_lower_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_late4_upper_r   : std_logic_vector(31 downto 0);
    signal dl_cp_rx_late4_lower_r   : std_logic_vector(31 downto 0);
    signal dl_cp_rx_ndm0_upper_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_ndm0_lower_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_ndm0_upper_r    : std_logic_vector(31 downto 0);
    signal dl_cp_rx_ndm0_lower_r    : std_logic_vector(31 downto 0);
    signal dl_cp_rx_ndm1_upper_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_ndm1_lower_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_ndm1_upper_r    : std_logic_vector(31 downto 0);
    signal dl_cp_rx_ndm1_lower_r    : std_logic_vector(31 downto 0);
    signal dl_cp_rx_ndm2_upper_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_ndm2_lower_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_ndm2_upper_r    : std_logic_vector(31 downto 0);
    signal dl_cp_rx_ndm2_lower_r    : std_logic_vector(31 downto 0);
    signal dl_cp_rx_ndm3_upper_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_ndm3_lower_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_ndm3_upper_r    : std_logic_vector(31 downto 0);
    signal dl_cp_rx_ndm3_lower_r    : std_logic_vector(31 downto 0);
    signal dl_cp_rx_ndm4_upper_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_ndm4_lower_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_cp_rx_ndm4_upper_r    : std_logic_vector(31 downto 0);
    signal dl_cp_rx_ndm4_lower_r    : std_logic_vector(31 downto 0);

    signal dl_up_rx_on_time0_upper_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_on_time0_lower_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_on_time0_upper_r: std_logic_vector(31 downto 0);
    signal dl_up_rx_on_time0_lower_r: std_logic_vector(31 downto 0);
    signal dl_up_rx_on_time1_upper_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_on_time1_lower_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_on_time1_upper_r: std_logic_vector(31 downto 0);
    signal dl_up_rx_on_time1_lower_r: std_logic_vector(31 downto 0);
    signal dl_up_rx_on_time2_upper_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_on_time2_lower_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_on_time2_upper_r: std_logic_vector(31 downto 0);
    signal dl_up_rx_on_time2_lower_r: std_logic_vector(31 downto 0);
    signal dl_up_rx_on_time3_upper_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_on_time3_lower_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_on_time3_upper_r: std_logic_vector(31 downto 0);
    signal dl_up_rx_on_time3_lower_r: std_logic_vector(31 downto 0);
    signal dl_up_rx_on_time4_upper_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_on_time4_lower_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_on_time4_upper_r: std_logic_vector(31 downto 0);
    signal dl_up_rx_on_time4_lower_r: std_logic_vector(31 downto 0);
    signal dl_up_rx_early0_upper_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_early0_lower_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_early0_upper_r  : std_logic_vector(31 downto 0);
    signal dl_up_rx_early0_lower_r  : std_logic_vector(31 downto 0);
    signal dl_up_rx_early1_upper_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_early1_lower_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_early1_upper_r  : std_logic_vector(31 downto 0);
    signal dl_up_rx_early1_lower_r  : std_logic_vector(31 downto 0);
    signal dl_up_rx_early2_upper_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_early2_lower_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_early2_upper_r  : std_logic_vector(31 downto 0);
    signal dl_up_rx_early2_lower_r  : std_logic_vector(31 downto 0);
    signal dl_up_rx_early3_upper_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_early3_lower_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_early3_upper_r  : std_logic_vector(31 downto 0);
    signal dl_up_rx_early3_lower_r  : std_logic_vector(31 downto 0);
    signal dl_up_rx_early4_upper_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_early4_lower_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_early4_upper_r  : std_logic_vector(31 downto 0);
    signal dl_up_rx_early4_lower_r  : std_logic_vector(31 downto 0);
    signal dl_up_rx_late0_upper_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_late0_lower_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_late0_upper_r   : std_logic_vector(31 downto 0);
    signal dl_up_rx_late0_lower_r   : std_logic_vector(31 downto 0);
    signal dl_up_rx_late1_upper_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_late1_lower_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_late1_upper_r   : std_logic_vector(31 downto 0);
    signal dl_up_rx_late1_lower_r   : std_logic_vector(31 downto 0);
    signal dl_up_rx_late2_upper_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_late2_lower_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_late2_upper_r   : std_logic_vector(31 downto 0);
    signal dl_up_rx_late2_lower_r   : std_logic_vector(31 downto 0);
    signal dl_up_rx_late3_upper_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_late3_lower_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_late3_upper_r   : std_logic_vector(31 downto 0);
    signal dl_up_rx_late3_lower_r   : std_logic_vector(31 downto 0);
    signal dl_up_rx_late4_upper_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_late4_lower_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_late4_upper_r   : std_logic_vector(31 downto 0);
    signal dl_up_rx_late4_lower_r   : std_logic_vector(31 downto 0);
    signal dl_up_rx_ndm0_upper_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_ndm0_lower_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_ndm0_upper_r    : std_logic_vector(31 downto 0);
    signal dl_up_rx_ndm0_lower_r    : std_logic_vector(31 downto 0);
    signal dl_up_rx_ndm1_upper_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_ndm1_lower_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_ndm1_upper_r    : std_logic_vector(31 downto 0);
    signal dl_up_rx_ndm1_lower_r    : std_logic_vector(31 downto 0);
    signal dl_up_rx_ndm2_upper_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_ndm2_lower_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_ndm2_upper_r    : std_logic_vector(31 downto 0);
    signal dl_up_rx_ndm2_lower_r    : std_logic_vector(31 downto 0);
    signal dl_up_rx_ndm3_upper_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_ndm3_lower_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_ndm3_upper_r    : std_logic_vector(31 downto 0);
    signal dl_up_rx_ndm3_lower_r    : std_logic_vector(31 downto 0);
    signal dl_up_rx_ndm4_upper_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_ndm4_lower_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal dl_up_rx_ndm4_upper_r    : std_logic_vector(31 downto 0);
    signal dl_up_rx_ndm4_lower_r    : std_logic_vector(31 downto 0);

    signal ul_cp_rx_on_time0_upper_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_on_time0_lower_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_on_time0_upper_r: std_logic_vector(31 downto 0);
    signal ul_cp_rx_on_time0_lower_r: std_logic_vector(31 downto 0);
    signal ul_cp_rx_on_time1_upper_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_on_time1_lower_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_on_time1_upper_r: std_logic_vector(31 downto 0);
    signal ul_cp_rx_on_time1_lower_r: std_logic_vector(31 downto 0);
    signal ul_cp_rx_on_time2_upper_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_on_time2_lower_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_on_time2_upper_r: std_logic_vector(31 downto 0);
    signal ul_cp_rx_on_time2_lower_r: std_logic_vector(31 downto 0);
    signal ul_cp_rx_on_time3_upper_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_on_time3_lower_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_on_time3_upper_r: std_logic_vector(31 downto 0);
    signal ul_cp_rx_on_time3_lower_r: std_logic_vector(31 downto 0);
    signal ul_cp_rx_on_time4_upper_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_on_time4_lower_w: std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_on_time4_upper_r: std_logic_vector(31 downto 0);
    signal ul_cp_rx_on_time4_lower_r: std_logic_vector(31 downto 0);
    signal ul_cp_rx_early0_upper_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_early0_lower_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_early0_upper_r  : std_logic_vector(31 downto 0);
    signal ul_cp_rx_early0_lower_r  : std_logic_vector(31 downto 0);
    signal ul_cp_rx_early1_upper_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_early1_lower_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_early1_upper_r  : std_logic_vector(31 downto 0);
    signal ul_cp_rx_early1_lower_r  : std_logic_vector(31 downto 0);
    signal ul_cp_rx_early2_upper_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_early2_lower_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_early2_upper_r  : std_logic_vector(31 downto 0);
    signal ul_cp_rx_early2_lower_r  : std_logic_vector(31 downto 0);
    signal ul_cp_rx_early3_upper_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_early3_lower_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_early3_upper_r  : std_logic_vector(31 downto 0);
    signal ul_cp_rx_early3_lower_r  : std_logic_vector(31 downto 0);
    signal ul_cp_rx_early4_upper_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_early4_lower_w  : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_early4_upper_r  : std_logic_vector(31 downto 0);
    signal ul_cp_rx_early4_lower_r  : std_logic_vector(31 downto 0);
    signal ul_cp_rx_late0_upper_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_late0_lower_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_late0_upper_r   : std_logic_vector(31 downto 0);
    signal ul_cp_rx_late0_lower_r   : std_logic_vector(31 downto 0);
    signal ul_cp_rx_late1_upper_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_late1_lower_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_late1_upper_r   : std_logic_vector(31 downto 0);
    signal ul_cp_rx_late1_lower_r   : std_logic_vector(31 downto 0);
    signal ul_cp_rx_late2_upper_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_late2_lower_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_late2_upper_r   : std_logic_vector(31 downto 0);
    signal ul_cp_rx_late2_lower_r   : std_logic_vector(31 downto 0);
    signal ul_cp_rx_late3_upper_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_late3_lower_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_late3_upper_r   : std_logic_vector(31 downto 0);
    signal ul_cp_rx_late3_lower_r   : std_logic_vector(31 downto 0);
    signal ul_cp_rx_late4_upper_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_late4_lower_w   : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_late4_upper_r   : std_logic_vector(31 downto 0);
    signal ul_cp_rx_late4_lower_r   : std_logic_vector(31 downto 0);
    signal ul_cp_rx_ndm0_upper_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_ndm0_lower_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_ndm0_upper_r    : std_logic_vector(31 downto 0);
    signal ul_cp_rx_ndm0_lower_r    : std_logic_vector(31 downto 0);
    signal ul_cp_rx_ndm1_upper_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_ndm1_lower_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_ndm1_upper_r    : std_logic_vector(31 downto 0);
    signal ul_cp_rx_ndm1_lower_r    : std_logic_vector(31 downto 0);
    signal ul_cp_rx_ndm2_upper_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_ndm2_lower_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_ndm2_upper_r    : std_logic_vector(31 downto 0);
    signal ul_cp_rx_ndm2_lower_r    : std_logic_vector(31 downto 0);
    signal ul_cp_rx_ndm3_upper_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_ndm3_lower_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_ndm3_upper_r    : std_logic_vector(31 downto 0);
    signal ul_cp_rx_ndm3_lower_r    : std_logic_vector(31 downto 0);
    signal ul_cp_rx_ndm4_upper_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_ndm4_lower_w    : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_cp_rx_ndm4_upper_r    : std_logic_vector(31 downto 0);
    signal ul_cp_rx_ndm4_lower_r    : std_logic_vector(31 downto 0);

    signal ul_up_tx_upper_w         : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_up_tx_lower_w         : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal ul_up_tx_upper_r         : std_logic_vector(31 downto 0);
    signal ul_up_tx_lower_r         : std_logic_vector(31 downto 0);

    signal rx_pe_valid_r            : std_logic_array32(7 downto 0);
    signal rx_invalid_dst_mac_r     : std_logic_array32(7 downto 0);
    signal rx_invalid_src_mac_r     : std_logic_array32(7 downto 0);
    signal rx_invalid_vlan_vid_r    : std_logic_array32(7 downto 0);
    signal rx_discontinue_r         : std_logic_array32(7 downto 0);
    signal rx_byte_size_r           : std_logic_array32(7 downto 0);
    signal rx_byte_align_r          : std_logic_array32(7 downto 0);

    signal rx_dl_cp_position_r      : std_logic_array64(7 downto 0);
    signal rx_dl_cp_position_f      : std_logic_array64(7 downto 0);
    signal rx_dl_up_position_r      : std_logic_array64(7 downto 0);
    signal rx_dl_up_position_f      : std_logic_array64(7 downto 0);
    signal rx_ul_cp_position_r      : std_logic_array64(7 downto 0);
    signal rx_ul_cp_position_f      : std_logic_array64(7 downto 0);

    signal usage_rx_cp_buffer_r     : std_logic_array32(7 downto 0);
    signal usage_rx_cp_buffer_f     : std_logic_array32(7 downto 0);
    signal usage_rx_up_buffer_r     : std_logic_array32(7 downto 0);
    signal usage_rx_up_buffer_f     : std_logic_array32(7 downto 0);

    signal cnt_rx_cp_r              : std_logic_array32(7 downto 0);
    signal cnt_rx_up_r              : std_logic_array32(7 downto 0);
    signal cnt_rx_cp_lost_r         : std_logic_array32(7 downto 0);
    signal cnt_rx_up_lost_r         : std_logic_array32(7 downto 0);

    signal usage_tx0_up_buffer_r    : std_logic_array32(7 downto 0);
    signal usage_tx0_up_buffer_f    : std_logic_array32(7 downto 0);
    signal usage_tx1_up_buffer_r    : std_logic_array32(7 downto 0);
    signal usage_tx1_up_buffer_f    : std_logic_array32(7 downto 0);
    signal usage_tx2_up_buffer_r    : std_logic_array32(7 downto 0);
    signal usage_tx2_up_buffer_f    : std_logic_array32(7 downto 0);
    signal usage_tx3_up_buffer_r    : std_logic_array32(7 downto 0);
    signal usage_tx3_up_buffer_f    : std_logic_array32(7 downto 0);
    signal usage_tx4_up_buffer_r    : std_logic_array32(7 downto 0);
    signal usage_tx4_up_buffer_f    : std_logic_array32(7 downto 0);
--    signal usage_tx5_up_buffer_r    : std_logic_array32(7 downto 0);
--    signal usage_tx5_up_buffer_f    : std_logic_array32(7 downto 0);

    signal cnt_tx0_r                : std_logic_array32(7 downto 0);
    signal cnt_tx1_r                : std_logic_array32(7 downto 0);
    signal cnt_tx2_r                : std_logic_array32(7 downto 0);
    signal cnt_tx3_r                : std_logic_array32(7 downto 0);
    signal cnt_tx4_r                : std_logic_array32(7 downto 0);
--    signal cnt_tx5_r                : std_logic_array32(7 downto 0);
    signal cnt_tx0_lost_r           : std_logic_array32(7 downto 0);
    signal cnt_tx1_lost_r           : std_logic_array32(7 downto 0);
    signal cnt_tx2_lost_r           : std_logic_array32(7 downto 0);
    signal cnt_tx3_lost_r           : std_logic_array32(7 downto 0);
    signal cnt_tx4_lost_r           : std_logic_array32(7 downto 0);
--    signal cnt_tx5_lost_r           : std_logic_array32(7 downto 0);

    signal det_dl_cp0_fault_id_31_r : std_logic_array64(7 downto 0);
    signal det_dl_cp0_fault_id_31_f : std_logic_array64(7 downto 0);
    signal det_dl_cp1_fault_id_31_r : std_logic_array64(7 downto 0);
    signal det_dl_cp1_fault_id_31_f : std_logic_array64(7 downto 0);
    signal det_dl_cp2_fault_id_31_r : std_logic_array64(7 downto 0);
    signal det_dl_cp2_fault_id_31_f : std_logic_array64(7 downto 0);
    signal det_dl_cp3_fault_id_31_r : std_logic_array64(7 downto 0);
    signal det_dl_cp3_fault_id_31_f : std_logic_array64(7 downto 0);
    signal det_dl_cp4_fault_id_31_r : std_logic_array64(7 downto 0);
    signal det_dl_cp4_fault_id_31_f : std_logic_array64(7 downto 0);
    signal det_dl_cp5_fault_id_31_r : std_logic_array64(7 downto 0);
    signal det_dl_cp5_fault_id_31_f : std_logic_array64(7 downto 0);
    signal det_dl_cp6_fault_id_31_r : std_logic_array64(7 downto 0);
    signal det_dl_cp6_fault_id_31_f : std_logic_array64(7 downto 0);
    signal det_dl_cp7_fault_id_31_r : std_logic_array64(7 downto 0);
    signal det_dl_cp7_fault_id_31_f : std_logic_array64(7 downto 0);
    signal det_ul_cp0_fault_id_31_r : std_logic_array64(7 downto 0);
    signal det_ul_cp0_fault_id_31_f : std_logic_array64(7 downto 0);
    signal det_ul_cp1_fault_id_31_r : std_logic_array64(7 downto 0);
    signal det_ul_cp1_fault_id_31_f : std_logic_array64(7 downto 0);
    signal det_ul_cp2_fault_id_31_r : std_logic_array64(7 downto 0);
    signal det_ul_cp2_fault_id_31_f : std_logic_array64(7 downto 0);
    signal det_ul_cp3_fault_id_31_r : std_logic_array64(7 downto 0);
    signal det_ul_cp3_fault_id_31_f : std_logic_array64(7 downto 0);
    signal det_ul_cp4_fault_id_31_r : std_logic_array64(7 downto 0);
    signal det_ul_cp4_fault_id_31_f : std_logic_array64(7 downto 0);
    signal det_ul_cp5_fault_id_31_r : std_logic_array64(7 downto 0);
    signal det_ul_cp5_fault_id_31_f : std_logic_array64(7 downto 0);
    signal det_ul_cp6_fault_id_31_r : std_logic_array64(7 downto 0);
    signal det_ul_cp6_fault_id_31_f : std_logic_array64(7 downto 0);
    signal det_ul_cp7_fault_id_31_r : std_logic_array64(7 downto 0);
    signal det_ul_cp7_fault_id_31_f : std_logic_array64(7 downto 0);

    signal tx0_sts_cq_fsm_r         : std_logic_array32(7 downto 0);
    signal tx0_sts_cq_fsm_f         : std_logic_array32(7 downto 0);
    signal tx0_cnt_cq_fsm_busy_r    : std_logic_array32(7 downto 0);
    signal tx0_cnt_cq_conv_full_r   : std_logic_array32(7 downto 0);
    signal tx0_frame_id_r           : std_logic_array32(7 downto 0);
    signal tx0_cnt_cpsec_sym0_r     : std_logic_array32(7 downto 0);
    signal tx0_cnt_cpsec_sym1_r     : std_logic_array32(7 downto 0);
    signal tx0_cnt_cpsec_sym2_r     : std_logic_array32(7 downto 0);
    signal tx0_cnt_cpsec_sym3_r     : std_logic_array32(7 downto 0);
    signal tx0_cnt_cpsec_sym4_r     : std_logic_array32(7 downto 0);
    signal tx0_cnt_cpsec_sym5_r     : std_logic_array32(7 downto 0);
    signal tx0_cnt_cpsec_sym6_r     : std_logic_array32(7 downto 0);
    signal tx0_cnt_cpsec_sym7_r     : std_logic_array32(7 downto 0);
    signal tx0_cnt_cpsec_sym8_r     : std_logic_array32(7 downto 0);
    signal tx0_cnt_cpsec_sym9_r     : std_logic_array32(7 downto 0);
    signal tx0_cnt_cpsec_sym10_r    : std_logic_array32(7 downto 0);
    signal tx0_cnt_cpsec_sym11_r    : std_logic_array32(7 downto 0);
    signal tx0_cnt_cpsec_sym12_r    : std_logic_array32(7 downto 0);
    signal tx0_cnt_cpsec_sym13_r    : std_logic_array32(7 downto 0);
    signal tx0_cnt_uppkt_sym0_r     : std_logic_array32(7 downto 0);
    signal tx0_cnt_uppkt_sym1_r     : std_logic_array32(7 downto 0);
    signal tx0_cnt_uppkt_sym2_r     : std_logic_array32(7 downto 0);
    signal tx0_cnt_uppkt_sym3_r     : std_logic_array32(7 downto 0);
    signal tx0_cnt_uppkt_sym4_r     : std_logic_array32(7 downto 0);
    signal tx0_cnt_uppkt_sym5_r     : std_logic_array32(7 downto 0);
    signal tx0_cnt_uppkt_sym6_r     : std_logic_array32(7 downto 0);
    signal tx0_cnt_uppkt_sym7_r     : std_logic_array32(7 downto 0);
    signal tx0_cnt_uppkt_sym8_r     : std_logic_array32(7 downto 0);
    signal tx0_cnt_uppkt_sym9_r     : std_logic_array32(7 downto 0);
    signal tx0_cnt_uppkt_sym10_r    : std_logic_array32(7 downto 0);
    signal tx0_cnt_uppkt_sym11_r    : std_logic_array32(7 downto 0);
    signal tx0_cnt_uppkt_sym12_r    : std_logic_array32(7 downto 0);
    signal tx0_cnt_uppkt_sym13_r    : std_logic_array32(7 downto 0);
    signal tx0_cnt_cq_full_sym0_r   : std_logic_array32(7 downto 0);
    signal tx0_cnt_cq_full_sym1_r   : std_logic_array32(7 downto 0);
    signal tx0_cnt_cq_full_sym2_r   : std_logic_array32(7 downto 0);
    signal tx0_cnt_cq_full_sym3_r   : std_logic_array32(7 downto 0);
    signal tx0_cnt_cq_full_sym4_r   : std_logic_array32(7 downto 0);
    signal tx0_cnt_cq_full_sym5_r   : std_logic_array32(7 downto 0);
    signal tx0_cnt_cq_full_sym6_r   : std_logic_array32(7 downto 0);
    signal tx0_cnt_cq_full_sym7_r   : std_logic_array32(7 downto 0);
    signal tx0_cnt_cq_full_sym8_r   : std_logic_array32(7 downto 0);
    signal tx0_cnt_cq_full_sym9_r   : std_logic_array32(7 downto 0);
    signal tx0_cnt_cq_full_sym10_r  : std_logic_array32(7 downto 0);
    signal tx0_cnt_cq_full_sym11_r  : std_logic_array32(7 downto 0);
    signal tx0_cnt_cq_full_sym12_r  : std_logic_array32(7 downto 0);
    signal tx0_cnt_cq_full_sym13_r  : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym0_r      : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym0_f      : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym1_r      : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym1_f      : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym2_r      : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym2_f      : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym3_r      : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym3_f      : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym4_r      : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym4_f      : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym5_r      : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym5_f      : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym6_r      : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym6_f      : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym7_r      : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym7_f      : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym8_r      : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym8_f      : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym9_r      : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym9_f      : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym10_r     : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym10_f     : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym11_r     : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym11_f     : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym12_r     : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym12_f     : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym13_r     : std_logic_array32(7 downto 0);
    signal tx0_usage_cq_sym13_f     : std_logic_array32(7 downto 0);

    signal tx1_sts_cq_fsm_r         : std_logic_array32(7 downto 0);
    signal tx1_sts_cq_fsm_f         : std_logic_array32(7 downto 0);
    signal tx1_cnt_cq_fsm_busy_r    : std_logic_array32(7 downto 0);
    signal tx1_cnt_cq_conv_full_r   : std_logic_array32(7 downto 0);
    signal tx1_frame_id_r           : std_logic_array32(7 downto 0);
    signal tx1_cnt_cpsec_sym0_r     : std_logic_array32(7 downto 0);
    signal tx1_cnt_cpsec_sym1_r     : std_logic_array32(7 downto 0);
    signal tx1_cnt_cpsec_sym2_r     : std_logic_array32(7 downto 0);
    signal tx1_cnt_cpsec_sym3_r     : std_logic_array32(7 downto 0);
    signal tx1_cnt_cpsec_sym4_r     : std_logic_array32(7 downto 0);
    signal tx1_cnt_cpsec_sym5_r     : std_logic_array32(7 downto 0);
    signal tx1_cnt_cpsec_sym6_r     : std_logic_array32(7 downto 0);
    signal tx1_cnt_cpsec_sym7_r     : std_logic_array32(7 downto 0);
    signal tx1_cnt_cpsec_sym8_r     : std_logic_array32(7 downto 0);
    signal tx1_cnt_cpsec_sym9_r     : std_logic_array32(7 downto 0);
    signal tx1_cnt_cpsec_sym10_r    : std_logic_array32(7 downto 0);
    signal tx1_cnt_cpsec_sym11_r    : std_logic_array32(7 downto 0);
    signal tx1_cnt_cpsec_sym12_r    : std_logic_array32(7 downto 0);
    signal tx1_cnt_cpsec_sym13_r    : std_logic_array32(7 downto 0);
    signal tx1_cnt_uppkt_sym0_r     : std_logic_array32(7 downto 0);
    signal tx1_cnt_uppkt_sym1_r     : std_logic_array32(7 downto 0);
    signal tx1_cnt_uppkt_sym2_r     : std_logic_array32(7 downto 0);
    signal tx1_cnt_uppkt_sym3_r     : std_logic_array32(7 downto 0);
    signal tx1_cnt_uppkt_sym4_r     : std_logic_array32(7 downto 0);
    signal tx1_cnt_uppkt_sym5_r     : std_logic_array32(7 downto 0);
    signal tx1_cnt_uppkt_sym6_r     : std_logic_array32(7 downto 0);
    signal tx1_cnt_uppkt_sym7_r     : std_logic_array32(7 downto 0);
    signal tx1_cnt_uppkt_sym8_r     : std_logic_array32(7 downto 0);
    signal tx1_cnt_uppkt_sym9_r     : std_logic_array32(7 downto 0);
    signal tx1_cnt_uppkt_sym10_r    : std_logic_array32(7 downto 0);
    signal tx1_cnt_uppkt_sym11_r    : std_logic_array32(7 downto 0);
    signal tx1_cnt_uppkt_sym12_r    : std_logic_array32(7 downto 0);
    signal tx1_cnt_uppkt_sym13_r    : std_logic_array32(7 downto 0);
    signal tx1_cnt_cq_full_sym0_r   : std_logic_array32(7 downto 0);
    signal tx1_cnt_cq_full_sym1_r   : std_logic_array32(7 downto 0);
    signal tx1_cnt_cq_full_sym2_r   : std_logic_array32(7 downto 0);
    signal tx1_cnt_cq_full_sym3_r   : std_logic_array32(7 downto 0);
    signal tx1_cnt_cq_full_sym4_r   : std_logic_array32(7 downto 0);
    signal tx1_cnt_cq_full_sym5_r   : std_logic_array32(7 downto 0);
    signal tx1_cnt_cq_full_sym6_r   : std_logic_array32(7 downto 0);
    signal tx1_cnt_cq_full_sym7_r   : std_logic_array32(7 downto 0);
    signal tx1_cnt_cq_full_sym8_r   : std_logic_array32(7 downto 0);
    signal tx1_cnt_cq_full_sym9_r   : std_logic_array32(7 downto 0);
    signal tx1_cnt_cq_full_sym10_r  : std_logic_array32(7 downto 0);
    signal tx1_cnt_cq_full_sym11_r  : std_logic_array32(7 downto 0);
    signal tx1_cnt_cq_full_sym12_r  : std_logic_array32(7 downto 0);
    signal tx1_cnt_cq_full_sym13_r  : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym0_r      : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym0_f      : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym1_r      : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym1_f      : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym2_r      : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym2_f      : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym3_r      : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym3_f      : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym4_r      : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym4_f      : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym5_r      : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym5_f      : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym6_r      : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym6_f      : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym7_r      : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym7_f      : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym8_r      : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym8_f      : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym9_r      : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym9_f      : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym10_r     : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym10_f     : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym11_r     : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym11_f     : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym12_r     : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym12_f     : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym13_r     : std_logic_array32(7 downto 0);
    signal tx1_usage_cq_sym13_f     : std_logic_array32(7 downto 0);

    signal tx2_sts_cq_fsm_r         : std_logic_array32(7 downto 0);
    signal tx2_sts_cq_fsm_f         : std_logic_array32(7 downto 0);
    signal tx2_cnt_cq_fsm_busy_r    : std_logic_array32(7 downto 0);
    signal tx2_cnt_cq_conv_full_r   : std_logic_array32(7 downto 0);
    signal tx2_frame_id_r           : std_logic_array32(7 downto 0);
    signal tx2_cnt_cpsec_sym0_r     : std_logic_array32(7 downto 0);
    signal tx2_cnt_cpsec_sym1_r     : std_logic_array32(7 downto 0);
    signal tx2_cnt_cpsec_sym2_r     : std_logic_array32(7 downto 0);
    signal tx2_cnt_cpsec_sym3_r     : std_logic_array32(7 downto 0);
    signal tx2_cnt_cpsec_sym4_r     : std_logic_array32(7 downto 0);
    signal tx2_cnt_cpsec_sym5_r     : std_logic_array32(7 downto 0);
    signal tx2_cnt_cpsec_sym6_r     : std_logic_array32(7 downto 0);
    signal tx2_cnt_cpsec_sym7_r     : std_logic_array32(7 downto 0);
    signal tx2_cnt_cpsec_sym8_r     : std_logic_array32(7 downto 0);
    signal tx2_cnt_cpsec_sym9_r     : std_logic_array32(7 downto 0);
    signal tx2_cnt_cpsec_sym10_r    : std_logic_array32(7 downto 0);
    signal tx2_cnt_cpsec_sym11_r    : std_logic_array32(7 downto 0);
    signal tx2_cnt_cpsec_sym12_r    : std_logic_array32(7 downto 0);
    signal tx2_cnt_cpsec_sym13_r    : std_logic_array32(7 downto 0);
    signal tx2_cnt_uppkt_sym0_r     : std_logic_array32(7 downto 0);
    signal tx2_cnt_uppkt_sym1_r     : std_logic_array32(7 downto 0);
    signal tx2_cnt_uppkt_sym2_r     : std_logic_array32(7 downto 0);
    signal tx2_cnt_uppkt_sym3_r     : std_logic_array32(7 downto 0);
    signal tx2_cnt_uppkt_sym4_r     : std_logic_array32(7 downto 0);
    signal tx2_cnt_uppkt_sym5_r     : std_logic_array32(7 downto 0);
    signal tx2_cnt_uppkt_sym6_r     : std_logic_array32(7 downto 0);
    signal tx2_cnt_uppkt_sym7_r     : std_logic_array32(7 downto 0);
    signal tx2_cnt_uppkt_sym8_r     : std_logic_array32(7 downto 0);
    signal tx2_cnt_uppkt_sym9_r     : std_logic_array32(7 downto 0);
    signal tx2_cnt_uppkt_sym10_r    : std_logic_array32(7 downto 0);
    signal tx2_cnt_uppkt_sym11_r    : std_logic_array32(7 downto 0);
    signal tx2_cnt_uppkt_sym12_r    : std_logic_array32(7 downto 0);
    signal tx2_cnt_uppkt_sym13_r    : std_logic_array32(7 downto 0);
    signal tx2_cnt_cq_full_sym0_r   : std_logic_array32(7 downto 0);
    signal tx2_cnt_cq_full_sym1_r   : std_logic_array32(7 downto 0);
    signal tx2_cnt_cq_full_sym2_r   : std_logic_array32(7 downto 0);
    signal tx2_cnt_cq_full_sym3_r   : std_logic_array32(7 downto 0);
    signal tx2_cnt_cq_full_sym4_r   : std_logic_array32(7 downto 0);
    signal tx2_cnt_cq_full_sym5_r   : std_logic_array32(7 downto 0);
    signal tx2_cnt_cq_full_sym6_r   : std_logic_array32(7 downto 0);
    signal tx2_cnt_cq_full_sym7_r   : std_logic_array32(7 downto 0);
    signal tx2_cnt_cq_full_sym8_r   : std_logic_array32(7 downto 0);
    signal tx2_cnt_cq_full_sym9_r   : std_logic_array32(7 downto 0);
    signal tx2_cnt_cq_full_sym10_r  : std_logic_array32(7 downto 0);
    signal tx2_cnt_cq_full_sym11_r  : std_logic_array32(7 downto 0);
    signal tx2_cnt_cq_full_sym12_r  : std_logic_array32(7 downto 0);
    signal tx2_cnt_cq_full_sym13_r  : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym0_r      : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym0_f      : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym1_r      : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym1_f      : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym2_r      : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym2_f      : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym3_r      : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym3_f      : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym4_r      : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym4_f      : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym5_r      : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym5_f      : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym6_r      : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym6_f      : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym7_r      : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym7_f      : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym8_r      : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym8_f      : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym9_r      : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym9_f      : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym10_r     : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym10_f     : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym11_r     : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym11_f     : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym12_r     : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym12_f     : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym13_r     : std_logic_array32(7 downto 0);
    signal tx2_usage_cq_sym13_f     : std_logic_array32(7 downto 0);

    signal tx3_sts_cq_fsm_r         : std_logic_array32(7 downto 0);
    signal tx3_sts_cq_fsm_f         : std_logic_array32(7 downto 0);
    signal tx3_cnt_cq_fsm_busy_r    : std_logic_array32(7 downto 0);
    signal tx3_cnt_cq_conv_full_r   : std_logic_array32(7 downto 0);
    signal tx3_frame_id_r           : std_logic_array32(7 downto 0);
    signal tx3_cnt_cpsec_sym0_r     : std_logic_array32(7 downto 0);
    signal tx3_cnt_cpsec_sym1_r     : std_logic_array32(7 downto 0);
    signal tx3_cnt_cpsec_sym2_r     : std_logic_array32(7 downto 0);
    signal tx3_cnt_cpsec_sym3_r     : std_logic_array32(7 downto 0);
    signal tx3_cnt_cpsec_sym4_r     : std_logic_array32(7 downto 0);
    signal tx3_cnt_cpsec_sym5_r     : std_logic_array32(7 downto 0);
    signal tx3_cnt_cpsec_sym6_r     : std_logic_array32(7 downto 0);
    signal tx3_cnt_cpsec_sym7_r     : std_logic_array32(7 downto 0);
    signal tx3_cnt_cpsec_sym8_r     : std_logic_array32(7 downto 0);
    signal tx3_cnt_cpsec_sym9_r     : std_logic_array32(7 downto 0);
    signal tx3_cnt_cpsec_sym10_r    : std_logic_array32(7 downto 0);
    signal tx3_cnt_cpsec_sym11_r    : std_logic_array32(7 downto 0);
    signal tx3_cnt_cpsec_sym12_r    : std_logic_array32(7 downto 0);
    signal tx3_cnt_cpsec_sym13_r    : std_logic_array32(7 downto 0);
    signal tx3_cnt_uppkt_sym0_r     : std_logic_array32(7 downto 0);
    signal tx3_cnt_uppkt_sym1_r     : std_logic_array32(7 downto 0);
    signal tx3_cnt_uppkt_sym2_r     : std_logic_array32(7 downto 0);
    signal tx3_cnt_uppkt_sym3_r     : std_logic_array32(7 downto 0);
    signal tx3_cnt_uppkt_sym4_r     : std_logic_array32(7 downto 0);
    signal tx3_cnt_uppkt_sym5_r     : std_logic_array32(7 downto 0);
    signal tx3_cnt_uppkt_sym6_r     : std_logic_array32(7 downto 0);
    signal tx3_cnt_uppkt_sym7_r     : std_logic_array32(7 downto 0);
    signal tx3_cnt_uppkt_sym8_r     : std_logic_array32(7 downto 0);
    signal tx3_cnt_uppkt_sym9_r     : std_logic_array32(7 downto 0);
    signal tx3_cnt_uppkt_sym10_r    : std_logic_array32(7 downto 0);
    signal tx3_cnt_uppkt_sym11_r    : std_logic_array32(7 downto 0);
    signal tx3_cnt_uppkt_sym12_r    : std_logic_array32(7 downto 0);
    signal tx3_cnt_uppkt_sym13_r    : std_logic_array32(7 downto 0);
    signal tx3_cnt_cq_full_sym0_r   : std_logic_array32(7 downto 0);
    signal tx3_cnt_cq_full_sym1_r   : std_logic_array32(7 downto 0);
    signal tx3_cnt_cq_full_sym2_r   : std_logic_array32(7 downto 0);
    signal tx3_cnt_cq_full_sym3_r   : std_logic_array32(7 downto 0);
    signal tx3_cnt_cq_full_sym4_r   : std_logic_array32(7 downto 0);
    signal tx3_cnt_cq_full_sym5_r   : std_logic_array32(7 downto 0);
    signal tx3_cnt_cq_full_sym6_r   : std_logic_array32(7 downto 0);
    signal tx3_cnt_cq_full_sym7_r   : std_logic_array32(7 downto 0);
    signal tx3_cnt_cq_full_sym8_r   : std_logic_array32(7 downto 0);
    signal tx3_cnt_cq_full_sym9_r   : std_logic_array32(7 downto 0);
    signal tx3_cnt_cq_full_sym10_r  : std_logic_array32(7 downto 0);
    signal tx3_cnt_cq_full_sym11_r  : std_logic_array32(7 downto 0);
    signal tx3_cnt_cq_full_sym12_r  : std_logic_array32(7 downto 0);
    signal tx3_cnt_cq_full_sym13_r  : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym0_r      : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym0_f      : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym1_r      : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym1_f      : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym2_r      : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym2_f      : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym3_r      : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym3_f      : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym4_r      : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym4_f      : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym5_r      : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym5_f      : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym6_r      : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym6_f      : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym7_r      : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym7_f      : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym8_r      : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym8_f      : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym9_r      : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym9_f      : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym10_r     : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym10_f     : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym11_r     : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym11_f     : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym12_r     : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym12_f     : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym13_r     : std_logic_array32(7 downto 0);
    signal tx3_usage_cq_sym13_f     : std_logic_array32(7 downto 0);

    signal tx4_sts_cq_fsm_r         : std_logic_array32(7 downto 0);
    signal tx4_sts_cq_fsm_f         : std_logic_array32(7 downto 0);
    signal tx4_cnt_cq_fsm_busy_r    : std_logic_array32(7 downto 0);
    signal tx4_cnt_cq_conv_full_r   : std_logic_array32(7 downto 0);
    signal tx4_frame_id_r           : std_logic_array32(7 downto 0);
    signal tx4_cnt_cpsec_sym0_r     : std_logic_array32(7 downto 0);
    signal tx4_cnt_cpsec_sym1_r     : std_logic_array32(7 downto 0);
    signal tx4_cnt_cpsec_sym2_r     : std_logic_array32(7 downto 0);
    signal tx4_cnt_cpsec_sym3_r     : std_logic_array32(7 downto 0);
    signal tx4_cnt_cpsec_sym4_r     : std_logic_array32(7 downto 0);
    signal tx4_cnt_cpsec_sym5_r     : std_logic_array32(7 downto 0);
    signal tx4_cnt_cpsec_sym6_r     : std_logic_array32(7 downto 0);
    signal tx4_cnt_cpsec_sym7_r     : std_logic_array32(7 downto 0);
    signal tx4_cnt_cpsec_sym8_r     : std_logic_array32(7 downto 0);
    signal tx4_cnt_cpsec_sym9_r     : std_logic_array32(7 downto 0);
    signal tx4_cnt_cpsec_sym10_r    : std_logic_array32(7 downto 0);
    signal tx4_cnt_cpsec_sym11_r    : std_logic_array32(7 downto 0);
    signal tx4_cnt_cpsec_sym12_r    : std_logic_array32(7 downto 0);
    signal tx4_cnt_cpsec_sym13_r    : std_logic_array32(7 downto 0);
    signal tx4_cnt_uppkt_sym0_r     : std_logic_array32(7 downto 0);
    signal tx4_cnt_uppkt_sym1_r     : std_logic_array32(7 downto 0);
    signal tx4_cnt_uppkt_sym2_r     : std_logic_array32(7 downto 0);
    signal tx4_cnt_uppkt_sym3_r     : std_logic_array32(7 downto 0);
    signal tx4_cnt_uppkt_sym4_r     : std_logic_array32(7 downto 0);
    signal tx4_cnt_uppkt_sym5_r     : std_logic_array32(7 downto 0);
    signal tx4_cnt_uppkt_sym6_r     : std_logic_array32(7 downto 0);
    signal tx4_cnt_uppkt_sym7_r     : std_logic_array32(7 downto 0);
    signal tx4_cnt_uppkt_sym8_r     : std_logic_array32(7 downto 0);
    signal tx4_cnt_uppkt_sym9_r     : std_logic_array32(7 downto 0);
    signal tx4_cnt_uppkt_sym10_r    : std_logic_array32(7 downto 0);
    signal tx4_cnt_uppkt_sym11_r    : std_logic_array32(7 downto 0);
    signal tx4_cnt_uppkt_sym12_r    : std_logic_array32(7 downto 0);
    signal tx4_cnt_uppkt_sym13_r    : std_logic_array32(7 downto 0);
    signal tx4_cnt_cq_full_sym0_r   : std_logic_array32(7 downto 0);
    signal tx4_cnt_cq_full_sym1_r   : std_logic_array32(7 downto 0);
    signal tx4_cnt_cq_full_sym2_r   : std_logic_array32(7 downto 0);
    signal tx4_cnt_cq_full_sym3_r   : std_logic_array32(7 downto 0);
    signal tx4_cnt_cq_full_sym4_r   : std_logic_array32(7 downto 0);
    signal tx4_cnt_cq_full_sym5_r   : std_logic_array32(7 downto 0);
    signal tx4_cnt_cq_full_sym6_r   : std_logic_array32(7 downto 0);
    signal tx4_cnt_cq_full_sym7_r   : std_logic_array32(7 downto 0);
    signal tx4_cnt_cq_full_sym8_r   : std_logic_array32(7 downto 0);
    signal tx4_cnt_cq_full_sym9_r   : std_logic_array32(7 downto 0);
    signal tx4_cnt_cq_full_sym10_r  : std_logic_array32(7 downto 0);
    signal tx4_cnt_cq_full_sym11_r  : std_logic_array32(7 downto 0);
    signal tx4_cnt_cq_full_sym12_r  : std_logic_array32(7 downto 0);
    signal tx4_cnt_cq_full_sym13_r  : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym0_r      : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym0_f      : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym1_r      : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym1_f      : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym2_r      : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym2_f      : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym3_r      : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym3_f      : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym4_r      : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym4_f      : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym5_r      : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym5_f      : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym6_r      : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym6_f      : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym7_r      : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym7_f      : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym8_r      : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym8_f      : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym9_r      : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym9_f      : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym10_r     : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym10_f     : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym11_r     : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym11_f     : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym12_r     : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym12_f     : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym13_r     : std_logic_array32(7 downto 0);
    signal tx4_usage_cq_sym13_f     : std_logic_array32(7 downto 0);

--    signal tx5_sts_cq_fsm_r         : std_logic_array32(7 downto 0);
--    signal tx5_sts_cq_fsm_f         : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cq_fsm_busy_r    : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cq_conv_full_r   : std_logic_array32(7 downto 0);
--    signal tx5_frame_id_r           : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cpsec_sym0_r     : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cpsec_sym1_r     : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cpsec_sym2_r     : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cpsec_sym3_r     : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cpsec_sym4_r     : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cpsec_sym5_r     : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cpsec_sym6_r     : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cpsec_sym7_r     : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cpsec_sym8_r     : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cpsec_sym9_r     : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cpsec_sym10_r    : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cpsec_sym11_r    : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cpsec_sym12_r    : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cpsec_sym13_r    : std_logic_array32(7 downto 0);
--    signal tx5_cnt_uppkt_sym0_r     : std_logic_array32(7 downto 0);
--    signal tx5_cnt_uppkt_sym1_r     : std_logic_array32(7 downto 0);
--    signal tx5_cnt_uppkt_sym2_r     : std_logic_array32(7 downto 0);
--    signal tx5_cnt_uppkt_sym3_r     : std_logic_array32(7 downto 0);
--    signal tx5_cnt_uppkt_sym4_r     : std_logic_array32(7 downto 0);
--    signal tx5_cnt_uppkt_sym5_r     : std_logic_array32(7 downto 0);
--    signal tx5_cnt_uppkt_sym6_r     : std_logic_array32(7 downto 0);
--    signal tx5_cnt_uppkt_sym7_r     : std_logic_array32(7 downto 0);
--    signal tx5_cnt_uppkt_sym8_r     : std_logic_array32(7 downto 0);
--    signal tx5_cnt_uppkt_sym9_r     : std_logic_array32(7 downto 0);
--    signal tx5_cnt_uppkt_sym10_r    : std_logic_array32(7 downto 0);
--    signal tx5_cnt_uppkt_sym11_r    : std_logic_array32(7 downto 0);
--    signal tx5_cnt_uppkt_sym12_r    : std_logic_array32(7 downto 0);
--    signal tx5_cnt_uppkt_sym13_r    : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cq_full_sym0_r   : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cq_full_sym1_r   : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cq_full_sym2_r   : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cq_full_sym3_r   : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cq_full_sym4_r   : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cq_full_sym5_r   : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cq_full_sym6_r   : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cq_full_sym7_r   : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cq_full_sym8_r   : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cq_full_sym9_r   : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cq_full_sym10_r  : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cq_full_sym11_r  : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cq_full_sym12_r  : std_logic_array32(7 downto 0);
--    signal tx5_cnt_cq_full_sym13_r  : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym0_r      : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym0_f      : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym1_r      : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym1_f      : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym2_r      : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym2_f      : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym3_r      : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym3_f      : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym4_r      : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym4_f      : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym5_r      : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym5_f      : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym6_r      : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym6_f      : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym7_r      : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym7_f      : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym8_r      : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym8_f      : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym9_r      : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym9_f      : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym10_r     : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym10_f     : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym11_r     : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym11_f     : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym12_r     : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym12_f     : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym13_r     : std_logic_array32(7 downto 0);
--    signal tx5_usage_cq_sym13_f     : std_logic_array32(7 downto 0);

    signal clear_stat_cnt           : std_logic;

begin

--------------------------------------------------------------------------------
-- WE/OE, address decoding
--------------------------------------------------------------------------------

    addr     <= "000" & ADDR_CPUIF_IN(12 downto 0);
    addr_msb <= addr(12 downto 8);
    addr_lsb <= addr(7 downto 0);

    process (RST, CLK)
    begin
        if (RST = '1') then
            we_buf <= '0';
            oe_buf <= '0';
        elsif (CLK'event and CLK = '1') then
            we_buf <= WREN_CPUIF_IN;
            oe_buf <= RDEN_CPUIF_IN;
        end if;
    end process;

    u_WE_OE : for i in 31 downto 0 generate
    -- read/write (short pulse)
    process (RST, CLK)
    begin
        if (RST = '1') then
            we(i) <= '0';
            oe(i) <= '0';
        elsif (CLK'event and CLK = '1') then
            if (addr_msb = i) then
                if (WREN_CPUIF_IN = '1') and (we_buf = '0') then
                    we(i) <= '1';
                else
                    we(i) <= '0';
                end if;
                if (RDEN_CPUIF_IN = '1') and (oe_buf = '0') then
                    oe(i) <= '1';
                else
                    oe(i) <= '0';
                end if;
            else
                we(i) <= '0';
                oe(i) <= '0';
            end if;
        end if;
    end process;

    -- read/write (long pulse)
    process (RST, CLK)
    begin
        if (RST = '1') then
            we_long(i) <= '0';
            oe_long(i) <= '0';
        elsif (CLK'event and CLK = '1') then
            if (addr_msb = i) then
                if (WREN_CPUIF_IN = '1') then
                    we_long(i) <= '1';
                else
                    we_long(i) <= '0';
                end if;
                if (RDEN_CPUIF_IN = '1') then
                    oe_long(i) <= '1';
                else
                    oe_long(i) <= '0';
                end if;
            else
                we_long(i) <= '0';
                oe_long(i) <= '0';
            end if;
        end if;
    end process;
    end generate;

    process (RST, CLK)
    begin
        if (RST = '1') then
            read_valid <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            read_valid <= read_valid(2 downto 0) & RDEN_CPUIF_IN;
        end if;
    end process;

    process (RST, CLK)
    begin
        if (RST = '1') then
            RDVAL_CPUIF_OUT <= '0';
        elsif (CLK'event and CLK = '1') then
            if (read_valid(3 downto 2) = "01") then
                RDVAL_CPUIF_OUT <= '1';
            else
                RDVAL_CPUIF_OUT <= '0';
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Read Mux
--------------------------------------------------------------------------------

    process (RST, CLK)
    begin
        if (RST = '1') then
            RDATA_CPUIF_OUT <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            case addr_msb is
            when "00000" => RDATA_CPUIF_OUT <= read_data(0);
            when "00001" => RDATA_CPUIF_OUT <= read_data(1);
            when "00010" => RDATA_CPUIF_OUT <= read_data(2);
            when "00011" => RDATA_CPUIF_OUT <= read_data(3);
            when "00100" => RDATA_CPUIF_OUT <= read_data(4);
            when "00101" => RDATA_CPUIF_OUT <= read_data(5);
            when "00110" => RDATA_CPUIF_OUT <= read_data(6);
            when "00111" => RDATA_CPUIF_OUT <= read_data(7);
            when "01000" => RDATA_CPUIF_OUT <= read_data(8);
            when "01001" => RDATA_CPUIF_OUT <= read_data(9);
            when "01010" => RDATA_CPUIF_OUT <= read_data(10);
            when "01011" => RDATA_CPUIF_OUT <= read_data(11);
            when "01100" => RDATA_CPUIF_OUT <= read_data(12);
            when "01101" => RDATA_CPUIF_OUT <= read_data(13);
            when "01110" => RDATA_CPUIF_OUT <= read_data(14);
            when "01111" => RDATA_CPUIF_OUT <= read_data(15);
            when "10000" => RDATA_CPUIF_OUT <= read_data(16);
            when "10001" => RDATA_CPUIF_OUT <= read_data(17);
            when "10010" => RDATA_CPUIF_OUT <= read_data(18);
            when "10011" => RDATA_CPUIF_OUT <= read_data(19);
            when "10100" => RDATA_CPUIF_OUT <= read_data(20);
            when "10101" => RDATA_CPUIF_OUT <= read_data(21);
            when "10110" => RDATA_CPUIF_OUT <= read_data(22);
            when "10111" => RDATA_CPUIF_OUT <= read_data(23);
            when "11000" => RDATA_CPUIF_OUT <= read_data(24);
            when "11001" => RDATA_CPUIF_OUT <= read_data(25);
            when "11010" => RDATA_CPUIF_OUT <= read_data(26);
            when "11011" => RDATA_CPUIF_OUT <= read_data(27);
            when "11100" => RDATA_CPUIF_OUT <= read_data(28);
            when "11101" => RDATA_CPUIF_OUT <= read_data(29);
            when "11110" => RDATA_CPUIF_OUT <= read_data(30);
            when "11111" => RDATA_CPUIF_OUT <= read_data(31);
            when others  => RDATA_CPUIF_OUT <= (others => '0');
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case addr_lsb is
            when x"00"  => read_data(0) <= EXT(set_dl_data_type_w, 32);
            when x"01"  => read_data(0) <= max_dl_index_r;
            when x"02"  => read_data(0) <= EXT(set_dl_index_w, 32);
            when x"03"  => read_data(0) <= dl_uplane_only_en_r;

            when x"06"  => read_data(0) <= dss_test_en_r;
            when x"07"  => read_data(0) <= coeff_vld_cnt_r(0);
            when x"08"  => read_data(0) <= coeff_idx_mon_r(0);
            when x"09"  => read_data(0) <= coeff_vld_cnt_r(1);
            when x"0A"  => read_data(0) <= coeff_idx_mon_r(1);

            when x"0C"  => read_data(0) <= user_debug0_r;
            when x"0D"  => read_data(0) <= user_debug1_r;
            when x"0E"  => read_data(0) <= user_debug2_r;
            when x"0F"  => read_data(0) <= user_debug3_r;

            when x"10"  => read_data(0) <= dl_eaxc_id_r1;
            when x"11"  => read_data(0) <= dl_comp_mode_r1;
            when x"12"  => read_data(0) <= dl_frame_structure_r1;
            when x"13"  => read_data(0) <= dl_prb_per_symbol_r1;
            when x"15"  => read_data(0) <= dl_pe_index_r1;

            when x"30"  => read_data(0) <= dl_comp_exp_offset_r1;

            when x"80"  => read_data(0) <= EXT(sts_dl_data_type_w, 32);
            when x"81"  => read_data(0) <= max_dl_index_r;
            when x"82"  => read_data(0) <= EXT(sts_dl_index_w, 32);

            when x"E0"  => read_data(0) <= det_dl_cp0_fault_id_31_f(0)(31 downto 0);
            when x"E2"  => read_data(0) <= det_dl_cp1_fault_id_31_f(0)(31 downto 0);
            when x"E4"  => read_data(0) <= det_dl_cp2_fault_id_31_f(0)(31 downto 0);
--            when x"E6"  => read_data(0) <= det_dl_cp3_fault_id_31_f(0)(31 downto 0);
--            when x"E8"  => read_data(0) <= det_dl_cp4_fault_id_31_f(0)(31 downto 0);
--            when x"EA"  => read_data(0) <= det_dl_cp5_fault_id_31_f(0)(31 downto 0);
--            when x"EC"  => read_data(0) <= det_dl_cp6_fault_id_31_f(0)(31 downto 0);
--            when x"EE"  => read_data(0) <= det_dl_cp7_fault_id_31_f(0)(31 downto 0);

--            when x"F0"  => read_data(0) <= det_dl_up0_fault_id_31_f(0)(31 downto 0);
--            when x"F2"  => read_data(0) <= det_dl_up1_fault_id_31_f(0)(31 downto 0);
--            when x"F4"  => read_data(0) <= det_dl_up2_fault_id_31_f(0)(31 downto 0);
--            when x"F6"  => read_data(0) <= det_dl_up3_fault_id_31_f(0)(31 downto 0);
--            when x"F8"  => read_data(0) <= det_dl_up4_fault_id_31_f(0)(31 downto 0);
--            when x"FA"  => read_data(0) <= det_dl_up5_fault_id_31_f(0)(31 downto 0);
--            when x"FC"  => read_data(0) <= det_dl_up6_fault_id_31_f(0)(31 downto 0);
--            when x"FE"  => read_data(0) <= det_dl_up7_fault_id_31_f(0)(31 downto 0);

            when others => read_data(0) <= (others => '0');
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case addr_lsb is
            when x"00"  => read_data(1) <= EXT(set_ul_data_type_w, 32);
            when x"01"  => read_data(1) <= max_ul_index_r;
            when x"02"  => read_data(1) <= EXT(set_ul_index_w, 32);
--            when x"03"  => read_data(1) <= info_ul_data_type_r;

            when x"10"  => read_data(1) <= ul_eaxc_id_r1;
            when x"11"  => read_data(1) <= ul_comp_mode_r1;
            when x"12"  => read_data(1) <= ul_frame_structure_r1;
            when x"13"  => read_data(1) <= ul_prb_per_symbol_r1;
            when x"14"  => read_data(1) <= ul_prb_per_mtu_r1;
            when x"15"  => read_data(1) <= ul_pe_index_r1;

            when x"30"  => read_data(1) <= ul_comp_exp_offset_r1;
            when x"31"  => read_data(1) <= ul_comp_gain_offset_r1;
            when x"32"  => read_data(1) <= ul_comp_scale_gain_offset_r1;

            when x"80"  => read_data(1) <= EXT(sts_ul_data_type_w, 32);
            when x"81"  => read_data(1) <= max_ul_index_r;
            when x"82"  => read_data(1) <= EXT(sts_ul_index_w, 32);

            when x"E0"  => read_data(1) <= det_ul_cp0_fault_id_31_f(0)(31 downto 0);
            when x"E2"  => read_data(1) <= det_ul_cp1_fault_id_31_f(0)(31 downto 0);
            when x"E4"  => read_data(1) <= det_ul_cp2_fault_id_31_f(0)(31 downto 0);
            when x"E6"  => read_data(1) <= det_ul_cp3_fault_id_31_f(0)(31 downto 0);
            when x"E8"  => read_data(1) <= det_ul_cp4_fault_id_31_f(0)(31 downto 0);
--            when x"EA"  => read_data(1) <= det_ul_cp5_fault_id_31_f(0)(31 downto 0);
--            when x"EC"  => read_data(1) <= det_ul_cp6_fault_id_31_f(0)(31 downto 0);
--            when x"EE"  => read_data(1) <= det_ul_cp7_fault_id_31_f(0)(31 downto 0);

            when others => read_data(1) <= (others => '0');
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case addr_lsb is
            when x"00"  => read_data(2) <= l0_mac_47_to_32_w;
            when x"01"  => read_data(2) <= l0_mac_31_to_0_w;
            when x"02"  => read_data(2) <= l1_mac_47_to_32_w;
            when x"03"  => read_data(2) <= l1_mac_31_to_0_w;
            when x"04"  => read_data(2) <= l2_mac_47_to_32_w;
            when x"05"  => read_data(2) <= l2_mac_31_to_0_w;
            when x"06"  => read_data(2) <= l3_mac_47_to_32_w;
            when x"07"  => read_data(2) <= l3_mac_31_to_0_w;

            when x"41"  => read_data(2) <= max_pe_index_r;
            when x"42"  => read_data(2) <= EXT(set_pe_index_w, 32);

            when x"50"  => read_data(2) <= ru_mac_31_to_0_r;
            when x"51"  => read_data(2) <= ru_mac_47_to_32_r;
            when x"52"  => read_data(2) <= du_mac_31_to_0_r;
            when x"53"  => read_data(2) <= du_mac_47_to_32_r;
            when x"54"  => read_data(2) <= vlan0_vid_r;
--            when x"55"  => read_data(2) <= vlan1_vid_r;

            when x"61"  => read_data(2) <= max_pe_index_r;
            when x"62"  => read_data(2) <= EXT(sts_pe_index_w, 32);

            when x"70"  => read_data(2) <= capture_period_r;

            when x"80"  => read_data(2) <= t2a_max0_dl_cp_rx_r;
            when x"81"  => read_data(2) <= t2a_min0_dl_cp_rx_r;
            when x"82"  => read_data(2) <= t2a_max1_dl_cp_rx_r;
            when x"83"  => read_data(2) <= t2a_min1_dl_cp_rx_r;
            when x"84"  => read_data(2) <= t2a_max2_dl_cp_rx_r;
            when x"85"  => read_data(2) <= t2a_min2_dl_cp_rx_r;
            when x"86"  => read_data(2) <= t2a_max3_dl_cp_rx_r;
            when x"87"  => read_data(2) <= t2a_min3_dl_cp_rx_r;
            when x"88"  => read_data(2) <= t2a_max4_dl_cp_rx_r;
            when x"89"  => read_data(2) <= t2a_min4_dl_cp_rx_r;

            when x"90"  => read_data(2) <= t2a_max0_dl_up_rx_r;
            when x"91"  => read_data(2) <= t2a_min0_dl_up_rx_r;
            when x"92"  => read_data(2) <= t2a_max1_dl_up_rx_r;
            when x"93"  => read_data(2) <= t2a_min1_dl_up_rx_r;
            when x"94"  => read_data(2) <= t2a_max2_dl_up_rx_r;
            when x"95"  => read_data(2) <= t2a_min2_dl_up_rx_r;
            when x"96"  => read_data(2) <= t2a_max3_dl_up_rx_r;
            when x"97"  => read_data(2) <= t2a_min3_dl_up_rx_r;
            when x"98"  => read_data(2) <= t2a_max4_dl_up_rx_r;
            when x"99"  => read_data(2) <= t2a_min4_dl_up_rx_r;

            when x"A0"  => read_data(2) <= t2a_max0_ul_cp_rx_r;
            when x"A1"  => read_data(2) <= t2a_min0_ul_cp_rx_r;
            when x"A2"  => read_data(2) <= t2a_max1_ul_cp_rx_r;
            when x"A3"  => read_data(2) <= t2a_min1_ul_cp_rx_r;
            when x"A4"  => read_data(2) <= t2a_max2_ul_cp_rx_r;
            when x"A5"  => read_data(2) <= t2a_min2_ul_cp_rx_r;
            when x"A6"  => read_data(2) <= t2a_max3_ul_cp_rx_r;
            when x"A7"  => read_data(2) <= t2a_min3_ul_cp_rx_r;
            when x"A8"  => read_data(2) <= t2a_max4_ul_cp_rx_r;
            when x"A9"  => read_data(2) <= t2a_min4_ul_cp_rx_r;

            when x"C0"  => read_data(2) <= rx_total_upper_r;
            when x"C1"  => read_data(2) <= rx_total_lower_r;
            when x"C2"  => read_data(2) <= rx_on_time_u_upper_r;
            when x"C3"  => read_data(2) <= rx_on_time_u_lower_r;
            when x"C4"  => read_data(2) <= rx_early_u_upper_r;
            when x"C5"  => read_data(2) <= rx_early_u_lower_r;
            when x"C6"  => read_data(2) <= rx_late_u_upper_r;
            when x"C7"  => read_data(2) <= rx_late_u_lower_r;

            when x"CA"  => read_data(2) <= rx_on_time_c_upper_r;
            when x"CB"  => read_data(2) <= rx_on_time_c_lower_r;
            when x"CC"  => read_data(2) <= rx_early_c_upper_r;
            when x"CD"  => read_data(2) <= rx_early_c_lower_r;
            when x"CE"  => read_data(2) <= rx_late_c_upper_r;
            when x"CF"  => read_data(2) <= rx_late_c_lower_r;

            when x"D2"  => read_data(2) <= s_r_cnt_rx_corrupt_upper;
            when x"D3"  => read_data(2) <= s_r_cnt_rx_corrupt_lower;

            when x"D8"  => read_data(2) <= ul_up_tx_upper_r;
            when x"D9"  => read_data(2) <= ul_up_tx_lower_r;

            when others => read_data(2) <= (others => '0');
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case addr_lsb is
            when x"00"  => read_data(3) <= dl_cp_rx_on_time0_upper_r;
            when x"01"  => read_data(3) <= dl_cp_rx_on_time0_lower_r;
            when x"02"  => read_data(3) <= dl_cp_rx_early0_upper_r;
            when x"03"  => read_data(3) <= dl_cp_rx_early0_lower_r;
            when x"04"  => read_data(3) <= dl_cp_rx_late0_upper_r;
            when x"05"  => read_data(3) <= dl_cp_rx_late0_lower_r;
            when x"06"  => read_data(3) <= dl_cp_rx_ndm0_upper_r;
            when x"07"  => read_data(3) <= dl_cp_rx_ndm0_lower_r;
            when x"08"  => read_data(3) <= dl_cp_rx_on_time1_upper_r;
            when x"09"  => read_data(3) <= dl_cp_rx_on_time1_lower_r;
            when x"0A"  => read_data(3) <= dl_cp_rx_early1_upper_r;
            when x"0B"  => read_data(3) <= dl_cp_rx_early1_lower_r;
            when x"0C"  => read_data(3) <= dl_cp_rx_late1_upper_r;
            when x"0D"  => read_data(3) <= dl_cp_rx_late1_lower_r;
            when x"0E"  => read_data(3) <= dl_cp_rx_ndm1_upper_r;
            when x"0F"  => read_data(3) <= dl_cp_rx_ndm1_lower_r;
            when x"10"  => read_data(3) <= dl_cp_rx_on_time2_upper_r;
            when x"11"  => read_data(3) <= dl_cp_rx_on_time2_lower_r;
            when x"12"  => read_data(3) <= dl_cp_rx_early2_upper_r;
            when x"13"  => read_data(3) <= dl_cp_rx_early2_lower_r;
            when x"14"  => read_data(3) <= dl_cp_rx_late2_upper_r;
            when x"15"  => read_data(3) <= dl_cp_rx_late2_lower_r;
            when x"16"  => read_data(3) <= dl_cp_rx_ndm2_upper_r;
            when x"17"  => read_data(3) <= dl_cp_rx_ndm2_lower_r;
            when x"18"  => read_data(3) <= dl_cp_rx_on_time3_upper_r;
            when x"19"  => read_data(3) <= dl_cp_rx_on_time3_lower_r;
            when x"1A"  => read_data(3) <= dl_cp_rx_early3_upper_r;
            when x"1B"  => read_data(3) <= dl_cp_rx_early3_lower_r;
            when x"1C"  => read_data(3) <= dl_cp_rx_late3_upper_r;
            when x"1D"  => read_data(3) <= dl_cp_rx_late3_lower_r;
            when x"1E"  => read_data(3) <= dl_cp_rx_ndm3_upper_r;
            when x"1F"  => read_data(3) <= dl_cp_rx_ndm3_lower_r;
            when x"20"  => read_data(3) <= dl_cp_rx_on_time4_upper_r;
            when x"21"  => read_data(3) <= dl_cp_rx_on_time4_lower_r;
            when x"22"  => read_data(3) <= dl_cp_rx_early4_upper_r;
            when x"23"  => read_data(3) <= dl_cp_rx_early4_lower_r;
            when x"24"  => read_data(3) <= dl_cp_rx_late4_upper_r;
            when x"25"  => read_data(3) <= dl_cp_rx_late4_lower_r;
            when x"26"  => read_data(3) <= dl_cp_rx_ndm4_upper_r;
            when x"27"  => read_data(3) <= dl_cp_rx_ndm4_lower_r;

            when x"28"  => read_data(3) <= dl_up_rx_on_time0_upper_r;
            when x"29"  => read_data(3) <= dl_up_rx_on_time0_lower_r;
            when x"2A"  => read_data(3) <= dl_up_rx_early0_upper_r;
            when x"2B"  => read_data(3) <= dl_up_rx_early0_lower_r;
            when x"2C"  => read_data(3) <= dl_up_rx_late0_upper_r;
            when x"2D"  => read_data(3) <= dl_up_rx_late0_lower_r;
            when x"2E"  => read_data(3) <= dl_up_rx_ndm0_upper_r;
            when x"2F"  => read_data(3) <= dl_up_rx_ndm0_lower_r;
            when x"30"  => read_data(3) <= dl_up_rx_on_time1_upper_r;
            when x"31"  => read_data(3) <= dl_up_rx_on_time1_lower_r;
            when x"32"  => read_data(3) <= dl_up_rx_early1_upper_r;
            when x"33"  => read_data(3) <= dl_up_rx_early1_lower_r;
            when x"34"  => read_data(3) <= dl_up_rx_late1_upper_r;
            when x"35"  => read_data(3) <= dl_up_rx_late1_lower_r;
            when x"36"  => read_data(3) <= dl_up_rx_ndm1_upper_r;
            when x"37"  => read_data(3) <= dl_up_rx_ndm1_lower_r;
            when x"38"  => read_data(3) <= dl_up_rx_on_time2_upper_r;
            when x"39"  => read_data(3) <= dl_up_rx_on_time2_lower_r;
            when x"3A"  => read_data(3) <= dl_up_rx_early2_upper_r;
            when x"3B"  => read_data(3) <= dl_up_rx_early2_lower_r;
            when x"3C"  => read_data(3) <= dl_up_rx_late2_upper_r;
            when x"3D"  => read_data(3) <= dl_up_rx_late2_lower_r;
            when x"3E"  => read_data(3) <= dl_up_rx_ndm2_upper_r;
            when x"3F"  => read_data(3) <= dl_up_rx_ndm2_lower_r;
            when x"40"  => read_data(3) <= dl_up_rx_on_time3_upper_r;
            when x"41"  => read_data(3) <= dl_up_rx_on_time3_lower_r;
            when x"42"  => read_data(3) <= dl_up_rx_early3_upper_r;
            when x"43"  => read_data(3) <= dl_up_rx_early3_lower_r;
            when x"44"  => read_data(3) <= dl_up_rx_late3_upper_r;
            when x"45"  => read_data(3) <= dl_up_rx_late3_lower_r;
            when x"46"  => read_data(3) <= dl_up_rx_ndm3_upper_r;
            when x"47"  => read_data(3) <= dl_up_rx_ndm3_lower_r;
            when x"48"  => read_data(3) <= dl_up_rx_on_time4_upper_r;
            when x"49"  => read_data(3) <= dl_up_rx_on_time4_lower_r;
            when x"4A"  => read_data(3) <= dl_up_rx_early4_upper_r;
            when x"4B"  => read_data(3) <= dl_up_rx_early4_lower_r;
            when x"4C"  => read_data(3) <= dl_up_rx_late4_upper_r;
            when x"4D"  => read_data(3) <= dl_up_rx_late4_lower_r;
            when x"4E"  => read_data(3) <= dl_up_rx_ndm4_upper_r;
            when x"4F"  => read_data(3) <= dl_up_rx_ndm4_lower_r;

            when x"50"  => read_data(3) <= ul_cp_rx_on_time0_upper_r;
            when x"51"  => read_data(3) <= ul_cp_rx_on_time0_lower_r;
            when x"52"  => read_data(3) <= ul_cp_rx_early0_upper_r;
            when x"53"  => read_data(3) <= ul_cp_rx_early0_lower_r;
            when x"54"  => read_data(3) <= ul_cp_rx_late0_upper_r;
            when x"55"  => read_data(3) <= ul_cp_rx_late0_lower_r;
            when x"56"  => read_data(3) <= ul_cp_rx_ndm0_upper_r;
            when x"57"  => read_data(3) <= ul_cp_rx_ndm0_lower_r;
            when x"58"  => read_data(3) <= ul_cp_rx_on_time1_upper_r;
            when x"59"  => read_data(3) <= ul_cp_rx_on_time1_lower_r;
            when x"5A"  => read_data(3) <= ul_cp_rx_early1_upper_r;
            when x"5B"  => read_data(3) <= ul_cp_rx_early1_lower_r;
            when x"5C"  => read_data(3) <= ul_cp_rx_late1_upper_r;
            when x"5D"  => read_data(3) <= ul_cp_rx_late1_lower_r;
            when x"5E"  => read_data(3) <= ul_cp_rx_ndm1_upper_r;
            when x"5F"  => read_data(3) <= ul_cp_rx_ndm1_lower_r;
            when x"60"  => read_data(3) <= ul_cp_rx_on_time2_upper_r;
            when x"61"  => read_data(3) <= ul_cp_rx_on_time2_lower_r;
            when x"62"  => read_data(3) <= ul_cp_rx_early2_upper_r;
            when x"63"  => read_data(3) <= ul_cp_rx_early2_lower_r;
            when x"64"  => read_data(3) <= ul_cp_rx_late2_upper_r;
            when x"65"  => read_data(3) <= ul_cp_rx_late2_lower_r;
            when x"66"  => read_data(3) <= ul_cp_rx_ndm2_upper_r;
            when x"67"  => read_data(3) <= ul_cp_rx_ndm2_lower_r;
            when x"68"  => read_data(3) <= ul_cp_rx_on_time3_upper_r;
            when x"69"  => read_data(3) <= ul_cp_rx_on_time3_lower_r;
            when x"6A"  => read_data(3) <= ul_cp_rx_early3_upper_r;
            when x"6B"  => read_data(3) <= ul_cp_rx_early3_lower_r;
            when x"6C"  => read_data(3) <= ul_cp_rx_late3_upper_r;
            when x"6D"  => read_data(3) <= ul_cp_rx_late3_lower_r;
            when x"6E"  => read_data(3) <= ul_cp_rx_ndm3_upper_r;
            when x"6F"  => read_data(3) <= ul_cp_rx_ndm3_lower_r;
            when x"70"  => read_data(3) <= ul_cp_rx_on_time4_upper_r;
            when x"71"  => read_data(3) <= ul_cp_rx_on_time4_lower_r;
            when x"72"  => read_data(3) <= ul_cp_rx_early4_upper_r;
            when x"73"  => read_data(3) <= ul_cp_rx_early4_lower_r;
            when x"74"  => read_data(3) <= ul_cp_rx_late4_upper_r;
            when x"75"  => read_data(3) <= ul_cp_rx_late4_lower_r;
            when x"76"  => read_data(3) <= ul_cp_rx_ndm4_upper_r;
            when x"77"  => read_data(3) <= ul_cp_rx_ndm4_lower_r;

            when x"80"  => read_data(3) <= ul_up_tx_upper_r;
            when x"81"  => read_data(3) <= ul_up_tx_lower_r;

            when x"90"  => read_data(3) <= s_r_cnt_rx_corrupt_pcid_ecpriv_payloadv_upper;
            when x"91"  => read_data(3) <= s_r_cnt_rx_corrupt_pcid_ecpriv_payloadv_lower;
            when x"92"  => read_data(3) <= s_r_cnt_rx_corrupt_pcid_upper;
            when x"93"  => read_data(3) <= s_r_cnt_rx_corrupt_pcid_lower;
            when x"94"  => read_data(3) <= s_r_cnt_rx_corrupt_ecpriv_upper;
            when x"95"  => read_data(3) <= s_r_cnt_rx_corrupt_ecpriv_lower;
            when x"96"  => read_data(3) <= s_r_cnt_rx_corrupt_payloadv_upper;
            when x"97"  => read_data(3) <= s_r_cnt_rx_corrupt_payloadv_lower;
            when x"98"  => read_data(3) <= s_r_cnt_rx_corrupt_sectionid_upper;
            when x"99"  => read_data(3) <= s_r_cnt_rx_corrupt_sectionid_lower;
                        
            when others => read_data(3) <= (others => '0');
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case addr_lsb is
            when x"00"  => read_data(8) <= rx_pe_valid_r(0);
            when x"01"  => read_data(8) <= rx_invalid_dst_mac_r(0);
            when x"02"  => read_data(8) <= rx_invalid_src_mac_r(0);
            when x"03"  => read_data(8) <= rx_invalid_vlan_vid_r(0);
            when x"04"  => read_data(8) <= rx_pe_valid_r(1);
            when x"05"  => read_data(8) <= rx_invalid_dst_mac_r(1);
            when x"06"  => read_data(8) <= rx_invalid_src_mac_r(1);
            when x"07"  => read_data(8) <= rx_invalid_vlan_vid_r(1);
            when x"08"  => read_data(8) <= rx_pe_valid_r(2);
            when x"09"  => read_data(8) <= rx_invalid_dst_mac_r(2);
            when x"0A"  => read_data(8) <= rx_invalid_src_mac_r(2);
            when x"0B"  => read_data(8) <= rx_invalid_vlan_vid_r(2);
            when x"0C"  => read_data(8) <= rx_pe_valid_r(3);
            when x"0D"  => read_data(8) <= rx_invalid_dst_mac_r(3);
            when x"0E"  => read_data(8) <= rx_invalid_src_mac_r(3);
            when x"0F"  => read_data(8) <= rx_invalid_vlan_vid_r(3);
            when x"10"  => read_data(8) <= rx_pe_valid_r(4);
            when x"11"  => read_data(8) <= rx_invalid_dst_mac_r(4);
            when x"12"  => read_data(8) <= rx_invalid_src_mac_r(4);
            when x"13"  => read_data(8) <= rx_invalid_vlan_vid_r(4);
            when x"14"  => read_data(8) <= rx_pe_valid_r(5);
            when x"15"  => read_data(8) <= rx_invalid_dst_mac_r(5);
            when x"16"  => read_data(8) <= rx_invalid_src_mac_r(5);
            when x"17"  => read_data(8) <= rx_invalid_vlan_vid_r(5);
            when x"18"  => read_data(8) <= rx_pe_valid_r(6);
            when x"19"  => read_data(8) <= rx_invalid_dst_mac_r(6);
            when x"1A"  => read_data(8) <= rx_invalid_src_mac_r(6);
            when x"1B"  => read_data(8) <= rx_invalid_vlan_vid_r(6);
            when x"1C"  => read_data(8) <= rx_pe_valid_r(7);
            when x"1D"  => read_data(8) <= rx_invalid_dst_mac_r(7);
            when x"1E"  => read_data(8) <= rx_invalid_src_mac_r(7);
            when x"1F"  => read_data(8) <= rx_invalid_vlan_vid_r(7);

            when x"20"  => read_data(8) <= rx_discontinue_r(0);
            when x"21"  => read_data(8) <= rx_discontinue_r(1);
            when x"22"  => read_data(8) <= rx_discontinue_r(2);
            when x"23"  => read_data(8) <= rx_discontinue_r(3);
            when x"24"  => read_data(8) <= rx_discontinue_r(4);
            when x"25"  => read_data(8) <= rx_discontinue_r(5);
            when x"26"  => read_data(8) <= rx_discontinue_r(6);
            when x"27"  => read_data(8) <= rx_discontinue_r(7);
            when x"28"  => read_data(8) <= rx_byte_size_r(0);
            when x"29"  => read_data(8) <= rx_byte_size_r(1);
            when x"2A"  => read_data(8) <= rx_byte_size_r(2);
            when x"2B"  => read_data(8) <= rx_byte_size_r(3);
            when x"2C"  => read_data(8) <= rx_byte_size_r(4);
            when x"2D"  => read_data(8) <= rx_byte_size_r(5);
            when x"2E"  => read_data(8) <= rx_byte_size_r(6);
            when x"2F"  => read_data(8) <= rx_byte_size_r(7);
            when x"30"  => read_data(8) <= rx_byte_align_r(0);
            when x"31"  => read_data(8) <= rx_byte_align_r(1);
            when x"32"  => read_data(8) <= rx_byte_align_r(2);
            when x"33"  => read_data(8) <= rx_byte_align_r(3);
            when x"34"  => read_data(8) <= rx_byte_align_r(4);
            when x"35"  => read_data(8) <= rx_byte_align_r(5);
            when x"36"  => read_data(8) <= rx_byte_align_r(6);
            when x"37"  => read_data(8) <= rx_byte_align_r(7);

            when x"40"  => read_data(8) <= usage_rx_cp_buffer_f(0);
            when x"42"  => read_data(8) <= cnt_rx_cp_r(0);
            when x"43"  => read_data(8) <= cnt_rx_cp_lost_r(0);
            when x"44"  => read_data(8) <= usage_rx_up_buffer_f(0);
            when x"46"  => read_data(8) <= cnt_rx_up_r(0);
            when x"47"  => read_data(8) <= cnt_rx_up_lost_r(0);
            when x"48"  => read_data(8) <= usage_rx_cp_buffer_f(1);
            when x"4A"  => read_data(8) <= cnt_rx_cp_r(1);
            when x"4B"  => read_data(8) <= cnt_rx_cp_lost_r(1);
            when x"4C"  => read_data(8) <= usage_rx_up_buffer_f(1);
            when x"4E"  => read_data(8) <= cnt_rx_up_r(1);
            when x"4F"  => read_data(8) <= cnt_rx_up_lost_r(1);
            when x"50"  => read_data(8) <= usage_rx_cp_buffer_f(2);
            when x"52"  => read_data(8) <= cnt_rx_cp_r(2);
            when x"53"  => read_data(8) <= cnt_rx_cp_lost_r(2);
            when x"54"  => read_data(8) <= usage_rx_up_buffer_f(2);
            when x"56"  => read_data(8) <= cnt_rx_up_r(2);
            when x"57"  => read_data(8) <= cnt_rx_up_lost_r(2);
            when x"58"  => read_data(8) <= usage_rx_cp_buffer_f(3);
            when x"5A"  => read_data(8) <= cnt_rx_cp_r(3);
            when x"5B"  => read_data(8) <= cnt_rx_cp_lost_r(3);
            when x"5C"  => read_data(8) <= usage_rx_up_buffer_f(3);
            when x"5E"  => read_data(8) <= cnt_rx_up_r(3);
            when x"5F"  => read_data(8) <= cnt_rx_up_lost_r(3);
            when x"60"  => read_data(8) <= usage_rx_cp_buffer_f(4);
            when x"62"  => read_data(8) <= cnt_rx_cp_r(4);
            when x"63"  => read_data(8) <= cnt_rx_cp_lost_r(4);
            when x"64"  => read_data(8) <= usage_rx_up_buffer_f(4);
            when x"66"  => read_data(8) <= cnt_rx_up_r(4);
            when x"67"  => read_data(8) <= cnt_rx_up_lost_r(4);
            when x"68"  => read_data(8) <= usage_rx_cp_buffer_f(5);
            when x"6A"  => read_data(8) <= cnt_rx_cp_r(5);
            when x"6B"  => read_data(8) <= cnt_rx_cp_lost_r(5);
            when x"6C"  => read_data(8) <= usage_rx_up_buffer_f(5);
            when x"6E"  => read_data(8) <= cnt_rx_up_r(5);
            when x"6F"  => read_data(8) <= cnt_rx_up_lost_r(5);
            when x"70"  => read_data(8) <= usage_rx_cp_buffer_f(6);
            when x"72"  => read_data(8) <= cnt_rx_cp_r(6);
            when x"73"  => read_data(8) <= cnt_rx_cp_lost_r(6);
            when x"74"  => read_data(8) <= usage_rx_up_buffer_f(6);
            when x"76"  => read_data(8) <= cnt_rx_up_r(6);
            when x"77"  => read_data(8) <= cnt_rx_up_lost_r(6);
            when x"78"  => read_data(8) <= usage_rx_cp_buffer_f(7);
            when x"7A"  => read_data(8) <= cnt_rx_cp_r(7);
            when x"7B"  => read_data(8) <= cnt_rx_cp_lost_r(7);
            when x"7C"  => read_data(8) <= usage_rx_up_buffer_f(7);
            when x"7E"  => read_data(8) <= cnt_rx_up_r(7);
            when x"7F"  => read_data(8) <= cnt_rx_up_lost_r(7);

            when x"80"  => read_data(8) <= rx_dl_cp_position_f(0)(31 downto 0);
            when x"82"  => read_data(8) <= rx_dl_cp_position_f(1)(31 downto 0);
            when x"84"  => read_data(8) <= rx_dl_cp_position_f(2)(31 downto 0);
            when x"86"  => read_data(8) <= rx_dl_cp_position_f(3)(31 downto 0);
            when x"88"  => read_data(8) <= rx_dl_cp_position_f(4)(31 downto 0);
            when x"8A"  => read_data(8) <= rx_dl_cp_position_f(5)(31 downto 0);
            when x"8C"  => read_data(8) <= rx_dl_cp_position_f(6)(31 downto 0);
            when x"8E"  => read_data(8) <= rx_dl_cp_position_f(7)(31 downto 0);

            when x"90"  => read_data(8) <= rx_dl_up_position_f(0)(31 downto 0);
            when x"92"  => read_data(8) <= rx_dl_up_position_f(1)(31 downto 0);
            when x"94"  => read_data(8) <= rx_dl_up_position_f(2)(31 downto 0);
            when x"96"  => read_data(8) <= rx_dl_up_position_f(3)(31 downto 0);
            when x"98"  => read_data(8) <= rx_dl_up_position_f(4)(31 downto 0);
            when x"9A"  => read_data(8) <= rx_dl_up_position_f(5)(31 downto 0);
            when x"9C"  => read_data(8) <= rx_dl_up_position_f(6)(31 downto 0);
            when x"9E"  => read_data(8) <= rx_dl_up_position_f(7)(31 downto 0);

            when x"A0"  => read_data(8) <= rx_ul_cp_position_f(0)(31 downto 0);
            when x"A2"  => read_data(8) <= rx_ul_cp_position_f(1)(31 downto 0);
            when x"A4"  => read_data(8) <= rx_ul_cp_position_f(2)(31 downto 0);
            when x"A6"  => read_data(8) <= rx_ul_cp_position_f(3)(31 downto 0);
            when x"A8"  => read_data(8) <= rx_ul_cp_position_f(4)(31 downto 0);
            when x"AA"  => read_data(8) <= rx_ul_cp_position_f(5)(31 downto 0);
            when x"AC"  => read_data(8) <= rx_ul_cp_position_f(6)(31 downto 0);
            when x"AE"  => read_data(8) <= rx_ul_cp_position_f(7)(31 downto 0);

            when others => read_data(8) <= (others => '0');
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case addr_lsb is
            when x"00"  => read_data(9) <= usage_tx0_up_buffer_f(0);
            when x"02"  => read_data(9) <= cnt_tx0_r(0);
            when x"03"  => read_data(9) <= cnt_tx0_lost_r(0);
            when x"04"  => read_data(9) <= usage_tx1_up_buffer_f(0);
            when x"06"  => read_data(9) <= cnt_tx1_r(0);
            when x"07"  => read_data(9) <= cnt_tx1_lost_r(0);
            when x"08"  => read_data(9) <= usage_tx2_up_buffer_f(0);
            when x"0A"  => read_data(9) <= cnt_tx2_r(0);
            when x"0B"  => read_data(9) <= cnt_tx2_lost_r(0);
            when x"0C"  => read_data(9) <= usage_tx3_up_buffer_f(0);
            when x"0E"  => read_data(9) <= cnt_tx3_r(0);
            when x"0F"  => read_data(9) <= cnt_tx3_lost_r(0);
            when x"10"  => read_data(9) <= usage_tx4_up_buffer_f(0);
            when x"12"  => read_data(9) <= cnt_tx4_r(0);
            when x"13"  => read_data(9) <= cnt_tx4_lost_r(0);
--            when x"14"  => read_data(9) <= usage_tx5_up_buffer_f(0);
--            when x"16"  => read_data(9) <= cnt_tx5_r(0);
--            when x"17"  => read_data(9) <= cnt_tx5_lost_r(0);

            when x"20"  => read_data(9) <= usage_tx0_up_buffer_f(1);
            when x"22"  => read_data(9) <= cnt_tx0_r(1);
            when x"23"  => read_data(9) <= cnt_tx0_lost_r(1);
            when x"24"  => read_data(9) <= usage_tx1_up_buffer_f(1);
            when x"26"  => read_data(9) <= cnt_tx1_r(1);
            when x"27"  => read_data(9) <= cnt_tx1_lost_r(1);
            when x"28"  => read_data(9) <= usage_tx2_up_buffer_f(1);
            when x"2A"  => read_data(9) <= cnt_tx2_r(1);
            when x"2B"  => read_data(9) <= cnt_tx2_lost_r(1);
            when x"2C"  => read_data(9) <= usage_tx3_up_buffer_f(1);
            when x"2E"  => read_data(9) <= cnt_tx3_r(1);
            when x"2F"  => read_data(9) <= cnt_tx3_lost_r(1);
            when x"30"  => read_data(9) <= usage_tx4_up_buffer_f(1);
            when x"32"  => read_data(9) <= cnt_tx4_r(1);
            when x"33"  => read_data(9) <= cnt_tx4_lost_r(1);
--            when x"34"  => read_data(9) <= usage_tx5_up_buffer_f(1);
--            when x"36"  => read_data(9) <= cnt_tx5_r(1);
--            when x"37"  => read_data(9) <= cnt_tx5_lost_r(1);

            when x"40"  => read_data(9) <= usage_tx0_up_buffer_f(2);
            when x"42"  => read_data(9) <= cnt_tx0_r(2);
            when x"43"  => read_data(9) <= cnt_tx0_lost_r(2);
            when x"44"  => read_data(9) <= usage_tx1_up_buffer_f(2);
            when x"46"  => read_data(9) <= cnt_tx1_r(2);
            when x"47"  => read_data(9) <= cnt_tx1_lost_r(2);
            when x"48"  => read_data(9) <= usage_tx2_up_buffer_f(2);
            when x"4A"  => read_data(9) <= cnt_tx2_r(2);
            when x"4B"  => read_data(9) <= cnt_tx2_lost_r(2);
            when x"4C"  => read_data(9) <= usage_tx3_up_buffer_f(2);
            when x"4E"  => read_data(9) <= cnt_tx3_r(2);
            when x"4F"  => read_data(9) <= cnt_tx3_lost_r(2);
            when x"50"  => read_data(9) <= usage_tx4_up_buffer_f(2);
            when x"52"  => read_data(9) <= cnt_tx4_r(2);
            when x"53"  => read_data(9) <= cnt_tx4_lost_r(2);
--            when x"54"  => read_data(9) <= usage_tx5_up_buffer_f(2);
--            when x"56"  => read_data(9) <= cnt_tx5_r(2);
--            when x"57"  => read_data(9) <= cnt_tx5_lost_r(2);

            when x"60"  => read_data(9) <= usage_tx0_up_buffer_f(3);
            when x"62"  => read_data(9) <= cnt_tx0_r(3);
            when x"63"  => read_data(9) <= cnt_tx0_lost_r(3);
            when x"64"  => read_data(9) <= usage_tx1_up_buffer_f(3);
            when x"66"  => read_data(9) <= cnt_tx1_r(3);
            when x"67"  => read_data(9) <= cnt_tx1_lost_r(3);
            when x"68"  => read_data(9) <= usage_tx2_up_buffer_f(3);
            when x"6A"  => read_data(9) <= cnt_tx2_r(3);
            when x"6B"  => read_data(9) <= cnt_tx2_lost_r(3);
            when x"6C"  => read_data(9) <= usage_tx3_up_buffer_f(3);
            when x"6E"  => read_data(9) <= cnt_tx3_r(3);
            when x"6F"  => read_data(9) <= cnt_tx3_lost_r(3);
            when x"70"  => read_data(9) <= usage_tx4_up_buffer_f(3);
            when x"72"  => read_data(9) <= cnt_tx4_r(3);
            when x"73"  => read_data(9) <= cnt_tx4_lost_r(3);
--            when x"74"  => read_data(9) <= usage_tx5_up_buffer_f(3);
--            when x"76"  => read_data(9) <= cnt_tx5_r(3);
--            when x"77"  => read_data(9) <= cnt_tx5_lost_r(3);

            when x"80"  => read_data(9) <= usage_tx0_up_buffer_f(4);
            when x"82"  => read_data(9) <= cnt_tx0_r(4);
            when x"83"  => read_data(9) <= cnt_tx0_lost_r(4);
            when x"84"  => read_data(9) <= usage_tx1_up_buffer_f(4);
            when x"86"  => read_data(9) <= cnt_tx1_r(4);
            when x"87"  => read_data(9) <= cnt_tx1_lost_r(4);
            when x"88"  => read_data(9) <= usage_tx2_up_buffer_f(4);
            when x"8A"  => read_data(9) <= cnt_tx2_r(4);
            when x"8B"  => read_data(9) <= cnt_tx2_lost_r(4);
            when x"8C"  => read_data(9) <= usage_tx3_up_buffer_f(4);
            when x"8E"  => read_data(9) <= cnt_tx3_r(4);
            when x"8F"  => read_data(9) <= cnt_tx3_lost_r(4);
            when x"90"  => read_data(9) <= usage_tx4_up_buffer_f(4);
            when x"92"  => read_data(9) <= cnt_tx4_r(4);
            when x"93"  => read_data(9) <= cnt_tx4_lost_r(4);
--            when x"94"  => read_data(9) <= usage_tx5_up_buffer_f(4);
--            when x"96"  => read_data(9) <= cnt_tx5_r(4);
--            when x"97"  => read_data(9) <= cnt_tx5_lost_r(4);

            when x"A0"  => read_data(9) <= usage_tx0_up_buffer_f(5);
            when x"A2"  => read_data(9) <= cnt_tx0_r(5);
            when x"A3"  => read_data(9) <= cnt_tx0_lost_r(5);
            when x"A4"  => read_data(9) <= usage_tx1_up_buffer_f(5);
            when x"A6"  => read_data(9) <= cnt_tx1_r(5);
            when x"A7"  => read_data(9) <= cnt_tx1_lost_r(5);
            when x"A8"  => read_data(9) <= usage_tx2_up_buffer_f(5);
            when x"AA"  => read_data(9) <= cnt_tx2_r(5);
            when x"AB"  => read_data(9) <= cnt_tx2_lost_r(5);
            when x"AC"  => read_data(9) <= usage_tx3_up_buffer_f(5);
            when x"AE"  => read_data(9) <= cnt_tx3_r(5);
            when x"AF"  => read_data(9) <= cnt_tx3_lost_r(5);
            when x"B0"  => read_data(9) <= usage_tx4_up_buffer_f(5);
            when x"B2"  => read_data(9) <= cnt_tx4_r(5);
            when x"B3"  => read_data(9) <= cnt_tx4_lost_r(5);
--            when x"B4"  => read_data(9) <= usage_tx5_up_buffer_f(5);
--            when x"B6"  => read_data(9) <= cnt_tx5_r(5);
--            when x"B7"  => read_data(9) <= cnt_tx5_lost_r(5);

            when x"C0"  => read_data(9) <= usage_tx0_up_buffer_f(6);
            when x"C2"  => read_data(9) <= cnt_tx0_r(6);
            when x"C3"  => read_data(9) <= cnt_tx0_lost_r(6);
            when x"C4"  => read_data(9) <= usage_tx1_up_buffer_f(6);
            when x"C6"  => read_data(9) <= cnt_tx1_r(6);
            when x"C7"  => read_data(9) <= cnt_tx1_lost_r(6);
            when x"C8"  => read_data(9) <= usage_tx2_up_buffer_f(6);
            when x"CA"  => read_data(9) <= cnt_tx2_r(6);
            when x"CB"  => read_data(9) <= cnt_tx2_lost_r(6);
            when x"CC"  => read_data(9) <= usage_tx3_up_buffer_f(6);
            when x"CE"  => read_data(9) <= cnt_tx3_r(6);
            when x"CF"  => read_data(9) <= cnt_tx3_lost_r(6);
            when x"D0"  => read_data(9) <= usage_tx4_up_buffer_f(6);
            when x"D2"  => read_data(9) <= cnt_tx4_r(6);
            when x"D3"  => read_data(9) <= cnt_tx4_lost_r(6);
--            when x"D4"  => read_data(9) <= usage_tx5_up_buffer_f(6);
--            when x"D6"  => read_data(9) <= cnt_tx5_r(6);
--            when x"D7"  => read_data(9) <= cnt_tx5_lost_r(6);

            when x"E0"  => read_data(9) <= usage_tx0_up_buffer_f(7);
            when x"E2"  => read_data(9) <= cnt_tx0_r(7);
            when x"E3"  => read_data(9) <= cnt_tx0_lost_r(7);
            when x"E4"  => read_data(9) <= usage_tx1_up_buffer_f(7);
            when x"E6"  => read_data(9) <= cnt_tx1_r(7);
            when x"E7"  => read_data(9) <= cnt_tx1_lost_r(7);
            when x"E8"  => read_data(9) <= usage_tx2_up_buffer_f(7);
            when x"EA"  => read_data(9) <= cnt_tx2_r(7);
            when x"EB"  => read_data(9) <= cnt_tx2_lost_r(7);
            when x"EC"  => read_data(9) <= usage_tx3_up_buffer_f(7);
            when x"EE"  => read_data(9) <= cnt_tx3_r(7);
            when x"EF"  => read_data(9) <= cnt_tx3_lost_r(7);
            when x"F0"  => read_data(9) <= usage_tx4_up_buffer_f(7);
            when x"F2"  => read_data(9) <= cnt_tx4_r(7);
            when x"F3"  => read_data(9) <= cnt_tx4_lost_r(7);
--            when x"F4"  => read_data(9) <= usage_tx5_up_buffer_f(7);
--            when x"F6"  => read_data(9) <= cnt_tx5_r(7);
--            when x"F7"  => read_data(9) <= cnt_tx5_lost_r(7);

            when others => read_data(9) <= (others => '0');
            end case;
        end if;
    end process;

    u_DEBUG : for i in MAX_CC_UL-1 downto 0 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case addr_lsb is
            when x"00"  => read_data(i*2+16) <= tx0_cnt_cpsec_sym0_r(i);
            when x"01"  => read_data(i*2+16) <= tx0_cnt_cpsec_sym1_r(i);
            when x"02"  => read_data(i*2+16) <= tx0_cnt_cpsec_sym2_r(i);
            when x"03"  => read_data(i*2+16) <= tx0_cnt_cpsec_sym3_r(i);
            when x"04"  => read_data(i*2+16) <= tx0_cnt_cpsec_sym4_r(i);
            when x"05"  => read_data(i*2+16) <= tx0_cnt_cpsec_sym5_r(i);
            when x"06"  => read_data(i*2+16) <= tx0_cnt_cpsec_sym6_r(i);
            when x"07"  => read_data(i*2+16) <= tx0_cnt_cpsec_sym7_r(i);
            when x"08"  => read_data(i*2+16) <= tx0_cnt_cpsec_sym8_r(i);
            when x"09"  => read_data(i*2+16) <= tx0_cnt_cpsec_sym9_r(i);
            when x"0A"  => read_data(i*2+16) <= tx0_cnt_cpsec_sym10_r(i);
            when x"0B"  => read_data(i*2+16) <= tx0_cnt_cpsec_sym11_r(i);
            when x"0C"  => read_data(i*2+16) <= tx0_cnt_cpsec_sym12_r(i);
            when x"0D"  => read_data(i*2+16) <= tx0_cnt_cpsec_sym13_r(i);
            when x"0E"  => read_data(i*2+16) <= tx0_cnt_cq_conv_full_r(i);
            when x"0F"  => read_data(i*2+16) <= tx0_frame_id_r(i);

            when x"10"  => read_data(i*2+16) <= tx0_cnt_uppkt_sym0_r(i);
            when x"11"  => read_data(i*2+16) <= tx0_cnt_uppkt_sym1_r(i);
            when x"12"  => read_data(i*2+16) <= tx0_cnt_uppkt_sym2_r(i);
            when x"13"  => read_data(i*2+16) <= tx0_cnt_uppkt_sym3_r(i);
            when x"14"  => read_data(i*2+16) <= tx0_cnt_uppkt_sym4_r(i);
            when x"15"  => read_data(i*2+16) <= tx0_cnt_uppkt_sym5_r(i);
            when x"16"  => read_data(i*2+16) <= tx0_cnt_uppkt_sym6_r(i);
            when x"17"  => read_data(i*2+16) <= tx0_cnt_uppkt_sym7_r(i);
            when x"18"  => read_data(i*2+16) <= tx0_cnt_uppkt_sym8_r(i);
            when x"19"  => read_data(i*2+16) <= tx0_cnt_uppkt_sym9_r(i);
            when x"1A"  => read_data(i*2+16) <= tx0_cnt_uppkt_sym10_r(i);
            when x"1B"  => read_data(i*2+16) <= tx0_cnt_uppkt_sym11_r(i);
            when x"1C"  => read_data(i*2+16) <= tx0_cnt_uppkt_sym12_r(i);
            when x"1D"  => read_data(i*2+16) <= tx0_cnt_uppkt_sym13_r(i);

            when x"20"  => read_data(i*2+16) <= tx0_cnt_cq_full_sym0_r(i);
            when x"21"  => read_data(i*2+16) <= tx0_cnt_cq_full_sym1_r(i);
            when x"22"  => read_data(i*2+16) <= tx0_cnt_cq_full_sym2_r(i);
            when x"23"  => read_data(i*2+16) <= tx0_cnt_cq_full_sym3_r(i);
            when x"24"  => read_data(i*2+16) <= tx0_cnt_cq_full_sym4_r(i);
            when x"25"  => read_data(i*2+16) <= tx0_cnt_cq_full_sym5_r(i);
            when x"26"  => read_data(i*2+16) <= tx0_cnt_cq_full_sym6_r(i);
            when x"27"  => read_data(i*2+16) <= tx0_cnt_cq_full_sym7_r(i);
            when x"28"  => read_data(i*2+16) <= tx0_cnt_cq_full_sym8_r(i);
            when x"29"  => read_data(i*2+16) <= tx0_cnt_cq_full_sym9_r(i);
            when x"2A"  => read_data(i*2+16) <= tx0_cnt_cq_full_sym10_r(i);
            when x"2B"  => read_data(i*2+16) <= tx0_cnt_cq_full_sym11_r(i);
            when x"2C"  => read_data(i*2+16) <= tx0_cnt_cq_full_sym12_r(i);
            when x"2D"  => read_data(i*2+16) <= tx0_cnt_cq_full_sym13_r(i);
            when x"2F"  => read_data(i*2+16) <= tx0_cnt_cq_fsm_busy_r(i);

            when x"30"  => read_data(i*2+16) <= tx0_usage_cq_sym0_f(i);
            when x"31"  => read_data(i*2+16) <= tx0_usage_cq_sym1_f(i);
            when x"32"  => read_data(i*2+16) <= tx0_usage_cq_sym2_f(i);
            when x"33"  => read_data(i*2+16) <= tx0_usage_cq_sym3_f(i);
            when x"34"  => read_data(i*2+16) <= tx0_usage_cq_sym4_f(i);
            when x"35"  => read_data(i*2+16) <= tx0_usage_cq_sym5_f(i);
            when x"36"  => read_data(i*2+16) <= tx0_usage_cq_sym6_f(i);
            when x"37"  => read_data(i*2+16) <= tx0_usage_cq_sym7_f(i);
            when x"38"  => read_data(i*2+16) <= tx0_usage_cq_sym8_f(i);
            when x"39"  => read_data(i*2+16) <= tx0_usage_cq_sym9_f(i);
            when x"3A"  => read_data(i*2+16) <= tx0_usage_cq_sym10_f(i);
            when x"3B"  => read_data(i*2+16) <= tx0_usage_cq_sym11_f(i);
            when x"3C"  => read_data(i*2+16) <= tx0_usage_cq_sym12_f(i);
            when x"3D"  => read_data(i*2+16) <= tx0_usage_cq_sym13_f(i);
            when x"3F"  => read_data(i*2+16) <= tx0_sts_cq_fsm_f(i);

            when x"40"  => read_data(i*2+16) <= tx1_cnt_cpsec_sym0_r(i);
            when x"41"  => read_data(i*2+16) <= tx1_cnt_cpsec_sym1_r(i);
            when x"42"  => read_data(i*2+16) <= tx1_cnt_cpsec_sym2_r(i);
            when x"43"  => read_data(i*2+16) <= tx1_cnt_cpsec_sym3_r(i);
            when x"44"  => read_data(i*2+16) <= tx1_cnt_cpsec_sym4_r(i);
            when x"45"  => read_data(i*2+16) <= tx1_cnt_cpsec_sym5_r(i);
            when x"46"  => read_data(i*2+16) <= tx1_cnt_cpsec_sym6_r(i);
            when x"47"  => read_data(i*2+16) <= tx1_cnt_cpsec_sym7_r(i);
            when x"48"  => read_data(i*2+16) <= tx1_cnt_cpsec_sym8_r(i);
            when x"49"  => read_data(i*2+16) <= tx1_cnt_cpsec_sym9_r(i);
            when x"4A"  => read_data(i*2+16) <= tx1_cnt_cpsec_sym10_r(i);
            when x"4B"  => read_data(i*2+16) <= tx1_cnt_cpsec_sym11_r(i);
            when x"4C"  => read_data(i*2+16) <= tx1_cnt_cpsec_sym12_r(i);
            when x"4D"  => read_data(i*2+16) <= tx1_cnt_cpsec_sym13_r(i);
            when x"4E"  => read_data(i*2+16) <= tx1_cnt_cq_conv_full_r(i);
            when x"4F"  => read_data(i*2+16) <= tx1_frame_id_r(i);

            when x"50"  => read_data(i*2+16) <= tx1_cnt_uppkt_sym0_r(i);
            when x"51"  => read_data(i*2+16) <= tx1_cnt_uppkt_sym1_r(i);
            when x"52"  => read_data(i*2+16) <= tx1_cnt_uppkt_sym2_r(i);
            when x"53"  => read_data(i*2+16) <= tx1_cnt_uppkt_sym3_r(i);
            when x"54"  => read_data(i*2+16) <= tx1_cnt_uppkt_sym4_r(i);
            when x"55"  => read_data(i*2+16) <= tx1_cnt_uppkt_sym5_r(i);
            when x"56"  => read_data(i*2+16) <= tx1_cnt_uppkt_sym6_r(i);
            when x"57"  => read_data(i*2+16) <= tx1_cnt_uppkt_sym7_r(i);
            when x"58"  => read_data(i*2+16) <= tx1_cnt_uppkt_sym8_r(i);
            when x"59"  => read_data(i*2+16) <= tx1_cnt_uppkt_sym9_r(i);
            when x"5A"  => read_data(i*2+16) <= tx1_cnt_uppkt_sym10_r(i);
            when x"5B"  => read_data(i*2+16) <= tx1_cnt_uppkt_sym11_r(i);
            when x"5C"  => read_data(i*2+16) <= tx1_cnt_uppkt_sym12_r(i);
            when x"5D"  => read_data(i*2+16) <= tx1_cnt_uppkt_sym13_r(i);

            when x"60"  => read_data(i*2+16) <= tx1_cnt_cq_full_sym0_r(i);
            when x"61"  => read_data(i*2+16) <= tx1_cnt_cq_full_sym1_r(i);
            when x"62"  => read_data(i*2+16) <= tx1_cnt_cq_full_sym2_r(i);
            when x"63"  => read_data(i*2+16) <= tx1_cnt_cq_full_sym3_r(i);
            when x"64"  => read_data(i*2+16) <= tx1_cnt_cq_full_sym4_r(i);
            when x"65"  => read_data(i*2+16) <= tx1_cnt_cq_full_sym5_r(i);
            when x"66"  => read_data(i*2+16) <= tx1_cnt_cq_full_sym6_r(i);
            when x"67"  => read_data(i*2+16) <= tx1_cnt_cq_full_sym7_r(i);
            when x"68"  => read_data(i*2+16) <= tx1_cnt_cq_full_sym8_r(i);
            when x"69"  => read_data(i*2+16) <= tx1_cnt_cq_full_sym9_r(i);
            when x"6A"  => read_data(i*2+16) <= tx1_cnt_cq_full_sym10_r(i);
            when x"6B"  => read_data(i*2+16) <= tx1_cnt_cq_full_sym11_r(i);
            when x"6C"  => read_data(i*2+16) <= tx1_cnt_cq_full_sym12_r(i);
            when x"6D"  => read_data(i*2+16) <= tx1_cnt_cq_full_sym13_r(i);
            when x"6F"  => read_data(i*2+16) <= tx1_cnt_cq_fsm_busy_r(i);

            when x"70"  => read_data(i*2+16) <= tx1_usage_cq_sym0_f(i);
            when x"71"  => read_data(i*2+16) <= tx1_usage_cq_sym1_f(i);
            when x"72"  => read_data(i*2+16) <= tx1_usage_cq_sym2_f(i);
            when x"73"  => read_data(i*2+16) <= tx1_usage_cq_sym3_f(i);
            when x"74"  => read_data(i*2+16) <= tx1_usage_cq_sym4_f(i);
            when x"75"  => read_data(i*2+16) <= tx1_usage_cq_sym5_f(i);
            when x"76"  => read_data(i*2+16) <= tx1_usage_cq_sym6_f(i);
            when x"77"  => read_data(i*2+16) <= tx1_usage_cq_sym7_f(i);
            when x"78"  => read_data(i*2+16) <= tx1_usage_cq_sym8_f(i);
            when x"79"  => read_data(i*2+16) <= tx1_usage_cq_sym9_f(i);
            when x"7A"  => read_data(i*2+16) <= tx1_usage_cq_sym10_f(i);
            when x"7B"  => read_data(i*2+16) <= tx1_usage_cq_sym11_f(i);
            when x"7C"  => read_data(i*2+16) <= tx1_usage_cq_sym12_f(i);
            when x"7D"  => read_data(i*2+16) <= tx1_usage_cq_sym13_f(i);
            when x"7F"  => read_data(i*2+16) <= tx1_sts_cq_fsm_f(i);

            when x"80"  => read_data(i*2+16) <= tx2_cnt_cpsec_sym0_r(i);
            when x"81"  => read_data(i*2+16) <= tx2_cnt_cpsec_sym1_r(i);
            when x"82"  => read_data(i*2+16) <= tx2_cnt_cpsec_sym2_r(i);
            when x"83"  => read_data(i*2+16) <= tx2_cnt_cpsec_sym3_r(i);
            when x"84"  => read_data(i*2+16) <= tx2_cnt_cpsec_sym4_r(i);
            when x"85"  => read_data(i*2+16) <= tx2_cnt_cpsec_sym5_r(i);
            when x"86"  => read_data(i*2+16) <= tx2_cnt_cpsec_sym6_r(i);
            when x"87"  => read_data(i*2+16) <= tx2_cnt_cpsec_sym7_r(i);
            when x"88"  => read_data(i*2+16) <= tx2_cnt_cpsec_sym8_r(i);
            when x"89"  => read_data(i*2+16) <= tx2_cnt_cpsec_sym9_r(i);
            when x"8A"  => read_data(i*2+16) <= tx2_cnt_cpsec_sym10_r(i);
            when x"8B"  => read_data(i*2+16) <= tx2_cnt_cpsec_sym11_r(i);
            when x"8C"  => read_data(i*2+16) <= tx2_cnt_cpsec_sym12_r(i);
            when x"8D"  => read_data(i*2+16) <= tx2_cnt_cpsec_sym13_r(i);
            when x"8E"  => read_data(i*2+16) <= tx2_cnt_cq_conv_full_r(i);
            when x"8F"  => read_data(i*2+16) <= tx2_frame_id_r(i);

            when x"90"  => read_data(i*2+16) <= tx2_cnt_uppkt_sym0_r(i);
            when x"91"  => read_data(i*2+16) <= tx2_cnt_uppkt_sym1_r(i);
            when x"92"  => read_data(i*2+16) <= tx2_cnt_uppkt_sym2_r(i);
            when x"93"  => read_data(i*2+16) <= tx2_cnt_uppkt_sym3_r(i);
            when x"94"  => read_data(i*2+16) <= tx2_cnt_uppkt_sym4_r(i);
            when x"95"  => read_data(i*2+16) <= tx2_cnt_uppkt_sym5_r(i);
            when x"96"  => read_data(i*2+16) <= tx2_cnt_uppkt_sym6_r(i);
            when x"97"  => read_data(i*2+16) <= tx2_cnt_uppkt_sym7_r(i);
            when x"98"  => read_data(i*2+16) <= tx2_cnt_uppkt_sym8_r(i);
            when x"99"  => read_data(i*2+16) <= tx2_cnt_uppkt_sym9_r(i);
            when x"9A"  => read_data(i*2+16) <= tx2_cnt_uppkt_sym10_r(i);
            when x"9B"  => read_data(i*2+16) <= tx2_cnt_uppkt_sym11_r(i);
            when x"9C"  => read_data(i*2+16) <= tx2_cnt_uppkt_sym12_r(i);
            when x"9D"  => read_data(i*2+16) <= tx2_cnt_uppkt_sym13_r(i);

            when x"A0"  => read_data(i*2+16) <= tx2_cnt_cq_full_sym0_r(i);
            when x"A1"  => read_data(i*2+16) <= tx2_cnt_cq_full_sym1_r(i);
            when x"A2"  => read_data(i*2+16) <= tx2_cnt_cq_full_sym2_r(i);
            when x"A3"  => read_data(i*2+16) <= tx2_cnt_cq_full_sym3_r(i);
            when x"A4"  => read_data(i*2+16) <= tx2_cnt_cq_full_sym4_r(i);
            when x"A5"  => read_data(i*2+16) <= tx2_cnt_cq_full_sym5_r(i);
            when x"A6"  => read_data(i*2+16) <= tx2_cnt_cq_full_sym6_r(i);
            when x"A7"  => read_data(i*2+16) <= tx2_cnt_cq_full_sym7_r(i);
            when x"A8"  => read_data(i*2+16) <= tx2_cnt_cq_full_sym8_r(i);
            when x"A9"  => read_data(i*2+16) <= tx2_cnt_cq_full_sym9_r(i);
            when x"AA"  => read_data(i*2+16) <= tx2_cnt_cq_full_sym10_r(i);
            when x"AB"  => read_data(i*2+16) <= tx2_cnt_cq_full_sym11_r(i);
            when x"AC"  => read_data(i*2+16) <= tx2_cnt_cq_full_sym12_r(i);
            when x"AD"  => read_data(i*2+16) <= tx2_cnt_cq_full_sym13_r(i);
            when x"AF"  => read_data(i*2+16) <= tx2_cnt_cq_fsm_busy_r(i);

            when x"B0"  => read_data(i*2+16) <= tx2_usage_cq_sym0_f(i);
            when x"B1"  => read_data(i*2+16) <= tx2_usage_cq_sym1_f(i);
            when x"B2"  => read_data(i*2+16) <= tx2_usage_cq_sym2_f(i);
            when x"B3"  => read_data(i*2+16) <= tx2_usage_cq_sym3_f(i);
            when x"B4"  => read_data(i*2+16) <= tx2_usage_cq_sym4_f(i);
            when x"B5"  => read_data(i*2+16) <= tx2_usage_cq_sym5_f(i);
            when x"B6"  => read_data(i*2+16) <= tx2_usage_cq_sym6_f(i);
            when x"B7"  => read_data(i*2+16) <= tx2_usage_cq_sym7_f(i);
            when x"B8"  => read_data(i*2+16) <= tx2_usage_cq_sym8_f(i);
            when x"B9"  => read_data(i*2+16) <= tx2_usage_cq_sym9_f(i);
            when x"BA"  => read_data(i*2+16) <= tx2_usage_cq_sym10_f(i);
            when x"BB"  => read_data(i*2+16) <= tx2_usage_cq_sym11_f(i);
            when x"BC"  => read_data(i*2+16) <= tx2_usage_cq_sym12_f(i);
            when x"BD"  => read_data(i*2+16) <= tx2_usage_cq_sym13_f(i);
            when x"BF"  => read_data(i*2+16) <= tx2_sts_cq_fsm_f(i);

            when x"C0"  => read_data(i*2+16) <= tx3_cnt_cpsec_sym0_r(i);
            when x"C1"  => read_data(i*2+16) <= tx3_cnt_cpsec_sym1_r(i);
            when x"C2"  => read_data(i*2+16) <= tx3_cnt_cpsec_sym2_r(i);
            when x"C3"  => read_data(i*2+16) <= tx3_cnt_cpsec_sym3_r(i);
            when x"C4"  => read_data(i*2+16) <= tx3_cnt_cpsec_sym4_r(i);
            when x"C5"  => read_data(i*2+16) <= tx3_cnt_cpsec_sym5_r(i);
            when x"C6"  => read_data(i*2+16) <= tx3_cnt_cpsec_sym6_r(i);
            when x"C7"  => read_data(i*2+16) <= tx3_cnt_cpsec_sym7_r(i);
            when x"C8"  => read_data(i*2+16) <= tx3_cnt_cpsec_sym8_r(i);
            when x"C9"  => read_data(i*2+16) <= tx3_cnt_cpsec_sym9_r(i);
            when x"CA"  => read_data(i*2+16) <= tx3_cnt_cpsec_sym10_r(i);
            when x"CB"  => read_data(i*2+16) <= tx3_cnt_cpsec_sym11_r(i);
            when x"CC"  => read_data(i*2+16) <= tx3_cnt_cpsec_sym12_r(i);
            when x"CD"  => read_data(i*2+16) <= tx3_cnt_cpsec_sym13_r(i);
            when x"CE"  => read_data(i*2+16) <= tx3_cnt_cq_conv_full_r(i);
            when x"CF"  => read_data(i*2+16) <= tx3_frame_id_r(i);

            when x"D0"  => read_data(i*2+16) <= tx3_cnt_uppkt_sym0_r(i);
            when x"D1"  => read_data(i*2+16) <= tx3_cnt_uppkt_sym1_r(i);
            when x"D2"  => read_data(i*2+16) <= tx3_cnt_uppkt_sym2_r(i);
            when x"D3"  => read_data(i*2+16) <= tx3_cnt_uppkt_sym3_r(i);
            when x"D4"  => read_data(i*2+16) <= tx3_cnt_uppkt_sym4_r(i);
            when x"D5"  => read_data(i*2+16) <= tx3_cnt_uppkt_sym5_r(i);
            when x"D6"  => read_data(i*2+16) <= tx3_cnt_uppkt_sym6_r(i);
            when x"D7"  => read_data(i*2+16) <= tx3_cnt_uppkt_sym7_r(i);
            when x"D8"  => read_data(i*2+16) <= tx3_cnt_uppkt_sym8_r(i);
            when x"D9"  => read_data(i*2+16) <= tx3_cnt_uppkt_sym9_r(i);
            when x"DA"  => read_data(i*2+16) <= tx3_cnt_uppkt_sym10_r(i);
            when x"DB"  => read_data(i*2+16) <= tx3_cnt_uppkt_sym11_r(i);
            when x"DC"  => read_data(i*2+16) <= tx3_cnt_uppkt_sym12_r(i);
            when x"DD"  => read_data(i*2+16) <= tx3_cnt_uppkt_sym13_r(i);

            when x"E0"  => read_data(i*2+16) <= tx3_cnt_cq_full_sym0_r(i);
            when x"E1"  => read_data(i*2+16) <= tx3_cnt_cq_full_sym1_r(i);
            when x"E2"  => read_data(i*2+16) <= tx3_cnt_cq_full_sym2_r(i);
            when x"E3"  => read_data(i*2+16) <= tx3_cnt_cq_full_sym3_r(i);
            when x"E4"  => read_data(i*2+16) <= tx3_cnt_cq_full_sym4_r(i);
            when x"E5"  => read_data(i*2+16) <= tx3_cnt_cq_full_sym5_r(i);
            when x"E6"  => read_data(i*2+16) <= tx3_cnt_cq_full_sym6_r(i);
            when x"E7"  => read_data(i*2+16) <= tx3_cnt_cq_full_sym7_r(i);
            when x"E8"  => read_data(i*2+16) <= tx3_cnt_cq_full_sym8_r(i);
            when x"E9"  => read_data(i*2+16) <= tx3_cnt_cq_full_sym9_r(i);
            when x"EA"  => read_data(i*2+16) <= tx3_cnt_cq_full_sym10_r(i);
            when x"EB"  => read_data(i*2+16) <= tx3_cnt_cq_full_sym11_r(i);
            when x"EC"  => read_data(i*2+16) <= tx3_cnt_cq_full_sym12_r(i);
            when x"ED"  => read_data(i*2+16) <= tx3_cnt_cq_full_sym13_r(i);
            when x"EF"  => read_data(i*2+16) <= tx3_cnt_cq_fsm_busy_r(i);

            when x"F0"  => read_data(i*2+16) <= tx3_usage_cq_sym0_f(i);
            when x"F1"  => read_data(i*2+16) <= tx3_usage_cq_sym1_f(i);
            when x"F2"  => read_data(i*2+16) <= tx3_usage_cq_sym2_f(i);
            when x"F3"  => read_data(i*2+16) <= tx3_usage_cq_sym3_f(i);
            when x"F4"  => read_data(i*2+16) <= tx3_usage_cq_sym4_f(i);
            when x"F5"  => read_data(i*2+16) <= tx3_usage_cq_sym5_f(i);
            when x"F6"  => read_data(i*2+16) <= tx3_usage_cq_sym6_f(i);
            when x"F7"  => read_data(i*2+16) <= tx3_usage_cq_sym7_f(i);
            when x"F8"  => read_data(i*2+16) <= tx3_usage_cq_sym8_f(i);
            when x"F9"  => read_data(i*2+16) <= tx3_usage_cq_sym9_f(i);
            when x"FA"  => read_data(i*2+16) <= tx3_usage_cq_sym10_f(i);
            when x"FB"  => read_data(i*2+16) <= tx3_usage_cq_sym11_f(i);
            when x"FC"  => read_data(i*2+16) <= tx3_usage_cq_sym12_f(i);
            when x"FD"  => read_data(i*2+16) <= tx3_usage_cq_sym13_f(i);
            when x"FF"  => read_data(i*2+16) <= tx3_sts_cq_fsm_f(i);

            when others => read_data(i*2+16) <= (others => '0');
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case addr_lsb is
            when x"00"  => read_data(i*2+17) <= tx4_cnt_cpsec_sym0_r(i);
            when x"01"  => read_data(i*2+17) <= tx4_cnt_cpsec_sym1_r(i);
            when x"02"  => read_data(i*2+17) <= tx4_cnt_cpsec_sym2_r(i);
            when x"03"  => read_data(i*2+17) <= tx4_cnt_cpsec_sym3_r(i);
            when x"04"  => read_data(i*2+17) <= tx4_cnt_cpsec_sym4_r(i);
            when x"05"  => read_data(i*2+17) <= tx4_cnt_cpsec_sym5_r(i);
            when x"06"  => read_data(i*2+17) <= tx4_cnt_cpsec_sym6_r(i);
            when x"07"  => read_data(i*2+17) <= tx4_cnt_cpsec_sym7_r(i);
            when x"08"  => read_data(i*2+17) <= tx4_cnt_cpsec_sym8_r(i);
            when x"09"  => read_data(i*2+17) <= tx4_cnt_cpsec_sym9_r(i);
            when x"0A"  => read_data(i*2+17) <= tx4_cnt_cpsec_sym10_r(i);
            when x"0B"  => read_data(i*2+17) <= tx4_cnt_cpsec_sym11_r(i);
            when x"0C"  => read_data(i*2+17) <= tx4_cnt_cpsec_sym12_r(i);
            when x"0D"  => read_data(i*2+17) <= tx4_cnt_cpsec_sym13_r(i);
            when x"0E"  => read_data(i*2+17) <= tx4_cnt_cq_conv_full_r(i);
            when x"0F"  => read_data(i*2+17) <= tx4_frame_id_r(i);

            when x"10"  => read_data(i*2+17) <= tx4_cnt_uppkt_sym0_r(i);
            when x"11"  => read_data(i*2+17) <= tx4_cnt_uppkt_sym1_r(i);
            when x"12"  => read_data(i*2+17) <= tx4_cnt_uppkt_sym2_r(i);
            when x"13"  => read_data(i*2+17) <= tx4_cnt_uppkt_sym3_r(i);
            when x"14"  => read_data(i*2+17) <= tx4_cnt_uppkt_sym4_r(i);
            when x"15"  => read_data(i*2+17) <= tx4_cnt_uppkt_sym5_r(i);
            when x"16"  => read_data(i*2+17) <= tx4_cnt_uppkt_sym6_r(i);
            when x"17"  => read_data(i*2+17) <= tx4_cnt_uppkt_sym7_r(i);
            when x"18"  => read_data(i*2+17) <= tx4_cnt_uppkt_sym8_r(i);
            when x"19"  => read_data(i*2+17) <= tx4_cnt_uppkt_sym9_r(i);
            when x"1A"  => read_data(i*2+17) <= tx4_cnt_uppkt_sym10_r(i);
            when x"1B"  => read_data(i*2+17) <= tx4_cnt_uppkt_sym11_r(i);
            when x"1C"  => read_data(i*2+17) <= tx4_cnt_uppkt_sym12_r(i);
            when x"1D"  => read_data(i*2+17) <= tx4_cnt_uppkt_sym13_r(i);

            when x"20"  => read_data(i*2+17) <= tx4_cnt_cq_full_sym0_r(i);
            when x"21"  => read_data(i*2+17) <= tx4_cnt_cq_full_sym1_r(i);
            when x"22"  => read_data(i*2+17) <= tx4_cnt_cq_full_sym2_r(i);
            when x"23"  => read_data(i*2+17) <= tx4_cnt_cq_full_sym3_r(i);
            when x"24"  => read_data(i*2+17) <= tx4_cnt_cq_full_sym4_r(i);
            when x"25"  => read_data(i*2+17) <= tx4_cnt_cq_full_sym5_r(i);
            when x"26"  => read_data(i*2+17) <= tx4_cnt_cq_full_sym6_r(i);
            when x"27"  => read_data(i*2+17) <= tx4_cnt_cq_full_sym7_r(i);
            when x"28"  => read_data(i*2+17) <= tx4_cnt_cq_full_sym8_r(i);
            when x"29"  => read_data(i*2+17) <= tx4_cnt_cq_full_sym9_r(i);
            when x"2A"  => read_data(i*2+17) <= tx4_cnt_cq_full_sym10_r(i);
            when x"2B"  => read_data(i*2+17) <= tx4_cnt_cq_full_sym11_r(i);
            when x"2C"  => read_data(i*2+17) <= tx4_cnt_cq_full_sym12_r(i);
            when x"2D"  => read_data(i*2+17) <= tx4_cnt_cq_full_sym13_r(i);
            when x"2F"  => read_data(i*2+17) <= tx4_cnt_cq_fsm_busy_r(i);

            when x"30"  => read_data(i*2+17) <= tx4_usage_cq_sym0_f(i);
            when x"31"  => read_data(i*2+17) <= tx4_usage_cq_sym1_f(i);
            when x"32"  => read_data(i*2+17) <= tx4_usage_cq_sym2_f(i);
            when x"33"  => read_data(i*2+17) <= tx4_usage_cq_sym3_f(i);
            when x"34"  => read_data(i*2+17) <= tx4_usage_cq_sym4_f(i);
            when x"35"  => read_data(i*2+17) <= tx4_usage_cq_sym5_f(i);
            when x"36"  => read_data(i*2+17) <= tx4_usage_cq_sym6_f(i);
            when x"37"  => read_data(i*2+17) <= tx4_usage_cq_sym7_f(i);
            when x"38"  => read_data(i*2+17) <= tx4_usage_cq_sym8_f(i);
            when x"39"  => read_data(i*2+17) <= tx4_usage_cq_sym9_f(i);
            when x"3A"  => read_data(i*2+17) <= tx4_usage_cq_sym10_f(i);
            when x"3B"  => read_data(i*2+17) <= tx4_usage_cq_sym11_f(i);
            when x"3C"  => read_data(i*2+17) <= tx4_usage_cq_sym12_f(i);
            when x"3D"  => read_data(i*2+17) <= tx4_usage_cq_sym13_f(i);
            when x"3F"  => read_data(i*2+17) <= tx4_sts_cq_fsm_f(i);

--            when x"40"  => read_data(i*2+17) <= tx5_cnt_cpsec_sym0_r(i);
--            when x"41"  => read_data(i*2+17) <= tx5_cnt_cpsec_sym1_r(i);
--            when x"42"  => read_data(i*2+17) <= tx5_cnt_cpsec_sym2_r(i);
--            when x"43"  => read_data(i*2+17) <= tx5_cnt_cpsec_sym3_r(i);
--            when x"44"  => read_data(i*2+17) <= tx5_cnt_cpsec_sym4_r(i);
--            when x"45"  => read_data(i*2+17) <= tx5_cnt_cpsec_sym5_r(i);
--            when x"46"  => read_data(i*2+17) <= tx5_cnt_cpsec_sym6_r(i);
--            when x"47"  => read_data(i*2+17) <= tx5_cnt_cpsec_sym7_r(i);
--            when x"48"  => read_data(i*2+17) <= tx5_cnt_cpsec_sym8_r(i);
--            when x"49"  => read_data(i*2+17) <= tx5_cnt_cpsec_sym9_r(i);
--            when x"4A"  => read_data(i*2+17) <= tx5_cnt_cpsec_sym10_r(i);
--            when x"4B"  => read_data(i*2+17) <= tx5_cnt_cpsec_sym11_r(i);
--            when x"4C"  => read_data(i*2+17) <= tx5_cnt_cpsec_sym12_r(i);
--            when x"4D"  => read_data(i*2+17) <= tx5_cnt_cpsec_sym13_r(i);
--            when x"4E"  => read_data(i*2+17) <= tx5_cnt_cq_conv_full_r(i);
--            when x"4F"  => read_data(i*2+17) <= tx5_frame_id_r(i);
--
--            when x"50"  => read_data(i*2+17) <= tx5_cnt_uppkt_sym0_r(i);
--            when x"51"  => read_data(i*2+17) <= tx5_cnt_uppkt_sym1_r(i);
--            when x"52"  => read_data(i*2+17) <= tx5_cnt_uppkt_sym2_r(i);
--            when x"53"  => read_data(i*2+17) <= tx5_cnt_uppkt_sym3_r(i);
--            when x"54"  => read_data(i*2+17) <= tx5_cnt_uppkt_sym4_r(i);
--            when x"55"  => read_data(i*2+17) <= tx5_cnt_uppkt_sym5_r(i);
--            when x"56"  => read_data(i*2+17) <= tx5_cnt_uppkt_sym6_r(i);
--            when x"57"  => read_data(i*2+17) <= tx5_cnt_uppkt_sym7_r(i);
--            when x"58"  => read_data(i*2+17) <= tx5_cnt_uppkt_sym8_r(i);
--            when x"59"  => read_data(i*2+17) <= tx5_cnt_uppkt_sym9_r(i);
--            when x"5A"  => read_data(i*2+17) <= tx5_cnt_uppkt_sym10_r(i);
--            when x"5B"  => read_data(i*2+17) <= tx5_cnt_uppkt_sym11_r(i);
--            when x"5C"  => read_data(i*2+17) <= tx5_cnt_uppkt_sym12_r(i);
--            when x"5D"  => read_data(i*2+17) <= tx5_cnt_uppkt_sym13_r(i);
--
--            when x"60"  => read_data(i*2+17) <= tx5_cnt_cq_full_sym0_r(i);
--            when x"61"  => read_data(i*2+17) <= tx5_cnt_cq_full_sym1_r(i);
--            when x"62"  => read_data(i*2+17) <= tx5_cnt_cq_full_sym2_r(i);
--            when x"63"  => read_data(i*2+17) <= tx5_cnt_cq_full_sym3_r(i);
--            when x"64"  => read_data(i*2+17) <= tx5_cnt_cq_full_sym4_r(i);
--            when x"65"  => read_data(i*2+17) <= tx5_cnt_cq_full_sym5_r(i);
--            when x"66"  => read_data(i*2+17) <= tx5_cnt_cq_full_sym6_r(i);
--            when x"67"  => read_data(i*2+17) <= tx5_cnt_cq_full_sym7_r(i);
--            when x"68"  => read_data(i*2+17) <= tx5_cnt_cq_full_sym8_r(i);
--            when x"69"  => read_data(i*2+17) <= tx5_cnt_cq_full_sym9_r(i);
--            when x"6A"  => read_data(i*2+17) <= tx5_cnt_cq_full_sym10_r(i);
--            when x"6B"  => read_data(i*2+17) <= tx5_cnt_cq_full_sym11_r(i);
--            when x"6C"  => read_data(i*2+17) <= tx5_cnt_cq_full_sym12_r(i);
--            when x"6D"  => read_data(i*2+17) <= tx5_cnt_cq_full_sym13_r(i);
--            when x"6F"  => read_data(i*2+17) <= tx5_cnt_cq_fsm_busy_r(i);
--
--            when x"70"  => read_data(i*2+17) <= tx5_usage_cq_sym0_f(i);
--            when x"71"  => read_data(i*2+17) <= tx5_usage_cq_sym1_f(i);
--            when x"72"  => read_data(i*2+17) <= tx5_usage_cq_sym2_f(i);
--            when x"73"  => read_data(i*2+17) <= tx5_usage_cq_sym3_f(i);
--            when x"74"  => read_data(i*2+17) <= tx5_usage_cq_sym4_f(i);
--            when x"75"  => read_data(i*2+17) <= tx5_usage_cq_sym5_f(i);
--            when x"76"  => read_data(i*2+17) <= tx5_usage_cq_sym6_f(i);
--            when x"77"  => read_data(i*2+17) <= tx5_usage_cq_sym7_f(i);
--            when x"78"  => read_data(i*2+17) <= tx5_usage_cq_sym8_f(i);
--            when x"79"  => read_data(i*2+17) <= tx5_usage_cq_sym9_f(i);
--            when x"7A"  => read_data(i*2+17) <= tx5_usage_cq_sym10_f(i);
--            when x"7B"  => read_data(i*2+17) <= tx5_usage_cq_sym11_f(i);
--            when x"7C"  => read_data(i*2+17) <= tx5_usage_cq_sym12_f(i);
--            when x"7D"  => read_data(i*2+17) <= tx5_usage_cq_sym13_f(i);
--            when x"7F"  => read_data(i*2+17) <= tx5_sts_cq_fsm_f(i);

            when others => read_data(i*2+17) <= (others => '0');
            end case;
        end if;
    end process;
    end generate;

--    process (CLK)
--    begin
--        if (CLK'event and CLK = '1') then
--            case addr_lsb is
--            when x"00"  => read_data(17) <= EXT(FREQ_OFFSET_FOR_PRACH0(0), 32);
--            when x"01"  => read_data(17) <= EXT(FREQ_OFFSET_FOR_PRACH0(1), 32);
--            when x"02"  => read_data(17) <= EXT(FREQ_OFFSET_FOR_PRACH0(2), 32);
--            when x"03"  => read_data(17) <= EXT(FREQ_OFFSET_FOR_PRACH0(3), 32);
--            when x"04"  => read_data(17) <= EXT(FREQ_OFFSET_FOR_PRACH0(4), 32);
--            when x"05"  => read_data(17) <= EXT(FREQ_OFFSET_FOR_PRACH0(5), 32);
--            when x"06"  => read_data(17) <= EXT(FREQ_OFFSET_FOR_PRACH0(6), 32);
--            when x"07"  => read_data(17) <= EXT(FREQ_OFFSET_FOR_PRACH0(7), 32);
--            when x"08"  => read_data(17) <= EXT(FREQ_OFFSET_FOR_PRACH1(0), 32);
--            when x"09"  => read_data(17) <= EXT(FREQ_OFFSET_FOR_PRACH1(1), 32);
--            when x"0A"  => read_data(17) <= EXT(FREQ_OFFSET_FOR_PRACH1(2), 32);
--            when x"0B"  => read_data(17) <= EXT(FREQ_OFFSET_FOR_PRACH1(3), 32);
--            when x"0C"  => read_data(17) <= EXT(FREQ_OFFSET_FOR_PRACH1(4), 32);
--            when x"0D"  => read_data(17) <= EXT(FREQ_OFFSET_FOR_PRACH1(5), 32);
--            when x"0E"  => read_data(17) <= EXT(FREQ_OFFSET_FOR_PRACH1(6), 32);
--            when x"0F"  => read_data(17) <= EXT(FREQ_OFFSET_FOR_PRACH1(7), 32);
--
--            when others => read_data(17) <= (others => '0');
--            end case;
--        end if;
--    end process;

--------------------------------------------------------------------------------
-- Indirect access
--------------------------------------------------------------------------------

    set_dl_data_type_r              <= "010" when (set_dl_data_type_w = 2) and (IMPL_H_MATRIX = true) else
                                       "001" when (set_dl_data_type_w = 1) and (IMPL_SSB = true) else
                                       "000" when (set_dl_data_type_w = 0) and (IMPL_PDxCH = true) else
                                       (others => '1');

    sts_dl_data_type_r              <= "010" when (sts_dl_data_type_w = 2) and (IMPL_H_MATRIX = true) else
                                       "001" when (sts_dl_data_type_w = 1) and (IMPL_SSB = true) else
                                       "000" when (sts_dl_data_type_w = 0) and (IMPL_PDxCH = true) else
                                       (others => '1');

    max_dl_index_r(15 downto 0)     <= conv_std_logic_vector(MAX_CC_DL, 8) & conv_std_logic_vector(MAX_H_MATRIX, 8) when (set_dl_data_type_r = 2) and (IMPL_H_MATRIX = true) else
                                       conv_std_logic_vector(MAX_CC_DL, 8) & conv_std_logic_vector(MAX_SSB, 8)      when (set_dl_data_type_r = 1) and (IMPL_SSB = true) else
                                       conv_std_logic_vector(MAX_CC_DL, 8) & conv_std_logic_vector(MAX_PDxCH, 8)    when (set_dl_data_type_r = 0) and (IMPL_PDxCH = true) else
                                       (others => '0');

    set_ul_data_type_r              <= "100" when (set_ul_data_type_w = 4) and (IMPL_NB_IoT = true) else
                                       "011" when (set_ul_data_type_w = 3) and (IMPL_RIM_RS = true) else
                                       "010" when (set_ul_data_type_w = 2) and (IMPL_SRS = true) else
                                       "001" when (set_ul_data_type_w = 1) and (IMPL_PRACH = true) else
                                       "000" when (set_ul_data_type_w = 0) and (IMPL_PUxCH = true) else
                                       (others => '1');

    sts_ul_data_type_r              <= "100" when (sts_ul_data_type_w = 4) and (IMPL_NB_IoT = true) else
                                       "011" when (sts_ul_data_type_w = 3) and (IMPL_RIM_RS = true) else
                                       "010" when (sts_ul_data_type_w = 2) and (IMPL_SRS = true) else
                                       "001" when (sts_ul_data_type_w = 1) and (IMPL_PRACH = true) else
                                       "000" when (sts_ul_data_type_w = 0) and (IMPL_PUxCH = true) else
                                       (others => '1');

    max_ul_index_r(15 downto 0)     <= conv_std_logic_vector(MAX_CC_UL, 8) & conv_std_logic_vector(MAX_NB_IoT, 8)   when (set_ul_data_type_r = 4) and (IMPL_NB_IoT = true) else
                                       conv_std_logic_vector(MAX_CC_UL, 8) & conv_std_logic_vector(MAX_RIM_RS, 8)   when (set_ul_data_type_r = 3) and (IMPL_RIM_RS = true) else
                                       conv_std_logic_vector(MAX_CC_UL, 8) & conv_std_logic_vector(MAX_SRS, 8)      when (set_ul_data_type_r = 2) and (IMPL_SRS = true) else
                                       conv_std_logic_vector(MAX_CC_UL, 8) & conv_std_logic_vector(MAX_PRACH, 8)    when (set_ul_data_type_r = 1) and (IMPL_PRACH = true) else
                                       conv_std_logic_vector(MAX_CC_UL, 8) & conv_std_logic_vector(MAX_PUxCH, 8)    when (set_ul_data_type_r = 0) and (IMPL_PUxCH = true) else
                                       (others => '0');

    max_pe_index_r                  <= conv_std_logic_vector(MAX_PE, 32);

--------------------------------------------------------------------------------
-- In/output port mapping
--------------------------------------------------------------------------------

    USER_DEBUG0                     <= user_debug0_r;
    USER_DEBUG1                     <= user_debug1_r;
    USER_DEBUG2                     <= user_debug2_r;
    USER_DEBUG3                     <= user_debug3_r;

    DL_UPLANE_ONLY_EN               <= dl_uplane_only_en_w(0);
    dl_uplane_only_en_r(0)          <= dl_uplane_only_en_w(0);

    DSS_PARAM_TEST_PATTERN_EN       <= dss_test_en_w(0);
    dss_test_en_r(0)                <= dss_test_en_w(0);
    coeff_vld_cnt_r(0)              <= I_CC0_COEFF_VLD_CNT;
    coeff_vld_cnt_r(1)              <= I_CC1_COEFF_VLD_CNT;
    coeff_idx_mon_r(0)              <= I_CC0_COEFF_IDX_MON;
    coeff_idx_mon_r(1)              <= I_CC1_COEFF_IDX_MON;

    u_OUTPUT_LINK : for i in 7 downto 0 generate
    u_LOOP_INDEX : for j in 63 downto 0 generate
    DL_PARAM_ID_EN(i)(j)            <= dl_eaxc_id_w(i)(j)(16);
    DL_PARAM_ID(i)(j)               <= dl_eaxc_id_w(i)(j)(15 downto 0);
    DL_PE_INDEX(i)(j)               <= VALUE8_TO_BIT8(dl_pe_index_w(i)(j)(2 downto 0));
    DL_COMP_MODE(i)(j)              <= dl_comp_mode_w(i)(j)(8);
    DL_IQ_WIDTH(i)(j)               <= dl_comp_mode_w(i)(j)(7 downto 4);
    DL_COMP_METHOD(i)(j)            <= dl_comp_mode_w(i)(j)(3 downto 0);
    DL_SCS_CONFIG(i)(j)             <= dl_frame_structure_w(i)(j)(3 downto 0);
    DL_FFT_SIZE(i)(j)               <= dl_frame_structure_w(i)(j)(7 downto 4);
    DL_PRB_PER_SYMBOL(i)(j)         <= dl_prb_per_symbol_w(i)(j)(9 downto 0);
    DL_COMP_EXP_OFFSET(i)(j)        <= dl_comp_exp_offset_w(i)(0)(4 downto 0);

    UL_PARAM_ID_EN(i)(j)            <= ul_eaxc_id_w(i)(j)(16);
    UL_PARAM_ID(i)(j)               <= ul_eaxc_id_w(i)(j)(15 downto 0);
    UL_PE_INDEX(i)(j)               <= VALUE8_TO_BIT8(ul_pe_index_w(i)(j)(2 downto 0));
    UL_COMP_MODE(i)(j)              <= ul_comp_mode_w(i)(j)(8);
    UL_IQ_WIDTH(i)(j)               <= ul_comp_mode_w(i)(j)(7 downto 4);
    UL_COMP_METHOD(i)(j)            <= ul_comp_mode_w(i)(j)(3 downto 0);
    UL_SCS_CONFIG(i)(j)             <= ul_frame_structure_w(i)(j)(3 downto 0);
    UL_FFT_SIZE(i)(j)               <= ul_frame_structure_w(i)(j)(7 downto 4);
    UL_PRB_PER_SYMBOL(i)(j)         <= ul_prb_per_symbol_w(i)(j)(9 downto 0);
    UL_PRB_PER_MTU(i)(j)            <= ul_prb_per_mtu_w(i)(j)(9 downto 0);
    UL_COMP_EXP_OFFSET(i)(j)        <= ul_comp_exp_offset_w(i)(j)(4 downto 0);
    UL_COMP_GAIN_OFFSET(i)(j)       <= ul_comp_gain_offset_w(i)(j)(10 downto 0);
    UL_COMP_SCALE_GAIN_OFFSET(i)(j) <= ul_comp_scale_gain_offset_w(i)(j)(3 downto 0);
    end generate;
    end generate;

    u_OUTPUT_PE : for i in 7 downto 0 generate
    PARAM_RU_MAC(i)                 <= ru_mac_47_to_32_w(i)(15 downto 0) & ru_mac_31_to_0_w(i);
    PARAM_PORT_INDEX(i)             <= (others => '0');                     -- should be implemented
    PARAM_DU_MAC(i)                 <= du_mac_47_to_32_w(i)(15 downto 0) & du_mac_31_to_0_w(i);
    PARAM_VLAN0_EN(i)               <= vlan0_vid_w(i)(16);
    PARAM_VLAN0_VID(i)              <= vlan0_vid_w(i)(11 downto 0);
    PARAM_VLAN1_EN(i)               <= '0';             -- vlan1_vid_w(0)(i)(16);
    PARAM_VLAN1_VID(i)              <= (others => '0'); -- vlan1_vid_w(0)(i)(11 downto 0);

    CAPTURE_PERIOD(i)               <= capture_period_w(i)(7 downto 0);

    T2A_MAX_DL_CP_RX(i)(0)          <= t2a_max0_dl_cp_rx_w(i)(21 downto 0);
    T2A_MIN_DL_CP_RX(i)(0)          <= t2a_min0_dl_cp_rx_w(i)(21 downto 0);
    T2A_MAX_DL_CP_RX(i)(1)          <= t2a_max1_dl_cp_rx_w(i)(21 downto 0);
    T2A_MIN_DL_CP_RX(i)(1)          <= t2a_min1_dl_cp_rx_w(i)(21 downto 0);
    T2A_MAX_DL_CP_RX(i)(2)          <= t2a_max2_dl_cp_rx_w(i)(21 downto 0);
    T2A_MIN_DL_CP_RX(i)(2)          <= t2a_min2_dl_cp_rx_w(i)(21 downto 0);
    T2A_MAX_DL_CP_RX(i)(3)          <= t2a_max3_dl_cp_rx_w(i)(21 downto 0);
    T2A_MIN_DL_CP_RX(i)(3)          <= t2a_min3_dl_cp_rx_w(i)(21 downto 0);
    T2A_MAX_DL_CP_RX(i)(4)          <= t2a_max4_dl_cp_rx_w(i)(21 downto 0);
    T2A_MIN_DL_CP_RX(i)(4)          <= t2a_min4_dl_cp_rx_w(i)(21 downto 0);

    T2A_MAX_DL_UP_RX(i)(0)          <= t2a_max0_dl_up_rx_w(i)(21 downto 0);
    T2A_MIN_DL_UP_RX(i)(0)          <= t2a_min0_dl_up_rx_w(i)(21 downto 0);
    T2A_MAX_DL_UP_RX(i)(1)          <= t2a_max1_dl_up_rx_w(i)(21 downto 0);
    T2A_MIN_DL_UP_RX(i)(1)          <= t2a_min1_dl_up_rx_w(i)(21 downto 0);
    T2A_MAX_DL_UP_RX(i)(2)          <= t2a_max2_dl_up_rx_w(i)(21 downto 0);
    T2A_MIN_DL_UP_RX(i)(2)          <= t2a_min2_dl_up_rx_w(i)(21 downto 0);
    T2A_MAX_DL_UP_RX(i)(3)          <= t2a_max3_dl_up_rx_w(i)(21 downto 0);
    T2A_MIN_DL_UP_RX(i)(3)          <= t2a_min3_dl_up_rx_w(i)(21 downto 0);
    T2A_MAX_DL_UP_RX(i)(4)          <= t2a_max4_dl_up_rx_w(i)(21 downto 0);
    T2A_MIN_DL_UP_RX(i)(4)          <= t2a_min4_dl_up_rx_w(i)(21 downto 0);

    T2A_MAX_UL_CP_RX(i)(0)          <= t2a_max0_ul_cp_rx_w(i)(21 downto 0);
    T2A_MIN_UL_CP_RX(i)(0)          <= t2a_min0_ul_cp_rx_w(i)(21 downto 0);
    T2A_MAX_UL_CP_RX(i)(1)          <= t2a_max1_ul_cp_rx_w(i)(21 downto 0);
    T2A_MIN_UL_CP_RX(i)(1)          <= t2a_min1_ul_cp_rx_w(i)(21 downto 0);
    T2A_MAX_UL_CP_RX(i)(2)          <= t2a_max2_ul_cp_rx_w(i)(21 downto 0);
    T2A_MIN_UL_CP_RX(i)(2)          <= t2a_min2_ul_cp_rx_w(i)(21 downto 0);
    T2A_MAX_UL_CP_RX(i)(3)          <= t2a_max3_ul_cp_rx_w(i)(21 downto 0);
    T2A_MIN_UL_CP_RX(i)(3)          <= t2a_min3_ul_cp_rx_w(i)(21 downto 0);
    T2A_MAX_UL_CP_RX(i)(4)          <= t2a_max4_ul_cp_rx_w(i)(21 downto 0);
    T2A_MIN_UL_CP_RX(i)(4)          <= t2a_min4_ul_cp_rx_w(i)(21 downto 0);
    end generate;

    u_INPUT_PE : for i in MAX_PE-1 downto 0 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            rx_on_time_c_w(i) <= DL_CP_SCS0_RX_ON_TIME(i) + UL_CP_SCS0_RX_ON_TIME(i);
            rx_early_c_w(i)   <= DL_CP_SCS0_RX_EARLY(i)   + UL_CP_SCS0_RX_EARLY(i);
            rx_late_c_w(i)    <= DL_CP_SCS0_RX_LATE(i)    + UL_CP_SCS0_RX_LATE(i);
        end if;
    end process;

--    process (CLK)
--    begin
--        if (CLK'event and CLK = '1') then
            rx_on_time_u_w(i) <= DL_UP_SCS0_RX_ON_TIME(i);
            rx_early_u_w(i)   <= DL_UP_SCS0_RX_EARLY(i);
            rx_late_u_w(i)    <= DL_UP_SCS0_RX_LATE(i);
--        end if;
--    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            rx_total_u_w(i)   <= rx_on_time_u_w(i) + rx_early_u_w(i) + rx_late_u_w(i);
            rx_total_c_w(i)   <= rx_on_time_c_w(i) + rx_early_c_w(i) + rx_late_c_w(i);
        end if;
    end process;

--    process (CLK)
--    begin
--        if (CLK'event and CLK = '1') then
            rx_total_w(i)     <= rx_total_u_w(i) + rx_total_c_w(i);
--        end if;
--    end process;

--    process (CLK)
--    begin
--        if (CLK'event and CLK = '1') then
            rx_total_upper_w(i)     <= rx_total_w(i)(63 downto 32);
            rx_total_lower_w(i)     <= rx_total_w(i)(31 downto 0);

            rx_on_time_u_upper_w(i) <= rx_on_time_u_w(i)(63 downto 32);
            rx_on_time_u_lower_w(i) <= rx_on_time_u_w(i)(31 downto 0);
            rx_early_u_upper_w(i)   <= rx_early_u_w(i)(63 downto 32);
            rx_early_u_lower_w(i)   <= rx_early_u_w(i)(31 downto 0);
            rx_late_u_upper_w(i)    <= rx_late_u_w(i)(63 downto 32);
            rx_late_u_lower_w(i)    <= rx_late_u_w(i)(31 downto 0);

            rx_on_time_c_upper_w(i) <= rx_on_time_c_w(i)(63 downto 32);
            rx_on_time_c_lower_w(i) <= rx_on_time_c_w(i)(31 downto 0);
            rx_early_c_upper_w(i)   <= rx_early_c_w(i)(63 downto 32);
            rx_early_c_lower_w(i)   <= rx_early_c_w(i)(31 downto 0);
            rx_late_c_upper_w(i)    <= rx_late_c_w(i)(63 downto 32);
            rx_late_c_lower_w(i)    <= rx_late_c_w(i)(31 downto 0);
--        end if;
--    end process;

    s_w_cnt_rx_corrupt_upper(i)						    <= CNT_RX_CORRUPT(i)(63 downto 32);
    s_w_cnt_rx_corrupt_lower(i)						    <= CNT_RX_CORRUPT(i)(31 downto 0);
    s_w_cnt_rx_corrupt_sectionid_upper(i)			    <= CNT_RX_SECTIONID(i)(63 downto 32);
    s_w_cnt_rx_corrupt_sectionid_lower(i)			    <= CNT_RX_SECTIONID(i)(31 downto 0);
    s_w_cnt_rx_corrupt_pcid_ecpriv_payloadv_upper(i)	<= CNT_RX_PCID_eCPRIVERSION_PAYLOADVERSION(i)(63 downto 32);
    s_w_cnt_rx_corrupt_pcid_ecpriv_payloadv_lower(i)	<= CNT_RX_PCID_eCPRIVERSION_PAYLOADVERSION(i)(31 downto 0);
    s_w_cnt_rx_corrupt_ecpriv_upper(i)				    <= CNT_RX_eCPRIVERSION(i)(63 downto 32);
    s_w_cnt_rx_corrupt_ecpriv_lower(i)				    <= CNT_RX_eCPRIVERSION(i)(31 downto 0);
    s_w_cnt_rx_corrupt_pcid_upper(i)					<= CNT_RX_PCID(i)(63 downto 32);
    s_w_cnt_rx_corrupt_pcid_lower(i)					<= CNT_RX_PCID(i)(31 downto 0);
    s_w_cnt_rx_corrupt_payloadv_upper(i)				<= CNT_RX_PAYLOADVERSION(i)(63 downto 32);
    s_w_cnt_rx_corrupt_payloadv_lower(i)				<= CNT_RX_PAYLOADVERSION(i)(31 downto 0);
        
    dl_cp_rx_on_time0_upper_w(i)    <= DL_CP_SCS0_RX_ON_TIME(i)(63 downto 32);
    dl_cp_rx_on_time0_lower_w(i)    <= DL_CP_SCS0_RX_ON_TIME(i)(31 downto 0);
    dl_cp_rx_on_time1_upper_w(i)    <= DL_CP_SCS1_RX_ON_TIME(i)(63 downto 32);
    dl_cp_rx_on_time1_lower_w(i)    <= DL_CP_SCS1_RX_ON_TIME(i)(31 downto 0);
    dl_cp_rx_on_time2_upper_w(i)    <= DL_CP_SCS2_RX_ON_TIME(i)(63 downto 32);
    dl_cp_rx_on_time2_lower_w(i)    <= DL_CP_SCS2_RX_ON_TIME(i)(31 downto 0);
    dl_cp_rx_on_time3_upper_w(i)    <= DL_CP_SCS3_RX_ON_TIME(i)(63 downto 32);
    dl_cp_rx_on_time3_lower_w(i)    <= DL_CP_SCS3_RX_ON_TIME(i)(31 downto 0);
    dl_cp_rx_on_time4_upper_w(i)    <= DL_CP_SCS4_RX_ON_TIME(i)(63 downto 32);
    dl_cp_rx_on_time4_lower_w(i)    <= DL_CP_SCS4_RX_ON_TIME(i)(31 downto 0);
    dl_cp_rx_early0_upper_w(i)      <= DL_CP_SCS0_RX_EARLY(i)(63 downto 32);
    dl_cp_rx_early0_lower_w(i)      <= DL_CP_SCS0_RX_EARLY(i)(31 downto 0);
    dl_cp_rx_early1_upper_w(i)      <= DL_CP_SCS1_RX_EARLY(i)(63 downto 32);
    dl_cp_rx_early1_lower_w(i)      <= DL_CP_SCS1_RX_EARLY(i)(31 downto 0);
    dl_cp_rx_early2_upper_w(i)      <= DL_CP_SCS2_RX_EARLY(i)(63 downto 32);
    dl_cp_rx_early2_lower_w(i)      <= DL_CP_SCS2_RX_EARLY(i)(31 downto 0);
    dl_cp_rx_early3_upper_w(i)      <= DL_CP_SCS3_RX_EARLY(i)(63 downto 32);
    dl_cp_rx_early3_lower_w(i)      <= DL_CP_SCS3_RX_EARLY(i)(31 downto 0);
    dl_cp_rx_early4_upper_w(i)      <= DL_CP_SCS4_RX_EARLY(i)(63 downto 32);
    dl_cp_rx_early4_lower_w(i)      <= DL_CP_SCS4_RX_EARLY(i)(31 downto 0);
    dl_cp_rx_late0_upper_w(i)       <= DL_CP_SCS0_RX_LATE(i)(63 downto 32);
    dl_cp_rx_late0_lower_w(i)       <= DL_CP_SCS0_RX_LATE(i)(31 downto 0);
    dl_cp_rx_late1_upper_w(i)       <= DL_CP_SCS1_RX_LATE(i)(63 downto 32);
    dl_cp_rx_late1_lower_w(i)       <= DL_CP_SCS1_RX_LATE(i)(31 downto 0);
    dl_cp_rx_late2_upper_w(i)       <= DL_CP_SCS2_RX_LATE(i)(63 downto 32);
    dl_cp_rx_late2_lower_w(i)       <= DL_CP_SCS2_RX_LATE(i)(31 downto 0);
    dl_cp_rx_late3_upper_w(i)       <= DL_CP_SCS3_RX_LATE(i)(63 downto 32);
    dl_cp_rx_late3_lower_w(i)       <= DL_CP_SCS3_RX_LATE(i)(31 downto 0);
    dl_cp_rx_late4_upper_w(i)       <= DL_CP_SCS4_RX_LATE(i)(63 downto 32);
    dl_cp_rx_late4_lower_w(i)       <= DL_CP_SCS4_RX_LATE(i)(31 downto 0);
    dl_cp_rx_ndm0_upper_w(i)        <= DL_CP_SCS0_RX_NDM(i)(63 downto 32);
    dl_cp_rx_ndm0_lower_w(i)        <= DL_CP_SCS0_RX_NDM(i)(31 downto 0);
    dl_cp_rx_ndm1_upper_w(i)        <= DL_CP_SCS1_RX_NDM(i)(63 downto 32);
    dl_cp_rx_ndm1_lower_w(i)        <= DL_CP_SCS1_RX_NDM(i)(31 downto 0);
    dl_cp_rx_ndm2_upper_w(i)        <= DL_CP_SCS2_RX_NDM(i)(63 downto 32);
    dl_cp_rx_ndm2_lower_w(i)        <= DL_CP_SCS2_RX_NDM(i)(31 downto 0);
    dl_cp_rx_ndm3_upper_w(i)        <= DL_CP_SCS3_RX_NDM(i)(63 downto 32);
    dl_cp_rx_ndm3_lower_w(i)        <= DL_CP_SCS3_RX_NDM(i)(31 downto 0);
    dl_cp_rx_ndm4_upper_w(i)        <= DL_CP_SCS4_RX_NDM(i)(63 downto 32);
    dl_cp_rx_ndm4_lower_w(i)        <= DL_CP_SCS4_RX_NDM(i)(31 downto 0);

    dl_up_rx_on_time0_upper_w(i)    <= DL_UP_SCS0_RX_ON_TIME(i)(63 downto 32);
    dl_up_rx_on_time0_lower_w(i)    <= DL_UP_SCS0_RX_ON_TIME(i)(31 downto 0);
    dl_up_rx_on_time1_upper_w(i)    <= DL_UP_SCS1_RX_ON_TIME(i)(63 downto 32);
    dl_up_rx_on_time1_lower_w(i)    <= DL_UP_SCS1_RX_ON_TIME(i)(31 downto 0);
    dl_up_rx_on_time2_upper_w(i)    <= DL_UP_SCS2_RX_ON_TIME(i)(63 downto 32);
    dl_up_rx_on_time2_lower_w(i)    <= DL_UP_SCS2_RX_ON_TIME(i)(31 downto 0);
    dl_up_rx_on_time3_upper_w(i)    <= DL_UP_SCS3_RX_ON_TIME(i)(63 downto 32);
    dl_up_rx_on_time3_lower_w(i)    <= DL_UP_SCS3_RX_ON_TIME(i)(31 downto 0);
    dl_up_rx_on_time4_upper_w(i)    <= DL_UP_SCS4_RX_ON_TIME(i)(63 downto 32);
    dl_up_rx_on_time4_lower_w(i)    <= DL_UP_SCS4_RX_ON_TIME(i)(31 downto 0);
    dl_up_rx_early0_upper_w(i)      <= DL_UP_SCS0_RX_EARLY(i)(63 downto 32);
    dl_up_rx_early0_lower_w(i)      <= DL_UP_SCS0_RX_EARLY(i)(31 downto 0);
    dl_up_rx_early1_upper_w(i)      <= DL_UP_SCS1_RX_EARLY(i)(63 downto 32);
    dl_up_rx_early1_lower_w(i)      <= DL_UP_SCS1_RX_EARLY(i)(31 downto 0);
    dl_up_rx_early2_upper_w(i)      <= DL_UP_SCS2_RX_EARLY(i)(63 downto 32);
    dl_up_rx_early2_lower_w(i)      <= DL_UP_SCS2_RX_EARLY(i)(31 downto 0);
    dl_up_rx_early3_upper_w(i)      <= DL_UP_SCS3_RX_EARLY(i)(63 downto 32);
    dl_up_rx_early3_lower_w(i)      <= DL_UP_SCS3_RX_EARLY(i)(31 downto 0);
    dl_up_rx_early4_upper_w(i)      <= DL_UP_SCS4_RX_EARLY(i)(63 downto 32);
    dl_up_rx_early4_lower_w(i)      <= DL_UP_SCS4_RX_EARLY(i)(31 downto 0);
    dl_up_rx_late0_upper_w(i)       <= DL_UP_SCS0_RX_LATE(i)(63 downto 32);
    dl_up_rx_late0_lower_w(i)       <= DL_UP_SCS0_RX_LATE(i)(31 downto 0);
    dl_up_rx_late1_upper_w(i)       <= DL_UP_SCS1_RX_LATE(i)(63 downto 32);
    dl_up_rx_late1_lower_w(i)       <= DL_UP_SCS1_RX_LATE(i)(31 downto 0);
    dl_up_rx_late2_upper_w(i)       <= DL_UP_SCS2_RX_LATE(i)(63 downto 32);
    dl_up_rx_late2_lower_w(i)       <= DL_UP_SCS2_RX_LATE(i)(31 downto 0);
    dl_up_rx_late3_upper_w(i)       <= DL_UP_SCS3_RX_LATE(i)(63 downto 32);
    dl_up_rx_late3_lower_w(i)       <= DL_UP_SCS3_RX_LATE(i)(31 downto 0);
    dl_up_rx_late4_upper_w(i)       <= DL_UP_SCS4_RX_LATE(i)(63 downto 32);
    dl_up_rx_late4_lower_w(i)       <= DL_UP_SCS4_RX_LATE(i)(31 downto 0);
    dl_up_rx_ndm0_upper_w(i)        <= DL_UP_SCS0_RX_NDM(i)(63 downto 32);
    dl_up_rx_ndm0_lower_w(i)        <= DL_UP_SCS0_RX_NDM(i)(31 downto 0);
    dl_up_rx_ndm1_upper_w(i)        <= DL_UP_SCS1_RX_NDM(i)(63 downto 32);
    dl_up_rx_ndm1_lower_w(i)        <= DL_UP_SCS1_RX_NDM(i)(31 downto 0);
    dl_up_rx_ndm2_upper_w(i)        <= DL_UP_SCS2_RX_NDM(i)(63 downto 32);
    dl_up_rx_ndm2_lower_w(i)        <= DL_UP_SCS2_RX_NDM(i)(31 downto 0);
    dl_up_rx_ndm3_upper_w(i)        <= DL_UP_SCS3_RX_NDM(i)(63 downto 32);
    dl_up_rx_ndm3_lower_w(i)        <= DL_UP_SCS3_RX_NDM(i)(31 downto 0);
    dl_up_rx_ndm4_upper_w(i)        <= DL_UP_SCS4_RX_NDM(i)(63 downto 32);
    dl_up_rx_ndm4_lower_w(i)        <= DL_UP_SCS4_RX_NDM(i)(31 downto 0);

    ul_cp_rx_on_time0_upper_w(i)    <= UL_CP_SCS0_RX_ON_TIME(i)(63 downto 32);
    ul_cp_rx_on_time0_lower_w(i)    <= UL_CP_SCS0_RX_ON_TIME(i)(31 downto 0);
    ul_cp_rx_on_time1_upper_w(i)    <= UL_CP_SCS1_RX_ON_TIME(i)(63 downto 32);
    ul_cp_rx_on_time1_lower_w(i)    <= UL_CP_SCS1_RX_ON_TIME(i)(31 downto 0);
    ul_cp_rx_on_time2_upper_w(i)    <= UL_CP_SCS2_RX_ON_TIME(i)(63 downto 32);
    ul_cp_rx_on_time2_lower_w(i)    <= UL_CP_SCS2_RX_ON_TIME(i)(31 downto 0);
    ul_cp_rx_on_time3_upper_w(i)    <= UL_CP_SCS3_RX_ON_TIME(i)(63 downto 32);
    ul_cp_rx_on_time3_lower_w(i)    <= UL_CP_SCS3_RX_ON_TIME(i)(31 downto 0);
    ul_cp_rx_on_time4_upper_w(i)    <= UL_CP_SCS4_RX_ON_TIME(i)(63 downto 32);
    ul_cp_rx_on_time4_lower_w(i)    <= UL_CP_SCS4_RX_ON_TIME(i)(31 downto 0);
    ul_cp_rx_early0_upper_w(i)      <= UL_CP_SCS0_RX_EARLY(i)(63 downto 32);
    ul_cp_rx_early0_lower_w(i)      <= UL_CP_SCS0_RX_EARLY(i)(31 downto 0);
    ul_cp_rx_early1_upper_w(i)      <= UL_CP_SCS1_RX_EARLY(i)(63 downto 32);
    ul_cp_rx_early1_lower_w(i)      <= UL_CP_SCS1_RX_EARLY(i)(31 downto 0);
    ul_cp_rx_early2_upper_w(i)      <= UL_CP_SCS2_RX_EARLY(i)(63 downto 32);
    ul_cp_rx_early2_lower_w(i)      <= UL_CP_SCS2_RX_EARLY(i)(31 downto 0);
    ul_cp_rx_early3_upper_w(i)      <= UL_CP_SCS3_RX_EARLY(i)(63 downto 32);
    ul_cp_rx_early3_lower_w(i)      <= UL_CP_SCS3_RX_EARLY(i)(31 downto 0);
    ul_cp_rx_early4_upper_w(i)      <= UL_CP_SCS4_RX_EARLY(i)(63 downto 32);
    ul_cp_rx_early4_lower_w(i)      <= UL_CP_SCS4_RX_EARLY(i)(31 downto 0);
    ul_cp_rx_late0_upper_w(i)       <= UL_CP_SCS0_RX_LATE(i)(63 downto 32);
    ul_cp_rx_late0_lower_w(i)       <= UL_CP_SCS0_RX_LATE(i)(31 downto 0);
    ul_cp_rx_late1_upper_w(i)       <= UL_CP_SCS1_RX_LATE(i)(63 downto 32);
    ul_cp_rx_late1_lower_w(i)       <= UL_CP_SCS1_RX_LATE(i)(31 downto 0);
    ul_cp_rx_late2_upper_w(i)       <= UL_CP_SCS2_RX_LATE(i)(63 downto 32);
    ul_cp_rx_late2_lower_w(i)       <= UL_CP_SCS2_RX_LATE(i)(31 downto 0);
    ul_cp_rx_late3_upper_w(i)       <= UL_CP_SCS3_RX_LATE(i)(63 downto 32);
    ul_cp_rx_late3_lower_w(i)       <= UL_CP_SCS3_RX_LATE(i)(31 downto 0);
    ul_cp_rx_late4_upper_w(i)       <= UL_CP_SCS4_RX_LATE(i)(63 downto 32);
    ul_cp_rx_late4_lower_w(i)       <= UL_CP_SCS4_RX_LATE(i)(31 downto 0);
    ul_cp_rx_ndm0_upper_w(i)        <= UL_CP_SCS0_RX_NDM(i)(63 downto 32);
    ul_cp_rx_ndm0_lower_w(i)        <= UL_CP_SCS0_RX_NDM(i)(31 downto 0);
    ul_cp_rx_ndm1_upper_w(i)        <= UL_CP_SCS1_RX_NDM(i)(63 downto 32);
    ul_cp_rx_ndm1_lower_w(i)        <= UL_CP_SCS1_RX_NDM(i)(31 downto 0);
    ul_cp_rx_ndm2_upper_w(i)        <= UL_CP_SCS2_RX_NDM(i)(63 downto 32);
    ul_cp_rx_ndm2_lower_w(i)        <= UL_CP_SCS2_RX_NDM(i)(31 downto 0);
    ul_cp_rx_ndm3_upper_w(i)        <= UL_CP_SCS3_RX_NDM(i)(63 downto 32);
    ul_cp_rx_ndm3_lower_w(i)        <= UL_CP_SCS3_RX_NDM(i)(31 downto 0);
    ul_cp_rx_ndm4_upper_w(i)        <= UL_CP_SCS4_RX_NDM(i)(63 downto 32);
    ul_cp_rx_ndm4_lower_w(i)        <= UL_CP_SCS4_RX_NDM(i)(31 downto 0);

    ul_up_tx_upper_w(i)             <= UL_UP_TX_TOTAL(i)(63 downto 32);
    ul_up_tx_lower_w(i)             <= UL_UP_TX_TOTAL(i)(31 downto 0);
    end generate;

    u_DEBUG_8 : for i in 7 downto 0 generate
    rx_pe_valid_r(i)                <= RX_PE_VALID(i);
    rx_invalid_dst_mac_r(i)         <= RX_INVALID_DST_MAC(i);
    rx_invalid_src_mac_r(i)         <= RX_INVALID_SRC_MAC(i);
    rx_invalid_vlan_vid_r(i)        <= RX_INVALID_VLAN_VID(i);
    rx_discontinue_r(i)             <= RX_DISCONTINUE(i);
    rx_byte_size_r(i)               <= RX_BYTE_SIZE(i);
    rx_byte_align_r(i)              <= RX_BYTE_ALIGN(i);

    rx_dl_cp_position_r(i)          <= RX_DL_CP_POSITION(i);
    rx_dl_up_position_r(i)          <= RX_DL_UP_POSITION(i);
    rx_ul_cp_position_r(i)          <= RX_UL_CP_POSITION(i);

    usage_rx_cp_buffer_r(i)         <= USAGE_RX_CP_BUFFER(i);
    usage_rx_up_buffer_r(i)         <= USAGE_RX_UP_BUFFER(i);
    cnt_rx_cp_r(i)                  <= CNT_RX_CP(i);
    cnt_rx_up_r(i)                  <= CNT_RX_UP(i);
    cnt_rx_cp_lost_r(i)             <= CNT_RX_CP_LOST(i);
    cnt_rx_up_lost_r(i)             <= CNT_RX_UP_LOST(i);

    det_dl_cp0_fault_id_31_r(i)     <= x"000000000000" & DET_DL_CP0_FAULT_ID_31(i);
    det_dl_cp1_fault_id_31_r(i)     <= x"000000000000" & DET_DL_CP1_FAULT_ID_31(i);
    det_dl_cp2_fault_id_31_r(i)     <= x"000000000000" & DET_DL_CP2_FAULT_ID_31(i);
    det_dl_cp3_fault_id_31_r(i)     <= x"000000000000" & DET_DL_CP3_FAULT_ID_31(i);
    det_dl_cp4_fault_id_31_r(i)     <= x"000000000000" & DET_DL_CP4_FAULT_ID_31(i);
    det_dl_cp5_fault_id_31_r(i)     <= x"000000000000" & DET_DL_CP5_FAULT_ID_31(i);
    det_dl_cp6_fault_id_31_r(i)     <= x"000000000000" & DET_DL_CP6_FAULT_ID_31(i);
    det_dl_cp7_fault_id_31_r(i)     <= x"000000000000" & DET_DL_CP7_FAULT_ID_31(i);
    det_ul_cp0_fault_id_31_r(i)     <= x"000000000000" & DET_UL_CP0_FAULT_ID_31(i);
    det_ul_cp1_fault_id_31_r(i)     <= x"000000000000" & DET_UL_CP1_FAULT_ID_31(i);
    det_ul_cp2_fault_id_31_r(i)     <= x"000000000000" & DET_UL_CP2_FAULT_ID_31(i);
    det_ul_cp3_fault_id_31_r(i)     <= x"000000000000" & DET_UL_CP3_FAULT_ID_31(i);
    det_ul_cp4_fault_id_31_r(i)     <= x"000000000000" & DET_UL_CP4_FAULT_ID_31(i);
    det_ul_cp5_fault_id_31_r(i)     <= x"000000000000" & DET_UL_CP5_FAULT_ID_31(i);
    det_ul_cp6_fault_id_31_r(i)     <= x"000000000000" & DET_UL_CP6_FAULT_ID_31(i);
    det_ul_cp7_fault_id_31_r(i)     <= x"000000000000" & DET_UL_CP7_FAULT_ID_31(i);

    tx0_sts_cq_fsm_r(i)             <= x"000000" & STATUS_TX0_CQ_FSM(i);
    tx0_cnt_cq_fsm_busy_r(i)        <= CNT_TX0_CQ_FSM_BUSY(i);
    tx0_cnt_cq_conv_full_r(i)       <= CNT_TX0_CQ_CONV_FULL(i);
    tx0_frame_id_r(i)               <= x"00" & IGNORE_FRAME_ID_PUxCH_RX(i) & x"00" & IGNORE_FRAME_ID_PUxCH_TX(i);
    tx0_cnt_cpsec_sym0_r(i)         <= CNT_TX0_CPSEC_SYMBOL0(i);
    tx0_cnt_cpsec_sym1_r(i)         <= CNT_TX0_CPSEC_SYMBOL1(i);
    tx0_cnt_cpsec_sym2_r(i)         <= CNT_TX0_CPSEC_SYMBOL2(i);
    tx0_cnt_cpsec_sym3_r(i)         <= CNT_TX0_CPSEC_SYMBOL3(i);
    tx0_cnt_cpsec_sym4_r(i)         <= CNT_TX0_CPSEC_SYMBOL4(i);
    tx0_cnt_cpsec_sym5_r(i)         <= CNT_TX0_CPSEC_SYMBOL5(i);
    tx0_cnt_cpsec_sym6_r(i)         <= CNT_TX0_CPSEC_SYMBOL6(i);
    tx0_cnt_cpsec_sym7_r(i)         <= CNT_TX0_CPSEC_SYMBOL7(i);
    tx0_cnt_cpsec_sym8_r(i)         <= CNT_TX0_CPSEC_SYMBOL8(i);
    tx0_cnt_cpsec_sym9_r(i)         <= CNT_TX0_CPSEC_SYMBOL9(i);
    tx0_cnt_cpsec_sym10_r(i)        <= CNT_TX0_CPSEC_SYMBOL10(i);
    tx0_cnt_cpsec_sym11_r(i)        <= CNT_TX0_CPSEC_SYMBOL11(i);
    tx0_cnt_cpsec_sym12_r(i)        <= CNT_TX0_CPSEC_SYMBOL12(i);
    tx0_cnt_cpsec_sym13_r(i)        <= CNT_TX0_CPSEC_SYMBOL13(i);
    tx0_cnt_uppkt_sym0_r(i)         <= CNT_TX0_UPPKT_SYMBOL0(i);
    tx0_cnt_uppkt_sym1_r(i)         <= CNT_TX0_UPPKT_SYMBOL1(i);
    tx0_cnt_uppkt_sym2_r(i)         <= CNT_TX0_UPPKT_SYMBOL2(i);
    tx0_cnt_uppkt_sym3_r(i)         <= CNT_TX0_UPPKT_SYMBOL3(i);
    tx0_cnt_uppkt_sym4_r(i)         <= CNT_TX0_UPPKT_SYMBOL4(i);
    tx0_cnt_uppkt_sym5_r(i)         <= CNT_TX0_UPPKT_SYMBOL5(i);
    tx0_cnt_uppkt_sym6_r(i)         <= CNT_TX0_UPPKT_SYMBOL6(i);
    tx0_cnt_uppkt_sym7_r(i)         <= CNT_TX0_UPPKT_SYMBOL7(i);
    tx0_cnt_uppkt_sym8_r(i)         <= CNT_TX0_UPPKT_SYMBOL8(i);
    tx0_cnt_uppkt_sym9_r(i)         <= CNT_TX0_UPPKT_SYMBOL9(i);
    tx0_cnt_uppkt_sym10_r(i)        <= CNT_TX0_UPPKT_SYMBOL10(i);
    tx0_cnt_uppkt_sym11_r(i)        <= CNT_TX0_UPPKT_SYMBOL11(i);
    tx0_cnt_uppkt_sym12_r(i)        <= CNT_TX0_UPPKT_SYMBOL12(i);
    tx0_cnt_uppkt_sym13_r(i)        <= CNT_TX0_UPPKT_SYMBOL13(i);
    tx0_cnt_cq_full_sym0_r(i)       <= CNT_TX0_CQ_FULL_SYMBOL0(i);
    tx0_cnt_cq_full_sym1_r(i)       <= CNT_TX0_CQ_FULL_SYMBOL1(i);
    tx0_cnt_cq_full_sym2_r(i)       <= CNT_TX0_CQ_FULL_SYMBOL2(i);
    tx0_cnt_cq_full_sym3_r(i)       <= CNT_TX0_CQ_FULL_SYMBOL3(i);
    tx0_cnt_cq_full_sym4_r(i)       <= CNT_TX0_CQ_FULL_SYMBOL4(i);
    tx0_cnt_cq_full_sym5_r(i)       <= CNT_TX0_CQ_FULL_SYMBOL5(i);
    tx0_cnt_cq_full_sym6_r(i)       <= CNT_TX0_CQ_FULL_SYMBOL6(i);
    tx0_cnt_cq_full_sym7_r(i)       <= CNT_TX0_CQ_FULL_SYMBOL7(i);
    tx0_cnt_cq_full_sym8_r(i)       <= CNT_TX0_CQ_FULL_SYMBOL8(i);
    tx0_cnt_cq_full_sym9_r(i)       <= CNT_TX0_CQ_FULL_SYMBOL9(i);
    tx0_cnt_cq_full_sym10_r(i)      <= CNT_TX0_CQ_FULL_SYMBOL10(i);
    tx0_cnt_cq_full_sym11_r(i)      <= CNT_TX0_CQ_FULL_SYMBOL11(i);
    tx0_cnt_cq_full_sym12_r(i)      <= CNT_TX0_CQ_FULL_SYMBOL12(i);
    tx0_cnt_cq_full_sym13_r(i)      <= CNT_TX0_CQ_FULL_SYMBOL13(i);
    tx0_usage_cq_sym0_r(i)          <= USAGE_TX0_CQ_SYMBOL0(i);
    tx0_usage_cq_sym1_r(i)          <= USAGE_TX0_CQ_SYMBOL1(i);
    tx0_usage_cq_sym2_r(i)          <= USAGE_TX0_CQ_SYMBOL2(i);
    tx0_usage_cq_sym3_r(i)          <= USAGE_TX0_CQ_SYMBOL3(i);
    tx0_usage_cq_sym4_r(i)          <= USAGE_TX0_CQ_SYMBOL4(i);
    tx0_usage_cq_sym5_r(i)          <= USAGE_TX0_CQ_SYMBOL5(i);
    tx0_usage_cq_sym6_r(i)          <= USAGE_TX0_CQ_SYMBOL6(i);
    tx0_usage_cq_sym7_r(i)          <= USAGE_TX0_CQ_SYMBOL7(i);
    tx0_usage_cq_sym8_r(i)          <= USAGE_TX0_CQ_SYMBOL8(i);
    tx0_usage_cq_sym9_r(i)          <= USAGE_TX0_CQ_SYMBOL9(i);
    tx0_usage_cq_sym10_r(i)         <= USAGE_TX0_CQ_SYMBOL10(i);
    tx0_usage_cq_sym11_r(i)         <= USAGE_TX0_CQ_SYMBOL11(i);
    tx0_usage_cq_sym12_r(i)         <= USAGE_TX0_CQ_SYMBOL12(i);
    tx0_usage_cq_sym13_r(i)         <= USAGE_TX0_CQ_SYMBOL13(i);

    tx1_sts_cq_fsm_r(i)             <= x"000000" & STATUS_TX1_CQ_FSM(i);
    tx1_cnt_cq_fsm_busy_r(i)        <= CNT_TX1_CQ_FSM_BUSY(i);
    tx1_cnt_cq_conv_full_r(i)       <= CNT_TX1_CQ_CONV_FULL(i);
    tx1_frame_id_r(i)               <= x"00" & IGNORE_FRAME_ID_PRACH0_RX(i) & x"00" & IGNORE_FRAME_ID_PRACH0_TX(i);
    tx1_cnt_cpsec_sym0_r(i)         <= CNT_TX1_CPSEC_SYMBOL0(i);
    tx1_cnt_cpsec_sym1_r(i)         <= CNT_TX1_CPSEC_SYMBOL1(i);
    tx1_cnt_cpsec_sym2_r(i)         <= CNT_TX1_CPSEC_SYMBOL2(i);
    tx1_cnt_cpsec_sym3_r(i)         <= CNT_TX1_CPSEC_SYMBOL3(i);
    tx1_cnt_cpsec_sym4_r(i)         <= CNT_TX1_CPSEC_SYMBOL4(i);
    tx1_cnt_cpsec_sym5_r(i)         <= CNT_TX1_CPSEC_SYMBOL5(i);
    tx1_cnt_cpsec_sym6_r(i)         <= CNT_TX1_CPSEC_SYMBOL6(i);
    tx1_cnt_cpsec_sym7_r(i)         <= CNT_TX1_CPSEC_SYMBOL7(i);
    tx1_cnt_cpsec_sym8_r(i)         <= CNT_TX1_CPSEC_SYMBOL8(i);
    tx1_cnt_cpsec_sym9_r(i)         <= CNT_TX1_CPSEC_SYMBOL9(i);
    tx1_cnt_cpsec_sym10_r(i)        <= CNT_TX1_CPSEC_SYMBOL10(i);
    tx1_cnt_cpsec_sym11_r(i)        <= CNT_TX1_CPSEC_SYMBOL11(i);
    tx1_cnt_cpsec_sym12_r(i)        <= CNT_TX1_CPSEC_SYMBOL12(i);
    tx1_cnt_cpsec_sym13_r(i)        <= CNT_TX1_CPSEC_SYMBOL13(i);
    tx1_cnt_uppkt_sym0_r(i)         <= CNT_TX1_UPPKT_SYMBOL0(i);
    tx1_cnt_uppkt_sym1_r(i)         <= CNT_TX1_UPPKT_SYMBOL1(i);
    tx1_cnt_uppkt_sym2_r(i)         <= CNT_TX1_UPPKT_SYMBOL2(i);
    tx1_cnt_uppkt_sym3_r(i)         <= CNT_TX1_UPPKT_SYMBOL3(i);
    tx1_cnt_uppkt_sym4_r(i)         <= CNT_TX1_UPPKT_SYMBOL4(i);
    tx1_cnt_uppkt_sym5_r(i)         <= CNT_TX1_UPPKT_SYMBOL5(i);
    tx1_cnt_uppkt_sym6_r(i)         <= CNT_TX1_UPPKT_SYMBOL6(i);
    tx1_cnt_uppkt_sym7_r(i)         <= CNT_TX1_UPPKT_SYMBOL7(i);
    tx1_cnt_uppkt_sym8_r(i)         <= CNT_TX1_UPPKT_SYMBOL8(i);
    tx1_cnt_uppkt_sym9_r(i)         <= CNT_TX1_UPPKT_SYMBOL9(i);
    tx1_cnt_uppkt_sym10_r(i)        <= CNT_TX1_UPPKT_SYMBOL10(i);
    tx1_cnt_uppkt_sym11_r(i)        <= CNT_TX1_UPPKT_SYMBOL11(i);
    tx1_cnt_uppkt_sym12_r(i)        <= CNT_TX1_UPPKT_SYMBOL12(i);
    tx1_cnt_uppkt_sym13_r(i)        <= CNT_TX1_UPPKT_SYMBOL13(i);
    tx1_cnt_cq_full_sym0_r(i)       <= CNT_TX1_CQ_FULL_SYMBOL0(i);
    tx1_cnt_cq_full_sym1_r(i)       <= CNT_TX1_CQ_FULL_SYMBOL1(i);
    tx1_cnt_cq_full_sym2_r(i)       <= CNT_TX1_CQ_FULL_SYMBOL2(i);
    tx1_cnt_cq_full_sym3_r(i)       <= CNT_TX1_CQ_FULL_SYMBOL3(i);
    tx1_cnt_cq_full_sym4_r(i)       <= CNT_TX1_CQ_FULL_SYMBOL4(i);
    tx1_cnt_cq_full_sym5_r(i)       <= CNT_TX1_CQ_FULL_SYMBOL5(i);
    tx1_cnt_cq_full_sym6_r(i)       <= CNT_TX1_CQ_FULL_SYMBOL6(i);
    tx1_cnt_cq_full_sym7_r(i)       <= CNT_TX1_CQ_FULL_SYMBOL7(i);
    tx1_cnt_cq_full_sym8_r(i)       <= CNT_TX1_CQ_FULL_SYMBOL8(i);
    tx1_cnt_cq_full_sym9_r(i)       <= CNT_TX1_CQ_FULL_SYMBOL9(i);
    tx1_cnt_cq_full_sym10_r(i)      <= CNT_TX1_CQ_FULL_SYMBOL10(i);
    tx1_cnt_cq_full_sym11_r(i)      <= CNT_TX1_CQ_FULL_SYMBOL11(i);
    tx1_cnt_cq_full_sym12_r(i)      <= CNT_TX1_CQ_FULL_SYMBOL12(i);
    tx1_cnt_cq_full_sym13_r(i)      <= CNT_TX1_CQ_FULL_SYMBOL13(i);
    tx1_usage_cq_sym0_r(i)          <= USAGE_TX1_CQ_SYMBOL0(i);
    tx1_usage_cq_sym1_r(i)          <= USAGE_TX1_CQ_SYMBOL1(i);
    tx1_usage_cq_sym2_r(i)          <= USAGE_TX1_CQ_SYMBOL2(i);
    tx1_usage_cq_sym3_r(i)          <= USAGE_TX1_CQ_SYMBOL3(i);
    tx1_usage_cq_sym4_r(i)          <= USAGE_TX1_CQ_SYMBOL4(i);
    tx1_usage_cq_sym5_r(i)          <= USAGE_TX1_CQ_SYMBOL5(i);
    tx1_usage_cq_sym6_r(i)          <= USAGE_TX1_CQ_SYMBOL6(i);
    tx1_usage_cq_sym7_r(i)          <= USAGE_TX1_CQ_SYMBOL7(i);
    tx1_usage_cq_sym8_r(i)          <= USAGE_TX1_CQ_SYMBOL8(i);
    tx1_usage_cq_sym9_r(i)          <= USAGE_TX1_CQ_SYMBOL9(i);
    tx1_usage_cq_sym10_r(i)         <= USAGE_TX1_CQ_SYMBOL10(i);
    tx1_usage_cq_sym11_r(i)         <= USAGE_TX1_CQ_SYMBOL11(i);
    tx1_usage_cq_sym12_r(i)         <= USAGE_TX1_CQ_SYMBOL12(i);
    tx1_usage_cq_sym13_r(i)         <= USAGE_TX1_CQ_SYMBOL13(i);

    tx2_sts_cq_fsm_r(i)             <= x"000000" & STATUS_TX2_CQ_FSM(i);
    tx2_cnt_cq_fsm_busy_r(i)        <= CNT_TX2_CQ_FSM_BUSY(i);
    tx2_cnt_cq_conv_full_r(i)       <= CNT_TX2_CQ_CONV_FULL(i);
    tx2_frame_id_r(i)               <= x"00" & IGNORE_FRAME_ID_PRACH1_RX(i) & x"00" & IGNORE_FRAME_ID_PRACH1_TX(i);
    tx2_cnt_cpsec_sym0_r(i)         <= CNT_TX2_CPSEC_SYMBOL0(i);
    tx2_cnt_cpsec_sym1_r(i)         <= CNT_TX2_CPSEC_SYMBOL1(i);
    tx2_cnt_cpsec_sym2_r(i)         <= CNT_TX2_CPSEC_SYMBOL2(i);
    tx2_cnt_cpsec_sym3_r(i)         <= CNT_TX2_CPSEC_SYMBOL3(i);
    tx2_cnt_cpsec_sym4_r(i)         <= CNT_TX2_CPSEC_SYMBOL4(i);
    tx2_cnt_cpsec_sym5_r(i)         <= CNT_TX2_CPSEC_SYMBOL5(i);
    tx2_cnt_cpsec_sym6_r(i)         <= CNT_TX2_CPSEC_SYMBOL6(i);
    tx2_cnt_cpsec_sym7_r(i)         <= CNT_TX2_CPSEC_SYMBOL7(i);
    tx2_cnt_cpsec_sym8_r(i)         <= CNT_TX2_CPSEC_SYMBOL8(i);
    tx2_cnt_cpsec_sym9_r(i)         <= CNT_TX2_CPSEC_SYMBOL9(i);
    tx2_cnt_cpsec_sym10_r(i)        <= CNT_TX2_CPSEC_SYMBOL10(i);
    tx2_cnt_cpsec_sym11_r(i)        <= CNT_TX2_CPSEC_SYMBOL11(i);
    tx2_cnt_cpsec_sym12_r(i)        <= CNT_TX2_CPSEC_SYMBOL12(i);
    tx2_cnt_cpsec_sym13_r(i)        <= CNT_TX2_CPSEC_SYMBOL13(i);
    tx2_cnt_uppkt_sym0_r(i)         <= CNT_TX2_UPPKT_SYMBOL0(i);
    tx2_cnt_uppkt_sym1_r(i)         <= CNT_TX2_UPPKT_SYMBOL1(i);
    tx2_cnt_uppkt_sym2_r(i)         <= CNT_TX2_UPPKT_SYMBOL2(i);
    tx2_cnt_uppkt_sym3_r(i)         <= CNT_TX2_UPPKT_SYMBOL3(i);
    tx2_cnt_uppkt_sym4_r(i)         <= CNT_TX2_UPPKT_SYMBOL4(i);
    tx2_cnt_uppkt_sym5_r(i)         <= CNT_TX2_UPPKT_SYMBOL5(i);
    tx2_cnt_uppkt_sym6_r(i)         <= CNT_TX2_UPPKT_SYMBOL6(i);
    tx2_cnt_uppkt_sym7_r(i)         <= CNT_TX2_UPPKT_SYMBOL7(i);
    tx2_cnt_uppkt_sym8_r(i)         <= CNT_TX2_UPPKT_SYMBOL8(i);
    tx2_cnt_uppkt_sym9_r(i)         <= CNT_TX2_UPPKT_SYMBOL9(i);
    tx2_cnt_uppkt_sym10_r(i)        <= CNT_TX2_UPPKT_SYMBOL10(i);
    tx2_cnt_uppkt_sym11_r(i)        <= CNT_TX2_UPPKT_SYMBOL11(i);
    tx2_cnt_uppkt_sym12_r(i)        <= CNT_TX2_UPPKT_SYMBOL12(i);
    tx2_cnt_uppkt_sym13_r(i)        <= CNT_TX2_UPPKT_SYMBOL13(i);
    tx2_cnt_cq_full_sym0_r(i)       <= CNT_TX2_CQ_FULL_SYMBOL0(i);
    tx2_cnt_cq_full_sym1_r(i)       <= CNT_TX2_CQ_FULL_SYMBOL1(i);
    tx2_cnt_cq_full_sym2_r(i)       <= CNT_TX2_CQ_FULL_SYMBOL2(i);
    tx2_cnt_cq_full_sym3_r(i)       <= CNT_TX2_CQ_FULL_SYMBOL3(i);
    tx2_cnt_cq_full_sym4_r(i)       <= CNT_TX2_CQ_FULL_SYMBOL4(i);
    tx2_cnt_cq_full_sym5_r(i)       <= CNT_TX2_CQ_FULL_SYMBOL5(i);
    tx2_cnt_cq_full_sym6_r(i)       <= CNT_TX2_CQ_FULL_SYMBOL6(i);
    tx2_cnt_cq_full_sym7_r(i)       <= CNT_TX2_CQ_FULL_SYMBOL7(i);
    tx2_cnt_cq_full_sym8_r(i)       <= CNT_TX2_CQ_FULL_SYMBOL8(i);
    tx2_cnt_cq_full_sym9_r(i)       <= CNT_TX2_CQ_FULL_SYMBOL9(i);
    tx2_cnt_cq_full_sym10_r(i)      <= CNT_TX2_CQ_FULL_SYMBOL10(i);
    tx2_cnt_cq_full_sym11_r(i)      <= CNT_TX2_CQ_FULL_SYMBOL11(i);
    tx2_cnt_cq_full_sym12_r(i)      <= CNT_TX2_CQ_FULL_SYMBOL12(i);
    tx2_cnt_cq_full_sym13_r(i)      <= CNT_TX2_CQ_FULL_SYMBOL13(i);
    tx2_usage_cq_sym0_r(i)          <= USAGE_TX2_CQ_SYMBOL0(i);
    tx2_usage_cq_sym1_r(i)          <= USAGE_TX2_CQ_SYMBOL1(i);
    tx2_usage_cq_sym2_r(i)          <= USAGE_TX2_CQ_SYMBOL2(i);
    tx2_usage_cq_sym3_r(i)          <= USAGE_TX2_CQ_SYMBOL3(i);
    tx2_usage_cq_sym4_r(i)          <= USAGE_TX2_CQ_SYMBOL4(i);
    tx2_usage_cq_sym5_r(i)          <= USAGE_TX2_CQ_SYMBOL5(i);
    tx2_usage_cq_sym6_r(i)          <= USAGE_TX2_CQ_SYMBOL6(i);
    tx2_usage_cq_sym7_r(i)          <= USAGE_TX2_CQ_SYMBOL7(i);
    tx2_usage_cq_sym8_r(i)          <= USAGE_TX2_CQ_SYMBOL8(i);
    tx2_usage_cq_sym9_r(i)          <= USAGE_TX2_CQ_SYMBOL9(i);
    tx2_usage_cq_sym10_r(i)         <= USAGE_TX2_CQ_SYMBOL10(i);
    tx2_usage_cq_sym11_r(i)         <= USAGE_TX2_CQ_SYMBOL11(i);
    tx2_usage_cq_sym12_r(i)         <= USAGE_TX2_CQ_SYMBOL12(i);
    tx2_usage_cq_sym13_r(i)         <= USAGE_TX2_CQ_SYMBOL13(i);

    tx3_sts_cq_fsm_r(i)             <= x"000000" & STATUS_TX3_CQ_FSM(i);
    tx3_cnt_cq_fsm_busy_r(i)        <= CNT_TX3_CQ_FSM_BUSY(i);
    tx3_cnt_cq_conv_full_r(i)       <= CNT_TX3_CQ_CONV_FULL(i);
    tx3_frame_id_r(i)               <= x"00" & IGNORE_FRAME_ID_NBIOT0_RX(i) & x"00" & IGNORE_FRAME_ID_NBIOT0_TX(i);
    tx3_cnt_cpsec_sym0_r(i)         <= CNT_TX3_CPSEC_SYMBOL0(i);
    tx3_cnt_cpsec_sym1_r(i)         <= CNT_TX3_CPSEC_SYMBOL1(i);
    tx3_cnt_cpsec_sym2_r(i)         <= CNT_TX3_CPSEC_SYMBOL2(i);
    tx3_cnt_cpsec_sym3_r(i)         <= CNT_TX3_CPSEC_SYMBOL3(i);
    tx3_cnt_cpsec_sym4_r(i)         <= CNT_TX3_CPSEC_SYMBOL4(i);
    tx3_cnt_cpsec_sym5_r(i)         <= CNT_TX3_CPSEC_SYMBOL5(i);
    tx3_cnt_cpsec_sym6_r(i)         <= CNT_TX3_CPSEC_SYMBOL6(i);
    tx3_cnt_cpsec_sym7_r(i)         <= CNT_TX3_CPSEC_SYMBOL7(i);
    tx3_cnt_cpsec_sym8_r(i)         <= CNT_TX3_CPSEC_SYMBOL8(i);
    tx3_cnt_cpsec_sym9_r(i)         <= CNT_TX3_CPSEC_SYMBOL9(i);
    tx3_cnt_cpsec_sym10_r(i)        <= CNT_TX3_CPSEC_SYMBOL10(i);
    tx3_cnt_cpsec_sym11_r(i)        <= CNT_TX3_CPSEC_SYMBOL11(i);
    tx3_cnt_cpsec_sym12_r(i)        <= CNT_TX3_CPSEC_SYMBOL12(i);
    tx3_cnt_cpsec_sym13_r(i)        <= CNT_TX3_CPSEC_SYMBOL13(i);
    tx3_cnt_uppkt_sym0_r(i)         <= CNT_TX3_UPPKT_SYMBOL0(i);
    tx3_cnt_uppkt_sym1_r(i)         <= CNT_TX3_UPPKT_SYMBOL1(i);
    tx3_cnt_uppkt_sym2_r(i)         <= CNT_TX3_UPPKT_SYMBOL2(i);
    tx3_cnt_uppkt_sym3_r(i)         <= CNT_TX3_UPPKT_SYMBOL3(i);
    tx3_cnt_uppkt_sym4_r(i)         <= CNT_TX3_UPPKT_SYMBOL4(i);
    tx3_cnt_uppkt_sym5_r(i)         <= CNT_TX3_UPPKT_SYMBOL5(i);
    tx3_cnt_uppkt_sym6_r(i)         <= CNT_TX3_UPPKT_SYMBOL6(i);
    tx3_cnt_uppkt_sym7_r(i)         <= CNT_TX3_UPPKT_SYMBOL7(i);
    tx3_cnt_uppkt_sym8_r(i)         <= CNT_TX3_UPPKT_SYMBOL8(i);
    tx3_cnt_uppkt_sym9_r(i)         <= CNT_TX3_UPPKT_SYMBOL9(i);
    tx3_cnt_uppkt_sym10_r(i)        <= CNT_TX3_UPPKT_SYMBOL10(i);
    tx3_cnt_uppkt_sym11_r(i)        <= CNT_TX3_UPPKT_SYMBOL11(i);
    tx3_cnt_uppkt_sym12_r(i)        <= CNT_TX3_UPPKT_SYMBOL12(i);
    tx3_cnt_uppkt_sym13_r(i)        <= CNT_TX3_UPPKT_SYMBOL13(i);
    tx3_cnt_cq_full_sym0_r(i)       <= CNT_TX3_CQ_FULL_SYMBOL0(i);
    tx3_cnt_cq_full_sym1_r(i)       <= CNT_TX3_CQ_FULL_SYMBOL1(i);
    tx3_cnt_cq_full_sym2_r(i)       <= CNT_TX3_CQ_FULL_SYMBOL2(i);
    tx3_cnt_cq_full_sym3_r(i)       <= CNT_TX3_CQ_FULL_SYMBOL3(i);
    tx3_cnt_cq_full_sym4_r(i)       <= CNT_TX3_CQ_FULL_SYMBOL4(i);
    tx3_cnt_cq_full_sym5_r(i)       <= CNT_TX3_CQ_FULL_SYMBOL5(i);
    tx3_cnt_cq_full_sym6_r(i)       <= CNT_TX3_CQ_FULL_SYMBOL6(i);
    tx3_cnt_cq_full_sym7_r(i)       <= CNT_TX3_CQ_FULL_SYMBOL7(i);
    tx3_cnt_cq_full_sym8_r(i)       <= CNT_TX3_CQ_FULL_SYMBOL8(i);
    tx3_cnt_cq_full_sym9_r(i)       <= CNT_TX3_CQ_FULL_SYMBOL9(i);
    tx3_cnt_cq_full_sym10_r(i)      <= CNT_TX3_CQ_FULL_SYMBOL10(i);
    tx3_cnt_cq_full_sym11_r(i)      <= CNT_TX3_CQ_FULL_SYMBOL11(i);
    tx3_cnt_cq_full_sym12_r(i)      <= CNT_TX3_CQ_FULL_SYMBOL12(i);
    tx3_cnt_cq_full_sym13_r(i)      <= CNT_TX3_CQ_FULL_SYMBOL13(i);
    tx3_usage_cq_sym0_r(i)          <= USAGE_TX3_CQ_SYMBOL0(i);
    tx3_usage_cq_sym1_r(i)          <= USAGE_TX3_CQ_SYMBOL1(i);
    tx3_usage_cq_sym2_r(i)          <= USAGE_TX3_CQ_SYMBOL2(i);
    tx3_usage_cq_sym3_r(i)          <= USAGE_TX3_CQ_SYMBOL3(i);
    tx3_usage_cq_sym4_r(i)          <= USAGE_TX3_CQ_SYMBOL4(i);
    tx3_usage_cq_sym5_r(i)          <= USAGE_TX3_CQ_SYMBOL5(i);
    tx3_usage_cq_sym6_r(i)          <= USAGE_TX3_CQ_SYMBOL6(i);
    tx3_usage_cq_sym7_r(i)          <= USAGE_TX3_CQ_SYMBOL7(i);
    tx3_usage_cq_sym8_r(i)          <= USAGE_TX3_CQ_SYMBOL8(i);
    tx3_usage_cq_sym9_r(i)          <= USAGE_TX3_CQ_SYMBOL9(i);
    tx3_usage_cq_sym10_r(i)         <= USAGE_TX3_CQ_SYMBOL10(i);
    tx3_usage_cq_sym11_r(i)         <= USAGE_TX3_CQ_SYMBOL11(i);
    tx3_usage_cq_sym12_r(i)         <= USAGE_TX3_CQ_SYMBOL12(i);
    tx3_usage_cq_sym13_r(i)         <= USAGE_TX3_CQ_SYMBOL13(i);

    tx4_sts_cq_fsm_r(i)             <= x"000000" & STATUS_TX4_CQ_FSM(i);
    tx4_cnt_cq_fsm_busy_r(i)        <= CNT_TX4_CQ_FSM_BUSY(i);
    tx4_cnt_cq_conv_full_r(i)       <= CNT_TX4_CQ_CONV_FULL(i);
    tx4_frame_id_r(i)               <= x"00" & IGNORE_FRAME_ID_NBIOT1_RX(i) & x"00" & IGNORE_FRAME_ID_NBIOT1_TX(i);
    tx4_cnt_cpsec_sym0_r(i)         <= CNT_TX4_CPSEC_SYMBOL0(i);
    tx4_cnt_cpsec_sym1_r(i)         <= CNT_TX4_CPSEC_SYMBOL1(i);
    tx4_cnt_cpsec_sym2_r(i)         <= CNT_TX4_CPSEC_SYMBOL2(i);
    tx4_cnt_cpsec_sym3_r(i)         <= CNT_TX4_CPSEC_SYMBOL3(i);
    tx4_cnt_cpsec_sym4_r(i)         <= CNT_TX4_CPSEC_SYMBOL4(i);
    tx4_cnt_cpsec_sym5_r(i)         <= CNT_TX4_CPSEC_SYMBOL5(i);
    tx4_cnt_cpsec_sym6_r(i)         <= CNT_TX4_CPSEC_SYMBOL6(i);
    tx4_cnt_cpsec_sym7_r(i)         <= CNT_TX4_CPSEC_SYMBOL7(i);
    tx4_cnt_cpsec_sym8_r(i)         <= CNT_TX4_CPSEC_SYMBOL8(i);
    tx4_cnt_cpsec_sym9_r(i)         <= CNT_TX4_CPSEC_SYMBOL9(i);
    tx4_cnt_cpsec_sym10_r(i)        <= CNT_TX4_CPSEC_SYMBOL10(i);
    tx4_cnt_cpsec_sym11_r(i)        <= CNT_TX4_CPSEC_SYMBOL11(i);
    tx4_cnt_cpsec_sym12_r(i)        <= CNT_TX4_CPSEC_SYMBOL12(i);
    tx4_cnt_cpsec_sym13_r(i)        <= CNT_TX4_CPSEC_SYMBOL13(i);
    tx4_cnt_uppkt_sym0_r(i)         <= CNT_TX4_UPPKT_SYMBOL0(i);
    tx4_cnt_uppkt_sym1_r(i)         <= CNT_TX4_UPPKT_SYMBOL1(i);
    tx4_cnt_uppkt_sym2_r(i)         <= CNT_TX4_UPPKT_SYMBOL2(i);
    tx4_cnt_uppkt_sym3_r(i)         <= CNT_TX4_UPPKT_SYMBOL3(i);
    tx4_cnt_uppkt_sym4_r(i)         <= CNT_TX4_UPPKT_SYMBOL4(i);
    tx4_cnt_uppkt_sym5_r(i)         <= CNT_TX4_UPPKT_SYMBOL5(i);
    tx4_cnt_uppkt_sym6_r(i)         <= CNT_TX4_UPPKT_SYMBOL6(i);
    tx4_cnt_uppkt_sym7_r(i)         <= CNT_TX4_UPPKT_SYMBOL7(i);
    tx4_cnt_uppkt_sym8_r(i)         <= CNT_TX4_UPPKT_SYMBOL8(i);
    tx4_cnt_uppkt_sym9_r(i)         <= CNT_TX4_UPPKT_SYMBOL9(i);
    tx4_cnt_uppkt_sym10_r(i)        <= CNT_TX4_UPPKT_SYMBOL10(i);
    tx4_cnt_uppkt_sym11_r(i)        <= CNT_TX4_UPPKT_SYMBOL11(i);
    tx4_cnt_uppkt_sym12_r(i)        <= CNT_TX4_UPPKT_SYMBOL12(i);
    tx4_cnt_uppkt_sym13_r(i)        <= CNT_TX4_UPPKT_SYMBOL13(i);
    tx4_cnt_cq_full_sym0_r(i)       <= CNT_TX4_CQ_FULL_SYMBOL0(i);
    tx4_cnt_cq_full_sym1_r(i)       <= CNT_TX4_CQ_FULL_SYMBOL1(i);
    tx4_cnt_cq_full_sym2_r(i)       <= CNT_TX4_CQ_FULL_SYMBOL2(i);
    tx4_cnt_cq_full_sym3_r(i)       <= CNT_TX4_CQ_FULL_SYMBOL3(i);
    tx4_cnt_cq_full_sym4_r(i)       <= CNT_TX4_CQ_FULL_SYMBOL4(i);
    tx4_cnt_cq_full_sym5_r(i)       <= CNT_TX4_CQ_FULL_SYMBOL5(i);
    tx4_cnt_cq_full_sym6_r(i)       <= CNT_TX4_CQ_FULL_SYMBOL6(i);
    tx4_cnt_cq_full_sym7_r(i)       <= CNT_TX4_CQ_FULL_SYMBOL7(i);
    tx4_cnt_cq_full_sym8_r(i)       <= CNT_TX4_CQ_FULL_SYMBOL8(i);
    tx4_cnt_cq_full_sym9_r(i)       <= CNT_TX4_CQ_FULL_SYMBOL9(i);
    tx4_cnt_cq_full_sym10_r(i)      <= CNT_TX4_CQ_FULL_SYMBOL10(i);
    tx4_cnt_cq_full_sym11_r(i)      <= CNT_TX4_CQ_FULL_SYMBOL11(i);
    tx4_cnt_cq_full_sym12_r(i)      <= CNT_TX4_CQ_FULL_SYMBOL12(i);
    tx4_cnt_cq_full_sym13_r(i)      <= CNT_TX4_CQ_FULL_SYMBOL13(i);
    tx4_usage_cq_sym0_r(i)          <= USAGE_TX4_CQ_SYMBOL0(i);
    tx4_usage_cq_sym1_r(i)          <= USAGE_TX4_CQ_SYMBOL1(i);
    tx4_usage_cq_sym2_r(i)          <= USAGE_TX4_CQ_SYMBOL2(i);
    tx4_usage_cq_sym3_r(i)          <= USAGE_TX4_CQ_SYMBOL3(i);
    tx4_usage_cq_sym4_r(i)          <= USAGE_TX4_CQ_SYMBOL4(i);
    tx4_usage_cq_sym5_r(i)          <= USAGE_TX4_CQ_SYMBOL5(i);
    tx4_usage_cq_sym6_r(i)          <= USAGE_TX4_CQ_SYMBOL6(i);
    tx4_usage_cq_sym7_r(i)          <= USAGE_TX4_CQ_SYMBOL7(i);
    tx4_usage_cq_sym8_r(i)          <= USAGE_TX4_CQ_SYMBOL8(i);
    tx4_usage_cq_sym9_r(i)          <= USAGE_TX4_CQ_SYMBOL9(i);
    tx4_usage_cq_sym10_r(i)         <= USAGE_TX4_CQ_SYMBOL10(i);
    tx4_usage_cq_sym11_r(i)         <= USAGE_TX4_CQ_SYMBOL11(i);
    tx4_usage_cq_sym12_r(i)         <= USAGE_TX4_CQ_SYMBOL12(i);
    tx4_usage_cq_sym13_r(i)         <= USAGE_TX4_CQ_SYMBOL13(i);

--    tx5_sts_cq_fsm_r(i)             <= x"000000" & STATUS_TX5_CQ_FSM(i);
--    tx5_cnt_cq_fsm_busy_r(i)        <= CNT_TX5_CQ_FSM_BUSY(i);
--    tx5_cnt_cq_conv_full_r(i)       <= CNT_TX5_CQ_CONV_FULL(i);
--    tx5_frame_id_r(i)               <= x"00" & IGNORE_FRAME_ID_NBIOT2_RX(i) & x"00" & IGNORE_FRAME_ID_NBIOT2_TX(i);
--    tx5_cnt_cpsec_sym0_r(i)         <= CNT_TX5_CPSEC_SYMBOL0(i);
--    tx5_cnt_cpsec_sym1_r(i)         <= CNT_TX5_CPSEC_SYMBOL1(i);
--    tx5_cnt_cpsec_sym2_r(i)         <= CNT_TX5_CPSEC_SYMBOL2(i);
--    tx5_cnt_cpsec_sym3_r(i)         <= CNT_TX5_CPSEC_SYMBOL3(i);
--    tx5_cnt_cpsec_sym4_r(i)         <= CNT_TX5_CPSEC_SYMBOL4(i);
--    tx5_cnt_cpsec_sym5_r(i)         <= CNT_TX5_CPSEC_SYMBOL5(i);
--    tx5_cnt_cpsec_sym6_r(i)         <= CNT_TX5_CPSEC_SYMBOL6(i);
--    tx5_cnt_cpsec_sym7_r(i)         <= CNT_TX5_CPSEC_SYMBOL7(i);
--    tx5_cnt_cpsec_sym8_r(i)         <= CNT_TX5_CPSEC_SYMBOL8(i);
--    tx5_cnt_cpsec_sym9_r(i)         <= CNT_TX5_CPSEC_SYMBOL9(i);
--    tx5_cnt_cpsec_sym10_r(i)        <= CNT_TX5_CPSEC_SYMBOL10(i);
--    tx5_cnt_cpsec_sym11_r(i)        <= CNT_TX5_CPSEC_SYMBOL11(i);
--    tx5_cnt_cpsec_sym12_r(i)        <= CNT_TX5_CPSEC_SYMBOL12(i);
--    tx5_cnt_cpsec_sym13_r(i)        <= CNT_TX5_CPSEC_SYMBOL13(i);
--    tx5_cnt_uppkt_sym0_r(i)         <= CNT_TX5_UPPKT_SYMBOL0(i);
--    tx5_cnt_uppkt_sym1_r(i)         <= CNT_TX5_UPPKT_SYMBOL1(i);
--    tx5_cnt_uppkt_sym2_r(i)         <= CNT_TX5_UPPKT_SYMBOL2(i);
--    tx5_cnt_uppkt_sym3_r(i)         <= CNT_TX5_UPPKT_SYMBOL3(i);
--    tx5_cnt_uppkt_sym4_r(i)         <= CNT_TX5_UPPKT_SYMBOL4(i);
--    tx5_cnt_uppkt_sym5_r(i)         <= CNT_TX5_UPPKT_SYMBOL5(i);
--    tx5_cnt_uppkt_sym6_r(i)         <= CNT_TX5_UPPKT_SYMBOL6(i);
--    tx5_cnt_uppkt_sym7_r(i)         <= CNT_TX5_UPPKT_SYMBOL7(i);
--    tx5_cnt_uppkt_sym8_r(i)         <= CNT_TX5_UPPKT_SYMBOL8(i);
--    tx5_cnt_uppkt_sym9_r(i)         <= CNT_TX5_UPPKT_SYMBOL9(i);
--    tx5_cnt_uppkt_sym10_r(i)        <= CNT_TX5_UPPKT_SYMBOL10(i);
--    tx5_cnt_uppkt_sym11_r(i)        <= CNT_TX5_UPPKT_SYMBOL11(i);
--    tx5_cnt_uppkt_sym12_r(i)        <= CNT_TX5_UPPKT_SYMBOL12(i);
--    tx5_cnt_uppkt_sym13_r(i)        <= CNT_TX5_UPPKT_SYMBOL13(i);
--    tx5_cnt_cq_full_sym0_r(i)       <= CNT_TX5_CQ_FULL_SYMBOL0(i);
--    tx5_cnt_cq_full_sym1_r(i)       <= CNT_TX5_CQ_FULL_SYMBOL1(i);
--    tx5_cnt_cq_full_sym2_r(i)       <= CNT_TX5_CQ_FULL_SYMBOL2(i);
--    tx5_cnt_cq_full_sym3_r(i)       <= CNT_TX5_CQ_FULL_SYMBOL3(i);
--    tx5_cnt_cq_full_sym4_r(i)       <= CNT_TX5_CQ_FULL_SYMBOL4(i);
--    tx5_cnt_cq_full_sym5_r(i)       <= CNT_TX5_CQ_FULL_SYMBOL5(i);
--    tx5_cnt_cq_full_sym6_r(i)       <= CNT_TX5_CQ_FULL_SYMBOL6(i);
--    tx5_cnt_cq_full_sym7_r(i)       <= CNT_TX5_CQ_FULL_SYMBOL7(i);
--    tx5_cnt_cq_full_sym8_r(i)       <= CNT_TX5_CQ_FULL_SYMBOL8(i);
--    tx5_cnt_cq_full_sym9_r(i)       <= CNT_TX5_CQ_FULL_SYMBOL9(i);
--    tx5_cnt_cq_full_sym10_r(i)      <= CNT_TX5_CQ_FULL_SYMBOL10(i);
--    tx5_cnt_cq_full_sym11_r(i)      <= CNT_TX5_CQ_FULL_SYMBOL11(i);
--    tx5_cnt_cq_full_sym12_r(i)      <= CNT_TX5_CQ_FULL_SYMBOL12(i);
--    tx5_cnt_cq_full_sym13_r(i)      <= CNT_TX5_CQ_FULL_SYMBOL13(i);
--    tx5_usage_cq_sym0_r(i)          <= USAGE_TX5_CQ_SYMBOL0(i);
--    tx5_usage_cq_sym1_r(i)          <= USAGE_TX5_CQ_SYMBOL1(i);
--    tx5_usage_cq_sym2_r(i)          <= USAGE_TX5_CQ_SYMBOL2(i);
--    tx5_usage_cq_sym3_r(i)          <= USAGE_TX5_CQ_SYMBOL3(i);
--    tx5_usage_cq_sym4_r(i)          <= USAGE_TX5_CQ_SYMBOL4(i);
--    tx5_usage_cq_sym5_r(i)          <= USAGE_TX5_CQ_SYMBOL5(i);
--    tx5_usage_cq_sym6_r(i)          <= USAGE_TX5_CQ_SYMBOL6(i);
--    tx5_usage_cq_sym7_r(i)          <= USAGE_TX5_CQ_SYMBOL7(i);
--    tx5_usage_cq_sym8_r(i)          <= USAGE_TX5_CQ_SYMBOL8(i);
--    tx5_usage_cq_sym9_r(i)          <= USAGE_TX5_CQ_SYMBOL9(i);
--    tx5_usage_cq_sym10_r(i)         <= USAGE_TX5_CQ_SYMBOL10(i);
--    tx5_usage_cq_sym11_r(i)         <= USAGE_TX5_CQ_SYMBOL11(i);
--    tx5_usage_cq_sym12_r(i)         <= USAGE_TX5_CQ_SYMBOL12(i);
--    tx5_usage_cq_sym13_r(i)         <= USAGE_TX5_CQ_SYMBOL13(i);

    usage_tx0_up_buffer_r(i)        <= USAGE_TX0_UP_BUFFER(i);
    usage_tx1_up_buffer_r(i)        <= USAGE_TX1_UP_BUFFER(i);
    usage_tx2_up_buffer_r(i)        <= USAGE_TX2_UP_BUFFER(i);
    usage_tx3_up_buffer_r(i)        <= USAGE_TX3_UP_BUFFER(i);
    usage_tx4_up_buffer_r(i)        <= USAGE_TX4_UP_BUFFER(i);
--    usage_tx5_up_buffer_r(i)        <= USAGE_TX5_UP_BUFFER(i);

    cnt_tx0_r(i)                    <= CNT_TX0(i);
    cnt_tx1_r(i)                    <= CNT_TX1(i);
    cnt_tx2_r(i)                    <= CNT_TX2(i);
    cnt_tx3_r(i)                    <= CNT_TX3(i);
    cnt_tx4_r(i)                    <= CNT_TX4(i);
--    cnt_tx5_r(i)                    <= CNT_TX5(i);
    cnt_tx0_lost_r(i)               <= CNT_TX0_LOST(i);
    cnt_tx1_lost_r(i)               <= CNT_TX1_LOST(i);
    cnt_tx2_lost_r(i)               <= CNT_TX2_LOST(i);
    cnt_tx3_lost_r(i)               <= CNT_TX3_LOST(i);
    cnt_tx4_lost_r(i)               <= CNT_TX4_LOST(i);
--    cnt_tx5_lost_r(i)               <= CNT_TX5_LOST(i);
    end generate;

--------------------------------------------------------------------------------
-- Read register (for DL)
--------------------------------------------------------------------------------

-- 4cc 2t2r dl index select bit
--    set_dl_index_r <= "000" & set_dl_index_w(9 downto 8) & set_dl_index_w(0);   -- 0 ~ 7
-- 2cc 4t4r dl index select bit
--    set_dl_index_r <= "000" & set_dl_index_w(8) & set_dl_index_w(1 downto 0);   -- 0 ~ 7
    set_dl_index_r <= "00" & set_dl_index_w(9 downto 8) & set_dl_index_w(1 downto 0);   -- 0 ~ 7

    u_RD_DL0 : if IMPL_PDxCH = true generate
    u_0x0010_RD : MPI_REG_RD64 generic map(true,  DL*D0, 17) port map(CLK, set_dl_index_r, dl_eaxc_id_w(0),           dl_eaxc_id_r0(0) );
    u_0x0011_RD : MPI_REG_RD64 generic map(true,  DL*D0,  9) port map(CLK, set_dl_index_r, dl_comp_mode_w(0),         dl_comp_mode_r0(0) );
    u_0x0012_RD : MPI_REG_RD64 generic map(true,  DL*D0,  8) port map(CLK, set_dl_index_r, dl_frame_structure_w(0),   dl_frame_structure_r0(0) );
    u_0x0013_RD : MPI_REG_RD64 generic map(true,  DL*D0, 10) port map(CLK, set_dl_index_r, dl_prb_per_symbol_w(0),    dl_prb_per_symbol_r0(0) );
    u_0x0015_RD : MPI_REG_RD64 generic map(true,  DL*D0,  1) port map(CLK, set_dl_index_r, dl_pe_index_w(0),          dl_pe_index_r0(0) );
    u_0x0030_RD : MPI_REG_RD64 generic map(true,  DL*D0,  5) port map(CLK, set_dl_index_r, dl_comp_exp_offset_w(0),   dl_comp_exp_offset_r0(0) );
    end generate;

    u_RD_DL1 : if IMPL_SSB = true generate
    u_0x0010_RD : MPI_REG_RD64 generic map(true,  DL*D1, 17) port map(CLK, set_dl_index_r, dl_eaxc_id_w(1),           dl_eaxc_id_r0(1) );
    u_0x0011_RD : MPI_REG_RD64 generic map(true,  DL*D1,  9) port map(CLK, set_dl_index_r, dl_comp_mode_w(1),         dl_comp_mode_r0(1) );
    u_0x0012_RD : MPI_REG_RD64 generic map(true,  DL*D1,  8) port map(CLK, set_dl_index_r, dl_frame_structure_w(1),   dl_frame_structure_r0(1) );
    u_0x0013_RD : MPI_REG_RD64 generic map(true,  DL*D1, 10) port map(CLK, set_dl_index_r, dl_prb_per_symbol_w(1),    dl_prb_per_symbol_r0(1) );
    u_0x0015_RD : MPI_REG_RD64 generic map(true,  DL*D1,  1) port map(CLK, set_dl_index_r, dl_pe_index_w(1),          dl_pe_index_r0(1) );
    u_0x0030_RD : MPI_REG_RD64 generic map(true,  DL*D1,  5) port map(CLK, set_dl_index_r, dl_comp_exp_offset_w(1),   dl_comp_exp_offset_r0(1) );
    end generate;

    u_RD_DL2 : if IMPL_H_MATRIX = true generate
    u_0x0010_RD : MPI_REG_RD64 generic map(true,  DL*D2, 17) port map(CLK, set_dl_index_r, dl_eaxc_id_w(2),           dl_eaxc_id_r0(2) );
    u_0x0011_RD : MPI_REG_RD64 generic map(true,  DL*D2,  9) port map(CLK, set_dl_index_r, dl_comp_mode_w(2),         dl_comp_mode_r0(2) );
    u_0x0012_RD : MPI_REG_RD64 generic map(true,  DL*D2,  8) port map(CLK, set_dl_index_r, dl_frame_structure_w(2),   dl_frame_structure_r0(2) );
    u_0x0013_RD : MPI_REG_RD64 generic map(true,  DL*D2, 10) port map(CLK, set_dl_index_r, dl_prb_per_symbol_w(2),    dl_prb_per_symbol_r0(2) );
    u_0x0015_RD : MPI_REG_RD64 generic map(true,  DL*D2,  1) port map(CLK, set_dl_index_r, dl_pe_index_w(2),          dl_pe_index_r0(2) );
    u_0x0030_RD : MPI_REG_RD64 generic map(true,  DL*D2,  5) port map(CLK, set_dl_index_r, dl_comp_exp_offset_w(2),   dl_comp_exp_offset_r0(2) );
    end generate;

    u_0x0010_RD : MPI_REG_RD8  generic map(false,     1, 17) port map(CLK, set_dl_data_type_r, dl_eaxc_id_r0,         dl_eaxc_id_r1 );
    u_0x0011_RD : MPI_REG_RD8  generic map(false,     1,  9) port map(CLK, set_dl_data_type_r, dl_comp_mode_r0,       dl_comp_mode_r1 );
    u_0x0012_RD : MPI_REG_RD8  generic map(false,     1,  8) port map(CLK, set_dl_data_type_r, dl_frame_structure_r0, dl_frame_structure_r1 );
    u_0x0013_RD : MPI_REG_RD8  generic map(false,     1, 10) port map(CLK, set_dl_data_type_r, dl_prb_per_symbol_r0,  dl_prb_per_symbol_r1 );
    u_0x0015_RD : MPI_REG_RD8  generic map(false,     1,  1) port map(CLK, set_dl_data_type_r, dl_pe_index_r0,        dl_pe_index_r1 );
    u_0x0030_RD : MPI_REG_RD8  generic map(false,     1,  5) port map(CLK, set_dl_data_type_r, dl_comp_exp_offset_r0, dl_comp_exp_offset_r1 );

--------------------------------------------------------------------------------
-- Read register (for UL)
--------------------------------------------------------------------------------
-- 4cc 2t2r ul index select bit
--    set_ul_index_r <= "000" & set_ul_index_w(9 downto 8) & set_ul_index_w(0);   -- 0 ~ 7

-- 2cc 4t4r ul index select bit
    set_ul_index_r <= "00" & set_ul_index_w(9 downto 8) & set_ul_index_w(1 downto 0);   -- 0 ~ 7
    
    
    u_RD_UL0 : if IMPL_PUxCH = true generate
    u_0x0110_RD : MPI_REG_RD64 generic map(true,  UL*U0, 17) port map(CLK, set_ul_index_r, ul_eaxc_id_w(0),                  ul_eaxc_id_r0(0) );
    u_0x0111_RD : MPI_REG_RD64 generic map(true,  UL*U0,  9) port map(CLK, set_ul_index_r, ul_comp_mode_w(0),                ul_comp_mode_r0(0) );
    u_0x0112_RD : MPI_REG_RD64 generic map(true,  UL*U0,  8) port map(CLK, set_ul_index_r, ul_frame_structure_w(0),          ul_frame_structure_r0(0) );
    u_0x0113_RD : MPI_REG_RD64 generic map(true,  UL*U0, 10) port map(CLK, set_ul_index_r, ul_prb_per_symbol_w(0),           ul_prb_per_symbol_r0(0) );
    u_0x0114_RD : MPI_REG_RD64 generic map(true,  UL*U0, 10) port map(CLK, set_ul_index_r, ul_prb_per_mtu_w(0),              ul_prb_per_mtu_r0(0) );
    u_0x0115_RD : MPI_REG_RD64 generic map(true,  UL*U0,  1) port map(CLK, set_ul_index_r, ul_pe_index_w(0),                 ul_pe_index_r0(0) );
    u_0x0130_RD : MPI_REG_RD64 generic map(true,  UL*U0,  5) port map(CLK, set_ul_index_r, ul_comp_exp_offset_w(0),          ul_comp_exp_offset_r0(0) );
    u_0x0131_RD : MPI_REG_RD64 generic map(true,  UL*U0, 11) port map(CLK, set_ul_index_r, ul_comp_gain_offset_w(0),         ul_comp_gain_offset_r0(0) );
    u_0x0132_RD : MPI_REG_RD64 generic map(true,  UL*U0,  4) port map(CLK, set_ul_index_r, ul_comp_scale_gain_offset_w(0),   ul_comp_scale_gain_offset_r0(0) );
    end generate;

    u_RD_UL1 : if IMPL_PRACH = true generate
    u_0x0110_RD : MPI_REG_RD64 generic map(true,  UL*U1, 17) port map(CLK, set_ul_index_r, ul_eaxc_id_w(1),                  ul_eaxc_id_r0(1) );
    u_0x0111_RD : MPI_REG_RD64 generic map(true,  UL*U1,  9) port map(CLK, set_ul_index_r, ul_comp_mode_w(1),                ul_comp_mode_r0(1) );
    u_0x0112_RD : MPI_REG_RD64 generic map(true,  UL*U1,  8) port map(CLK, set_ul_index_r, ul_frame_structure_w(1),          ul_frame_structure_r0(1) );
    u_0x0113_RD : MPI_REG_RD64 generic map(true,  UL*U1, 10) port map(CLK, set_ul_index_r, ul_prb_per_symbol_w(1),           ul_prb_per_symbol_r0(1) );
    u_0x0114_RD : MPI_REG_RD64 generic map(true,  UL*U1, 10) port map(CLK, set_ul_index_r, ul_prb_per_mtu_w(1),              ul_prb_per_mtu_r0(1) );
    u_0x0115_RD : MPI_REG_RD64 generic map(true,  UL*U1,  1) port map(CLK, set_ul_index_r, ul_pe_index_w(1),                 ul_pe_index_r0(1) );
    u_0x0130_RD : MPI_REG_RD64 generic map(true,  UL*U1,  5) port map(CLK, set_ul_index_r, ul_comp_exp_offset_w(1),          ul_comp_exp_offset_r0(1) );
    u_0x0131_RD : MPI_REG_RD64 generic map(true,  UL*U1, 11) port map(CLK, set_ul_index_r, ul_comp_gain_offset_w(1),         ul_comp_gain_offset_r0(1) );
    u_0x0132_RD : MPI_REG_RD64 generic map(true,  UL*U1,  4) port map(CLK, set_ul_index_r, ul_comp_scale_gain_offset_w(1),   ul_comp_scale_gain_offset_r0(1) );
    end generate;

    u_RD_UL2 : if IMPL_SRS = true generate
    u_0x0110_RD : MPI_REG_RD64 generic map(true,  UL*U2, 17) port map(CLK, set_ul_index_r, ul_eaxc_id_w(2),                  ul_eaxc_id_r0(2) );
    u_0x0111_RD : MPI_REG_RD64 generic map(true,  UL*U2,  9) port map(CLK, set_ul_index_r, ul_comp_mode_w(2),                ul_comp_mode_r0(2) );
    u_0x0112_RD : MPI_REG_RD64 generic map(true,  UL*U2,  8) port map(CLK, set_ul_index_r, ul_frame_structure_w(2),          ul_frame_structure_r0(2) );
    u_0x0113_RD : MPI_REG_RD64 generic map(true,  UL*U2, 10) port map(CLK, set_ul_index_r, ul_prb_per_symbol_w(2),           ul_prb_per_symbol_r0(2) );
    u_0x0114_RD : MPI_REG_RD64 generic map(true,  UL*U2, 10) port map(CLK, set_ul_index_r, ul_prb_per_mtu_w(2),              ul_prb_per_mtu_r0(2) );
    u_0x0115_RD : MPI_REG_RD64 generic map(true,  UL*U2,  1) port map(CLK, set_ul_index_r, ul_pe_index_w(2),                 ul_pe_index_r0(2) );
    u_0x0130_RD : MPI_REG_RD64 generic map(true,  UL*U2,  5) port map(CLK, set_ul_index_r, ul_comp_exp_offset_w(2),          ul_comp_exp_offset_r0(2) );
    u_0x0131_RD : MPI_REG_RD64 generic map(true,  UL*U2, 11) port map(CLK, set_ul_index_r, ul_comp_gain_offset_w(2),         ul_comp_gain_offset_r0(2) );
    u_0x0132_RD : MPI_REG_RD64 generic map(true,  UL*U2,  4) port map(CLK, set_ul_index_r, ul_comp_scale_gain_offset_w(2),   ul_comp_scale_gain_offset_r0(2) );
    end generate;

    u_RD_UL3 : if IMPL_RIM_RS = true generate
    u_0x0110_RD : MPI_REG_RD64 generic map(true,  UL*U3, 17) port map(CLK, set_ul_index_r, ul_eaxc_id_w(3),                  ul_eaxc_id_r0(3) );
    u_0x0111_RD : MPI_REG_RD64 generic map(true,  UL*U3,  9) port map(CLK, set_ul_index_r, ul_comp_mode_w(3),                ul_comp_mode_r0(3) );
    u_0x0112_RD : MPI_REG_RD64 generic map(true,  UL*U3,  8) port map(CLK, set_ul_index_r, ul_frame_structure_w(3),          ul_frame_structure_r0(3) );
    u_0x0113_RD : MPI_REG_RD64 generic map(true,  UL*U3, 10) port map(CLK, set_ul_index_r, ul_prb_per_symbol_w(3),           ul_prb_per_symbol_r0(3) );
    u_0x0114_RD : MPI_REG_RD64 generic map(true,  UL*U3, 10) port map(CLK, set_ul_index_r, ul_prb_per_mtu_w(3),              ul_prb_per_mtu_r0(3) );
    u_0x0115_RD : MPI_REG_RD64 generic map(true,  UL*U3,  1) port map(CLK, set_ul_index_r, ul_pe_index_w(3),                 ul_pe_index_r0(3) );
    u_0x0130_RD : MPI_REG_RD64 generic map(true,  UL*U3,  5) port map(CLK, set_ul_index_r, ul_comp_exp_offset_w(3),          ul_comp_exp_offset_r0(3) );
    u_0x0131_RD : MPI_REG_RD64 generic map(true,  UL*U3, 11) port map(CLK, set_ul_index_r, ul_comp_gain_offset_w(3),         ul_comp_gain_offset_r0(3) );
    u_0x0132_RD : MPI_REG_RD64 generic map(true,  UL*U3,  4) port map(CLK, set_ul_index_r, ul_comp_scale_gain_offset_w(3),   ul_comp_scale_gain_offset_r0(3) );
    end generate;

    u_RD_UL4 : if IMPL_NB_IoT = true generate
    u_0x0110_RD : MPI_REG_RD64 generic map(true,  UL*U4, 17) port map(CLK, set_ul_index_r, ul_eaxc_id_w(4),                  ul_eaxc_id_r0(4) );
    u_0x0111_RD : MPI_REG_RD64 generic map(true,  UL*U4,  9) port map(CLK, set_ul_index_r, ul_comp_mode_w(4),                ul_comp_mode_r0(4) );
    u_0x0112_RD : MPI_REG_RD64 generic map(true,  UL*U4,  8) port map(CLK, set_ul_index_r, ul_frame_structure_w(4),          ul_frame_structure_r0(4) );
    u_0x0113_RD : MPI_REG_RD64 generic map(true,  UL*U4, 10) port map(CLK, set_ul_index_r, ul_prb_per_symbol_w(4),           ul_prb_per_symbol_r0(4) );
    u_0x0114_RD : MPI_REG_RD64 generic map(true,  UL*U4, 10) port map(CLK, set_ul_index_r, ul_prb_per_mtu_w(4),              ul_prb_per_mtu_r0(4) );
    u_0x0115_RD : MPI_REG_RD64 generic map(true,  UL*U4,  1) port map(CLK, set_ul_index_r, ul_pe_index_w(4),                 ul_pe_index_r0(4) );
    u_0x0130_RD : MPI_REG_RD64 generic map(true,  UL*U4,  5) port map(CLK, set_ul_index_r, ul_comp_exp_offset_w(4),          ul_comp_exp_offset_r0(4) );
    u_0x0131_RD : MPI_REG_RD64 generic map(true,  UL*U4, 11) port map(CLK, set_ul_index_r, ul_comp_gain_offset_w(4),         ul_comp_gain_offset_r0(4) );
    u_0x0132_RD : MPI_REG_RD64 generic map(true,  UL*U4,  4) port map(CLK, set_ul_index_r, ul_comp_scale_gain_offset_w(4),   ul_comp_scale_gain_offset_r0(4) );
    end generate;

 --   u_0x0110_RD : MPI_REG_RD8  generic map(false,     2, 17) port map(CLK, set_ul_data_type_r, ul_eaxc_id_r0,                ul_eaxc_id_r1 );
 --   u_0x0111_RD : MPI_REG_RD8  generic map(false,     2,  9) port map(CLK, set_ul_data_type_r, ul_comp_mode_r0,              ul_comp_mode_r1 );
 --   u_0x0112_RD : MPI_REG_RD8  generic map(false,     2,  8) port map(CLK, set_ul_data_type_r, ul_frame_structure_r0,        ul_frame_structure_r1 );
 --   u_0x0113_RD : MPI_REG_RD8  generic map(false,     2, 10) port map(CLK, set_ul_data_type_r, ul_prb_per_symbol_r0,         ul_prb_per_symbol_r1 );
 --   u_0x0114_RD : MPI_REG_RD8  generic map(false,     2, 10) port map(CLK, set_ul_data_type_r, ul_prb_per_mtu_r0,            ul_prb_per_mtu_r1 );
 --   u_0x0115_RD : MPI_REG_RD8  generic map(false,     2,  1) port map(CLK, set_ul_data_type_r, ul_pe_index_r0,               ul_pe_index_r1 );
 --   u_0x0130_RD : MPI_REG_RD8  generic map(false,     2,  5) port map(CLK, set_ul_data_type_r, ul_comp_exp_offset_r0,        ul_comp_exp_offset_r1 );
 --   u_0x0131_RD : MPI_REG_RD8  generic map(false,     2, 11) port map(CLK, set_ul_data_type_r, ul_comp_gain_offset_r0,       ul_comp_gain_offset_r1 );
 --   u_0x0132_RD : MPI_REG_RD8  generic map(false,     2,  4) port map(CLK, set_ul_data_type_r, ul_comp_scale_gain_offset_r0, ul_comp_scale_gain_offset_r1 );

    u_0x0110_RD : MPI_REG_RD8  generic map(false,     5, 17) port map(CLK, set_ul_data_type_r, ul_eaxc_id_r0,                ul_eaxc_id_r1 );
    u_0x0111_RD : MPI_REG_RD8  generic map(false,     5,  9) port map(CLK, set_ul_data_type_r, ul_comp_mode_r0,              ul_comp_mode_r1 );
    u_0x0112_RD : MPI_REG_RD8  generic map(false,     5,  8) port map(CLK, set_ul_data_type_r, ul_frame_structure_r0,        ul_frame_structure_r1 );
    u_0x0113_RD : MPI_REG_RD8  generic map(false,     5, 10) port map(CLK, set_ul_data_type_r, ul_prb_per_symbol_r0,         ul_prb_per_symbol_r1 );
    u_0x0114_RD : MPI_REG_RD8  generic map(false,     5, 10) port map(CLK, set_ul_data_type_r, ul_prb_per_mtu_r0,            ul_prb_per_mtu_r1 );
    u_0x0115_RD : MPI_REG_RD8  generic map(false,     5,  1) port map(CLK, set_ul_data_type_r, ul_pe_index_r0,               ul_pe_index_r1 );
    u_0x0130_RD : MPI_REG_RD8  generic map(false,     5,  5) port map(CLK, set_ul_data_type_r, ul_comp_exp_offset_r0,        ul_comp_exp_offset_r1 );
    u_0x0131_RD : MPI_REG_RD8  generic map(false,     5, 11) port map(CLK, set_ul_data_type_r, ul_comp_gain_offset_r0,       ul_comp_gain_offset_r1 );
    u_0x0132_RD : MPI_REG_RD8  generic map(false,     5,  4) port map(CLK, set_ul_data_type_r, ul_comp_scale_gain_offset_r0, ul_comp_scale_gain_offset_r1 );

--------------------------------------------------------------------------------
-- Read register (for PE)
--------------------------------------------------------------------------------

    set_pe_index_r <= set_pe_index_w;
    sts_pe_index_r <= sts_pe_index_w;

    u_0x0250_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, set_pe_index_r, ru_mac_31_to_0_w,     ru_mac_31_to_0_r );
    u_0x0251_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, set_pe_index_r, ru_mac_47_to_32_w,    ru_mac_47_to_32_r );
    u_0x0252_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, set_pe_index_r, du_mac_31_to_0_w,     du_mac_31_to_0_r );
    u_0x0253_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, set_pe_index_r, du_mac_47_to_32_w,    du_mac_47_to_32_r );
    u_0x0254_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, set_pe_index_r, vlan0_vid_w,          vlan0_vid_r );
--    u_0x0255_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, set_pe_index_r, vlan1_vid_w,          vlan1_vid_r );

    u_0x0270_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, capture_period_w,     capture_period_r );

    u_0x02C0_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, rx_total_upper_w,     rx_total_upper_r );
    u_0x02C1_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, rx_total_lower_w,     rx_total_lower_r );
    u_0x02C2_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, rx_on_time_u_upper_w, rx_on_time_u_upper_r );
    u_0x02C3_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, rx_on_time_u_lower_w, rx_on_time_u_lower_r );
    u_0x02C4_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, rx_early_u_upper_w,   rx_early_u_upper_r );
    u_0x02C5_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, rx_early_u_lower_w,   rx_early_u_lower_r );
    u_0x02C6_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, rx_late_u_upper_w,    rx_late_u_upper_r );
    u_0x02C7_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, rx_late_u_lower_w,    rx_late_u_lower_r );

    u_0x02CA_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, rx_on_time_c_upper_w, rx_on_time_c_upper_r );
    u_0x02CB_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, rx_on_time_c_lower_w, rx_on_time_c_lower_r );
    u_0x02CC_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, rx_early_c_upper_w,   rx_early_c_upper_r );
    u_0x02CD_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, rx_early_c_lower_w,   rx_early_c_lower_r );
    u_0x02CE_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, rx_late_c_upper_w,    rx_late_c_upper_r );
    u_0x02CF_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, rx_late_c_lower_w,    rx_late_c_lower_r );

    -- RX CORRUPT
    u_0x02D2_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, s_w_cnt_rx_corrupt_upper,    s_r_cnt_rx_corrupt_upper);
    u_0x02D3_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, s_w_cnt_rx_corrupt_lower,    s_r_cnt_rx_corrupt_lower);

    -- Write registers for 't2a_max/min' is moved to SCS section
    u_0x0300_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_on_time0_upper_w, dl_cp_rx_on_time0_upper_r );
    u_0x0301_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_on_time0_lower_w, dl_cp_rx_on_time0_lower_r );
    u_0x0302_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_early0_upper_w,   dl_cp_rx_early0_upper_r );
    u_0x0303_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_early0_lower_w,   dl_cp_rx_early0_lower_r );
    u_0x0304_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_late0_upper_w,    dl_cp_rx_late0_upper_r );
    u_0x0305_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_late0_lower_w,    dl_cp_rx_late0_lower_r );
    u_0x0306_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_ndm0_upper_w,     dl_cp_rx_ndm0_upper_r );
    u_0x0307_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_ndm0_lower_w,     dl_cp_rx_ndm0_lower_r );
    u_0x0308_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_on_time1_upper_w, dl_cp_rx_on_time1_upper_r );
    u_0x0309_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_on_time1_lower_w, dl_cp_rx_on_time1_lower_r );
    u_0x030A_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_early1_upper_w,   dl_cp_rx_early1_upper_r );
    u_0x030B_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_early1_lower_w,   dl_cp_rx_early1_lower_r );
    u_0x030C_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_late1_upper_w,    dl_cp_rx_late1_upper_r );
    u_0x030D_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_late1_lower_w,    dl_cp_rx_late1_lower_r );
    u_0x030E_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_ndm1_upper_w,     dl_cp_rx_ndm1_upper_r );
    u_0x030F_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_ndm1_lower_w,     dl_cp_rx_ndm1_lower_r );
    u_0x0310_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_on_time2_upper_w, dl_cp_rx_on_time2_upper_r );
    u_0x0311_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_on_time2_lower_w, dl_cp_rx_on_time2_lower_r );
    u_0x0312_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_early2_upper_w,   dl_cp_rx_early2_upper_r );
    u_0x0313_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_early2_lower_w,   dl_cp_rx_early2_lower_r );
    u_0x0314_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_late2_upper_w,    dl_cp_rx_late2_upper_r );
    u_0x0315_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_late2_lower_w,    dl_cp_rx_late2_lower_r );
    u_0x0316_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_ndm2_upper_w,     dl_cp_rx_ndm2_upper_r );
    u_0x0317_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_ndm2_lower_w,     dl_cp_rx_ndm2_lower_r );
    u_0x0318_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_on_time3_upper_w, dl_cp_rx_on_time3_upper_r );
    u_0x0319_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_on_time3_lower_w, dl_cp_rx_on_time3_lower_r );
    u_0x031A_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_early3_upper_w,   dl_cp_rx_early3_upper_r );
    u_0x031B_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_early3_lower_w,   dl_cp_rx_early3_lower_r );
    u_0x031C_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_late3_upper_w,    dl_cp_rx_late3_upper_r );
    u_0x031D_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_late3_lower_w,    dl_cp_rx_late3_lower_r );
    u_0x031E_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_ndm3_upper_w,     dl_cp_rx_ndm3_upper_r );
    u_0x031F_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_ndm3_lower_w,     dl_cp_rx_ndm3_lower_r );
    u_0x0320_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_on_time4_upper_w, dl_cp_rx_on_time4_upper_r );
    u_0x0321_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_on_time4_lower_w, dl_cp_rx_on_time4_lower_r );
    u_0x0322_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_early4_upper_w,   dl_cp_rx_early4_upper_r );
    u_0x0323_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_early4_lower_w,   dl_cp_rx_early4_lower_r );
    u_0x0324_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_late4_upper_w,    dl_cp_rx_late4_upper_r );
    u_0x0325_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_late4_lower_w,    dl_cp_rx_late4_lower_r );
    u_0x0326_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_ndm4_upper_w,     dl_cp_rx_ndm4_upper_r );
    u_0x0327_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_cp_rx_ndm4_lower_w,     dl_cp_rx_ndm4_lower_r );

    u_0x0328_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_on_time0_upper_w, dl_up_rx_on_time0_upper_r );
    u_0x0329_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_on_time0_lower_w, dl_up_rx_on_time0_lower_r );
    u_0x032A_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_early0_upper_w,   dl_up_rx_early0_upper_r );
    u_0x032B_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_early0_lower_w,   dl_up_rx_early0_lower_r );
    u_0x032C_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_late0_upper_w,    dl_up_rx_late0_upper_r );
    u_0x032D_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_late0_lower_w,    dl_up_rx_late0_lower_r );
    u_0x032E_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_ndm0_upper_w,     dl_up_rx_ndm0_upper_r );
    u_0x032F_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_ndm0_lower_w,     dl_up_rx_ndm0_lower_r );
    u_0x0330_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_on_time1_upper_w, dl_up_rx_on_time1_upper_r );
    u_0x0331_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_on_time1_lower_w, dl_up_rx_on_time1_lower_r );
    u_0x0332_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_early1_upper_w,   dl_up_rx_early1_upper_r );
    u_0x0333_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_early1_lower_w,   dl_up_rx_early1_lower_r );
    u_0x0334_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_late1_upper_w,    dl_up_rx_late1_upper_r );
    u_0x0335_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_late1_lower_w,    dl_up_rx_late1_lower_r );
    u_0x0336_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_ndm1_upper_w,     dl_up_rx_ndm1_upper_r );
    u_0x0337_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_ndm1_lower_w,     dl_up_rx_ndm1_lower_r );
    u_0x0338_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_on_time2_upper_w, dl_up_rx_on_time2_upper_r );
    u_0x0339_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_on_time2_lower_w, dl_up_rx_on_time2_lower_r );
    u_0x033A_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_early2_upper_w,   dl_up_rx_early2_upper_r );
    u_0x033B_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_early2_lower_w,   dl_up_rx_early2_lower_r );
    u_0x033C_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_late2_upper_w,    dl_up_rx_late2_upper_r );
    u_0x033D_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_late2_lower_w,    dl_up_rx_late2_lower_r );
    u_0x033E_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_ndm2_upper_w,     dl_up_rx_ndm2_upper_r );
    u_0x033F_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_ndm2_lower_w,     dl_up_rx_ndm2_lower_r );
    u_0x0340_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_on_time3_upper_w, dl_up_rx_on_time3_upper_r );
    u_0x0341_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_on_time3_lower_w, dl_up_rx_on_time3_lower_r );
    u_0x0342_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_early3_upper_w,   dl_up_rx_early3_upper_r );
    u_0x0343_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_early3_lower_w,   dl_up_rx_early3_lower_r );
    u_0x0344_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_late3_upper_w,    dl_up_rx_late3_upper_r );
    u_0x0345_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_late3_lower_w,    dl_up_rx_late3_lower_r );
    u_0x0346_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_ndm3_upper_w,     dl_up_rx_ndm3_upper_r );
    u_0x0347_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_ndm3_lower_w,     dl_up_rx_ndm3_lower_r );
    u_0x0348_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_on_time4_upper_w, dl_up_rx_on_time4_upper_r );
    u_0x0349_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_on_time4_lower_w, dl_up_rx_on_time4_lower_r );
    u_0x034A_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_early4_upper_w,   dl_up_rx_early4_upper_r );
    u_0x034B_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_early4_lower_w,   dl_up_rx_early4_lower_r );
    u_0x034C_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_late4_upper_w,    dl_up_rx_late4_upper_r );
    u_0x034D_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_late4_lower_w,    dl_up_rx_late4_lower_r );
    u_0x034E_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_ndm4_upper_w,     dl_up_rx_ndm4_upper_r );
    u_0x034F_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, dl_up_rx_ndm4_lower_w,     dl_up_rx_ndm4_lower_r );

    u_0x0350_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_on_time0_upper_w, ul_cp_rx_on_time0_upper_r );
    u_0x0351_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_on_time0_lower_w, ul_cp_rx_on_time0_lower_r );
    u_0x0352_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_early0_upper_w,   ul_cp_rx_early0_upper_r );
    u_0x0353_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_early0_lower_w,   ul_cp_rx_early0_lower_r );
    u_0x0354_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_late0_upper_w,    ul_cp_rx_late0_upper_r );
    u_0x0355_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_late0_lower_w,    ul_cp_rx_late0_lower_r );
    u_0x0356_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_ndm0_upper_w,     ul_cp_rx_ndm0_upper_r );
    u_0x0357_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_ndm0_lower_w,     ul_cp_rx_ndm0_lower_r );
    u_0x0358_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_on_time1_upper_w, ul_cp_rx_on_time1_upper_r );
    u_0x0359_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_on_time1_lower_w, ul_cp_rx_on_time1_lower_r );
    u_0x035A_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_early1_upper_w,   ul_cp_rx_early1_upper_r );
    u_0x035B_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_early1_lower_w,   ul_cp_rx_early1_lower_r );
    u_0x035C_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_late1_upper_w,    ul_cp_rx_late1_upper_r );
    u_0x035D_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_late1_lower_w,    ul_cp_rx_late1_lower_r );
    u_0x035E_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_ndm1_upper_w,     ul_cp_rx_ndm1_upper_r );
    u_0x035F_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_ndm1_lower_w,     ul_cp_rx_ndm1_lower_r );
    u_0x0360_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_on_time2_upper_w, ul_cp_rx_on_time2_upper_r );
    u_0x0361_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_on_time2_lower_w, ul_cp_rx_on_time2_lower_r );
    u_0x0362_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_early2_upper_w,   ul_cp_rx_early2_upper_r );
    u_0x0363_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_early2_lower_w,   ul_cp_rx_early2_lower_r );
    u_0x0364_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_late2_upper_w,    ul_cp_rx_late2_upper_r );
    u_0x0365_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_late2_lower_w,    ul_cp_rx_late2_lower_r );
    u_0x0366_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_ndm2_upper_w,     ul_cp_rx_ndm2_upper_r );
    u_0x0367_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_ndm2_lower_w,     ul_cp_rx_ndm2_lower_r );
    u_0x0368_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_on_time3_upper_w, ul_cp_rx_on_time3_upper_r );
    u_0x0369_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_on_time3_lower_w, ul_cp_rx_on_time3_lower_r );
    u_0x036A_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_early3_upper_w,   ul_cp_rx_early3_upper_r );
    u_0x036B_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_early3_lower_w,   ul_cp_rx_early3_lower_r );
    u_0x036C_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_late3_upper_w,    ul_cp_rx_late3_upper_r );
    u_0x036D_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_late3_lower_w,    ul_cp_rx_late3_lower_r );
    u_0x036E_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_ndm3_upper_w,     ul_cp_rx_ndm3_upper_r );
    u_0x036F_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_ndm3_lower_w,     ul_cp_rx_ndm3_lower_r );
    u_0x0370_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_on_time4_upper_w, ul_cp_rx_on_time4_upper_r );
    u_0x0371_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_on_time4_lower_w, ul_cp_rx_on_time4_lower_r );
    u_0x0372_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_early4_upper_w,   ul_cp_rx_early4_upper_r );
    u_0x0373_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_early4_lower_w,   ul_cp_rx_early4_lower_r );
    u_0x0374_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_late4_upper_w,    ul_cp_rx_late4_upper_r );
    u_0x0375_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_late4_lower_w,    ul_cp_rx_late4_lower_r );
    u_0x0376_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_ndm4_upper_w,     ul_cp_rx_ndm4_upper_r );
    u_0x0377_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_cp_rx_ndm4_lower_w,     ul_cp_rx_ndm4_lower_r );

    u_0x0380_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_up_tx_upper_w,          ul_up_tx_upper_r );
    u_0x0381_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, ul_up_tx_lower_w,          ul_up_tx_lower_r );

    -- rx corrupt debug registers
    u_0x0390_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, s_w_cnt_rx_corrupt_pcid_ecpriv_payloadv_upper, s_r_cnt_rx_corrupt_pcid_ecpriv_payloadv_upper); 
    u_0x0391_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, s_w_cnt_rx_corrupt_pcid_ecpriv_payloadv_lower, s_r_cnt_rx_corrupt_pcid_ecpriv_payloadv_lower); 
    u_0x0392_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, s_w_cnt_rx_corrupt_pcid_upper,                 s_r_cnt_rx_corrupt_pcid_upper                ); 
    u_0x0393_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, s_w_cnt_rx_corrupt_pcid_lower,                 s_r_cnt_rx_corrupt_pcid_lower                ); 
    u_0x0394_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, s_w_cnt_rx_corrupt_ecpriv_upper,               s_r_cnt_rx_corrupt_ecpriv_upper              ); 
    u_0x0395_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, s_w_cnt_rx_corrupt_ecpriv_lower,               s_r_cnt_rx_corrupt_ecpriv_lower              ); 
    u_0x0396_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, s_w_cnt_rx_corrupt_payloadv_upper,             s_r_cnt_rx_corrupt_payloadv_upper            ); 
    u_0x0397_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, s_w_cnt_rx_corrupt_payloadv_lower,             s_r_cnt_rx_corrupt_payloadv_lower            ); 
    u_0x0398_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, s_w_cnt_rx_corrupt_sectionid_upper,            s_r_cnt_rx_corrupt_sectionid_upper           ); 
    u_0x0399_RD : MPI_REG_RD8 generic map(false, MAX_PE, 32) port map(CLK, sts_pe_index_r, s_w_cnt_rx_corrupt_sectionid_lower,            s_r_cnt_rx_corrupt_sectionid_lower           ); 
    
--------------------------------------------------------------------------------
-- SCS dependent
--------------------------------------------------------------------------------

    u_SCS_15kHz : if SCS_CONFIG_0 = true generate
    u_0x0280_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_max0_dl_cp_rx_w, t2a_max0_dl_cp_rx_r );
    u_0x0281_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_min0_dl_cp_rx_w, t2a_min0_dl_cp_rx_r );
    u_0x0290_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_max0_dl_up_rx_w, t2a_max0_dl_up_rx_r );
    u_0x0291_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_min0_dl_up_rx_w, t2a_min0_dl_up_rx_r );
    u_0x02A0_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_max0_ul_cp_rx_w, t2a_max0_ul_cp_rx_r );
    u_0x02A1_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_min0_ul_cp_rx_w, t2a_min0_ul_cp_rx_r );
    end generate;

    u_SCS_30kHz : if SCS_CONFIG_1 = true generate
    u_0x0282_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_max1_dl_cp_rx_w, t2a_max1_dl_cp_rx_r );
    u_0x0283_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_min1_dl_cp_rx_w, t2a_min1_dl_cp_rx_r );
    u_0x0292_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_max1_dl_up_rx_w, t2a_max1_dl_up_rx_r );
    u_0x0293_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_min1_dl_up_rx_w, t2a_min1_dl_up_rx_r );
    u_0x02A2_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_max1_ul_cp_rx_w, t2a_max1_ul_cp_rx_r );
    u_0x02A3_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_min1_ul_cp_rx_w, t2a_min1_ul_cp_rx_r );
    end generate;

    u_SCS_60kHz : if SCS_CONFIG_2 = true generate
    u_0x0284_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_max2_dl_cp_rx_w, t2a_max2_dl_cp_rx_r );
    u_0x0285_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_min2_dl_cp_rx_w, t2a_min2_dl_cp_rx_r );
    u_0x0294_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_max2_dl_up_rx_w, t2a_max2_dl_up_rx_r );
    u_0x0295_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_min2_dl_up_rx_w, t2a_min2_dl_up_rx_r );
    u_0x02A4_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_max2_ul_cp_rx_w, t2a_max2_ul_cp_rx_r );
    u_0x02A5_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_min2_ul_cp_rx_w, t2a_min2_ul_cp_rx_r );
    end generate;

    u_SCS_120kHz : if SCS_CONFIG_3 = true generate
    u_0x0286_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_max3_dl_cp_rx_w, t2a_max3_dl_cp_rx_r );
    u_0x0287_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_min3_dl_cp_rx_w, t2a_min3_dl_cp_rx_r );
    u_0x0296_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_max3_dl_up_rx_w, t2a_max3_dl_up_rx_r );
    u_0x0297_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_min3_dl_up_rx_w, t2a_min3_dl_up_rx_r );
    u_0x02A6_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_max3_ul_cp_rx_w, t2a_max3_ul_cp_rx_r );
    u_0x02A7_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_min3_ul_cp_rx_w, t2a_min3_ul_cp_rx_r );
    end generate;

    u_SCS_240kHz : if SCS_CONFIG_4 = true generate
    u_0x0288_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_max4_dl_cp_rx_w, t2a_max4_dl_cp_rx_r );
    u_0x0289_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_min4_dl_cp_rx_w, t2a_min4_dl_cp_rx_r );
    u_0x0298_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_max4_dl_up_rx_w, t2a_max4_dl_up_rx_r );
    u_0x0299_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_min4_dl_up_rx_w, t2a_min4_dl_up_rx_r );
    u_0x02A8_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_max4_ul_cp_rx_w, t2a_max4_ul_cp_rx_r );
    u_0x02A9_RD : MPI_REG_RD8 generic map(false, MAX_PE, 22) port map(CLK, sts_pe_index_r, t2a_min4_ul_cp_rx_w, t2a_min4_ul_cp_rx_r );
    end generate;

--------------------------------------------------------------------------------
-- Write register
--------------------------------------------------------------------------------

    u_0x0000_WO : MPI_REG_WO generic map(0, MAP_ONE,   3, x"00", x"00000000") port map(RST, CLK, '1', we(0), addr_lsb, WDATA_CPUIF_IN, set_dl_data_type_w );
    u_0x0002_WO : MPI_REG_WO generic map(0, MAP_ONE,  16, x"02", x"00000000") port map(RST, CLK, '1', we(0), addr_lsb, WDATA_CPUIF_IN, set_dl_index_w );
    u_0x0003_WO : MPI_REG_WO generic map(0, MAP_ONE,  32, x"03", x"00000000") port map(RST, CLK, '1', we(0), addr_lsb, WDATA_CPUIF_IN, dl_uplane_only_en_w );

    u_0x000C_WO : MPI_REG_WO generic map(0, MAP_ONE,  32, x"0C", x"00000000") port map(RST, CLK, '1', we(0), addr_lsb, WDATA_CPUIF_IN, user_debug0_r );
    u_0x000D_WO : MPI_REG_WO generic map(0, MAP_ONE,  32, x"0D", x"00000000") port map(RST, CLK, '1', we(0), addr_lsb, WDATA_CPUIF_IN, user_debug1_r );
    u_0x000E_WO : MPI_REG_WO generic map(0, MAP_ONE,  32, x"0E", x"00000000") port map(RST, CLK, '1', we(0), addr_lsb, WDATA_CPUIF_IN, user_debug2_r );
    u_0x000F_WO : MPI_REG_WO generic map(0, MAP_ONE,  32, x"0F", x"00000000") port map(RST, CLK, '1', we(0), addr_lsb, WDATA_CPUIF_IN, user_debug3_r );

    u_0x0080_WO : MPI_REG_WO generic map(0, MAP_ONE,   3, x"80", x"00000000") port map(RST, CLK, '1', we(0), addr_lsb, WDATA_CPUIF_IN, sts_dl_data_type_w );
    u_0x0082_WO : MPI_REG_WO generic map(0, MAP_ONE,  16, x"82", x"00000000") port map(RST, CLK, '1', we(0), addr_lsb, WDATA_CPUIF_IN, sts_dl_index_w );

    u_0x0100_WO : MPI_REG_WO generic map(0, MAP_ONE,   3, x"00", x"00000000") port map(RST, CLK, '1', we(1), addr_lsb, WDATA_CPUIF_IN, set_ul_data_type_w );
    u_0x0102_WO : MPI_REG_WO generic map(0, MAP_ONE,  16, x"02", x"00000000") port map(RST, CLK, '1', we(1), addr_lsb, WDATA_CPUIF_IN, set_ul_index_w );

    u_0x0180_WO : MPI_REG_WO generic map(0, MAP_ONE,   3, x"80", x"00000000") port map(RST, CLK, '1', we(1), addr_lsb, WDATA_CPUIF_IN, sts_ul_data_type_w );
    u_0x0182_WO : MPI_REG_WO generic map(0, MAP_ONE,  16, x"82", x"00000000") port map(RST, CLK, '1', we(1), addr_lsb, WDATA_CPUIF_IN, sts_ul_index_w );

    u_0x0242_WO : MPI_REG_WO generic map(0, MAP_ONE,   3, x"42", x"00000000") port map(RST, CLK, '1', we(2), addr_lsb, WDATA_CPUIF_IN, set_pe_index_w );

    u_0x0262_WO : MPI_REG_WO generic map(0, MAP_ONE,   3, x"62", x"00000000") port map(RST, CLK, '1', we(2), addr_lsb, WDATA_CPUIF_IN, sts_pe_index_w );

--------------------------------------------------------------------------------
-- Write register (For GSM)
--------------------------------------------------------------------------------

    u_0x0040_WO : MPI_REG_WO generic map(0, MAP_ONE,   1, x"40", x"00000000") port map(RST, CLK, '1', we(0), addr_lsb, WDATA_CPUIF_IN, dss_test_en_w );

--------------------------------------------------------------------------------
-- Write register (for PDxCH, Data type 0)
--------------------------------------------------------------------------------

    u_WR_PDxCH : for j in MAX_CC_DL*MAX_PDxCH-1 downto 0 generate
    active_pdxch(j) <= '1' when (set_dl_data_type_r = 0) and (set_dl_index_r = j) else '0';

    u_0x0010_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"10", x"00000000") port map(RST, CLK, active_pdxch(j), we(0), addr_lsb, WDATA_CPUIF_IN, dl_eaxc_id_w(0)(j) );
    u_0x0011_WO : MPI_REG_WO generic map(j, MAP_PDxCH,  32, x"11", x"00000000") port map(RST, CLK, active_pdxch(j), we(0), addr_lsb, WDATA_CPUIF_IN, dl_comp_mode_w(0)(j) );
    u_0x0012_WO : MPI_REG_WO generic map(j, MAP_PDxCH,  32, x"12", x"0000001C") port map(RST, CLK, active_pdxch(j), we(0), addr_lsb, WDATA_CPUIF_IN, dl_frame_structure_w(0)(j) );
    u_0x0013_WO : MPI_REG_WO generic map(j, MAP_PDxCH,  32, x"13", x"00000111") port map(RST, CLK, active_pdxch(j), we(0), addr_lsb, WDATA_CPUIF_IN, dl_prb_per_symbol_w(0)(j) );
    u_0x0015_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"15", x"00000000") port map(RST, CLK, active_pdxch(j), we(0), addr_lsb, WDATA_CPUIF_IN, dl_pe_index_w(0)(j) );

    u_0x0030_WO : MPI_REG_WO generic map(j, MAP_PDxCH,  32, x"30", x"00000000") port map(RST, CLK, active_pdxch(j), we(0), addr_lsb, WDATA_CPUIF_IN, dl_comp_exp_offset_w(0)(j) );
    end generate;

--------------------------------------------------------------------------------
-- Write register (for SSB, Data type 1)
--------------------------------------------------------------------------------

    -- Not implemented

--------------------------------------------------------------------------------
-- Write register (for H matrix, Data type 2)
--------------------------------------------------------------------------------

    -- Not implemented

--------------------------------------------------------------------------------
-- Write register (for PUxCH, Data type 0)
--------------------------------------------------------------------------------

    u_WR_PUxCH : for j in MAX_CC_UL*MAX_PUxCH-1 downto 0 generate
    active_puxch(j) <= '1' when (set_ul_data_type_r = 0) and (set_ul_index_r = j) else '0';

    u_0x0010_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"10", x"00000000") port map(RST, CLK, active_puxch(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_eaxc_id_w(0)(j) );
    u_0x0011_WO : MPI_REG_WO generic map(j, MAP_PUxCH,  32, x"11", x"00000000") port map(RST, CLK, active_puxch(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_comp_mode_w(0)(j) );
    u_0x0012_WO : MPI_REG_WO generic map(j, MAP_PUxCH,  32, x"12", x"0000001C") port map(RST, CLK, active_puxch(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_frame_structure_w(0)(j) );
    u_0x0013_WO : MPI_REG_WO generic map(j, MAP_PUxCH,  32, x"13", x"00000111") port map(RST, CLK, active_puxch(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_prb_per_symbol_w(0)(j) );
    u_0x0014_WO : MPI_REG_WO generic map(j, MAP_PUxCH,  32, x"14", x"00000064") port map(RST, CLK, active_puxch(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_prb_per_mtu_w(0)(j) );
    u_0x0015_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"15", x"00000000") port map(RST, CLK, active_puxch(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_pe_index_w(0)(j) );

    u_0x0030_WO : MPI_REG_WO generic map(j, MAP_PUxCH,  32, x"30", x"00000000") port map(RST, CLK, active_puxch(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_comp_exp_offset_w(0)(j) );
    u_0x0031_WO : MPI_REG_WO generic map(j, MAP_PUxCH,  32, x"31", x"00000001") port map(RST, CLK, active_puxch(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_comp_gain_offset_w(0)(j) );
    u_0x0032_WO : MPI_REG_WO generic map(j, MAP_PUxCH,  32, x"32", x"00000000") port map(RST, CLK, active_puxch(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_comp_scale_gain_offset_w(0)(j) );
    end generate;

--------------------------------------------------------------------------------
-- Write register (for PRACH, Data type 1)
--------------------------------------------------------------------------------

    u_WR_PRACH : for j in MAX_CC_UL*MAX_PRACH-1 downto 0 generate
    active_prach(j) <= '1' when (set_ul_data_type_r = 1) and (set_ul_index_r = j) else '0';

    u_0x0010_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"10", x"00000000") port map(RST, CLK, active_prach(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_eaxc_id_w(1)(j) );
    u_0x0011_WO : MPI_REG_WO generic map(j, MAP_PRACH,  32, x"11", x"00000000") port map(RST, CLK, active_prach(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_comp_mode_w(1)(j) );
    u_0x0012_WO : MPI_REG_WO generic map(j, MAP_PRACH,  32, x"12", x"0000001C") port map(RST, CLK, active_prach(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_frame_structure_w(1)(j) );
    u_0x0013_WO : MPI_REG_WO generic map(j, MAP_PRACH,  32, x"13", x"00000111") port map(RST, CLK, active_prach(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_prb_per_symbol_w(1)(j) );
    u_0x0014_WO : MPI_REG_WO generic map(j, MAP_PRACH,  32, x"14", x"00000064") port map(RST, CLK, active_prach(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_prb_per_mtu_w(1)(j) );
    u_0x0015_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"15", x"00000000") port map(RST, CLK, active_prach(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_pe_index_w(1)(j) );

    u_0x0030_WO : MPI_REG_WO generic map(j, MAP_PRACH,  32, x"30", x"00000000") port map(RST, CLK, active_prach(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_comp_exp_offset_w(1)(j) );
    u_0x0031_WO : MPI_REG_WO generic map(j, MAP_PRACH,  32, x"31", x"00000001") port map(RST, CLK, active_prach(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_comp_gain_offset_w(1)(j) );
    u_0x0032_WO : MPI_REG_WO generic map(j, MAP_PRACH,  32, x"32", x"00000000") port map(RST, CLK, active_prach(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_comp_scale_gain_offset_w(1)(j) );
    end generate;

--------------------------------------------------------------------------------
-- Write register (for SRS, Data type 2)
--------------------------------------------------------------------------------

    -- Not implemented

--------------------------------------------------------------------------------
-- Write register (for RIM-RS, Data type 3)
--------------------------------------------------------------------------------

    -- Not implemented

--------------------------------------------------------------------------------
-- Write register (for NB-IoT, Data type 4)
--------------------------------------------------------------------------------

    u_WR_NB_IoT : for j in MAX_CC_UL*MAX_NB_IoT-1 downto 0 generate
    active_nbiot(j) <= '1' when (set_ul_data_type_r = 4) and (set_ul_index_r = j) else '0';

    u_0x0010_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"10", x"00000000") port map(RST, CLK, active_nbiot(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_eaxc_id_w(4)(j) );
    u_0x0011_WO : MPI_REG_WO generic map(j, MAP_NB_IOT, 32, x"11", x"00000000") port map(RST, CLK, active_nbiot(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_comp_mode_w(4)(j) );
    u_0x0012_WO : MPI_REG_WO generic map(j, MAP_NB_IOT, 32, x"12", x"0000001C") port map(RST, CLK, active_nbiot(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_frame_structure_w(4)(j) );
    u_0x0013_WO : MPI_REG_WO generic map(j, MAP_NB_IOT, 32, x"13", x"00000111") port map(RST, CLK, active_nbiot(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_prb_per_symbol_w(4)(j) );
    u_0x0014_WO : MPI_REG_WO generic map(j, MAP_NB_IOT, 32, x"14", x"00000064") port map(RST, CLK, active_nbiot(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_prb_per_mtu_w(4)(j) );
    u_0x0015_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"15", x"00000000") port map(RST, CLK, active_nbiot(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_pe_index_w(4)(j) );

    u_0x0030_WO : MPI_REG_WO generic map(j, MAP_NB_IOT, 32, x"30", x"00000000") port map(RST, CLK, active_nbiot(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_comp_exp_offset_w(4)(j) );
    u_0x0031_WO : MPI_REG_WO generic map(j, MAP_NB_IOT, 32, x"31", x"00000001") port map(RST, CLK, active_nbiot(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_comp_gain_offset_w(4)(j) );
    u_0x0032_WO : MPI_REG_WO generic map(j, MAP_NB_IOT, 32, x"32", x"00000000") port map(RST, CLK, active_nbiot(j), we(1), addr_lsb, WDATA_CPUIF_IN, ul_comp_scale_gain_offset_w(4)(j) );
    end generate;

--------------------------------------------------------------------------------
-- Write register (for processing element list)
--------------------------------------------------------------------------------

    u_0x0200_WO : MPI_REG_WO generic map(0, MAP_ALL,    32, x"00", x"00000000") port map(RST, CLK, '1', we(2), addr_lsb, WDATA_CPUIF_IN, l0_mac_47_to_32_w );
    u_0x0201_WO : MPI_REG_WO generic map(0, MAP_ALL,    32, x"01", x"00000000") port map(RST, CLK, '1', we(2), addr_lsb, WDATA_CPUIF_IN, l0_mac_31_to_0_w );
    u_0x0202_WO : MPI_REG_WO generic map(0, MAP_ALL,    32, x"02", x"00000000") port map(RST, CLK, '1', we(2), addr_lsb, WDATA_CPUIF_IN, l1_mac_47_to_32_w );
    u_0x0203_WO : MPI_REG_WO generic map(0, MAP_ALL,    32, x"03", x"00000000") port map(RST, CLK, '1', we(2), addr_lsb, WDATA_CPUIF_IN, l1_mac_31_to_0_w );
    u_0x0204_WO : MPI_REG_WO generic map(0, MAP_ALL,    32, x"04", x"00000000") port map(RST, CLK, '1', we(2), addr_lsb, WDATA_CPUIF_IN, l2_mac_47_to_32_w );
    u_0x0205_WO : MPI_REG_WO generic map(0, MAP_ALL,    32, x"05", x"00000000") port map(RST, CLK, '1', we(2), addr_lsb, WDATA_CPUIF_IN, l2_mac_31_to_0_w );
    u_0x0206_WO : MPI_REG_WO generic map(0, MAP_ALL,    32, x"06", x"00000000") port map(RST, CLK, '1', we(2), addr_lsb, WDATA_CPUIF_IN, l3_mac_47_to_32_w );
    u_0x0207_WO : MPI_REG_WO generic map(0, MAP_ALL,    32, x"07", x"00000000") port map(RST, CLK, '1', we(2), addr_lsb, WDATA_CPUIF_IN, l3_mac_31_to_0_w );

    u_WR_MAC : for j in MAX_PE-1 downto 0 generate
    active_set_pe(j) <= '1' when (set_pe_index_r = j) else '0';
    active_sts_pe(j) <= '1' when (sts_pe_index_r = j) else '0';

    u_0x0250_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"50", x"00000000") port map(RST, CLK, active_set_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, ru_mac_31_to_0_w(j) );
    u_0x0251_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"51", x"00000000") port map(RST, CLK, active_set_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, ru_mac_47_to_32_w(j) );
    u_0x0252_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"52", x"00000000") port map(RST, CLK, active_set_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, du_mac_31_to_0_w(j) );
    u_0x0253_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"53", x"00000000") port map(RST, CLK, active_set_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, du_mac_47_to_32_w(j) );
    u_0x0254_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"54", x"00000000") port map(RST, CLK, active_set_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, vlan0_vid_w(j) );
--    u_0x0255_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"55", x"00000000") port map(RST, CLK, active_set_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, vlan1_vid_w(j) );

    u_0x0270_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"70", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, capture_period_w(j) );

    u_0x0280_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"80", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_max0_dl_cp_rx_w(j) );
    u_0x0281_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"81", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_min0_dl_cp_rx_w(j) );
    u_0x0282_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"82", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_max1_dl_cp_rx_w(j) );
    u_0x0283_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"83", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_min1_dl_cp_rx_w(j) );
    u_0x0284_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"84", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_max2_dl_cp_rx_w(j) );
    u_0x0285_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"85", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_min2_dl_cp_rx_w(j) );
    u_0x0286_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"86", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_max3_dl_cp_rx_w(j) );
    u_0x0287_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"87", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_min3_dl_cp_rx_w(j) );
    u_0x0288_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"88", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_max4_dl_cp_rx_w(j) );
    u_0x0289_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"89", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_min4_dl_cp_rx_w(j) );

    u_0x0290_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"90", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_max0_dl_up_rx_w(j) );
    u_0x0291_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"91", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_min0_dl_up_rx_w(j) );
    u_0x0292_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"92", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_max1_dl_up_rx_w(j) );
    u_0x0293_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"93", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_min1_dl_up_rx_w(j) );
    u_0x0294_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"94", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_max2_dl_up_rx_w(j) );
    u_0x0295_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"95", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_min2_dl_up_rx_w(j) );
    u_0x0296_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"96", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_max3_dl_up_rx_w(j) );
    u_0x0297_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"97", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_min3_dl_up_rx_w(j) );
    u_0x0298_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"98", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_max4_dl_up_rx_w(j) );
    u_0x0299_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"99", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_min4_dl_up_rx_w(j) );

    u_0x02A0_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"A0", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_max0_ul_cp_rx_w(j) );
    u_0x02A1_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"A1", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_min0_ul_cp_rx_w(j) );
    u_0x02A2_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"A2", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_max1_ul_cp_rx_w(j) );
    u_0x02A3_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"A3", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_min1_ul_cp_rx_w(j) );
    u_0x02A4_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"A4", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_max2_ul_cp_rx_w(j) );
    u_0x02A5_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"A5", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_min2_ul_cp_rx_w(j) );
    u_0x02A6_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"A6", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_max3_ul_cp_rx_w(j) );
    u_0x02A7_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"A7", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_min3_ul_cp_rx_w(j) );
    u_0x02A8_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"A8", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_max4_ul_cp_rx_w(j) );
    u_0x02A9_WO : MPI_REG_WO generic map(j, MAP_ALL,    32, x"A9", x"00000000") port map(RST, CLK, active_sts_pe(j), we(2), addr_lsb, WDATA_CPUIF_IN, t2a_min4_ul_cp_rx_w(j) );
    end generate;

--------------------------------------------------------------------------------
-- CDC register
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Flag/status register
--------------------------------------------------------------------------------

    u_0x00E0_RC : MPI_REG_RC generic map(32, x"E0") port map(RST, CLK, oe(0),  addr_lsb, det_dl_cp0_fault_id_31_r(0)(31 downto 0),  open, det_dl_cp0_fault_id_31_f(0)(31 downto 0) );
    u_0x00E2_RC : MPI_REG_RC generic map(32, x"E2") port map(RST, CLK, oe(0),  addr_lsb, det_dl_cp1_fault_id_31_r(0)(31 downto 0),  open, det_dl_cp1_fault_id_31_f(0)(31 downto 0) );
    u_0x00E4_RC : MPI_REG_RC generic map(32, x"E4") port map(RST, CLK, oe(0),  addr_lsb, det_dl_cp2_fault_id_31_r(0)(31 downto 0),  open, det_dl_cp2_fault_id_31_f(0)(31 downto 0) );
--    u_0x00E6_RC : MPI_REG_RC generic map(32, x"E6") port map(RST, CLK, oe(0),  addr_lsb, det_dl_cp3_fault_id_31_r(0)(31 downto 0),  open, det_dl_cp3_fault_id_31_f(0)(31 downto 0) );
--    u_0x00E8_RC : MPI_REG_RC generic map(32, x"E8") port map(RST, CLK, oe(0),  addr_lsb, det_dl_cp4_fault_id_31_r(0)(31 downto 0),  open, det_dl_cp4_fault_id_31_f(0)(31 downto 0) );
--    u_0x00EA_RC : MPI_REG_RC generic map(32, x"EA") port map(RST, CLK, oe(0),  addr_lsb, det_dl_cp5_fault_id_31_r(0)(31 downto 0),  open, det_dl_cp5_fault_id_31_f(0)(31 downto 0) );
--    u_0x00EC_RC : MPI_REG_RC generic map(32, x"EC") port map(RST, CLK, oe(0),  addr_lsb, det_dl_cp6_fault_id_31_r(0)(31 downto 0),  open, det_dl_cp6_fault_id_31_f(0)(31 downto 0) );
--    u_0x00EE_RC : MPI_REG_RC generic map(32, x"EE") port map(RST, CLK, oe(0),  addr_lsb, det_dl_cp7_fault_id_31_r(0)(31 downto 0),  open, det_dl_cp7_fault_id_31_f(0)(31 downto 0) );

--    u_0x00F0_RC : MPI_REG_RC generic map(32, x"F0") port map(RST, CLK, oe(0),  addr_lsb, det_dl_up_fault_id_31_r(0)(31 downto 0),  open, det_dl_up_fault_id_31_f(0)(31 downto 0) );
--    u_0x00F2_RC : MPI_REG_RC generic map(32, x"F2") port map(RST, CLK, oe(0),  addr_lsb, det_dl_up_fault_id_31_r(1)(31 downto 0),  open, det_dl_up_fault_id_31_f(1)(31 downto 0) );
--    u_0x00F4_RC : MPI_REG_RC generic map(32, x"F4") port map(RST, CLK, oe(0),  addr_lsb, det_dl_up_fault_id_31_r(2)(31 downto 0),  open, det_dl_up_fault_id_31_f(2)(31 downto 0) );
--    u_0x00F6_RC : MPI_REG_RC generic map(32, x"F6") port map(RST, CLK, oe(0),  addr_lsb, det_dl_up_fault_id_31_r(3)(31 downto 0),  open, det_dl_up_fault_id_31_f(3)(31 downto 0) );
--    u_0x00F8_RC : MPI_REG_RC generic map(32, x"F8") port map(RST, CLK, oe(0),  addr_lsb, det_dl_up_fault_id_31_r(4)(31 downto 0),  open, det_dl_up_fault_id_31_f(4)(31 downto 0) );
--    u_0x00FA_RC : MPI_REG_RC generic map(32, x"FA") port map(RST, CLK, oe(0),  addr_lsb, det_dl_up_fault_id_31_r(5)(31 downto 0),  open, det_dl_up_fault_id_31_f(5)(31 downto 0) );
--    u_0x00FC_RC : MPI_REG_RC generic map(32, x"FC") port map(RST, CLK, oe(0),  addr_lsb, det_dl_up_fault_id_31_r(6)(31 downto 0),  open, det_dl_up_fault_id_31_f(6)(31 downto 0) );
--    u_0x00FE_RC : MPI_REG_RC generic map(32, x"FE") port map(RST, CLK, oe(0),  addr_lsb, det_dl_up_fault_id_31_r(7)(31 downto 0),  open, det_dl_up_fault_id_31_f(7)(31 downto 0) );

    u_0x01E0_RC : MPI_REG_RC generic map(32, x"E0") port map(RST, CLK, oe(1),  addr_lsb, det_ul_cp0_fault_id_31_r(0)(31 downto 0),  open, det_ul_cp0_fault_id_31_f(0)(31 downto 0) );
    u_0x01E2_RC : MPI_REG_RC generic map(32, x"E2") port map(RST, CLK, oe(1),  addr_lsb, det_ul_cp1_fault_id_31_r(0)(31 downto 0),  open, det_ul_cp1_fault_id_31_f(0)(31 downto 0) );
    u_0x01E4_RC : MPI_REG_RC generic map(32, x"E4") port map(RST, CLK, oe(1),  addr_lsb, det_ul_cp2_fault_id_31_r(0)(31 downto 0),  open, det_ul_cp2_fault_id_31_f(0)(31 downto 0) );
    u_0x01E6_RC : MPI_REG_RC generic map(32, x"E6") port map(RST, CLK, oe(1),  addr_lsb, det_ul_cp3_fault_id_31_r(0)(31 downto 0),  open, det_ul_cp3_fault_id_31_f(0)(31 downto 0) );
    u_0x01E8_RC : MPI_REG_RC generic map(32, x"E8") port map(RST, CLK, oe(1),  addr_lsb, det_ul_cp4_fault_id_31_r(0)(31 downto 0),  open, det_ul_cp4_fault_id_31_f(0)(31 downto 0) );
--    u_0x01EA_RC : MPI_REG_RC generic map(32, x"EA") port map(RST, CLK, oe(1),  addr_lsb, det_ul_cp5_fault_id_31_r(0)(31 downto 0),  open, det_ul_cp5_fault_id_31_f(0)(31 downto 0) );
--    u_0x01EC_RC : MPI_REG_RC generic map(32, x"EC") port map(RST, CLK, oe(1),  addr_lsb, det_ul_cp6_fault_id_31_r(0)(31 downto 0),  open, det_ul_cp6_fault_id_31_f(0)(31 downto 0) );
--    u_0x01EE_RC : MPI_REG_RC generic map(32, x"EE") port map(RST, CLK, oe(1),  addr_lsb, det_ul_cp7_fault_id_31_r(0)(31 downto 0),  open, det_ul_cp7_fault_id_31_f(0)(31 downto 0) );

    u_0x0840_RC : MPI_REG_RC generic map(32, x"40") port map(RST, CLK, oe(8),  addr_lsb, usage_rx_cp_buffer_r(0),  open, usage_rx_cp_buffer_f(0) );
    u_0x0848_RC : MPI_REG_RC generic map(32, x"48") port map(RST, CLK, oe(8),  addr_lsb, usage_rx_cp_buffer_r(1),  open, usage_rx_cp_buffer_f(1) );
    u_0x0850_RC : MPI_REG_RC generic map(32, x"50") port map(RST, CLK, oe(8),  addr_lsb, usage_rx_cp_buffer_r(2),  open, usage_rx_cp_buffer_f(2) );
    u_0x0858_RC : MPI_REG_RC generic map(32, x"58") port map(RST, CLK, oe(8),  addr_lsb, usage_rx_cp_buffer_r(3),  open, usage_rx_cp_buffer_f(3) );
    u_0x0860_RC : MPI_REG_RC generic map(32, x"60") port map(RST, CLK, oe(8),  addr_lsb, usage_rx_cp_buffer_r(4),  open, usage_rx_cp_buffer_f(4) );
    u_0x0868_RC : MPI_REG_RC generic map(32, x"68") port map(RST, CLK, oe(8),  addr_lsb, usage_rx_cp_buffer_r(5),  open, usage_rx_cp_buffer_f(5) );
    u_0x0870_RC : MPI_REG_RC generic map(32, x"70") port map(RST, CLK, oe(8),  addr_lsb, usage_rx_cp_buffer_r(6),  open, usage_rx_cp_buffer_f(6) );
    u_0x0878_RC : MPI_REG_RC generic map(32, x"78") port map(RST, CLK, oe(8),  addr_lsb, usage_rx_cp_buffer_r(7),  open, usage_rx_cp_buffer_f(7) );

    u_0x0844_RC : MPI_REG_RC generic map(32, x"44") port map(RST, CLK, oe(8),  addr_lsb, usage_rx_up_buffer_r(0),  open, usage_rx_up_buffer_f(0) );
    u_0x084F_RC : MPI_REG_RC generic map(32, x"4F") port map(RST, CLK, oe(8),  addr_lsb, usage_rx_up_buffer_r(1),  open, usage_rx_up_buffer_f(1) );
    u_0x0854_RC : MPI_REG_RC generic map(32, x"54") port map(RST, CLK, oe(8),  addr_lsb, usage_rx_up_buffer_r(2),  open, usage_rx_up_buffer_f(2) );
    u_0x085F_RC : MPI_REG_RC generic map(32, x"5F") port map(RST, CLK, oe(8),  addr_lsb, usage_rx_up_buffer_r(3),  open, usage_rx_up_buffer_f(3) );
    u_0x0864_RC : MPI_REG_RC generic map(32, x"64") port map(RST, CLK, oe(8),  addr_lsb, usage_rx_up_buffer_r(4),  open, usage_rx_up_buffer_f(4) );
    u_0x086F_RC : MPI_REG_RC generic map(32, x"6F") port map(RST, CLK, oe(8),  addr_lsb, usage_rx_up_buffer_r(5),  open, usage_rx_up_buffer_f(5) );
    u_0x0874_RC : MPI_REG_RC generic map(32, x"74") port map(RST, CLK, oe(8),  addr_lsb, usage_rx_up_buffer_r(6),  open, usage_rx_up_buffer_f(6) );
    u_0x087F_RC : MPI_REG_RC generic map(32, x"7F") port map(RST, CLK, oe(8),  addr_lsb, usage_rx_up_buffer_r(7),  open, usage_rx_up_buffer_f(7) );

    u_0x0880_RC : MPI_REG_RC generic map(32, x"80") port map(RST, CLK, oe(8),  addr_lsb, rx_dl_cp_position_r(0)(31 downto 0),  open, rx_dl_cp_position_f(0)(31 downto 0) );
    u_0x0882_RC : MPI_REG_RC generic map(32, x"82") port map(RST, CLK, oe(8),  addr_lsb, rx_dl_cp_position_r(1)(31 downto 0),  open, rx_dl_cp_position_f(1)(31 downto 0) );
    u_0x0884_RC : MPI_REG_RC generic map(32, x"84") port map(RST, CLK, oe(8),  addr_lsb, rx_dl_cp_position_r(2)(31 downto 0),  open, rx_dl_cp_position_f(2)(31 downto 0) );
    u_0x0886_RC : MPI_REG_RC generic map(32, x"86") port map(RST, CLK, oe(8),  addr_lsb, rx_dl_cp_position_r(3)(31 downto 0),  open, rx_dl_cp_position_f(3)(31 downto 0) );
    u_0x0888_RC : MPI_REG_RC generic map(32, x"88") port map(RST, CLK, oe(8),  addr_lsb, rx_dl_cp_position_r(4)(31 downto 0),  open, rx_dl_cp_position_f(4)(31 downto 0) );
    u_0x088A_RC : MPI_REG_RC generic map(32, x"8A") port map(RST, CLK, oe(8),  addr_lsb, rx_dl_cp_position_r(5)(31 downto 0),  open, rx_dl_cp_position_f(5)(31 downto 0) );
    u_0x088C_RC : MPI_REG_RC generic map(32, x"8C") port map(RST, CLK, oe(8),  addr_lsb, rx_dl_cp_position_r(6)(31 downto 0),  open, rx_dl_cp_position_f(6)(31 downto 0) );
    u_0x088E_RC : MPI_REG_RC generic map(32, x"8E") port map(RST, CLK, oe(8),  addr_lsb, rx_dl_cp_position_r(7)(31 downto 0),  open, rx_dl_cp_position_f(7)(31 downto 0) );

    u_0x0890_RC : MPI_REG_RC generic map(32, x"90") port map(RST, CLK, oe(8),  addr_lsb, rx_dl_up_position_r(0)(31 downto 0),  open, rx_dl_up_position_f(0)(31 downto 0) );
    u_0x0892_RC : MPI_REG_RC generic map(32, x"92") port map(RST, CLK, oe(8),  addr_lsb, rx_dl_up_position_r(1)(31 downto 0),  open, rx_dl_up_position_f(1)(31 downto 0) );
    u_0x0894_RC : MPI_REG_RC generic map(32, x"94") port map(RST, CLK, oe(8),  addr_lsb, rx_dl_up_position_r(2)(31 downto 0),  open, rx_dl_up_position_f(2)(31 downto 0) );
    u_0x0896_RC : MPI_REG_RC generic map(32, x"96") port map(RST, CLK, oe(8),  addr_lsb, rx_dl_up_position_r(3)(31 downto 0),  open, rx_dl_up_position_f(3)(31 downto 0) );
    u_0x0898_RC : MPI_REG_RC generic map(32, x"98") port map(RST, CLK, oe(8),  addr_lsb, rx_dl_up_position_r(4)(31 downto 0),  open, rx_dl_up_position_f(4)(31 downto 0) );
    u_0x089A_RC : MPI_REG_RC generic map(32, x"9A") port map(RST, CLK, oe(8),  addr_lsb, rx_dl_up_position_r(5)(31 downto 0),  open, rx_dl_up_position_f(5)(31 downto 0) );
    u_0x089C_RC : MPI_REG_RC generic map(32, x"9C") port map(RST, CLK, oe(8),  addr_lsb, rx_dl_up_position_r(6)(31 downto 0),  open, rx_dl_up_position_f(6)(31 downto 0) );
    u_0x089E_RC : MPI_REG_RC generic map(32, x"9E") port map(RST, CLK, oe(8),  addr_lsb, rx_dl_up_position_r(7)(31 downto 0),  open, rx_dl_up_position_f(7)(31 downto 0) );

    u_0x08A0_RC : MPI_REG_RC generic map(32, x"A0") port map(RST, CLK, oe(8),  addr_lsb, rx_ul_cp_position_r(0)(31 downto 0),  open, rx_ul_cp_position_f(0)(31 downto 0) );
    u_0x08A2_RC : MPI_REG_RC generic map(32, x"A2") port map(RST, CLK, oe(8),  addr_lsb, rx_ul_cp_position_r(1)(31 downto 0),  open, rx_ul_cp_position_f(1)(31 downto 0) );
    u_0x08A4_RC : MPI_REG_RC generic map(32, x"A4") port map(RST, CLK, oe(8),  addr_lsb, rx_ul_cp_position_r(2)(31 downto 0),  open, rx_ul_cp_position_f(2)(31 downto 0) );
    u_0x08A6_RC : MPI_REG_RC generic map(32, x"A6") port map(RST, CLK, oe(8),  addr_lsb, rx_ul_cp_position_r(3)(31 downto 0),  open, rx_ul_cp_position_f(3)(31 downto 0) );
    u_0x08A8_RC : MPI_REG_RC generic map(32, x"A8") port map(RST, CLK, oe(8),  addr_lsb, rx_ul_cp_position_r(4)(31 downto 0),  open, rx_ul_cp_position_f(4)(31 downto 0) );
    u_0x08AA_RC : MPI_REG_RC generic map(32, x"AA") port map(RST, CLK, oe(8),  addr_lsb, rx_ul_cp_position_r(5)(31 downto 0),  open, rx_ul_cp_position_f(5)(31 downto 0) );
    u_0x08AC_RC : MPI_REG_RC generic map(32, x"AC") port map(RST, CLK, oe(8),  addr_lsb, rx_ul_cp_position_r(6)(31 downto 0),  open, rx_ul_cp_position_f(6)(31 downto 0) );
    u_0x08AE_RC : MPI_REG_RC generic map(32, x"AE") port map(RST, CLK, oe(8),  addr_lsb, rx_ul_cp_position_r(7)(31 downto 0),  open, rx_ul_cp_position_f(7)(31 downto 0) );

    u_0x0900_RC : MPI_REG_RC generic map(32, x"00") port map(RST, CLK, oe(9),  addr_lsb, usage_tx0_up_buffer_r(0),  open, usage_tx0_up_buffer_f(0) );
    u_0x0920_RC : MPI_REG_RC generic map(32, x"20") port map(RST, CLK, oe(9),  addr_lsb, usage_tx0_up_buffer_r(1),  open, usage_tx0_up_buffer_f(1) );
    u_0x0940_RC : MPI_REG_RC generic map(32, x"40") port map(RST, CLK, oe(9),  addr_lsb, usage_tx0_up_buffer_r(2),  open, usage_tx0_up_buffer_f(2) );
    u_0x0960_RC : MPI_REG_RC generic map(32, x"60") port map(RST, CLK, oe(9),  addr_lsb, usage_tx0_up_buffer_r(3),  open, usage_tx0_up_buffer_f(3) );
    u_0x0980_RC : MPI_REG_RC generic map(32, x"80") port map(RST, CLK, oe(9),  addr_lsb, usage_tx0_up_buffer_r(4),  open, usage_tx0_up_buffer_f(4) );
    u_0x09A0_RC : MPI_REG_RC generic map(32, x"A0") port map(RST, CLK, oe(9),  addr_lsb, usage_tx0_up_buffer_r(5),  open, usage_tx0_up_buffer_f(5) );
    u_0x09C0_RC : MPI_REG_RC generic map(32, x"C0") port map(RST, CLK, oe(9),  addr_lsb, usage_tx0_up_buffer_r(6),  open, usage_tx0_up_buffer_f(6) );
    u_0x09E0_RC : MPI_REG_RC generic map(32, x"E0") port map(RST, CLK, oe(9),  addr_lsb, usage_tx0_up_buffer_r(7),  open, usage_tx0_up_buffer_f(7) );

    u_0x0904_RC : MPI_REG_RC generic map(32, x"04") port map(RST, CLK, oe(9),  addr_lsb, usage_tx1_up_buffer_r(0),  open, usage_tx1_up_buffer_f(0) );
    u_0x0924_RC : MPI_REG_RC generic map(32, x"24") port map(RST, CLK, oe(9),  addr_lsb, usage_tx1_up_buffer_r(1),  open, usage_tx1_up_buffer_f(1) );
    u_0x0944_RC : MPI_REG_RC generic map(32, x"44") port map(RST, CLK, oe(9),  addr_lsb, usage_tx1_up_buffer_r(2),  open, usage_tx1_up_buffer_f(2) );
    u_0x0964_RC : MPI_REG_RC generic map(32, x"64") port map(RST, CLK, oe(9),  addr_lsb, usage_tx1_up_buffer_r(3),  open, usage_tx1_up_buffer_f(3) );
    u_0x0984_RC : MPI_REG_RC generic map(32, x"84") port map(RST, CLK, oe(9),  addr_lsb, usage_tx1_up_buffer_r(4),  open, usage_tx1_up_buffer_f(4) );
    u_0x09A4_RC : MPI_REG_RC generic map(32, x"A4") port map(RST, CLK, oe(9),  addr_lsb, usage_tx1_up_buffer_r(5),  open, usage_tx1_up_buffer_f(5) );
    u_0x09C4_RC : MPI_REG_RC generic map(32, x"C4") port map(RST, CLK, oe(9),  addr_lsb, usage_tx1_up_buffer_r(6),  open, usage_tx1_up_buffer_f(6) );
    u_0x09E4_RC : MPI_REG_RC generic map(32, x"E4") port map(RST, CLK, oe(9),  addr_lsb, usage_tx1_up_buffer_r(7),  open, usage_tx1_up_buffer_f(7) );

    u_0x0908_RC : MPI_REG_RC generic map(32, x"08") port map(RST, CLK, oe(9),  addr_lsb, usage_tx2_up_buffer_r(0),  open, usage_tx2_up_buffer_f(0) );
    u_0x0928_RC : MPI_REG_RC generic map(32, x"28") port map(RST, CLK, oe(9),  addr_lsb, usage_tx2_up_buffer_r(1),  open, usage_tx2_up_buffer_f(1) );
    u_0x0948_RC : MPI_REG_RC generic map(32, x"48") port map(RST, CLK, oe(9),  addr_lsb, usage_tx2_up_buffer_r(2),  open, usage_tx2_up_buffer_f(2) );
    u_0x0968_RC : MPI_REG_RC generic map(32, x"68") port map(RST, CLK, oe(9),  addr_lsb, usage_tx2_up_buffer_r(3),  open, usage_tx2_up_buffer_f(3) );
    u_0x0988_RC : MPI_REG_RC generic map(32, x"88") port map(RST, CLK, oe(9),  addr_lsb, usage_tx2_up_buffer_r(4),  open, usage_tx2_up_buffer_f(4) );
    u_0x09A8_RC : MPI_REG_RC generic map(32, x"A8") port map(RST, CLK, oe(9),  addr_lsb, usage_tx2_up_buffer_r(5),  open, usage_tx2_up_buffer_f(5) );
    u_0x09C8_RC : MPI_REG_RC generic map(32, x"C8") port map(RST, CLK, oe(9),  addr_lsb, usage_tx2_up_buffer_r(6),  open, usage_tx2_up_buffer_f(6) );
    u_0x09E8_RC : MPI_REG_RC generic map(32, x"E8") port map(RST, CLK, oe(9),  addr_lsb, usage_tx2_up_buffer_r(7),  open, usage_tx2_up_buffer_f(7) );

    u_0x090C_RC : MPI_REG_RC generic map(32, x"0C") port map(RST, CLK, oe(9),  addr_lsb, usage_tx3_up_buffer_r(0),  open, usage_tx3_up_buffer_f(0) );
    u_0x092C_RC : MPI_REG_RC generic map(32, x"2C") port map(RST, CLK, oe(9),  addr_lsb, usage_tx3_up_buffer_r(1),  open, usage_tx3_up_buffer_f(1) );
    u_0x094C_RC : MPI_REG_RC generic map(32, x"4C") port map(RST, CLK, oe(9),  addr_lsb, usage_tx3_up_buffer_r(2),  open, usage_tx3_up_buffer_f(2) );
    u_0x096C_RC : MPI_REG_RC generic map(32, x"6C") port map(RST, CLK, oe(9),  addr_lsb, usage_tx3_up_buffer_r(3),  open, usage_tx3_up_buffer_f(3) );
    u_0x098C_RC : MPI_REG_RC generic map(32, x"8C") port map(RST, CLK, oe(9),  addr_lsb, usage_tx3_up_buffer_r(4),  open, usage_tx3_up_buffer_f(4) );
    u_0x09AC_RC : MPI_REG_RC generic map(32, x"AC") port map(RST, CLK, oe(9),  addr_lsb, usage_tx3_up_buffer_r(5),  open, usage_tx3_up_buffer_f(5) );
    u_0x09CC_RC : MPI_REG_RC generic map(32, x"CC") port map(RST, CLK, oe(9),  addr_lsb, usage_tx3_up_buffer_r(6),  open, usage_tx3_up_buffer_f(6) );
    u_0x09EC_RC : MPI_REG_RC generic map(32, x"EC") port map(RST, CLK, oe(9),  addr_lsb, usage_tx3_up_buffer_r(7),  open, usage_tx3_up_buffer_f(7) );

    u_0x0910_RC : MPI_REG_RC generic map(32, x"10") port map(RST, CLK, oe(9),  addr_lsb, usage_tx4_up_buffer_r(0),  open, usage_tx4_up_buffer_f(0) );
    u_0x0930_RC : MPI_REG_RC generic map(32, x"30") port map(RST, CLK, oe(9),  addr_lsb, usage_tx4_up_buffer_r(1),  open, usage_tx4_up_buffer_f(1) );
    u_0x0950_RC : MPI_REG_RC generic map(32, x"50") port map(RST, CLK, oe(9),  addr_lsb, usage_tx4_up_buffer_r(2),  open, usage_tx4_up_buffer_f(2) );
    u_0x0970_RC : MPI_REG_RC generic map(32, x"70") port map(RST, CLK, oe(9),  addr_lsb, usage_tx4_up_buffer_r(3),  open, usage_tx4_up_buffer_f(3) );
    u_0x0990_RC : MPI_REG_RC generic map(32, x"90") port map(RST, CLK, oe(9),  addr_lsb, usage_tx4_up_buffer_r(4),  open, usage_tx4_up_buffer_f(4) );
    u_0x09B0_RC : MPI_REG_RC generic map(32, x"B0") port map(RST, CLK, oe(9),  addr_lsb, usage_tx4_up_buffer_r(5),  open, usage_tx4_up_buffer_f(5) );
    u_0x09D0_RC : MPI_REG_RC generic map(32, x"D0") port map(RST, CLK, oe(9),  addr_lsb, usage_tx4_up_buffer_r(6),  open, usage_tx4_up_buffer_f(6) );
    u_0x09F0_RC : MPI_REG_RC generic map(32, x"F0") port map(RST, CLK, oe(9),  addr_lsb, usage_tx4_up_buffer_r(7),  open, usage_tx4_up_buffer_f(7) );

--    u_0x0914_RC : MPI_REG_RC generic map(32, x"14") port map(RST, CLK, oe(9),  addr_lsb, usage_tx5_up_buffer_r(0),  open, usage_tx5_up_buffer_f(0) );
--    u_0x0934_RC : MPI_REG_RC generic map(32, x"34") port map(RST, CLK, oe(9),  addr_lsb, usage_tx5_up_buffer_r(1),  open, usage_tx5_up_buffer_f(1) );
--    u_0x0954_RC : MPI_REG_RC generic map(32, x"54") port map(RST, CLK, oe(9),  addr_lsb, usage_tx5_up_buffer_r(2),  open, usage_tx5_up_buffer_f(2) );
--    u_0x0974_RC : MPI_REG_RC generic map(32, x"74") port map(RST, CLK, oe(9),  addr_lsb, usage_tx5_up_buffer_r(3),  open, usage_tx5_up_buffer_f(3) );
--    u_0x0994_RC : MPI_REG_RC generic map(32, x"94") port map(RST, CLK, oe(9),  addr_lsb, usage_tx5_up_buffer_r(4),  open, usage_tx5_up_buffer_f(4) );
--    u_0x09B4_RC : MPI_REG_RC generic map(32, x"B4") port map(RST, CLK, oe(9),  addr_lsb, usage_tx5_up_buffer_r(5),  open, usage_tx5_up_buffer_f(5) );
--    u_0x09D4_RC : MPI_REG_RC generic map(32, x"D4") port map(RST, CLK, oe(9),  addr_lsb, usage_tx5_up_buffer_r(6),  open, usage_tx5_up_buffer_f(6) );
--    u_0x09F4_RC : MPI_REG_RC generic map(32, x"F4") port map(RST, CLK, oe(9),  addr_lsb, usage_tx5_up_buffer_r(7),  open, usage_tx5_up_buffer_f(7) );

    u_DEBUG_CC_LATCH : for i in MAX_CC_UL-1 downto 0 generate
    u_0x1030_RC : MPI_REG_RC generic map(32, x"30") port map(RST, CLK, oe(i*2+16), addr_lsb, tx0_usage_cq_sym0_r(i),  open, tx0_usage_cq_sym0_f(i) );
    u_0x1031_RC : MPI_REG_RC generic map(32, x"31") port map(RST, CLK, oe(i*2+16), addr_lsb, tx0_usage_cq_sym1_r(i),  open, tx0_usage_cq_sym1_f(i) );
    u_0x1032_RC : MPI_REG_RC generic map(32, x"32") port map(RST, CLK, oe(i*2+16), addr_lsb, tx0_usage_cq_sym2_r(i),  open, tx0_usage_cq_sym2_f(i) );
    u_0x1033_RC : MPI_REG_RC generic map(32, x"33") port map(RST, CLK, oe(i*2+16), addr_lsb, tx0_usage_cq_sym3_r(i),  open, tx0_usage_cq_sym3_f(i) );
    u_0x1034_RC : MPI_REG_RC generic map(32, x"34") port map(RST, CLK, oe(i*2+16), addr_lsb, tx0_usage_cq_sym4_r(i),  open, tx0_usage_cq_sym4_f(i) );
    u_0x1035_RC : MPI_REG_RC generic map(32, x"35") port map(RST, CLK, oe(i*2+16), addr_lsb, tx0_usage_cq_sym5_r(i),  open, tx0_usage_cq_sym5_f(i) );
    u_0x1036_RC : MPI_REG_RC generic map(32, x"36") port map(RST, CLK, oe(i*2+16), addr_lsb, tx0_usage_cq_sym6_r(i),  open, tx0_usage_cq_sym6_f(i) );
    u_0x1037_RC : MPI_REG_RC generic map(32, x"37") port map(RST, CLK, oe(i*2+16), addr_lsb, tx0_usage_cq_sym7_r(i),  open, tx0_usage_cq_sym7_f(i) );
    u_0x1038_RC : MPI_REG_RC generic map(32, x"38") port map(RST, CLK, oe(i*2+16), addr_lsb, tx0_usage_cq_sym8_r(i),  open, tx0_usage_cq_sym8_f(i) );
    u_0x1039_RC : MPI_REG_RC generic map(32, x"39") port map(RST, CLK, oe(i*2+16), addr_lsb, tx0_usage_cq_sym9_r(i),  open, tx0_usage_cq_sym9_f(i) );
    u_0x103A_RC : MPI_REG_RC generic map(32, x"3A") port map(RST, CLK, oe(i*2+16), addr_lsb, tx0_usage_cq_sym10_r(i), open, tx0_usage_cq_sym10_f(i) );
    u_0x103B_RC : MPI_REG_RC generic map(32, x"3B") port map(RST, CLK, oe(i*2+16), addr_lsb, tx0_usage_cq_sym11_r(i), open, tx0_usage_cq_sym11_f(i) );
    u_0x103C_RC : MPI_REG_RC generic map(32, x"3C") port map(RST, CLK, oe(i*2+16), addr_lsb, tx0_usage_cq_sym12_r(i), open, tx0_usage_cq_sym12_f(i) );
    u_0x103D_RC : MPI_REG_RC generic map(32, x"3D") port map(RST, CLK, oe(i*2+16), addr_lsb, tx0_usage_cq_sym13_r(i), open, tx0_usage_cq_sym13_f(i) );
    u_0x103F_RC : MPI_REG_RC generic map(32, x"3F") port map(RST, CLK, oe(i*2+16), addr_lsb, tx0_sts_cq_fsm_r(i),     open, tx0_sts_cq_fsm_f(i) );

    u_0x1070_RC : MPI_REG_RC generic map(32, x"70") port map(RST, CLK, oe(i*2+16), addr_lsb, tx1_usage_cq_sym0_r(i),  open, tx1_usage_cq_sym0_f(i) );
    u_0x1071_RC : MPI_REG_RC generic map(32, x"71") port map(RST, CLK, oe(i*2+16), addr_lsb, tx1_usage_cq_sym1_r(i),  open, tx1_usage_cq_sym1_f(i) );
    u_0x1072_RC : MPI_REG_RC generic map(32, x"72") port map(RST, CLK, oe(i*2+16), addr_lsb, tx1_usage_cq_sym2_r(i),  open, tx1_usage_cq_sym2_f(i) );
    u_0x1073_RC : MPI_REG_RC generic map(32, x"73") port map(RST, CLK, oe(i*2+16), addr_lsb, tx1_usage_cq_sym3_r(i),  open, tx1_usage_cq_sym3_f(i) );
    u_0x1074_RC : MPI_REG_RC generic map(32, x"74") port map(RST, CLK, oe(i*2+16), addr_lsb, tx1_usage_cq_sym4_r(i),  open, tx1_usage_cq_sym4_f(i) );
    u_0x1075_RC : MPI_REG_RC generic map(32, x"75") port map(RST, CLK, oe(i*2+16), addr_lsb, tx1_usage_cq_sym5_r(i),  open, tx1_usage_cq_sym5_f(i) );
    u_0x1076_RC : MPI_REG_RC generic map(32, x"76") port map(RST, CLK, oe(i*2+16), addr_lsb, tx1_usage_cq_sym6_r(i),  open, tx1_usage_cq_sym6_f(i) );
    u_0x1077_RC : MPI_REG_RC generic map(32, x"77") port map(RST, CLK, oe(i*2+16), addr_lsb, tx1_usage_cq_sym7_r(i),  open, tx1_usage_cq_sym7_f(i) );
    u_0x1078_RC : MPI_REG_RC generic map(32, x"78") port map(RST, CLK, oe(i*2+16), addr_lsb, tx1_usage_cq_sym8_r(i),  open, tx1_usage_cq_sym8_f(i) );
    u_0x1079_RC : MPI_REG_RC generic map(32, x"79") port map(RST, CLK, oe(i*2+16), addr_lsb, tx1_usage_cq_sym9_r(i),  open, tx1_usage_cq_sym9_f(i) );
    u_0x107A_RC : MPI_REG_RC generic map(32, x"7A") port map(RST, CLK, oe(i*2+16), addr_lsb, tx1_usage_cq_sym10_r(i), open, tx1_usage_cq_sym10_f(i) );
    u_0x107B_RC : MPI_REG_RC generic map(32, x"7B") port map(RST, CLK, oe(i*2+16), addr_lsb, tx1_usage_cq_sym11_r(i), open, tx1_usage_cq_sym11_f(i) );
    u_0x107C_RC : MPI_REG_RC generic map(32, x"7C") port map(RST, CLK, oe(i*2+16), addr_lsb, tx1_usage_cq_sym12_r(i), open, tx1_usage_cq_sym12_f(i) );
    u_0x107D_RC : MPI_REG_RC generic map(32, x"7D") port map(RST, CLK, oe(i*2+16), addr_lsb, tx1_usage_cq_sym13_r(i), open, tx1_usage_cq_sym13_f(i) );
    u_0x107F_RC : MPI_REG_RC generic map(32, x"7F") port map(RST, CLK, oe(i*2+16), addr_lsb, tx1_sts_cq_fsm_r(i),     open, tx1_sts_cq_fsm_f(i) );

    u_0x10B0_RC : MPI_REG_RC generic map(32, x"B0") port map(RST, CLK, oe(i*2+16), addr_lsb, tx2_usage_cq_sym0_r(i),  open, tx2_usage_cq_sym0_f(i) );
    u_0x10B1_RC : MPI_REG_RC generic map(32, x"B1") port map(RST, CLK, oe(i*2+16), addr_lsb, tx2_usage_cq_sym1_r(i),  open, tx2_usage_cq_sym1_f(i) );
    u_0x10B2_RC : MPI_REG_RC generic map(32, x"B2") port map(RST, CLK, oe(i*2+16), addr_lsb, tx2_usage_cq_sym2_r(i),  open, tx2_usage_cq_sym2_f(i) );
    u_0x10B3_RC : MPI_REG_RC generic map(32, x"B3") port map(RST, CLK, oe(i*2+16), addr_lsb, tx2_usage_cq_sym3_r(i),  open, tx2_usage_cq_sym3_f(i) );
    u_0x10B4_RC : MPI_REG_RC generic map(32, x"B4") port map(RST, CLK, oe(i*2+16), addr_lsb, tx2_usage_cq_sym4_r(i),  open, tx2_usage_cq_sym4_f(i) );
    u_0x10B5_RC : MPI_REG_RC generic map(32, x"B5") port map(RST, CLK, oe(i*2+16), addr_lsb, tx2_usage_cq_sym5_r(i),  open, tx2_usage_cq_sym5_f(i) );
    u_0x10B6_RC : MPI_REG_RC generic map(32, x"B6") port map(RST, CLK, oe(i*2+16), addr_lsb, tx2_usage_cq_sym6_r(i),  open, tx2_usage_cq_sym6_f(i) );
    u_0x10B7_RC : MPI_REG_RC generic map(32, x"B7") port map(RST, CLK, oe(i*2+16), addr_lsb, tx2_usage_cq_sym7_r(i),  open, tx2_usage_cq_sym7_f(i) );
    u_0x10B8_RC : MPI_REG_RC generic map(32, x"B8") port map(RST, CLK, oe(i*2+16), addr_lsb, tx2_usage_cq_sym8_r(i),  open, tx2_usage_cq_sym8_f(i) );
    u_0x10B9_RC : MPI_REG_RC generic map(32, x"B9") port map(RST, CLK, oe(i*2+16), addr_lsb, tx2_usage_cq_sym9_r(i),  open, tx2_usage_cq_sym9_f(i) );
    u_0x10BA_RC : MPI_REG_RC generic map(32, x"BA") port map(RST, CLK, oe(i*2+16), addr_lsb, tx2_usage_cq_sym10_r(i), open, tx2_usage_cq_sym10_f(i) );
    u_0x10BB_RC : MPI_REG_RC generic map(32, x"BB") port map(RST, CLK, oe(i*2+16), addr_lsb, tx2_usage_cq_sym11_r(i), open, tx2_usage_cq_sym11_f(i) );
    u_0x10BC_RC : MPI_REG_RC generic map(32, x"BC") port map(RST, CLK, oe(i*2+16), addr_lsb, tx2_usage_cq_sym12_r(i), open, tx2_usage_cq_sym12_f(i) );
    u_0x10BD_RC : MPI_REG_RC generic map(32, x"BD") port map(RST, CLK, oe(i*2+16), addr_lsb, tx2_usage_cq_sym13_r(i), open, tx2_usage_cq_sym13_f(i) );
    u_0x10BF_RC : MPI_REG_RC generic map(32, x"BF") port map(RST, CLK, oe(i*2+16), addr_lsb, tx2_sts_cq_fsm_r(i),     open, tx2_sts_cq_fsm_f(i) );

    u_0x10F0_RC : MPI_REG_RC generic map(32, x"F0") port map(RST, CLK, oe(i*2+16), addr_lsb, tx3_usage_cq_sym0_r(i),  open, tx3_usage_cq_sym0_f(i) );
    u_0x10F1_RC : MPI_REG_RC generic map(32, x"F1") port map(RST, CLK, oe(i*2+16), addr_lsb, tx3_usage_cq_sym1_r(i),  open, tx3_usage_cq_sym1_f(i) );
    u_0x10F2_RC : MPI_REG_RC generic map(32, x"F2") port map(RST, CLK, oe(i*2+16), addr_lsb, tx3_usage_cq_sym2_r(i),  open, tx3_usage_cq_sym2_f(i) );
    u_0x10F3_RC : MPI_REG_RC generic map(32, x"F3") port map(RST, CLK, oe(i*2+16), addr_lsb, tx3_usage_cq_sym3_r(i),  open, tx3_usage_cq_sym3_f(i) );
    u_0x10F4_RC : MPI_REG_RC generic map(32, x"F4") port map(RST, CLK, oe(i*2+16), addr_lsb, tx3_usage_cq_sym4_r(i),  open, tx3_usage_cq_sym4_f(i) );
    u_0x10F5_RC : MPI_REG_RC generic map(32, x"F5") port map(RST, CLK, oe(i*2+16), addr_lsb, tx3_usage_cq_sym5_r(i),  open, tx3_usage_cq_sym5_f(i) );
    u_0x10F6_RC : MPI_REG_RC generic map(32, x"F6") port map(RST, CLK, oe(i*2+16), addr_lsb, tx3_usage_cq_sym6_r(i),  open, tx3_usage_cq_sym6_f(i) );
    u_0x10F7_RC : MPI_REG_RC generic map(32, x"F7") port map(RST, CLK, oe(i*2+16), addr_lsb, tx3_usage_cq_sym7_r(i),  open, tx3_usage_cq_sym7_f(i) );
    u_0x10F8_RC : MPI_REG_RC generic map(32, x"F8") port map(RST, CLK, oe(i*2+16), addr_lsb, tx3_usage_cq_sym8_r(i),  open, tx3_usage_cq_sym8_f(i) );
    u_0x10F9_RC : MPI_REG_RC generic map(32, x"F9") port map(RST, CLK, oe(i*2+16), addr_lsb, tx3_usage_cq_sym9_r(i),  open, tx3_usage_cq_sym9_f(i) );
    u_0x10FA_RC : MPI_REG_RC generic map(32, x"FA") port map(RST, CLK, oe(i*2+16), addr_lsb, tx3_usage_cq_sym10_r(i), open, tx3_usage_cq_sym10_f(i) );
    u_0x10FB_RC : MPI_REG_RC generic map(32, x"FB") port map(RST, CLK, oe(i*2+16), addr_lsb, tx3_usage_cq_sym11_r(i), open, tx3_usage_cq_sym11_f(i) );
    u_0x10FC_RC : MPI_REG_RC generic map(32, x"FC") port map(RST, CLK, oe(i*2+16), addr_lsb, tx3_usage_cq_sym12_r(i), open, tx3_usage_cq_sym12_f(i) );
    u_0x10FD_RC : MPI_REG_RC generic map(32, x"FD") port map(RST, CLK, oe(i*2+16), addr_lsb, tx3_usage_cq_sym13_r(i), open, tx3_usage_cq_sym13_f(i) );
    u_0x10FF_RC : MPI_REG_RC generic map(32, x"FF") port map(RST, CLK, oe(i*2+16), addr_lsb, tx3_sts_cq_fsm_r(i),     open, tx3_sts_cq_fsm_f(i) );

    u_0x1130_RC : MPI_REG_RC generic map(32, x"30") port map(RST, CLK, oe(i*2+17), addr_lsb, tx4_usage_cq_sym0_r(i),  open, tx4_usage_cq_sym0_f(i) );
    u_0x1131_RC : MPI_REG_RC generic map(32, x"31") port map(RST, CLK, oe(i*2+17), addr_lsb, tx4_usage_cq_sym1_r(i),  open, tx4_usage_cq_sym1_f(i) );
    u_0x1132_RC : MPI_REG_RC generic map(32, x"32") port map(RST, CLK, oe(i*2+17), addr_lsb, tx4_usage_cq_sym2_r(i),  open, tx4_usage_cq_sym2_f(i) );
    u_0x1133_RC : MPI_REG_RC generic map(32, x"33") port map(RST, CLK, oe(i*2+17), addr_lsb, tx4_usage_cq_sym3_r(i),  open, tx4_usage_cq_sym3_f(i) );
    u_0x1134_RC : MPI_REG_RC generic map(32, x"34") port map(RST, CLK, oe(i*2+17), addr_lsb, tx4_usage_cq_sym4_r(i),  open, tx4_usage_cq_sym4_f(i) );
    u_0x1135_RC : MPI_REG_RC generic map(32, x"35") port map(RST, CLK, oe(i*2+17), addr_lsb, tx4_usage_cq_sym5_r(i),  open, tx4_usage_cq_sym5_f(i) );
    u_0x1136_RC : MPI_REG_RC generic map(32, x"36") port map(RST, CLK, oe(i*2+17), addr_lsb, tx4_usage_cq_sym6_r(i),  open, tx4_usage_cq_sym6_f(i) );
    u_0x1137_RC : MPI_REG_RC generic map(32, x"37") port map(RST, CLK, oe(i*2+17), addr_lsb, tx4_usage_cq_sym7_r(i),  open, tx4_usage_cq_sym7_f(i) );
    u_0x1138_RC : MPI_REG_RC generic map(32, x"38") port map(RST, CLK, oe(i*2+17), addr_lsb, tx4_usage_cq_sym8_r(i),  open, tx4_usage_cq_sym8_f(i) );
    u_0x1139_RC : MPI_REG_RC generic map(32, x"39") port map(RST, CLK, oe(i*2+17), addr_lsb, tx4_usage_cq_sym9_r(i),  open, tx4_usage_cq_sym9_f(i) );
    u_0x113A_RC : MPI_REG_RC generic map(32, x"3A") port map(RST, CLK, oe(i*2+17), addr_lsb, tx4_usage_cq_sym10_r(i), open, tx4_usage_cq_sym10_f(i) );
    u_0x113B_RC : MPI_REG_RC generic map(32, x"3B") port map(RST, CLK, oe(i*2+17), addr_lsb, tx4_usage_cq_sym11_r(i), open, tx4_usage_cq_sym11_f(i) );
    u_0x113C_RC : MPI_REG_RC generic map(32, x"3C") port map(RST, CLK, oe(i*2+17), addr_lsb, tx4_usage_cq_sym12_r(i), open, tx4_usage_cq_sym12_f(i) );
    u_0x113D_RC : MPI_REG_RC generic map(32, x"3D") port map(RST, CLK, oe(i*2+17), addr_lsb, tx4_usage_cq_sym13_r(i), open, tx4_usage_cq_sym13_f(i) );
    u_0x113F_RC : MPI_REG_RC generic map(32, x"3F") port map(RST, CLK, oe(i*2+17), addr_lsb, tx4_sts_cq_fsm_r(i),     open, tx4_sts_cq_fsm_f(i) );

--    u_0x1170_RC : MPI_REG_RC generic map(32, x"70") port map(RST, CLK, oe(i*2+17), addr_lsb, tx5_usage_cq_sym0_r(i),  open, tx5_usage_cq_sym0_f(i) );
--    u_0x1171_RC : MPI_REG_RC generic map(32, x"71") port map(RST, CLK, oe(i*2+17), addr_lsb, tx5_usage_cq_sym1_r(i),  open, tx5_usage_cq_sym1_f(i) );
--    u_0x1172_RC : MPI_REG_RC generic map(32, x"72") port map(RST, CLK, oe(i*2+17), addr_lsb, tx5_usage_cq_sym2_r(i),  open, tx5_usage_cq_sym2_f(i) );
--    u_0x1173_RC : MPI_REG_RC generic map(32, x"73") port map(RST, CLK, oe(i*2+17), addr_lsb, tx5_usage_cq_sym3_r(i),  open, tx5_usage_cq_sym3_f(i) );
--    u_0x1174_RC : MPI_REG_RC generic map(32, x"74") port map(RST, CLK, oe(i*2+17), addr_lsb, tx5_usage_cq_sym4_r(i),  open, tx5_usage_cq_sym4_f(i) );
--    u_0x1175_RC : MPI_REG_RC generic map(32, x"75") port map(RST, CLK, oe(i*2+17), addr_lsb, tx5_usage_cq_sym5_r(i),  open, tx5_usage_cq_sym5_f(i) );
--    u_0x1176_RC : MPI_REG_RC generic map(32, x"76") port map(RST, CLK, oe(i*2+17), addr_lsb, tx5_usage_cq_sym6_r(i),  open, tx5_usage_cq_sym6_f(i) );
--    u_0x1177_RC : MPI_REG_RC generic map(32, x"77") port map(RST, CLK, oe(i*2+17), addr_lsb, tx5_usage_cq_sym7_r(i),  open, tx5_usage_cq_sym7_f(i) );
--    u_0x1178_RC : MPI_REG_RC generic map(32, x"78") port map(RST, CLK, oe(i*2+17), addr_lsb, tx5_usage_cq_sym8_r(i),  open, tx5_usage_cq_sym8_f(i) );
--    u_0x1179_RC : MPI_REG_RC generic map(32, x"79") port map(RST, CLK, oe(i*2+17), addr_lsb, tx5_usage_cq_sym9_r(i),  open, tx5_usage_cq_sym9_f(i) );
--    u_0x117A_RC : MPI_REG_RC generic map(32, x"7A") port map(RST, CLK, oe(i*2+17), addr_lsb, tx5_usage_cq_sym10_r(i), open, tx5_usage_cq_sym10_f(i) );
--    u_0x117B_RC : MPI_REG_RC generic map(32, x"7B") port map(RST, CLK, oe(i*2+17), addr_lsb, tx5_usage_cq_sym11_r(i), open, tx5_usage_cq_sym11_f(i) );
--    u_0x117C_RC : MPI_REG_RC generic map(32, x"7C") port map(RST, CLK, oe(i*2+17), addr_lsb, tx5_usage_cq_sym12_r(i), open, tx5_usage_cq_sym12_f(i) );
--    u_0x117D_RC : MPI_REG_RC generic map(32, x"7D") port map(RST, CLK, oe(i*2+17), addr_lsb, tx5_usage_cq_sym13_r(i), open, tx5_usage_cq_sym13_f(i) );
--    u_0x117F_RC : MPI_REG_RC generic map(32, x"7F") port map(RST, CLK, oe(i*2+17), addr_lsb, tx5_sts_cq_fsm_r(i),     open, tx5_sts_cq_fsm_f(i) );
    end generate;

--------------------------------------------------------------------------------
-- Clear register
--------------------------------------------------------------------------------

    u_CLEAR_per_PE : for i in 7 downto 0 generate
    STAT_CNT_CLEAR(i) <= clear_stat_cnt when active_sts_pe(i) = '1' else '0';
    end generate;

    u_0x0271_WC : MPI_REG_WC generic map(x"71") port map(RST, CLK, we(2), addr_lsb, clear_stat_cnt );

end BEHAVE;
