--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : Register, WRITE-CLEAR (MPI component)                         --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.15                                                    --
--                                                                            --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MPI_REG_WC is
    generic (
        REG_ADDR                    : std_logic_vector(7 downto 0) := (others => '0')
    );
    port (
        RESET                       : in  std_logic;
        CLK                         : in  std_logic;

        EN                          : in  std_logic;                            -- 1-pulse@CLK
        ADDR                        : in  std_logic_vector(7 downto 0);
        DATA_OUT                    : out std_logic                             -- 1-pulse@CLK
    );
end MPI_REG_WC;

architecture BEHAVE of MPI_REG_WC is

    signal enable                   : std_logic;

begin

    process (RESET, CLK)
    begin
        if (RESET = '1') then
            enable <= '0';
        elsif (CLK'event and CLK = '1') then
            if (ADDR = REG_ADDR) and (EN = '1') then
                enable <= '1';
            else
                enable <= '0';
            end if;
        end if;
    end process;

    DATA_OUT <= enable;

end BEHAVE;
