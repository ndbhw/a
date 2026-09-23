--------------------------------------------------------------------------------
--
-- Copyright (C) 2022, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2022.02.16
--------------------------------------------------------------------------------
-- Function description
--   1. Common component
--   2. Buffer
--     1) Dimension : 32x8192
--     2) Read latency : 3-clocks
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2022.02.16) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

entity BUFFER_32x8K is
    port (
        CLK                         : in  std_logic;
        ENA                         : in  std_logic;
        WEA                         : in  std_logic_vector(0 downto 0);
        ADDRA                       : in  std_logic_vector(12 downto 0);
        DINA                        : in  std_logic_vector(31 downto 0);
        ENB                         : in  std_logic;
        ADDRB                       : in  std_logic_vector(12 downto 0);
        DOUTB                       : out std_logic_vector(31 downto 0)
    );
end BUFFER_32x8K;

architecture BEHAVE of BUFFER_32x8K is

    component URAM288_BASE is
    generic (
        AUTO_SLEEP_LATENCY          : integer := 8;
        AVG_CONS_INACTIVE_CYCLES    : integer := 10;
        BWE_MODE_A                  : string := "PARITY_INTERLEAVED";
        BWE_MODE_B                  : string := "PARITY_INTERLEAVED";
        EN_AUTO_SLEEP_MODE          : string := "FALSE";
        EN_ECC_RD_A                 : string := "FALSE";
        EN_ECC_RD_B                 : string := "FALSE";
        EN_ECC_WR_A                 : string := "FALSE";
        EN_ECC_WR_B                 : string := "FALSE";
        IREG_PRE_A                  : string := "FALSE";
        IREG_PRE_B                  : string := "FALSE";
        IS_CLK_INVERTED             : bit := '0';
        IS_EN_A_INVERTED            : bit := '0';
        IS_EN_B_INVERTED            : bit := '0';
        IS_RDB_WR_A_INVERTED        : bit := '0';
        IS_RDB_WR_B_INVERTED        : bit := '0';
        IS_RST_A_INVERTED           : bit := '0';
        IS_RST_B_INVERTED           : bit := '0';
        OREG_A                      : string := "FALSE";
        OREG_B                      : string := "FALSE";
        OREG_ECC_A                  : string := "FALSE";
        OREG_ECC_B                  : string := "FALSE";
        RST_MODE_A                  : string := "SYNC";
        RST_MODE_B                  : string := "SYNC";
        USE_EXT_CE_A                : string := "FALSE";
        USE_EXT_CE_B                : string := "FALSE"
    );
    port (
        DBITERR_A                   : out std_ulogic;
        DBITERR_B                   : out std_ulogic;
        DOUT_A                      : out std_logic_vector(71 downto 0);
        DOUT_B                      : out std_logic_vector(71 downto 0);
        SBITERR_A                   : out std_ulogic;
        SBITERR_B                   : out std_ulogic;
        ADDR_A                      : in  std_logic_vector(22 downto 0);
        ADDR_B                      : in  std_logic_vector(22 downto 0);
        BWE_A                       : in  std_logic_vector(8 downto 0);
        BWE_B                       : in  std_logic_vector(8 downto 0);
        CLK                         : in  std_ulogic;
        DIN_A                       : in  std_logic_vector(71 downto 0);
        DIN_B                       : in  std_logic_vector(71 downto 0);
        EN_A                        : in  std_ulogic;
        EN_B                        : in  std_ulogic;
        INJECT_DBITERR_A            : in  std_ulogic;
        INJECT_DBITERR_B            : in  std_ulogic;
        INJECT_SBITERR_A            : in  std_ulogic;
        INJECT_SBITERR_B            : in  std_ulogic;
        OREG_CE_A                   : in  std_ulogic;
        OREG_CE_B                   : in  std_ulogic;
        OREG_ECC_CE_A               : in  std_ulogic;
        OREG_ECC_CE_B               : in  std_ulogic;
        RDB_WR_A                    : in  std_ulogic;
        RDB_WR_B                    : in  std_ulogic;
        RST_A                       : in  std_ulogic;
        RST_B                       : in  std_ulogic;
        SLEEP                       : in  std_ulogic
    );
    end component;

    signal dout_b                   : std_logic_vector(71 downto 0) := (others => '0');
    signal addr_a                   : std_logic_vector(22 downto 0) := (others => '0');
    signal addr_b                   : std_logic_vector(22 downto 0) := (others => '0');
    signal bwe_a                    : std_logic_vector(8 downto 0);
    signal din_a                    : std_logic_vector(71 downto 0) := (others => '0');

    signal lsb                      : std_logic_vector(1 downto 0) := (others => '0');

begin

    addr_a(11 downto 0) <= ADDRA(12 downto 1);
    addr_b(11 downto 0) <= ADDRB(12 downto 1);
    bwe_a               <= '0' &          WEA & WEA & WEA & WEA & "0000" when ADDRA(0) = '1' else
                           '0' & "0000" & WEA & WEA & WEA & WEA;
    din_a               <= x"00" & DINA & DINA;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            lsb <= lsb(0) & ADDRB(0);
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (ENB = '1') then
                if (lsb(1) = '0') then
                    DOUTB <= dout_b(31 downto 0);
                else
                    DOUTB <= dout_b(63 downto 32);
                end if;
            else
                DOUTB <= (others => '0');
            end if;
        end if;
    end process;

    u_INST : URAM288_BASE
    generic map(
        AUTO_SLEEP_LATENCY          => 8                                       ,--: integer := 8;
        AVG_CONS_INACTIVE_CYCLES    => 10                                      ,--: integer := 10;
        BWE_MODE_A                  => "PARITY_INDEPENDENT"                    ,--: string := "PARITY_INTERLEAVED";
        BWE_MODE_B                  => "PARITY_INDEPENDENT"                    ,--: string := "PARITY_INTERLEAVED";
        EN_AUTO_SLEEP_MODE          => "FALSE"                                 ,--: string := "FALSE";
        EN_ECC_RD_A                 => "FALSE"                                 ,--: string := "FALSE";
        EN_ECC_RD_B                 => "FALSE"                                 ,--: string := "FALSE";
        EN_ECC_WR_A                 => "FALSE"                                 ,--: string := "FALSE";
        EN_ECC_WR_B                 => "FALSE"                                 ,--: string := "FALSE";
        IREG_PRE_A                  => "FALSE"                                 ,--: string := "FALSE";
        IREG_PRE_B                  => "FALSE"                                 ,--: string := "FALSE";
        IS_CLK_INVERTED             => '0'                                     ,--: bit := '0';
        IS_EN_A_INVERTED            => '0'                                     ,--: bit := '0';
        IS_EN_B_INVERTED            => '0'                                     ,--: bit := '0';
        IS_RDB_WR_A_INVERTED        => '0'                                     ,--: bit := '0';
        IS_RDB_WR_B_INVERTED        => '0'                                     ,--: bit := '0';
        IS_RST_A_INVERTED           => '0'                                     ,--: bit := '0';
        IS_RST_B_INVERTED           => '0'                                     ,--: bit := '0';
        OREG_A                      => "TRUE"                                  ,--: string := "FALSE";
        OREG_B                      => "TRUE"                                  ,--: string := "FALSE";
        OREG_ECC_A                  => "FALSE"                                 ,--: string := "FALSE";
        OREG_ECC_B                  => "FALSE"                                 ,--: string := "FALSE";
        RST_MODE_A                  => "SYNC"                                  ,--: string := "SYNC";
        RST_MODE_B                  => "SYNC"                                  ,--: string := "SYNC";
        USE_EXT_CE_A                => "TRUE"                                  ,--: string := "FALSE";
        USE_EXT_CE_B                => "TRUE"                                   --: string := "FALSE"
    )
    port map(
        DBITERR_A                   => open                                    ,--: out std_ulogic;
        DBITERR_B                   => open                                    ,--: out std_ulogic;
        DOUT_A                      => open                                    ,--: out std_logic_vector(71 downto 0);
        DOUT_B                      => dout_b                                  ,--: out std_logic_vector(71 downto 0);
        SBITERR_A                   => open                                    ,--: out std_ulogic;
        SBITERR_B                   => open                                    ,--: out std_ulogic;
        ADDR_A                      => addr_a                                  ,--: in  std_logic_vector(22 downto 0);
        ADDR_B                      => addr_b                                  ,--: in  std_logic_vector(22 downto 0);
        BWE_A                       => bwe_a                                   ,--: in  std_logic_vector(8 downto 0);
        BWE_B                       => (others => '0')                         ,--: in  std_logic_vector(8 downto 0);
        CLK                         => CLK                                     ,--: in  std_ulogic;
        DIN_A                       => din_a                                   ,--: in  std_logic_vector(71 downto 0);
        DIN_B                       => (others => '0')                         ,--: in  std_logic_vector(71 downto 0);
        EN_A                        => ENA                                     ,--: in  std_ulogic;
        EN_B                        => ENB                                     ,--: in  std_ulogic;
        INJECT_DBITERR_A            => '0'                                     ,--: in  std_ulogic;
        INJECT_DBITERR_B            => '0'                                     ,--: in  std_ulogic;
        INJECT_SBITERR_A            => '0'                                     ,--: in  std_ulogic;
        INJECT_SBITERR_B            => '0'                                     ,--: in  std_ulogic;
        OREG_CE_A                   => ENA                                     ,--: in  std_ulogic;
        OREG_CE_B                   => ENB                                     ,--: in  std_ulogic;
        OREG_ECC_CE_A               => '0'                                     ,--: in  std_ulogic;
        OREG_ECC_CE_B               => '0'                                     ,--: in  std_ulogic;
        RDB_WR_A                    => '1'                                     ,--: in  std_ulogic;
        RDB_WR_B                    => '0'                                     ,--: in  std_ulogic;
        RST_A                       => '0'                                     ,--: in  std_ulogic;
        RST_B                       => '0'                                     ,--: in  std_ulogic;
        SLEEP                       => '0'                                      --: in  std_ulogic
    );

end BEHAVE;