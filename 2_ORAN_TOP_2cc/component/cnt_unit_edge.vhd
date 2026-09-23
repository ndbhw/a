--------------------------------------------------------------------------------
--
-- Copyright (C) 2022, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2022.02.16
--------------------------------------------------------------------------------
-- Function description
--   1. Common component
--   2. Count up
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2022.02.16) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity CNT_UNIT_EDGE is
    generic (
        EDGE                        : std_logic := '1';
        CNT_WIDTH                   : natural := 32
    );
    port (
        CLK                         : in  std_logic;

        I                           : in  std_logic;

        O                           : out std_logic_vector(31 downto 0) := (others => '0')
    );
end CNT_UNIT_EDGE;

architecture BEHAVE of CNT_UNIT_EDGE is

    signal reg                      : std_logic := not EDGE;
    signal cnt                      : std_logic_vector(CNT_WIDTH-1 downto 0) := (others => '0');

begin

    O <= EXT(cnt, 32);

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            reg <= I;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (I = not EDGE) and (reg = EDGE) then
                cnt <= cnt + 1;
            end if;
        end if;
    end process;

end BEHAVE;