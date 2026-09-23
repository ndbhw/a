--------------------------------------------------------------------------------
--
-- Copyright (C) 2022, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2022.02.16
--------------------------------------------------------------------------------
-- Function description
--   1. Performance measurement component
--   2. FIFO for time stamp (16-depth)
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2022.02.16) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library XPM;
use XPM.VCOMPONENTS.ALL;

entity TIMESTAMP is
    generic (
        FIFO_WIDTH                  : natural := 16
    );
    port (
        RST                         : in  std_logic;
        WR_CLK                      : in  std_logic;
        RD_CLK                      : in  std_logic;
        DIN                         : in  std_logic_vector(FIFO_WIDTH-1 downto 0);
        WR_EN                       : in  std_logic;
        RD_EN                       : in  std_logic;
        DOUT                        : out std_logic_vector(FIFO_WIDTH-1 downto 0);
        FULL                        : out std_logic;
        EMPTY                       : out std_logic;
        WR_DATA_COUNT               : out std_logic_vector(3 downto 0)
    );
end TIMESTAMP;

architecture BEHAVE of TIMESTAMP is

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

    signal sreset                   : std_logic;

    component XPM_FIFO_ASYNC is
    generic (
        -- Common module generics
        FIFO_MEMORY_TYPE            : string := "auto";                         -- Allowed values: auto, block, distributed. Default value = auto.
        FIFO_WRITE_DEPTH            : integer := 2048;
        RELATED_CLOCKS              : integer := 0;
        WRITE_DATA_WIDTH            : integer := 32;
        READ_MODE                   : string := "std";                           -- Allowed values: std, fwft. Default value = std.
        FIFO_READ_LATENCY           : integer := 1;
        FULL_RESET_VALUE            : integer := 0;
        USE_ADV_FEATURES            : string := "0707";
        READ_DATA_WIDTH             : integer := 32;
        CDC_SYNC_STAGES             : integer := 2;
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
        RD_CLK                      : in  std_logic;
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

--------------------------------------------------------------------------------
-- Synchronous reset
--------------------------------------------------------------------------------

    u_RST : RST_SYNC
    generic map(
        DLY_NUM                     => 4                                       ,--: natural := 4;
        MAX_FANOUT_NUM              => 200                                      --: integer := 200
    )
    port map(
        RST_IN                      => RST                                     ,--: in  std_logic;
        CLK                         => WR_CLK                                  ,--: in  std_logic;
        RST_OUT                     => sreset                                   --: out std_logic
    );

--------------------------------------------------------------------------------
-- FIFO
--------------------------------------------------------------------------------

    u_FIFO : XPM_FIFO_ASYNC
    generic map(
        FIFO_MEMORY_TYPE            => "distributed"                           ,--: string := "auto";
        FIFO_WRITE_DEPTH            => 16                                      ,--: integer := 2048;
        RELATED_CLOCKS              => 0                                       ,--: integer := 0;
        WRITE_DATA_WIDTH            => FIFO_WIDTH                              ,--: integer := 32;
        READ_MODE                   => "fwft"                                  ,--: string := "std";
        FIFO_READ_LATENCY           => 0                                       ,--: integer := 1;
        FULL_RESET_VALUE            => 0                                       ,--: integer := 0;
        USE_ADV_FEATURES            => "0505"                                  ,--: string := "0707";
        READ_DATA_WIDTH             => FIFO_WIDTH                              ,--: integer := 32;
        CDC_SYNC_STAGES             => 2                                       ,--: integer := 2;
        WR_DATA_COUNT_WIDTH         => 4                                       ,--: integer := 1;
        PROG_FULL_THRESH            => 16                                      ,--: integer := 10;
        RD_DATA_COUNT_WIDTH         => 4                                       ,--: integer := 1;
        PROG_EMPTY_THRESH           => 10                                      ,--: integer := 10;
        DOUT_RESET_VALUE            => "0"                                     ,--: string := "0";
        ECC_MODE                    => "no_ecc"                                ,--: string := "no_ecc";
        SIM_ASSERT_CHK              => 1                                       ,--: integer := 0;
        WAKEUP_TIME                 => 0                                        --: integer := 0
    )
    port map(
        SLEEP                       => '0'                                     ,--: in  std_logic;
        RST                         => sreset                                  ,--: in  std_logic;
        WR_CLK                      => WR_CLK                                  ,--: in  std_logic;
        WR_EN                       => WR_EN                                   ,--: in  std_logic;
        DIN                         => DIN                                     ,--: in  std_logic_vector(WRITE_DATA_WIDTH-1 downto 0);
        FULL                        => FULL                                    ,--: out std_logic;
        PROG_FULL                   => open                                    ,--: out std_logic;
        WR_DATA_COUNT               => WR_DATA_COUNT                           ,--: out std_logic_vector(WR_DATA_COUNT_WIDTH-1 downto 0);
        OVERFLOW                    => open                                    ,--: out std_logic;
        WR_RST_BUSY                 => open                                    ,--: out std_logic;
        ALMOST_FULL                 => open                                    ,--: out std_logic;
        WR_ACK                      => open                                    ,--: out std_logic;
        RD_CLK                      => RD_CLK                                  ,--: in  std_logic;
        RD_EN                       => RD_EN                                   ,--: in  std_logic;
        DOUT                        => DOUT                                    ,--: out std_logic_vector(READ_DATA_WIDTH-1 downto 0);
        EMPTY                       => EMPTY                                   ,--: out std_logic;
        PROG_EMPTY                  => open                                    ,--: out std_logic;
        RD_DATA_COUNT               => open                                    ,--: out std_logic_vector(RD_DATA_COUNT_WIDTH-1 downto 0);
        UNDERFLOW                   => open                                    ,--: out std_logic;
        RD_RST_BUSY                 => open                                    ,--: out std_logic;
        ALMOST_EMPTY                => open                                    ,--: out std_logic;
        DATA_VALID                  => open                                    ,--: out std_logic;
        INJECTSBITERR               => '0'                                     ,--: in  std_logic;
        INJECTDBITERR               => '0'                                     ,--: in  std_logic;
        SBITERR                     => open                                    ,--: out std_logic;
        DBITERR                     => open                                     --: out std_logic
    );

end BEHAVE;