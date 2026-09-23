--------------------------------------------------------------------------------
--
-- Copyright (C) 2024, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com) \ nhu.dong
-- Date     : 2024.03.11
--------------------------------------------------------------------------------
-- Function description
--   -. ORAN C-Plane processing (without sectionType 6)
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2024.03.11) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.ARRAY_TYPE.ALL;
use WORK.PKG_ORAN.ALL;
use WORK.PKG_ORAN_ARRAY.ALL;

entity DL_CP_UP_STAMPING_32 is
    generic (
        USAGE_TYPE0                 : boolean := false;
        USAGE_TYPE1                 : boolean := true;
        USAGE_TYPE3                 : boolean := true;
        USAGE_TYPE5                 : boolean := true;
        USAGE_TYPE6                 : boolean := false;
        USAGE_TYPE7                 : boolean := false;
        MAX_SECTIONID_PER_PKT       : natural := 5;
        NUM_LINK                    : natural := 16

    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;                            -- 245.76-MHz
        RST                         : in  std_logic;                            -- CLK

        PARAM_ID_EN                 : in  std_logic_vector(63 downto 0);
        PARAM_ID                    : in  std_logic_array16(63 downto 0);
        PE_INDEX                    : in  std_logic_array8(63 downto 0);
        SCS_CONFIG                  : in  std_logic_array4(63 downto 0);
        
--------------------------------------------------------------------------------
-- CU-Plane
--------------------------------------------------------------------------------

        CUP32_VALID                  : in  std_logic;
        CUP32_LAST                   : in  std_logic;
        CUP32_DATA                   : in  std_logic_vector(31 downto 0);
        IN_PE_INDEX               	 : in  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

----------------------------------------------------------------------------------
---- Packet stamp
----------------------------------------------------------------------------------

        PACKET_IS_CP                : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_UP                : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

        PACKET_SCS                  : out std_logic_vector(3 downto 0) := (others => '0');
        PACKET_FRAME_ID             : out std_logic_vector(7 downto 0) := (others => '0');
        PACKET_SUBFRAME_ID          : out std_logic_vector(3 downto 0) := (others => '0');
        PACKET_SLOT_ID              : out std_logic_vector(5 downto 0) := (others => '0');
        PACKET_SYMBOL_ID            : out std_logic_vector(5 downto 0) := (others => '0');        
        PACKET_SECTION_ID           : out std_logic_array13(MAX_SECTIONID_PER_PKT-1 downto 0);

        OUT_CUP_LINK_MAP             : out std_logic_vector(NUM_LINK-1 downto 0)

    );
end DL_CP_UP_STAMPING_32;

architecture BEHAVE of DL_CP_UP_STAMPING_32 is

    component RST_SYNC is
    generic (
        DLY_NUM                     : natural := 4;
        MAX_FANOUT_NUM              : integer := 200
    );
    port (
        RST_IN                      : in  std_logic;
        CLK                         : in  std_logic;
        RST_OUT                     : out std_logic
    );
    end component;

    signal srst                     : std_logic;

    signal buf_valid                : std_logic := '0';
    signal buf_last                 : std_logic := '0';
    signal buf_data                 : std_logic_vector(31 downto 0) := (others => '0');
    signal buf_data_index           : std_logic_vector(2 downto 0) := (others => '0');
    signal buf_link_index           : std_logic_vector(3 downto 0) := (others => '0');

    type fsm_c_plane                is (HDR0, HDR1, DEC0, DEC1, DEC2, SEC0, SEC1, SEC2, EXT0, EXT1, DUMMY);
    signal fsm_dec                  : fsm_c_plane;
    signal cnt_dec_state            : std_logic_vector(7 downto 0) := (others => '0');
    signal cnt_sec                  : std_logic_vector(7 downto 0) := (others => '0');

--    signal field_data_id            : std_logic_vector(2 downto 0) := (others => '0');
    signal field_ant_id             : std_logic_vector(15 downto 0) := (others => '0');
    signal field_data_direction     : std_logic := '0';
--    signal field_filter_index       : std_logic_vector(3 downto 0) := (others => '0');
    signal field_frame_id           : std_logic_vector(7 downto 0) := (others => '0');
    signal field_subframe_id        : std_logic_vector(3 downto 0) := (others => '0');
    signal field_slot_id            : std_logic_vector(5 downto 0) := (others => '0');
    signal field_symbol_id          : std_logic_vector(5 downto 0) := (others => '0');
    signal field_num_section        : std_logic_vector(7 downto 0) := (others => '0');
    signal field_section_type       : std_logic_vector(7 downto 0) := (others => '0');
--    signal field_ud_comp_hdr        : std_logic_vector(7 downto 0) := (others => '0');
    signal field_section_id         : std_logic_vector(11 downto 0) := (others => '0');
--    signal field_rb                 : std_logic := '0';
--    signal field_syminc             : std_logic := '0';
--    signal field_start_prb          : std_logic_vector(9 downto 0) := (others => '0');
--    signal field_num_prb            : std_logic_vector(7 downto 0) := (others => '0');
--    signal field_num_symbol         : std_logic_vector(3 downto 0) := (others => '0');
    signal field_ef                 : std_logic := '0';
--    signal field_beamid             : std_logic_vector(14 downto 0) := (others => '0');
--    signal field_freq_offset        : std_logic_vector(23 downto 0) := (others => '0');
    signal field_ext_ef             : std_logic := '0';
--    signal field_ext_type           : std_logic_vector(6 downto 0) := (others => '0');
    signal field_ext_len            : std_logic_vector(7 downto 0) := (others => '0');
    signal en                       : std_logic;
    signal c_plane                  : std_logic;
    signal u_plane                  : std_logic;
    signal dl_direction             : std_logic;
    signal ul_direction             : std_logic;
    signal frame_id                 : std_logic_vector(7 downto 0) := (others => '0');
    signal subframe_id              : std_logic_vector(3 downto 0) := (others => '0');
    signal slot_id                  : std_logic_vector(5 downto 0) := (others => '0');
    signal symbol_id                : std_logic_vector(5 downto 0) := (others => '0');
    signal section_type             : std_logic_vector(7 downto 0) := (others => '0');
    signal scs                      : std_logic_vector(3 downto 0) := (others => '0');
    
    signal matched_id               : std_logic_vector(NUM_LINK-1 downto 0) := (others => '0');
    signal matched_pe               : std_logic_vector(NUM_LINK-1 downto 0) := (others => '0');

    signal eaxc_id                  : std_logic_array16(NUM_LINK-1 downto 0);
--    signal param_id                 : std_logic_array16(7 downto 0);
--    signal param_id_enable          : std_logic_vector(7 downto 0);

    signal pkt_is_cp_dl             : std_logic;
    signal pkt_is_up_dl             : std_logic;
    
    signal pkt_is_cp_dl_d           : std_logic;
    signal pkt_is_up_dl_d           : std_logic;
    
    signal pkt_is_cp_dl_fpl         : std_logic;
    signal pkt_is_up_dl_fpl         : std_logic;
    signal packet_sectionids        : std_logic_array13(MAX_SECTIONID_PER_PKT-1 downto 0) := (others => ("1000000000000"));
    signal matched_map              : std_logic_vector(15 downto 0) := (others => '0');
    
    signal pkt_is_cp_dl_dd             : std_logic_vector(MAX_RU_ELEMENT-1 downto 0);     
    signal pkt_is_up_dl_dd             : std_logic_vector(MAX_RU_ELEMENT-1 downto 0);     
    
    signal pkt_is_cp_dl_ddd             : std_logic_vector(MAX_RU_ELEMENT-1 downto 0);     
    signal pkt_is_up_dl_ddd             : std_logic_vector(MAX_RU_ELEMENT-1 downto 0);     

begin

    u_RST : RST_SYNC
    generic map(
        DLY_NUM                     => 4                                       ,--: natural := 4;
        MAX_FANOUT_NUM              => 200                                      --: integer := 200
    )
    port map(
        RST_IN                      => RST                                     ,--: in  std_logic;
        CLK                         => CLK                                     ,--: in  std_logic;
        RST_OUT                     => srst                                     --: out std_logic
    );

--------------------------------------------------------------------------------
-- FSM for C-Plane decoding
--------------------------------------------------------------------------------

--    process (CLK)
--    begin
--        if (CLK'event and CLK = '1') then
            PACKET_SCS         <= scs;
            PACKET_FRAME_ID    <= frame_id;
            PACKET_SUBFRAME_ID <= subframe_id;
--            PACKET_SLOT_ID     <= slot_id;
--            PACKET_SYMBOL_ID   <= symbol_id;
            PACKET_SLOT_ID     <= "00" & slot_id(3 downto 0);
            PACKET_SYMBOL_ID   <= "00" & symbol_id(3 downto 0);
            
--        end if;
--    end process;

    u_DL_PARAM_ID : for i in NUM_LINK-1 downto 0 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (IN_VALID = '1') and (IN_LAST = '1') then
            if (CUP32_LAST = '1') then
                matched_id(i) <= '0';
            else                
                if (fsm_dec = DEC0) then

                    if (eaxc_id(i) = PARAM_ID(i)) then
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
            if (CUP32_LAST = '1') then
                matched_pe(i) <= '0';
            else
                if (fsm_dec = DEC0) then
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

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then            

            if (fsm_dec = DEC1) then
                for i in MAX_RU_ELEMENT-1 downto 0 loop
                    if (IN_PE_INDEX(i) = '1') then
                        pkt_is_cp_dl_dd(i) <= field_data_direction and c_plane;
                        pkt_is_up_dl_dd(i) <= field_data_direction and u_plane;                        
                    else
                        pkt_is_cp_dl_dd(i) <= '0';
                        pkt_is_up_dl_dd(i) <= '0';                                
                    end if;
                 end loop;
             else
                 pkt_is_cp_dl_dd <= (others => '0');
                 pkt_is_up_dl_dd <= (others => '0');                 
             end if;
--             pkt_is_cp_dl_dd <= pkt_is_cp_dl_d;
--             pkt_is_up_dl_dd <= pkt_is_up_dl_d;
             
             PACKET_IS_CP <= pkt_is_cp_dl_dd;
             PACKET_IS_UP <= pkt_is_up_dl_dd;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (fsm_dec = DEC1) then
                matched_map <= EXT(matched_id and matched_pe, 16);
--            end if;
        end if;
    end process;
    
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (fsm_dec = DEC1) then
                OUT_CUP_LINK_MAP <= EXT(matched_id and matched_pe, NUM_LINK); --16); --matched_map;
            else 
                if (fsm_dec = DEC0) then
                    OUT_CUP_LINK_MAP <= (others => '0');
                end if;
            end if;
        end if;
    end process;
    
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            buf_valid      <= CUP32_VALID;
            buf_last       <= CUP32_LAST;
            buf_data       <= CUP32_DATA;
        end if;
    end process;

    -- FSM
    process (srst, CLK)
    begin
        if (srst = '1') then
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
                if (c_plane = '1') then -- C plane continue checking section id of sections if any
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
                else      -- Uplane end checking after got section id
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
            when HDR0   =>
                if (buf_data(23 downto 16) = x"02") then -- message_type C
                    c_plane <= '1';
                else
                    c_plane <= '0';
                end if;
                if (buf_data(23 downto 16) = x"00") then -- U
                    u_plane <= '1';
                else
                    u_plane <= '0';
                end if;                                
            when others =>
                NULL;
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_dec is
            when HDR1   =>
                eaxc_id(0)         <= buf_data(31 downto 16);
                eaxc_id(1)         <= buf_data(31 downto 16);
                eaxc_id(2)         <= buf_data(31 downto 16);
                eaxc_id(3)         <= buf_data(31 downto 16);
                eaxc_id(4)         <= buf_data(31 downto 16);
                eaxc_id(5)         <= buf_data(31 downto 16);
                eaxc_id(6)         <= buf_data(31 downto 16);
                eaxc_id(7)         <= buf_data(31 downto 16);
            when HDR0 =>
                eaxc_id(0)         <= (others => '0');
                eaxc_id(1)         <= (others => '0');
                eaxc_id(2)         <= (others => '0');
                eaxc_id(3)         <= (others => '0');
                eaxc_id(4)         <= (others => '0');
                eaxc_id(5)         <= (others => '0');
                eaxc_id(6)         <= (others => '0');
                eaxc_id(7)         <= (others => '0');
            when others => 
                NULL;
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

--------------------------------------------------------------------------------
-- FSM for C-Plane decoding
--------------------------------------------------------------------------------

    -- 1st word (eCPRI header)
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_dec is
            when DEC0   =>
--                field_data_id         <= buf_data_index;
                field_ant_id          <= VALUE16_TO_BIT16(buf_link_index);
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
            when HDR0   => 
                field_data_direction <= '0';
            when DEC0   =>
                field_data_direction  <= buf_data(31);

                frame_id        <= buf_data(23 downto 16);
                subframe_id     <= buf_data(15 downto 12);
                slot_id         <= buf_data(11 downto 6);
                symbol_id       <= buf_data(5 downto 0);

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

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (fsm_dec = DEC1) then
                
                for i in NUM_LINK-1 downto 0 loop
                    if (matched_id(i) = '1') then
                        PACKET_SCS <= SCS_CONFIG(i);
                    end if;
                end loop;
                
            end if;
        end if;
    end process;
 
    -- 1st word (Section header)
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_dec is
            when SEC0   =>
                if (c_plane = '1') then
                    packet_sectionids   <= packet_sectionids(MAX_SECTIONID_PER_PKT-2 downto 0) & ('0' & buf_data(31 downto 20));
                end if;
                
            when DEC1   =>
                if (u_plane = '1') then
                    field_section_id    <= buf_data(31 downto 20);
                    packet_sectionids   <= packet_sectionids(MAX_SECTIONID_PER_PKT-2 downto 0) & ('0' & buf_data(31 downto 20));
                end if;
                   
            when HDR1   => 
                 packet_sectionids   <= (others => ("1000000000000"));
                 
            when others =>
                NULL;
            end case;
        end if;
    end process;

    PACKET_SECTION_ID <= packet_sectionids;

    -- 2nd word (Section header)
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_dec is
            when SEC1   =>
--                field_num_symbol      <= buf_data(19 downto 16);
                field_ef              <= buf_data(15);
--                field_beamid          <= buf_data(14 downto 0);
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
--                field_ext_type        <= (others => '0');
                field_ext_len         <= (others => '0');
--                field_num_portc       <= (others => '0');
            when EXT0   =>
                field_ext_ef          <= buf_data(31);
--                field_ext_type        <= buf_data(30 downto 24);
                field_ext_len         <= buf_data(23 downto 16);
--                if (buf_data(30 downto 24) = 10) then
--                    if (buf_data(13 downto 8) = 0) then
--                        field_num_portc       <= (others => '1');               -- exception (65R -> 64R)
--                    else
--                        field_num_portc       <= buf_data(13 downto 8);
--                    end if;
--                end if;
            when others =>
                NULL;
            end case;
        end if;
    end process;



end BEHAVE;