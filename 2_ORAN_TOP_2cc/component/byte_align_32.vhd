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

entity BYTE_ALIGN_32 is
    port (
--------------------------------------------------------------------------------
-- Clock
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------

        ALIGN_START                 : in  std_logic;
        ALIGN_POSITION              : in  std_logic_vector(1 downto 0);

--------------------------------------------------------------------------------
-- Data
--------------------------------------------------------------------------------

        VALID_IN                    : in  std_logic;
        LAST_IN                     : in  std_logic;
        KEEP_IN                     : in  std_logic_vector(3 downto 0);
        DATA_IN                     : in  std_logic_vector(31 downto 0);

        VALID_OUT                   : out std_logic;
        LAST_OUT                    : out std_logic;
        KEEP_OUT                    : out std_logic_vector(3 downto 0);
        DATA_OUT                    : out std_logic_vector(31 downto 0)
    );
end BYTE_ALIGN_32;

architecture BEHAVE of BYTE_ALIGN_32 is

    type std_logic_array4           is array(natural range <>) of std_logic_vector(3 downto 0);
    type std_logic_array32          is array(natural range <>) of std_logic_vector(31 downto 0);

    signal position                 : std_logic_vector(1 downto 0) := (others => '0');
    signal last_enc                 : std_logic_vector(3 downto 0) := (others => '0');
    signal last_buf                 : std_logic_array4(2 downto 0) := (others => (others => '0'));
    signal keep_buf                 : std_logic_array4(2 downto 0) := (others => (others => '0'));
    signal data_buf                 : std_logic_array32(2 downto 0) := (others => (others => '0'));

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
            if    (KEEP_IN = x"F") then
                last_enc <= "0001";
            elsif (KEEP_IN = x"E") then
                last_enc <= "0010";
            elsif (KEEP_IN = x"C") then
                last_enc <= "0100";
            elsif (KEEP_IN = x"8") then
                last_enc <= "1000";
            else
                last_enc <= "0000";
            end if;
        else
            last_enc <= "0000";
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            last_buf(1 downto 0) <= last_buf(0) & last_enc;
            keep_buf(1 downto 0) <= keep_buf(0) & KEEP_IN;
            data_buf(1 downto 0) <= data_buf(0) & DATA_IN;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (position = "01") then        last_buf(2) <= last_buf(1)(0 downto 0) & last_buf(0)(3 downto 1);
            elsif (position = "10") then        last_buf(2) <= last_buf(1)(1 downto 0) & last_buf(0)(3 downto 2);
            elsif (position = "11") then        last_buf(2) <= last_buf(1)(2 downto 0) & last_buf(0)(3 downto 3);
            else                                last_buf(2) <=                           last_buf(0)(3 downto 0);
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (position = "01") then        keep_buf(2) <= keep_buf(1)(0 downto 0) & keep_buf(0)(3 downto 1);
            elsif (position = "10") then        keep_buf(2) <= keep_buf(1)(1 downto 0) & keep_buf(0)(3 downto 2);
            elsif (position = "11") then        keep_buf(2) <= keep_buf(1)(2 downto 0) & keep_buf(0)(3 downto 3);
            else                                keep_buf(2) <=                           keep_buf(0)(3 downto 0);
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (position = "01") then        data_buf(2) <= data_buf(1)(7 downto 0)  & data_buf(0)(31 downto 8);
            elsif (position = "10") then        data_buf(2) <= data_buf(1)(15 downto 0) & data_buf(0)(31 downto 16);
            elsif (position = "11") then        data_buf(2) <= data_buf(1)(23 downto 0) & data_buf(0)(31 downto 24);
            else                                data_buf(2) <=                            data_buf(0)(31 downto 0);
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (keep_buf(2) = "0000") then
                VALID_OUT <= '0';
            else
                VALID_OUT <= '1';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (last_buf(2) = "0000") then
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