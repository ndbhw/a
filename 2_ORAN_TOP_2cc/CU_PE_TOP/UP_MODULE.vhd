--================================================================================
-- Filename     : UP_MODULE.vhd
-- Author       : Taeyoup Kim (taeyoup.kim@samsung.com)
-- Description  : O-RAN U-Plane (DL) IQ Data Alignment and Rx window management
----------------------------------------------------------------------------------
--     Date    |     By           |  Version | Description
----------------------------------------------------------------------------------
--  08-07-2020 | Taeyoup Kim      |    1.0   | Original Version
--================================================================================
-- Copyright (c) 2020 SAMSUNG. All rights reserved.
--================================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;


    entity UP_MODULE is
    generic (
    VENDOR                         : string  := "XILINX";
    iFFT_k0_SHIFT                  : boolean :=     TRUE;
    iFFT_ZERO_PADDING              : boolean :=    FALSE;
    SCS                            : natural :=       30;
    iFFT_WIDTH                     : natural :=       12;
    SYMBOL_NUM                     : natural :=        7;
    CH_NUM                         : natural :=        2  -- Layer/Path @ module
    );
    port (
    CLK                            : in  std_logic;
    BW_iFFT_WIDTH                  : in natural range 0 to 12;
    RE_SIZE                        : in natural range 0 to 3276;

    --------------------------------------------------------------------------------
    -- DL Sync Advance
    --------------------------------------------------------------------------------
    DL_ADV_SBF_SYNC                : in  std_logic;
    DL_ADV_SBF_IDX                 : in std_logic_vector( 3 downto 0); -- 0~9
    DL_ADV_SLOT_SYNC               : in  std_logic;
    DL_ADV_SLOT_IDX                : in  std_logic_vector(7 downto 0); -- SCS 15kHz : 0 ~ 9 (per Frame)
    DL_ADV_SYMBOL_SYNC             : in  std_logic;
    DL_ADV_SYMBOL_CH_SYNC          : in  std_logic;
    DL_ADV_SYMBOL_IDX              : in  std_logic_vector(3 downto 0); -- 0~13

    --------------------------------------------------------------------------------
    -- ORAN_TOP
    --------------------------------------------------------------------------------
    RB_CH_IDX                      : in  std_logic_vector(3 downto 0);
    RB_FRAME_ID                    : in  std_logic_vector(7 downto 0);
    RB_SUBFRAME_ID                 : in  std_logic_vector(3 downto 0);
    RB_SLOT_ID                     : in  std_logic_vector(5 downto 0);
    RB_SYMBOL_ID                   : in  std_logic_vector(5 downto 0);
    RB_SECTION_ID                  : in  std_logic_vector(11 downto 0);
    RE_NUMBER                      : in  std_logic_vector(11 downto 0);
    RB_VALID                       : in  std_logic;
    RB_START                       : in  std_logic;
    RB_LAST                        : in  std_logic;
    RB_TICK                        : in  std_logic;
    RB_DATA_I                      : in  std_logic_vector(15 downto 0);
    RB_DATA_Q                      : in  std_logic_vector(15 downto 0);

    --------------------------------------------------------------------------------
    -- DLFE
    --------------------------------------------------------------------------------
    SYSTEM_MODE                    : in  std_logic;                    -- 0: LTE, 1: NR
    K0                             : in  std_logic_vector(11 downto 0);
    DL_DATA                        : out std_logic_vector(CH_NUM*32 - 1 downto 0)
    );
    end UP_MODULE;

architecture BEHAVE of UP_MODULE is

    component ADDR_TAILOR is
    generic (
    SCS                            : natural := 30;
    ADDR_WIDTH                     : natural :=  3
    );
    port (
    SUBFRAME_ID                    : in  std_logic_vector(3 downto 0);
    SLOT_ID                        : in  std_logic_vector(5 downto 0);
    SYMBOL_ID                      : in  std_logic_vector(5 downto 0);
    ADDR                           : out std_logic_vector(ADDR_WIDTH - 1 downto 0)
    );
    end component;

    component UP_MEMORY is
    generic
    (
    VENDOR                         : string  := "XILINX";
    ADDR_WIDTH                     : natural := 13;
    DATA_WIDTH                     : natural := 72
    );
    port
    (
    CLK                            : in  std_logic;
    ENA                            : in  std_logic;
    ENB                            : in  std_logic;
    WEB                            : in  std_logic;
    ADDRA                          : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    ADDRB                          : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    DINA                           : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    DOUTB                          : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
    end component;


    constant CH_NUM_WIDTH          : positive  := positive(ceil(log2(real(CH_NUM))));
    constant SYMBOL_NUM_WIDTH      : positive  := positive(ceil(log2(real(SYMBOL_NUM))));
    signal i_ch_idx                : std_logic_vector(CH_NUM_WIDTH - 1 downto 0) := (others => '0');
    signal i_rd_ch_idx             : std_logic_vector(CH_NUM_WIDTH - 1 downto 0) := (others => '0');
    signal i_section_id            : std_logic_vector( 7 downto 0) := (others => '0');  -- 256 sections support
    signal i_frame_id              : std_logic_vector( 7 downto 0) := (others => '0');
    signal i_subframe_id           : std_logic_vector( 3 downto 0) := (others => '0');
    signal i_slot_id               : std_logic_vector( 5 downto 0) := (others => '0');
    signal i_wr_addr_sym           : std_logic_vector(SYMBOL_NUM_WIDTH - 1 downto 0) := (others => '0');
    signal i_rd_addr_sym           : std_logic_vector(SYMBOL_NUM_WIDTH - 1 downto 0) := (others => '0');
    signal i_addr_sym              : std_logic_vector(SYMBOL_NUM_WIDTH - 1 downto 0) := (others => '0');
    signal i_addr_re               : std_logic_vector(iFFT_WIDTH - 1 downto 0) := (others => '0');
    signal i_addra                 : std_logic_vector((iFFT_WIDTH - 1) + SYMBOL_NUM_WIDTH + CH_NUM_WIDTH - 1 downto 0) := (others => '0');
    signal i_addrb                 : std_logic_vector((iFFT_WIDTH - 1) + SYMBOL_NUM_WIDTH + CH_NUM_WIDTH - 1 downto 0) := (others => '0');
    signal i_ena                   : std_logic := '0';
    signal i_enb                   : std_logic := '0';
    signal i_web                   : std_logic := '0';
    signal i_enb_d                 : std_logic_vector( 5 downto 0) := (others => '0');
    signal i_data_h                : std_logic_vector(31 downto 0) := (others => '0');
    signal i_data_l                : std_logic_vector(31 downto 0) := (others => '0');
    signal i_dina                  : std_logic_vector(71 downto 0) := (others => '0');
    signal i_doutb                 : std_logic_vector(71 downto 0) := (others => '0');
    signal iFFT_shift              : std_logic_vector(iFFT_WIDTH - 1 downto 0) := (others => '0');
    signal i_rd_cnt                : std_logic_vector(iFFT_WIDTH - 1 downto 0) := (others => '0');
    signal i_rd_cnt_complete       : natural range 0 to 4095 := 0;
    signal i_rd_cnt_max_value      : natural range 0 to 2**(iFFT_WIDTH) - 1 := 0;
    signal i_rd_complete, i_K0_odd_detect, i_doutb_valid, i_doutb_valid_d1, i_doutb_valid_d2, i_doutb_valid_d3 : std_logic := '0';
    signal i_dl_data_latch         : std_logic_vector(63 downto 0) := (others => '0');
    signal i_dl_data               : std_logic_vector(31 downto 0) := (others => '0');
    signal i_dl_data_d             : std_logic_vector(31 downto 0) := (others => '0');
    signal i_enb_latency           : std_logic := '0';
    signal i_rd_complete_d         : std_logic_vector( 5 downto 0) := (others => '0');
    signal dl_adv_symbol_ch_sync_d : std_logic := '0';
    signal i_dl_adv_symbol_idx     : std_logic_vector( 5 downto 0) := (others => '0');

    -- just for simulation
    type std_logic_array16 is array(natural range <>) of std_logic_vector(15 downto 0);
    signal DL_VALID                : std_logic_vector(CH_NUM - 1 downto 0) := (others => '0');
    signal DL_DATA_I               : std_logic_array16(CH_NUM - 1 downto 0) := (others => (others =>'0'));
    signal DL_DATA_Q               : std_logic_array16(CH_NUM - 1 downto 0) := (others => (others =>'0'));


begin

--================================================================================================
--  Write Operation
--================================================================================================

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            i_ch_idx      <= RB_CH_IDX(CH_NUM_WIDTH - 1 downto 0);
            i_frame_id    <= RB_FRAME_ID;
            i_subframe_id <= RB_SUBFRAME_ID;
            i_slot_id     <= RB_SLOT_ID;
        end if;
    end process;

    WR_ADDR_GEN : ADDR_TAILOR
    generic map(SCS => SCS, ADDR_WIDTH => SYMBOL_NUM_WIDTH)
    port map(
    SUBFRAME_ID => RB_SUBFRAME_ID,
    SLOT_ID     => RB_SLOT_ID,
    SYMBOL_ID   => RB_SYMBOL_ID,
    ADDR        => i_wr_addr_sym
    );

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           i_addr_sym <= i_wr_addr_sym;
           if (RB_VALID = '1') then
              if (RB_TICK = '1') then
                 i_addr_re <= RE_NUMBER(iFFT_WIDTH - 1 downto 0);
              else
                 i_addr_re <= i_addr_re + '1';
              end if;
           else
              i_addr_re <= (others => '0');
           end if;
        end if;
    end process;

    i_addra <= i_addr_sym & i_ch_idx & i_addr_re(iFFT_WIDTH - 1 downto 1);

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           i_ena        <= RB_VALID; -- read masking ???
           i_section_id <= RB_SECTION_ID(7 downto 0);
           i_data_l     <= RB_DATA_I & RB_DATA_Q;
           i_data_h     <= i_data_l;
        end if;
    end process;

    i_dina <= i_section_id & i_data_h & i_data_l;

--================================================================================================
--  Read Operation
--================================================================================================

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (DL_ADV_SYMBOL_SYNC = '1') then
              i_rd_ch_idx <= (others => '0');
           else
              if (DL_ADV_SYMBOL_CH_SYNC = '1') then
                 i_rd_ch_idx <= i_rd_ch_idx + '1';
              end if;
           end if;
        end if;
    end process;

    -- read address should consider K0 offset odd/even !!!
    -- iFFTshift / Non-zero-padding (need to be checked when non-zero K0 !!!)

    u_iFFT_SHIFT_NO : if iFFT_k0_SHIFT = FALSE generate
       iFFT_shift <= (others => '0');
       i_rd_cnt_max_value <= 0 when RE_SIZE = 0 else RE_SIZE - 1;
    end generate;

    u_iFFT_SHIFT_with_PADDING : if iFFT_k0_SHIFT = TRUE and iFFT_ZERO_PADDING = TRUE generate
       iFFT_shift <= conv_std_logic_vector(RE_SIZE/2, iFFT_WIDTH) - K0(iFFT_WIDTH - 1 downto 0);
       i_rd_cnt_max_value <= 2**(BW_iFFT_WIDTH)- 1;
    end generate;

    u_iFFT_SHIFT_without_PADDING : if iFFT_k0_SHIFT = TRUE and iFFT_ZERO_PADDING = FALSE generate
       iFFT_shift <= conv_std_logic_vector(RE_SIZE/2, iFFT_WIDTH) - K0(iFFT_WIDTH - 1 downto 0);
       i_rd_cnt_max_value <= 0 when RE_SIZE = 0 else RE_SIZE - 1;
    end generate;

    process (RE_SIZE,iFFT_shift)
    begin
        if (RE_SIZE = 0) then
           i_rd_cnt_complete <= 0;
        else
           if (iFFT_shift = 0) then
              i_rd_cnt_complete <= (RE_SIZE - 1);
           else
              i_rd_cnt_complete <= conv_integer(iFFT_shift  - '1');
           end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (i_enb_latency = '1' and i_rd_cnt = i_rd_cnt_complete) then
              i_rd_complete <= '1';
           else
              i_rd_complete <= '0';
           end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           dl_adv_symbol_ch_sync_d <= DL_ADV_SYMBOL_CH_SYNC;
           if (SYSTEM_MODE = '0') then
              if (DL_ADV_SYMBOL_CH_SYNC = '1') then
                 i_rd_cnt <= conv_std_logic_vector(i_rd_cnt_max_value, iFFT_WIDTH);
              elsif (dl_adv_symbol_ch_sync_d = '1') then
                 i_rd_cnt <= iFFT_shift;
              else
                 if (i_rd_cnt = i_rd_cnt_max_value - 1) then
                    i_rd_cnt <= (others => '0');
                 else
                    i_rd_cnt <= i_rd_cnt + '1';
                 end if;
              end if;
           else
              if (DL_ADV_SYMBOL_CH_SYNC = '1') then
                 i_rd_cnt <= iFFT_shift;
              else
                 if (i_rd_cnt = i_rd_cnt_max_value) then
                    i_rd_cnt <= (others => '0');
                 else
                    i_rd_cnt <= i_rd_cnt + '1';
                 end if;
              end if;
           end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (DL_ADV_SYMBOL_CH_SYNC = '1') then
              i_enb <= '1';
              if (SYSTEM_MODE = '0') then
                 i_web <= '1';
              else
                 i_web <= '0';
              end if;
           else
              if (i_enb = '1') then
                 if (i_rd_complete = '1') then
                    i_enb <= '0';
                    i_web <= '0';
                 else
                    if ((SYSTEM_MODE = '0' and i_rd_cnt = i_rd_cnt_max_value - 1) or i_rd_cnt(0) = '1') then
                      i_web <= '0';
                    else
                      i_web <= '1';
                    end if;
                 end if;
              end if;
           end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           i_rd_complete_d <= i_rd_complete_d(4 downto 0) & i_rd_complete;
           if (DL_ADV_SYMBOL_CH_SYNC = '1') then
              i_enb_latency <= '1';
           elsif (i_rd_complete_d(5) = '1' and VENDOR = "XILINX") or (i_rd_complete = '1' and VENDOR = "INTEL") then
              i_enb_latency <= '0';
           end if;
        end if;
    end process;

    i_dl_adv_symbol_idx <= "00" & DL_ADV_SYMBOL_IDX;

    RD_ADDR_GEN : ADDR_TAILOR
    generic map(SCS => SCS, ADDR_WIDTH => SYMBOL_NUM_WIDTH)
    port map(
    SUBFRAME_ID => DL_ADV_SBF_IDX,
    SLOT_ID     => DL_ADV_SLOT_IDX(5 downto 0),
    SYMBOL_ID   => i_dl_adv_symbol_idx,
    ADDR        => i_rd_addr_sym
    );

    i_addrb <= i_rd_addr_sym & i_rd_ch_idx & i_rd_cnt(iFFT_WIDTH - 1 downto 1);

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           i_enb_d <= i_enb_d(4 downto 0) & i_enb;
           if (i_enb_d(5 downto 4) = "01" and VENDOR = "XILINX") or (i_enb_d(1 downto 0) = "01" and VENDOR = "INTEL") then
              i_doutb_valid <= '1';
           elsif (i_enb_d(4 downto 3) = "10" and VENDOR = "XILINX") or (i_enb_d(0) = '1' and i_enb = '0' and VENDOR = "INTEL") then
              i_doutb_valid <= '0';
           end if;
           if (i_enb_d(5 downto 4) = "01" and VENDOR = "XILINX") or (i_enb_d(1 downto 0) = "01" and VENDOR = "INTEL") then
              i_K0_odd_detect <= '1';
           else
              i_K0_odd_detect <= '0';
           end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           i_doutb_valid_d1 <= i_doutb_valid;
           if (i_K0_odd_detect = '1' or i_rd_cnt(0) = '0') then
              i_dl_data_latch <= i_doutb(63 downto 0);
           end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           i_doutb_valid_d2 <= i_doutb_valid_d1;
           if (i_doutb_valid_d1 = '1') then
              if (i_rd_cnt(0) = '1') then
                 i_dl_data <= i_dl_data_latch(63 downto 32);
              else
                 i_dl_data <= i_dl_data_latch(31 downto 0);
              end if;
           else
              i_dl_data <= (others => '0');
           end if;
        end if;
    end process;

    -- latency : 6 clk (XILINX), 2 clk (INTEL)
    DL_UP_MEM :  UP_MEMORY
    generic map
    (
    VENDOR     => VENDOR,
    ADDR_WIDTH => (iFFT_WIDTH - 1) + SYMBOL_NUM_WIDTH + CH_NUM_WIDTH,
    DATA_WIDTH => 72
    )
    port map(
    CLK        => CLK,
    ENA        => i_ena,
    ENB        => i_enb_latency,
    WEB        => i_web,
    ADDRA      => i_addra,
    ADDRB      => i_addrb,
    DINA       => i_dina,
    DOUTB      => i_doutb
    );

    u_DL_DATA_GEN : for i in CH_NUM - 1 downto 0 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           if (i_rd_ch_idx = i) then
              DL_DATA(i*32 + 31 downto i*32) <= i_dl_data;
           else
              DL_DATA(i*32 + 31 downto i*32) <= (others => '0');
           end if;
        end if;
    end process;
    end generate;

    -- just for simulation
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           i_doutb_valid_d3 <= i_doutb_valid_d2;
           i_dl_data_d <= i_dl_data;
        end if;
    end process;

    u_DL_DATA_SIMULATION : for i in CH_NUM - 1 downto 0 generate

    DL_VALID(i)  <= i_doutb_valid_d3 when i_rd_ch_idx = i else '0';
    DL_DATA_I(i) <= i_dl_data_d(31 downto 16) when i_rd_ch_idx = i else (others => '0');
    DL_DATA_Q(i) <= i_dl_data_d(15 downto  0) when i_rd_ch_idx = i else (others => '0');

    end generate;

end BEHAVE;