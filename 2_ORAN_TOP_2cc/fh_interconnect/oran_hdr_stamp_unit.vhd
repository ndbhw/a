--------------------------------------------------------------------------------
--
-- Copyright (C) 2025, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2025.03.18
--------------------------------------------------------------------------------
-- Function description
--   1. FH interconnect component
--   2. Stamping according to header information
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

entity ORAN_HDR_STAMP_UNIT is
    generic (
        IMPL_CP                     : boolean := true;
        IMPL_UP                     : boolean := true;

        LINK_DIRECTION              : std_logic := '0';                         -- DL : '1', UL : '0'
        DATA_INDEX                  : natural := 0;
        NUM_LINK                    : natural := 16
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------

        PARAM_ID_EN                 : in  std_logic_vector(63 downto 0);
        PARAM_ID                    : in  std_logic_array16(63 downto 0);
        PE_INDEX                    : in  std_logic_array8(63 downto 0);
        SCS_CONFIG                  : in  std_logic_array4(63 downto 0);
        ENABLE_NDM                  : in  std_logic_vector(63 downto 0);

--------------------------------------------------------------------------------
-- Statistics signals
--------------------------------------------------------------------------------

        CNTUP_INVALID_ecpriVersion  : out std_logic;
        CNTUP_INVALID_ecpriC        : out std_logic;
        CNTUP_INVALID_ecpriMessage  : out std_logic;

        CNTUP_LENGTH_IS_NORMAL      : out std_logic;
        CNTUP_LENGTH_IS_LONG        : out std_logic;
        CNTUP_LENGTH_IS_SHORT       : out std_logic;

--------------------------------------------------------------------------------
-- Input
--------------------------------------------------------------------------------

        IN_VALID                    : in  std_logic;
        IN_LAST                     : in  std_logic;
        IN_KEEP                     : in  std_logic_vector(7 downto 0);
        IN_DATA                     : in  std_logic_vector(63 downto 0);
        IN_PE_INDEX                 : in  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        OUT_PE_INDEX                : out  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

--------------------------------------------------------------------------------
-- Output (C-Plane)
--------------------------------------------------------------------------------

        OUT_CP_VALID                : out std_logic;
        OUT_CP_LAST                 : out std_logic;
        OUT_CP_KEEP                 : out std_logic_vector(7 downto 0);
        OUT_CP_DATA                 : out std_logic_vector(63 downto 0);
        OUT_CP_INDEX                : out std_logic_vector(2 downto 0);
        OUT_CP_LINK_MAP             : out std_logic_vector(15 downto 0);

--------------------------------------------------------------------------------
-- Output (U-Plane)
--------------------------------------------------------------------------------

        OUT_UP_VALID                : out std_logic;
        OUT_UP_LAST                 : out std_logic;
        OUT_UP_KEEP                 : out std_logic_vector(7 downto 0);
        OUT_UP_DATA                 : out std_logic_vector(63 downto 0);
        OUT_UP_INDEX                : out std_logic_vector(2 downto 0);
        OUT_UP_LINK_MAP             : out std_logic_vector(15 downto 0);

--------------------------------------------------------------------------------
-- Packet stamp
--------------------------------------------------------------------------------

        PACKET_IS_CP                : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_UP                : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_NDM               : out std_logic := '0';
        PACKET_SCS                  : out std_logic_vector(3 downto 0) := (others => '0');
        PACKET_FRAME_ID             : out std_logic_vector(7 downto 0) := (others => '0');
        PACKET_SUBFRAME_ID          : out std_logic_vector(3 downto 0) := (others => '0');
        PACKET_SLOT_ID              : out std_logic_vector(5 downto 0) := (others => '0');
        PACKET_SYMBOL_ID            : out std_logic_vector(5 downto 0) := (others => '0')
    );
end ORAN_HDR_STAMP_UNIT;

architecture BEHAVE of ORAN_HDR_STAMP_UNIT is

    signal buf_in_valid             : std_logic_vector(2 downto 0) := (others => '0');
    signal buf_in_last              : std_logic_vector(2 downto 0) := (others => '0');
--    signal buf_in_keep              : std_logic_array8(2 downto 0) := (others => (others => '0'));
    signal buf_in_empty             : std_logic_array4(2 downto 0) := (others => (others => '0'));
    signal buf_in_data              : std_logic_array64(2 downto 0) := (others => (others => '0'));

    signal cnt                      : std_logic_vector(2 downto 0) := (others => '0');

    signal matched_version          : std_logic := '0';
    signal matched_c                : std_logic := '0';
    signal matched_message          : std_logic_vector(1 downto 0) := (others => '0');
    signal matched_id               : std_logic_vector(NUM_LINK-1 downto 0) := (others => '0');
    signal matched_pe               : std_logic_vector(NUM_LINK-1 downto 0) := (others => '0');
    signal matched_direction        : std_logic_vector(NUM_LINK-1 downto 0) := (others => '0');
    signal matched_map              : std_logic_vector(15 downto 0) := (others => '0');

    signal version                  : std_logic_vector(3 downto 0);
    signal c                        : std_logic_vector(0 downto 0);
    signal message                  : std_logic_vector(7 downto 0);
    signal payload                  : std_logic_vector(15 downto 0);
    signal datadirection            : std_logic;
    signal eaxc_id                  : std_logic_vector(15 downto 0);
    signal length                   : std_logic_vector(15 downto 0) := (others => '1');
    signal packet_is_valid          : std_logic := '0';
    signal packet_is_end            : std_logic := '0';

    signal condition0               : std_logic := '0';
    signal condition1               : std_logic_vector(1 downto 0) := (others => '0');

    signal output_enable            : std_logic_vector(1 downto 0) := (others => '0');

    signal section_type             : std_logic_vector(7 downto 0) := (others => '0');

    signal keep_to_empty            : std_logic_vector(2 downto 0) := (others => '0');
    signal left_length              : std_logic_vector(15 downto 0) := (others => '0');

    signal check_normality          : std_logic := '0';

    type std_logic_array_max_ru_element                      is array(natural range <>) of std_logic_vector( MAX_RU_ELEMENT-1 downto 0);
    signal in_pe_index_d            :  std_logic_array_max_ru_element(10 downto 0);

    signal payload_version           : std_logic_vector(2 downto 0);
    signal matched_payload_version  : std_logic_vector(NUM_LINK-1 downto 0) := (others => '0');


begin

--------------------------------------------------------------------------------
-- Parameters
--------------------------------------------------------------------------------
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            in_pe_index_d <= in_pe_index_d(9 downto 0) & IN_PE_INDEX;
        end if;
    end process;
    OUT_PE_INDEX <= in_pe_index_d(6);

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (IN_VALID = '1') then
                if (IN_LAST = '1') then
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

    version            <= IN_DATA(7 downto 4);
    c                  <= IN_DATA(0 downto 0);
    message            <= IN_DATA(15 downto 8);
    payload            <= IN_DATA(23 downto 16) & IN_DATA(31 downto 24);
    datadirection      <= IN_DATA(7);
    
    payload_version    <= IN_DATA(6 downto 4);

    eaxc_id            <= IN_DATA(39 downto 32) & IN_DATA(47 downto 40);

--------------------------------------------------------------------------------
-- ecpriVersion, ecpriConcatenate (eCPRI layer)
--------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (IN_VALID = '1') and (IN_LAST = '1') then
            if (IN_LAST = '1') then
                matched_version <= '0';
            else
                if (cnt = 0) then
                    if (version = "0001") then
                        matched_version <= '1';
                    else
                        matched_version <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (IN_VALID = '1') and (IN_LAST = '1') then
            if (IN_LAST = '1') then
                matched_c <= '0';
            else
                if (cnt = 0) then
                    if (c = "0") then
                        matched_c <= '1';
                    else
                        matched_c <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

--    process (CLK)
--    begin
--        if (CLK'event and CLK = '1') then
            condition0 <= matched_version and matched_c;
--        end if;
--    end process;

--------------------------------------------------------------------------------
-- ecpriMessage (eCPRI layer)
--------------------------------------------------------------------------------

    u_IN_CP_USED : if IMPL_CP = true generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (IN_VALID = '1') and (IN_LAST = '1') then
            if (IN_LAST = '1') then
                matched_message(0) <= '0';
            else
                if (cnt = 0) then
                    if (message = x"02") then
                        matched_message(0) <= '1';
                    else
                        matched_message(0) <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
    end generate;

    u_IN_CP_UNUSED : if IMPL_CP = false generate
    matched_message(0) <= '0';
    end generate;

    u_IN_UP_USED : if IMPL_UP = true generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (IN_VALID = '1') and (IN_LAST = '1') then
            if (IN_LAST = '1') then
                matched_message(1) <= '0';
            else
                if (cnt = 0) then
                    if (message = x"00") then
                        matched_message(1) <= '1';
                    else
                        matched_message(1) <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
    end generate;

    u_IN_UP_UNUSED : if IMPL_UP = false generate
    matched_message(1) <= '0';
    end generate;

--    process (CLK)
--    begin
--        if (CLK'event and CLK = '1') then
            condition1 <= matched_message;
--        end if;
--    end process;

--------------------------------------------------------------------------------
-- ecpriRtcid/ecpriPcid (eCPRI layer)
--------------------------------------------------------------------------------

    u_DL_PARAM_ID : for i in NUM_LINK-1 downto 0 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (IN_VALID = '1') and (IN_LAST = '1') then
            if (IN_LAST = '1') then
                matched_id(i) <= '0';
            else
                if (cnt = 0) then
                    if (eaxc_id = PARAM_ID(i)) then
                        matched_id(i) <= PARAM_ID_EN(i);
                    else
                        matched_id(i) <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (IN_VALID = '1') and (IN_LAST = '1') then
            if (IN_LAST = '1') then
                matched_pe(i) <= '0';
            else
                if (cnt = 0) then
                    if (IN_PE_INDEX = PE_INDEX(i)(MAX_RU_ELEMENT-1 downto 0)) then
                        matched_pe(i) <= '1';
                    else
                        matched_pe(i) <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
    end generate;

--------------------------------------------------------------------------------
-- ecpriPayload (eCPRI layer)
--------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (IN_VALID /= 0) and (IN_LAST = '1') then
--                length <= (others => '0');
--            else
                if (IN_VALID = '1') and (cnt = 0) then
--                    length <= payload + 4;
                    length <= payload + 3;
                else
                    if (buf_in_valid(0) = '1') then
                        length <= length - buf_in_empty(0);
                    end if;
                end if;
--            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (buf_in_valid(0) = '1') then
                if (length(15) = '1') then
                    packet_is_valid <= '0';
                else
                    packet_is_valid <= '1';
                end if;
            else
                packet_is_valid <= '0';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (buf_in_valid(0) = '1') then
                if (length(15 downto 3) = 0) then
                    packet_is_end <= '1';
                else
                    packet_is_end <= '0';
                end if;
            else
                packet_is_end <= '0';
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------
-- dataDirection (O-RAN layer)
--------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (IN_VALID = '1') and (IN_LAST = '1') then
            if (IN_LAST = '1') then
                matched_direction <= (others => '0');
                matched_payload_version <= (others => '0');
            else
                if (cnt = 1) then
                    if (datadirection = LINK_DIRECTION) then
                        matched_direction <= (others => '1');
                    else
                        matched_direction <= (others => '0');
                    end if;
                    
                    if (payload_version = "001") then
                        matched_payload_version <= (others => '1');
                    else
                        matched_payload_version <= (others => '0');
                    end if;
                    
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (cnt = 2) then
                matched_map <= EXT(matched_id and matched_pe and matched_direction and matched_payload_version, 16);
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Output control
--------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            buf_in_valid(1 downto 0) <= buf_in_valid(0) & IN_VALID;
            buf_in_last(1 downto 0)  <= buf_in_last(0) & IN_LAST;
            buf_in_data(1 downto 0)  <= buf_in_data(0) & IN_DATA;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            buf_in_valid(2) <= buf_in_valid(1) and packet_is_valid;
            buf_in_last(2)  <= buf_in_last(1) or packet_is_end;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            buf_in_empty(0) <= KEEP_TO_EMPTY_LSB(IN_KEEP);
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (length(15 downto 3) = 0) then
                if (length(2 downto 0) < buf_in_empty(0)) then
                    buf_in_empty(1) <= ('0' & length(2 downto 0)) + 1;
                else
                    buf_in_empty(1) <= buf_in_empty(0);
                end if;
            else
                buf_in_empty(1) <= "1000";
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            buf_in_empty(2) <= buf_in_empty(1);
            buf_in_data(2)  <= buf_in_data(1);
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (cnt = 2) then
                if (condition0 = '1') then
                    output_enable <= condition1;
                else
                    output_enable <= (others => '0');
                end if;
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Output (C-Plane)
--------------------------------------------------------------------------------

    u_OUT_CP_USED : if IMPL_CP = true generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (output_enable(0) = '1') and (buf_in_valid(2) = '1') then
                OUT_CP_VALID <= '1';
            else
                OUT_CP_VALID <= '0';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (output_enable(0) = '1') and (buf_in_valid(2) = '1') then
                OUT_CP_LAST  <= buf_in_last(2);
                OUT_CP_KEEP  <= EMPTY_TO_KEEP_LSB(buf_in_empty(2));
                OUT_CP_DATA  <= buf_in_data(2);
            else
                OUT_CP_LAST  <= '0';
                OUT_CP_KEEP  <= (others => '0');
                OUT_CP_DATA  <= (others => '0');
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (output_enable(0) = '1') and (buf_in_valid(2) = '1') and (matched_map /= 0) then
                OUT_CP_INDEX    <= conv_std_logic_vector(DATA_INDEX, 3);
            else
                OUT_CP_INDEX    <= (others => '0');
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (output_enable(0) = '1') and (buf_in_valid(2) = '1') then
                OUT_CP_LINK_MAP <= matched_map;
            else
                OUT_CP_LINK_MAP <= (others => '0');
            end if;
        end if;
    end process;
    end generate;

    u_OUT_CP_UNUSED : if IMPL_CP = false generate
    OUT_CP_VALID                    <= '0';
    OUT_CP_LAST                     <= '0';
    OUT_CP_KEEP                     <= (others => '0');
    OUT_CP_DATA                     <= (others => '0');
    OUT_CP_INDEX                    <= (others => '0');
    OUT_CP_LINK_MAP                 <= (others => '0');
    end generate;

--------------------------------------------------------------------------------
-- Output (U-Plane)
--------------------------------------------------------------------------------

    u_OUT_UP_USED : if IMPL_UP = true generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (output_enable(1) = '1') and (buf_in_valid(2) = '1') then
                OUT_UP_VALID <= '1';
            else
                OUT_UP_VALID <= '0';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (output_enable(1) = '1') and (buf_in_valid(2) = '1') then
                OUT_UP_LAST  <= buf_in_last(2);
                OUT_UP_KEEP  <= EMPTY_TO_KEEP_LSB(buf_in_empty(2));
                OUT_UP_DATA  <= buf_in_data(2);
            else
                OUT_UP_LAST  <= '0';
                OUT_UP_KEEP  <= (others => '0');
                OUT_UP_DATA  <= (others => '0');
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (output_enable(1) = '1') and (buf_in_valid(2) = '1') and (matched_map /= 0) then
                OUT_UP_INDEX    <= conv_std_logic_vector(DATA_INDEX, 3);
            else
                OUT_UP_INDEX    <= (others => '0');
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (output_enable(1) = '1') and (buf_in_valid(2) = '1') then
                OUT_UP_LINK_MAP <= matched_map;
            else
                OUT_UP_LINK_MAP <= (others => '0');
            end if;
        end if;
    end process;
    end generate;

    u_OUT_UP_UNUSED : if IMPL_UP = false generate
    OUT_UP_VALID                    <= '0';
    OUT_UP_LAST                     <= '0';
    OUT_UP_KEEP                     <= (others => '0');
    OUT_UP_DATA                     <= (others => '0');
    OUT_UP_INDEX                    <= (others => '0');
    OUT_UP_LINK_MAP                 <= (others => '0');
    end generate;

--------------------------------------------------------------------------------
-- Packet header stamp for RX window measurement
--------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (cnt = 3) then
                for i in MAX_RU_ELEMENT-1 downto 0 loop
                if (IN_PE_INDEX(i) = '1') then
                    if (matched_map = 0) then
                        PACKET_IS_CP(i) <= '0';
                        PACKET_IS_UP(i) <= '0';
                    else
                        PACKET_IS_CP(i) <= output_enable(0);
                        PACKET_IS_UP(i) <= output_enable(1);
                    end if;
                else
                    PACKET_IS_CP(i) <= '0';
                    PACKET_IS_UP(i) <= '0';
                end if;
                end loop;
            else
                PACKET_IS_CP <= (others => '0');
                PACKET_IS_UP <= (others => '0');
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (cnt = 1) then
                section_type <= IN_DATA(47 downto 40);
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (cnt = 2) then
                for i in NUM_LINK-1 downto 0 loop
                if (matched_id(i) = '1') then
                    PACKET_IS_NDM <= ENABLE_NDM(i);
                end if;
                end loop;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (cnt = 2) then
                if (output_enable(0) = '1') and (section_type = 3) then
                    PACKET_SCS <= IN_DATA(3 downto 0);
                else
                    for i in NUM_LINK-1 downto 0 loop
                    if (matched_id(i) = '1') then
                        PACKET_SCS <= SCS_CONFIG(i);
                    end if;
                    end loop;
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (cnt = 1) then
                PACKET_FRAME_ID    <= IN_DATA(15 downto 8);
                PACKET_SUBFRAME_ID <= IN_DATA(23 downto 20);
                PACKET_SLOT_ID     <= IN_DATA(19 downto 16) & IN_DATA(31 downto 30);
                PACKET_SYMBOL_ID   <= IN_DATA(29 downto 24);
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (IN_VALID = '1') and (IN_LAST = '1') then
                if (matched_version = '0') then
                    CNTUP_INVALID_ecpriVersion <= '1';
                else
                    CNTUP_INVALID_ecpriVersion <= '0';
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (IN_VALID = '1') and (IN_LAST = '1') then
                if (matched_c = '0') then
                    CNTUP_INVALID_ecpriC <= '1';
                else
                    CNTUP_INVALID_ecpriC <= '0';
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (IN_VALID = '1') and (IN_LAST = '1') then
                if (matched_message = 0) then
                    CNTUP_INVALID_ecpriMessage <= '1';
                else
                    CNTUP_INVALID_ecpriMessage <= '0';
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case IN_KEEP is
            when "00000001" => keep_to_empty <= "000";
            when "00000011" => keep_to_empty <= "001";
            when "00000111" => keep_to_empty <= "010";
            when "00001111" => keep_to_empty <= "011";
            when "00011111" => keep_to_empty <= "100";
            when "00111111" => keep_to_empty <= "101";
            when "01111111" => keep_to_empty <= "110";
            when "11111111" => keep_to_empty <= "111";
            when others     => keep_to_empty <= "111";
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (buf_in_valid(0) = '1') and (buf_in_last(0) = '1') then
--                if (packet_is_end = '1') then
--                    left_length <= (others => '1');
--                else
                    left_length <= length - keep_to_empty;
--                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (buf_in_valid(0) = '1') and (buf_in_last(0) = '1') then
                check_normality <= '1';
            else
                check_normality <= '0';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (check_normality = '1') and (left_length = 0) then
                CNTUP_LENGTH_IS_NORMAL <= '1';
            else
                CNTUP_LENGTH_IS_NORMAL <= '0';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (check_normality = '1') and (left_length(15) = '0') and (left_length(14 downto 0) /= 0) then
                CNTUP_LENGTH_IS_LONG <= '1';
            else
                CNTUP_LENGTH_IS_LONG <= '0';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (check_normality = '1') and (left_length(15) = '1') then
                CNTUP_LENGTH_IS_SHORT <= '1';
            else
                CNTUP_LENGTH_IS_SHORT <= '0';
            end if;
        end if;
    end process;

end BEHAVE;