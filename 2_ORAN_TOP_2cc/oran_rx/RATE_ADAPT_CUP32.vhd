--------------------------------------------------------------------------------
--
-- Copyright (C) 2024, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2024.03.11
--------------------------------------------------------------------------------
-- Function description
--   1. ORAN C-Plane processing component
--   2. Change byte order
--   3. Perform CDC
--   4. Perform bus conversion (64 -> 32bits)
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2024.03.11) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use WORK.PKG_ORAN_ARRAY.ALL;

entity RATE_ADAPT_CUP32 is
    generic (
        NUM_OF_URAM                 : natural := 16
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;                            -- 156.25/390.625-MHz
        RST                         : in  std_logic;                            -- SYNC@CLK

        CLK_CDC                     : in  std_logic;                            -- Slower than CLK_MAC

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

        USAGE_DATA_BUFFER           : out std_logic_vector(31 downto 0);        -- CLK

        CNT_RX                      : out std_logic_vector(31 downto 0);        -- CLK
        CNT_LOST                    : out std_logic_vector(31 downto 0);        -- CLK

--------------------------------------------------------------------------------
-- Data bus
--------------------------------------------------------------------------------

        IN_VALID                    : in  std_logic;
        IN_LAST                     : in  std_logic;
        IN_DATA                     : in  std_logic_vector(63 downto 0);
        IN_DATA_INDEX               : in  std_logic_vector(2 downto 0);
        IN_LINK_INDEX               : in  std_logic_vector(3 downto 0);

        OUT_READY                   : in  std_logic;
        OUT_VALID                   : out std_logic;
        OUT_LAST                    : out std_logic;
        OUT_DATA                    : out std_logic_vector(31 downto 0);
        OUT_DATA_INDEX              : out std_logic_vector(2 downto 0);
        OUT_LINK_INDEX              : out std_logic_vector(3 downto 0)
    );
end RATE_ADAPT_CUP32;

architecture BEHAVE of RATE_ADAPT_CUP32 is

    type std_logic_array7             is array(natural range <>) of std_logic_vector(6 downto 0);
    type std_logic_array32            is array(natural range <>) of std_logic_vector(31 downto 0);
    type std_logic_array64            is array(natural range <>) of std_logic_vector(63 downto 0);

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

    signal sreset_in_n              : std_logic;
    signal sreset_out               : std_logic;
    signal sreset_out_n             : std_logic;

    component AXIS_REG_32 is
    port (
        ACLK                        : in  std_logic;
        ARESETN                     : in  std_logic;
        S_AXIS_TVALID               : in  std_logic;
        S_AXIS_TREADY               : out std_logic;
        S_AXIS_TDATA                : in  std_logic_vector(31 downto 0);
        S_AXIS_TKEEP                : in  std_logic_vector(3 downto 0);
        S_AXIS_TLAST                : in  std_logic;
        S_AXIS_TUSER                : in  std_logic_vector(6 downto 0);
        M_AXIS_TVALID               : out std_logic;
        M_AXIS_TREADY               : in  std_logic;
        M_AXIS_TDATA                : out std_logic_vector(31 downto 0);
        M_AXIS_TKEEP                : out std_logic_vector(3 downto 0);
        M_AXIS_TLAST                : out std_logic;
        M_AXIS_TUSER                : out std_logic_vector(6 downto 0)
    );
    end component;

    component AXIS_REG_64 is
    port (
        ACLK                        : in  std_logic;
        ARESETN                     : in  std_logic;
        S_AXIS_TVALID               : in  std_logic;
        S_AXIS_TREADY               : out std_logic;
        S_AXIS_TDATA                : in  std_logic_vector(63 downto 0);
        S_AXIS_TKEEP                : in  std_logic_vector(7 downto 0);
        S_AXIS_TLAST                : in  std_logic;
        S_AXIS_TUSER                : in  std_logic_vector(6 downto 0);
        M_AXIS_TVALID               : out std_logic;
        M_AXIS_TREADY               : in  std_logic;
        M_AXIS_TDATA                : out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                : out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                : out std_logic;
        M_AXIS_TUSER                : out std_logic_vector(6 downto 0)
    );
    end component;

    component AXIS_BUFFER is
    port (
        S_AXIS_ARESETN              : in  std_logic;
        S_AXIS_ACLK                 : in  std_logic;
        S_AXIS_TVALID               : in  std_logic;
        S_AXIS_TREADY               : out std_logic;
        S_AXIS_TDATA                : in  std_logic_vector(63 downto 0);
        S_AXIS_TLAST                : in  std_logic;
        S_AXIS_TUSER                : in  std_logic_vector(6 downto 0);
        M_AXIS_TVALID               : out std_logic;
        M_AXIS_TREADY               : in  std_logic;
        M_AXIS_TDATA                : out std_logic_vector(63 downto 0);
        M_AXIS_TLAST                : out std_logic;
        M_AXIS_TUSER                : out std_logic_vector(6 downto 0);
        AXIS_WR_DATA_COUNT          : out std_logic_vector(31 downto 0);
        AXIS_RD_DATA_COUNT          : out std_logic_vector(31 downto 0);
        PROG_FULL                   : out std_logic
    );
    end component;

    signal data_fifo_en             : std_logic := '0';
    signal data_fifo_block          : std_logic := '1';
    signal packet_accepted          : std_logic := '0';
    signal packet_discarded         : std_logic := '0';

    signal data_fifo_valid          : std_logic_vector(NUM_OF_URAM downto 0);
    signal data_fifo_ready          : std_logic_vector(NUM_OF_URAM downto 0);
    signal data_fifo_data           : std_logic_array64(NUM_OF_URAM downto 0);
--    signal data_fifo_keep           : std_logic_vector(7 downto 0);
    signal data_fifo_last           : std_logic_vector(NUM_OF_URAM downto 0);
    signal data_fifo_user           : std_logic_array7(NUM_OF_URAM downto 0);
    signal data_fifo_wr_usage       : std_logic_array32(NUM_OF_URAM-1 downto 0);
    signal data_fifo_full           : std_logic_vector(NUM_OF_URAM-1 downto 0);

    signal data_reg_valid           : std_logic_vector(NUM_OF_URAM downto 0);
    signal data_reg_ready           : std_logic_vector(NUM_OF_URAM downto 0);
    signal data_reg_data            : std_logic_array64(NUM_OF_URAM downto 0);
--    signal data_reg_keep            : std_logic_vector(7 downto 0);
    signal data_reg_last            : std_logic_vector(NUM_OF_URAM downto 0);
    signal data_reg_user            : std_logic_array7(NUM_OF_URAM downto 0) := (others => (others => '0'));

    component AXIS_CLOCK_DOWN is
    port (
        S_AXIS_ARESETN              : in  std_logic;
        M_AXIS_ARESETN              : in  std_logic;
        S_AXIS_ACLK                 : in  std_logic;
        S_AXIS_TVALID               : in  std_logic;
        S_AXIS_TREADY               : out std_logic;
        S_AXIS_TDATA                : in  std_logic_vector(63 downto 0);
        S_AXIS_TKEEP                : in  std_logic_vector(7 downto 0);
        S_AXIS_TLAST                : in  std_logic;
        S_AXIS_TUSER                : in  std_logic_vector(6 downto 0);
        M_AXIS_ACLK                 : in  std_logic;
        M_AXIS_TVALID               : out std_logic;
        M_AXIS_TREADY               : in  std_logic;
        M_AXIS_TDATA                : out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                : out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                : out std_logic;
        M_AXIS_TUSER                : out std_logic_vector(6 downto 0)
    );
    end component;

    signal clock_axis_tvalid        : std_logic;
    signal clock_axis_tready        : std_logic;
    signal clock_axis_tdata         : std_logic_vector(63 downto 0);
--    signal clock_axis_tkeep         : std_logic_vector(7 downto 0);
    signal clock_axis_tlast         : std_logic;
    signal clock_axis_tuser         : std_logic_vector(6 downto 0);

    signal clock_reg_axis_tvalid    : std_logic;
    signal clock_reg_axis_tready    : std_logic;
    signal clock_reg_axis_tdata     : std_logic_vector(63 downto 0);
--    signal clock_reg_axis_tkeep     : std_logic_vector(7 downto 0);
    signal clock_reg_axis_tlast     : std_logic;
    signal clock_reg_axis_tuser     : std_logic_vector(15 downto 0) := (others => '0');

    component AXIS_WIDTH_DOWN is
    port (
        ACLK                        : in  std_logic;
        ARESETN                     : in  std_logic;
        S_AXIS_TVALID               : in  std_logic;
        S_AXIS_TREADY               : out std_logic;
        S_AXIS_TDATA                : in  std_logic_vector(63 downto 0);
        S_AXIS_TKEEP                : in  std_logic_vector(7 downto 0);
        S_AXIS_TLAST                : in  std_logic;
        S_AXIS_TUSER                : in  std_logic_vector(15 downto 0);
        M_AXIS_TVALID               : out std_logic;
        M_AXIS_TREADY               : in  std_logic;
        M_AXIS_TDATA                : out std_logic_vector(31 downto 0);
        M_AXIS_TKEEP                : out std_logic_vector(3 downto 0);
        M_AXIS_TLAST                : out std_logic;
        M_AXIS_TUSER                : out std_logic_vector(7 downto 0)
    );
    end component;

    signal width_axis_tvalid        : std_logic;
    signal width_axis_tready        : std_logic;
    signal width_axis_tdata         : std_logic_vector(31 downto 0);
--    signal width_axis_tkeep         : std_logic_vector(3 downto 0);
    signal width_axis_tlast         : std_logic;
    signal width_axis_tuser         : std_logic_vector(7 downto 0);

--    signal out_keep_rev             : std_logic_vector(3 downto 0);
    signal out_data_rev             : std_logic_vector(31 downto 0);
    signal out_user                 : std_logic_vector(6 downto 0);

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

begin

--------------------------------------------------------------------------------
-- Synchronous reset
--------------------------------------------------------------------------------

    u_RST : RST_SYNC
    generic map(
        DLY_NUM                     => 4                                       ,--: natural := 4;
        MAX_FANOUT_NUM              => 200                                      --: integer := 200
    )
    port map(
        RST_IN                      => RST                                     ,--: in  std_logic;
        CLK                         => CLK_CDC                                 ,--: in  std_logic;
        RST_OUT                     => sreset_out                               --: out std_logic
    );

    sreset_in_n                     <= not RST;
    sreset_out_n                    <= not sreset_out;

--------------------------------------------------------------------------------
-- Input
--------------------------------------------------------------------------------

    process (sreset_in_n, CLK)
    begin
        if (sreset_in_n = '0') then
            data_fifo_en <= '0';
        elsif (CLK'event and CLK = '1') then
            data_fifo_en <= IN_VALID;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (IN_VALID = '1') and (data_fifo_en = '0') then                   -- start of packet
                if (data_fifo_full(0) = '1') then
                    data_fifo_block <= '1';
                else
                    data_fifo_block <= '0';
                end if;
            end if;
        end if;
    end process;

    data_fifo_valid(0) <= data_fifo_en and (not data_fifo_block);

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            data_fifo_data(0) <= IN_DATA;
            data_fifo_last(0) <= IN_LAST;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            data_fifo_user(0)(2 downto 0) <= IN_DATA_INDEX;
            data_fifo_user(0)(6 downto 3) <= IN_LINK_INDEX;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Data buffer
--------------------------------------------------------------------------------

    u_DATA_BUFFER : for i in NUM_OF_URAM-1 downto 0 generate
    u_BUFFER : AXIS_BUFFER
    port map(
        S_AXIS_ARESETN              => sreset_in_n                             ,--: in  std_logic;
        S_AXIS_ACLK                 => CLK                                     ,--: in  std_logic;
        S_AXIS_TVALID               => data_fifo_valid(i)                      ,--: in  std_logic;
        S_AXIS_TREADY               => data_fifo_ready(i)                      ,--: out std_logic;
        S_AXIS_TDATA                => data_fifo_data(i)                       ,--: in  std_logic_vector(63 downto 0);
        S_AXIS_TLAST                => data_fifo_last(i)                       ,--: in  std_logic;
        S_AXIS_TUSER                => data_fifo_user(i)(6 downto 0)           ,--: in  std_logic_vector(6 downto 0);
        M_AXIS_TVALID               => data_reg_valid(i)                       ,--: out std_logic;
        M_AXIS_TREADY               => data_reg_ready(i)                       ,--: in  std_logic;
        M_AXIS_TDATA                => data_reg_data(i)                        ,--: out std_logic_vector(63 downto 0);
        M_AXIS_TLAST                => data_reg_last(i)                        ,--: out std_logic;
        M_AXIS_TUSER                => data_reg_user(i)(6 downto 0)            ,--: out std_logic_vector(6 downto 0);
        AXIS_WR_DATA_COUNT          => data_fifo_wr_usage(i)                   ,--: out std_logic_vector(31 downto 0);
        AXIS_RD_DATA_COUNT          => open                                    ,--: out std_logic_vector(31 downto 0);
        PROG_FULL                   => data_fifo_full(i)                        --: out std_logic
    );

    u_BUFFER_REG : AXIS_REG_64
    port map(
        ACLK                        => CLK                                     ,--: in  std_logic;
        ARESETN                     => sreset_in_n                             ,--: in  std_logic;
        S_AXIS_TVALID               => data_reg_valid(i)                       ,--: in  std_logic;
        S_AXIS_TREADY               => data_reg_ready(i)                       ,--: out std_logic;
        S_AXIS_TDATA                => data_reg_data(i)                        ,--: in  std_logic_vector(63 downto 0);
        S_AXIS_TKEEP                => (others => '1')                         ,--: in  std_logic_vector(7 downto 0);
        S_AXIS_TLAST                => data_reg_last(i)                        ,--: in  std_logic;
        S_AXIS_TUSER                => data_reg_user(i)                        ,--: in  std_logic_vector(6 downto 0);
        M_AXIS_TVALID               => data_fifo_valid(i+1)                    ,--: out std_logic;
        M_AXIS_TREADY               => data_fifo_ready(i+1)                    ,--: in  std_logic;
        M_AXIS_TDATA                => data_fifo_data(i+1)                     ,--: out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                => open                                    ,--: out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                => data_fifo_last(i+1)                     ,--: out std_logic;
        M_AXIS_TUSER                => data_fifo_user(i+1)                      --: out std_logic_vector(6 downto 0)
    );
    end generate;

--------------------------------------------------------------------------------
-- Clock down
--------------------------------------------------------------------------------

    u_CLOCK : AXIS_CLOCK_DOWN
    port map(
        S_AXIS_ARESETN              => sreset_in_n                             ,--: in  std_logic;
        M_AXIS_ARESETN              => sreset_out_n                            ,--: in  std_logic;
        S_AXIS_ACLK                 => CLK                                     ,--: in  std_logic;
        S_AXIS_TVALID               => data_fifo_valid(NUM_OF_URAM)            ,--: in  std_logic;
        S_AXIS_TREADY               => data_fifo_ready(NUM_OF_URAM)            ,--: out std_logic;
        S_AXIS_TDATA                => data_fifo_data(NUM_OF_URAM)             ,--: in  std_logic_vector(63 downto 0);
        S_AXIS_TKEEP                => (others => '1')                         ,--: in  std_logic_vector(7 downto 0);
        S_AXIS_TLAST                => data_fifo_last(NUM_OF_URAM)             ,--: in  std_logic;
        S_AXIS_TUSER                => data_fifo_user(NUM_OF_URAM)             ,--: in  std_logic_vector(6 downto 0);
        M_AXIS_ACLK                 => CLK_CDC                                 ,--: in  std_logic;
        M_AXIS_TVALID               => clock_axis_tvalid                       ,--: out std_logic;
        M_AXIS_TREADY               => clock_axis_tready                       ,--: in  std_logic;
        M_AXIS_TDATA                => clock_axis_tdata                        ,--: out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                => open                                    ,--: out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                => clock_axis_tlast                        ,--: out std_logic;
        M_AXIS_TUSER                => clock_axis_tuser                         --: out std_logic_vector(6 downto 0)
    );

    u_CLOCK_REG : AXIS_REG_64
    port map(
        ACLK                        => CLK_CDC                                 ,--: in  std_logic;
        ARESETN                     => sreset_out_n                            ,--: in  std_logic;
        S_AXIS_TVALID               => clock_axis_tvalid                       ,--: in  std_logic;
        S_AXIS_TREADY               => clock_axis_tready                       ,--: out std_logic;
        S_AXIS_TDATA                => clock_axis_tdata                        ,--: in  std_logic_vector(63 downto 0);
        S_AXIS_TKEEP                => (others => '1')                         ,--: in  std_logic_vector(7 downto 0);
        S_AXIS_TLAST                => clock_axis_tlast                        ,--: in  std_logic;
        S_AXIS_TUSER                => clock_axis_tuser                        ,--: in  std_logic_vector(6 downto 0);
        M_AXIS_TVALID               => clock_reg_axis_tvalid                   ,--: out std_logic;
        M_AXIS_TREADY               => clock_reg_axis_tready                   ,--: in  std_logic;
        M_AXIS_TDATA                => clock_reg_axis_tdata                    ,--: out std_logic_vector(63 downto 0);
        M_AXIS_TKEEP                => open                                    ,--: out std_logic_vector(7 downto 0);
        M_AXIS_TLAST                => clock_reg_axis_tlast                    ,--: out std_logic;
        M_AXIS_TUSER                => clock_reg_axis_tuser(6 downto 0)         --: out std_logic_vector(6 downto 0)
    );

    clock_reg_axis_tuser(14 downto 8) <= clock_reg_axis_tuser(6 downto 0);

--------------------------------------------------------------------------------
-- Width down and output
--------------------------------------------------------------------------------

    u_WIDTH : AXIS_WIDTH_DOWN
    port map(
        ACLK                        => CLK_CDC                                 ,--: in  std_logic;
        ARESETN                     => sreset_out_n                            ,--: in  std_logic;
        S_AXIS_TVALID               => clock_reg_axis_tvalid                   ,--: in  std_logic;
        S_AXIS_TREADY               => clock_reg_axis_tready                   ,--: out std_logic;
        S_AXIS_TDATA                => clock_reg_axis_tdata                    ,--: in  std_logic_vector(63 downto 0);
        S_AXIS_TKEEP                => (others => '1')                         ,--: in  std_logic_vector(7 downto 0);
        S_AXIS_TLAST                => clock_reg_axis_tlast                    ,--: in  std_logic;
        S_AXIS_TUSER                => clock_reg_axis_tuser                    ,--: in  std_logic_vector(15 downto 0);
        M_AXIS_TVALID               => width_axis_tvalid                       ,--: out std_logic;
        M_AXIS_TREADY               => width_axis_tready                       ,--: in  std_logic;
        M_AXIS_TDATA                => width_axis_tdata                        ,--: out std_logic_vector(31 downto 0);
        M_AXIS_TKEEP                => open                                    ,--: out std_logic_vector(3 downto 0);
        M_AXIS_TLAST                => width_axis_tlast                        ,--: out std_logic;
        M_AXIS_TUSER                => width_axis_tuser                         --: out std_logic_vector(7 downto 0)
    );

    u_WIDTH_REG : AXIS_REG_32
    port map(
        ACLK                        => CLK_CDC                                 ,--: in  std_logic;
        ARESETN                     => sreset_out_n                            ,--: in  std_logic;
        S_AXIS_TVALID               => width_axis_tvalid                       ,--: in  std_logic;
        S_AXIS_TREADY               => width_axis_tready                       ,--: out std_logic;
        S_AXIS_TDATA                => width_axis_tdata                        ,--: in  std_logic_vector(31 downto 0);
        S_AXIS_TKEEP                => (others => '1')                         ,--: in  std_logic_vector(3 downto 0);
        S_AXIS_TLAST                => width_axis_tlast                        ,--: in  std_logic;
        S_AXIS_TUSER                => width_axis_tuser(6 downto 0)            ,--: in  std_logic_vector(6 downto 0);
        M_AXIS_TVALID               => OUT_VALID                               ,--: out std_logic;
        M_AXIS_TREADY               => OUT_READY                               ,--: in  std_logic;
        M_AXIS_TDATA                => out_data_rev                            ,--: out std_logic_vector(31 downto 0);
        M_AXIS_TKEEP                => open                                    ,--: out std_logic_vector(3 downto 0);
        M_AXIS_TLAST                => OUT_LAST                                ,--: out std_logic;
        M_AXIS_TUSER                => out_user                                 --: out std_logic_vector(6 downto 0)
    );

    OUT_DATA(31 downto 24)          <= out_data_rev(7 downto 0);
    OUT_DATA(23 downto 16)          <= out_data_rev(15 downto 8);
    OUT_DATA(15 downto 8)           <= out_data_rev(23 downto 16);
    OUT_DATA(7 downto 0)            <= out_data_rev(31 downto 24);
    OUT_DATA_INDEX                  <= out_user(2 downto 0);
    OUT_LINK_INDEX                  <= out_user(6 downto 3);

--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

    packet_accepted                 <= data_fifo_en and (not data_fifo_block);
    packet_discarded                <= data_fifo_en and data_fifo_block;

    u_DATA_BUFFER_STATUS : USAGE_TO_GAUGE generic map(4096) port map(CLK, data_fifo_wr_usage(0), USAGE_DATA_BUFFER);

    u_CNT_RX   : CNT_UNIT_EDGE generic map('1', MAX_DEBUG_BIT) port map(CLK, packet_accepted, CNT_RX);
    u_CNT_LOST : CNT_UNIT_EDGE generic map('1', MAX_DEBUG_BIT) port map(CLK, packet_discarded, CNT_LOST);

end BEHAVE;