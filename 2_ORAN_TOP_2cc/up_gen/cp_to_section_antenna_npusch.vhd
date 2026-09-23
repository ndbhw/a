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

use WORK.ARRAY_TYPE.ALL;
use WORK.PKG_ORAN.ALL;

entity CP_TO_SECTION_ANTENNA_NPUSCH is
    generic (
        MAX_NUM_PORTC               : natural := 16;
        LINK_DIRECTION              : std_logic := '0';                         -- '0' : Uplink, '1' : Downlink
        DATA_ID                     : natural := 0
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;
        RST                         : in  std_logic;

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

        CNT_FIFO_FULL               : out std_logic_vector(31 downto 0);

--------------------------------------------------------------------------------
-- C-Plane message
--------------------------------------------------------------------------------

        FREQ_OFFSET_FOR_PRACH       : in  std_logic_array24(MAX_NUM_PORTC-1 downto 0);

--------------------------------------------------------------------------------
-- Decoded C-Plane
--------------------------------------------------------------------------------

        CP_UPDATE                   : in  std_logic;

        CP_DATA_ID                  : in  std_logic_vector(2 downto 0);
        CP_ANT_ID                   : in  std_logic_vector(3 downto 0);
        CP_DATA_DIRECTION           : in  std_logic;
        CP_FILTER_INDEX             : in  std_logic_vector(3 downto 0);
        CP_FRAME_ID                 : in  std_logic_vector(7 downto 0);
        CP_SUBFRAME_ID              : in  std_logic_vector(3 downto 0);
        CP_SLOT_ID                  : in  std_logic_vector(5 downto 0);
        CP_SYMBOL_ID                : in  std_logic_vector(5 downto 0);
        CP_SECTION_TYPE             : in  std_logic_vector(7 downto 0);
        CP_UD_COMP_HDR              : in  std_logic_vector(7 downto 0);
        CP_SECTION_ID               : in  std_logic_vector(11 downto 0);
        CP_RB                       : in  std_logic;
        CP_START_PRB                : in  std_logic_vector(9 downto 0);
        CP_NUM_PRB                  : in  std_logic_vector(7 downto 0);
        CP_NUM_SYMBOL               : in  std_logic_vector(3 downto 0);
--        CP_BEAMID                   : in  std_logic_vector(14 downto 0);
        CP_FREQ_OFFSET              : in  std_logic_vector(23 downto 0);
        CP_NUM_PORTC                : in  std_logic_vector(5 downto 0);

--------------------------------------------------------------------------------
-- Section command queue
--------------------------------------------------------------------------------

        CMD_EN                      : out std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        CMD                         : out std_logic_array72(MAX_NUM_PORTC-1 downto 0)
    );
end CP_TO_SECTION_ANTENNA_NPUSCH;

architecture BEHAVE of CP_TO_SECTION_ANTENNA_NPUSCH is

    type fsm_c_plane                is (IDLE, LOAD0, LOAD1, LOAD2, PROC);
    signal fsm_write                : fsm_c_plane;
    signal cnt_dec_state            : std_logic_vector(2 downto 0) := (others => '0');

    signal do_write                 : std_logic := '0';
    signal field_filter_index       : std_logic_vector(3 downto 0);
--    signal field_frame_id           : std_logic_vector(7 downto 0);
--    signal field_subframe_id        : std_logic_vector(3 downto 0);
--    signal field_slot_id            : std_logic_vector(3 downto 0);
--    signal field_symbol_id          : std_logic_vector(5 downto 0);
    signal field_section_type       : std_logic_vector(7 downto 0);
--    signal field_ud_comp_hdr        : std_logic_vector(7 downto 0);
--    signal field_section_id         : std_logic_vector(11 downto 0);
--    signal field_rb                 : std_logic;
--    signal field_start_prb          : std_logic_vector(9 downto 0);
--    signal field_num_prb            : std_logic_vector(7 downto 0);
    signal field_num_symbol         : std_logic_vector(3 downto 0);
    signal field_freq_offset        : std_logic_vector(23 downto 0);
    signal field_num_portc          : std_logic_vector(5 downto 0);
    signal field_ant_id             : std_logic_vector(3 downto 0);

    signal sec_cmd_en               : std_logic_array15(MAX_NUM_PORTC-1 downto 0);
    signal sec_cmd                  : std_logic_array72(MAX_NUM_PORTC-1 downto 0);

    component PRB_ANTENNA is
    port (
        CHANNEL_ID                  : in  std_logic_vector(2 downto 0);
        NUM_PORTC                   : in  std_logic_vector(5 downto 0);

        INDEX                       : out std_logic_vector(63 downto 0)
    );
    end component;

    signal index_antenna            : std_logic_vector(63 downto 0);

    component XPM_FIFO_SYNC is
    generic (
        -- Common module generics
        FIFO_MEMORY_TYPE            : string := "auto";                         -- Allowed values: auto, block, distributed. Default value = auto.
        FIFO_WRITE_DEPTH            : integer := 2048;
        WRITE_DATA_WIDTH            : integer := 32;
        READ_MODE                   : string := "std";                          -- Allowed values: std, fwft. Default value = std.
        FIFO_READ_LATENCY           : integer := 1;
        FULL_RESET_VALUE            : integer := 0;
        USE_ADV_FEATURES            : string := "0707";
        READ_DATA_WIDTH             : integer := 32;
        WR_DATA_COUNT_WIDTH         : integer := 1;
        PROG_FULL_THRESH            : integer := 10;
        RD_DATA_COUNT_WIDTH         : integer := 1;
        PROG_EMPTY_THRESH           : integer := 10;
        DOUT_RESET_VALUE            : string := "0";
        ECC_MODE                    : string := "no_ecc";
        SIM_ASSERT_CHK              : integer := 0;
        WAKEUP_TIME                 : integer := 0
    );
    port (
        SLEEP                       : in  std_logic;
        RST                         : in  std_logic;
        WR_CLK                      : in  std_logic;
        WR_EN                       : in  std_logic;
        DIN                         : in  std_logic_vector(WRITE_DATA_WIDTH-1 downto 0);
        FULL                        : out std_logic;
        PROG_FULL                   : out std_logic;
        WR_DATA_COUNT               : out std_logic_vector(WR_DATA_COUNT_WIDTH-1 downto 0);
        OVERFLOW                    : out std_logic;
        WR_RST_BUSY                 : out std_logic;
        ALMOST_FULL                 : out std_logic;
        WR_ACK                      : out std_logic;
        RD_EN                       : in  std_logic;
        DOUT                        : out std_logic_vector(READ_DATA_WIDTH-1 downto 0);
        EMPTY                       : out std_logic;
        PROG_EMPTY                  : out std_logic;
        RD_DATA_COUNT               : out std_logic_vector(RD_DATA_COUNT_WIDTH-1 downto 0);
        UNDERFLOW                   : out std_logic;
        RD_RST_BUSY                 : out std_logic;
        ALMOST_EMPTY                : out std_logic;
        DATA_VALID                  : out std_logic;
        INJECTSBITERR               : in  std_logic;
        INJECTDBITERR               : in  std_logic;
        SBITERR                     : out std_logic;
        DBITERR                     : out std_logic
    );
    end component;

    constant CMD_WIDTH              : natural := 111;

    signal wr_en                    : std_logic;
    signal din                      : std_logic_vector(CMD_WIDTH-1 downto 0);
    signal full                     : std_logic_vector(1 downto 0) := (others => '1');
    signal rd_en                    : std_logic;
    signal dout                     : std_logic_vector(CMD_WIDTH-1 downto 0);
    signal dout_optimized           : std_logic_vector(71 downto 0);
    signal empty                    : std_logic;
    signal cnt_full                 : std_logic_vector(15 downto 0) := (others => '0');

begin

--------------------------------------------------------------------------------
-- Write command
--------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (CP_UPDATE = '1') and (CP_DATA_DIRECTION = LINK_DIRECTION) and (CP_DATA_ID = DATA_ID) then
                wr_en <= not full(0);
            else
                wr_en <= '0';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            din(03 downto 00)   <= CP_FILTER_INDEX;
            din(11 downto 04)   <= CP_FRAME_ID;
            din(15 downto 12)   <= CP_SUBFRAME_ID;
            din(19 downto 16)   <= CP_SLOT_ID(3 downto 0);
            din(25 downto 20)   <= CP_SYMBOL_ID;
            din(33 downto 26)   <= CP_SECTION_TYPE;
            din(41 downto 34)   <= CP_UD_COMP_HDR;
            din(53 downto 42)   <= CP_SECTION_ID;
            din(54)             <= CP_RB;
            din(64 downto 55)   <= CP_START_PRB;
            din(72 downto 65)   <= CP_NUM_PRB;
            din(76 downto 73)   <= CP_NUM_SYMBOL;
            din(100 downto 77)  <= CP_FREQ_OFFSET;
            din(106 downto 101) <= CP_NUM_PORTC;
            din(110 downto 107) <= CP_ANT_ID;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Command Queue
--------------------------------------------------------------------------------

    u_FIFO : XPM_FIFO_SYNC
    generic map(
        FIFO_MEMORY_TYPE            => "distributed"                           ,--: string := "auto";
        FIFO_WRITE_DEPTH            => 32                                      ,--: integer := 2048;
        WRITE_DATA_WIDTH            => CMD_WIDTH                               ,--: integer := 32;
        READ_MODE                   => "std"                                   ,--: string := "std";
        FIFO_READ_LATENCY           => 3                                       ,--: integer := 1;
        FULL_RESET_VALUE            => 0                                       ,--: integer := 0;
        USE_ADV_FEATURES            => "0705"                                  ,--: string := "0707";
        READ_DATA_WIDTH             => CMD_WIDTH                               ,--: integer := 32;
        WR_DATA_COUNT_WIDTH         => 4                                       ,--: integer := 1;
        PROG_FULL_THRESH            => 10                                      ,--: integer := 10;
        RD_DATA_COUNT_WIDTH         => 4                                       ,--: integer := 1;
        PROG_EMPTY_THRESH           => 10                                      ,--: integer := 10;
        DOUT_RESET_VALUE            => "0"                                     ,--: string := "0";
        ECC_MODE                    => "no_ecc"                                ,--: string := "no_ecc";
        SIM_ASSERT_CHK              => 1                                       ,--: integer := 0;
        WAKEUP_TIME                 => 0                                        --: integer := 0
    )
    port map(
        SLEEP                       => '0'                                     ,--: in  std_logic;
        RST                         => RST                                     ,--: in  std_logic;
        WR_CLK                      => CLK                                     ,--: in  std_logic;
        WR_EN                       => wr_en                                   ,--: in  std_logic;
        DIN                         => din                                     ,--: in  std_logic_vector(WRITE_DATA_WIDTH-1 downto 0);
        FULL                        => full(0)                                 ,--: out std_logic;
        PROG_FULL                   => open                                    ,--: out std_logic;
        WR_DATA_COUNT               => open                                    ,--: out std_logic_vector(WR_DATA_COUNT_WIDTH-1 downto 0);
        OVERFLOW                    => open                                    ,--: out std_logic;
        WR_RST_BUSY                 => open                                    ,--: out std_logic;
        ALMOST_FULL                 => open                                    ,--: out std_logic;
        WR_ACK                      => open                                    ,--: out std_logic;
        RD_EN                       => rd_en                                   ,--: in  std_logic;
        DOUT                        => dout                                    ,--: out std_logic_vector(READ_DATA_WIDTH-1 downto 0);
        EMPTY                       => empty                                   ,--: out std_logic;
        PROG_EMPTY                  => open                                    ,--: out std_logic;
        RD_DATA_COUNT               => open                                    ,--: out std_logic_vector(RD_DATA_COUNT_WIDTH-1 downto 0);
        UNDERFLOW                   => open                                    ,--: out std_logic;
        RD_RST_BUSY                 => open                                    ,--: out std_logic;
        ALMOST_EMPTY                => open                                    ,--: out std_logic;
        DATA_VALID                  => open                                    ,--: out std_logic;
        INJECTSBITERR               => '0'                                     ,--: in  std_logic;
        INJECTDBITERR               => '0'                                     ,--: in  std_logic;
        SBITERR                     => open                                    ,--: out std_logic;
        DBITERR                     => open                                     --: out std_logic
    );

    CNT_FIFO_FULL <= x"0000" & cnt_full;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            full(1) <= full(0);
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (full = "01") then
                cnt_full <= cnt_full + 1;
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------
-- FSM
--------------------------------------------------------------------------------

    process (RST, CLK)
    begin
        if (RST = '1') then
            fsm_write <= IDLE;
        elsif (CLK'event and CLK = '1') then
            case fsm_write is
            when IDLE   =>
                if (empty = '0') then
                    fsm_write <= LOAD0;
                else
                    fsm_write <= IDLE;
                end if;
            when LOAD0  =>
                fsm_write <= LOAD1;
            when LOAD1  =>
                fsm_write <= LOAD2;
            when LOAD2  =>
                fsm_write <= PROC;
            when PROC   =>
                if (cnt_dec_state = 7) then
                    fsm_write <= IDLE;
                else
                    fsm_write <= PROC;
                end if;
            when others =>
                fsm_write <= IDLE;
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_write is
            when PROC   =>
                cnt_dec_state <= cnt_dec_state + 1;
            when others =>
                cnt_dec_state <= (others => '0');
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_write is
            when IDLE   =>
                if (empty = '0') then
                    rd_en <= '1';
                else
                    rd_en <= '0';
                end if;
            when others =>
                rd_en <= '0';
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_write is
            when LOAD2  =>
                do_write <= '1';
            when others =>
                do_write <= '0';
            end case;
        end if;
    end process;

--------------------------------------------------------------------------------
-- DOUT mapping
--------------------------------------------------------------------------------

    field_filter_index              <= dout(03 downto 00);
--    field_frame_id                  <= dout(11 downto 04);
--    field_subframe_id               <= dout(15 downto 12);
--    field_slot_id                   <= dout(19 downto 16);
--    field_symbol_id                 <= dout(25 downto 20);
    field_section_type              <= dout(33 downto 26);
--    field_ud_comp_hdr               <= dout(41 downto 34);
--    field_section_id                <= dout(53 downto 42);
--    field_rb                        <= dout(54);
--    field_start_prb                 <= dout(64 downto 55);
--    field_num_prb                   <= dout(72 downto 65);
    field_num_symbol                <= dout(76 downto 73);
    field_freq_offset               <= dout(100 downto 77);
    field_num_portc                 <= dout(106 downto 101);
    field_ant_id                    <= dout(110 downto 107);

--------------------------------------------------------------------------------
-- Optimization of queue width (Limited up to 72bits for BRAM implementation)
--------------------------------------------------------------------------------

    dout_optimized(03 downto 00)    <= dout(03 downto 00);                      -- field_filter_index
    dout_optimized(11 downto 04)    <= dout(11 downto 04);                      -- field_frame_id
    dout_optimized(15 downto 12)    <= dout(15 downto 12);                      -- field_subframe_id
    dout_optimized(19 downto 16)    <= dout(19 downto 16);                      -- field_slot_id
    dout_optimized(25 downto 20)    <= dout(25 downto 20);                      -- field_symbol_id
    dout_optimized(33 downto 26)    <= dout(41 downto 34);                      -- field_ud_comp_hdr
    dout_optimized(45 downto 34)    <= dout(53 downto 42);                      -- field_section_id
    dout_optimized(46)              <= dout(54);                                -- field_rb
    dout_optimized(56 downto 47)    <= dout(64 downto 55);                      -- field_start_prb
    dout_optimized(64 downto 57)    <= dout(72 downto 65);                      -- field_num_prb
    dout_optimized(68 downto 65)    <= dout(110 downto 107);                    -- field_ant_id
    dout_optimized(71 downto 69)    <= (others => '0');                         -- reserved

--------------------------------------------------------------------------------
-- Write
--------------------------------------------------------------------------------

    u_ANTENNA : PRB_ANTENNA
    port map(
        CHANNEL_ID                  => field_ant_id(2 downto 0)                ,--: in  std_logic_vector(2 downto 0);
        NUM_PORTC                   => field_num_portc                         ,--: in  std_logic_vector(5 downto 0);

        INDEX                       => index_antenna                            --: out std_logic_vector(63 downto 0)
    );

    u_FOR_ANTENNA : for i in MAX_NUM_PORTC-1 downto 0 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (do_write = '1') and (field_section_type = 3) and (field_filter_index = 8) then
                if    (index_antenna(i) = '1') and (field_freq_offset = FREQ_OFFSET_FOR_PRACH(i)) then
                    if    (field_num_symbol = 1) then                           sec_cmd_en(i) <= "010000000000000";
                    elsif (field_num_symbol = 2) then                           sec_cmd_en(i) <= "011000000000000";
                    elsif (field_num_symbol = 3) then                           sec_cmd_en(i) <= "011100000000000";
                    elsif (field_num_symbol = 4) then                           sec_cmd_en(i) <= "011110000000000";
                    elsif (field_num_symbol = 5) then                           sec_cmd_en(i) <= "011111000000000";
                    elsif (field_num_symbol = 6) then                           sec_cmd_en(i) <= "011111100000000";
                    elsif (field_num_symbol = 7) then                           sec_cmd_en(i) <= "011111110000000";
                    elsif (field_num_symbol = 8) then                           sec_cmd_en(i) <= "011111111000000";
                    elsif (field_num_symbol = 9) then                           sec_cmd_en(i) <= "011111111100000";
                    elsif (field_num_symbol = 10) then                          sec_cmd_en(i) <= "011111111110000";
                    elsif (field_num_symbol = 11) then                          sec_cmd_en(i) <= "011111111111000";
                    elsif (field_num_symbol = 12) then                          sec_cmd_en(i) <= "011111111111100";
                    elsif (field_num_symbol = 13) then                          sec_cmd_en(i) <= "011111111111110";
                    elsif (field_num_symbol = 14) then                          sec_cmd_en(i) <= "011111111111111";
                    else                                                        sec_cmd_en(i) <= "000000000000000";
                    end if;
                else
                    sec_cmd_en(i) <= sec_cmd_en(i)(13 downto 0) & '0';
                end if;
            else
                sec_cmd_en(i) <= sec_cmd_en(i)(13 downto 0) & '0';
            end if;
        end if;
    end process;

    CMD(i) <= sec_cmd(i);

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (do_write = '1') then
                sec_cmd(i) <= dout_optimized;
            else
                if (sec_cmd_en(i)(14) = '1') then
                    sec_cmd(i)(25 downto 20) <= sec_cmd(i)(25 downto 20) + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            CMD_EN(i) <= sec_cmd_en(i)(13);
        end if;
    end process;
    end generate;

end BEHAVE;