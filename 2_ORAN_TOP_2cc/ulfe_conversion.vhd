--------------------------------------------------------------------------------
--
-- Copyright (C) 2025, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Function   : ULFE to ORAN interface conversion
--
-- Author     : jaekyu.no (jaekyu.no@samsung.com)
-- Department : Hardware R&D Group (Network Division)
-- Target     : RF2221/22/25
-- Release    : 2025.03.18
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use WORK.ARRAY_TYPE.ALL;

entity ULFE_CONVERSION is
    port (
--------------------------------------------------------------------------------
-- Clock
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;

--------------------------------------------------------------------------------
-- Input
--------------------------------------------------------------------------------

        ULFE_RB_FRAME_ID_IN         : in  std_logic_vector(7 downto 0);
        ULFE_RB_SUBFRAME_ID_IN      : in  std_logic_vector(3 downto 0);
        ULFE_RB_SLOT_ID_IN          : in  std_logic_vector(5 downto 0);
        ULFE_RB_SYMBOL_ID_IN        : in  std_logic_vector(5 downto 0);
        ULFE_RB_START_RE_IN         : in  std_logic_vector(4*16-1 downto 0);

        ULFE_RB_VALID_IN            : in  std_logic_vector(4*1-1 downto 0);
        ULFE_RB_START_IN            : in  std_logic_vector(4*1-1 downto 0);
        ULFE_RB_LAST_IN             : in  std_logic_vector(4*1-1 downto 0);
        ULFE_RB_DATA_IN             : in  std_logic_vector(4*32-1 downto 0);

--------------------------------------------------------------------------------
-- Ouput
--------------------------------------------------------------------------------

        ULFE_RB_FRAME_ID_OUT        : out std_logic_vector(7 downto 0);
        ULFE_RB_SUBFRAME_ID_OUT     : out std_logic_vector(3 downto 0);
        ULFE_RB_SLOT_ID_OUT         : out std_logic_vector(5 downto 0);
        ULFE_RB_SYMBOL_ID_OUT       : out std_logic_vector(5 downto 0);

        ULFE_RB_VALID_OUT           : out std_logic_vector(7 downto 0);
        ULFE_RB_START_OUT           : out std_logic_vector(7 downto 0);
        ULFE_RB_LAST_OUT            : out std_logic_vector(7 downto 0);
        ULFE_RB_DATA_I_OUT          : out std_logic_array16(7 downto 0);
        ULFE_RB_DATA_Q_OUT          : out std_logic_array16(7 downto 0)
    );
end ULFE_CONVERSION;

architecture BEHAVE of ULFE_CONVERSION is



begin

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            ULFE_RB_FRAME_ID_OUT    <= ULFE_RB_FRAME_ID_IN;
            ULFE_RB_SUBFRAME_ID_OUT <= ULFE_RB_SUBFRAME_ID_IN;
            ULFE_RB_SLOT_ID_OUT     <= ULFE_RB_SLOT_ID_IN;
            ULFE_RB_SYMBOL_ID_OUT   <= ULFE_RB_SYMBOL_ID_IN;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            ULFE_RB_VALID_OUT       <= "0000" & ULFE_RB_VALID_IN;
            ULFE_RB_START_OUT       <= "0000" & ULFE_RB_START_IN;
            ULFE_RB_LAST_OUT        <= "0000" & ULFE_RB_LAST_IN;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            ULFE_RB_DATA_I_OUT(0)   <= ULFE_RB_DATA_IN(0*32+31 downto 0*32+16);
            ULFE_RB_DATA_Q_OUT(0)   <= ULFE_RB_DATA_IN(0*32+15 downto 0*32+0);
            ULFE_RB_DATA_I_OUT(1)   <= ULFE_RB_DATA_IN(1*32+31 downto 1*32+16);
            ULFE_RB_DATA_Q_OUT(1)   <= ULFE_RB_DATA_IN(1*32+15 downto 1*32+0);
            ULFE_RB_DATA_I_OUT(2)   <= ULFE_RB_DATA_IN(2*32+31 downto 2*32+16);
            ULFE_RB_DATA_Q_OUT(2)   <= ULFE_RB_DATA_IN(2*32+15 downto 2*32+0); 
            ULFE_RB_DATA_I_OUT(3)   <= ULFE_RB_DATA_IN(3*32+31 downto 3*32+16);
            ULFE_RB_DATA_Q_OUT(3)   <= ULFE_RB_DATA_IN(3*32+15 downto 3*32+0); 
            ULFE_RB_DATA_I_OUT(4)   <= (others => '0');
            ULFE_RB_DATA_Q_OUT(4)   <= (others => '0');
            ULFE_RB_DATA_I_OUT(5)   <= (others => '0');
            ULFE_RB_DATA_Q_OUT(5)   <= (others => '0');
            ULFE_RB_DATA_I_OUT(6)   <= (others => '0');
            ULFE_RB_DATA_Q_OUT(6)   <= (others => '0');
            ULFE_RB_DATA_I_OUT(7)   <= (others => '0');
            ULFE_RB_DATA_Q_OUT(7)   <= (others => '0');
        end if;
    end process;

end BEHAVE;