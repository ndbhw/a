--------------------------------------------------------------------------------
--
-- Copyright (C) 2022, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2022.02.16
--------------------------------------------------------------------------------
-- Function description
--   1. Performance measurement component
--   2. TX monitoring
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2022.02.16) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity TX_STAT is
    generic (
        NUM_TX                      : natural := 6
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK_CPUIF                   : in  std_logic;
        RST_CPUIF                   : in  std_logic;

        CLK_245p76MHz               : in  std_logic;                            -- 245.76-MHz

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------

        WINDOW_PERIOD               : in  std_logic_vector(7 downto 0);

--------------------------------------------------------------------------------
-- Synchronization
--------------------------------------------------------------------------------

        REF_10msec                  : in  std_logic;                            -- Longer than 1-clocks@245.76-MHz

--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

        CNT_CLEAR                   : in  std_logic;

        CNT_TOTAL                   : out std_logic_vector(63 downto 0);

--------------------------------------------------------------------------------
-- Packet stamp
--------------------------------------------------------------------------------

        CLK_PACKET                  : in  std_logic;

        PACKET_EN                   : in  std_logic_vector(NUM_TX-1 downto 0)
    );
end TX_STAT;

architecture BEHAVE of TX_STAT is

    constant PORT_WIDTH             : natural := NUM_TX;

    signal update_long_pulse        : std_logic_vector(15 downto 0) := (others => '0');
    signal update_buf               : std_logic_vector(2 downto 0) := (others => '0');
    signal update_cnt_sec           : std_logic_vector(6 downto 0) := (others => '0');
    signal update_cnt               : std_logic_vector(7 downto 0) := (others => '0');
    signal update_en                : std_logic := '0';

    signal cnt_detect_0             : std_logic_vector(63 downto 0) := (others => '0');
    signal cnt_detect_1             : std_logic_vector(63 downto 0) := (others => '0');
    signal cnt_detect_2             : std_logic_vector(63 downto 0) := (others => '0');

    component TIMESTAMP is
    generic (
        FIFO_WIDTH                  : natural := 16
    );
    port (
        RST                         : in  std_logic;
        WR_CLK                      : in  std_logic;
        RD_CLK                      : in  std_logic;
        DIN                         : in  std_logic_vector(FIFO_WIDTH-1 downto 0);
        WR_EN                       : in  std_logic;
        RD_EN                       : in  std_logic;
        DOUT                        : out std_logic_vector(FIFO_WIDTH-1 downto 0);
        FULL                        : out std_logic;
        EMPTY                       : out std_logic;
        WR_DATA_COUNT               : out std_logic_vector(3 downto 0)
    );
    end component;

    signal din                      : std_logic_vector(PORT_WIDTH-1 downto 0);
    signal wr_en                    : std_logic;
    signal rd_en                    : std_logic;
    signal dout                     : std_logic_vector(PORT_WIDTH-1 downto 0);
    signal full                     : std_logic;
    signal empty                    : std_logic;

    signal check                    : std_logic := '0';
    signal packet_flag              : std_logic_vector(23 downto 0);

begin

--------------------------------------------------------------------------------
-- Update counters per its period
--------------------------------------------------------------------------------

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (REF_10msec = '1') then
                update_long_pulse <= (others => '1');
            else
                update_long_pulse <= update_long_pulse(14 downto 0) & '0';
            end if;
        end if;
    end process;

    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            update_buf <= update_buf(1 downto 0) & update_long_pulse(15);
        end if;
    end process;

    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            if (update_buf(2 downto 1) = "01") then
                if (update_cnt_sec = 99) then
                    update_cnt_sec <= (others => '0');
                else
                    update_cnt_sec <= update_cnt_sec + 1;
                end if;
            end if;
        end if;
    end process;

    process (RST_CPUIF, CLK_CPUIF)
    begin
        if (RST_CPUIF = '1') then
            update_cnt <= (others => '0');
        elsif (CLK_CPUIF'event and CLK_CPUIF = '1') then
            if (update_buf(2 downto 1) = "01") and (update_cnt_sec = 99) then
                if (update_cnt = WINDOW_PERIOD) then
                    update_cnt <= (others => '0');
                else
                    update_cnt <= update_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            if (update_buf(2 downto 1) = "01") and (update_cnt_sec = 99) and (update_cnt = WINDOW_PERIOD) then
                update_en <= '1';
            else
                update_en <= '0';
            end if;
        end if;
    end process;

    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            if (update_en = '1') then
                CNT_TOTAL <= cnt_detect_0 + cnt_detect_1 + cnt_detect_2;
            elsif (CNT_CLEAR = '1') then
                CNT_TOTAL <= (others => '0');
            end if;
        end if;
    end process;

    process (CLK_PACKET)
    begin
        if (CLK_PACKET'event and CLK_PACKET = '1') then
            din <= PACKET_EN;
        end if;
    end process;

    process (CLK_PACKET)
    begin
        if (CLK_PACKET'event and CLK_PACKET = '1') then
            if (PACKET_EN /= 0) then
                wr_en <= not full;
            else
                wr_en <= '0';
            end if;
        end if;
    end process;

    u_TIMESTAMP : TIMESTAMP
    generic map(
        FIFO_WIDTH                  => PORT_WIDTH                               --: natural := 16
    )
    port map(
        RST                         => RST_CPUIF                               ,--: in  std_logic;
        WR_CLK                      => CLK_PACKET                              ,--: in  std_logic;
        RD_CLK                      => CLK_CPUIF                               ,--: in  std_logic;
        DIN                         => din                                     ,--: in  std_logic_vector(FIFO_WIDTH-1 downto 0);
        WR_EN                       => wr_en                                   ,--: in  std_logic;
        RD_EN                       => rd_en                                   ,--: in  std_logic;
        DOUT                        => dout                                    ,--: out std_logic_vector(FIFO_WIDTH-1 downto 0);
        FULL                        => full                                    ,--: out std_logic;
        EMPTY                       => empty                                   ,--: out std_logic;
        WR_DATA_COUNT               => open                                     --: out std_logic_vector(3 downto 0)
    );

    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            rd_en <= not empty;
        end if;
    end process;

    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            check <= rd_en and (not empty);
        end if;
    end process;

    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            packet_flag <= EXT(dout, 24);
        end if;
    end process;

    u_TOTAL_TX_is_up_to_8 : if NUM_TX > 0 generate
    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            if (update_en = '1') then
                if (check = '1') then
                    case packet_flag(7 downto 0) is
                    when "00000000" => cnt_detect_0 <= x"0000000000000000" + 0 + 0;
                    when "00000001" => cnt_detect_0 <= x"0000000000000000" + 1 + 0;
                    when "00000010" => cnt_detect_0 <= x"0000000000000000" + 1 + 0;
                    when "00000011" => cnt_detect_0 <= x"0000000000000000" + 2 + 0;
                    when "00000100" => cnt_detect_0 <= x"0000000000000000" + 1 + 0;
                    when "00000101" => cnt_detect_0 <= x"0000000000000000" + 2 + 0;
                    when "00000110" => cnt_detect_0 <= x"0000000000000000" + 2 + 0;
                    when "00000111" => cnt_detect_0 <= x"0000000000000000" + 3 + 0;
                    when "00001000" => cnt_detect_0 <= x"0000000000000000" + 1 + 0;
                    when "00001001" => cnt_detect_0 <= x"0000000000000000" + 2 + 0;
                    when "00001010" => cnt_detect_0 <= x"0000000000000000" + 2 + 0;
                    when "00001011" => cnt_detect_0 <= x"0000000000000000" + 3 + 0;
                    when "00001100" => cnt_detect_0 <= x"0000000000000000" + 2 + 0;
                    when "00001101" => cnt_detect_0 <= x"0000000000000000" + 3 + 0;
                    when "00001110" => cnt_detect_0 <= x"0000000000000000" + 3 + 0;
                    when "00001111" => cnt_detect_0 <= x"0000000000000000" + 4 + 0;

                    when "00010000" => cnt_detect_0 <= x"0000000000000000" + 0 + 1;
                    when "00010001" => cnt_detect_0 <= x"0000000000000000" + 1 + 1;
                    when "00010010" => cnt_detect_0 <= x"0000000000000000" + 1 + 1;
                    when "00010011" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "00010100" => cnt_detect_0 <= x"0000000000000000" + 1 + 1;
                    when "00010101" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "00010110" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "00010111" => cnt_detect_0 <= x"0000000000000000" + 3 + 1;
                    when "00011000" => cnt_detect_0 <= x"0000000000000000" + 1 + 1;
                    when "00011001" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "00011010" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "00011011" => cnt_detect_0 <= x"0000000000000000" + 3 + 1;
                    when "00011100" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "00011101" => cnt_detect_0 <= x"0000000000000000" + 3 + 1;
                    when "00011110" => cnt_detect_0 <= x"0000000000000000" + 3 + 1;
                    when "00011111" => cnt_detect_0 <= x"0000000000000000" + 4 + 1;

                    when "00100000" => cnt_detect_0 <= x"0000000000000000" + 0 + 1;
                    when "00100001" => cnt_detect_0 <= x"0000000000000000" + 1 + 1;
                    when "00100010" => cnt_detect_0 <= x"0000000000000000" + 1 + 1;
                    when "00100011" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "00100100" => cnt_detect_0 <= x"0000000000000000" + 1 + 1;
                    when "00100101" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "00100110" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "00100111" => cnt_detect_0 <= x"0000000000000000" + 3 + 1;
                    when "00101000" => cnt_detect_0 <= x"0000000000000000" + 1 + 1;
                    when "00101001" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "00101010" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "00101011" => cnt_detect_0 <= x"0000000000000000" + 3 + 1;
                    when "00101100" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "00101101" => cnt_detect_0 <= x"0000000000000000" + 3 + 1;
                    when "00101110" => cnt_detect_0 <= x"0000000000000000" + 3 + 1;
                    when "00101111" => cnt_detect_0 <= x"0000000000000000" + 4 + 1;

                    when "00110000" => cnt_detect_0 <= x"0000000000000000" + 0 + 2;
                    when "00110001" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "00110010" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "00110011" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "00110100" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "00110101" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "00110110" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "00110111" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "00111000" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "00111001" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "00111010" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "00111011" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "00111100" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "00111101" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "00111110" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "00111111" => cnt_detect_0 <= x"0000000000000000" + 4 + 2;

                    when "01000000" => cnt_detect_0 <= x"0000000000000000" + 0 + 1;
                    when "01000001" => cnt_detect_0 <= x"0000000000000000" + 1 + 1;
                    when "01000010" => cnt_detect_0 <= x"0000000000000000" + 1 + 1;
                    when "01000011" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "01000100" => cnt_detect_0 <= x"0000000000000000" + 1 + 1;
                    when "01000101" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "01000110" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "01000111" => cnt_detect_0 <= x"0000000000000000" + 3 + 1;
                    when "01001000" => cnt_detect_0 <= x"0000000000000000" + 1 + 1;
                    when "01001001" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "01001010" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "01001011" => cnt_detect_0 <= x"0000000000000000" + 3 + 1;
                    when "01001100" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "01001101" => cnt_detect_0 <= x"0000000000000000" + 3 + 1;
                    when "01001110" => cnt_detect_0 <= x"0000000000000000" + 3 + 1;
                    when "01001111" => cnt_detect_0 <= x"0000000000000000" + 4 + 1;

                    when "01010000" => cnt_detect_0 <= x"0000000000000000" + 0 + 2;
                    when "01010001" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "01010010" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "01010011" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "01010100" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "01010101" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "01010110" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "01010111" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "01011000" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "01011001" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "01011010" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "01011011" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "01011100" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "01011101" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "01011110" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "01011111" => cnt_detect_0 <= x"0000000000000000" + 4 + 2;

                    when "01100000" => cnt_detect_0 <= x"0000000000000000" + 0 + 2;
                    when "01100001" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "01100010" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "01100011" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "01100100" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "01100101" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "01100110" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "01100111" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "01101000" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "01101001" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "01101010" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "01101011" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "01101100" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "01101101" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "01101110" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "01101111" => cnt_detect_0 <= x"0000000000000000" + 4 + 2;

                    when "01110000" => cnt_detect_0 <= x"0000000000000000" + 0 + 3;
                    when "01110001" => cnt_detect_0 <= x"0000000000000000" + 1 + 3;
                    when "01110010" => cnt_detect_0 <= x"0000000000000000" + 1 + 3;
                    when "01110011" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "01110100" => cnt_detect_0 <= x"0000000000000000" + 1 + 3;
                    when "01110101" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "01110110" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "01110111" => cnt_detect_0 <= x"0000000000000000" + 3 + 3;
                    when "01111000" => cnt_detect_0 <= x"0000000000000000" + 1 + 3;
                    when "01111001" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "01111010" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "01111011" => cnt_detect_0 <= x"0000000000000000" + 3 + 3;
                    when "01111100" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "01111101" => cnt_detect_0 <= x"0000000000000000" + 3 + 3;
                    when "01111110" => cnt_detect_0 <= x"0000000000000000" + 3 + 3;
                    when "01111111" => cnt_detect_0 <= x"0000000000000000" + 4 + 3;

                    when "10000000" => cnt_detect_0 <= x"0000000000000000" + 0 + 1;
                    when "10000001" => cnt_detect_0 <= x"0000000000000000" + 1 + 1;
                    when "10000010" => cnt_detect_0 <= x"0000000000000000" + 1 + 1;
                    when "10000011" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "10000100" => cnt_detect_0 <= x"0000000000000000" + 1 + 1;
                    when "10000101" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "10000110" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "10000111" => cnt_detect_0 <= x"0000000000000000" + 3 + 1;
                    when "10001000" => cnt_detect_0 <= x"0000000000000000" + 1 + 1;
                    when "10001001" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "10001010" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "10001011" => cnt_detect_0 <= x"0000000000000000" + 3 + 1;
                    when "10001100" => cnt_detect_0 <= x"0000000000000000" + 2 + 1;
                    when "10001101" => cnt_detect_0 <= x"0000000000000000" + 3 + 1;
                    when "10001110" => cnt_detect_0 <= x"0000000000000000" + 3 + 1;
                    when "10001111" => cnt_detect_0 <= x"0000000000000000" + 4 + 1;

                    when "10010000" => cnt_detect_0 <= x"0000000000000000" + 0 + 2;
                    when "10010001" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "10010010" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "10010011" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "10010100" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "10010101" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "10010110" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "10010111" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "10011000" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "10011001" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "10011010" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "10011011" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "10011100" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "10011101" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "10011110" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "10011111" => cnt_detect_0 <= x"0000000000000000" + 4 + 2;

                    when "10100000" => cnt_detect_0 <= x"0000000000000000" + 0 + 2;
                    when "10100001" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "10100010" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "10100011" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "10100100" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "10100101" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "10100110" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "10100111" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "10101000" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "10101001" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "10101010" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "10101011" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "10101100" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "10101101" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "10101110" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "10101111" => cnt_detect_0 <= x"0000000000000000" + 4 + 2;

                    when "10110000" => cnt_detect_0 <= x"0000000000000000" + 0 + 3;
                    when "10110001" => cnt_detect_0 <= x"0000000000000000" + 1 + 3;
                    when "10110010" => cnt_detect_0 <= x"0000000000000000" + 1 + 3;
                    when "10110011" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "10110100" => cnt_detect_0 <= x"0000000000000000" + 1 + 3;
                    when "10110101" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "10110110" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "10110111" => cnt_detect_0 <= x"0000000000000000" + 3 + 3;
                    when "10111000" => cnt_detect_0 <= x"0000000000000000" + 1 + 3;
                    when "10111001" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "10111010" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "10111011" => cnt_detect_0 <= x"0000000000000000" + 3 + 3;
                    when "10111100" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "10111101" => cnt_detect_0 <= x"0000000000000000" + 3 + 3;
                    when "10111110" => cnt_detect_0 <= x"0000000000000000" + 3 + 3;
                    when "10111111" => cnt_detect_0 <= x"0000000000000000" + 4 + 3;

                    when "11000000" => cnt_detect_0 <= x"0000000000000000" + 0 + 2;
                    when "11000001" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "11000010" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "11000011" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "11000100" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "11000101" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "11000110" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "11000111" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "11001000" => cnt_detect_0 <= x"0000000000000000" + 1 + 2;
                    when "11001001" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "11001010" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "11001011" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "11001100" => cnt_detect_0 <= x"0000000000000000" + 2 + 2;
                    when "11001101" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "11001110" => cnt_detect_0 <= x"0000000000000000" + 3 + 2;
                    when "11001111" => cnt_detect_0 <= x"0000000000000000" + 4 + 2;

                    when "11010000" => cnt_detect_0 <= x"0000000000000000" + 0 + 3;
                    when "11010001" => cnt_detect_0 <= x"0000000000000000" + 1 + 3;
                    when "11010010" => cnt_detect_0 <= x"0000000000000000" + 1 + 3;
                    when "11010011" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "11010100" => cnt_detect_0 <= x"0000000000000000" + 1 + 3;
                    when "11010101" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "11010110" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "11010111" => cnt_detect_0 <= x"0000000000000000" + 3 + 3;
                    when "11011000" => cnt_detect_0 <= x"0000000000000000" + 1 + 3;
                    when "11011001" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "11011010" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "11011011" => cnt_detect_0 <= x"0000000000000000" + 3 + 3;
                    when "11011100" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "11011101" => cnt_detect_0 <= x"0000000000000000" + 3 + 3;
                    when "11011110" => cnt_detect_0 <= x"0000000000000000" + 3 + 3;
                    when "11011111" => cnt_detect_0 <= x"0000000000000000" + 4 + 3;

                    when "11100000" => cnt_detect_0 <= x"0000000000000000" + 0 + 3;
                    when "11100001" => cnt_detect_0 <= x"0000000000000000" + 1 + 3;
                    when "11100010" => cnt_detect_0 <= x"0000000000000000" + 1 + 3;
                    when "11100011" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "11100100" => cnt_detect_0 <= x"0000000000000000" + 1 + 3;
                    when "11100101" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "11100110" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "11100111" => cnt_detect_0 <= x"0000000000000000" + 3 + 3;
                    when "11101000" => cnt_detect_0 <= x"0000000000000000" + 1 + 3;
                    when "11101001" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "11101010" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "11101011" => cnt_detect_0 <= x"0000000000000000" + 3 + 3;
                    when "11101100" => cnt_detect_0 <= x"0000000000000000" + 2 + 3;
                    when "11101101" => cnt_detect_0 <= x"0000000000000000" + 3 + 3;
                    when "11101110" => cnt_detect_0 <= x"0000000000000000" + 3 + 3;
                    when "11101111" => cnt_detect_0 <= x"0000000000000000" + 4 + 3;

                    when "11110000" => cnt_detect_0 <= x"0000000000000000" + 0 + 4;
                    when "11110001" => cnt_detect_0 <= x"0000000000000000" + 1 + 4;
                    when "11110010" => cnt_detect_0 <= x"0000000000000000" + 1 + 4;
                    when "11110011" => cnt_detect_0 <= x"0000000000000000" + 2 + 4;
                    when "11110100" => cnt_detect_0 <= x"0000000000000000" + 1 + 4;
                    when "11110101" => cnt_detect_0 <= x"0000000000000000" + 2 + 4;
                    when "11110110" => cnt_detect_0 <= x"0000000000000000" + 2 + 4;
                    when "11110111" => cnt_detect_0 <= x"0000000000000000" + 3 + 4;
                    when "11111000" => cnt_detect_0 <= x"0000000000000000" + 1 + 4;
                    when "11111001" => cnt_detect_0 <= x"0000000000000000" + 2 + 4;
                    when "11111010" => cnt_detect_0 <= x"0000000000000000" + 2 + 4;
                    when "11111011" => cnt_detect_0 <= x"0000000000000000" + 3 + 4;
                    when "11111100" => cnt_detect_0 <= x"0000000000000000" + 2 + 4;
                    when "11111101" => cnt_detect_0 <= x"0000000000000000" + 3 + 4;
                    when "11111110" => cnt_detect_0 <= x"0000000000000000" + 3 + 4;
                    when "11111111" => cnt_detect_0 <= x"0000000000000000" + 4 + 4;

                    when others     => cnt_detect_0 <= x"0000000000000000" + 0;
                    end case;
                else
                    cnt_detect_0 <= (others => '0');
                end if;
            else
                if (check = '1') then
                    case packet_flag(7 downto 0) is
                    when "00000000" => cnt_detect_0 <= cnt_detect_0 + 0 + 0;
                    when "00000001" => cnt_detect_0 <= cnt_detect_0 + 1 + 0;
                    when "00000010" => cnt_detect_0 <= cnt_detect_0 + 1 + 0;
                    when "00000011" => cnt_detect_0 <= cnt_detect_0 + 2 + 0;
                    when "00000100" => cnt_detect_0 <= cnt_detect_0 + 1 + 0;
                    when "00000101" => cnt_detect_0 <= cnt_detect_0 + 2 + 0;
                    when "00000110" => cnt_detect_0 <= cnt_detect_0 + 2 + 0;
                    when "00000111" => cnt_detect_0 <= cnt_detect_0 + 3 + 0;
                    when "00001000" => cnt_detect_0 <= cnt_detect_0 + 1 + 0;
                    when "00001001" => cnt_detect_0 <= cnt_detect_0 + 2 + 0;
                    when "00001010" => cnt_detect_0 <= cnt_detect_0 + 2 + 0;
                    when "00001011" => cnt_detect_0 <= cnt_detect_0 + 3 + 0;
                    when "00001100" => cnt_detect_0 <= cnt_detect_0 + 2 + 0;
                    when "00001101" => cnt_detect_0 <= cnt_detect_0 + 3 + 0;
                    when "00001110" => cnt_detect_0 <= cnt_detect_0 + 3 + 0;
                    when "00001111" => cnt_detect_0 <= cnt_detect_0 + 4 + 0;

                    when "00010000" => cnt_detect_0 <= cnt_detect_0 + 0 + 1;
                    when "00010001" => cnt_detect_0 <= cnt_detect_0 + 1 + 1;
                    when "00010010" => cnt_detect_0 <= cnt_detect_0 + 1 + 1;
                    when "00010011" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "00010100" => cnt_detect_0 <= cnt_detect_0 + 1 + 1;
                    when "00010101" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "00010110" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "00010111" => cnt_detect_0 <= cnt_detect_0 + 3 + 1;
                    when "00011000" => cnt_detect_0 <= cnt_detect_0 + 1 + 1;
                    when "00011001" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "00011010" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "00011011" => cnt_detect_0 <= cnt_detect_0 + 3 + 1;
                    when "00011100" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "00011101" => cnt_detect_0 <= cnt_detect_0 + 3 + 1;
                    when "00011110" => cnt_detect_0 <= cnt_detect_0 + 3 + 1;
                    when "00011111" => cnt_detect_0 <= cnt_detect_0 + 4 + 1;

                    when "00100000" => cnt_detect_0 <= cnt_detect_0 + 0 + 1;
                    when "00100001" => cnt_detect_0 <= cnt_detect_0 + 1 + 1;
                    when "00100010" => cnt_detect_0 <= cnt_detect_0 + 1 + 1;
                    when "00100011" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "00100100" => cnt_detect_0 <= cnt_detect_0 + 1 + 1;
                    when "00100101" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "00100110" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "00100111" => cnt_detect_0 <= cnt_detect_0 + 3 + 1;
                    when "00101000" => cnt_detect_0 <= cnt_detect_0 + 1 + 1;
                    when "00101001" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "00101010" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "00101011" => cnt_detect_0 <= cnt_detect_0 + 3 + 1;
                    when "00101100" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "00101101" => cnt_detect_0 <= cnt_detect_0 + 3 + 1;
                    when "00101110" => cnt_detect_0 <= cnt_detect_0 + 3 + 1;
                    when "00101111" => cnt_detect_0 <= cnt_detect_0 + 4 + 1;

                    when "00110000" => cnt_detect_0 <= cnt_detect_0 + 0 + 2;
                    when "00110001" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "00110010" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "00110011" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "00110100" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "00110101" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "00110110" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "00110111" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "00111000" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "00111001" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "00111010" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "00111011" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "00111100" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "00111101" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "00111110" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "00111111" => cnt_detect_0 <= cnt_detect_0 + 4 + 2;

                    when "01000000" => cnt_detect_0 <= cnt_detect_0 + 0 + 1;
                    when "01000001" => cnt_detect_0 <= cnt_detect_0 + 1 + 1;
                    when "01000010" => cnt_detect_0 <= cnt_detect_0 + 1 + 1;
                    when "01000011" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "01000100" => cnt_detect_0 <= cnt_detect_0 + 1 + 1;
                    when "01000101" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "01000110" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "01000111" => cnt_detect_0 <= cnt_detect_0 + 3 + 1;
                    when "01001000" => cnt_detect_0 <= cnt_detect_0 + 1 + 1;
                    when "01001001" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "01001010" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "01001011" => cnt_detect_0 <= cnt_detect_0 + 3 + 1;
                    when "01001100" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "01001101" => cnt_detect_0 <= cnt_detect_0 + 3 + 1;
                    when "01001110" => cnt_detect_0 <= cnt_detect_0 + 3 + 1;
                    when "01001111" => cnt_detect_0 <= cnt_detect_0 + 4 + 1;

                    when "01010000" => cnt_detect_0 <= cnt_detect_0 + 0 + 2;
                    when "01010001" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "01010010" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "01010011" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "01010100" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "01010101" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "01010110" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "01010111" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "01011000" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "01011001" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "01011010" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "01011011" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "01011100" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "01011101" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "01011110" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "01011111" => cnt_detect_0 <= cnt_detect_0 + 4 + 2;

                    when "01100000" => cnt_detect_0 <= cnt_detect_0 + 0 + 2;
                    when "01100001" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "01100010" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "01100011" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "01100100" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "01100101" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "01100110" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "01100111" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "01101000" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "01101001" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "01101010" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "01101011" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "01101100" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "01101101" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "01101110" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "01101111" => cnt_detect_0 <= cnt_detect_0 + 4 + 2;

                    when "01110000" => cnt_detect_0 <= cnt_detect_0 + 0 + 3;
                    when "01110001" => cnt_detect_0 <= cnt_detect_0 + 1 + 3;
                    when "01110010" => cnt_detect_0 <= cnt_detect_0 + 1 + 3;
                    when "01110011" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "01110100" => cnt_detect_0 <= cnt_detect_0 + 1 + 3;
                    when "01110101" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "01110110" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "01110111" => cnt_detect_0 <= cnt_detect_0 + 3 + 3;
                    when "01111000" => cnt_detect_0 <= cnt_detect_0 + 1 + 3;
                    when "01111001" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "01111010" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "01111011" => cnt_detect_0 <= cnt_detect_0 + 3 + 3;
                    when "01111100" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "01111101" => cnt_detect_0 <= cnt_detect_0 + 3 + 3;
                    when "01111110" => cnt_detect_0 <= cnt_detect_0 + 3 + 3;
                    when "01111111" => cnt_detect_0 <= cnt_detect_0 + 4 + 3;

                    when "10000000" => cnt_detect_0 <= cnt_detect_0 + 0 + 1;
                    when "10000001" => cnt_detect_0 <= cnt_detect_0 + 1 + 1;
                    when "10000010" => cnt_detect_0 <= cnt_detect_0 + 1 + 1;
                    when "10000011" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "10000100" => cnt_detect_0 <= cnt_detect_0 + 1 + 1;
                    when "10000101" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "10000110" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "10000111" => cnt_detect_0 <= cnt_detect_0 + 3 + 1;
                    when "10001000" => cnt_detect_0 <= cnt_detect_0 + 1 + 1;
                    when "10001001" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "10001010" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "10001011" => cnt_detect_0 <= cnt_detect_0 + 3 + 1;
                    when "10001100" => cnt_detect_0 <= cnt_detect_0 + 2 + 1;
                    when "10001101" => cnt_detect_0 <= cnt_detect_0 + 3 + 1;
                    when "10001110" => cnt_detect_0 <= cnt_detect_0 + 3 + 1;
                    when "10001111" => cnt_detect_0 <= cnt_detect_0 + 4 + 1;

                    when "10010000" => cnt_detect_0 <= cnt_detect_0 + 0 + 2;
                    when "10010001" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "10010010" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "10010011" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "10010100" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "10010101" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "10010110" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "10010111" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "10011000" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "10011001" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "10011010" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "10011011" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "10011100" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "10011101" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "10011110" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "10011111" => cnt_detect_0 <= cnt_detect_0 + 4 + 2;

                    when "10100000" => cnt_detect_0 <= cnt_detect_0 + 0 + 2;
                    when "10100001" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "10100010" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "10100011" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "10100100" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "10100101" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "10100110" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "10100111" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "10101000" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "10101001" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "10101010" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "10101011" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "10101100" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "10101101" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "10101110" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "10101111" => cnt_detect_0 <= cnt_detect_0 + 4 + 2;

                    when "10110000" => cnt_detect_0 <= cnt_detect_0 + 0 + 3;
                    when "10110001" => cnt_detect_0 <= cnt_detect_0 + 1 + 3;
                    when "10110010" => cnt_detect_0 <= cnt_detect_0 + 1 + 3;
                    when "10110011" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "10110100" => cnt_detect_0 <= cnt_detect_0 + 1 + 3;
                    when "10110101" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "10110110" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "10110111" => cnt_detect_0 <= cnt_detect_0 + 3 + 3;
                    when "10111000" => cnt_detect_0 <= cnt_detect_0 + 1 + 3;
                    when "10111001" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "10111010" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "10111011" => cnt_detect_0 <= cnt_detect_0 + 3 + 3;
                    when "10111100" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "10111101" => cnt_detect_0 <= cnt_detect_0 + 3 + 3;
                    when "10111110" => cnt_detect_0 <= cnt_detect_0 + 3 + 3;
                    when "10111111" => cnt_detect_0 <= cnt_detect_0 + 4 + 3;

                    when "11000000" => cnt_detect_0 <= cnt_detect_0 + 0 + 2;
                    when "11000001" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "11000010" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "11000011" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "11000100" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "11000101" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "11000110" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "11000111" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "11001000" => cnt_detect_0 <= cnt_detect_0 + 1 + 2;
                    when "11001001" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "11001010" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "11001011" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "11001100" => cnt_detect_0 <= cnt_detect_0 + 2 + 2;
                    when "11001101" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "11001110" => cnt_detect_0 <= cnt_detect_0 + 3 + 2;
                    when "11001111" => cnt_detect_0 <= cnt_detect_0 + 4 + 2;

                    when "11010000" => cnt_detect_0 <= cnt_detect_0 + 0 + 3;
                    when "11010001" => cnt_detect_0 <= cnt_detect_0 + 1 + 3;
                    when "11010010" => cnt_detect_0 <= cnt_detect_0 + 1 + 3;
                    when "11010011" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "11010100" => cnt_detect_0 <= cnt_detect_0 + 1 + 3;
                    when "11010101" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "11010110" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "11010111" => cnt_detect_0 <= cnt_detect_0 + 3 + 3;
                    when "11011000" => cnt_detect_0 <= cnt_detect_0 + 1 + 3;
                    when "11011001" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "11011010" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "11011011" => cnt_detect_0 <= cnt_detect_0 + 3 + 3;
                    when "11011100" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "11011101" => cnt_detect_0 <= cnt_detect_0 + 3 + 3;
                    when "11011110" => cnt_detect_0 <= cnt_detect_0 + 3 + 3;
                    when "11011111" => cnt_detect_0 <= cnt_detect_0 + 4 + 3;

                    when "11100000" => cnt_detect_0 <= cnt_detect_0 + 0 + 3;
                    when "11100001" => cnt_detect_0 <= cnt_detect_0 + 1 + 3;
                    when "11100010" => cnt_detect_0 <= cnt_detect_0 + 1 + 3;
                    when "11100011" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "11100100" => cnt_detect_0 <= cnt_detect_0 + 1 + 3;
                    when "11100101" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "11100110" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "11100111" => cnt_detect_0 <= cnt_detect_0 + 3 + 3;
                    when "11101000" => cnt_detect_0 <= cnt_detect_0 + 1 + 3;
                    when "11101001" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "11101010" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "11101011" => cnt_detect_0 <= cnt_detect_0 + 3 + 3;
                    when "11101100" => cnt_detect_0 <= cnt_detect_0 + 2 + 3;
                    when "11101101" => cnt_detect_0 <= cnt_detect_0 + 3 + 3;
                    when "11101110" => cnt_detect_0 <= cnt_detect_0 + 3 + 3;
                    when "11101111" => cnt_detect_0 <= cnt_detect_0 + 4 + 3;

                    when "11110000" => cnt_detect_0 <= cnt_detect_0 + 0 + 4;
                    when "11110001" => cnt_detect_0 <= cnt_detect_0 + 1 + 4;
                    when "11110010" => cnt_detect_0 <= cnt_detect_0 + 1 + 4;
                    when "11110011" => cnt_detect_0 <= cnt_detect_0 + 2 + 4;
                    when "11110100" => cnt_detect_0 <= cnt_detect_0 + 1 + 4;
                    when "11110101" => cnt_detect_0 <= cnt_detect_0 + 2 + 4;
                    when "11110110" => cnt_detect_0 <= cnt_detect_0 + 2 + 4;
                    when "11110111" => cnt_detect_0 <= cnt_detect_0 + 3 + 4;
                    when "11111000" => cnt_detect_0 <= cnt_detect_0 + 1 + 4;
                    when "11111001" => cnt_detect_0 <= cnt_detect_0 + 2 + 4;
                    when "11111010" => cnt_detect_0 <= cnt_detect_0 + 2 + 4;
                    when "11111011" => cnt_detect_0 <= cnt_detect_0 + 3 + 4;
                    when "11111100" => cnt_detect_0 <= cnt_detect_0 + 2 + 4;
                    when "11111101" => cnt_detect_0 <= cnt_detect_0 + 3 + 4;
                    when "11111110" => cnt_detect_0 <= cnt_detect_0 + 3 + 4;
                    when "11111111" => cnt_detect_0 <= cnt_detect_0 + 4 + 4;

                    when others     => cnt_detect_0 <= cnt_detect_0 + 0;
                    end case;
                end if;
            end if;
        end if;
    end process;
    end generate;

    u_TOTAL_TX_is_up_to_16 : if NUM_TX > 8 generate
    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            if (update_en = '1') then
                if (check = '1') then
                    case packet_flag(15 downto 8) is
                    when "00000000" => cnt_detect_1 <= x"0000000000000000" + 0 + 0;
                    when "00000001" => cnt_detect_1 <= x"0000000000000000" + 1 + 0;
                    when "00000010" => cnt_detect_1 <= x"0000000000000000" + 1 + 0;
                    when "00000011" => cnt_detect_1 <= x"0000000000000000" + 2 + 0;
                    when "00000100" => cnt_detect_1 <= x"0000000000000000" + 1 + 0;
                    when "00000101" => cnt_detect_1 <= x"0000000000000000" + 2 + 0;
                    when "00000110" => cnt_detect_1 <= x"0000000000000000" + 2 + 0;
                    when "00000111" => cnt_detect_1 <= x"0000000000000000" + 3 + 0;
                    when "00001000" => cnt_detect_1 <= x"0000000000000000" + 1 + 0;
                    when "00001001" => cnt_detect_1 <= x"0000000000000000" + 2 + 0;
                    when "00001010" => cnt_detect_1 <= x"0000000000000000" + 2 + 0;
                    when "00001011" => cnt_detect_1 <= x"0000000000000000" + 3 + 0;
                    when "00001100" => cnt_detect_1 <= x"0000000000000000" + 2 + 0;
                    when "00001101" => cnt_detect_1 <= x"0000000000000000" + 3 + 0;
                    when "00001110" => cnt_detect_1 <= x"0000000000000000" + 3 + 0;
                    when "00001111" => cnt_detect_1 <= x"0000000000000000" + 4 + 0;

                    when "00010000" => cnt_detect_1 <= x"0000000000000000" + 0 + 1;
                    when "00010001" => cnt_detect_1 <= x"0000000000000000" + 1 + 1;
                    when "00010010" => cnt_detect_1 <= x"0000000000000000" + 1 + 1;
                    when "00010011" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "00010100" => cnt_detect_1 <= x"0000000000000000" + 1 + 1;
                    when "00010101" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "00010110" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "00010111" => cnt_detect_1 <= x"0000000000000000" + 3 + 1;
                    when "00011000" => cnt_detect_1 <= x"0000000000000000" + 1 + 1;
                    when "00011001" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "00011010" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "00011011" => cnt_detect_1 <= x"0000000000000000" + 3 + 1;
                    when "00011100" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "00011101" => cnt_detect_1 <= x"0000000000000000" + 3 + 1;
                    when "00011110" => cnt_detect_1 <= x"0000000000000000" + 3 + 1;
                    when "00011111" => cnt_detect_1 <= x"0000000000000000" + 4 + 1;

                    when "00100000" => cnt_detect_1 <= x"0000000000000000" + 0 + 1;
                    when "00100001" => cnt_detect_1 <= x"0000000000000000" + 1 + 1;
                    when "00100010" => cnt_detect_1 <= x"0000000000000000" + 1 + 1;
                    when "00100011" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "00100100" => cnt_detect_1 <= x"0000000000000000" + 1 + 1;
                    when "00100101" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "00100110" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "00100111" => cnt_detect_1 <= x"0000000000000000" + 3 + 1;
                    when "00101000" => cnt_detect_1 <= x"0000000000000000" + 1 + 1;
                    when "00101001" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "00101010" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "00101011" => cnt_detect_1 <= x"0000000000000000" + 3 + 1;
                    when "00101100" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "00101101" => cnt_detect_1 <= x"0000000000000000" + 3 + 1;
                    when "00101110" => cnt_detect_1 <= x"0000000000000000" + 3 + 1;
                    when "00101111" => cnt_detect_1 <= x"0000000000000000" + 4 + 1;

                    when "00110000" => cnt_detect_1 <= x"0000000000000000" + 0 + 2;
                    when "00110001" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "00110010" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "00110011" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "00110100" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "00110101" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "00110110" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "00110111" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "00111000" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "00111001" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "00111010" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "00111011" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "00111100" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "00111101" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "00111110" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "00111111" => cnt_detect_1 <= x"0000000000000000" + 4 + 2;

                    when "01000000" => cnt_detect_1 <= x"0000000000000000" + 0 + 1;
                    when "01000001" => cnt_detect_1 <= x"0000000000000000" + 1 + 1;
                    when "01000010" => cnt_detect_1 <= x"0000000000000000" + 1 + 1;
                    when "01000011" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "01000100" => cnt_detect_1 <= x"0000000000000000" + 1 + 1;
                    when "01000101" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "01000110" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "01000111" => cnt_detect_1 <= x"0000000000000000" + 3 + 1;
                    when "01001000" => cnt_detect_1 <= x"0000000000000000" + 1 + 1;
                    when "01001001" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "01001010" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "01001011" => cnt_detect_1 <= x"0000000000000000" + 3 + 1;
                    when "01001100" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "01001101" => cnt_detect_1 <= x"0000000000000000" + 3 + 1;
                    when "01001110" => cnt_detect_1 <= x"0000000000000000" + 3 + 1;
                    when "01001111" => cnt_detect_1 <= x"0000000000000000" + 4 + 1;

                    when "01010000" => cnt_detect_1 <= x"0000000000000000" + 0 + 2;
                    when "01010001" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "01010010" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "01010011" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "01010100" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "01010101" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "01010110" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "01010111" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "01011000" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "01011001" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "01011010" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "01011011" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "01011100" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "01011101" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "01011110" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "01011111" => cnt_detect_1 <= x"0000000000000000" + 4 + 2;

                    when "01100000" => cnt_detect_1 <= x"0000000000000000" + 0 + 2;
                    when "01100001" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "01100010" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "01100011" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "01100100" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "01100101" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "01100110" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "01100111" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "01101000" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "01101001" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "01101010" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "01101011" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "01101100" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "01101101" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "01101110" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "01101111" => cnt_detect_1 <= x"0000000000000000" + 4 + 2;

                    when "01110000" => cnt_detect_1 <= x"0000000000000000" + 0 + 3;
                    when "01110001" => cnt_detect_1 <= x"0000000000000000" + 1 + 3;
                    when "01110010" => cnt_detect_1 <= x"0000000000000000" + 1 + 3;
                    when "01110011" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "01110100" => cnt_detect_1 <= x"0000000000000000" + 1 + 3;
                    when "01110101" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "01110110" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "01110111" => cnt_detect_1 <= x"0000000000000000" + 3 + 3;
                    when "01111000" => cnt_detect_1 <= x"0000000000000000" + 1 + 3;
                    when "01111001" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "01111010" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "01111011" => cnt_detect_1 <= x"0000000000000000" + 3 + 3;
                    when "01111100" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "01111101" => cnt_detect_1 <= x"0000000000000000" + 3 + 3;
                    when "01111110" => cnt_detect_1 <= x"0000000000000000" + 3 + 3;
                    when "01111111" => cnt_detect_1 <= x"0000000000000000" + 4 + 3;

                    when "10000000" => cnt_detect_1 <= x"0000000000000000" + 0 + 1;
                    when "10000001" => cnt_detect_1 <= x"0000000000000000" + 1 + 1;
                    when "10000010" => cnt_detect_1 <= x"0000000000000000" + 1 + 1;
                    when "10000011" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "10000100" => cnt_detect_1 <= x"0000000000000000" + 1 + 1;
                    when "10000101" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "10000110" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "10000111" => cnt_detect_1 <= x"0000000000000000" + 3 + 1;
                    when "10001000" => cnt_detect_1 <= x"0000000000000000" + 1 + 1;
                    when "10001001" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "10001010" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "10001011" => cnt_detect_1 <= x"0000000000000000" + 3 + 1;
                    when "10001100" => cnt_detect_1 <= x"0000000000000000" + 2 + 1;
                    when "10001101" => cnt_detect_1 <= x"0000000000000000" + 3 + 1;
                    when "10001110" => cnt_detect_1 <= x"0000000000000000" + 3 + 1;
                    when "10001111" => cnt_detect_1 <= x"0000000000000000" + 4 + 1;

                    when "10010000" => cnt_detect_1 <= x"0000000000000000" + 0 + 2;
                    when "10010001" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "10010010" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "10010011" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "10010100" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "10010101" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "10010110" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "10010111" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "10011000" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "10011001" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "10011010" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "10011011" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "10011100" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "10011101" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "10011110" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "10011111" => cnt_detect_1 <= x"0000000000000000" + 4 + 2;

                    when "10100000" => cnt_detect_1 <= x"0000000000000000" + 0 + 2;
                    when "10100001" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "10100010" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "10100011" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "10100100" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "10100101" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "10100110" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "10100111" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "10101000" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "10101001" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "10101010" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "10101011" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "10101100" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "10101101" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "10101110" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "10101111" => cnt_detect_1 <= x"0000000000000000" + 4 + 2;

                    when "10110000" => cnt_detect_1 <= x"0000000000000000" + 0 + 3;
                    when "10110001" => cnt_detect_1 <= x"0000000000000000" + 1 + 3;
                    when "10110010" => cnt_detect_1 <= x"0000000000000000" + 1 + 3;
                    when "10110011" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "10110100" => cnt_detect_1 <= x"0000000000000000" + 1 + 3;
                    when "10110101" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "10110110" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "10110111" => cnt_detect_1 <= x"0000000000000000" + 3 + 3;
                    when "10111000" => cnt_detect_1 <= x"0000000000000000" + 1 + 3;
                    when "10111001" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "10111010" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "10111011" => cnt_detect_1 <= x"0000000000000000" + 3 + 3;
                    when "10111100" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "10111101" => cnt_detect_1 <= x"0000000000000000" + 3 + 3;
                    when "10111110" => cnt_detect_1 <= x"0000000000000000" + 3 + 3;
                    when "10111111" => cnt_detect_1 <= x"0000000000000000" + 4 + 3;

                    when "11000000" => cnt_detect_1 <= x"0000000000000000" + 0 + 2;
                    when "11000001" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "11000010" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "11000011" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "11000100" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "11000101" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "11000110" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "11000111" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "11001000" => cnt_detect_1 <= x"0000000000000000" + 1 + 2;
                    when "11001001" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "11001010" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "11001011" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "11001100" => cnt_detect_1 <= x"0000000000000000" + 2 + 2;
                    when "11001101" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "11001110" => cnt_detect_1 <= x"0000000000000000" + 3 + 2;
                    when "11001111" => cnt_detect_1 <= x"0000000000000000" + 4 + 2;

                    when "11010000" => cnt_detect_1 <= x"0000000000000000" + 0 + 3;
                    when "11010001" => cnt_detect_1 <= x"0000000000000000" + 1 + 3;
                    when "11010010" => cnt_detect_1 <= x"0000000000000000" + 1 + 3;
                    when "11010011" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "11010100" => cnt_detect_1 <= x"0000000000000000" + 1 + 3;
                    when "11010101" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "11010110" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "11010111" => cnt_detect_1 <= x"0000000000000000" + 3 + 3;
                    when "11011000" => cnt_detect_1 <= x"0000000000000000" + 1 + 3;
                    when "11011001" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "11011010" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "11011011" => cnt_detect_1 <= x"0000000000000000" + 3 + 3;
                    when "11011100" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "11011101" => cnt_detect_1 <= x"0000000000000000" + 3 + 3;
                    when "11011110" => cnt_detect_1 <= x"0000000000000000" + 3 + 3;
                    when "11011111" => cnt_detect_1 <= x"0000000000000000" + 4 + 3;

                    when "11100000" => cnt_detect_1 <= x"0000000000000000" + 0 + 3;
                    when "11100001" => cnt_detect_1 <= x"0000000000000000" + 1 + 3;
                    when "11100010" => cnt_detect_1 <= x"0000000000000000" + 1 + 3;
                    when "11100011" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "11100100" => cnt_detect_1 <= x"0000000000000000" + 1 + 3;
                    when "11100101" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "11100110" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "11100111" => cnt_detect_1 <= x"0000000000000000" + 3 + 3;
                    when "11101000" => cnt_detect_1 <= x"0000000000000000" + 1 + 3;
                    when "11101001" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "11101010" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "11101011" => cnt_detect_1 <= x"0000000000000000" + 3 + 3;
                    when "11101100" => cnt_detect_1 <= x"0000000000000000" + 2 + 3;
                    when "11101101" => cnt_detect_1 <= x"0000000000000000" + 3 + 3;
                    when "11101110" => cnt_detect_1 <= x"0000000000000000" + 3 + 3;
                    when "11101111" => cnt_detect_1 <= x"0000000000000000" + 4 + 3;

                    when "11110000" => cnt_detect_1 <= x"0000000000000000" + 0 + 4;
                    when "11110001" => cnt_detect_1 <= x"0000000000000000" + 1 + 4;
                    when "11110010" => cnt_detect_1 <= x"0000000000000000" + 1 + 4;
                    when "11110011" => cnt_detect_1 <= x"0000000000000000" + 2 + 4;
                    when "11110100" => cnt_detect_1 <= x"0000000000000000" + 1 + 4;
                    when "11110101" => cnt_detect_1 <= x"0000000000000000" + 2 + 4;
                    when "11110110" => cnt_detect_1 <= x"0000000000000000" + 2 + 4;
                    when "11110111" => cnt_detect_1 <= x"0000000000000000" + 3 + 4;
                    when "11111000" => cnt_detect_1 <= x"0000000000000000" + 1 + 4;
                    when "11111001" => cnt_detect_1 <= x"0000000000000000" + 2 + 4;
                    when "11111010" => cnt_detect_1 <= x"0000000000000000" + 2 + 4;
                    when "11111011" => cnt_detect_1 <= x"0000000000000000" + 3 + 4;
                    when "11111100" => cnt_detect_1 <= x"0000000000000000" + 2 + 4;
                    when "11111101" => cnt_detect_1 <= x"0000000000000000" + 3 + 4;
                    when "11111110" => cnt_detect_1 <= x"0000000000000000" + 3 + 4;
                    when "11111111" => cnt_detect_1 <= x"0000000000000000" + 4 + 4;

                    when others     => cnt_detect_1 <= x"0000000000000000" + 0;
                    end case;
                else
                    cnt_detect_1 <= (others => '0');
                end if;
            else
                if (check = '1') then
                    case packet_flag(15 downto 8) is
                    when "00000000" => cnt_detect_1 <= cnt_detect_1 + 0 + 0;
                    when "00000001" => cnt_detect_1 <= cnt_detect_1 + 1 + 0;
                    when "00000010" => cnt_detect_1 <= cnt_detect_1 + 1 + 0;
                    when "00000011" => cnt_detect_1 <= cnt_detect_1 + 2 + 0;
                    when "00000100" => cnt_detect_1 <= cnt_detect_1 + 1 + 0;
                    when "00000101" => cnt_detect_1 <= cnt_detect_1 + 2 + 0;
                    when "00000110" => cnt_detect_1 <= cnt_detect_1 + 2 + 0;
                    when "00000111" => cnt_detect_1 <= cnt_detect_1 + 3 + 0;
                    when "00001000" => cnt_detect_1 <= cnt_detect_1 + 1 + 0;
                    when "00001001" => cnt_detect_1 <= cnt_detect_1 + 2 + 0;
                    when "00001010" => cnt_detect_1 <= cnt_detect_1 + 2 + 0;
                    when "00001011" => cnt_detect_1 <= cnt_detect_1 + 3 + 0;
                    when "00001100" => cnt_detect_1 <= cnt_detect_1 + 2 + 0;
                    when "00001101" => cnt_detect_1 <= cnt_detect_1 + 3 + 0;
                    when "00001110" => cnt_detect_1 <= cnt_detect_1 + 3 + 0;
                    when "00001111" => cnt_detect_1 <= cnt_detect_1 + 4 + 0;

                    when "00010000" => cnt_detect_1 <= cnt_detect_1 + 0 + 1;
                    when "00010001" => cnt_detect_1 <= cnt_detect_1 + 1 + 1;
                    when "00010010" => cnt_detect_1 <= cnt_detect_1 + 1 + 1;
                    when "00010011" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "00010100" => cnt_detect_1 <= cnt_detect_1 + 1 + 1;
                    when "00010101" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "00010110" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "00010111" => cnt_detect_1 <= cnt_detect_1 + 3 + 1;
                    when "00011000" => cnt_detect_1 <= cnt_detect_1 + 1 + 1;
                    when "00011001" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "00011010" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "00011011" => cnt_detect_1 <= cnt_detect_1 + 3 + 1;
                    when "00011100" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "00011101" => cnt_detect_1 <= cnt_detect_1 + 3 + 1;
                    when "00011110" => cnt_detect_1 <= cnt_detect_1 + 3 + 1;
                    when "00011111" => cnt_detect_1 <= cnt_detect_1 + 4 + 1;

                    when "00100000" => cnt_detect_1 <= cnt_detect_1 + 0 + 1;
                    when "00100001" => cnt_detect_1 <= cnt_detect_1 + 1 + 1;
                    when "00100010" => cnt_detect_1 <= cnt_detect_1 + 1 + 1;
                    when "00100011" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "00100100" => cnt_detect_1 <= cnt_detect_1 + 1 + 1;
                    when "00100101" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "00100110" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "00100111" => cnt_detect_1 <= cnt_detect_1 + 3 + 1;
                    when "00101000" => cnt_detect_1 <= cnt_detect_1 + 1 + 1;
                    when "00101001" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "00101010" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "00101011" => cnt_detect_1 <= cnt_detect_1 + 3 + 1;
                    when "00101100" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "00101101" => cnt_detect_1 <= cnt_detect_1 + 3 + 1;
                    when "00101110" => cnt_detect_1 <= cnt_detect_1 + 3 + 1;
                    when "00101111" => cnt_detect_1 <= cnt_detect_1 + 4 + 1;

                    when "00110000" => cnt_detect_1 <= cnt_detect_1 + 0 + 2;
                    when "00110001" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "00110010" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "00110011" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "00110100" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "00110101" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "00110110" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "00110111" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "00111000" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "00111001" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "00111010" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "00111011" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "00111100" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "00111101" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "00111110" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "00111111" => cnt_detect_1 <= cnt_detect_1 + 4 + 2;

                    when "01000000" => cnt_detect_1 <= cnt_detect_1 + 0 + 1;
                    when "01000001" => cnt_detect_1 <= cnt_detect_1 + 1 + 1;
                    when "01000010" => cnt_detect_1 <= cnt_detect_1 + 1 + 1;
                    when "01000011" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "01000100" => cnt_detect_1 <= cnt_detect_1 + 1 + 1;
                    when "01000101" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "01000110" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "01000111" => cnt_detect_1 <= cnt_detect_1 + 3 + 1;
                    when "01001000" => cnt_detect_1 <= cnt_detect_1 + 1 + 1;
                    when "01001001" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "01001010" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "01001011" => cnt_detect_1 <= cnt_detect_1 + 3 + 1;
                    when "01001100" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "01001101" => cnt_detect_1 <= cnt_detect_1 + 3 + 1;
                    when "01001110" => cnt_detect_1 <= cnt_detect_1 + 3 + 1;
                    when "01001111" => cnt_detect_1 <= cnt_detect_1 + 4 + 1;

                    when "01010000" => cnt_detect_1 <= cnt_detect_1 + 0 + 2;
                    when "01010001" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "01010010" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "01010011" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "01010100" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "01010101" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "01010110" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "01010111" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "01011000" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "01011001" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "01011010" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "01011011" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "01011100" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "01011101" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "01011110" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "01011111" => cnt_detect_1 <= cnt_detect_1 + 4 + 2;

                    when "01100000" => cnt_detect_1 <= cnt_detect_1 + 0 + 2;
                    when "01100001" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "01100010" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "01100011" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "01100100" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "01100101" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "01100110" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "01100111" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "01101000" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "01101001" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "01101010" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "01101011" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "01101100" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "01101101" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "01101110" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "01101111" => cnt_detect_1 <= cnt_detect_1 + 4 + 2;

                    when "01110000" => cnt_detect_1 <= cnt_detect_1 + 0 + 3;
                    when "01110001" => cnt_detect_1 <= cnt_detect_1 + 1 + 3;
                    when "01110010" => cnt_detect_1 <= cnt_detect_1 + 1 + 3;
                    when "01110011" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "01110100" => cnt_detect_1 <= cnt_detect_1 + 1 + 3;
                    when "01110101" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "01110110" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "01110111" => cnt_detect_1 <= cnt_detect_1 + 3 + 3;
                    when "01111000" => cnt_detect_1 <= cnt_detect_1 + 1 + 3;
                    when "01111001" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "01111010" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "01111011" => cnt_detect_1 <= cnt_detect_1 + 3 + 3;
                    when "01111100" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "01111101" => cnt_detect_1 <= cnt_detect_1 + 3 + 3;
                    when "01111110" => cnt_detect_1 <= cnt_detect_1 + 3 + 3;
                    when "01111111" => cnt_detect_1 <= cnt_detect_1 + 4 + 3;

                    when "10000000" => cnt_detect_1 <= cnt_detect_1 + 0 + 1;
                    when "10000001" => cnt_detect_1 <= cnt_detect_1 + 1 + 1;
                    when "10000010" => cnt_detect_1 <= cnt_detect_1 + 1 + 1;
                    when "10000011" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "10000100" => cnt_detect_1 <= cnt_detect_1 + 1 + 1;
                    when "10000101" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "10000110" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "10000111" => cnt_detect_1 <= cnt_detect_1 + 3 + 1;
                    when "10001000" => cnt_detect_1 <= cnt_detect_1 + 1 + 1;
                    when "10001001" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "10001010" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "10001011" => cnt_detect_1 <= cnt_detect_1 + 3 + 1;
                    when "10001100" => cnt_detect_1 <= cnt_detect_1 + 2 + 1;
                    when "10001101" => cnt_detect_1 <= cnt_detect_1 + 3 + 1;
                    when "10001110" => cnt_detect_1 <= cnt_detect_1 + 3 + 1;
                    when "10001111" => cnt_detect_1 <= cnt_detect_1 + 4 + 1;

                    when "10010000" => cnt_detect_1 <= cnt_detect_1 + 0 + 2;
                    when "10010001" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "10010010" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "10010011" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "10010100" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "10010101" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "10010110" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "10010111" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "10011000" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "10011001" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "10011010" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "10011011" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "10011100" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "10011101" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "10011110" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "10011111" => cnt_detect_1 <= cnt_detect_1 + 4 + 2;

                    when "10100000" => cnt_detect_1 <= cnt_detect_1 + 0 + 2;
                    when "10100001" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "10100010" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "10100011" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "10100100" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "10100101" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "10100110" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "10100111" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "10101000" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "10101001" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "10101010" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "10101011" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "10101100" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "10101101" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "10101110" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "10101111" => cnt_detect_1 <= cnt_detect_1 + 4 + 2;

                    when "10110000" => cnt_detect_1 <= cnt_detect_1 + 0 + 3;
                    when "10110001" => cnt_detect_1 <= cnt_detect_1 + 1 + 3;
                    when "10110010" => cnt_detect_1 <= cnt_detect_1 + 1 + 3;
                    when "10110011" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "10110100" => cnt_detect_1 <= cnt_detect_1 + 1 + 3;
                    when "10110101" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "10110110" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "10110111" => cnt_detect_1 <= cnt_detect_1 + 3 + 3;
                    when "10111000" => cnt_detect_1 <= cnt_detect_1 + 1 + 3;
                    when "10111001" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "10111010" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "10111011" => cnt_detect_1 <= cnt_detect_1 + 3 + 3;
                    when "10111100" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "10111101" => cnt_detect_1 <= cnt_detect_1 + 3 + 3;
                    when "10111110" => cnt_detect_1 <= cnt_detect_1 + 3 + 3;
                    when "10111111" => cnt_detect_1 <= cnt_detect_1 + 4 + 3;

                    when "11000000" => cnt_detect_1 <= cnt_detect_1 + 0 + 2;
                    when "11000001" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "11000010" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "11000011" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "11000100" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "11000101" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "11000110" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "11000111" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "11001000" => cnt_detect_1 <= cnt_detect_1 + 1 + 2;
                    when "11001001" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "11001010" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "11001011" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "11001100" => cnt_detect_1 <= cnt_detect_1 + 2 + 2;
                    when "11001101" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "11001110" => cnt_detect_1 <= cnt_detect_1 + 3 + 2;
                    when "11001111" => cnt_detect_1 <= cnt_detect_1 + 4 + 2;

                    when "11010000" => cnt_detect_1 <= cnt_detect_1 + 0 + 3;
                    when "11010001" => cnt_detect_1 <= cnt_detect_1 + 1 + 3;
                    when "11010010" => cnt_detect_1 <= cnt_detect_1 + 1 + 3;
                    when "11010011" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "11010100" => cnt_detect_1 <= cnt_detect_1 + 1 + 3;
                    when "11010101" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "11010110" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "11010111" => cnt_detect_1 <= cnt_detect_1 + 3 + 3;
                    when "11011000" => cnt_detect_1 <= cnt_detect_1 + 1 + 3;
                    when "11011001" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "11011010" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "11011011" => cnt_detect_1 <= cnt_detect_1 + 3 + 3;
                    when "11011100" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "11011101" => cnt_detect_1 <= cnt_detect_1 + 3 + 3;
                    when "11011110" => cnt_detect_1 <= cnt_detect_1 + 3 + 3;
                    when "11011111" => cnt_detect_1 <= cnt_detect_1 + 4 + 3;

                    when "11100000" => cnt_detect_1 <= cnt_detect_1 + 0 + 3;
                    when "11100001" => cnt_detect_1 <= cnt_detect_1 + 1 + 3;
                    when "11100010" => cnt_detect_1 <= cnt_detect_1 + 1 + 3;
                    when "11100011" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "11100100" => cnt_detect_1 <= cnt_detect_1 + 1 + 3;
                    when "11100101" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "11100110" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "11100111" => cnt_detect_1 <= cnt_detect_1 + 3 + 3;
                    when "11101000" => cnt_detect_1 <= cnt_detect_1 + 1 + 3;
                    when "11101001" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "11101010" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "11101011" => cnt_detect_1 <= cnt_detect_1 + 3 + 3;
                    when "11101100" => cnt_detect_1 <= cnt_detect_1 + 2 + 3;
                    when "11101101" => cnt_detect_1 <= cnt_detect_1 + 3 + 3;
                    when "11101110" => cnt_detect_1 <= cnt_detect_1 + 3 + 3;
                    when "11101111" => cnt_detect_1 <= cnt_detect_1 + 4 + 3;

                    when "11110000" => cnt_detect_1 <= cnt_detect_1 + 0 + 4;
                    when "11110001" => cnt_detect_1 <= cnt_detect_1 + 1 + 4;
                    when "11110010" => cnt_detect_1 <= cnt_detect_1 + 1 + 4;
                    when "11110011" => cnt_detect_1 <= cnt_detect_1 + 2 + 4;
                    when "11110100" => cnt_detect_1 <= cnt_detect_1 + 1 + 4;
                    when "11110101" => cnt_detect_1 <= cnt_detect_1 + 2 + 4;
                    when "11110110" => cnt_detect_1 <= cnt_detect_1 + 2 + 4;
                    when "11110111" => cnt_detect_1 <= cnt_detect_1 + 3 + 4;
                    when "11111000" => cnt_detect_1 <= cnt_detect_1 + 1 + 4;
                    when "11111001" => cnt_detect_1 <= cnt_detect_1 + 2 + 4;
                    when "11111010" => cnt_detect_1 <= cnt_detect_1 + 2 + 4;
                    when "11111011" => cnt_detect_1 <= cnt_detect_1 + 3 + 4;
                    when "11111100" => cnt_detect_1 <= cnt_detect_1 + 2 + 4;
                    when "11111101" => cnt_detect_1 <= cnt_detect_1 + 3 + 4;
                    when "11111110" => cnt_detect_1 <= cnt_detect_1 + 3 + 4;
                    when "11111111" => cnt_detect_1 <= cnt_detect_1 + 4 + 4;

                    when others     => cnt_detect_1 <= cnt_detect_1 + 0;
                    end case;
                end if;
            end if;
        end if;
    end process;
    end generate;

    u_TOTAL_TX_is_up_to_24 : if NUM_TX > 16 generate
    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            if (update_en = '1') then
                if (check = '1') then
                    case packet_flag(23 downto 16) is
                    when "00000000" => cnt_detect_2 <= x"0000000000000000" + 0 + 0;
                    when "00000001" => cnt_detect_2 <= x"0000000000000000" + 1 + 0;
                    when "00000010" => cnt_detect_2 <= x"0000000000000000" + 1 + 0;
                    when "00000011" => cnt_detect_2 <= x"0000000000000000" + 2 + 0;
                    when "00000100" => cnt_detect_2 <= x"0000000000000000" + 1 + 0;
                    when "00000101" => cnt_detect_2 <= x"0000000000000000" + 2 + 0;
                    when "00000110" => cnt_detect_2 <= x"0000000000000000" + 2 + 0;
                    when "00000111" => cnt_detect_2 <= x"0000000000000000" + 3 + 0;
                    when "00001000" => cnt_detect_2 <= x"0000000000000000" + 1 + 0;
                    when "00001001" => cnt_detect_2 <= x"0000000000000000" + 2 + 0;
                    when "00001010" => cnt_detect_2 <= x"0000000000000000" + 2 + 0;
                    when "00001011" => cnt_detect_2 <= x"0000000000000000" + 3 + 0;
                    when "00001100" => cnt_detect_2 <= x"0000000000000000" + 2 + 0;
                    when "00001101" => cnt_detect_2 <= x"0000000000000000" + 3 + 0;
                    when "00001110" => cnt_detect_2 <= x"0000000000000000" + 3 + 0;
                    when "00001111" => cnt_detect_2 <= x"0000000000000000" + 4 + 0;

                    when "00010000" => cnt_detect_2 <= x"0000000000000000" + 0 + 1;
                    when "00010001" => cnt_detect_2 <= x"0000000000000000" + 1 + 1;
                    when "00010010" => cnt_detect_2 <= x"0000000000000000" + 1 + 1;
                    when "00010011" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "00010100" => cnt_detect_2 <= x"0000000000000000" + 1 + 1;
                    when "00010101" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "00010110" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "00010111" => cnt_detect_2 <= x"0000000000000000" + 3 + 1;
                    when "00011000" => cnt_detect_2 <= x"0000000000000000" + 1 + 1;
                    when "00011001" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "00011010" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "00011011" => cnt_detect_2 <= x"0000000000000000" + 3 + 1;
                    when "00011100" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "00011101" => cnt_detect_2 <= x"0000000000000000" + 3 + 1;
                    when "00011110" => cnt_detect_2 <= x"0000000000000000" + 3 + 1;
                    when "00011111" => cnt_detect_2 <= x"0000000000000000" + 4 + 1;

                    when "00100000" => cnt_detect_2 <= x"0000000000000000" + 0 + 1;
                    when "00100001" => cnt_detect_2 <= x"0000000000000000" + 1 + 1;
                    when "00100010" => cnt_detect_2 <= x"0000000000000000" + 1 + 1;
                    when "00100011" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "00100100" => cnt_detect_2 <= x"0000000000000000" + 1 + 1;
                    when "00100101" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "00100110" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "00100111" => cnt_detect_2 <= x"0000000000000000" + 3 + 1;
                    when "00101000" => cnt_detect_2 <= x"0000000000000000" + 1 + 1;
                    when "00101001" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "00101010" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "00101011" => cnt_detect_2 <= x"0000000000000000" + 3 + 1;
                    when "00101100" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "00101101" => cnt_detect_2 <= x"0000000000000000" + 3 + 1;
                    when "00101110" => cnt_detect_2 <= x"0000000000000000" + 3 + 1;
                    when "00101111" => cnt_detect_2 <= x"0000000000000000" + 4 + 1;

                    when "00110000" => cnt_detect_2 <= x"0000000000000000" + 0 + 2;
                    when "00110001" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "00110010" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "00110011" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "00110100" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "00110101" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "00110110" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "00110111" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "00111000" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "00111001" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "00111010" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "00111011" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "00111100" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "00111101" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "00111110" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "00111111" => cnt_detect_2 <= x"0000000000000000" + 4 + 2;

                    when "01000000" => cnt_detect_2 <= x"0000000000000000" + 0 + 1;
                    when "01000001" => cnt_detect_2 <= x"0000000000000000" + 1 + 1;
                    when "01000010" => cnt_detect_2 <= x"0000000000000000" + 1 + 1;
                    when "01000011" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "01000100" => cnt_detect_2 <= x"0000000000000000" + 1 + 1;
                    when "01000101" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "01000110" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "01000111" => cnt_detect_2 <= x"0000000000000000" + 3 + 1;
                    when "01001000" => cnt_detect_2 <= x"0000000000000000" + 1 + 1;
                    when "01001001" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "01001010" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "01001011" => cnt_detect_2 <= x"0000000000000000" + 3 + 1;
                    when "01001100" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "01001101" => cnt_detect_2 <= x"0000000000000000" + 3 + 1;
                    when "01001110" => cnt_detect_2 <= x"0000000000000000" + 3 + 1;
                    when "01001111" => cnt_detect_2 <= x"0000000000000000" + 4 + 1;

                    when "01010000" => cnt_detect_2 <= x"0000000000000000" + 0 + 2;
                    when "01010001" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "01010010" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "01010011" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "01010100" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "01010101" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "01010110" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "01010111" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "01011000" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "01011001" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "01011010" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "01011011" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "01011100" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "01011101" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "01011110" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "01011111" => cnt_detect_2 <= x"0000000000000000" + 4 + 2;

                    when "01100000" => cnt_detect_2 <= x"0000000000000000" + 0 + 2;
                    when "01100001" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "01100010" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "01100011" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "01100100" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "01100101" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "01100110" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "01100111" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "01101000" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "01101001" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "01101010" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "01101011" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "01101100" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "01101101" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "01101110" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "01101111" => cnt_detect_2 <= x"0000000000000000" + 4 + 2;

                    when "01110000" => cnt_detect_2 <= x"0000000000000000" + 0 + 3;
                    when "01110001" => cnt_detect_2 <= x"0000000000000000" + 1 + 3;
                    when "01110010" => cnt_detect_2 <= x"0000000000000000" + 1 + 3;
                    when "01110011" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "01110100" => cnt_detect_2 <= x"0000000000000000" + 1 + 3;
                    when "01110101" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "01110110" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "01110111" => cnt_detect_2 <= x"0000000000000000" + 3 + 3;
                    when "01111000" => cnt_detect_2 <= x"0000000000000000" + 1 + 3;
                    when "01111001" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "01111010" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "01111011" => cnt_detect_2 <= x"0000000000000000" + 3 + 3;
                    when "01111100" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "01111101" => cnt_detect_2 <= x"0000000000000000" + 3 + 3;
                    when "01111110" => cnt_detect_2 <= x"0000000000000000" + 3 + 3;
                    when "01111111" => cnt_detect_2 <= x"0000000000000000" + 4 + 3;

                    when "10000000" => cnt_detect_2 <= x"0000000000000000" + 0 + 1;
                    when "10000001" => cnt_detect_2 <= x"0000000000000000" + 1 + 1;
                    when "10000010" => cnt_detect_2 <= x"0000000000000000" + 1 + 1;
                    when "10000011" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "10000100" => cnt_detect_2 <= x"0000000000000000" + 1 + 1;
                    when "10000101" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "10000110" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "10000111" => cnt_detect_2 <= x"0000000000000000" + 3 + 1;
                    when "10001000" => cnt_detect_2 <= x"0000000000000000" + 1 + 1;
                    when "10001001" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "10001010" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "10001011" => cnt_detect_2 <= x"0000000000000000" + 3 + 1;
                    when "10001100" => cnt_detect_2 <= x"0000000000000000" + 2 + 1;
                    when "10001101" => cnt_detect_2 <= x"0000000000000000" + 3 + 1;
                    when "10001110" => cnt_detect_2 <= x"0000000000000000" + 3 + 1;
                    when "10001111" => cnt_detect_2 <= x"0000000000000000" + 4 + 1;

                    when "10010000" => cnt_detect_2 <= x"0000000000000000" + 0 + 2;
                    when "10010001" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "10010010" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "10010011" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "10010100" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "10010101" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "10010110" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "10010111" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "10011000" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "10011001" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "10011010" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "10011011" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "10011100" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "10011101" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "10011110" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "10011111" => cnt_detect_2 <= x"0000000000000000" + 4 + 2;

                    when "10100000" => cnt_detect_2 <= x"0000000000000000" + 0 + 2;
                    when "10100001" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "10100010" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "10100011" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "10100100" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "10100101" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "10100110" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "10100111" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "10101000" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "10101001" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "10101010" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "10101011" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "10101100" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "10101101" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "10101110" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "10101111" => cnt_detect_2 <= x"0000000000000000" + 4 + 2;

                    when "10110000" => cnt_detect_2 <= x"0000000000000000" + 0 + 3;
                    when "10110001" => cnt_detect_2 <= x"0000000000000000" + 1 + 3;
                    when "10110010" => cnt_detect_2 <= x"0000000000000000" + 1 + 3;
                    when "10110011" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "10110100" => cnt_detect_2 <= x"0000000000000000" + 1 + 3;
                    when "10110101" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "10110110" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "10110111" => cnt_detect_2 <= x"0000000000000000" + 3 + 3;
                    when "10111000" => cnt_detect_2 <= x"0000000000000000" + 1 + 3;
                    when "10111001" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "10111010" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "10111011" => cnt_detect_2 <= x"0000000000000000" + 3 + 3;
                    when "10111100" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "10111101" => cnt_detect_2 <= x"0000000000000000" + 3 + 3;
                    when "10111110" => cnt_detect_2 <= x"0000000000000000" + 3 + 3;
                    when "10111111" => cnt_detect_2 <= x"0000000000000000" + 4 + 3;

                    when "11000000" => cnt_detect_2 <= x"0000000000000000" + 0 + 2;
                    when "11000001" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "11000010" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "11000011" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "11000100" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "11000101" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "11000110" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "11000111" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "11001000" => cnt_detect_2 <= x"0000000000000000" + 1 + 2;
                    when "11001001" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "11001010" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "11001011" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "11001100" => cnt_detect_2 <= x"0000000000000000" + 2 + 2;
                    when "11001101" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "11001110" => cnt_detect_2 <= x"0000000000000000" + 3 + 2;
                    when "11001111" => cnt_detect_2 <= x"0000000000000000" + 4 + 2;

                    when "11010000" => cnt_detect_2 <= x"0000000000000000" + 0 + 3;
                    when "11010001" => cnt_detect_2 <= x"0000000000000000" + 1 + 3;
                    when "11010010" => cnt_detect_2 <= x"0000000000000000" + 1 + 3;
                    when "11010011" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "11010100" => cnt_detect_2 <= x"0000000000000000" + 1 + 3;
                    when "11010101" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "11010110" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "11010111" => cnt_detect_2 <= x"0000000000000000" + 3 + 3;
                    when "11011000" => cnt_detect_2 <= x"0000000000000000" + 1 + 3;
                    when "11011001" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "11011010" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "11011011" => cnt_detect_2 <= x"0000000000000000" + 3 + 3;
                    when "11011100" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "11011101" => cnt_detect_2 <= x"0000000000000000" + 3 + 3;
                    when "11011110" => cnt_detect_2 <= x"0000000000000000" + 3 + 3;
                    when "11011111" => cnt_detect_2 <= x"0000000000000000" + 4 + 3;

                    when "11100000" => cnt_detect_2 <= x"0000000000000000" + 0 + 3;
                    when "11100001" => cnt_detect_2 <= x"0000000000000000" + 1 + 3;
                    when "11100010" => cnt_detect_2 <= x"0000000000000000" + 1 + 3;
                    when "11100011" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "11100100" => cnt_detect_2 <= x"0000000000000000" + 1 + 3;
                    when "11100101" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "11100110" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "11100111" => cnt_detect_2 <= x"0000000000000000" + 3 + 3;
                    when "11101000" => cnt_detect_2 <= x"0000000000000000" + 1 + 3;
                    when "11101001" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "11101010" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "11101011" => cnt_detect_2 <= x"0000000000000000" + 3 + 3;
                    when "11101100" => cnt_detect_2 <= x"0000000000000000" + 2 + 3;
                    when "11101101" => cnt_detect_2 <= x"0000000000000000" + 3 + 3;
                    when "11101110" => cnt_detect_2 <= x"0000000000000000" + 3 + 3;
                    when "11101111" => cnt_detect_2 <= x"0000000000000000" + 4 + 3;

                    when "11110000" => cnt_detect_2 <= x"0000000000000000" + 0 + 4;
                    when "11110001" => cnt_detect_2 <= x"0000000000000000" + 1 + 4;
                    when "11110010" => cnt_detect_2 <= x"0000000000000000" + 1 + 4;
                    when "11110011" => cnt_detect_2 <= x"0000000000000000" + 2 + 4;
                    when "11110100" => cnt_detect_2 <= x"0000000000000000" + 1 + 4;
                    when "11110101" => cnt_detect_2 <= x"0000000000000000" + 2 + 4;
                    when "11110110" => cnt_detect_2 <= x"0000000000000000" + 2 + 4;
                    when "11110111" => cnt_detect_2 <= x"0000000000000000" + 3 + 4;
                    when "11111000" => cnt_detect_2 <= x"0000000000000000" + 1 + 4;
                    when "11111001" => cnt_detect_2 <= x"0000000000000000" + 2 + 4;
                    when "11111010" => cnt_detect_2 <= x"0000000000000000" + 2 + 4;
                    when "11111011" => cnt_detect_2 <= x"0000000000000000" + 3 + 4;
                    when "11111100" => cnt_detect_2 <= x"0000000000000000" + 2 + 4;
                    when "11111101" => cnt_detect_2 <= x"0000000000000000" + 3 + 4;
                    when "11111110" => cnt_detect_2 <= x"0000000000000000" + 3 + 4;
                    when "11111111" => cnt_detect_2 <= x"0000000000000000" + 4 + 4;

                    when others     => cnt_detect_2 <= x"0000000000000000" + 0;
                    end case;
                else
                    cnt_detect_2 <= (others => '0');
                end if;
            else
                if (check = '1') then
                    case packet_flag(23 downto 16) is
                    when "00000000" => cnt_detect_2 <= cnt_detect_2 + 0 + 0;
                    when "00000001" => cnt_detect_2 <= cnt_detect_2 + 1 + 0;
                    when "00000010" => cnt_detect_2 <= cnt_detect_2 + 1 + 0;
                    when "00000011" => cnt_detect_2 <= cnt_detect_2 + 2 + 0;
                    when "00000100" => cnt_detect_2 <= cnt_detect_2 + 1 + 0;
                    when "00000101" => cnt_detect_2 <= cnt_detect_2 + 2 + 0;
                    when "00000110" => cnt_detect_2 <= cnt_detect_2 + 2 + 0;
                    when "00000111" => cnt_detect_2 <= cnt_detect_2 + 3 + 0;
                    when "00001000" => cnt_detect_2 <= cnt_detect_2 + 1 + 0;
                    when "00001001" => cnt_detect_2 <= cnt_detect_2 + 2 + 0;
                    when "00001010" => cnt_detect_2 <= cnt_detect_2 + 2 + 0;
                    when "00001011" => cnt_detect_2 <= cnt_detect_2 + 3 + 0;
                    when "00001100" => cnt_detect_2 <= cnt_detect_2 + 2 + 0;
                    when "00001101" => cnt_detect_2 <= cnt_detect_2 + 3 + 0;
                    when "00001110" => cnt_detect_2 <= cnt_detect_2 + 3 + 0;
                    when "00001111" => cnt_detect_2 <= cnt_detect_2 + 4 + 0;

                    when "00010000" => cnt_detect_2 <= cnt_detect_2 + 0 + 1;
                    when "00010001" => cnt_detect_2 <= cnt_detect_2 + 1 + 1;
                    when "00010010" => cnt_detect_2 <= cnt_detect_2 + 1 + 1;
                    when "00010011" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "00010100" => cnt_detect_2 <= cnt_detect_2 + 1 + 1;
                    when "00010101" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "00010110" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "00010111" => cnt_detect_2 <= cnt_detect_2 + 3 + 1;
                    when "00011000" => cnt_detect_2 <= cnt_detect_2 + 1 + 1;
                    when "00011001" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "00011010" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "00011011" => cnt_detect_2 <= cnt_detect_2 + 3 + 1;
                    when "00011100" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "00011101" => cnt_detect_2 <= cnt_detect_2 + 3 + 1;
                    when "00011110" => cnt_detect_2 <= cnt_detect_2 + 3 + 1;
                    when "00011111" => cnt_detect_2 <= cnt_detect_2 + 4 + 1;

                    when "00100000" => cnt_detect_2 <= cnt_detect_2 + 0 + 1;
                    when "00100001" => cnt_detect_2 <= cnt_detect_2 + 1 + 1;
                    when "00100010" => cnt_detect_2 <= cnt_detect_2 + 1 + 1;
                    when "00100011" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "00100100" => cnt_detect_2 <= cnt_detect_2 + 1 + 1;
                    when "00100101" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "00100110" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "00100111" => cnt_detect_2 <= cnt_detect_2 + 3 + 1;
                    when "00101000" => cnt_detect_2 <= cnt_detect_2 + 1 + 1;
                    when "00101001" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "00101010" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "00101011" => cnt_detect_2 <= cnt_detect_2 + 3 + 1;
                    when "00101100" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "00101101" => cnt_detect_2 <= cnt_detect_2 + 3 + 1;
                    when "00101110" => cnt_detect_2 <= cnt_detect_2 + 3 + 1;
                    when "00101111" => cnt_detect_2 <= cnt_detect_2 + 4 + 1;

                    when "00110000" => cnt_detect_2 <= cnt_detect_2 + 0 + 2;
                    when "00110001" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "00110010" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "00110011" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "00110100" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "00110101" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "00110110" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "00110111" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "00111000" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "00111001" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "00111010" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "00111011" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "00111100" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "00111101" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "00111110" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "00111111" => cnt_detect_2 <= cnt_detect_2 + 4 + 2;

                    when "01000000" => cnt_detect_2 <= cnt_detect_2 + 0 + 1;
                    when "01000001" => cnt_detect_2 <= cnt_detect_2 + 1 + 1;
                    when "01000010" => cnt_detect_2 <= cnt_detect_2 + 1 + 1;
                    when "01000011" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "01000100" => cnt_detect_2 <= cnt_detect_2 + 1 + 1;
                    when "01000101" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "01000110" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "01000111" => cnt_detect_2 <= cnt_detect_2 + 3 + 1;
                    when "01001000" => cnt_detect_2 <= cnt_detect_2 + 1 + 1;
                    when "01001001" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "01001010" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "01001011" => cnt_detect_2 <= cnt_detect_2 + 3 + 1;
                    when "01001100" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "01001101" => cnt_detect_2 <= cnt_detect_2 + 3 + 1;
                    when "01001110" => cnt_detect_2 <= cnt_detect_2 + 3 + 1;
                    when "01001111" => cnt_detect_2 <= cnt_detect_2 + 4 + 1;

                    when "01010000" => cnt_detect_2 <= cnt_detect_2 + 0 + 2;
                    when "01010001" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "01010010" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "01010011" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "01010100" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "01010101" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "01010110" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "01010111" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "01011000" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "01011001" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "01011010" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "01011011" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "01011100" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "01011101" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "01011110" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "01011111" => cnt_detect_2 <= cnt_detect_2 + 4 + 2;

                    when "01100000" => cnt_detect_2 <= cnt_detect_2 + 0 + 2;
                    when "01100001" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "01100010" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "01100011" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "01100100" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "01100101" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "01100110" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "01100111" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "01101000" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "01101001" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "01101010" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "01101011" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "01101100" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "01101101" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "01101110" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "01101111" => cnt_detect_2 <= cnt_detect_2 + 4 + 2;

                    when "01110000" => cnt_detect_2 <= cnt_detect_2 + 0 + 3;
                    when "01110001" => cnt_detect_2 <= cnt_detect_2 + 1 + 3;
                    when "01110010" => cnt_detect_2 <= cnt_detect_2 + 1 + 3;
                    when "01110011" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "01110100" => cnt_detect_2 <= cnt_detect_2 + 1 + 3;
                    when "01110101" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "01110110" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "01110111" => cnt_detect_2 <= cnt_detect_2 + 3 + 3;
                    when "01111000" => cnt_detect_2 <= cnt_detect_2 + 1 + 3;
                    when "01111001" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "01111010" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "01111011" => cnt_detect_2 <= cnt_detect_2 + 3 + 3;
                    when "01111100" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "01111101" => cnt_detect_2 <= cnt_detect_2 + 3 + 3;
                    when "01111110" => cnt_detect_2 <= cnt_detect_2 + 3 + 3;
                    when "01111111" => cnt_detect_2 <= cnt_detect_2 + 4 + 3;

                    when "10000000" => cnt_detect_2 <= cnt_detect_2 + 0 + 1;
                    when "10000001" => cnt_detect_2 <= cnt_detect_2 + 1 + 1;
                    when "10000010" => cnt_detect_2 <= cnt_detect_2 + 1 + 1;
                    when "10000011" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "10000100" => cnt_detect_2 <= cnt_detect_2 + 1 + 1;
                    when "10000101" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "10000110" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "10000111" => cnt_detect_2 <= cnt_detect_2 + 3 + 1;
                    when "10001000" => cnt_detect_2 <= cnt_detect_2 + 1 + 1;
                    when "10001001" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "10001010" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "10001011" => cnt_detect_2 <= cnt_detect_2 + 3 + 1;
                    when "10001100" => cnt_detect_2 <= cnt_detect_2 + 2 + 1;
                    when "10001101" => cnt_detect_2 <= cnt_detect_2 + 3 + 1;
                    when "10001110" => cnt_detect_2 <= cnt_detect_2 + 3 + 1;
                    when "10001111" => cnt_detect_2 <= cnt_detect_2 + 4 + 1;

                    when "10010000" => cnt_detect_2 <= cnt_detect_2 + 0 + 2;
                    when "10010001" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "10010010" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "10010011" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "10010100" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "10010101" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "10010110" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "10010111" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "10011000" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "10011001" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "10011010" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "10011011" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "10011100" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "10011101" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "10011110" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "10011111" => cnt_detect_2 <= cnt_detect_2 + 4 + 2;

                    when "10100000" => cnt_detect_2 <= cnt_detect_2 + 0 + 2;
                    when "10100001" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "10100010" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "10100011" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "10100100" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "10100101" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "10100110" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "10100111" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "10101000" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "10101001" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "10101010" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "10101011" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "10101100" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "10101101" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "10101110" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "10101111" => cnt_detect_2 <= cnt_detect_2 + 4 + 2;

                    when "10110000" => cnt_detect_2 <= cnt_detect_2 + 0 + 3;
                    when "10110001" => cnt_detect_2 <= cnt_detect_2 + 1 + 3;
                    when "10110010" => cnt_detect_2 <= cnt_detect_2 + 1 + 3;
                    when "10110011" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "10110100" => cnt_detect_2 <= cnt_detect_2 + 1 + 3;
                    when "10110101" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "10110110" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "10110111" => cnt_detect_2 <= cnt_detect_2 + 3 + 3;
                    when "10111000" => cnt_detect_2 <= cnt_detect_2 + 1 + 3;
                    when "10111001" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "10111010" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "10111011" => cnt_detect_2 <= cnt_detect_2 + 3 + 3;
                    when "10111100" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "10111101" => cnt_detect_2 <= cnt_detect_2 + 3 + 3;
                    when "10111110" => cnt_detect_2 <= cnt_detect_2 + 3 + 3;
                    when "10111111" => cnt_detect_2 <= cnt_detect_2 + 4 + 3;

                    when "11000000" => cnt_detect_2 <= cnt_detect_2 + 0 + 2;
                    when "11000001" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "11000010" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "11000011" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "11000100" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "11000101" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "11000110" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "11000111" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "11001000" => cnt_detect_2 <= cnt_detect_2 + 1 + 2;
                    when "11001001" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "11001010" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "11001011" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "11001100" => cnt_detect_2 <= cnt_detect_2 + 2 + 2;
                    when "11001101" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "11001110" => cnt_detect_2 <= cnt_detect_2 + 3 + 2;
                    when "11001111" => cnt_detect_2 <= cnt_detect_2 + 4 + 2;

                    when "11010000" => cnt_detect_2 <= cnt_detect_2 + 0 + 3;
                    when "11010001" => cnt_detect_2 <= cnt_detect_2 + 1 + 3;
                    when "11010010" => cnt_detect_2 <= cnt_detect_2 + 1 + 3;
                    when "11010011" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "11010100" => cnt_detect_2 <= cnt_detect_2 + 1 + 3;
                    when "11010101" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "11010110" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "11010111" => cnt_detect_2 <= cnt_detect_2 + 3 + 3;
                    when "11011000" => cnt_detect_2 <= cnt_detect_2 + 1 + 3;
                    when "11011001" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "11011010" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "11011011" => cnt_detect_2 <= cnt_detect_2 + 3 + 3;
                    when "11011100" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "11011101" => cnt_detect_2 <= cnt_detect_2 + 3 + 3;
                    when "11011110" => cnt_detect_2 <= cnt_detect_2 + 3 + 3;
                    when "11011111" => cnt_detect_2 <= cnt_detect_2 + 4 + 3;

                    when "11100000" => cnt_detect_2 <= cnt_detect_2 + 0 + 3;
                    when "11100001" => cnt_detect_2 <= cnt_detect_2 + 1 + 3;
                    when "11100010" => cnt_detect_2 <= cnt_detect_2 + 1 + 3;
                    when "11100011" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "11100100" => cnt_detect_2 <= cnt_detect_2 + 1 + 3;
                    when "11100101" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "11100110" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "11100111" => cnt_detect_2 <= cnt_detect_2 + 3 + 3;
                    when "11101000" => cnt_detect_2 <= cnt_detect_2 + 1 + 3;
                    when "11101001" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "11101010" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "11101011" => cnt_detect_2 <= cnt_detect_2 + 3 + 3;
                    when "11101100" => cnt_detect_2 <= cnt_detect_2 + 2 + 3;
                    when "11101101" => cnt_detect_2 <= cnt_detect_2 + 3 + 3;
                    when "11101110" => cnt_detect_2 <= cnt_detect_2 + 3 + 3;
                    when "11101111" => cnt_detect_2 <= cnt_detect_2 + 4 + 3;

                    when "11110000" => cnt_detect_2 <= cnt_detect_2 + 0 + 4;
                    when "11110001" => cnt_detect_2 <= cnt_detect_2 + 1 + 4;
                    when "11110010" => cnt_detect_2 <= cnt_detect_2 + 1 + 4;
                    when "11110011" => cnt_detect_2 <= cnt_detect_2 + 2 + 4;
                    when "11110100" => cnt_detect_2 <= cnt_detect_2 + 1 + 4;
                    when "11110101" => cnt_detect_2 <= cnt_detect_2 + 2 + 4;
                    when "11110110" => cnt_detect_2 <= cnt_detect_2 + 2 + 4;
                    when "11110111" => cnt_detect_2 <= cnt_detect_2 + 3 + 4;
                    when "11111000" => cnt_detect_2 <= cnt_detect_2 + 1 + 4;
                    when "11111001" => cnt_detect_2 <= cnt_detect_2 + 2 + 4;
                    when "11111010" => cnt_detect_2 <= cnt_detect_2 + 2 + 4;
                    when "11111011" => cnt_detect_2 <= cnt_detect_2 + 3 + 4;
                    when "11111100" => cnt_detect_2 <= cnt_detect_2 + 2 + 4;
                    when "11111101" => cnt_detect_2 <= cnt_detect_2 + 3 + 4;
                    when "11111110" => cnt_detect_2 <= cnt_detect_2 + 3 + 4;
                    when "11111111" => cnt_detect_2 <= cnt_detect_2 + 4 + 4;

                    when others     => cnt_detect_2 <= cnt_detect_2 + 0;
                    end case;
                end if;
            end if;
        end if;
    end process;
    end generate;

end BEHAVE;