--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : UL ecpriRtc/Pcid generation (O-RAN component)                 --
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

entity UP_HDR_RTCPC_ID is
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

        RTCPC_ID                    : in  std_logic_array16(MAX_CH-1 downto 0);

        RB_UPDATE                   : out std_logic;
        RB_eAxC_ID                  : out std_logic_vector(15 downto 0)
    );
end UP_HDR_RTCPC_ID;

architecture BEHAVE of UP_HDR_RTCPC_ID is

    signal tick_history             : std_logic := '0';
    signal tick                     : std_logic := '0';

    signal id                       : std_logic_vector(15 downto 0) := (others => '0');

    constant HDR_BUF                : natural := 2;
    signal id_buf                   : std_logic_array16(HDR_BUF-1 downto 0) := (others => (others => '0'));
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

    RB_eAxC_ID <= id_buf(index_rd);

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
                id <= RTCPC_ID(0);
            end if;
        end if;
    end process;
    end generate;

    u_2CHANNEL : if MAX_CH = 2 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (PACKING_TICK(0) = '1') then
                id <= RTCPC_ID(0);
            elsif (PACKING_TICK(1) = '1') then
                id <= RTCPC_ID(1);
            end if;
        end if;
    end process;
    end generate;

    u_4CHANNEL : if MAX_CH = 4 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (PACKING_TICK(0) = '1') then
                id <= RTCPC_ID(0);
            elsif (PACKING_TICK(1) = '1') then
                id <= RTCPC_ID(1);
            elsif (PACKING_TICK(2) = '1') then
                id <= RTCPC_ID(2);
            elsif (PACKING_TICK(3) = '1') then
                id <= RTCPC_ID(3);
            end if;
        end if;
    end process;
    end generate;

    u_8CHANNEL : if MAX_CH = 8 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (PACKING_TICK(0) = '1') then
                id <= RTCPC_ID(0);
            elsif (PACKING_TICK(1) = '1') then
                id <= RTCPC_ID(1);
            elsif (PACKING_TICK(2) = '1') then
                id <= RTCPC_ID(2);
            elsif (PACKING_TICK(3) = '1') then
                id <= RTCPC_ID(3);
            elsif (PACKING_TICK(4) = '1') then
                id <= RTCPC_ID(4);
            elsif (PACKING_TICK(5) = '1') then
                id <= RTCPC_ID(5);
            elsif (PACKING_TICK(6) = '1') then
                id <= RTCPC_ID(6);
            elsif (PACKING_TICK(7) = '1') then
                id <= RTCPC_ID(7);
            end if;
        end if;
    end process;
    end generate;

    u_16CHANNEL : if MAX_CH = 16 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (PACKING_TICK(0) = '1') then
                id <= RTCPC_ID(0);
            elsif (PACKING_TICK(1) = '1') then
                id <= RTCPC_ID(1);
            elsif (PACKING_TICK(2) = '1') then
                id <= RTCPC_ID(2);
            elsif (PACKING_TICK(3) = '1') then
                id <= RTCPC_ID(3);
            elsif (PACKING_TICK(4) = '1') then
                id <= RTCPC_ID(4);
            elsif (PACKING_TICK(5) = '1') then
                id <= RTCPC_ID(5);
            elsif (PACKING_TICK(6) = '1') then
                id <= RTCPC_ID(6);
            elsif (PACKING_TICK(7) = '1') then
                id <= RTCPC_ID(7);
            elsif (PACKING_TICK(8) = '1') then
                id <= RTCPC_ID(8);
            elsif (PACKING_TICK(9) = '1') then
                id <= RTCPC_ID(9);
            elsif (PACKING_TICK(10) = '1') then
                id <= RTCPC_ID(10);
            elsif (PACKING_TICK(11) = '1') then
                id <= RTCPC_ID(11);
            elsif (PACKING_TICK(12) = '1') then
                id <= RTCPC_ID(12);
            elsif (PACKING_TICK(13) = '1') then
                id <= RTCPC_ID(13);
            elsif (PACKING_TICK(14) = '1') then
                id <= RTCPC_ID(14);
            elsif (PACKING_TICK(15) = '1') then
                id <= RTCPC_ID(15);
            end if;
        end if;
    end process;
    end generate;

    u_32CHANNEL : if MAX_CH = 32 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (PACKING_TICK(0) = '1') then
                id <= RTCPC_ID(0);
            elsif (PACKING_TICK(1) = '1') then
                id <= RTCPC_ID(1);
            elsif (PACKING_TICK(2) = '1') then
                id <= RTCPC_ID(2);
            elsif (PACKING_TICK(3) = '1') then
                id <= RTCPC_ID(3);
            elsif (PACKING_TICK(4) = '1') then
                id <= RTCPC_ID(4);
            elsif (PACKING_TICK(5) = '1') then
                id <= RTCPC_ID(5);
            elsif (PACKING_TICK(6) = '1') then
                id <= RTCPC_ID(6);
            elsif (PACKING_TICK(7) = '1') then
                id <= RTCPC_ID(7);
            elsif (PACKING_TICK(8) = '1') then
                id <= RTCPC_ID(8);
            elsif (PACKING_TICK(9) = '1') then
                id <= RTCPC_ID(9);
            elsif (PACKING_TICK(10) = '1') then
                id <= RTCPC_ID(10);
            elsif (PACKING_TICK(11) = '1') then
                id <= RTCPC_ID(11);
            elsif (PACKING_TICK(12) = '1') then
                id <= RTCPC_ID(12);
            elsif (PACKING_TICK(13) = '1') then
                id <= RTCPC_ID(13);
            elsif (PACKING_TICK(14) = '1') then
                id <= RTCPC_ID(14);
            elsif (PACKING_TICK(15) = '1') then
                id <= RTCPC_ID(15);
            elsif (PACKING_TICK(16) = '1') then
                id <= RTCPC_ID(16);
            elsif (PACKING_TICK(17) = '1') then
                id <= RTCPC_ID(17);
            elsif (PACKING_TICK(18) = '1') then
                id <= RTCPC_ID(18);
            elsif (PACKING_TICK(19) = '1') then
                id <= RTCPC_ID(19);
            elsif (PACKING_TICK(20) = '1') then
                id <= RTCPC_ID(20);
            elsif (PACKING_TICK(21) = '1') then
                id <= RTCPC_ID(21);
            elsif (PACKING_TICK(22) = '1') then
                id <= RTCPC_ID(22);
            elsif (PACKING_TICK(23) = '1') then
                id <= RTCPC_ID(23);
            elsif (PACKING_TICK(24) = '1') then
                id <= RTCPC_ID(24);
            elsif (PACKING_TICK(25) = '1') then
                id <= RTCPC_ID(25);
            elsif (PACKING_TICK(26) = '1') then
                id <= RTCPC_ID(26);
            elsif (PACKING_TICK(27) = '1') then
                id <= RTCPC_ID(27);
            elsif (PACKING_TICK(28) = '1') then
                id <= RTCPC_ID(28);
            elsif (PACKING_TICK(29) = '1') then
                id <= RTCPC_ID(29);
            elsif (PACKING_TICK(30) = '1') then
                id <= RTCPC_ID(30);
            elsif (PACKING_TICK(31) = '1') then
                id <= RTCPC_ID(31);
            end if;
        end if;
    end process;
    end generate;

end BEHAVE;