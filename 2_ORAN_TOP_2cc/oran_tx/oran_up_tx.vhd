--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : O-RAN framer                                                  --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.15                                                    --
--                                                                            --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use WORK.ARRAY_TYPE.ALL;
use WORK.PKG_ORAN.ALL;

entity ORAN_UP_TX is
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;                            -- 390.625-MHz
        RST                         : in  std_logic;                            -- ASYNC

        CLK_UP                      : in  std_logic;                            -- 245.76-MHz

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------

        PARAM_RU_MAC                : in  std_logic_array48(7 downto 0);
        PARAM_PORT_INDEX            : in  std_logic_array3(7 downto 0);
        PARAM_DU_MAC                : in  std_logic_array48(7 downto 0);
        PARAM_VLAN0_EN              : in  std_logic_vector(7 downto 0);
        PARAM_VLAN0_VID             : in  std_logic_array12(7 downto 0);
        PARAM_VLAN1_EN              : in  std_logic_vector(7 downto 0);
        PARAM_VLAN1_VID             : in  std_logic_array12(7 downto 0);

        TX_COMP_EXP_OFFSET          : in  std_logic_array5(7 downto 0);
        TX_COMP_GAIN_OFFSET         : in  std_logic_array11(7 downto 0);
        TX_COMP_SCALE_GAIN_OFFSET   : in  std_logic_array4(7 downto 0);

--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

        USAGE_DATA_BUFFER           : out std_logic_vector(31 downto 0);        -- CLK

        CNT_TX                      : out std_logic_vector(31 downto 0);        -- CLK
        CNT_LOST                    : out std_logic_vector(31 downto 0);        -- CLK

--------------------------------------------------------------------------------
-- U-Plane (Not encoded)
--------------------------------------------------------------------------------

        RB_INIT                     : in  std_logic;
        RB_PATH                     : in  std_logic_vector(2 downto 0);
        RB_PE_INDEX                 : in  std_logic_vector(2 downto 0);
        RB_eAxC_ID                  : in  std_logic_vector(15 downto 0);
        RB_SEQUENCE_ID              : in  std_logic_vector(15 downto 0);
        RB_HEADER_APP               : in  std_logic_vector(31 downto 0);
        RB_HEADER_APP_ACK           : out std_logic;
        RB_HEADER_SEC               : in  std_logic_vector(31 downto 0);
        RB_HEADER_SEC_ACK           : out std_logic;

        RB_COMP_HDR                 : in  std_logic_vector(8 downto 0);

        RB_VALID                    : in  std_logic;
        RB_START                    : in  std_logic;
        RB_TICK                     : in  std_logic;
        RB_LAST                     : in  std_logic;
        RB_DATA_I                   : in  std_logic_vector(15 downto 0);
        RB_DATA_Q                   : in  std_logic_vector(15 downto 0);
        RB_USER                     : in  std_logic_vector(15 downto 0);

--------------------------------------------------------------------------------
-- Tx-stat
--------------------------------------------------------------------------------

        PE_TRANSMITTED              : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

--------------------------------------------------------------------------------
-- U-Plane
--------------------------------------------------------------------------------

        UP64_READY                  : in  std_logic;
        UP64_VALID                  : out std_logic;
        UP64_LAST                   : out std_logic;
        UP64_KEEP                   : out std_logic_vector(7 downto 0);
        UP64_DATA                   : out std_logic_vector(63 downto 0)
    );
end ORAN_UP_TX;

architecture BEHAVE of ORAN_UP_TX is

    component RST_SYNC is
    generic (
        DLY_NUM                     : natural := 4;
        MAX_FANOUT_NUM              : integer := 200
    );
    port (
        RST_IN                      : in  std_logic;
        CLK                         : in  std_logic;
        RST_OUT                     : out std_logic
    );
    end component;

    signal reset_bus                : std_logic;

    component PRB_COMP is
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        COMP_EXP_OFFSET             : in  std_logic_array5(7 downto 0);
        COMP_GAIN_OFFSET            : in  std_logic_array11(7 downto 0);
        COMP_SCALE_GAIN_OFFSET      : in  std_logic_array4(7 downto 0);

        RB_PATH                     : in  std_logic_vector(2 downto 0);

        IQ_COMP_HDR                 : in  std_logic_vector(8 downto 0);

        IQ_VALID                    : in  std_logic;
        IQ_TICK                     : in  std_logic;
        IQ_DATA_I                   : in  std_logic_vector(15 downto 0);
        IQ_DATA_Q                   : in  std_logic_vector(15 downto 0);
        IQ_USER                     : in  std_logic_vector(15 downto 0);

        COMP_HDR                    : out std_logic_vector(8 downto 0);
        COMP_PARAM                  : out std_logic_vector(7 downto 0);

        COMP_VALID                  : out std_logic;
        COMP_TICK                   : out std_logic;
        COMP_DATA_I                 : out std_logic_vector(15 downto 0);
        COMP_DATA_Q                 : out std_logic_vector(15 downto 0);
        COMP_USER                   : out std_logic_vector(15 downto 0)
    );
    end component;

    signal comp_hdr                 : std_logic_vector(8 downto 0);
    signal comp_param               : std_logic_vector(7 downto 0);
    signal comp_valid               : std_logic;
    signal comp_tick                : std_logic;
    signal comp_data_i              : std_logic_vector(15 downto 0);
    signal comp_data_q              : std_logic_vector(15 downto 0);
    signal comp_user                : std_logic_vector(15 downto 0);

    component PRB_PACKER is
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        PARAM_RU_MAC                : in  std_logic_array48(7 downto 0);
        PARAM_PORT_INDEX            : in  std_logic_array3(7 downto 0);
        PARAM_DU_MAC                : in  std_logic_array48(7 downto 0);
        PARAM_VLAN0_EN              : in  std_logic_vector(7 downto 0);
        PARAM_VLAN0_VID             : in  std_logic_array12(7 downto 0);
        PARAM_VLAN1_EN              : in  std_logic_vector(7 downto 0);
        PARAM_VLAN1_VID             : in  std_logic_array12(7 downto 0);

        RB_PE_INDEX                 : in  std_logic_vector(2 downto 0);
        RB_eAxC_ID                  : in  std_logic_vector(15 downto 0);
        RB_SEQUENCE_ID              : in  std_logic_vector(15 downto 0);
        RB_HEADER_APP               : in  std_logic_vector(31 downto 0);
        RB_HEADER_APP_ACK           : out std_logic;
        RB_HEADER_SEC               : in  std_logic_vector(31 downto 0);
        RB_HEADER_SEC_ACK           : out std_logic;

        PE_TRANSMITTED              : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

        COMP_HDR                    : in  std_logic_vector(8 downto 0);
        COMP_PARAM                  : in  std_logic_vector(7 downto 0);

        COMP_VALID                  : in  std_logic;
        COMP_TICK                   : in  std_logic;
        COMP_DATA_I                 : in  std_logic_vector(15 downto 0);
        COMP_DATA_Q                 : in  std_logic_vector(15 downto 0);
        COMP_USER                   : in  std_logic_vector(15 downto 0);

        PACK_PORT_ID                : out std_logic_vector(2 downto 0);
        PACK_VLAN_MODE              : out std_logic_vector(1 downto 0);
        PACK_LENGTH                 : out std_logic_vector(15 downto 0);

        PACK_VALID                  : out std_logic;
        PACK_START                  : out std_logic;
        PACK_LAST                   : out std_logic;
        PACK_KEEP                   : out std_logic_vector(3 downto 0);
        PACK_DATA                   : out std_logic_vector(31 downto 0)
    );
    end component;

    signal pack_port_id             : std_logic_vector(2 downto 0);
    signal pack_vlan_mode           : std_logic_vector(1 downto 0);
    signal pack_length              : std_logic_vector(15 downto 0);
    signal pack_valid               : std_logic;
    signal pack_start               : std_logic;
    signal pack_last                : std_logic;
    signal pack_keep                : std_logic_vector(3 downto 0);
    signal pack_data                : std_logic_vector(31 downto 0);

    component PKT_GEN is
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        CLK_UP                      : in  std_logic;
        RST_UP                      : in  std_logic;

        PACK_PORT_ID                : in  std_logic_vector(2 downto 0);
        PACK_VLAN_MODE              : in  std_logic_vector(1 downto 0);
        PACK_LENGTH                 : in  std_logic_vector(15 downto 0);

        PACK_VALID                  : in  std_logic;
        PACK_START                  : in  std_logic;
        PACK_LAST                   : in  std_logic;
        PACK_KEEP                   : in  std_logic_vector(3 downto 0);
        PACK_DATA                   : in  std_logic_vector(31 downto 0);

        TX_VALID                    : out std_logic;
        TX_START                    : out std_logic;
        TX_LAST                     : out std_logic;
        TX_DEST                     : out std_logic_vector(2 downto 0);
        TX_KEEP                     : out std_logic_vector(7 downto 0);
        TX_DATA                     : out std_logic_vector(63 downto 0)
    );
    end component;

    signal tx_valid                 : std_logic;
--    signal tx_start                 : std_logic;
    signal tx_last                  : std_logic;
    signal tx_dest                  : std_logic_vector(2 downto 0);
    signal tx_keep                  : std_logic_vector(7 downto 0);
    signal tx_data                  : std_logic_vector(63 downto 0);

    component PKT_BUFFER is
    generic (
        NUM_OF_URAM                 : natural := 1
    );
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        USAGE_DATA_BUFFER           : out std_logic_vector(31 downto 0);

        CNT_TX                      : out std_logic_vector(31 downto 0);
        CNT_LOST                    : out std_logic_vector(31 downto 0);

        IN_VALID                    : in  std_logic;
        IN_LAST                     : in  std_logic;
        IN_DEST                     : in  std_logic_vector(2 downto 0);
        IN_KEEP                     : in  std_logic_vector(7 downto 0);
        IN_DATA                     : in  std_logic_vector(63 downto 0);

        OUT0_READY                  : in  std_logic;
        OUT0_VALID                  : out std_logic;
        OUT0_LAST                   : out std_logic;
        OUT0_KEEP                   : out std_logic_vector(7 downto 0);
        OUT0_DATA                   : out std_logic_vector(63 downto 0)
    );
    end component;

begin

--------------------------------------------------------------------------------
-- U-Plane
--------------------------------------------------------------------------------

    u_RST_BUS : RST_SYNC
    generic map(
        DLY_NUM                     => 4                                       ,--: natural := 4;
        MAX_FANOUT_NUM              => 200                                      --: integer := 200
    )
    port map(
        RST_IN                      => RST                                     ,--: in  std_logic;
        CLK                         => CLK_UP                                  ,--: in  std_logic;
        RST_OUT                     => reset_bus                                --: out std_logic
    );

    u_COMP : PRB_COMP
    port map(
        CLK                         => CLK_UP                                  ,--: in  std_logic;
        RST                         => RB_INIT                                 ,--: in  std_logic;

        COMP_EXP_OFFSET             => TX_COMP_EXP_OFFSET                      ,--: in  std_logic_array5(7 downto 0);
        COMP_GAIN_OFFSET            => TX_COMP_GAIN_OFFSET                     ,--: in  std_logic_array11(7 downto 0);
        COMP_SCALE_GAIN_OFFSET      => TX_COMP_SCALE_GAIN_OFFSET               ,--: in  std_logic_array4(7 downto 0);

        RB_PATH                     => RB_PATH                                 ,--: in  std_logic_vector(2 downto 0);

        IQ_COMP_HDR                 => RB_COMP_HDR                             ,--: in  std_logic_vector(8 downto 0);

        IQ_VALID                    => RB_VALID                                ,--: in  std_logic;
        IQ_TICK                     => RB_TICK                                 ,--: in  std_logic;
        IQ_DATA_I                   => RB_DATA_I                               ,--: in  std_logic_vector(15 downto 0);
        IQ_DATA_Q                   => RB_DATA_Q                               ,--: in  std_logic_vector(15 downto 0);
        IQ_USER                     => RB_USER                                 ,--: in  std_logic_vector(15 downto 0);

        COMP_HDR                    => comp_hdr                                ,--: out std_logic_vector(8 downto 0);
        COMP_PARAM                  => comp_param                              ,--: out std_logic_vector(7 downto 0);

        COMP_VALID                  => comp_valid                              ,--: out std_logic;
        COMP_TICK                   => comp_tick                               ,--: out std_logic;
        COMP_DATA_I                 => comp_data_i                             ,--: out std_logic_vector(15 downto 0);
        COMP_DATA_Q                 => comp_data_q                             ,--: out std_logic_vector(15 downto 0);
        COMP_USER                   => comp_user                                --: out std_logic_vector(15 downto 0)
    );

    u_PACKER : PRB_PACKER
    port map(
        CLK                         => CLK_UP                                  ,--: in  std_logic;
        RST                         => reset_bus                               ,--: in  std_logic;

        PARAM_RU_MAC                => PARAM_RU_MAC                            ,--: in  std_logic_array48(7 downto 0);
        PARAM_PORT_INDEX            => PARAM_PORT_INDEX                        ,--: in  std_logic_array3(7 downto 0);
        PARAM_DU_MAC                => PARAM_DU_MAC                            ,--: in  std_logic_array48(7 downto 0);
        PARAM_VLAN0_EN              => PARAM_VLAN0_EN                          ,--: in  std_logic_vector(7 downto 0);
        PARAM_VLAN0_VID             => PARAM_VLAN0_VID                         ,--: in  std_logic_array12(7 downto 0);
        PARAM_VLAN1_EN              => PARAM_VLAN1_EN                          ,--: in  std_logic_vector(7 downto 0);
        PARAM_VLAN1_VID             => PARAM_VLAN1_VID                         ,--: in  std_logic_array12(7 downto 0);

        RB_PE_INDEX                 => RB_PE_INDEX                             ,--: in  std_logic_vector(2 downto 0);
        RB_eAxC_ID                  => RB_eAxC_ID                              ,--: in  std_logic_vector(15 downto 0);
        RB_SEQUENCE_ID              => RB_SEQUENCE_ID                          ,--: in  std_logic_vector(15 downto 0);
        RB_HEADER_APP               => RB_HEADER_APP                           ,--: in  std_logic_vector(31 downto 0);
        RB_HEADER_APP_ACK           => RB_HEADER_APP_ACK                       ,--: out std_logic;
        RB_HEADER_SEC               => RB_HEADER_SEC                           ,--: in  std_logic_vector(31 downto 0);
        RB_HEADER_SEC_ACK           => RB_HEADER_SEC_ACK                       ,--: out std_logic;

        PE_TRANSMITTED              => PE_TRANSMITTED                          ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

        COMP_HDR                    => comp_hdr                                ,--: in  std_logic_vector(8 downto 0);
        COMP_PARAM                  => comp_param                              ,--: in  std_logic_vector(7 downto 0);

        COMP_VALID                  => comp_valid                              ,--: in  std_logic;
        COMP_TICK                   => comp_tick                               ,--: in  std_logic;
        COMP_DATA_I                 => comp_data_i                             ,--: in  std_logic_vector(15 downto 0);
        COMP_DATA_Q                 => comp_data_q                             ,--: in  std_logic_vector(15 downto 0);
        COMP_USER                   => comp_user                               ,--: in  std_logic_vector(15 downto 0);

        PACK_PORT_ID                => pack_port_id                            ,--: out std_logic_vector(2 downto 0);
        PACK_VLAN_MODE              => pack_vlan_mode                          ,--: out std_logic_vector(1 downto 0);
        PACK_LENGTH                 => pack_length                             ,--: out std_logic_vector(15 downto 0);

        PACK_VALID                  => pack_valid                              ,--: out std_logic;
        PACK_START                  => pack_start                              ,--: out std_logic;
        PACK_LAST                   => pack_last                               ,--: out std_logic;
        PACK_KEEP                   => pack_keep                               ,--: out std_logic_vector(3 downto 0);
        PACK_DATA                   => pack_data                                --: out std_logic_vector(31 downto 0)
    );

    u_PKT_GEN : PKT_GEN
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => RST                                     ,--: in  std_logic;

        CLK_UP                      => CLK_UP                                  ,--: in  std_logic;
        RST_UP                      => reset_bus                               ,--: in  std_logic;

        PACK_PORT_ID                => pack_port_id                            ,--: in  std_logic_vector(2 downto 0);
        PACK_VLAN_MODE              => pack_vlan_mode                          ,--: in  std_logic_vector(1 downto 0);
        PACK_LENGTH                 => pack_length                             ,--: in  std_logic_vector(15 downto 0);

        PACK_VALID                  => pack_valid                              ,--: in  std_logic;
        PACK_START                  => pack_start                              ,--: in  std_logic;
        PACK_LAST                   => pack_last                               ,--: in  std_logic;
        PACK_KEEP                   => pack_keep                               ,--: in  std_logic_vector(3 downto 0);
        PACK_DATA                   => pack_data                               ,--: in  std_logic_vector(31 downto 0);

        TX_VALID                    => tx_valid                                ,--: out std_logic;
        TX_START                    => open                                    ,--: out std_logic;
        TX_LAST                     => tx_last                                 ,--: out std_logic;
        TX_DEST                     => tx_dest                                 ,--: out std_logic_vector(2 downto 0);
        TX_KEEP                     => tx_keep                                 ,--: out std_logic_vector(7 downto 0);
        TX_DATA                     => tx_data                                  --: out std_logic_vector(63 downto 0)
    );

    u_TX_BUFFER : PKT_BUFFER
    generic map(
        NUM_OF_URAM                 => 1                                        --: natural := 1
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => RST                                     ,--: in  std_logic;

        USAGE_DATA_BUFFER           => USAGE_DATA_BUFFER                       ,--: out std_logic_vector(31 downto 0);

        CNT_TX                      => CNT_TX                                  ,--: out std_logic_vector(31 downto 0);
        CNT_LOST                    => CNT_LOST                                ,--: out std_logic_vector(31 downto 0);

        IN_VALID                    => tx_valid                                ,--: in  std_logic;
        IN_LAST                     => tx_last                                 ,--: in  std_logic;
        IN_DEST                     => tx_dest                                 ,--: in  std_logic_vector(2 downto 0);
        IN_KEEP                     => tx_keep                                 ,--: in  std_logic_vector(7 downto 0);
        IN_DATA                     => tx_data                                 ,--: in  std_logic_vector(63 downto 0);

        OUT0_READY                  => UP64_READY                              ,--: in  std_logic;
        OUT0_VALID                  => UP64_VALID                              ,--: out std_logic;
        OUT0_LAST                   => UP64_LAST                               ,--: out std_logic;
        OUT0_KEEP                   => UP64_KEEP                               ,--: out std_logic_vector(7 downto 0);
        OUT0_DATA                   => UP64_DATA                                --: out std_logic_vector(63 downto 0)
    );

end BEHAVE;