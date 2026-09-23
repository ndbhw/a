--------------------------------------------------------------------------------
--
-- Copyright (C) 2024, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2024.03.11
--------------------------------------------------------------------------------
-- Function description
--   -. ORAN U-Plane processing
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2024.03.11) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use WORK.PKG_ORAN.ALL;
use WORK.PKG_ORAN_ARRAY.ALL;

entity ORAN_UP_RX is
    generic (
        DATA_INDEX_MASK             : natural := 0;
        LINK_MAP_MASK               : std_logic_vector(15 downto 0)
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;                            -- 156.25/390.625-MHz
        RST                         : in  std_logic;                            -- CLK_ORAN

        CLK_UP                      : in  std_logic;                            -- 245.76-MHz

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------

        RX_COMP_MODE                : in  std_logic;
        RX_IQ_WIDTH                 : in  std_logic_vector(3 downto 0);
        RX_COMP_METHOD              : in  std_logic_vector(3 downto 0);
        RX_PRB_PER_SYMBOL           : in  std_logic_vector(9 downto 0);
        RX_COMP_EXP_OFFSET          : in  std_logic_vector(4 downto 0);

--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

        USAGE_DATA_BUFFER           : out std_logic_vector(31 downto 0);

        CNT_RX                      : out std_logic_vector(31 downto 0);
        CNT_LOST                    : out std_logic_vector(31 downto 0);

--------------------------------------------------------------------------------
-- U-Plane (with eCPRI header)
--------------------------------------------------------------------------------

        UP64_VALID                  : in  std_logic;
        UP64_LAST                   : in  std_logic;
        UP64_KEEP                   : in  std_logic_vector(7 downto 0);
        UP64_DATA                   : in  std_logic_vector(63 downto 0);
        UP64_DATA_INDEX             : in  std_logic_vector(2 downto 0);
        UP64_LINK_MAP               : in  std_logic_vector(15 downto 0);

--------------------------------------------------------------------------------
-- Decoded U-Plane
--------------------------------------------------------------------------------

        ADV_RB_CHANNEL_ID           : out std_logic_vector(2 downto 0);         -- 4-clocks advanced
        ADV_RB_FRAME_ID             : out std_logic_vector(7 downto 0);         -- 4-clocks advanced
        ADV_RB_SUBFRAME_ID          : out std_logic_vector(3 downto 0);         -- 4-clocks advanced
        ADV_RB_SLOT_ID              : out std_logic_vector(5 downto 0);         -- 4-clocks advanced
        ADV_RB_SYMBOL_ID            : out std_logic_vector(5 downto 0);         -- 4-clocks advanced
        ADV_RB_START                : out std_logic;                            -- 4-clocks advanced

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
end ORAN_UP_RX;

architecture BEHAVE of ORAN_UP_RX is

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

    component RATE_ADAPT_UP32 is
    generic (
        NUM_OF_URAM                 : natural := 16
    );
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        CLK_CDC                     : in  std_logic;

        USAGE_DATA_BUFFER           : out std_logic_vector(31 downto 0);

        CNT_RX                      : out std_logic_vector(31 downto 0);
        CNT_LOST                    : out std_logic_vector(31 downto 0);

        IN_VALID                    : in  std_logic;
        IN_LAST                     : in  std_logic;
        IN_KEEP                     : in  std_logic_vector(7 downto 0);
        IN_DATA                     : in  std_logic_vector(63 downto 0);
        IN_LINK_INDEX               : in  std_logic_vector(3 downto 0);

        OUT_READY                   : in  std_logic;
        OUT_VALID                   : out std_logic;
        OUT_LAST                    : out std_logic;
        OUT_KEEP                    : out std_logic_vector(3 downto 0);
        OUT_DATA                    : out std_logic_vector(31 downto 0);
        OUT_LINK_INDEX              : out std_logic_vector(3 downto 0)
    );
    end component;

    signal data_match               : std_logic;
    signal link_match               : std_logic_vector(15 downto 0);
    signal up64_valid_mask          : std_logic;
    signal up64_link_index          : std_logic_vector(3 downto 0);

    signal prb_ready                : std_logic;
    signal prb_valid                : std_logic;
    signal prb_last                 : std_logic;
    signal prb_keep                 : std_logic_vector(3 downto 0);
    signal prb_data                 : std_logic_vector(31 downto 0);
    signal prb_link_index           : std_logic_vector(3 downto 0);

    component PRB_UNPACKER is
    generic (
        LINK_DIRECTION              : std_logic := '0'
    );
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        COMP_MODE                   : in  std_logic;
        IQ_WIDTH                    : in  std_logic_vector(3 downto 0);
        COMP_METHOD                 : in  std_logic_vector(3 downto 0);

        PRB_PER_SYMBOL              : in  std_logic_vector(9 downto 0);

        U_PLANE_READY               : out std_logic;
        U_PLANE_VALID               : in  std_logic;
        U_PLANE_LAST                : in  std_logic;
        U_PLANE_KEEP                : in  std_logic_vector(3 downto 0);
        U_PLANE_DATA                : in  std_logic_vector(31 downto 0);
        U_PLANE_LINK_INDEX          : in  std_logic_vector(3 downto 0);

        COMP_FRAME_ID               : out std_logic_vector(7 downto 0);
        COMP_SUBFRAME_ID            : out std_logic_vector(3 downto 0);
        COMP_SLOT_ID                : out std_logic_vector(5 downto 0);
        COMP_SYMBOL_ID              : out std_logic_vector(5 downto 0);
        COMP_USER                   : out std_logic_vector(62 downto 0);

        COMP_HDR                    : out std_logic_vector(7 downto 0);
        COMP_PARAM                  : out std_logic_vector(7 downto 0);

        COMP_VALID                  : out std_logic;
        COMP_TICK                   : out std_logic;
        COMP_DATA_I                 : out std_logic_vector(15 downto 0);
        COMP_DATA_Q                 : out std_logic_vector(15 downto 0)
    );
    end component;

    signal comp_frame_id            : std_logic_vector(7 downto 0);
    signal comp_subframe_id         : std_logic_vector(3 downto 0);
    signal comp_slot_id             : std_logic_vector(5 downto 0);
    signal comp_symbol_id           : std_logic_vector(5 downto 0);
    signal comp_user                : std_logic_vector(62 downto 0) := (others => '0');
    signal comp_hdr                 : std_logic_vector(7 downto 0);
    signal comp_param               : std_logic_vector(7 downto 0);
    signal comp_valid               : std_logic;
    signal comp_tick                : std_logic;
    signal comp_data_i              : std_logic_vector(15 downto 0);
    signal comp_data_q              : std_logic_vector(15 downto 0);

    component PRB_DECOMP is
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        COMP_EXP_OFFSET             : in  std_logic_vector(4 downto 0);

        COMP_FRAME_ID               : in  std_logic_vector(7 downto 0);
        COMP_SUBFRAME_ID            : in  std_logic_vector(3 downto 0);
        COMP_SLOT_ID                : in  std_logic_vector(5 downto 0);
        COMP_SYMBOL_ID              : in  std_logic_vector(5 downto 0);
        COMP_USER                   : in  std_logic_vector(62 downto 0);

        COMP_HDR                    : in  std_logic_vector(7 downto 0);
        COMP_PARAM                  : in  std_logic_vector(7 downto 0);

        COMP_VALID                  : in  std_logic;
        COMP_TICK                   : in  std_logic;
        COMP_DATA_I                 : in  std_logic_vector(15 downto 0);
        COMP_DATA_Q                 : in  std_logic_vector(15 downto 0);

        IQ_FRAME_ID                 : out std_logic_vector(7 downto 0);
        IQ_SUBFRAME_ID              : out std_logic_vector(3 downto 0);
        IQ_SLOT_ID                  : out std_logic_vector(5 downto 0);
        IQ_SYMBOL_ID                : out std_logic_vector(5 downto 0);
        IQ_USER                     : out std_logic_vector(62 downto 0);

        IQ_VALID                    : out std_logic;
        IQ_TICK                     : out std_logic;
        IQ_DATA_I                   : out std_logic_vector(15 downto 0);
        IQ_DATA_Q                   : out std_logic_vector(15 downto 0)
    );
    end component;

    signal iq_frame_id              : std_logic_vector(7 downto 0);
    signal iq_subframe_id           : std_logic_vector(3 downto 0);
    signal iq_slot_id               : std_logic_vector(5 downto 0);
    signal iq_symbol_id             : std_logic_vector(5 downto 0);
    signal iq_user                  : std_logic_vector(62 downto 0);
    signal iq_valid                 : std_logic;
    signal iq_tick                  : std_logic;
    signal iq_data_i                : std_logic_vector(15 downto 0);
    signal iq_data_q                : std_logic_vector(15 downto 0);

    component CONV_IF is
    port (
        CLK                         : in  std_logic;

        IQ_FRAME_ID                 : in  std_logic_vector(7 downto 0);
        IQ_SUBFRAME_ID              : in  std_logic_vector(3 downto 0);
        IQ_SLOT_ID                  : in  std_logic_vector(5 downto 0);
        IQ_SYMBOL_ID                : in  std_logic_vector(5 downto 0);
        IQ_USER                     : in  std_logic_vector(62 downto 0);

        IQ_VALID                    : in  std_logic;
        IQ_TICK                     : in  std_logic;
        IQ_DATA_I                   : in  std_logic_vector(15 downto 0);
        IQ_DATA_Q                   : in  std_logic_vector(15 downto 0);

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

    data_match <= '1' when (UP64_DATA_INDEX = DATA_INDEX_MASK) else '0';
    link_match <= UP64_LINK_MAP and LINK_MAP_MASK;

    up64_valid_mask <= UP64_VALID when (data_match = '1') and (link_match /= 0) else '0';
    up64_link_index <= BIT16_TO_VALUE16(UP64_LINK_MAP);

--------------------------------------------------------------------------------
-- Component mapping
--------------------------------------------------------------------------------

    u_RST : RST_SYNC
    generic map(
        DLY_NUM                     => 4                                       ,--: natural := 4;
        MAX_FANOUT_NUM              => 200                                      --: integer := 200
    )
    port map(
        RST_IN                      => RST                                     ,--: in  std_logic;
        CLK                         => CLK                                     ,--: in  std_logic;
        RST_OUT                     => srst                                     --: out std_logic
    );

    u_RATE_ADAPT : RATE_ADAPT_UP32
    generic map(
        NUM_OF_URAM                 => 1                                        --: natural := 16
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => RST                                     ,--: in  std_logic;

        CLK_CDC                     => CLK_UP                                  ,--: in  std_logic;

        USAGE_DATA_BUFFER           => USAGE_DATA_BUFFER                       ,--: out std_logic_vector(31 downto 0);

        CNT_RX                      => CNT_RX                                  ,--: out std_logic_vector(31 downto 0);
        CNT_LOST                    => CNT_LOST                                ,--: out std_logic_vector(31 downto 0);

        IN_VALID                    => up64_valid_mask                         ,--: in  std_logic;
        IN_LAST                     => UP64_LAST                               ,--: in  std_logic;
        IN_KEEP                     => UP64_KEEP                               ,--: in  std_logic_vector(7 downto 0);
        IN_DATA                     => UP64_DATA                               ,--: in  std_logic_vector(63 downto 0);
        IN_LINK_INDEX               => up64_link_index                         ,--: in  std_logic_vector(3 downto 0);

        OUT_READY                   => prb_ready                               ,--: in  std_logic;
        OUT_VALID                   => prb_valid                               ,--: out std_logic;
        OUT_LAST                    => prb_last                                ,--: out std_logic;
        OUT_KEEP                    => prb_keep                                ,--: out std_logic_vector(3 downto 0);
        OUT_DATA                    => prb_data                                ,--: out std_logic_vector(31 downto 0);
        OUT_LINK_INDEX              => prb_link_index                           --: out std_logic_vector(3 downto 0)
    );

    u_UNPACKER : PRB_UNPACKER
    generic map(
        LINK_DIRECTION              => TX_LINK_DIRECTION                        --: std_logic := '0'
    )
    port map(
        CLK                         => CLK_UP                                  ,--: in  std_logic;
        RST                         => srst                                    ,--: in  std_logic;

        COMP_MODE                   => RX_COMP_MODE                            ,--: in  std_logic;
        IQ_WIDTH                    => RX_IQ_WIDTH                             ,--: in  std_logic_vector(3 downto 0);
        COMP_METHOD                 => RX_COMP_METHOD                          ,--: in  std_logic_vector(3 downto 0);

        PRB_PER_SYMBOL              => RX_PRB_PER_SYMBOL                       ,--: in  std_logic_vector(9 downto 0);

        U_PLANE_READY               => prb_ready                               ,--: out std_logic;
        U_PLANE_VALID               => prb_valid                               ,--: in  std_logic;
        U_PLANE_LAST                => prb_last                                ,--: in  std_logic;
        U_PLANE_KEEP                => prb_keep                                ,--: in  std_logic_vector(3 downto 0);
        U_PLANE_DATA                => prb_data                                ,--: in  std_logic_vector(31 downto 0);
        U_PLANE_LINK_INDEX          => prb_link_index                          ,--: in  std_logic_vector(3 downto 0);

        COMP_FRAME_ID               => comp_frame_id                           ,--: out std_logic_vector(7 downto 0);
        COMP_SUBFRAME_ID            => comp_subframe_id                        ,--: out std_logic_vector(3 downto 0);
        COMP_SLOT_ID                => comp_slot_id                            ,--: out std_logic_vector(5 downto 0);
        COMP_SYMBOL_ID              => comp_symbol_id                          ,--: out std_logic_vector(5 downto 0);
        COMP_USER                   => comp_user                               ,--: out std_logic_vector(62 downto 0);

        COMP_HDR                    => comp_hdr                                ,--: out std_logic_vector(7 downto 0);
        COMP_PARAM                  => comp_param                              ,--: out std_logic_vector(7 downto 0);

        COMP_VALID                  => comp_valid                              ,--: out std_logic;
        COMP_TICK                   => comp_tick                               ,--: out std_logic;
        COMP_DATA_I                 => comp_data_i                             ,--: out std_logic_vector(15 downto 0);
        COMP_DATA_Q                 => comp_data_q                              --: out std_logic_vector(15 downto 0)
    );

    u_DECOMP : PRB_DECOMP
    port map(
        CLK                         => CLK_UP                                  ,--: in  std_logic;
        RST                         => srst                                    ,--: in  std_logic;

        COMP_EXP_OFFSET             => RX_COMP_EXP_OFFSET                      ,--: in  std_logic_vector(4 downto 0);

        COMP_FRAME_ID               => comp_frame_id                           ,--: in  std_logic_vector(7 downto 0);
        COMP_SUBFRAME_ID            => comp_subframe_id                        ,--: in  std_logic_vector(3 downto 0);
        COMP_SLOT_ID                => comp_slot_id                            ,--: in  std_logic_vector(5 downto 0);
        COMP_SYMBOL_ID              => comp_symbol_id                          ,--: in  std_logic_vector(5 downto 0);
        COMP_USER                   => comp_user                               ,--: in  std_logic_vector(62 downto 0);

        COMP_HDR                    => comp_hdr                                ,--: in  std_logic_vector(7 downto 0);
        COMP_PARAM                  => comp_param                              ,--: in  std_logic_vector(7 downto 0);

        COMP_VALID                  => comp_valid                              ,--: in  std_logic;
        COMP_TICK                   => comp_tick                               ,--: in  std_logic;
        COMP_DATA_I                 => comp_data_i                             ,--: in  std_logic_vector(15 downto 0);
        COMP_DATA_Q                 => comp_data_q                             ,--: in  std_logic_vector(15 downto 0);

        IQ_FRAME_ID                 => iq_frame_id                             ,--: out std_logic_vector(7 downto 0);
        IQ_SUBFRAME_ID              => iq_subframe_id                          ,--: out std_logic_vector(3 downto 0);
        IQ_SLOT_ID                  => iq_slot_id                              ,--: out std_logic_vector(5 downto 0);
        IQ_SYMBOL_ID                => iq_symbol_id                            ,--: out std_logic_vector(5 downto 0);
        IQ_USER                     => iq_user                                 ,--: out std_logic_vector(62 downto 0);

        IQ_VALID                    => iq_valid                                ,--: out std_logic;
        IQ_TICK                     => iq_tick                                 ,--: out std_logic;
        IQ_DATA_I                   => iq_data_i                               ,--: out std_logic_vector(15 downto 0);
        IQ_DATA_Q                   => iq_data_q                                --: out std_logic_vector(15 downto 0)
    );

    u_CONV : CONV_IF
    port map(
        CLK                         => CLK_UP                                  ,--: in  std_logic;

        IQ_FRAME_ID                 => iq_frame_id                             ,--: in  std_logic_vector(7 downto 0);
        IQ_SUBFRAME_ID              => iq_subframe_id                          ,--: in  std_logic_vector(3 downto 0);
        IQ_SLOT_ID                  => iq_slot_id                              ,--: in  std_logic_vector(5 downto 0);
        IQ_SYMBOL_ID                => iq_symbol_id                            ,--: in  std_logic_vector(5 downto 0);
        IQ_USER                     => iq_user                                 ,--: in  std_logic_vector(62 downto 0);

        IQ_VALID                    => iq_valid                                ,--: in  std_logic;
        IQ_TICK                     => iq_tick                                 ,--: in  std_logic;
        IQ_DATA_I                   => iq_data_i                               ,--: in  std_logic_vector(15 downto 0);
        IQ_DATA_Q                   => iq_data_q                               ,--: in  std_logic_vector(15 downto 0);

        RB_eAxC_ID                  => RB_eAxC_ID                              ,--: out std_logic_vector(15 downto 0);
        RB_SEQUENCE_ID              => RB_SEQUENCE_ID                          ,--: out std_logic_vector(15 downto 0);
        RB_CHANNEL_ID               => RB_CHANNEL_ID                           ,--: out std_logic_vector(3 downto 0);
        RB_FRAME_ID                 => RB_FRAME_ID                             ,--: out std_logic_vector(7 downto 0);
        RB_SUBFRAME_ID              => RB_SUBFRAME_ID                          ,--: out std_logic_vector(3 downto 0);
        RB_SLOT_ID                  => RB_SLOT_ID                              ,--: out std_logic_vector(5 downto 0);
        RB_SYMBOL_ID                => RB_SYMBOL_ID                            ,--: out std_logic_vector(5 downto 0);
        RB_SECTION_ID               => RB_SECTION_ID                           ,--: out std_logic_vector(11 downto 0);
        RB_NUMBER                   => RB_NUMBER                               ,--: out std_logic_vector(9 downto 0);
        RE_NUMBER                   => RE_NUMBER                               ,--: out std_logic_vector(11 downto 0);

        RB_VALID                    => RB_VALID                                ,--: out std_logic;
        RB_START                    => RB_START                                ,--: out std_logic;
        RB_TICK                     => RB_TICK                                 ,--: out std_logic;
        RB_LAST                     => RB_LAST                                 ,--: out std_logic;
        RB_DATA_I                   => RB_DATA_I                               ,--: out std_logic_vector(15 downto 0);
        RB_DATA_Q                   => RB_DATA_Q                                --: out std_logic_vector(15 downto 0)
    );

    ADV_RB_CHANNEL_ID               <= comp_user(60 downto 58);
    ADV_RB_FRAME_ID                 <= comp_frame_id;
    ADV_RB_SUBFRAME_ID              <= comp_subframe_id;
    ADV_RB_SLOT_ID                  <= comp_slot_id;
    ADV_RB_SYMBOL_ID                <= comp_symbol_id;
    ADV_RB_START                    <= comp_tick and comp_user(0);

end BEHAVE;