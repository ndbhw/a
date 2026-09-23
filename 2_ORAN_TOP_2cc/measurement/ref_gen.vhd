--------------------------------------------------------------------------------
--
-- Copyright (C) 2024, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2024.03.11
--------------------------------------------------------------------------------
-- Function description
--   1. Performance measurement component
--   2. 10-msec re-generation
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2024.03.11) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity REF_GEN is
    port (
        CLK                         : in  std_logic;                            -- 245.76-MHz
        RST                         : in  std_logic;

        N_TA_OFFSET                 : in  std_logic_vector(15 downto 0);        -- 0/25600/39936

        IN_10msec                   : in  std_logic;
        IN_SFN                      : in  std_logic_vector(7 downto 0);

        OUT_10msec                  : out std_logic;
        OUT_SFN                     : out std_logic_vector(7 downto 0)
    );
end REF_GEN;

architecture BEHAVE of REF_GEN is

    signal delay_ref                : std_logic_vector(21 downto 0) := (others => '0');

    signal cnt                      : std_logic_vector(21 downto 0) := (others => '0');
    signal delay_rise               : std_logic_vector(21 downto 0) := (others => '0');
    signal sync_rise                : std_logic := '0';

    signal ref_buf                  : std_logic_vector(1 downto 0) := (others => '0');
    signal sync_delay               : std_logic := '0';

    signal sfn                      : std_logic_vector(7 downto 0) := (others => '0');

begin

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            cnt <= cnt + 1;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            ref_buf <= ref_buf(0) & IN_10msec;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (ref_buf = "01") then
                sfn <= IN_SFN + 1;
            end if;
        end if;
    end process;

    process (RST, CLK)
    begin
        if (RST = '1') then
            sync_rise <= '0';
        elsif (CLK'event and CLK = '1') then
            if (ref_buf = "01") then
                sync_rise <= '1';
            elsif (sync_delay = '1') then
                sync_rise <= '0';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (IN_10msec = '1') and (ref_buf(0) = '0') then
                delay_ref <= 2457600 - EXT(N_TA_OFFSET(15 downto 3), 22) - 3;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (ref_buf = "01") then
                delay_rise <= delay_ref + cnt;
            end if;
        end if;
    end process;

    process (RST, CLK)
    begin
        if (RST = '1') then
            sync_delay <= '0';
        elsif (CLK'event and CLK = '1') then
            if (cnt = delay_rise) and (sync_rise = '1') then
                sync_delay <= '1';
            else
                sync_delay <= '0';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (sync_delay = '1') then
                OUT_10msec <= '1';
                OUT_SFN    <= sfn;
            else
                OUT_10msec <= '0';
            end if;
        end if;
    end process;

end BEHAVE;