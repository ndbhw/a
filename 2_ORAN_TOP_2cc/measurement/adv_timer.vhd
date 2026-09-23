--------------------------------------------------------------------------------
--
-- Copyright (C) 2025, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2025.08.25
--------------------------------------------------------------------------------
-- Function description
--   1. Performance measurement component
--   2. Generate time stamp
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2025.08.25) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity ADV_TIMER is
    generic (
        SCS_CONFIG                  : natural := 0
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK_245p76MHz               : in  std_logic;                            -- 245.76-MHz
        CLK_CDC                     : in  std_logic;

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------

        START_VALUE                 : in  std_logic_vector(21 downto 0);        -- Cannot exceed 10-msec

--------------------------------------------------------------------------------
-- Synchronization
--------------------------------------------------------------------------------

        REF_10msec                  : in  std_logic;                            -- 245.76-MHz
        REF_SFN                     : in  std_logic_vector(7 downto 0);

--------------------------------------------------------------------------------
-- Timer (Clock domain : CLK_CDC)
--------------------------------------------------------------------------------

        FRAME_ID                    : out std_logic_vector(7 downto 0);
        SUBFRAME_ID                 : out std_logic_vector(3 downto 0);
        SLOT_ID                     : out std_logic_vector(3 downto 0);
        SYMBOL_ID                   : out std_logic_vector(3 downto 0)
    );
end ADV_TIMER;

architecture BEHAVE of ADV_TIMER is

    signal tick                     : std_logic_vector(2 downto 0) := (others => '0');
    signal tick_reset               : std_logic := '0';
    signal tick_reset_sh            : std_logic := '0';
    signal tick_1ms                 : std_logic := '0';
    signal tick_500us               : std_logic := '0';

    constant REF_UNIT_0             : std_logic_vector(6 downto 0) := conv_std_logic_vector(128-1, 7);
    constant REF_UNIT_1             : std_logic_vector(5 downto 0) := conv_std_logic_vector( 64-1, 6);
    constant REF_UNIT_2             : std_logic_vector(4 downto 0) := conv_std_logic_vector( 32-1, 5);
    constant REF_UNIT_3             : std_logic_vector(3 downto 0) := conv_std_logic_vector( 16-1, 4);
    constant REF_UNIT_4             : std_logic_vector(2 downto 0) := conv_std_logic_vector(  8-1, 3);

    constant REF_SLOT_1             : std_logic_vector(0 downto 0) := conv_std_logic_vector( 1, 1);
    constant REF_SLOT_2             : std_logic_vector(1 downto 0) := conv_std_logic_vector( 3, 2);
    constant REF_SLOT_3             : std_logic_vector(2 downto 0) := conv_std_logic_vector( 7, 3);
    constant REF_SLOT_4             : std_logic_vector(3 downto 0) := conv_std_logic_vector(15, 4);

    signal cnt_base                 : std_logic_vector(21 downto 0) := (others => '0');
    signal cnt_main                 : std_logic_vector(17 downto 0) := (others => '0');
    signal cnt_unit_0               : std_logic_vector(6 downto 0) := (others => '0');
    signal cnt_unit_1               : std_logic_vector(5 downto 0) := (others => '0');
    signal cnt_unit_2               : std_logic_vector(4 downto 0) := (others => '0');
    signal cnt_unit_3               : std_logic_vector(3 downto 0) := (others => '0');
    signal cnt_unit_4               : std_logic_vector(2 downto 0) := (others => '0');
    signal cp_type                  : std_logic_vector(4 downto 0) := (others => '0');
    signal cnt_sample_0             : std_logic_vector(7 downto 0) := (others => '0');
    signal cnt_sample_1             : std_logic_vector(7 downto 0) := (others => '0');
    signal cnt_sample_2             : std_logic_vector(7 downto 0) := (others => '0');
    signal cnt_sample_3             : std_logic_vector(7 downto 0) := (others => '0');
    signal cnt_sample_4             : std_logic_vector(7 downto 0) := (others => '0');
    signal ref_sample_0             : std_logic_vector(7 downto 0);
    signal ref_sample_1             : std_logic_vector(7 downto 0);
    signal ref_sample_2             : std_logic_vector(7 downto 0);
    signal ref_sample_3             : std_logic_vector(7 downto 0);
    signal ref_sample_4             : std_logic_vector(7 downto 0);
    signal cnt_symbol               : std_logic_vector(3 downto 0) := (others => '0');
    signal cnt_slot_1               : std_logic_vector(0 downto 0) := (others => '0');
    signal cnt_slot_2               : std_logic_vector(1 downto 0) := (others => '0');
    signal cnt_slot_3               : std_logic_vector(2 downto 0) := (others => '0');
    signal cnt_slot_4               : std_logic_vector(3 downto 0) := (others => '0');
    signal cnt_slot                 : std_logic_vector(3 downto 0);
    signal cnt_subframe             : std_logic_vector(3 downto 0) := (others => '0');
    signal cnt_frame_buf            : std_logic_vector(7 downto 0) := (others => '0');
    signal cnt_frame                : std_logic_vector(7 downto 0) := (others => '0');

    signal update                   : std_logic_vector(7 downto 0) := (others => '0');
    signal update_cdc               : std_logic_vector(3 downto 0) := (others => '0');

begin

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            tick <= tick(1 downto 0) & REF_10msec;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick(2 downto 1) = "01") then
                cnt_base <= START_VALUE;
            else
                if (cnt_base = 2457600-1) then
                    cnt_base <= (others => '0');
                else
                    cnt_base <= cnt_base + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (cnt_base = 245760*10-1) then
                tick_reset <= '1';
            else
                tick_reset <= '0';
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            tick_reset_sh <= tick_reset;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_reset = '1') then
                cnt_main <= (others => '0');
            else
                if (cnt_main = 245760-1) then
                    cnt_main <= (others => '0');
                else
                    cnt_main <= cnt_main + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (cnt_main = 245760-1) then
                tick_1ms <= '1';
            else
                tick_1ms <= '0';
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (cnt_main = 122880-1) or (cnt_main = 245760-1) then
                tick_500us <= '1';
            else
                tick_500us <= '0';
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (REF_10msec = '1') then
                cnt_frame_buf <= REF_SFN + 1;
            end if;
        end if;
    end process;

    u_SCS_15kHz : if SCS_CONFIG = 0 generate
    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_1ms = '1') then
                cnt_unit_0 <= (others => '0');
            else
                if (cnt_unit_0 = REF_UNIT_0) then
                    cnt_unit_0 <= (others => '0');
                else
                    cnt_unit_0 <= cnt_unit_0 + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_500us = '1') then
                cnt_sample_0 <= (others => '0');
            else
                if (cnt_unit_0 = REF_UNIT_0) then
                    if (cnt_sample_0 = ref_sample_0) then
                        cnt_sample_0 <= (others => '0');
                    else
                        cnt_sample_0 <= cnt_sample_0 + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (cp_type)
    begin
        if (cp_type(0) = '1') then
            ref_sample_0 <= conv_std_logic_vector(137, 8);
        else
            ref_sample_0 <= conv_std_logic_vector(136, 8);
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_500us = '1') then
                cp_type(0) <= '1';
            else
                if (cnt_unit_0 = REF_UNIT_0) and (cnt_sample_0 = ref_sample_0) then
                    cp_type(0) <= '0';
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_1ms = '1') then
                cnt_symbol <= (others => '0');
            else
                if (cnt_unit_0 = REF_UNIT_0) and (cnt_sample_0 = ref_sample_0) then
                    if (cnt_symbol = 13) then
                        cnt_symbol <= (others => '0');
                    else
                        cnt_symbol <= cnt_symbol + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_reset_sh = '1') and (tick_1ms = '1') then
                cnt_subframe <= (others => '0');
            else
                if (cnt_unit_0 = REF_UNIT_0) and (cnt_sample_0 = 136) and (cnt_symbol = 13) then
                    if (cnt_subframe = 9) then
                        cnt_subframe <= (others => '0');
                    else
                        cnt_subframe <= cnt_subframe + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (cnt_unit_0 = REF_UNIT_0) and (cnt_sample_0 = 136) and (cnt_symbol = 13) then
                if (cnt_subframe = 9) then
                    cnt_frame <= cnt_frame_buf;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (cnt_unit_0 = REF_UNIT_0) and (cnt_sample_0 = ref_sample_0) then
                update <= (others => '1');
            else
                update <= update(6 downto 0) & '0';
            end if;
        end if;
    end process;

    cnt_slot <= "0000";
    end generate;

    u_SCS_30kHz : if SCS_CONFIG = 1 generate
    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_1ms = '1') then
                cnt_unit_1 <= (others => '0');
            else
                if (cnt_unit_1 = REF_UNIT_1) then
                    cnt_unit_1 <= (others => '0');
                else
                    cnt_unit_1 <= cnt_unit_1 + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_500us = '1') then
                cnt_sample_1 <= (others => '0');
            else
                if (cnt_unit_1 = REF_UNIT_1) then
                    if (cnt_sample_1 = ref_sample_1) then
                        cnt_sample_1 <= (others => '0');
                    else
                        cnt_sample_1 <= cnt_sample_1 + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (cp_type)
    begin
        if (cp_type(1) = '1') then
            ref_sample_1 <= conv_std_logic_vector(138, 8);
        else
            ref_sample_1 <= conv_std_logic_vector(136, 8);
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_500us = '1') then
                cp_type(1) <= '1';
            else
                if (cnt_unit_1 = REF_UNIT_1) and (cnt_sample_1 = ref_sample_1) then
                    cp_type(1) <= '0';
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_1ms = '1') then
                cnt_symbol <= (others => '0');
            else
                if (cnt_unit_1 = REF_UNIT_1) and (cnt_sample_1 = ref_sample_1) then
                    if (cnt_symbol = 13) then
                        cnt_symbol <= (others => '0');
                    else
                        cnt_symbol <= cnt_symbol + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_1ms = '1') then
                cnt_slot_1 <= (others => '0');
            else
                if (cnt_unit_1 = REF_UNIT_1) and (cnt_sample_1 = 136) and (cnt_symbol = 13) then
                    cnt_slot_1 <= cnt_slot_1 + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_reset_sh = '1') and (tick_1ms = '1') then
                cnt_subframe <= (others => '0');
            else
                if (cnt_unit_1 = REF_UNIT_1) and (cnt_sample_1 = 136) and (cnt_symbol = 13) and (cnt_slot_1 = REF_SLOT_1) then
                    if (cnt_subframe = 9) then
                        cnt_subframe <= (others => '0');
                    else
                        cnt_subframe <= cnt_subframe + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (cnt_unit_1 = REF_UNIT_1) and (cnt_sample_1 = 136) and (cnt_symbol = 13) and (cnt_slot_1 = REF_SLOT_1) then
                if (cnt_subframe = 9) then
                    cnt_frame <= cnt_frame_buf;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (cnt_unit_1 = REF_UNIT_1) and (cnt_sample_1 = ref_sample_1) then
                update <= (others => '1');
            else
                update <= update(6 downto 0) & '0';
            end if;
        end if;
    end process;

    cnt_slot <= "000" & cnt_slot_1(0 downto 0);
    end generate;

    u_SCS_60kHz : if SCS_CONFIG = 2 generate
    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_1ms = '1') then
                cnt_unit_2 <= (others => '0');
            else
                if (cnt_unit_2 = REF_UNIT_2) then
                    cnt_unit_2 <= (others => '0');
                else
                    cnt_unit_2 <= cnt_unit_2 + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_500us = '1') then
                cnt_sample_2 <= (others => '0');
            else
                if (cnt_unit_2 = REF_UNIT_2) then
                    if (cnt_sample_2 = ref_sample_2) then
                        cnt_sample_2 <= (others => '0');
                    else
                        cnt_sample_2 <= cnt_sample_2 + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (cp_type)
    begin
        if (cp_type(2) = '1') then
            ref_sample_2 <= conv_std_logic_vector(140, 8);
        else
            ref_sample_2 <= conv_std_logic_vector(136, 8);
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_500us = '1') then
                cp_type(2) <= '1';
            else
                if (cnt_unit_2 = REF_UNIT_2) and (cnt_sample_2 = ref_sample_2) then
                    cp_type(2) <= '0';
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_1ms = '1') then
                cnt_symbol <= (others => '0');
            else
                if (cnt_unit_2 = REF_UNIT_2) and (cnt_sample_2 = ref_sample_2) then
                    if (cnt_symbol = 13) then
                        cnt_symbol <= (others => '0');
                    else
                        cnt_symbol <= cnt_symbol + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_1ms = '1') then
                cnt_slot_2 <= (others => '0');
            else
                if (cnt_unit_2 = REF_UNIT_2) and (cnt_sample_2 = 136) and (cnt_symbol = 13) then
                    cnt_slot_2 <= cnt_slot_2 + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_reset_sh = '1') and (tick_1ms = '1') then
                cnt_subframe <= (others => '0');
            else
                if (cnt_unit_2 = REF_UNIT_2) and (cnt_sample_2 = 136) and (cnt_symbol = 13) and (cnt_slot_2 = REF_SLOT_2) then
                    if (cnt_subframe = 9) then
                        cnt_subframe <= (others => '0');
                    else
                        cnt_subframe <= cnt_subframe + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (cnt_unit_2 = REF_UNIT_2) and (cnt_sample_2 = 136) and (cnt_symbol = 13) and (cnt_slot_2 = REF_SLOT_2) then
                if (cnt_subframe = 9) then
                    cnt_frame <= cnt_frame_buf;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (cnt_unit_2 = REF_UNIT_2) and (cnt_sample_2 = ref_sample_2) then
                update <= (others => '1');
            else
                update <= update(6 downto 0) & '0';
            end if;
        end if;
    end process;

    cnt_slot <= "00" & cnt_slot_2(1 downto 0);
    end generate;

    u_SCS_120kHz : if SCS_CONFIG = 3 generate
    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_1ms = '1') then
                cnt_unit_3 <= (others => '0');
            else
                if (cnt_unit_3 = REF_UNIT_3) then
                    cnt_unit_3 <= (others => '0');
                else
                    cnt_unit_3 <= cnt_unit_3 + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_500us = '1') then
                cnt_sample_3 <= (others => '0');
            else
                if (cnt_unit_3 = REF_UNIT_3) then
                    if (cnt_sample_3 = ref_sample_3) then
                        cnt_sample_3 <= (others => '0');
                    else
                        cnt_sample_3 <= cnt_sample_3 + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (cp_type)
    begin
        if (cp_type(3) = '1') then
            ref_sample_3 <= conv_std_logic_vector(144, 8);
        else
            ref_sample_3 <= conv_std_logic_vector(136, 8);
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_500us = '1') then
                cp_type(3) <= '1';
            else
                if (cnt_unit_3 = REF_UNIT_3) and (cnt_sample_3 = ref_sample_3) then
                    cp_type(3) <= '0';
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_1ms = '1') then
                cnt_symbol <= (others => '0');
            else
                if (cnt_unit_3 = REF_UNIT_3) and (cnt_sample_3 = ref_sample_3) then
                    if (cnt_symbol = 13) then
                        cnt_symbol <= (others => '0');
                    else
                        cnt_symbol <= cnt_symbol + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_1ms = '1') then
                cnt_slot_3 <= (others => '0');
            else
                if (cnt_unit_3 = REF_UNIT_3) and (cnt_sample_3 = 136) and (cnt_symbol = 13) then
                    cnt_slot_3 <= cnt_slot_3 + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_reset_sh = '1') and (tick_1ms = '1') then
                cnt_subframe <= (others => '0');
            else
                if (cnt_unit_3 = REF_UNIT_3) and (cnt_sample_3 = 136) and (cnt_symbol = 13) and (cnt_slot_3 = REF_SLOT_3) then
                    if (cnt_subframe = 9) then
                        cnt_subframe <= (others => '0');
                    else
                        cnt_subframe <= cnt_subframe + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (cnt_unit_3 = REF_UNIT_3) and (cnt_sample_3 = 136) and (cnt_symbol = 13) and (cnt_slot_3 = REF_SLOT_3) then
                if (cnt_subframe = 9) then
                    cnt_frame <= cnt_frame_buf;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (cnt_unit_3 = REF_UNIT_3) and (cnt_sample_3 = ref_sample_3) then
                update <= (others => '1');
            else
                update <= update(6 downto 0) & '0';
            end if;
        end if;
    end process;

    cnt_slot <= '0' & cnt_slot_3(2 downto 0);
    end generate;

    u_SCS_240kHz : if SCS_CONFIG = 4 generate
    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_1ms = '1') then
                cnt_unit_4 <= (others => '0');
            else
                if (cnt_unit_4 = REF_UNIT_4) then
                    cnt_unit_4 <= (others => '0');
                else
                    cnt_unit_4 <= cnt_unit_4 + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_500us = '1') then
                cnt_sample_4 <= (others => '0');
            else
                if (cnt_unit_4 = REF_UNIT_4) then
                    if (cnt_sample_4 = ref_sample_4) then
                        cnt_sample_4 <= (others => '0');
                    else
                        cnt_sample_4 <= cnt_sample_4 + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (cp_type)
    begin
        if (cp_type(4) = '1') then
            ref_sample_4 <= conv_std_logic_vector(152, 8);
        else
            ref_sample_4 <= conv_std_logic_vector(136, 8);
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_500us = '1') then
                cp_type(4) <= '1';
            else
                if (cnt_unit_4 = REF_UNIT_4) and (cnt_sample_4 = ref_sample_4) then
                    cp_type(4) <= '0';
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_1ms = '1') then
                cnt_symbol <= (others => '0');
            else
                if (cnt_unit_4 = REF_UNIT_4) and (cnt_sample_4 = ref_sample_4) then
                    if (cnt_symbol = 13) then
                        cnt_symbol <= (others => '0');
                    else
                        cnt_symbol <= cnt_symbol + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_1ms = '1') then
                cnt_slot_4 <= (others => '0');
            else
                if (cnt_unit_4 = REF_UNIT_4) and (cnt_sample_4 = 136) and (cnt_symbol = 13) then
                    cnt_slot_4 <= cnt_slot_4 + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (tick_reset_sh = '1') and (tick_1ms = '1') then
                cnt_subframe <= (others => '0');
            else
                if (cnt_unit_4 = REF_UNIT_4) and (cnt_sample_4 = 136) and (cnt_symbol = 13) and (cnt_slot_4 = REF_SLOT_4) then
                    if (cnt_subframe = 9) then
                        cnt_subframe <= (others => '0');
                    else
                        cnt_subframe <= cnt_subframe + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (cnt_unit_4 = REF_UNIT_4) and (cnt_sample_4 = 136) and (cnt_symbol = 13) and (cnt_slot_4 = REF_SLOT_4) then
                if (cnt_subframe = 9) then
                    cnt_frame <= cnt_frame_buf;
                end if;
            end if;
        end if;
    end process;

    process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            if (cnt_unit_4 = REF_UNIT_4) and (cnt_sample_4 = ref_sample_4) then
                update <= (others => '1');
            else
                update <= update(6 downto 0) & '0';
            end if;
        end if;
    end process;

    cnt_slot <= cnt_slot_4(3 downto 0);
    end generate;

    process (CLK_CDC)
    begin
        if (CLK_CDC'event and CLK_CDC = '1') then
            update_cdc <= update_cdc(2 downto 0) & update(7);
        end if;
    end process;

    process (CLK_CDC)
    begin
        if (CLK_CDC'event and CLK_CDC = '1') then
            if (update_cdc(3 downto 2) = "01") then
                FRAME_ID    <= cnt_frame;
                SUBFRAME_ID <= cnt_subframe;
                SLOT_ID     <= cnt_slot;
                SYMBOL_ID   <= cnt_symbol;
            end if;
        end if;
    end process;

end BEHAVE;