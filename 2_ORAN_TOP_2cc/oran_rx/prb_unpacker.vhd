--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : PRB unpacker (O-RAN component)                                --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.15                                                    --
--                                                                            --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use WORK.PKG_ORAN.ALL;

entity PRB_UNPACKER is
    generic (
        LINK_DIRECTION              : std_logic := '0'
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;
        RST                         : in  std_logic;

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------

        COMP_MODE                   : in  std_logic;                            -- 0 : Static, 1 : Dynamic
        IQ_WIDTH                    : in  std_logic_vector(3 downto 0);
        COMP_METHOD                 : in  std_logic_vector(3 downto 0);

        PRB_PER_SYMBOL              : in  std_logic_vector(9 downto 0);

--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- U-Plane
--------------------------------------------------------------------------------

        U_PLANE_READY               : out std_logic;
        U_PLANE_VALID               : in  std_logic;
        U_PLANE_LAST                : in  std_logic;
        U_PLANE_KEEP                : in  std_logic_vector(3 downto 0);
        U_PLANE_DATA                : in  std_logic_vector(31 downto 0);
        U_PLANE_LINK_INDEX          : in  std_logic_vector(3 downto 0);

--------------------------------------------------------------------------------
-- Compression block
--------------------------------------------------------------------------------

        COMP_FRAME_ID               : out std_logic_vector(7 downto 0);
        COMP_SUBFRAME_ID            : out std_logic_vector(3 downto 0);
        COMP_SLOT_ID                : out std_logic_vector(5 downto 0);
        COMP_SYMBOL_ID              : out std_logic_vector(5 downto 0);
        COMP_USER                   : out std_logic_vector(62 downto 0);

        COMP_HDR                    : out std_logic_vector(7 downto 0);
        COMP_PARAM                  : out std_logic_vector(7 downto 0);

        COMP_VALID                  : out std_logic;
        COMP_TICK                   : out std_logic;
        COMP_DATA_I                 : out std_logic_vector(15 downto 0);
        COMP_DATA_Q                 : out std_logic_vector(15 downto 0)
    );
end PRB_UNPACKER;

architecture BEHAVE of PRB_UNPACKER is

    signal rx_last_buf              : std_logic := '0';

    type fsm_mtu                     is (HDR0, HDR1, DEC, SEC, COMP, ALIGN, PRB);
    signal fsm_split                : fsm_mtu;
    signal cnt_state                : std_logic_vector(3 downto 0) := (others => '0');
    signal ref_state                : std_logic_vector(3 downto 0) := (others => '0');
    signal cnt_rb                   : std_logic_vector(9 downto 0) := (others => '0');

    signal ready                    : std_logic;

    signal channel_id               : std_logic_vector(3 downto 0) := (others => '0');
    signal eaxc_id                  : std_logic_vector(15 downto 0) := (others => '0');
    signal seq_id                   : std_logic_vector(15 downto 0) := (others => '0');
    signal app_direction            : std_logic := '0';
    signal app_frame_id             : std_logic_vector(7 downto 0) := (others => '0');
    signal app_subframe_id          : std_logic_vector(3 downto 0) := (others => '0');
    signal app_slot_id              : std_logic_vector(5 downto 0) := (others => '0');
    signal app_symbol_id            : std_logic_vector(5 downto 0) := (others => '0');
    signal sec_id                   : std_logic_vector(11 downto 0) := (others => '0');
    signal sec_rb_indi              : std_logic := '0';
    signal sec_prb_start            : std_logic_vector(9 downto 0) := (others => '0');
    signal sec_prb_num              : std_logic_vector(10 downto 0) := (others => '0');
    signal ud_comp_hdr              : std_logic_vector(7 downto 0) := (others => '0');

    component PRB_LENGTH is
    generic (
        UNCOMP_1B                   : boolean := true;
        UNCOMP_2B                   : boolean := true;
        UNCOMP_3B                   : boolean := true;
        UNCOMP_4B                   : boolean := true;
        UNCOMP_5B                   : boolean := true;
        UNCOMP_6B                   : boolean := true;
        UNCOMP_7B                   : boolean := true;
        UNCOMP_8B                   : boolean := true;
        UNCOMP_9B                   : boolean := true;
        UNCOMP_10B                  : boolean := true;
        UNCOMP_11B                  : boolean := true;
        UNCOMP_12B                  : boolean := true;
        UNCOMP_13B                  : boolean := true;
        UNCOMP_14B                  : boolean := true;
        UNCOMP_15B                  : boolean := true;
        UNCOMP_16B                  : boolean := true;
        COMP_1B                     : boolean := true;
        COMP_2B                     : boolean := true;
        COMP_3B                     : boolean := true;
        COMP_4B                     : boolean := true;
        COMP_5B                     : boolean := true;
        COMP_6B                     : boolean := true;
        COMP_7B                     : boolean := true;
        COMP_8B                     : boolean := true;
        COMP_9B                     : boolean := true;
        COMP_10B                    : boolean := true;
        COMP_11B                    : boolean := true;
        COMP_12B                    : boolean := true;
        COMP_13B                    : boolean := true;
        COMP_14B                    : boolean := true;
        COMP_15B                    : boolean := true;
        COMP_16B                    : boolean := false
    );
    port (
        IQ_WIDTH                    : in  std_logic_vector(3 downto 0);
        COMP_METHOD                 : in  std_logic_vector(3 downto 0);

        QUOTIENT                    : out std_logic_vector(3 downto 0);
        REMAINDER                   : out std_logic_vector(1 downto 0)
    );
    end component;

    signal quotient                 : std_logic_vector(3 downto 0);
    signal remainder                : std_logic_vector(1 downto 0);

    component BYTE_ALIGN_32 is
    port (
        CLK                         : in  std_logic;

        ALIGN_START                 : in  std_logic;
        ALIGN_POSITION              : in  std_logic_vector(1 downto 0);

        VALID_IN                    : in  std_logic;
        LAST_IN                     : in  std_logic;
        KEEP_IN                     : in  std_logic_vector(3 downto 0);
        DATA_IN                     : in  std_logic_vector(31 downto 0);

        VALID_OUT                   : out std_logic;
        LAST_OUT                    : out std_logic;
        KEEP_OUT                    : out std_logic_vector(3 downto 0);
        DATA_OUT                    : out std_logic_vector(31 downto 0)
    );
    end component;

    signal keep_buf                 : std_logic_vector(3 downto 0);
    signal data_buf                 : std_logic_vector(31 downto 0);
    signal align_start              : std_logic := '0';
    signal align_position           : std_logic_vector(1 downto 0) := (others => '0');
    signal prev_position            : std_logic_vector(1 downto 0) := (others => '0');
    signal aligned_rb_start         : std_logic;
    signal aligned_rb_tick          : std_logic;
    signal aligned_rb_last          : std_logic;
    signal aligned_rb_data          : std_logic_vector(31 downto 0);
    signal aligned_rb_user          : std_logic_vector(15 downto 0);

    component PRB_32_TO_N is
    generic (
        UNCOMP_1B                   : boolean := true;
        UNCOMP_2B                   : boolean := true;
        UNCOMP_3B                   : boolean := true;
        UNCOMP_4B                   : boolean := true;
        UNCOMP_5B                   : boolean := true;
        UNCOMP_6B                   : boolean := true;
        UNCOMP_7B                   : boolean := true;
        UNCOMP_8B                   : boolean := true;
        UNCOMP_9B                   : boolean := true;
        UNCOMP_10B                  : boolean := true;
        UNCOMP_11B                  : boolean := true;
        UNCOMP_12B                  : boolean := true;
        UNCOMP_13B                  : boolean := true;
        UNCOMP_14B                  : boolean := true;
        UNCOMP_15B                  : boolean := true;
        UNCOMP_16B                  : boolean := true;
        COMP_1B                     : boolean := true;
        COMP_2B                     : boolean := true;
        COMP_3B                     : boolean := true;
        COMP_4B                     : boolean := true;
        COMP_5B                     : boolean := true;
        COMP_6B                     : boolean := true;
        COMP_7B                     : boolean := true;
        COMP_8B                     : boolean := true;
        COMP_9B                     : boolean := true;
        COMP_10B                    : boolean := true;
        COMP_11B                    : boolean := true;
        COMP_12B                    : boolean := true;
        COMP_13B                    : boolean := true;
        COMP_14B                    : boolean := true;
        COMP_15B                    : boolean := true;
        COMP_16B                    : boolean := false
    );
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        PRB_COMP_HDR                : in  std_logic_vector(7 downto 0);

        PRB_VALID                   : in  std_logic;
        PRB_TICK                    : in  std_logic;
        PRB_KEEP                    : in  std_logic_vector(3 downto 0);
        PRB_DATA                    : in  std_logic_vector(31 downto 0);
        PRB_USER                    : in  std_logic_vector(15 downto 0);

        COMP_HDR                    : out std_logic_vector(7 downto 0);
        COMP_PARAM                  : out std_logic_vector(7 downto 0);

        COMP_VALID                  : out std_logic;
        COMP_TICK                   : out std_logic;
        COMP_DATA_I                 : out std_logic_vector(15 downto 0);
        COMP_DATA_Q                 : out std_logic_vector(15 downto 0);
        COMP_USER                   : out std_logic_vector(15 downto 0)
    );
    end component;

    signal conv_enable              : std_logic;
    signal conv_hdr                 : std_logic_vector(7 downto 0);
    signal conv_param               : std_logic_vector(7 downto 0);
    signal conv_valid               : std_logic;
    signal conv_tick                : std_logic;
    signal conv_data_i              : std_logic_vector(15 downto 0);
    signal conv_data_q              : std_logic_vector(15 downto 0);
    signal conv_user                : std_logic_vector(15 downto 0);

begin

--------------------------------------------------------------------------------
-- Split section
--------------------------------------------------------------------------------

    process (RST, CLK)
    begin
        if (RST = '1') then
            fsm_split <= HDR0;
        elsif (CLK'event and CLK = '1') then
            case fsm_split is
            when HDR0   =>
                if (U_PLANE_VALID = '1') and (ready = '1') then
                    fsm_split <= HDR1;
                else
                    fsm_split <= HDR0;
                end if;
            when HDR1   =>
--                if (U_PLANE_VALID = '1') and (ready = '1') then
                    fsm_split <= DEC;
--                else
--                    fsm_split <= HDR1;
--                end if;
            when DEC    =>
--                if (U_PLANE_VALID = '1') and (ready = '1') then
                    fsm_split <= ALIGN;
--                else
--                    fsm_split <= DEC;
--                end if;
            when ALIGN  =>
                fsm_split <= SEC;
            when SEC    =>
                if (COMP_MODE = '0') then
                    fsm_split <= PRB;
                else
                    fsm_split <= COMP;
                end if;
            when COMP   =>
                fsm_split <= PRB;
            when PRB    =>
                if (cnt_state = 11) and (cnt_rb = sec_prb_num(9 downto 0)) then
                    if (U_PLANE_LAST = '1') or (rx_last_buf = '1') then
                        fsm_split <= HDR0;
                    else
                        fsm_split <= ALIGN;
                    end if;
                else
                    fsm_split <= PRB;
                end if;
            when others =>
                fsm_split <= HDR0;
            end case;
        end if;
    end process;

    U_PLANE_READY <= ready;

    process (RST, CLK)
    begin
        if (RST = '1') then
            ready <= '0';
        elsif (CLK'event and CLK = '1') then
            case fsm_split is
            when DEC    =>
--                if (U_PLANE_VALID = '0') then
--                    ready <= '1';
--                else
                    ready <= '0';
--                end if;
            when ALIGN  =>
                if (COMP_MODE = '0') then
                    ready <= '1';
                else
                    if (align_position = 2) or (align_position = 3) then
                        ready <= '0';
                    else
                        ready <= '1';
                    end if;
                end if;
            when PRB    =>
                if (cnt_state = 11) then
                    if (cnt_rb = sec_prb_num(9 downto 0)) then
                        if (U_PLANE_LAST = '1') or (rx_last_buf = '1') then
                            ready <= '1';
                        else
                            ready <= '0';
                        end if;
                    else
                        ready <= '1';
                    end if;
                else
                    if (cnt_state >= ref_state) then
                        ready <= '0';
                    else
                        ready <= '1';
                    end if;
                end if;
            when others =>
                ready <= '1';
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_split is
            when PRB    =>
                if (cnt_state = 11) then 
                    cnt_state <= (others => '0');
                else
                    cnt_state <= cnt_state + 1;
                end if;
            when others =>
                cnt_state <= (others => '0');
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_split is
            when PRB    =>
                if (cnt_state = 11) then 
                    cnt_rb <= cnt_rb + 1;
                end if;
            when others =>
                cnt_rb <= "0000000001";
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_split is
            when PRB    =>
                if (U_PLANE_LAST = '1') then
                    rx_last_buf <= '1';
                end if;
            when others =>
                rx_last_buf <= '0';
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_split is
            when HDR0   =>
                if (U_PLANE_VALID = '1') then
                    channel_id   <= U_PLANE_LINK_INDEX;
                end if;
            when others =>
                NULL;
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_split is
            when HDR1   =>
                if (U_PLANE_VALID = '1') then
                    eaxc_id <= U_PLANE_DATA(31 downto 16);
                    seq_id  <= U_PLANE_DATA(15 downto 0);
                end if;
            when others =>
                NULL;
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_split is
            when DEC    =>
                if (U_PLANE_VALID = '1') then
                    app_direction   <= U_PLANE_DATA(31);
                    app_frame_id    <= U_PLANE_DATA(23 downto 16);
                    app_subframe_id <= U_PLANE_DATA(15 downto 12);
                    app_slot_id     <= U_PLANE_DATA(11 downto 6);
                    app_symbol_id   <= U_PLANE_DATA(5 downto 0);
                end if;
            when others =>
                NULL;
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_split is
            when PRB    =>
                if (COMP_MODE = '0') then
                    if (cnt_state = 3) and (cnt_rb = 1) then
                        sec_id <= aligned_rb_data(31 downto 20);
                    end if;
                else
                    if (cnt_state = 2) and (cnt_rb = 1) then
                        sec_id <= aligned_rb_data(15 downto 4);
                    end if;
                end if;
            when others =>
                NULL;
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_split is
            when PRB    =>
                if (COMP_MODE = '0') then
                    if (cnt_rb = 1) then
                        if (cnt_state = 3) then
                            sec_rb_indi   <= aligned_rb_data(19);
                            sec_prb_start <= aligned_rb_data(17 downto 8);
                        else
                            if (sec_prb_num(10) = '1') then
                                sec_prb_start <= (others => '0');
                            end if;
                        end if;
                    end if;
                else
                    if (cnt_rb = 1) then
                        if (cnt_state = 2) then
                            sec_rb_indi               <= aligned_rb_data(3);
                            sec_prb_start(9 downto 8) <= aligned_rb_data(1 downto 0);
                        else
                            if (sec_prb_num(10) = '1') then
                                sec_prb_start(9 downto 8) <= (others => '0');
                            end if;
                        end if;
                        if (cnt_state = 3) then
                            sec_prb_start(7 downto 0) <= aligned_rb_data(31 downto 24);
                        else
                            if (sec_prb_num(10) = '1') then
                                sec_prb_start(7 downto 0) <= (others => '0');
                            end if;
                        end if;
                    end if;
                end if;
            when others =>
                NULL;
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_split is
            when PRB    =>
                if (COMP_MODE = '0') then
                    if (cnt_state = 3) and (cnt_rb = 1) then
                        if (aligned_rb_data(7 downto 0) = 0) then
                            sec_prb_num <= '1' & PRB_PER_SYMBOL;
                        else
                            sec_prb_num <= "000" & aligned_rb_data(7 downto 0);
                        end if;
                    end if;
                else
                    if (cnt_state = 3) and (cnt_rb = 1) then
                        if (aligned_rb_data(23 downto 16) = 0) then
                            sec_prb_num <= '1' & PRB_PER_SYMBOL;
                        else
                            sec_prb_num <= "000" & aligned_rb_data(23 downto 16);
                        end if;
                    end if;
                end if;
            when others =>
                NULL;
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (COMP_MODE = '0') then
                ud_comp_hdr <= IQ_WIDTH & COMP_METHOD;
            else
                case fsm_split is
                when SEC    =>
                    if    (align_position = 1) then
                        ud_comp_hdr <= U_PLANE_DATA(7 downto 0);
                    elsif (align_position = 2) then
                        ud_comp_hdr <= U_PLANE_DATA(15 downto 8);
                    elsif (align_position = 3) then
                        ud_comp_hdr <= U_PLANE_DATA(23 downto 16);
                    end if;
                when COMP   =>
                    if    (prev_position = 0) then
                        ud_comp_hdr <= U_PLANE_DATA(31 downto 24);
                    end if;
                when others =>
                    NULL;
                end case;
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Spread stream
--------------------------------------------------------------------------------

    u_PRB_LENGTH : PRB_LENGTH
    generic map(
        UNCOMP_1B                   => TX_UNCOMP_1B                            ,--: boolean := true;
        UNCOMP_2B                   => TX_UNCOMP_2B                            ,--: boolean := true;
        UNCOMP_3B                   => TX_UNCOMP_3B                            ,--: boolean := true;
        UNCOMP_4B                   => TX_UNCOMP_4B                            ,--: boolean := true;
        UNCOMP_5B                   => TX_UNCOMP_5B                            ,--: boolean := true;
        UNCOMP_6B                   => TX_UNCOMP_6B                            ,--: boolean := true;
        UNCOMP_7B                   => TX_UNCOMP_7B                            ,--: boolean := true;
        UNCOMP_8B                   => TX_UNCOMP_8B                            ,--: boolean := true;
        UNCOMP_9B                   => TX_UNCOMP_9B                            ,--: boolean := true;
        UNCOMP_10B                  => TX_UNCOMP_10B                           ,--: boolean := true;
        UNCOMP_11B                  => TX_UNCOMP_11B                           ,--: boolean := true;
        UNCOMP_12B                  => TX_UNCOMP_12B                           ,--: boolean := true;
        UNCOMP_13B                  => TX_UNCOMP_13B                           ,--: boolean := true;
        UNCOMP_14B                  => TX_UNCOMP_14B                           ,--: boolean := true;
        UNCOMP_15B                  => TX_UNCOMP_15B                           ,--: boolean := true;
        UNCOMP_16B                  => TX_UNCOMP_16B                           ,--: boolean := true;
        COMP_1B                     => TX_COMP_1B                              ,--: boolean := true;
        COMP_2B                     => TX_COMP_2B                              ,--: boolean := true;
        COMP_3B                     => TX_COMP_3B                              ,--: boolean := true;
        COMP_4B                     => TX_COMP_4B                              ,--: boolean := true;
        COMP_5B                     => TX_COMP_5B                              ,--: boolean := true;
        COMP_6B                     => TX_COMP_6B                              ,--: boolean := true;
        COMP_7B                     => TX_COMP_7B                              ,--: boolean := true;
        COMP_8B                     => TX_COMP_8B                              ,--: boolean := true;
        COMP_9B                     => TX_COMP_9B                              ,--: boolean := true;
        COMP_10B                    => TX_COMP_10B                             ,--: boolean := true;
        COMP_11B                    => TX_COMP_11B                             ,--: boolean := true;
        COMP_12B                    => TX_COMP_12B                             ,--: boolean := true;
        COMP_13B                    => TX_COMP_13B                             ,--: boolean := true;
        COMP_14B                    => TX_COMP_14B                             ,--: boolean := true;
        COMP_15B                    => TX_COMP_15B                             ,--: boolean := true;
        COMP_16B                    => TX_COMP_16B                              --: boolean := true
    )
    port map(
        IQ_WIDTH                    => ud_comp_hdr(7 downto 4)                 ,--: in  std_logic_vector(3 downto 0);
        COMP_METHOD                 => ud_comp_hdr(3 downto 0)                 ,--: in  std_logic_vector(3 downto 0);

        QUOTIENT                    => quotient                                ,--: out std_logic_vector(3 downto 0);
        REMAINDER                   => remainder                                --: out std_logic_vector(1 downto 0)
    );

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_split is
            when PRB    =>
                if (cnt_state = 0) then
                    if    (remainder = 3) then
                        if    (align_position = 1) then
                            ref_state <= quotient + 1;
                        elsif (align_position = 2) then
                            ref_state <= quotient + 1;
                        elsif (align_position = 3) then
                            ref_state <= quotient;
                        else
                            ref_state <= quotient + 1;
                        end if;
                    elsif (remainder = 2) then
                        if    (align_position = 2) then
                            ref_state <= quotient;
                        else
                            ref_state <= quotient + 1;
                        end if;
                    elsif (remainder = 1) then
                        if    (align_position = 1) then
                            ref_state <= quotient;
                        elsif (align_position = 2) then
                            ref_state <= quotient;
                        elsif (align_position = 3) then
                            ref_state <= quotient;
                        else
                            ref_state <= quotient + 1;
                        end if;
                    else
                        ref_state <= quotient;
                    end if;
                end if;
            when others =>
                ref_state <= x"B";
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_split is
            when SEC    =>
                align_start <= '1';
            when COMP   =>
                align_start <= '1';
            when PRB    =>
                if (cnt_state = 0) then
                    align_start <= '1';
                else
                    align_start <= '0';
                end if;
            when others =>
                align_start <= '0';
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_split is
            when DEC    =>
                align_position <= "00";
                prev_position  <= "00";
            when SEC    =>
                if (COMP_MODE = '1') then
                    align_position <= align_position + 2;
                    prev_position  <= align_position;
                end if;
            when PRB    =>
                if (cnt_state = 10) then 
                    align_position <= align_position - remainder;
                    prev_position  <= align_position;
                else
                    align_position <= align_position;
                end if;
            when others =>
                NULL;
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (ready = '1') then
                keep_buf <= U_PLANE_KEEP;
                data_buf <= U_PLANE_DATA;
            end if;
        end if;
    end process;

    u_ALIGN : BYTE_ALIGN_32
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;

        ALIGN_START                 => align_start                             ,--: in  std_logic;
        ALIGN_POSITION              => align_position                          ,--: in  std_logic_vector(1 downto 0);

        VALID_IN                    => '0'                                     ,--: in  std_logic;
        LAST_IN                     => '0'                                     ,--: in  std_logic;
        KEEP_IN                     => keep_buf                                ,--: in  std_logic_vector(3 downto 0);
        DATA_IN                     => data_buf                                ,--: in  std_logic_vector(31 downto 0);

        VALID_OUT                   => open                                    ,--: out std_logic;
        LAST_OUT                    => open                                    ,--: out std_logic;
        KEEP_OUT                    => open                                    ,--: out std_logic_vector(3 downto 0);
        DATA_OUT                    => aligned_rb_data                          --: out std_logic_vector(31 downto 0)
    );

--------------------------------------------------------------------------------
-- Output
--------------------------------------------------------------------------------

    process (cnt_rb)
    begin
        if (cnt_rb = 1) then
            aligned_rb_start <= '1';
        else
            aligned_rb_start <= '0';
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_split is
            when PRB    =>
                if (cnt_state = 3) then 
                    aligned_rb_tick <= '1';
                else
                    aligned_rb_tick <= '0';
                end if;
            when others =>
                aligned_rb_tick <= '0';
            end case;
        end if;
    end process;

    process (cnt_rb, sec_prb_num)
    begin
        if (cnt_rb = sec_prb_num(9 downto 0)) then
            aligned_rb_last <= '1';
        else
            aligned_rb_last <= '0';
        end if;
    end process;

--------------------------------------------------------------------------------
-- Conversion
--------------------------------------------------------------------------------

    aligned_rb_user(0)  <= aligned_rb_start;
    aligned_rb_user(1)  <= aligned_rb_last;
    aligned_rb_user(2)  <= '0';
    aligned_rb_user(3)  <= '0';
    aligned_rb_user(4)  <= '0';
    aligned_rb_user(5)  <= '0';
    aligned_rb_user(6)  <= '0';
    aligned_rb_user(7)  <= '0';
    aligned_rb_user(8)  <= '0';
    aligned_rb_user(9)  <= '0';
    aligned_rb_user(10) <= '0';
    aligned_rb_user(11) <= '0';
    aligned_rb_user(12) <= '0';
    aligned_rb_user(13) <= '0';
    aligned_rb_user(14) <= '0';
    aligned_rb_user(15) <= '0';

    u_32_to_N : PRB_32_TO_N
    generic map(
        UNCOMP_1B                   => TX_UNCOMP_1B                            ,--: boolean := true;
        UNCOMP_2B                   => TX_UNCOMP_2B                            ,--: boolean := true;
        UNCOMP_3B                   => TX_UNCOMP_3B                            ,--: boolean := true;
        UNCOMP_4B                   => TX_UNCOMP_4B                            ,--: boolean := true;
        UNCOMP_5B                   => TX_UNCOMP_5B                            ,--: boolean := true;
        UNCOMP_6B                   => TX_UNCOMP_6B                            ,--: boolean := true;
        UNCOMP_7B                   => TX_UNCOMP_7B                            ,--: boolean := true;
        UNCOMP_8B                   => TX_UNCOMP_8B                            ,--: boolean := true;
        UNCOMP_9B                   => TX_UNCOMP_9B                            ,--: boolean := true;
        UNCOMP_10B                  => TX_UNCOMP_10B                           ,--: boolean := true;
        UNCOMP_11B                  => TX_UNCOMP_11B                           ,--: boolean := true;
        UNCOMP_12B                  => TX_UNCOMP_12B                           ,--: boolean := true;
        UNCOMP_13B                  => TX_UNCOMP_13B                           ,--: boolean := true;
        UNCOMP_14B                  => TX_UNCOMP_14B                           ,--: boolean := true;
        UNCOMP_15B                  => TX_UNCOMP_15B                           ,--: boolean := true;
        UNCOMP_16B                  => TX_UNCOMP_16B                           ,--: boolean := true;
        COMP_1B                     => TX_COMP_1B                              ,--: boolean := true;
        COMP_2B                     => TX_COMP_2B                              ,--: boolean := true;
        COMP_3B                     => TX_COMP_3B                              ,--: boolean := true;
        COMP_4B                     => TX_COMP_4B                              ,--: boolean := true;
        COMP_5B                     => TX_COMP_5B                              ,--: boolean := true;
        COMP_6B                     => TX_COMP_6B                              ,--: boolean := true;
        COMP_7B                     => TX_COMP_7B                              ,--: boolean := true;
        COMP_8B                     => TX_COMP_8B                              ,--: boolean := true;
        COMP_9B                     => TX_COMP_9B                              ,--: boolean := true;
        COMP_10B                    => TX_COMP_10B                             ,--: boolean := true;
        COMP_11B                    => TX_COMP_11B                             ,--: boolean := true;
        COMP_12B                    => TX_COMP_12B                             ,--: boolean := true;
        COMP_13B                    => TX_COMP_13B                             ,--: boolean := true;
        COMP_14B                    => TX_COMP_14B                             ,--: boolean := true;
        COMP_15B                    => TX_COMP_15B                             ,--: boolean := true;
        COMP_16B                    => TX_COMP_16B                              --: boolean := false
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => RST                                     ,--: in  std_logic;

        PRB_COMP_HDR                => ud_comp_hdr                             ,--: in  std_logic_vector(7 downto 0);

        PRB_VALID                   => '0'                                     ,--: in  std_logic;
        PRB_TICK                    => aligned_rb_tick                         ,--: in  std_logic;
        PRB_KEEP                    => x"0"                                    ,--: in  std_logic_vector(3 downto 0);
        PRB_DATA                    => aligned_rb_data                         ,--: in  std_logic_vector(31 downto 0);
        PRB_USER                    => aligned_rb_user                         ,--: in  std_logic_vector(15 downto 0);

        COMP_HDR                    => conv_hdr                                ,--: out std_logic_vector(7 downto 0);
        COMP_PARAM                  => conv_param                              ,--: out std_logic_vector(7 downto 0);

        COMP_VALID                  => conv_valid                              ,--: out std_logic;
        COMP_TICK                   => conv_tick                               ,--: out std_logic;
        COMP_DATA_I                 => conv_data_i                             ,--: out std_logic_vector(15 downto 0);
        COMP_DATA_Q                 => conv_data_q                             ,--: out std_logic_vector(15 downto 0);
        COMP_USER                   => conv_user                                --: out std_logic_vector(15 downto 0)
    );

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (aligned_rb_tick = '1') then
                if (app_direction = LINK_DIRECTION) then
                    conv_enable <= '1';
                else
                    conv_enable <= '0';
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (conv_tick = '1') and (conv_user(0) = '1') then
                COMP_FRAME_ID           <= app_frame_id;
                COMP_SUBFRAME_ID        <= app_subframe_id;
                COMP_SLOT_ID            <= app_slot_id;
                COMP_SYMBOL_ID          <= app_symbol_id;
                COMP_USER(62 downto 59) <= channel_id;
                COMP_USER(58 downto 43) <= seq_id;
                COMP_USER(42 downto 27) <= eaxc_id;
                COMP_USER(26 downto 15) <= sec_id;
                COMP_USER(14)           <= sec_rb_indi;
                COMP_USER(13 downto 4)  <= sec_prb_start;
                COMP_HDR                <= conv_hdr;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (conv_tick = '1') then
                COMP_USER(3 downto 0) <= conv_user(3 downto 0);
                COMP_PARAM            <= conv_param;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            COMP_VALID  <= conv_valid and conv_enable;
            COMP_TICK   <= conv_tick;
            COMP_DATA_I <= conv_data_i;
            COMP_DATA_Q <= conv_data_q;
        end if;
    end process;

end BEHAVE;