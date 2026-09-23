--------------------------------------------------------------------------------
--
-- Copyright (C) 2022, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2022.02.16
--------------------------------------------------------------------------------
-- Function description
--   1. Performance measurement component
--   2. RX window monitoring
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2022.02.16) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use WORK.PKG_ORAN.ALL;

entity RX_WINDOW is
    generic (
        SCS_CONFIG                  : natural := 0
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

        WINDOW_START                : in  std_logic_vector(21 downto 0);
        WINDOW_END                  : in  std_logic_vector(21 downto 0);
        WINDOW_PERIOD               : in  std_logic_vector(7 downto 0);

--------------------------------------------------------------------------------
-- Synchronization
--------------------------------------------------------------------------------

        REF_10msec                  : in  std_logic;                            -- Longer than 1-clocks@245.76-MHz
        REF_SFN                     : in  std_logic_vector(7 downto 0);

--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

        CNT_CLEAR                   : in  std_logic;

        CNT_ON_TIME                 : out std_logic_vector(63 downto 0);
        CNT_EARLY                   : out std_logic_vector(63 downto 0);
        CNT_LATE                    : out std_logic_vector(63 downto 0);
        CNT_NDM                     : out std_logic_vector(63 downto 0);

--------------------------------------------------------------------------------
-- Packet stamp
--------------------------------------------------------------------------------

        CLK_PACKET                  : in  std_logic;
        UPDATE_EN_OUT               : out std_logic;

        PACKET_EN                   : in  std_logic;
        PACKET_IS_NDM               : in  std_logic;
        PACKET_SCS                  : in  std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             : in  std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          : in  std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              : in  std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            : in  std_logic_vector(5 downto 0)
    );
end RX_WINDOW;

architecture BEHAVE of RX_WINDOW is

    signal update_long_pulse        : std_logic_vector(15 downto 0) := (others => '0');
    signal update_buf               : std_logic_vector(2 downto 0) := (others => '0');
    signal update_cnt_sec           : std_logic_vector(6 downto 0) := (others => '0');
    signal update_cnt               : std_logic_vector(7 downto 0) := (others => '0');
    signal update_en                : std_logic := '0';

    signal cnt_detect_on_time       : std_logic_vector(63 downto 0) := (others => '0');
    signal cnt_detect_early         : std_logic_vector(63 downto 0) := (others => '0');
    signal cnt_detect_late          : std_logic_vector(63 downto 0) := (others => '0');
    signal cnt_detect_oor           : std_logic_vector(63 downto 0) := (others => '0');
    signal cnt_detect_ndm           : std_logic_vector(63 downto 0) := (others => '0');

    component ADV_TIMER is
    generic (
        SCS_CONFIG                  : natural := 0
    );
    port (
        CLK_245p76MHz               : in  std_logic;
        CLK_CDC                     : in  std_logic;

        START_VALUE                 : in  std_logic_vector(21 downto 0);

        REF_10msec                  : in  std_logic;
        REF_SFN                     : in  std_logic_vector(7 downto 0);

        FRAME_ID                    : out std_logic_vector(7 downto 0);
        SUBFRAME_ID                 : out std_logic_vector(3 downto 0);
        SLOT_ID                     : out std_logic_vector(3 downto 0);
        SYMBOL_ID                   : out std_logic_vector(3 downto 0)
    );
    end component;

    signal early_frame_id           : std_logic_vector(7 downto 0);
    signal early_subframe_id        : std_logic_vector(3 downto 0);
    signal early_slot_id            : std_logic_vector(5 downto 0);
    signal early_symbol_id          : std_logic_vector(5 downto 0);
    signal late_frame_id            : std_logic_vector(7 downto 0);
    signal late_subframe_id         : std_logic_vector(3 downto 0);
    signal late_slot_id             : std_logic_vector(3 downto 0);
    signal late_symbol_id           : std_logic_vector(3 downto 0);

    signal later_than_early         : std_logic_vector(2 downto 0) := (others => '0');
    signal earlier_than_late        : std_logic_vector(2 downto 0) := (others => '0');
    signal check                    : std_logic := '0';
    signal check_ndm                : std_logic := '0';
    signal det_on_time              : std_logic_vector(3 downto 0) := (others => '0');
    signal det_early                : std_logic_vector(3 downto 0) := (others => '0');
    signal det_late                 : std_logic_vector(3 downto 0) := (others => '0');
    signal det_oor                  : std_logic_vector(3 downto 0) := (others => '0');
    signal det_ndm                  : std_logic_vector(3 downto 0) := (others => '0');
    signal cdc_on_time              : std_logic_vector(3 downto 0) := (others => '0');
    signal cdc_early                : std_logic_vector(3 downto 0) := (others => '0');
    signal cdc_late                 : std_logic_vector(3 downto 0) := (others => '0');
    signal cdc_oor                  : std_logic_vector(3 downto 0) := (others => '0');
    signal cdc_ndm                  : std_logic_vector(3 downto 0) := (others => '0');

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
            UPDATE_EN_OUT <= update_en;
            
        end if;
    end process;

    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            if (update_en = '1') then
                CNT_ON_TIME <= cnt_detect_on_time;
            elsif (CNT_CLEAR = '1') then
                CNT_ON_TIME <= (others => '0');
            end if;
        end if;
    end process;

    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            if (update_en = '1') then
                CNT_EARLY <= cnt_detect_early;
            elsif (CNT_CLEAR = '1') then
                CNT_EARLY <= (others => '0');
            end if;
        end if;
    end process;

    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            if (update_en = '1') then
                CNT_LATE <= cnt_detect_late + cnt_detect_oor;
            elsif (CNT_CLEAR = '1') then
                CNT_LATE <= (others => '0');
            end if;
        end if;
    end process;

    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            if (update_en = '1') then
                CNT_NDM <= cnt_detect_ndm;
            elsif (CNT_CLEAR = '1') then
                CNT_NDM <= (others => '0');
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Window check
--------------------------------------------------------------------------------

    u_EARLY_TIMER : ADV_TIMER
    generic map(
        SCS_CONFIG                  => SCS_CONFIG                               --: natural := 0
    )
    port map(
        CLK_245p76MHz               => CLK_245p76MHz                           ,--: in  std_logic;
        CLK_CDC                     => CLK_PACKET                              ,--: in  std_logic;

        START_VALUE                 => WINDOW_START                            ,--: in  std_logic_vector(21 downto 0);

        REF_10msec                  => REF_10msec                              ,--: in  std_logic;
        REF_SFN                     => REF_SFN                                 ,--: in  std_logic_vector(7 downto 0);

        FRAME_ID                    => early_frame_id                          ,--: out std_logic_vector(7 downto 0);
        SUBFRAME_ID                 => early_subframe_id                       ,--: out std_logic_vector(3 downto 0);
        SLOT_ID                     => early_slot_id(3 downto 0)               ,--: out std_logic_vector(3 downto 0);
        SYMBOL_ID                   => early_symbol_id(3 downto 0)              --: out std_logic_vector(3 downto 0)
    );

    u_LATE_TIMER : ADV_TIMER
    generic map(
        SCS_CONFIG                  => SCS_CONFIG                               --: natural := 0
    )
    port map(
        CLK_245p76MHz               => CLK_245p76MHz                           ,--: in  std_logic;
        CLK_CDC                     => CLK_PACKET                              ,--: in  std_logic;

        START_VALUE                 => WINDOW_END                              ,--: in  std_logic_vector(21 downto 0);

        REF_10msec                  => REF_10msec                              ,--: in  std_logic;
        REF_SFN                     => REF_SFN                                 ,--: in  std_logic_vector(7 downto 0);

        FRAME_ID                    => late_frame_id                           ,--: out std_logic_vector(7 downto 0);
        SUBFRAME_ID                 => late_subframe_id                        ,--: out std_logic_vector(3 downto 0);
        SLOT_ID                     => late_slot_id(3 downto 0)                ,--: out std_logic_vector(3 downto 0);
        SYMBOL_ID                   => late_symbol_id(3 downto 0)               --: out std_logic_vector(3 downto 0)
    );

    -- detect whether packet is arrived later than start of RX window (frameId & subframeId)
    process (CLK_PACKET)
    begin
        if (CLK_PACKET'event and CLK_PACKET = '1') then
            if (PACKET_EN = '1') then
                if (PACKET_FRAME_ID = early_frame_id) then
--                    if (PACKET_SUBFRAME_ID <= early_subframe_id) then
                        later_than_early(0) <= '1';
--                    else
--                        later_than_early(0) <= '0';
--                    end if;
                else
                    if (early_frame_id - PACKET_FRAME_ID = 1) then
                        later_than_early(0) <= '1';
                    else
                        later_than_early(0) <= '0';
                    end if;
                end if;
            else
                later_than_early(0) <= '0';
            end if;
        end if;
    end process;

    -- detect whether packet is arrived later than start of RX window (subframeId & slotId)
    process (CLK_PACKET)
    begin
        if (CLK_PACKET'event and CLK_PACKET = '1') then
            if (PACKET_EN = '1') then
                if (PACKET_SUBFRAME_ID = early_subframe_id) then
                    if    (SCS_CONFIG = 0) and ((PACKET_SCS(3) = '1') or (PACKET_SCS(2 downto 0) = 0)) then
--                        if (PACKET_SLOT_ID <= early_slot_id) then
                            later_than_early(1) <= '1';
--                        else
--                            later_than_early(1) <= '0';
--                        end if;
                    elsif (SCS_CONFIG = 1) and (PACKET_SCS = 1) then
                        if (PACKET_SLOT_ID <= early_slot_id) then
                            later_than_early(1) <= '1';
                        else
                            later_than_early(1) <= '0';
                        end if;
                    elsif (SCS_CONFIG = 2) and (PACKET_SCS = 2) then
                        if (PACKET_SLOT_ID <= early_slot_id) then
                            later_than_early(1) <= '1';
                        else
                            later_than_early(1) <= '0';
                        end if;
                    elsif (SCS_CONFIG = 3) and (PACKET_SCS = 3) then
                        if (PACKET_SLOT_ID <= early_slot_id) then
                            later_than_early(1) <= '1';
                        else
                            later_than_early(1) <= '0';
                        end if;
                    elsif (SCS_CONFIG = 4) and (PACKET_SCS = 4) then
                        if (PACKET_SLOT_ID <= early_slot_id) then
                            later_than_early(1) <= '1';
                        else
                            later_than_early(1) <= '0';
                        end if;
                    else
                        later_than_early(1) <= '0';
                    end if;
                else
                    if (PACKET_SUBFRAME_ID = 9) then
                        if (early_subframe_id = 0) then
                            later_than_early(1) <= '1';
                        else
                            later_than_early(1) <= '0';
                        end if;
                    else
                        if (early_subframe_id - PACKET_SUBFRAME_ID = 1) then
                            later_than_early(1) <= '1';
                        else
                            later_than_early(1) <= '0';
                        end if;
                    end if;
                end if;
            else
                later_than_early(1) <= '0';
            end if;
        end if;
    end process;

    -- detect whether packet is arrived later than start of RX window (slotId & symbolid)
    process (CLK_PACKET)
    begin
        if (CLK_PACKET'event and CLK_PACKET = '1') then
            if (PACKET_EN = '1') then
                if    (SCS_CONFIG = 0) and ((PACKET_SCS(3) = '1') or (PACKET_SCS(2 downto 0) = 0)) then
--                    if (PACKET_SLOT_ID = early_slot_id) then
                    if (PACKET_SUBFRAME_ID = early_subframe_id) then
                        if (PACKET_SYMBOL_ID <= early_symbol_id) then
                            later_than_early(2) <= '1';
                        else
                            later_than_early(2) <= '0';
                        end if;
                    else
                        later_than_early(2) <= '1';
                    end if;
                elsif (SCS_CONFIG = 1) and (PACKET_SCS = 1) then
                    if (PACKET_SLOT_ID = early_slot_id) then
                        if (PACKET_SYMBOL_ID <= early_symbol_id) then
                            later_than_early(2) <= '1';
                        else
                            later_than_early(2) <= '0';
                        end if;
                    else
                        later_than_early(2) <= '1';
                    end if;
                elsif (SCS_CONFIG = 2) and (PACKET_SCS = 2) then
                    if (PACKET_SLOT_ID = early_slot_id) then
                        if (PACKET_SYMBOL_ID <= early_symbol_id) then
                            later_than_early(2) <= '1';
                        else
                            later_than_early(2) <= '0';
                        end if;
                    else
                        later_than_early(2) <= '1';
                    end if;
                elsif (SCS_CONFIG = 3) and (PACKET_SCS = 3) then
                    if (PACKET_SLOT_ID = early_slot_id) then
                        if (PACKET_SYMBOL_ID <= early_symbol_id) then
                            later_than_early(2) <= '1';
                        else
                            later_than_early(2) <= '0';
                        end if;
                    else
                        later_than_early(2) <= '1';
                    end if;
                elsif (SCS_CONFIG = 4) and (PACKET_SCS = 4) then
                    if (PACKET_SLOT_ID = early_slot_id) then
                        if (PACKET_SYMBOL_ID <= early_symbol_id) then
                            later_than_early(2) <= '1';
                        else
                            later_than_early(2) <= '0';
                        end if;
                    else
                        later_than_early(2) <= '1';
                    end if;
                else
                    later_than_early(2) <= '0';
                end if;
            else
                later_than_early(2) <= '0';
            end if;
        end if;
    end process;

    -- detect whether packet is arrived earlier than end of RX window (frameId & subframeId)
    process (CLK_PACKET)
    begin
        if (CLK_PACKET'event and CLK_PACKET = '1') then
            if (PACKET_EN = '1') then
                if (PACKET_FRAME_ID = late_frame_id) then
--                    if (PACKET_SUBFRAME_ID >= late_subframe_id) then
                        earlier_than_late(0) <= '1';
--                    else
--                        earlier_than_late(0) <= '0';
--                    end if;
                else
                    if (PACKET_FRAME_ID - late_frame_id = 1) then
                        earlier_than_late(0) <= '1';
                    else
                        earlier_than_late(0) <= '0';
                    end if;
                end if;
            else
                earlier_than_late(0) <= '0';
            end if;
        end if;
    end process;

    -- detect whether packet is arrived earlier than end of RX window (subframeId & slotId)
    process (CLK_PACKET)
    begin
        if (CLK_PACKET'event and CLK_PACKET = '1') then
            if (PACKET_EN = '1') then
                if (PACKET_SUBFRAME_ID = late_subframe_id) then
                    if    (SCS_CONFIG = 0) and ((PACKET_SCS(3) = '1') or (PACKET_SCS(2 downto 0) = 0)) then
--                        if (PACKET_SLOT_ID >= late_slot_id) then
                            earlier_than_late(1) <= '1';
--                        else
--                            earlier_than_late(1) <= '0';
--                        end if;
                    elsif (SCS_CONFIG = 1) and (PACKET_SCS = 1) then
                        if (PACKET_SLOT_ID >= late_slot_id) then
                            earlier_than_late(1) <= '1';
                        else
                            earlier_than_late(1) <= '0';
                        end if;
                    elsif (SCS_CONFIG = 2) and (PACKET_SCS = 2) then
                        if (PACKET_SLOT_ID >= late_slot_id) then
                            earlier_than_late(1) <= '1';
                        else
                            earlier_than_late(1) <= '0';
                        end if;
                    elsif (SCS_CONFIG = 3) and (PACKET_SCS = 3) then
                        if (PACKET_SLOT_ID >= late_slot_id) then
                            earlier_than_late(1) <= '1';
                        else
                            earlier_than_late(1) <= '0';
                        end if;
                    elsif (SCS_CONFIG = 4) and (PACKET_SCS = 4) then
                        if (PACKET_SLOT_ID >= late_slot_id) then
                            earlier_than_late(1) <= '1';
                        else
                            earlier_than_late(1) <= '0';
                        end if;
                    else
                        earlier_than_late(1) <= '0';
                    end if;
                else
                    if (late_subframe_id = 9) then
                        if (PACKET_SUBFRAME_ID = 0) then
                            earlier_than_late(1) <= '1';
                        else
                            earlier_than_late(1) <= '0';
                        end if;
                    else
                        if (PACKET_SUBFRAME_ID - late_subframe_id = 1) then
                            earlier_than_late(1) <= '1';
                        else
                            earlier_than_late(1) <= '0';
                        end if;
                    end if;
                end if;
            else
                earlier_than_late(1) <= '0';
            end if;
        end if;
    end process;

    -- detect whether packet is arrived earlier than end of RX window (slotId & symbolid)
    process (CLK_PACKET)
    begin
        if (CLK_PACKET'event and CLK_PACKET = '1') then
            if (PACKET_EN = '1') then
                if    (SCS_CONFIG = 0) and ((PACKET_SCS(3) = '1') or (PACKET_SCS(2 downto 0) = 0)) then
--                    if (PACKET_SLOT_ID = late_slot_id) then
                    if (PACKET_SUBFRAME_ID = late_subframe_id) then
                        if (PACKET_SYMBOL_ID > late_symbol_id) then
                            earlier_than_late(2) <= '1';
                        else
                            earlier_than_late(2) <= '0';
                        end if;
                    else
                        earlier_than_late(2) <= '1';
                    end if;
                elsif (SCS_CONFIG = 1) and (PACKET_SCS = 1) then
                    if (PACKET_SLOT_ID = late_slot_id) then
                        if (PACKET_SYMBOL_ID > late_symbol_id) then
                            earlier_than_late(2) <= '1';
                        else
                            earlier_than_late(2) <= '0';
                        end if;
                    else
                        earlier_than_late(2) <= '1';
                    end if;
                elsif (SCS_CONFIG = 2) and (PACKET_SCS = 2) then
                    if (PACKET_SLOT_ID = late_slot_id) then
                        if (PACKET_SYMBOL_ID > late_symbol_id) then
                            earlier_than_late(2) <= '1';
                        else
                            earlier_than_late(2) <= '0';
                        end if;
                    else
                        earlier_than_late(2) <= '1';
                    end if;
                elsif (SCS_CONFIG = 3) and (PACKET_SCS = 3) then
                    if (PACKET_SLOT_ID = late_slot_id) then
                        if (PACKET_SYMBOL_ID > late_symbol_id) then
                            earlier_than_late(2) <= '1';
                        else
                            earlier_than_late(2) <= '0';
                        end if;
                    else
                        earlier_than_late(2) <= '1';
                    end if;
                elsif (SCS_CONFIG = 4) and (PACKET_SCS = 4) then
                    if (PACKET_SLOT_ID = late_slot_id) then
                        if (PACKET_SYMBOL_ID > late_symbol_id) then
                            earlier_than_late(2) <= '1';
                        else
                            earlier_than_late(2) <= '0';
                        end if;
                    else
                        earlier_than_late(2) <= '1';
                    end if;
                else
                    earlier_than_late(2) <= '0';
                end if;
            else
                earlier_than_late(2) <= '0';
            end if;
        end if;
    end process;

    process (CLK_PACKET)
    begin
        if (CLK_PACKET'event and CLK_PACKET = '1') then
            if (PACKET_SCS = SCS_CONFIG) then
                check     <= PACKET_EN and (not PACKET_IS_NDM);
                check_ndm <= PACKET_EN and PACKET_IS_NDM;
            else
                if (SCS_CONFIG = 0) and ((PACKET_SCS(3) = '1') or (PACKET_SCS(2 downto 0) = 0)) then
                    check     <= PACKET_EN and (not PACKET_IS_NDM);
                    check_ndm <= PACKET_EN and PACKET_IS_NDM;
                else
                    check     <= '0';
                    check_ndm <= '0';
                end if;
            end if;
        end if;
    end process;

    process (CLK_PACKET)
    begin
        if (CLK_PACKET'event and CLK_PACKET = '1') then
            if (check = '1') then
                if    (later_than_early = "111") and (earlier_than_late = "111") then
                    det_on_time <= (others => '1');
                else
                    det_on_time <= det_on_time(2 downto 0) & '0';
                end if;
            else
                det_on_time <= det_on_time(2 downto 0) & '0';
            end if;
        end if;
    end process;

    process (CLK_PACKET)
    begin
        if (CLK_PACKET'event and CLK_PACKET = '1') then
            if (check = '1') then
                if (later_than_early /= "111") and (earlier_than_late = "111") then
                    det_early <= (others => '1');
                else
                    det_early <= det_early(2 downto 0) & '0';
                end if;
            else
                det_early <= det_early(2 downto 0) & '0';
            end if;
        end if;
    end process;

    process (CLK_PACKET)
    begin
        if (CLK_PACKET'event and CLK_PACKET = '1') then
            if (check = '1') then
                if (later_than_early = "111") and (earlier_than_late /= "111") then
                    det_late <= (others => '1');
                else
                    det_late <= det_late(2 downto 0) & '0';
                end if;
            else
                det_late <= det_late(2 downto 0) & '0';
            end if;
        end if;
    end process;

    process (CLK_PACKET)
    begin
        if (CLK_PACKET'event and CLK_PACKET = '1') then
            if (check = '1') then
                if (later_than_early /= "111") and (earlier_than_late /= "111") then
                    det_oor <= (others => '1');
                else
                    det_oor <= det_oor(2 downto 0) & '0';
                end if;
            else
                det_oor <= det_oor(2 downto 0) & '0';
            end if;
        end if;
    end process;

    process (CLK_PACKET)
    begin
        if (CLK_PACKET'event and CLK_PACKET = '1') then
            if (check_ndm = '1') then
                det_ndm <= (others => '1');
            else
                det_ndm <= det_ndm(2 downto 0) & '0';
            end if;
        end if;
    end process;

    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            cdc_on_time <= cdc_on_time(2 downto 0) & det_on_time(3);
            cdc_early   <= cdc_early(2 downto 0) & det_early(3);
            cdc_late    <= cdc_late(2 downto 0) & det_late(3);
            cdc_oor     <= cdc_oor(2 downto 0) & det_oor(3);
            cdc_ndm     <= cdc_ndm(2 downto 0) & det_ndm(3);
        end if;
    end process;

    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            if (update_en = '1') then
                if (cdc_on_time(3 downto 2) = "01") then
                    cnt_detect_on_time <= x"0000000000000001";
                else
                    cnt_detect_on_time <= x"0000000000000000";
                end if;
            else
                if (cdc_on_time(3 downto 2) = "01") then
                    cnt_detect_on_time <= cnt_detect_on_time + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            if (update_en = '1') then
                if (cdc_early(3 downto 2) = "01") then
                    cnt_detect_early <= x"0000000000000001";
                else
                    cnt_detect_early <= x"0000000000000000";
                end if;
            else
                if (cdc_early(3 downto 2) = "01") then
                    cnt_detect_early <= cnt_detect_early + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            if (update_en = '1') then
                if (cdc_late(3 downto 2) = "01") then
                    cnt_detect_late <= x"0000000000000001";
                else
                    cnt_detect_late <= x"0000000000000000";
                end if;
            else
                if (cdc_late(3 downto 2) = "01") then
                    cnt_detect_late <= cnt_detect_late + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            if (update_en = '1') then
                if (cdc_oor(3 downto 2) = "01") then
                    cnt_detect_oor <= x"0000000000000001";
                else
                    cnt_detect_oor <= x"0000000000000000";
                end if;
            else
                if (cdc_oor(3 downto 2) = "01") then
                    cnt_detect_oor <= cnt_detect_oor + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            if (update_en = '1') then
                if (cdc_ndm(3 downto 2) = "01") then
                    cnt_detect_ndm <= x"0000000000000001";
                else
                    cnt_detect_ndm <= x"0000000000000000";
                end if;
            else
                if (cdc_ndm(3 downto 2) = "01") then
                    cnt_detect_ndm <= cnt_detect_ndm + 1;
                end if;
            end if;
        end if;
    end process;

end BEHAVE;