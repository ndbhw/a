--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : UL U-Plane parameter (O-RAN component)                        --
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

entity UP_HDR_GEN_1BAND is
    generic (
        MAX_NUM_PORTC               : natural := 4
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------

        PARAM_ID                    : in  std_logic_array16(MAX_NUM_PORTC-1 downto 0);
        PE_INDEX                    : in  std_logic_array8(MAX_NUM_PORTC-1 downto 0);

--------------------------------------------------------------------------------
-- Section manager
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- TX window
--------------------------------------------------------------------------------

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
end UP_HDR_GEN_1BAND;

architecture BEHAVE of UP_HDR_GEN_1BAND is

    signal band0_tick               : std_logic_vector(MAX_NUM_PORTC-1 downto 0);
    signal id                       : std_logic_array16(MAX_NUM_PORTC-1 downto 0);
    signal pe                       : std_logic_array3(MAX_NUM_PORTC-1 downto 0);

    component UP_HDR_APP is
    generic (
        MAX_CH                      : natural := 8
    );
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        PACKING_TICK                : in  std_logic_vector(MAX_CH-1 downto 0);
        PACKING_TICK_ACK            : in  std_logic;

        DATA_DIRECTION              : in  std_logic;
        PAYLOAD_VERSION             : in  std_logic_vector(2 downto 0);
        FILTER_INDEX                : in  std_logic_vector(3 downto 0);
        FRAME_ID                    : in  std_logic_vector(7 downto 0);
        SUBFRAME_ID                 : in  std_logic_vector(3 downto 0);
        SLOT_ID                     : in  std_logic_vector(5 downto 0);
        SYMBOL_ID                   : in  std_logic_vector(5 downto 0);

        RB_HEADER_APP               : out std_logic_vector(31 downto 0)
    );
    end component;

    component UP_HDR_SEC is
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        SECTION_TICK                : in  std_logic;
        SECTION_TICK_ACK            : in  std_logic;

        SECTION_ID                  : in  std_logic_vector(11 downto 0);
        USE_EVERY_PRB               : in  std_logic;
        START_OF_PRB                : in  std_logic_vector(9 downto 0);
        NUMBER_OF_PRB               : in  std_logic_vector(9 downto 0);

        RB_UPDATE                   : out std_logic;
        RB_HEADER_SEC               : out std_logic_vector(31 downto 0)
    );
    end component;

    component UP_HDR_RTCPC_ID is
    generic (
        MAX_CH                      : natural := 2
    );
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        PACKING_TICK                : in  std_logic_vector(MAX_CH-1 downto 0);
        PACKING_TICK_ACK            : in  std_logic;

        RTCPC_ID                    : in  std_logic_array16(MAX_CH-1 downto 0);

        RB_UPDATE                   : out std_logic;
        RB_eAxC_ID                  : out std_logic_vector(15 downto 0)
    );
    end component;

    component UP_HDR_PE_INDEX is
    generic (
        MAX_CH                      : natural := 2
    );
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        PACKING_TICK                : in  std_logic_vector(MAX_CH-1 downto 0);
        PACKING_TICK_ACK            : in  std_logic;

        PE_INDEX                    : in  std_logic_array3(MAX_CH-1 downto 0);

        RB_UPDATE                   : out std_logic;
        RB_PE_INDEX                 : out std_logic_vector(2 downto 0)
    );
    end component;

    component UP_HDR_SEQ_ID_1BAND is
    generic (
        MAX_CH                      : natural := 8
    );
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        PACKING_TICK                : in  std_logic_vector(MAX_CH-1 downto 0);
        PACKING_TICK_ACK            : in  std_logic;

        RB_SEQUENCE_ID              : out std_logic_vector(15 downto 0)
    );
    end component;

begin

--------------------------------------------------------------------------------
-- Component mapping
--------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            BAND0_PARAM_INIT_START  <= BAND0_INIT_SESSION;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (BAND0_SECTION_TICK = '1') then
                BAND0_PARAM_PATH_SEL    <= BAND0_PATH_SEL;
            end if;
        end if;
    end process;

    band0_tick                      <= BAND0_PACKING_TICK;
    id                              <= PARAM_ID;

    u_BIT8_TO_VALUE8 : for i in MAX_NUM_PORTC-1 downto 0 generate
    pe(i)                           <= BIT8_TO_VALUE8(PE_INDEX(i));
    end generate;

    u_HEADER_RTCPC_ID_BAND0 : UP_HDR_RTCPC_ID
    generic map(
        MAX_CH                      => MAX_NUM_PORTC                            --: natural := 2
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => BAND0_INIT_SESSION                      ,--: in  std_logic;

        PACKING_TICK                => band0_tick                              ,--: in  std_logic_vector(MAX_CH-1 downto 0);
        PACKING_TICK_ACK            => BAND0_PARAM_ORAN_ACK                    ,--: in  std_logic;

        RTCPC_ID                    => id                                      ,--: in  std_logic_array16(MAX_CH-1 downto 0);

        RB_UPDATE                   => BAND0_PARAM_ORAN_START                  ,--: out std_logic;
        RB_eAxC_ID                  => BAND0_PARAM_ORAN_eAxC_ID                 --: out std_logic_vector(15 downto 0)
    );

    u_HEADER_PE_INDEX_BAND0 : UP_HDR_PE_INDEX
    generic map(
        MAX_CH                      => MAX_NUM_PORTC                            --: natural := 2
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => BAND0_INIT_SESSION                      ,--: in  std_logic;

        PACKING_TICK                => band0_tick                              ,--: in  std_logic_vector(MAX_CH-1 downto 0);
        PACKING_TICK_ACK            => BAND0_PARAM_ORAN_ACK                    ,--: in  std_logic;

        PE_INDEX                    => pe                                      ,--: in  std_logic_array3(MAX_CH-1 downto 0);

        RB_UPDATE                   => open                                    ,--: out std_logic;
        RB_PE_INDEX                 => BAND0_PARAM_ORAN_PE_INDEX                --: out std_logic_vector(2 downto 0)
    );

    u_HEADER_SEQ_ID : UP_HDR_SEQ_ID_1BAND
    generic map(
        MAX_CH                      => MAX_NUM_PORTC                            --: natural := 8
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => BAND0_INIT_SESSION                      ,--: in  std_logic;

        PACKING_TICK                => band0_tick                              ,--: in  std_logic_vector(MAX_CH-1 downto 0);
        PACKING_TICK_ACK            => BAND0_PARAM_ORAN_ACK                    ,--: in  std_logic;

        RB_SEQUENCE_ID              => BAND0_PARAM_ORAN_SEQUENCE_ID             --: out std_logic_vector(15 downto 0)
    );

    u_HEADER_APP_BAND0 : UP_HDR_APP
    generic map(
        MAX_CH                      => MAX_NUM_PORTC                            --: natural := 8
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => BAND0_INIT_SESSION                      ,--: in  std_logic;

        PACKING_TICK                => BAND0_PACKING_TICK                      ,--: in  std_logic_vector(MAX_CH-1 downto 0);
        PACKING_TICK_ACK            => BAND0_PARAM_ORAN_ACK                    ,--: in  std_logic;

        DATA_DIRECTION              => BAND0_DATA_DIRECTION                    ,--: in  std_logic;
        PAYLOAD_VERSION             => BAND0_PAYLOAD_VERSION                   ,--: in  std_logic_vector(2 downto 0);
        FILTER_INDEX                => BAND0_FILTER_INDEX                      ,--: in  std_logic_vector(3 downto 0);
        FRAME_ID                    => BAND0_FRAME_ID                          ,--: in  std_logic_vector(7 downto 0);
        SUBFRAME_ID                 => BAND0_SUBFRAME_ID                       ,--: in  std_logic_vector(3 downto 0);
        SLOT_ID                     => BAND0_SLOT_ID                           ,--: in  std_logic_vector(5 downto 0);
        SYMBOL_ID                   => BAND0_SYMBOL_ID                         ,--: in  std_logic_vector(5 downto 0);

        RB_HEADER_APP               => BAND0_PARAM_ORAN_HEADER                  --: out std_logic_vector(31 downto 0)
    );

    u_HEADER_SEC_BAND0 : UP_HDR_SEC
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => BAND0_INIT_SESSION                      ,--: in  std_logic;

        SECTION_TICK                => BAND0_SECTION_TICK                      ,--: in  std_logic;
        SECTION_TICK_ACK            => BAND0_PARAM_SECTION_ACK                 ,--: in  std_logic;

        SECTION_ID                  => BAND0_SECTION_ID                        ,--: in  std_logic_vector(11 downto 0);
        USE_EVERY_PRB               => BAND0_USE_EVERY_PRB                     ,--: in  std_logic;
        START_OF_PRB                => BAND0_START_OF_PRB                      ,--: in  std_logic_vector(9 downto 0);
        NUMBER_OF_PRB               => BAND0_NUMBER_OF_PRB                     ,--: in  std_logic_vector(9 downto 0);

        RB_UPDATE                   => BAND0_PARAM_SECTION_START               ,--: out std_logic;
        RB_HEADER_SEC               => BAND0_PARAM_SECTION_HEADER               --: out std_logic_vector(31 downto 0)
    );

end BEHAVE;