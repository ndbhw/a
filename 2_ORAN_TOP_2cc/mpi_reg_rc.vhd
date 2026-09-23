--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : Register, type RO+RC, include CDC (MPI component)             --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.15                                                    --
--                                                                            --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MPI_REG_RC is
    generic (
        BIT_WIDTH                   : natural := 32;
        REG_ADDR                    : std_logic_vector(7 downto 0) := (others => '0')
    );
    port (
        RESET                       : in  std_logic;
        CLK                         : in  std_logic;

        EN                          : in  std_logic;                            -- 1-pulse@CLK
        ADDR                        : in  std_logic_vector(7 downto 0);
        DATA_IN                     : in  std_logic_vector(BIT_WIDTH-1 downto 0);
        DATA_OUT                    : out std_logic_vector(BIT_WIDTH-1 downto 0);
        FLAG_OUT                    : out std_logic_vector(BIT_WIDTH-1 downto 0)
    );
end MPI_REG_RC;

architecture BEHAVE of MPI_REG_RC is

    signal data                     : std_logic_vector(BIT_WIDTH-1 downto 0);
    signal data_ret                 : std_logic_vector(BIT_WIDTH-1 downto 0);
    signal flag_ret                 : std_logic_vector(BIT_WIDTH-1 downto 0);

begin

    process (RESET, CLK)
    begin
        if (RESET = '1') then
            data     <= (others => '0');
            data_ret <= (others => '0');
            flag_ret <= (others => '0');
            FLAG_OUT <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            for i in BIT_WIDTH-1 downto 0 loop
            data(i)     <= DATA_IN(i);
            data_ret(i) <= data(i);
            if (data_ret(i) = '1') then
                flag_ret(i) <= '1';
            elsif (EN = '1' and ADDR = REG_ADDR) then
                flag_ret(i) <= '0';
            end if;
            if (EN = '1' and ADDR = REG_ADDR) then
                FLAG_OUT(i) <= flag_ret(i);
            end if;
            end loop;
        end if;
    end process;

    DATA_OUT <= data_ret;

end BEHAVE;
