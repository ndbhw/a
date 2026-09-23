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

entity UP_HDR_APP is
    generic (
        MAX_CH                      : natural := 8
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;
        RST                         : in  std_logic;

--------------------------------------------------------------------------------
-- Parameter
--------------------------------------------------------------------------------

        PACKING_TICK                : in  std_logic_vector(MAX_CH-1 downto 0);
        PACKING_TICK_ACK            : in  std_logic;

        DATA_DIRECTION              : in  std_logic;
        PAYLOAD_VERSION             : in  std_logic_vector(2 downto 0);
        FILTER_INDEX                : in  std_logic_vector(3 downto 0);
        FRAME_ID                    : in  std_logic_vector(7 downto 0);
        SUBFRAME_ID                 : in  std_logic_vector(3 downto 0);
        SLOT_ID                     : in  std_logic_vector(5 downto 0);
        SYMBOL_ID                   : in  std_logic_vector(5 downto 0);

        RB_HEADER_APP               : out std_logic_vector(31 downto 0)
    );
end UP_HDR_APP;

architecture BEHAVE of UP_HDR_APP is

    type std_logic_array32          is array(natural range <>) of std_logic_vector(31 downto 0);

    constant HDR_BUF                : natural := 2;
    signal app_hdr_data_temp        : std_logic_vector(31 downto 0);
    signal app_hdr_data             : std_logic_array32(HDR_BUF-1 downto 0) := (others => (others => '0'));
    signal index_app_wr             : natural range 0 to HDR_BUF;
    signal index_app_rd             : natural range 0 to HDR_BUF;

begin

--------------------------------------------------------------------------------
-- Header parameters
--------------------------------------------------------------------------------

    app_hdr_data_temp <= DATA_DIRECTION & PAYLOAD_VERSION & FILTER_INDEX & FRAME_ID & SUBFRAME_ID & SLOT_ID & SYMBOL_ID;

    RB_HEADER_APP <= app_hdr_data(index_app_rd);

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (PACKING_TICK /= 0) then
                app_hdr_data <= app_hdr_data(HDR_BUF-2 downto 0) & app_hdr_data_temp;
            end if;
        end if;
    end process;

    process (RST, CLK)
    begin
        if (RST = '1') then
            index_app_wr <= 0;
            index_app_rd <= 0;
        elsif (CLK'event and CLK = '1') then
            if (PACKING_TICK /= 0) then
                if (PACKING_TICK_ACK = '1') then
                    index_app_wr <= index_app_wr;
                else
                    index_app_wr <= index_app_wr + 1;
                end if;
            else
                if (PACKING_TICK_ACK = '1') then
                    if (index_app_wr = 0) then
                        index_app_wr <= 0;
                    else
                        index_app_wr <= index_app_wr - 1;
                    end if;
                end if;
            end if;
            if (PACKING_TICK /= 0) then
                if (PACKING_TICK_ACK = '1') then
                    index_app_rd <= index_app_rd;
                else
                    index_app_rd <= index_app_wr;
                end if;
            else
                if (PACKING_TICK_ACK = '1') then
                    if (index_app_rd = 0) then
                        index_app_rd <= 0;
                    else
                        index_app_rd <= index_app_rd - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

end BEHAVE;