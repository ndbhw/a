--------------------------------------------------------------------------------
--
-- Copyright (C) 2025, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2025.03.18
--------------------------------------------------------------------------------
-- Function description
--   1. FH interconnect component
--   2. n-to-1 MUX
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2025.03.18) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use WORK.ARRAY_TYPE.ALL;

entity MAC_TX_MUX is
    generic (
        TX_NUM                      : natural := 3
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;
        RST                         : in  std_logic;                            -- SYNC@CLK
        RST_n                       : in  std_logic;                            -- SYNC@CLK

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- UL U-Plane
--------------------------------------------------------------------------------

        IN_READY                    : out std_logic_vector(TX_NUM-1 downto 0);
        IN_VALID                    : in  std_logic_vector(TX_NUM-1 downto 0);
        IN_LAST                     : in  std_logic_vector(TX_NUM-1 downto 0);
        IN_KEEP                     : in  std_logic_array8(TX_NUM-1 downto 0);
        IN_DATA                     : in  std_logic_array64(TX_NUM-1 downto 0);

--------------------------------------------------------------------------------
-- MAC interconnect
--------------------------------------------------------------------------------

        OUT_READY                   : in  std_logic;
        OUT_VALID                   : out std_logic;
        OUT_LAST                    : out std_logic;
        OUT_KEEP                    : out std_logic_vector(7 downto 0);
        OUT_DATA                    : out std_logic_vector(63 downto 0)

    );
end MAC_TX_MUX;

architecture BEHAVE of MAC_TX_MUX is

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

    u_PORT_MAP : for i in TX_NUM-1 downto 0 generate
    IN_READY(i)                     <= reg_ready(i);
    reg_valid(i)                    <= IN_VALID(i);
    reg_last(i)                     <= IN_LAST(i);
    reg_keep(i*8+7 downto i*8)      <= IN_KEEP(i);
    reg_data(i*64+63 downto i*64)   <= IN_DATA(i);
    end generate;

--------------------------------------------------------------------------------
-- Input registering
--------------------------------------------------------------------------------

    u_1PATH : if TX_NUM = 1 generate
    tx_muxed_valid(0)               <= reg_valid(0);
    reg_ready(0)                    <= tx_muxed_ready(0);
    tx_muxed_data                   <= reg_data(63 downto 0);
    tx_muxed_keep                   <= reg_keep(7 downto 0);
    tx_muxed_last(0)                <= reg_last(0);
    end generate;

    u_2PATH : if TX_NUM = 2 generate
    u_COMBINE : AXIS_SWITCH_2to1
    port map(
        ACLK                        => CLK                                     ,--: in  std_logic;
        ARESETN                     => RST_n                                   ,--: in  std_logic;
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

    u_3PATH : if TX_NUM = 3 generate
    u_COMBINE : AXIS_SWITCH_3to1
    port map(
        ACLK                        => CLK                                     ,--: in  std_logic;
        ARESETN                     => RST_n                                   ,--: in  std_logic;
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

    u_4PATH : if TX_NUM = 4 generate
    u_COMBINE : AXIS_SWITCH_4to1
    port map(
        ACLK                        => CLK                                     ,--: in  std_logic;
        ARESETN                     => RST_n                                   ,--: in  std_logic;
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

    u_5PATH : if TX_NUM = 5 generate
    u_COMBINE : AXIS_SWITCH_5to1
    port map(
        ACLK                        => CLK                                     ,--: in  std_logic;
        ARESETN                     => RST_n                                   ,--: in  std_logic;
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

    u_6PATH : if TX_NUM = 6 generate
    u_COMBINE : AXIS_SWITCH_6to1
    port map(
        ACLK                        => CLK                                     ,--: in  std_logic;
        ARESETN                     => RST_n                                   ,--: in  std_logic;
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

    u_7PATH : if TX_NUM = 7 generate
    u_COMBINE : AXIS_SWITCH_7to1
    port map(
        ACLK                        => CLK                                     ,--: in  std_logic;
        ARESETN                     => RST_n                                   ,--: in  std_logic;
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

    u_8PATH : if TX_NUM = 8 generate
    u_COMBINE : AXIS_SWITCH_8to1
    port map(
        ACLK                        => CLK                                     ,--: in  std_logic;
        ARESETN                     => RST_n                                   ,--: in  std_logic;
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
        ARESETN                     => RST_n                                   ,--: in  std_logic;
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