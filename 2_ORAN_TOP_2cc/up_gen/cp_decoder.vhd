--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : UL Scheduler (O-RAN component)                                --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.15                                                    --
--                                                                            --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity CP_DECODER is
    generic (
        USAGE_TYPE0                 : boolean := false;
        USAGE_TYPE1                 : boolean := true;
        USAGE_TYPE3                 : boolean := true;
        USAGE_TYPE5                 : boolean := true;
        USAGE_TYPE6                 : boolean := false;
        USAGE_TYPE7                 : boolean := false
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;
        RST                         : in  std_logic;                            -- SYNC@CLK

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- ORAN interconnect
--------------------------------------------------------------------------------

        C_PLANE_VALID               : in  std_logic;
        C_PLANE_LAST                : in  std_logic;
        C_PLANE_DATA                : in  std_logic_vector(31 downto 0);
        C_PLANE_DATA_INDEX          : in  std_logic_vector(2 downto 0);
        C_PLANE_LINK_INDEX          : in  std_logic_vector(3 downto 0);

--------------------------------------------------------------------------------
-- Section manager
--------------------------------------------------------------------------------

        CP_UPDATE                   : out std_logic;

        CP_DATA_ID                  : out std_logic_vector(2 downto 0);
        CP_ANT_ID                   : out std_logic_vector(3 downto 0);
        CP_DATA_DIRECTION           : out std_logic;
        CP_FILTER_INDEX             : out std_logic_vector(3 downto 0);
        CP_FRAME_ID                 : out std_logic_vector(7 downto 0);
        CP_SUBFRAME_ID              : out std_logic_vector(3 downto 0);
        CP_SLOT_ID                  : out std_logic_vector(5 downto 0);
        CP_SYMBOL_ID                : out std_logic_vector(5 downto 0);
        CP_SECTION_TYPE             : out std_logic_vector(7 downto 0);
        CP_UD_COMP_HDR              : out std_logic_vector(7 downto 0);
        CP_SECTION_ID               : out std_logic_vector(11 downto 0);
        CP_RB                       : out std_logic;
        CP_START_PRB                : out std_logic_vector(9 downto 0);
        CP_NUM_PRB                  : out std_logic_vector(7 downto 0);
        CP_NUM_SYMBOL               : out std_logic_vector(3 downto 0);
        CP_BEAMID                   : out std_logic_vector(14 downto 0);
        CP_FREQ_OFFSET              : out std_logic_vector(23 downto 0);
        CP_NUM_PORTC                : out std_logic_vector(5 downto 0)
    );
end CP_DECODER;

architecture BEHAVE of CP_DECODER is

    signal buf_valid                : std_logic := '0';
    signal buf_last                 : std_logic := '0';
    signal buf_data                 : std_logic_vector(31 downto 0) := (others => '0');
    signal buf_data_index           : std_logic_vector(2 downto 0) := (others => '0');
    signal buf_link_index           : std_logic_vector(3 downto 0) := (others => '0');

    type fsm_c_plane                is (HDR0, HDR1, DEC0, DEC1, DEC2, SEC0, SEC1, SEC2, EXT0, EXT1, DUMMY);
    signal fsm_dec                  : fsm_c_plane;
    signal cnt_dec_state            : std_logic_vector(7 downto 0) := (others => '0');
    signal cnt_sec                  : std_logic_vector(7 downto 0) := (others => '0');

    signal field_data_id            : std_logic_vector(2 downto 0) := (others => '0');
    signal field_ant_id             : std_logic_vector(3 downto 0) := (others => '0');
    signal field_data_direction     : std_logic := '0';
    signal field_filter_index       : std_logic_vector(3 downto 0) := (others => '0');
    signal field_frame_id           : std_logic_vector(7 downto 0) := (others => '0');
    signal field_subframe_id        : std_logic_vector(3 downto 0) := (others => '0');
    signal field_slot_id            : std_logic_vector(5 downto 0) := (others => '0');
    signal field_symbol_id          : std_logic_vector(5 downto 0) := (others => '0');
    signal field_num_section        : std_logic_vector(7 downto 0) := (others => '0');
    signal field_section_type       : std_logic_vector(7 downto 0) := (others => '0');
    signal field_ud_comp_hdr        : std_logic_vector(7 downto 0) := (others => '0');
    signal field_section_id         : std_logic_vector(11 downto 0) := (others => '0');
    signal field_rb                 : std_logic := '0';
--    signal field_syminc             : std_logic := '0';
    signal field_start_prb          : std_logic_vector(9 downto 0) := (others => '0');
    signal field_num_prb            : std_logic_vector(7 downto 0) := (others => '0');
    signal field_num_symbol         : std_logic_vector(3 downto 0) := (others => '0');
    signal field_ef                 : std_logic := '0';
    signal field_beamid             : std_logic_vector(14 downto 0) := (others => '0');
    signal field_freq_offset        : std_logic_vector(23 downto 0) := (others => '0');
    signal field_ext_ef             : std_logic := '0';
    signal field_ext_len            : std_logic_vector(7 downto 0) := (others => '0');
    signal field_num_portc          : std_logic_vector(5 downto 0) := (others => '0');

begin

--------------------------------------------------------------------------------
-- FSM for C-Plane decoding
--------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            buf_valid      <= C_PLANE_VALID;
            buf_last       <= C_PLANE_LAST;
            buf_data       <= C_PLANE_DATA;
            buf_data_index <= C_PLANE_DATA_INDEX;
            buf_link_index <= C_PLANE_LINK_INDEX;
        end if;
    end process;

    -- FSM
    process (RST, CLK)
    begin
        if (RST = '1') then
            fsm_dec <= HDR0;
        elsif (CLK'event and CLK = '1') then
            case fsm_dec is
            when HDR0   =>
                if (buf_valid = '1') then
                    fsm_dec <= HDR1;
                else
                    fsm_dec <= HDR0;
                end if;
            when HDR1   =>
                fsm_dec <= DEC0;
            when DEC0   =>
                fsm_dec <= DEC1;
            when DEC1   =>
                if    (USAGE_TYPE0 = true) and (buf_data(23 downto 16) = 0) then
                    fsm_dec <= DUMMY;
                elsif (USAGE_TYPE1 = true) and (buf_data(23 downto 16) = 1) then
                    fsm_dec <= SEC0;
                elsif (USAGE_TYPE3 = true) and (buf_data(23 downto 16) = 3) then
                    fsm_dec <= DEC2;
                elsif (USAGE_TYPE5 = true) and (buf_data(23 downto 16) = 5) then
                    fsm_dec <= SEC0;
                elsif (USAGE_TYPE6 = true) and (buf_data(23 downto 16) = 6) then
                    fsm_dec <= DUMMY;
                elsif (USAGE_TYPE7 = true) and (buf_data(23 downto 16) = 7) then
                    fsm_dec <= DUMMY;
                else
                    fsm_dec <= DUMMY;
                end if;
            when DEC2   =>
                fsm_dec <= SEC0;
            when SEC0   =>
                fsm_dec <= SEC1;
            when SEC1   =>
                if    (USAGE_TYPE1 = true) and (field_section_type = 1) then
                    if (buf_data(15) = '1') then
                        fsm_dec <= EXT0;
                    else
                        if (cnt_sec = field_num_section) then
                            if (buf_last = '1') then
                                fsm_dec <= HDR0;
                            else
                                fsm_dec <= DUMMY;
                            end if;
                        else
                            fsm_dec <= SEC0;
                        end if;
                    end if;
                elsif (USAGE_TYPE3 = true) and (field_section_type = 3) then
                    fsm_dec <= SEC2;
                elsif (USAGE_TYPE5 = true) and (field_section_type = 5) then
                    if (buf_data(15) = '1') then
                        fsm_dec <= EXT0;
                    else
                        if (cnt_sec = field_num_section) then
                            if (buf_last = '1') then
                                fsm_dec <= HDR0;
                            else
                                fsm_dec <= DUMMY;
                            end if;
                        else
                            fsm_dec <= SEC0;
                        end if;
                    end if;
                else
                    fsm_dec <= DUMMY;
                end if;
            when SEC2   =>
                if (field_ef = '1') then
                    fsm_dec <= EXT0;
                else
                    if (cnt_sec = field_num_section) then
                        if (buf_last = '1') then
                            fsm_dec <= HDR0;
                        else
                            fsm_dec <= DUMMY;
                        end if;
                    else
                        fsm_dec <= SEC0;
                    end if;
                end if;
            when EXT0   =>
                if (buf_data(23 downto 16) = cnt_dec_state) then
                    if (buf_data(31) = '1') then
                        fsm_dec <= EXT0;
                    else
                        if (cnt_sec = field_num_section) then
                            if (buf_last = '1') then
                                fsm_dec <= HDR0;
                            else
                                fsm_dec <= DUMMY;
                            end if;
                        else
                            fsm_dec <= SEC0;
                        end if;
                    end if;
                else
                    fsm_dec <= EXT1;
                end if;
            when EXT1   =>
                if (field_ext_len = cnt_dec_state) then
                    if (field_ext_ef = '1') then
                        fsm_dec <= EXT0;
                    else
                        if (cnt_sec = field_num_section) then
                            if (buf_last = '1') then
                                fsm_dec <= HDR0;
                            else
                                fsm_dec <= DUMMY;
                            end if;
                        else
                            fsm_dec <= SEC0;
                        end if;
                    end if;
                else
                    fsm_dec <= EXT1;
                end if;
            when DUMMY  =>
                if (buf_last = '1') then
                    fsm_dec <= HDR0;
                else
                    fsm_dec <= DUMMY;
                end if;
            when others =>
                fsm_dec <= HDR0;
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_dec is
            when EXT0   =>
                if (buf_data(23 downto 16) = cnt_dec_state) then
                    cnt_dec_state <= "00000001";
                else
                    cnt_dec_state <= cnt_dec_state + 1;
                end if;
            when EXT1   =>
                if (field_ext_len = cnt_dec_state) then
                    cnt_dec_state <= "00000001";
                else
                    cnt_dec_state <= cnt_dec_state + 1;
                end if;
            when others =>
                cnt_dec_state <= "00000001";
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_dec is
            when DEC0   =>
                cnt_sec <= (others => '0');
            when SEC0   =>
                cnt_sec <= cnt_sec + 1;
            when others =>
                NULL;
            end case;
        end if;
    end process;

    -- 1st word (eCPRI header)
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_dec is
            when DEC0   =>
                field_data_id         <= buf_data_index;
                field_ant_id          <= buf_link_index;
            when others =>
                NULL;
            end case;
        end if;
    end process;

    -- 1st word (O-RAN header)
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_dec is
            when DEC0   =>
                field_data_direction  <= buf_data(31);
                field_filter_index    <= buf_data(27 downto 24);
                field_frame_id        <= buf_data(23 downto 16);
                field_subframe_id     <= buf_data(15 downto 12);
                field_slot_id         <= buf_data(11 downto 6);
                field_symbol_id       <= buf_data(5 downto 0);
            when others =>
                NULL;
            end case;
        end if;
    end process;

    -- 2nd word (O-RAN header)
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_dec is
            when DEC1   =>
                field_num_section     <= buf_data(31 downto 24);
                field_section_type    <= buf_data(23 downto 16);
            when others =>
                NULL;
            end case;
        end if;
    end process;

    -- 2nd&3rd word (O-RAN header)
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_dec is
            when DEC1   =>
                field_ud_comp_hdr     <= buf_data(15 downto 8);
            when DEC2   =>
                field_ud_comp_hdr     <= buf_data(15 downto 8);
            when others =>
                NULL;
            end case;
        end if;
    end process;

    -- 1st word (Section header)
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_dec is
            when SEC0   =>
                field_section_id      <= buf_data(31 downto 20);
                field_rb              <= buf_data(19);
--                field_syminc          <= buf_data(18);
                field_start_prb       <= buf_data(17 downto 8);
                field_num_prb         <= buf_data(7 downto 0);
            when others =>
                NULL;
            end case;
        end if;
    end process;

    -- 2nd word (Section header)
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_dec is
            when SEC1   =>
                field_num_symbol      <= buf_data(19 downto 16);
                field_ef              <= buf_data(15);
                field_beamid          <= buf_data(14 downto 0);
            when others =>
                NULL;
            end case;
        end if;
    end process;

    -- 3rd word (Section header)
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_dec is
            when SEC0   =>
                field_freq_offset     <= (others => '0');
            when SEC2   =>
                field_freq_offset     <= buf_data(31 downto 8);
            when others =>
                NULL;
            end case;
        end if;
    end process;

    -- 1st word (Section extension header)
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_dec is
            when SEC0   =>
                field_ext_ef          <= '0';
                field_ext_len         <= (others => '0');
                field_num_portc       <= (others => '0');
            when EXT0   =>
                field_ext_ef          <= buf_data(31);
                field_ext_len         <= buf_data(23 downto 16);
                if (buf_data(30 downto 24) = 10) then
                    if (buf_data(13 downto 8) = 0) then
                        field_num_portc       <= (others => '1');               -- exception (65R -> 64R)
                    else
                        field_num_portc       <= buf_data(13 downto 8);
                    end if;
                end if;
            when others =>
                NULL;
            end case;
        end if;
    end process;

    -- write pulse (end of each sectionExtension / end of each section)
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_dec is
            when SEC1   =>
                if (field_section_type = 1) or (field_section_type = 5) then
                    if (buf_data(15) = '0') then
                        CP_UPDATE             <= '1';
                    else
                        CP_UPDATE             <= '0';
                    end if;
                else
                    CP_UPDATE             <= '0';
                end if;
            when SEC2   =>
                if (field_section_type = 3) then
                    if (field_ef = '0') then
                        CP_UPDATE             <= '1';
                    else
                        CP_UPDATE             <= '0';
                    end if;
                else
                    CP_UPDATE             <= '0';
                end if;
            when EXT0   =>
                if (buf_data(23 downto 16) = cnt_dec_state) then
                    if (buf_data(31) = '0') then
                        CP_UPDATE             <= '1';
                    else
                        CP_UPDATE             <= '0';
                    end if;
                else
                    CP_UPDATE             <= '0';
                end if;
            when EXT1   =>
                if (field_ext_len = cnt_dec_state) then
                    if (field_ext_ef = '0') then
                        CP_UPDATE             <= '1';
                    else
                        CP_UPDATE             <= '0';
                    end if;
                else
                    CP_UPDATE             <= '0';
                end if;
            when others =>
                CP_UPDATE             <= '0';
            end case;
        end if;
    end process;

    CP_DATA_ID        <= field_data_id;
    CP_ANT_ID         <= field_ant_id;
    CP_DATA_DIRECTION <= field_data_direction;
    CP_FILTER_INDEX   <= field_filter_index;
    CP_FRAME_ID       <= field_frame_id;
    CP_SUBFRAME_ID    <= field_subframe_id;
    CP_SLOT_ID        <= field_slot_id;
    CP_SYMBOL_ID      <= field_symbol_id;
    CP_SECTION_TYPE   <= field_section_type;
    CP_UD_COMP_HDR    <= field_ud_comp_hdr;
    CP_SECTION_ID     <= field_section_id;
    CP_RB             <= field_rb;
    CP_START_PRB      <= field_start_prb;
    CP_NUM_PRB        <= field_num_prb;
    CP_NUM_SYMBOL     <= field_num_symbol;
    CP_BEAMID         <= field_beamid;
    CP_FREQ_OFFSET    <= field_freq_offset;
    CP_NUM_PORTC      <= field_num_portc;

end BEHAVE;