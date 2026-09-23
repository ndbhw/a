--================================================================================
-- Filename     : SIZE_TAILOR.vhd
-- Author       : Taeyoup Kim (taeyoup.kim@samsung.com)
-- Description  : Total RE, RB, iFFT Size Conversion
----------------------------------------------------------------------------------
--     Date    |     By           |  Version | Description
----------------------------------------------------------------------------------
--  08-07-2020 | Taeyoup Kim      |    1.0   | Original Version
--================================================================================
-- Copyright (c) 2020 SAMSUNG. All rights reserved.
--================================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity SIZE_TAILOR is
    port (
    CLK                         : in std_logic;
    nRE                         : in std_logic_vector(11 downto 0);
    nFFT                        : in std_logic_vector(1 downto 0);
    RE_SIZE                     : out natural range 0 to 3276;
    RB_SIZE                     : out natural range 0 to 273;
    BW_iFFT_WIDTH               : out natural range 0 to 12
    );
end SIZE_TAILOR;

architecture BEHAVE of SIZE_TAILOR is

begin

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (nRE = 0) then -- for stable operation before register setting at initialization
              RE_SIZE <= 300;
              RB_SIZE <=  25;
           else
              RE_SIZE <= conv_integer(nRE);
              RB_SIZE <= conv_integer(nRE) / 12;
           end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           case (nFFT) is
               when "00"   => BW_iFFT_WIDTH <=  9;
               when "01"   => BW_iFFT_WIDTH <= 10;
               when "10"   => BW_iFFT_WIDTH <= 11;
               when "11"   => BW_iFFT_WIDTH <= 12;
               when others => BW_iFFT_WIDTH <=  9;
           end case;
        end if;
    end process;

end BEHAVE;

