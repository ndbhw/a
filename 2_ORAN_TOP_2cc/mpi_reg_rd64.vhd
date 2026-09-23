--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : Register, 64-to-1 read (MPI component)                         --
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

entity MPI_REG_RD64 is
    generic (
        OUTPUT_REG                  : boolean := true;
        INDEX_VALUE                 : natural := 64;                            -- 1 ~ 64
        DATA_BIT                    : natural := 32                             -- 1 ~ 32
    );
    port (
        CLK                         : in  std_logic;

        INDEX                       : in  std_logic_vector(5 downto 0);         -- 0 ~ 63
        INPUT                       : in  std_logic_array32(63 downto 0);
        OUTPUT                      : out std_logic_vector(31 downto 0)
    );
end MPI_REG_RD64;

architecture BEHAVE of MPI_REG_RD64 is

    type buf_logic_vector           is array(natural range <>) of std_logic_vector(DATA_BIT-1 downto 0);

    signal temp_data                : buf_logic_vector(63 downto 0);
    signal temp_output              : std_logic_vector(DATA_BIT-1 downto 0);

begin

    temp_data(00) <= INPUT(00)(DATA_BIT-1 downto 0) when INDEX_VALUE > 00 else (others => '0');
    temp_data(01) <= INPUT(01)(DATA_BIT-1 downto 0) when INDEX_VALUE > 01 else (others => '0');
    temp_data(02) <= INPUT(02)(DATA_BIT-1 downto 0) when INDEX_VALUE > 02 else (others => '0');
    temp_data(03) <= INPUT(03)(DATA_BIT-1 downto 0) when INDEX_VALUE > 03 else (others => '0');
    temp_data(04) <= INPUT(04)(DATA_BIT-1 downto 0) when INDEX_VALUE > 04 else (others => '0');
    temp_data(05) <= INPUT(05)(DATA_BIT-1 downto 0) when INDEX_VALUE > 05 else (others => '0');
    temp_data(06) <= INPUT(06)(DATA_BIT-1 downto 0) when INDEX_VALUE > 06 else (others => '0');
    temp_data(07) <= INPUT(07)(DATA_BIT-1 downto 0) when INDEX_VALUE > 07 else (others => '0');
    temp_data(08) <= INPUT(08)(DATA_BIT-1 downto 0) when INDEX_VALUE > 08 else (others => '0');
    temp_data(09) <= INPUT(09)(DATA_BIT-1 downto 0) when INDEX_VALUE > 09 else (others => '0');
    temp_data(10) <= INPUT(10)(DATA_BIT-1 downto 0) when INDEX_VALUE > 10 else (others => '0');
    temp_data(11) <= INPUT(11)(DATA_BIT-1 downto 0) when INDEX_VALUE > 11 else (others => '0');
    temp_data(12) <= INPUT(12)(DATA_BIT-1 downto 0) when INDEX_VALUE > 12 else (others => '0');
    temp_data(13) <= INPUT(13)(DATA_BIT-1 downto 0) when INDEX_VALUE > 13 else (others => '0');
    temp_data(14) <= INPUT(14)(DATA_BIT-1 downto 0) when INDEX_VALUE > 14 else (others => '0');
    temp_data(15) <= INPUT(15)(DATA_BIT-1 downto 0) when INDEX_VALUE > 15 else (others => '0');
    temp_data(16) <= INPUT(16)(DATA_BIT-1 downto 0) when INDEX_VALUE > 16 else (others => '0');
    temp_data(17) <= INPUT(17)(DATA_BIT-1 downto 0) when INDEX_VALUE > 17 else (others => '0');
    temp_data(18) <= INPUT(18)(DATA_BIT-1 downto 0) when INDEX_VALUE > 18 else (others => '0');
    temp_data(19) <= INPUT(19)(DATA_BIT-1 downto 0) when INDEX_VALUE > 19 else (others => '0');
    temp_data(20) <= INPUT(20)(DATA_BIT-1 downto 0) when INDEX_VALUE > 20 else (others => '0');
    temp_data(21) <= INPUT(21)(DATA_BIT-1 downto 0) when INDEX_VALUE > 21 else (others => '0');
    temp_data(22) <= INPUT(22)(DATA_BIT-1 downto 0) when INDEX_VALUE > 22 else (others => '0');
    temp_data(23) <= INPUT(23)(DATA_BIT-1 downto 0) when INDEX_VALUE > 23 else (others => '0');
    temp_data(24) <= INPUT(24)(DATA_BIT-1 downto 0) when INDEX_VALUE > 24 else (others => '0');
    temp_data(25) <= INPUT(25)(DATA_BIT-1 downto 0) when INDEX_VALUE > 25 else (others => '0');
    temp_data(26) <= INPUT(26)(DATA_BIT-1 downto 0) when INDEX_VALUE > 26 else (others => '0');
    temp_data(27) <= INPUT(27)(DATA_BIT-1 downto 0) when INDEX_VALUE > 27 else (others => '0');
    temp_data(28) <= INPUT(28)(DATA_BIT-1 downto 0) when INDEX_VALUE > 28 else (others => '0');
    temp_data(29) <= INPUT(29)(DATA_BIT-1 downto 0) when INDEX_VALUE > 29 else (others => '0');
    temp_data(30) <= INPUT(30)(DATA_BIT-1 downto 0) when INDEX_VALUE > 30 else (others => '0');
    temp_data(31) <= INPUT(31)(DATA_BIT-1 downto 0) when INDEX_VALUE > 31 else (others => '0');
    temp_data(32) <= INPUT(32)(DATA_BIT-1 downto 0) when INDEX_VALUE > 32 else (others => '0');
    temp_data(33) <= INPUT(33)(DATA_BIT-1 downto 0) when INDEX_VALUE > 33 else (others => '0');
    temp_data(34) <= INPUT(34)(DATA_BIT-1 downto 0) when INDEX_VALUE > 34 else (others => '0');
    temp_data(35) <= INPUT(35)(DATA_BIT-1 downto 0) when INDEX_VALUE > 35 else (others => '0');
    temp_data(36) <= INPUT(36)(DATA_BIT-1 downto 0) when INDEX_VALUE > 36 else (others => '0');
    temp_data(37) <= INPUT(37)(DATA_BIT-1 downto 0) when INDEX_VALUE > 37 else (others => '0');
    temp_data(38) <= INPUT(38)(DATA_BIT-1 downto 0) when INDEX_VALUE > 38 else (others => '0');
    temp_data(39) <= INPUT(39)(DATA_BIT-1 downto 0) when INDEX_VALUE > 39 else (others => '0');
    temp_data(40) <= INPUT(40)(DATA_BIT-1 downto 0) when INDEX_VALUE > 40 else (others => '0');
    temp_data(41) <= INPUT(41)(DATA_BIT-1 downto 0) when INDEX_VALUE > 41 else (others => '0');
    temp_data(42) <= INPUT(42)(DATA_BIT-1 downto 0) when INDEX_VALUE > 42 else (others => '0');
    temp_data(43) <= INPUT(43)(DATA_BIT-1 downto 0) when INDEX_VALUE > 43 else (others => '0');
    temp_data(44) <= INPUT(44)(DATA_BIT-1 downto 0) when INDEX_VALUE > 44 else (others => '0');
    temp_data(45) <= INPUT(45)(DATA_BIT-1 downto 0) when INDEX_VALUE > 45 else (others => '0');
    temp_data(46) <= INPUT(46)(DATA_BIT-1 downto 0) when INDEX_VALUE > 46 else (others => '0');
    temp_data(47) <= INPUT(47)(DATA_BIT-1 downto 0) when INDEX_VALUE > 47 else (others => '0');
    temp_data(48) <= INPUT(48)(DATA_BIT-1 downto 0) when INDEX_VALUE > 48 else (others => '0');
    temp_data(49) <= INPUT(49)(DATA_BIT-1 downto 0) when INDEX_VALUE > 49 else (others => '0');
    temp_data(50) <= INPUT(50)(DATA_BIT-1 downto 0) when INDEX_VALUE > 50 else (others => '0');
    temp_data(51) <= INPUT(51)(DATA_BIT-1 downto 0) when INDEX_VALUE > 51 else (others => '0');
    temp_data(52) <= INPUT(52)(DATA_BIT-1 downto 0) when INDEX_VALUE > 52 else (others => '0');
    temp_data(53) <= INPUT(53)(DATA_BIT-1 downto 0) when INDEX_VALUE > 53 else (others => '0');
    temp_data(54) <= INPUT(54)(DATA_BIT-1 downto 0) when INDEX_VALUE > 54 else (others => '0');
    temp_data(55) <= INPUT(55)(DATA_BIT-1 downto 0) when INDEX_VALUE > 55 else (others => '0');
    temp_data(56) <= INPUT(56)(DATA_BIT-1 downto 0) when INDEX_VALUE > 56 else (others => '0');
    temp_data(57) <= INPUT(57)(DATA_BIT-1 downto 0) when INDEX_VALUE > 57 else (others => '0');
    temp_data(58) <= INPUT(58)(DATA_BIT-1 downto 0) when INDEX_VALUE > 58 else (others => '0');
    temp_data(59) <= INPUT(59)(DATA_BIT-1 downto 0) when INDEX_VALUE > 59 else (others => '0');
    temp_data(60) <= INPUT(60)(DATA_BIT-1 downto 0) when INDEX_VALUE > 60 else (others => '0');
    temp_data(61) <= INPUT(61)(DATA_BIT-1 downto 0) when INDEX_VALUE > 61 else (others => '0');
    temp_data(62) <= INPUT(62)(DATA_BIT-1 downto 0) when INDEX_VALUE > 62 else (others => '0');
    temp_data(63) <= INPUT(63)(DATA_BIT-1 downto 0) when INDEX_VALUE > 63 else (others => '0');

    process (INDEX, temp_data)
    begin
        case INDEX is
        when "000000"  => temp_output <= temp_data(00);
        when "000001"  => temp_output <= temp_data(01);
        when "000010"  => temp_output <= temp_data(02);
        when "000011"  => temp_output <= temp_data(03);
        when "000100"  => temp_output <= temp_data(04);
        when "000101"  => temp_output <= temp_data(05);
        when "000110"  => temp_output <= temp_data(06);
        when "000111"  => temp_output <= temp_data(07);
        when "001000"  => temp_output <= temp_data(08);
        when "001001"  => temp_output <= temp_data(09);
        when "001010"  => temp_output <= temp_data(10);
        when "001011"  => temp_output <= temp_data(11);
        when "001100"  => temp_output <= temp_data(12);
        when "001101"  => temp_output <= temp_data(13);
        when "001110"  => temp_output <= temp_data(14);
        when "001111"  => temp_output <= temp_data(15);
        when "010000"  => temp_output <= temp_data(16);
        when "010001"  => temp_output <= temp_data(17);
        when "010010"  => temp_output <= temp_data(18);
        when "010011"  => temp_output <= temp_data(19);
        when "010100"  => temp_output <= temp_data(20);
        when "010101"  => temp_output <= temp_data(21);
        when "010110"  => temp_output <= temp_data(22);
        when "010111"  => temp_output <= temp_data(23);
        when "011000"  => temp_output <= temp_data(24);
        when "011001"  => temp_output <= temp_data(25);
        when "011010"  => temp_output <= temp_data(26);
        when "011011"  => temp_output <= temp_data(27);
        when "011100"  => temp_output <= temp_data(28);
        when "011101"  => temp_output <= temp_data(29);
        when "011110"  => temp_output <= temp_data(30);
        when "011111"  => temp_output <= temp_data(31);
        when "100000"  => temp_output <= temp_data(32);
        when "100001"  => temp_output <= temp_data(33);
        when "100010"  => temp_output <= temp_data(34);
        when "100011"  => temp_output <= temp_data(35);
        when "100100"  => temp_output <= temp_data(36);
        when "100101"  => temp_output <= temp_data(37);
        when "100110"  => temp_output <= temp_data(38);
        when "100111"  => temp_output <= temp_data(39);
        when "101000"  => temp_output <= temp_data(40);
        when "101001"  => temp_output <= temp_data(41);
        when "101010"  => temp_output <= temp_data(42);
        when "101011"  => temp_output <= temp_data(43);
        when "101100"  => temp_output <= temp_data(44);
        when "101101"  => temp_output <= temp_data(45);
        when "101110"  => temp_output <= temp_data(46);
        when "101111"  => temp_output <= temp_data(47);
        when "110000"  => temp_output <= temp_data(48);
        when "110001"  => temp_output <= temp_data(49);
        when "110010"  => temp_output <= temp_data(50);
        when "110011"  => temp_output <= temp_data(51);
        when "110100"  => temp_output <= temp_data(52);
        when "110101"  => temp_output <= temp_data(53);
        when "110110"  => temp_output <= temp_data(54);
        when "110111"  => temp_output <= temp_data(55);
        when "111000"  => temp_output <= temp_data(56);
        when "111001"  => temp_output <= temp_data(57);
        when "111010"  => temp_output <= temp_data(58);
        when "111011"  => temp_output <= temp_data(59);
        when "111100"  => temp_output <= temp_data(60);
        when "111101"  => temp_output <= temp_data(61);
        when "111110"  => temp_output <= temp_data(62);
        when "111111"  => temp_output <= temp_data(63);
        when others    => temp_output <= (others => '0');
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
