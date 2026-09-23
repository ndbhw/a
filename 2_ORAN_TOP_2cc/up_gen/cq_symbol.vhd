--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : CQ, UL symbol (O-RAN component)                               --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.15                                                    --
--                                                                            --
--------------------------------------------------------------------------------
-- Read latency 0-clocks                                                      --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library XPM;
use XPM.VCOMPONENTS.ALL;

use WORK.PKG_ORAN.ALL;

entity CQ_SYMBOL is
    generic (
        MEMORY_TYPE                 : string := "auto";                         -- Allowed values: auto, block, distributed. Default value = auto.
        WRITE_DEPTH                 : integer := 2048;
        WRITE_WIDTH                 : integer := 72
    );
    port (
        CLK                         : in  std_logic;
        SRST                        : in  std_logic;
        DIN                         : in  std_logic_vector(WRITE_WIDTH-1 downto 0);
        WR_EN                       : in  std_logic;
        RD_EN                       : in  std_logic;
        DOUT                        : out std_logic_vector(WRITE_WIDTH-1 downto 0);
        FULL                        : out std_logic;
        EMPTY                       : out std_logic;
        DATA_COUNT                  : out std_logic_vector(31 downto 0) := (others => '0');
        WR_RST_BUSY                 : out std_logic;
        RD_RST_BUSY                 : out std_logic
    );
end CQ_SYMBOL;

architecture BEHAVE of CQ_SYMBOL is

    component XPM_FIFO_SYNC is
    generic (
        -- Common module generics
        FIFO_MEMORY_TYPE            : string := "auto";                         -- Allowed values: auto, block, distributed. Default value = auto.
        FIFO_WRITE_DEPTH            : integer := 2048;
        WRITE_DATA_WIDTH            : integer := 32;
        READ_MODE                   : string := "std";                          -- Allowed values: std, fwft. Default value = std.
        FIFO_READ_LATENCY           : integer := 1;
        FULL_RESET_VALUE            : integer := 0;
        USE_ADV_FEATURES            : string := "0707";
        READ_DATA_WIDTH             : integer := 32;
        WR_DATA_COUNT_WIDTH         : integer := 1;
        PROG_FULL_THRESH            : integer := 10;
        RD_DATA_COUNT_WIDTH         : integer := 1;
        PROG_EMPTY_THRESH           : integer := 10;
        DOUT_RESET_VALUE            : string := "0";
        ECC_MODE                    : string := "no_ecc";
        SIM_ASSERT_CHK              : integer := 0;
        WAKEUP_TIME                 : integer := 0
    );
    port (
        SLEEP                       : in  std_logic;
        RST                         : in  std_logic;
        WR_CLK                      : in  std_logic;
        WR_EN                       : in  std_logic;
        DIN                         : in  std_logic_vector(WRITE_DATA_WIDTH-1 downto 0);
        FULL                        : out std_logic;
        PROG_FULL                   : out std_logic;
        WR_DATA_COUNT               : out std_logic_vector(WR_DATA_COUNT_WIDTH-1 downto 0);
        OVERFLOW                    : out std_logic;
        WR_RST_BUSY                 : out std_logic;
        ALMOST_FULL                 : out std_logic;
        WR_ACK                      : out std_logic;
        RD_EN                       : in  std_logic;
        DOUT                        : out std_logic_vector(READ_DATA_WIDTH-1 downto 0);
        EMPTY                       : out std_logic;
        PROG_EMPTY                  : out std_logic;
        RD_DATA_COUNT               : out std_logic_vector(RD_DATA_COUNT_WIDTH-1 downto 0);
        UNDERFLOW                   : out std_logic;
        RD_RST_BUSY                 : out std_logic;
        ALMOST_EMPTY                : out std_logic;
        DATA_VALID                  : out std_logic;
        INJECTSBITERR               : in  std_logic;
        INJECTDBITERR               : in  std_logic;
        SBITERR                     : out std_logic;
        DBITERR                     : out std_logic
    );
    end component;

begin

    DATA_COUNT(31 downto LOG2(WRITE_DEPTH)+1) <= (others => '0');

--------------------------------------------------------------------------------
-- Component mapping
--------------------------------------------------------------------------------

    u_FIFO : XPM_FIFO_SYNC
    generic map(
        FIFO_MEMORY_TYPE            => MEMORY_TYPE                             ,--: string := "auto";
        FIFO_WRITE_DEPTH            => WRITE_DEPTH                             ,--: integer := 2048;
        WRITE_DATA_WIDTH            => WRITE_WIDTH                             ,--: integer := 32;
        READ_MODE                   => "fwft"                                  ,--: string := "std";
        FIFO_READ_LATENCY           => 0                                       ,--: integer := 1;
        FULL_RESET_VALUE            => 0                                       ,--: integer := 0;
        USE_ADV_FEATURES            => "0705"                                  ,--: string := "0707";
        READ_DATA_WIDTH             => WRITE_WIDTH                             ,--: integer := 32;
        WR_DATA_COUNT_WIDTH         => LOG2(WRITE_DEPTH)+1                     ,--: integer := 1;
        PROG_FULL_THRESH            => 10                                      ,--: integer := 10;
        RD_DATA_COUNT_WIDTH         => LOG2(WRITE_DEPTH)+1                     ,--: integer := 1;
        PROG_EMPTY_THRESH           => 10                                      ,--: integer := 10;
        DOUT_RESET_VALUE            => "0"                                     ,--: string := "0";
        ECC_MODE                    => "no_ecc"                                ,--: string := "no_ecc";
        SIM_ASSERT_CHK              => 1                                       ,--: integer := 0;
        WAKEUP_TIME                 => 0                                        --: integer := 0
    )
    port map(
        SLEEP                       => '0'                                     ,--: in  std_logic;
        RST                         => SRST                                    ,--: in  std_logic;
        WR_CLK                      => CLK                                     ,--: in  std_logic;
        WR_EN                       => WR_EN                                   ,--: in  std_logic;
        DIN                         => DIN                                     ,--: in  std_logic_vector(WRITE_DATA_WIDTH-1 downto 0);
        FULL                        => FULL                                    ,--: out std_logic;
        PROG_FULL                   => open                                    ,--: out std_logic;
        WR_DATA_COUNT               => DATA_COUNT(LOG2(WRITE_DEPTH) downto 0)  ,--: out std_logic_vector(WR_DATA_COUNT_WIDTH-1 downto 0);
        OVERFLOW                    => open                                    ,--: out std_logic;
        WR_RST_BUSY                 => WR_RST_BUSY                             ,--: out std_logic;
        ALMOST_FULL                 => open                                    ,--: out std_logic;
        WR_ACK                      => open                                    ,--: out std_logic;
        RD_EN                       => RD_EN                                   ,--: in  std_logic;
        DOUT                        => DOUT                                    ,--: out std_logic_vector(READ_DATA_WIDTH-1 downto 0);
        EMPTY                       => EMPTY                                   ,--: out std_logic;
        PROG_EMPTY                  => open                                    ,--: out std_logic;
        RD_DATA_COUNT               => open                                    ,--: out std_logic_vector(RD_DATA_COUNT_WIDTH-1 downto 0);
        UNDERFLOW                   => open                                    ,--: out std_logic;
        RD_RST_BUSY                 => RD_RST_BUSY                             ,--: out std_logic;
        ALMOST_EMPTY                => open                                    ,--: out std_logic;
        DATA_VALID                  => open                                    ,--: out std_logic;
        INJECTSBITERR               => '0'                                     ,--: in  std_logic;
        INJECTDBITERR               => '0'                                     ,--: in  std_logic;
        SBITERR                     => open                                    ,--: out std_logic;
        DBITERR                     => open                                     --: out std_logic
    );

end BEHAVE;