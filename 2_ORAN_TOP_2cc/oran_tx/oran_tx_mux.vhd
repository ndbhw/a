--------------------------------------------------------------------------------
--
-- Copyright (C) 2024, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2024.03.11
--------------------------------------------------------------------------------
-- Function description
--   1. ORAN interconnect component
--   2. TX MUX
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2024.03.11) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use WORK.ARRAY_TYPE.ALL;

entity ORAN_TX_MUX is
    generic (
        TX_UNIT                     : natural := 2
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;                            -- 390.625-MHz
        RST                         : in  std_logic;                            -- SYNC@CLK

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Input
--------------------------------------------------------------------------------

        IN0_READY                   : out std_logic;
        IN0_VALID                   : in  std_logic;
        IN0_LAST                    : in  std_logic;
        IN0_KEEP                    : in  std_logic_vector(7 downto 0);
        IN0_DATA                    : in  std_logic_vector(63 downto 0);

        IN1_READY                   : out std_logic;
        IN1_VALID                   : in  std_logic;
        IN1_LAST                    : in  std_logic;
        IN1_KEEP                    : in  std_logic_vector(7 downto 0);
        IN1_DATA                    : in  std_logic_vector(63 downto 0);

        IN2_READY                   : out std_logic;
        IN2_VALID                   : in  std_logic;
        IN2_LAST                    : in  std_logic;
        IN2_KEEP                    : in  std_logic_vector(7 downto 0);
        IN2_DATA                    : in  std_logic_vector(63 downto 0);

        IN3_READY                   : out std_logic;
        IN3_VALID                   : in  std_logic;
        IN3_LAST                    : in  std_logic;
        IN3_KEEP                    : in  std_logic_vector(7 downto 0);
        IN3_DATA                    : in  std_logic_vector(63 downto 0);

        IN4_READY                   : out std_logic;
        IN4_VALID                   : in  std_logic;
        IN4_LAST                    : in  std_logic;
        IN4_KEEP                    : in  std_logic_vector(7 downto 0);
        IN4_DATA                    : in  std_logic_vector(63 downto 0);

        IN5_READY                   : out std_logic;
        IN5_VALID                   : in  std_logic;
        IN5_LAST                    : in  std_logic;
        IN5_KEEP                    : in  std_logic_vector(7 downto 0);
        IN5_DATA                    : in  std_logic_vector(63 downto 0);

        IN6_READY                   : out std_logic;
        IN6_VALID                   : in  std_logic;
        IN6_LAST                    : in  std_logic;
        IN6_KEEP                    : in  std_logic_vector(7 downto 0);
        IN6_DATA                    : in  std_logic_vector(63 downto 0);

        IN7_READY                   : out std_logic;
        IN7_VALID                   : in  std_logic;
        IN7_LAST                    : in  std_logic;
        IN7_KEEP                    : in  std_logic_vector(7 downto 0);
        IN7_DATA                    : in  std_logic_vector(63 downto 0);

--------------------------------------------------------------------------------
-- Output
--------------------------------------------------------------------------------

        OUT_READY                   : in  std_logic;
        OUT_VALID                   : out std_logic;
        OUT_LAST                    : out std_logic;
        OUT_KEEP                    : out std_logic_vector(7 downto 0);
        OUT_DATA                    : out std_logic_vector(63 downto 0)
    );
end ORAN_TX_MUX;

architecture BEHAVE of ORAN_TX_MUX is

    signal sreset_n_tx              : std_logic;

    component AXIS_REG_64 is
    port (
        ACLK                        : in  std_logic;
        ARESETN                     : in  std_logic;
        S_AXIS_TVALID               : in  std_logic;
        S_AXIS_TREADY               : out std_logic;
        S_AXIS_TDATA                : in  std_logic_vector(63 downto 0);
        S_AXIS_TKEEP                : in  std_logic_vector(7 downto 0);
        S_AXIS_TLAST                : in  std_logic;
        S_AXIS_TUSER                : in  std_logic_vector(6 downto 0);
        M_AXIS_TVALID               : out std_logic;
        M_AXIS_TREADY               : in  std_logic;
        M_AXIS_TDATA                : out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                : out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                : out std_logic;
        M_AXIS_TUSER                : out std_logic_vector(6 downto 0)
    );
    end component;

    signal reg_valid                : std_logic_vector(8*1-1 downto 0) := (others => '0');
    signal reg_ready                : std_logic_vector(8*1-1 downto 0);
    signal reg_data                 : std_logic_vector(8*64-1 downto 0) := (others => '0');
    signal reg_keep                 : std_logic_vector(8*8-1 downto 0) := (others => '0');
    signal reg_last                 : std_logic_vector(8*1-1 downto 0) := (others => '0');

    component AXIS_SWITCH_2to1 is
    port (
        ACLK                        : in  std_logic;
        ARESETN                     : in  std_logic;
        S_AXIS_TVALID               : in  std_logic_vector(1*2-1 downto 0);
        S_AXIS_TREADY               : out std_logic_vector(1*2-1 downto 0);
        S_AXIS_TDATA                : in  std_logic_vector(64*2-1 downto 0);
        S_AXIS_TKEEP                : in  std_logic_vector(8*2-1 downto 0);
        S_AXIS_TLAST                : in  std_logic_vector(1*2-1 downto 0);
        M_AXIS_TVALID               : out std_logic_vector(0 downto 0);
        M_AXIS_TREADY               : in  std_logic_vector(0 downto 0);
        M_AXIS_TDATA                : out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                : out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                : out std_logic_vector(0 downto 0);
        S_REQ_SUPPRESS              : in  std_logic_vector(2-1 downto 0);
        S_DECODE_ERR                : out std_logic_vector(2-1 downto 0)
    );
    end component;

    component AXIS_SWITCH_3to1 is
    port (
        ACLK                        : in  std_logic;
        ARESETN                     : in  std_logic;
        S_AXIS_TVALID               : in  std_logic_vector(1*3-1 downto 0);
        S_AXIS_TREADY               : out std_logic_vector(1*3-1 downto 0);
        S_AXIS_TDATA                : in  std_logic_vector(64*3-1 downto 0);
        S_AXIS_TKEEP                : in  std_logic_vector(8*3-1 downto 0);
        S_AXIS_TLAST                : in  std_logic_vector(1*3-1 downto 0);
        M_AXIS_TVALID               : out std_logic_vector(0 downto 0);
        M_AXIS_TREADY               : in  std_logic_vector(0 downto 0);
        M_AXIS_TDATA                : out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                : out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                : out std_logic_vector(0 downto 0);
        S_REQ_SUPPRESS              : in  std_logic_vector(3-1 downto 0);
        S_DECODE_ERR                : out std_logic_vector(3-1 downto 0)
    );
    end component;

    component AXIS_SWITCH_4to1 is
    port (
        ACLK                        : in  std_logic;
        ARESETN                     : in  std_logic;
        S_AXIS_TVALID               : in  std_logic_vector(1*4-1 downto 0);
        S_AXIS_TREADY               : out std_logic_vector(1*4-1 downto 0);
        S_AXIS_TDATA                : in  std_logic_vector(64*4-1 downto 0);
        S_AXIS_TKEEP                : in  std_logic_vector(8*4-1 downto 0);
        S_AXIS_TLAST                : in  std_logic_vector(1*4-1 downto 0);
        M_AXIS_TVALID               : out std_logic_vector(0 downto 0);
        M_AXIS_TREADY               : in  std_logic_vector(0 downto 0);
        M_AXIS_TDATA                : out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                : out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                : out std_logic_vector(0 downto 0);
        S_REQ_SUPPRESS              : in  std_logic_vector(4-1 downto 0);
        S_DECODE_ERR                : out std_logic_vector(4-1 downto 0)
    );
    end component;

    component AXIS_SWITCH_5to1 is
    port (
        ACLK                        : in  std_logic;
        ARESETN                     : in  std_logic;
        S_AXIS_TVALID               : in  std_logic_vector(1*5-1 downto 0);
        S_AXIS_TREADY               : out std_logic_vector(1*5-1 downto 0);
        S_AXIS_TDATA                : in  std_logic_vector(64*5-1 downto 0);
        S_AXIS_TKEEP                : in  std_logic_vector(8*5-1 downto 0);
        S_AXIS_TLAST                : in  std_logic_vector(1*5-1 downto 0);
        M_AXIS_TVALID               : out std_logic_vector(0 downto 0);
        M_AXIS_TREADY               : in  std_logic_vector(0 downto 0);
        M_AXIS_TDATA                : out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                : out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                : out std_logic_vector(0 downto 0);
        S_REQ_SUPPRESS              : in  std_logic_vector(5-1 downto 0);
        S_DECODE_ERR                : out std_logic_vector(5-1 downto 0)
    );
    end component;

    component AXIS_SWITCH_6to1 is
    port (
        ACLK                        : in  std_logic;
        ARESETN                     : in  std_logic;
        S_AXIS_TVALID               : in  std_logic_vector(1*6-1 downto 0);
        S_AXIS_TREADY               : out std_logic_vector(1*6-1 downto 0);
        S_AXIS_TDATA                : in  std_logic_vector(64*6-1 downto 0);
        S_AXIS_TKEEP                : in  std_logic_vector(8*6-1 downto 0);
        S_AXIS_TLAST                : in  std_logic_vector(1*6-1 downto 0);
        M_AXIS_TVALID               : out std_logic_vector(0 downto 0);
        M_AXIS_TREADY               : in  std_logic_vector(0 downto 0);
        M_AXIS_TDATA                : out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                : out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                : out std_logic_vector(0 downto 0);
        S_REQ_SUPPRESS              : in  std_logic_vector(6-1 downto 0);
        S_DECODE_ERR                : out std_logic_vector(6-1 downto 0)
    );
    end component;

    component AXIS_SWITCH_7to1 is
    port (
        ACLK                        : in  std_logic;
        ARESETN                     : in  std_logic;
        S_AXIS_TVALID               : in  std_logic_vector(1*7-1 downto 0);
        S_AXIS_TREADY               : out std_logic_vector(1*7-1 downto 0);
        S_AXIS_TDATA                : in  std_logic_vector(64*7-1 downto 0);
        S_AXIS_TKEEP                : in  std_logic_vector(8*7-1 downto 0);
        S_AXIS_TLAST                : in  std_logic_vector(1*7-1 downto 0);
        M_AXIS_TVALID               : out std_logic_vector(0 downto 0);
        M_AXIS_TREADY               : in  std_logic_vector(0 downto 0);
        M_AXIS_TDATA                : out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                : out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                : out std_logic_vector(0 downto 0);
        S_REQ_SUPPRESS              : in  std_logic_vector(7-1 downto 0);
        S_DECODE_ERR                : out std_logic_vector(7-1 downto 0)
    );
    end component;

    component AXIS_SWITCH_8to1 is
    port (
        ACLK                        : in  std_logic;
        ARESETN                     : in  std_logic;
        S_AXIS_TVALID               : in  std_logic_vector(1*8-1 downto 0);
        S_AXIS_TREADY               : out std_logic_vector(1*8-1 downto 0);
        S_AXIS_TDATA                : in  std_logic_vector(64*8-1 downto 0);
        S_AXIS_TKEEP                : in  std_logic_vector(8*8-1 downto 0);
        S_AXIS_TLAST                : in  std_logic_vector(1*8-1 downto 0);
        M_AXIS_TVALID               : out std_logic_vector(0 downto 0);
        M_AXIS_TREADY               : in  std_logic_vector(0 downto 0);
        M_AXIS_TDATA                : out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                : out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                : out std_logic_vector(0 downto 0);
        S_REQ_SUPPRESS              : in  std_logic_vector(8-1 downto 0);
        S_DECODE_ERR                : out std_logic_vector(8-1 downto 0)
    );
    end component;

    signal tx_muxed_ready           : std_logic_vector(0 downto 0);
    signal tx_muxed_valid           : std_logic_vector(0 downto 0);
    signal tx_muxed_last            : std_logic_vector(0 downto 0);
    signal tx_muxed_keep            : std_logic_vector(7 downto 0);
    signal tx_muxed_data            : std_logic_vector(63 downto 0);

begin

--------------------------------------------------------------------------------
-- Synchronous reset
--------------------------------------------------------------------------------

    sreset_n_tx                     <= not RST;

--------------------------------------------------------------------------------
-- Input Mapping
--------------------------------------------------------------------------------

    IN0_READY                       <= reg_ready(0);
    IN1_READY                       <= reg_ready(1);
    IN2_READY                       <= reg_ready(2);
    IN3_READY                       <= reg_ready(3);
    IN4_READY                       <= reg_ready(4);
    IN5_READY                       <= reg_ready(5);
    IN6_READY                       <= '0';
    IN7_READY                       <= '0';

    reg_valid(0)                    <= IN0_VALID;
    reg_valid(1)                    <= IN1_VALID;
    reg_valid(2)                    <= IN2_VALID;
    reg_valid(3)                    <= IN3_VALID;
    reg_valid(4)                    <= IN4_VALID;
    reg_valid(5)                    <= IN5_VALID;

    reg_last(0)                     <= IN0_LAST;
    reg_last(1)                     <= IN1_LAST;
    reg_last(2)                     <= IN2_LAST;
    reg_last(3)                     <= IN3_LAST;
    reg_last(4)                     <= IN4_LAST;
    reg_last(5)                     <= IN5_LAST;

    reg_keep(0*8+7 downto 0*8)      <= IN0_KEEP;
    reg_keep(1*8+7 downto 1*8)      <= IN1_KEEP;
    reg_keep(2*8+7 downto 2*8)      <= IN2_KEEP;
    reg_keep(3*8+7 downto 3*8)      <= IN3_KEEP;
    reg_keep(4*8+7 downto 4*8)      <= IN4_KEEP;
    reg_keep(5*8+7 downto 5*8)      <= IN5_KEEP;

    reg_data(0*64+63 downto 0*64)   <= IN0_DATA;
    reg_data(1*64+63 downto 1*64)   <= IN1_DATA;
    reg_data(2*64+63 downto 2*64)   <= IN2_DATA;
    reg_data(3*64+63 downto 3*64)   <= IN3_DATA;
    reg_data(4*64+63 downto 4*64)   <= IN4_DATA;
    reg_data(5*64+63 downto 5*64)   <= IN5_DATA;

--------------------------------------------------------------------------------
-- Input registering
--------------------------------------------------------------------------------

    u_1PATH : if TX_UNIT = 1 generate
    tx_muxed_valid(0)               <= reg_valid(0);
    reg_ready(0)                    <= tx_muxed_ready(0);
    tx_muxed_data                   <= reg_data(63 downto 0);
    tx_muxed_keep                   <= reg_keep(7 downto 0);
    tx_muxed_last(0)                <= reg_last(0);
    end generate;

    u_2PATH : if TX_UNIT = 2 generate
    u_COMBINE : AXIS_SWITCH_2to1
    port map(
        ACLK                        => CLK                                     ,--: in  std_logic;
        ARESETN                     => sreset_n_tx                             ,--: in  std_logic;
        S_AXIS_TVALID               => reg_valid(1*2-1 downto 0)               ,--: in  std_logic_vector(1*n-1 downto 0);
        S_AXIS_TREADY               => reg_ready(1*2-1 downto 0)               ,--: out std_logic_vector(1*n-1 downto 0);
        S_AXIS_TDATA                => reg_data(64*2-1 downto 0)               ,--: in  std_logic_vector(64*n-1 downto 0);
        S_AXIS_TKEEP                => reg_keep(8*2-1 downto 0)                ,--: in  std_logic_vector(8*n-1 downto 0);
        S_AXIS_TLAST                => reg_last(1*2-1 downto 0)                ,--: in  std_logic_vector(1*n-1 downto 0);
        M_AXIS_TVALID               => tx_muxed_valid                          ,--: out std_logic_vector(0 downto 0);
        M_AXIS_TREADY               => tx_muxed_ready                          ,--: in  std_logic_vector(0 downto 0);
        M_AXIS_TDATA                => tx_muxed_data                           ,--: out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                => tx_muxed_keep                           ,--: out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                => tx_muxed_last                           ,--: out std_logic_vector(0 downto 0);
        S_REQ_SUPPRESS              => (others => '0')                         ,--: in  std_logic_vector(n-1 downto 0);
        S_DECODE_ERR                => open                                     --: out std_logic_vector(n-1 downto 0)
    );
    end generate;

    u_3PATH : if TX_UNIT = 3 generate
    u_COMBINE : AXIS_SWITCH_3to1
    port map(
        ACLK                        => CLK                                     ,--: in  std_logic;
        ARESETN                     => sreset_n_tx                             ,--: in  std_logic;
        S_AXIS_TVALID               => reg_valid(1*3-1 downto 0)               ,--: in  std_logic_vector(1*n-1 downto 0);
        S_AXIS_TREADY               => reg_ready(1*3-1 downto 0)               ,--: out std_logic_vector(1*n-1 downto 0);
        S_AXIS_TDATA                => reg_data(64*3-1 downto 0)               ,--: in  std_logic_vector(64*n-1 downto 0);
        S_AXIS_TKEEP                => reg_keep(8*3-1 downto 0)                ,--: in  std_logic_vector(8*n-1 downto 0);
        S_AXIS_TLAST                => reg_last(1*3-1 downto 0)                ,--: in  std_logic_vector(1*n-1 downto 0);
        M_AXIS_TVALID               => tx_muxed_valid                          ,--: out std_logic_vector(0 downto 0);
        M_AXIS_TREADY               => tx_muxed_ready                          ,--: in  std_logic_vector(0 downto 0);
        M_AXIS_TDATA                => tx_muxed_data                           ,--: out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                => tx_muxed_keep                           ,--: out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                => tx_muxed_last                           ,--: out std_logic_vector(0 downto 0);
        S_REQ_SUPPRESS              => (others => '0')                         ,--: in  std_logic_vector(n-1 downto 0);
        S_DECODE_ERR                => open                                     --: out std_logic_vector(n-1 downto 0)
    );
    end generate;

    u_4PATH : if TX_UNIT = 4 generate
    u_COMBINE : AXIS_SWITCH_4to1
    port map(
        ACLK                        => CLK                                     ,--: in  std_logic;
        ARESETN                     => sreset_n_tx                             ,--: in  std_logic;
        S_AXIS_TVALID               => reg_valid(1*4-1 downto 0)               ,--: in  std_logic_vector(1*n-1 downto 0);
        S_AXIS_TREADY               => reg_ready(1*4-1 downto 0)               ,--: out std_logic_vector(1*n-1 downto 0);
        S_AXIS_TDATA                => reg_data(64*4-1 downto 0)               ,--: in  std_logic_vector(64*n-1 downto 0);
        S_AXIS_TKEEP                => reg_keep(8*4-1 downto 0)                ,--: in  std_logic_vector(8*n-1 downto 0);
        S_AXIS_TLAST                => reg_last(1*4-1 downto 0)                ,--: in  std_logic_vector(1*n-1 downto 0);
        M_AXIS_TVALID               => tx_muxed_valid                          ,--: out std_logic_vector(0 downto 0);
        M_AXIS_TREADY               => tx_muxed_ready                          ,--: in  std_logic_vector(0 downto 0);
        M_AXIS_TDATA                => tx_muxed_data                           ,--: out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                => tx_muxed_keep                           ,--: out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                => tx_muxed_last                           ,--: out std_logic_vector(0 downto 0);
        S_REQ_SUPPRESS              => (others => '0')                         ,--: in  std_logic_vector(n-1 downto 0);
        S_DECODE_ERR                => open                                     --: out std_logic_vector(n-1 downto 0)
    );
    end generate;

    u_5PATH : if TX_UNIT = 5 generate
    u_COMBINE : AXIS_SWITCH_5to1
    port map(
        ACLK                        => CLK                                     ,--: in  std_logic;
        ARESETN                     => sreset_n_tx                             ,--: in  std_logic;
        S_AXIS_TVALID               => reg_valid(1*5-1 downto 0)               ,--: in  std_logic_vector(1*n-1 downto 0);
        S_AXIS_TREADY               => reg_ready(1*5-1 downto 0)               ,--: out std_logic_vector(1*n-1 downto 0);
        S_AXIS_TDATA                => reg_data(64*5-1 downto 0)               ,--: in  std_logic_vector(64*n-1 downto 0);
        S_AXIS_TKEEP                => reg_keep(8*5-1 downto 0)                ,--: in  std_logic_vector(8*n-1 downto 0);
        S_AXIS_TLAST                => reg_last(1*5-1 downto 0)                ,--: in  std_logic_vector(1*n-1 downto 0);
        M_AXIS_TVALID               => tx_muxed_valid                          ,--: out std_logic_vector(0 downto 0);
        M_AXIS_TREADY               => tx_muxed_ready                          ,--: in  std_logic_vector(0 downto 0);
        M_AXIS_TDATA                => tx_muxed_data                           ,--: out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                => tx_muxed_keep                           ,--: out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                => tx_muxed_last                           ,--: out std_logic_vector(0 downto 0);
        S_REQ_SUPPRESS              => (others => '0')                         ,--: in  std_logic_vector(n-1 downto 0);
        S_DECODE_ERR                => open                                     --: out std_logic_vector(n-1 downto 0)
    );
    end generate;

    u_6PATH : if TX_UNIT = 6 generate
    u_COMBINE : AXIS_SWITCH_6to1
    port map(
        ACLK                        => CLK                                     ,--: in  std_logic;
        ARESETN                     => sreset_n_tx                             ,--: in  std_logic;
        S_AXIS_TVALID               => reg_valid(1*6-1 downto 0)               ,--: in  std_logic_vector(1*n-1 downto 0);
        S_AXIS_TREADY               => reg_ready(1*6-1 downto 0)               ,--: out std_logic_vector(1*n-1 downto 0);
        S_AXIS_TDATA                => reg_data(64*6-1 downto 0)               ,--: in  std_logic_vector(64*n-1 downto 0);
        S_AXIS_TKEEP                => reg_keep(8*6-1 downto 0)                ,--: in  std_logic_vector(8*n-1 downto 0);
        S_AXIS_TLAST                => reg_last(1*6-1 downto 0)                ,--: in  std_logic_vector(1*n-1 downto 0);
        M_AXIS_TVALID               => tx_muxed_valid                          ,--: out std_logic_vector(0 downto 0);
        M_AXIS_TREADY               => tx_muxed_ready                          ,--: in  std_logic_vector(0 downto 0);
        M_AXIS_TDATA                => tx_muxed_data                           ,--: out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                => tx_muxed_keep                           ,--: out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                => tx_muxed_last                           ,--: out std_logic_vector(0 downto 0);
        S_REQ_SUPPRESS              => (others => '0')                         ,--: in  std_logic_vector(n-1 downto 0);
        S_DECODE_ERR                => open                                     --: out std_logic_vector(n-1 downto 0)
    );
    end generate;

    u_7PATH : if TX_UNIT = 7 generate
    u_COMBINE : AXIS_SWITCH_7to1
    port map(
        ACLK                        => CLK                                     ,--: in  std_logic;
        ARESETN                     => sreset_n_tx                             ,--: in  std_logic;
        S_AXIS_TVALID               => reg_valid(1*7-1 downto 0)               ,--: in  std_logic_vector(1*n-1 downto 0);
        S_AXIS_TREADY               => reg_ready(1*7-1 downto 0)               ,--: out std_logic_vector(1*n-1 downto 0);
        S_AXIS_TDATA                => reg_data(64*7-1 downto 0)               ,--: in  std_logic_vector(64*n-1 downto 0);
        S_AXIS_TKEEP                => reg_keep(8*7-1 downto 0)                ,--: in  std_logic_vector(8*n-1 downto 0);
        S_AXIS_TLAST                => reg_last(1*7-1 downto 0)                ,--: in  std_logic_vector(1*n-1 downto 0);
        M_AXIS_TVALID               => tx_muxed_valid                          ,--: out std_logic_vector(0 downto 0);
        M_AXIS_TREADY               => tx_muxed_ready                          ,--: in  std_logic_vector(0 downto 0);
        M_AXIS_TDATA                => tx_muxed_data                           ,--: out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                => tx_muxed_keep                           ,--: out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                => tx_muxed_last                           ,--: out std_logic_vector(0 downto 0);
        S_REQ_SUPPRESS              => (others => '0')                         ,--: in  std_logic_vector(n-1 downto 0);
        S_DECODE_ERR                => open                                     --: out std_logic_vector(n-1 downto 0)
    );
    end generate;

    u_8PATH : if TX_UNIT = 8 generate
    u_COMBINE : AXIS_SWITCH_8to1
    port map(
        ACLK                        => CLK                                     ,--: in  std_logic;
        ARESETN                     => sreset_n_tx                             ,--: in  std_logic;
        S_AXIS_TVALID               => reg_valid(1*8-1 downto 0)               ,--: in  std_logic_vector(1*n-1 downto 0);
        S_AXIS_TREADY               => reg_ready(1*8-1 downto 0)               ,--: out std_logic_vector(1*n-1 downto 0);
        S_AXIS_TDATA                => reg_data(64*8-1 downto 0)               ,--: in  std_logic_vector(64*n-1 downto 0);
        S_AXIS_TKEEP                => reg_keep(8*8-1 downto 0)                ,--: in  std_logic_vector(8*n-1 downto 0);
        S_AXIS_TLAST                => reg_last(1*8-1 downto 0)                ,--: in  std_logic_vector(1*n-1 downto 0);
        M_AXIS_TVALID               => tx_muxed_valid                          ,--: out std_logic_vector(0 downto 0);
        M_AXIS_TREADY               => tx_muxed_ready                          ,--: in  std_logic_vector(0 downto 0);
        M_AXIS_TDATA                => tx_muxed_data                           ,--: out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                => tx_muxed_keep                           ,--: out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                => tx_muxed_last                           ,--: out std_logic_vector(0 downto 0);
        S_REQ_SUPPRESS              => (others => '0')                         ,--: in  std_logic_vector(n-1 downto 0);
        S_DECODE_ERR                => open                                     --: out std_logic_vector(n-1 downto 0)
    );
    end generate;

    u_OUTPUT_REG : AXIS_REG_64
    port map(
        ACLK                        => CLK                                     ,--: in  std_logic;
        ARESETN                     => sreset_n_tx                             ,--: in  std_logic;
        S_AXIS_TVALID               => tx_muxed_valid(0)                       ,--: in  std_logic;
        S_AXIS_TREADY               => tx_muxed_ready(0)                       ,--: out std_logic;
        S_AXIS_TDATA                => tx_muxed_data                           ,--: in  std_logic_vector(63 downto 0);
        S_AXIS_TKEEP                => tx_muxed_keep                           ,--: in  std_logic_vector(7 downto 0);
        S_AXIS_TLAST                => tx_muxed_last(0)                        ,--: in  std_logic;
        S_AXIS_TUSER                => (others => '0')                         ,--: in  std_logic_vector(6 downto 0);
        M_AXIS_TVALID               => OUT_VALID                               ,--: out std_logic;
        M_AXIS_TREADY               => OUT_READY                               ,--: in  std_logic;
        M_AXIS_TDATA                => OUT_DATA                                ,--: out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                => OUT_KEEP                                ,--: out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                => OUT_LAST                                ,--: out std_logic;
        M_AXIS_TUSER                => open                                     --: out std_logic_vector(6 downto 0)
    );

end BEHAVE;