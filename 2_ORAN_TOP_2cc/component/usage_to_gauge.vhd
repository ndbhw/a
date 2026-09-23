--------------------------------------------------------------------------------
--
-- Copyright (C) 2022, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2022.02.16
--------------------------------------------------------------------------------
-- Function description
--   1. Common component
--   2. Convert FIFO usage to fill level gauge
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2022.02.16) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity USAGE_TO_GAUGE is
    generic (
        MAX_USAGE                   : natural := 1024
    );
    port (
        CLK                         : in  std_logic;

        USAGE                       : in  std_logic_vector(31 downto 0);
        GAUGE                       : out std_logic_vector(31 downto 0)
    );
end USAGE_TO_GAUGE;

architecture BEHAVE of USAGE_TO_GAUGE is

    function LOG2 (
        DATA_VALUE                  : integer
    )
    return integer is
        variable width              : integer := 0;
        variable cnt                : integer := 1;
    begin
        if (DATA_VALUE <= 1) then
            width := 0;
        else
            while (cnt < DATA_VALUE) loop
                width := width + 1;
                cnt   := cnt * 2;
            end loop;
        end if;
    return width;
    end LOG2;

    signal conv_usage               : std_logic_vector(4 downto 0) := (others => '0');

begin

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            conv_usage <= USAGE(LOG2(MAX_USAGE/32)+4 downto LOG2(MAX_USAGE/32));
        end if;
    end process;

    u_SET : for i in 31 downto 0 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (conv_usage = i) then
                GAUGE(i) <= '1';
            else
                GAUGE(i) <= '0';
            end if;
        end if;
    end process;
    end generate;

end BEHAVE;