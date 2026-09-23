--------------------------------------------------------------------------------
--
-- Copyright (C) 2025, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2025.03.18
--------------------------------------------------------------------------------
-- Function description
--   1. FH interconnect
--   2. RX Input  : Ethernet + eCPRI + ORAN + Payload
--   3. RX Output : eCPRI + ORAN + Payload
--   4. TX Input  : Ethernet + eCPRI + ORAN + Payload
--   5. TX Output : Ethernet + eCPRI + ORAN + Payload
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2025.03.18) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.ARRAY_TYPE.ALL;
use WORK.PKG_ORAN.ALL;
use WORK.PKG_ORAN_ARRAY.ALL;

entity FH_INTERCONNECT is
    generic (
        IMPL_PDxCH                  : boolean := true;
        IMPL_SSB                    : boolean := false;
        IMPL_H_MATRIX               : boolean := false;
        IMPL_PUxCH                  : boolean := true;
        IMPL_PRACH                  : boolean := true;
        IMPL_SRS                    : boolean := false;
        IMPL_RIM_RS                 : boolean := false;
        IMPL_NB_IoT                 : boolean := false;

        MAX_PDxCH                   : natural := 4;
        MAX_SSB                     : natural := 0;
        MAX_H_MATRIX                : natural := 0;
        MAX_PUxCH                   : natural := 4;
        MAX_PRACH                   : natural := 4;
        MAX_SRS                     : natural := 0;
        MAX_RIM_RS                  : natural := 0;
        MAX_NB_IoT                  : natural := 0;

        NUM_PORT_TX                 : natural := 3                              -- Number of port for UL C/U-Plane
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK_MAC_RX                  : in  std_logic;                            -- 156.25/390.625-MHz
        CLK_MAC_TX                  : in  std_logic;                            -- 156.25/390.625-MHz
        CLK_BUS                     : in  std_logic;                            -- 245.76

        RST_RX                      : in  std_logic;                            -- SYNC@CLK_MAC_RX
        RST_RX_n                    : in  std_logic;                            -- SYNC@CLK_MAC_RX
        RST_TX                      : in  std_logic;                            -- SYNC@CLK_MAC_TX
        RST_TX_n                    : in  std_logic;                            -- SYNC@CLK_MAC_TX

--------------------------------------------------------------------------------
-- Debug
--------------------------------------------------------------------------------

        IGNORE_VLAN_VID             : in  std_logic;

--------------------------------------------------------------------------------
-- Sync
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------

        DL_PARAM_ID_EN              : in  std_logic_array64(7 downto 0);
        DL_PARAM_ID                 : in  std_logic_array64_array16(7 downto 0);
        DL_PE_INDEX                 : in  std_logic_array64_array8(7 downto 0);
        DL_SCS_CONFIG               : in  std_logic_array64_array4(7 downto 0);

        UL_PARAM_ID_EN              : in  std_logic_array64(7 downto 0);
        UL_PARAM_ID                 : in  std_logic_array64_array16(7 downto 0);
        UL_PE_INDEX                 : in  std_logic_array64_array8(7 downto 0);
        UL_SCS_CONFIG               : in  std_logic_array64_array4(7 downto 0);

        PARAM_DST_MAC               : in  std_logic_array48(7 downto 0);
        PARAM_SRC_MAC               : in  std_logic_array48(7 downto 0);
        PARAM_VLAN0_MODE            : in  std_logic_vector(7 downto 0);
        PARAM_VLAN0_VID             : in  std_logic_array12(7 downto 0);
        PARAM_VLAN1_MODE            : in  std_logic_vector(7 downto 0);
        PARAM_VLAN1_VID             : in  std_logic_array12(7 downto 0);

--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

        RX_PE_VALID                 : out std_logic_array32(7 downto 0);
        RX_INVALID_DST_MAC          : out std_logic_array32(7 downto 0);
        RX_INVALID_SRC_MAC          : out std_logic_array32(7 downto 0);
        RX_INVALID_VLAN_VID         : out std_logic_array32(7 downto 0);

        RX_DISCONTINUE              : out std_logic_vector(31 downto 0);
        RX_BYTE_SIZE                : out std_logic_vector(31 downto 0);
        RX_BYTE_ALIGN               : out std_logic_vector(31 downto 0);

        RX_DL_CP_POSITION           : out std_logic_array64(7 downto 0);
        RX_DL_UP_POSITION           : out std_logic_array64(7 downto 0);
        RX_UL_CP_POSITION           : out std_logic_array64(7 downto 0);

--------------------------------------------------------------------------------
-- MAC
--------------------------------------------------------------------------------

        MAC_RX_VALID                : in  std_logic;
        MAC_RX_LAST                 : in  std_logic;
        MAC_RX_KEEP                 : in  std_logic_vector(7 downto 0);
        MAC_RX_DATA                 : in  std_logic_vector(63 downto 0);

        MAC_TX_READY                : in  std_logic;
        MAC_TX_VALID                : out std_logic;
        MAC_TX_LAST                 : out std_logic;
        MAC_TX_KEEP                 : out std_logic_vector(7 downto 0);
        MAC_TX_DATA                 : out std_logic_vector(63 downto 0);

--------------------------------------------------------------------------------
-- Rx-window-stat
--------------------------------------------------------------------------------

        PACKET_IS_CP_DL             : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_CP_UL             : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_UP_DL             : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_NDM               : out std_logic;
        PACKET_SCS                  : out std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             : out std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          : out std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              : out std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            : out std_logic_vector(5 downto 0);

--------------------------------------------------------------------------------
-- ORAN interconnect
--------------------------------------------------------------------------------

        ORAN_RX_C64_VALID           : out std_logic;
        ORAN_RX_C64_LAST            : out std_logic;
        ORAN_RX_C64_KEEP            : out std_logic_vector(7 downto 0);
        ORAN_RX_C64_DATA            : out std_logic_vector(63 downto 0);
        ORAN_RX_C64_DATA_INDEX      : out std_logic_vector(2 downto 0);
        ORAN_RX_C64_LINK_MAP        : out std_logic_vector(15 downto 0);

        ORAN_RX_U64_VALID           : out std_logic;
        ORAN_RX_U64_LAST            : out std_logic;
        ORAN_RX_U64_KEEP            : out std_logic_vector(7 downto 0);
        ORAN_RX_U64_DATA            : out std_logic_vector(63 downto 0);
        ORAN_RX_U64_DATA_INDEX      : out std_logic_vector(2 downto 0);
        ORAN_RX_U64_LINK_MAP        : out std_logic_vector(15 downto 0);

        MAC_IC_TX_READY             : out std_logic_vector(NUM_PORT_TX-1 downto 0);
        MAC_IC_TX_VALID             : in  std_logic_vector(NUM_PORT_TX-1 downto 0);
        MAC_IC_TX_LAST              : in  std_logic_vector(NUM_PORT_TX-1 downto 0);
        MAC_IC_TX_KEEP              : in  std_logic_array8(NUM_PORT_TX-1 downto 0);
        MAC_IC_TX_DATA              : in  std_logic_array64(NUM_PORT_TX-1 downto 0);
        
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK_CPUIF                   : in  std_logic;
        RST_CPUIF                   : in  std_logic;

--------------------------------------------------------------------------------
-- Synchronization
--------------------------------------------------------------------------------

        N_TA_OFFSET                 : in  std_logic_vector(15 downto 0);
        RX_WINDOW_UPDATE_EN         : in  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        REF_10msec                  : in  std_logic;                            -- Longer than 1-clocks@245.76-MHz
        REF_SFN                     : in  std_logic_vector(7 downto 0);

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------        
        CAPTURE_PERIOD              : in std_logic_array8(7 downto 0);
                                      
        T2A_MAX_DL_CP_RX            : in std_logic_array5_array22(7 downto 0);
        T2A_MIN_DL_CP_RX            : in std_logic_array5_array22(7 downto 0);
        T2A_MAX_DL_UP_RX            : in std_logic_array5_array22(7 downto 0);
        T2A_MIN_DL_UP_RX            : in std_logic_array5_array22(7 downto 0);
        
        CNT_RX_CORRUPT                                          : out std_logic_array64(7 downto 0); 
        CNT_RX_SECTIONID                                        : out std_logic_array64(7 downto 0); 
        CNT_RX_PCID_eCPRIVERSION_PAYLOADVERSION                 : out std_logic_array64(7 downto 0); 
        CNT_RX_PCID                                             : out std_logic_array64(7 downto 0); 
        CNT_RX_eCPRIVERSION                                     : out std_logic_array64(7 downto 0); 
        CNT_RX_PAYLOADVERSION                                   : out std_logic_array64(7 downto 0)  
                
    );
end FH_INTERCONNECT;

architecture BEHAVE of FH_INTERCONNECT is

    component MAC_HDR_STAMP is
    generic (
        IMPL_CHECK_DST_MAC          : boolean := true;
        IMPL_CHECK_SRC_MAC          : boolean := false;
        IMPL_CHECK_VLAN_VID         : boolean := false
    );
    port (
        CLK                         : in  std_logic;

        IGNORE_VLAN_VID             : in  std_logic;

        PARAM_DST_MAC               : in  std_logic_array48(7 downto 0);
        PARAM_SRC_MAC               : in  std_logic_array48(7 downto 0);
        PARAM_VLAN0_MODE            : in  std_logic_vector(7 downto 0);
        PARAM_VLAN0_VID             : in  std_logic_array12(7 downto 0);
        PARAM_VLAN1_MODE            : in  std_logic_vector(7 downto 0);
        PARAM_VLAN1_VID             : in  std_logic_array12(7 downto 0);

        CNT_PE_VALID                : out std_logic_array32(7 downto 0);
        CNT_INVALID_DST_MAC         : out std_logic_array32(7 downto 0);
        CNT_INVALID_SRC_MAC         : out std_logic_array32(7 downto 0);
        CNT_INVALID_VLAN_VID        : out std_logic_array32(7 downto 0);

        IN_VALID                    : in  std_logic;
        IN_LAST                     : in  std_logic;
        IN_KEEP                     : in  std_logic_vector(7 downto 0);
        IN_DATA                     : in  std_logic_vector(63 downto 0);

        OUT_VALID                   : out std_logic;
        OUT_LAST                    : out std_logic;
        OUT_KEEP                    : out std_logic_vector(7 downto 0);
        OUT_DATA                    : out std_logic_vector(63 downto 0);

        OUT_PE_INDEX                : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        OUT_VLAN_MODE               : out std_logic_vector(1 downto 0)
    );
    end component;

    signal mac_hdr_stamp_valid      : std_logic;
    signal mac_hdr_stamp_last       : std_logic;
    signal mac_hdr_stamp_keep       : std_logic_vector(7 downto 0);
    signal mac_hdr_stamp_data       : std_logic_vector(63 downto 0);
    signal mac_hdr_stamp_pe_index   : std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
    signal mac_hdr_stamp_vlan_mode  : std_logic_vector(1 downto 0);

    component MAC_HDR_REMOVE is
    port (
        CLK                         : in  std_logic;

        IN_VALID                    : in  std_logic;
        IN_LAST                     : in  std_logic;
        IN_KEEP                     : in  std_logic_vector(7 downto 0);
        IN_DATA                     : in  std_logic_vector(63 downto 0);

        IN_PE_INDEX                 : in  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        IN_VLAN_MODE                : in  std_logic_vector(1 downto 0);

        OUT_VALID                   : out std_logic;
        OUT_LAST                    : out std_logic;
        OUT_KEEP                    : out std_logic_vector(7 downto 0);
        OUT_DATA                    : out std_logic_vector(63 downto 0);

        OUT_PE_INDEX                : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0)
    );
    end component;

    signal mac_hdr_remove_valid     : std_logic;
    signal mac_hdr_remove_last      : std_logic;
    signal mac_hdr_remove_keep      : std_logic_vector(7 downto 0);
    signal mac_hdr_remove_data      : std_logic_vector(63 downto 0);
    signal mac_hdr_remove_pe_index  : std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

    component ORAN_HDR_STAMP is
    generic (
        IMPL_PDxCH                  : boolean := true;
        IMPL_SSB                    : boolean := false;
        IMPL_H_MATRIX               : boolean := true;
        IMPL_PUxCH                  : boolean := true;
        IMPL_PRACH                  : boolean := true;
        IMPL_SRS                    : boolean := true;
        IMPL_RIM_RS                 : boolean := false;
        IMPL_NB_IoT                 : boolean := false;

        MAX_PDxCH                   : natural := 16;
        MAX_SSB                     : natural := 0;
        MAX_H_MATRIX                : natural := 1;
        MAX_PUxCH                   : natural := 16;
        MAX_PRACH                   : natural := 16;
        MAX_SRS                     : natural := 64;
        MAX_RIM_RS                  : natural := 0;
        MAX_NB_IoT                  : natural := 0
    );
    port (
        CLK                         : in  std_logic;
        CLK_BUS                     : in  std_logic;                            -- 245.76
        
        RST_RX                      : in  std_logic;                            -- SYNC@CLK_MAC_RX

        DL_PARAM_ID_EN              : in  std_logic_array64(7 downto 0);
        DL_PARAM_ID                 : in  std_logic_array64_array16(7 downto 0);
        DL_PE_INDEX                 : in  std_logic_array64_array8(7 downto 0);
        UL_PARAM_ID_EN              : in  std_logic_array64(7 downto 0);
        UL_PARAM_ID                 : in  std_logic_array64_array16(7 downto 0);
        UL_PE_INDEX                 : in  std_logic_array64_array8(7 downto 0);

        DL_SCS_CONFIG               : in  std_logic_array64_array4(7 downto 0);
        UL_SCS_CONFIG               : in  std_logic_array64_array4(7 downto 0);

        RX_DL_CP_POSITION           : out std_logic_array64(7 downto 0);
        RX_DL_UP_POSITION           : out std_logic_array64(7 downto 0);
        RX_UL_CP_POSITION           : out std_logic_array64(7 downto 0);

        MAC_IC_RX_VALID             : in  std_logic;
        MAC_IC_RX_LAST              : in  std_logic;
        MAC_IC_RX_KEEP              : in  std_logic_vector(7 downto 0);
        MAC_IC_RX_DATA              : in  std_logic_vector(63 downto 0);
        MAC_IC_RX_PE_INDEX          : in  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

        PACKET_IS_CP_DL             : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_CP_UL             : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_UP_DL             : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_NDM               : out std_logic;
        PACKET_SCS                  : out std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             : out std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          : out std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              : out std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            : out std_logic_vector(5 downto 0);

        ORAN_RX_C64_VALID           : out std_logic;
        ORAN_RX_C64_LAST            : out std_logic;
        ORAN_RX_C64_KEEP            : out std_logic_vector(7 downto 0);
        ORAN_RX_C64_DATA            : out std_logic_vector(63 downto 0);
        ORAN_RX_C64_DATA_INDEX      : out std_logic_vector(2 downto 0);
        ORAN_RX_C64_LINK_MAP        : out std_logic_vector(15 downto 0);

        ORAN_RX_U64_VALID           : out std_logic;
        ORAN_RX_U64_LAST            : out std_logic;
        ORAN_RX_U64_KEEP            : out std_logic_vector(7 downto 0);
        ORAN_RX_U64_DATA            : out std_logic_vector(63 downto 0);
        ORAN_RX_U64_DATA_INDEX      : out std_logic_vector(2 downto 0);
        ORAN_RX_U64_LINK_MAP        : out std_logic_vector(15 downto 0);
        
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK_CPUIF                   : in  std_logic;
        RST_CPUIF                   : in  std_logic;

--------------------------------------------------------------------------------
-- Synchronization
--------------------------------------------------------------------------------

        N_TA_OFFSET                 : in  std_logic_vector(15 downto 0);
        RX_WINDOW_UPDATE_EN         : in  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        REF_10msec                  : in  std_logic;                            -- Longer than 1-clocks@245.76-MHz
        REF_SFN                     : in  std_logic_vector(7 downto 0);

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------        
        CAPTURE_PERIOD              : in std_logic_array8(7 downto 0);
                                      
        T2A_MAX_DL_CP_RX            : in std_logic_array5_array22(7 downto 0);
        T2A_MIN_DL_CP_RX            : in std_logic_array5_array22(7 downto 0);
        T2A_MAX_DL_UP_RX            : in std_logic_array5_array22(7 downto 0);
        T2A_MIN_DL_UP_RX            : in std_logic_array5_array22(7 downto 0);
        
        CNT_RX_CORRUPT                                          : out std_logic_array64(7 downto 0); 
        CNT_RX_SECTIONID                                        : out std_logic_array64(7 downto 0); 
        CNT_RX_PCID_eCPRIVERSION_PAYLOADVERSION                 : out std_logic_array64(7 downto 0); 
        CNT_RX_PCID                                             : out std_logic_array64(7 downto 0); 
        CNT_RX_eCPRIVERSION                                     : out std_logic_array64(7 downto 0); 
        CNT_RX_PAYLOADVERSION                                   : out std_logic_array64(7 downto 0)              
    );
    end component;

    component MAC_TX_MUX is
    generic (
        TX_NUM                      : natural := 2
    );
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;
        RST_n                       : in  std_logic;

        IN_READY                    : out std_logic_vector(TX_NUM-1 downto 0);
        IN_VALID                    : in  std_logic_vector(TX_NUM-1 downto 0);
        IN_LAST                     : in  std_logic_vector(TX_NUM-1 downto 0);
        IN_KEEP                     : in  std_logic_array8(TX_NUM-1 downto 0);
        IN_DATA                     : in  std_logic_array64(TX_NUM-1 downto 0);

        OUT_READY                   : in  std_logic;
        OUT_VALID                   : out std_logic;
        OUT_LAST                    : out std_logic;
        OUT_KEEP                    : out std_logic_vector(7 downto 0);
        OUT_DATA                    : out std_logic_vector(63 downto 0)
    );
    end component;

    component AXIS_CHECKER is
    generic (
        BYTE_WIDTH                  : natural := 8;
        BIT_ORDER                   : string := "MSB"
    );
    port (
        CLK                         : in  std_logic;

        IN_READY                    : in  std_logic;
        IN_VALID                    : in  std_logic;
        IN_LAST                     : in  std_logic;
        IN_KEEP                     : in  std_logic_vector(BYTE_WIDTH-1 downto 0);

        CNT_DISCONTINUE             : out std_logic_vector(31 downto 0);
        CNT_BYTE_SIZE               : out std_logic_vector(31 downto 0);
        CNT_BYTE_ALIGN              : out std_logic_vector(31 downto 0)
    );
    end component;


begin

--------------------------------------------------------------------------------
-- RX (Downlink)
--------------------------------------------------------------------------------

    u_RX_HEADER_STAMP : MAC_HDR_STAMP
    generic map(
        IMPL_CHECK_DST_MAC          => IMPL_CHECK_DST_MAC                      ,--: boolean := true;
        IMPL_CHECK_SRC_MAC          => IMPL_CHECK_SRC_MAC                      ,--: boolean := false;
        IMPL_CHECK_VLAN_VID         => IMPL_CHECK_VLAN_VID                      --: boolean := false
    )
    port map(
        CLK                         => CLK_MAC_RX                              ,--: in  std_logic;

        IGNORE_VLAN_VID             => IGNORE_VLAN_VID                         ,--: in  std_logic;

        PARAM_DST_MAC               => PARAM_DST_MAC                           ,--: in  std_logic_array48(7 downto 0);
        PARAM_SRC_MAC               => PARAM_SRC_MAC                           ,--: in  std_logic_array48(7 downto 0);
        PARAM_VLAN0_MODE            => PARAM_VLAN0_MODE                        ,--: in  std_logic_vector(7 downto 0);
        PARAM_VLAN0_VID             => PARAM_VLAN0_VID                         ,--: in  std_logic_array12(7 downto 0);
        PARAM_VLAN1_MODE            => PARAM_VLAN1_MODE                        ,--: in  std_logic_vector(7 downto 0);
        PARAM_VLAN1_VID             => PARAM_VLAN1_VID                         ,--: in  std_logic_array12(7 downto 0);

        CNT_PE_VALID                => RX_PE_VALID                             ,--: out std_logic_array32(7 downto 0);
        CNT_INVALID_DST_MAC         => RX_INVALID_DST_MAC                      ,--: out std_logic_array32(7 downto 0);
        CNT_INVALID_SRC_MAC         => RX_INVALID_SRC_MAC                      ,--: out std_logic_array32(7 downto 0);
        CNT_INVALID_VLAN_VID        => RX_INVALID_VLAN_VID                     ,--: out std_logic_array32(7 downto 0);

        IN_VALID                    => MAC_RX_VALID                            ,--: in  std_logic;
        IN_LAST                     => MAC_RX_LAST                             ,--: in  std_logic;
        IN_KEEP                     => MAC_RX_KEEP                             ,--: in  std_logic_vector(7 downto 0);
        IN_DATA                     => MAC_RX_DATA                             ,--: in  std_logic_vector(63 downto 0);

        OUT_VALID                   => mac_hdr_stamp_valid                     ,--: out std_logic;
        OUT_LAST                    => mac_hdr_stamp_last                      ,--: out std_logic;
        OUT_KEEP                    => mac_hdr_stamp_keep                      ,--: out std_logic_vector(7 downto 0);
        OUT_DATA                    => mac_hdr_stamp_data                      ,--: out std_logic_vector(63 downto 0);

        OUT_PE_INDEX                => mac_hdr_stamp_pe_index                  ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        OUT_VLAN_MODE               => mac_hdr_stamp_vlan_mode                  --: out std_logic_vector(1 downto 0)
    );

    u_RX_HEADER_REMOVE : MAC_HDR_REMOVE
    port map(
        CLK                         => CLK_MAC_RX                              ,--: in  std_logic;

        IN_VALID                    => mac_hdr_stamp_valid                     ,--: in  std_logic;
        IN_LAST                     => mac_hdr_stamp_last                      ,--: in  std_logic;
        IN_KEEP                     => mac_hdr_stamp_keep                      ,--: in  std_logic_vector(7 downto 0);
        IN_DATA                     => mac_hdr_stamp_data                      ,--: in  std_logic_vector(63 downto 0);

        IN_PE_INDEX                 => mac_hdr_stamp_pe_index                  ,--: in  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        IN_VLAN_MODE                => mac_hdr_stamp_vlan_mode                 ,--: in  std_logic_vector(1 downto 0);

        OUT_VALID                   => mac_hdr_remove_valid                    ,--: out std_logic;
        OUT_LAST                    => mac_hdr_remove_last                     ,--: out std_logic;
        OUT_KEEP                    => mac_hdr_remove_keep                     ,--: out std_logic_vector(7 downto 0);
        OUT_DATA                    => mac_hdr_remove_data                     ,--: out std_logic_vector(63 downto 0);

        OUT_PE_INDEX                => mac_hdr_remove_pe_index                  --: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0)
    );

    u_ORAN_STAMP : ORAN_HDR_STAMP
    generic map(
        IMPL_PDxCH                  => IMPL_PDxCH                              ,--: boolean := true;
        IMPL_SSB                    => IMPL_SSB                                ,--: boolean := false;
        IMPL_H_MATRIX               => IMPL_H_MATRIX                           ,--: boolean := true;
        IMPL_PUxCH                  => IMPL_PUxCH                              ,--: boolean := true;
        IMPL_PRACH                  => IMPL_PRACH                              ,--: boolean := true;
        IMPL_SRS                    => IMPL_SRS                                ,--: boolean := true;
        IMPL_RIM_RS                 => IMPL_RIM_RS                             ,--: boolean := false;
        IMPL_NB_IoT                 => IMPL_NB_IoT                             ,--: boolean := false;

        MAX_PDxCH                   => MAX_PDxCH                               ,--: natural := 16;
        MAX_SSB                     => MAX_SSB                                 ,--: natural := 0;
        MAX_H_MATRIX                => MAX_H_MATRIX                            ,--: natural := 1;
        MAX_PUxCH                   => MAX_PUxCH                               ,--: natural := 16;
        MAX_PRACH                   => MAX_PRACH                               ,--: natural := 16;
        MAX_SRS                     => MAX_SRS                                 ,--: natural := 64;
        MAX_RIM_RS                  => MAX_RIM_RS                              ,--: natural := 0;
        MAX_NB_IoT                  => MAX_NB_IoT                               --: natural := 0
    )
    port map(
        CLK                         => CLK_MAC_RX                              ,--: in  std_logic;
        CLK_BUS                     => CLK_BUS                                 ,
       
        RST_RX                      => RST_RX                                  ,

        DL_PARAM_ID_EN              => DL_PARAM_ID_EN                          ,--: in  std_logic_array64(7 downto 0);
        DL_PARAM_ID                 => DL_PARAM_ID                             ,--: in  std_logic_array64_array16(7 downto 0);
        DL_PE_INDEX                 => DL_PE_INDEX                             ,--: in  std_logic_array64_array8(7 downto 0);
        UL_PARAM_ID_EN              => UL_PARAM_ID_EN                          ,--: in  std_logic_array64(7 downto 0);
        UL_PARAM_ID                 => UL_PARAM_ID                             ,--: in  std_logic_array64_array16(7 downto 0);
        UL_PE_INDEX                 => UL_PE_INDEX                             ,--: in  std_logic_array64_array8(7 downto 0);

        DL_SCS_CONFIG               => DL_SCS_CONFIG                           ,--: in  std_logic_array64_array4(7 downto 0);
        UL_SCS_CONFIG               => UL_SCS_CONFIG                           ,--: in  std_logic_array64_array4(7 downto 0);

        RX_DL_CP_POSITION           => RX_DL_CP_POSITION                       ,--: out std_logic_array64(7 downto 0);
        RX_DL_UP_POSITION           => RX_DL_UP_POSITION                       ,--: out std_logic_array64(7 downto 0);
        RX_UL_CP_POSITION           => RX_UL_CP_POSITION                       ,--: out std_logic_array64(7 downto 0);

        MAC_IC_RX_VALID             => mac_hdr_remove_valid                    ,--: in  std_logic;
        MAC_IC_RX_LAST              => mac_hdr_remove_last                     ,--: in  std_logic;
        MAC_IC_RX_KEEP              => mac_hdr_remove_keep                     ,--: in  std_logic_vector(7 downto 0);
        MAC_IC_RX_DATA              => mac_hdr_remove_data                     ,--: in  std_logic_vector(63 downto 0);
        MAC_IC_RX_PE_INDEX          => mac_hdr_remove_pe_index                 ,--: in  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

        PACKET_IS_CP_DL             => PACKET_IS_CP_DL                         ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_CP_UL             => PACKET_IS_CP_UL                         ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_UP_DL             => PACKET_IS_UP_DL                         ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_NDM               => PACKET_IS_NDM                           ,--: out std_logic;
        PACKET_SCS                  => PACKET_SCS                              ,--: out std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             => PACKET_FRAME_ID                         ,--: out std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          => PACKET_SUBFRAME_ID                      ,--: out std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              => PACKET_SLOT_ID                          ,--: out std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            => PACKET_SYMBOL_ID                        ,--: out std_logic_vector(5 downto 0);

        ORAN_RX_C64_VALID           => ORAN_RX_C64_VALID                       ,--: out std_logic;
        ORAN_RX_C64_LAST            => ORAN_RX_C64_LAST                        ,--: out std_logic;
        ORAN_RX_C64_KEEP            => ORAN_RX_C64_KEEP                        ,--: out std_logic_vector(7 downto 0);
        ORAN_RX_C64_DATA            => ORAN_RX_C64_DATA                        ,--: out std_logic_vector(63 downto 0);
        ORAN_RX_C64_DATA_INDEX      => ORAN_RX_C64_DATA_INDEX                  ,--: out std_logic_vector(2 downto 0);
        ORAN_RX_C64_LINK_MAP        => ORAN_RX_C64_LINK_MAP                    ,--: out std_logic_vector(15 downto 0);

        ORAN_RX_U64_VALID           => ORAN_RX_U64_VALID                       ,--: out std_logic;
        ORAN_RX_U64_LAST            => ORAN_RX_U64_LAST                        ,--: out std_logic;
        ORAN_RX_U64_KEEP            => ORAN_RX_U64_KEEP                        ,--: out std_logic_vector(7 downto 0);
        ORAN_RX_U64_DATA            => ORAN_RX_U64_DATA                        ,--: out std_logic_vector(63 downto 0);
        ORAN_RX_U64_DATA_INDEX      => ORAN_RX_U64_DATA_INDEX                  ,--: out std_logic_vector(2 downto 0);
        ORAN_RX_U64_LINK_MAP        => ORAN_RX_U64_LINK_MAP                    ,--: out std_logic_vector(15 downto 0)
        
        CLK_CPUIF                   => CLK_CPUIF                               ,--: in  std_logic;
        RST_CPUIF                   => RST_CPUIF                               ,--: in  std_logic;
       
        N_TA_OFFSET                 => N_TA_OFFSET                             ,--: in  std_logic_vector(15 downto 0);
        RX_WINDOW_UPDATE_EN         => RX_WINDOW_UPDATE_EN                     ,--: in  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

        REF_10msec                  => REF_10msec                              ,--: in  std_logic;
        REF_SFN                     => REF_SFN                                 ,--: in  std_logic_vector(7 downto 0);

        CAPTURE_PERIOD              => CAPTURE_PERIOD                          ,--: in  std_logic_vector(7 downto 0);

        T2A_MAX_DL_CP_RX            => T2A_MAX_DL_CP_RX                        ,--: in  std_logic_array22(4 downto 0);
        T2A_MIN_DL_CP_RX            => T2A_MIN_DL_CP_RX                        ,--: in  std_logic_array22(4 downto 0);
        T2A_MAX_DL_UP_RX            => T2A_MAX_DL_UP_RX                        ,--: in  std_logic_array22(4 downto 0);
        T2A_MIN_DL_UP_RX            => T2A_MIN_DL_UP_RX                        ,--: in  std_logic_array22(4 downto 0);
        
        CNT_RX_CORRUPT                          => CNT_RX_CORRUPT                           ,
        CNT_RX_SECTIONID                        => CNT_RX_SECTIONID                         ,
        CNT_RX_PCID_eCPRIVERSION_PAYLOADVERSION => CNT_RX_PCID_eCPRIVERSION_PAYLOADVERSION  ,
        CNT_RX_PCID                             => CNT_RX_PCID                              ,
        CNT_RX_eCPRIVERSION                     => CNT_RX_eCPRIVERSION                      ,
        CNT_RX_PAYLOADVERSION                   => CNT_RX_PAYLOADVERSION                            
    );

    u_AXIS_CHECK : AXIS_CHECKER
    generic map(
        BYTE_WIDTH                  => 8                                       ,--: natural := 8;
        BIT_ORDER                   => "LSB"                                    --: string := "MSB"
    )
    port map(
        CLK                         => CLK_MAC_RX                              ,--: in  std_logic;

        IN_READY                    => '1'                                     ,--: in  std_logic;
        IN_VALID                    => MAC_RX_VALID                            ,--: in  std_logic;
        IN_LAST                     => MAC_RX_LAST                             ,--: in  std_logic;
        IN_KEEP                     => MAC_RX_KEEP                             ,--: in  std_logic_vector(BYTE_WIDTH-1 downto 0);

        CNT_DISCONTINUE             => RX_DISCONTINUE                          ,--: out std_logic_vector(31 downto 0);
        CNT_BYTE_SIZE               => RX_BYTE_SIZE                            ,--: out std_logic_vector(31 downto 0);
        CNT_BYTE_ALIGN              => RX_BYTE_ALIGN                            --: out std_logic_vector(31 downto 0)
    );

--------------------------------------------------------------------------------
-- TX (Uplink)
--------------------------------------------------------------------------------

    u_TX : MAC_TX_MUX
    generic map(
        TX_NUM                      => NUM_PORT_TX                               --: natural := 2
    )
    port map(
        CLK                         => CLK_MAC_TX                              ,--: in  std_logic;
        RST                         => RST_TX                                  ,--: in  std_logic;
        RST_n                       => RST_TX_n                                ,--: in  std_logic;

        IN_READY                    => MAC_IC_TX_READY                         ,--: out std_logic_vector(TX_NUM-1 downto 0);
        IN_VALID                    => MAC_IC_TX_VALID                         ,--: in  std_logic_vector(TX_NUM-1 downto 0);
        IN_LAST                     => MAC_IC_TX_LAST                          ,--: in  std_logic_vector(TX_NUM-1 downto 0);
        IN_KEEP                     => MAC_IC_TX_KEEP                          ,--: in  std_logic_array8(TX_NUM-1 downto 0);
        IN_DATA                     => MAC_IC_TX_DATA                          ,--: in  std_logic_array64(TX_NUM-1 downto 0);

        OUT_READY                   => MAC_TX_READY                            ,--: in  std_logic;
        OUT_VALID                   => MAC_TX_VALID                            ,--: out std_logic;
        OUT_LAST                    => MAC_TX_LAST                             ,--: out std_logic;
        OUT_KEEP                    => MAC_TX_KEEP                             ,--: out std_logic_vector(7 downto 0);
        OUT_DATA                    => MAC_TX_DATA                              --: out std_logic_vector(63 downto 0)
    );

end BEHAVE;