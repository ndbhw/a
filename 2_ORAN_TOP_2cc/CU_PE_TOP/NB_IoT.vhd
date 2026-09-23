
--================================================================================
-- Filename     : NB_IoT.vhd
-- Author       : Taeyoup Kim (taeyoup.kim@samsung.com)
-- Description  : O-RAN UL C-Plane Parameter Parsing for NB_IoT
----------------------------------------------------------------------------------
--     Date    |     By           |  Version | Description
----------------------------------------------------------------------------------
--  10-27-2021 | Taeyoup Kim      |    1.0   | Original Version
--================================================================================
-- Copyright (c) 2021 SAMSUNG. All rights reserved.
--================================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;


    entity NB_IoT is
    generic (
    PATH_NUM                       : natural := 4
    );
    port (

    CLK                            : in std_logic;

    --------------------------------------------------------------------------------
    -- CP_PARSER
    --------------------------------------------------------------------------------

    IS_NPRACH                      : in std_logic;
    CC_ENABLE                      : in std_logic;
    SECTOR_EN                      : in std_logic_vector(PATH_NUM*1-1 downto 0);
    CP_UPDATE                      : in std_logic;
    DATA_DIRECTION                 : in std_logic;
    FILTER_INDEX                   : in std_logic_vector(  3 downto 0);
    SUBFRAME_ID                    : in std_logic_vector(  3 downto 0);
    SLOT_ID                        : in std_logic_vector(  5 downto 0);
    START_SYMBOL_ID                : in std_logic_vector(  5 downto 0);
    SECTION_TYPE                   : in std_logic_vector(  7 downto 0);
    TIME_OFFSET                    : in std_logic_vector( 15 downto 0);
    FRAME_STRUCTURE                : in std_logic_vector(  7 downto 0);
    CPLENGTH                       : in std_logic_vector( 15 downto 0);
    FREQ_OFFSET                    : in std_logic_vector( 23 downto 0);
    START_PRBC                     : in std_logic_vector(  9 downto 0);
    NUM_PRBC                       : in std_logic_vector(  7 downto 0);
    NUM_SYMBOL                     : in std_logic_vector(  3 downto 0);

    --------------------------------------------------------------------------------
    -- UL Sync Retard
    --------------------------------------------------------------------------------

    UL_RTD_15kHz_SBF_SYNC          : in std_logic;
    UL_RTD_15kHz_SBF_IDX           : in std_logic_vector(  3 downto 0); -- 0~9
    UL_RTD_15kHz_SLOT_SYNC         : in std_logic;
    UL_RTD_15kHz_SLOT_IDX          : in std_logic_vector(  7 downto 0); -- SCS 15kHz : 0 ~ 9 (per Frame)
    UL_RTD_15kHz_SYMBOL_SYNC       : in std_logic;
    UL_RTD_15kHz_SYMBOL_IDX        : in std_logic_vector(  3 downto 0); -- 0~13

    UL_RTD_3_75kHz_SBF_SYNC        : in std_logic;
    UL_RTD_3_75kHz_SBF_IDX         : in std_logic_vector(  3 downto 0); -- 0~9
    UL_RTD_3_75kHz_SLOT_SYNC       : in std_logic;
    UL_RTD_3_75kHz_SLOT_IDX        : in std_logic_vector(  7 downto 0); -- SCS 3.75kHz
    UL_RTD_3_75kHz_SYMBOL_SYNC     : in std_logic;
    UL_RTD_3_75kHz_SYMBOL_IDX      : in std_logic_vector(  3 downto 0); -- 0~13

    --------------------------------------------------------------------------------
    -- RAFE
    --------------------------------------------------------------------------------

    UL_FILTER_INDEX                : out std_logic_vector(PATH_NUM*4-1 downto 0);
    UL_TIME_OFFSET                 : out std_logic_vector(PATH_NUM*16-1 downto 0);
    UL_FRAME_STRUCTURE             : out std_logic_vector(PATH_NUM*8-1 downto 0);
    UL_CPLENGTH                    : out std_logic_vector(PATH_NUM*16-1 downto 0);
    UL_FREQ_OFFSET                 : out std_logic_vector(PATH_NUM*24-1 downto 0);
    UL_START_PRBC                  : out std_logic_vector(PATH_NUM*10-1 downto 0);
    UL_NUM_PRBC                    : out std_logic_vector(PATH_NUM*8-1 downto 0);
    UL_NUM_PSYMBOL                 : out std_logic_vector(PATH_NUM*4-1 downto 0);
    UL_NUM_RO                      : out std_logic_vector(PATH_NUM*3-1 downto 0)
    );
    end NB_IoT;

architecture BEHAVE of NB_IoT is

    type std_logic_array_sector is array(natural range <>) of std_logic_vector(PATH_NUM*1-1 downto 0);
    type std_logic_array17 is array(natural range <>) of std_logic_vector(16 downto 0);

    signal NB_IoT_c_plane         : std_logic := '0';
    signal nb_sym_en              : std_logic := '0';
    signal nb_sym_sync            : std_logic := '0';
    signal nb_sector_en           : std_logic_vector(PATH_NUM*1-1 downto 0) := (others => '0');
    signal nb_sector_en_slot0     : std_logic_array_sector(13 downto 0) := (others => (others => '0'));
    signal nb_sector_en_slot1     : std_logic_array_sector(13 downto 0) := (others => (others => '0'));

    signal nb_subframe_id         : std_logic_vector(  3 downto 0) := (others => '0');
    signal nb_slot_id             : std_logic_vector(  5 downto 0) := (others => '0');
    signal nb_symbol_id           : std_logic_vector(  5 downto 0) := (others => '0');
    signal nb_filter_index        : std_logic_vector(  3 downto 0) := (others => '0');

    signal npusch_15kHz           : std_logic := '0';
    signal nb_time_offset         : std_logic_vector( 15 downto 0) := (others => '0');
    signal nb_time_offset_slot0   : std_logic_array17(13 downto 0) := (others => (others => '0'));
    signal nb_time_offset_slot1   : std_logic_array17(13 downto 0) := (others => (others => '0'));

    signal nb_sym_sector_en       : std_logic_vector(PATH_NUM*1-1 downto 0) := (others => '0');
    signal nb_sym_filter_index    : std_logic_vector(  3 downto 0) := (others => '0');
    signal nb_sym_frame_structure : std_logic_vector(  7 downto 0) := (others => '0');
    signal nb_sym_freq_offset     : std_logic_vector( 23 downto 0) := (others => '0');
    signal nb_sym_start_prbc      : std_logic_vector(  9 downto 0) := (others => '0');
    signal nb_sym_num_prbc        : std_logic_vector(  7 downto 0) := (others => '0');
    signal nb_sym_num_symbol      : std_logic_vector(  3 downto 0) := (others => '0');
    signal nb_sym_cplength        : std_logic_vector( 15 downto 0) := (others => '0');
    signal nb_sym_time_offset     : std_logic_vector( 16 downto 0) := (others => '0');

    signal ul_rtd_sbf_sync        : std_logic := '0';
    signal ul_rtd_sbf_idx         : std_logic_vector(  3 downto 0) := (others => '0');
    signal ul_rtd_symbol_sync     : std_logic := '0';
    signal ul_rtd_symbol_idx      : std_logic_vector(  3 downto 0) := (others => '0');


begin


--===============================================================================================================
--  NB_IoT
--===============================================================================================================


    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           nb_sector_en       <= SECTOR_EN;
           nb_subframe_id     <= SUBFRAME_ID;
           nb_slot_id         <= SLOT_ID;
           nb_symbol_id       <= START_SYMBOL_ID;
           nb_filter_index    <= FILTER_INDEX;
           nb_time_offset     <= TIME_OFFSET;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (CC_ENABLE = '1') then
              nb_sym_filter_index    <= nb_filter_index;
              nb_sym_frame_structure <= FRAME_STRUCTURE;
              nb_sym_freq_offset     <= FREQ_OFFSET;
              nb_sym_start_prbc      <= START_PRBC;
              nb_sym_num_prbc        <= NUM_PRBC;
              nb_sym_num_symbol      <= NUM_SYMBOL;
           end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (CC_ENABLE = '1') then
              if (FRAME_STRUCTURE(3 downto 0) = x"0") then
                 npusch_15kHz <= '1';
              else
                 npusch_15kHz <= '0';
              end if;
           end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--           if (npusch_15kHz = '1') then
              ul_rtd_sbf_sync    <= UL_RTD_15kHz_SBF_SYNC;
              ul_rtd_sbf_idx     <= UL_RTD_15kHz_SBF_IDX;
              ul_rtd_symbol_sync <= UL_RTD_15kHz_SYMBOL_SYNC;
              ul_rtd_symbol_idx  <= UL_RTD_15kHz_SYMBOL_IDX;
--           else
--              ul_rtd_sbf_sync    <= UL_RTD_3_75kHz_SBF_SYNC;
--              ul_rtd_sbf_idx     <= UL_RTD_3_75kHz_SBF_IDX;
--              ul_rtd_symbol_sync <= UL_RTD_3_75kHz_SYMBOL_SYNC;
--              ul_rtd_symbol_idx  <= UL_RTD_3_75kHz_SYMBOL_IDX;
--           end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (IS_NPRACH = '1') then
              nb_sym_cplength <= (others => '0'); -- NPRACH
           else
              if (npusch_15kHz = '1') then
                 if (ul_rtd_symbol_idx = 0 or ul_rtd_symbol_idx = 7) then
                    nb_sym_cplength <= x"00A0"; -- NPUSCH 15kHz LCP
                 else
                    nb_sym_cplength <= x"0090"; -- NPUSCH 15kHz NCP
                 end if;
              else
                 nb_sym_cplength <= x"0100"; -- NPUSCH 3.75kHz
              end if;
           end if;
        end if;
    end process;

    u_NB_IoT_TIME_OFFSET : for i in 13 downto 0 generate

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (ul_rtd_sbf_sync = '1' and ul_rtd_sbf_idx(0) = '1') then
              nb_sector_en_slot0(i) <= (others => '0');
              nb_time_offset_slot0(i) <= (others => '0');
           elsif (CC_ENABLE = '1') then
              if (nb_subframe_id(0) = '0' and nb_symbol_id(3 downto 0) = i) then
                 nb_sector_en_slot0(i) <= nb_sector_en_slot0(i) or nb_sector_en;
                 nb_time_offset_slot0(i) <= '1' & nb_time_offset;
              end if;
           end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (ul_rtd_sbf_sync = '1' and ul_rtd_sbf_idx(0) = '0') then
              nb_sector_en_slot1(i) <= (others => '0');
              nb_time_offset_slot1(i) <= (others => '0');
           elsif (CC_ENABLE = '1') then
              if (nb_subframe_id(0) = '1' and nb_symbol_id(3 downto 0) = i) then
                 nb_sector_en_slot1(i) <= nb_sector_en_slot1(i) or nb_sector_en;
                 nb_time_offset_slot1(i) <= '1' & nb_time_offset;
              end if;
           end if;
        end if;
    end process;

    end generate;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           case (ul_rtd_symbol_idx) is
               when x"0" => if (ul_rtd_sbf_idx(0) = '0') then nb_sym_sector_en <= nb_sector_en_slot0(0);  nb_sym_time_offset <= nb_time_offset_slot0(0);  else nb_sym_sector_en <= nb_sector_en_slot1(0);  nb_sym_time_offset <= nb_time_offset_slot1(0);  end if;
               when x"1" => if (ul_rtd_sbf_idx(0) = '0') then nb_sym_sector_en <= nb_sector_en_slot0(1);  nb_sym_time_offset <= nb_time_offset_slot0(1);  else nb_sym_sector_en <= nb_sector_en_slot1(1);  nb_sym_time_offset <= nb_time_offset_slot1(1);  end if;
               when x"2" => if (ul_rtd_sbf_idx(0) = '0') then nb_sym_sector_en <= nb_sector_en_slot0(2);  nb_sym_time_offset <= nb_time_offset_slot0(2);  else nb_sym_sector_en <= nb_sector_en_slot1(2);  nb_sym_time_offset <= nb_time_offset_slot1(2);  end if;
               when x"3" => if (ul_rtd_sbf_idx(0) = '0') then nb_sym_sector_en <= nb_sector_en_slot0(3);  nb_sym_time_offset <= nb_time_offset_slot0(3);  else nb_sym_sector_en <= nb_sector_en_slot1(3);  nb_sym_time_offset <= nb_time_offset_slot1(3);  end if;
               when x"4" => if (ul_rtd_sbf_idx(0) = '0') then nb_sym_sector_en <= nb_sector_en_slot0(4);  nb_sym_time_offset <= nb_time_offset_slot0(4);  else nb_sym_sector_en <= nb_sector_en_slot1(4);  nb_sym_time_offset <= nb_time_offset_slot1(4);  end if;
               when x"5" => if (ul_rtd_sbf_idx(0) = '0') then nb_sym_sector_en <= nb_sector_en_slot0(5);  nb_sym_time_offset <= nb_time_offset_slot0(5);  else nb_sym_sector_en <= nb_sector_en_slot1(5);  nb_sym_time_offset <= nb_time_offset_slot1(5);  end if;
               when x"6" => if (ul_rtd_sbf_idx(0) = '0') then nb_sym_sector_en <= nb_sector_en_slot0(6);  nb_sym_time_offset <= nb_time_offset_slot0(6);  else nb_sym_sector_en <= nb_sector_en_slot1(6);  nb_sym_time_offset <= nb_time_offset_slot1(6);  end if;
               when x"7" => if (ul_rtd_sbf_idx(0) = '0') then nb_sym_sector_en <= nb_sector_en_slot0(7);  nb_sym_time_offset <= nb_time_offset_slot0(7);  else nb_sym_sector_en <= nb_sector_en_slot1(7);  nb_sym_time_offset <= nb_time_offset_slot1(7);  end if;
               when x"8" => if (ul_rtd_sbf_idx(0) = '0') then nb_sym_sector_en <= nb_sector_en_slot0(8);  nb_sym_time_offset <= nb_time_offset_slot0(8);  else nb_sym_sector_en <= nb_sector_en_slot1(8);  nb_sym_time_offset <= nb_time_offset_slot1(8);  end if;
               when x"9" => if (ul_rtd_sbf_idx(0) = '0') then nb_sym_sector_en <= nb_sector_en_slot0(9);  nb_sym_time_offset <= nb_time_offset_slot0(9);  else nb_sym_sector_en <= nb_sector_en_slot1(9);  nb_sym_time_offset <= nb_time_offset_slot1(9);  end if;
               when x"A" => if (ul_rtd_sbf_idx(0) = '0') then nb_sym_sector_en <= nb_sector_en_slot0(10); nb_sym_time_offset <= nb_time_offset_slot0(10); else nb_sym_sector_en <= nb_sector_en_slot1(10); nb_sym_time_offset <= nb_time_offset_slot1(10); end if;
               when x"B" => if (ul_rtd_sbf_idx(0) = '0') then nb_sym_sector_en <= nb_sector_en_slot0(11); nb_sym_time_offset <= nb_time_offset_slot0(11); else nb_sym_sector_en <= nb_sector_en_slot1(11); nb_sym_time_offset <= nb_time_offset_slot1(11); end if;
               when x"C" => if (ul_rtd_sbf_idx(0) = '0') then nb_sym_sector_en <= nb_sector_en_slot0(12); nb_sym_time_offset <= nb_time_offset_slot0(12); else nb_sym_sector_en <= nb_sector_en_slot1(12); nb_sym_time_offset <= nb_time_offset_slot1(12); end if;
               when x"D" => if (ul_rtd_sbf_idx(0) = '0') then nb_sym_sector_en <= nb_sector_en_slot0(13); nb_sym_time_offset <= nb_time_offset_slot0(13); else nb_sym_sector_en <= nb_sector_en_slot1(13); nb_sym_time_offset <= nb_time_offset_slot1(13); end if;
               when others => nb_sym_sector_en <= (others => '0'); nb_sym_time_offset <= (others => '0');
           end case;
           nb_sym_sync <= ul_rtd_symbol_sync;
        end if;
    end process;

    nb_sym_en <= nb_sym_time_offset(16);

    u_NB_IoT_Port_Mapping : for i in PATH_NUM - 1 downto 0 generate

    UL_FRAME_STRUCTURE(8*(i+1)-1 downto 8*i) <= nb_sym_frame_structure;
    UL_START_PRBC(10*(i+1)-1 downto 10*i)    <= nb_sym_start_prbc;
    UL_NUM_PRBC(8*(i+1)-1 downto 8*i)        <= nb_sym_num_prbc;
    UL_NUM_PSYMBOL(4*(i+1)-1 downto 4*i)     <= nb_sym_num_symbol;
    UL_FREQ_OFFSET(24*(i+1)-1 downto 24*i)   <= nb_sym_freq_offset;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (nb_sym_sync = '1') then
              if (nb_sym_en = '1' and nb_sym_sector_en(i) = '1') then
                 UL_FILTER_INDEX(4*(i+1)-1 downto 4*i)    <= nb_sym_filter_index;
              else
                 UL_FILTER_INDEX(4*(i+1)-1 downto 4*i)    <= (others => '0');
              end if;
              UL_TIME_OFFSET(16*(i+1)-1 downto 16*i) <= nb_sym_time_offset(15 downto 0);
              UL_CPLENGTH(16*(i+1)-1 downto 16*i)    <= nb_sym_cplength;
           end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (nb_sym_sync = '1' and nb_sym_sector_en(i) = '1') then
              UL_NUM_RO(3*(i+1)-1 downto 3*i) <= "00" & nb_sym_en;
           else
              UL_NUM_RO(3*(i+1)-1 downto 3*i) <= (others => '0');
           end if;
        end if;
    end process;

    end generate;

end BEHAVE;


