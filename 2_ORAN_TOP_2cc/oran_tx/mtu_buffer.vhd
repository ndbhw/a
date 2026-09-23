--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : MTU buffer (O-RAN component)                                  --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.15                                                    --
--                                                                            --
--------------------------------------------------------------------------------
-- Read latency 3-clocks                                                      --
-- Read depth   2,560                                                         --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library XPM;
use XPM.VCOMPONENTS.ALL;

entity MTU_BUFFER is
    port (
        CLKA                        : in  std_logic;
        ENA                         : in  std_logic;
        WEA                         : in  std_logic_vector(3 downto 0);
        ADDRA                       : in  std_logic_vector(11 downto 0);
        DINA                        : in  std_logic_vector(35 downto 0);
        CLKB                        : in  std_logic;
        ENB                         : in  std_logic;
        ADDRB                       : in  std_logic_vector(10 downto 0);
        DOUTB                       : out std_logic_vector(71 downto 0)
    );
end MTU_BUFFER;

architecture BEHAVE of MTU_BUFFER is

    component XPM_MEMORY_TDPRAM is
    generic (
        -- Common module generics
        MEMORY_SIZE                 : integer := 2048;
        MEMORY_PRIMITIVE            : string := "auto";                         -- Allowed values: auto, block, distributed, ultra. Default value = auto.
        CLOCKING_MODE               : string := "common_clock";                 -- Allowed values: common_clock, independent_clock. Default value = common_clock.
        ECC_MODE                    : string := "no_ecc";
        MEMORY_INIT_FILE            : string := "none";
        MEMORY_INIT_PARAM           : string := "";
        USE_MEM_INIT                : integer := 1;
        WAKEUP_TIME                 : string := "disable_sleep";                -- Allowed values: disable_sleep, use_sleep_pin. Default value = disable_sleep.
        AUTO_SLEEP_TIME             : integer := 0;
        MESSAGE_CONTROL             : integer := 0;
        USE_EMBEDDED_CONSTRAINT     : integer := 0;
        MEMORY_OPTIMIZATION         : string := "true";
        CASCADE_HEIGHT              : integer := 0;
        SIM_ASSERT_CHK              : integer := 0;

        -- Port A module generics
        WRITE_DATA_WIDTH_A          : integer := 32;
        READ_DATA_WIDTH_A           : integer := 32;
        BYTE_WRITE_WIDTH_A          : integer := 32;
        ADDR_WIDTH_A                : integer := 6;
        READ_RESET_VALUE_A          : string := "0";
        READ_LATENCY_A              : integer := 2;
        WRITE_MODE_A                : string := "no_change";                    -- Allowed values: no_change, read_first, write_first. Default value = no_change.
        RST_MODE_A                  : string := "SYNC";                         -- Allowed values: SYNC, ASYNC. Default value = SYNC.

        -- Port B module generics
        WRITE_DATA_WIDTH_B          : integer := 32;
        READ_DATA_WIDTH_B           : integer := 32;
        BYTE_WRITE_WIDTH_B          : integer := 32;
        ADDR_WIDTH_B                : integer := 6;
        READ_RESET_VALUE_B          : string := "0";
        READ_LATENCY_B              : integer := 2;
        WRITE_MODE_B                : string := "no_change";                    -- Allowed values: no_change, read_first, write_first. Default value = no_change.
        RST_MODE_B                  : string := "SYNC"                          -- Allowed values: SYNC, ASYNC. Default value = SYNC.
    );
    port (
        -- Common module ports
        SLEEP                       : in  std_logic;

        -- Port A module ports
        CLKA                        : in  std_logic;
        RSTA                        : in  std_logic;
        ENA                         : in  std_logic;
        REGCEA                      : in  std_logic;
        WEA                         : in  std_logic_vector((WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A)-1 downto 0);
        ADDRA                       : in  std_logic_vector(ADDR_WIDTH_A-1 downto 0);
        DINA                        : in  std_logic_vector(WRITE_DATA_WIDTH_A-1 downto 0);
        INJECTSBITERRA              : in  std_logic;
        INJECTDBITERRA              : in  std_logic;
        DOUTA                       : out std_logic_vector(READ_DATA_WIDTH_A-1 downto 0);
        SBITERRA                    : out std_logic;
        DBITERRA                    : out std_logic;

        -- Port B module ports
        CLKB                        : in  std_logic;
        RSTB                        : in  std_logic;
        ENB                         : in  std_logic;
        REGCEB                      : in  std_logic;
        WEB                         : in  std_logic_vector((WRITE_DATA_WIDTH_B/BYTE_WRITE_WIDTH_B)-1 downto 0);
        ADDRB                       : in  std_logic_vector(ADDR_WIDTH_B-1 downto 0);
        DINB                        : in  std_logic_vector(WRITE_DATA_WIDTH_B-1 downto 0);
        INJECTSBITERRB              : in  std_logic;
        INJECTDBITERRB              : in  std_logic;
        DOUTB                       : out std_logic_vector(READ_DATA_WIDTH_B-1 downto 0);
        SBITERRB                    : out std_logic;
        DBITERRB                    : out std_logic
    );
    end component;

begin


--------------------------------------------------------------------------------
-- Component mapping
--------------------------------------------------------------------------------

    u_MEMORY : XPM_MEMORY_TDPRAM
    generic map(
        MEMORY_SIZE                 => 92160                                   ,--: integer := 2048;
        MEMORY_PRIMITIVE            => "block"                                 ,--: string := "auto";
        CLOCKING_MODE               => "independent_clock"                     ,--: string := "common_clock";
        ECC_MODE                    => "no_ecc"                                ,--: string := "no_ecc";
        MEMORY_INIT_FILE            => "none"                                  ,--: string := "none";
        MEMORY_INIT_PARAM           => ""                                      ,--: string := "";
        USE_MEM_INIT                => 1                                       ,--: integer := 1;
        WAKEUP_TIME                 => "disable_sleep"                         ,--: string := "disable_sleep";
        AUTO_SLEEP_TIME             => 0                                       ,--: integer := 0;
        MESSAGE_CONTROL             => 1                                       ,--: integer := 0;
        USE_EMBEDDED_CONSTRAINT     => 0                                       ,--: integer := 0;
        MEMORY_OPTIMIZATION         => "true"                                  ,--: string := "true";
        CASCADE_HEIGHT              => 0                                       ,--: integer := 0;
        SIM_ASSERT_CHK              => 1                                       ,--: integer := 0;

        WRITE_DATA_WIDTH_A          => 36                                      ,--: integer := 32;
        READ_DATA_WIDTH_A           => 36                                      ,--: integer := 32;
        BYTE_WRITE_WIDTH_A          => 9                                       ,--: integer := 32;
        ADDR_WIDTH_A                => 12                                      ,--: integer := 6;
        READ_RESET_VALUE_A          => "0"                                     ,--: string  := "0";
        READ_LATENCY_A              => 3                                       ,--: integer := 2;
        WRITE_MODE_A                => "no_change"                             ,--: string  := "no_change";
        RST_MODE_A                  => "SYNC"                                  ,--: string  := "SYNC";

        WRITE_DATA_WIDTH_B          => 72                                      ,--: integer := 32;
        READ_DATA_WIDTH_B           => 72                                      ,--: integer := 32;
        BYTE_WRITE_WIDTH_B          => 72                                      ,--: integer := 32;
        ADDR_WIDTH_B                => 11                                      ,--: integer := 6;
        READ_RESET_VALUE_B          => "0"                                     ,--: string  := "0";
        READ_LATENCY_B              => 3                                       ,--: integer := 2;
        WRITE_MODE_B                => "read_first"                            ,--: string  := "no_change";
        RST_MODE_B                  => "SYNC"                                   --: string  := "SYNC"
    )
    port map(
        SLEEP                       => '0'                                     ,--: in  std_logic;

        CLKA                        => CLKA                                    ,--: in  std_logic;
        RSTA                        => '0'                                     ,--: in  std_logic;
        ENA                         => ENA                                     ,--: in  std_logic;
        REGCEA                      => '1'                                     ,--: in  std_logic;
        WEA                         => WEA                                     ,--: in  std_logic_vector((WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A)-1 downto 0);
        ADDRA                       => ADDRA                                   ,--: in  std_logic_vector(ADDR_WIDTH_A-1 downto 0);
        DINA                        => DINA                                    ,--: in  std_logic_vector(WRITE_DATA_WIDTH_A-1 downto 0);
        INJECTSBITERRA              => '0'                                     ,--: in  std_logic;
        INJECTDBITERRA              => '0'                                     ,--: in  std_logic;
        DOUTA                       => open                                    ,--: out std_logic_vector(READ_DATA_WIDTH_A-1 downto 0);
        SBITERRA                    => open                                    ,--: out std_logic;
        DBITERRA                    => open                                    ,--: out std_logic;

        CLKB                        => CLKB                                    ,--: in  std_logic;
        RSTB                        => '0'                                     ,--: in  std_logic;
        ENB                         => ENB                                     ,--: in  std_logic;
        REGCEB                      => '1'                                     ,--: in  std_logic;
        WEB                         => (others => '1')                         ,--: in  std_logic_vector((WRITE_DATA_WIDTH_B/BYTE_WRITE_WIDTH_B)-1 downto 0);
        ADDRB                       => ADDRB                                   ,--: in  std_logic_vector(ADDR_WIDTH_B-1 downto 0);
        DINB                        => (others => '0')                         ,--: in  std_logic_vector(WRITE_DATA_WIDTH_B-1 downto 0);
        INJECTSBITERRB              => '0'                                     ,--: in  std_logic;
        INJECTDBITERRB              => '0'                                     ,--: in  std_logic;
        DOUTB                       => DOUTB                                   ,--: out std_logic_vector(READ_DATA_WIDTH_B-1 downto 0);
        SBITERRB                    => open                                    ,--: out std_logic;
        DBITERRB                    => open                                     --: out std_logic
    );

end BEHAVE;