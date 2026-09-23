--------------------------------------------------------------------------------
--
-- Copyright (C) 2025, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Function   : RAFE to ORAN interface conversion
--
-- Author     : jaekyu.no (jaekyu.no@samsung.com)
-- Department : Hardware R&D Group (Network Division)
-- Target     : RF2221/22/25
-- Release    : 2025.03.18
--
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use WORK.ARRAY_TYPE.ALL;
use WORK.PKG_ORAN.ALL;

entity RAFE_CONVERSION is
    port (
--------------------------------------------------------------------------------
-- Clock
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;

--------------------------------------------------------------------------------
-- Input
--------------------------------------------------------------------------------

        RAFE_RB_FRAME_ID_IN         : in  std_logic_vector(7 downto 0);
        RAFE_RB_SUBFRAME_ID_IN      : in  std_logic_vector(3 downto 0);
        RAFE_RB_SLOT_ID_IN          : in  std_logic_vector(5 downto 0);
        RAFE_RB_SYMBOL_ID_IN        : in  std_logic_vector(5 downto 0);

        RAFE_RB_VALID_IN            : in  std_logic_vector(4*1-1 downto 0);
        RAFE_RB_START_IN            : in  std_logic_vector(4*1-1 downto 0);
        RAFE_RB_LAST_IN             : in  std_logic_vector(4*1-1 downto 0);
        RAFE_RB_DATA_IN             : in  std_logic_vector(4*32-1 downto 0);

--------------------------------------------------------------------------------
-- Ouput
--------------------------------------------------------------------------------

        RAFE_RB_FRAME_ID_OUT        : out std_logic_vector(7 downto 0);
        RAFE_RB_SUBFRAME_ID_OUT     : out std_logic_vector(3 downto 0);
        RAFE_RB_SLOT_ID_OUT         : out std_logic_vector(5 downto 0);
        RAFE_RB_SYMBOL_ID_OUT       : out std_logic_vector(5 downto 0);
        RAFE_RB_ANT_ID_OUT          : out std_logic_vector(2 downto 0);

        RAFE_RB_VALID_OUT           : out std_logic;
        RAFE_RB_START_OUT           : out std_logic;
        RAFE_RB_LAST_OUT            : out std_logic;
        RAFE_RB_DATA_I_OUT          : out std_logic_vector(15 downto 0);
        RAFE_RB_DATA_Q_OUT          : out std_logic_vector(15 downto 0)
    );
end RAFE_CONVERSION;

architecture BEHAVE of RAFE_CONVERSION is



begin

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            RAFE_RB_FRAME_ID_OUT    <= RAFE_RB_FRAME_ID_IN;
            RAFE_RB_SUBFRAME_ID_OUT <= RAFE_RB_SUBFRAME_ID_IN;
            RAFE_RB_SLOT_ID_OUT     <= RAFE_RB_SLOT_ID_IN;
            RAFE_RB_SYMBOL_ID_OUT   <= RAFE_RB_SYMBOL_ID_IN;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            RAFE_RB_ANT_ID_OUT      <= "00" & BIT2_TO_VALUE2(RAFE_RB_VALID_IN);
            RAFE_RB_ANT_ID_OUT      <= "0" & BIT4_TO_VALUE4(RAFE_RB_VALID_IN);
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (RAFE_RB_VALID_IN(0) = '1') then
                RAFE_RB_VALID_OUT       <= RAFE_RB_VALID_IN(0);
                RAFE_RB_START_OUT       <= RAFE_RB_START_IN(0);
                RAFE_RB_LAST_OUT        <= RAFE_RB_LAST_IN(0);
                RAFE_RB_DATA_I_OUT      <= RAFE_RB_DATA_IN(0*32+31 downto 0*32+16);
                RAFE_RB_DATA_Q_OUT      <= RAFE_RB_DATA_IN(0*32+15 downto 0*32+0);
            elsif (RAFE_RB_VALID_IN(1) = '1') then
                RAFE_RB_VALID_OUT       <= RAFE_RB_VALID_IN(1);
                RAFE_RB_START_OUT       <= RAFE_RB_START_IN(1);
                RAFE_RB_LAST_OUT        <= RAFE_RB_LAST_IN(1);
                RAFE_RB_DATA_I_OUT      <= RAFE_RB_DATA_IN(1*32+31 downto 1*32+16);
                RAFE_RB_DATA_Q_OUT      <= RAFE_RB_DATA_IN(1*32+15 downto 1*32+0);
            elsif (RAFE_RB_VALID_IN(2) = '1') then
                RAFE_RB_VALID_OUT       <= RAFE_RB_VALID_IN(2);
                RAFE_RB_START_OUT       <= RAFE_RB_START_IN(2);
                RAFE_RB_LAST_OUT        <= RAFE_RB_LAST_IN(2);
                RAFE_RB_DATA_I_OUT      <= RAFE_RB_DATA_IN(2*32+31 downto 2*32+16);
                RAFE_RB_DATA_Q_OUT      <= RAFE_RB_DATA_IN(2*32+15 downto 2*32+0);
            elsif (RAFE_RB_VALID_IN(3) = '1') then
                RAFE_RB_VALID_OUT       <= RAFE_RB_VALID_IN(3);
                RAFE_RB_START_OUT       <= RAFE_RB_START_IN(3);
                RAFE_RB_LAST_OUT        <= RAFE_RB_LAST_IN(3);
                RAFE_RB_DATA_I_OUT      <= RAFE_RB_DATA_IN(3*32+31 downto 3*32+16);
                RAFE_RB_DATA_Q_OUT      <= RAFE_RB_DATA_IN(3*32+15 downto 3*32+0);
            else
                RAFE_RB_VALID_OUT       <= '0';
                RAFE_RB_START_OUT       <= '0';
                RAFE_RB_LAST_OUT        <= '0';
                RAFE_RB_DATA_I_OUT      <= (others => '0');
                RAFE_RB_DATA_Q_OUT      <= (others => '0');
            end if;
        end if;
    end process;

end BEHAVE;