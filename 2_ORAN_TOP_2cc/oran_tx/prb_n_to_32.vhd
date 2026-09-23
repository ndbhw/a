--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : PRB aligner, n-to-32 bits (O-RAN component)                   --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.15                                                    --
--                                                                            --
--------------------------------------------------------------------------------
-- Configurations                                                             --
--------------------------------------------------------------------------------
--  IQ bit width  1 (X)                                                       --
--  IQ bit width  2 (X)                                                       --
--  IQ bit width  3 - Uncomp/MC/BFP                                           --
--  IQ bit width  4 - Uncomp/MC/BFP                                           --
--  IQ bit width  5 - Uncomp/MC/BFP                                           --
--  IQ bit width  6 - Uncomp/MC/BFP                                           --
--  IQ bit width  7 - Uncomp/MC/BFP                                           --
--  IQ bit width  8 - Uncomp/MC/BFP                                           --
--  IQ bit width  9 - Uncomp/MC/BFP                                           --
--  IQ bit width 10 - Uncomp/MC/BFP                                           --
--  IQ bit width 11 - Uncomp/MC/BFP                                           --
--  IQ bit width 12 - Uncomp/MC/BFP                                           --
--  IQ bit width 13 - Uncomp/MC/BFP                                           --
--  IQ bit width 14 - Uncomp/MC/BFP                                           --
--  IQ bit width 15 - Uncomp/MC/BFP                                           --
--  IQ bit width 16 - Uncomp/MC                                               --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity PRB_N_TO_32 is
    generic (
        -- udCompParam is not present (Uncomp/MC)
        UNCOMP_1B                   : boolean := false;
        UNCOMP_2B                   : boolean := false;
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
        -- udCompParam is present (BFP)
        COMP_1B                     : boolean := false;
        COMP_2B                     : boolean := false;
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
--------------------------------------------------------------------------------
-- Clock
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;
        RST                         : in  std_logic;

--------------------------------------------------------------------------------
-- Compression block
--------------------------------------------------------------------------------

        COMP_HDR                    : in  std_logic_vector(8 downto 0);
        COMP_PARAM                  : in  std_logic_vector(7 downto 0);

        COMP_VALID                  : in  std_logic;
        COMP_TICK                   : in  std_logic;
        COMP_DATA_I                 : in  std_logic_vector(15 downto 0);
        COMP_DATA_Q                 : in  std_logic_vector(15 downto 0);
        COMP_USER                   : in  std_logic_vector(15 downto 0);

--------------------------------------------------------------------------------
-- PRB data bus
--------------------------------------------------------------------------------

        PRB_COMP_HDR                : out std_logic_vector(8 downto 0);

        PRB_VALID                   : out std_logic;
        PRB_TICK                    : out std_logic;
        PRB_KEEP                    : out std_logic_vector(3 downto 0);
        PRB_DATA                    : out std_logic_vector(31 downto 0);
        PRB_USER                    : out std_logic_vector(15 downto 0)
    );
end PRB_N_TO_32;

architecture BEHAVE of PRB_N_TO_32 is

    type std_logic_array16          is array(natural range <>) of std_logic_vector(15 downto 0);

    signal comp_mode                : std_logic := '0';
    signal iq_width                 : std_logic_vector(3 downto 0) := (others => '0');
    signal comp_method              : std_logic_vector(3 downto 0) := (others => '0');

    signal buf_tick                 : std_logic_vector(7 downto 0) := (others => '0');
    signal buf_param                : std_logic_vector(7 downto 0) := (others => '0');
    signal buf_i                    : std_logic_array16(9 downto 0) := (others => (others => '0'));
    signal buf_q                    : std_logic_array16(9 downto 0) := (others => (others => '0'));
    signal buf_user                 : std_logic_vector(15 downto 0) := (others => '0');

    signal start                    : std_logic := '0';
    signal cnt                      : std_logic_vector(3 downto 0) := (others => '1');

    signal out_prb_tick             : std_logic;
    signal out_prb_dis              : std_logic;
    signal out_prb_valid            : std_logic;
    signal out_prb_keep             : std_logic_vector(3 downto 0);
    signal out_prb_data             : std_logic_vector(31 downto 0);

begin

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            buf_tick <= buf_tick(6 downto 0) & COMP_TICK;
            buf_i    <= buf_i(8 downto 0) & COMP_DATA_I;
            buf_q    <= buf_q(8 downto 0) & COMP_DATA_Q;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (COMP_TICK = '1') then
                comp_mode   <= COMP_HDR(8);
                iq_width    <= COMP_HDR(7 downto 4);
                comp_method <= COMP_HDR(3 downto 0);
                buf_param   <= COMP_PARAM;
                buf_user    <= COMP_USER;
            end if;
        end if;
    end process;

    -- Use buf_tick(0) if the maximum gap between input and output is 2.
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (COMP_HDR(1 downto 0) = "00") then
                if    (UNCOMP_16B = true) and (COMP_HDR(7 downto 4) = 0) then   -- Uncomp/MC + 16bits
                    start <= buf_tick(5);
                elsif (UNCOMP_15B = true) and (COMP_HDR(7 downto 4) = 15) then  -- Uncomp/MC + 15bits
                    start <= buf_tick(5);
                elsif (UNCOMP_14B = true) and (COMP_HDR(7 downto 4) = 14) then  -- Uncomp/MC + 14bits
                    start <= buf_tick(5);
                elsif (UNCOMP_13B = true) and (COMP_HDR(7 downto 4) = 13) then  -- Uncomp/MC + 13bits
                    start <= buf_tick(5);
                elsif (UNCOMP_12B = true) and (COMP_HDR(7 downto 4) = 12) then  -- Uncomp/MC + 12bits
                    start <= buf_tick(5);
                elsif (UNCOMP_11B = true) and (COMP_HDR(7 downto 4) = 11) then  -- Uncomp/MC + 11bits
                    start <= buf_tick(5);
                elsif (UNCOMP_10B = true) and (COMP_HDR(7 downto 4) = 10) then  -- Uncomp/MC + 10bits
                    start <= buf_tick(5);
                elsif (UNCOMP_9B = true) and (COMP_HDR(7 downto 4) = 9) then    -- Uncomp/MC +  9bits
                    start <= buf_tick(5);
                elsif (UNCOMP_8B = true) and (COMP_HDR(7 downto 4) = 8) then    -- Uncomp/MC +  8bits
                    start <= buf_tick(5);
                elsif (UNCOMP_7B = true) and (COMP_HDR(7 downto 4) = 7) then    -- Uncomp/MC +  7bits
                    start <= buf_tick(5);
                elsif (UNCOMP_6B = true) and (COMP_HDR(7 downto 4) = 6) then    -- Uncomp/MC +  6bits
                    start <= buf_tick(5);
                elsif (UNCOMP_5B = true) and (COMP_HDR(7 downto 4) = 5) then    -- Uncomp/MC +  5bits
                    start <= buf_tick(6);
                elsif (UNCOMP_4B = true) and (COMP_HDR(7 downto 4) = 4) then    -- Uncomp/MC +  4bits
                    start <= buf_tick(7);
                elsif (UNCOMP_3B = true) and (COMP_HDR(7 downto 4) = 3) then    -- Uncomp/MC +  3bits
                    start <= buf_tick(7);
                else
                    start <= '0';
                end if;
            else
                if    (COMP_15B = true) and (COMP_HDR(7 downto 4) = 15) then    -- Comp + 15bits
                    start <= buf_tick(5);
                elsif (COMP_14B = true) and (COMP_HDR(7 downto 4) = 14) then    -- Comp + 14bits
                    start <= buf_tick(5);
                elsif (COMP_13B = true) and (COMP_HDR(7 downto 4) = 13) then    -- Comp + 13bits
                    start <= buf_tick(5);
                elsif (COMP_12B = true) and (COMP_HDR(7 downto 4) = 12) then    -- Comp + 12bits
                    start <= buf_tick(5);
                elsif (COMP_11B = true) and (COMP_HDR(7 downto 4) = 11) then    -- Comp + 11bits
                    start <= buf_tick(5);
                elsif (COMP_10B = true) and (COMP_HDR(7 downto 4) = 10) then    -- Comp + 10bits
                    start <= buf_tick(5);
                elsif (COMP_9B = true) and (COMP_HDR(7 downto 4) = 9) then      -- Comp +  9bits
                    start <= buf_tick(5);
                elsif (COMP_8B = true) and (COMP_HDR(7 downto 4) = 8) then      -- Comp +  8bits
                    start <= buf_tick(5);
                elsif (COMP_7B = true) and (COMP_HDR(7 downto 4) = 7) then      -- Comp +  7bits
                    start <= buf_tick(5);
                elsif (COMP_6B = true) and (COMP_HDR(7 downto 4) = 6) then      -- Comp +  6bits
                    start <= buf_tick(5);
                elsif (COMP_5B = true) and (COMP_HDR(7 downto 4) = 5) then      -- Comp +  5bits
                    start <= buf_tick(6);
                elsif (COMP_4B = true) and (COMP_HDR(7 downto 4) = 4) then      -- Comp +  4bits
                    start <= buf_tick(6);
                elsif (COMP_3B = true) and (COMP_HDR(7 downto 4) = 3) then      -- Comp +  3bits
                    start <= buf_tick(7);
                else
                    start <= '0';
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (start = '1') then
                cnt <= (others => '0');
            else
                if (cnt = 15) then
                    cnt <= cnt;
                else
                    cnt <= cnt + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (comp_method(1 downto 0) = "00") then
                if    (UNCOMP_16B = true) and (iq_width = 0) then               -- Uncomp/MC + 16bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"5"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"6"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"7"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"8"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"9"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"A"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"B"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (UNCOMP_15B = true) and (iq_width = 15) then              -- Uncomp/MC + 15bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"5"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"6"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"7"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"8"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"9"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"A"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"B"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1000";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (UNCOMP_14B = true) and (iq_width = 14) then              -- Uncomp/MC + 14bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"5"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"6"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"7"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"8"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"9"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"A"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1100";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (UNCOMP_13B = true) and (iq_width = 13) then              -- Uncomp/MC + 13bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"5"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"6"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"7"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"8"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"9"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1110";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (UNCOMP_12B = true) and (iq_width = 12) then              -- Uncomp/MC + 12bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"5"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"6"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"7"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"8"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (UNCOMP_11B = true) and (iq_width = 11) then              -- Uncomp/MC + 11bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"5"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"6"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"7"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"8"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1000";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (UNCOMP_10B = true) and (iq_width = 10) then              -- Uncomp/MC + 10bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"5"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"6"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"7"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1100";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (UNCOMP_9B = true) and (iq_width = 9) then                -- Uncomp/MC +  9bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"5"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"6"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1110";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (UNCOMP_8B = true) and (iq_width = 8) then                -- Uncomp/MC +  8bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"5"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (UNCOMP_7B = true) and (iq_width = 7) then                -- Uncomp/MC +  7bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"5"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1000";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (UNCOMP_6B = true) and (iq_width = 6) then                -- Uncomp/MC +  6bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1100";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (UNCOMP_5B = true) and (iq_width = 5) then                -- Uncomp/MC +  5bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1110";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (UNCOMP_4B = true) and (iq_width = 4) then                -- Uncomp/MC +  4bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (UNCOMP_3B = true) and (iq_width = 3) then                -- Uncomp/MC +  3bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1000";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                else
                    out_prb_tick  <= '0';
                    out_prb_dis   <= '1';
                    out_prb_valid <= '0';
                    out_prb_keep  <= "0000";
                end if;
            else
                if    (COMP_15B = true) and (iq_width = 15) then                -- Comp + 15bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"5"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"6"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"7"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"8"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"9"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"A"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"B"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1100";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (COMP_14B = true) and (iq_width = 14) then                -- Comp + 14bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"5"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"6"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"7"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"8"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"9"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"A"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1110";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (COMP_13B = true) and (iq_width = 13) then                -- Comp + 13bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"5"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"6"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"7"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"8"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"9"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (COMP_12B = true) and (iq_width = 12) then                -- Comp + 12bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"5"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"6"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"7"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"8"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"9"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1000";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (COMP_11B = true) and (iq_width = 11) then                -- Comp + 11bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"5"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"6"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"7"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"8"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1100";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (COMP_10B = true) and (iq_width = 10) then                -- Comp + 10bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"5"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"6"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"7"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1110";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (COMP_9B = true) and (iq_width = 9) then                  -- Comp +  9bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"5"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"6"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (COMP_8B = true) and (iq_width = 8) then                  -- Comp +  8bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"5"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"6"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1000";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (COMP_7B = true) and (iq_width = 7) then                  -- Comp +  7bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"5"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1100";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (COMP_6B = true) and (iq_width = 6) then                  -- Comp +  6bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"4"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1110";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (COMP_5B = true) and (iq_width = 5) then                  -- Comp +  5bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (COMP_4B = true) and (iq_width = 4) then                  -- Comp +  4bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"3"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1000";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                elsif (COMP_3B = true) and (iq_width = 3) then                  -- Comp +  3bits
                    case cnt is
                    when x"0"   => out_prb_tick <= '1'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"1"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1111";
                    when x"2"   => out_prb_tick <= '0'; out_prb_dis <= '0'; out_prb_valid <= '1'; out_prb_keep <= "1100";
                    when others => out_prb_tick <= '0'; out_prb_dis <= '1'; out_prb_valid <= '0'; out_prb_keep <= "0000";
                    end case;
                else
                    out_prb_tick  <= '0';
                    out_prb_dis   <= '1';
                    out_prb_valid <= '0';
                    out_prb_keep  <= "0000";
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (comp_method(1 downto 0) = "00") then
                if    (UNCOMP_16B = true) and (iq_width = 0) then               -- Uncomp/MC + 16bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_i(7)(15 downto 0)  & buf_q(7)(15 downto 0);
                    when x"1"   => out_prb_data <= buf_i(7)(15 downto 0)  & buf_q(7)(15 downto 0);
                    when x"2"   => out_prb_data <= buf_i(7)(15 downto 0)  & buf_q(7)(15 downto 0);
                    when x"3"   => out_prb_data <= buf_i(7)(15 downto 0)  & buf_q(7)(15 downto 0);
                    when x"4"   => out_prb_data <= buf_i(7)(15 downto 0)  & buf_q(7)(15 downto 0);
                    when x"5"   => out_prb_data <= buf_i(7)(15 downto 0)  & buf_q(7)(15 downto 0);
                    when x"6"   => out_prb_data <= buf_i(7)(15 downto 0)  & buf_q(7)(15 downto 0);
                    when x"7"   => out_prb_data <= buf_i(7)(15 downto 0)  & buf_q(7)(15 downto 0);
                    when x"8"   => out_prb_data <= buf_i(7)(15 downto 0)  & buf_q(7)(15 downto 0);
                    when x"9"   => out_prb_data <= buf_i(7)(15 downto 0)  & buf_q(7)(15 downto 0);
                    when x"A"   => out_prb_data <= buf_i(7)(15 downto 0)  & buf_q(7)(15 downto 0);
                    when x"B"   => out_prb_data <= buf_i(7)(15 downto 0)  & buf_q(7)(15 downto 0);
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (UNCOMP_15B = true) and (iq_width = 15) then              -- Uncomp/MC + 15bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_i(7)(14 downto 0)  & buf_q(7)(14 downto 0)  & buf_i(6)(14 downto 13);
                    when x"1"   => out_prb_data <= buf_i(7)(12 downto 0)  & buf_q(7)(14 downto 0)  & buf_i(6)(14 downto 11);
                    when x"2"   => out_prb_data <= buf_i(7)(10 downto 0)  & buf_q(7)(14 downto 0)  & buf_i(6)(14 downto 9);
                    when x"3"   => out_prb_data <= buf_i(7)(8 downto 0)   & buf_q(7)(14 downto 0)  & buf_i(6)(14 downto 7);
                    when x"4"   => out_prb_data <= buf_i(7)(6 downto 0)   & buf_q(7)(14 downto 0)  & buf_i(6)(14 downto 5);
                    when x"5"   => out_prb_data <= buf_i(7)(4 downto 0)   & buf_q(7)(14 downto 0)  & buf_i(6)(14 downto 3);
                    when x"6"   => out_prb_data <= buf_i(7)(2 downto 0)   & buf_q(7)(14 downto 0)  & buf_i(6)(14 downto 1);
                    when x"7"   => out_prb_data <= buf_i(7)(0 downto 0)   & buf_q(7)(14 downto 0)  & buf_i(6)(14 downto 0)  & buf_q(6)(14 downto 14);
                    when x"8"   => out_prb_data <= buf_q(7)(13 downto 0)  & buf_i(6)(14 downto 0)  & buf_q(6)(14 downto 12);
                    when x"9"   => out_prb_data <= buf_q(7)(11 downto 0)  & buf_i(6)(14 downto 0)  & buf_q(6)(14 downto 10);
                    when x"A"   => out_prb_data <= buf_q(7)(9 downto 0)   & buf_i(6)(14 downto 0)  & buf_q(6)(14 downto 8);
                    when x"B"   => out_prb_data <= buf_q(7)(7 downto 0)   & x"000000";
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (UNCOMP_14B = true) and (iq_width = 14) then              -- Uncomp/MC + 14bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_i(7)(13 downto 0)  & buf_q(7)(13 downto 0)  & buf_i(6)(13 downto 10);
                    when x"1"   => out_prb_data <= buf_i(7)(9 downto 0)   & buf_q(7)(13 downto 0)  & buf_i(6)(13 downto 6);
                    when x"2"   => out_prb_data <= buf_i(7)(5 downto 0)   & buf_q(7)(13 downto 0)  & buf_i(6)(13 downto 2);
                    when x"3"   => out_prb_data <= buf_i(7)(1 downto 0)   & buf_q(7)(13 downto 0)  & buf_i(6)(13 downto 0)  & buf_q(6)(13 downto 12);
                    when x"4"   => out_prb_data <= buf_q(7)(11 downto 0)  & buf_i(6)(13 downto 0)  & buf_q(6)(13 downto 8);
                    when x"5"   => out_prb_data <= buf_q(7)(7 downto 0)   & buf_i(6)(13 downto 0)  & buf_q(6)(13 downto 4);
                    when x"6"   => out_prb_data <= buf_q(7)(3 downto 0)   & buf_i(6)(13 downto 0)  & buf_q(6)(13 downto 0);
                    when x"7"   => out_prb_data <= buf_i(6)(13 downto 0)  & buf_q(6)(13 downto 0)  & buf_i(5)(13 downto 10);
                    when x"8"   => out_prb_data <= buf_i(6)(9 downto 0)   & buf_q(6)(13 downto 0)  & buf_i(5)(13 downto 6);
                    when x"9"   => out_prb_data <= buf_i(6)(5 downto 0)   & buf_q(6)(13 downto 0)  & buf_i(5)(13 downto 2);
                    when x"A"   => out_prb_data <= buf_i(6)(1 downto 0)   & buf_q(6)(13 downto 0)  & x"0000";
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (UNCOMP_13B = true) and (iq_width = 13) then              -- Uncomp/MC + 13bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_i(7)(12 downto 0)  & buf_q(7)(12 downto 0)  & buf_i(6)(12 downto 7);
                    when x"1"   => out_prb_data <= buf_i(7)(6 downto 0)   & buf_q(7)(12 downto 0)  & buf_i(6)(12 downto 1);
                    when x"2"   => out_prb_data <= buf_i(7)(0 downto 0)   & buf_q(7)(12 downto 0)  & buf_i(6)(12 downto 0)  & buf_q(6)(12 downto 8);
                    when x"3"   => out_prb_data <= buf_q(7)(7 downto 0)   & buf_i(6)(12 downto 0)  & buf_q(6)(12 downto 2);
                    when x"4"   => out_prb_data <= buf_q(7)(1 downto 0)   & buf_i(6)(12 downto 0)  & buf_q(6)(12 downto 0)  & buf_i(5)(12 downto 9);
                    when x"5"   => out_prb_data <= buf_i(6)(8 downto 0)   & buf_q(6)(12 downto 0)  & buf_i(5)(12 downto 3);
                    when x"6"   => out_prb_data <= buf_i(6)(2 downto 0)   & buf_q(6)(12 downto 0)  & buf_i(5)(12 downto 0)  & buf_q(5)(12 downto 10);
                    when x"7"   => out_prb_data <= buf_q(6)(9 downto 0)   & buf_i(5)(12 downto 0)  & buf_q(5)(12 downto 4);
                    when x"8"   => out_prb_data <= buf_q(6)(3 downto 0)   & buf_i(5)(12 downto 0)  & buf_q(5)(12 downto 0)  & buf_i(4)(12 downto 11);
                    when x"9"   => out_prb_data <= buf_i(5)(10 downto 0)  & buf_q(5)(12 downto 0)  & x"00";
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (UNCOMP_12B = true) and (iq_width = 12) then              -- Uncomp/MC + 12bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_i(7)(11 downto 0)  & buf_q(7)(11 downto 0)  & buf_i(6)(11 downto 4);
                    when x"1"   => out_prb_data <= buf_i(7)(3 downto 0)   & buf_q(7)(11 downto 0)  & buf_i(6)(11 downto 0)  & buf_q(6)(11 downto 8);
                    when x"2"   => out_prb_data <= buf_q(7)(7 downto 0)   & buf_i(6)(11 downto 0)  & buf_q(6)(11 downto 0);
                    when x"3"   => out_prb_data <= buf_i(6)(11 downto 0)  & buf_q(6)(11 downto 0)  & buf_i(5)(11 downto 4);
                    when x"4"   => out_prb_data <= buf_i(6)(3 downto 0)   & buf_q(6)(11 downto 0)  & buf_i(5)(11 downto 0)  & buf_q(5)(11 downto 8);
                    when x"5"   => out_prb_data <= buf_q(6)(7 downto 0)   & buf_i(5)(11 downto 0)  & buf_q(5)(11 downto 0);
                    when x"6"   => out_prb_data <= buf_i(5)(11 downto 0)  & buf_q(5)(11 downto 0)  & buf_i(4)(11 downto 4);
                    when x"7"   => out_prb_data <= buf_i(5)(3 downto 0)   & buf_q(5)(11 downto 0)  & buf_i(4)(11 downto 0)  & buf_q(4)(11 downto 8);
                    when x"8"   => out_prb_data <= buf_q(5)(7 downto 0)   & buf_i(4)(11 downto 0)  & buf_q(4)(11 downto 0);
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (UNCOMP_11B = true) and (iq_width = 11) then              -- Uncomp/MC + 11bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_i(7)(10 downto 0)  & buf_q(7)(10 downto 0)  & buf_i(6)(10 downto 1);
                    when x"1"   => out_prb_data <= buf_i(7)(0 downto 0)   & buf_q(7)(10 downto 0)  & buf_i(6)(10 downto 0)  & buf_q(6)(10 downto 2);
                    when x"2"   => out_prb_data <= buf_q(7)(1 downto 0)   & buf_i(6)(10 downto 0)  & buf_q(6)(10 downto 0)  & buf_i(5)(10 downto 3);
                    when x"3"   => out_prb_data <= buf_i(6)(2 downto 0)   & buf_q(6)(10 downto 0)  & buf_i(5)(10 downto 0)  & buf_q(5)(10 downto 4);
                    when x"4"   => out_prb_data <= buf_q(6)(3 downto 0)   & buf_i(5)(10 downto 0)  & buf_q(5)(10 downto 0)  & buf_i(4)(10 downto 5);
                    when x"5"   => out_prb_data <= buf_i(5)(4 downto 0)   & buf_q(5)(10 downto 0)  & buf_i(4)(10 downto 0)  & buf_q(4)(10 downto 6);
                    when x"6"   => out_prb_data <= buf_q(5)(5 downto 0)   & buf_i(4)(10 downto 0)  & buf_q(4)(10 downto 0)  & buf_i(3)(10 downto 7);
                    when x"7"   => out_prb_data <= buf_i(4)(6 downto 0)   & buf_q(4)(10 downto 0)  & buf_i(3)(10 downto 0)  & buf_q(3)(10 downto 8);
                    when x"8"   => out_prb_data <= buf_q(4)(7 downto 0)   & x"000000";
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (UNCOMP_10B = true) and (iq_width = 10) then              -- Uncomp/MC + 10bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_i(7)(9 downto 0)   & buf_q(7)(9 downto 0)   & buf_i(6)(9 downto 0)   & buf_q(6)(9 downto 8);
                    when x"1"   => out_prb_data <= buf_q(7)(7 downto 0)   & buf_i(6)(9 downto 0)   & buf_q(6)(9 downto 0)   & buf_i(5)(9 downto 6);
                    when x"2"   => out_prb_data <= buf_i(6)(5 downto 0)   & buf_q(6)(9 downto 0)   & buf_i(5)(9 downto 0)   & buf_q(5)(9 downto 4);
                    when x"3"   => out_prb_data <= buf_q(6)(3 downto 0)   & buf_i(5)(9 downto 0)   & buf_q(5)(9 downto 0)   & buf_i(4)(9 downto 2);
                    when x"4"   => out_prb_data <= buf_i(5)(1 downto 0)   & buf_q(5)(9 downto 0)   & buf_i(4)(9 downto 0)   & buf_q(4)(9 downto 0);
                    when x"5"   => out_prb_data <= buf_i(4)(9 downto 0)   & buf_q(4)(9 downto 0)   & buf_i(3)(9 downto 0)   & buf_q(3)(9 downto 8);
                    when x"6"   => out_prb_data <= buf_q(4)(7 downto 0)   & buf_i(3)(9 downto 0)   & buf_q(3)(9 downto 0)   & buf_i(2)(9 downto 6);
                    when x"7"   => out_prb_data <= buf_i(3)(5 downto 0)   & buf_q(3)(9 downto 0)   & x"0000";
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (UNCOMP_9B = true) and (iq_width = 9) then                -- Uncomp/MC +  9bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_i(7)(8 downto 0)   & buf_q(7)(8 downto 0)   & buf_i(6)(8 downto 0)   & buf_q(6)(8 downto 4);
                    when x"1"   => out_prb_data <= buf_q(7)(3 downto 0)   & buf_i(6)(8 downto 0)   & buf_q(6)(8 downto 0)   & buf_i(5)(8 downto 0)   & buf_q(5)(8 downto 8);
                    when x"2"   => out_prb_data <= buf_q(6)(7 downto 0)   & buf_i(5)(8 downto 0)   & buf_q(5)(8 downto 0)   & buf_i(4)(8 downto 3);
                    when x"3"   => out_prb_data <= buf_i(5)(2 downto 0)   & buf_q(5)(8 downto 0)   & buf_i(4)(8 downto 0)   & buf_q(4)(8 downto 0)   & buf_i(3)(8 downto 7);
                    when x"4"   => out_prb_data <= buf_i(4)(6 downto 0)   & buf_q(4)(8 downto 0)   & buf_i(3)(8 downto 0)   & buf_q(3)(8 downto 2);
                    when x"5"   => out_prb_data <= buf_q(4)(1 downto 0)   & buf_i(3)(8 downto 0)   & buf_q(3)(8 downto 0)   & buf_i(2)(8 downto 0)   & buf_q(2)(8 downto 6);
                    when x"6"   => out_prb_data <= buf_q(3)(5 downto 0)   & buf_i(2)(8 downto 0)   & buf_q(2)(8 downto 0)   & x"00";
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (UNCOMP_8B = true) and (iq_width = 8) then                -- Uncomp/MC +  8bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_i(7)(7 downto 0)   & buf_q(7)(7 downto 0)   & buf_i(6)(7 downto 0)   & buf_q(6)(7 downto 0);
                    when x"1"   => out_prb_data <= buf_i(6)(7 downto 0)   & buf_q(6)(7 downto 0)   & buf_i(5)(7 downto 0)   & buf_q(5)(7 downto 0);
                    when x"2"   => out_prb_data <= buf_i(5)(7 downto 0)   & buf_q(5)(7 downto 0)   & buf_i(4)(7 downto 0)   & buf_q(4)(7 downto 0);
                    when x"3"   => out_prb_data <= buf_i(4)(7 downto 0)   & buf_q(4)(7 downto 0)   & buf_i(3)(7 downto 0)   & buf_q(3)(7 downto 0);
                    when x"4"   => out_prb_data <= buf_i(3)(7 downto 0)   & buf_q(3)(7 downto 0)   & buf_i(2)(7 downto 0)   & buf_q(2)(7 downto 0);
                    when x"5"   => out_prb_data <= buf_i(2)(7 downto 0)   & buf_q(2)(7 downto 0)   & buf_i(1)(7 downto 0)   & buf_q(1)(7 downto 0);
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (UNCOMP_7B = true) and (iq_width = 7) then                -- Uncomp/MC +  7bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_i(7)(6 downto 0)   & buf_q(7)(6 downto 0)   & buf_i(6)(6 downto 0)   & buf_q(6)(6 downto 0)   & buf_i(5)(6 downto 3);
                    when x"1"   => out_prb_data <= buf_i(6)(2 downto 0)   & buf_q(6)(6 downto 0)   & buf_i(5)(6 downto 0)   & buf_q(5)(6 downto 0)   & buf_i(4)(6 downto 0)   & buf_q(4)(6 downto 6);
                    when x"2"   => out_prb_data <= buf_q(5)(5 downto 0)   & buf_i(4)(6 downto 0)   & buf_q(4)(6 downto 0)   & buf_i(3)(6 downto 0)   & buf_q(3)(6 downto 2);
                    when x"3"   => out_prb_data <= buf_q(4)(1 downto 0)   & buf_i(3)(6 downto 0)   & buf_q(3)(6 downto 0)   & buf_i(2)(6 downto 0)   & buf_q(2)(6 downto 0)   & buf_i(1)(6 downto 5);
                    when x"4"   => out_prb_data <= buf_i(2)(4 downto 0)   & buf_q(2)(6 downto 0)   & buf_i(1)(6 downto 0)   & buf_q(1)(6 downto 0)   & buf_i(0)(6 downto 1);
                    when x"5"   => out_prb_data <= buf_i(1)(0 downto 0)   & buf_q(1)(6 downto 0)   & x"000000";
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (UNCOMP_6B = true) and (iq_width = 6) then                -- Uncomp/MC +  6bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_i(7)(5 downto 0)   & buf_q(7)(5 downto 0)   & buf_i(6)(5 downto 0)   & buf_q(6)(5 downto 0)   & buf_i(5)(5 downto 0)   & buf_q(5)(5 downto 4);
                    when x"1"   => out_prb_data <= buf_q(6)(3 downto 0)   & buf_i(5)(5 downto 0)   & buf_q(5)(5 downto 0)   & buf_i(4)(5 downto 0)   & buf_q(4)(5 downto 0)   & buf_i(3)(5 downto 2);
                    when x"2"   => out_prb_data <= buf_i(4)(1 downto 0)   & buf_q(4)(5 downto 0)   & buf_i(3)(5 downto 0)   & buf_q(3)(5 downto 0)   & buf_i(2)(5 downto 0)   & buf_q(2)(5 downto 0);
                    when x"3"   => out_prb_data <= buf_i(2)(5 downto 0)   & buf_q(2)(5 downto 0)   & buf_i(1)(5 downto 0)   & buf_q(1)(5 downto 0)   & buf_i(0)(5 downto 0)   & buf_q(0)(5 downto 4);
                    when x"4"   => out_prb_data <= buf_q(1)(3 downto 0)   & buf_i(0)(5 downto 0)   & buf_q(0)(5 downto 0)   & x"0000";
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (UNCOMP_5B = true) and (iq_width = 5) then                -- Uncomp/MC +  5bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_i(8)(4 downto 0)   & buf_q(8)(4 downto 0)   & buf_i(7)(4 downto 0)   & buf_q(7)(4 downto 0)   & buf_i(6)(4 downto 0)   & buf_q(6)(4 downto 0)   & buf_i(5)(4 downto 3);
                    when x"1"   => out_prb_data <= buf_i(6)(2 downto 0)   & buf_q(6)(4 downto 0)   & buf_i(5)(4 downto 0)   & buf_q(5)(4 downto 0)   & buf_i(4)(4 downto 0)   & buf_q(4)(4 downto 0)   & buf_i(3)(4 downto 1);
                    when x"2"   => out_prb_data <= buf_i(4)(0 downto 0)   & buf_q(4)(4 downto 0)   & buf_i(3)(4 downto 0)   & buf_q(3)(4 downto 0)   & buf_i(2)(4 downto 0)   & buf_q(2)(4 downto 0)   & buf_i(1)(4 downto 0)   & buf_q(1)(4 downto 4);
                    when x"3"   => out_prb_data <= buf_q(2)(3 downto 0)   & buf_i(1)(4 downto 0)   & buf_q(1)(4 downto 0)   & buf_i(0)(4 downto 0)   & buf_q(0)(4 downto 0)   & x"00";
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (UNCOMP_4B = true) and (iq_width = 4) then                -- Uncomp/MC +  4bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_i(9)(3 downto 0)   & buf_q(9)(3 downto 0)   & buf_i(8)(3 downto 0)   & buf_q(8)(3 downto 0)   & buf_i(7)(3 downto 0)   & buf_q(7)(3 downto 0)   & buf_i(6)(3 downto 0)   & buf_q(6)(3 downto 0);
                    when x"1"   => out_prb_data <= buf_i(6)(3 downto 0)   & buf_q(6)(3 downto 0)   & buf_i(5)(3 downto 0)   & buf_q(5)(3 downto 0)   & buf_i(4)(3 downto 0)   & buf_q(4)(3 downto 0)   & buf_i(3)(3 downto 0)   & buf_q(3)(3 downto 0);
                    when x"2"   => out_prb_data <= buf_i(3)(3 downto 0)   & buf_q(3)(3 downto 0)   & buf_i(2)(3 downto 0)   & buf_q(2)(3 downto 0)   & buf_i(1)(3 downto 0)   & buf_q(1)(3 downto 0)   & buf_i(0)(3 downto 0)   & buf_q(0)(3 downto 0);
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (UNCOMP_3B = true) and (iq_width = 3) then                -- Uncomp/MC +  3bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_i(9)(2 downto 0)   & buf_q(9)(2 downto 0)   & buf_i(8)(2 downto 0)   & buf_q(8)(2 downto 0)   & buf_i(7)(2 downto 0)   & buf_q(7)(2 downto 0)   & buf_i(6)(2 downto 0)   & buf_q(6)(2 downto 0)   & buf_i(5)(2 downto 0)   & buf_q(5)(2 downto 0)   & buf_i(4)(2 downto 1);
                    when x"1"   => out_prb_data <= buf_i(5)(0 downto 0)   & buf_q(5)(2 downto 0)   & buf_i(4)(2 downto 0)   & buf_q(4)(2 downto 0)   & buf_i(3)(2 downto 0)   & buf_q(3)(2 downto 0)   & buf_i(2)(2 downto 0)   & buf_q(2)(2 downto 0)   & buf_i(1)(2 downto 0)   & buf_q(1)(2 downto 0)   & buf_i(0)(2 downto 0)   & buf_q(0)(2 downto 2);
                    when x"2"   => out_prb_data <= buf_q(1)(1 downto 0)   & buf_i(0)(2 downto 0)   & buf_q(0)(2 downto 0)   & x"000000";
                    when others => out_prb_data <= (others => '0');
                    end case;
                else                                                            -- Uncomp/MC + others
                    out_prb_data <= (others => '0');
                end if;
            else
                if    (COMP_15B = true) and (iq_width = 15) then                -- Comp + 15bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_param              & buf_i(7)(14 downto 0)  & buf_q(7)(14 downto 6);
                    when x"1"   => out_prb_data <= buf_q(8)(5 downto 0)   & buf_i(7)(14 downto 0)  & buf_q(7)(14 downto 4);
                    when x"2"   => out_prb_data <= buf_q(8)(3 downto 0)   & buf_i(7)(14 downto 0)  & buf_q(7)(14 downto 2);
                    when x"3"   => out_prb_data <= buf_q(8)(1 downto 0)   & buf_i(7)(14 downto 0)  & buf_q(7)(14 downto 0);
                    when x"4"   => out_prb_data <= buf_i(7)(14 downto 0)  & buf_q(7)(14 downto 0)  & buf_i(6)(14 downto 13);
                    when x"5"   => out_prb_data <= buf_i(7)(12 downto 0)  & buf_q(7)(14 downto 0)  & buf_i(6)(14 downto 11);
                    when x"6"   => out_prb_data <= buf_i(7)(10 downto 0)  & buf_q(7)(14 downto 0)  & buf_i(6)(14 downto 9);
                    when x"7"   => out_prb_data <= buf_i(7)(8 downto 0)   & buf_q(7)(14 downto 0)  & buf_i(6)(14 downto 7);
                    when x"8"   => out_prb_data <= buf_i(7)(6 downto 0)   & buf_q(7)(14 downto 0)  & buf_i(6)(14 downto 5);
                    when x"9"   => out_prb_data <= buf_i(7)(4 downto 0)   & buf_q(7)(14 downto 0)  & buf_i(6)(14 downto 3);
                    when x"A"   => out_prb_data <= buf_i(7)(2 downto 0)   & buf_q(7)(14 downto 0)  & buf_i(6)(14 downto 1);
                    when x"B"   => out_prb_data <= buf_i(7)(0 downto 0)   & buf_q(7)(14 downto 0)  & x"0000";
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (COMP_14B = true) and (iq_width = 14) then                -- Comp + 14bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_param              & buf_i(7)(13 downto 0)  & buf_q(7)(13 downto 4);
                    when x"1"   => out_prb_data <= buf_q(8)(3 downto 0)   & buf_i(7)(13 downto 0)  & buf_q(7)(13 downto 0);
                    when x"2"   => out_prb_data <= buf_i(7)(13 downto 0)  & buf_q(7)(13 downto 0)  & buf_i(6)(13 downto 10);
                    when x"3"   => out_prb_data <= buf_i(7)(9 downto 0)   & buf_q(7)(13 downto 0)  & buf_i(6)(13 downto 6);
                    when x"4"   => out_prb_data <= buf_i(7)(5 downto 0)   & buf_q(7)(13 downto 0)  & buf_i(6)(13 downto 2);
                    when x"5"   => out_prb_data <= buf_i(7)(1 downto 0)   & buf_q(7)(13 downto 0)  & buf_i(6)(13 downto 0)  & buf_q(6)(13 downto 12);
                    when x"6"   => out_prb_data <= buf_q(7)(11 downto 0)  & buf_i(6)(13 downto 0)  & buf_q(6)(13 downto 8);
                    when x"7"   => out_prb_data <= buf_q(7)(7 downto 0)   & buf_i(6)(13 downto 0)  & buf_q(6)(13 downto 4);
                    when x"8"   => out_prb_data <= buf_q(7)(3 downto 0)   & buf_i(6)(13 downto 0)  & buf_q(6)(13 downto 0);
                    when x"9"   => out_prb_data <= buf_i(6)(13 downto 0)  & buf_q(6)(13 downto 0)  & buf_i(5)(13 downto 10);
                    when x"A"   => out_prb_data <= buf_i(6)(9 downto 0)   & buf_q(6)(13 downto 0)  & x"00";
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (COMP_13B = true) and (iq_width = 13) then                -- Comp + 13bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_param              & buf_i(7)(12 downto 0)  & buf_q(7)(12 downto 2);
                    when x"1"   => out_prb_data <= buf_q(8)(1 downto 0)   & buf_i(7)(12 downto 0)  & buf_q(7)(12 downto 0)  & buf_i(6)(12 downto 9);
                    when x"2"   => out_prb_data <= buf_i(7)(8 downto 0)   & buf_q(7)(12 downto 0)  & buf_i(6)(12 downto 3);
                    when x"3"   => out_prb_data <= buf_i(7)(2 downto 0)   & buf_q(7)(12 downto 0)  & buf_i(6)(12 downto 0)  & buf_q(6)(12 downto 10);
                    when x"4"   => out_prb_data <= buf_q(7)(9 downto 0)   & buf_i(6)(12 downto 0)  & buf_q(6)(12 downto 4);
                    when x"5"   => out_prb_data <= buf_q(7)(3 downto 0)   & buf_i(6)(12 downto 0)  & buf_q(6)(12 downto 0)  & buf_i(5)(12 downto 11);
                    when x"6"   => out_prb_data <= buf_i(6)(10 downto 0)  & buf_q(6)(12 downto 0)  & buf_i(5)(12 downto 5);
                    when x"7"   => out_prb_data <= buf_i(6)(4 downto 0)   & buf_q(6)(12 downto 0)  & buf_i(5)(12 downto 0)  & buf_q(5)(12 downto 12);
                    when x"8"   => out_prb_data <= buf_q(6)(11 downto 0)  & buf_i(5)(12 downto 0)  & buf_q(5)(12 downto 6);
                    when x"9"   => out_prb_data <= buf_q(6)(5 downto 0)   & buf_i(5)(12 downto 0)  & buf_q(5)(12 downto 0);
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (COMP_12B = true) and (iq_width = 12) then                -- Comp + 12bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_param              & buf_i(7)(11 downto 0)  & buf_q(7)(11 downto 0);
                    when x"1"   => out_prb_data <= buf_i(7)(11 downto 0)  & buf_q(7)(11 downto 0)  & buf_i(6)(11 downto 4);
                    when x"2"   => out_prb_data <= buf_i(7)(3 downto 0)   & buf_q(7)(11 downto 0)  & buf_i(6)(11 downto 0)  & buf_q(6)(11 downto 8);
                    when x"3"   => out_prb_data <= buf_q(7)(7 downto 0)   & buf_i(6)(11 downto 0)  & buf_q(6)(11 downto 0);
                    when x"4"   => out_prb_data <= buf_i(6)(11 downto 0)  & buf_q(6)(11 downto 0)  & buf_i(5)(11 downto 4);
                    when x"5"   => out_prb_data <= buf_i(6)(3 downto 0)   & buf_q(6)(11 downto 0)  & buf_i(5)(11 downto 0)  & buf_q(5)(11 downto 8);
                    when x"6"   => out_prb_data <= buf_q(6)(7 downto 0)   & buf_i(5)(11 downto 0)  & buf_q(5)(11 downto 0);
                    when x"7"   => out_prb_data <= buf_i(5)(11 downto 0)  & buf_q(5)(11 downto 0)  & buf_i(4)(11 downto 4);
                    when x"8"   => out_prb_data <= buf_i(5)(3 downto 0)   & buf_q(5)(11 downto 0)  & buf_i(4)(11 downto 0)  & buf_q(4)(11 downto 8);
                    when x"9"   => out_prb_data <= buf_q(5)(7 downto 0)   & x"000000";
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (COMP_11B = true) and (iq_width = 11) then                -- Comp + 11bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_param              & buf_i(7)(10 downto 0)  & buf_q(7)(10 downto 0)  & buf_i(6)(10 downto 9);
                    when x"1"   => out_prb_data <= buf_i(7)(8 downto 0)   & buf_q(7)(10 downto 0)  & buf_i(6)(10 downto 0)  & buf_q(6)(10 downto 10);
                    when x"2"   => out_prb_data <= buf_q(7)(9 downto 0)   & buf_i(6)(10 downto 0)  & buf_q(6)(10 downto 0);
                    when x"3"   => out_prb_data <= buf_i(6)(10 downto 0)  & buf_q(6)(10 downto 0)  & buf_i(5)(10 downto 1);
                    when x"4"   => out_prb_data <= buf_i(6)(0 downto 0)   & buf_q(6)(10 downto 0)  & buf_i(5)(10 downto 0)  & buf_q(5)(10 downto 2);
                    when x"5"   => out_prb_data <= buf_q(6)(1 downto 0)   & buf_i(5)(10 downto 0)  & buf_q(5)(10 downto 0)  & buf_i(4)(10 downto 3);
                    when x"6"   => out_prb_data <= buf_i(5)(2 downto 0)   & buf_q(5)(10 downto 0)  & buf_i(4)(10 downto 0)  & buf_q(4)(10 downto 4);
                    when x"7"   => out_prb_data <= buf_q(5)(3 downto 0)   & buf_i(4)(10 downto 0)  & buf_q(4)(10 downto 0)  & buf_i(3)(10 downto 5);
                    when x"8"   => out_prb_data <= buf_i(4)(4 downto 0)   & buf_q(4)(10 downto 0)  & x"0000";
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (COMP_10B = true) and (iq_width = 10) then                -- Comp + 10bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_param              & buf_i(7)(9 downto 0)   & buf_q(7)(9 downto 0)   & buf_i(6)(9 downto 6);
                    when x"1"   => out_prb_data <= buf_i(7)(5 downto 0)   & buf_q(7)(9 downto 0)   & buf_i(6)(9 downto 0)   & buf_q(6)(9 downto 4);
                    when x"2"   => out_prb_data <= buf_q(7)(3 downto 0)   & buf_i(6)(9 downto 0)   & buf_q(6)(9 downto 0)   & buf_i(5)(9 downto 2);
                    when x"3"   => out_prb_data <= buf_i(6)(1 downto 0)   & buf_q(6)(9 downto 0)   & buf_i(5)(9 downto 0)   & buf_q(5)(9 downto 0);
                    when x"4"   => out_prb_data <= buf_i(5)(9 downto 0)   & buf_q(5)(9 downto 0)   & buf_i(4)(9 downto 0)   & buf_q(4)(9 downto 8);
                    when x"5"   => out_prb_data <= buf_q(5)(7 downto 0)   & buf_i(4)(9 downto 0)   & buf_q(4)(9 downto 0)   & buf_i(3)(9 downto 6);
                    when x"6"   => out_prb_data <= buf_i(4)(5 downto 0)   & buf_q(4)(9 downto 0)   & buf_i(3)(9 downto 0)   & buf_q(3)(9 downto 4);
                    when x"7"   => out_prb_data <= buf_q(4)(3 downto 0)   & buf_i(3)(9 downto 0)   & buf_q(3)(9 downto 0)   & x"00";
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (COMP_9B = true) and (iq_width = 9) then                  -- Comp +  9bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_param              & buf_i(7)(8 downto 0)   & buf_q(7)(8 downto 0)   & buf_i(6)(8 downto 3);
                    when x"1"   => out_prb_data <= buf_i(7)(2 downto 0)   & buf_q(7)(8 downto 0)   & buf_i(6)(8 downto 0)   & buf_q(6)(8 downto 0)   & buf_i(5)(8 downto 7);
                    when x"2"   => out_prb_data <= buf_i(6)(6 downto 0)   & buf_q(6)(8 downto 0)   & buf_i(5)(8 downto 0)   & buf_q(5)(8 downto 2);
                    when x"3"   => out_prb_data <= buf_q(6)(1 downto 0)   & buf_i(5)(8 downto 0)   & buf_q(5)(8 downto 0)   & buf_i(4)(8 downto 0)   & buf_q(4)(8 downto 6);
                    when x"4"   => out_prb_data <= buf_q(5)(5 downto 0)   & buf_i(4)(8 downto 0)   & buf_q(4)(8 downto 0)   & buf_i(3)(8 downto 1);
                    when x"5"   => out_prb_data <= buf_i(4)(0 downto 0)   & buf_q(4)(8 downto 0)   & buf_i(3)(8 downto 0)   & buf_q(3)(8 downto 0)   & buf_i(2)(8 downto 5);
                    when x"6"   => out_prb_data <= buf_i(3)(4 downto 0)   & buf_q(3)(8 downto 0)   & buf_i(2)(8 downto 0)   & buf_q(2)(8 downto 0);
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (COMP_8B = true) and (iq_width = 8) then                  -- Comp +  8bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_param              & buf_i(7)(7 downto 0)   & buf_q(7)(7 downto 0)   & buf_i(6)(7 downto 0);
                    when x"1"   => out_prb_data <= buf_q(7)(7 downto 0)   & buf_i(6)(7 downto 0)   & buf_q(6)(7 downto 0)   & buf_i(5)(7 downto 0);
                    when x"2"   => out_prb_data <= buf_q(6)(7 downto 0)   & buf_i(5)(7 downto 0)   & buf_q(5)(7 downto 0)   & buf_i(4)(7 downto 0);
                    when x"3"   => out_prb_data <= buf_q(5)(7 downto 0)   & buf_i(4)(7 downto 0)   & buf_q(4)(7 downto 0)   & buf_i(3)(7 downto 0);
                    when x"4"   => out_prb_data <= buf_q(4)(7 downto 0)   & buf_i(3)(7 downto 0)   & buf_q(3)(7 downto 0)   & buf_i(2)(7 downto 0);
                    when x"5"   => out_prb_data <= buf_q(3)(7 downto 0)   & buf_i(2)(7 downto 0)   & buf_q(2)(7 downto 0)   & buf_i(1)(7 downto 0);
                    when x"6"   => out_prb_data <= buf_q(2)(7 downto 0)   & x"000000";
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (COMP_7B = true) and (iq_width = 7) then                  -- Comp +  7bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_param              & buf_i(7)(6 downto 0)   & buf_q(7)(6 downto 0)   & buf_i(6)(6 downto 0)   & buf_q(6)(6 downto 4);
                    when x"1"   => out_prb_data <= buf_q(7)(3 downto 0)   & buf_i(6)(6 downto 0)   & buf_q(6)(6 downto 0)   & buf_i(5)(6 downto 0)   & buf_q(5)(6 downto 0);
                    when x"2"   => out_prb_data <= buf_i(5)(6 downto 0)   & buf_q(5)(6 downto 0)   & buf_i(4)(6 downto 0)   & buf_q(4)(6 downto 0)   & buf_i(3)(6 downto 3);
                    when x"3"   => out_prb_data <= buf_i(4)(2 downto 0)   & buf_q(4)(6 downto 0)   & buf_i(3)(6 downto 0)   & buf_q(3)(6 downto 0)   & buf_i(2)(6 downto 0)   & buf_q(2)(6 downto 6);
                    when x"4"   => out_prb_data <= buf_q(3)(5 downto 0)   & buf_i(2)(6 downto 0)   & buf_q(2)(6 downto 0)   & buf_i(1)(6 downto 0)   & buf_q(1)(6 downto 2);
                    when x"5"   => out_prb_data <= buf_q(2)(1 downto 0)   & buf_i(1)(6 downto 0)   & buf_q(1)(6 downto 0)   & x"0000";
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (COMP_6B = true) and (iq_width = 6) then                  -- Comp +  6bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_param              & buf_i(7)(5 downto 0)   & buf_q(7)(5 downto 0)   & buf_i(6)(5 downto 0)   & buf_q(6)(5 downto 0);
                    when x"1"   => out_prb_data <= buf_i(6)(5 downto 0)   & buf_q(6)(5 downto 0)   & buf_i(5)(5 downto 0)   & buf_q(5)(5 downto 0)   & buf_i(4)(5 downto 0)   & buf_q(4)(5 downto 4);
                    when x"2"   => out_prb_data <= buf_q(5)(3 downto 0)   & buf_i(4)(5 downto 0)   & buf_q(4)(5 downto 0)   & buf_i(3)(5 downto 0)   & buf_q(3)(5 downto 0)   & buf_i(2)(5 downto 2);
                    when x"3"   => out_prb_data <= buf_i(3)(1 downto 0)   & buf_q(3)(5 downto 0)   & buf_i(2)(5 downto 0)   & buf_q(2)(5 downto 0)   & buf_i(1)(5 downto 0)   & buf_q(1)(5 downto 0);
                    when x"4"   => out_prb_data <= buf_i(1)(5 downto 0)   & buf_q(1)(5 downto 0)   & buf_i(0)(5 downto 0)   & buf_q(0)(5 downto 0)   & x"00";
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (COMP_5B = true) and (iq_width = 5) then                  -- Comp +  5bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_param              & buf_i(8)(4 downto 0)   & buf_q(8)(4 downto 0)   & buf_i(7)(4 downto 0)   & buf_q(7)(4 downto 0)   & buf_i(6)(4 downto 1);
                    when x"1"   => out_prb_data <= buf_i(7)(0 downto 0)   & buf_q(7)(4 downto 0)   & buf_i(6)(4 downto 0)   & buf_q(6)(4 downto 0)   & buf_i(5)(4 downto 0)   & buf_q(5)(4 downto 0)   & buf_i(4)(4 downto 0)   & buf_q(4)(4 downto 4);
                    when x"2"   => out_prb_data <= buf_q(5)(3 downto 0)   & buf_i(4)(4 downto 0)   & buf_q(4)(4 downto 0)   & buf_i(3)(4 downto 0)   & buf_q(3)(4 downto 0)   & buf_i(2)(4 downto 0)   & buf_q(2)(4 downto 2);
                    when x"3"   => out_prb_data <= buf_q(3)(1 downto 0)   & buf_i(2)(4 downto 0)   & buf_q(2)(4 downto 0)   & buf_i(1)(4 downto 0)   & buf_q(1)(4 downto 0)   & buf_i(0)(4 downto 0)   & buf_q(0)(4 downto 0);
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (COMP_4B = true) and (iq_width = 4) then                  -- Comp +  4bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_param              & buf_i(8)(3 downto 0)   & buf_q(8)(3 downto 0)   & buf_i(7)(3 downto 0)   & buf_q(7)(3 downto 0)   & buf_i(6)(3 downto 0)   & buf_q(6)(3 downto 0);
                    when x"1"   => out_prb_data <= buf_i(6)(3 downto 0)   & buf_q(6)(3 downto 0)   & buf_i(5)(3 downto 0)   & buf_q(5)(3 downto 0)   & buf_i(4)(3 downto 0)   & buf_q(4)(3 downto 0)   & buf_i(3)(3 downto 0)   & buf_q(3)(3 downto 0);
                    when x"2"   => out_prb_data <= buf_i(3)(3 downto 0)   & buf_q(3)(3 downto 0)   & buf_i(2)(3 downto 0)   & buf_q(2)(3 downto 0)   & buf_i(1)(3 downto 0)   & buf_q(1)(3 downto 0)   & buf_i(0)(3 downto 0)   & buf_q(0)(3 downto 0);
                    when x"3"   => out_prb_data <= buf_i(0)(3 downto 0)   & buf_q(0)(3 downto 0)   & x"000000";
                    when others => out_prb_data <= (others => '0');
                    end case;
                elsif (COMP_3B = true) and (iq_width = 3) then                  -- Comp +  3bits
                    case cnt is
                    when x"0"   => out_prb_data <= buf_param              & buf_i(9)(2 downto 0)   & buf_q(9)(2 downto 0)   & buf_i(8)(2 downto 0)   & buf_q(8)(2 downto 0)   & buf_i(7)(2 downto 0)   & buf_q(7)(2 downto 0)   & buf_i(6)(2 downto 0)   & buf_q(6)(2 downto 0);
                    when x"1"   => out_prb_data <= buf_i(6)(2 downto 0)   & buf_q(6)(2 downto 0)   & buf_i(5)(2 downto 0)   & buf_q(5)(2 downto 0)   & buf_i(4)(2 downto 0)   & buf_q(4)(2 downto 0)   & buf_i(3)(2 downto 0)   & buf_q(3)(2 downto 0)   & buf_i(2)(2 downto 0)   & buf_q(2)(2 downto 0)   & buf_i(1)(2 downto 1);
                    when x"2"   => out_prb_data <= buf_i(2)(0 downto 0)   & buf_q(2)(2 downto 0)   & buf_i(1)(2 downto 0)   & buf_q(1)(2 downto 0)   & buf_i(0)(2 downto 0)   & buf_q(0)(2 downto 0)   & x"0000";
                    when others => out_prb_data <= (others => '0');
                    end case;
                else                                                            -- Comp + others
                    out_prb_data <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (out_prb_tick = '1') then
                PRB_COMP_HDR <= comp_mode & iq_width & comp_method;
                PRB_USER     <= buf_user;
            elsif (out_prb_dis = '1') then
                PRB_COMP_HDR <= (others => '0');
                PRB_USER     <= (others => '0');
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            PRB_VALID <= out_prb_valid;
            PRB_TICK  <= out_prb_tick;
            PRB_KEEP  <= out_prb_keep;
            PRB_DATA  <= out_prb_data;
        end if;
    end process;

end BEHAVE;