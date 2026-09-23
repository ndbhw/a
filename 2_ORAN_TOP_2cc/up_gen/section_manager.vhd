--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : UL Scheduler (O-RAN component)                                --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.15                                                    --
--                                                                            --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use WORK.ARRAY_TYPE.ALL;
use WORK.PKG_ORAN.ALL;
use WORK.PKG_ORAN_ARRAY.ALL;

entity SECTION_MANAGER is
    generic (
        OFFSET                      : natural := 4;
        MAX_CH                      : natural := 4;
        MAX_NUM_PORTC               : natural := 4;
        LINK_DIRECTION              : std_logic := '0';                         -- '0' : Uplink, '1' : Downlink
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
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;
        RST                         : in  std_logic;

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

        PARAM_ID                    : in  std_logic_array64_array16(7 downto 0);
        PE_INDEX                    : in  std_logic_array64_array8(7 downto 0);

        COMP_MODE                   : in  std_logic_array64(7 downto 0);
        IQ_WIDTH                    : in  std_logic_array64_array4(7 downto 0);
        COMP_METHOD                 : in  std_logic_array64_array4(7 downto 0);
        PRB_PER_SYMBOL              : in  std_logic_array64_array10(7 downto 0);
        PRB_PER_MTU                 : in  std_logic_array64_array10(7 downto 0);

        FREQ_OFFSET_FOR_PRACH0      : in  std_logic_array24(MAX_NUM_PORTC-1 downto 0);
        FREQ_OFFSET_FOR_PRACH1      : in  std_logic_array24(MAX_NUM_PORTC-1 downto 0);

--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- C-Plane message
--------------------------------------------------------------------------------

        C_PLANE_VALID               : in  std_logic;
        C_PLANE_LAST                : in  std_logic;
        C_PLANE_DATA                : in  std_logic_vector(31 downto 0);
        C_PLANE_DATA_INDEX          : in  std_logic_vector(2 downto 0);
        C_PLANE_LINK_INDEX          : in  std_logic_vector(3 downto 0);

--------------------------------------------------------------------------------
-- ULFE
--------------------------------------------------------------------------------

        ULFE_UPDATE                 : in  std_logic;

        ULFE_FRAME_ID               : in  std_logic_vector(7 downto 0);
        ULFE_SUBFRAME_ID            : in  std_logic_vector(3 downto 0);
        ULFE_SLOT_ID                : in  std_logic_vector(5 downto 0);
        ULFE_SYMBOL_ID              : in  std_logic_vector(5 downto 0);

--------------------------------------------------------------------------------
-- RAFE0
--------------------------------------------------------------------------------

        RAFE0_UPDATE                : in  std_logic;

        RAFE0_FRAME_ID              : in  std_logic_vector(7 downto 0);
        RAFE0_SUBFRAME_ID           : in  std_logic_vector(3 downto 0);
        RAFE0_SLOT_ID               : in  std_logic_vector(5 downto 0);
        RAFE0_SYMBOL_ID             : in  std_logic_vector(5 downto 0);
        RAFE0_ANT_ID                : in  std_logic_vector(2 downto 0);

--------------------------------------------------------------------------------
-- RAFE1 (Additional FDM or eMTC)
--------------------------------------------------------------------------------

        RAFE1_UPDATE                : in  std_logic;

        RAFE1_FRAME_ID              : in  std_logic_vector(7 downto 0);
        RAFE1_SUBFRAME_ID           : in  std_logic_vector(3 downto 0);
        RAFE1_SLOT_ID               : in  std_logic_vector(5 downto 0);
        RAFE1_SYMBOL_ID             : in  std_logic_vector(5 downto 0);
        RAFE1_ANT_ID                : in  std_logic_vector(2 downto 0);

--------------------------------------------------------------------------------
-- TX window
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- ORAN U-Plane TX
--------------------------------------------------------------------------------

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
end SECTION_MANAGER;

architecture BEHAVE of SECTION_MANAGER is

    constant S                      : natural := OFFSET+MAX_NUM_PORTC-1;
    constant E                      : natural := OFFSET;
    constant UL                     : natural := INDEX_PUxCH;
    constant RA                     : natural := INDEX_PRACH;

--    type num_portc_array            is array(natural range <>) of std_logic_vector(MAX_NUM_PORTC-1 downto 0);
--    type num_band_array             is array(natural range <>) of std_logic_vector(MAX_BAND-1 downto 0);

--    signal split_transmission       : std_logic := '0';

    component CP_DECODER is
    generic (
        USAGE_TYPE0                 : boolean := false;
        USAGE_TYPE1                 : boolean := true;
        USAGE_TYPE3                 : boolean := true;
        USAGE_TYPE5                 : boolean := false;
        USAGE_TYPE6                 : boolean := false;
        USAGE_TYPE7                 : boolean := false
    );
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        C_PLANE_VALID               : in  std_logic;
        C_PLANE_LAST                : in  std_logic;
        C_PLANE_DATA                : in  std_logic_vector(31 downto 0);
        C_PLANE_DATA_INDEX          : in  std_logic_vector(2 downto 0);
        C_PLANE_LINK_INDEX          : in  std_logic_vector(3 downto 0);

        CP_UPDATE                   : out std_logic;

        CP_DATA_ID                  : out std_logic_vector(2 downto 0);
        CP_ANT_ID                   : out std_logic_vector(3 downto 0);
        CP_DATA_DIRECTION           : out std_logic;
        CP_FILTER_INDEX             : out std_logic_vector(3 downto 0);
        CP_FRAME_ID                 : out std_logic_vector(7 downto 0);
        CP_SUBFRAME_ID              : out std_logic_vector(3 downto 0);
        CP_SLOT_ID                  : out std_logic_vector(5 downto 0);
        CP_SYMBOL_ID                : out std_logic_vector(5 downto 0);
        CP_SECTION_TYPE             : out std_logic_vector(7 downto 0);
        CP_UD_COMP_HDR              : out std_logic_vector(7 downto 0);
        CP_SECTION_ID               : out std_logic_vector(11 downto 0);
        CP_RB                       : out std_logic;
        CP_START_PRB                : out std_logic_vector(9 downto 0);
        CP_NUM_PRB                  : out std_logic_vector(7 downto 0);
        CP_NUM_SYMBOL               : out std_logic_vector(3 downto 0);
        CP_BEAMID                   : out std_logic_vector(14 downto 0);
        CP_FREQ_OFFSET              : out std_logic_vector(23 downto 0);
        CP_NUM_PORTC                : out std_logic_vector(5 downto 0)
    );
    end component;

    signal cp_update                : std_logic;
    signal cp_data_id               : std_logic_vector(2 downto 0);
    signal cp_ant_id                : std_logic_vector(3 downto 0);
    signal cp_data_direction        : std_logic;
    signal cp_filter_index          : std_logic_vector(3 downto 0);
    signal cp_frame_id              : std_logic_vector(7 downto 0);
    signal cp_subframe_id           : std_logic_vector(3 downto 0);
    signal cp_slot_id               : std_logic_vector(5 downto 0);
    signal cp_symbol_id             : std_logic_vector(5 downto 0);
    signal cp_section_type          : std_logic_vector(7 downto 0);
    signal cp_ud_comp_hdr           : std_logic_vector(7 downto 0);
    signal cp_section_id            : std_logic_vector(11 downto 0);
    signal cp_rb                    : std_logic;
    signal cp_start_prb             : std_logic_vector(9 downto 0);
    signal cp_num_prb               : std_logic_vector(7 downto 0);
    signal cp_num_symbol            : std_logic_vector(3 downto 0);
--    signal cp_beamid                : std_logic_vector(14 downto 0);
    signal cp_freq_offset           : std_logic_vector(23 downto 0);
    signal cp_num_portc             : std_logic_vector(5 downto 0);

    component CP_TO_SECTION_SYMBOL is
    generic (
        LINK_DIRECTION              : std_logic := '0';
        DATA_ID                     : natural := 0
    );
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        CNT_FIFO_FULL               : out std_logic_vector(31 downto 0);

        CP_UPDATE                   : in  std_logic;

        CP_DATA_ID                  : in  std_logic_vector(2 downto 0);
        CP_ANT_ID                   : in  std_logic_vector(3 downto 0);
        CP_DATA_DIRECTION           : in  std_logic;
        CP_FILTER_INDEX             : in  std_logic_vector(3 downto 0);
        CP_FRAME_ID                 : in  std_logic_vector(7 downto 0);
        CP_SUBFRAME_ID              : in  std_logic_vector(3 downto 0);
        CP_SLOT_ID                  : in  std_logic_vector(5 downto 0);
        CP_SYMBOL_ID                : in  std_logic_vector(5 downto 0);
        CP_SECTION_TYPE             : in  std_logic_vector(7 downto 0);
        CP_UD_COMP_HDR              : in  std_logic_vector(7 downto 0);
        CP_SECTION_ID               : in  std_logic_vector(11 downto 0);
        CP_RB                       : in  std_logic;
        CP_START_PRB                : in  std_logic_vector(9 downto 0);
        CP_NUM_PRB                  : in  std_logic_vector(7 downto 0);
        CP_NUM_SYMBOL               : in  std_logic_vector(3 downto 0);
        CP_FREQ_OFFSET              : in  std_logic_vector(23 downto 0);
        CP_NUM_PORTC                : in  std_logic_vector(5 downto 0);

        CMD_EN                      : out std_logic_vector(13 downto 0);
        CMD                         : out std_logic_vector(71 downto 0)
    );
    end component;

    component CP_TO_SECTION_ANTENNA is
    generic (
        MAX_NUM_PORTC               : natural := 16;
        LINK_DIRECTION              : std_logic := '0';
        DATA_ID                     : natural := 0
    );
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        CNT_FIFO_FULL               : out std_logic_vector(31 downto 0);

        FREQ_OFFSET_FOR_PRACH       : in  std_logic_array24(MAX_NUM_PORTC-1 downto 0);

        CP_UPDATE                   : in  std_logic;

        CP_DATA_ID                  : in  std_logic_vector(2 downto 0);
        CP_ANT_ID                   : in  std_logic_vector(3 downto 0);
        CP_DATA_DIRECTION           : in  std_logic;
        CP_FILTER_INDEX             : in  std_logic_vector(3 downto 0);
        CP_FRAME_ID                 : in  std_logic_vector(7 downto 0);
        CP_SUBFRAME_ID              : in  std_logic_vector(3 downto 0);
        CP_SLOT_ID                  : in  std_logic_vector(5 downto 0);
        CP_SYMBOL_ID                : in  std_logic_vector(5 downto 0);
        CP_SECTION_TYPE             : in  std_logic_vector(7 downto 0);
        CP_UD_COMP_HDR              : in  std_logic_vector(7 downto 0);
        CP_SECTION_ID               : in  std_logic_vector(11 downto 0);
        CP_RB                       : in  std_logic;
        CP_START_PRB                : in  std_logic_vector(9 downto 0);
        CP_NUM_PRB                  : in  std_logic_vector(7 downto 0);
        CP_NUM_SYMBOL               : in  std_logic_vector(3 downto 0);
        CP_FREQ_OFFSET              : in  std_logic_vector(23 downto 0);
        CP_NUM_PORTC                : in  std_logic_vector(5 downto 0);

        CMD_EN                      : out std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        CMD                         : out std_logic_array72(MAX_NUM_PORTC-1 downto 0)
    );
    end component;

    signal cmd_puxch_en             : std_logic_vector(13 downto 0);
    signal cmd_puxch                : std_logic_vector(71 downto 0);
    signal cmd_prach0_en            : std_logic_vector(MAX_NUM_PORTC-1 downto 0);
    signal cmd_prach0               : std_logic_array72(MAX_NUM_PORTC-1 downto 0);
    signal cmd_prach1_en            : std_logic_vector(MAX_NUM_PORTC-1 downto 0);
    signal cmd_prach1               : std_logic_array72(MAX_NUM_PORTC-1 downto 0);

    component SECTION_CMD_QUEUE_SYMBOL is
    generic (
        MAX_NUM_PORTC               : natural := 16;
        LINK_DIRECTION              : std_logic := '0';
        CMD_QUEUE_MEMORY_TYPE       : string := "auto";
        CMD_QUEUE_DEPTH             : integer := 2048
    );
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        IGNORE_FRAME_ID             : in  std_logic;
        IGNORE_FRAME_ID_RX          : out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_TX          : out std_logic_vector(7 downto 0);

        COMP_MODE                   : in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        IQ_WIDTH                    : in  std_logic_array4(MAX_NUM_PORTC-1 downto 0);
        COMP_METHOD                 : in  std_logic_array4(MAX_NUM_PORTC-1 downto 0);
        PRB_PER_SYMBOL              : in  std_logic_array10(MAX_NUM_PORTC-1 downto 0);
        PRB_PER_MTU                 : in  std_logic_vector(9 downto 0);

        CNT_ABNORMAL_TERMINATION    : out std_logic_vector(31 downto 0);

        CNT_SECTION_SYMBOL0         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL1         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL2         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL3         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL4         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL5         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL6         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL7         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL8         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL9         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL10        : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL11        : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL12        : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL13        : out std_logic_vector(31 downto 0);

        CNT_CQ_FULL_SYMBOL0         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL1         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL2         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL3         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL4         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL5         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL6         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL7         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL8         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL9         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL10        : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL11        : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL12        : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL13        : out std_logic_vector(31 downto 0);

        USAGE_CQ_SYMBOL0            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL1            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL2            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL3            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL4            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL5            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL6            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL7            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL8            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL9            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL10           : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL11           : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL12           : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL13           : out std_logic_vector(31 downto 0);

        STATUS_FSM                  : out std_logic_vector(7 downto 0);

        INFO_UPDATE                 : in  std_logic;

        INFO_FRAME_ID               : in  std_logic_vector(7 downto 0);
        INFO_SUBFRAME_ID            : in  std_logic_vector(3 downto 0);
        INFO_SLOT_ID                : in  std_logic_vector(5 downto 0);
        INFO_SYMBOL_ID              : in  std_logic_vector(5 downto 0);

        CMD_EN                      : in  std_logic_vector(13 downto 0);
        CMD                         : in  std_logic_vector(71 downto 0);

        INIT_SESSION                : out std_logic;
        PATH_SEL                    : out std_logic_vector(2 downto 0);

        PACKING_TICK                : out std_logic_vector(MAX_NUM_PORTC-1 downto 0);

        DATA_DIRECTION              : out std_logic;
        PAYLOAD_VERSION             : out std_logic_vector(2 downto 0);
        FILTER_INDEX                : out std_logic_vector(3 downto 0);
        FRAME_ID                    : out std_logic_vector(7 downto 0);
        SUBFRAME_ID                 : out std_logic_vector(3 downto 0);
        SLOT_ID                     : out std_logic_vector(5 downto 0);
        SYMBOL_ID                   : out std_logic_vector(5 downto 0);

        SECTION_TICK                : out std_logic;
        SECTION_TICK_PORT           : out std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        SECTION_LAST                : out std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        SECTION_DONE                : in  std_logic;

        SECTION_ID                  : out std_logic_vector(11 downto 0);
        BANK_OF_PRB                 : out std_logic_vector(0 downto 0);
        USE_EVERY_PRB               : out std_logic;
        START_OF_PRB                : out std_logic_vector(9 downto 0);
        NUMBER_OF_PRB               : out std_logic_vector(9 downto 0);
        UD_COMP_HDR                 : out std_logic_vector(8 downto 0)
    );
    end component;

    component SECTION_CMD_QUEUE_ANTENNA is
    generic (
        MAX_NUM_PORTC               : natural := 16;
        LINK_DIRECTION              : std_logic := '0';
        CMD_QUEUE_MEMORY_TYPE       : string := "auto";
        CMD_QUEUE_DEPTH             : integer := 2048
    );
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        IGNORE_FRAME_ID             : in  std_logic;
        IGNORE_FRAME_ID_RX          : out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_TX          : out std_logic_vector(7 downto 0);

        COMP_MODE                   : in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        IQ_WIDTH                    : in  std_logic_array4(MAX_NUM_PORTC-1 downto 0);
        COMP_METHOD                 : in  std_logic_array4(MAX_NUM_PORTC-1 downto 0);
        PRB_PER_SYMBOL              : in  std_logic_array10(MAX_NUM_PORTC-1 downto 0);
        PRB_PER_MTU                 : in  std_logic_vector(9 downto 0);

        CNT_ABNORMAL_TERMINATION    : out std_logic_vector(31 downto 0);

        CNT_SECTION_SYMBOL0         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL1         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL2         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL3         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL4         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL5         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL6         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL7         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL8         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL9         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL10        : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL11        : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL12        : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL13        : out std_logic_vector(31 downto 0);

        CNT_CQ_FULL_SYMBOL0         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL1         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL2         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL3         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL4         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL5         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL6         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL7         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL8         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL9         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL10        : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL11        : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL12        : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL13        : out std_logic_vector(31 downto 0);

        USAGE_CQ_SYMBOL0            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL1            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL2            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL3            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL4            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL5            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL6            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL7            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL8            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL9            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL10           : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL11           : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL12           : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL13           : out std_logic_vector(31 downto 0);

        STATUS_FSM                  : out std_logic_vector(7 downto 0);

        INFO_UPDATE                 : in  std_logic;

        INFO_FRAME_ID               : in  std_logic_vector(7 downto 0);
        INFO_SUBFRAME_ID            : in  std_logic_vector(3 downto 0);
        INFO_SLOT_ID                : in  std_logic_vector(5 downto 0);
        INFO_SYMBOL_ID              : in  std_logic_vector(5 downto 0);
        INFO_ANT_ID                 : in  std_logic_vector(2 downto 0);

        CMD_EN                      : in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        CMD                         : in  std_logic_array72(MAX_NUM_PORTC-1 downto 0);

        INIT_SESSION                : out std_logic;
        PATH_SEL                    : out std_logic_vector(2 downto 0);

        PACKING_TICK                : out std_logic_vector(MAX_NUM_PORTC-1 downto 0);

        DATA_DIRECTION              : out std_logic;
        PAYLOAD_VERSION             : out std_logic_vector(2 downto 0);
        FILTER_INDEX                : out std_logic_vector(3 downto 0);
        FRAME_ID                    : out std_logic_vector(7 downto 0);
        SUBFRAME_ID                 : out std_logic_vector(3 downto 0);
        SLOT_ID                     : out std_logic_vector(5 downto 0);
        SYMBOL_ID                   : out std_logic_vector(5 downto 0);

        SECTION_TICK                : out std_logic;
        SECTION_LAST                : out std_logic;
        SECTION_DONE                : in  std_logic;

        SECTION_ID                  : out std_logic_vector(11 downto 0);
        BANK_OF_PRB                 : out std_logic_vector(0 downto 0);
        USE_EVERY_PRB               : out std_logic;
        START_OF_PRB                : out std_logic_vector(9 downto 0);
        OFFSET_OF_PRB               : out std_logic_vector(9 downto 0);
        NUMBER_OF_PRB               : out std_logic_vector(9 downto 0);
        UD_COMP_HDR                 : out std_logic_vector(8 downto 0)
    );
    end component;

    signal puxch_init_session       : std_logic;
    signal puxch_path_sel           : std_logic_vector(2 downto 0);
    signal puxch_packing_tick       : std_logic_vector(MAX_NUM_PORTC-1 downto 0);
    signal puxch_data_direction     : std_logic;
    signal puxch_payload_version    : std_logic_vector(2 downto 0);
    signal puxch_filter_index       : std_logic_vector(3 downto 0);
    signal puxch_frame_id           : std_logic_vector(7 downto 0);
    signal puxch_subframe_id        : std_logic_vector(3 downto 0);
    signal puxch_slot_id            : std_logic_vector(5 downto 0);
    signal puxch_symbol_id          : std_logic_vector(5 downto 0);
    signal puxch_section_tick       : std_logic;
    signal puxch_section_tick_port  : std_logic_vector(MAX_NUM_PORTC-1 downto 0);
    signal puxch_section_last       : std_logic_vector(MAX_NUM_PORTC-1 downto 0);
    signal puxch_section_done       : std_logic;
    signal puxch_section_id         : std_logic_vector(11 downto 0);
    signal puxch_bank_of_prb        : std_logic_vector(0 downto 0);
    signal puxch_use_every_prb      : std_logic;
    signal puxch_start_of_prb       : std_logic_vector(9 downto 0);
    signal puxch_number_of_prb      : std_logic_vector(9 downto 0);
    signal puxch_ud_comp_hdr        : std_logic_vector(8 downto 0);

    signal prach0_init_session      : std_logic;
    signal prach0_path_sel          : std_logic_vector(2 downto 0);
    signal prach0_packing_tick      : std_logic_vector(MAX_NUM_PORTC-1 downto 0);
    signal prach0_data_direction    : std_logic;
    signal prach0_payload_version   : std_logic_vector(2 downto 0);
    signal prach0_filter_index      : std_logic_vector(3 downto 0);
    signal prach0_frame_id          : std_logic_vector(7 downto 0);
    signal prach0_subframe_id       : std_logic_vector(3 downto 0);
    signal prach0_slot_id           : std_logic_vector(5 downto 0);
    signal prach0_symbol_id         : std_logic_vector(5 downto 0);
    signal prach0_section_tick      : std_logic;
    signal prach0_section_last      : std_logic;
    signal prach0_section_done      : std_logic;
    signal prach0_section_id        : std_logic_vector(11 downto 0);
    signal prach0_bank_of_prb       : std_logic_vector(0 downto 0);
    signal prach0_use_every_prb     : std_logic;
    signal prach0_start_of_prb      : std_logic_vector(9 downto 0);
    signal prach0_offset_of_prb     : std_logic_vector(9 downto 0);
    signal prach0_number_of_prb     : std_logic_vector(9 downto 0);
    signal prach0_ud_comp_hdr       : std_logic_vector(8 downto 0);

    signal prach1_init_session      : std_logic;
    signal prach1_path_sel          : std_logic_vector(2 downto 0);
    signal prach1_packing_tick      : std_logic_vector(MAX_NUM_PORTC-1 downto 0);
    signal prach1_data_direction    : std_logic;
    signal prach1_payload_version   : std_logic_vector(2 downto 0);
    signal prach1_filter_index      : std_logic_vector(3 downto 0);
    signal prach1_frame_id          : std_logic_vector(7 downto 0);
    signal prach1_subframe_id       : std_logic_vector(3 downto 0);
    signal prach1_slot_id           : std_logic_vector(5 downto 0);
    signal prach1_symbol_id         : std_logic_vector(5 downto 0);
    signal prach1_section_tick      : std_logic;
    signal prach1_section_last      : std_logic;
    signal prach1_section_done      : std_logic;
    signal prach1_section_id        : std_logic_vector(11 downto 0);
    signal prach1_bank_of_prb       : std_logic_vector(0 downto 0);
    signal prach1_use_every_prb     : std_logic;
    signal prach1_start_of_prb      : std_logic_vector(9 downto 0);
    signal prach1_offset_of_prb     : std_logic_vector(9 downto 0);
    signal prach1_number_of_prb     : std_logic_vector(9 downto 0);
    signal prach1_ud_comp_hdr       : std_logic_vector(8 downto 0);

    component UP_HDR_GEN_1BAND is
    generic (
        MAX_NUM_PORTC               : natural := 4
    );
    port (
        CLK                         : in  std_logic;

        PARAM_ID                    : in  std_logic_array16(MAX_NUM_PORTC-1 downto 0);
        PE_INDEX                    : in  std_logic_array8(MAX_NUM_PORTC-1 downto 0);

        BAND0_INIT_SESSION          : in  std_logic;
        BAND0_PATH_SEL              : in  std_logic_vector(2 downto 0);
        BAND0_PACKING_TICK          : in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        BAND0_DATA_DIRECTION        : in  std_logic;
        BAND0_PAYLOAD_VERSION       : in  std_logic_vector(2 downto 0);
        BAND0_FILTER_INDEX          : in  std_logic_vector(3 downto 0);
        BAND0_FRAME_ID              : in  std_logic_vector(7 downto 0);
        BAND0_SUBFRAME_ID           : in  std_logic_vector(3 downto 0);
        BAND0_SLOT_ID               : in  std_logic_vector(5 downto 0);
        BAND0_SYMBOL_ID             : in  std_logic_vector(5 downto 0);
        BAND0_SECTION_TICK          : in  std_logic;
        BAND0_SECTION_ID            : in  std_logic_vector(11 downto 0);
        BAND0_USE_EVERY_PRB         : in  std_logic;
        BAND0_START_OF_PRB          : in  std_logic_vector(9 downto 0);
        BAND0_NUMBER_OF_PRB         : in  std_logic_vector(9 downto 0);

        BAND0_PARAM_INIT_START      : out std_logic;
        BAND0_PARAM_ORAN_START      : out std_logic;
        BAND0_PARAM_ORAN_ACK        : in  std_logic;
        BAND0_PARAM_PATH_SEL        : out std_logic_vector(2 downto 0);
        BAND0_PARAM_ORAN_PE_INDEX   : out std_logic_vector(2 downto 0);
        BAND0_PARAM_ORAN_eAxC_ID    : out std_logic_vector(15 downto 0);
        BAND0_PARAM_ORAN_SEQUENCE_ID: out std_logic_vector(15 downto 0);
        BAND0_PARAM_ORAN_HEADER     : out std_logic_vector(31 downto 0);
        BAND0_PARAM_SECTION_START   : out std_logic;
        BAND0_PARAM_SECTION_ACK     : in  std_logic;
        BAND0_PARAM_SECTION_HEADER  : out std_logic_vector(31 downto 0)
    );
    end component;

    component UP_HDR_GEN_2BAND is
    generic (
        MAX_NUM_PORTC               : natural := 4
    );
    port (
        CLK                         : in  std_logic;

        PARAM_ID                    : in  std_logic_array16(MAX_NUM_PORTC-1 downto 0);
        PE_INDEX                    : in  std_logic_array8(MAX_NUM_PORTC-1 downto 0);

        BAND0_INIT_SESSION          : in  std_logic;
        BAND0_PATH_SEL              : in  std_logic_vector(2 downto 0);
        BAND0_PACKING_TICK          : in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        BAND0_DATA_DIRECTION        : in  std_logic;
        BAND0_PAYLOAD_VERSION       : in  std_logic_vector(2 downto 0);
        BAND0_FILTER_INDEX          : in  std_logic_vector(3 downto 0);
        BAND0_FRAME_ID              : in  std_logic_vector(7 downto 0);
        BAND0_SUBFRAME_ID           : in  std_logic_vector(3 downto 0);
        BAND0_SLOT_ID               : in  std_logic_vector(5 downto 0);
        BAND0_SYMBOL_ID             : in  std_logic_vector(5 downto 0);
        BAND0_SECTION_TICK          : in  std_logic;
        BAND0_SECTION_ID            : in  std_logic_vector(11 downto 0);
        BAND0_USE_EVERY_PRB         : in  std_logic;
        BAND0_START_OF_PRB          : in  std_logic_vector(9 downto 0);
        BAND0_NUMBER_OF_PRB         : in  std_logic_vector(9 downto 0);

        BAND1_INIT_SESSION          : in  std_logic;
        BAND1_PATH_SEL              : in  std_logic_vector(2 downto 0);
        BAND1_PACKING_TICK          : in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        BAND1_DATA_DIRECTION        : in  std_logic;
        BAND1_PAYLOAD_VERSION       : in  std_logic_vector(2 downto 0);
        BAND1_FILTER_INDEX          : in  std_logic_vector(3 downto 0);
        BAND1_FRAME_ID              : in  std_logic_vector(7 downto 0);
        BAND1_SUBFRAME_ID           : in  std_logic_vector(3 downto 0);
        BAND1_SLOT_ID               : in  std_logic_vector(5 downto 0);
        BAND1_SYMBOL_ID             : in  std_logic_vector(5 downto 0);
        BAND1_SECTION_TICK          : in  std_logic;
        BAND1_SECTION_ID            : in  std_logic_vector(11 downto 0);
        BAND1_USE_EVERY_PRB         : in  std_logic;
        BAND1_START_OF_PRB          : in  std_logic_vector(9 downto 0);
        BAND1_NUMBER_OF_PRB         : in  std_logic_vector(9 downto 0);

        BAND0_PARAM_INIT_START      : out std_logic;
        BAND0_PARAM_ORAN_START      : out std_logic;
        BAND0_PARAM_ORAN_ACK        : in  std_logic;
        BAND0_PARAM_PATH_SEL        : out std_logic_vector(2 downto 0);
        BAND0_PARAM_ORAN_PE_INDEX   : out std_logic_vector(2 downto 0);
        BAND0_PARAM_ORAN_eAxC_ID    : out std_logic_vector(15 downto 0);
        BAND0_PARAM_ORAN_SEQUENCE_ID: out std_logic_vector(15 downto 0);
        BAND0_PARAM_ORAN_HEADER     : out std_logic_vector(31 downto 0);
        BAND0_PARAM_SECTION_START   : out std_logic;
        BAND0_PARAM_SECTION_ACK     : in  std_logic;
        BAND0_PARAM_SECTION_HEADER  : out std_logic_vector(31 downto 0);

        BAND1_PARAM_INIT_START      : out std_logic;
        BAND1_PARAM_ORAN_START      : out std_logic;
        BAND1_PARAM_ORAN_ACK        : in  std_logic;
        BAND1_PARAM_PATH_SEL        : out std_logic_vector(2 downto 0);
        BAND1_PARAM_ORAN_PE_INDEX   : out std_logic_vector(2 downto 0);
        BAND1_PARAM_ORAN_eAxC_ID    : out std_logic_vector(15 downto 0);
        BAND1_PARAM_ORAN_SEQUENCE_ID: out std_logic_vector(15 downto 0);
        BAND1_PARAM_ORAN_HEADER     : out std_logic_vector(31 downto 0);
        BAND1_PARAM_SECTION_START   : out std_logic;
        BAND1_PARAM_SECTION_ACK     : in  std_logic;
        BAND1_PARAM_SECTION_HEADER  : out std_logic_vector(31 downto 0)
    );
    end component;

--    component UP_HDR_GEN_3BAND is
--    generic (
--        MAX_NUM_PORTC               : natural := 4
--    );
--    port (
--        CLK                         : in  std_logic;
--
--        PARAM_ID                    : in  std_logic_array16(MAX_NUM_PORTC-1 downto 0);
--        PE_INDEX                    : in  std_logic_array8(MAX_NUM_PORTC-1 downto 0);
--
--        BAND0_INIT_SESSION          : in  std_logic;
--        BAND0_PATH_SEL              : in  std_logic_vector(2 downto 0);
--        BAND0_PACKING_TICK          : in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
--        BAND0_DATA_DIRECTION        : in  std_logic;
--        BAND0_PAYLOAD_VERSION       : in  std_logic_vector(2 downto 0);
--        BAND0_FILTER_INDEX          : in  std_logic_vector(3 downto 0);
--        BAND0_FRAME_ID              : in  std_logic_vector(7 downto 0);
--        BAND0_SUBFRAME_ID           : in  std_logic_vector(3 downto 0);
--        BAND0_SLOT_ID               : in  std_logic_vector(5 downto 0);
--        BAND0_SYMBOL_ID             : in  std_logic_vector(5 downto 0);
--        BAND0_SECTION_TICK          : in  std_logic;
--        BAND0_SECTION_ID            : in  std_logic_vector(11 downto 0);
--        BAND0_USE_EVERY_PRB         : in  std_logic;
--        BAND0_START_OF_PRB          : in  std_logic_vector(9 downto 0);
--        BAND0_NUMBER_OF_PRB         : in  std_logic_vector(9 downto 0);
--
--        BAND1_INIT_SESSION          : in  std_logic;
--        BAND1_PATH_SEL              : in  std_logic_vector(2 downto 0);
--        BAND1_PACKING_TICK          : in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
--        BAND1_DATA_DIRECTION        : in  std_logic;
--        BAND1_PAYLOAD_VERSION       : in  std_logic_vector(2 downto 0);
--        BAND1_FILTER_INDEX          : in  std_logic_vector(3 downto 0);
--        BAND1_FRAME_ID              : in  std_logic_vector(7 downto 0);
--        BAND1_SUBFRAME_ID           : in  std_logic_vector(3 downto 0);
--        BAND1_SLOT_ID               : in  std_logic_vector(5 downto 0);
--        BAND1_SYMBOL_ID             : in  std_logic_vector(5 downto 0);
--        BAND1_SECTION_TICK          : in  std_logic;
--        BAND1_SECTION_ID            : in  std_logic_vector(11 downto 0);
--        BAND1_USE_EVERY_PRB         : in  std_logic;
--        BAND1_START_OF_PRB          : in  std_logic_vector(9 downto 0);
--        BAND1_NUMBER_OF_PRB         : in  std_logic_vector(9 downto 0);
--
--        BAND2_INIT_SESSION          : in  std_logic;
--        BAND2_PATH_SEL              : in  std_logic_vector(2 downto 0);
--        BAND2_PACKING_TICK          : in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
--        BAND2_DATA_DIRECTION        : in  std_logic;
--        BAND2_PAYLOAD_VERSION       : in  std_logic_vector(2 downto 0);
--        BAND2_FILTER_INDEX          : in  std_logic_vector(3 downto 0);
--        BAND2_FRAME_ID              : in  std_logic_vector(7 downto 0);
--        BAND2_SUBFRAME_ID           : in  std_logic_vector(3 downto 0);
--        BAND2_SLOT_ID               : in  std_logic_vector(5 downto 0);
--        BAND2_SYMBOL_ID             : in  std_logic_vector(5 downto 0);
--        BAND2_SECTION_TICK          : in  std_logic;
--        BAND2_SECTION_ID            : in  std_logic_vector(11 downto 0);
--        BAND2_USE_EVERY_PRB         : in  std_logic;
--        BAND2_START_OF_PRB          : in  std_logic_vector(9 downto 0);
--        BAND2_NUMBER_OF_PRB         : in  std_logic_vector(9 downto 0);
--
--        BAND0_PARAM_INIT_START      : out std_logic;
--        BAND0_PARAM_ORAN_START      : out std_logic;
--        BAND0_PARAM_ORAN_ACK        : in  std_logic;
--        BAND0_PARAM_PATH_SEL        : out std_logic_vector(2 downto 0);
--        BAND0_PARAM_ORAN_PE_INDEX   : out std_logic_vector(2 downto 0);
--        BAND0_PARAM_ORAN_eAxC_ID    : out std_logic_vector(15 downto 0);
--        BAND0_PARAM_ORAN_SEQUENCE_ID: out std_logic_vector(15 downto 0);
--        BAND0_PARAM_ORAN_HEADER     : out std_logic_vector(31 downto 0);
--        BAND0_PARAM_SECTION_START   : out std_logic;
--        BAND0_PARAM_SECTION_ACK     : in  std_logic;
--        BAND0_PARAM_SECTION_HEADER  : out std_logic_vector(31 downto 0);
--
--        BAND1_PARAM_INIT_START      : out std_logic;
--        BAND1_PARAM_ORAN_START      : out std_logic;
--        BAND1_PARAM_ORAN_ACK        : in  std_logic;
--        BAND1_PARAM_PATH_SEL        : out std_logic_vector(2 downto 0);
--        BAND1_PARAM_ORAN_PE_INDEX   : out std_logic_vector(2 downto 0);
--        BAND1_PARAM_ORAN_eAxC_ID    : out std_logic_vector(15 downto 0);
--        BAND1_PARAM_ORAN_SEQUENCE_ID: out std_logic_vector(15 downto 0);
--        BAND1_PARAM_ORAN_HEADER     : out std_logic_vector(31 downto 0);
--        BAND1_PARAM_SECTION_START   : out std_logic;
--        BAND1_PARAM_SECTION_ACK     : in  std_logic;
--        BAND1_PARAM_SECTION_HEADER  : out std_logic_vector(31 downto 0);
--
--        BAND2_PARAM_INIT_START      : out std_logic;
--        BAND2_PARAM_ORAN_START      : out std_logic;
--        BAND2_PARAM_ORAN_ACK        : in  std_logic;
--        BAND2_PARAM_PATH_SEL        : out std_logic_vector(2 downto 0);
--        BAND2_PARAM_ORAN_PE_INDEX   : out std_logic_vector(2 downto 0);
--        BAND2_PARAM_ORAN_eAxC_ID    : out std_logic_vector(15 downto 0);
--        BAND2_PARAM_ORAN_SEQUENCE_ID: out std_logic_vector(15 downto 0);
--        BAND2_PARAM_ORAN_HEADER     : out std_logic_vector(31 downto 0);
--        BAND2_PARAM_SECTION_START   : out std_logic;
--        BAND2_PARAM_SECTION_ACK     : in  std_logic;
--        BAND2_PARAM_SECTION_HEADER  : out std_logic_vector(31 downto 0)
--    );
--    end component;

    signal puxch_init_start         : std_logic;
    signal puxch_oran_start         : std_logic;
    signal puxch_oran_ack           : std_logic;
    signal puxch_path               : std_logic_vector(2 downto 0);
    signal puxch_oran_pe_index      : std_logic_vector(2 downto 0);
    signal puxch_oran_eaxc_id       : std_logic_vector(15 downto 0);
    signal puxch_oran_sequence_id   : std_logic_vector(15 downto 0);
    signal puxch_oran_header        : std_logic_vector(31 downto 0);
    signal puxch_section_start      : std_logic;
    signal puxch_section_ack        : std_logic;
    signal puxch_section_header     : std_logic_vector(31 downto 0);

    signal prach0_init_start        : std_logic;
    signal prach0_oran_start        : std_logic;
    signal prach0_oran_ack          : std_logic;
    signal prach0_path              : std_logic_vector(2 downto 0);
    signal prach0_oran_pe_index     : std_logic_vector(2 downto 0);
    signal prach0_oran_eaxc_id      : std_logic_vector(15 downto 0);
    signal prach0_oran_sequence_id  : std_logic_vector(15 downto 0);
    signal prach0_oran_header       : std_logic_vector(31 downto 0);
    signal prach0_section_start     : std_logic;
    signal prach0_section_ack       : std_logic;
    signal prach0_section_header    : std_logic_vector(31 downto 0);

    signal prach1_init_start        : std_logic;
    signal prach1_oran_start        : std_logic;
    signal prach1_oran_ack          : std_logic;
    signal prach1_path              : std_logic_vector(2 downto 0);
    signal prach1_oran_pe_index     : std_logic_vector(2 downto 0);
    signal prach1_oran_eaxc_id      : std_logic_vector(15 downto 0);
    signal prach1_oran_sequence_id  : std_logic_vector(15 downto 0);
    signal prach1_oran_header       : std_logic_vector(31 downto 0);
    signal prach1_section_start     : std_logic;
    signal prach1_section_ack       : std_logic;
    signal prach1_section_header    : std_logic_vector(31 downto 0);

begin

--------------------------------------------------------------------------------
-- C-Plane processing
--------------------------------------------------------------------------------

    u_CP_DECODE : CP_DECODER
    generic map(
        USAGE_TYPE0                 => USAGE_TYPE0                             ,--: boolean := false;
        USAGE_TYPE1                 => USAGE_TYPE1                             ,--: boolean := true;
        USAGE_TYPE3                 => USAGE_TYPE3                             ,--: boolean := true;
        USAGE_TYPE5                 => USAGE_TYPE5                             ,--: boolean := false;
        USAGE_TYPE6                 => USAGE_TYPE6                             ,--: boolean := false;
        USAGE_TYPE7                 => USAGE_TYPE7                              --: boolean := false
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => RST                                     ,--: in  std_logic;

        C_PLANE_VALID               => C_PLANE_VALID                           ,--: in  std_logic;
        C_PLANE_LAST                => C_PLANE_LAST                            ,--: in  std_logic;
        C_PLANE_DATA                => C_PLANE_DATA                            ,--: in  std_logic_vector(31 downto 0);
        C_PLANE_DATA_INDEX          => C_PLANE_DATA_INDEX                      ,--: in  std_logic_vector(2 downto 0);
        C_PLANE_LINK_INDEX          => C_PLANE_LINK_INDEX                      ,--: in  std_logic_vector(3 downto 0);

        CP_UPDATE                   => cp_update                               ,--: out std_logic;

        CP_DATA_ID                  => cp_data_id                              ,--: out std_logic_vector(2 downto 0);
        CP_ANT_ID                   => cp_ant_id                               ,--: out std_logic_vector(3 downto 0);
        CP_DATA_DIRECTION           => cp_data_direction                       ,--: out std_logic;
        CP_FILTER_INDEX             => cp_filter_index                         ,--: out std_logic_vector(3 downto 0);
        CP_FRAME_ID                 => cp_frame_id                             ,--: out std_logic_vector(7 downto 0);
        CP_SUBFRAME_ID              => cp_subframe_id                          ,--: out std_logic_vector(3 downto 0);
        CP_SLOT_ID                  => cp_slot_id                              ,--: out std_logic_vector(5 downto 0);
        CP_SYMBOL_ID                => cp_symbol_id                            ,--: out std_logic_vector(5 downto 0);
        CP_SECTION_TYPE             => cp_section_type                         ,--: out std_logic_vector(7 downto 0);
        CP_UD_COMP_HDR              => cp_ud_comp_hdr                          ,--: out std_logic_vector(7 downto 0);
        CP_SECTION_ID               => cp_section_id                           ,--: out std_logic_vector(11 downto 0);
        CP_RB                       => cp_rb                                   ,--: out std_logic;
        CP_START_PRB                => cp_start_prb                            ,--: out std_logic_vector(9 downto 0);
        CP_NUM_PRB                  => cp_num_prb                              ,--: out std_logic_vector(7 downto 0);
        CP_NUM_SYMBOL               => cp_num_symbol                           ,--: out std_logic_vector(3 downto 0);
        CP_BEAMID                   => open                                    ,--: out std_logic_vector(14 downto 0);
        CP_FREQ_OFFSET              => cp_freq_offset                          ,--: out std_logic_vector(23 downto 0);
        CP_NUM_PORTC                => cp_num_portc                             --: out std_logic_vector(5 downto 0)
    );

    u_CP_TO_SECTION_TX0 : CP_TO_SECTION_SYMBOL
    generic map(
        LINK_DIRECTION              => LINK_DIRECTION                          ,--: std_logic := '0';
        DATA_ID                     => INDEX_PUxCH                              --: natural := 0
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => RST                                     ,--: in  std_logic;

        CNT_FIFO_FULL               => CNT_TX0_CQ_CONV_FULL                    ,--: out std_logic_vector(31 downto 0);

        CP_UPDATE                   => cp_update                               ,--: in  std_logic;

        CP_DATA_ID                  => cp_data_id                              ,--: in  std_logic_vector(2 downto 0);
        CP_ANT_ID                   => cp_ant_id                               ,--: in  std_logic_vector(3 downto 0);
        CP_DATA_DIRECTION           => cp_data_direction                       ,--: in  std_logic;
        CP_FILTER_INDEX             => cp_filter_index                         ,--: in  std_logic_vector(3 downto 0);
        CP_FRAME_ID                 => cp_frame_id                             ,--: in  std_logic_vector(7 downto 0);
        CP_SUBFRAME_ID              => cp_subframe_id                          ,--: in  std_logic_vector(3 downto 0);
        CP_SLOT_ID                  => cp_slot_id                              ,--: in  std_logic_vector(5 downto 0);
        CP_SYMBOL_ID                => cp_symbol_id                            ,--: in  std_logic_vector(5 downto 0);
        CP_SECTION_TYPE             => cp_section_type                         ,--: in  std_logic_vector(7 downto 0);
        CP_UD_COMP_HDR              => cp_ud_comp_hdr                          ,--: in  std_logic_vector(7 downto 0);
        CP_SECTION_ID               => cp_section_id                           ,--: in  std_logic_vector(11 downto 0);
        CP_RB                       => cp_rb                                   ,--: in  std_logic;
        CP_START_PRB                => cp_start_prb                            ,--: in  std_logic_vector(9 downto 0);
        CP_NUM_PRB                  => cp_num_prb                              ,--: in  std_logic_vector(7 downto 0);
        CP_NUM_SYMBOL               => cp_num_symbol                           ,--: in  std_logic_vector(3 downto 0);
        CP_FREQ_OFFSET              => cp_freq_offset                          ,--: in  std_logic_vector(23 downto 0);
        CP_NUM_PORTC                => cp_num_portc                            ,--: in  std_logic_vector(5 downto 0);

        CMD_EN                      => cmd_puxch_en                            ,--: out std_logic_vector(13 downto 0);
        CMD                         => cmd_puxch                                --: out std_logic_vector(71 downto 0)
    );

    u_CP_TO_SECTION_TX1 : CP_TO_SECTION_ANTENNA
    generic map(
        MAX_NUM_PORTC               => MAX_NUM_PORTC                           ,--: natural := 16;
        LINK_DIRECTION              => LINK_DIRECTION                          ,--: std_logic := '0';
        DATA_ID                     => INDEX_PRACH                              --: natural := 0
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => RST                                     ,--: in  std_logic;

        CNT_FIFO_FULL               => CNT_TX1_CQ_CONV_FULL                    ,--: out std_logic_vector(31 downto 0);

        FREQ_OFFSET_FOR_PRACH       => FREQ_OFFSET_FOR_PRACH0                  ,--: in  std_logic_array24(MAX_NUM_PORTC-1 downto 0);

        CP_UPDATE                   => cp_update                               ,--: in  std_logic;

        CP_DATA_ID                  => cp_data_id                              ,--: in  std_logic_vector(2 downto 0);
        CP_ANT_ID                   => cp_ant_id                               ,--: in  std_logic_vector(3 downto 0);
        CP_DATA_DIRECTION           => cp_data_direction                       ,--: in  std_logic;
        CP_FILTER_INDEX             => cp_filter_index                         ,--: in  std_logic_vector(3 downto 0);
        CP_FRAME_ID                 => cp_frame_id                             ,--: in  std_logic_vector(7 downto 0);
        CP_SUBFRAME_ID              => cp_subframe_id                          ,--: in  std_logic_vector(3 downto 0);
        CP_SLOT_ID                  => cp_slot_id                              ,--: in  std_logic_vector(5 downto 0);
        CP_SYMBOL_ID                => cp_symbol_id                            ,--: in  std_logic_vector(5 downto 0);
        CP_SECTION_TYPE             => cp_section_type                         ,--: in  std_logic_vector(7 downto 0);
        CP_UD_COMP_HDR              => cp_ud_comp_hdr                          ,--: in  std_logic_vector(7 downto 0);
        CP_SECTION_ID               => cp_section_id                           ,--: in  std_logic_vector(11 downto 0);
        CP_RB                       => cp_rb                                   ,--: in  std_logic;
        CP_START_PRB                => cp_start_prb                            ,--: in  std_logic_vector(9 downto 0);
        CP_NUM_PRB                  => cp_num_prb                              ,--: in  std_logic_vector(7 downto 0);
        CP_NUM_SYMBOL               => cp_num_symbol                           ,--: in  std_logic_vector(3 downto 0);
        CP_FREQ_OFFSET              => cp_freq_offset                          ,--: in  std_logic_vector(23 downto 0);
        CP_NUM_PORTC                => cp_num_portc                            ,--: in  std_logic_vector(5 downto 0);

        CMD_EN                      => cmd_prach0_en                           ,--: out std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        CMD                         => cmd_prach0                               --: out std_logic_array72(MAX_NUM_PORTC-1 downto 0)
    );

--    u_CP_TO_SECTION_TX2 : CP_TO_SECTION_ANTENNA
--    generic map(
--        MAX_NUM_PORTC               => MAX_NUM_PORTC                           ,--: natural := 16;
--        LINK_DIRECTION              => LINK_DIRECTION                          ,--: std_logic := '0';
--        DATA_ID                     => INDEX_PRACH                              --: natural := 0
--    )
--    port map(
--        CLK                         => CLK                                     ,--: in  std_logic;
--        RST                         => RST                                     ,--: in  std_logic;

--        CNT_FIFO_FULL               => CNT_TX2_CQ_CONV_FULL                    ,--: out std_logic_vector(31 downto 0);

--        FREQ_OFFSET_FOR_PRACH       => FREQ_OFFSET_FOR_PRACH1                  ,--: in  std_logic_array24(MAX_NUM_PORTC-1 downto 0);

--        CP_UPDATE                   => cp_update                               ,--: in  std_logic;

--        CP_DATA_ID                  => cp_data_id                              ,--: in  std_logic_vector(2 downto 0);
--        CP_ANT_ID                   => cp_ant_id                               ,--: in  std_logic_vector(3 downto 0);
--        CP_DATA_DIRECTION           => cp_data_direction                       ,--: in  std_logic;
--        CP_FILTER_INDEX             => cp_filter_index                         ,--: in  std_logic_vector(3 downto 0);
--        CP_FRAME_ID                 => cp_frame_id                             ,--: in  std_logic_vector(7 downto 0);
--        CP_SUBFRAME_ID              => cp_subframe_id                          ,--: in  std_logic_vector(3 downto 0);
--        CP_SLOT_ID                  => cp_slot_id                              ,--: in  std_logic_vector(5 downto 0);
--        CP_SYMBOL_ID                => cp_symbol_id                            ,--: in  std_logic_vector(5 downto 0);
--        CP_SECTION_TYPE             => cp_section_type                         ,--: in  std_logic_vector(7 downto 0);
--        CP_UD_COMP_HDR              => cp_ud_comp_hdr                          ,--: in  std_logic_vector(7 downto 0);
--        CP_SECTION_ID               => cp_section_id                           ,--: in  std_logic_vector(11 downto 0);
--        CP_RB                       => cp_rb                                   ,--: in  std_logic;
--        CP_START_PRB                => cp_start_prb                            ,--: in  std_logic_vector(9 downto 0);
--        CP_NUM_PRB                  => cp_num_prb                              ,--: in  std_logic_vector(7 downto 0);
--        CP_NUM_SYMBOL               => cp_num_symbol                           ,--: in  std_logic_vector(3 downto 0);
--        CP_FREQ_OFFSET              => cp_freq_offset                          ,--: in  std_logic_vector(23 downto 0);
--        CP_NUM_PORTC                => cp_num_portc                            ,--: in  std_logic_vector(5 downto 0);

--        CMD_EN                      => cmd_prach1_en                           ,--: out std_logic_vector(MAX_NUM_PORTC-1 downto 0);
--        CMD                         => cmd_prach1                               --: out std_logic_array72(MAX_NUM_PORTC-1 downto 0)
--    );

--------------------------------------------------------------------------------
-- Section command queue (PUxCH)
--------------------------------------------------------------------------------

    u_CQ_PUxCH : SECTION_CMD_QUEUE_SYMBOL
    generic map(
        MAX_NUM_PORTC               => MAX_NUM_PORTC                           ,--: natural := 16;
        LINK_DIRECTION              => LINK_DIRECTION                          ,--: std_logic := '0';
        CMD_QUEUE_MEMORY_TYPE       => "block"                                 ,--: string := "auto";
        CMD_QUEUE_DEPTH             => PUxCH_CMD_QUEUE_DEPTH                    --: integer := 2048
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => RST                                     ,--: in  std_logic;

        IGNORE_FRAME_ID             => IGNORE_FRAME_ID                         ,--: in  std_logic;
        IGNORE_FRAME_ID_RX          => IGNORE_FRAME_ID_PUxCH_RX                ,--: out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_TX          => IGNORE_FRAME_ID_PUxCH_TX                ,--: out std_logic_vector(7 downto 0);

        COMP_MODE                   => COMP_MODE(UL)(S downto E)               ,--: in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        IQ_WIDTH                    => IQ_WIDTH(UL)(S downto E)                ,--: in  std_logic_array4(MAX_NUM_PORTC-1 downto 0);
        COMP_METHOD                 => COMP_METHOD(UL)(S downto E)             ,--: in  std_logic_array4(MAX_NUM_PORTC-1 downto 0);
        PRB_PER_SYMBOL              => PRB_PER_SYMBOL(UL)(S downto E)          ,--: in  std_logic_array10(MAX_NUM_PORTC-1 downto 0);
        PRB_PER_MTU                 => PRB_PER_MTU(UL)(E)                      ,--: in  std_logic_vector(9 downto 0);

        CNT_ABNORMAL_TERMINATION    => CNT_TX0_CQ_FSM_TERMINATION              ,--: out std_logic_vector(31 downto 0);

        CNT_SECTION_SYMBOL0         => CNT_TX0_CPSEC_SYMBOL0                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL1         => CNT_TX0_CPSEC_SYMBOL1                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL2         => CNT_TX0_CPSEC_SYMBOL2                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL3         => CNT_TX0_CPSEC_SYMBOL3                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL4         => CNT_TX0_CPSEC_SYMBOL4                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL5         => CNT_TX0_CPSEC_SYMBOL5                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL6         => CNT_TX0_CPSEC_SYMBOL6                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL7         => CNT_TX0_CPSEC_SYMBOL7                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL8         => CNT_TX0_CPSEC_SYMBOL8                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL9         => CNT_TX0_CPSEC_SYMBOL9                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL10        => CNT_TX0_CPSEC_SYMBOL10                  ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL11        => CNT_TX0_CPSEC_SYMBOL11                  ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL12        => CNT_TX0_CPSEC_SYMBOL12                  ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL13        => CNT_TX0_CPSEC_SYMBOL13                  ,--: out std_logic_vector(31 downto 0);

        CNT_CQ_FULL_SYMBOL0         => CNT_TX0_CQ_FULL_SYMBOL0                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL1         => CNT_TX0_CQ_FULL_SYMBOL1                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL2         => CNT_TX0_CQ_FULL_SYMBOL2                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL3         => CNT_TX0_CQ_FULL_SYMBOL3                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL4         => CNT_TX0_CQ_FULL_SYMBOL4                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL5         => CNT_TX0_CQ_FULL_SYMBOL5                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL6         => CNT_TX0_CQ_FULL_SYMBOL6                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL7         => CNT_TX0_CQ_FULL_SYMBOL7                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL8         => CNT_TX0_CQ_FULL_SYMBOL8                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL9         => CNT_TX0_CQ_FULL_SYMBOL9                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL10        => CNT_TX0_CQ_FULL_SYMBOL10                ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL11        => CNT_TX0_CQ_FULL_SYMBOL11                ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL12        => CNT_TX0_CQ_FULL_SYMBOL12                ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL13        => CNT_TX0_CQ_FULL_SYMBOL13                ,--: out std_logic_vector(31 downto 0);

        USAGE_CQ_SYMBOL0            => USAGE_TX0_CQ_SYMBOL0                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL1            => USAGE_TX0_CQ_SYMBOL1                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL2            => USAGE_TX0_CQ_SYMBOL2                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL3            => USAGE_TX0_CQ_SYMBOL3                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL4            => USAGE_TX0_CQ_SYMBOL4                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL5            => USAGE_TX0_CQ_SYMBOL5                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL6            => USAGE_TX0_CQ_SYMBOL6                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL7            => USAGE_TX0_CQ_SYMBOL7                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL8            => USAGE_TX0_CQ_SYMBOL8                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL9            => USAGE_TX0_CQ_SYMBOL9                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL10           => USAGE_TX0_CQ_SYMBOL10                   ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL11           => USAGE_TX0_CQ_SYMBOL11                   ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL12           => USAGE_TX0_CQ_SYMBOL12                   ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL13           => USAGE_TX0_CQ_SYMBOL13                   ,--: out std_logic_vector(31 downto 0);

        STATUS_FSM                  => STATUS_TX0_CQ_FSM                        ,--: out std_logic_vector(7 downto 0);

        INFO_UPDATE                 => ULFE_UPDATE                             ,--: in  std_logic;

        INFO_FRAME_ID               => ULFE_FRAME_ID                           ,--: in  std_logic_vector(7 downto 0);
        INFO_SUBFRAME_ID            => ULFE_SUBFRAME_ID                        ,--: in  std_logic_vector(3 downto 0);
        INFO_SLOT_ID                => ULFE_SLOT_ID                            ,--: in  std_logic_vector(5 downto 0);
        INFO_SYMBOL_ID              => ULFE_SYMBOL_ID                          ,--: in  std_logic_vector(5 downto 0);

        CMD_EN                      => cmd_puxch_en                            ,--: in  std_logic_vector(13 downto 0);
        CMD                         => cmd_puxch                               ,--: in  std_logic_vector(71 downto 0);

        INIT_SESSION                => puxch_init_session                      ,--: out std_logic_vector(MAX_NUM_PORTC/MAX_CH-1 downto 0);
        PATH_SEL                    => puxch_path_sel                          ,--: out std_logic_vector(2 downto 0);

        PACKING_TICK                => puxch_packing_tick                      ,--: out std_logic_vector(MAX_NUM_PORTC-1 downto 0);

        DATA_DIRECTION              => puxch_data_direction                    ,--: out std_logic;
        PAYLOAD_VERSION             => puxch_payload_version                   ,--: out std_logic_vector(2 downto 0);
        FILTER_INDEX                => puxch_filter_index                      ,--: out std_logic_vector(3 downto 0);
        FRAME_ID                    => puxch_frame_id                          ,--: out std_logic_vector(7 downto 0);
        SUBFRAME_ID                 => puxch_subframe_id                       ,--: out std_logic_vector(3 downto 0);
        SLOT_ID                     => puxch_slot_id                           ,--: out std_logic_vector(5 downto 0);
        SYMBOL_ID                   => puxch_symbol_id                         ,--: out std_logic_vector(5 downto 0);

        SECTION_TICK                => puxch_section_tick                      ,--: out std_logic;
        SECTION_TICK_PORT           => puxch_section_tick_port                 ,--: out std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        SECTION_LAST                => puxch_section_last                      ,--: out std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        SECTION_DONE                => puxch_section_done                      ,--: in  std_logic;

        SECTION_ID                  => puxch_section_id                        ,--: out std_logic_vector(11 downto 0);
        BANK_OF_PRB                 => puxch_bank_of_prb                       ,--: out std_logic_vector(0 downto 0);
        USE_EVERY_PRB               => puxch_use_every_prb                     ,--: out std_logic;
        START_OF_PRB                => puxch_start_of_prb                      ,--: out std_logic_vector(9 downto 0);
        NUMBER_OF_PRB               => puxch_number_of_prb                     ,--: out std_logic_vector(9 downto 0);
        UD_COMP_HDR                 => puxch_ud_comp_hdr                        --: out std_logic_vector(8 downto 0)
    );

    u_HDR_PUxCH : UP_HDR_GEN_1BAND
    generic map(
        MAX_NUM_PORTC               => MAX_NUM_PORTC                            --: natural := 4
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;

        PARAM_ID                    => PARAM_ID(UL)(S downto E)                ,--: in  std_logic_array16(MAX_NUM_PORTC-1 downto 0);
        PE_INDEX                    => PE_INDEX(UL)(S downto E)                ,--: in  std_logic_array8(MAX_NUM_PORTC-1 downto 0);

        BAND0_INIT_SESSION          => puxch_init_session                      ,--: in  std_logic;
        BAND0_PATH_SEL              => puxch_path_sel                          ,--: in  std_logic_vector(2 downto 0);
        BAND0_PACKING_TICK          => puxch_packing_tick                      ,--: in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        BAND0_DATA_DIRECTION        => puxch_data_direction                    ,--: in  std_logic;
        BAND0_PAYLOAD_VERSION       => puxch_payload_version                   ,--: in  std_logic_vector(2 downto 0);
        BAND0_FILTER_INDEX          => puxch_filter_index                      ,--: in  std_logic_vector(3 downto 0);
        BAND0_FRAME_ID              => puxch_frame_id                          ,--: in  std_logic_vector(7 downto 0);
        BAND0_SUBFRAME_ID           => puxch_subframe_id                       ,--: in  std_logic_vector(3 downto 0);
        BAND0_SLOT_ID               => puxch_slot_id                           ,--: in  std_logic_vector(5 downto 0);
        BAND0_SYMBOL_ID             => puxch_symbol_id                         ,--: in  std_logic_vector(5 downto 0);
        BAND0_SECTION_TICK          => puxch_section_tick                      ,--: in  std_logic;
        BAND0_SECTION_ID            => puxch_section_id                        ,--: in  std_logic_vector(11 downto 0);
        BAND0_USE_EVERY_PRB         => puxch_use_every_prb                     ,--: in  std_logic;
        BAND0_START_OF_PRB          => puxch_start_of_prb                      ,--: in  std_logic_vector(9 downto 0);
        BAND0_NUMBER_OF_PRB         => puxch_number_of_prb                     ,--: in  std_logic_vector(9 downto 0);

        BAND0_PARAM_INIT_START      => puxch_init_start                        ,--: out std_logic;
        BAND0_PARAM_ORAN_START      => puxch_oran_start                        ,--: out std_logic;
        BAND0_PARAM_ORAN_ACK        => puxch_oran_ack                          ,--: in  std_logic;
        BAND0_PARAM_PATH_SEL        => puxch_path                              ,--: out std_logic_vector(2 downto 0);
        BAND0_PARAM_ORAN_PE_INDEX   => puxch_oran_pe_index                     ,--: out std_logic_vector(2 downto 0);
        BAND0_PARAM_ORAN_eAxC_ID    => puxch_oran_eaxc_id                      ,--: out std_logic_vector(15 downto 0);
        BAND0_PARAM_ORAN_SEQUENCE_ID=> puxch_oran_sequence_id                  ,--: out std_logic_vector(15 downto 0);
        BAND0_PARAM_ORAN_HEADER     => puxch_oran_header                       ,--: out std_logic_vector(31 downto 0);
        BAND0_PARAM_SECTION_START   => puxch_section_start                     ,--: out std_logic;
        BAND0_PARAM_SECTION_ACK     => puxch_section_ack                       ,--: in  std_logic;
        BAND0_PARAM_SECTION_HEADER  => puxch_section_header                     --: out std_logic_vector(31 downto 0)
    );

--------------------------------------------------------------------------------
-- Section command queue (PRACH)
--------------------------------------------------------------------------------

    u_CQ_PRACH0 : SECTION_CMD_QUEUE_ANTENNA
    generic map(
        MAX_NUM_PORTC               => MAX_NUM_PORTC                           ,--: natural := 16;
        LINK_DIRECTION              => LINK_DIRECTION                          ,--: std_logic := '0';
        CMD_QUEUE_MEMORY_TYPE       => "block"                                 ,--: string := "auto";
        CMD_QUEUE_DEPTH             => PRACH_CMD_QUEUE_DEPTH                    --: integer := 2048
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => RST                                     ,--: in  std_logic;

        IGNORE_FRAME_ID             => IGNORE_FRAME_ID                         ,--: in  std_logic;
        IGNORE_FRAME_ID_RX          => IGNORE_FRAME_ID_PRACH0_RX               ,--: out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_TX          => IGNORE_FRAME_ID_PRACH0_TX               ,--: out std_logic_vector(7 downto 0);

        COMP_MODE                   => COMP_MODE(RA)(S downto E)               ,--: in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        IQ_WIDTH                    => IQ_WIDTH(RA)(S downto E)                ,--: in  std_logic_array4(MAX_NUM_PORTC-1 downto 0);
        COMP_METHOD                 => COMP_METHOD(RA)(S downto E)             ,--: in  std_logic_array4(MAX_NUM_PORTC-1 downto 0);
        PRB_PER_SYMBOL              => PRB_PER_SYMBOL(RA)(S downto E)          ,--: in  std_logic_array10(MAX_NUM_PORTC-1 downto 0);
        PRB_PER_MTU                 => PRB_PER_MTU(RA)(E)                      ,--: in  std_logic_vector(9 downto 0);

        CNT_ABNORMAL_TERMINATION    => CNT_TX1_CQ_FSM_TERMINATION              ,--: out std_logic_vector(31 downto 0);

        CNT_SECTION_SYMBOL0         => CNT_TX1_CPSEC_SYMBOL0                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL1         => CNT_TX1_CPSEC_SYMBOL1                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL2         => CNT_TX1_CPSEC_SYMBOL2                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL3         => CNT_TX1_CPSEC_SYMBOL3                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL4         => CNT_TX1_CPSEC_SYMBOL4                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL5         => CNT_TX1_CPSEC_SYMBOL5                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL6         => CNT_TX1_CPSEC_SYMBOL6                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL7         => CNT_TX1_CPSEC_SYMBOL7                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL8         => CNT_TX1_CPSEC_SYMBOL8                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL9         => CNT_TX1_CPSEC_SYMBOL9                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL10        => CNT_TX1_CPSEC_SYMBOL10                  ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL11        => CNT_TX1_CPSEC_SYMBOL11                  ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL12        => CNT_TX1_CPSEC_SYMBOL12                  ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL13        => CNT_TX1_CPSEC_SYMBOL13                  ,--: out std_logic_vector(31 downto 0);

        CNT_CQ_FULL_SYMBOL0         => CNT_TX1_CQ_FULL_SYMBOL0                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL1         => CNT_TX1_CQ_FULL_SYMBOL1                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL2         => CNT_TX1_CQ_FULL_SYMBOL2                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL3         => CNT_TX1_CQ_FULL_SYMBOL3                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL4         => CNT_TX1_CQ_FULL_SYMBOL4                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL5         => CNT_TX1_CQ_FULL_SYMBOL5                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL6         => CNT_TX1_CQ_FULL_SYMBOL6                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL7         => CNT_TX1_CQ_FULL_SYMBOL7                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL8         => CNT_TX1_CQ_FULL_SYMBOL8                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL9         => CNT_TX1_CQ_FULL_SYMBOL9                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL10        => CNT_TX1_CQ_FULL_SYMBOL10                ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL11        => CNT_TX1_CQ_FULL_SYMBOL11                ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL12        => CNT_TX1_CQ_FULL_SYMBOL12                ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL13        => CNT_TX1_CQ_FULL_SYMBOL13                ,--: out std_logic_vector(31 downto 0);

        USAGE_CQ_SYMBOL0            => USAGE_TX1_CQ_SYMBOL0                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL1            => USAGE_TX1_CQ_SYMBOL1                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL2            => USAGE_TX1_CQ_SYMBOL2                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL3            => USAGE_TX1_CQ_SYMBOL3                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL4            => USAGE_TX1_CQ_SYMBOL4                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL5            => USAGE_TX1_CQ_SYMBOL5                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL6            => USAGE_TX1_CQ_SYMBOL6                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL7            => USAGE_TX1_CQ_SYMBOL7                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL8            => USAGE_TX1_CQ_SYMBOL8                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL9            => USAGE_TX1_CQ_SYMBOL9                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL10           => USAGE_TX1_CQ_SYMBOL10                   ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL11           => USAGE_TX1_CQ_SYMBOL11                   ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL12           => USAGE_TX1_CQ_SYMBOL12                   ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL13           => USAGE_TX1_CQ_SYMBOL13                   ,--: out std_logic_vector(31 downto 0);

        STATUS_FSM                  => STATUS_TX1_CQ_FSM                        ,--: out std_logic_vector(7 downto 0);

        INFO_UPDATE                 => RAFE0_UPDATE                            ,--: in  std_logic;

        INFO_FRAME_ID               => RAFE0_FRAME_ID                          ,--: in  std_logic_vector(7 downto 0);
        INFO_SUBFRAME_ID            => RAFE0_SUBFRAME_ID                       ,--: in  std_logic_vector(3 downto 0);
        INFO_SLOT_ID                => RAFE0_SLOT_ID                           ,--: in  std_logic_vector(5 downto 0);
        INFO_SYMBOL_ID              => RAFE0_SYMBOL_ID                         ,--: in  std_logic_vector(5 downto 0);
        INFO_ANT_ID                 => RAFE0_ANT_ID                            ,--: in  std_logic_vector(2 downto 0);

        CMD_EN                      => cmd_prach0_en                           ,--: in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        CMD                         => cmd_prach0                              ,--: in  std_logic_array72(MAX_NUM_PORTC-1 downto 0);

        INIT_SESSION                => prach0_init_session                     ,--: out std_logic;
        PATH_SEL                    => prach0_path_sel                         ,--: out std_logic_vector(2 downto 0);

        PACKING_TICK                => prach0_packing_tick                     ,--: out std_logic_vector(MAX_NUM_PORTC-1 downto 0);

        DATA_DIRECTION              => prach0_data_direction                   ,--: out std_logic;
        PAYLOAD_VERSION             => prach0_payload_version                  ,--: out std_logic_vector(2 downto 0);
        FILTER_INDEX                => prach0_filter_index                     ,--: out std_logic_vector(3 downto 0);
        FRAME_ID                    => prach0_frame_id                         ,--: out std_logic_vector(7 downto 0);
        SUBFRAME_ID                 => prach0_subframe_id                      ,--: out std_logic_vector(3 downto 0);
        SLOT_ID                     => prach0_slot_id                          ,--: out std_logic_vector(5 downto 0);
        SYMBOL_ID                   => prach0_symbol_id                        ,--: out std_logic_vector(5 downto 0);

        SECTION_TICK                => prach0_section_tick                     ,--: out std_logic;
        SECTION_LAST                => prach0_section_last                     ,--: out std_logic;
        SECTION_DONE                => prach0_section_done                     ,--: in  std_logic;

        SECTION_ID                  => prach0_section_id                       ,--: out std_logic_vector(11 downto 0);
        BANK_OF_PRB                 => prach0_bank_of_prb                      ,--: out std_logic_vector(0 downto 0);
        USE_EVERY_PRB               => prach0_use_every_prb                    ,--: out std_logic;
        START_OF_PRB                => prach0_start_of_prb                     ,--: out std_logic_vector(9 downto 0);
        OFFSET_OF_PRB               => prach0_offset_of_prb                    ,--: out std_logic_vector(9 downto 0);
        NUMBER_OF_PRB               => prach0_number_of_prb                    ,--: out std_logic_vector(9 downto 0);
        UD_COMP_HDR                 => prach0_ud_comp_hdr                       --: out std_logic_vector(8 downto 0)
    );

    u_CQ_PRACH1 : SECTION_CMD_QUEUE_ANTENNA
    generic map(
        MAX_NUM_PORTC               => MAX_NUM_PORTC                           ,--: natural := 16;
        LINK_DIRECTION              => LINK_DIRECTION                          ,--: std_logic := '0';
        CMD_QUEUE_MEMORY_TYPE       => "block"                                 ,--: string := "auto";
        CMD_QUEUE_DEPTH             => PRACH_CMD_QUEUE_DEPTH                    --: integer := 2048
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => RST                                     ,--: in  std_logic;

        IGNORE_FRAME_ID             => IGNORE_FRAME_ID                         ,--: in  std_logic;
        IGNORE_FRAME_ID_RX          => IGNORE_FRAME_ID_PRACH1_RX               ,--: out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_TX          => IGNORE_FRAME_ID_PRACH1_TX               ,--: out std_logic_vector(7 downto 0);

        COMP_MODE                   => COMP_MODE(RA)(S downto E)               ,--: in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        IQ_WIDTH                    => IQ_WIDTH(RA)(S downto E)                ,--: in  std_logic_array4(MAX_NUM_PORTC-1 downto 0);
        COMP_METHOD                 => COMP_METHOD(RA)(S downto E)             ,--: in  std_logic_array4(MAX_NUM_PORTC-1 downto 0);
        PRB_PER_SYMBOL              => PRB_PER_SYMBOL(RA)(S downto E)          ,--: in  std_logic_array10(MAX_NUM_PORTC-1 downto 0);
        PRB_PER_MTU                 => PRB_PER_MTU(RA)(E)                      ,--: in  std_logic_vector(9 downto 0);

        CNT_ABNORMAL_TERMINATION    => CNT_TX2_CQ_FSM_TERMINATION              ,--: out std_logic_vector(31 downto 0);

        CNT_SECTION_SYMBOL0         => CNT_TX2_CPSEC_SYMBOL0                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL1         => CNT_TX2_CPSEC_SYMBOL1                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL2         => CNT_TX2_CPSEC_SYMBOL2                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL3         => CNT_TX2_CPSEC_SYMBOL3                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL4         => CNT_TX2_CPSEC_SYMBOL4                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL5         => CNT_TX2_CPSEC_SYMBOL5                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL6         => CNT_TX2_CPSEC_SYMBOL6                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL7         => CNT_TX2_CPSEC_SYMBOL7                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL8         => CNT_TX2_CPSEC_SYMBOL8                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL9         => CNT_TX2_CPSEC_SYMBOL9                   ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL10        => CNT_TX2_CPSEC_SYMBOL10                  ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL11        => CNT_TX2_CPSEC_SYMBOL11                  ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL12        => CNT_TX2_CPSEC_SYMBOL12                  ,--: out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL13        => CNT_TX2_CPSEC_SYMBOL13                  ,--: out std_logic_vector(31 downto 0);

        CNT_CQ_FULL_SYMBOL0         => CNT_TX2_CQ_FULL_SYMBOL0                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL1         => CNT_TX2_CQ_FULL_SYMBOL1                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL2         => CNT_TX2_CQ_FULL_SYMBOL2                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL3         => CNT_TX2_CQ_FULL_SYMBOL3                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL4         => CNT_TX2_CQ_FULL_SYMBOL4                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL5         => CNT_TX2_CQ_FULL_SYMBOL5                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL6         => CNT_TX2_CQ_FULL_SYMBOL6                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL7         => CNT_TX2_CQ_FULL_SYMBOL7                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL8         => CNT_TX2_CQ_FULL_SYMBOL8                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL9         => CNT_TX2_CQ_FULL_SYMBOL9                 ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL10        => CNT_TX2_CQ_FULL_SYMBOL10                ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL11        => CNT_TX2_CQ_FULL_SYMBOL11                ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL12        => CNT_TX2_CQ_FULL_SYMBOL12                ,--: out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL13        => CNT_TX2_CQ_FULL_SYMBOL13                ,--: out std_logic_vector(31 downto 0);

        USAGE_CQ_SYMBOL0            => USAGE_TX2_CQ_SYMBOL0                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL1            => USAGE_TX2_CQ_SYMBOL1                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL2            => USAGE_TX2_CQ_SYMBOL2                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL3            => USAGE_TX2_CQ_SYMBOL3                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL4            => USAGE_TX2_CQ_SYMBOL4                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL5            => USAGE_TX2_CQ_SYMBOL5                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL6            => USAGE_TX2_CQ_SYMBOL6                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL7            => USAGE_TX2_CQ_SYMBOL7                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL8            => USAGE_TX2_CQ_SYMBOL8                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL9            => USAGE_TX2_CQ_SYMBOL9                    ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL10           => USAGE_TX2_CQ_SYMBOL10                   ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL11           => USAGE_TX2_CQ_SYMBOL11                   ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL12           => USAGE_TX2_CQ_SYMBOL12                   ,--: out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL13           => USAGE_TX2_CQ_SYMBOL13                   ,--: out std_logic_vector(31 downto 0);

        STATUS_FSM                  => STATUS_TX2_CQ_FSM                        ,--: out std_logic_vector(7 downto 0);

        INFO_UPDATE                 => RAFE1_UPDATE                            ,--: in  std_logic;

        INFO_FRAME_ID               => RAFE1_FRAME_ID                          ,--: in  std_logic_vector(7 downto 0);
        INFO_SUBFRAME_ID            => RAFE1_SUBFRAME_ID                       ,--: in  std_logic_vector(3 downto 0);
        INFO_SLOT_ID                => RAFE1_SLOT_ID                           ,--: in  std_logic_vector(5 downto 0);
        INFO_SYMBOL_ID              => RAFE1_SYMBOL_ID                         ,--: in  std_logic_vector(5 downto 0);
        INFO_ANT_ID                 => RAFE1_ANT_ID                            ,--: in  std_logic_vector(2 downto 0);

        CMD_EN                      => cmd_prach1_en                           ,--: in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        CMD                         => cmd_prach1                              ,--: in  std_logic_array72(MAX_NUM_PORTC-1 downto 0);

        INIT_SESSION                => prach1_init_session                     ,--: out std_logic;
        PATH_SEL                    => prach1_path_sel                         ,--: out std_logic_vector(2 downto 0);

        PACKING_TICK                => prach1_packing_tick                     ,--: out std_logic_vector(MAX_NUM_PORTC-1 downto 0);

        DATA_DIRECTION              => prach1_data_direction                   ,--: out std_logic;
        PAYLOAD_VERSION             => prach1_payload_version                  ,--: out std_logic_vector(2 downto 0);
        FILTER_INDEX                => prach1_filter_index                     ,--: out std_logic_vector(3 downto 0);
        FRAME_ID                    => prach1_frame_id                         ,--: out std_logic_vector(7 downto 0);
        SUBFRAME_ID                 => prach1_subframe_id                      ,--: out std_logic_vector(3 downto 0);
        SLOT_ID                     => prach1_slot_id                          ,--: out std_logic_vector(5 downto 0);
        SYMBOL_ID                   => prach1_symbol_id                        ,--: out std_logic_vector(5 downto 0);

        SECTION_TICK                => prach1_section_tick                     ,--: out std_logic;
        SECTION_LAST                => prach1_section_last                     ,--: out std_logic;
        SECTION_DONE                => prach1_section_done                     ,--: in  std_logic;

        SECTION_ID                  => prach1_section_id                       ,--: out std_logic_vector(11 downto 0);
        BANK_OF_PRB                 => prach1_bank_of_prb                      ,--: out std_logic_vector(0 downto 0);
        USE_EVERY_PRB               => prach1_use_every_prb                    ,--: out std_logic;
        START_OF_PRB                => prach1_start_of_prb                     ,--: out std_logic_vector(9 downto 0);
        OFFSET_OF_PRB               => prach1_offset_of_prb                    ,
        NUMBER_OF_PRB               => prach1_number_of_prb                    ,--: out std_logic_vector(9 downto 0);
        UD_COMP_HDR                 => prach1_ud_comp_hdr                       --: out std_logic_vector(8 downto 0)
    );

--    u_HDR_PRACH : UP_HDR_GEN_1BAND
--    generic map(
--        MAX_NUM_PORTC               => MAX_NUM_PORTC                            --: natural := 4
--    )
--    port map(
--        CLK                         => CLK                                     ,--: in  std_logic;
--
--        PARAM_ID                    => PARAM_ID(RA)(S downto E)                ,--: in  std_logic_array16(MAX_NUM_PORTC-1 downto 0);
--        PE_INDEX                    => PE_INDEX(RA)(S downto E)                ,--: in  std_logic_array8(MAX_NUM_PORTC-1 downto 0);
--
--        BAND0_INIT_SESSION          => prach0_init_session                     ,--: in  std_logic;
--        BAND0_PATH_SEL              => prach0_path_sel                         ,--: in  std_logic_vector(2 downto 0);
--        BAND0_PACKING_TICK          => prach0_packing_tick                     ,--: in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
--        BAND0_DATA_DIRECTION        => prach0_data_direction                   ,--: in  std_logic;
--        BAND0_PAYLOAD_VERSION       => prach0_payload_version                  ,--: in  std_logic_vector(2 downto 0);
--        BAND0_FILTER_INDEX          => prach0_filter_index                     ,--: in  std_logic_vector(3 downto 0);
--        BAND0_FRAME_ID              => prach0_frame_id                         ,--: in  std_logic_vector(7 downto 0);
--        BAND0_SUBFRAME_ID           => prach0_subframe_id                      ,--: in  std_logic_vector(3 downto 0);
--        BAND0_SLOT_ID               => prach0_slot_id                          ,--: in  std_logic_vector(5 downto 0);
--        BAND0_SYMBOL_ID             => prach0_symbol_id                        ,--: in  std_logic_vector(5 downto 0);
--        BAND0_SECTION_TICK          => prach0_section_tick                     ,--: in  std_logic;
--        BAND0_SECTION_ID            => prach0_section_id                       ,--: in  std_logic_vector(11 downto 0);
--        BAND0_USE_EVERY_PRB         => prach0_use_every_prb                    ,--: in  std_logic;
--        BAND0_START_OF_PRB          => prach0_start_of_prb                     ,--: in  std_logic_vector(9 downto 0);
--        BAND0_NUMBER_OF_PRB         => prach0_number_of_prb                    ,--: in  std_logic_vector(9 downto 0);
--
--        BAND0_PARAM_INIT_START      => prach0_init_start                       ,--: out std_logic;
--        BAND0_PARAM_ORAN_START      => prach0_oran_start                       ,--: out std_logic;
--        BAND0_PARAM_ORAN_ACK        => prach0_oran_ack                         ,--: in  std_logic;
--        BAND0_PARAM_PATH_SEL        => prach0_path                             ,--: out std_logic_vector(2 downto 0);
--        BAND0_PARAM_ORAN_PE_INDEX   => prach0_oran_pe_index                    ,--: out std_logic_vector(2 downto 0);
--        BAND0_PARAM_ORAN_eAxC_ID    => prach0_oran_eaxc_id                     ,--: out std_logic_vector(15 downto 0);
--        BAND0_PARAM_ORAN_SEQUENCE_ID=> prach0_oran_sequence_id                 ,--: out std_logic_vector(15 downto 0);
--        BAND0_PARAM_ORAN_HEADER     => prach0_oran_header                      ,--: out std_logic_vector(31 downto 0);
--        BAND0_PARAM_SECTION_START   => prach0_section_start                    ,--: out std_logic;
--        BAND0_PARAM_SECTION_ACK     => prach0_section_ack                      ,--: in  std_logic;
--        BAND0_PARAM_SECTION_HEADER  => prach0_section_header                    --: out std_logic_vector(31 downto 0)
--    );

    u_HDR_PRACH : UP_HDR_GEN_2BAND
    generic map(
        MAX_NUM_PORTC               => MAX_NUM_PORTC                            --: natural := 4
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;

        PARAM_ID                    => PARAM_ID(RA)(S downto E)                ,--: in  std_logic_array16(MAX_NUM_PORTC-1 downto 0);
        PE_INDEX                    => PE_INDEX(RA)(S downto E)                ,--: in  std_logic_array8(MAX_NUM_PORTC-1 downto 0);

        BAND0_INIT_SESSION          => prach0_init_session                     ,--: in  std_logic;
        BAND0_PATH_SEL              => prach0_path_sel                         ,--: in  std_logic_vector(2 downto 0);
        BAND0_PACKING_TICK          => prach0_packing_tick                     ,--: in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        BAND0_DATA_DIRECTION        => prach0_data_direction                   ,--: in  std_logic;
        BAND0_PAYLOAD_VERSION       => prach0_payload_version                  ,--: in  std_logic_vector(2 downto 0);
        BAND0_FILTER_INDEX          => prach0_filter_index                     ,--: in  std_logic_vector(3 downto 0);
        BAND0_FRAME_ID              => prach0_frame_id                         ,--: in  std_logic_vector(7 downto 0);
        BAND0_SUBFRAME_ID           => prach0_subframe_id                      ,--: in  std_logic_vector(3 downto 0);
        BAND0_SLOT_ID               => prach0_slot_id                          ,--: in  std_logic_vector(5 downto 0);
        BAND0_SYMBOL_ID             => prach0_symbol_id                        ,--: in  std_logic_vector(5 downto 0);
        BAND0_SECTION_TICK          => prach0_section_tick                     ,--: in  std_logic;
        BAND0_SECTION_ID            => prach0_section_id                       ,--: in  std_logic_vector(11 downto 0);
        BAND0_USE_EVERY_PRB         => prach0_use_every_prb                    ,--: in  std_logic;
        BAND0_START_OF_PRB          => prach0_start_of_prb                     ,--: in  std_logic_vector(9 downto 0);
        BAND0_NUMBER_OF_PRB         => prach0_number_of_prb                    ,--: in  std_logic_vector(9 downto 0);

        BAND1_INIT_SESSION          => prach1_init_session                     ,--: in  std_logic;
        BAND1_PATH_SEL              => prach1_path_sel                         ,--: in  std_logic_vector(2 downto 0);
        BAND1_PACKING_TICK          => prach1_packing_tick                     ,--: in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        BAND1_DATA_DIRECTION        => prach1_data_direction                   ,--: in  std_logic;
        BAND1_PAYLOAD_VERSION       => prach1_payload_version                  ,--: in  std_logic_vector(2 downto 0);
        BAND1_FILTER_INDEX          => prach1_filter_index                     ,--: in  std_logic_vector(3 downto 0);
        BAND1_FRAME_ID              => prach1_frame_id                         ,--: in  std_logic_vector(7 downto 0);
        BAND1_SUBFRAME_ID           => prach1_subframe_id                      ,--: in  std_logic_vector(3 downto 0);
        BAND1_SLOT_ID               => prach1_slot_id                          ,--: in  std_logic_vector(5 downto 0);
        BAND1_SYMBOL_ID             => prach1_symbol_id                        ,--: in  std_logic_vector(5 downto 0);
        BAND1_SECTION_TICK          => prach1_section_tick                     ,--: in  std_logic;
        BAND1_SECTION_ID            => prach1_section_id                       ,--: in  std_logic_vector(11 downto 0);
        BAND1_USE_EVERY_PRB         => prach1_use_every_prb                    ,--: in  std_logic;
        BAND1_START_OF_PRB          => prach1_start_of_prb                     ,--: in  std_logic_vector(9 downto 0);
        BAND1_NUMBER_OF_PRB         => prach1_number_of_prb                    ,--: in  std_logic_vector(9 downto 0);

        BAND0_PARAM_INIT_START      => prach0_init_start                       ,--: out std_logic;
        BAND0_PARAM_ORAN_START      => prach0_oran_start                       ,--: out std_logic;
        BAND0_PARAM_ORAN_ACK        => prach0_oran_ack                         ,--: in  std_logic;
        BAND0_PARAM_PATH_SEL        => prach0_path                             ,--: out std_logic_vector(2 downto 0);
        BAND0_PARAM_ORAN_PE_INDEX   => prach0_oran_pe_index                    ,--: out std_logic_vector(2 downto 0);
        BAND0_PARAM_ORAN_eAxC_ID    => prach0_oran_eaxc_id                     ,--: out std_logic_vector(15 downto 0);
        BAND0_PARAM_ORAN_SEQUENCE_ID=> prach0_oran_sequence_id                 ,--: out std_logic_vector(15 downto 0);
        BAND0_PARAM_ORAN_HEADER     => prach0_oran_header                      ,--: out std_logic_vector(31 downto 0);
        BAND0_PARAM_SECTION_START   => prach0_section_start                    ,--: out std_logic;
        BAND0_PARAM_SECTION_ACK     => prach0_section_ack                      ,--: in  std_logic;
        BAND0_PARAM_SECTION_HEADER  => prach0_section_header                   ,--: out std_logic_vector(31 downto 0);

        BAND1_PARAM_INIT_START      => prach1_init_start                       ,--: out std_logic;
        BAND1_PARAM_ORAN_START      => prach1_oran_start                       ,--: out std_logic;
        BAND1_PARAM_ORAN_ACK        => prach1_oran_ack                         ,--: in  std_logic;
        BAND1_PARAM_PATH_SEL        => prach1_path                             ,--: out std_logic_vector(2 downto 0);
        BAND1_PARAM_ORAN_PE_INDEX   => prach1_oran_pe_index                    ,--: out std_logic_vector(2 downto 0);
        BAND1_PARAM_ORAN_eAxC_ID    => prach1_oran_eaxc_id                     ,--: out std_logic_vector(15 downto 0);
        BAND1_PARAM_ORAN_SEQUENCE_ID=> prach1_oran_sequence_id                 ,--: out std_logic_vector(15 downto 0);
        BAND1_PARAM_ORAN_HEADER     => prach1_oran_header                      ,--: out std_logic_vector(31 downto 0);
        BAND1_PARAM_SECTION_START   => prach1_section_start                    ,--: out std_logic;
        BAND1_PARAM_SECTION_ACK     => prach1_section_ack                      ,--: in  std_logic;
        BAND1_PARAM_SECTION_HEADER  => prach1_section_header                    --: out std_logic_vector(31 downto 0)
    );

--------------------------------------------------------------------------------
-- Parameter assignment (TX0)
--------------------------------------------------------------------------------

    TX0_SECTION_TICK                <= puxch_section_tick_port;
    TX0_SECTION_LAST                <= puxch_section_last;
    TX0_BANK_OF_PRB                 <= puxch_bank_of_prb;
    TX0_USE_EVERY_PRB               <= puxch_use_every_prb;
    TX0_START_OF_PRB                <= puxch_start_of_prb;
    TX0_NUMBER_OF_PRB               <= puxch_number_of_prb;
    TX0_UD_COMP_HDR                 <= puxch_ud_comp_hdr;

    puxch_section_done              <= '0' when TX0_SECTION_DONE(MAX_CH-1 downto 0) = 0 else '1';

    TX0_INIT                        <= puxch_init_start;
    TX0_RB_PATH                     <= puxch_path;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (puxch_oran_start = '0') then
                TX0_PE_INDEX        <= puxch_oran_pe_index;
                TX0_eAxC_ID         <= puxch_oran_eaxc_id;
                TX0_SEQUENCE_ID     <= puxch_oran_sequence_id;
                TX0_HEADER_APP      <= puxch_oran_header;
--            else
--                TX0_eAxC_ID         <= (others => (others => '0'));
--                TX0_SEQUENCE_ID     <= (others => (others => '0'));
--                TX0_HEADER_APP      <= (others => '0');
            end if;
        end if;
    end process;

    puxch_oran_ack                  <= TX0_HEADER_APP_ACK;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (puxch_section_start = '1') then
                TX0_HEADER_SEC      <= puxch_section_header;
--            else
--                TX0_HEADER_SEC      <= (others => '0');
            end if;
        end if;
    end process;

    puxch_section_ack               <= TX0_HEADER_SEC_ACK;

--------------------------------------------------------------------------------
-- Parameter assignment (TX1)
--------------------------------------------------------------------------------

    TX1_SECTION_TICK                <= prach0_section_tick;
    TX1_SECTION_LAST                <= prach0_section_last;
    TX1_BANK_OF_PRB                 <= prach0_bank_of_prb;
    TX1_USE_EVERY_PRB               <= prach0_use_every_prb;
    TX1_START_OF_PRB                <= prach0_offset_of_prb;
    TX1_NUMBER_OF_PRB               <= prach0_number_of_prb;
    TX1_UD_COMP_HDR                 <= prach0_ud_comp_hdr;

    prach0_section_done             <= TX1_SECTION_DONE;

    TX1_INIT                        <= prach0_init_start;
    TX1_RB_PATH                     <= prach0_path;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (prach0_oran_start = '1') then
                TX1_PE_INDEX        <= prach0_oran_pe_index;
                TX1_eAxC_ID         <= prach0_oran_eaxc_id;
                TX1_SEQUENCE_ID     <= prach0_oran_sequence_id;
                TX1_HEADER_APP      <= prach0_oran_header;
--            else
--                TX1_eAxC_ID         <= (others => (others => '0'));
--                TX1_SEQUENCE_ID     <= (others => (others => '0'));
--                TX1_HEADER_APP      <= (others => '0');
            end if;
        end if;
    end process;

    prach0_oran_ack                 <= TX1_HEADER_APP_ACK;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (prach0_section_start = '1') then
                TX1_HEADER_SEC      <= prach0_section_header;
--            else
--                TX1_HEADER_SEC      <= (others => '0');
            end if;
        end if;
    end process;

    prach0_section_ack              <= TX1_HEADER_SEC_ACK;

--------------------------------------------------------------------------------
-- Parameter assignment (TX2)
--------------------------------------------------------------------------------

    TX2_SECTION_TICK                <= prach1_section_tick;
    TX2_SECTION_LAST                <= prach1_section_last;
    TX2_BANK_OF_PRB                 <= prach1_bank_of_prb;
    TX2_USE_EVERY_PRB               <= prach1_use_every_prb;
    TX2_START_OF_PRB                <= prach1_offset_of_prb;
    TX2_NUMBER_OF_PRB               <= prach1_number_of_prb;
    TX2_UD_COMP_HDR                 <= prach1_ud_comp_hdr;

    prach1_section_done             <= TX2_SECTION_DONE;

    TX2_INIT                        <= prach1_init_start;
    TX2_RB_PATH                     <= prach1_path;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (prach1_oran_start = '1') then
                TX2_PE_INDEX        <= prach1_oran_pe_index;
                TX2_eAxC_ID         <= prach1_oran_eaxc_id;
                TX2_SEQUENCE_ID     <= prach1_oran_sequence_id;
                TX2_HEADER_APP      <= prach1_oran_header;
--            else
--                TX2_eAxC_ID         <= (others => (others => '0'));
--                TX2_SEQUENCE_ID     <= (others => (others => '0'));
--                TX2_HEADER_APP      <= (others => '0');
            end if;
        end if;
    end process;

    prach1_oran_ack                 <= TX2_HEADER_APP_ACK;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (prach1_section_start = '1') then
                TX2_HEADER_SEC      <= prach1_section_header;
--            else
--                TX2_HEADER_SEC      <= (others => '0');
            end if;
        end if;
    end process;

    prach1_section_ack              <= TX2_HEADER_SEC_ACK;

end BEHAVE;