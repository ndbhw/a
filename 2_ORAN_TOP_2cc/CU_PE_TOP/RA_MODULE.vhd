
--================================================================================
-- Filename     : RA_MODULE.vhd
-- Author       : Taeyoup Kim (taeyoup.kim@samsung.com)
-- Description  : O-RAN UL C-Plane Parameter Parsing for PRACH
----------------------------------------------------------------------------------
--     Date    |     By           |  Version | Description
----------------------------------------------------------------------------------
--  11-28-2021 | Taeyoup Kim      |    1.0   | Original Version
--================================================================================
-- Copyright (c) 2021 SAMSUNG. All rights reserved.
--================================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

    entity RA_MODULE is
    generic (
    PATH_NUM                       : natural := 1
    );
    port (

    CLK                            : in std_logic;

    --------------------------------------------------------------------------------
    -- CP_PARSER
    --------------------------------------------------------------------------------

    MODULE_EN                      : in std_logic;
    CP_UPDATE                      : in std_logic;
    CP_CH_IDX                      : in std_logic_vector(  3 downto 0);
    NUM_PORTC                      : in std_logic_vector(  5 downto 0);
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

    UL_RTD_SBF_SYNC                : in std_logic;
    UL_RTD_SBF_IDX                 : in std_logic_vector(  3 downto 0); -- 0~9
    UL_RTD_SLOT_SYNC               : in std_logic;
    UL_RTD_SLOT_IDX                : in std_logic_vector(  7 downto 0); -- SCS 15kHz : 0 ~ 9 (per Frame)
    UL_RTD_SYMBOL_SYNC             : in std_logic;
    UL_RTD_SYMBOL_IDX              : in std_logic_vector(  3 downto 0); -- 0~13

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
    end RA_MODULE;

architecture BEHAVE of RA_MODULE is

    type std_logic_array3  is array(natural range <>) of std_logic_vector( 2 downto 0);
    type std_logic_array4  is array(natural range <>) of std_logic_vector( 3 downto 0);
    type std_logic_array6  is array(natural range <>) of std_logic_vector( 5 downto 0);
    type std_logic_array8  is array(natural range <>) of std_logic_vector( 7 downto 0);
    type std_logic_array10 is array(natural range <>) of std_logic_vector( 9 downto 0);
    type std_logic_array16 is array(natural range <>) of std_logic_vector(15 downto 0);
    type std_logic_array24 is array(natural range <>) of std_logic_vector(23 downto 0);

    signal ul_rtd_symbol_sync_d    : std_logic_vector(  1 downto 0) := (others => '0');
    signal r0_enable               : std_logic_vector(  3 downto 0) := (others => '0');
    signal r1_enable               : std_logic_vector(  3 downto 0) := (others => '0');
    signal cp_rach_frame_index     : std_logic_vector(  5 downto 0) := (others => '0');
    signal rach_r0_frame_index     : std_logic_array6(  3 downto 0) := (others => (others => '0'));
    signal rach_r0_filter_index    : std_logic_array4(  3 downto 0) := (others => (others => '0'));
    signal rach_r0_time_offset     : std_logic_array16( 3 downto 0) := (others => (others => '0'));
    signal rach_r0_frame_structure : std_logic_array8(  3 downto 0) := (others => (others => '0'));
    signal rach_r0_cpLength        : std_logic_array16( 3 downto 0) := (others => (others => '0'));
    signal rach_r0_freq_offset     : std_logic_array24( 3 downto 0) := (others => (others => '0'));
    signal rach_r0_start_prbc      : std_logic_array10( 3 downto 0) := (others => (others => '0'));
    signal rach_r0_num_prbc        : std_logic_array8(  3 downto 0) := (others => (others => '0'));
    signal rach_r0_num_psymbol     : std_logic_array4(  3 downto 0) := (others => (others => '0'));
    signal rach_r0_num_ro          : std_logic_array3(  3 downto 0) := (others => (others => '0'));
    signal rach_r1_frame_index     : std_logic_array6(  3 downto 0) := (others => (others => '0'));
    signal rach_r1_filter_index    : std_logic_array4(  3 downto 0) := (others => (others => '0'));
    signal rach_r1_time_offset     : std_logic_array16( 3 downto 0) := (others => (others => '0'));
    signal rach_r1_frame_structure : std_logic_array8(  3 downto 0) := (others => (others => '0'));
    signal rach_r1_cpLength        : std_logic_array16( 3 downto 0) := (others => (others => '0'));
    signal rach_r1_freq_offset     : std_logic_array24( 3 downto 0) := (others => (others => '0'));
    signal rach_r1_start_prbc      : std_logic_array10( 3 downto 0) := (others => (others => '0'));
    signal rach_r1_num_prbc        : std_logic_array8(  3 downto 0) := (others => (others => '0'));
    signal rach_r1_num_psymbol     : std_logic_array4(  3 downto 0) := (others => (others => '0'));
    signal rach_r1_num_ro          : std_logic_array3(  3 downto 0) := (others => (others => '0'));

    signal band_filter_index       : std_logic_vector(  3 downto 0) := (others => '0');


begin


--===============================================================================================================
--  RA_MODULE
--===============================================================================================================

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           cp_rach_frame_index <= SUBFRAME_ID(0) & SLOT_ID(0) & START_SYMBOL_ID(3 downto 0);
           band_filter_index <= FILTER_INDEX;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (MODULE_EN = '1') then
              rach_r0_frame_structure(0) <= FRAME_STRUCTURE;
              rach_r0_start_prbc(0)      <= START_PRBC;
              rach_r0_num_prbc(0)        <= NUM_PRBC;
              rach_r0_num_psymbol(0)     <= NUM_SYMBOL;
              rach_r0_freq_offset(0)     <= FREQ_OFFSET;
           end if;
        end if;
    end process;

-----------------------------------------------------------------------------------------------------------------
--  RO#0
-----------------------------------------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (MODULE_EN = '1') then
              if (rach_r0_frame_index(0)(3 downto 0) = x"F") then
                 rach_r0_frame_index(0)     <= cp_rach_frame_index;  -- should be changed according to SCS
                 rach_r0_filter_index(0)    <= band_filter_index;
                 rach_r0_time_offset(0)     <= TIME_OFFSET;
                 rach_r0_cpLength(0)        <= CPLENGTH;
                 rach_r0_num_ro(0)          <= "001";
              end if;
           else
              if (r0_enable(0) = '1' and ul_rtd_symbol_sync_d(0) = '1') then
                 rach_r0_frame_index(0)     <= (others => '1');
                 rach_r0_filter_index(0)    <= (others => '0');
                 rach_r0_num_ro(0)          <= (others => '0');
              end if;
           end if;
        end if;
    end process;

-----------------------------------------------------------------------------------------------------------------
--  RO#1
-----------------------------------------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (MODULE_EN = '1') then
              if (rach_r0_frame_index(0) /= cp_rach_frame_index and rach_r0_num_ro(0)(0) = '1' and rach_r1_num_ro(0)(0) = '0') then
                 rach_r1_frame_index(0)     <= cp_rach_frame_index;  -- should be changed according to SCS
                 rach_r1_filter_index(0)    <= band_filter_index;
                 rach_r1_time_offset(0)     <= TIME_OFFSET;
                 rach_r1_cpLength(0)        <= CPLENGTH;
                 rach_r1_num_ro(0)          <= "001";
              end if;
           else
              if (r1_enable(0) = '1' and ul_rtd_symbol_sync_d(0) = '1') then
                 rach_r1_frame_index(0)     <= (others => '1');
                 rach_r1_filter_index(0)    <= (others => '0');
                 rach_r1_num_ro(0)          <= (others => '0');
              end if;
           end if;
        end if;
    end process;

-----------------------------------------------------------------------------------------------------------------
--  RO Enable
-----------------------------------------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           ul_rtd_symbol_sync_d(0) <= UL_RTD_SYMBOL_SYNC;
        end if;
    end process;

    RO_ENABLE : for i in 0 downto 0 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (rach_r0_frame_index(i)(3 downto 0) = UL_RTD_SYMBOL_IDX(3 downto 0)) then
              r0_enable(i) <= '1';
           else
              r0_enable(i) <= '0';
           end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (rach_r1_frame_index(i)(3 downto 0) = UL_RTD_SYMBOL_IDX(3 downto 0)) then
              r1_enable(i) <= '1';
           else
              r1_enable(i) <= '0';
           end if;
        end if;
    end process;

    end generate;

-----------------------------------------------------------------------------------------------------------------
--  Output Port Mapping
-----------------------------------------------------------------------------------------------------------------

    PRACH_Port_Mapping : for i in PATH_NUM - 1 downto 0 generate

    UL_FRAME_STRUCTURE(8*(i+1)-1 downto 8*i) <= rach_r0_frame_structure(0);
    UL_START_PRBC(10*(i+1)-1 downto 10*i)    <= rach_r0_start_prbc(0);
    UL_NUM_PRBC(8*(i+1)-1 downto 8*i)        <= rach_r0_num_prbc(0);
    UL_NUM_PSYMBOL(4*(i+1)-1 downto 4*i)     <= rach_r0_num_psymbol(0);
    UL_FREQ_OFFSET(24*(i+1)-1 downto 24*i)   <= rach_r0_freq_offset(0);

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (ul_rtd_symbol_sync_d(0) = '1') then
              if (r0_enable(i) = '1') then
                 UL_FILTER_INDEX(4*(i+1)-1 downto 4*i)    <= rach_r0_filter_index(i);
                 UL_TIME_OFFSET(16*(i+1)-1 downto 16*i)   <= rach_r0_time_offset(i);
                 UL_CPLENGTH(16*(i+1)-1 downto 16*i)      <= rach_r0_cpLength(i);
                 UL_NUM_RO(3*(i+1)-1 downto 3*i)          <= rach_r0_num_ro(i);
              elsif (r1_enable(i) = '1') then
                 UL_FILTER_INDEX(4*(i+1)-1 downto 4*i)    <= rach_r1_filter_index(i);
                 UL_TIME_OFFSET(16*(i+1)-1 downto 16*i)   <= rach_r1_time_offset(i);
                 UL_CPLENGTH(16*(i+1)-1 downto 16*i)      <= rach_r1_cpLength(i);
                 UL_NUM_RO(3*(i+1)-1 downto 3*i)          <= rach_r1_num_ro(i);
              else
                 UL_FILTER_INDEX(4*(i+1)-1 downto 4*i)    <= (others => '0');
                 UL_TIME_OFFSET(16*(i+1)-1 downto 16*i)   <= (others => '0');
                 UL_CPLENGTH(16*(i+1)-1 downto 16*i)      <= (others => '0');
                 UL_NUM_RO(3*(i+1)-1 downto 3*i)          <= (others => '0');
              end if;
           end if;
        end if;
    end process;

    end generate;

end BEHAVE;