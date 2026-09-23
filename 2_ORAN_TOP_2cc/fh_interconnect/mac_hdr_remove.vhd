--------------------------------------------------------------------------------
--
-- Copyright (C) 2025, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2025.03.18
--------------------------------------------------------------------------------
-- Function description
--   1. FH interconnect component
--   2. Remove Ethernet header
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2025.03.18) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.PKG_ORAN.ALL;

entity MAC_HDR_REMOVE is
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Data bus
--------------------------------------------------------------------------------

        IN_VALID                    : in  std_logic;
        IN_LAST                     : in  std_logic;
        IN_KEEP                     : in  std_logic_vector(7 downto 0);
        IN_DATA                     : in  std_logic_vector(63 downto 0);

        IN_PE_INDEX                 : in  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        IN_VLAN_MODE                : in  std_logic_vector(1 downto 0);

        OUT_VALID                   : out std_logic;
        OUT_LAST                    : out std_logic;
        OUT_KEEP                    : out std_logic_vector(7 downto 0);
        OUT_DATA                    : out std_logic_vector(63 downto 0);

        OUT_PE_INDEX                : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0) := (others => '0')
    );
end MAC_HDR_REMOVE;

architecture BEHAVE of MAC_HDR_REMOVE is

    type fsm_remove                 is (TP_HDR0, TP_HDR1, TP_HDR2, HDR, PAYLOAD);
    signal fsm                      : fsm_remove := TP_HDR0;

    signal in_last_conv             : std_logic_vector(7 downto 0) := (others => '0');
    signal in_last_buf              : std_logic_vector(7 downto 0) := (others => '0');
    signal in_keep_buf              : std_logic_vector(7 downto 0) := (others => '0');
    signal in_data_buf              : std_logic_vector(63 downto 0) := (others => '0');

    signal align                    : std_logic := '0';
    signal align_position           : std_logic := '0';

    signal buf_start                : std_logic := '0';
    signal buf_last                 : std_logic_vector(7 downto 0) := (others => '0');
    signal buf_keep                 : std_logic_vector(7 downto 0) := (others => '0');
    signal buf_data                 : std_logic_vector(63 downto 0) := (others => '0');

    signal align_buf_last           : std_logic_vector(7 downto 0) := (others => '0');
    signal align_buf_keep           : std_logic_vector(7 downto 0) := (others => '0');
    signal align_buf_data           : std_logic_vector(63 downto 0) := (others => '0');

    signal align_case               : std_logic := '0';
    signal aligned_buf_last         : std_logic_vector(7 downto 0) := (others => '0');
    signal aligned_buf_keep         : std_logic_vector(7 downto 0) := (others => '0');
    signal aligned_buf_data         : std_logic_vector(63 downto 0) := (others => '0');

    signal out_valid_buf            : std_logic := '0';
    signal out_last_buf             : std_logic := '0';
    signal out_keep_buf             : std_logic_vector(7 downto 0) := (others => '0');
    signal out_data_buf             : std_logic_vector(63 downto 0) := (others => '0');

begin

--------------------------------------------------------------------------------
-- Remove header of packet (transport layer)
--------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            in_last_buf   <= in_last_conv;
            in_keep_buf   <= IN_KEEP;
            in_data_buf   <= IN_DATA;
        end if;
    end process;

    process (IN_KEEP, IN_LAST)
    begin
        if (IN_LAST = '1') then
            if    (IN_KEEP = x"FF") then
                in_last_conv <= "10000000";
            elsif (IN_KEEP = x"7F") then
                in_last_conv <= "01000000";
            elsif (IN_KEEP = x"3F") then
                in_last_conv <= "00100000";
            elsif (IN_KEEP = x"1F") then
                in_last_conv <= "00010000";
            elsif (IN_KEEP = x"0F") then
                in_last_conv <= "00001000";
            elsif (IN_KEEP = x"07") then
                in_last_conv <= "00000100";
            elsif (IN_KEEP = x"03") then
                in_last_conv <= "00000010";
            elsif (IN_KEEP = x"01") then
                in_last_conv <= "00000001";
            else
                in_last_conv <= "00000000";
            end if;
        else
            in_last_conv <= "00000000";
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm is
            when TP_HDR0 =>
                if (IN_VALID = '1') then
                    fsm <= TP_HDR1;
                else
                    fsm <= TP_HDR0;
                end if;
            when TP_HDR1 =>
                if (IN_VLAN_MODE = "00") then
                    fsm <= HDR;
                else
                    fsm <= TP_HDR2;
                end if;
            when TP_HDR2 =>
                fsm <= HDR;
            when HDR     =>
                fsm <= PAYLOAD;
            when PAYLOAD =>
                if (IN_VALID = '1') and (IN_LAST = '1') then
                    fsm <= TP_HDR0;
                else
                    fsm <= PAYLOAD;
                end if;
            when others  =>
                fsm <= TP_HDR0;
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm is
            when TP_HDR0 =>
                align <= '0';
            when TP_HDR1 =>
                if (IN_VLAN_MODE = "00") then
                    align <= '1';
                else
                    align <= '0';
                end if;
            when TP_HDR2 =>
                align <= '1';
            when others  =>
                NULL;
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm is
            when TP_HDR0 =>
                align_position <= '0';
            when TP_HDR2 =>
                if (IN_VLAN_MODE = "01") then
                    align_position <= '1';
                else
                    align_position <= '0';
                end if;
            when others  =>
                NULL;
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (align = '1') then
                case fsm is
                when HDR     =>
                    if (align_position = '0') then
                        buf_start <= '1';
                        buf_last  <= in_last_buf;
                        buf_keep  <= "11000000";
                        buf_data  <= in_data_buf;
                    else
                        buf_start <= '1';
                        buf_last  <= in_last_buf;
                        buf_keep  <= "11111100";
                        buf_data  <= in_data_buf;
                    end if;
                when others  =>
                    buf_start <= '0';
                    buf_last  <= in_last_buf;
                    buf_keep  <= in_keep_buf;
                    buf_data  <= in_data_buf;
                end case;
            else
                buf_start <= '0';
                buf_last  <= (others => '0');
                buf_keep  <= (others => '0');
                buf_data  <= (others => '0');
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Adjust the start of packet to be not blank
--------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (buf_start = '1') then
                align_case <= align_position;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            align_buf_last <= buf_last;
            align_buf_keep <= buf_keep;
            align_buf_data <= buf_data;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (align_case = '0') then
                aligned_buf_last <= buf_last(5 downto 0) & align_buf_last(7 downto 6);
                aligned_buf_keep <= buf_keep(5 downto 0) & align_buf_keep(7 downto 6);
                aligned_buf_data <= buf_data(47 downto 0) & align_buf_data(63 downto 48);
            else
                aligned_buf_last <= buf_last(1 downto 0) & align_buf_last(7 downto 2);
                aligned_buf_keep <= buf_keep(1 downto 0) & align_buf_keep(7 downto 2);
                aligned_buf_data <= buf_data(15 downto 0) & align_buf_data(63 downto 16);
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            out_valid_buf <= aligned_buf_keep(0);
            if (aligned_buf_last = x"00") then
                out_last_buf  <= '0';
            else
                out_last_buf  <= '1';
            end if;
            out_keep_buf  <= aligned_buf_keep;
            out_data_buf  <= aligned_buf_data;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            OUT_VALID <= out_valid_buf;
            OUT_LAST  <= out_last_buf;
            OUT_KEEP  <= out_keep_buf;
            OUT_DATA  <= out_data_buf;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (buf_start = '1') then
                OUT_PE_INDEX <= IN_PE_INDEX;
            end if;
        end if;
    end process;

end BEHAVE;