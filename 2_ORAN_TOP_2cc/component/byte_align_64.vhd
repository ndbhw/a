--------------------------------------------------------------------------------
--
-- Copyright (C) 2022, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2022.02.16
--------------------------------------------------------------------------------
-- Function description
--   1. Common component
--   2. Byte align
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2022.02.16) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity BYTE_ALIGN_64 is
    port (
--------------------------------------------------------------------------------
-- Clock
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------

        ALIGN_START                 : in  std_logic;
        ALIGN_POSITION              : in  std_logic_vector(2 downto 0);

--------------------------------------------------------------------------------
-- Data
--------------------------------------------------------------------------------

        VALID_IN                    : in  std_logic;
        LAST_IN                     : in  std_logic;
        KEEP_IN                     : in  std_logic_vector(7 downto 0);
        DATA_IN                     : in  std_logic_vector(63 downto 0);

        VALID_OUT                   : out std_logic;
        LAST_OUT                    : out std_logic;
        KEEP_OUT                    : out std_logic_vector(7 downto 0);
        DATA_OUT                    : out std_logic_vector(63 downto 0)
    );
end BYTE_ALIGN_64;

architecture BEHAVE of BYTE_ALIGN_64 is

    type std_logic_array8           is array(natural range <>) of std_logic_vector(7 downto 0);
    type std_logic_array64          is array(natural range <>) of std_logic_vector(63 downto 0);

    signal position                 : std_logic_vector(2 downto 0) := (others => '0');
    signal last_enc                 : std_logic_vector(7 downto 0) := (others => '0');
    signal last_buf                 : std_logic_array8(2 downto 0) := (others => (others => '0'));
    signal keep_buf                 : std_logic_array8(2 downto 0) := (others => (others => '0'));
    signal data_buf                 : std_logic_array64(2 downto 0) := (others => (others => '0'));

begin

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (ALIGN_START = '1') then
                position <= ALIGN_POSITION;
            end if;
        end if;
    end process;

    process (KEEP_IN, LAST_IN)
    begin
        if (LAST_IN = '1') then
            if    (KEEP_IN = x"FF") then
                last_enc <= "00000001";
            elsif (KEEP_IN = x"FE") then
                last_enc <= "00000010";
            elsif (KEEP_IN = x"FC") then
                last_enc <= "00000100";
            elsif (KEEP_IN = x"F8") then
                last_enc <= "00001000";
            elsif (KEEP_IN = x"F0") then
                last_enc <= "00010000";
            elsif (KEEP_IN = x"E0") then
                last_enc <= "00100000";
            elsif (KEEP_IN = x"C0") then
                last_enc <= "01000000";
            elsif (KEEP_IN = x"80") then
                last_enc <= "10000000";
            else
                last_enc <= "00000000";
            end if;
        else
            last_enc <= "00000000";
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (VALID_IN = '1') then
                last_buf(1 downto 0) <= last_buf(0) & last_enc;
                keep_buf(1 downto 0) <= keep_buf(0) & KEEP_IN;
                data_buf(1 downto 0) <= data_buf(0) & DATA_IN;
            else
                last_buf(1 downto 0) <= last_buf(0) & x"00";
                keep_buf(1 downto 0) <= keep_buf(0) & x"00";
                data_buf(1 downto 0) <= data_buf(0) & x"0000000000000000";
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (position = "001") then       last_buf(2) <= last_buf(1)(0 downto 0) & last_buf(0)(7 downto 1);
            elsif (position = "010") then       last_buf(2) <= last_buf(1)(1 downto 0) & last_buf(0)(7 downto 2);
            elsif (position = "011") then       last_buf(2) <= last_buf(1)(2 downto 0) & last_buf(0)(7 downto 3);
            elsif (position = "100") then       last_buf(2) <= last_buf(1)(3 downto 0) & last_buf(0)(7 downto 4);
            elsif (position = "101") then       last_buf(2) <= last_buf(1)(4 downto 0) & last_buf(0)(7 downto 5);
            elsif (position = "110") then       last_buf(2) <= last_buf(1)(5 downto 0) & last_buf(0)(7 downto 6);
            elsif (position = "111") then       last_buf(2) <= last_buf(1)(6 downto 0) & last_buf(0)(7 downto 7);
            else                                last_buf(2) <=                           last_buf(0)(7 downto 0);
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (position = "001") then       keep_buf(2) <= keep_buf(1)(0 downto 0) & keep_buf(0)(7 downto 1);
            elsif (position = "010") then       keep_buf(2) <= keep_buf(1)(1 downto 0) & keep_buf(0)(7 downto 2);
            elsif (position = "011") then       keep_buf(2) <= keep_buf(1)(2 downto 0) & keep_buf(0)(7 downto 3);
            elsif (position = "100") then       keep_buf(2) <= keep_buf(1)(3 downto 0) & keep_buf(0)(7 downto 4);
            elsif (position = "101") then       keep_buf(2) <= keep_buf(1)(4 downto 0) & keep_buf(0)(7 downto 5);
            elsif (position = "110") then       keep_buf(2) <= keep_buf(1)(5 downto 0) & keep_buf(0)(7 downto 6);
            elsif (position = "111") then       keep_buf(2) <= keep_buf(1)(6 downto 0) & keep_buf(0)(7 downto 7);
            else                                keep_buf(2) <=                           keep_buf(0)(7 downto 0);
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (position = "001") then       data_buf(2) <= data_buf(1)(7 downto 0)  & data_buf(0)(63 downto 8);
            elsif (position = "010") then       data_buf(2) <= data_buf(1)(15 downto 0) & data_buf(0)(63 downto 16);
            elsif (position = "011") then       data_buf(2) <= data_buf(1)(23 downto 0) & data_buf(0)(63 downto 24);
            elsif (position = "100") then       data_buf(2) <= data_buf(1)(31 downto 0) & data_buf(0)(63 downto 32);
            elsif (position = "101") then       data_buf(2) <= data_buf(1)(39 downto 0) & data_buf(0)(63 downto 40);
            elsif (position = "110") then       data_buf(2) <= data_buf(1)(47 downto 0) & data_buf(0)(63 downto 48);
            elsif (position = "111") then       data_buf(2) <= data_buf(1)(55 downto 0) & data_buf(0)(63 downto 56);
            else                                data_buf(2) <=                            data_buf(0)(63 downto 0);
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (keep_buf(2) = "00000000") then
                VALID_OUT <= '0';
            else
                VALID_OUT <= '1';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (last_buf(2) = "00000000") then
                LAST_OUT <= '0';
            else
                LAST_OUT <= '1';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            KEEP_OUT <= keep_buf(2);
            DATA_OUT <= data_buf(2);
        end if;
    end process;

end BEHAVE;