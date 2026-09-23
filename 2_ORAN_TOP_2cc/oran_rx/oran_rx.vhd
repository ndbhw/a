--------------------------------------------------------------------------------
--
-- Copyright (C) 2024, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2024.03.11
--------------------------------------------------------------------------------
-- Function description
--   1. ORAN interconnect (Connection between ORAN and LPHY)
--   2. Max 8-ports per each direction
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2024.03.11) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use WORK.ARRAY_TYPE.ALL;
use WORK.PKG_ORAN.ALL;
use WORK.PKG_ORAN_ARRAY.ALL;

entity ORAN_RX is
    generic (
        LINK_MAP_MASK               : std_logic_vector(15 downto 0)
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        RST                         : in  std_logic;                            -- CLK_MAC

        CLK_MAC                     : in  std_logic;
        CLK_BUS                     : in  std_logic;

--------------------------------------------------------------------------------
-- Sync
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Debug
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- MPI
--------------------------------------------------------------------------------

        DL_COMP_MODE                : in  std_logic_array64(7 downto 0);
        DL_IQ_WIDTH                 : in  std_logic_array64_array4(7 downto 0);
        DL_COMP_METHOD              : in  std_logic_array64_array4(7 downto 0);
        DL_PRB_PER_SYMBOL           : in  std_logic_array64_array10(7 downto 0);
        DL_COMP_EXP_OFFSET          : in  std_logic_array64_array5(7 downto 0);

--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

        USAGE_RX_CP_BUFFER          : out std_logic_vector(31 downto 0);
        USAGE_RX_UP_BUFFER          : out std_logic_vector(31 downto 0);

        CNT_RX_CP                   : out std_logic_vector(31 downto 0);
        CNT_RX_UP                   : out std_logic_vector(31 downto 0);
        CNT_RX_CP_LOST              : out std_logic_vector(31 downto 0);
        CNT_RX_UP_LOST              : out std_logic_vector(31 downto 0);

        DET_DL_CP0_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_DL_CP1_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_DL_CP2_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_DL_CP3_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_DL_CP4_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_DL_CP5_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_DL_CP6_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_DL_CP7_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_UL_CP0_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_UL_CP1_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_UL_CP2_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_UL_CP3_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_UL_CP4_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_UL_CP5_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_UL_CP6_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_UL_CP7_FAULT_ID_31      : out std_logic_vector(15 downto 0);

--------------------------------------------------------------------------------
-- MAC interconnect
--------------------------------------------------------------------------------

        ORAN_RX_C64_VALID           : in  std_logic;
        ORAN_RX_C64_LAST            : in  std_logic;
        ORAN_RX_C64_KEEP            : in  std_logic_vector(7 downto 0);
        ORAN_RX_C64_DATA            : in  std_logic_vector(63 downto 0);
        ORAN_RX_C64_DATA_INDEX      : in  std_logic_vector(2 downto 0);
        ORAN_RX_C64_LINK_MAP        : in  std_logic_vector(15 downto 0);

        ORAN_RX_U64_VALID           : in  std_logic;
        ORAN_RX_U64_LAST            : in  std_logic;
        ORAN_RX_U64_KEEP            : in  std_logic_vector(7 downto 0);
        ORAN_RX_U64_DATA            : in  std_logic_vector(63 downto 0);
        ORAN_RX_U64_DATA_INDEX      : in  std_logic_vector(2 downto 0);
        ORAN_RX_U64_LINK_MAP        : in  std_logic_vector(15 downto 0);

--------------------------------------------------------------------------------
-- CUPE
--------------------------------------------------------------------------------

        xL_CP_VALID                 : out std_logic;
        xL_CP_LAST                  : out std_logic;
        xL_CP_DATA                  : out std_logic_vector(31 downto 0);
        xL_CP_DATA_INDEX            : out std_logic_vector(2 downto 0);
        xL_CP_LINK_INDEX            : out std_logic_vector(3 downto 0);

        DL_RB_eAxC_ID               : out std_logic_vector(15 downto 0);
        DL_RB_SEQUENCE_ID           : out std_logic_vector(15 downto 0);
        DL_RB_CHANNEL_ID            : out std_logic_vector(3 downto 0);
        DL_RB_FRAME_ID              : out std_logic_vector(7 downto 0);
        DL_RB_SUBFRAME_ID           : out std_logic_vector(3 downto 0);
        DL_RB_SLOT_ID               : out std_logic_vector(5 downto 0);
        DL_RB_SYMBOL_ID             : out std_logic_vector(5 downto 0);
        DL_RB_SECTION_ID            : out std_logic_vector(11 downto 0);
        DL_RB_NUMBER                : out std_logic_vector(9 downto 0);
        DL_RE_NUMBER                : out std_logic_vector(11 downto 0);

        DL_RB_VALID                 : out std_logic;
        DL_RB_START                 : out std_logic;
        DL_RB_TICK                  : out std_logic;
        DL_RB_LAST                  : out std_logic;
        DL_RB_DATA_I                : out std_logic_vector(15 downto 0);
        DL_RB_DATA_Q                : out std_logic_vector(15 downto 0)
    );
end ORAN_RX;

architecture BEHAVE of ORAN_RX is

    component ORAN_CP_RX is
    generic (
--        DATA_INDEX_MASK             : natural := 0;
        LINK_MAP_MASK               : std_logic_vector(15 downto 0)
    );
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        CLK_UP                      : in  std_logic;

        USAGE_DATA_BUFFER           : out std_logic_vector(31 downto 0);

        CNT_RX                      : out std_logic_vector(31 downto 0);
        CNT_LOST                    : out std_logic_vector(31 downto 0);

        CP64_VALID                  : in  std_logic;
        CP64_LAST                   : in  std_logic;
        CP64_KEEP                   : in  std_logic_vector(7 downto 0);
        CP64_DATA                   : in  std_logic_vector(63 downto 0);
        CP64_DATA_INDEX             : in  std_logic_vector(2 downto 0);
        CP64_LINK_MAP               : in  std_logic_vector(15 downto 0);

        CP32_VALID                  : out std_logic;
        CP32_LAST                   : out std_logic;
        CP32_KEEP                   : out std_logic_vector(3 downto 0);
        CP32_DATA                   : out std_logic_vector(31 downto 0);
        CP32_DATA_INDEX             : out std_logic_vector(2 downto 0);
        CP32_LINK_INDEX             : out std_logic_vector(3 downto 0)
    );
    end component;

    signal cp32_valid               : std_logic;
    signal cp32_last                : std_logic;
--    signal cp32_keep                : std_logic_vector(3 downto 0);
    signal cp32_data                : std_logic_vector(31 downto 0);
    signal cp32_data_index          : std_logic_vector(2 downto 0);
    signal cp32_link_index          : std_logic_vector(3 downto 0);

    component FAULT_ID_31 is
    generic (
        USAGE_TYPE0                 : boolean := false;
        USAGE_TYPE1                 : boolean := true;
        USAGE_TYPE3                 : boolean := true;
        USAGE_TYPE5                 : boolean := true;
        USAGE_TYPE6                 : boolean := false;
        USAGE_TYPE7                 : boolean := false
    );
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        DET_DL_CP0_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_DL_CP1_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_DL_CP2_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_DL_CP3_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_DL_CP4_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_DL_CP5_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_DL_CP6_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_DL_CP7_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_UL_CP0_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_UL_CP1_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_UL_CP2_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_UL_CP3_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_UL_CP4_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_UL_CP5_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_UL_CP6_FAULT_ID_31      : out std_logic_vector(15 downto 0);
        DET_UL_CP7_FAULT_ID_31      : out std_logic_vector(15 downto 0);

        CP32_VALID                  : in  std_logic;
        CP32_LAST                   : in  std_logic;
        CP32_DATA                   : in  std_logic_vector(31 downto 0);
        CP32_DATA_INDEX             : in  std_logic_vector(2 downto 0);
        CP32_LINK_INDEX             : in  std_logic_vector(3 downto 0)
    );
    end component;

    component ORAN_UP_RX is
    generic (
        DATA_INDEX_MASK             : natural := 0;
        LINK_MAP_MASK               : std_logic_vector(15 downto 0)
    );
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        CLK_UP                      : in  std_logic;

        RX_COMP_MODE                : in  std_logic;
        RX_IQ_WIDTH                 : in  std_logic_vector(3 downto 0);
        RX_COMP_METHOD              : in  std_logic_vector(3 downto 0);
        RX_PRB_PER_SYMBOL           : in  std_logic_vector(9 downto 0);
        RX_COMP_EXP_OFFSET          : in  std_logic_vector(4 downto 0);

        USAGE_DATA_BUFFER           : out std_logic_vector(31 downto 0);

        CNT_RX                      : out std_logic_vector(31 downto 0);
        CNT_LOST                    : out std_logic_vector(31 downto 0);

        UP64_VALID                  : in  std_logic;
        UP64_LAST                   : in  std_logic;
        UP64_KEEP                   : in  std_logic_vector(7 downto 0);
        UP64_DATA                   : in  std_logic_vector(63 downto 0);
        UP64_DATA_INDEX             : in  std_logic_vector(2 downto 0);
        UP64_LINK_MAP               : in  std_logic_vector(15 downto 0);

        ADV_RB_CHANNEL_ID           : out std_logic_vector(2 downto 0);
        ADV_RB_FRAME_ID             : out std_logic_vector(7 downto 0);
        ADV_RB_SUBFRAME_ID          : out std_logic_vector(3 downto 0);
        ADV_RB_SLOT_ID              : out std_logic_vector(5 downto 0);
        ADV_RB_SYMBOL_ID            : out std_logic_vector(5 downto 0);
        ADV_RB_START                : out std_logic;

        RB_eAxC_ID                  : out std_logic_vector(15 downto 0);
        RB_SEQUENCE_ID              : out std_logic_vector(15 downto 0);
        RB_CHANNEL_ID               : out std_logic_vector(3 downto 0);
        RB_FRAME_ID                 : out std_logic_vector(7 downto 0);
        RB_SUBFRAME_ID              : out std_logic_vector(3 downto 0);
        RB_SLOT_ID                  : out std_logic_vector(5 downto 0);
        RB_SYMBOL_ID                : out std_logic_vector(5 downto 0);
        RB_SECTION_ID               : out std_logic_vector(11 downto 0);
        RB_NUMBER                   : out std_logic_vector(9 downto 0);
        RE_NUMBER                   : out std_logic_vector(11 downto 0);

        RB_VALID                    : out std_logic;
        RB_START                    : out std_logic;
        RB_TICK                     : out std_logic;
        RB_LAST                     : out std_logic;
        RB_DATA_I                   : out std_logic_vector(15 downto 0);
        RB_DATA_Q                   : out std_logic_vector(15 downto 0)
    );
    end component;

begin

    u_xL_C_PLANE : ORAN_CP_RX
    generic map(
--        DATA_INDEX_MASK             => INDEX_PDxCH                             ,--: natural := 0;
        LINK_MAP_MASK               => LINK_MAP_MASK                            --: std_logic_vector(15 downto 0)
    )
    port map(
        CLK                         => CLK_MAC                                 ,--: in  std_logic;
        RST                         => RST                                     ,--: in  std_logic;

        CLK_UP                      => CLK_BUS                                 ,--: in  std_logic;

        USAGE_DATA_BUFFER           => USAGE_RX_CP_BUFFER                      ,--: out std_logic_vector(31 downto 0);

        CNT_RX                      => CNT_RX_CP                               ,--: out std_logic_vector(31 downto 0);
        CNT_LOST                    => CNT_RX_CP_LOST                          ,--: out std_logic_vector(31 downto 0);

        CP64_VALID                  => ORAN_RX_C64_VALID                       ,--: in  std_logic;
        CP64_LAST                   => ORAN_RX_C64_LAST                        ,--: in  std_logic;
        CP64_KEEP                   => ORAN_RX_C64_KEEP                        ,--: in  std_logic_vector(7 downto 0);
        CP64_DATA                   => ORAN_RX_C64_DATA                        ,--: in  std_logic_vector(63 downto 0);
        CP64_DATA_INDEX             => ORAN_RX_C64_DATA_INDEX                  ,--: in  std_logic_vector(2 downto 0);
        CP64_LINK_MAP               => ORAN_RX_C64_LINK_MAP                    ,--: in  std_logic_vector(15 downto 0);

        CP32_VALID                  => cp32_valid                              ,--: out std_logic;
        CP32_LAST                   => cp32_last                               ,--: out std_logic;
        CP32_KEEP                   => open                                    ,--: out std_logic_vector(3 downto 0);
        CP32_DATA                   => cp32_data                               ,--: out std_logic_vector(31 downto 0);
        CP32_DATA_INDEX             => cp32_data_index                         ,--: out std_logic_vector(2 downto 0);
        CP32_LINK_INDEX             => cp32_link_index                          --: out std_logic_vector(3 downto 0)
    );

    u_FAULT_ID_31 : FAULT_ID_31
    generic map(
        USAGE_TYPE0                 => false                                   ,--: boolean := false;
        USAGE_TYPE1                 => true                                    ,--: boolean := true;
        USAGE_TYPE3                 => true                                    ,--: boolean := true;
        USAGE_TYPE5                 => false                                   ,--: boolean := true;
        USAGE_TYPE6                 => false                                   ,--: boolean := false;
        USAGE_TYPE7                 => false                                    --: boolean := false
    )
    port map(
        CLK                         => CLK_BUS                                 ,--: in  std_logic;
        RST                         => RST                                     ,--: in  std_logic;

        DET_DL_CP0_FAULT_ID_31      => DET_DL_CP0_FAULT_ID_31                  ,--: out std_logic_vector(15 downto 0);
        DET_DL_CP1_FAULT_ID_31      => DET_DL_CP1_FAULT_ID_31                  ,--: out std_logic_vector(15 downto 0);
        DET_DL_CP2_FAULT_ID_31      => DET_DL_CP2_FAULT_ID_31                  ,--: out std_logic_vector(15 downto 0);
        DET_DL_CP3_FAULT_ID_31      => DET_DL_CP3_FAULT_ID_31                  ,--: out std_logic_vector(15 downto 0);
        DET_DL_CP4_FAULT_ID_31      => DET_DL_CP4_FAULT_ID_31                  ,--: out std_logic_vector(15 downto 0);
        DET_DL_CP5_FAULT_ID_31      => DET_DL_CP5_FAULT_ID_31                  ,--: out std_logic_vector(15 downto 0);
        DET_DL_CP6_FAULT_ID_31      => DET_DL_CP6_FAULT_ID_31                  ,--: out std_logic_vector(15 downto 0);
        DET_DL_CP7_FAULT_ID_31      => DET_DL_CP7_FAULT_ID_31                  ,--: out std_logic_vector(15 downto 0);
        DET_UL_CP0_FAULT_ID_31      => DET_UL_CP0_FAULT_ID_31                  ,--: out std_logic_vector(15 downto 0);
        DET_UL_CP1_FAULT_ID_31      => DET_UL_CP1_FAULT_ID_31                  ,--: out std_logic_vector(15 downto 0);
        DET_UL_CP2_FAULT_ID_31      => DET_UL_CP2_FAULT_ID_31                  ,--: out std_logic_vector(15 downto 0);
        DET_UL_CP3_FAULT_ID_31      => DET_UL_CP3_FAULT_ID_31                  ,--: out std_logic_vector(15 downto 0);
        DET_UL_CP4_FAULT_ID_31      => DET_UL_CP4_FAULT_ID_31                  ,--: out std_logic_vector(15 downto 0);
        DET_UL_CP5_FAULT_ID_31      => DET_UL_CP5_FAULT_ID_31                  ,--: out std_logic_vector(15 downto 0);
        DET_UL_CP6_FAULT_ID_31      => DET_UL_CP6_FAULT_ID_31                  ,--: out std_logic_vector(15 downto 0);
        DET_UL_CP7_FAULT_ID_31      => DET_UL_CP7_FAULT_ID_31                  ,--: out std_logic_vector(15 downto 0);

        CP32_VALID                  => cp32_valid                              ,--: in  std_logic;
        CP32_LAST                   => cp32_last                               ,--: in  std_logic;
        CP32_DATA                   => cp32_data                               ,--: in  std_logic_vector(31 downto 0);
        CP32_DATA_INDEX             => cp32_data_index                         ,--: in  std_logic_vector(2 downto 0);
        CP32_LINK_INDEX             => cp32_link_index                          --: in  std_logic_vector(3 downto 0)
    );

    xL_CP_VALID                     <= cp32_valid;
    xL_CP_LAST                      <= cp32_last;
    xL_CP_DATA                      <= cp32_data;
    xL_CP_DATA_INDEX                <= cp32_data_index;
    xL_CP_LINK_INDEX                <= cp32_link_index;

    u_PDxCH_0 : ORAN_UP_RX
    generic map(
        DATA_INDEX_MASK             => 0                                       ,--: natural := 0;
        LINK_MAP_MASK               => LINK_MAP_MASK                            --: std_logic_vector(15 downto 0)
    )
    port map(
        CLK                         => CLK_MAC                                 ,--: in  std_logic;
        RST                         => RST                                     ,--: in  std_logic;

        CLK_UP                      => CLK_BUS                                 ,--: in  std_logic;

        RX_COMP_MODE                => DL_COMP_MODE(0)(0)                      ,--: in  std_logic;
        RX_IQ_WIDTH                 => DL_IQ_WIDTH(0)(0)                       ,--: in  std_logic_vector(3 downto 0);
        RX_COMP_METHOD              => DL_COMP_METHOD(0)(0)                    ,--: in  std_logic_vector(3 downto 0);
        RX_PRB_PER_SYMBOL           => DL_PRB_PER_SYMBOL(0)(0)                 ,--: in  std_logic_vector(9 downto 0);
        RX_COMP_EXP_OFFSET          => DL_COMP_EXP_OFFSET(0)(0)                ,--: in  std_logic_vector(4 downto 0);

        USAGE_DATA_BUFFER           => USAGE_RX_UP_BUFFER                      ,--: out std_logic_vector(31 downto 0);

        CNT_RX                      => CNT_RX_UP                               ,--: out std_logic_vector(31 downto 0);
        CNT_LOST                    => CNT_RX_UP_LOST                          ,--: out std_logic_vector(31 downto 0);

        UP64_VALID                  => ORAN_RX_U64_VALID                       ,--: in  std_logic;
        UP64_LAST                   => ORAN_RX_U64_LAST                        ,--: in  std_logic;
        UP64_KEEP                   => ORAN_RX_U64_KEEP                        ,--: in  std_logic_vector(7 downto 0);
        UP64_DATA                   => ORAN_RX_U64_DATA                        ,--: in  std_logic_vector(63 downto 0);
        UP64_DATA_INDEX             => ORAN_RX_U64_DATA_INDEX                  ,--: in  std_logic_vector(2 downto 0);
        UP64_LINK_MAP               => ORAN_RX_U64_LINK_MAP                    ,--: in  std_logic_vector(15 downto 0);

        ADV_RB_CHANNEL_ID           => open                                    ,--: out std_logic_vector(2 downto 0);
        ADV_RB_FRAME_ID             => open                                    ,--: out std_logic_vector(7 downto 0);
        ADV_RB_SUBFRAME_ID          => open                                    ,--: out std_logic_vector(3 downto 0);
        ADV_RB_SLOT_ID              => open                                    ,--: out std_logic_vector(5 downto 0);
        ADV_RB_SYMBOL_ID            => open                                    ,--: out std_logic_vector(5 downto 0);
        ADV_RB_START                => open                                    ,--: out std_logic;

        RB_eAxC_ID                  => DL_RB_eAxC_ID                           ,--: out std_logic_vector(15 downto 0);
        RB_SEQUENCE_ID              => DL_RB_SEQUENCE_ID                       ,--: out std_logic_vector(15 downto 0);
        RB_CHANNEL_ID               => DL_RB_CHANNEL_ID                        ,--: out std_logic_vector(3 downto 0);
        RB_FRAME_ID                 => DL_RB_FRAME_ID                          ,--: out std_logic_vector(7 downto 0);
        RB_SUBFRAME_ID              => DL_RB_SUBFRAME_ID                       ,--: out std_logic_vector(3 downto 0);
        RB_SLOT_ID                  => DL_RB_SLOT_ID                           ,--: out std_logic_vector(5 downto 0);
        RB_SYMBOL_ID                => DL_RB_SYMBOL_ID                         ,--: out std_logic_vector(5 downto 0);
        RB_SECTION_ID               => DL_RB_SECTION_ID                        ,--: out std_logic_vector(11 downto 0);
        RB_NUMBER                   => DL_RB_NUMBER                            ,--: out std_logic_vector(9 downto 0);
        RE_NUMBER                   => DL_RE_NUMBER                            ,--: out std_logic_vector(11 downto 0);

        RB_VALID                    => DL_RB_VALID                             ,--: out std_logic;
        RB_START                    => DL_RB_START                             ,--: out std_logic;
        RB_TICK                     => DL_RB_TICK                              ,--: out std_logic;
        RB_LAST                     => DL_RB_LAST                              ,--: out std_logic;
        RB_DATA_I                   => DL_RB_DATA_I                            ,--: out std_logic_vector(15 downto 0);
        RB_DATA_Q                   => DL_RB_DATA_Q                             --: out std_logic_vector(15 downto 0)
    );

end BEHAVE;