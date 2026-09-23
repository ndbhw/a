--------------------------------------------------------------------------------
--
-- Copyright (C) 2022, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com) / nhu.dong
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

entity RX_WINDOW_SHORT is
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
-- Packet stamp
--------------------------------------------------------------------------------

        CLK_PACKET                  : in  std_logic;

        PACKET_EN                   : in  std_logic;
        PACKET_SCS                  : in  std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             : in  std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          : in  std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              : in  std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            : in  std_logic_vector(5 downto 0);
        
        DETECT_ON_TIME              : out std_logic;
        DETECT_EARLY                : out std_logic;
        DETECT_LATE                 : out std_logic;
        DETECT_OOR                  : out std_logic
    );
end RX_WINDOW_SHORT;

architecture BEHAVE of RX_WINDOW_SHORT is

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
    
    signal det_on_time              : std_logic := '0';
    signal det_early                : std_logic := '0';
    signal det_late                 : std_logic := '0';
    signal det_oor                  : std_logic := '0';
    
begin

--    DETECT_ON_TIME   <=   det_late or det_oor or det_early;  --det_on_time  ;
--    DETECT_EARLY     <=   det_early    ;
--    DETECT_LATE      <=   '0'; --det_late     ;
--    DETECT_OOR       <=   '0'; --det_oor      ;

    DETECT_ON_TIME   <=   det_on_time; --det_late or det_oor or det_early;  --det_on_time  ;
    DETECT_EARLY     <=   det_early;
    DETECT_LATE      <=   det_late; --'0'; --det_late     ;
    DETECT_OOR       <=   det_oor; --'0'; --det_oor      ;

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
                check     <= PACKET_EN; --and (not PACKET_IS_NDM);
            else
                if (SCS_CONFIG = 0) and ((PACKET_SCS(3) = '1') or (PACKET_SCS(2 downto 0) = 0)) then
                    check     <= PACKET_EN;-- and (not PACKET_IS_NDM);
                else
                    check     <= '0';
                end if;
            end if;
        end if;
    end process;

    process (CLK_PACKET)
    begin
        if (CLK_PACKET'event and CLK_PACKET = '1') then
            check <= PACKET_EN;
        end if;
    end process;

    process (CLK_PACKET)
    begin
        if (CLK_PACKET'event and CLK_PACKET = '1') then
            if (check = '1') then
                if    (later_than_early = "111") and (earlier_than_late = "111") then
                    det_on_time <= '1';
                else
                    det_on_time <= '0';
                end if;
            else
                det_on_time <= '0';
            end if;
        end if;
    end process;

    process (CLK_PACKET)
    begin
        if (CLK_PACKET'event and CLK_PACKET = '1') then
            if (check = '1') then
                if (later_than_early /= "111") and (earlier_than_late = "111") then
                    det_early <= '1';
                else
                    det_early <= '0';
                end if;
            else
                det_early <= '0';
            end if;
        end if;
    end process;

    process (CLK_PACKET)
    begin
        if (CLK_PACKET'event and CLK_PACKET = '1') then
            if (check = '1') then
                if (later_than_early = "111") and (earlier_than_late /= "111") then
                    det_late <= '1';
                else
                    det_late <= '0';
                end if;
            else
                det_late <= '0';
            end if;
        end if;
    end process;

    process (CLK_PACKET)
    begin
        if (CLK_PACKET'event and CLK_PACKET = '1') then
            if (check = '1') then
                if (later_than_early /= "111") and (earlier_than_late /= "111") then
                    det_oor <= '1';
                else
                    det_oor <= '0';
                end if;
            else
                det_oor <= '0';
            end if;
        end if;
    end process;

end BEHAVE;