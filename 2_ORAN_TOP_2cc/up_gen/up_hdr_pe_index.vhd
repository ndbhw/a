--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : UL output port ID (O-RAN component)                           --
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

entity UP_HDR_PE_INDEX is
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
-- RTC/PC_ID
--------------------------------------------------------------------------------

        PACKING_TICK                : in  std_logic_vector(MAX_CH-1 downto 0);
        PACKING_TICK_ACK            : in  std_logic;

        PE_INDEX                    : in  std_logic_array3(MAX_CH-1 downto 0);

        RB_UPDATE                   : out std_logic;
        RB_PE_INDEX                 : out std_logic_vector(2 downto 0)
    );
end UP_HDR_PE_INDEX;

architecture BEHAVE of UP_HDR_PE_INDEX is

    signal tick_history             : std_logic := '0';
    signal tick                     : std_logic := '0';

    signal id                       : std_logic_vector(2 downto 0) := (others => '0');

    constant HDR_BUF                : natural := 2;
    signal id_buf                   : std_logic_array3(HDR_BUF-1 downto 0) := (others => (others => '0'));
    signal index_wr                 : natural range 0 to HDR_BUF;
    signal index_rd                 : natural range 0 to HDR_BUF-1;

begin

    process (RST, CLK)
    begin
        if (RST = '1') then
            tick_history <= '0';
        elsif (CLK'event and CLK = '1') then
            if (PACKING_TICK_ACK = '1') then
                if (PACKING_TICK(MAX_CH-1 downto 0) /= 0) then
                    tick_history <= '1';
                else
                    tick_history <= '0';
                end if;
            else
                if (PACKING_TICK(MAX_CH-1 downto 0) /= 0) then
                    tick_history <= '1';
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (tick = '1') or (PACKING_TICK_ACK = '1') then
                RB_UPDATE <= tick_history;
            else
                RB_UPDATE <= '0';
            end if;
        end if;
    end process;

    RB_PE_INDEX <= id_buf(index_rd);

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (PACKING_TICK(MAX_CH-1 downto 0) /= 0) then
                tick <= '1';
            else
                tick <= '0';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (tick = '1') then
                id_buf <= id_buf(HDR_BUF-2 downto 0) & id;
            end if;
        end if;
    end process;

    process (RST, CLK)
    begin
        if (RST = '1') then
            index_wr <= 0;
            index_rd <= 0;
        elsif (CLK'event and CLK = '1') then
            if (tick = '1') then
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
            if (tick = '1') then
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

    u_1CHANNEL : if MAX_CH = 1 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (PACKING_TICK(0) = '1') then
                id <= PE_INDEX(0);
            end if;
        end if;
    end process;
    end generate;

    u_2CHANNEL : if MAX_CH = 2 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (PACKING_TICK(0) = '1') then
                id <= PE_INDEX(0);
            elsif (PACKING_TICK(1) = '1') then
                id <= PE_INDEX(1);
            end if;
        end if;
    end process;
    end generate;

    u_4CHANNEL : if MAX_CH = 4 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (PACKING_TICK(0) = '1') then
                id <= PE_INDEX(0);
            elsif (PACKING_TICK(1) = '1') then
                id <= PE_INDEX(1);
            elsif (PACKING_TICK(2) = '1') then
                id <= PE_INDEX(2);
            elsif (PACKING_TICK(3) = '1') then
                id <= PE_INDEX(3);
            end if;
        end if;
    end process;
    end generate;

    u_8CHANNEL : if MAX_CH = 8 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (PACKING_TICK(0) = '1') then
                id <= PE_INDEX(0);
            elsif (PACKING_TICK(1) = '1') then
                id <= PE_INDEX(1);
            elsif (PACKING_TICK(2) = '1') then
                id <= PE_INDEX(2);
            elsif (PACKING_TICK(3) = '1') then
                id <= PE_INDEX(3);
            elsif (PACKING_TICK(4) = '1') then
                id <= PE_INDEX(4);
            elsif (PACKING_TICK(5) = '1') then
                id <= PE_INDEX(5);
            elsif (PACKING_TICK(6) = '1') then
                id <= PE_INDEX(6);
            elsif (PACKING_TICK(7) = '1') then
                id <= PE_INDEX(7);
            end if;
        end if;
    end process;
    end generate;

    u_16CHANNEL : if MAX_CH = 16 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (PACKING_TICK(0) = '1') then
                id <= PE_INDEX(0);
            elsif (PACKING_TICK(1) = '1') then
                id <= PE_INDEX(1);
            elsif (PACKING_TICK(2) = '1') then
                id <= PE_INDEX(2);
            elsif (PACKING_TICK(3) = '1') then
                id <= PE_INDEX(3);
            elsif (PACKING_TICK(4) = '1') then
                id <= PE_INDEX(4);
            elsif (PACKING_TICK(5) = '1') then
                id <= PE_INDEX(5);
            elsif (PACKING_TICK(6) = '1') then
                id <= PE_INDEX(6);
            elsif (PACKING_TICK(7) = '1') then
                id <= PE_INDEX(7);
            elsif (PACKING_TICK(8) = '1') then
                id <= PE_INDEX(8);
            elsif (PACKING_TICK(9) = '1') then
                id <= PE_INDEX(9);
            elsif (PACKING_TICK(10) = '1') then
                id <= PE_INDEX(10);
            elsif (PACKING_TICK(11) = '1') then
                id <= PE_INDEX(11);
            elsif (PACKING_TICK(12) = '1') then
                id <= PE_INDEX(12);
            elsif (PACKING_TICK(13) = '1') then
                id <= PE_INDEX(13);
            elsif (PACKING_TICK(14) = '1') then
                id <= PE_INDEX(14);
            elsif (PACKING_TICK(15) = '1') then
                id <= PE_INDEX(15);
            end if;
        end if;
    end process;
    end generate;

end BEHAVE;