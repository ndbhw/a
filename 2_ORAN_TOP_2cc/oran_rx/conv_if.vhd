--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : Interface conversion (O-RAN component)                        --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.15                                                    --
--                                                                            --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity CONV_IF is
    port (
--------------------------------------------------------------------------------
-- Clock
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;

--------------------------------------------------------------------------------
-- Decompressed data
--------------------------------------------------------------------------------

        IQ_FRAME_ID                 : in  std_logic_vector(7 downto 0);
        IQ_SUBFRAME_ID              : in  std_logic_vector(3 downto 0);
        IQ_SLOT_ID                  : in  std_logic_vector(5 downto 0);
        IQ_SYMBOL_ID                : in  std_logic_vector(5 downto 0);
        IQ_USER                     : in  std_logic_vector(62 downto 0);

        IQ_VALID                    : in  std_logic;
        IQ_TICK                     : in  std_logic;
        IQ_DATA_I                   : in  std_logic_vector(15 downto 0);
        IQ_DATA_Q                   : in  std_logic_vector(15 downto 0);

--------------------------------------------------------------------------------
-- User interface
--------------------------------------------------------------------------------

        RB_eAxC_ID                  : out std_logic_vector(15 downto 0);
        RB_SEQUENCE_ID              : out std_logic_vector(15 downto 0);
        RB_CHANNEL_ID               : out std_logic_vector(3 downto 0);
        RB_FRAME_ID                 : out std_logic_vector(7 downto 0);
        RB_SUBFRAME_ID              : out std_logic_vector(3 downto 0);
        RB_SLOT_ID                  : out std_logic_vector(5 downto 0);
        RB_SYMBOL_ID                : out std_logic_vector(5 downto 0);
        RB_SECTION_ID               : out std_logic_vector(11 downto 0);
        RB_NUMBER                   : out std_logic_vector(9 downto 0);
        RE_NUMBER                   : out std_logic_vector(11 downto 0);

        RB_VALID                    : out std_logic;
        RB_START                    : out std_logic;
        RB_TICK                     : out std_logic;
        RB_LAST                     : out std_logic;
        RB_DATA_I                   : out std_logic_vector(15 downto 0);
        RB_DATA_Q                   : out std_logic_vector(15 downto 0)
    );
end CONV_IF;

architecture BEHAVE of CONV_IF is

    signal iq_cnt                   : std_logic_vector(3 downto 0) := (others => '1');
    signal rb_cnt                   : std_logic_vector(9 downto 0) := (others => '0');

begin

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            RB_eAxC_ID     <= IQ_USER(42 downto 27);
            RB_SEQUENCE_ID <= IQ_USER(58 downto 43);
            RB_CHANNEL_ID  <= IQ_USER(62 downto 59);
            RB_FRAME_ID    <= IQ_FRAME_ID;
            RB_SUBFRAME_ID <= IQ_SUBFRAME_ID;
            RB_SLOT_ID     <= IQ_SLOT_ID;
            RB_SYMBOL_ID   <= IQ_SYMBOL_ID;
            RB_SECTION_ID  <= IQ_USER(26 downto 15);
--            RB_NUMBER      <= IQ_USER(13 downto 4);
--            RE_NUMBER      <= (IQ_USER(13 downto 4) & "00") + (IQ_USER(12 downto 4) & "000");
            RB_VALID       <= IQ_VALID;
            RB_TICK        <= IQ_TICK;
            RB_DATA_I      <= IQ_DATA_I;
            RB_DATA_Q      <= IQ_DATA_Q;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (IQ_TICK = '1') then
                if (IQ_USER(0) = '1') then
                    rb_cnt <= IQ_USER(13 downto 4);
                else
                    if (IQ_USER(14) = '0') then
                        rb_cnt <= rb_cnt + 1;
                    else
                        rb_cnt <= rb_cnt + 2;
                    end if;
                end if;
            end if;
        end if;
    end process;

    RB_NUMBER <= rb_cnt;
    RE_NUMBER <= (rb_cnt & "00") + (rb_cnt(8 downto 0) & "000");

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (IQ_TICK = '1') and (IQ_USER(0) = '1') then
                RB_START <= '1';
            else
                RB_START <= '0';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (IQ_TICK = '1') then
                iq_cnt <= (others => '0');
            else
                if (iq_cnt = 15) then
                    iq_cnt <= iq_cnt;
                else
                    iq_cnt <= iq_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (iq_cnt = 10) then
                RB_LAST <= IQ_VALID and IQ_USER(1);
            else
                RB_LAST <= '0';
            end if;
        end if;
    end process;

end BEHAVE;