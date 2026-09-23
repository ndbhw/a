--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : Register, 8-to-1 read (MPI component)                         --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.15                                                    --
--                                                                            --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.ARRAY_TYPE.ALL;

entity MPI_REG_RD8 is
    generic (
        OUTPUT_REG                  : boolean := true;
        INDEX_VALUE                 : natural := 8;                             -- 1 ~ 8
        DATA_BIT                    : natural := 32                             -- 1 ~ 32
    );
    port (
        CLK                         : in  std_logic;

        INDEX                       : in  std_logic_vector(2 downto 0);         -- 0 ~ 7
        INPUT                       : in  std_logic_array32(7 downto 0);
        OUTPUT                      : out std_logic_vector(31 downto 0)
    );
end MPI_REG_RD8;

architecture BEHAVE of MPI_REG_RD8 is

    type buf_logic_vector           is array(natural range <>) of std_logic_vector(DATA_BIT-1 downto 0);

    signal temp_data                : buf_logic_vector(7 downto 0);
    signal temp_output              : std_logic_vector(DATA_BIT-1 downto 0);

begin

    temp_data(0) <= INPUT(0)(DATA_BIT-1 downto 0) when INDEX_VALUE > 0 else (others => '0');
    temp_data(1) <= INPUT(1)(DATA_BIT-1 downto 0) when INDEX_VALUE > 1 else (others => '0');
    temp_data(2) <= INPUT(2)(DATA_BIT-1 downto 0) when INDEX_VALUE > 2 else (others => '0');
    temp_data(3) <= INPUT(3)(DATA_BIT-1 downto 0) when INDEX_VALUE > 3 else (others => '0');
    temp_data(4) <= INPUT(4)(DATA_BIT-1 downto 0) when INDEX_VALUE > 4 else (others => '0');
    temp_data(5) <= INPUT(5)(DATA_BIT-1 downto 0) when INDEX_VALUE > 5 else (others => '0');
    temp_data(6) <= INPUT(6)(DATA_BIT-1 downto 0) when INDEX_VALUE > 6 else (others => '0');
    temp_data(7) <= INPUT(7)(DATA_BIT-1 downto 0) when INDEX_VALUE > 7 else (others => '0');

    process (INDEX, temp_data)
    begin
        case INDEX is
        when "000"  => temp_output <= temp_data(0);
        when "001"  => temp_output <= temp_data(1);
        when "010"  => temp_output <= temp_data(2);
        when "011"  => temp_output <= temp_data(3);
        when "100"  => temp_output <= temp_data(4);
        when "101"  => temp_output <= temp_data(5);
        when "110"  => temp_output <= temp_data(6);
        when "111"  => temp_output <= temp_data(7);
        when others => temp_output <= (others => '0');
        end case;
    end process;

    u_OUTPUT_REG_USED : if OUTPUT_REG = true generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            OUTPUT <= EXT(temp_output(DATA_BIT-1 downto 0), 32);
        end if;
    end process;
    end generate;

    u_OUTPUT_REG_UNUSED : if OUTPUT_REG = false generate
--    process (CLK)
--    begin
--        if (CLK'event and CLK = '1') then
            OUTPUT <= EXT(temp_output(DATA_BIT-1 downto 0), 32);
--        end if;
--    end process;
    end generate;


end BEHAVE;
