--------------------------------------------------------------------------------
--
-- Copyright (C) 2024, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2024.01.12
--------------------------------------------------------------------------------
-- Function description
--   -. Package declaration for ORAN
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2024.01.12) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;

package PKG_ORAN is

    -- Ethernet features
    constant IMPL_CHECK_DST_MAC     : boolean := true;
    constant IMPL_CHECK_SRC_MAC     : boolean := true;
    constant IMPL_CHECK_VLAN_VID    : boolean := true;

    -- ORAN features
    constant IMPL_PDxCH             : boolean := true;
    constant IMPL_SSB               : boolean := false;
    constant IMPL_H_MATRIX          : boolean := false;
    constant IMPL_PUxCH             : boolean := true;
    constant IMPL_PRACH             : boolean := true;
    constant IMPL_SRS               : boolean := false;
    constant IMPL_RIM_RS            : boolean := false;
    constant IMPL_NB_IoT            : boolean := false;

    constant MAX_RU_ELEMENT         : natural := 4;                             -- number of processing element lists
    constant MAX_LINK               : natural := 16;                            -- Do not modify

    -- ORAN references
    constant ORAN_ETHERTYPE         : std_logic_vector(15 downto 0) := x"AEFE";
    constant TX_LINK_DIRECTION      : std_logic := '1';                         -- DL
    constant RX_LINK_DIRECTION      : std_logic := '0';                         -- UL

    constant INDEX_PDxCH            : natural := 0;
    constant INDEX_SSB              : natural := 1;
    constant INDEX_H_MATRIX         : natural := 2;
    constant INDEX_PUxCH            : natural := 0;
    constant INDEX_PRACH            : natural := 1;
    constant INDEX_SRS              : natural := 2;
    constant INDEX_RIM_RS           : natural := 3;
    constant INDEX_NB_IoT           : natural := 4;

    constant COMP_NO_COMP           : boolean := true;
    constant COMP_BFPC              : boolean := true;
    constant COMP_BS                : boolean := false;
    constant COMP_M_LAW             : boolean := false;
    constant COMP_MC                : boolean := false;

    -- sectionType/sectionExtension
    constant ST0                    : boolean := true;
    constant ST1                    : boolean := true;
    constant ST1_SE10               : boolean := true;
    constant ST1_SE9                : boolean := true;
    constant ST3                    : boolean := true;
    constant ST3_SE9                : boolean := false;
    constant ST3_SE10               : boolean := true;

    -- u (Subcarrier spacing) configurations
    constant SCS_CONFIG_0           : boolean := true;                          -- 15kHz under
    constant SCS_CONFIG_1           : boolean := false;                         -- 30kHz
    constant SCS_CONFIG_2           : boolean := false;                         -- 60kHz
    constant SCS_CONFIG_3           : boolean := false;                         -- 120kHz
    constant SCS_CONFIG_4           : boolean := false;                         -- 240kHz

    -- udIqWidth configurations (when udCompParam is not present, no-comp/MC)
    constant TX_UNCOMP_1B           : boolean := false;
    constant TX_UNCOMP_2B           : boolean := false;
    constant TX_UNCOMP_3B           : boolean := false;
    constant TX_UNCOMP_4B           : boolean := false;
    constant TX_UNCOMP_5B           : boolean := false;
    constant TX_UNCOMP_6B           : boolean := false;
    constant TX_UNCOMP_7B           : boolean := false;
    constant TX_UNCOMP_8B           : boolean := false;
    constant TX_UNCOMP_9B           : boolean := false;
    constant TX_UNCOMP_10B          : boolean := false;
    constant TX_UNCOMP_11B          : boolean := false;
    constant TX_UNCOMP_12B          : boolean := false;
    constant TX_UNCOMP_13B          : boolean := false;
    constant TX_UNCOMP_14B          : boolean := false;
    constant TX_UNCOMP_15B          : boolean := false;
    constant TX_UNCOMP_16B          : boolean := true;

    constant RX_UNCOMP_1B           : boolean := false;
    constant RX_UNCOMP_2B           : boolean := false;
    constant RX_UNCOMP_3B           : boolean := false;
    constant RX_UNCOMP_4B           : boolean := false;
    constant RX_UNCOMP_5B           : boolean := false;
    constant RX_UNCOMP_6B           : boolean := false;
    constant RX_UNCOMP_7B           : boolean := false;
    constant RX_UNCOMP_8B           : boolean := false;
    constant RX_UNCOMP_9B           : boolean := false;
    constant RX_UNCOMP_10B          : boolean := false;
    constant RX_UNCOMP_11B          : boolean := false;
    constant RX_UNCOMP_12B          : boolean := false;
    constant RX_UNCOMP_13B          : boolean := false;
    constant RX_UNCOMP_14B          : boolean := false;
    constant RX_UNCOMP_15B          : boolean := false;
    constant RX_UNCOMP_16B          : boolean := true;

    -- udIqWidth configurations (when udCompParam is present, BFP/BS/u-law)
    constant TX_COMP_1B             : boolean := false;
    constant TX_COMP_2B             : boolean := false;
    constant TX_COMP_3B             : boolean := false;
    constant TX_COMP_4B             : boolean := false;
    constant TX_COMP_5B             : boolean := false;
    constant TX_COMP_6B             : boolean := false;
    constant TX_COMP_7B             : boolean := false;
    constant TX_COMP_8B             : boolean := false;
    constant TX_COMP_9B             : boolean := true;
    constant TX_COMP_10B            : boolean := false;
    constant TX_COMP_11B            : boolean := false;
    constant TX_COMP_12B            : boolean := true;
    constant TX_COMP_13B            : boolean := false;
    constant TX_COMP_14B            : boolean := true;
    constant TX_COMP_15B            : boolean := false;
    constant TX_COMP_16B            : boolean := false;

    constant RX_COMP_1B             : boolean := false;
    constant RX_COMP_2B             : boolean := false;
    constant RX_COMP_3B             : boolean := false;
    constant RX_COMP_4B             : boolean := false;
    constant RX_COMP_5B             : boolean := false;
    constant RX_COMP_6B             : boolean := false;
    constant RX_COMP_7B             : boolean := false;
    constant RX_COMP_8B             : boolean := false;
    constant RX_COMP_9B             : boolean := true;
    constant RX_COMP_10B            : boolean := false;
    constant RX_COMP_11B            : boolean := false;
    constant RX_COMP_12B            : boolean := true;
    constant RX_COMP_13B            : boolean := false;
    constant RX_COMP_14B            : boolean := true;
    constant RX_COMP_15B            : boolean := false;
    constant RX_COMP_16B            : boolean := false;

    -- user functions
    function KEEP_TO_EMPTY_LSB (DATA_VALUE : std_logic_vector(7 downto 0)) return std_logic_vector;
    function EMPTY_TO_KEEP_LSB (DATA_VALUE : std_logic_vector(3 downto 0)) return std_logic_vector;
    function KEEP_TO_EMPTY_MSB (DATA_VALUE : std_logic_vector(7 downto 0)) return std_logic_vector;
    function EMPTY_TO_KEEP_MSB (DATA_VALUE : std_logic_vector(2 downto 0)) return std_logic_vector;

    function LOG2 (DATA_VALUE : natural) return natural;
    function LOG2_BITMAP (DATA_VALUE : natural) return natural;

    function VALUE2_TO_BIT2   (DATA_VALUE : std_logic_vector(0 downto 0)) return std_logic_vector;
    function VALUE4_TO_BIT4   (DATA_VALUE : std_logic_vector(1 downto 0)) return std_logic_vector;
    function VALUE8_TO_BIT8   (DATA_VALUE : std_logic_vector(2 downto 0)) return std_logic_vector;
    function VALUE16_TO_BIT16 (DATA_VALUE : std_logic_vector(3 downto 0)) return std_logic_vector;

    function BIT2_TO_VALUE2   (DATA_VALUE : std_logic_vector(1 downto 0)) return std_logic_vector;
    function BIT4_TO_VALUE4   (DATA_VALUE : std_logic_vector(3 downto 0)) return std_logic_vector;
    function BIT8_TO_VALUE8   (DATA_VALUE : std_logic_vector(7 downto 0)) return std_logic_vector;
    function BIT16_TO_VALUE16 (DATA_VALUE : std_logic_vector(15 downto 0)) return std_logic_vector;

end PKG_ORAN;

package body PKG_ORAN is

    function KEEP_TO_EMPTY_LSB (
        DATA_VALUE                  : std_logic_vector(7 downto 0)
    )
    return std_logic_vector is
    begin
        case DATA_VALUE is
        when "00000001" => return "0001";
        when "00000011" => return "0010";
        when "00000111" => return "0011";
        when "00001111" => return "0100";
        when "00011111" => return "0101";
        when "00111111" => return "0110";
        when "01111111" => return "0111";
        when "11111111" => return "1000";
        when others     => return "1000";
        end case;
    end KEEP_TO_EMPTY_LSB;

    function EMPTY_TO_KEEP_LSB (
        DATA_VALUE                  : std_logic_vector(3 downto 0)
    )
    return std_logic_vector is
    begin
        case DATA_VALUE is
        when "0001"  => return "00000001";
        when "0010"  => return "00000011";
        when "0011"  => return "00000111";
        when "0100"  => return "00001111";
        when "0101"  => return "00011111";
        when "0110"  => return "00111111";
        when "0111"  => return "01111111";
        when "1000"  => return "11111111";
        when others  => return "11111111";
        end case;
    end EMPTY_TO_KEEP_LSB;

    function KEEP_TO_EMPTY_MSB (
        DATA_VALUE                  : std_logic_vector(7 downto 0)
    )
    return std_logic_vector is
    begin
        case DATA_VALUE is
        when "10000000" => return "111";
        when "11000000" => return "110";
        when "11100000" => return "101";
        when "11110000" => return "100";
        when "11111000" => return "011";
        when "11111100" => return "010";
        when "11111110" => return "001";
        when "11111111" => return "000";
        when others     => return "000";
        end case;
    end KEEP_TO_EMPTY_MSB;

    function EMPTY_TO_KEEP_MSB (
        DATA_VALUE                  : std_logic_vector(2 downto 0)
    )
    return std_logic_vector is
    begin
        case DATA_VALUE is
        when "111"  => return "10000000";
        when "110"  => return "11000000";
        when "101"  => return "11100000";
        when "100"  => return "11110000";
        when "011"  => return "11111000";
        when "010"  => return "11111100";
        when "001"  => return "11111110";
        when "000"  => return "11111111";
        when others => return "11111111";
        end case;
    end EMPTY_TO_KEEP_MSB;

    function LOG2 (
        DATA_VALUE                  : natural
    )
    return natural is
        variable result             : natural := 0;
        variable cnt                : natural := 1;
    begin
        if (DATA_VALUE <= 1) then
            result := 0;
        else
            while (cnt < DATA_VALUE) loop
                result := result + 1;
                cnt    := cnt *2;
            end loop;
        end if;
        return result;
    end LOG2;

    function LOG2_BITMAP (
        DATA_VALUE                  : natural
    )
    return natural is
        variable result             : natural := 0;
        variable cnt                : natural := 1;
    begin
        if (DATA_VALUE <= 1) then
            result := 1;
        else
            while (cnt < DATA_VALUE) loop
                result := result + 1;
                cnt    := cnt *2;
            end loop;
        end if;
        return result;
    end LOG2_BITMAP;

    function VALUE2_TO_BIT2 (
        DATA_VALUE                  : std_logic_vector(0 downto 0)
    )
    return std_logic_vector is
    begin
        case DATA_VALUE is
        when "0"    => return "01";
        when others => return "10";
        end case;
    end VALUE2_TO_BIT2;

    function VALUE4_TO_BIT4 (
        DATA_VALUE                  : std_logic_vector(1 downto 0)
    )
    return std_logic_vector is
    begin
        case DATA_VALUE is
        when "00"   => return "0001";
        when "01"   => return "0010";
        when "10"   => return "0100";
        when others => return "1000";
        end case;
    end VALUE4_TO_BIT4;

    function VALUE8_TO_BIT8 (
        DATA_VALUE                  : std_logic_vector(2 downto 0)
    )
    return std_logic_vector is
    begin
        case DATA_VALUE is
        when "000"  => return "00000001";
        when "001"  => return "00000010";
        when "010"  => return "00000100";
        when "011"  => return "00001000";
        when "100"  => return "00010000";
        when "101"  => return "00100000";
        when "110"  => return "01000000";
        when others => return "10000000";
        end case;
    end VALUE8_TO_BIT8;

    function VALUE16_TO_BIT16 (
        DATA_VALUE                  : std_logic_vector(3 downto 0)
    )
    return std_logic_vector is
    begin
        case DATA_VALUE is
        when "0000" => return "0000000000000001";
        when "0001" => return "0000000000000010";
        when "0010" => return "0000000000000100";
        when "0011" => return "0000000000001000";
        when "0100" => return "0000000000010000";
        when "0101" => return "0000000000100000";
        when "0110" => return "0000000001000000";
        when "0111" => return "0000000010000000";
        when "1000" => return "0000000100000000";
        when "1001" => return "0000001000000000";
        when "1010" => return "0000010000000000";
        when "1011" => return "0000100000000000";
        when "1100" => return "0001000000000000";
        when "1101" => return "0010000000000000";
        when "1110" => return "0100000000000000";
        when others => return "1000000000000000";
        end case;
    end VALUE16_TO_BIT16;

    function BIT2_TO_VALUE2 (
        DATA_VALUE                  : std_logic_vector(1 downto 0)
    )
    return std_logic_vector is
    begin
        case DATA_VALUE is
        when "01"   => return "0";
        when "10"   => return "1";
        when others => return "0";
        end case;
    end BIT2_TO_VALUE2;

    function BIT4_TO_VALUE4 (
        DATA_VALUE                  : std_logic_vector(3 downto 0)
    )
    return std_logic_vector is
    begin
        case DATA_VALUE is
        when "0001" => return "00";
        when "0010" => return "01";
        when "0100" => return "10";
        when "1000" => return "11";
        when others => return "00";
        end case;
    end BIT4_TO_VALUE4;

    function BIT8_TO_VALUE8 (
        DATA_VALUE                  : std_logic_vector(7 downto 0)
    )
    return std_logic_vector is
    begin
        case DATA_VALUE is
        when "00000001" => return "000";
        when "00000010" => return "001";
        when "00000100" => return "010";
        when "00001000" => return "011";
        when "00010000" => return "100";
        when "00100000" => return "101";
        when "01000000" => return "110";
        when "10000000" => return "111";
        when others     => return "000";
        end case;
    end BIT8_TO_VALUE8;

    function BIT16_TO_VALUE16 (
        DATA_VALUE                  : std_logic_vector(15 downto 0)
    )
    return std_logic_vector is
    begin
        case DATA_VALUE is
        when "0000000000000001" => return "0000";
        when "0000000000000010" => return "0001";
        when "0000000000000100" => return "0010";
        when "0000000000001000" => return "0011";
        when "0000000000010000" => return "0100";
        when "0000000000100000" => return "0101";
        when "0000000001000000" => return "0110";
        when "0000000010000000" => return "0111";
        when "0000000100000000" => return "1000";
        when "0000001000000000" => return "1001";
        when "0000010000000000" => return "1010";
        when "0000100000000000" => return "1011";
        when "0001000000000000" => return "1100";
        when "0010000000000000" => return "1101";
        when "0100000000000000" => return "1110";
        when "1000000000000000" => return "1111";
        when others             => return "0000";
        end case;
    end BIT16_TO_VALUE16;

end PKG_ORAN;