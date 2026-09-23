--------------------------------------------------------------------------------
--
-- Copyright (C) 2024, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2024.03.11
--------------------------------------------------------------------------------
-- Function description
--   1. ORAN interconnect component
--   2. TX switch
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2024.03.11) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use WORK.ARRAY_TYPE.ALL;
use WORK.PKG_ORAN_ARRAY.ALL;

entity PKT_BUFFER is
    generic (
        NUM_OF_URAM                 : natural := 1
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;                            -- 390.625-MHz
        RST                         : in  std_logic;                            -- SYNC@CLK

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

        USAGE_DATA_BUFFER           : out std_logic_vector(31 downto 0);        -- CLK

        CNT_TX                      : out std_logic_vector(31 downto 0);        -- CLK
        CNT_LOST                    : out std_logic_vector(31 downto 0);        -- CLK

--------------------------------------------------------------------------------
-- Input
--------------------------------------------------------------------------------

        IN_VALID                    : in  std_logic;
        IN_LAST                     : in  std_logic;
        IN_DEST                     : in  std_logic_vector(2 downto 0);
        IN_KEEP                     : in  std_logic_vector(7 downto 0);
        IN_DATA                     : in  std_logic_vector(63 downto 0);

--------------------------------------------------------------------------------
-- Output
--------------------------------------------------------------------------------

        OUT0_READY                  : in  std_logic;
        OUT0_VALID                  : out std_logic;
        OUT0_LAST                   : out std_logic;
        OUT0_KEEP                   : out std_logic_vector(7 downto 0);
        OUT0_DATA                   : out std_logic_vector(63 downto 0)
    );
end PKT_BUFFER;

architecture BEHAVE of PKT_BUFFER is

    signal sreset_n                 : std_logic;

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

    signal packet_accepted          : std_logic := '0';
    signal packet_discarded         : std_logic := '0';

    signal data_fifo_valid          : std_logic_vector(NUM_OF_URAM downto 0);
    signal data_fifo_ready          : std_logic_vector(NUM_OF_URAM downto 0);
    signal data_fifo_data           : std_logic_array64(NUM_OF_URAM downto 0);
    signal data_fifo_last           : std_logic_vector(NUM_OF_URAM downto 0);
    signal data_fifo_user           : std_logic_array7(NUM_OF_URAM downto 0);
    signal data_fifo_wr_usage       : std_logic_array32(NUM_OF_URAM-1 downto 0);

    signal data_reg_valid           : std_logic_vector(NUM_OF_URAM downto 0);
    signal data_reg_ready           : std_logic_vector(NUM_OF_URAM downto 0);
    signal data_reg_data            : std_logic_array64(NUM_OF_URAM downto 0);
--    signal data_reg_keep            : std_logic_vector(7 downto 0);
    signal data_reg_last            : std_logic_vector(NUM_OF_URAM downto 0);
    signal data_reg_user            : std_logic_array7(NUM_OF_URAM downto 0) := (others => (others => '0'));

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

    sreset_n                        <= not RST;

--------------------------------------------------------------------------------
-- Input registering
--------------------------------------------------------------------------------

    process (sreset_n, CLK)
    begin
        if (sreset_n = '0') then
            data_fifo_valid(0) <= '0';
        elsif (CLK'event and CLK = '1') then
            data_fifo_valid(0) <= IN_VALID;
        end if;
    end process;

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
            case IN_KEEP is
            when x"7F"  => data_fifo_user(0)(2 downto 0) <= "111";
            when x"3F"  => data_fifo_user(0)(2 downto 0) <= "110";
            when x"1F"  => data_fifo_user(0)(2 downto 0) <= "101";
            when x"0F"  => data_fifo_user(0)(2 downto 0) <= "100";
            when x"07"  => data_fifo_user(0)(2 downto 0) <= "011";
            when x"03"  => data_fifo_user(0)(2 downto 0) <= "010";
            when x"01"  => data_fifo_user(0)(2 downto 0) <= "001";
            when others => data_fifo_user(0)(2 downto 0) <= "000";
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            data_fifo_user(0)(6 downto 3) <= '0' & IN_DEST;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Data buffer
--------------------------------------------------------------------------------

    u_DATA_BUFFER : for i in NUM_OF_URAM-1 downto 0 generate
    u_BUFFER : AXIS_BUFFER
    port map(
        S_AXIS_ARESETN              => sreset_n                                ,--: in  std_logic;
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
        PROG_FULL                   => open                                     --: out std_logic
    );

    u_BUFFER_REG : AXIS_REG_64
    port map(
        ACLK                        => CLK                                     ,--: in  std_logic;
        ARESETN                     => sreset_n                                ,--: in  std_logic;
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
-- Route and output
--------------------------------------------------------------------------------

    data_fifo_ready(NUM_OF_URAM)    <= OUT0_READY;

    OUT0_VALID                      <= data_fifo_valid(NUM_OF_URAM);
    OUT0_LAST                       <= data_fifo_last(NUM_OF_URAM);
    OUT0_KEEP(7 downto 0)           <= x"7F" when data_fifo_user(NUM_OF_URAM)(2 downto 0) = "111" else
                                       x"3F" when data_fifo_user(NUM_OF_URAM)(2 downto 0) = "110" else
                                       x"1F" when data_fifo_user(NUM_OF_URAM)(2 downto 0) = "101" else
                                       x"0F" when data_fifo_user(NUM_OF_URAM)(2 downto 0) = "100" else
                                       x"07" when data_fifo_user(NUM_OF_URAM)(2 downto 0) = "011" else
                                       x"03" when data_fifo_user(NUM_OF_URAM)(2 downto 0) = "010" else
                                       x"01" when data_fifo_user(NUM_OF_URAM)(2 downto 0) = "001" else
                                       x"FF";
    OUT0_DATA                       <= data_fifo_data(NUM_OF_URAM);

--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

    packet_accepted                 <= data_fifo_valid(0) and data_fifo_last(0);
    packet_discarded                <= data_fifo_valid(0) and (not data_fifo_ready(0));

    u_DATA_BUFFER_STATUS : USAGE_TO_GAUGE generic map(4096) port map(CLK, data_fifo_wr_usage(0), USAGE_DATA_BUFFER);

    u_CNT_RX   : CNT_UNIT_EDGE generic map('1', MAX_DEBUG_BIT) port map(CLK, packet_accepted, CNT_TX);
    u_CNT_LOST : CNT_UNIT_EDGE generic map('1', MAX_DEBUG_BIT) port map(CLK, packet_discarded, CNT_LOST);

end BEHAVE;