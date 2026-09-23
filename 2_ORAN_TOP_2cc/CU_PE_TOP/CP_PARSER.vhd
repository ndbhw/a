--================================================================================
-- Filename     : CP_PARSER.vhd
-- Author       : Taeyoup Kim (taeyoup.kim@samsung.com)
-- Description  : O-RAN C-Plane(DL/UL) Parameter Parsing
----------------------------------------------------------------------------------
--     Date    |     By           |  Version | Description
----------------------------------------------------------------------------------
--  08-07-2020 | Taeyoup Kim      |    1.0   | Original Version
----------------------------------------------------------------------------------
--  02-08-2022 | MoonHyeok Jang   |    1.1   | Change cp_msg_valid initial value (0 -> 1)
--================================================================================
-- Copyright (c) 2020 SAMSUNG. All rights reserved.
--================================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;


    entity CP_PARSER is
    generic (
    eCPRI_HDR                   : boolean := FALSE
    );
    port (

    CLK                         : in std_logic;

    ------------------------------------------------------------------------------
    -- C-Plane (Not decoded)
    ------------------------------------------------------------------------------

    ECPRI_RX_C_CH_IDX           : in std_logic_vector(  3 downto 0);
    ECPRI_RX_C_VALID            : in std_logic;
    ECPRI_RX_C_LAST             : in std_logic;
    ECPRI_RX_C_KEEP             : in std_logic_vector(  3 downto 0);
    ECPRI_RX_C_DATA             : in std_logic_vector( 31 downto 0);

    ------------------------------------------------------------------------------
    --  Output to CP_LATER
    ------------------------------------------------------------------------------

    CP_UPDATE                   : out std_logic;
    CP_CH_IDX                   : out std_logic_vector(  3 downto 0);
    CP_PARAMETER                : out std_logic_vector(191+(15*3)+6+16 downto 0);

    CP_BLANKINGPATTERNID        : out std_logic_vector(  7 downto 0)

    );
    end CP_PARSER;

architecture BEHAVE of CP_PARSER is

    signal ch_idx               : std_logic_vector(  3 downto 0) := (others => '0');
    signal sec_word             : std_logic_vector(  2 downto 0) := (others => '0');
    signal end_section          : std_logic := '0';
    signal is_type0             : std_logic := '0'; -- MoonHyeok Jang (2023/01/16)
    signal ef                   : std_logic := '0';
    signal data_direction       : std_logic := '0';
    signal filter_index         : std_logic_vector(  3 downto 0) := (others => '0');
    signal frame_id             : std_logic_vector(  7 downto 0) := (others => '0');
    signal subframe_id          : std_logic_vector(  3 downto 0) := (others => '0');
    signal slot_id              : std_logic_vector(  5 downto 0) := (others => '0');
    signal start_symbol_id      : std_logic_vector(  5 downto 0) := (others => '0');
    signal start_symbol_id_pre  : std_logic_vector(  5 downto 0) := (others => '0');
    signal numInc               : std_logic_vector(  3 downto 0) := (others => '0');

    signal num_section          : std_logic_vector(  7 downto 0) := (others => '0');
    signal section_cnt          : std_logic_vector(  7 downto 0) := (others => '0');
    signal section_type         : std_logic_vector(  7 downto 0) := (others => '0');
    signal time_offset          : std_logic_vector( 15 downto 0) := (others => '0');
    signal frame_structure      : std_logic_vector(  7 downto 0) := (others => '0');
    signal cpLength             : std_logic_vector( 15 downto 0) := (others => '0');
    signal section_id           : std_logic_vector( 11 downto 0) := (others => '0');
    signal rb                   : std_logic := '0';
    signal symInc               : std_logic := '0';
    signal start_prbc           : std_logic_vector(  9 downto 0) := (others => '0');
    signal num_prbc             : std_logic_vector(  7 downto 0) := (others => '0');
    signal re_mask              : std_logic_vector( 11 downto 0) := (others => '0');
    signal num_symbol           : std_logic_vector(  3 downto 0) := (others => '0');
    signal beamId               : std_logic_vector( 14 downto 0) := (others => '0');
    signal freq_offset          : std_logic_vector( 23 downto 0) := (others => '0');

    -- For 2G/4G DSS
    signal blankingpatternid    : std_logic_vector(  7 downto 0) := (others => '0');

    signal ecpri_rx_c_valid_d   : std_logic_vector(  1 downto 0) := (others => '0');
    signal ecpri_rx_c_last_d    : std_logic_vector(  1 downto 0) := (others => '0');
    --signal cp_msg_valid         : std_logic := '0';
    signal cp_msg_valid         : std_logic := '1';    -- MoonHyeok Jang (2022/02/08)
    signal oran_rx_c_valid      : std_logic := '0';
    signal oran_rx_c_valid_d    : std_logic := '0';

    signal numberOfUEs          : std_logic_vector(  7 downto 0) := (others => '0');
    signal sec_type_6_complete  : std_logic := '0';

    signal beamId_group         : std_logic_vector(15*3-1 downto 0) := (others => '0');
    signal numPortc             : std_logic_vector(  5 downto 0) := (others => '0');

    signal eAxC_ID              : std_logic_vector(15 downto 0) := (others => '0');


begin


    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           ecpri_rx_c_valid_d <= ecpri_rx_c_valid_d(0) & ECPRI_RX_C_VALID;
           ecpri_rx_c_last_d  <= ecpri_rx_c_last_d(0) & ECPRI_RX_C_LAST;
        end if;
    end process;

    u_eCPRI_HDR_SUPPORT : if eCPRI_HDR = TRUE generate
       process (CLK)
       begin
           if (CLK'event and CLK = '1') then
              if (ECPRI_RX_C_VALID = '1') then
                 if (ecpri_rx_c_valid_d = "01" or (ecpri_rx_c_last_d(1) = '1' and ecpri_rx_c_valid_d = "11")) then
                    oran_rx_c_valid <= '1';
                    eAxC_ID <= ECPRI_RX_C_DATA(31 downto 16);
                 elsif (ECPRI_RX_C_LAST = '1') then
                    oran_rx_c_valid <= '0';
                 end if;
              else
                 oran_rx_c_valid <= '0';
              end if;
           end if;
       end process;
    end generate;

    u_eCPRI_HDR_NOT_SUPPORT : if eCPRI_HDR = FALSE generate
       oran_rx_c_valid <= ECPRI_RX_C_VALID;
    end generate;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (ecpri_rx_c_valid_d(0) = '1' and ecpri_rx_c_last_d(0) = '1') then
              cp_msg_valid <= '1';
           elsif (oran_rx_c_valid = '1' and sec_word = "000" and end_section = '1') then
              cp_msg_valid <= '0';
           end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (oran_rx_c_valid = '1') then
              if (ECPRI_RX_C_LAST = '1') then
                 sec_word <= "000"; end_section <= '1';
              else
                  case sec_word is
                     -- when "000"  => sec_word <= "001"; end_section <= '0';
                     when "000"  => sec_word <= "001"; end_section <= '0'; is_type0 <= '0';
                     -- when "001"  => if (ECPRI_RX_C_DATA(17) = ECPRI_RX_C_DATA(16)) then sec_word <= "010";              -- Section type 0, 3
                     --                elsif (ECPRI_RX_C_DATA(18 downto 17) = "11") then sec_word <= "110";                -- Section type 6
                     --                else sec_word <= "011";
                     --                end if;
                     when "001"  => if (ECPRI_RX_C_DATA(17 downto 16) = "11") then sec_word <= "010";                 -- Section type 3
                                    elsif (ECPRI_RX_C_DATA(17 downto 16) = "00") then sec_word <= "110"; is_type0 <= '1';  -- Section type 0
                                    else sec_word <= "011";                                                                -- Section type 1
                                    end if;
                     when "010"  => sec_word <= "011"; end_section <= '0';
                     when "011"  => sec_word <= "100"; end_section <= '0';
                     when "100"  => if (ECPRI_RX_C_DATA(15) = '1' and section_type(1 downto 0) = "01") then sec_word <= "111"; end_section <= '0';
                                    else
                                       if (section_type(1 downto 0) = "11") then sec_word <= "101"; end_section <= '0'; -- Section type 3
                                       elsif (num_section = section_cnt) then sec_word <= "000"; end_section <= '1';
                                       else sec_word <= "011"; end_section <= '1';
                                       end if;
                                    end if;
                                    -- check ef and go to section extension, will be added later
                     when "101"  => if (ef = '1') then sec_word <= "111"; end_section <= '0';
                                    else
                                       if (num_section = section_cnt) then sec_word <= "000";
                                       else sec_word <= "011";
                                       end if;
                                       end_section <= '1';
                                    end if;
                                    -- check ef and go to section extension, will be added later
                     -- when "110"  => if (sec_type_6_complete = '1') then sec_word <= "000"; end if;                   -- Section type 6
                     when "110"  => sec_word <= "110";                                                                  -- Section type 0
                     when "111"  => if (ECPRI_RX_C_DATA(31) = '0') then                                                 -- Section extension type 10
                                       if (num_section = section_cnt) then sec_word <= "000";
                                       else sec_word <= "011";
                                       end if;
                                       end_section <= '1';
                                    else end_section <= '0';
                                    end if;

                     when others => sec_word <= "000"; end_section <= '0';
                  end case;
              end if;
           else
              sec_word <= sec_word; end_section <= '0';
           end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (sec_word = "000") then
              ch_idx              <= ECPRI_RX_C_CH_IDX;
              data_direction      <= ECPRI_RX_C_DATA(31);
              filter_index        <= ECPRI_RX_C_DATA(27 downto 24);
              frame_id            <= ECPRI_RX_C_DATA(23 downto 16);
              subframe_id         <= ECPRI_RX_C_DATA(15 downto 12);
              slot_id             <= ECPRI_RX_C_DATA(11 downto 6);
              start_symbol_id_pre <= ECPRI_RX_C_DATA(5 downto 0);
           end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (oran_rx_c_valid = '1') then
              if (sec_word = "001") then
                 num_section   <= ECPRI_RX_C_DATA(31 downto 24);
                 section_type  <= ECPRI_RX_C_DATA(23 downto 16);
                 if (ECPRI_RX_C_DATA(17) = ECPRI_RX_C_DATA(16)) then -- Section type 0, 3
                    time_offset <= ECPRI_RX_C_DATA(15 downto 0);
                    blankingpatternid <= (others => '0');
                 else -- Section type 1
                    time_offset <= (others => '0');
                    blankingpatternid <= ECPRI_RX_C_DATA(7 downto 0);
                 end if;

                 if (ECPRI_RX_C_DATA(18 downto 17) = "11") then      -- Section type 6
                    numberOfUEs <= ECPRI_RX_C_DATA(15 downto 8);
                 else
                    numberOfUEs <= (others => '0');
                 end if;
              end if;
           else
              numberOfUEs <= (others => '0');
           end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (oran_rx_c_valid = '1') then
              if (sec_word = "010") then
                 frame_structure <= ECPRI_RX_C_DATA(31 downto 24);
                 cpLength        <= ECPRI_RX_C_DATA(23 downto 8);
              end if;
           end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (oran_rx_c_valid = '1') then
              if (sec_word = "011") then
                 section_id  <= ECPRI_RX_C_DATA(31 downto 20);
                 rb          <= ECPRI_RX_C_DATA(19);
                 symInc      <= ECPRI_RX_C_DATA(18);              -- not required in this project
                 start_prbc  <= ECPRI_RX_C_DATA(17 downto 8);
                 num_prbc    <= ECPRI_RX_C_DATA(7 downto 0);
                 section_cnt <= section_cnt + '1';
              elsif (ECPRI_RX_C_LAST = '1') then                  -- can be removed if eCPRI_HDR = TRUE
                 section_cnt <= (others => '0');
              end if;
           else
              section_cnt <= (others => '0');
           end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (oran_rx_c_valid = '1') then
              if (sec_word = "100") then
                 re_mask    <= ECPRI_RX_C_DATA(31 downto 20);
                 num_symbol <= ECPRI_RX_C_DATA(19 downto 16);
                 ef         <= ECPRI_RX_C_DATA(15);
                 beamId     <= ECPRI_RX_C_DATA(14 downto 0);
                 if (symInc = '1') then
                    numInc <= numInc + num_symbol;
                 else
                    numInc <= (others => '0');
                 end if;
              end if;
           else
              numInc <= (others => '0');
           end if;
        end if;
    end process;

    start_symbol_id <= start_symbol_id_pre + ("00" & numInc);

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (sec_word = "101") then
              freq_offset <= ECPRI_RX_C_DATA(31 downto 8);
           end if;
        end if;
    end process;

    -- Section Extension = 10 for beamGroupType = 00b or 01b
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (sec_word = "111") then
              if (ECPRI_RX_C_DATA(30 downto 24) = 10) then
                 for i in 2 downto 0 loop
                    if (ECPRI_RX_C_DATA(13 downto 8) > i) then
                       if (ECPRI_RX_C_DATA(15 downto 14) = "01") then
                          beamId_group((i+1)*15-1 downto i*15) <= beamId + (i+1);
                       else
                          beamId_group((i+1)*15-1 downto i*15) <= beamId;
                       end if;
                    else
                       beamId_group((i+1)*15-1 downto i*15) <= (others => '0');
                    end if;
                 end loop;
                 numPortc <= ECPRI_RX_C_DATA(13 downto 8);
              end if;
           else
              beamId_group <= (others => '0');
              numPortc <= (others => '0');
           end if;
        end if;
    end process;

    CP_UPDATE                    <= (end_section and cp_msg_valid and not(is_type0));
    CP_CH_IDX                    <= ch_idx;
    CP_PARAMETER(191 downto 160) <= freq_offset & x"00";
    CP_PARAMETER(159 downto 128) <= re_mask & num_symbol & ef & beamId;
    CP_PARAMETER(127 downto  96) <= section_id & rb & symInc & start_prbc & num_prbc;
    CP_PARAMETER( 95 downto  64) <= frame_structure & cpLength & x"00";
    CP_PARAMETER( 63 downto  32) <= num_section & section_type & time_offset;
    CP_PARAMETER( 31 downto   0) <= data_direction & "000" & filter_index & frame_id & subframe_id & slot_id & start_symbol_id;

    -- Section Extension = 10 for beamGroupType = 00b or 01b
    CP_PARAMETER(192+(15*3)-1 downto 192) <= beamId_group;
    CP_PARAMETER(192+(15*3)+5 downto 192+(15*3)) <= numPortc;

    CP_BLANKINGPATTERNID <= blankingpatternid;

    CP_PARAMETER(192+(15*3)+21 downto 192+(15*3)+6) <= eAxC_ID;

end BEHAVE;