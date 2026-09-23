--------------------------------------------------------------------------------
--
-- Copyright (C) 2024, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2024.03.11
--------------------------------------------------------------------------------
-- Function description
--   -. ORAN C-Plane processing (without sectionType 6)
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2024.03.11) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use WORK.PKG_ORAN.ALL;
use WORK.PKG_ORAN_ARRAY.ALL;

entity ORAN_CP_RX is
    generic (
--        DATA_INDEX_MASK             : natural := 0;
        LINK_MAP_MASK               : std_logic_vector(15 downto 0)
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;                            -- 156.25/390.625-MHz
        RST                         : in  std_logic;                            -- CLK_ORAN

        CLK_UP                      : in  std_logic;                            -- 245.76-MHz

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

        USAGE_DATA_BUFFER           : out std_logic_vector(31 downto 0);

        CNT_RX                      : out std_logic_vector(31 downto 0);
        CNT_LOST                    : out std_logic_vector(31 downto 0);

--------------------------------------------------------------------------------
-- C-Plane (with eCPRI header)
--------------------------------------------------------------------------------

        CP64_VALID                  : in  std_logic;
        CP64_LAST                   : in  std_logic;
        CP64_KEEP                   : in  std_logic_vector(7 downto 0);
        CP64_DATA                   : in  std_logic_vector(63 downto 0);
        CP64_DATA_INDEX             : in  std_logic_vector(2 downto 0);
        CP64_LINK_MAP               : in  std_logic_vector(15 downto 0);

--------------------------------------------------------------------------------
-- C-Plane (Seperated)
--------------------------------------------------------------------------------

        CP32_VALID                  : out std_logic;
        CP32_LAST                   : out std_logic;
        CP32_KEEP                   : out std_logic_vector(3 downto 0);
        CP32_DATA                   : out std_logic_vector(31 downto 0);
        CP32_DATA_INDEX             : out std_logic_vector(2 downto 0);
        CP32_LINK_INDEX             : out std_logic_vector(3 downto 0)
    );
end ORAN_CP_RX;

architecture BEHAVE of ORAN_CP_RX is

--    component RST_SYNC is
--    generic (
--        DLY_NUM                     : natural := 4;
--        MAX_FANOUT_NUM              : integer := 200
--    );
--    port (
--        RST_IN                      : in  std_logic;
--        CLK                         : in  std_logic;
--        RST_OUT                     : out std_logic
--    );
--    end component;
--
--    signal sreset                   : std_logic;

    component RATE_ADAPT_CP32 is
    generic (
        NUM_OF_URAM                 : natural := 16
    );
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        CLK_CDC                     : in  std_logic;

        USAGE_DATA_BUFFER           : out std_logic_vector(31 downto 0);

        CNT_RX                      : out std_logic_vector(31 downto 0);
        CNT_LOST                    : out std_logic_vector(31 downto 0);

        IN_VALID                    : in  std_logic;
        IN_LAST                     : in  std_logic;
        IN_DATA                     : in  std_logic_vector(63 downto 0);
        IN_DATA_INDEX               : in  std_logic_vector(2 downto 0);
        IN_LINK_INDEX               : in  std_logic_vector(3 downto 0);

        OUT_READY                   : in  std_logic;
        OUT_VALID                   : out std_logic;
        OUT_LAST                    : out std_logic;
        OUT_DATA                    : out std_logic_vector(31 downto 0);
        OUT_DATA_INDEX              : out std_logic_vector(2 downto 0);
        OUT_LINK_INDEX              : out std_logic_vector(3 downto 0)
    );
    end component;

--    signal data_match               : std_logic;
    signal link_match               : std_logic_vector(15 downto 0);
    signal cp64_valid_mask          : std_logic;
    signal cp64_link_index          : std_logic_vector(3 downto 0);

begin

--------------------------------------------------------------------------------
-- Unused port
--------------------------------------------------------------------------------

    CP32_KEEP <= (others => '1');

--------------------------------------------------------------------------------
-- Data masking
--------------------------------------------------------------------------------

--    data_match <= '1' when (CP64_DATA_INDEX = DATA_INDEX_MASK) else '0';
    link_match <= CP64_LINK_MAP and LINK_MAP_MASK;

--    cp64_valid_mask <= CP64_VALID when (data_match = '1') and (link_match /= 0) else '0';
    cp64_valid_mask <= CP64_VALID when (link_match /= 0) else '0';
    cp64_link_index <= BIT16_TO_VALUE16(CP64_LINK_MAP);

--------------------------------------------------------------------------------
-- Component mapping
--------------------------------------------------------------------------------

--    u_RST : RST_SYNC
--    generic map(
--        DLY_NUM                     => 4                                       ,--: natural := 4;
--        MAX_FANOUT_NUM              => 200                                      --: integer := 200
--    )
--    port map(
--        RST_IN                      => RST                                     ,--: in  std_logic;
--        CLK                         => CLK                                     ,--: in  std_logic;
--        RST_OUT                     => sreset                                   --: out std_logic
--    );

    u_RATE_ADAPT : RATE_ADAPT_CP32
    generic map(
        NUM_OF_URAM                 => 1                                        --: natural := 16
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => RST                                     ,--: in  std_logic;

        CLK_CDC                     => CLK_UP                                  ,--: in  std_logic;

        USAGE_DATA_BUFFER           => USAGE_DATA_BUFFER                       ,--: out std_logic_vector(31 downto 0);

        CNT_RX                      => CNT_RX                                  ,--: out std_logic_vector(31 downto 0);
        CNT_LOST                    => CNT_LOST                                ,--: out std_logic_vector(31 downto 0);

        IN_VALID                    => cp64_valid_mask                         ,--: in  std_logic;
        IN_LAST                     => CP64_LAST                               ,--: in  std_logic;
        IN_DATA                     => CP64_DATA                               ,--: in  std_logic_vector(63 downto 0);
        IN_DATA_INDEX               => CP64_DATA_INDEX                         ,--: in  std_logic_vector(2 downto 0);
        IN_LINK_INDEX               => cp64_link_index                         ,--: in  std_logic_vector(3 downto 0);

        OUT_READY                   => '1'                                     ,--: in  std_logic;
        OUT_VALID                   => CP32_VALID                              ,--: out std_logic;
        OUT_LAST                    => CP32_LAST                               ,--: out std_logic;
        OUT_DATA                    => CP32_DATA                               ,--: out std_logic_vector(31 downto 0);
        OUT_DATA_INDEX              => CP32_DATA_INDEX                         ,--: out std_logic_vector(2 downto 0);
        OUT_LINK_INDEX              => CP32_LINK_INDEX                          --: out std_logic_vector(3 downto 0)
    );

end BEHAVE;