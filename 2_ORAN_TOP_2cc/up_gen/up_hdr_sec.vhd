--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : UL U-Plane common parameter (O-RAN component)                 --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.15                                                    --
--                                                                            --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UP_HDR_SEC is
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;
        RST                         : in  std_logic;

--------------------------------------------------------------------------------
-- Parameter
--------------------------------------------------------------------------------

        SECTION_TICK                : in  std_logic;
        SECTION_TICK_ACK            : in  std_logic;

        SECTION_ID                  : in  std_logic_vector(11 downto 0);
        USE_EVERY_PRB               : in  std_logic;
        START_OF_PRB                : in  std_logic_vector(9 downto 0);
        NUMBER_OF_PRB               : in  std_logic_vector(9 downto 0);

        RB_UPDATE                   : out std_logic;
        RB_HEADER_SEC               : out std_logic_vector(31 downto 0)
    );
end UP_HDR_SEC;

architecture BEHAVE of UP_HDR_SEC is

    type std_logic_array32          is array(natural range <>) of std_logic_vector(31 downto 0);

    constant HDR_BUF                : natural := 2;
    signal sec_hdr_data_temp        : std_logic_vector(31 downto 0);
    signal sec_hdr_data             : std_logic_array32(HDR_BUF-1 downto 0) := (others => (others => '0'));
    signal index_sec_wr             : natural range 0 to HDR_BUF;
    signal index_sec_rd             : natural range 0 to HDR_BUF;

begin

--------------------------------------------------------------------------------
-- Header parameters
--------------------------------------------------------------------------------

    process (SECTION_ID, USE_EVERY_PRB, START_OF_PRB, NUMBER_OF_PRB)
    begin
        if (NUMBER_OF_PRB(9 downto 8) = "00") then
            sec_hdr_data_temp <= SECTION_ID & (not USE_EVERY_PRB) & '0' & START_OF_PRB & NUMBER_OF_PRB(7 downto 0);
        else
            sec_hdr_data_temp <= SECTION_ID & (not USE_EVERY_PRB) & '0' & START_OF_PRB & x"00";
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (SECTION_TICK = '1') or (SECTION_TICK_ACK = '1') then
                RB_UPDATE <= '1';
            else
                RB_UPDATE <= '0';
            end if;
        end if;
    end process;

    RB_HEADER_SEC <= sec_hdr_data(index_sec_rd);

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (SECTION_TICK = '1') then
                sec_hdr_data <= sec_hdr_data(HDR_BUF-2 downto 0) & sec_hdr_data_temp;
            end if;
        end if;
    end process;

    process (RST, CLK)
    begin
        if (RST = '1') then
            index_sec_wr <= 0;
            index_sec_rd <= 0;
        elsif (CLK'event and CLK = '1') then
            if (SECTION_TICK = '1') then
                if (SECTION_TICK_ACK = '1') then
                    index_sec_wr <= index_sec_wr;
                else
                    index_sec_wr <= index_sec_wr + 1;
                end if;
            else
                if (SECTION_TICK_ACK = '1') then
                    if (index_sec_wr = 0) then
                        index_sec_wr <= 0;
                    else
                        index_sec_wr <= index_sec_wr - 1;
                    end if;
                end if;
            end if;
            if (SECTION_TICK = '1') then
                if (SECTION_TICK_ACK = '1') then
                    index_sec_rd <= index_sec_rd;
                else
                    index_sec_rd <= index_sec_wr;
                end if;
            else
                if (SECTION_TICK_ACK = '1') then
                    if (index_sec_rd = 0) then
                        index_sec_rd <= 0;
                    else
                        index_sec_rd <= index_sec_rd - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

end BEHAVE;