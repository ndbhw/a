--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : Buffer 32x32K (O-RAN component)                               --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.15                                                    --
--                                                                            --
--------------------------------------------------------------------------------
-- Read latency 3-clocks                                                      --
-- Read depth   32,768 (4-banks)                                              --
-- Maximum read range on 1 cycle, it is limited to 8192                       --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity BUFFER_32x32K is
    port (
        CLK                         : in  std_logic;
        ENA                         : in  std_logic;
        WEA                         : in  std_logic_vector(0 downto 0);
        ADDRA                       : in  std_logic_vector(14 downto 0);
        DINA                        : in  std_logic_vector(31 downto 0);
        ENB                         : in  std_logic;
        ADDRB                       : in  std_logic_vector(14 downto 0);
        DOUTB                       : out std_logic_vector(31 downto 0)
    );
end BUFFER_32x32K;

architecture BEHAVE of BUFFER_32x32K is

    component BUFFER_32x8K is
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
    end component;

    signal buffer0_ena              : std_logic;
    signal buffer0_wea              : std_logic_vector(0 downto 0);
    signal buffer0_enb              : std_logic;
    signal buffer0_doutb            : std_logic_vector(31 downto 0);

    signal buffer1_ena              : std_logic;
    signal buffer1_wea              : std_logic_vector(0 downto 0);
    signal buffer1_enb              : std_logic;
    signal buffer1_doutb            : std_logic_vector(31 downto 0);

    signal buffer2_ena              : std_logic;
    signal buffer2_wea              : std_logic_vector(0 downto 0);
    signal buffer2_enb              : std_logic;
    signal buffer2_doutb            : std_logic_vector(31 downto 0);

    signal buffer3_ena              : std_logic;
    signal buffer3_wea              : std_logic_vector(0 downto 0);
    signal buffer3_enb              : std_logic;
    signal buffer3_doutb            : std_logic_vector(31 downto 0);

begin

    buffer0_ena <= ENA when ADDRA(14 downto 13) = "00" else '0';
    buffer0_wea <= WEA when ADDRA(14 downto 13) = "00" else "0";
    buffer1_ena <= ENA when ADDRA(14 downto 13) = "01" else '0';
    buffer1_wea <= WEA when ADDRA(14 downto 13) = "01" else "0";
    buffer2_ena <= ENA when ADDRA(14 downto 13) = "10" else '0';
    buffer2_wea <= WEA when ADDRA(14 downto 13) = "10" else "0";
    buffer3_ena <= ENA when ADDRA(14 downto 13) = "11" else '0';
    buffer3_wea <= WEA when ADDRA(14 downto 13) = "11" else "0";

    buffer0_enb <= ENB when ADDRB(14 downto 13) = "00" else '0';
    buffer1_enb <= ENB when ADDRB(14 downto 13) = "01" else '0';
    buffer2_enb <= ENB when ADDRB(14 downto 13) = "10" else '0';
    buffer3_enb <= ENB when ADDRB(14 downto 13) = "11" else '0';

--    process (CLK)
--    begin
--        if (CLK'event and CLK = '1') then
            DOUTB <= buffer0_doutb or buffer1_doutb or buffer2_doutb or buffer3_doutb;
--        end if;
--    end process;

--------------------------------------------------------------------------------
-- Component mapping
--------------------------------------------------------------------------------

    u_BUFFER0 : BUFFER_32x8K
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        ENA                         => buffer0_ena                             ,--: in  std_logic;
        WEA                         => buffer0_wea                             ,--: in  std_logic_vector(0 downto 0);
        ADDRA                       => ADDRA(12 downto 0)                      ,--: in  std_logic_vector(12 downto 0);
        DINA                        => DINA                                    ,--: in  std_logic_vector(31 downto 0);
        ENB                         => buffer0_enb                             ,--: in  std_logic;
        ADDRB                       => ADDRB(12 downto 0)                      ,--: in  std_logic_vector(12 downto 0);
        DOUTB                       => buffer0_doutb                            --: out std_logic_vector(31 downto 0)
    );

    u_BUFFER1 : BUFFER_32x8K
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        ENA                         => buffer1_ena                             ,--: in  std_logic;
        WEA                         => buffer1_wea                             ,--: in  std_logic_vector(0 downto 0);
        ADDRA                       => ADDRA(12 downto 0)                      ,--: in  std_logic_vector(12 downto 0);
        DINA                        => DINA                                    ,--: in  std_logic_vector(31 downto 0);
        ENB                         => buffer1_enb                             ,--: in  std_logic;
        ADDRB                       => ADDRB(12 downto 0)                      ,--: in  std_logic_vector(12 downto 0);
        DOUTB                       => buffer1_doutb                            --: out std_logic_vector(31 downto 0)
    );

    u_BUFFER2 : BUFFER_32x8K
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        ENA                         => buffer2_ena                             ,--: in  std_logic;
        WEA                         => buffer2_wea                             ,--: in  std_logic_vector(0 downto 0);
        ADDRA                       => ADDRA(12 downto 0)                      ,--: in  std_logic_vector(12 downto 0);
        DINA                        => DINA                                    ,--: in  std_logic_vector(31 downto 0);
        ENB                         => buffer2_enb                             ,--: in  std_logic;
        ADDRB                       => ADDRB(12 downto 0)                      ,--: in  std_logic_vector(12 downto 0);
        DOUTB                       => buffer2_doutb                            --: out std_logic_vector(31 downto 0)
    );

    u_BUFFER3 : BUFFER_32x8K
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        ENA                         => buffer3_ena                             ,--: in  std_logic;
        WEA                         => buffer3_wea                             ,--: in  std_logic_vector(0 downto 0);
        ADDRA                       => ADDRA(12 downto 0)                      ,--: in  std_logic_vector(12 downto 0);
        DINA                        => DINA                                    ,--: in  std_logic_vector(31 downto 0);
        ENB                         => buffer3_enb                             ,--: in  std_logic;
        ADDRB                       => ADDRB(12 downto 0)                      ,--: in  std_logic_vector(12 downto 0);
        DOUTB                       => buffer3_doutb                            --: out std_logic_vector(31 downto 0)
    );

end BEHAVE;