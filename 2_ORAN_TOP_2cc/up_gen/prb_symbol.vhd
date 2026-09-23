--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : Calculate symbol position C-Plane (O-RAN component)           --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.15                                                    --
--                                                                            --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity PRB_SYMBOL is
    port (
--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------

        START_SYMBOL_ID             : in  std_logic_vector(3 downto 0);
        NUM_OF_SYMBOL               : in  std_logic_vector(3 downto 0);

--------------------------------------------------------------------------------
-- Index
--------------------------------------------------------------------------------

        INDEX                       : out std_logic_vector(13 downto 0)
    );
end PRB_SYMBOL;

architecture BEHAVE of PRB_SYMBOL is

begin

    process (START_SYMBOL_ID, NUM_OF_SYMBOL)
    begin
        if    (START_SYMBOL_ID = 0) then
            if    (NUM_OF_SYMBOL = 1)  then                                     INDEX <= "00000000000001";
            elsif (NUM_OF_SYMBOL = 2)  then                                     INDEX <= "00000000000011";
            elsif (NUM_OF_SYMBOL = 3)  then                                     INDEX <= "00000000000111";
            elsif (NUM_OF_SYMBOL = 4)  then                                     INDEX <= "00000000001111";
            elsif (NUM_OF_SYMBOL = 5)  then                                     INDEX <= "00000000011111";
            elsif (NUM_OF_SYMBOL = 6)  then                                     INDEX <= "00000000111111";
            elsif (NUM_OF_SYMBOL = 7)  then                                     INDEX <= "00000001111111";
            elsif (NUM_OF_SYMBOL = 8)  then                                     INDEX <= "00000011111111";
            elsif (NUM_OF_SYMBOL = 9)  then                                     INDEX <= "00000111111111";
            elsif (NUM_OF_SYMBOL = 10) then                                     INDEX <= "00001111111111";
            elsif (NUM_OF_SYMBOL = 11) then                                     INDEX <= "00011111111111";
            elsif (NUM_OF_SYMBOL = 12) then                                     INDEX <= "00111111111111";
            elsif (NUM_OF_SYMBOL = 13) then                                     INDEX <= "01111111111111";
            else                                                                INDEX <= "11111111111111";
            end if;
        elsif (START_SYMBOL_ID = 1) then
            if    (NUM_OF_SYMBOL = 1)  then                                     INDEX <= "00000000000010";
            elsif (NUM_OF_SYMBOL = 2)  then                                     INDEX <= "00000000000110";
            elsif (NUM_OF_SYMBOL = 3)  then                                     INDEX <= "00000000001110";
            elsif (NUM_OF_SYMBOL = 4)  then                                     INDEX <= "00000000011110";
            elsif (NUM_OF_SYMBOL = 5)  then                                     INDEX <= "00000000111110";
            elsif (NUM_OF_SYMBOL = 6)  then                                     INDEX <= "00000001111110";
            elsif (NUM_OF_SYMBOL = 7)  then                                     INDEX <= "00000011111110";
            elsif (NUM_OF_SYMBOL = 8)  then                                     INDEX <= "00000111111110";
            elsif (NUM_OF_SYMBOL = 9)  then                                     INDEX <= "00001111111110";
            elsif (NUM_OF_SYMBOL = 10) then                                     INDEX <= "00011111111110";
            elsif (NUM_OF_SYMBOL = 11) then                                     INDEX <= "00111111111110";
            elsif (NUM_OF_SYMBOL = 12) then                                     INDEX <= "01111111111110";
            else                                                                INDEX <= "11111111111110";
            end if;
        elsif (START_SYMBOL_ID = 2) then
            if    (NUM_OF_SYMBOL = 1)  then                                     INDEX <= "00000000000100";
            elsif (NUM_OF_SYMBOL = 2)  then                                     INDEX <= "00000000001100";
            elsif (NUM_OF_SYMBOL = 3)  then                                     INDEX <= "00000000011100";
            elsif (NUM_OF_SYMBOL = 4)  then                                     INDEX <= "00000000111100";
            elsif (NUM_OF_SYMBOL = 5)  then                                     INDEX <= "00000001111100";
            elsif (NUM_OF_SYMBOL = 6)  then                                     INDEX <= "00000011111100";
            elsif (NUM_OF_SYMBOL = 7)  then                                     INDEX <= "00000111111100";
            elsif (NUM_OF_SYMBOL = 8)  then                                     INDEX <= "00001111111100";
            elsif (NUM_OF_SYMBOL = 9)  then                                     INDEX <= "00011111111100";
            elsif (NUM_OF_SYMBOL = 10) then                                     INDEX <= "00111111111100";
            elsif (NUM_OF_SYMBOL = 11) then                                     INDEX <= "01111111111100";
            else                                                                INDEX <= "11111111111100";
            end if;
        elsif (START_SYMBOL_ID = 3) then
            if    (NUM_OF_SYMBOL = 1)  then                                     INDEX <= "00000000001000";
            elsif (NUM_OF_SYMBOL = 2)  then                                     INDEX <= "00000000011000";
            elsif (NUM_OF_SYMBOL = 3)  then                                     INDEX <= "00000000111000";
            elsif (NUM_OF_SYMBOL = 4)  then                                     INDEX <= "00000001111000";
            elsif (NUM_OF_SYMBOL = 5)  then                                     INDEX <= "00000011111000";
            elsif (NUM_OF_SYMBOL = 6)  then                                     INDEX <= "00000111111000";
            elsif (NUM_OF_SYMBOL = 7)  then                                     INDEX <= "00001111111000";
            elsif (NUM_OF_SYMBOL = 8)  then                                     INDEX <= "00011111111000";
            elsif (NUM_OF_SYMBOL = 9)  then                                     INDEX <= "00111111111000";
            elsif (NUM_OF_SYMBOL = 10) then                                     INDEX <= "01111111111000";
            else                                                                INDEX <= "11111111111000";
            end if;
        elsif (START_SYMBOL_ID = 4) then
            if    (NUM_OF_SYMBOL = 1)  then                                     INDEX <= "00000000010000";
            elsif (NUM_OF_SYMBOL = 2)  then                                     INDEX <= "00000000110000";
            elsif (NUM_OF_SYMBOL = 3)  then                                     INDEX <= "00000001110000";
            elsif (NUM_OF_SYMBOL = 4)  then                                     INDEX <= "00000011110000";
            elsif (NUM_OF_SYMBOL = 5)  then                                     INDEX <= "00000111110000";
            elsif (NUM_OF_SYMBOL = 6)  then                                     INDEX <= "00001111110000";
            elsif (NUM_OF_SYMBOL = 7)  then                                     INDEX <= "00011111110000";
            elsif (NUM_OF_SYMBOL = 8)  then                                     INDEX <= "00111111110000";
            elsif (NUM_OF_SYMBOL = 9)  then                                     INDEX <= "01111111110000";
            else                                                                INDEX <= "11111111110000";
            end if;
        elsif (START_SYMBOL_ID = 5) then
            if    (NUM_OF_SYMBOL = 1)  then                                     INDEX <= "00000000100000";
            elsif (NUM_OF_SYMBOL = 2)  then                                     INDEX <= "00000001100000";
            elsif (NUM_OF_SYMBOL = 3)  then                                     INDEX <= "00000011100000";
            elsif (NUM_OF_SYMBOL = 4)  then                                     INDEX <= "00000111100000";
            elsif (NUM_OF_SYMBOL = 5)  then                                     INDEX <= "00001111100000";
            elsif (NUM_OF_SYMBOL = 6)  then                                     INDEX <= "00011111100000";
            elsif (NUM_OF_SYMBOL = 7)  then                                     INDEX <= "00111111100000";
            elsif (NUM_OF_SYMBOL = 8)  then                                     INDEX <= "01111111100000";
            else                                                                INDEX <= "11111111100000";
            end if;
        elsif (START_SYMBOL_ID = 6) then
            if    (NUM_OF_SYMBOL = 1)  then                                     INDEX <= "00000001000000";
            elsif (NUM_OF_SYMBOL = 2)  then                                     INDEX <= "00000011000000";
            elsif (NUM_OF_SYMBOL = 3)  then                                     INDEX <= "00000111000000";
            elsif (NUM_OF_SYMBOL = 4)  then                                     INDEX <= "00001111000000";
            elsif (NUM_OF_SYMBOL = 5)  then                                     INDEX <= "00011111000000";
            elsif (NUM_OF_SYMBOL = 6)  then                                     INDEX <= "00111111000000";
            elsif (NUM_OF_SYMBOL = 7)  then                                     INDEX <= "01111111000000";
            else                                                                INDEX <= "11111111000000";
            end if;
        elsif (START_SYMBOL_ID = 7) then
            if    (NUM_OF_SYMBOL = 1)  then                                     INDEX <= "00000010000000";
            elsif (NUM_OF_SYMBOL = 2)  then                                     INDEX <= "00000110000000";
            elsif (NUM_OF_SYMBOL = 3)  then                                     INDEX <= "00001110000000";
            elsif (NUM_OF_SYMBOL = 4)  then                                     INDEX <= "00011110000000";
            elsif (NUM_OF_SYMBOL = 5)  then                                     INDEX <= "00111110000000";
            elsif (NUM_OF_SYMBOL = 6)  then                                     INDEX <= "01111110000000";
            else                                                                INDEX <= "11111110000000";
            end if;
        elsif (START_SYMBOL_ID = 8) then
            if    (NUM_OF_SYMBOL = 1)  then                                     INDEX <= "00000100000000";
            elsif (NUM_OF_SYMBOL = 2)  then                                     INDEX <= "00001100000000";
            elsif (NUM_OF_SYMBOL = 3)  then                                     INDEX <= "00011100000000";
            elsif (NUM_OF_SYMBOL = 4)  then                                     INDEX <= "00111100000000";
            elsif (NUM_OF_SYMBOL = 5)  then                                     INDEX <= "01111100000000";
            else                                                                INDEX <= "11111100000000";
            end if;
        elsif (START_SYMBOL_ID = 9) then
            if    (NUM_OF_SYMBOL = 1)  then                                     INDEX <= "00001000000000";
            elsif (NUM_OF_SYMBOL = 2)  then                                     INDEX <= "00011000000000";
            elsif (NUM_OF_SYMBOL = 3)  then                                     INDEX <= "00111000000000";
            elsif (NUM_OF_SYMBOL = 4)  then                                     INDEX <= "01111000000000";
            else                                                                INDEX <= "11111000000000";
            end if;
        elsif (START_SYMBOL_ID = 10) then
            if    (NUM_OF_SYMBOL = 1)  then                                     INDEX <= "00010000000000";
            elsif (NUM_OF_SYMBOL = 2)  then                                     INDEX <= "00110000000000";
            elsif (NUM_OF_SYMBOL = 3)  then                                     INDEX <= "01110000000000";
            else                                                                INDEX <= "11110000000000";
            end if;
        elsif (START_SYMBOL_ID = 11) then
            if    (NUM_OF_SYMBOL = 1)  then                                     INDEX <= "00100000000000";
            elsif (NUM_OF_SYMBOL = 2)  then                                     INDEX <= "01100000000000";
            else                                                                INDEX <= "11100000000000";
            end if;
        elsif (START_SYMBOL_ID = 12) then
            if    (NUM_OF_SYMBOL = 1)  then                                     INDEX <= "01000000000000";
            else                                                                INDEX <= "11000000000000";
            end if;
        elsif (START_SYMBOL_ID = 13) then
                                                                                INDEX <= "10000000000000";
        else
            INDEX <= "00000000000000";
        end if;
    end process;

end BEHAVE;