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
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.ARRAY_TYPE.ALL;
use WORK.PKG_ORAN_ARRAY.ALL;

entity SECTION_CMD_QUEUE_ANTENNA is
    generic (
        MAX_NUM_PORTC               : natural := 8;
        LINK_DIRECTION              : std_logic := '0';                         -- '0' : Uplink, '1' : Downlink
        CMD_QUEUE_MEMORY_TYPE       : string := "auto";                         -- Allowed values: auto, block, distributed. Default value = auto.
        CMD_QUEUE_DEPTH             : integer := 2048
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

        IGNORE_FRAME_ID             : in  std_logic;
        IGNORE_FRAME_ID_RX          : out std_logic_vector(7 downto 0);
        IGNORE_FRAME_ID_TX          : out std_logic_vector(7 downto 0);

        COMP_MODE                   : in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        IQ_WIDTH                    : in  std_logic_array4(MAX_NUM_PORTC-1 downto 0);
        COMP_METHOD                 : in  std_logic_array4(MAX_NUM_PORTC-1 downto 0);
        PRB_PER_SYMBOL              : in  std_logic_array10(MAX_NUM_PORTC-1 downto 0);
        PRB_PER_MTU                 : in  std_logic_vector(9 downto 0);

--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

        CNT_ABNORMAL_TERMINATION    : out std_logic_vector(31 downto 0);

        CNT_SECTION_SYMBOL0         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL1         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL2         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL3         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL4         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL5         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL6         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL7         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL8         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL9         : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL10        : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL11        : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL12        : out std_logic_vector(31 downto 0);
        CNT_SECTION_SYMBOL13        : out std_logic_vector(31 downto 0);

        CNT_CQ_FULL_SYMBOL0         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL1         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL2         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL3         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL4         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL5         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL6         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL7         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL8         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL9         : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL10        : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL11        : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL12        : out std_logic_vector(31 downto 0);
        CNT_CQ_FULL_SYMBOL13        : out std_logic_vector(31 downto 0);

        USAGE_CQ_SYMBOL0            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL1            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL2            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL3            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL4            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL5            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL6            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL7            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL8            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL9            : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL10           : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL11           : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL12           : out std_logic_vector(31 downto 0);
        USAGE_CQ_SYMBOL13           : out std_logic_vector(31 downto 0);

        STATUS_FSM                  : out std_logic_vector(7 downto 0);

--------------------------------------------------------------------------------
-- Scheduler timer
--------------------------------------------------------------------------------

        INFO_UPDATE                 : in  std_logic;

        INFO_FRAME_ID               : in  std_logic_vector(7 downto 0);
        INFO_SUBFRAME_ID            : in  std_logic_vector(3 downto 0);
        INFO_SLOT_ID                : in  std_logic_vector(5 downto 0);
        INFO_SYMBOL_ID              : in  std_logic_vector(5 downto 0);
        INFO_ANT_ID                 : in  std_logic_vector(2 downto 0);

--------------------------------------------------------------------------------
-- Command bus
--------------------------------------------------------------------------------

        CMD_EN                      : in  std_logic_vector(MAX_NUM_PORTC-1 downto 0);
        CMD                         : in  std_logic_array72(MAX_NUM_PORTC-1 downto 0);

--------------------------------------------------------------------------------
-- PRB Packer
--------------------------------------------------------------------------------

        INIT_SESSION                : out std_logic;
        PATH_SEL                    : out std_logic_vector(2 downto 0);

        PACKING_TICK                : out std_logic_vector(MAX_NUM_PORTC-1 downto 0);

        DATA_DIRECTION              : out std_logic;
        PAYLOAD_VERSION             : out std_logic_vector(2 downto 0);
        FILTER_INDEX                : out std_logic_vector(3 downto 0);
        FRAME_ID                    : out std_logic_vector(7 downto 0);
        SUBFRAME_ID                 : out std_logic_vector(3 downto 0);
        SLOT_ID                     : out std_logic_vector(5 downto 0);
        SYMBOL_ID                   : out std_logic_vector(5 downto 0);

        SECTION_TICK                : out std_logic;
        SECTION_LAST                : out std_logic;
        SECTION_DONE                : in  std_logic;

        SECTION_ID                  : out std_logic_vector(11 downto 0) := (others => '0');
        BANK_OF_PRB                 : out std_logic_vector(0 downto 0) := (others => '0');
        USE_EVERY_PRB               : out std_logic := '0';
        START_OF_PRB                : out std_logic_vector(9 downto 0) := (others => '0');
        OFFSET_OF_PRB               : out std_logic_vector(9 downto 0) := (others => '0');
        NUMBER_OF_PRB               : out std_logic_vector(9 downto 0) := (others => '0');
        UD_COMP_HDR                 : out std_logic_vector(8 downto 0) := (others => '0')
    );
end SECTION_CMD_QUEUE_ANTENNA;

architecture BEHAVE of SECTION_CMD_QUEUE_ANTENNA is

    component CQ_SYMBOL is
    generic (
        MEMORY_TYPE                 : string := "auto";                         -- Allowed values: auto, block, distributed. Default value = auto.
        WRITE_DEPTH                 : integer := 2048;
        WRITE_WIDTH                 : integer := 72
    );
    port (
        CLK                         : in  std_logic;
        SRST                        : in  std_logic;
        DIN                         : in  std_logic_vector(WRITE_WIDTH-1 downto 0);
        WR_EN                       : in  std_logic;
        RD_EN                       : in  std_logic;
        DOUT                        : out std_logic_vector(WRITE_WIDTH-1 downto 0);
        FULL                        : out std_logic;
        EMPTY                       : out std_logic;
        DATA_COUNT                  : out std_logic_vector(31 downto 0);
        WR_RST_BUSY                 : out std_logic;
        RD_RST_BUSY                 : out std_logic
    );
    end component;

    constant LATENCY_FIFO           : natural := 1+1;                           -- FIFO + User

    signal din                      : std_logic_array72(MAX_NUM_PORTC-1 downto 0) := (others => (others => '0'));
    signal wr_en                    : std_logic_vector(MAX_NUM_PORTC-1 downto 0) := (others => '0');
    signal rd_en                    : std_logic_vector(MAX_NUM_PORTC-1 downto 0) := (others => '0');
    signal dout_buf                 : std_logic_array72(MAX_NUM_PORTC-1 downto 0);
    signal dout                     : std_logic_vector(71 downto 0) := (others => '1');
    signal full                     : std_logic_vector(MAX_NUM_PORTC-1 downto 0);
    signal empty                    : std_logic_vector(MAX_NUM_PORTC-1 downto 0);
    signal data_count               : std_logic_array32(7 downto 0) := (others => (others => '0'));
    signal wr_rst_busy              : std_logic_vector(MAX_NUM_PORTC-1 downto 0);
    signal wr_stop                  : std_logic_vector(MAX_NUM_PORTC-1 downto 0);

    signal slot_lost                : std_logic_array2(MAX_NUM_PORTC-1 downto 0) := (others => (others => '1'));
    signal ref_frame_id             : std_logic_vector(7 downto 0) := (others => '0');
    signal ref_frame_id_sh          : std_logic_vector(7 downto 0) := (others => '0');
    signal ref_subframe_id          : std_logic_vector(3 downto 0) := (others => '0');
    signal ref_subframe_id_sh       : std_logic_vector(3 downto 0) := (others => '0');
    signal ref_slot_id              : std_logic_vector(5 downto 0) := (others => '0');
    signal ref_slot_id_sh           : std_logic_vector(5 downto 0) := (others => '0');
    signal ref_symbol_id            : std_logic_vector(5 downto 0) := (others => '0');
    signal ref_symbol_id_sh         : std_logic_vector(5 downto 0) := (others => '0');
    signal ref_ant_id               : std_logic_vector(2 downto 0) := (others => '0');
    signal ant_index                : std_logic_vector(7 downto 0) := (others => '0');

    signal now_frame_id             : std_logic_vector(7 downto 0) := (others => '0');
    signal now_subframe_id          : std_logic_vector(3 downto 0) := (others => '0');
    signal now_slot_id              : std_logic_vector(5 downto 0) := (others => '0');
    signal now_symbol_id            : std_logic_vector(5 downto 0) := (others => '0');

    signal cmd_filter_index         : std_logic_vector(3 downto 0) := (others => '0');
    signal cmd_frame_id             : std_logic_vector(7 downto 0) := (others => '0');
    signal cmd_subframe_id          : std_logic_vector(3 downto 0) := (others => '0');
    signal cmd_slot_id              : std_logic_vector(5 downto 0) := (others => '0');
--    signal cmd_symbol_id            : std_logic_vector(5 downto 0) := (others => '0');
    signal cmd_ud_comp_hdr          : std_logic_vector(7 downto 0) := (others => '0');
    signal cmd_section_id           : std_logic_vector(11 downto 0) := (others => '0');
    signal cmd_use_every_prb        : std_logic := '0';
--    signal cmd_start_prb            : std_logic_vector(9 downto 0) := (others => '0');
--    signal cmd_num_prb              : std_logic_vector(7 downto 0) := (others => '0');

    signal ontime_cmd               : std_logic_vector(1 downto 0) := (others => '0');

    type fsm_section                is (IDLE, LOAD, SPLIT, PACK, SECTION, WAITING);
    signal fsm_cmd                  : fsm_section;
    signal cnt_cmd_state            : std_logic_vector(3 downto 0);

    signal max_prb                  : std_logic_vector(9 downto 0);
    signal prb_start                : std_logic_vector(9 downto 0);
    signal prb_offset               : std_logic_vector(9 downto 0);
    signal prb_num                  : std_logic_vector(9 downto 0);
    signal prb_end                  : std_logic_vector(9 downto 0);
    signal split_section            : std_logic := '0';
    signal more_section             : std_logic := '0';

    component USAGE_TO_GAUGE is
    generic (
        MAX_USAGE                   : natural := 1024
    );
    port (
        CLK                         : in  std_logic;

        USAGE                       : in  std_logic_vector(31 downto 0);
        GAUGE                       : out std_logic_vector(31 downto 0)
    );
    end component;

    signal cnt_section              : std_logic_array32(13 downto 0) := (others => (others => '0'));
    signal cnt_cq_full              : std_logic_array32(13 downto 0) := (others => (others => '0'));
    signal cnt_termination          : std_logic_vector(MAX_DEBUG_BIT-1 downto 0) := (others => '0');

begin

--------------------------------------------------------------------------------
-- Time Index
--------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (INFO_UPDATE = '1') then
                ref_frame_id    <= INFO_FRAME_ID;
                ref_subframe_id <= INFO_SUBFRAME_ID;
                ref_slot_id     <= INFO_SLOT_ID;
                ref_symbol_id   <= INFO_SYMBOL_ID;
                ref_ant_id      <= INFO_ANT_ID;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            ref_frame_id_sh    <= ref_frame_id;
            ref_subframe_id_sh <= ref_subframe_id;
            ref_slot_id_sh     <= ref_slot_id;
            ref_symbol_id_sh   <= ref_symbol_id;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (ref_ant_id = 0) then             ant_index <= "00000001";
            elsif (ref_ant_id = 1) then             ant_index <= "00000010";
            elsif (ref_ant_id = 2) then             ant_index <= "00000100";
            elsif (ref_ant_id = 3) then             ant_index <= "00001000";
            elsif (ref_ant_id = 4) then             ant_index <= "00010000";
            elsif (ref_ant_id = 5) then             ant_index <= "00100000";
            elsif (ref_ant_id = 6) then             ant_index <= "01000000";
            elsif (ref_ant_id = 7) then             ant_index <= "10000000";
            else                                    ant_index <= "00000000";
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Command Queue
--------------------------------------------------------------------------------

    u_CQ_ANTENNA : for i in MAX_NUM_PORTC-1 downto 0 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            din(i)   <= CMD(i);
            wr_en(i) <= CMD_EN(i) and (not wr_rst_busy(i));
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (wr_stop(i) = '1') then
                slot_lost(i) <= slot_lost(i)(0) & '1';
            else
                slot_lost(i) <= slot_lost(i)(0) & '0';
            end if;
        end if;
    end process;

    u_CQ : CQ_SYMBOL
    generic map(
        MEMORY_TYPE                 => CMD_QUEUE_MEMORY_TYPE                   ,--: string := "auto";
        WRITE_DEPTH                 => CMD_QUEUE_DEPTH                         ,--: integer := 2048;
        WRITE_WIDTH                 => 72                                       --: integer := 72
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        SRST                        => slot_lost(i)(0)                         ,--: in  std_logic;
        DIN                         => din(i)                                  ,--: in  std_logic_vector(WRITE_WIDTH-1 downto 0);
        WR_EN                       => wr_en(i)                                ,--: in  std_logic;
        RD_EN                       => rd_en(i)                                ,--: in  std_logic;
        DOUT                        => dout_buf(i)                             ,--: out std_logic_vector(WRITE_WIDTH-1 downto 0);
        FULL                        => full(i)                                 ,--: out std_logic;
        EMPTY                       => empty(i)                                ,--: out std_logic;
        DATA_COUNT                  => data_count(i)                           ,--: out std_logic_vector(31 downto 0);
        WR_RST_BUSY                 => wr_rst_busy(i)                          ,--: out std_logic;
        RD_RST_BUSY                 => open                                     --: out std_logic
    );

    process (RST, CLK)
    begin
        if (RST = '1') then
            wr_stop(i) <= '1';
        elsif (CLK'event and CLK = '1') then
            if (wr_en(i) = '1') and (full(i) = '1') then
                wr_stop(i) <= '1';
            elsif (empty(i) = '1') then
                wr_stop(i) <= '0';
            end if;
        end if;
    end process;
    end generate;

--------------------------------------------------------------------------------
-- Command Selection
--------------------------------------------------------------------------------

    u_MAX_CH_2 : if MAX_NUM_PORTC = 2 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (ref_ant_id = 0) and (empty(0) = '0') then
                dout <= dout_buf(0);
            elsif (ref_ant_id = 1) and (empty(1) = '0') then
                dout <= dout_buf(1);
            else
                dout <= (others => '1');
            end if;
        end if;
    end process;
    end generate;

    u_MAX_CH_4 : if MAX_NUM_PORTC = 4 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (ref_ant_id = 0) and (empty(0) = '0') then
                dout <= dout_buf(0);
            elsif (ref_ant_id = 1) and (empty(1) = '0') then
                dout <= dout_buf(1);
            elsif (ref_ant_id = 2) and (empty(2) = '0') then
                dout <= dout_buf(2);
            elsif (ref_ant_id = 3) and (empty(3) = '0') then
                dout <= dout_buf(3);
            else
                dout <= (others => '1');
            end if;
        end if;
    end process;
    end generate;

    u_MAX_CH_8 : if MAX_NUM_PORTC = 8 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (ref_ant_id = 0) and (empty(0) = '0') then
                dout <= dout_buf(0);
            elsif (ref_ant_id = 1) and (empty(1) = '0') then
                dout <= dout_buf(1);
            elsif (ref_ant_id = 2) and (empty(2) = '0') then
                dout <= dout_buf(2);
            elsif (ref_ant_id = 3) and (empty(3) = '0') then
                dout <= dout_buf(3);
            elsif (ref_ant_id = 4) and (empty(4) = '0') then
                dout <= dout_buf(4);
            elsif (ref_ant_id = 5) and (empty(5) = '0') then
                dout <= dout_buf(5);
            elsif (ref_ant_id = 6) and (empty(6) = '0') then
                dout <= dout_buf(6);
            elsif (ref_ant_id = 7) and (empty(7) = '0') then
                dout <= dout_buf(7);
            else
                dout <= (others => '1');
            end if;
        end if;
    end process;
    end generate;

    now_frame_id    <= dout(11 downto 4);
    now_subframe_id <= dout(15 downto 12);
    now_slot_id     <= "00" & dout(19 downto 16);
    now_symbol_id   <= dout(25 downto 20);

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (IGNORE_FRAME_ID = '1') then
                if (now_subframe_id = ref_subframe_id_sh) and (now_slot_id = ref_slot_id_sh) and (now_symbol_id = ref_symbol_id_sh) then
                    ontime_cmd(0) <= '1';
                else
                    ontime_cmd(0) <= '0';
                end if;
            else
                if (now_frame_id = ref_frame_id_sh) and (now_subframe_id = ref_subframe_id_sh) and (now_slot_id = ref_slot_id_sh) and (now_symbol_id = ref_symbol_id_sh) then
                    ontime_cmd(0) <= '1';
                else
                    ontime_cmd(0) <= '0';
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            ontime_cmd(1) <= ontime_cmd(0);
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (now_subframe_id = ref_subframe_id_sh) and (now_slot_id = ref_slot_id_sh) and (now_symbol_id = ref_symbol_id_sh) then
                IGNORE_FRAME_ID_RX <= ref_frame_id_sh;
                IGNORE_FRAME_ID_TX <= now_frame_id;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_cmd is
            when LOAD    =>
                cmd_filter_index       <= dout(3 downto 0);
                cmd_frame_id           <= dout(11 downto 4);
                cmd_subframe_id        <= dout(15 downto 12);
                cmd_slot_id            <= "00" & dout(19 downto 16);
--                cmd_symbol_id          <= "00" & dout(25 downto 20);
                cmd_ud_comp_hdr        <= dout(33 downto 26);
                cmd_section_id         <= dout(45 downto 34);
                cmd_use_every_prb      <= not dout(46);
--                cmd_start_prb          <= dout(56 downto 47);
--                cmd_num_prb            <= dout(64 downto 57);
            when others  =>
                NULL;
            end case;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Split command to maximum MTU size
--------------------------------------------------------------------------------

    -- FSM
    process (RST, CLK)
    begin
        if (RST = '1') then
            fsm_cmd <= IDLE;
        elsif (CLK'event and CLK = '1') then
            if (ontime_cmd = "01") then
                fsm_cmd <= IDLE;
            else
                case fsm_cmd is
                when IDLE    =>
                    if (ontime_cmd(0) = '1') then
                        fsm_cmd <= LOAD;
                    else
                        fsm_cmd <= IDLE;
                    end if;
                when LOAD    =>
                    fsm_cmd <= SPLIT;
                when SPLIT   =>
                    if (cnt_cmd_state = LATENCY_FIFO-1) then
                        fsm_cmd <= PACK;
                    else
                        fsm_cmd <= SPLIT;
                    end if;
                when PACK    =>
                    fsm_cmd <= SECTION;
                when SECTION =>
                    fsm_cmd <= WAITING;
                when WAITING =>
                    if (SECTION_DONE = '1') then
                        if (split_section = '1') then
                            fsm_cmd <= SPLIT;
                        elsif (more_section = '1') then
                            if (ontime_cmd(0) = '0') then
                                fsm_cmd <= IDLE;
                            else
                                fsm_cmd <= LOAD;
                            end if;
                        else
                            fsm_cmd <= IDLE;
                        end if;
                    else
                        fsm_cmd <= WAITING;
                    end if;
                when others  =>
                    fsm_cmd <= IDLE;
                end case;
            end if;
        end if;
    end process;

    -- FSM status
    process (RST, CLK)
    begin
        if (RST = '1') then
            STATUS_FSM <= "00000000";
        elsif (CLK'event and CLK = '1') then
            case fsm_cmd is
            when IDLE    =>
                STATUS_FSM <= "00000001";
            when LOAD    =>
                STATUS_FSM <= "00000100";
            when SPLIT   =>
                STATUS_FSM <= "00001000";
            when PACK    =>
                STATUS_FSM <= "00010000";
            when SECTION =>
                STATUS_FSM <= "00100000";
            when WAITING =>
                STATUS_FSM <= "01000000";
            when others  =>
                STATUS_FSM <= "10000000";
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_cmd is
            when SPLIT   =>
                if (cnt_cmd_state = LATENCY_FIFO-1) then
                    cnt_cmd_state <= (others => '0');
                else
                    cnt_cmd_state <= cnt_cmd_state + 1;
                end if;
            when others  =>
                cnt_cmd_state <= (others => '0');
            end case;
        end if;
    end process;

    -- clear FIFO data
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_cmd is
            when LOAD    =>
                rd_en <= ant_index(MAX_NUM_PORTC-1 downto 0);
            when others  =>
                rd_en <= (others => '0');
            end case;
        end if;
    end process;

    -- Initiate block when time slot is changed
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (ontime_cmd = "01") then
                INIT_SESSION <= '1';
            else
                INIT_SESSION <= '0';
            end if;
        end if;
    end process;

    -- 1 MTU interrupt
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_cmd is
            when PACK    =>
                if (more_section = '1') then
                    PACKING_TICK    <= (others => '0');
                else
                    PACKING_TICK    <= ant_index(MAX_NUM_PORTC-1 downto 0);
                end if;
            when others  =>
                PACKING_TICK    <= (others => '0');
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            DATA_DIRECTION  <= LINK_DIRECTION;
            PAYLOAD_VERSION <= "001";
            FILTER_INDEX    <= cmd_filter_index;
            FRAME_ID        <= cmd_frame_id;
            SUBFRAME_ID     <= cmd_subframe_id;
            SLOT_ID         <= cmd_slot_id;
            SYMBOL_ID       <= ref_symbol_id;
        end if;
    end process;

    -- Split 1-section to maximum PRBs
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_cmd is
            when IDLE    =>
                max_prb <= PRB_PER_MTU;
            when PACK    =>
                max_prb <= max_prb - prb_num;
            when SECTION =>
                if (max_prb = 0) then
                    max_prb <= PRB_PER_MTU;
                end if;
            when others  =>
                NULL;
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_cmd is
            when IDLE    =>
                prb_num   <= (others => '0');
            when SPLIT   =>
                if (prb_end >= max_prb) then
                    prb_num   <= max_prb;
                else
                    prb_num   <= prb_end;
                end if;
            when others  =>
                NULL;
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_cmd is
            when IDLE    =>
                prb_start <= (others => '0');
                prb_offset <= (others => '0');
                prb_end   <= (others => '0');
            when LOAD    =>
                if (dout(64 downto 57) = 0) then
                    prb_start <= (others => '0');
                    prb_offset <= (others => '0');
                    for i in MAX_NUM_PORTC-1 downto 0 loop
                    if (ref_ant_id = i) then
                        prb_end   <= PRB_PER_SYMBOL(i);
                    end if;
                    end loop;
                else
                    prb_start <= dout(56 downto 47);
                    prb_offset <= (others => '0');
                    prb_end   <= "00" & dout(64 downto 57);
                end if;
            when SECTION =>
                if (cmd_use_every_prb = '1') then
                prb_start <= prb_start + prb_num;
                    prb_offset <= prb_offset + prb_num;
                else
                    prb_start  <= prb_start + (prb_num(8 downto 0) & '0');
                    prb_offset <= prb_offset + (prb_num(8 downto 0) & '0');
                end if;
                prb_end   <= prb_end - prb_num;
            when others  =>
                NULL;
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_cmd is
            when IDLE    =>
                split_section <= '0';
            when LOAD    =>
                split_section <= '0';
            when SPLIT   =>
                if (prb_end > max_prb) then
                    split_section <= '1';
                else
                    split_section <= '0';
                end if;
            when others  =>
                NULL;
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_cmd is
            when IDLE    =>
                more_section <= '0';
            when SECTION =>
                if (max_prb = 0) then
                    more_section <= '0';
                else
                    more_section <= '1';
                end if;
            when others  =>
                NULL;
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_cmd is
            when SECTION =>
                PATH_SEL          <= ref_ant_id;
            when others  =>
                PATH_SEL          <= (others => '0');
            end case;
        end if;
    end process;

    -- 1 section interrupt
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_cmd is
            when SECTION =>
                SECTION_TICK      <= '1';
                if (max_prb = 0) or (ontime_cmd(0) = '0') then
                    SECTION_LAST      <= '1';
                end if;
                SECTION_ID        <= cmd_section_id;
                BANK_OF_PRB       <= ref_symbol_id(0 downto 0);
                USE_EVERY_PRB     <= cmd_use_every_prb;
                START_OF_PRB      <= prb_start;
                OFFSET_OF_PRB     <= prb_offset;
                NUMBER_OF_PRB     <= prb_num;
                for i in MAX_NUM_PORTC-1 downto 0 loop
                if (ref_ant_id = i) then
                    if (COMP_MODE(i) = '1') then
                        UD_COMP_HDR       <= '1' & cmd_ud_comp_hdr;
                    else
                        UD_COMP_HDR       <= '0' & IQ_WIDTH(i) & COMP_METHOD(i);
                    end if;
                end if;
                end loop;
            when others  =>
                SECTION_TICK      <= '0';
                SECTION_LAST      <= '0';
                SECTION_ID        <= (others => '0');
                BANK_OF_PRB       <= (others => '0');
                USE_EVERY_PRB     <= '0';
                START_OF_PRB      <= (others => '0');
                OFFSET_OF_PRB     <= (others => '0');
                NUMBER_OF_PRB     <= (others => '0');
                UD_COMP_HDR       <= (others => '0');
            end case;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

    CNT_ABNORMAL_TERMINATION        <= EXT(cnt_termination, 32);

    CNT_SECTION_SYMBOL0             <= cnt_section(0);
    CNT_SECTION_SYMBOL1             <= cnt_section(1);
    CNT_SECTION_SYMBOL2             <= cnt_section(2);
    CNT_SECTION_SYMBOL3             <= cnt_section(3);
    CNT_SECTION_SYMBOL4             <= cnt_section(4);
    CNT_SECTION_SYMBOL5             <= cnt_section(5);
    CNT_SECTION_SYMBOL6             <= cnt_section(6);
    CNT_SECTION_SYMBOL7             <= cnt_section(7);
    CNT_SECTION_SYMBOL8             <= (others => '0'); -- x"0000" & cnt_section(8);
    CNT_SECTION_SYMBOL9             <= (others => '0'); -- x"0000" & cnt_section(9);
    CNT_SECTION_SYMBOL10            <= (others => '0'); -- x"0000" & cnt_section(10);
    CNT_SECTION_SYMBOL11            <= (others => '0'); -- x"0000" & cnt_section(11);
    CNT_SECTION_SYMBOL12            <= (others => '0'); -- x"0000" & cnt_section(12);
    CNT_SECTION_SYMBOL13            <= (others => '0'); -- x"0000" & cnt_section(13);

    CNT_CQ_FULL_SYMBOL0             <= cnt_cq_full(0);
    CNT_CQ_FULL_SYMBOL1             <= cnt_cq_full(1);
    CNT_CQ_FULL_SYMBOL2             <= cnt_cq_full(2);
    CNT_CQ_FULL_SYMBOL3             <= cnt_cq_full(3);
    CNT_CQ_FULL_SYMBOL4             <= cnt_cq_full(4);
    CNT_CQ_FULL_SYMBOL5             <= cnt_cq_full(5);
    CNT_CQ_FULL_SYMBOL6             <= cnt_cq_full(6);
    CNT_CQ_FULL_SYMBOL7             <= cnt_cq_full(7);
    CNT_CQ_FULL_SYMBOL8             <= (others => '0'); -- x"0000" & cnt_cq_full(8);
    CNT_CQ_FULL_SYMBOL9             <= (others => '0'); -- x"0000" & cnt_cq_full(9);
    CNT_CQ_FULL_SYMBOL10            <= (others => '0'); -- x"0000" & cnt_cq_full(10);
    CNT_CQ_FULL_SYMBOL11            <= (others => '0'); -- x"0000" & cnt_cq_full(11);
    CNT_CQ_FULL_SYMBOL12            <= (others => '0'); -- x"0000" & cnt_cq_full(12);
    CNT_CQ_FULL_SYMBOL13            <= (others => '0'); -- x"0000" & cnt_cq_full(13);

    -- Abnormal termination
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (ontime_cmd = "01") then
                if (fsm_cmd = IDLE) then
                    cnt_termination <= cnt_termination;
                else
                    cnt_termination <= cnt_termination + 1;
                end if;
            end if;
        end if;
    end process;

    -- Normal operation
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            for i in MAX_NUM_PORTC-1 downto 0 loop
            if (CMD_EN(i) = '1') then
                cnt_section(i)(MAX_DEBUG_BIT-1 downto 0) <= cnt_section(i)(MAX_DEBUG_BIT-1 downto 0) + 1;
            end if;
            end loop;
        end if;
    end process;

    -- Command queue full
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            for i in MAX_NUM_PORTC-1 downto 0 loop
            if (slot_lost(i) = "01") then
                cnt_cq_full(i)(MAX_DEBUG_BIT-1 downto 0) <= cnt_cq_full(i)(MAX_DEBUG_BIT-1 downto 0) + 1;
            end if;
            end loop;
        end if;
    end process;

    u_FIFO_STATUS0  : USAGE_TO_GAUGE generic map(CMD_QUEUE_DEPTH) port map(CLK, data_count(0),  USAGE_CQ_SYMBOL0);
    u_FIFO_STATUS1  : USAGE_TO_GAUGE generic map(CMD_QUEUE_DEPTH) port map(CLK, data_count(1),  USAGE_CQ_SYMBOL1);
    u_FIFO_STATUS2  : USAGE_TO_GAUGE generic map(CMD_QUEUE_DEPTH) port map(CLK, data_count(2),  USAGE_CQ_SYMBOL2);
    u_FIFO_STATUS3  : USAGE_TO_GAUGE generic map(CMD_QUEUE_DEPTH) port map(CLK, data_count(3),  USAGE_CQ_SYMBOL3);
    u_FIFO_STATUS4  : USAGE_TO_GAUGE generic map(CMD_QUEUE_DEPTH) port map(CLK, data_count(4),  USAGE_CQ_SYMBOL4);
    u_FIFO_STATUS5  : USAGE_TO_GAUGE generic map(CMD_QUEUE_DEPTH) port map(CLK, data_count(5),  USAGE_CQ_SYMBOL5);
    u_FIFO_STATUS6  : USAGE_TO_GAUGE generic map(CMD_QUEUE_DEPTH) port map(CLK, data_count(6),  USAGE_CQ_SYMBOL6);
    u_FIFO_STATUS7  : USAGE_TO_GAUGE generic map(CMD_QUEUE_DEPTH) port map(CLK, data_count(7),  USAGE_CQ_SYMBOL7);
    USAGE_CQ_SYMBOL8  <= (others => '0');
    USAGE_CQ_SYMBOL9  <= (others => '0');
    USAGE_CQ_SYMBOL10 <= (others => '0'); 
    USAGE_CQ_SYMBOL11 <= (others => '0'); 
    USAGE_CQ_SYMBOL12 <= (others => '0'); 
    USAGE_CQ_SYMBOL13 <= (others => '0'); 

end BEHAVE;