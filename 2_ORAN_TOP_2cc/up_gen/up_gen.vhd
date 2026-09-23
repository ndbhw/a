--------------------------------------------------------------------------------
--
-- Copyright (C) 2025, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2025.03.18
--------------------------------------------------------------------------------
-- Function description
--   -. U-Plane generation
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2025.03.18) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use WORK.ARRAY_TYPE.ALL;
use WORK.PKG_ORAN.ALL;
use WORK.PKG_ORAN_ARRAY.ALL;

entity UP_GEN is
    generic (
        OFFSET                      : natural := 4;
        MAX_CH                      : natural := 4;
        MAX_NUM_PORTC               : natural := 4
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;                            -- 245.76-MHz
        RST                         : in  std_logic;                            -- ASYNC

--------------------------------------------------------------------------------
-- Debug
--------------------------------------------------------------------------------

        IGNORE_FRAME_ID             : in  std_logic;
        IGNORE_FRAME_ID_PUxCH_RX    : out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_PUxCH_TX    : out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_PRACH0_RX   : out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_PRACH0_TX   : out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_PRACH1_RX   : out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_PRACH1_TX   : out std_logic_vector(7 downto 0);

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------

        UL_PARAM_ID_EN              : in  std_logic_array64(7 downto 0);
        UL_PARAM_ID                 : in  std_logic_array64_array16(7 downto 0);
        UL_PE_INDEX                 : in  std_logic_array64_array8(7 downto 0);

        UL_COMP_MODE                : in  std_logic_array64(7 downto 0);
        UL_IQ_WIDTH                 : in  std_logic_array64_array4(7 downto 0);
        UL_COMP_METHOD              : in  std_logic_array64_array4(7 downto 0);
        UL_PRB_PER_SYMBOL           : in  std_logic_array64_array10(7 downto 0);
        UL_PRB_PER_MTU              : in  std_logic_array64_array10(7 downto 0);

        FREQ_OFFSET_FOR_PRACH0      : in  std_logic_array24(7 downto 0);
        FREQ_OFFSET_FOR_PRACH1      : in  std_logic_array24(7 downto 0);        -- 2nd FDM or eMTC

--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

        STATUS_TX0_CQ_FSM           : out std_logic_vector(7 downto 0);
        CNT_TX0_CQ_FSM_BUSY         : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_CONV_FULL        : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL0       : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL1       : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL2       : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL3       : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL4       : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL5       : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL6       : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL7       : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL8       : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL9       : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL10      : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL11      : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL12      : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL13      : out std_logic_vector(31 downto 0);
        CNT_TX0_UPPKT_SYMBOL0       : out std_logic_vector(31 downto 0);
        CNT_TX0_UPPKT_SYMBOL1       : out std_logic_vector(31 downto 0);
        CNT_TX0_UPPKT_SYMBOL2       : out std_logic_vector(31 downto 0);
        CNT_TX0_UPPKT_SYMBOL3       : out std_logic_vector(31 downto 0);
        CNT_TX0_UPPKT_SYMBOL4       : out std_logic_vector(31 downto 0);
        CNT_TX0_UPPKT_SYMBOL5       : out std_logic_vector(31 downto 0);
        CNT_TX0_UPPKT_SYMBOL6       : out std_logic_vector(31 downto 0);
        CNT_TX0_UPPKT_SYMBOL7       : out std_logic_vector(31 downto 0);
        CNT_TX0_UPPKT_SYMBOL8       : out std_logic_vector(31 downto 0);
        CNT_TX0_UPPKT_SYMBOL9       : out std_logic_vector(31 downto 0);
        CNT_TX0_UPPKT_SYMBOL10      : out std_logic_vector(31 downto 0);
        CNT_TX0_UPPKT_SYMBOL11      : out std_logic_vector(31 downto 0);
        CNT_TX0_UPPKT_SYMBOL12      : out std_logic_vector(31 downto 0);
        CNT_TX0_UPPKT_SYMBOL13      : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL0     : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL1     : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL2     : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL3     : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL4     : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL5     : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL6     : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL7     : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL8     : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL9     : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL10    : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL11    : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL12    : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL13    : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL0        : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL1        : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL2        : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL3        : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL4        : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL5        : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL6        : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL7        : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL8        : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL9        : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL10       : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL11       : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL12       : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL13       : out std_logic_vector(31 downto 0);

        STATUS_TX1_CQ_FSM           : out std_logic_vector(7 downto 0);
        CNT_TX1_CQ_FSM_BUSY         : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_CONV_FULL        : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL0       : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL1       : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL2       : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL3       : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL4       : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL5       : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL6       : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL7       : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL8       : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL9       : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL10      : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL11      : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL12      : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL13      : out std_logic_vector(31 downto 0);
        CNT_TX1_UPPKT_SYMBOL0       : out std_logic_vector(31 downto 0);
        CNT_TX1_UPPKT_SYMBOL1       : out std_logic_vector(31 downto 0);
        CNT_TX1_UPPKT_SYMBOL2       : out std_logic_vector(31 downto 0);
        CNT_TX1_UPPKT_SYMBOL3       : out std_logic_vector(31 downto 0);
        CNT_TX1_UPPKT_SYMBOL4       : out std_logic_vector(31 downto 0);
        CNT_TX1_UPPKT_SYMBOL5       : out std_logic_vector(31 downto 0);
        CNT_TX1_UPPKT_SYMBOL6       : out std_logic_vector(31 downto 0);
        CNT_TX1_UPPKT_SYMBOL7       : out std_logic_vector(31 downto 0);
        CNT_TX1_UPPKT_SYMBOL8       : out std_logic_vector(31 downto 0);
        CNT_TX1_UPPKT_SYMBOL9       : out std_logic_vector(31 downto 0);
        CNT_TX1_UPPKT_SYMBOL10      : out std_logic_vector(31 downto 0);
        CNT_TX1_UPPKT_SYMBOL11      : out std_logic_vector(31 downto 0);
        CNT_TX1_UPPKT_SYMBOL12      : out std_logic_vector(31 downto 0);
        CNT_TX1_UPPKT_SYMBOL13      : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL0     : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL1     : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL2     : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL3     : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL4     : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL5     : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL6     : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL7     : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL8     : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL9     : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL10    : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL11    : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL12    : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL13    : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL0        : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL1        : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL2        : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL3        : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL4        : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL5        : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL6        : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL7        : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL8        : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL9        : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL10       : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL11       : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL12       : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL13       : out std_logic_vector(31 downto 0);

        STATUS_TX2_CQ_FSM           : out std_logic_vector(7 downto 0);
        CNT_TX2_CQ_FSM_BUSY         : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_CONV_FULL        : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL0       : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL1       : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL2       : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL3       : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL4       : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL5       : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL6       : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL7       : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL8       : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL9       : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL10      : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL11      : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL12      : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL13      : out std_logic_vector(31 downto 0);
        CNT_TX2_UPPKT_SYMBOL0       : out std_logic_vector(31 downto 0);
        CNT_TX2_UPPKT_SYMBOL1       : out std_logic_vector(31 downto 0);
        CNT_TX2_UPPKT_SYMBOL2       : out std_logic_vector(31 downto 0);
        CNT_TX2_UPPKT_SYMBOL3       : out std_logic_vector(31 downto 0);
        CNT_TX2_UPPKT_SYMBOL4       : out std_logic_vector(31 downto 0);
        CNT_TX2_UPPKT_SYMBOL5       : out std_logic_vector(31 downto 0);
        CNT_TX2_UPPKT_SYMBOL6       : out std_logic_vector(31 downto 0);
        CNT_TX2_UPPKT_SYMBOL7       : out std_logic_vector(31 downto 0);
        CNT_TX2_UPPKT_SYMBOL8       : out std_logic_vector(31 downto 0);
        CNT_TX2_UPPKT_SYMBOL9       : out std_logic_vector(31 downto 0);
        CNT_TX2_UPPKT_SYMBOL10      : out std_logic_vector(31 downto 0);
        CNT_TX2_UPPKT_SYMBOL11      : out std_logic_vector(31 downto 0);
        CNT_TX2_UPPKT_SYMBOL12      : out std_logic_vector(31 downto 0);
        CNT_TX2_UPPKT_SYMBOL13      : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL0     : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL1     : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL2     : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL3     : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL4     : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL5     : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL6     : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL7     : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL8     : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL9     : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL10    : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL11    : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL12    : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL13    : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL0        : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL1        : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL2        : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL3        : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL4        : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL5        : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL6        : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL7        : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL8        : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL9        : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL10       : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL11       : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL12       : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL13       : out std_logic_vector(31 downto 0);

--------------------------------------------------------------------------------
-- DL/UL C-Plane (Not decoded)
--------------------------------------------------------------------------------

        C_PLANE_VALID               : in  std_logic;
        C_PLANE_LAST                : in  std_logic;
        C_PLANE_DATA                : in  std_logic_vector(31 downto 0);
        C_PLANE_DATA_INDEX          : in  std_logic_vector(2 downto 0);
        C_PLANE_LINK_INDEX          : in  std_logic_vector(3 downto 0);

--------------------------------------------------------------------------------
-- ULFE
--------------------------------------------------------------------------------

        ULFE_FRAME_ID               : in  std_logic_vector(7 downto 0);
        ULFE_SUBFRAME_ID            : in  std_logic_vector(3 downto 0);
        ULFE_SLOT_ID                : in  std_logic_vector(5 downto 0);
        ULFE_SYMBOL_ID              : in  std_logic_vector(5 downto 0);

        ULFE_VALID                  : in  std_logic_vector(7 downto 0);
        ULFE_START                  : in  std_logic_vector(7 downto 0);
        ULFE_LAST                   : in  std_logic_vector(7 downto 0);
        ULFE_DATA_I                 : in  std_logic_array16(7 downto 0);
        ULFE_DATA_Q                 : in  std_logic_array16(7 downto 0);

--------------------------------------------------------------------------------
-- RAFE0
--------------------------------------------------------------------------------

        RAFE0_FRAME_ID              : in  std_logic_vector(7 downto 0);
        RAFE0_SUBFRAME_ID           : in  std_logic_vector(3 downto 0);
        RAFE0_SLOT_ID               : in  std_logic_vector(5 downto 0);
        RAFE0_SYMBOL_ID             : in  std_logic_vector(5 downto 0);
        RAFE0_ANT_ID                : in  std_logic_vector(2 downto 0);

        RAFE0_VALID                 : in  std_logic;
        RAFE0_START                 : in  std_logic;
        RAFE0_LAST                  : in  std_logic;
        RAFE0_DATA_I                : in  std_logic_vector(15 downto 0);
        RAFE0_DATA_Q                : in  std_logic_vector(15 downto 0);

--------------------------------------------------------------------------------
-- RAFE1 (Additional FDM or eMTC)
--------------------------------------------------------------------------------

        RAFE1_FRAME_ID              : in  std_logic_vector(7 downto 0);
        RAFE1_SUBFRAME_ID           : in  std_logic_vector(3 downto 0);
        RAFE1_SLOT_ID               : in  std_logic_vector(5 downto 0);
        RAFE1_SYMBOL_ID             : in  std_logic_vector(5 downto 0);
        RAFE1_ANT_ID                : in  std_logic_vector(2 downto 0);

        RAFE1_VALID                 : in  std_logic;
        RAFE1_START                 : in  std_logic;
        RAFE1_LAST                  : in  std_logic;
        RAFE1_DATA_I                : in  std_logic_vector(15 downto 0);
        RAFE1_DATA_Q                : in  std_logic_vector(15 downto 0);

--------------------------------------------------------------------------------
-- UL U-Plane (Not encoded)
--------------------------------------------------------------------------------

        TX0_RB_INIT                 : out std_logic;
        TX0_RB_PATH                 : out std_logic_vector(2 downto 0);
        TX0_RB_PE_INDEX             : out std_logic_vector(2 downto 0);
        TX0_RB_eAxC_ID              : out std_logic_vector(15 downto 0);
        TX0_RB_SEQUENCE_ID          : out std_logic_vector(15 downto 0);
        TX0_RB_HEADER_APP           : out std_logic_vector(31 downto 0);
        TX0_RB_HEADER_APP_ACK       : in  std_logic;
        TX0_RB_HEADER_SEC           : out std_logic_vector(31 downto 0);
        TX0_RB_HEADER_SEC_ACK       : in  std_logic;
        TX0_RB_COMP_HDR             : out std_logic_vector(8 downto 0);
        TX0_RB_VALID                : out std_logic;
        TX0_RB_TICK                 : out std_logic;
        TX0_RB_DATA_I               : out std_logic_vector(15 downto 0);
        TX0_RB_DATA_Q               : out std_logic_vector(15 downto 0);
        TX0_RB_USER                 : out std_logic_vector(15 downto 0);
                                    
        TX1_RB_INIT                 : out std_logic;
        TX1_RB_PATH                 : out std_logic_vector(2 downto 0);
        TX1_RB_PE_INDEX             : out std_logic_vector(2 downto 0);
        TX1_RB_eAxC_ID              : out std_logic_vector(15 downto 0);
        TX1_RB_SEQUENCE_ID          : out std_logic_vector(15 downto 0);
        TX1_RB_HEADER_APP           : out std_logic_vector(31 downto 0);
        TX1_RB_HEADER_APP_ACK       : in  std_logic;
        TX1_RB_HEADER_SEC           : out std_logic_vector(31 downto 0);
        TX1_RB_HEADER_SEC_ACK       : in  std_logic;
        TX1_RB_COMP_HDR             : out std_logic_vector(8 downto 0);
        TX1_RB_VALID                : out std_logic;
        TX1_RB_TICK                 : out std_logic;
        TX1_RB_DATA_I               : out std_logic_vector(15 downto 0);
        TX1_RB_DATA_Q               : out std_logic_vector(15 downto 0);
        TX1_RB_USER                 : out std_logic_vector(15 downto 0);

        TX2_RB_INIT                 : out std_logic;
        TX2_RB_PATH                 : out std_logic_vector(2 downto 0);
        TX2_RB_PE_INDEX             : out std_logic_vector(2 downto 0);
        TX2_RB_eAxC_ID              : out std_logic_vector(15 downto 0);
        TX2_RB_SEQUENCE_ID          : out std_logic_vector(15 downto 0);
        TX2_RB_HEADER_APP           : out std_logic_vector(31 downto 0);
        TX2_RB_HEADER_APP_ACK       : in  std_logic;
        TX2_RB_HEADER_SEC           : out std_logic_vector(31 downto 0);
        TX2_RB_HEADER_SEC_ACK       : in  std_logic;
        TX2_RB_COMP_HDR             : out std_logic_vector(8 downto 0);
        TX2_RB_VALID                : out std_logic;
        TX2_RB_TICK                 : out std_logic;
        TX2_RB_DATA_I               : out std_logic_vector(15 downto 0);
        TX2_RB_DATA_Q               : out std_logic_vector(15 downto 0);
        TX2_RB_USER                 : out std_logic_vector(15 downto 0)

    );
end UP_GEN;

architecture BEHAVE of UP_GEN is

    constant R                      : natural := MAX_NUM_PORTC;

    component RST_SYNC is
    generic (
        DLY_NUM                     : natural := 4;
        MAX_FANOUT_NUM              : integer := 200
    );
    port (
        RST_IN                      : in  std_logic;
        CLK                         : in  std_logic;
        RST_OUT                     : out std_logic
    );
    end component;

    signal srst                     : std_logic;

    component SECTION_MANAGER is
    generic (
        OFFSET                      : natural := 4;
        MAX_CH                      : natural := 4;
        MAX_NUM_PORTC               : natural := 4;
        LINK_DIRECTION              : std_logic := '0';
        USAGE_TYPE0                 : boolean := false;
        USAGE_TYPE1                 : boolean := true;
        USAGE_TYPE3                 : boolean := true;
        USAGE_TYPE5                 : boolean := false;
        USAGE_TYPE6                 : boolean := false;
        USAGE_TYPE7                 : boolean := false;
        PUxCH_CMD_QUEUE_DEPTH       : natural := 512;
        PRACH_CMD_QUEUE_DEPTH       : natural := 32
    );
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        IGNORE_FRAME_ID             : in  std_logic;
        IGNORE_FRAME_ID_PUxCH_RX    : out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_PUxCH_TX    : out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_PRACH0_RX   : out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_PRACH0_TX   : out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_PRACH1_RX   : out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_PRACH1_TX   : out std_logic_vector(7 downto 0);

        PARAM_ID                    : in  std_logic_array64_array16(7 downto 0);
        PE_INDEX                    : in  std_logic_array64_array8(7 downto 0);

        COMP_MODE                   : in  std_logic_array64(7 downto 0);
        IQ_WIDTH                    : in  std_logic_array64_array4(7 downto 0);
        COMP_METHOD                 : in  std_logic_array64_array4(7 downto 0);
        PRB_PER_SYMBOL              : in  std_logic_array64_array10(7 downto 0);
        PRB_PER_MTU                 : in  std_logic_array64_array10(7 downto 0);

        FREQ_OFFSET_FOR_PRACH0      : in  std_logic_array24(MAX_NUM_PORTC-1 downto 0);
        FREQ_OFFSET_FOR_PRACH1      : in  std_logic_array24(MAX_NUM_PORTC-1 downto 0);

        STATUS_TX0_CQ_FSM           : out std_logic_vector(7 downto 0);
        CNT_TX0_CQ_FSM_TERMINATION  : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_CONV_FULL        : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL0       : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL1       : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL2       : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL3       : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL4       : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL5       : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL6       : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL7       : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL8       : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL9       : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL10      : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL11      : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL12      : out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL13      : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL0     : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL1     : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL2     : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL3     : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL4     : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL5     : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL6     : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL7     : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL8     : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL9     : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL10    : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL11    : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL12    : out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL13    : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL0        : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL1        : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL2        : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL3        : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL4        : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL5        : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL6        : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL7        : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL8        : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL9        : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL10       : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL11       : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL12       : out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL13       : out std_logic_vector(31 downto 0);

        STATUS_TX1_CQ_FSM           : out std_logic_vector(7 downto 0);
        CNT_TX1_CQ_FSM_TERMINATION  : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_CONV_FULL        : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL0       : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL1       : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL2       : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL3       : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL4       : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL5       : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL6       : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL7       : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL8       : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL9       : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL10      : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL11      : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL12      : out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL13      : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL0     : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL1     : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL2     : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL3     : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL4     : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL5     : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL6     : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL7     : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL8     : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL9     : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL10    : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL11    : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL12    : out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL13    : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL0        : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL1        : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL2        : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL3        : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL4        : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL5        : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL6        : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL7        : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL8        : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL9        : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL10       : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL11       : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL12       : out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL13       : out std_logic_vector(31 downto 0);

        STATUS_TX2_CQ_FSM           : out std_logic_vector(7 downto 0);
        CNT_TX2_CQ_FSM_TERMINATION  : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_CONV_FULL        : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL0       : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL1       : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL2       : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL3       : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL4       : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL5       : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL6       : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL7       : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL8       : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL9       : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL10      : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL11      : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL12      : out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL13      : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL0     : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL1     : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL2     : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL3     : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL4     : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL5     : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL6     : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL7     : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL8     : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL9     : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL10    : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL11    : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL12    : out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL13    : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL0        : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL1        : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL2        : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL3        : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL4        : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL5        : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL6        : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL7        : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL8        : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL9        : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL10       : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL11       : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL12       : out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL13       : out std_logic_vector(31 downto 0);

        C_PLANE_VALID               : in  std_logic;
        C_PLANE_LAST                : in  std_logic;
        C_PLANE_DATA                : in  std_logic_vector(31 downto 0);
        C_PLANE_DATA_INDEX          : in  std_logic_vector(2 downto 0);
        C_PLANE_LINK_INDEX          : in  std_logic_vector(3 downto 0);

        ULFE_UPDATE                 : in  std_logic;

        ULFE_FRAME_ID               : in  std_logic_vector(7 downto 0);
        ULFE_SUBFRAME_ID            : in  std_logic_vector(3 downto 0);
        ULFE_SLOT_ID                : in  std_logic_vector(5 downto 0);
        ULFE_SYMBOL_ID              : in  std_logic_vector(5 downto 0);

        RAFE0_UPDATE                : in  std_logic;

        RAFE0_FRAME_ID              : in  std_logic_vector(7 downto 0);
        RAFE0_SUBFRAME_ID           : in  std_logic_vector(3 downto 0);
        RAFE0_SLOT_ID               : in  std_logic_vector(5 downto 0);
        RAFE0_SYMBOL_ID             : in  std_logic_vector(5 downto 0);
        RAFE0_ANT_ID                : in  std_logic_vector(2 downto 0);

        RAFE1_UPDATE                : in  std_logic;

        RAFE1_FRAME_ID              : in  std_logic_vector(7 downto 0);
        RAFE1_SUBFRAME_ID           : in  std_logic_vector(3 downto 0);
        RAFE1_SLOT_ID               : in  std_logic_vector(5 downto 0);
        RAFE1_SYMBOL_ID             : in  std_logic_vector(5 downto 0);
        RAFE1_ANT_ID                : in  std_logic_vector(2 downto 0);

        TX0_SECTION_TICK            : out std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        TX0_SECTION_LAST            : out std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        TX0_SECTION_DONE            : in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        TX0_BANK_OF_PRB             : out std_logic_vector(0 downto 0);
        TX0_USE_EVERY_PRB           : out std_logic;
        TX0_START_OF_PRB            : out std_logic_vector(9 downto 0);
        TX0_NUMBER_OF_PRB           : out std_logic_vector(9 downto 0);
        TX0_UD_COMP_HDR             : out std_logic_vector(8 downto 0);

        TX1_SECTION_TICK            : out std_logic;
        TX1_SECTION_LAST            : out std_logic;
        TX1_SECTION_DONE            : in  std_logic;
        TX1_BANK_OF_PRB             : out std_logic_vector(0 downto 0);
        TX1_USE_EVERY_PRB           : out std_logic;
        TX1_START_OF_PRB            : out std_logic_vector(9 downto 0);
        TX1_NUMBER_OF_PRB           : out std_logic_vector(9 downto 0);
        TX1_UD_COMP_HDR             : out std_logic_vector(8 downto 0);

        TX2_SECTION_TICK            : out std_logic;
        TX2_SECTION_LAST            : out std_logic;
        TX2_SECTION_DONE            : in  std_logic;
        TX2_BANK_OF_PRB             : out std_logic_vector(0 downto 0);
        TX2_USE_EVERY_PRB           : out std_logic;
        TX2_START_OF_PRB            : out std_logic_vector(9 downto 0);
        TX2_NUMBER_OF_PRB           : out std_logic_vector(9 downto 0);
        TX2_UD_COMP_HDR             : out std_logic_vector(8 downto 0);

        TX0_INIT                    : out std_logic;
        TX0_RB_PATH                 : out std_logic_vector(2 downto 0);
        TX0_PE_INDEX                : out std_logic_vector(2 downto 0);
        TX0_eAxC_ID                 : out std_logic_vector(15 downto 0);
        TX0_SEQUENCE_ID             : out std_logic_vector(15 downto 0);
        TX0_HEADER_APP              : out std_logic_vector(31 downto 0);
        TX0_HEADER_APP_ACK          : in  std_logic;
        TX0_HEADER_SEC              : out std_logic_vector(31 downto 0);
        TX0_HEADER_SEC_ACK          : in  std_logic;

        TX1_INIT                    : out std_logic;
        TX1_RB_PATH                 : out std_logic_vector(2 downto 0);
        TX1_PE_INDEX                : out std_logic_vector(2 downto 0);
        TX1_eAxC_ID                 : out std_logic_vector(15 downto 0);
        TX1_SEQUENCE_ID             : out std_logic_vector(15 downto 0);
        TX1_HEADER_APP              : out std_logic_vector(31 downto 0);
        TX1_HEADER_APP_ACK          : in  std_logic;
        TX1_HEADER_SEC              : out std_logic_vector(31 downto 0);
        TX1_HEADER_SEC_ACK          : in  std_logic;

        TX2_INIT                    : out std_logic;
        TX2_RB_PATH                 : out std_logic_vector(2 downto 0);
        TX2_PE_INDEX                : out std_logic_vector(2 downto 0);
        TX2_eAxC_ID                 : out std_logic_vector(15 downto 0);
        TX2_SEQUENCE_ID             : out std_logic_vector(15 downto 0);
        TX2_HEADER_APP              : out std_logic_vector(31 downto 0);
        TX2_HEADER_APP_ACK          : in  std_logic;
        TX2_HEADER_SEC              : out std_logic_vector(31 downto 0);
        TX2_HEADER_SEC_ACK          : in  std_logic

    );
    end component;

    signal buf_ulfe_valid           : std_logic_vector(7 downto 0) := (others => '0');
    signal buf_ulfe_last            : std_logic_vector(7 downto 0) := (others => '0');
--    signal buf_ulfe_valid           : std_logic_vector(MAX_NUM_PORTC-1 downto 0);

    signal ulfe_update              : std_logic;
    signal rafe0_update             : std_logic;
    signal rafe1_update             : std_logic;
    signal tx0_section_tick         : std_logic_vector(MAX_NUM_PORTC-1 downto 0);
    signal tx0_section_last         : std_logic_vector(MAX_NUM_PORTC-1 downto 0);
    signal tx0_section_done         : std_logic_vector(MAX_NUM_PORTC-1 downto 0);
    signal tx0_bank_of_prb          : std_logic_vector(0 downto 0);
    signal tx0_use_every_prb        : std_logic;
    signal tx0_start_of_prb         : std_logic_vector(9 downto 0);
    signal tx0_number_of_prb        : std_logic_vector(9 downto 0);
    signal tx0_ud_comp_hdr          : std_logic_vector(8 downto 0);
    signal tx1_section_tick         : std_logic;
    signal tx1_section_last         : std_logic;
    signal tx1_section_done         : std_logic;
    signal tx1_bank_of_prb          : std_logic_vector(0 downto 0);
    signal tx1_use_every_prb        : std_logic;
    signal tx1_start_of_prb         : std_logic_vector(9 downto 0);
    signal tx1_number_of_prb        : std_logic_vector(9 downto 0);
    signal tx1_ud_comp_hdr          : std_logic_vector(8 downto 0);
    signal tx2_section_tick         : std_logic;
    signal tx2_section_last         : std_logic;
    signal tx2_section_done         : std_logic;
    signal tx2_bank_of_prb          : std_logic_vector(0 downto 0);
    signal tx2_use_every_prb        : std_logic;
    signal tx2_start_of_prb         : std_logic_vector(9 downto 0);
    signal tx2_number_of_prb        : std_logic_vector(9 downto 0);
    signal tx2_ud_comp_hdr          : std_logic_vector(8 downto 0);
    signal tx0_init                 : std_logic;
    signal tx1_init                 : std_logic;
    signal tx2_init                 : std_logic;

    component UP_TX_WINDOW is
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        STATUS_FSM                  : out std_logic_vector(5 downto 0);

        SECTION_TICK                : in  std_logic;
        SECTION_LAST                : in  std_logic;
        SECTION_DONE                : out std_logic;

        BANK_OF_PRB                 : in  std_logic_vector(0 downto 0);
        USE_EVERY_PRB               : in  std_logic;
        START_OF_PRB                : in  std_logic_vector(9 downto 0);
        NUMBER_OF_PRB               : in  std_logic_vector(9 downto 0);
        UD_COMP_HDR                 : in  std_logic_vector(8 downto 0);

        UL_FRAME_ID                 : in  std_logic_vector(7 downto 0);
        UL_SUBFRAME_ID              : in  std_logic_vector(3 downto 0);
        UL_SLOT_ID                  : in  std_logic_vector(5 downto 0);
        UL_SYMBOL_ID                : in  std_logic_vector(5 downto 0);
        UL_BANK_ID                  : in  std_logic_vector(0 downto 0);
        UL_START_RE                 : in  std_logic_vector(15 downto 0);

        UL_VALID                    : in  std_logic;
        UL_START                    : in  std_logic;
        UL_LAST                     : in  std_logic;
        UL_DATA_I                   : in  std_logic_vector(15 downto 0);
        UL_DATA_Q                   : in  std_logic_vector(15 downto 0);

        RB_COMP_HDR                 : out std_logic_vector(8 downto 0);

        RB_VALID                    : out std_logic;
        RB_TICK                     : out std_logic;
        RB_DATA_I                   : out std_logic_vector(15 downto 0);
        RB_DATA_Q                   : out std_logic_vector(15 downto 0);
        RB_USER                     : out std_logic_vector(15 downto 0)
    );
    end component;

    component UP_TX_WINDOW_RACH is
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        STATUS_FSM                  : out std_logic_vector(5 downto 0);

        SECTION_TICK                : in  std_logic;
        SECTION_LAST                : in  std_logic;
        SECTION_DONE                : out std_logic;

        BANK_OF_PRB                 : in  std_logic_vector(0 downto 0);
        USE_EVERY_PRB               : in  std_logic;
        START_OF_PRB                : in  std_logic_vector(9 downto 0);
        NUMBER_OF_PRB               : in  std_logic_vector(9 downto 0);
        UD_COMP_HDR                 : in  std_logic_vector(8 downto 0);

        UL_FRAME_ID                 : in  std_logic_vector(7 downto 0);
        UL_SUBFRAME_ID              : in  std_logic_vector(3 downto 0);
        UL_SLOT_ID                  : in  std_logic_vector(5 downto 0);
        UL_SYMBOL_ID                : in  std_logic_vector(5 downto 0);
        UL_BANK_ID                  : in  std_logic_vector(0 downto 0);
        UL_START_RE                 : in  std_logic_vector(15 downto 0);

        UL_VALID                    : in  std_logic;
        UL_START                    : in  std_logic;
        UL_LAST                     : in  std_logic;
        UL_DATA_I                   : in  std_logic_vector(15 downto 0);
        UL_DATA_Q                   : in  std_logic_vector(15 downto 0);

        RB_COMP_HDR                 : out std_logic_vector(8 downto 0);

        RB_VALID                    : out std_logic;
        RB_TICK                     : out std_logic;
        RB_DATA_I                   : out std_logic_vector(15 downto 0);
        RB_DATA_Q                   : out std_logic_vector(15 downto 0);
        RB_USER                     : out std_logic_vector(15 downto 0)
    );
    end component;

    signal puxch_comp_hdr           : std_logic_array9(MAX_NUM_PORTC-1 downto 0);
    signal puxch_valid              : std_logic_vector(MAX_NUM_PORTC-1 downto 0);
    signal puxch_tick               : std_logic_vector(MAX_NUM_PORTC-1 downto 0);
    signal puxch_data_i             : std_logic_array16(MAX_NUM_PORTC-1 downto 0);
    signal puxch_data_q             : std_logic_array16(MAX_NUM_PORTC-1 downto 0);
    signal puxch_user               : std_logic_array16(MAX_NUM_PORTC-1 downto 0);
    signal prach0_comp_hdr          : std_logic_vector(8 downto 0);
    signal prach0_valid             : std_logic;
    signal prach0_tick              : std_logic;
    signal prach0_data_i            : std_logic_vector(15 downto 0);
    signal prach0_data_q            : std_logic_vector(15 downto 0);
    signal prach0_user              : std_logic_vector(15 downto 0);
    signal prach1_comp_hdr          : std_logic_vector(8 downto 0);
    signal prach1_valid             : std_logic;
    signal prach1_tick              : std_logic;
    signal prach1_data_i            : std_logic_vector(15 downto 0);
    signal prach1_data_q            : std_logic_vector(15 downto 0);
    signal prach1_user              : std_logic_vector(15 downto 0);

begin

--------------------------------------------------------------------------------
-- Port/signal mapping
--------------------------------------------------------------------------------

    u_REMAP : for i in MAX_NUM_PORTC-1 downto 0 generate
    buf_ulfe_valid(i) <= ULFE_VALID(i);
    buf_ulfe_last(i)  <= ULFE_LAST(i);
    end generate;

    rafe0_update                    <= RAFE0_VALID and RAFE0_LAST;
    rafe1_update                    <= RAFE1_VALID and RAFE1_LAST;

    TX0_RB_INIT                     <= tx0_init;
    TX1_RB_INIT                     <= tx1_init;
    TX2_RB_INIT                     <= tx2_init;

    u_2CHANNEL : if MAX_CH = 2 generate
    ulfe_update                     <= buf_ulfe_valid(1) and buf_ulfe_last(1) when UL_PARAM_ID_EN(0)(OFFSET+1) = '1' else
                                       buf_ulfe_valid(0) and buf_ulfe_last(0) when UL_PARAM_ID_EN(0)(OFFSET+0) = '1' else
                                       '0';

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            TX0_RB_COMP_HDR <= puxch_comp_hdr(0) or puxch_comp_hdr(1);
            TX0_RB_VALID    <= puxch_valid(0)    or puxch_valid(1);
            TX0_RB_TICK     <= puxch_tick(0)     or puxch_tick(1);
            TX0_RB_DATA_I   <= puxch_data_i(0)   or puxch_data_i(1);
            TX0_RB_DATA_Q   <= puxch_data_q(0)   or puxch_data_q(1);
            TX0_RB_USER     <= puxch_user(0)     or puxch_user(1);
        end if;
    end process;
    end generate;

    u_4CHANNEL : if MAX_CH = 4 generate
    ulfe_update                     <= buf_ulfe_valid(3) and buf_ulfe_last(3) when UL_PARAM_ID_EN(0)(OFFSET+3) = '1' else
                                       buf_ulfe_valid(2) and buf_ulfe_last(2) when UL_PARAM_ID_EN(0)(OFFSET+2) = '1' else
                                       buf_ulfe_valid(1) and buf_ulfe_last(1) when UL_PARAM_ID_EN(0)(OFFSET+1) = '1' else
                                       buf_ulfe_valid(0) and buf_ulfe_last(0) when UL_PARAM_ID_EN(0)(OFFSET+0) = '1' else
                                       '0';

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            TX0_RB_COMP_HDR <= puxch_comp_hdr(0) or puxch_comp_hdr(1) or puxch_comp_hdr(2) or puxch_comp_hdr(3);
            TX0_RB_VALID    <= puxch_valid(0)    or puxch_valid(1)    or puxch_valid(2)    or puxch_valid(3);
            TX0_RB_TICK     <= puxch_tick(0)     or puxch_tick(1)     or puxch_tick(2)     or puxch_tick(3);
            TX0_RB_DATA_I   <= puxch_data_i(0)   or puxch_data_i(1)   or puxch_data_i(2)   or puxch_data_i(3);
            TX0_RB_DATA_Q   <= puxch_data_q(0)   or puxch_data_q(1)   or puxch_data_q(2)   or puxch_data_q(3);
            TX0_RB_USER     <= puxch_user(0)     or puxch_user(1)     or puxch_user(2)     or puxch_user(3);
        end if;
    end process;
    end generate;

    u_8CHANNEL : if MAX_CH = 8 generate
    ulfe_update                     <= buf_ulfe_valid(7) and buf_ulfe_last(7) when UL_PARAM_ID_EN(0)(OFFSET+7) = '1' else
                                       buf_ulfe_valid(6) and buf_ulfe_last(6) when UL_PARAM_ID_EN(0)(OFFSET+6) = '1' else
                                       buf_ulfe_valid(5) and buf_ulfe_last(5) when UL_PARAM_ID_EN(0)(OFFSET+5) = '1' else
                                       buf_ulfe_valid(4) and buf_ulfe_last(4) when UL_PARAM_ID_EN(0)(OFFSET+4) = '1' else
                                       buf_ulfe_valid(3) and buf_ulfe_last(3) when UL_PARAM_ID_EN(0)(OFFSET+3) = '1' else
                                       buf_ulfe_valid(2) and buf_ulfe_last(2) when UL_PARAM_ID_EN(0)(OFFSET+2) = '1' else
                                       buf_ulfe_valid(1) and buf_ulfe_last(1) when UL_PARAM_ID_EN(0)(OFFSET+1) = '1' else
                                       buf_ulfe_valid(0) and buf_ulfe_last(0) when UL_PARAM_ID_EN(0)(OFFSET+0) = '1' else
                                       '0';

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            TX0_RB_COMP_HDR <= puxch_comp_hdr(0) or puxch_comp_hdr(1) or puxch_comp_hdr(2) or puxch_comp_hdr(3) or puxch_comp_hdr(4) or puxch_comp_hdr(5) or puxch_comp_hdr(6) or puxch_comp_hdr(7);
            TX0_RB_VALID    <= puxch_valid(0)    or puxch_valid(1)    or puxch_valid(2)    or puxch_valid(3)    or puxch_valid(4)    or puxch_valid(5)    or puxch_valid(6)    or puxch_valid(7);
            TX0_RB_TICK     <= puxch_tick(0)     or puxch_tick(1)     or puxch_tick(2)     or puxch_tick(3)     or puxch_tick(4)     or puxch_tick(5)     or puxch_tick(6)     or puxch_tick(7);
            TX0_RB_DATA_I   <= puxch_data_i(0)   or puxch_data_i(1)   or puxch_data_i(2)   or puxch_data_i(3)   or puxch_data_i(4)   or puxch_data_i(5)   or puxch_data_i(6)   or puxch_data_i(7);
            TX0_RB_DATA_Q   <= puxch_data_q(0)   or puxch_data_q(1)   or puxch_data_q(2)   or puxch_data_q(3)   or puxch_data_q(4)   or puxch_data_q(5)   or puxch_data_q(6)   or puxch_data_q(7);
            TX0_RB_USER     <= puxch_user(0)     or puxch_user(1)     or puxch_user(2)     or puxch_user(3)     or puxch_user(4)     or puxch_user(5)     or puxch_user(6)     or puxch_user(7);
        end if;
    end process;
    end generate;

--    process (CLK)
--    begin
--        if (CLK'event and CLK = '1') then
            TX1_RB_COMP_HDR <= prach0_comp_hdr;
            TX1_RB_VALID    <= prach0_valid;
            TX1_RB_TICK     <= prach0_tick;
            TX1_RB_DATA_I   <= prach0_data_i;
            TX1_RB_DATA_Q   <= prach0_data_q;
            TX1_RB_USER     <= prach0_user;
--        end if;
--    end process;

--    process (CLK)
--    begin
--        if (CLK'event and CLK = '1') then
            TX2_RB_COMP_HDR <= prach1_comp_hdr;
            TX2_RB_VALID    <= prach1_valid;
            TX2_RB_TICK     <= prach1_tick;
            TX2_RB_DATA_I   <= prach1_data_i;
            TX2_RB_DATA_Q   <= prach1_data_q;
            TX2_RB_USER     <= prach1_user;
--        end if;
--    end process;

--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

    CNT_TX0_UPPKT_SYMBOL0           <= (others => '0');
    CNT_TX0_UPPKT_SYMBOL1           <= (others => '0');
    CNT_TX0_UPPKT_SYMBOL2           <= (others => '0');
    CNT_TX0_UPPKT_SYMBOL3           <= (others => '0');
    CNT_TX0_UPPKT_SYMBOL4           <= (others => '0');
    CNT_TX0_UPPKT_SYMBOL5           <= (others => '0');
    CNT_TX0_UPPKT_SYMBOL6           <= (others => '0');
    CNT_TX0_UPPKT_SYMBOL7           <= (others => '0');
    CNT_TX0_UPPKT_SYMBOL8           <= (others => '0');
    CNT_TX0_UPPKT_SYMBOL9           <= (others => '0');
    CNT_TX0_UPPKT_SYMBOL10          <= (others => '0');
    CNT_TX0_UPPKT_SYMBOL11          <= (others => '0');
    CNT_TX0_UPPKT_SYMBOL12          <= (others => '0');
    CNT_TX0_UPPKT_SYMBOL13          <= (others => '0');

    CNT_TX1_UPPKT_SYMBOL0           <= x"00" & FREQ_OFFSET_FOR_PRACH0(0);
    CNT_TX1_UPPKT_SYMBOL1           <= x"00" & FREQ_OFFSET_FOR_PRACH0(1);
    CNT_TX1_UPPKT_SYMBOL2           <= x"00" & FREQ_OFFSET_FOR_PRACH0(2);
    CNT_TX1_UPPKT_SYMBOL3           <= x"00" & FREQ_OFFSET_FOR_PRACH0(3);
    CNT_TX1_UPPKT_SYMBOL4           <= x"00" & FREQ_OFFSET_FOR_PRACH0(4);
    CNT_TX1_UPPKT_SYMBOL5           <= x"00" & FREQ_OFFSET_FOR_PRACH0(5);
    CNT_TX1_UPPKT_SYMBOL6           <= x"00" & FREQ_OFFSET_FOR_PRACH0(6);
    CNT_TX1_UPPKT_SYMBOL7           <= x"00" & FREQ_OFFSET_FOR_PRACH0(7);
    CNT_TX1_UPPKT_SYMBOL8           <= (others => '0');
    CNT_TX1_UPPKT_SYMBOL9           <= (others => '0');
    CNT_TX1_UPPKT_SYMBOL10          <= (others => '0');
    CNT_TX1_UPPKT_SYMBOL11          <= (others => '0');
    CNT_TX1_UPPKT_SYMBOL12          <= (others => '0');
    CNT_TX1_UPPKT_SYMBOL13          <= (others => '0');

    CNT_TX2_UPPKT_SYMBOL0           <= x"00" & FREQ_OFFSET_FOR_PRACH1(0);
    CNT_TX2_UPPKT_SYMBOL1           <= x"00" & FREQ_OFFSET_FOR_PRACH1(1);
    CNT_TX2_UPPKT_SYMBOL2           <= x"00" & FREQ_OFFSET_FOR_PRACH1(2);
    CNT_TX2_UPPKT_SYMBOL3           <= x"00" & FREQ_OFFSET_FOR_PRACH1(3);
    CNT_TX2_UPPKT_SYMBOL4           <= x"00" & FREQ_OFFSET_FOR_PRACH1(4);
    CNT_TX2_UPPKT_SYMBOL5           <= x"00" & FREQ_OFFSET_FOR_PRACH1(5);
    CNT_TX2_UPPKT_SYMBOL6           <= x"00" & FREQ_OFFSET_FOR_PRACH1(6);
    CNT_TX2_UPPKT_SYMBOL7           <= x"00" & FREQ_OFFSET_FOR_PRACH1(7);
    CNT_TX2_UPPKT_SYMBOL8           <= (others => '0');
    CNT_TX2_UPPKT_SYMBOL9           <= (others => '0');
    CNT_TX2_UPPKT_SYMBOL10          <= (others => '0');
    CNT_TX2_UPPKT_SYMBOL11          <= (others => '0');
    CNT_TX2_UPPKT_SYMBOL12          <= (others => '0');
    CNT_TX2_UPPKT_SYMBOL13          <= (others => '0');


--------------------------------------------------------------------------------
-- Component mapping
--------------------------------------------------------------------------------

    u_RST_PER_PORT : RST_SYNC
    generic map(
        DLY_NUM                     => 4                                       ,--: natural := 4;
        MAX_FANOUT_NUM              => 200                                      --: integer := 200
    )
    port map(
        RST_IN                      => RST                                     ,--: in  std_logic;
        CLK                         => CLK                                     ,--: in  std_logic;
        RST_OUT                     => srst                                     --: out std_logic
    );

    u_SECTION_MANAGER : SECTION_MANAGER
    generic map(
        OFFSET                      => OFFSET                                  ,--: natural := 4;
        MAX_CH                      => MAX_CH                                  ,--: natural := 4;
        MAX_NUM_PORTC               => MAX_NUM_PORTC                           ,--: natural := 4;
        LINK_DIRECTION              => RX_LINK_DIRECTION                       ,--: std_logic := '0';
        USAGE_TYPE0                 => false                                   ,--: boolean := false;
        USAGE_TYPE1                 => true                                    ,--: boolean := true;
        USAGE_TYPE3                 => true                                    ,--: boolean := true;
        USAGE_TYPE5                 => true                                    ,--: boolean := false;
        USAGE_TYPE6                 => false                                   ,--: boolean := false;
        USAGE_TYPE7                 => false                                   ,--: boolean := false;
        PUxCH_CMD_QUEUE_DEPTH       => 512                                     ,--: natural := 512;
        PRACH_CMD_QUEUE_DEPTH       => MAX_CH*32                                --: natural := 32
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => srst                                    ,--: in  std_logic;

        IGNORE_FRAME_ID             => IGNORE_FRAME_ID                         ,--: in  std_logic;
        IGNORE_FRAME_ID_PUxCH_RX    => IGNORE_FRAME_ID_PUxCH_RX                ,--: out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_PUxCH_TX    => IGNORE_FRAME_ID_PUxCH_TX                ,--: out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_PRACH0_RX   => IGNORE_FRAME_ID_PRACH0_RX               ,--: out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_PRACH0_TX   => IGNORE_FRAME_ID_PRACH0_TX               ,--: out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_PRACH1_RX   => IGNORE_FRAME_ID_PRACH1_RX               ,--: out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_PRACH1_TX   => IGNORE_FRAME_ID_PRACH1_TX               ,--: out std_logic_vector(7 downto 0);

        PARAM_ID                    => UL_PARAM_ID                             ,--: in  std_logic_array64_array16(7 downto 0);
        PE_INDEX                    => UL_PE_INDEX                             ,--: in  std_logic_array64_array8(7 downto 0);

        COMP_MODE                   => UL_COMP_MODE                            ,--: in  std_logic_array64(7 downto 0);
        IQ_WIDTH                    => UL_IQ_WIDTH                             ,--: in  std_logic_array64_array4(7 downto 0);
        COMP_METHOD                 => UL_COMP_METHOD                          ,--: in  std_logic_array64_array4(7 downto 0);
        PRB_PER_SYMBOL              => UL_PRB_PER_SYMBOL                       ,--: in  std_logic_array64_array10(7 downto 0);
        PRB_PER_MTU                 => UL_PRB_PER_MTU                          ,--: in  std_logic_array64_array10(7 downto 0);

        FREQ_OFFSET_FOR_PRACH0      => FREQ_OFFSET_FOR_PRACH0(R-1 downto 0)    ,--: in  std_logic_array24(MAX_NUM_PORTC-1 downto 0);
        FREQ_OFFSET_FOR_PRACH1      => FREQ_OFFSET_FOR_PRACH1(R-1 downto 0)    ,--: in  std_logic_array24(MAX_NUM_PORTC-1 downto 0);

        STATUS_TX0_CQ_FSM           => STATUS_TX0_CQ_FSM                       ,--: out std_logic_vector(7 downto 0);
        CNT_TX0_CQ_FSM_TERMINATION  => CNT_TX0_CQ_FSM_BUSY                     ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_CONV_FULL        => CNT_TX0_CQ_CONV_FULL                    ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL0       => CNT_TX0_CPSEC_SYMBOL0                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL1       => CNT_TX0_CPSEC_SYMBOL1                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL2       => CNT_TX0_CPSEC_SYMBOL2                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL3       => CNT_TX0_CPSEC_SYMBOL3                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL4       => CNT_TX0_CPSEC_SYMBOL4                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL5       => CNT_TX0_CPSEC_SYMBOL5                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL6       => CNT_TX0_CPSEC_SYMBOL6                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL7       => CNT_TX0_CPSEC_SYMBOL7                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL8       => CNT_TX0_CPSEC_SYMBOL8                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL9       => CNT_TX0_CPSEC_SYMBOL9                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL10      => CNT_TX0_CPSEC_SYMBOL10                  ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL11      => CNT_TX0_CPSEC_SYMBOL11                  ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL12      => CNT_TX0_CPSEC_SYMBOL12                  ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CPSEC_SYMBOL13      => CNT_TX0_CPSEC_SYMBOL13                  ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL0     => CNT_TX0_CQ_FULL_SYMBOL0                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL1     => CNT_TX0_CQ_FULL_SYMBOL1                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL2     => CNT_TX0_CQ_FULL_SYMBOL2                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL3     => CNT_TX0_CQ_FULL_SYMBOL3                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL4     => CNT_TX0_CQ_FULL_SYMBOL4                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL5     => CNT_TX0_CQ_FULL_SYMBOL5                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL6     => CNT_TX0_CQ_FULL_SYMBOL6                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL7     => CNT_TX0_CQ_FULL_SYMBOL7                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL8     => CNT_TX0_CQ_FULL_SYMBOL8                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL9     => CNT_TX0_CQ_FULL_SYMBOL9                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL10    => CNT_TX0_CQ_FULL_SYMBOL10                ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL11    => CNT_TX0_CQ_FULL_SYMBOL11                ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL12    => CNT_TX0_CQ_FULL_SYMBOL12                ,--: out std_logic_vector(31 downto 0);
        CNT_TX0_CQ_FULL_SYMBOL13    => CNT_TX0_CQ_FULL_SYMBOL13                ,--: out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL0        => USAGE_TX0_CQ_SYMBOL0                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL1        => USAGE_TX0_CQ_SYMBOL1                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL2        => USAGE_TX0_CQ_SYMBOL2                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL3        => USAGE_TX0_CQ_SYMBOL3                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL4        => USAGE_TX0_CQ_SYMBOL4                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL5        => USAGE_TX0_CQ_SYMBOL5                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL6        => USAGE_TX0_CQ_SYMBOL6                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL7        => USAGE_TX0_CQ_SYMBOL7                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL8        => USAGE_TX0_CQ_SYMBOL8                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL9        => USAGE_TX0_CQ_SYMBOL9                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL10       => USAGE_TX0_CQ_SYMBOL10                   ,--: out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL11       => USAGE_TX0_CQ_SYMBOL11                   ,--: out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL12       => USAGE_TX0_CQ_SYMBOL12                   ,--: out std_logic_vector(31 downto 0);
        USAGE_TX0_CQ_SYMBOL13       => USAGE_TX0_CQ_SYMBOL13                   ,--: out std_logic_vector(31 downto 0);

        STATUS_TX1_CQ_FSM           => STATUS_TX1_CQ_FSM                       ,--: out std_logic_vector(7 downto 0);
        CNT_TX1_CQ_FSM_TERMINATION  => CNT_TX1_CQ_FSM_BUSY                     ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_CONV_FULL        => CNT_TX1_CQ_CONV_FULL                    ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL0       => CNT_TX1_CPSEC_SYMBOL0                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL1       => CNT_TX1_CPSEC_SYMBOL1                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL2       => CNT_TX1_CPSEC_SYMBOL2                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL3       => CNT_TX1_CPSEC_SYMBOL3                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL4       => CNT_TX1_CPSEC_SYMBOL4                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL5       => CNT_TX1_CPSEC_SYMBOL5                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL6       => CNT_TX1_CPSEC_SYMBOL6                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL7       => CNT_TX1_CPSEC_SYMBOL7                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL8       => CNT_TX1_CPSEC_SYMBOL8                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL9       => CNT_TX1_CPSEC_SYMBOL9                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL10      => CNT_TX1_CPSEC_SYMBOL10                  ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL11      => CNT_TX1_CPSEC_SYMBOL11                  ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL12      => CNT_TX1_CPSEC_SYMBOL12                  ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CPSEC_SYMBOL13      => CNT_TX1_CPSEC_SYMBOL13                  ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL0     => CNT_TX1_CQ_FULL_SYMBOL0                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL1     => CNT_TX1_CQ_FULL_SYMBOL1                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL2     => CNT_TX1_CQ_FULL_SYMBOL2                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL3     => CNT_TX1_CQ_FULL_SYMBOL3                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL4     => CNT_TX1_CQ_FULL_SYMBOL4                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL5     => CNT_TX1_CQ_FULL_SYMBOL5                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL6     => CNT_TX1_CQ_FULL_SYMBOL6                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL7     => CNT_TX1_CQ_FULL_SYMBOL7                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL8     => CNT_TX1_CQ_FULL_SYMBOL8                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL9     => CNT_TX1_CQ_FULL_SYMBOL9                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL10    => CNT_TX1_CQ_FULL_SYMBOL10                ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL11    => CNT_TX1_CQ_FULL_SYMBOL11                ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL12    => CNT_TX1_CQ_FULL_SYMBOL12                ,--: out std_logic_vector(31 downto 0);
        CNT_TX1_CQ_FULL_SYMBOL13    => CNT_TX1_CQ_FULL_SYMBOL13                ,--: out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL0        => USAGE_TX1_CQ_SYMBOL0                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL1        => USAGE_TX1_CQ_SYMBOL1                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL2        => USAGE_TX1_CQ_SYMBOL2                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL3        => USAGE_TX1_CQ_SYMBOL3                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL4        => USAGE_TX1_CQ_SYMBOL4                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL5        => USAGE_TX1_CQ_SYMBOL5                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL6        => USAGE_TX1_CQ_SYMBOL6                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL7        => USAGE_TX1_CQ_SYMBOL7                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL8        => USAGE_TX1_CQ_SYMBOL8                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL9        => USAGE_TX1_CQ_SYMBOL9                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL10       => USAGE_TX1_CQ_SYMBOL10                   ,--: out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL11       => USAGE_TX1_CQ_SYMBOL11                   ,--: out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL12       => USAGE_TX1_CQ_SYMBOL12                   ,--: out std_logic_vector(31 downto 0);
        USAGE_TX1_CQ_SYMBOL13       => USAGE_TX1_CQ_SYMBOL13                   ,--: out std_logic_vector(31 downto 0);

        STATUS_TX2_CQ_FSM           => STATUS_TX2_CQ_FSM                       ,--: out std_logic_vector(7 downto 0);
        CNT_TX2_CQ_FSM_TERMINATION  => CNT_TX2_CQ_FSM_BUSY                     ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_CONV_FULL        => CNT_TX2_CQ_CONV_FULL                    ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL0       => CNT_TX2_CPSEC_SYMBOL0                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL1       => CNT_TX2_CPSEC_SYMBOL1                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL2       => CNT_TX2_CPSEC_SYMBOL2                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL3       => CNT_TX2_CPSEC_SYMBOL3                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL4       => CNT_TX2_CPSEC_SYMBOL4                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL5       => CNT_TX2_CPSEC_SYMBOL5                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL6       => CNT_TX2_CPSEC_SYMBOL6                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL7       => CNT_TX2_CPSEC_SYMBOL7                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL8       => CNT_TX2_CPSEC_SYMBOL8                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL9       => CNT_TX2_CPSEC_SYMBOL9                   ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL10      => CNT_TX2_CPSEC_SYMBOL10                  ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL11      => CNT_TX2_CPSEC_SYMBOL11                  ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL12      => CNT_TX2_CPSEC_SYMBOL12                  ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CPSEC_SYMBOL13      => CNT_TX2_CPSEC_SYMBOL13                  ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL0     => CNT_TX2_CQ_FULL_SYMBOL0                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL1     => CNT_TX2_CQ_FULL_SYMBOL1                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL2     => CNT_TX2_CQ_FULL_SYMBOL2                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL3     => CNT_TX2_CQ_FULL_SYMBOL3                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL4     => CNT_TX2_CQ_FULL_SYMBOL4                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL5     => CNT_TX2_CQ_FULL_SYMBOL5                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL6     => CNT_TX2_CQ_FULL_SYMBOL6                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL7     => CNT_TX2_CQ_FULL_SYMBOL7                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL8     => CNT_TX2_CQ_FULL_SYMBOL8                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL9     => CNT_TX2_CQ_FULL_SYMBOL9                 ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL10    => CNT_TX2_CQ_FULL_SYMBOL10                ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL11    => CNT_TX2_CQ_FULL_SYMBOL11                ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL12    => CNT_TX2_CQ_FULL_SYMBOL12                ,--: out std_logic_vector(31 downto 0);
        CNT_TX2_CQ_FULL_SYMBOL13    => CNT_TX2_CQ_FULL_SYMBOL13                ,--: out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL0        => USAGE_TX2_CQ_SYMBOL0                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL1        => USAGE_TX2_CQ_SYMBOL1                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL2        => USAGE_TX2_CQ_SYMBOL2                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL3        => USAGE_TX2_CQ_SYMBOL3                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL4        => USAGE_TX2_CQ_SYMBOL4                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL5        => USAGE_TX2_CQ_SYMBOL5                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL6        => USAGE_TX2_CQ_SYMBOL6                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL7        => USAGE_TX2_CQ_SYMBOL7                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL8        => USAGE_TX2_CQ_SYMBOL8                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL9        => USAGE_TX2_CQ_SYMBOL9                    ,--: out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL10       => USAGE_TX2_CQ_SYMBOL10                   ,--: out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL11       => USAGE_TX2_CQ_SYMBOL11                   ,--: out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL12       => USAGE_TX2_CQ_SYMBOL12                   ,--: out std_logic_vector(31 downto 0);
        USAGE_TX2_CQ_SYMBOL13       => USAGE_TX2_CQ_SYMBOL13                   ,--: out std_logic_vector(31 downto 0);

        C_PLANE_VALID               => C_PLANE_VALID                           ,--: in  std_logic;
        C_PLANE_LAST                => C_PLANE_LAST                            ,--: in  std_logic;
        C_PLANE_DATA                => C_PLANE_DATA                            ,--: in  std_logic_vector(31 downto 0);
        C_PLANE_DATA_INDEX          => C_PLANE_DATA_INDEX                      ,--: in  std_logic_vector(2 downto 0);
        C_PLANE_LINK_INDEX          => C_PLANE_LINK_INDEX                      ,--: in  std_logic_vector(3 downto 0);

        ULFE_UPDATE                 => ulfe_update                             ,--: in  std_logic;

        ULFE_FRAME_ID               => ULFE_FRAME_ID                           ,--: in  std_logic_vector(7 downto 0);
        ULFE_SUBFRAME_ID            => ULFE_SUBFRAME_ID                        ,--: in  std_logic_vector(3 downto 0);
        ULFE_SLOT_ID                => ULFE_SLOT_ID                            ,--: in  std_logic_vector(5 downto 0);
        ULFE_SYMBOL_ID              => ULFE_SYMBOL_ID                          ,--: in  std_logic_vector(5 downto 0);

        RAFE0_UPDATE                => rafe0_update                            ,--: in  std_logic;

        RAFE0_FRAME_ID              => RAFE0_FRAME_ID                          ,--: in  std_logic_vector(7 downto 0);
        RAFE0_SUBFRAME_ID           => RAFE0_SUBFRAME_ID                       ,--: in  std_logic_vector(3 downto 0);
        RAFE0_SLOT_ID               => RAFE0_SLOT_ID                           ,--: in  std_logic_vector(5 downto 0);
        RAFE0_SYMBOL_ID             => RAFE0_SYMBOL_ID                         ,--: in  std_logic_vector(5 downto 0);
        RAFE0_ANT_ID                => RAFE0_ANT_ID                            ,--: in  std_logic_vector(2 downto 0);

        RAFE1_UPDATE                => rafe1_update                            ,--: in  std_logic;

        RAFE1_FRAME_ID              => RAFE1_FRAME_ID                          ,--: in  std_logic_vector(7 downto 0);
        RAFE1_SUBFRAME_ID           => RAFE1_SUBFRAME_ID                       ,--: in  std_logic_vector(3 downto 0);
        RAFE1_SLOT_ID               => RAFE1_SLOT_ID                           ,--: in  std_logic_vector(5 downto 0);
        RAFE1_SYMBOL_ID             => RAFE1_SYMBOL_ID                         ,--: in  std_logic_vector(5 downto 0);
        RAFE1_ANT_ID                => RAFE1_ANT_ID                            ,--: in  std_logic_vector(2 downto 0);

        TX0_SECTION_TICK            => tx0_section_tick                        ,--: out std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        TX0_SECTION_LAST            => tx0_section_last                        ,--: out std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        TX0_SECTION_DONE            => tx0_section_done                        ,--: in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        TX0_BANK_OF_PRB             => tx0_bank_of_prb                         ,--: out std_logic_vector(0 downto 0);
        TX0_USE_EVERY_PRB           => tx0_use_every_prb                       ,--: out std_logic;
        TX0_START_OF_PRB            => tx0_start_of_prb                        ,--: out std_logic_vector(9 downto 0);
        TX0_NUMBER_OF_PRB           => tx0_number_of_prb                       ,--: out std_logic_vector(9 downto 0);
        TX0_UD_COMP_HDR             => tx0_ud_comp_hdr                         ,--: out std_logic_vector(8 downto 0);

        TX1_SECTION_TICK            => tx1_section_tick                        ,--: out std_logic;
        TX1_SECTION_LAST            => tx1_section_last                        ,--: out std_logic;
        TX1_SECTION_DONE            => tx1_section_done                        ,--: in  std_logic;
        TX1_BANK_OF_PRB             => tx1_bank_of_prb                         ,--: out std_logic_vector(0 downto 0);
        TX1_USE_EVERY_PRB           => tx1_use_every_prb                       ,--: out std_logic;
        TX1_START_OF_PRB            => tx1_start_of_prb                        ,--: out std_logic_vector(9 downto 0);
        TX1_NUMBER_OF_PRB           => tx1_number_of_prb                       ,--: out std_logic_vector(9 downto 0);
        TX1_UD_COMP_HDR             => tx1_ud_comp_hdr                         ,--: out std_logic_vector(8 downto 0);

        TX2_SECTION_TICK            => tx2_section_tick                        ,--: out std_logic;
        TX2_SECTION_LAST            => tx2_section_last                        ,--: out std_logic;
        TX2_SECTION_DONE            => tx2_section_done                        ,--: in  std_logic;
        TX2_BANK_OF_PRB             => tx2_bank_of_prb                         ,--: out std_logic_vector(0 downto 0);
        TX2_USE_EVERY_PRB           => tx2_use_every_prb                       ,--: out std_logic;
        TX2_START_OF_PRB            => tx2_start_of_prb                        ,--: out std_logic_vector(9 downto 0);
        TX2_NUMBER_OF_PRB           => tx2_number_of_prb                       ,--: out std_logic_vector(9 downto 0);
        TX2_UD_COMP_HDR             => tx2_ud_comp_hdr                         ,--: out std_logic_vector(8 downto 0);

        TX0_INIT                    => tx0_init                                ,--: out std_logic;
        TX0_RB_PATH                 => TX0_RB_PATH                             ,--: out std_logic_vector(2 downto 0);
        TX0_PE_INDEX                => TX0_RB_PE_INDEX                         ,--: out std_logic_vector(2 downto 0);
        TX0_eAxC_ID                 => TX0_RB_eAxC_ID                          ,--: out std_logic_vector(15 downto 0);
        TX0_SEQUENCE_ID             => TX0_RB_SEQUENCE_ID                      ,--: out std_logic_vector(15 downto 0);
        TX0_HEADER_APP              => TX0_RB_HEADER_APP                       ,--: out std_logic_vector(31 downto 0);
        TX0_HEADER_APP_ACK          => TX0_RB_HEADER_APP_ACK                   ,--: in  std_logic;
        TX0_HEADER_SEC              => TX0_RB_HEADER_SEC                       ,--: out std_logic_vector(31 downto 0);
        TX0_HEADER_SEC_ACK          => TX0_RB_HEADER_SEC_ACK                   ,--: in  std_logic;

        TX1_INIT                    => tx1_init                                ,--: out std_logic;
        TX1_RB_PATH                 => TX1_RB_PATH                             ,--: out std_logic_vector(2 downto 0);
        TX1_PE_INDEX                => TX1_RB_PE_INDEX                         ,--: out std_logic_vector(2 downto 0);
        TX1_eAxC_ID                 => TX1_RB_eAxC_ID                          ,--: out std_logic_vector(15 downto 0);
        TX1_SEQUENCE_ID             => TX1_RB_SEQUENCE_ID                      ,--: out std_logic_vector(15 downto 0);
        TX1_HEADER_APP              => TX1_RB_HEADER_APP                       ,--: out std_logic_vector(31 downto 0);
        TX1_HEADER_APP_ACK          => TX1_RB_HEADER_APP_ACK                   ,--: in  std_logic;
        TX1_HEADER_SEC              => TX1_RB_HEADER_SEC                       ,--: out std_logic_vector(31 downto 0);
        TX1_HEADER_SEC_ACK          => TX1_RB_HEADER_SEC_ACK                   ,--: in  std_logic;

        TX2_INIT                    => tx2_init                                ,--: out std_logic;
        TX2_RB_PATH                 => TX2_RB_PATH                             ,--: out std_logic_vector(2 downto 0);
        TX2_PE_INDEX                => TX2_RB_PE_INDEX                         ,--: out std_logic_vector(2 downto 0);
        TX2_eAxC_ID                 => TX2_RB_eAxC_ID                          ,--: out std_logic_vector(15 downto 0);
        TX2_SEQUENCE_ID             => TX2_RB_SEQUENCE_ID                      ,--: out std_logic_vector(15 downto 0);
        TX2_HEADER_APP              => TX2_RB_HEADER_APP                       ,--: out std_logic_vector(31 downto 0);
        TX2_HEADER_APP_ACK          => TX2_RB_HEADER_APP_ACK                   ,--: in  std_logic;
        TX2_HEADER_SEC              => TX2_RB_HEADER_SEC                       ,--: out std_logic_vector(31 downto 0);
        TX2_HEADER_SEC_ACK          => TX2_RB_HEADER_SEC_ACK                    --: in  std_logic;

    );

    u_PUxCH : for i in MAX_NUM_PORTC-1 downto 0 generate
    u_TX_WINDOW_PUxCH : UP_TX_WINDOW
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => tx0_init                                ,--: in  std_logic;

        STATUS_FSM                  => open                                    ,--: out std_logic_vector(5 downto 0);

        SECTION_TICK                => tx0_section_tick(i)                     ,--: in  std_logic;
        SECTION_LAST                => tx0_section_last(i)                     ,--: in  std_logic;
        SECTION_DONE                => tx0_section_done(i)                     ,--: out std_logic;

        BANK_OF_PRB                 => tx0_bank_of_prb                         ,--: in  std_logic_vector(0 downto 0);
        USE_EVERY_PRB               => tx0_use_every_prb                       ,--: in  std_logic;
        START_OF_PRB                => tx0_start_of_prb                        ,--: in  std_logic_vector(9 downto 0);
        NUMBER_OF_PRB               => tx0_number_of_prb                       ,--: in  std_logic_vector(9 downto 0);
        UD_COMP_HDR                 => tx0_ud_comp_hdr                         ,--: in  std_logic_vector(8 downto 0);

        UL_FRAME_ID                 => ULFE_FRAME_ID                           ,--: in  std_logic_vector(7 downto 0);
        UL_SUBFRAME_ID              => ULFE_SUBFRAME_ID                        ,--: in  std_logic_vector(3 downto 0);
        UL_SLOT_ID                  => ULFE_SLOT_ID                            ,--: in  std_logic_vector(5 downto 0);
        UL_SYMBOL_ID                => ULFE_SYMBOL_ID                          ,--: in  std_logic_vector(5 downto 0);
        UL_BANK_ID                  => ULFE_SYMBOL_ID(0 downto 0)              ,--: in  std_logic_vector(0 downto 0);
        UL_START_RE                 => (others => '0')                         ,--: in  std_logic_vector(15 downto 0);

        UL_VALID                    => ULFE_VALID(i)                           ,--: in  std_logic;
        UL_START                    => ULFE_START(i)                           ,--: in  std_logic;
        UL_LAST                     => ULFE_LAST(i)                            ,--: in  std_logic;
        UL_DATA_I                   => ULFE_DATA_I(i)                          ,--: in  std_logic_vector(15 downto 0);
        UL_DATA_Q                   => ULFE_DATA_Q(i)                          ,--: in  std_logic_vector(15 downto 0);

        RB_COMP_HDR                 => puxch_comp_hdr(i)                       ,--: out std_logic_vector(8 downto 0);

        RB_VALID                    => puxch_valid(i)                          ,--: out std_logic;
        RB_TICK                     => puxch_tick(i)                           ,--: out std_logic;
        RB_DATA_I                   => puxch_data_i(i)                         ,--: out std_logic_vector(15 downto 0);
        RB_DATA_Q                   => puxch_data_q(i)                         ,--: out std_logic_vector(15 downto 0);
        RB_USER                     => puxch_user(i)                            --: out std_logic_vector(15 downto 0)
    );
    end generate;

    u_TX_WINDOW_PRACH0 : UP_TX_WINDOW_RACH
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => tx1_init                                ,--: in  std_logic;

        STATUS_FSM                  => open                                    ,--: out std_logic_vector(5 downto 0);

        SECTION_TICK                => tx1_section_tick                        ,--: in  std_logic;
        SECTION_LAST                => tx1_section_last                        ,--: in  std_logic;
        SECTION_DONE                => tx1_section_done                        ,--: out std_logic;

        BANK_OF_PRB                 => tx1_bank_of_prb                         ,--: in  std_logic_vector(0 downto 0);
        USE_EVERY_PRB               => tx1_use_every_prb                       ,--: in  std_logic;
        START_OF_PRB                => tx1_start_of_prb                        ,--: in  std_logic_vector(9 downto 0);
        NUMBER_OF_PRB               => tx1_number_of_prb                       ,--: in  std_logic_vector(9 downto 0);
        UD_COMP_HDR                 => tx1_ud_comp_hdr                         ,--: in  std_logic_vector(8 downto 0);

        UL_FRAME_ID                 => RAFE0_FRAME_ID                          ,--: in  std_logic_vector(7 downto 0);
        UL_SUBFRAME_ID              => RAFE0_SUBFRAME_ID                       ,--: in  std_logic_vector(3 downto 0);
        UL_SLOT_ID                  => RAFE0_SLOT_ID                           ,--: in  std_logic_vector(5 downto 0);
        UL_SYMBOL_ID                => RAFE0_SYMBOL_ID                         ,--: in  std_logic_vector(5 downto 0);
        UL_BANK_ID                  => RAFE0_SYMBOL_ID(0 downto 0)             ,--: in  std_logic_vector(0 downto 0);
        UL_START_RE                 => (others => '0')                         ,--: in  std_logic_vector(15 downto 0);

        UL_VALID                    => RAFE0_VALID                             ,--: in  std_logic;
        UL_START                    => RAFE0_START                             ,--: in  std_logic;
        UL_LAST                     => RAFE0_LAST                              ,--: in  std_logic;
        UL_DATA_I                   => RAFE0_DATA_I                            ,--: in  std_logic_vector(15 downto 0);
        UL_DATA_Q                   => RAFE0_DATA_Q                            ,--: in  std_logic_vector(15 downto 0);

        RB_COMP_HDR                 => prach0_comp_hdr                         ,--: out std_logic_vector(8 downto 0);

        RB_VALID                    => prach0_valid                            ,--: out std_logic;
        RB_TICK                     => prach0_tick                             ,--: out std_logic;
        RB_DATA_I                   => prach0_data_i                           ,--: out std_logic_vector(15 downto 0);
        RB_DATA_Q                   => prach0_data_q                           ,--: out std_logic_vector(15 downto 0);
        RB_USER                     => prach0_user                              --: out std_logic_vector(15 downto 0)
    );

--    u_TX_WINDOW_PRACH1 : UP_TX_WINDOW_RACH
--    port map(
--        CLK                         => CLK                                     ,--: in  std_logic;
--        RST                         => tx2_init                                ,--: in  std_logic;

--        STATUS_FSM                  => open                                    ,--: out std_logic_vector(5 downto 0);

--        SECTION_TICK                => tx2_section_tick                        ,--: in  std_logic;
--        SECTION_LAST                => tx2_section_last                        ,--: in  std_logic;
--        SECTION_DONE                => tx2_section_done                        ,--: out std_logic;

--        BANK_OF_PRB                 => tx2_bank_of_prb                         ,--: in  std_logic_vector(0 downto 0);
--        USE_EVERY_PRB               => tx2_use_every_prb                       ,--: in  std_logic;
--        START_OF_PRB                => tx2_start_of_prb                        ,--: in  std_logic_vector(9 downto 0);
--        NUMBER_OF_PRB               => tx2_number_of_prb                       ,--: in  std_logic_vector(9 downto 0);
--        UD_COMP_HDR                 => tx2_ud_comp_hdr                         ,--: in  std_logic_vector(8 downto 0);

--        UL_FRAME_ID                 => RAFE1_FRAME_ID                          ,--: in  std_logic_vector(7 downto 0);
--        UL_SUBFRAME_ID              => RAFE1_SUBFRAME_ID                       ,--: in  std_logic_vector(3 downto 0);
--        UL_SLOT_ID                  => RAFE1_SLOT_ID                           ,--: in  std_logic_vector(5 downto 0);
--        UL_SYMBOL_ID                => RAFE1_SYMBOL_ID                         ,--: in  std_logic_vector(5 downto 0);
--        UL_BANK_ID                  => RAFE1_SYMBOL_ID(0 downto 0)             ,--: in  std_logic_vector(0 downto 0);
--        UL_START_RE                 => (others => '0')                         ,--: in  std_logic_vector(15 downto 0);

--        UL_VALID                    => RAFE1_VALID                             ,--: in  std_logic;
--        UL_START                    => RAFE1_START                             ,--: in  std_logic;
--        UL_LAST                     => RAFE1_LAST                              ,--: in  std_logic;
--        UL_DATA_I                   => RAFE1_DATA_I                            ,--: in  std_logic_vector(15 downto 0);
--        UL_DATA_Q                   => RAFE1_DATA_Q                            ,--: in  std_logic_vector(15 downto 0);

--        RB_COMP_HDR                 => prach1_comp_hdr                         ,--: out std_logic_vector(8 downto 0);

--        RB_VALID                    => prach1_valid                            ,--: out std_logic;
--        RB_TICK                     => prach1_tick                             ,--: out std_logic;
--        RB_DATA_I                   => prach1_data_i                           ,--: out std_logic_vector(15 downto 0);
--        RB_DATA_Q                   => prach1_data_q                           ,--: out std_logic_vector(15 downto 0);
--        RB_USER                     => prach1_user                              --: out std_logic_vector(15 downto 0)
--    );

end BEHAVE;