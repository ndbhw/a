--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : Calculate the length of 1-PRB (O-RAN component)               --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.15                                                    --
--                                                                            --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PRB_LENGTH is
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
-- Control
--------------------------------------------------------------------------------

        IQ_WIDTH                    : in  std_logic_vector(3 downto 0);
        COMP_METHOD                 : in  std_logic_vector(3 downto 0);

--------------------------------------------------------------------------------
-- Length
--------------------------------------------------------------------------------

        QUOTIENT                    : out std_logic_vector(3 downto 0);
        REMAINDER                   : out std_logic_vector(1 downto 0)
    );
end PRB_LENGTH;

architecture BEHAVE of PRB_LENGTH is

begin

    process (COMP_METHOD, IQ_WIDTH)
    begin
        if (COMP_METHOD(1 downto 0) = "00") then
            if    (UNCOMP_16B = true) and (IQ_WIDTH = "0000") then              QUOTIENT  <= "1011";
                                                                                REMAINDER <= "00";
            elsif (UNCOMP_15B = true) and (IQ_WIDTH = "1111") then              QUOTIENT  <= "1010";
                                                                                REMAINDER <= "01";
            elsif (UNCOMP_14B = true) and (IQ_WIDTH = "1110") then              QUOTIENT  <= "1001";
                                                                                REMAINDER <= "10";
            elsif (UNCOMP_13B = true) and (IQ_WIDTH = "1101") then              QUOTIENT  <= "1000";
                                                                                REMAINDER <= "11";
            elsif (UNCOMP_12B = true) and (IQ_WIDTH = "1100") then              QUOTIENT  <= "1000";
                                                                                REMAINDER <= "00";
            elsif (UNCOMP_11B = true) and (IQ_WIDTH = "1011") then              QUOTIENT  <= "0111";
                                                                                REMAINDER <= "01";
            elsif (UNCOMP_10B = true) and (IQ_WIDTH = "1010") then              QUOTIENT  <= "0110";
                                                                                REMAINDER <= "10";
            elsif (UNCOMP_9B = true)  and (IQ_WIDTH = "1001") then              QUOTIENT  <= "0101";
                                                                                REMAINDER <= "11";
            elsif (UNCOMP_8B = true)  and (IQ_WIDTH = "1000") then              QUOTIENT  <= "0101";
                                                                                REMAINDER <= "00";
            elsif (UNCOMP_7B = true)  and (IQ_WIDTH = "0111") then              QUOTIENT  <= "0100";
                                                                                REMAINDER <= "01";
            elsif (UNCOMP_6B = true)  and (IQ_WIDTH = "0110") then              QUOTIENT  <= "0011";
                                                                                REMAINDER <= "10";
            elsif (UNCOMP_5B = true)  and (IQ_WIDTH = "0101") then              QUOTIENT  <= "0010";
                                                                                REMAINDER <= "11";
            elsif (UNCOMP_4B = true)  and (IQ_WIDTH = "0100") then              QUOTIENT  <= "0010";
                                                                                REMAINDER <= "00";
            elsif (UNCOMP_3B = true)  and (IQ_WIDTH = "0011") then              QUOTIENT  <= "0001";
                                                                                REMAINDER <= "01";
            else                                                                QUOTIENT  <= (others => '0');
                                                                                REMAINDER <= (others => '0');
            end if;
        else
            if    (COMP_15B = true) and (IQ_WIDTH = "1111") then                QUOTIENT  <= "1010";
                                                                                REMAINDER <= "10";
            elsif (COMP_14B = true) and (IQ_WIDTH = "1110") then                QUOTIENT  <= "1001";
                                                                                REMAINDER <= "11";
            elsif (COMP_13B = true) and (IQ_WIDTH = "1101") then                QUOTIENT  <= "1001";
                                                                                REMAINDER <= "00";
            elsif (COMP_12B = true) and (IQ_WIDTH = "1100") then                QUOTIENT  <= "1000";
                                                                                REMAINDER <= "01";
            elsif (COMP_11B = true) and (IQ_WIDTH = "1011") then                QUOTIENT  <= "0111";
                                                                                REMAINDER <= "10";
            elsif (COMP_10B = true) and (IQ_WIDTH = "1010") then                QUOTIENT  <= "0110";
                                                                                REMAINDER <= "11";
            elsif (COMP_9B = true)  and (IQ_WIDTH = "1001") then                QUOTIENT  <= "0110";
                                                                                REMAINDER <= "00";
            elsif (COMP_8B = true)  and (IQ_WIDTH = "1000") then                QUOTIENT  <= "0101";
                                                                                REMAINDER <= "01";
            elsif (COMP_7B = true)  and (IQ_WIDTH = "0111") then                QUOTIENT  <= "0100";
                                                                                REMAINDER <= "10";
            elsif (COMP_6B = true)  and (IQ_WIDTH = "0110") then                QUOTIENT  <= "0011";
                                                                                REMAINDER <= "11";
            elsif (COMP_5B = true)  and (IQ_WIDTH = "0101") then                QUOTIENT  <= "0011";
                                                                                REMAINDER <= "00";
            elsif (COMP_4B = true)  and (IQ_WIDTH = "0100") then                QUOTIENT  <= "0010";
                                                                                REMAINDER <= "01";
            elsif (COMP_3B = true)  and (IQ_WIDTH = "0011") then                QUOTIENT  <= "0001";
                                                                                REMAINDER <= "10";
            else                                                                QUOTIENT  <= (others => '0');
                                                                                REMAINDER <= (others => '0');
            end if;
        end if;
    end process;

end BEHAVE;