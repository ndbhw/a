--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : UL TX window buffer for PRACH (O-RAN component)               --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.15                                                    --
--                                                                            --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UP_TX_WINDOW_RACH is
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;
        RST                         : in  std_logic;

--------------------------------------------------------------------------------
-- Debug
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

        STATUS_FSM                  : out std_logic_vector(5 downto 0);

--------------------------------------------------------------------------------
-- Packing timer
--------------------------------------------------------------------------------

        SECTION_TICK                : in  std_logic;
        SECTION_LAST                : in  std_logic;
        SECTION_DONE                : out std_logic;

        BANK_OF_PRB                 : in  std_logic_vector(0 downto 0);
        USE_EVERY_PRB               : in  std_logic;
        START_OF_PRB                : in  std_logic_vector(9 downto 0);
        NUMBER_OF_PRB               : in  std_logic_vector(9 downto 0);
        UD_COMP_HDR                 : in  std_logic_vector(8 downto 0);

--------------------------------------------------------------------------------
-- Input
--------------------------------------------------------------------------------

        UL_FRAME_ID                 : in  std_logic_vector(7 downto 0);
        UL_SUBFRAME_ID              : in  std_logic_vector(3 downto 0);
        UL_SLOT_ID                  : in  std_logic_vector(5 downto 0);
        UL_SYMBOL_ID                : in  std_logic_vector(5 downto 0);
        UL_BANK_ID                  : in  std_logic_vector(0 downto 0);
        UL_START_RE                 : in  std_logic_vector(15 downto 0);

        UL_VALID                    : in  std_logic;
        UL_START                    : in  std_logic;
        UL_LAST                     : in  std_logic;
        UL_DATA_I                   : in  std_logic_vector(15 downto 0);
        UL_DATA_Q                   : in  std_logic_vector(15 downto 0);

--------------------------------------------------------------------------------
-- UL U-Plane (Not encoded)
--------------------------------------------------------------------------------

        RB_COMP_HDR                 : out std_logic_vector(8 downto 0);

        RB_VALID                    : out std_logic;
        RB_TICK                     : out std_logic;
        RB_DATA_I                   : out std_logic_vector(15 downto 0);
        RB_DATA_Q                   : out std_logic_vector(15 downto 0);
        RB_USER                     : out std_logic_vector(15 downto 0)
    );
end UP_TX_WINDOW_RACH;

architecture BEHAVE of UP_TX_WINDOW_RACH is

    constant LATENCY_BUFFER         : natural := 3;                             -- IP latency
    constant PACK_GAP               : natural := 7-LATENCY_BUFFER;

    component BUFFER_32x2K is
    port (
        CLKA                        : in  std_logic;
        ENA                         : in  std_logic;
        WEA                         : in  std_logic_vector(0 downto 0);
        ADDRA                       : in  std_logic_vector(10 downto 0);
        DINA                        : in  std_logic_vector(31 downto 0);
        DOUTA                       : out std_logic_vector(31 downto 0);
        CLKB                        : in  std_logic;
        ENB                         : in  std_logic;
        WEB                         : in  std_logic_vector(0 downto 0);
        ADDRB                       : in  std_logic_vector(10 downto 0);
        DINB                        : in  std_logic_vector(31 downto 0);
        DOUTB                       : out std_logic_vector(31 downto 0)
    );
    end component;

    signal ena                      : std_logic := '0';
    signal wea                      : std_logic_vector(0 downto 0) := (others => '0');
    signal addra_msb                : std_logic_vector(0 downto 0) := (others => '0');
    signal addra_lsb                : std_logic_vector(9 downto 0) := (others => '0');
    signal addra                    : std_logic_vector(10 downto 0);
    signal dina                     : std_logic_vector(31 downto 0) := (others => '0');
    signal enb                      : std_logic := '0';
    signal web                      : std_logic_vector(0 downto 0) := (others => '0');
    signal addrb_msb                : std_logic_vector(0 downto 0) := (others => '0');
    signal addrb_lsb                : std_logic_vector(9 downto 0) := (others => '0');
    signal addrb                    : std_logic_vector(10 downto 0) := (others => '0');
    signal doutb                    : std_logic_vector(31 downto 0);

    type fsm                        is (IDLE, PRELOAD, PRB, POSTLOAD, WAITING);
    signal fsm_pack                 : fsm;
    signal cnt_pack_state           : std_logic_vector(3 downto 0);
    signal cnt_set                  : std_logic_vector(9 downto 0);

    signal sec_prb_last             : std_logic := '0';
    signal sec_prb_bank             : std_logic_vector(0 downto 0) := (others => '0');
    signal sec_rb                   : std_logic := '0';
    signal sec_re_start             : std_logic_vector(11 downto 0) := (others => '0');
    signal sec_prb_num              : std_logic_vector(9 downto 0) := (others => '0');
    signal sec_comp_hdr             : std_logic_vector(8 downto 0) := (others => '0');

    signal iq_valid                 : std_logic_vector(LATENCY_BUFFER-1 downto 0) := (others => '0');
    signal iq_start                 : std_logic;
    signal iq_end                   : std_logic;

begin

--------------------------------------------------------------------------------
-- Write PRB data
--------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            ena    <= UL_VALID;
            wea(0) <= UL_VALID;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (UL_VALID = '1') then
                if (UL_START = '1') then
                    addra_msb <= UL_BANK_ID(0 downto 0);
                    addra_lsb <= UL_START_RE(9 downto 0);
                else
                    addra_lsb <= addra_lsb + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            dina(31 downto 16) <= UL_DATA_I;
            dina(15 downto 0)  <= UL_DATA_Q;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Buffer
--------------------------------------------------------------------------------

    addra <= addra_msb(0 downto 0) & addra_lsb(9 downto 0);

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            addrb <= addrb_msb(0 downto 0) & addrb_lsb(9 downto 0);
        end if;
    end process;

    u_BUFFER : BUFFER_32x2K
    port map(
        CLKA                        => CLK                                     ,--: in  std_logic;
        ENA                         => ena                                     ,--: in  std_logic;
        WEA                         => wea                                     ,--: in  std_logic_vector(0 downto 0);
        ADDRA                       => addra                                   ,--: in  std_logic_vector(10 downto 0);
        DINA                        => dina                                    ,--: in  std_logic_vector(31 downto 0);
        DOUTA                       => open                                    ,--: out std_logic_vector(31 downto 0);
        CLKB                        => CLK                                     ,--: in  std_logic;
        ENB                         => enb                                     ,--: in  std_logic;
        WEB                         => web                                     ,--: in  std_logic_vector(0 downto 0);
        ADDRB                       => addrb                                   ,--: in  std_logic_vector(10 downto 0);
        DINB                        => (others => '0')                         ,--: in  std_logic_vector(31 downto 0);
        DOUTB                       => doutb                                    --: out std_logic_vector(31 downto 0)
    );

--------------------------------------------------------------------------------
-- Packing
--------------------------------------------------------------------------------

    -- FSM
    process (RST, CLK)
    begin
        if (RST = '1') then
            fsm_pack <= IDLE;
        elsif (CLK'event and CLK = '1') then
            case fsm_pack is
            when IDLE     =>
                if (SECTION_TICK = '1') then
                    fsm_pack <= PRELOAD;
                else
                    fsm_pack <= IDLE;
                end if;
            when PRELOAD  =>
                fsm_pack <= PRB;
            when PRB     =>
                if (cnt_pack_state = 11) and (cnt_set = sec_prb_num) then
                    fsm_pack <= POSTLOAD;
                else
                    fsm_pack <= PRB;
                end if;
            when POSTLOAD =>
                if (cnt_pack_state = LATENCY_BUFFER-1) then
                    fsm_pack <= WAITING;
                else
                    fsm_pack <= POSTLOAD;
                end if;
            when WAITING  =>
                if (cnt_pack_state = PACK_GAP-1) then
                    fsm_pack <= IDLE;
                else
                    fsm_pack <= WAITING;
                end if;
            when others   =>
                fsm_pack <= IDLE;
            end case;
        end if;
    end process;

    -- FSM status
    process (RST, CLK)
    begin
        if (RST = '1') then
            STATUS_FSM <= "000000";
        elsif (CLK'event and CLK = '1') then
            case fsm_pack is
            when IDLE     =>
                STATUS_FSM <= "000001";
            when PRELOAD  =>
                STATUS_FSM <= "000010";
            when PRB     =>
                STATUS_FSM <= "000100";
            when POSTLOAD =>
                STATUS_FSM <= "001000";
            when WAITING  =>
                STATUS_FSM <= "010000";
            when others   =>
                STATUS_FSM <= "100000";
            end case;
        end if;
    end process;

    -- FSM counter
    process (RST, CLK)
    begin
        if (RST = '1') then
            cnt_pack_state <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            case fsm_pack is
            when PRB      =>
                if (cnt_pack_state = 11) then
                    cnt_pack_state <= (others => '0');
                else
                    cnt_pack_state <= cnt_pack_state + 1;
                end if;
            when POSTLOAD =>
                if (cnt_pack_state = LATENCY_BUFFER-1) then
                    cnt_pack_state <= (others => '0');
                else
                    cnt_pack_state <= cnt_pack_state + 1;
                end if;
            when WAITING  =>
                if (cnt_pack_state = PACK_GAP-1) then
                    cnt_pack_state <= (others => '0');
                else
                    cnt_pack_state <= cnt_pack_state + 1;
                end if;
            when others   =>
                cnt_pack_state <= (others => '0');
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_pack is
            when PRB      =>
                if (cnt_pack_state = 11) then
                    cnt_set <= cnt_set + 1;
                end if;
            when others   =>
                cnt_set <= "0000000001";
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (SECTION_TICK = '1') then
                sec_prb_last <= SECTION_LAST;
                sec_prb_bank <= BANK_OF_PRB;
                sec_rb       <= not USE_EVERY_PRB;
                sec_re_start <= (START_OF_PRB(9 downto 0) & "00") + (START_OF_PRB(8 downto 0) & "000");
                sec_prb_num  <= NUMBER_OF_PRB;
                sec_comp_hdr <= UD_COMP_HDR;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_pack is
            when WAITING  =>
                if (cnt_pack_state = PACK_GAP-1) then
                    SECTION_DONE <= '1';
                else
                    SECTION_DONE <= '0';
                end if;
            when others   =>
                SECTION_DONE <= '0';
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_pack is
            when PRB      =>
                if (cnt_set = 1) then
                    iq_start <= '1';
                else
                    iq_start <= '0';
                end if;
            when others   =>
                iq_start <= '0';
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_pack is
            when PRB      =>
                if (cnt_set = sec_prb_num) then
                    iq_end <= '1';
                else
                    iq_end <= '0';
                end if;
            when others   =>
                iq_end <= '0';
            end case;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Read
--------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_pack is
            when PRB      =>
                enb <= '1';
                web <= "1";
            when POSTLOAD =>
                enb <= '1';
                web <= "0";
            when others   =>
                enb <= '0';
                web <= "0";
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_pack is
            when PRELOAD  =>
                addrb_msb <= sec_prb_bank;
                addrb_lsb <= sec_re_start(9 downto 0);
            when PRB      =>
                if (sec_rb = '0') then
                    addrb_lsb <= addrb_lsb + 1;
                else
                    if (cnt_pack_state = 11) then
                        addrb_lsb <= addrb_lsb + 13;
                    else
                        addrb_lsb <= addrb_lsb + 1;
                    end if;
                end if;
            when others   =>
                addrb_lsb <= (others => '0');
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            iq_valid <= iq_valid(LATENCY_BUFFER-2 downto 0) & web;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (iq_valid(LATENCY_BUFFER-1) = '1') then
                RB_COMP_HDR <= sec_comp_hdr;
            else
                RB_COMP_HDR <= (others => '0');
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (iq_valid(LATENCY_BUFFER-1) = '1') then
                RB_VALID  <= '1';
                if (cnt_pack_state = LATENCY_BUFFER+1) then
                    RB_TICK   <= '1';
                else
                    RB_TICK   <= '0';
                end if;
                RB_DATA_I <= doutb(31 downto 16);
                RB_DATA_Q <= doutb(15 downto 0);
            else
                RB_VALID  <= '0';
                RB_TICK   <= '0';
                RB_DATA_I <= (others => '0');
                RB_DATA_Q <= (others => '0');
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (iq_valid(LATENCY_BUFFER-1) = '1') then
                if (cnt_pack_state = LATENCY_BUFFER+1) then
                    RB_USER(0)           <= iq_start;
                    RB_USER(1)           <= iq_end;
                    RB_USER(2)           <= iq_end and sec_prb_last;
                    RB_USER(15 downto 3) <= (others => '0');
                end if;
            else
                RB_USER              <= (others => '0');
            end if;
        end if;
    end process;

end BEHAVE;