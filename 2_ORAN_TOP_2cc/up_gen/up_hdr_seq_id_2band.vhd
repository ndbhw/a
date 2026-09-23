--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : UL ecpriSeqid generation (O-RAN component)                    --
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

entity UP_HDR_SEQ_ID_2BAND is
    generic (
        MAX_CH                      : natural := 2
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;
        RST_BAND0                   : in  std_logic;
        RST_BAND1                   : in  std_logic;

--------------------------------------------------------------------------------
-- ecpriSeqid
--------------------------------------------------------------------------------

        BAND0_PACKING_TICK          : in  std_logic_vector(MAX_CH-1 downto 0);
        BAND0_PACKING_TICK_ACK      : in  std_logic;
        BAND1_PACKING_TICK          : in  std_logic_vector(MAX_CH-1 downto 0);
        BAND1_PACKING_TICK_ACK      : in  std_logic;

        BAND0_RB_SEQUENCE_ID        : out std_logic_vector(15 downto 0);
        BAND1_RB_SEQUENCE_ID        : out std_logic_vector(15 downto 0)
    );
end UP_HDR_SEQ_ID_2BAND;

architecture BEHAVE of UP_HDR_SEQ_ID_2BAND is

    constant ALL_ZERO               : std_logic_vector(MAX_CH-1 downto 0) := (others => '0');

    signal band0_packing_tick_sh    : std_logic_vector(MAX_CH-1 downto 0) := (others => '0');
    signal band1_packing_tick_sh    : std_logic_vector(MAX_CH-1 downto 0) := (others => '0');

    signal band0_tick               : std_logic := '0';
    signal band1_tick               : std_logic := '0';

    signal cnt_seed                 : std_logic_array8(31 downto 0) := (others => (others => '0'));
    signal band0_cnt_seed           : std_logic_array8(31 downto 0) := (others => (others => '0'));
    signal band1_cnt_seed           : std_logic_array8(31 downto 0) := (others => (others => '0'));

    signal band0_seq_id             : std_logic_vector(7 downto 0) := (others => '0');
    signal band1_seq_id             : std_logic_vector(7 downto 0) := (others => '0');

    constant HDR_BUF                : natural := 2;
    signal band0_seq_id_buf         : std_logic_array8(HDR_BUF-1 downto 0) := (others => (others => '0'));
    signal band0_index_wr           : natural range 0 to HDR_BUF;
    signal band0_index_rd           : natural range 0 to HDR_BUF-1;
    signal band1_seq_id_buf         : std_logic_array8(HDR_BUF-1 downto 0) := (others => (others => '0'));
    signal band1_index_wr           : natural range 0 to HDR_BUF;
    signal band1_index_rd           : natural range 0 to HDR_BUF-1;

begin

    BAND0_RB_SEQUENCE_ID <= band0_seq_id_buf(band0_index_rd) & x"80";
    BAND1_RB_SEQUENCE_ID <= band1_seq_id_buf(band1_index_rd) & x"80";

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            band0_packing_tick_sh <= BAND0_PACKING_TICK;
            band1_packing_tick_sh <= BAND1_PACKING_TICK;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (BAND0_PACKING_TICK /= ALL_ZERO) then
                band0_tick <= '1';
            else
                band0_tick <= '0';
            end if;
        end if;
    end process;

    band0_seq_id_buf(0) <= band0_seq_id;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (band0_tick = '1') then
                band0_seq_id_buf(1) <= band0_seq_id_buf(0);
            end if;
        end if;
    end process;

    process (RST_BAND0, CLK)
    begin
        if (RST_BAND0 = '1') then
            band0_index_wr <= 0;
            band0_index_rd <= 0;
        elsif (CLK'event and CLK = '1') then
            if (band0_tick = '1') then
                if (BAND0_PACKING_TICK_ACK = '1') then
                    band0_index_wr <= band0_index_wr;
                else
                    band0_index_wr <= band0_index_wr + 1;
                end if;
            else
                if (BAND0_PACKING_TICK_ACK = '1') then
                    if (band0_index_wr = 0) then
                        band0_index_wr <= 0;
                    else
                        band0_index_wr <= band0_index_wr - 1;
                    end if;
                end if;
            end if;
            if (band0_tick = '1') then
                if (BAND0_PACKING_TICK_ACK = '1') then
                    band0_index_rd <= band0_index_rd;
                else
                    band0_index_rd <= band0_index_wr;
                end if;
            else
                if (BAND0_PACKING_TICK_ACK = '1') then
                    if (band0_index_rd = 0) then
                        band0_index_rd <= 0;
                    else
                        band0_index_rd <= band0_index_rd - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (BAND1_PACKING_TICK /= ALL_ZERO) then
                band1_tick <= '1';
            else
                band1_tick <= '0';
            end if;
        end if;
    end process;

    band1_seq_id_buf(0) <= band1_seq_id;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (band1_tick = '1') then
                band1_seq_id_buf(1) <= band1_seq_id_buf(0);
            end if;
        end if;
    end process;

    process (RST_BAND1, CLK)
    begin
        if (RST_BAND1 = '1') then
            band1_index_wr <= 0;
            band1_index_rd <= 0;
        elsif (CLK'event and CLK = '1') then
            if (band1_tick = '1') then
                if (BAND1_PACKING_TICK_ACK = '1') then
                    band1_index_wr <= band1_index_wr;
                else
                    band1_index_wr <= band1_index_wr + 1;
                end if;
            else
                if (BAND1_PACKING_TICK_ACK = '1') then
                    if (band1_index_wr = 0) then
                        band1_index_wr <= 0;
                    else
                        band1_index_wr <= band1_index_wr - 1;
                    end if;
                end if;
            end if;
            if (band1_tick = '1') then
                if (BAND1_PACKING_TICK_ACK = '1') then
                    band1_index_rd <= band1_index_rd;
                else
                    band1_index_rd <= band1_index_wr;
                end if;
            else
                if (BAND1_PACKING_TICK_ACK = '1') then
                    if (band1_index_rd = 0) then
                        band1_index_rd <= 0;
                    else
                        band1_index_rd <= band1_index_rd - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    u_2CHANNEL : if MAX_CH = 2 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (band0_packing_tick_sh(0) = '1') then
                band0_seq_id <= band0_cnt_seed(0);
            elsif (band0_packing_tick_sh(1) = '1') then
                band0_seq_id <= band0_cnt_seed(1);
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (band1_packing_tick_sh(0) = '1') then
                band1_seq_id <= band1_cnt_seed(0);
            elsif (band1_packing_tick_sh(1) = '1') then
                band1_seq_id <= band1_cnt_seed(1);
            end if;
        end if;
    end process;
    end generate;

    u_4CHANNEL : if MAX_CH = 4 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (band0_packing_tick_sh(0) = '1') then
                band0_seq_id <= band0_cnt_seed(0);
            elsif (band0_packing_tick_sh(1) = '1') then
                band0_seq_id <= band0_cnt_seed(1);
            elsif (band0_packing_tick_sh(2) = '1') then
                band0_seq_id <= band0_cnt_seed(2);
            elsif (band0_packing_tick_sh(3) = '1') then
                band0_seq_id <= band0_cnt_seed(3);
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (band1_packing_tick_sh(0) = '1') then
                band1_seq_id <= band1_cnt_seed(0);
            elsif (band1_packing_tick_sh(1) = '1') then
                band1_seq_id <= band1_cnt_seed(1);
            elsif (band1_packing_tick_sh(2) = '1') then
                band1_seq_id <= band1_cnt_seed(2);
            elsif (band1_packing_tick_sh(3) = '1') then
                band1_seq_id <= band1_cnt_seed(3);
            end if;
        end if;
    end process;
    end generate;

    u_8CHANNEL : if MAX_CH = 8 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (band0_packing_tick_sh(0) = '1') then
                band0_seq_id <= band0_cnt_seed(0);
            elsif (band0_packing_tick_sh(1) = '1') then
                band0_seq_id <= band0_cnt_seed(1);
            elsif (band0_packing_tick_sh(2) = '1') then
                band0_seq_id <= band0_cnt_seed(2);
            elsif (band0_packing_tick_sh(3) = '1') then
                band0_seq_id <= band0_cnt_seed(3);
            elsif (band0_packing_tick_sh(4) = '1') then
                band0_seq_id <= band0_cnt_seed(4);
            elsif (band0_packing_tick_sh(5) = '1') then
                band0_seq_id <= band0_cnt_seed(5);
            elsif (band0_packing_tick_sh(6) = '1') then
                band0_seq_id <= band0_cnt_seed(6);
            elsif (band0_packing_tick_sh(7) = '1') then
                band0_seq_id <= band0_cnt_seed(7);
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (band1_packing_tick_sh(0) = '1') then
                band1_seq_id <= band1_cnt_seed(0);
            elsif (band1_packing_tick_sh(1) = '1') then
                band1_seq_id <= band1_cnt_seed(1);
            elsif (band1_packing_tick_sh(2) = '1') then
                band1_seq_id <= band1_cnt_seed(2);
            elsif (band1_packing_tick_sh(3) = '1') then
                band1_seq_id <= band1_cnt_seed(3);
            elsif (band1_packing_tick_sh(4) = '1') then
                band1_seq_id <= band1_cnt_seed(4);
            elsif (band1_packing_tick_sh(5) = '1') then
                band1_seq_id <= band1_cnt_seed(5);
            elsif (band1_packing_tick_sh(6) = '1') then
                band1_seq_id <= band1_cnt_seed(6);
            elsif (band1_packing_tick_sh(7) = '1') then
                band1_seq_id <= band1_cnt_seed(7);
            end if;
        end if;
    end process;
    end generate;

    u_CH : for i in MAX_CH-1 downto 0 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (BAND0_PACKING_TICK(i) = '1') and (BAND1_PACKING_TICK(i) = '1') then
                cnt_seed(i)       <= cnt_seed(i) + 2;
                band0_cnt_seed(i) <= cnt_seed(i);
                band1_cnt_seed(i) <= cnt_seed(i) + 1;
            else
                if    (BAND0_PACKING_TICK(i) = '1') then
                    cnt_seed(i)       <= cnt_seed(i) + 1;
                    band0_cnt_seed(i) <= cnt_seed(i);
--                    band1_cnt_seed(i) <= cnt_seed(i);
                elsif (BAND1_PACKING_TICK(i) = '1') then
                    cnt_seed(i)       <= cnt_seed(i) + 1;
--                    band0_cnt_seed(i) <= cnt_seed(i);
                    band1_cnt_seed(i) <= cnt_seed(i);
                end if;
            end if;
        end if;
    end process;
    end generate;

end BEHAVE;