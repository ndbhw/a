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

use WORK.ARRAY_TYPE.ALL;
use WORK.PKG_ORAN.ALL;

package PKG_ORAN_ARRAY is

    -- ORAN features
--    constant MAX_DATA_INDEX         : natural := LOG2(MAX_DATA_TYPE);           -- bit width of index for data types
--    constant MAX_LINK_INDEX         : natural := LOG2_BITMAP(MAX_LINK);         -- bit width of index for links
    constant MAX_PE_INDEX           : natural := LOG2_BITMAP(MAX_RU_ELEMENT);   -- bit width of index for processing elements
    constant MAX_DEBUG_BIT          : natural := 16;

    constant LINK_MASK_2U           : std_logic_array16(0 to 7) := (x"0003", x"000C", x"0030", x"00C0", x"0300", x"0C00", x"3000", x"C000");
    constant LINK_MASK_4U           : std_logic_array16(0 to 3) := (x"000F", x"00F0", x"0F00", x"FFF0");
    constant LINK_MASK_8U           : std_logic_array16(0 to 1) := (x"00FF", x"FF00");

    -- user data type
    type array_natural              is array(natural range <>) of natural range 0 to 64;
    type logic_array_pe             is array(natural range <>) of std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

    type std_logic_array8_array4    is array(natural range <>) of std_logic_array4( 7 downto 0);
    type std_logic_array64_array4   is array(natural range <>) of std_logic_array4(63 downto 0);
    type std_logic_array8_array5    is array(natural range <>) of std_logic_array5( 7 downto 0);
    type std_logic_array64_array5   is array(natural range <>) of std_logic_array5(63 downto 0);
    type std_logic_array64_array8   is array(natural range <>) of std_logic_array8(63 downto 0);
    type std_logic_array64_array10  is array(natural range <>) of std_logic_array10(63 downto 0);
    type std_logic_array8_array11   is array(natural range <>) of std_logic_array11( 7 downto 0);
    type std_logic_array64_array11  is array(natural range <>) of std_logic_array11(63 downto 0);
    type std_logic_array64_array16  is array(natural range <>) of std_logic_array16(63 downto 0);
    type std_logic_array8_array24   is array(natural range <>) of std_logic_array24( 7 downto 0);

end PKG_ORAN_ARRAY;

package body PKG_ORAN_ARRAY is



end PKG_ORAN_ARRAY;