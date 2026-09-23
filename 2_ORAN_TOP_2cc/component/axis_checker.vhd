--------------------------------------------------------------------------------
--
-- Copyright (C) 2022, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2022.02.16
--------------------------------------------------------------------------------
-- Function description
--   1. Common component
--   2. Check integrity of AXI4-Stream
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2022.02.16) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.PKG_ORAN_ARRAY.ALL;

entity AXIS_CHECKER is
    generic (
        BYTE_WIDTH                  : natural := 8;
        BIT_ORDER                   : string := "MSB"                           -- "MSB", "LSB"
    );
    port (
        CLK                         : in  std_logic;

        IN_READY                    : in  std_logic;
        IN_VALID                    : in  std_logic;
        IN_LAST                     : in  std_logic;
        IN_KEEP                     : in  std_logic_vector(BYTE_WIDTH-1 downto 0);

        CNT_DISCONTINUE             : out std_logic_vector(31 downto 0);
        CNT_BYTE_SIZE               : out std_logic_vector(31 downto 0);
        CNT_BYTE_ALIGN              : out std_logic_vector(31 downto 0)
    );
end AXIS_CHECKER;

architecture BEHAVE of AXIS_CHECKER is

    signal buf_valid                : std_logic_vector(1 downto 0) := (others => '0');
    signal buf_last                 : std_logic_vector(1 downto 0) := (others => '0');
    signal buf_keep                 : std_logic_vector(BYTE_WIDTH-1 downto 0) := (others => '0');

    constant REF_KEEP               : std_logic_vector(BYTE_WIDTH-1 downto 0) := (others => '1');

    signal cnt0_en                  : std_logic := '0';
    signal cnt1_en                  : std_logic := '0';
    signal cnt2_en                  : std_logic := '0';

    signal cnt0                     : std_logic_vector(MAX_DEBUG_BIT-1 downto 0) := (others => '0');
    signal cnt1                     : std_logic_vector(MAX_DEBUG_BIT-1 downto 0) := (others => '0');
    signal cnt2                     : std_logic_vector(MAX_DEBUG_BIT-1 downto 0) := (others => '0');

begin

    CNT_DISCONTINUE <= EXT(cnt0, 32);
    CNT_BYTE_SIZE   <= EXT(cnt1, 32);
    CNT_BYTE_ALIGN  <= EXT(cnt2, 32);

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (IN_READY = '1') then
                buf_valid <= buf_valid(0) & IN_VALID;
                buf_last  <= buf_last(0) & IN_LAST;
                buf_keep  <= IN_KEEP;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (buf_valid = "10") then
                if (buf_last(1) = '0') then
                    cnt0_en <= '1';
                else
                    cnt0_en <= '0';
                end if;
            else
                cnt0_en <= '0';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (buf_valid(0) = '1') and (buf_last(0) = '0') then
               if (buf_keep /= REF_KEEP) then
                   cnt1_en <= '1';
               else
                   cnt1_en <= '0';
               end if;
           else
               cnt1_en <= '0';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (buf_valid(0) = '1') and (buf_last(0) = '1') then
                if    BIT_ORDER = "MSB" then
                    if (buf_keep(BYTE_WIDTH-1) = '0') then
                        cnt2_en <= '1';
                    else
                        cnt2_en <= '0';
                    end if;
                elsif BIT_ORDER = "LSB" then
                    if (buf_keep(0) = '0') then
                        cnt2_en <= '1';
                    else
                        cnt2_en <= '0';
                    end if;
                else
                    cnt2_en <= '1';
                end if;
            else
                cnt2_en <= '0';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (cnt0_en = '1') then
                cnt0 <= cnt0 + 1;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (cnt1_en = '1') then
                cnt1 <= cnt1 + 1;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (cnt2_en = '1') then
                cnt2 <= cnt2 + 1;
            end if;
        end if;
    end process;

end BEHAVE;