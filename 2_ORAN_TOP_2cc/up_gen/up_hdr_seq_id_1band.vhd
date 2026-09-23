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

entity UP_HDR_SEQ_ID_1BAND is
    generic (
        MAX_CH                      : natural := 2
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;
        RST                         : in  std_logic;

--------------------------------------------------------------------------------
-- ecpriSeqid
--------------------------------------------------------------------------------

        PACKING_TICK                : in  std_logic_vector(MAX_CH-1 downto 0);
        PACKING_TICK_ACK            : in  std_logic;

        RB_SEQUENCE_ID              : out std_logic_vector(15 downto 0)
    );
end UP_HDR_SEQ_ID_1BAND;

architecture BEHAVE of UP_HDR_SEQ_ID_1BAND is

    signal tick                     : std_logic_vector(MAX_CH-1 downto 0) := (others => '0');

    signal cnt_seed                 : std_logic_array8(31 downto 0) := (others => (others => '0'));
    signal seq_id                   : std_logic_vector(7 downto 0) := (others => '0');

    constant HDR_BUF                : natural := 2;
    signal seq_id_buf               : std_logic_array8(HDR_BUF-1 downto 0) := (others => (others => '0'));
    signal index_wr                 : natural range 0 to HDR_BUF;
    signal index_rd                 : natural range 0 to HDR_BUF-1;

begin

    RB_SEQUENCE_ID <= seq_id_buf(index_rd) & x"80";

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            tick(MAX_CH-1 downto 0) <= PACKING_TICK;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (tick /= 0) then
                seq_id_buf <= seq_id_buf(HDR_BUF-2 downto 0) & seq_id;
            end if;
        end if;
    end process;

    process (RST, CLK)
    begin
        if (RST = '1') then
            index_wr <= 0;
            index_rd <= 0;
        elsif (CLK'event and CLK = '1') then
            if (tick /= 0) then
                if (PACKING_TICK_ACK = '1') then
                    index_wr <= index_wr;
                else
                    index_wr <= index_wr + 1;
                end if;
            else
                if (PACKING_TICK_ACK = '1') then
                    if (index_wr = 0) then
                        index_wr <= 0;
                    else
                        index_wr <= index_wr - 1;
                    end if;
                end if;
            end if;
            if (tick /= 0) then
                if (PACKING_TICK_ACK = '1') then
                    index_rd <= index_rd;
                else
                    index_rd <= index_wr;
                end if;
            else
                if (PACKING_TICK_ACK = '1') then
                    if (index_rd = 0) then
                        index_rd <= 0;
                    else
                        index_rd <= index_rd - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    u_2CHANNEL : if MAX_CH = 2 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (PACKING_TICK(0) = '1') then
                seq_id <= cnt_seed(0);
            elsif (PACKING_TICK(1) = '1') then
                seq_id <= cnt_seed(1);
            end if;
        end if;
    end process;
    end generate;

    u_4CHANNEL : if MAX_CH = 4 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (PACKING_TICK(0) = '1') then
                seq_id <= cnt_seed(0);
            elsif (PACKING_TICK(1) = '1') then
                seq_id <= cnt_seed(1);
            elsif (PACKING_TICK(2) = '1') then
                seq_id <= cnt_seed(2);
            elsif (PACKING_TICK(3) = '1') then
                seq_id <= cnt_seed(3);
            end if;
        end if;
    end process;
    end generate;

    u_8CHANNEL : if MAX_CH = 8 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (PACKING_TICK(0) = '1') then
                seq_id <= cnt_seed(0);
            elsif (PACKING_TICK(1) = '1') then
                seq_id <= cnt_seed(1);
            elsif (PACKING_TICK(2) = '1') then
                seq_id <= cnt_seed(2);
            elsif (PACKING_TICK(3) = '1') then
                seq_id <= cnt_seed(3);
            elsif (PACKING_TICK(4) = '1') then
                seq_id <= cnt_seed(4);
            elsif (PACKING_TICK(5) = '1') then
                seq_id <= cnt_seed(5);
            elsif (PACKING_TICK(6) = '1') then
                seq_id <= cnt_seed(6);
            elsif (PACKING_TICK(7) = '1') then
                seq_id <= cnt_seed(7);
            end if;
        end if;
    end process;
    end generate;

    u_CH : for i in MAX_CH-1 downto 0 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (PACKING_TICK(i) = '1') then
                cnt_seed(i) <= cnt_seed(i) + 1;
            end if;
        end if;
    end process;
    end generate;

end BEHAVE;