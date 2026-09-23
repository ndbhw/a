--------------------------------------------------------------------------------
--
-- Copyright (C) 2025, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2025.03.18
--------------------------------------------------------------------------------
-- Function description
--   1. FH interconnect component
--   2. Stamp 'ru-element' index
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2025.03.18) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.ARRAY_TYPE.ALL;
use WORK.PKG_ORAN.ALL;
use WORK.PKG_ORAN_ARRAY.ALL;

entity MAC_HDR_STAMP is
    generic (
        IMPL_CHECK_DST_MAC          : boolean := true;
        IMPL_CHECK_SRC_MAC          : boolean := false;
        IMPL_CHECK_VLAN_VID         : boolean := false
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;

--------------------------------------------------------------------------------
-- Debug
--------------------------------------------------------------------------------

        IGNORE_VLAN_VID             : in  std_logic;

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------

        PARAM_DST_MAC               : in  std_logic_array48(7 downto 0);
        PARAM_SRC_MAC               : in  std_logic_array48(7 downto 0);
        PARAM_VLAN0_MODE            : in  std_logic_vector(7 downto 0);
        PARAM_VLAN0_VID             : in  std_logic_array12(7 downto 0);
        PARAM_VLAN1_MODE            : in  std_logic_vector(7 downto 0);
        PARAM_VLAN1_VID             : in  std_logic_array12(7 downto 0);

--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

        CNT_PE_VALID                : out std_logic_array32(7 downto 0);
        CNT_INVALID_DST_MAC         : out std_logic_array32(7 downto 0);
        CNT_INVALID_SRC_MAC         : out std_logic_array32(7 downto 0);
        CNT_INVALID_VLAN_VID        : out std_logic_array32(7 downto 0);

--------------------------------------------------------------------------------
-- Data bus
--------------------------------------------------------------------------------

        IN_VALID                    : in  std_logic;
        IN_LAST                     : in  std_logic;
        IN_KEEP                     : in  std_logic_vector(7 downto 0);
        IN_DATA                     : in  std_logic_vector(63 downto 0);

        OUT_VALID                   : out std_logic;
        OUT_LAST                    : out std_logic;
        OUT_KEEP                    : out std_logic_vector(7 downto 0);
        OUT_DATA                    : out std_logic_vector(63 downto 0);

        OUT_PE_INDEX                : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        OUT_VLAN_MODE               : out std_logic_vector(1 downto 0)
    );
end MAC_HDR_STAMP;

architecture BEHAVE of MAC_HDR_STAMP is

    signal buf_in_valid             : std_logic_vector(5 downto 0) := (others => '0');
    signal buf_in_last              : std_logic_vector(5 downto 0) := (others => '0');
    signal buf_in_keep              : std_logic_array8(5 downto 0) := (others => (others => '0'));
    signal buf_in_data              : std_logic_array64(5 downto 0) := (others => (others => '0'));

    signal cnt                      : std_logic_vector(2 downto 0) := (others => '0');

    signal matched_dst_mac          : std_logic_vector(MAX_RU_ELEMENT-1 downto 0) := (others => '0');
    signal matched_src_mac          : std_logic_vector(MAX_RU_ELEMENT-1 downto 0) := (others => '0');
    signal matched_vlan_tpid        : std_logic_vector(1 downto 0) := (others => '0');
    signal matched_vlan_vid         : std_logic_array2(MAX_RU_ELEMENT-1 downto 0) := (others => (others => '0'));
    signal matched_type             : std_logic_vector(2 downto 0) := (others => '0');
    signal matched_pe               : std_logic_vector(MAX_RU_ELEMENT-1 downto 0) := (others => '0');

    signal vlan_detected            : std_logic_vector(1 downto 0) := (others => '0');

    signal dst_mac                  : std_logic_vector(47 downto 0);
    signal src_mac                  : std_logic_vector(47 downto 0);
    signal vlan_tpid0               : std_logic_vector(15 downto 0);
    signal vlan_vid0                : std_logic_vector(11 downto 0);
    signal vlan_tpid1               : std_logic_vector(15 downto 0);
    signal vlan_vid1                : std_logic_vector(11 downto 0);
    signal ethertype0               : std_logic_vector(15 downto 0);
    signal ethertype1               : std_logic_vector(15 downto 0);

    component CNT_UNIT_EDGE is
    generic (
        EDGE                        : std_logic := '1';
        CNT_WIDTH                   : natural := 32
    );
    port (
        CLK                         : in  std_logic;

        I                           : in  std_logic;

        O                           : out std_logic_vector(31 downto 0) := (others => '0')
    );
    end component;

    signal packet_accepted          : std_logic_vector(MAX_RU_ELEMENT-1 downto 0) := (others => '0');
    signal invalid_dst_mac          : std_logic_vector(MAX_RU_ELEMENT-1 downto 0) := (others => '0');
    signal invalid_src_mac          : std_logic_vector(MAX_RU_ELEMENT-1 downto 0) := (others => '0');
    signal invalid_vlan_vid         : std_logic_vector(MAX_RU_ELEMENT-1 downto 0) := (others => '0');

begin

--------------------------------------------------------------------------------
-- Input registering
--------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            buf_in_valid <= buf_in_valid(4 downto 0) & IN_VALID;
            buf_in_last  <= buf_in_last(4 downto 0) & IN_LAST;
            buf_in_keep  <= buf_in_keep(4 downto 0) & IN_KEEP;
            buf_in_data  <= buf_in_data(4 downto 0) & IN_DATA;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Parameters
--------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (buf_in_valid(0) = '1') then
                if (buf_in_last(0) = '1') then
                    cnt <= (others => '0');
                else
                    if (cnt = 7) then
                        cnt <= cnt;
                    else
                        cnt <= cnt + 1;
                    end if;
                end if;
--            else
--                cnt <= (others => '0');
            end if;
        end if;
    end process;

    dst_mac                         <= buf_in_data(0)(7 downto 0) & buf_in_data(0)(15 downto 8) & buf_in_data(0)(23 downto 16) & buf_in_data(0)(31 downto 24) & buf_in_data(0)(39 downto 32) & buf_in_data(0)(47 downto 40);
    src_mac                         <= buf_in_data(0)(55 downto 48) & buf_in_data(0)(63 downto 56) & buf_in_data(0)(7 downto 0) & buf_in_data(0)(15 downto 8) & buf_in_data(0)(23 downto 16) & buf_in_data(0)(31 downto 24);
    vlan_tpid0                      <= buf_in_data(0)(39 downto 32) & buf_in_data(0)(47 downto 40);
    vlan_vid0                       <= buf_in_data(0)(51 downto 48) & buf_in_data(0)(63 downto 56);
    vlan_tpid1                      <= buf_in_data(0)(7 downto 0) & buf_in_data(0)(15 downto 8);
    vlan_vid1                       <= buf_in_data(0)(19 downto 16) & buf_in_data(0)(31 downto 24);
    ethertype0                      <= buf_in_data(0)(39 downto 32) & buf_in_data(0)(47 downto 40);
    ethertype1                      <= buf_in_data(0)(7 downto 0) & buf_in_data(0)(15 downto 8);

--------------------------------------------------------------------------------
-- Destination/Source MAC (Ethernet layer)
--------------------------------------------------------------------------------

    u_DST_MAC : for i in MAX_RU_ELEMENT-1 downto 0 generate
    u_DST_MAC_USED : if IMPL_CHECK_DST_MAC = true generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (buf_in_valid(0) = '1') and (buf_in_last(0) = '1') then
            if (buf_in_last(0) = '1') then
                matched_dst_mac(i) <= '0';
            else
                if (cnt = 0) then
                    if (dst_mac = PARAM_DST_MAC(i)) then
                        matched_dst_mac(i) <= '1';
                    else
                        matched_dst_mac(i) <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
    end generate;

    u_DST_MAC_UNUSED : if IMPL_CHECK_DST_MAC = false generate
    matched_dst_mac(i) <= '1';
    end generate;
    end generate;

    u_SRC_MAC : for i in MAX_RU_ELEMENT-1 downto 0 generate
    u_SRC_MAC_USED : if IMPL_CHECK_SRC_MAC = true generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (buf_in_valid(0) = '1') and (buf_in_last(0) = '1') then
            if (buf_in_last(0) = '1') then
                matched_src_mac(i) <= '0';
            else
                if (cnt = 0) then
                    if (src_mac(47 downto 32) = PARAM_SRC_MAC(i)(47 downto 32)) then
                        matched_src_mac(i) <= '1';
                    else
                        matched_src_mac(i) <= '0';
                    end if;
                elsif (cnt = 1) then
                    if (src_mac(31 downto 0) = PARAM_SRC_MAC(i)(31 downto 0)) then
                        matched_src_mac(i) <= matched_src_mac(i);
                    else
                        matched_src_mac(i) <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
    end generate;

    u_SRC_MAC_UNUSED : if IMPL_CHECK_SRC_MAC = false generate
    matched_src_mac(i) <= '1';
    end generate;
    end generate;

--------------------------------------------------------------------------------
-- VLAN TPID, EtherType (Ethernet layer)
--------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (buf_in_valid(0) = '1') and (buf_in_last(0) = '1') then
            if (buf_in_last(0) = '1') then
                matched_vlan_tpid(0) <= '0';
            else
                if (cnt = 1) then
                    if (vlan_tpid0 = x"88A8") or (vlan_tpid0 = x"8100") then
                        matched_vlan_tpid(0) <= '1';
                    else
                        matched_vlan_tpid(0) <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (buf_in_valid(0) = '1') and (buf_in_last(0) = '1') then
            if (buf_in_last(0) = '1') then
                matched_vlan_tpid(1) <= '0';
            else
                if (cnt = 2) then
                    if (vlan_tpid1 = x"8100") then
                        matched_vlan_tpid(1) <= '1';
                    else
                        matched_vlan_tpid(1) <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (buf_in_valid(0) = '1') and (buf_in_last(0) = '1') then
            if (buf_in_last(0) = '1') then
                matched_type <= (others => '0');
            else
                if (cnt = 1) then                                               -- No VLAN tag
                    if (ethertype0 = ORAN_ETHERTYPE) then
                        matched_type(0) <= '1';
                    else
                        matched_type(0) <= '0';
                    end if;
                end if;
                if (cnt = 2) then                                               -- Single-tagged
                    if (ethertype1 = ORAN_ETHERTYPE) then
                        matched_type(1) <= '1';
                    else
                        matched_type(1) <= '0';
                    end if;
                end if;
                if (cnt = 2) then                                               -- Double-tagged
                    if (ethertype0 = ORAN_ETHERTYPE) then
                        matched_type(2) <= '1';
                    else
                        matched_type(2) <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------
-- VLAN VID (Ethernet layer)
--------------------------------------------------------------------------------

    u_VID : for i in MAX_RU_ELEMENT-1 downto 0 generate
    u_VID_USED : if IMPL_CHECK_VLAN_VID = true generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (buf_in_valid(0) = '1') and (buf_in_last(0) = '1') then
            if (buf_in_last(0) = '1') then
                matched_vlan_vid(i)(0) <= '0';
            else
                if (cnt = 1) then
                    if (PARAM_VLAN0_VID(i) = vlan_vid0) then
                        matched_vlan_vid(i)(0) <= '1';
                    else
                        matched_vlan_vid(i)(0) <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (buf_in_valid(0) = '1') and (buf_in_last(0) = '1') then
            if (buf_in_last(0) = '1') then
                matched_vlan_vid(i)(1) <= '0';
            else
                if (cnt = 2) then
                    if (PARAM_VLAN1_VID(i) = vlan_vid1) then
                        matched_vlan_vid(i)(1) <= '1';
                    else
                        matched_vlan_vid(i)(1) <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
    end generate;

    u_VID_UNUSED : if IMPL_CHECK_VLAN_VID = false generate
    matched_vlan_vid(i) <= (others => '1');
    end generate;
    end generate;

--------------------------------------------------------------------------------
-- 'ru-element' index, VLAN tag
--------------------------------------------------------------------------------

    u_RE_INDEX : for i in MAX_RU_ELEMENT-1 downto 0 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (buf_in_valid(0) = '1') and (buf_in_last(0) = '1') then
            if (buf_in_last(0) = '1') then
                matched_pe(i) <= '0';
            else
                if (IGNORE_VLAN_VID = '0') then
                    if (cnt = 3) then
                        if    (PARAM_VLAN0_MODE(i) = '1') and (PARAM_VLAN1_MODE(i) = '1') then
                            if (matched_vlan_vid(i)(1 downto 0) = "11") and (matched_type(2) = '1') then
                                matched_pe(i) <= '1';
                            else
                                matched_pe(i) <= '0';
                            end if;
                        elsif (PARAM_VLAN0_MODE(i) = '1') and (PARAM_VLAN1_MODE(i) = '0') then
                            if (matched_vlan_vid(i)(0 downto 0) = "1") and (matched_type(1) = '1')then
                                matched_pe(i) <= '1';
                            else
                                matched_pe(i) <= '0';
                            end if;
                        elsif (PARAM_VLAN0_MODE(i) = '0') and (PARAM_VLAN1_MODE(i) = '1') then
                            matched_pe(i) <= '0';
                        else
                            if (matched_type(0) = '1') then
                                matched_pe(i) <= '1';
                            else
                                matched_pe(i) <= '0';
                            end if;
                        end if;
                    end if;
                else
                    matched_pe(i) <= '1';
                end if;
            end if;
        end if;
    end process;
    end generate;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (cnt = 3) then
                if    (matched_vlan_tpid(1 downto 0) = 3) and (matched_type(2 downto 0) = 4) then
                    vlan_detected <= "11";
                elsif (matched_vlan_tpid(1 downto 0) = 1) and (matched_type(1 downto 0) = 2) then
                    vlan_detected <= "01";
                elsif (matched_vlan_tpid(1 downto 0) = 0) and (matched_type(0 downto 0) = 1) then
                    vlan_detected <= "00";
                else
                    vlan_detected <= "10";
                end if;
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Output control
--------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            OUT_VALID     <= buf_in_valid(4);
            OUT_LAST      <= buf_in_last(4);
            OUT_KEEP      <= buf_in_keep(4);
            OUT_DATA      <= buf_in_data(4);
            if (cnt = 4) then
                OUT_PE_INDEX  <= matched_dst_mac and matched_src_mac and matched_pe;
            end if;
            OUT_VLAN_MODE <= vlan_detected;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

    u_RE_STAT : for i in MAX_RU_ELEMENT-1 downto 0 generate
    u_CNT_PE_VALID         : CNT_UNIT_EDGE generic map('1', MAX_DEBUG_BIT) port map(CLK, packet_accepted(i), CNT_PE_VALID(i));
    u_CNT_INVALID_DST_MAC  : CNT_UNIT_EDGE generic map('1', MAX_DEBUG_BIT) port map(CLK, invalid_dst_mac(i), CNT_INVALID_DST_MAC(i));
    u_CNT_INVALID_SRC_MAC  : CNT_UNIT_EDGE generic map('1', MAX_DEBUG_BIT) port map(CLK, invalid_src_mac(i), CNT_INVALID_SRC_MAC(i));
    u_CNT_INVALID_VLAN_VID : CNT_UNIT_EDGE generic map('1', MAX_DEBUG_BIT) port map(CLK, invalid_vlan_vid(i), CNT_INVALID_VLAN_VID(i));

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (buf_in_valid(0) = '1') and (buf_in_last(0) = '1') then
                if (matched_dst_mac(i) = '1') and (matched_src_mac(i) = '1') and (matched_pe(i) = '1') then
                    packet_accepted(i) <= '1';
                else
                    packet_accepted(i) <= '0';
                end if;
            else
                packet_accepted(i) <= '0';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (buf_in_valid(0) = '1') and (buf_in_last(0) = '1') then
                if (matched_dst_mac(i) = '0') and (matched_src_mac(i) = '1') and (matched_pe(i) = '1') then
                    invalid_dst_mac(i) <= '1';
                else
                    invalid_dst_mac(i) <= '0';
                end if;
            else
                invalid_dst_mac(i) <= '0';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (buf_in_valid(0) = '1') and (buf_in_last(0) = '1') then
                if (matched_dst_mac(i) = '1') and (matched_src_mac(i) = '0') and (matched_pe(i) = '1') then
                    invalid_src_mac(i) <= '1';
                else
                    invalid_src_mac(i) <= '0';
                end if;
            else
                invalid_src_mac(i) <= '0';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (buf_in_valid(0) = '1') and (buf_in_last(0) = '1') then
                if (matched_dst_mac(i) = '1') and (matched_src_mac(i) = '1') and (matched_pe(i) = '0') then
                    invalid_vlan_vid(i) <= '1';
                else
                    invalid_vlan_vid(i) <= '0';
                end if;
            else
                invalid_vlan_vid(i) <= '0';
            end if;
        end if;
    end process;
    end generate;

end BEHAVE;