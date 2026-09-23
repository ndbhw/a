--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : Convert from a number to bit enable (O-RAN component)         --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.20                                                    --
--                                                                            --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity NUM_TO_BIT is
    generic (
        MAX_NUM                     : natural := 8
    );
    port (
        NUM                         : in  std_logic_vector(2 downto 0);
        BIT                         : out std_logic_vector(7 downto 0)
    );
end NUM_TO_BIT;

architecture BEHAVE of NUM_TO_BIT is

begin

    u_MAX1 : if MAX_NUM = 1 generate
    process (NUM)
    begin
        if    (NUM = 0) then        BIT <= "00000001";
        else                        BIT <= "00000000";
        end if;
    end process;
    end generate;

    u_MAX2 : if MAX_NUM = 2 generate
    process (NUM)
    begin
        if    (NUM = 0) then        BIT <= "00000001";
        elsif (NUM = 1) then        BIT <= "00000010";
        else                        BIT <= "00000000";
        end if;
    end process;
    end generate;

    u_MAX3 : if MAX_NUM = 3 generate
    process (NUM)
    begin
        if    (NUM = 0) then        BIT <= "00000001";
        elsif (NUM = 1) then        BIT <= "00000010";
        elsif (NUM = 2) then        BIT <= "00000100";
        else                        BIT <= "00000000";
        end if;
    end process;
    end generate;

    u_MAX4 : if MAX_NUM = 4 generate
    process (NUM)
    begin
        if    (NUM = 0) then        BIT <= "00000001";
        elsif (NUM = 1) then        BIT <= "00000010";
        elsif (NUM = 2) then        BIT <= "00000100";
        elsif (NUM = 3) then        BIT <= "00001000";
        else                        BIT <= "00000000";
        end if;
    end process;
    end generate;

    u_MAX5 : if MAX_NUM = 5 generate
    process (NUM)
    begin
        if    (NUM = 0) then        BIT <= "00000001";
        elsif (NUM = 1) then        BIT <= "00000010";
        elsif (NUM = 2) then        BIT <= "00000100";
        elsif (NUM = 3) then        BIT <= "00001000";
        elsif (NUM = 4) then        BIT <= "00010000";
        else                        BIT <= "00000000";
        end if;
    end process;
    end generate;

    u_MAX6 : if MAX_NUM = 6 generate
    process (NUM)
    begin
        if    (NUM = 0) then        BIT <= "00000001";
        elsif (NUM = 1) then        BIT <= "00000010";
        elsif (NUM = 2) then        BIT <= "00000100";
        elsif (NUM = 3) then        BIT <= "00001000";
        elsif (NUM = 4) then        BIT <= "00010000";
        elsif (NUM = 5) then        BIT <= "00100000";
        else                        BIT <= "00000000";
        end if;
    end process;
    end generate;

    u_MAX7 : if MAX_NUM = 7 generate
    process (NUM)
    begin
        if    (NUM = 0) then        BIT <= "00000001";
        elsif (NUM = 1) then        BIT <= "00000010";
        elsif (NUM = 2) then        BIT <= "00000100";
        elsif (NUM = 3) then        BIT <= "00001000";
        elsif (NUM = 4) then        BIT <= "00010000";
        elsif (NUM = 5) then        BIT <= "00100000";
        elsif (NUM = 6) then        BIT <= "01000000";
        else                        BIT <= "00000000";
        end if;
    end process;
    end generate;

    u_MAX8 : if MAX_NUM = 8 generate
    process (NUM)
    begin
        if    (NUM = 1) then        BIT <= "00000010";
        elsif (NUM = 2) then        BIT <= "00000100";
        elsif (NUM = 3) then        BIT <= "00001000";
        elsif (NUM = 4) then        BIT <= "00010000";
        elsif (NUM = 5) then        BIT <= "00100000";
        elsif (NUM = 6) then        BIT <= "01000000";
        elsif (NUM = 7) then        BIT <= "10000000";
        else                        BIT <= "00000001";
        end if;
    end process;
    end generate;

end BEHAVE;