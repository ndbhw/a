--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : PRB aligner, 32-to-n bits (O-RAN component)                   --
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

entity PRB_32_TO_N is
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
-- PRB data bus
--------------------------------------------------------------------------------

        PRB_COMP_HDR                : in  std_logic_vector(7 downto 0);

        PRB_VALID                   : in  std_logic;
        PRB_TICK                    : in  std_logic;
        PRB_KEEP                    : in  std_logic_vector(3 downto 0);
        PRB_DATA                    : in  std_logic_vector(31 downto 0);
        PRB_USER                    : in  std_logic_vector(15 downto 0);

--------------------------------------------------------------------------------
-- Compression block
--------------------------------------------------------------------------------

        COMP_HDR                    : out std_logic_vector(7 downto 0);
        COMP_PARAM                  : out std_logic_vector(7 downto 0);

        COMP_VALID                  : out std_logic;
        COMP_TICK                   : out std_logic;
        COMP_DATA_I                 : out std_logic_vector(15 downto 0);
        COMP_DATA_Q                 : out std_logic_vector(15 downto 0);
        COMP_USER                   : out std_logic_vector(15 downto 0)
    );
end PRB_32_TO_N;

architecture BEHAVE of PRB_32_TO_N is

    type std_logic_array32          is array(natural range <>) of std_logic_vector(31 downto 0);

    signal iq_width                 : std_logic_vector(3 downto 0) := (others => '0');
    signal comp_method              : std_logic_vector(3 downto 0) := (others => '0');

    signal buf_prb_tick             : std_logic_vector(1 downto 0) := (others => '0');
    signal buf_prb_data             : std_logic_array32(10 downto 0) := (others => (others => '0'));
    signal buf_prb_user             : std_logic_vector(15 downto 0) := (others => '0');

    signal cnt                      : std_logic_vector(3 downto 0) := (others => '1');

    signal out_prb_tick             : std_logic;
    signal out_prb_valid            : std_logic;
    signal out_prb_param            : std_logic_vector(7 downto 0);
    signal out_prb_data_i           : std_logic_vector(15 downto 0);
    signal out_prb_data_q           : std_logic_vector(15 downto 0);

begin

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            buf_prb_tick <= buf_prb_tick(0) & PRB_TICK;
            buf_prb_data <= buf_prb_data(9 downto 0) & PRB_DATA;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (PRB_TICK = '1') then
                iq_width     <= PRB_COMP_HDR(7 downto 4);
                comp_method  <= PRB_COMP_HDR(3 downto 0);
                buf_prb_user <= PRB_USER;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (buf_prb_tick(0) = '1') then
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
            case cnt is
            when x"0"   => out_prb_tick <= '1'; out_prb_valid <= '1';
            when x"1"   => out_prb_tick <= '0'; out_prb_valid <= '1';
            when x"2"   => out_prb_tick <= '0'; out_prb_valid <= '1';
            when x"3"   => out_prb_tick <= '0'; out_prb_valid <= '1';
            when x"4"   => out_prb_tick <= '0'; out_prb_valid <= '1';
            when x"5"   => out_prb_tick <= '0'; out_prb_valid <= '1';
            when x"6"   => out_prb_tick <= '0'; out_prb_valid <= '1';
            when x"7"   => out_prb_tick <= '0'; out_prb_valid <= '1';
            when x"8"   => out_prb_tick <= '0'; out_prb_valid <= '1';
            when x"9"   => out_prb_tick <= '0'; out_prb_valid <= '1';
            when x"A"   => out_prb_tick <= '0'; out_prb_valid <= '1';
            when x"B"   => out_prb_tick <= '0'; out_prb_valid <= '1';
            when others => out_prb_tick <= '0'; out_prb_valid <= '0';
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (comp_method(1 downto 0) = "00") then
                out_prb_param <= (others => '0');
            else
                if (buf_prb_tick(1) = '1') then
                    out_prb_param <= buf_prb_data(1)(31 downto 24);
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
                    when x"0"   => out_prb_data_i <= buf_prb_data(1)(31 downto 16);
                                   out_prb_data_q <= buf_prb_data(1)(15 downto 0);
                    when x"1"   => out_prb_data_i <= buf_prb_data(1)(31 downto 16);
                                   out_prb_data_q <= buf_prb_data(1)(15 downto 0);
                    when x"2"   => out_prb_data_i <= buf_prb_data(1)(31 downto 16);
                                   out_prb_data_q <= buf_prb_data(1)(15 downto 0);
                    when x"3"   => out_prb_data_i <= buf_prb_data(1)(31 downto 16);
                                   out_prb_data_q <= buf_prb_data(1)(15 downto 0);
                    when x"4"   => out_prb_data_i <= buf_prb_data(1)(31 downto 16);
                                   out_prb_data_q <= buf_prb_data(1)(15 downto 0);
                    when x"5"   => out_prb_data_i <= buf_prb_data(1)(31 downto 16);
                                   out_prb_data_q <= buf_prb_data(1)(15 downto 0);
                    when x"6"   => out_prb_data_i <= buf_prb_data(1)(31 downto 16);
                                   out_prb_data_q <= buf_prb_data(1)(15 downto 0);
                    when x"7"   => out_prb_data_i <= buf_prb_data(1)(31 downto 16);
                                   out_prb_data_q <= buf_prb_data(1)(15 downto 0);
                    when x"8"   => out_prb_data_i <= buf_prb_data(1)(31 downto 16);
                                   out_prb_data_q <= buf_prb_data(1)(15 downto 0);
                    when x"9"   => out_prb_data_i <= buf_prb_data(1)(31 downto 16);
                                   out_prb_data_q <= buf_prb_data(1)(15 downto 0);
                    when x"A"   => out_prb_data_i <= buf_prb_data(1)(31 downto 16);
                                   out_prb_data_q <= buf_prb_data(1)(15 downto 0);
                    when x"B"   => out_prb_data_i <= buf_prb_data(1)(31 downto 16);
                                   out_prb_data_q <= buf_prb_data(1)(15 downto 0);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (UNCOMP_15B = true) and (iq_width = 15) then              -- Uncomp/MC + 15bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= '0' & buf_prb_data(1)(31 downto 17);
                                   out_prb_data_q <= '0' & buf_prb_data(1)(16 downto 2);
                    when x"1"   => out_prb_data_i <= '0' & buf_prb_data(2)(1 downto 0)   & buf_prb_data(1)(31 downto 19);
                                   out_prb_data_q <= '0' & buf_prb_data(1)(18 downto 4);
                    when x"2"   => out_prb_data_i <= '0' & buf_prb_data(2)(3 downto 0)   & buf_prb_data(1)(31 downto 21);
                                   out_prb_data_q <= '0' & buf_prb_data(1)(20 downto 6);
                    when x"3"   => out_prb_data_i <= '0' & buf_prb_data(2)(5 downto 0)   & buf_prb_data(1)(31 downto 23);
                                   out_prb_data_q <= '0' & buf_prb_data(1)(22 downto 8);
                    when x"4"   => out_prb_data_i <= '0' & buf_prb_data(2)(7 downto 0)   & buf_prb_data(1)(31 downto 25);
                                   out_prb_data_q <= '0' & buf_prb_data(1)(24 downto 10);
                    when x"5"   => out_prb_data_i <= '0' & buf_prb_data(2)(9 downto 0)   & buf_prb_data(1)(31 downto 27);
                                   out_prb_data_q <= '0' & buf_prb_data(1)(26 downto 12);
                    when x"6"   => out_prb_data_i <= '0' & buf_prb_data(2)(11 downto 0)  & buf_prb_data(1)(31 downto 29);
                                   out_prb_data_q <= '0' & buf_prb_data(1)(28 downto 14);
                    when x"7"   => out_prb_data_i <= '0' & buf_prb_data(2)(13 downto 0)  & buf_prb_data(1)(31 downto 31);
                                   out_prb_data_q <= '0' & buf_prb_data(1)(30 downto 16);
                    when x"8"   => out_prb_data_i <= '0' & buf_prb_data(2)(15 downto 1);
                                   out_prb_data_q <= '0' & buf_prb_data(2)(0 downto 0)   & buf_prb_data(1)(31 downto 18);
                    when x"9"   => out_prb_data_i <= '0' & buf_prb_data(2)(17 downto 3);
                                   out_prb_data_q <= '0' & buf_prb_data(2)(2 downto 0)   & buf_prb_data(1)(31 downto 20);
                    when x"A"   => out_prb_data_i <= '0' & buf_prb_data(2)(19 downto 5);
                                   out_prb_data_q <= '0' & buf_prb_data(2)(4 downto 0)   & buf_prb_data(1)(31 downto 22);
                    when x"B"   => out_prb_data_i <= '0' & buf_prb_data(2)(21 downto 7);
                                   out_prb_data_q <= '0' & buf_prb_data(2)(6 downto 0)   & buf_prb_data(1)(31 downto 24);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                 elsif (UNCOMP_14B = true) and (iq_width = 14) then              -- Uncomp/MC + 14bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "00" & buf_prb_data(1)(31 downto 18);
                                   out_prb_data_q <= "00" & buf_prb_data(1)(17 downto 4);
                    when x"1"   => out_prb_data_i <= "00" & buf_prb_data(2)(3 downto 0)   & buf_prb_data(1)(31 downto 22);
                                   out_prb_data_q <= "00" & buf_prb_data(1)(21 downto 8);
                    when x"2"   => out_prb_data_i <= "00" & buf_prb_data(2)(7 downto 0)   & buf_prb_data(1)(31 downto 26);
                                   out_prb_data_q <= "00" & buf_prb_data(1)(25 downto 12);
                    when x"3"   => out_prb_data_i <= "00" & buf_prb_data(2)(11 downto 0)  & buf_prb_data(1)(31 downto 30);
                                   out_prb_data_q <= "00" & buf_prb_data(1)(29 downto 16);
                    when x"4"   => out_prb_data_i <= "00" & buf_prb_data(2)(15 downto 2);
                                   out_prb_data_q <= "00" & buf_prb_data(2)(1 downto 0)   & buf_prb_data(1)(31 downto 20);
                    when x"5"   => out_prb_data_i <= "00" & buf_prb_data(2)(19 downto 6);
                                   out_prb_data_q <= "00" & buf_prb_data(2)(5 downto 0)   & buf_prb_data(1)(31 downto 24);
                    when x"6"   => out_prb_data_i <= "00" & buf_prb_data(2)(23 downto 10);
                                   out_prb_data_q <= "00" & buf_prb_data(2)(9 downto 0)   & buf_prb_data(1)(31 downto 28);
                    when x"7"   => out_prb_data_i <= "00" & buf_prb_data(2)(27 downto 14);
                                   out_prb_data_q <= "00" & buf_prb_data(2)(13 downto 0);
                    when x"8"   => out_prb_data_i <= "00" & buf_prb_data(2)(31 downto 18);
                                   out_prb_data_q <= "00" & buf_prb_data(2)(17 downto 4);
                    when x"9"   => out_prb_data_i <= "00" & buf_prb_data(3)(3 downto 0)   & buf_prb_data(2)(31 downto 22);
                                   out_prb_data_q <= "00" & buf_prb_data(2)(21 downto 8);
                    when x"A"   => out_prb_data_i <= "00" & buf_prb_data(3)(7 downto 0)   & buf_prb_data(2)(31 downto 26);
                                   out_prb_data_q <= "00" & buf_prb_data(2)(25 downto 12);
                    when x"B"   => out_prb_data_i <= "00" & buf_prb_data(3)(11 downto 0)  & buf_prb_data(2)(31 downto 30);
                                   out_prb_data_q <= "00" & buf_prb_data(2)(29 downto 16);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                 elsif (UNCOMP_13B = true) and (iq_width = 13) then              -- Uncomp/MC + 13bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "000" & buf_prb_data(1)(31 downto 19);
                                   out_prb_data_q <= "000" & buf_prb_data(1)(18 downto 6);
                    when x"1"   => out_prb_data_i <= "000" & buf_prb_data(2)(5 downto 0)   & buf_prb_data(1)(31 downto 25);
                                   out_prb_data_q <= "000" & buf_prb_data(1)(24 downto 12);
                    when x"2"   => out_prb_data_i <= "000" & buf_prb_data(2)(11 downto 0)  & buf_prb_data(1)(31 downto 31);
                                   out_prb_data_q <= "000" & buf_prb_data(1)(30 downto 18);
                    when x"3"   => out_prb_data_i <= "000" & buf_prb_data(2)(17 downto 5);
                                   out_prb_data_q <= "000" & buf_prb_data(2)(4 downto 0)   & buf_prb_data(1)(31 downto 24);
                    when x"4"   => out_prb_data_i <= "000" & buf_prb_data(2)(23 downto 11);
                                   out_prb_data_q <= "000" & buf_prb_data(2)(10 downto 0)  & buf_prb_data(1)(31 downto 30);
                    when x"5"   => out_prb_data_i <= "000" & buf_prb_data(2)(29 downto 17);
                                   out_prb_data_q <= "000" & buf_prb_data(2)(16 downto 4);
                    when x"6"   => out_prb_data_i <= "000" & buf_prb_data(3)(3 downto 0)   & buf_prb_data(2)(31 downto 23);
                                   out_prb_data_q <= "000" & buf_prb_data(2)(22 downto 10);
                    when x"7"   => out_prb_data_i <= "000" & buf_prb_data(3)(9 downto 0)   & buf_prb_data(2)(31 downto 29);
                                   out_prb_data_q <= "000" & buf_prb_data(2)(28 downto 16);
                    when x"8"   => out_prb_data_i <= "000" & buf_prb_data(3)(15 downto 3);
                                   out_prb_data_q <= "000" & buf_prb_data(3)(2 downto 0)   & buf_prb_data(2)(31 downto 22);
                    when x"9"   => out_prb_data_i <= "000" & buf_prb_data(3)(21 downto 9);
                                   out_prb_data_q <= "000" & buf_prb_data(3)(8 downto 0)   & buf_prb_data(2)(31 downto 28);
                    when x"A"   => out_prb_data_i <= "000" & buf_prb_data(3)(27 downto 15);
                                   out_prb_data_q <= "000" & buf_prb_data(3)(14 downto 2);
                    when x"B"   => out_prb_data_i <= "000" & buf_prb_data(4)(1 downto 0)   & buf_prb_data(3)(31 downto 21);
                                   out_prb_data_q <= "000" & buf_prb_data(3)(20 downto 8);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (UNCOMP_12B = true) and (iq_width = 12) then              -- Uncomp/MC + 12bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "0000" & buf_prb_data(1)(31 downto 20);
                                   out_prb_data_q <= "0000" & buf_prb_data(1)(19 downto 8);
                    when x"1"   => out_prb_data_i <= "0000" & buf_prb_data(2)(7 downto 0)   & buf_prb_data(1)(31 downto 28);
                                   out_prb_data_q <= "0000" & buf_prb_data(1)(27 downto 16);
                    when x"2"   => out_prb_data_i <= "0000" & buf_prb_data(2)(15 downto 4);
                                   out_prb_data_q <= "0000" & buf_prb_data(2)(3 downto 0)   & buf_prb_data(1)(31 downto 24);
                    when x"3"   => out_prb_data_i <= "0000" & buf_prb_data(2)(23 downto 12);
                                   out_prb_data_q <= "0000" & buf_prb_data(2)(11 downto 0);
                    when x"4"   => out_prb_data_i <= "0000" & buf_prb_data(2)(31 downto 20);
                                   out_prb_data_q <= "0000" & buf_prb_data(2)(19 downto 8);
                    when x"5"   => out_prb_data_i <= "0000" & buf_prb_data(3)(7 downto 0)   & buf_prb_data(2)(31 downto 28);
                                   out_prb_data_q <= "0000" & buf_prb_data(2)(27 downto 16);
                    when x"6"   => out_prb_data_i <= "0000" & buf_prb_data(3)(15 downto 4);
                                   out_prb_data_q <= "0000" & buf_prb_data(3)(3 downto 0)   & buf_prb_data(2)(31 downto 24);
                    when x"7"   => out_prb_data_i <= "0000" & buf_prb_data(3)(23 downto 12);
                                   out_prb_data_q <= "0000" & buf_prb_data(3)(11 downto 0);
                    when x"8"   => out_prb_data_i <= "0000" & buf_prb_data(3)(31 downto 20);
                                   out_prb_data_q <= "0000" & buf_prb_data(3)(19 downto 8);
                    when x"9"   => out_prb_data_i <= "0000" & buf_prb_data(4)(7 downto 0)   & buf_prb_data(3)(31 downto 28);
                                   out_prb_data_q <= "0000" & buf_prb_data(3)(27 downto 16);
                    when x"A"   => out_prb_data_i <= "0000" & buf_prb_data(4)(15 downto 4);
                                   out_prb_data_q <= "0000" & buf_prb_data(4)(3 downto 0)   & buf_prb_data(3)(31 downto 24);
                    when x"B"   => out_prb_data_i <= "0000" & buf_prb_data(4)(23 downto 12);
                                   out_prb_data_q <= "0000" & buf_prb_data(4)(11 downto 0);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (UNCOMP_11B = true) and (iq_width = 11) then              -- Uncomp/MC + 11bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "00000" & buf_prb_data(1)(31 downto 21);
                                   out_prb_data_q <= "00000" & buf_prb_data(1)(20 downto 10);
                    when x"1"   => out_prb_data_i <= "00000" & buf_prb_data(2)(9 downto 0)   & buf_prb_data(1)(31 downto 31);
                                   out_prb_data_q <= "00000" & buf_prb_data(1)(30 downto 20);
                    when x"2"   => out_prb_data_i <= "00000" & buf_prb_data(2)(19 downto 9);
                                   out_prb_data_q <= "00000" & buf_prb_data(2)(8 downto 0)   & buf_prb_data(1)(31 downto 30);
                    when x"3"   => out_prb_data_i <= "00000" & buf_prb_data(2)(29 downto 19);
                                   out_prb_data_q <= "00000" & buf_prb_data(2)(18 downto 8);
                    when x"4"   => out_prb_data_i <= "00000" & buf_prb_data(3)(7 downto 0)   & buf_prb_data(2)(31 downto 29);
                                   out_prb_data_q <= "00000" & buf_prb_data(2)(28 downto 18);
                    when x"5"   => out_prb_data_i <= "00000" & buf_prb_data(3)(17 downto 7);
                                   out_prb_data_q <= "00000" & buf_prb_data(3)(6 downto 0)   & buf_prb_data(2)(31 downto 28);
                    when x"6"   => out_prb_data_i <= "00000" & buf_prb_data(3)(27 downto 17);
                                   out_prb_data_q <= "00000" & buf_prb_data(3)(16 downto 6);
                    when x"7"   => out_prb_data_i <= "00000" & buf_prb_data(4)(5 downto 0)   & buf_prb_data(3)(31 downto 27);
                                   out_prb_data_q <= "00000" & buf_prb_data(3)(26 downto 16);
                    when x"8"   => out_prb_data_i <= "00000" & buf_prb_data(4)(15 downto 5);
                                   out_prb_data_q <= "00000" & buf_prb_data(4)(4 downto 0)   & buf_prb_data(3)(31 downto 26);
                    when x"9"   => out_prb_data_i <= "00000" & buf_prb_data(4)(25 downto 15);
                                   out_prb_data_q <= "00000" & buf_prb_data(4)(14 downto 4);
                    when x"A"   => out_prb_data_i <= "00000" & buf_prb_data(5)(3 downto 0)   & buf_prb_data(4)(31 downto 25);
                                   out_prb_data_q <= "00000" & buf_prb_data(4)(24 downto 14);
                    when x"B"   => out_prb_data_i <= "00000" & buf_prb_data(5)(13 downto 3);
                                   out_prb_data_q <= "00000" & buf_prb_data(5)(2 downto 0)   & buf_prb_data(4)(31 downto 24);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (UNCOMP_10B = true) and (iq_width = 10) then              -- Uncomp/MC + 10bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "000000" & buf_prb_data(1)(31 downto 22);
                                   out_prb_data_q <= "000000" & buf_prb_data(1)(21 downto 12);
                    when x"1"   => out_prb_data_i <= "000000" & buf_prb_data(2)(11 downto 2);
                                   out_prb_data_q <= "000000" & buf_prb_data(2)(1 downto 0)   & buf_prb_data(1)(31 downto 24);
                    when x"2"   => out_prb_data_i <= "000000" & buf_prb_data(2)(23 downto 14);
                                   out_prb_data_q <= "000000" & buf_prb_data(2)(13 downto 4);
                    when x"3"   => out_prb_data_i <= "000000" & buf_prb_data(3)(3 downto 0)   & buf_prb_data(2)(31 downto 26);
                                   out_prb_data_q <= "000000" & buf_prb_data(2)(25 downto 16);
                    when x"4"   => out_prb_data_i <= "000000" & buf_prb_data(3)(15 downto 6);
                                   out_prb_data_q <= "000000" & buf_prb_data(3)(5 downto 0)   & buf_prb_data(2)(31 downto 28);
                    when x"5"   => out_prb_data_i <= "000000" & buf_prb_data(3)(27 downto 18);
                                   out_prb_data_q <= "000000" & buf_prb_data(3)(17 downto 8);
                    when x"6"   => out_prb_data_i <= "000000" & buf_prb_data(4)(7 downto 0)   & buf_prb_data(3)(31 downto 30);
                                   out_prb_data_q <= "000000" & buf_prb_data(3)(29 downto 20);
                    when x"7"   => out_prb_data_i <= "000000" & buf_prb_data(4)(19 downto 10);
                                   out_prb_data_q <= "000000" & buf_prb_data(4)(9 downto 0);
                    when x"8"   => out_prb_data_i <= "000000" & buf_prb_data(4)(31 downto 22);
                                   out_prb_data_q <= "000000" & buf_prb_data(4)(21 downto 12);
                    when x"9"   => out_prb_data_i <= "000000" & buf_prb_data(5)(11 downto 2);
                                   out_prb_data_q <= "000000" & buf_prb_data(5)(1 downto 0)   & buf_prb_data(4)(31 downto 24);
                    when x"A"   => out_prb_data_i <= "000000" & buf_prb_data(5)(23 downto 14);
                                   out_prb_data_q <= "000000" & buf_prb_data(5)(13 downto 4);
                    when x"B"   => out_prb_data_i <= "000000" & buf_prb_data(6)(3 downto 0)   & buf_prb_data(5)(31 downto 26);
                                   out_prb_data_q <= "000000" & buf_prb_data(5)(25 downto 16);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (UNCOMP_9B = true) and (iq_width = 9) then                -- Uncomp/MC +  9bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "0000000" & buf_prb_data(1)(31 downto 23);
                                   out_prb_data_q <= "0000000" & buf_prb_data(1)(22 downto 14);
                    when x"1"   => out_prb_data_i <= "0000000" & buf_prb_data(2)(13 downto 5);
                                   out_prb_data_q <= "0000000" & buf_prb_data(2)(4 downto 0)   & buf_prb_data(1)(31 downto 28);
                    when x"2"   => out_prb_data_i <= "0000000" & buf_prb_data(2)(27 downto 19);
                                   out_prb_data_q <= "0000000" & buf_prb_data(2)(18 downto 10);
                    when x"3"   => out_prb_data_i <= "0000000" & buf_prb_data(3)(9 downto 1);
                                   out_prb_data_q <= "0000000" & buf_prb_data(3)(0 downto 0)   & buf_prb_data(2)(31 downto 24);
                    when x"4"   => out_prb_data_i <= "0000000" & buf_prb_data(3)(23 downto 15);
                                   out_prb_data_q <= "0000000" & buf_prb_data(3)(14 downto 6);
                    when x"5"   => out_prb_data_i <= "0000000" & buf_prb_data(4)(5 downto 0)   & buf_prb_data(3)(31 downto 29);
                                   out_prb_data_q <= "0000000" & buf_prb_data(3)(28 downto 20);
                    when x"6"   => out_prb_data_i <= "0000000" & buf_prb_data(4)(19 downto 11);
                                   out_prb_data_q <= "0000000" & buf_prb_data(4)(10 downto 2);
                    when x"7"   => out_prb_data_i <= "0000000" & buf_prb_data(5)(1 downto 0)   & buf_prb_data(4)(31 downto 25);
                                   out_prb_data_q <= "0000000" & buf_prb_data(4)(24 downto 16);
                    when x"8"   => out_prb_data_i <= "0000000" & buf_prb_data(5)(15 downto 7);
                                   out_prb_data_q <= "0000000" & buf_prb_data(5)(6 downto 0)   & buf_prb_data(4)(31 downto 30);
                    when x"9"   => out_prb_data_i <= "0000000" & buf_prb_data(5)(29 downto 21);
                                   out_prb_data_q <= "0000000" & buf_prb_data(5)(20 downto 12);
                    when x"A"   => out_prb_data_i <= "0000000" & buf_prb_data(6)(11 downto 3);
                                   out_prb_data_q <= "0000000" & buf_prb_data(6)(2 downto 0)   & buf_prb_data(5)(31 downto 26);
                    when x"B"   => out_prb_data_i <= "0000000" & buf_prb_data(6)(25 downto 17);
                                   out_prb_data_q <= "0000000" & buf_prb_data(6)(16 downto 8);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (UNCOMP_8B = true) and (iq_width = 8) then                -- Uncomp/MC +  8bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "00000000" & buf_prb_data(1)(31 downto 24);
                                   out_prb_data_q <= "00000000" & buf_prb_data(1)(23 downto 16);
                    when x"1"   => out_prb_data_i <= "00000000" & buf_prb_data(2)(15 downto 8);
                                   out_prb_data_q <= "00000000" & buf_prb_data(2)(7 downto 0);
                    when x"2"   => out_prb_data_i <= "00000000" & buf_prb_data(2)(31 downto 24);
                                   out_prb_data_q <= "00000000" & buf_prb_data(2)(23 downto 16);
                    when x"3"   => out_prb_data_i <= "00000000" & buf_prb_data(3)(15 downto 8);
                                   out_prb_data_q <= "00000000" & buf_prb_data(3)(7 downto 0);
                    when x"4"   => out_prb_data_i <= "00000000" & buf_prb_data(3)(31 downto 24);
                                   out_prb_data_q <= "00000000" & buf_prb_data(3)(23 downto 16);
                    when x"5"   => out_prb_data_i <= "00000000" & buf_prb_data(4)(15 downto 8);
                                   out_prb_data_q <= "00000000" & buf_prb_data(4)(7 downto 0);
                    when x"6"   => out_prb_data_i <= "00000000" & buf_prb_data(4)(31 downto 24);
                                   out_prb_data_q <= "00000000" & buf_prb_data(4)(23 downto 16);
                    when x"7"   => out_prb_data_i <= "00000000" & buf_prb_data(5)(15 downto 8);
                                   out_prb_data_q <= "00000000" & buf_prb_data(5)(7 downto 0);
                    when x"8"   => out_prb_data_i <= "00000000" & buf_prb_data(5)(31 downto 24);
                                   out_prb_data_q <= "00000000" & buf_prb_data(5)(23 downto 16);
                    when x"9"   => out_prb_data_i <= "00000000" & buf_prb_data(6)(15 downto 8);
                                   out_prb_data_q <= "00000000" & buf_prb_data(6)(7 downto 0);
                    when x"A"   => out_prb_data_i <= "00000000" & buf_prb_data(6)(31 downto 24);
                                   out_prb_data_q <= "00000000" & buf_prb_data(6)(23 downto 16);
                    when x"B"   => out_prb_data_i <= "00000000" & buf_prb_data(7)(15 downto 8);
                                   out_prb_data_q <= "00000000" & buf_prb_data(7)(7 downto 0);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (UNCOMP_7B = true) and (iq_width = 7) then                -- Uncomp/MC +  7bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "000000000" & buf_prb_data(1)(31 downto 25);
                                   out_prb_data_q <= "000000000" & buf_prb_data(1)(24 downto 18);
                    when x"1"   => out_prb_data_i <= "000000000" & buf_prb_data(2)(17 downto 11);
                                   out_prb_data_q <= "000000000" & buf_prb_data(2)(10 downto 4);
                    when x"2"   => out_prb_data_i <= "000000000" & buf_prb_data(3)(3 downto 0)   & buf_prb_data(2)(31 downto 29);
                                   out_prb_data_q <= "000000000" & buf_prb_data(2)(28 downto 22);
                    when x"3"   => out_prb_data_i <= "000000000" & buf_prb_data(3)(21 downto 15);
                                   out_prb_data_q <= "000000000" & buf_prb_data(3)(14 downto 8);
                    when x"4"   => out_prb_data_i <= "000000000" & buf_prb_data(4)(7 downto 1);
                                   out_prb_data_q <= "000000000" & buf_prb_data(4)(0 downto 0)   & buf_prb_data(3)(31 downto 26);
                    when x"5"   => out_prb_data_i <= "000000000" & buf_prb_data(4)(25 downto 19);
                                   out_prb_data_q <= "000000000" & buf_prb_data(4)(18 downto 12);
                    when x"6"   => out_prb_data_i <= "000000000" & buf_prb_data(5)(11 downto 5);
                                   out_prb_data_q <= "000000000" & buf_prb_data(5)(4 downto 0)   & buf_prb_data(4)(31 downto 30);
                    when x"7"   => out_prb_data_i <= "000000000" & buf_prb_data(5)(29 downto 23);
                                   out_prb_data_q <= "000000000" & buf_prb_data(5)(22 downto 16);
                    when x"8"   => out_prb_data_i <= "000000000" & buf_prb_data(6)(15 downto 9);
                                   out_prb_data_q <= "000000000" & buf_prb_data(6)(8 downto 2);
                    when x"9"   => out_prb_data_i <= "000000000" & buf_prb_data(7)(1 downto 0)   & buf_prb_data(6)(31 downto 27);
                                   out_prb_data_q <= "000000000" & buf_prb_data(6)(26 downto 20);
                    when x"A"   => out_prb_data_i <= "000000000" & buf_prb_data(7)(19 downto 13);
                                   out_prb_data_q <= "000000000" & buf_prb_data(7)(12 downto 6);
                    when x"B"   => out_prb_data_i <= "000000000" & buf_prb_data(8)(5 downto 0)   & buf_prb_data(7)(31 downto 31);
                                   out_prb_data_q <= "000000000" & buf_prb_data(7)(30 downto 24);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (UNCOMP_6B = true) and (iq_width = 6) then                -- Uncomp/MC +  6bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "0000000000" & buf_prb_data(1)(31 downto 26);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(1)(25 downto 20);
                    when x"1"   => out_prb_data_i <= "0000000000" & buf_prb_data(2)(19 downto 14);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(2)(13 downto 8);
                    when x"2"   => out_prb_data_i <= "0000000000" & buf_prb_data(3)(7 downto 2);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(3)(1 downto 0)   & buf_prb_data(2)(31 downto 28);
                    when x"3"   => out_prb_data_i <= "0000000000" & buf_prb_data(3)(27 downto 22);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(3)(21 downto 16);
                    when x"4"   => out_prb_data_i <= "0000000000" & buf_prb_data(4)(15 downto 10);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(4)(9 downto 4);
                    when x"5"   => out_prb_data_i <= "0000000000" & buf_prb_data(5)(3 downto 0)   & buf_prb_data(4)(31 downto 30);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(4)(29 downto 24);
                    when x"6"   => out_prb_data_i <= "0000000000" & buf_prb_data(5)(23 downto 18);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(5)(17 downto 12);
                    when x"7"   => out_prb_data_i <= "0000000000" & buf_prb_data(6)(11 downto 6);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(6)(5 downto 0);
                    when x"8"   => out_prb_data_i <= "0000000000" & buf_prb_data(6)(31 downto 26);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(6)(25 downto 20);
                    when x"9"   => out_prb_data_i <= "0000000000" & buf_prb_data(7)(19 downto 14);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(7)(13 downto 8);
                    when x"A"   => out_prb_data_i <= "0000000000" & buf_prb_data(8)(7 downto 2);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(8)(1 downto 0)   & buf_prb_data(7)(31 downto 28);
                    when x"B"   => out_prb_data_i <= "0000000000" & buf_prb_data(8)(27 downto 22);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(8)(21 downto 16);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (UNCOMP_5B = true) and (iq_width = 5) then                -- Uncomp/MC +  5bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "00000000000" & buf_prb_data(1)(31 downto 27);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(1)(26 downto 22);
                    when x"1"   => out_prb_data_i <= "00000000000" & buf_prb_data(2)(21 downto 17);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(2)(16 downto 12);
                    when x"2"   => out_prb_data_i <= "00000000000" & buf_prb_data(3)(11 downto 7);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(3)(6 downto 2);
                    when x"3"   => out_prb_data_i <= "00000000000" & buf_prb_data(4)(1 downto 0)   & buf_prb_data(3)(31 downto 29);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(3)(28 downto 24);
                    when x"4"   => out_prb_data_i <= "00000000000" & buf_prb_data(4)(23 downto 19);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(4)(18 downto 14);
                    when x"5"   => out_prb_data_i <= "00000000000" & buf_prb_data(5)(13 downto 9);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(5)(8 downto 4);
                    when x"6"   => out_prb_data_i <= "00000000000" & buf_prb_data(6)(3 downto 0)   & buf_prb_data(5)(31 downto 31);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(5)(30 downto 26);
                    when x"7"   => out_prb_data_i <= "00000000000" & buf_prb_data(6)(25 downto 21);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(6)(20 downto 16);
                    when x"8"   => out_prb_data_i <= "00000000000" & buf_prb_data(7)(15 downto 11);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(7)(10 downto 6);
                    when x"9"   => out_prb_data_i <= "00000000000" & buf_prb_data(8)(5 downto 1);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(8)(0 downto 0)   & buf_prb_data(7)(31 downto 28);
                    when x"A"   => out_prb_data_i <= "00000000000" & buf_prb_data(8)(27 downto 23);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(8)(22 downto 18);
                    when x"B"   => out_prb_data_i <= "00000000000" & buf_prb_data(9)(17 downto 13);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(9)(12 downto 8);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (UNCOMP_4B = true) and (iq_width = 4) then                -- Uncomp/MC +  4bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "000000000000" & buf_prb_data(1)(31 downto 28);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(1)(27 downto 24);
                    when x"1"   => out_prb_data_i <= "000000000000" & buf_prb_data(2)(23 downto 20);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(2)(19 downto 16);
                    when x"2"   => out_prb_data_i <= "000000000000" & buf_prb_data(3)(15 downto 12);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(3)(11 downto 8);
                    when x"3"   => out_prb_data_i <= "000000000000" & buf_prb_data(4)(7 downto 4);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(4)(3 downto 0);
                    when x"4"   => out_prb_data_i <= "000000000000" & buf_prb_data(4)(31 downto 28);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(4)(27 downto 24);
                    when x"5"   => out_prb_data_i <= "000000000000" & buf_prb_data(5)(23 downto 20);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(5)(19 downto 16);
                    when x"6"   => out_prb_data_i <= "000000000000" & buf_prb_data(6)(15 downto 12);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(6)(11 downto 8);
                    when x"7"   => out_prb_data_i <= "000000000000" & buf_prb_data(7)(7 downto 4);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(7)(3 downto 0);
                    when x"8"   => out_prb_data_i <= "000000000000" & buf_prb_data(7)(31 downto 28);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(7)(27 downto 24);
                    when x"9"   => out_prb_data_i <= "000000000000" & buf_prb_data(8)(23 downto 20);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(8)(19 downto 16);
                    when x"A"   => out_prb_data_i <= "000000000000" & buf_prb_data(9)(15 downto 12);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(9)(11 downto 8);
                    when x"B"   => out_prb_data_i <= "000000000000" & buf_prb_data(10)(7 downto 4);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(10)(3 downto 0);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (UNCOMP_3B = true) and (iq_width = 3) then                -- Uncomp/MC +  3bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "0000000000000" & buf_prb_data(1)(31 downto 29);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(1)(28 downto 26);
                    when x"1"   => out_prb_data_i <= "0000000000000" & buf_prb_data(2)(25 downto 23);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(2)(22 downto 20);
                    when x"2"   => out_prb_data_i <= "0000000000000" & buf_prb_data(3)(19 downto 17);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(3)(16 downto 14);
                    when x"3"   => out_prb_data_i <= "0000000000000" & buf_prb_data(4)(13 downto 11);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(4)(10 downto 8);
                    when x"4"   => out_prb_data_i <= "0000000000000" & buf_prb_data(5)(7 downto 5);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(5)(4 downto 2);
                    when x"5"   => out_prb_data_i <= "0000000000000" & buf_prb_data(6)(1 downto 0)    & buf_prb_data(5)(31 downto 31);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(5)(30 downto 28);
                    when x"6"   => out_prb_data_i <= "0000000000000" & buf_prb_data(6)(27 downto 25);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(6)(24 downto 22);
                    when x"7"   => out_prb_data_i <= "0000000000000" & buf_prb_data(7)(21 downto 19);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(7)(18 downto 16);
                    when x"8"   => out_prb_data_i <= "0000000000000" & buf_prb_data(8)(15 downto 13);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(8)(12 downto 10);
                    when x"9"   => out_prb_data_i <= "0000000000000" & buf_prb_data(9)(9 downto 7);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(9)(6 downto 4);
                    when x"A"   => out_prb_data_i <= "0000000000000" & buf_prb_data(10)(3 downto 1);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(10)(0 downto 0)   & buf_prb_data(9)(31 downto 30);
                    when x"B"   => out_prb_data_i <= "0000000000000" & buf_prb_data(10)(29 downto 27);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(10)(26 downto 24);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                else
                    out_prb_data_i <= (others => '0');
                    out_prb_data_q <= (others => '0');
                end if;
            else
                if    (COMP_15B = true) and (iq_width = 15) then                -- Comp + 15bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= '0' & buf_prb_data(1)(23 downto 9);
                                   out_prb_data_q <= '0' & buf_prb_data(1)(8 downto 0)   & buf_prb_data(0)(31 downto 26);
                    when x"1"   => out_prb_data_i <= '0' & buf_prb_data(1)(25 downto 11);
                                   out_prb_data_q <= '0' & buf_prb_data(1)(10 downto 0)  & buf_prb_data(0)(31 downto 28);
                    when x"2"   => out_prb_data_i <= '0' & buf_prb_data(1)(27 downto 13);
                                   out_prb_data_q <= '0' & buf_prb_data(1)(12 downto 0)  & buf_prb_data(0)(31 downto 30);
                    when x"3"   => out_prb_data_i <= '0' & buf_prb_data(1)(29 downto 15);
                                   out_prb_data_q <= '0' & buf_prb_data(1)(14 downto 0);
                    when x"4"   => out_prb_data_i <= '0' & buf_prb_data(1)(31 downto 17);
                                   out_prb_data_q <= '0' & buf_prb_data(1)(16 downto 2);
                    when x"5"   => out_prb_data_i <= '0' & buf_prb_data(2)(1 downto 0)   & buf_prb_data(1)(31 downto 19);
                                   out_prb_data_q <= '0' & buf_prb_data(1)(18 downto 4);
                    when x"6"   => out_prb_data_i <= '0' & buf_prb_data(2)(3 downto 0)   & buf_prb_data(1)(31 downto 21);
                                   out_prb_data_q <= '0' & buf_prb_data(1)(20 downto 6);
                    when x"7"   => out_prb_data_i <= '0' & buf_prb_data(2)(5 downto 0)   & buf_prb_data(1)(31 downto 23);
                                   out_prb_data_q <= '0' & buf_prb_data(1)(22 downto 8);
                    when x"8"   => out_prb_data_i <= '0' & buf_prb_data(2)(7 downto 0)   & buf_prb_data(1)(31 downto 25);
                                   out_prb_data_q <= '0' & buf_prb_data(1)(24 downto 10);
                    when x"9"   => out_prb_data_i <= '0' & buf_prb_data(2)(9 downto 0)   & buf_prb_data(1)(31 downto 27);
                                   out_prb_data_q <= '0' & buf_prb_data(1)(26 downto 12);
                    when x"A"   => out_prb_data_i <= '0' & buf_prb_data(2)(11 downto 0)  & buf_prb_data(1)(31 downto 29);
                                   out_prb_data_q <= '0' & buf_prb_data(1)(28 downto 14);
                    when x"B"   => out_prb_data_i <= '0' & buf_prb_data(2)(13 downto 0)  & buf_prb_data(1)(31 downto 31);
                                   out_prb_data_q <= '0' & buf_prb_data(1)(30 downto 16);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (COMP_14B = true) and (iq_width = 14) then                -- Comp + 14bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "00" & buf_prb_data(1)(23 downto 10);
                                   out_prb_data_q <= "00" & buf_prb_data(1)(9 downto 0)   & buf_prb_data(0)(31 downto 28);
                    when x"1"   => out_prb_data_i <= "00" & buf_prb_data(1)(27 downto 14);
                                   out_prb_data_q <= "00" & buf_prb_data(1)(13 downto 0);
                    when x"2"   => out_prb_data_i <= "00" & buf_prb_data(1)(31 downto 18);
                                   out_prb_data_q <= "00" & buf_prb_data(1)(17 downto 4);
                    when x"3"   => out_prb_data_i <= "00" & buf_prb_data(2)(3 downto 0)   & buf_prb_data(1)(31 downto 22);
                                   out_prb_data_q <= "00" & buf_prb_data(1)(21 downto 8);
                    when x"4"   => out_prb_data_i <= "00" & buf_prb_data(2)(7 downto 0)   & buf_prb_data(1)(31 downto 26);
                                   out_prb_data_q <= "00" & buf_prb_data(1)(25 downto 12);
                    when x"5"   => out_prb_data_i <= "00" & buf_prb_data(2)(11 downto 0)  & buf_prb_data(1)(31 downto 30);
                                   out_prb_data_q <= "00" & buf_prb_data(1)(29 downto 16);
                    when x"6"   => out_prb_data_i <= "00" & buf_prb_data(2)(15 downto 2);
                                   out_prb_data_q <= "00" & buf_prb_data(2)(1 downto 0)   & buf_prb_data(1)(31 downto 20);
                    when x"7"   => out_prb_data_i <= "00" & buf_prb_data(2)(19 downto 6);
                                   out_prb_data_q <= "00" & buf_prb_data(2)(5 downto 0)   & buf_prb_data(1)(31 downto 24);
                    when x"8"   => out_prb_data_i <= "00" & buf_prb_data(2)(23 downto 10);
                                   out_prb_data_q <= "00" & buf_prb_data(2)(9 downto 0)   & buf_prb_data(1)(31 downto 28);
                    when x"9"   => out_prb_data_i <= "00" & buf_prb_data(2)(27 downto 14);
                                   out_prb_data_q <= "00" & buf_prb_data(2)(13 downto 0);
                    when x"A"   => out_prb_data_i <= "00" & buf_prb_data(2)(31 downto 18);
                                   out_prb_data_q <= "00" & buf_prb_data(2)(17 downto 4);
                    when x"B"   => out_prb_data_i <= "00" & buf_prb_data(3)(3 downto 0)   & buf_prb_data(2)(31 downto 22);
                                   out_prb_data_q <= "00" & buf_prb_data(2)(21 downto 8);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (COMP_13B = true) and (iq_width = 13) then                -- Comp + 13bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "000" & buf_prb_data(1)(23 downto 11);
                                   out_prb_data_q <= "000" & buf_prb_data(1)(10 downto 0)  & buf_prb_data(0)(31 downto 30);
                    when x"1"   => out_prb_data_i <= "000" & buf_prb_data(1)(29 downto 17);
                                   out_prb_data_q <= "000" & buf_prb_data(1)(16 downto 4);
                    when x"2"   => out_prb_data_i <= "000" & buf_prb_data(2)(3 downto 0)   & buf_prb_data(1)(31 downto 23);
                                   out_prb_data_q <= "000" & buf_prb_data(1)(22 downto 10);
                    when x"3"   => out_prb_data_i <= "000" & buf_prb_data(2)(9 downto 0)   & buf_prb_data(1)(31 downto 29);
                                   out_prb_data_q <= "000" & buf_prb_data(1)(28 downto 16);
                    when x"4"   => out_prb_data_i <= "000" & buf_prb_data(2)(15 downto 3);
                                   out_prb_data_q <= "000" & buf_prb_data(2)(2 downto 0)   & buf_prb_data(1)(31 downto 22);
                    when x"5"   => out_prb_data_i <= "000" & buf_prb_data(2)(21 downto 9);
                                   out_prb_data_q <= "000" & buf_prb_data(2)(8 downto 0)   & buf_prb_data(1)(31 downto 28);
                    when x"6"   => out_prb_data_i <= "000" & buf_prb_data(2)(27 downto 15);
                                   out_prb_data_q <= "000" & buf_prb_data(2)(14 downto 2);
                    when x"7"   => out_prb_data_i <= "000" & buf_prb_data(3)(1 downto 0)   & buf_prb_data(2)(31 downto 21);
                                   out_prb_data_q <= "000" & buf_prb_data(2)(20 downto 8);
                    when x"8"   => out_prb_data_i <= "000" & buf_prb_data(3)(7 downto 0)   & buf_prb_data(2)(31 downto 27);
                                   out_prb_data_q <= "000" & buf_prb_data(2)(26 downto 14);
                    when x"9"   => out_prb_data_i <= "000" & buf_prb_data(3)(13 downto 1);
                                   out_prb_data_q <= "000" & buf_prb_data(3)(0 downto 0)   & buf_prb_data(2)(31 downto 20);
                    when x"A"   => out_prb_data_i <= "000" & buf_prb_data(3)(19 downto 7);
                                   out_prb_data_q <= "000" & buf_prb_data(3)(6 downto 0)   & buf_prb_data(2)(31 downto 26);
                    when x"B"   => out_prb_data_i <= "000" & buf_prb_data(3)(25 downto 13);
                                   out_prb_data_q <= "000" & buf_prb_data(3)(12 downto 0);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (COMP_12B = true) and (iq_width = 12) then                -- Comp + 12bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "0000" & buf_prb_data(1)(23 downto 12);
                                   out_prb_data_q <= "0000" & buf_prb_data(1)(11 downto 0);
                    when x"1"   => out_prb_data_i <= "0000" & buf_prb_data(1)(31 downto 20);
                                   out_prb_data_q <= "0000" & buf_prb_data(1)(19 downto 8);
                    when x"2"   => out_prb_data_i <= "0000" & buf_prb_data(2)(7 downto 0)   & buf_prb_data(1)(31 downto 28);
                                   out_prb_data_q <= "0000" & buf_prb_data(1)(27 downto 16);
                    when x"3"   => out_prb_data_i <= "0000" & buf_prb_data(2)(15 downto 4);
                                   out_prb_data_q <= "0000" & buf_prb_data(2)(3 downto 0)   & buf_prb_data(1)(31 downto 24);
                    when x"4"   => out_prb_data_i <= "0000" & buf_prb_data(2)(23 downto 12);
                                   out_prb_data_q <= "0000" & buf_prb_data(2)(11 downto 0);
                    when x"5"   => out_prb_data_i <= "0000" & buf_prb_data(2)(31 downto 20);
                                   out_prb_data_q <= "0000" & buf_prb_data(2)(19 downto 8);
                    when x"6"   => out_prb_data_i <= "0000" & buf_prb_data(3)(7 downto 0)   & buf_prb_data(2)(31 downto 28);
                                   out_prb_data_q <= "0000" & buf_prb_data(2)(27 downto 16);
                    when x"7"   => out_prb_data_i <= "0000" & buf_prb_data(3)(15 downto 4);
                                   out_prb_data_q <= "0000" & buf_prb_data(3)(3 downto 0)   & buf_prb_data(2)(31 downto 24);
                    when x"8"   => out_prb_data_i <= "0000" & buf_prb_data(3)(23 downto 12);
                                   out_prb_data_q <= "0000" & buf_prb_data(3)(11 downto 0);
                    when x"9"   => out_prb_data_i <= "0000" & buf_prb_data(3)(31 downto 20);
                                   out_prb_data_q <= "0000" & buf_prb_data(3)(19 downto 8);
                    when x"A"   => out_prb_data_i <= "0000" & buf_prb_data(4)(7 downto 0)   & buf_prb_data(3)(31 downto 28);
                                   out_prb_data_q <= "0000" & buf_prb_data(3)(27 downto 16);
                    when x"B"   => out_prb_data_i <= "0000" & buf_prb_data(4)(15 downto 4);
                                   out_prb_data_q <= "0000" & buf_prb_data(4)(3 downto 0)   & buf_prb_data(3)(31 downto 24);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (COMP_11B = true) and (iq_width = 11) then                -- Comp + 11bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "00000" & buf_prb_data(1)(23 downto 13);
                                   out_prb_data_q <= "00000" & buf_prb_data(1)(12 downto 2);
                    when x"1"   => out_prb_data_i <= "00000" & buf_prb_data(2)(1 downto 0)   & buf_prb_data(1)(31 downto 23);
                                   out_prb_data_q <= "00000" & buf_prb_data(1)(22 downto 12);
                    when x"2"   => out_prb_data_i <= "00000" & buf_prb_data(2)(11 downto 1);
                                   out_prb_data_q <= "00000" & buf_prb_data(2)(0 downto 0)   & buf_prb_data(1)(31 downto 22);
                    when x"3"   => out_prb_data_i <= "00000" & buf_prb_data(2)(21 downto 11);
                                   out_prb_data_q <= "00000" & buf_prb_data(2)(10 downto 0);
                    when x"4"   => out_prb_data_i <= "00000" & buf_prb_data(2)(31 downto 21);
                                   out_prb_data_q <= "00000" & buf_prb_data(2)(20 downto 10);
                    when x"5"   => out_prb_data_i <= "00000" & buf_prb_data(3)(9 downto 0)   & buf_prb_data(2)(31 downto 31);
                                   out_prb_data_q <= "00000" & buf_prb_data(2)(30 downto 20);
                    when x"6"   => out_prb_data_i <= "00000" & buf_prb_data(3)(19 downto 9);
                                   out_prb_data_q <= "00000" & buf_prb_data(3)(8 downto 0)   & buf_prb_data(2)(31 downto 30);
                    when x"7"   => out_prb_data_i <= "00000" & buf_prb_data(3)(29 downto 19);
                                   out_prb_data_q <= "00000" & buf_prb_data(3)(18 downto 8);
                    when x"8"   => out_prb_data_i <= "00000" & buf_prb_data(4)(7 downto 0)   & buf_prb_data(3)(31 downto 29);
                                   out_prb_data_q <= "00000" & buf_prb_data(3)(28 downto 18);
                    when x"9"   => out_prb_data_i <= "00000" & buf_prb_data(4)(17 downto 7);
                                   out_prb_data_q <= "00000" & buf_prb_data(4)(6 downto 0)   & buf_prb_data(3)(31 downto 28);
                    when x"A"   => out_prb_data_i <= "00000" & buf_prb_data(4)(27 downto 17);
                                   out_prb_data_q <= "00000" & buf_prb_data(4)(16 downto 6);
                    when x"B"   => out_prb_data_i <= "00000" & buf_prb_data(5)(5 downto 0)   & buf_prb_data(4)(31 downto 27);
                                   out_prb_data_q <= "00000" & buf_prb_data(4)(26 downto 16);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (COMP_10B = true) and (iq_width = 10) then                -- Comp + 10bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "000000" & buf_prb_data(1)(23 downto 14);
                                   out_prb_data_q <= "000000" & buf_prb_data(1)(13 downto 4);
                    when x"1"   => out_prb_data_i <= "000000" & buf_prb_data(2)(3 downto 0)   & buf_prb_data(1)(31 downto 26);
                                   out_prb_data_q <= "000000" & buf_prb_data(1)(25 downto 16);
                    when x"2"   => out_prb_data_i <= "000000" & buf_prb_data(2)(15 downto 6);
                                   out_prb_data_q <= "000000" & buf_prb_data(2)(5 downto 0)   & buf_prb_data(1)(31 downto 28);
                    when x"3"   => out_prb_data_i <= "000000" & buf_prb_data(2)(27 downto 18);
                                   out_prb_data_q <= "000000" & buf_prb_data(2)(17 downto 8);
                    when x"4"   => out_prb_data_i <= "000000" & buf_prb_data(3)(7 downto 0)   & buf_prb_data(2)(31 downto 30);
                                   out_prb_data_q <= "000000" & buf_prb_data(2)(29 downto 20);
                    when x"5"   => out_prb_data_i <= "000000" & buf_prb_data(3)(19 downto 10);
                                   out_prb_data_q <= "000000" & buf_prb_data(3)(9 downto 0);
                    when x"6"   => out_prb_data_i <= "000000" & buf_prb_data(3)(31 downto 22);
                                   out_prb_data_q <= "000000" & buf_prb_data(3)(21 downto 12);
                    when x"7"   => out_prb_data_i <= "000000" & buf_prb_data(4)(11 downto 2);
                                   out_prb_data_q <= "000000" & buf_prb_data(4)(1 downto 0)   & buf_prb_data(3)(31 downto 24);
                    when x"8"   => out_prb_data_i <= "000000" & buf_prb_data(4)(23 downto 14);
                                   out_prb_data_q <= "000000" & buf_prb_data(4)(13 downto 4);
                    when x"9"   => out_prb_data_i <= "000000" & buf_prb_data(5)(3 downto 0)   & buf_prb_data(4)(31 downto 26);
                                   out_prb_data_q <= "000000" & buf_prb_data(4)(25 downto 16);
                    when x"A"   => out_prb_data_i <= "000000" & buf_prb_data(5)(15 downto 6);
                                   out_prb_data_q <= "000000" & buf_prb_data(5)(5 downto 0)   & buf_prb_data(4)(31 downto 28);
                    when x"B"   => out_prb_data_i <= "000000" & buf_prb_data(5)(27 downto 18);
                                   out_prb_data_q <= "000000" & buf_prb_data(5)(17 downto 8);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (COMP_9B = true) and (iq_width = 9) then                  -- Comp +  9bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "0000000" & buf_prb_data(1)(23 downto 15);
                                   out_prb_data_q <= "0000000" & buf_prb_data(1)(14 downto 6);
                    when x"1"   => out_prb_data_i <= "0000000" & buf_prb_data(2)(5 downto 0)  & buf_prb_data(1)(31 downto 29);
                                   out_prb_data_q <= "0000000" & buf_prb_data(1)(28 downto 20);
                    when x"2"   => out_prb_data_i <= "0000000" & buf_prb_data(2)(19 downto 11);
                                   out_prb_data_q <= "0000000" & buf_prb_data(2)(10 downto 2);
                    when x"3"   => out_prb_data_i <= "0000000" & buf_prb_data(3)(1 downto 0)  & buf_prb_data(2)(31 downto 25);
                                   out_prb_data_q <= "0000000" & buf_prb_data(2)(24 downto 16);
                    when x"4"   => out_prb_data_i <= "0000000" & buf_prb_data(3)(15 downto 7);
                                   out_prb_data_q <= "0000000" & buf_prb_data(3)(6 downto 0)  & buf_prb_data(2)(31 downto 30);
                    when x"5"   => out_prb_data_i <= "0000000" & buf_prb_data(3)(29 downto 21);
                                   out_prb_data_q <= "0000000" & buf_prb_data(3)(20 downto 12);
                    when x"6"   => out_prb_data_i <= "0000000" & buf_prb_data(4)(11 downto 3);
                                   out_prb_data_q <= "0000000" & buf_prb_data(4)(2 downto 0)  & buf_prb_data(3)(31 downto 26);
                    when x"7"   => out_prb_data_i <= "0000000" & buf_prb_data(4)(25 downto 17);
                                   out_prb_data_q <= "0000000" & buf_prb_data(4)(16 downto 8);
                    when x"8"   => out_prb_data_i <= "0000000" & buf_prb_data(5)(7 downto 0)  & buf_prb_data(4)(31 downto 31);
                                   out_prb_data_q <= "0000000" & buf_prb_data(4)(30 downto 22);
                    when x"9"   => out_prb_data_i <= "0000000" & buf_prb_data(5)(21 downto 13);
                                   out_prb_data_q <= "0000000" & buf_prb_data(5)(12 downto 4);
                    when x"A"   => out_prb_data_i <= "0000000" & buf_prb_data(6)(3 downto 0)  & buf_prb_data(5)(31 downto 27);
                                   out_prb_data_q <= "0000000" & buf_prb_data(5)(26 downto 18);
                    when x"B"   => out_prb_data_i <= "0000000" & buf_prb_data(6)(17 downto 9);
                                   out_prb_data_q <= "0000000" & buf_prb_data(6)(8 downto 0);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (COMP_8B = true) and (iq_width = 8) then                  -- Comp +  8bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "00000000" & buf_prb_data(1)(23 downto 16);
                                   out_prb_data_q <= "00000000" & buf_prb_data(1)(15 downto 8);
                    when x"1"   => out_prb_data_i <= "00000000" & buf_prb_data(2)(7 downto 0);
                                   out_prb_data_q <= "00000000" & buf_prb_data(1)(31 downto 24);
                    when x"2"   => out_prb_data_i <= "00000000" & buf_prb_data(2)(23 downto 16);
                                   out_prb_data_q <= "00000000" & buf_prb_data(2)(15 downto 8);
                    when x"3"   => out_prb_data_i <= "00000000" & buf_prb_data(3)(7 downto 0);
                                   out_prb_data_q <= "00000000" & buf_prb_data(2)(31 downto 24);
                    when x"4"   => out_prb_data_i <= "00000000" & buf_prb_data(3)(23 downto 16);
                                   out_prb_data_q <= "00000000" & buf_prb_data(3)(15 downto 8);
                    when x"5"   => out_prb_data_i <= "00000000" & buf_prb_data(4)(7 downto 0);
                                   out_prb_data_q <= "00000000" & buf_prb_data(3)(31 downto 24);
                    when x"6"   => out_prb_data_i <= "00000000" & buf_prb_data(4)(23 downto 16);
                                   out_prb_data_q <= "00000000" & buf_prb_data(4)(15 downto 8);
                    when x"7"   => out_prb_data_i <= "00000000" & buf_prb_data(5)(7 downto 0);
                                   out_prb_data_q <= "00000000" & buf_prb_data(4)(31 downto 24);
                    when x"8"   => out_prb_data_i <= "00000000" & buf_prb_data(5)(23 downto 16);
                                   out_prb_data_q <= "00000000" & buf_prb_data(5)(15 downto 8);
                    when x"9"   => out_prb_data_i <= "00000000" & buf_prb_data(6)(7 downto 0);
                                   out_prb_data_q <= "00000000" & buf_prb_data(5)(31 downto 24);
                    when x"A"   => out_prb_data_i <= "00000000" & buf_prb_data(6)(23 downto 16);
                                   out_prb_data_q <= "00000000" & buf_prb_data(6)(15 downto 8);
                    when x"B"   => out_prb_data_i <= "00000000" & buf_prb_data(7)(7 downto 0);
                                   out_prb_data_q <= "00000000" & buf_prb_data(6)(31 downto 24);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (COMP_7B = true) and (iq_width = 7) then                  -- Comp +  7bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "000000000" & buf_prb_data(1)(23 downto 17);
                                   out_prb_data_q <= "000000000" & buf_prb_data(1)(16 downto 10);
                    when x"1"   => out_prb_data_i <= "000000000" & buf_prb_data(2)(9 downto 3);
                                   out_prb_data_q <= "000000000" & buf_prb_data(2)(2 downto 0)   & buf_prb_data(1)(31 downto 28);
                    when x"2"   => out_prb_data_i <= "000000000" & buf_prb_data(2)(27 downto 21);
                                   out_prb_data_q <= "000000000" & buf_prb_data(2)(20 downto 14);
                    when x"3"   => out_prb_data_i <= "000000000" & buf_prb_data(3)(13 downto 7);
                                   out_prb_data_q <= "000000000" & buf_prb_data(3)(6 downto 0);
                    when x"4"   => out_prb_data_i <= "000000000" & buf_prb_data(3)(31 downto 25);
                                   out_prb_data_q <= "000000000" & buf_prb_data(3)(24 downto 18);
                    when x"5"   => out_prb_data_i <= "000000000" & buf_prb_data(4)(17 downto 11);
                                   out_prb_data_q <= "000000000" & buf_prb_data(4)(10 downto 4);
                    when x"6"   => out_prb_data_i <= "000000000" & buf_prb_data(5)(3 downto 0)   & buf_prb_data(4)(31 downto 29);
                                   out_prb_data_q <= "000000000" & buf_prb_data(4)(28 downto 22);
                    when x"7"   => out_prb_data_i <= "000000000" & buf_prb_data(5)(21 downto 15);
                                   out_prb_data_q <= "000000000" & buf_prb_data(5)(14 downto 8);
                    when x"8"   => out_prb_data_i <= "000000000" & buf_prb_data(6)(7 downto 1);
                                   out_prb_data_q <= "000000000" & buf_prb_data(6)(0 downto 0)   & buf_prb_data(5)(31 downto 26);
                    when x"9"   => out_prb_data_i <= "000000000" & buf_prb_data(6)(25 downto 19);
                                   out_prb_data_q <= "000000000" & buf_prb_data(6)(18 downto 12);
                    when x"A"   => out_prb_data_i <= "000000000" & buf_prb_data(7)(11 downto 5);
                                   out_prb_data_q <= "000000000" & buf_prb_data(7)(4 downto 0)   & buf_prb_data(6)(31 downto 30);
                    when x"B"   => out_prb_data_i <= "000000000" & buf_prb_data(7)(29 downto 23);
                                   out_prb_data_q <= "000000000" & buf_prb_data(7)(22 downto 16);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (COMP_6B = true) and (iq_width = 6) then                  -- Comp +  6bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "0000000000" & buf_prb_data(1)(23 downto 18);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(1)(17 downto 12);
                    when x"1"   => out_prb_data_i <= "0000000000" & buf_prb_data(2)(11 downto 6);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(2)(5 downto 0);
                    when x"2"   => out_prb_data_i <= "0000000000" & buf_prb_data(2)(31 downto 26);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(2)(25 downto 20);
                    when x"3"   => out_prb_data_i <= "0000000000" & buf_prb_data(3)(19 downto 14);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(3)(13 downto 8);
                    when x"4"   => out_prb_data_i <= "0000000000" & buf_prb_data(4)(7 downto 2);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(4)(1 downto 0)   & buf_prb_data(3)(31 downto 28);
                    when x"5"   => out_prb_data_i <= "0000000000" & buf_prb_data(4)(27 downto 22);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(4)(21 downto 16);
                    when x"6"   => out_prb_data_i <= "0000000000" & buf_prb_data(5)(15 downto 10);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(5)(9 downto 4);
                    when x"7"   => out_prb_data_i <= "0000000000" & buf_prb_data(6)(3 downto 0)   & buf_prb_data(5)(31 downto 30);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(5)(29 downto 24);
                    when x"8"   => out_prb_data_i <= "0000000000" & buf_prb_data(6)(23 downto 18);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(6)(17 downto 12);
                    when x"9"   => out_prb_data_i <= "0000000000" & buf_prb_data(7)(11 downto 6);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(7)(5 downto 0);
                    when x"A"   => out_prb_data_i <= "0000000000" & buf_prb_data(7)(31 downto 26);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(7)(25 downto 20);
                    when x"B"   => out_prb_data_i <= "0000000000" & buf_prb_data(8)(19 downto 14);
                                   out_prb_data_q <= "0000000000" & buf_prb_data(8)(13 downto 8);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (COMP_5B = true) and (iq_width = 5) then                  -- Comp +  5bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "00000000000" & buf_prb_data(1)(23 downto 19);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(1)(18 downto 14);
                    when x"1"   => out_prb_data_i <= "00000000000" & buf_prb_data(2)(13 downto 9);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(2)(8 downto 4);
                    when x"2"   => out_prb_data_i <= "00000000000" & buf_prb_data(3)(3 downto 0)   & buf_prb_data(2)(31 downto 31);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(2)(30 downto 26);
                    when x"3"   => out_prb_data_i <= "00000000000" & buf_prb_data(3)(25 downto 21);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(3)(20 downto 16);
                    when x"4"   => out_prb_data_i <= "00000000000" & buf_prb_data(4)(15 downto 11);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(4)(10 downto 6);
                    when x"5"   => out_prb_data_i <= "00000000000" & buf_prb_data(5)(5 downto 1);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(5)(0 downto 0)   & buf_prb_data(4)(31 downto 28);
                    when x"6"   => out_prb_data_i <= "00000000000" & buf_prb_data(5)(27 downto 23);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(5)(22 downto 18);
                    when x"7"   => out_prb_data_i <= "00000000000" & buf_prb_data(6)(17 downto 13);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(6)(12 downto 8);
                    when x"8"   => out_prb_data_i <= "00000000000" & buf_prb_data(7)(7 downto 3);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(7)(2 downto 0)   & buf_prb_data(6)(31 downto 30);
                    when x"9"   => out_prb_data_i <= "00000000000" & buf_prb_data(7)(29 downto 25);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(7)(24 downto 20);
                    when x"A"   => out_prb_data_i <= "00000000000" & buf_prb_data(8)(19 downto 15);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(8)(14 downto 10);
                    when x"B"   => out_prb_data_i <= "00000000000" & buf_prb_data(9)(9 downto 5);
                                   out_prb_data_q <= "00000000000" & buf_prb_data(9)(4 downto 0);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (COMP_4B = true) and (iq_width = 4) then                  -- Comp +  4bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "000000000000" & buf_prb_data(1)(23 downto 20);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(1)(19 downto 16);
                    when x"1"   => out_prb_data_i <= "000000000000" & buf_prb_data(2)(15 downto 12);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(2)(11 downto 8);
                    when x"2"   => out_prb_data_i <= "000000000000" & buf_prb_data(3)(7 downto 4);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(3)(3 downto 0);
                    when x"3"   => out_prb_data_i <= "000000000000" & buf_prb_data(3)(31 downto 28);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(3)(27 downto 24);
                    when x"4"   => out_prb_data_i <= "000000000000" & buf_prb_data(4)(23 downto 20);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(4)(19 downto 16);
                    when x"5"   => out_prb_data_i <= "000000000000" & buf_prb_data(5)(15 downto 12);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(5)(11 downto 8);
                    when x"6"   => out_prb_data_i <= "000000000000" & buf_prb_data(6)(7 downto 4);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(6)(3 downto 0);
                    when x"7"   => out_prb_data_i <= "000000000000" & buf_prb_data(6)(31 downto 28);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(6)(27 downto 24);
                    when x"8"   => out_prb_data_i <= "000000000000" & buf_prb_data(7)(23 downto 20);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(7)(19 downto 16);
                    when x"9"   => out_prb_data_i <= "000000000000" & buf_prb_data(8)(15 downto 12);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(8)(11 downto 8);
                    when x"A"   => out_prb_data_i <= "000000000000" & buf_prb_data(9)(7 downto 4);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(9)(3 downto 0);
                    when x"B"   => out_prb_data_i <= "000000000000" & buf_prb_data(9)(31 downto 28);
                                   out_prb_data_q <= "000000000000" & buf_prb_data(9)(27 downto 24);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                elsif (COMP_3B = true) and (iq_width = 3) then                  -- Comp +  3bits
                    case cnt is
                    when x"0"   => out_prb_data_i <= "0000000000000" & buf_prb_data(1)(23 downto 21);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(1)(20 downto 18);
                    when x"1"   => out_prb_data_i <= "0000000000000" & buf_prb_data(2)(17 downto 15);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(2)(14 downto 12);
                    when x"2"   => out_prb_data_i <= "0000000000000" & buf_prb_data(3)(11 downto 9);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(3)(8 downto 6);
                    when x"3"   => out_prb_data_i <= "0000000000000" & buf_prb_data(4)(5 downto 3);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(4)(2 downto 0);
                    when x"4"   => out_prb_data_i <= "0000000000000" & buf_prb_data(4)(31 downto 29);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(4)(28 downto 26);
                    when x"5"   => out_prb_data_i <= "0000000000000" & buf_prb_data(5)(25 downto 23);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(5)(22 downto 20);
                    when x"6"   => out_prb_data_i <= "0000000000000" & buf_prb_data(6)(19 downto 17);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(6)(16 downto 14);
                    when x"7"   => out_prb_data_i <= "0000000000000" & buf_prb_data(7)(13 downto 11);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(7)(10 downto 8);
                    when x"8"   => out_prb_data_i <= "0000000000000" & buf_prb_data(8)(7 downto 5);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(8)(4 downto 2);
                    when x"9"   => out_prb_data_i <= "0000000000000" & buf_prb_data(9)(1 downto 0)    & buf_prb_data(8)(31 downto 31);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(8)(30 downto 28);
                    when x"A"   => out_prb_data_i <= "0000000000000" & buf_prb_data(9)(27 downto 25);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(9)(24 downto 22);
                    when x"B"   => out_prb_data_i <= "0000000000000" & buf_prb_data(10)(21 downto 19);
                                   out_prb_data_q <= "0000000000000" & buf_prb_data(10)(18 downto 16);
                    when others => out_prb_data_i <= (others => '0');
                                   out_prb_data_q <= (others => '0');
                    end case;
                else
                    out_prb_data_i <= (others => '0');
                    out_prb_data_q <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    process (RST, CLK)
    begin
        if (RST = '1') then
            COMP_HDR   <= (others => '0');
            COMP_PARAM <= (others => '0');
            COMP_USER  <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (out_prb_tick = '1') then
                COMP_HDR   <= iq_width & comp_method;
                COMP_PARAM <= out_prb_param;
                COMP_USER  <= buf_prb_user;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            COMP_VALID <= out_prb_valid;
            COMP_TICK  <= out_prb_tick;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (UNCOMP_16B = true or COMP_16B = true) and (iq_width = 0) then
                COMP_DATA_I <= out_prb_data_i(15 downto 0);
                COMP_DATA_Q <= out_prb_data_q(15 downto 0);
            elsif (UNCOMP_15B = true or COMP_15B = true) and (iq_width = 15) then
                COMP_DATA_I <= out_prb_data_i(14) & out_prb_data_i(14 downto 0);
                COMP_DATA_Q <= out_prb_data_q(14) & out_prb_data_q(14 downto 0);
            elsif (UNCOMP_14B = true or COMP_14B = true) and (iq_width = 14) then
                COMP_DATA_I <= out_prb_data_i(13) & out_prb_data_i(13) & out_prb_data_i(13 downto 0);
                COMP_DATA_Q <= out_prb_data_q(13) & out_prb_data_q(13) & out_prb_data_q(13 downto 0);
            elsif (UNCOMP_13B = true or COMP_13B = true) and (iq_width = 13) then
                COMP_DATA_I <= out_prb_data_i(12) & out_prb_data_i(12) & out_prb_data_i(12) & out_prb_data_i(12 downto 0);
                COMP_DATA_Q <= out_prb_data_q(12) & out_prb_data_q(12) & out_prb_data_q(12) & out_prb_data_q(12 downto 0);
            elsif (UNCOMP_12B = true or COMP_12B = true) and (iq_width = 12) then
                COMP_DATA_I <= out_prb_data_i(11) & out_prb_data_i(11) & out_prb_data_i(11) & out_prb_data_i(11) & out_prb_data_i(11 downto 0);
                COMP_DATA_Q <= out_prb_data_q(11) & out_prb_data_q(11) & out_prb_data_q(11) & out_prb_data_q(11) & out_prb_data_q(11 downto 0);
            elsif (UNCOMP_11B = true or COMP_11B = true) and (iq_width = 11) then
                COMP_DATA_I <= out_prb_data_i(10) & out_prb_data_i(10) & out_prb_data_i(10) & out_prb_data_i(10) & out_prb_data_i(10) & out_prb_data_i(10 downto 0);
                COMP_DATA_Q <= out_prb_data_q(10) & out_prb_data_q(10) & out_prb_data_q(10) & out_prb_data_q(10) & out_prb_data_q(10) & out_prb_data_q(10 downto 0);
            elsif (UNCOMP_10B = true or COMP_10B = true) and (iq_width = 10) then
                COMP_DATA_I <= out_prb_data_i(9)  & out_prb_data_i(9)  & out_prb_data_i(9)  & out_prb_data_i(9)  & out_prb_data_i(9)  & out_prb_data_i(9)  & out_prb_data_i(9 downto 0);
                COMP_DATA_Q <= out_prb_data_q(9)  & out_prb_data_q(9)  & out_prb_data_q(9)  & out_prb_data_q(9)  & out_prb_data_q(9)  & out_prb_data_q(9)  & out_prb_data_q(9 downto 0);
            elsif (UNCOMP_9B = true or COMP_9B = true) and (iq_width = 9) then
                COMP_DATA_I <= out_prb_data_i(8)  & out_prb_data_i(8)  & out_prb_data_i(8)  & out_prb_data_i(8)  & out_prb_data_i(8)  & out_prb_data_i(8)  & out_prb_data_i(8)  & out_prb_data_i(8 downto 0);
                COMP_DATA_Q <= out_prb_data_q(8)  & out_prb_data_q(8)  & out_prb_data_q(8)  & out_prb_data_q(8)  & out_prb_data_q(8)  & out_prb_data_q(8)  & out_prb_data_q(8)  & out_prb_data_q(8 downto 0);
            elsif (UNCOMP_8B = true or COMP_8B = true) and (iq_width = 8) then
                COMP_DATA_I <= out_prb_data_i(7)  & out_prb_data_i(7)  & out_prb_data_i(7)  & out_prb_data_i(7)  & out_prb_data_i(7)  & out_prb_data_i(7)  & out_prb_data_i(7)  & out_prb_data_i(7)  & out_prb_data_i(7 downto 0);
                COMP_DATA_Q <= out_prb_data_q(7)  & out_prb_data_q(7)  & out_prb_data_q(7)  & out_prb_data_q(7)  & out_prb_data_q(7)  & out_prb_data_q(7)  & out_prb_data_q(7)  & out_prb_data_q(7)  & out_prb_data_q(7 downto 0);
            elsif (UNCOMP_7B = true or COMP_7B = true) and (iq_width = 7) then
                COMP_DATA_I <= out_prb_data_i(6)  & out_prb_data_i(6)  & out_prb_data_i(6)  & out_prb_data_i(6)  & out_prb_data_i(6)  & out_prb_data_i(6)  & out_prb_data_i(6)  & out_prb_data_i(6)  & out_prb_data_i(6)  & out_prb_data_i(6 downto 0);
                COMP_DATA_Q <= out_prb_data_q(6)  & out_prb_data_q(6)  & out_prb_data_q(6)  & out_prb_data_q(6)  & out_prb_data_q(6)  & out_prb_data_q(6)  & out_prb_data_q(6)  & out_prb_data_q(6)  & out_prb_data_q(6)  & out_prb_data_q(6 downto 0);
            elsif (UNCOMP_6B = true or COMP_6B = true) and (iq_width = 6) then
                COMP_DATA_I <= out_prb_data_i(5)  & out_prb_data_i(5)  & out_prb_data_i(5)  & out_prb_data_i(5)  & out_prb_data_i(5)  & out_prb_data_i(5)  & out_prb_data_i(5)  & out_prb_data_i(5)  & out_prb_data_i(5)  & out_prb_data_i(5)  & out_prb_data_i(5 downto 0);
                COMP_DATA_Q <= out_prb_data_q(5)  & out_prb_data_q(5)  & out_prb_data_q(5)  & out_prb_data_q(5)  & out_prb_data_q(5)  & out_prb_data_q(5)  & out_prb_data_q(5)  & out_prb_data_q(5)  & out_prb_data_q(5)  & out_prb_data_q(5)  & out_prb_data_q(5 downto 0);
            elsif (UNCOMP_5B = true or COMP_5B = true) and (iq_width = 5) then
                COMP_DATA_I <= out_prb_data_i(4)  & out_prb_data_i(4)  & out_prb_data_i(4)  & out_prb_data_i(4)  & out_prb_data_i(4)  & out_prb_data_i(4)  & out_prb_data_i(4)  & out_prb_data_i(4)  & out_prb_data_i(4)  & out_prb_data_i(4)  & out_prb_data_i(4)  & out_prb_data_i(4 downto 0);
                COMP_DATA_Q <= out_prb_data_q(4)  & out_prb_data_q(4)  & out_prb_data_q(4)  & out_prb_data_q(4)  & out_prb_data_q(4)  & out_prb_data_q(4)  & out_prb_data_q(4)  & out_prb_data_q(4)  & out_prb_data_q(4)  & out_prb_data_q(4)  & out_prb_data_q(4)  & out_prb_data_q(4 downto 0);
            elsif (UNCOMP_4B = true or COMP_4B = true) and (iq_width = 4) then
                COMP_DATA_I <= out_prb_data_i(3)  & out_prb_data_i(3)  & out_prb_data_i(3)  & out_prb_data_i(3)  & out_prb_data_i(3)  & out_prb_data_i(3)  & out_prb_data_i(3)  & out_prb_data_i(3)  & out_prb_data_i(3)  & out_prb_data_i(3)  & out_prb_data_i(3)  & out_prb_data_i(3)  & out_prb_data_i(3 downto 0);
                COMP_DATA_Q <= out_prb_data_q(3)  & out_prb_data_q(3)  & out_prb_data_q(3)  & out_prb_data_q(3)  & out_prb_data_q(3)  & out_prb_data_q(3)  & out_prb_data_q(3)  & out_prb_data_q(3)  & out_prb_data_q(3)  & out_prb_data_q(3)  & out_prb_data_q(3)  & out_prb_data_q(3)  & out_prb_data_q(3 downto 0);
            elsif (UNCOMP_3B = true or COMP_3B = true) and (iq_width = 3) then
                COMP_DATA_I <= out_prb_data_i(2)  & out_prb_data_i(2)  & out_prb_data_i(2)  & out_prb_data_i(2)  & out_prb_data_i(2)  & out_prb_data_i(2)  & out_prb_data_i(2)  & out_prb_data_i(2)  & out_prb_data_i(2)  & out_prb_data_i(2)  & out_prb_data_i(2)  & out_prb_data_i(2)  & out_prb_data_i(2)  & out_prb_data_i(2 downto 0);
                COMP_DATA_Q <= out_prb_data_q(2)  & out_prb_data_q(2)  & out_prb_data_q(2)  & out_prb_data_q(2)  & out_prb_data_q(2)  & out_prb_data_q(2)  & out_prb_data_q(2)  & out_prb_data_q(2)  & out_prb_data_q(2)  & out_prb_data_q(2)  & out_prb_data_q(2)  & out_prb_data_q(2)  & out_prb_data_q(2)  & out_prb_data_q(2 downto 0);
            end if;
        end if;
    end process;

end BEHAVE;