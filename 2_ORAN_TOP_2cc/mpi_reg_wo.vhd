--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : Register, WRITE-ONLY (MPI component)                          --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.15                                                    --
--                                                                            --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MPI_REG_WO is
    generic (
        IMPL_INDEX                  : natural := 0;
        IMPL_MAP                    : std_logic_vector(63 downto 0);

        BIT_WIDTH                   : natural := 32;
        REG_ADDR                    : std_logic_vector(7 downto 0) := (others => '0');
        REG_DATA                    : std_logic_vector(31 downto 0) := (others => '0')
    );
    port (
        RESET                       : in  std_logic;
        CLK                         : in  std_logic;

        ACTIVE                      : in  std_logic;
        EN                          : in  std_logic;                            -- 1-pulse@CLK
        ADDR                        : in  std_logic_vector(7 downto 0);
        DATA_IN                     : in  std_logic_vector(31 downto 0);
        DATA_OUT                    : out std_logic_vector(BIT_WIDTH-1 downto 0)
    );
end MPI_REG_WO;

architecture BEHAVE of MPI_REG_WO is

begin

    u_USED : if IMPL_MAP(IMPL_INDEX) = '1' generate
    process (RESET, CLK)
    begin
        if (RESET = '1') then
            DATA_OUT <= REG_DATA(BIT_WIDTH-1 downto 0);
        elsif (CLK'event and CLK = '1') then
            if (ACTIVE = '1') and (EN = '1') and (ADDR = REG_ADDR) then
                DATA_OUT <= DATA_IN(BIT_WIDTH-1 downto 0);
            end if;
        end if;
    end process;
    end generate;

    u_UNUSED : if IMPL_MAP(IMPL_INDEX) = '0' generate
    DATA_OUT <= (others => '0');
    end generate;

end BEHAVE;