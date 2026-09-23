--------------------------------------------------------------------------------
--
-- Copyright (C) 2025, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2025.03.18
--------------------------------------------------------------------------------
-- Function description
--   1. FH interconnect component
--   2. Stamping according to header information
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2025.03.18) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.ARRAY_TYPE.ALL;
use WORK.PKG_ORAN.ALL;
use WORK.PKG_ORAN_ARRAY.ALL;

entity ORAN_HDR_STAMP is
    generic (
        IMPL_PDxCH                  : boolean := true;
        IMPL_SSB                    : boolean := false;
        IMPL_H_MATRIX               : boolean := false;
        IMPL_PUxCH                  : boolean := true;
        IMPL_PRACH                  : boolean := true;
        IMPL_SRS                    : boolean := false;
        IMPL_RIM_RS                 : boolean := false;
        IMPL_NB_IoT                 : boolean := false;

        MAX_PDxCH                   : natural := 8;                             -- 0 ~ 64
        MAX_SSB                     : natural := 0;                             -- 0 ~ 64
        MAX_H_MATRIX                : natural := 0;                             -- 0 ~ 64
        MAX_PUxCH                   : natural := 8;                             -- 0 ~ 64
        MAX_PRACH                   : natural := 8;                             -- 0 ~ 64
        MAX_SRS                     : natural := 0;                             -- 0 ~ 64
        MAX_RIM_RS                  : natural := 0;                             -- 0 ~ 64
        MAX_NB_IoT                  : natural := 0                              -- 0 ~ 64
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;                            -- 156.25 or 390.625-MHz
        CLK_BUS                     : in  std_logic;                            -- 245.76

        RST_RX                      : in  std_logic;                            -- SYNC@CLK_MAC_RX
--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------

        DL_PARAM_ID_EN              : in  std_logic_array64(7 downto 0);
        DL_PARAM_ID                 : in  std_logic_array64_array16(7 downto 0);
        DL_PE_INDEX                 : in  std_logic_array64_array8(7 downto 0);
        UL_PARAM_ID_EN              : in  std_logic_array64(7 downto 0);
        UL_PARAM_ID                 : in  std_logic_array64_array16(7 downto 0);
        UL_PE_INDEX                 : in  std_logic_array64_array8(7 downto 0);

        DL_SCS_CONFIG               : in  std_logic_array64_array4(7 downto 0);
        UL_SCS_CONFIG               : in  std_logic_array64_array4(7 downto 0);

--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

        RX_DL_CP_POSITION           : out std_logic_array64(7 downto 0);
        RX_DL_UP_POSITION           : out std_logic_array64(7 downto 0);
        RX_UL_CP_POSITION           : out std_logic_array64(7 downto 0);

--------------------------------------------------------------------------------
-- MAC interconnect
--------------------------------------------------------------------------------

        MAC_IC_RX_VALID             : in  std_logic;
        MAC_IC_RX_LAST              : in  std_logic;
        MAC_IC_RX_KEEP              : in  std_logic_vector(7 downto 0);
        MAC_IC_RX_DATA              : in  std_logic_vector(63 downto 0);
        MAC_IC_RX_PE_INDEX          : in  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

--        MAC_IC_RX_OTHERS_VALID      : in  std_logic;
--        MAC_IC_RX_OTHERS_LAST       : in  std_logic;
--        MAC_IC_RX_OTHERS_KEEP       : in  std_logic_vector(7 downto 0);
--        MAC_IC_RX_OTHERS_DATA       : in  std_logic_vector(63 downto 0);

--------------------------------------------------------------------------------
-- Packet stamp
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
-- DL/UL C-Plane sectionType 1/3/5 (high byte is first)
--------------------------------------------------------------------------------
--        OUT_PE_INDEX                : out  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

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
end ORAN_HDR_STAMP;

architecture BEHAVE of ORAN_HDR_STAMP is

--    constant INDEX_PDxCH            : natural := TERNARY_FUNC(IMPL_PDxCH,    0,                0);
--    constant INDEX_SSB              : natural := TERNARY_FUNC(IMPL_SSB,      INDEX_PDxCH+1,    INDEX_PDxCH);
--    constant INDEX_H_MATRIX         : natural := TERNARY_FUNC(IMPL_H_MATRIX, INDEX_SSB+1,      INDEX_SSB);
--    constant INDEX_PUxCH            : natural := TERNARY_FUNC(IMPL_PUxCH,    INDEX_H_MATRIX+1, INDEX_H_MATRIX);
--    constant INDEX_PRACH            : natural := TERNARY_FUNC(IMPL_PRACH,    INDEX_PUxCH+1,    INDEX_PUxCH);
--    constant INDEX_SRS              : natural := TERNARY_FUNC(IMPL_SRS,      INDEX_PRACH+1,    INDEX_PRACH);
--    constant INDEX_RIM_RS           : natural := TERNARY_FUNC(IMPL_RIM_RS,   INDEX_SRS+1,      INDEX_SRS);
--    constant INDEX_NB_IoT           : natural := TERNARY_FUNC(IMPL_NB_IoT,   INDEX_RIM_RS+1,   INDEX_RIM_RS);

    constant MAX_SECTIONID_PER_PKT  :  natural range 0 to 100 := 32; --98;

    component ORAN_HDR_STAMP_UNIT is
    generic (
        IMPL_CP                     : boolean := true;
        IMPL_UP                     : boolean := true;

        LINK_DIRECTION              : std_logic := '0';
        DATA_INDEX                  : natural := 0;
        NUM_LINK                    : natural := 16
    );
    port (
        CLK                         : in  std_logic;

        PARAM_ID_EN                 : in  std_logic_vector(63 downto 0);
        PARAM_ID                    : in  std_logic_array16(63 downto 0);
        PE_INDEX                    : in  std_logic_array8(63 downto 0);
        SCS_CONFIG                  : in  std_logic_array4(63 downto 0);
        ENABLE_NDM                  : in  std_logic_vector(63 downto 0);

        CNTUP_INVALID_ecpriVersion  : out std_logic;
        CNTUP_INVALID_ecpriC        : out std_logic;
        CNTUP_INVALID_ecpriMessage  : out std_logic;

        CNTUP_LENGTH_IS_NORMAL      : out std_logic;
        CNTUP_LENGTH_IS_LONG        : out std_logic;
        CNTUP_LENGTH_IS_SHORT       : out std_logic;

        IN_VALID                    : in  std_logic;
        IN_LAST                     : in  std_logic;
        IN_KEEP                     : in  std_logic_vector(7 downto 0);
        IN_DATA                     : in  std_logic_vector(63 downto 0);
        IN_PE_INDEX                 : in  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        OUT_PE_INDEX                : out  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

        OUT_CP_VALID                : out std_logic;
        OUT_CP_LAST                 : out std_logic;
        OUT_CP_KEEP                 : out std_logic_vector(7 downto 0);
        OUT_CP_DATA                 : out std_logic_vector(63 downto 0);
        OUT_CP_INDEX                : out std_logic_vector(2 downto 0);
        OUT_CP_LINK_MAP             : out std_logic_vector(15 downto 0);

        OUT_UP_VALID                : out std_logic;
        OUT_UP_LAST                 : out std_logic;
        OUT_UP_KEEP                 : out std_logic_vector(7 downto 0);
        OUT_UP_DATA                 : out std_logic_vector(63 downto 0);
        OUT_UP_INDEX                : out std_logic_vector(2 downto 0);
        OUT_UP_LINK_MAP             : out std_logic_vector(15 downto 0);

        PACKET_IS_CP                : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_UP                : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_NDM               : out std_logic;
        PACKET_SCS                  : out std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             : out std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          : out std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              : out std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            : out std_logic_vector(5 downto 0)
    );
    end component;

--    signal cnt_invalid_ecpriversion : std_logic_vector(7 downto 0);
--    signal cnt_invalid_ecpric       : std_logic_vector(7 downto 0);
--    signal cnt_invalid_ecprimessage : std_logic_vector(7 downto 0);
--    signal cnt_length_is_normal     : std_logic_vector(7 downto 0);
--    signal cnt_length_is_long       : std_logic_vector(7 downto 0);
--    signal cnt_length_is_short      : std_logic_vector(7 downto 0);
    signal rx_cp_dl_valid           : std_logic_vector(2 downto 0);
    signal rx_cp_dl_last            : std_logic_vector(2 downto 0);
    signal rx_cp_dl_keep            : std_logic_array8(2 downto 0);
    signal rx_cp_dl_data            : std_logic_array64(2 downto 0);
    signal rx_cp_dl_index           : std_logic_array3(2 downto 0) := (others => (others => '0'));
    signal rx_cp_dl_link_map        : std_logic_array16(2 downto 0) := (others => (others => '0'));
    
    signal rx_cp_ul_valid           : std_logic_vector(7 downto 0);
    signal rx_cp_ul_last            : std_logic_vector(7 downto 0);
    signal rx_cp_ul_keep            : std_logic_array8(7 downto 0);
    signal rx_cp_ul_data            : std_logic_array64(7 downto 0);
    signal rx_cp_ul_index           : std_logic_array3(7 downto 0) := (others => (others => '0'));
    signal rx_cp_ul_link_map        : std_logic_array16(7 downto 0) := (others => (others => '0'));
    
    signal rx_up_valid              : std_logic;
    signal rx_up_last               : std_logic;
    signal rx_up_keep               : std_logic_vector(7 downto 0);
    signal rx_up_data               : std_logic_vector(63 downto 0);
    signal rx_up_index              : std_logic_array3(1 downto 0) := (others => (others => '0'));
    signal rx_up_link_map           : std_logic_array16(1 downto 0) := (others => (others => '0'));

    signal buf_cp_dl_valid       : std_logic;                        
    signal buf_cp_dl_last        : std_logic;                        
    signal buf_cp_dl_keep        : std_logic_vector(7 downto 0);     
    signal buf_cp_dl_data        : std_logic_vector(63 downto 0);    
    signal buf_cp_dl_index       : std_logic_vector(2 downto 0);     
    signal buf_cp_dl_link_map    : std_logic_vector(15 downto 0); 
    
    signal buf_up_dl_valid          : std_logic;                         
    signal buf_up_dl_last           : std_logic;                         
    signal buf_up_dl_keep           : std_logic_vector(7 downto 0);      
    signal buf_up_dl_data           : std_logic_vector(63 downto 0);     
    signal buf_up_dl_index          : std_logic_vector(2 downto 0);      
    signal buf_up_dl_link_map       : std_logic_vector(15 downto 0);       

    signal buf_rxcr_cp_up_dl_valid       : std_logic;                        
    signal buf_rxcr_cp_up_dl_last        : std_logic;                        
    signal buf_rxcr_cp_up_dl_keep        : std_logic_vector(7 downto 0);     
    signal buf_rxcr_cp_up_dl_data        : std_logic_vector(63 downto 0);    
    signal buf_rxcr_cp_up_dl_index       : std_logic_vector(2 downto 0);     
    signal buf_rxcr_cp_up_dl_link_map    : std_logic_vector(15 downto 0); 
    
    signal buf_rxcr_up_dl_valid          : std_logic;                         
    signal buf_rxcr_up_dl_last           : std_logic;                         
    signal buf_rxcr_up_dl_keep           : std_logic_vector(7 downto 0);      
    signal buf_rxcr_up_dl_data           : std_logic_vector(63 downto 0);     
    signal buf_rxcr_up_dl_index          : std_logic_vector(2 downto 0);      
    signal buf_rxcr_up_dl_link_map       : std_logic_vector(15 downto 0);     
    
    signal buf_rxcr_cp_dl_valid       : std_logic;                     
    signal buf_rxcr_cp_dl_last        : std_logic;                     
    signal buf_rxcr_cp_dl_keep        : std_logic_vector(7 downto 0);  
    signal buf_rxcr_cp_dl_data        : std_logic_vector(63 downto 0); 
    signal buf_rxcr_cp_dl_index       : std_logic_vector(2 downto 0);  
    signal buf_rxcr_cp_dl_link_map    : std_logic_vector(15 downto 0); 
    
    signal rx_packet_is_cp          : logic_array_pe(7 downto 0) := (others => (others => '0'));
    signal rx_packet_is_up          : logic_array_pe(7 downto 0) := (others => (others => '0'));
    signal rx_packet_is_ndm         : std_logic_vector(7 downto 0);
    signal rx_packet_scs            : std_logic_array4(7 downto 0);

    signal buf_rx_cp_valid          : std_logic;
    signal buf_rx_cp_last           : std_logic;
    signal buf_rx_cp_keep           : std_logic_vector(7 downto 0);
    signal buf_rx_cp_data           : std_logic_vector(63 downto 0);
    signal buf_rx_cp_index          : std_logic_vector(2 downto 0);
    signal buf_rx_cp_link_map       : std_logic_vector(15 downto 0);

    signal buf_rx_up_valid          : std_logic;
    signal buf_rx_up_last           : std_logic;
    signal buf_rx_up_keep           : std_logic_vector(7 downto 0);
    signal buf_rx_up_data           : std_logic_vector(63 downto 0);
    signal buf_rx_up_index          : std_logic_vector(2 downto 0);
    signal buf_rx_up_link_map       : std_logic_vector(15 downto 0);

    signal output_enable_cp_dl      : std_logic_vector(2 downto 0) := (others => '0');
    signal output_enable_cp_ul      : std_logic_vector(4 downto 0) := (others => '0');
    signal output_enable_up         : std_logic_vector(7 downto 0) := (others => '0');

    signal detect_cp_dl             : std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
    signal detect_cp_ul             : std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
    signal detect_up_dl             : std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

    signal s_pe_index               : std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
    signal s_pe_index_d             : std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
    signal s_pe_index_dd           : std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
    signal s_pe_index_ddd           : std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

    
    component RXCORRUPT_SECTIONID is   
    generic (
        MAX_SECTIONID_PER_PKT       : natural := 5;
        NUM_LINK                    : natural := 16
    );     
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;
        RST                         : in  std_logic;
                
        CLK_CDC                     : in  std_logic;

        PARAM_ID_EN                 : in  std_logic_vector(63 downto 0);
        PARAM_ID                    : in  std_logic_array16(63 downto 0);
        PE_INDEX                    : in  std_logic_array8(63 downto 0);
        SCS_CONFIG                  : in  std_logic_array4(63 downto 0);
        
--------------------------------------------------------------------------------
-- Input
--------------------------------------------------------------------------------

        IN_VALID                    : in  std_logic;
        IN_LAST                     : in  std_logic;
        IN_KEEP                     : in  std_logic_vector(7 downto 0);
        IN_DATA                     : in  std_logic_vector(63 downto 0);
        IN_PE_INDEX                 : in  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK_CPUIF                   : in  std_logic;
        RST_CPUIF                   : in  std_logic;

--------------------------------------------------------------------------------
-- Synchronization
--------------------------------------------------------------------------------

        N_TA_OFFSET                 : in  std_logic_vector(15 downto 0);

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

        RX_CORRUPT_SECTIONID        : out std_logic_vector(MAX_RU_ELEMENT -1 downto 0)                
                
    );
    end component;
    
    component RX_CORRUPT_PCID_eCPRI_Payload is
    generic (        
        NUM_LINK                    : natural := 16
    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------

        PARAM_ID_EN                 : in  std_logic_vector(63 downto 0);
        PARAM_ID                    : in  std_logic_array16(63 downto 0);
        PE_INDEX                    : in  std_logic_array8(63 downto 0);

--------------------------------------------------------------------------------
-- Input
--------------------------------------------------------------------------------

        IN_VALID                    : in  std_logic;
        IN_LAST                     : in  std_logic;
        IN_KEEP                     : in  std_logic_vector(7 downto 0);
        IN_DATA                     : in  std_logic_vector(63 downto 0);
        IN_PE_INDEX                 : in  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        
        RX_CORRUPT_OF_PE                            : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        RX_CORRUPT_PCID_eCPRIVERSION_PAYLOADVERSION : out std_logic;
        RX_CORRUPT_PCID                             : out std_logic;
        RX_CORRUPT_eCPRIVERSION                     : out std_logic;
        RX_CORRUPT_PAYLOADVERSION                   : out std_logic
    );
    end component;
    
    signal rx_corrupt_pe_indicator                          : std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
    signal s_rx_corrupt_ecpriversion_payloadversion_pcid    : std_logic := '0';
    signal s_rx_corrupt_pcid                                : std_logic;
    signal s_rx_corrupt_ecpri_version                       : std_logic;
    signal s_rx_corrupt_payload_version                     : std_logic;        
    signal s_rx_corrupt_sectionid_by_pe : std_logic_vector(MAX_RU_ELEMENT -1 downto 0) := (others => '0'); 

    component rx_corrupt_counter is
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK_CPUIF                   : in  std_logic;
        RST_CPUIF                   : in  std_logic;

        CLK_245p76MHz               : in  std_logic;                            -- 245.76-MHz

--------------------------------------------------------------------------------
-- Synchronization
--------------------------------------------------------------------------------

		UPDATE_EN_IN                   : in std_logic;
	
--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------
		RX_CORRUPT_OF_PE							: in std_logic;
		RX_CORRUPT_PCID_eCPRIVERSION_PAYLOADVERSION	: in std_logic;
        RX_CORRUPT_PCID                             : in std_logic;
        RX_CORRUPT_eCPRIVERSION                     : in std_logic;
        RX_CORRUPT_PAYLOADVERSION                   : in std_logic;

        RX_CORRUPT_SECTIONID        				: in std_logic;
        
        CNT_RX_CORRUPT                                          : out std_logic_vector(63 downto 0);
        CNT_RX_SECTIONID                                        : out std_logic_vector(63 downto 0);
        CNT_RX_PCID_eCPRIVERSION_PAYLOADVERSION                 : out std_logic_vector(63 downto 0);
        CNT_RX_PCID                                             : out std_logic_vector(63 downto 0);
        CNT_RX_eCPRIVERSION                                     : out std_logic_vector(63 downto 0);
        CNT_RX_PAYLOADVERSION                                   : out std_logic_vector(63 downto 0)
    );
    end component;
    
--    signal cnt_rx_corrupt                                   : std_logic_array64(MAX_RU_ELEMENT-1 downto 0);
--    signal cnt_rx_corrupt_sectionid                         : std_logic_array64(MAX_RU_ELEMENT-1 downto 0);
--    signal cnt_rx_corrupt_ecpriversion_payloadversion_pcid  : std_logic_array64(MAX_RU_ELEMENT-1 downto 0);
--    signal cnt_rx_corrupt_ecpriversion                      : std_logic_array64(MAX_RU_ELEMENT-1 downto 0);
--    signal cnt_rx_corrupt_pcid                              : std_logic_array64(MAX_RU_ELEMENT-1 downto 0);
--    signal cnt_rx_corrupt_payloadversion                    : std_logic_array64(MAX_RU_ELEMENT-1 downto 0);
    
begin

--------------------------------------------------------------------------------
-- RX stamp
--------------------------------------------------------------------------------

    u_PDxCH : if IMPL_PDxCH = true generate
    u_RX_HDR_STAMP : ORAN_HDR_STAMP_UNIT
    generic map(
        IMPL_CP                     => true                                    ,--: boolean := true;
        IMPL_UP                     => true                                    ,--: boolean := true;

        LINK_DIRECTION              => TX_LINK_DIRECTION                       ,--: std_logic := '0';
        DATA_INDEX                  => INDEX_PDxCH                             ,--: natural := 0;
        NUM_LINK                    => MAX_PDxCH                                --: natural := 16
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;

        PARAM_ID_EN                 => DL_PARAM_ID_EN(0)                       ,--: in  std_logic_vector(63 downto 0);
        PARAM_ID                    => DL_PARAM_ID(0)                          ,--: in  std_logic_array16(63 downto 0);
        PE_INDEX                    => DL_PE_INDEX(0)                          ,--: in  std_logic_array8(63 downto 0);
        SCS_CONFIG                  => DL_SCS_CONFIG(0)                        ,--: in  std_logic_array4(63 downto 0);
        ENABLE_NDM                  => (others => '0')                         ,--: in  std_logic_vector(63 downto 0);

        CNTUP_INVALID_ecpriVersion  => open                                    ,--: out std_logic;
        CNTUP_INVALID_ecpriC        => open                                    ,--: out std_logic;
        CNTUP_INVALID_ecpriMessage  => open                                    ,--: out std_logic;

        CNTUP_LENGTH_IS_NORMAL      => open                                    ,--: out std_logic;
        CNTUP_LENGTH_IS_LONG        => open                                    ,--: out std_logic;
        CNTUP_LENGTH_IS_SHORT       => open                                    ,--: out std_logic;

        IN_VALID                    => MAC_IC_RX_VALID                         ,--: in  std_logic;
        IN_LAST                     => MAC_IC_RX_LAST                          ,--: in  std_logic;
        IN_KEEP                     => MAC_IC_RX_KEEP                          ,--: in  std_logic_vector(7 downto 0);
        IN_DATA                     => MAC_IC_RX_DATA                          ,--: in  std_logic_vector(63 downto 0);
        IN_PE_INDEX                 => MAC_IC_RX_PE_INDEX                      ,--: in  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

        OUT_PE_INDEX                => s_pe_index                              ,
        
        OUT_CP_VALID                => rx_cp_dl_valid(0)                       ,--: out std_logic;
        OUT_CP_LAST                 => rx_cp_dl_last(0)                        ,--: out std_logic;
        OUT_CP_KEEP                 => rx_cp_dl_keep(0)                        ,--: out std_logic_vector(7 downto 0);
        OUT_CP_DATA                 => rx_cp_dl_data(0)                        ,--: out std_logic_vector(63 downto 0);
        OUT_CP_INDEX                => rx_cp_dl_index(0)                       ,--: out std_logic_vector(2 downto 0);
        OUT_CP_LINK_MAP             => rx_cp_dl_link_map(0)                    ,--: out std_logic_vector(15 downto 0);

        OUT_UP_VALID                => rx_up_valid                             ,--: out std_logic;
        OUT_UP_LAST                 => rx_up_last                              ,--: out std_logic;
        OUT_UP_KEEP                 => rx_up_keep                              ,--: out std_logic_vector(7 downto 0);
        OUT_UP_DATA                 => rx_up_data                              ,--: out std_logic_vector(63 downto 0);
        OUT_UP_INDEX                => rx_up_index(0)                          ,--: out std_logic_vector(2 downto 0);
        OUT_UP_LINK_MAP             => rx_up_link_map(0)                       ,--: out std_logic_vector(15 downto 0);

        PACKET_IS_CP                => rx_packet_is_cp(0)                      ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_UP                => rx_packet_is_up(0)                      ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_NDM               => rx_packet_is_ndm(0)                     ,--: out std_logic;
        PACKET_SCS                  => rx_packet_scs(0)                        ,--: out std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             => PACKET_FRAME_ID                         ,--: out std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          => PACKET_SUBFRAME_ID                      ,--: out std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              => PACKET_SLOT_ID                          ,--: out std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            => PACKET_SYMBOL_ID                         --: out std_logic_vector(5 downto 0)
    );
    end generate;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            buf_cp_dl_valid      <= rx_cp_dl_valid(0)   ; 
            buf_cp_dl_last       <= rx_cp_dl_last(0)    ; 
            buf_cp_dl_keep       <= rx_cp_dl_keep(0)    ; 
            buf_cp_dl_data       <= rx_cp_dl_data(0)    ; 
            buf_cp_dl_index      <= rx_cp_dl_index(0)   ; 
            buf_cp_dl_link_map   <= rx_cp_dl_link_map(0);            

            buf_up_dl_valid      <= rx_up_valid      ;  
            buf_up_dl_last       <= rx_up_last       ;  
            buf_up_dl_keep       <= rx_up_keep       ;  
            buf_up_dl_data       <= rx_up_data       ;  
            buf_up_dl_index      <= rx_up_index(0)   ;  
            buf_up_dl_link_map   <= rx_up_link_map(0);       
                         
        end if;
    end process;
    
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (output_enable_cp_dl = 0) then
                buf_rxcr_cp_dl_valid      <= '0';
                buf_rxcr_cp_dl_last       <= '0';
                buf_rxcr_cp_dl_keep       <= (others => '0');
                buf_rxcr_cp_dl_data       <= (others => '0');
                buf_rxcr_cp_dl_index      <= (others => '0');
                buf_rxcr_cp_dl_link_map   <= (others => '0');
            else
                buf_rxcr_cp_dl_valid      <=  buf_cp_dl_valid   ;
                buf_rxcr_cp_dl_last       <=  buf_cp_dl_last    ;
                buf_rxcr_cp_dl_keep       <=  buf_cp_dl_keep    ;
                buf_rxcr_cp_dl_data       <=  buf_cp_dl_data    ;
                buf_rxcr_cp_dl_index      <=  buf_cp_dl_index   ;
                buf_rxcr_cp_dl_link_map   <=  buf_cp_dl_link_map;            
            end if;    
        end if;
    end process;
    
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (output_enable_up = 0) then
                buf_rxcr_up_dl_valid      <= '0';
                buf_rxcr_up_dl_last       <= '0';
                buf_rxcr_up_dl_keep       <= (others => '0');
                buf_rxcr_up_dl_data       <= (others => '0');
                buf_rxcr_up_dl_index      <= (others => '0');
                buf_rxcr_up_dl_link_map   <= (others => '0');
            else
                buf_rxcr_up_dl_valid      <=  buf_up_dl_valid   ;
                buf_rxcr_up_dl_last       <=  buf_up_dl_last    ;
                buf_rxcr_up_dl_keep       <=  buf_up_dl_keep    ;
                buf_rxcr_up_dl_data       <=  buf_up_dl_data    ;
                buf_rxcr_up_dl_index      <=  buf_up_dl_index   ;
                buf_rxcr_up_dl_link_map   <=  buf_up_dl_link_map;            
            end if;    
        end if;
    end process;
    
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            buf_rxcr_cp_up_dl_valid      <= buf_rxcr_cp_dl_valid    or  buf_rxcr_up_dl_valid   ;
            buf_rxcr_cp_up_dl_last       <= buf_rxcr_cp_dl_last     or  buf_rxcr_up_dl_last    ;
            buf_rxcr_cp_up_dl_keep       <= buf_rxcr_cp_dl_keep     or  buf_rxcr_up_dl_keep    ;
            buf_rxcr_cp_up_dl_data       <= buf_rxcr_cp_dl_data     or  buf_rxcr_up_dl_data    ;
            buf_rxcr_cp_up_dl_index      <= buf_rxcr_cp_dl_index    or  buf_rxcr_up_dl_index   ;
            buf_rxcr_cp_up_dl_link_map   <= buf_rxcr_cp_dl_link_map or  buf_rxcr_up_dl_link_map;           
            s_pe_index_d                 <= s_pe_index;
            s_pe_index_dd                <= s_pe_index_d;
            s_pe_index_ddd               <= s_pe_index_dd;     
        end if;
    end process;
         
    u_RXCORRUPT_SECTIONID : RXCORRUPT_SECTIONID
    generic map(
        MAX_SECTIONID_PER_PKT       => MAX_SECTIONID_PER_PKT,
        NUM_LINK                    => MAX_PDxCH
    )
    port map (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         => CLK               , --: in  std_logic;
        RST                         => RST_RX            ,
        CLK_CDC                     => CLK_BUS           ,
        PARAM_ID_EN                 => DL_PARAM_ID_EN(0)   , --: in  std_logic_vector(63 downto 0);
        PARAM_ID                    => DL_PARAM_ID(0)      , --: in  std_logic_array16(63 downto 0);
        PE_INDEX                    => DL_PE_INDEX(0)      , --: in  std_logic_array8(63 downto 0);
        SCS_CONFIG                  => DL_SCS_CONFIG(0)    , --: in  std_logic_array4(63 downto 0);
                
--------------------------------------------------------------------------------
-- Input
--------------------------------------------------------------------------------

        IN_VALID                    => buf_rxcr_cp_up_dl_valid      , --: in  std_logic;
        IN_LAST                     => buf_rxcr_cp_up_dl_last       , --: in  std_logic;
        IN_KEEP                     => buf_rxcr_cp_up_dl_keep       , --: in  std_logic_vector(7 downto 0);
        IN_DATA                     => buf_rxcr_cp_up_dl_data       , --: in  std_logic_vector(63 downto 0);
        IN_PE_INDEX                 => s_pe_index_ddd               , --: in  std_logic_vector(MAX_RU_ELEMENT-1 downto 0)
        
        CLK_CPUIF                   => CLK_CPUIF                               ,--: in  std_logic;
        RST_CPUIF                   => RST_CPUIF                               ,--: in  std_logic;
       
        N_TA_OFFSET                 => N_TA_OFFSET                             ,--: in  std_logic_vector(15 downto 0);

        REF_10msec                  => REF_10msec                              ,--: in  std_logic;
        REF_SFN                     => REF_SFN                                 ,--: in  std_logic_vector(7 downto 0);

        CAPTURE_PERIOD              => CAPTURE_PERIOD                          ,--: in  std_logic_vector(7 downto 0);

        T2A_MAX_DL_CP_RX            => T2A_MAX_DL_CP_RX                        ,--: in  std_logic_array22(4 downto 0);
        T2A_MIN_DL_CP_RX            => T2A_MIN_DL_CP_RX                        ,--: in  std_logic_array22(4 downto 0);
        T2A_MAX_DL_UP_RX            => T2A_MAX_DL_UP_RX                        ,--: in  std_logic_array22(4 downto 0);
        T2A_MIN_DL_UP_RX            => T2A_MIN_DL_UP_RX                        ,--: in  std_logic_array22(4 downto 0);
        
        RX_CORRUPT_SECTIONID        => s_rx_corrupt_sectionid_by_pe       
    );
    
    u_RX_CORRUPT_PCID_eCPRI_Payload : RX_CORRUPT_PCID_eCPRI_Payload
    generic map(
        NUM_LINK                    => MAX_PDxCH                                --: natural := 16
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;

        PARAM_ID_EN                 => DL_PARAM_ID_EN(0)                       ,--: in  std_logic_vector(63 downto 0);
        PARAM_ID                    => DL_PARAM_ID(0)                          ,--: in  std_logic_array16(63 downto 0);
        PE_INDEX                    => DL_PE_INDEX(0)                          ,--: in  std_logic_array8(63 downto 0);
        
        IN_VALID                    => MAC_IC_RX_VALID                         ,--: in  std_logic;
        IN_LAST                     => MAC_IC_RX_LAST                          ,--: in  std_logic;
        IN_KEEP                     => MAC_IC_RX_KEEP                          ,--: in  std_logic_vector(7 downto 0);
        IN_DATA                     => MAC_IC_RX_DATA                          ,--: in  std_logic_vector(63 downto 0);
        IN_PE_INDEX                 => MAC_IC_RX_PE_INDEX                      ,--: in  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        
        RX_CORRUPT_OF_PE                            => rx_corrupt_pe_indicator,--
        RX_CORRUPT_PCID_eCPRIVERSION_PAYLOADVERSION => s_rx_corrupt_ecpriversion_payloadversion_pcid, --: out std_logic;
        RX_CORRUPT_PCID                             => s_rx_corrupt_pcid                            , --: out std_logic;
        RX_CORRUPT_eCPRIVERSION                     => s_rx_corrupt_ecpri_version                   , --: out std_logic;
        RX_CORRUPT_PAYLOADVERSION                   => s_rx_corrupt_payload_version                  --: out std_logic        
    );
    
    u_MEASUREMENT_by_PE : for i in MAX_RU_ELEMENT-1 downto 0 generate

    u_RX_CORRUPT_CNT: rx_corrupt_counter 
    port map (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK_CPUIF                   => CLK_CPUIF                               ,--: in  std_logic;
        RST_CPUIF                   => RST_CPUIF                               ,--: in  std_logic;

        CLK_245p76MHz               => CLK_BUS                                 ,--: in  std_logic;                            -- 245.76-MHz


--------------------------------------------------------------------------------
-- Synchronization
--------------------------------------------------------------------------------        
        UPDATE_EN_IN                => RX_WINDOW_UPDATE_EN(i),--output_update_en(0)                      ,--: in std_logic;
	
--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------
		RX_CORRUPT_OF_PE                            => rx_corrupt_pe_indicator(i),
		RX_CORRUPT_PCID_eCPRIVERSION_PAYLOADVERSION	=> s_rx_corrupt_ecpriversion_payloadversion_pcid      ,--: in std_logic;
        RX_CORRUPT_PCID                             => s_rx_corrupt_pcid                                  ,
        RX_CORRUPT_eCPRIVERSION                     => s_rx_corrupt_ecpri_version                         ,
        RX_CORRUPT_PAYLOADVERSION                   => s_rx_corrupt_payload_version                       ,
       
        RX_CORRUPT_SECTIONID        				=> s_rx_corrupt_sectionid_by_pe(i)                    ,--: in std_logic_vector(DL_UNIT-1 downto 0);

        CNT_RX_CORRUPT                              => CNT_RX_CORRUPT(i)                           ,--cnt_rx_corrupt(i)                                     ,--: out std_logic_vector(63 downto 0)
        CNT_RX_SECTIONID                            => CNT_RX_SECTIONID(i)                         ,--cnt_rx_corrupt_sectionid(i)                           ,
        CNT_RX_PCID_eCPRIVERSION_PAYLOADVERSION     => CNT_RX_PCID_eCPRIVERSION_PAYLOADVERSION(i)  ,--cnt_rx_corrupt_ecpriversion_payloadversion_pcid(i)    ,
        CNT_RX_PCID                                 => CNT_RX_PCID(i)                              ,--cnt_rx_corrupt_pcid(i)                                ,
        CNT_RX_eCPRIVERSION                         => CNT_RX_eCPRIVERSION(i)                      ,--cnt_rx_corrupt_ecpriversion(i)                        ,      
        CNT_RX_PAYLOADVERSION                       => CNT_RX_PAYLOADVERSION(i)                     --cnt_rx_corrupt_payloadversion(i)                    
    );
    end generate;

    u_PDxCH_UNUSED : if IMPL_PDxCH = false generate
    rx_cp_dl_valid(0)               <= '0';
    rx_cp_dl_last(0)                <= '0';
    rx_cp_dl_keep(0)                <= (others => '0');
    rx_cp_dl_data(0)                <= (others => '0');
    rx_cp_dl_index(0)               <= (others => '0');
    rx_cp_dl_link_map(0)            <= (others => '0');
    rx_up_valid                     <= '0';
    rx_up_last                      <= '0';
    rx_up_keep                      <= (others => '0');
    rx_up_data                      <= (others => '0');
    rx_up_index(0)                  <= (others => '0');
    rx_up_link_map(0)               <= (others => '0');
    rx_packet_is_cp(0)              <= (others => '0');
    rx_packet_is_up(0)              <= (others => '0');
    rx_packet_is_ndm(0)             <= '0';
    rx_packet_scs(0)                <= (others => '0');
    end generate;

    u_SSB : if IMPL_SSB = true generate
    u_RX_HDR_STAMP : ORAN_HDR_STAMP_UNIT
    generic map(
        IMPL_CP                     => true                                    ,--: boolean := true;
        IMPL_UP                     => true                                    ,--: boolean := true;

        LINK_DIRECTION              => TX_LINK_DIRECTION                       ,--: std_logic := '0';
        DATA_INDEX                  => INDEX_SSB                               ,--: natural := 0;
        NUM_LINK                    => MAX_SSB                                  --: natural := 16
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;

        PARAM_ID_EN                 => DL_PARAM_ID_EN(1)                       ,--: in  std_logic_vector(63 downto 0);
        PARAM_ID                    => DL_PARAM_ID(1)                          ,--: in  std_logic_array16(63 downto 0);
        PE_INDEX                    => DL_PE_INDEX(1)                          ,--: in  std_logic_array8(63 downto 0);
        SCS_CONFIG                  => DL_SCS_CONFIG(1)                        ,--: in  std_logic_array4(63 downto 0);
        ENABLE_NDM                  => (others => '0')                         ,--: in  std_logic_vector(63 downto 0);

        CNTUP_INVALID_ecpriVersion  => open                                    ,--: out std_logic;
        CNTUP_INVALID_ecpriC        => open                                    ,--: out std_logic;
        CNTUP_INVALID_ecpriMessage  => open                                    ,--: out std_logic;

        CNTUP_LENGTH_IS_NORMAL      => open                                    ,--: out std_logic;
        CNTUP_LENGTH_IS_LONG        => open                                    ,--: out std_logic;
        CNTUP_LENGTH_IS_SHORT       => open                                    ,--: out std_logic;

        IN_VALID                    => MAC_IC_RX_VALID                         ,--: in  std_logic;
        IN_LAST                     => MAC_IC_RX_LAST                          ,--: in  std_logic;
        IN_KEEP                     => MAC_IC_RX_KEEP                          ,--: in  std_logic_vector(7 downto 0);
        IN_DATA                     => MAC_IC_RX_DATA                          ,--: in  std_logic_vector(63 downto 0);
        IN_PE_INDEX                 => MAC_IC_RX_PE_INDEX                      ,--: in  std_logic_vector(2 downto 0);
        OUT_PE_INDEX                => open                                    ,

        OUT_CP_VALID                => rx_cp_dl_valid(1)                       ,--: out std_logic;
        OUT_CP_LAST                 => rx_cp_dl_last(1)                        ,--: out std_logic;
        OUT_CP_KEEP                 => rx_cp_dl_keep(1)                        ,--: out std_logic_vector(7 downto 0);
        OUT_CP_DATA                 => rx_cp_dl_data(1)                        ,--: out std_logic_vector(63 downto 0);
        OUT_CP_INDEX                => rx_cp_dl_index(1)                       ,--: out std_logic_vector(2 downto 0);
        OUT_CP_LINK_MAP             => rx_cp_dl_link_map(1)                    ,--: out std_logic_vector(15 downto 0);

        OUT_UP_VALID                => open                                    ,--: out std_logic;
        OUT_UP_LAST                 => open                                    ,--: out std_logic;
        OUT_UP_KEEP                 => open                                    ,--: out std_logic_vector(7 downto 0);
        OUT_UP_DATA                 => open                                    ,--: out std_logic_vector(63 downto 0);
        OUT_UP_INDEX                => rx_up_index(1)                          ,--: out std_logic_vector(2 downto 0);
        OUT_UP_LINK_MAP             => rx_up_link_map(1)                       ,--: out std_logic_vector(15 downto 0);

        PACKET_IS_CP                => rx_packet_is_cp(1)                      ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_UP                => rx_packet_is_up(1)                      ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_NDM               => rx_packet_is_ndm(1)                     ,--: out std_logic;
        PACKET_SCS                  => rx_packet_scs(1)                        ,--: out std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             => open                                    ,--: out std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          => open                                    ,--: out std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              => open                                    ,--: out std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            => open                                     --: out std_logic_vector(5 downto 0)
    );
    end generate;

    u_SSB_UNUSED : if IMPL_SSB = false generate
    rx_cp_dl_valid(1)               <= '0';
    rx_cp_dl_last(1)                <= '0';
    rx_cp_dl_keep(1)                <= (others => '0');
    rx_cp_dl_data(1)                <= (others => '0');
    rx_cp_dl_index(1)               <= (others => '0');
    rx_cp_dl_link_map(1)            <= (others => '0');
--    rx_up_valid                     <= '0';
--    rx_up_last                      <= '0';
--    rx_up_keep                      <= (others => '0');
--    rx_up_data                      <= (others => '0');
    rx_up_index(1)                  <= (others => '0');
    rx_up_link_map(1)               <= (others => '0');
    rx_packet_is_cp(1)              <= (others => '0');
    rx_packet_is_up(1)              <= (others => '0');
    rx_packet_is_ndm(1)             <= '0';
    rx_packet_scs(1)                <= (others => '0');
    end generate;

    u_H_MATRIX : if IMPL_H_MATRIX = true generate
    u_RX_HDR_STAMP : ORAN_HDR_STAMP_UNIT
    generic map(
        IMPL_CP                     => true                                    ,--: boolean := true;
        IMPL_UP                     => false                                   ,--: boolean := true;

        LINK_DIRECTION              => TX_LINK_DIRECTION                       ,--: std_logic := '0';
        DATA_INDEX                  => INDEX_H_MATRIX                          ,--: natural := 0;
        NUM_LINK                    => MAX_H_MATRIX                             --: natural := 16
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;

        PARAM_ID_EN                 => DL_PARAM_ID_EN(2)                       ,--: in  std_logic_vector(63 downto 0);
        PARAM_ID                    => DL_PARAM_ID(2)                          ,--: in  std_logic_array16(63 downto 0);
        PE_INDEX                    => DL_PE_INDEX(2)                          ,--: in  std_logic_array8(63 downto 0);
        SCS_CONFIG                  => DL_SCS_CONFIG(2)                        ,--: in  std_logic_array4(63 downto 0);
        ENABLE_NDM                  => (others => '1')                         ,--: in  std_logic_vector(63 downto 0);

        CNTUP_INVALID_ecpriVersion  => open                                    ,--: out std_logic;
        CNTUP_INVALID_ecpriC        => open                                    ,--: out std_logic;
        CNTUP_INVALID_ecpriMessage  => open                                    ,--: out std_logic;

        CNTUP_LENGTH_IS_NORMAL      => open                                    ,--: out std_logic;
        CNTUP_LENGTH_IS_LONG        => open                                    ,--: out std_logic;
        CNTUP_LENGTH_IS_SHORT       => open                                    ,--: out std_logic;

        IN_VALID                    => MAC_IC_RX_VALID                         ,--: in  std_logic;
        IN_LAST                     => MAC_IC_RX_LAST                          ,--: in  std_logic;
        IN_KEEP                     => MAC_IC_RX_KEEP                          ,--: in  std_logic_vector(7 downto 0);
        IN_DATA                     => MAC_IC_RX_DATA                          ,--: in  std_logic_vector(63 downto 0);
        IN_PE_INDEX                 => MAC_IC_RX_PE_INDEX                      ,--: in  std_logic_vector(2 downto 0);
        OUT_PE_INDEX                => open                                    ,

        OUT_CP_VALID                => rx_cp_dl_valid(2)                       ,--: out std_logic;
        OUT_CP_LAST                 => rx_cp_dl_last(2)                        ,--: out std_logic;
        OUT_CP_KEEP                 => rx_cp_dl_keep(2)                        ,--: out std_logic_vector(7 downto 0);
        OUT_CP_DATA                 => rx_cp_dl_data(2)                        ,--: out std_logic_vector(63 downto 0);
        OUT_CP_INDEX                => rx_cp_dl_index(2)                       ,--: out std_logic_vector(2 downto 0);
        OUT_CP_LINK_MAP             => rx_cp_dl_link_map(2)                    ,--: out std_logic_vector(15 downto 0);

        OUT_UP_VALID                => open                                    ,--: out std_logic;
        OUT_UP_LAST                 => open                                    ,--: out std_logic;
        OUT_UP_KEEP                 => open                                    ,--: out std_logic_vector(7 downto 0);
        OUT_UP_DATA                 => open                                    ,--: out std_logic_vector(63 downto 0);
        OUT_UP_INDEX                => open                                    ,--: out std_logic_vector(2 downto 0);
        OUT_UP_LINK_MAP             => open                                    ,--: out std_logic_vector(15 downto 0);

        PACKET_IS_CP                => rx_packet_is_cp(2)                      ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_UP                => rx_packet_is_up(2)                      ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_NDM               => rx_packet_is_ndm(2)                     ,--: out std_logic;
        PACKET_SCS                  => rx_packet_scs(2)                        ,--: out std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             => open                                    ,--: out std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          => open                                    ,--: out std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              => open                                    ,--: out std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            => open                                     --: out std_logic_vector(5 downto 0)
    );
    end generate;

    u_H_MATRIX_UNUSED : if IMPL_H_MATRIX = false generate
    rx_cp_dl_valid(2)               <= '0';
    rx_cp_dl_last(2)                <= '0';
    rx_cp_dl_keep(2)                <= (others => '0');
    rx_cp_dl_data(2)                <= (others => '0');
    rx_cp_dl_index(2)               <= (others => '0');
    rx_cp_dl_link_map(2)            <= (others => '0');
--    rx_up_valid                     <= '0';
--    rx_up_last                      <= '0';
--    rx_up_keep                      <= (others => '0');
--    rx_up_data                      <= (others => '0');
--    rx_up_index(2)                  <= (others => '0');
--    rx_up_link_map(2)               <= (others => '0');
    rx_packet_is_cp(2)              <= (others => '0');
    rx_packet_is_up(2)              <= (others => '0');
    rx_packet_is_ndm(2)             <= '0';
    rx_packet_scs(2)                <= (others => '0');
    end generate;

    u_PUxCH : if IMPL_PUxCH = true generate
    u_RX_HDR_STAMP : ORAN_HDR_STAMP_UNIT
    generic map(
        IMPL_CP                     => true                                    ,--: boolean := true;
        IMPL_UP                     => false                                   ,--: boolean := true;

        LINK_DIRECTION              => RX_LINK_DIRECTION                       ,--: std_logic := '0';
        DATA_INDEX                  => INDEX_PUxCH                             ,--: natural := 0;
        NUM_LINK                    => MAX_PUxCH                                --: natural := 16
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;

        PARAM_ID_EN                 => UL_PARAM_ID_EN(0)                       ,--: in  std_logic_vector(63 downto 0);
        PARAM_ID                    => UL_PARAM_ID(0)                          ,--: in  std_logic_array16(63 downto 0);
        PE_INDEX                    => UL_PE_INDEX(0)                          ,--: in  std_logic_array8(63 downto 0);
        SCS_CONFIG                  => UL_SCS_CONFIG(0)                        ,--: in  std_logic_array4(63 downto 0);
        ENABLE_NDM                  => (others => '0')                         ,--: in  std_logic_vector(63 downto 0);

        CNTUP_INVALID_ecpriVersion  => open                                    ,--: out std_logic;
        CNTUP_INVALID_ecpriC        => open                                    ,--: out std_logic;
        CNTUP_INVALID_ecpriMessage  => open                                    ,--: out std_logic;

        CNTUP_LENGTH_IS_NORMAL      => open                                    ,--: out std_logic;
        CNTUP_LENGTH_IS_LONG        => open                                    ,--: out std_logic;
        CNTUP_LENGTH_IS_SHORT       => open                                    ,--: out std_logic;

        IN_VALID                    => MAC_IC_RX_VALID                         ,--: in  std_logic;
        IN_LAST                     => MAC_IC_RX_LAST                          ,--: in  std_logic;
        IN_KEEP                     => MAC_IC_RX_KEEP                          ,--: in  std_logic_vector(7 downto 0);
        IN_DATA                     => MAC_IC_RX_DATA                          ,--: in  std_logic_vector(63 downto 0);
        IN_PE_INDEX                 => MAC_IC_RX_PE_INDEX                      ,--: in  std_logic_vector(2 downto 0);
        OUT_PE_INDEX                => open                                    ,

        OUT_CP_VALID                => rx_cp_ul_valid(0)                       ,--: out std_logic;
        OUT_CP_LAST                 => rx_cp_ul_last(0)                        ,--: out std_logic;
        OUT_CP_KEEP                 => rx_cp_ul_keep(0)                        ,--: out std_logic_vector(7 downto 0);
        OUT_CP_DATA                 => rx_cp_ul_data(0)                        ,--: out std_logic_vector(63 downto 0);
        OUT_CP_INDEX                => rx_cp_ul_index(0)                       ,--: out std_logic_vector(2 downto 0);
        OUT_CP_LINK_MAP             => rx_cp_ul_link_map(0)                    ,--: out std_logic_vector(15 downto 0);

        OUT_UP_VALID                => open                                    ,--: out std_logic;
        OUT_UP_LAST                 => open                                    ,--: out std_logic;
        OUT_UP_KEEP                 => open                                    ,--: out std_logic_vector(7 downto 0);
        OUT_UP_DATA                 => open                                    ,--: out std_logic_vector(63 downto 0);
        OUT_UP_INDEX                => open                                    ,--: out std_logic_vector(2 downto 0);
        OUT_UP_LINK_MAP             => open                                    ,--: out std_logic_vector(15 downto 0);

        PACKET_IS_CP                => rx_packet_is_cp(3)                      ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_UP                => open                                    ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_NDM               => rx_packet_is_ndm(3)                     ,--: out std_logic;
        PACKET_SCS                  => rx_packet_scs(3)                        ,--: out std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             => open                                    ,--: out std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          => open                                    ,--: out std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              => open                                    ,--: out std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            => open                                     --: out std_logic_vector(5 downto 0)
    );
    end generate;

    u_PUxCH_UNUSED : if IMPL_PUxCH = false generate
    rx_cp_ul_valid(0)               <= '0';
    rx_cp_ul_last(0)                <= '0';
    rx_cp_ul_keep(0)                <= (others => '0');
    rx_cp_ul_data(0)                <= (others => '0');
    rx_cp_ul_index(0)               <= (others => '0');
    rx_cp_ul_link_map(0)            <= (others => '0');
    rx_packet_is_cp(3)              <= (others => '0');
    rx_packet_is_ndm(3)             <= '0';
    rx_packet_scs(3)                <= (others => '0');
    end generate;

    u_PRACH : if IMPL_PRACH = true generate
    u_RX_HDR_STAMP : ORAN_HDR_STAMP_UNIT
    generic map(
        IMPL_CP                     => true                                    ,--: boolean := true;
        IMPL_UP                     => false                                   ,--: boolean := true;

        LINK_DIRECTION              => RX_LINK_DIRECTION                       ,--: std_logic := '0';
        DATA_INDEX                  => INDEX_PRACH                             ,--: natural := 0;
        NUM_LINK                    => MAX_PRACH                                --: natural := 16
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;

        PARAM_ID_EN                 => UL_PARAM_ID_EN(1)                       ,--: in  std_logic_vector(63 downto 0);
        PARAM_ID                    => UL_PARAM_ID(1)                          ,--: in  std_logic_array16(63 downto 0);
        PE_INDEX                    => UL_PE_INDEX(1)                          ,--: in  std_logic_array8(63 downto 0);
        SCS_CONFIG                  => UL_SCS_CONFIG(1)                        ,--: in  std_logic_array4(63 downto 0);
        ENABLE_NDM                  => (others => '0')                         ,--: in  std_logic_vector(63 downto 0);

        CNTUP_INVALID_ecpriVersion  => open                                    ,--: out std_logic;
        CNTUP_INVALID_ecpriC        => open                                    ,--: out std_logic;
        CNTUP_INVALID_ecpriMessage  => open                                    ,--: out std_logic;

        CNTUP_LENGTH_IS_NORMAL      => open                                    ,--: out std_logic;
        CNTUP_LENGTH_IS_LONG        => open                                    ,--: out std_logic;
        CNTUP_LENGTH_IS_SHORT       => open                                    ,--: out std_logic;

        IN_VALID                    => MAC_IC_RX_VALID                         ,--: in  std_logic;
        IN_LAST                     => MAC_IC_RX_LAST                          ,--: in  std_logic;
        IN_KEEP                     => MAC_IC_RX_KEEP                          ,--: in  std_logic_vector(7 downto 0);
        IN_DATA                     => MAC_IC_RX_DATA                          ,--: in  std_logic_vector(63 downto 0);
        IN_PE_INDEX                 => MAC_IC_RX_PE_INDEX                      ,--: in  std_logic_vector(2 downto 0);
        OUT_PE_INDEX                => open                                    ,

        OUT_CP_VALID                => rx_cp_ul_valid(1)                       ,--: out std_logic;
        OUT_CP_LAST                 => rx_cp_ul_last(1)                        ,--: out std_logic;
        OUT_CP_KEEP                 => rx_cp_ul_keep(1)                        ,--: out std_logic_vector(7 downto 0);
        OUT_CP_DATA                 => rx_cp_ul_data(1)                        ,--: out std_logic_vector(63 downto 0);
        OUT_CP_INDEX                => rx_cp_ul_index(1)                       ,--: out std_logic_vector(2 downto 0);
        OUT_CP_LINK_MAP             => rx_cp_ul_link_map(1)                    ,--: out std_logic_vector(15 downto 0);

        OUT_UP_VALID                => open                                    ,--: out std_logic;
        OUT_UP_LAST                 => open                                    ,--: out std_logic;
        OUT_UP_KEEP                 => open                                    ,--: out std_logic_vector(7 downto 0);
        OUT_UP_DATA                 => open                                    ,--: out std_logic_vector(63 downto 0);
        OUT_UP_INDEX                => open                                    ,--: out std_logic_vector(2 downto 0);
        OUT_UP_LINK_MAP             => open                                    ,--: out std_logic_vector(15 downto 0);

        PACKET_IS_CP                => rx_packet_is_cp(4)                      ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_UP                => open                                    ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_NDM               => rx_packet_is_ndm(4)                     ,--: out std_logic;
        PACKET_SCS                  => rx_packet_scs(4)                        ,--: out std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             => open                                    ,--: out std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          => open                                    ,--: out std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              => open                                    ,--: out std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            => open                                     --: out std_logic_vector(5 downto 0)
    );
    end generate;

    u_PRACH_UNUSED : if IMPL_PRACH = false generate
    rx_cp_ul_valid(1)               <= '0';
    rx_cp_ul_last(1)                <= '0';
    rx_cp_ul_keep(1)                <= (others => '0');
    rx_cp_ul_data(1)                <= (others => '0');
    rx_cp_ul_index(1)               <= (others => '0');
    rx_cp_ul_link_map(1)            <= (others => '0');
    rx_packet_is_cp(4)              <= (others => '0');
    rx_packet_is_ndm(4)             <= '0';
    rx_packet_scs(4)                <= (others => '0');
    end generate;

    u_SRS : if IMPL_SRS = true generate
    u_RX_HDR_STAMP : ORAN_HDR_STAMP_UNIT
    generic map(
        IMPL_CP                     => true                                    ,--: boolean := true;
        IMPL_UP                     => false                                   ,--: boolean := true;

        LINK_DIRECTION              => RX_LINK_DIRECTION                       ,--: std_logic := '0';
        DATA_INDEX                  => INDEX_SRS                               ,--: natural := 0;
        NUM_LINK                    => MAX_SRS                                  --: natural := 16
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;

        PARAM_ID_EN                 => UL_PARAM_ID_EN(2)                       ,--: in  std_logic_vector(63 downto 0);
        PARAM_ID                    => UL_PARAM_ID(2)                          ,--: in  std_logic_array16(63 downto 0);
        PE_INDEX                    => UL_PE_INDEX(2)                          ,--: in  std_logic_array8(63 downto 0);
        SCS_CONFIG                  => UL_SCS_CONFIG(2)                        ,--: in  std_logic_array4(63 downto 0);
        ENABLE_NDM                  => (others => '0')                         ,--: in  std_logic_vector(63 downto 0);

        CNTUP_INVALID_ecpriVersion  => open                                    ,--: out std_logic;
        CNTUP_INVALID_ecpriC        => open                                    ,--: out std_logic;
        CNTUP_INVALID_ecpriMessage  => open                                    ,--: out std_logic;

        CNTUP_LENGTH_IS_NORMAL      => open                                    ,--: out std_logic;
        CNTUP_LENGTH_IS_LONG        => open                                    ,--: out std_logic;
        CNTUP_LENGTH_IS_SHORT       => open                                    ,--: out std_logic;

        IN_VALID                    => MAC_IC_RX_VALID                         ,--: in  std_logic;
        IN_LAST                     => MAC_IC_RX_LAST                          ,--: in  std_logic;
        IN_KEEP                     => MAC_IC_RX_KEEP                          ,--: in  std_logic_vector(7 downto 0);
        IN_DATA                     => MAC_IC_RX_DATA                          ,--: in  std_logic_vector(63 downto 0);
        IN_PE_INDEX                 => MAC_IC_RX_PE_INDEX                      ,--: in  std_logic_vector(2 downto 0);
        OUT_PE_INDEX                => open                                    ,

        OUT_CP_VALID                => rx_cp_ul_valid(2)                       ,--: out std_logic;
        OUT_CP_LAST                 => rx_cp_ul_last(2)                        ,--: out std_logic;
        OUT_CP_KEEP                 => rx_cp_ul_keep(2)                        ,--: out std_logic_vector(7 downto 0);
        OUT_CP_DATA                 => rx_cp_ul_data(2)                        ,--: out std_logic_vector(63 downto 0);
        OUT_CP_INDEX                => rx_cp_ul_index(2)                       ,--: out std_logic_vector(2 downto 0);
        OUT_CP_LINK_MAP             => rx_cp_ul_link_map(2)                    ,--: out std_logic_vector(15 downto 0);

        OUT_UP_VALID                => open                                    ,--: out std_logic;
        OUT_UP_LAST                 => open                                    ,--: out std_logic;
        OUT_UP_KEEP                 => open                                    ,--: out std_logic_vector(7 downto 0);
        OUT_UP_DATA                 => open                                    ,--: out std_logic_vector(63 downto 0);
        OUT_UP_INDEX                => open                                    ,--: out std_logic_vector(2 downto 0);
        OUT_UP_LINK_MAP             => open                                    ,--: out std_logic_vector(15 downto 0);

        PACKET_IS_CP                => rx_packet_is_cp(5)                      ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_UP                => open                                    ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_NDM               => rx_packet_is_ndm(5)                     ,--: out std_logic;
        PACKET_SCS                  => rx_packet_scs(5)                        ,--: out std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             => open                                    ,--: out std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          => open                                    ,--: out std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              => open                                    ,--: out std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            => open                                     --: out std_logic_vector(5 downto 0)
    );
    end generate;

    u_SRS_UNUSED : if IMPL_SRS = false generate
    rx_cp_ul_valid(2)               <= '0';
    rx_cp_ul_last(2)                <= '0';
    rx_cp_ul_keep(2)                <= (others => '0');
    rx_cp_ul_data(2)                <= (others => '0');
    rx_cp_ul_index(2)               <= (others => '0');
    rx_cp_ul_link_map(2)            <= (others => '0');
    rx_packet_is_cp(5)              <= (others => '0');
    rx_packet_is_ndm(5)             <= '0';
    rx_packet_scs(5)                <= (others => '0');
    end generate;

    u_RIM_RS : if IMPL_RIM_RS = true generate
    u_RX_HDR_STAMP : ORAN_HDR_STAMP_UNIT
    generic map(
        IMPL_CP                     => true                                    ,--: boolean := true;
        IMPL_UP                     => false                                   ,--: boolean := true;

        LINK_DIRECTION              => RX_LINK_DIRECTION                       ,--: std_logic := '0';
        DATA_INDEX                  => INDEX_RIM_RS                            ,--: natural := 0;
        NUM_LINK                    => MAX_RIM_RS                               --: natural := 16
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;

        PARAM_ID_EN                 => UL_PARAM_ID_EN(3)                       ,--: in  std_logic_vector(63 downto 0);
        PARAM_ID                    => UL_PARAM_ID(3)                          ,--: in  std_logic_array16(63 downto 0);
        PE_INDEX                    => UL_PE_INDEX(3)                          ,--: in  std_logic_array8(63 downto 0);
        SCS_CONFIG                  => UL_SCS_CONFIG(3)                        ,--: in  std_logic_array4(63 downto 0);
        ENABLE_NDM                  => (others => '0')                         ,--: in  std_logic_vector(63 downto 0);

        CNTUP_INVALID_ecpriVersion  => open                                    ,--: out std_logic;
        CNTUP_INVALID_ecpriC        => open                                    ,--: out std_logic;
        CNTUP_INVALID_ecpriMessage  => open                                    ,--: out std_logic;

        CNTUP_LENGTH_IS_NORMAL      => open                                    ,--: out std_logic;
        CNTUP_LENGTH_IS_LONG        => open                                    ,--: out std_logic;
        CNTUP_LENGTH_IS_SHORT       => open                                    ,--: out std_logic;

        IN_VALID                    => MAC_IC_RX_VALID                         ,--: in  std_logic;
        IN_LAST                     => MAC_IC_RX_LAST                          ,--: in  std_logic;
        IN_KEEP                     => MAC_IC_RX_KEEP                          ,--: in  std_logic_vector(7 downto 0);
        IN_DATA                     => MAC_IC_RX_DATA                          ,--: in  std_logic_vector(63 downto 0);
        IN_PE_INDEX                 => MAC_IC_RX_PE_INDEX                      ,--: in  std_logic_vector(2 downto 0);
        OUT_PE_INDEX                => open                                    ,

        OUT_CP_VALID                => rx_cp_ul_valid(3)                       ,--: out std_logic;
        OUT_CP_LAST                 => rx_cp_ul_last(3)                        ,--: out std_logic;
        OUT_CP_KEEP                 => rx_cp_ul_keep(3)                        ,--: out std_logic_vector(7 downto 0);
        OUT_CP_DATA                 => rx_cp_ul_data(3)                        ,--: out std_logic_vector(63 downto 0);
        OUT_CP_INDEX                => rx_cp_ul_index(3)                       ,--: out std_logic_vector(2 downto 0);
        OUT_CP_LINK_MAP             => rx_cp_ul_link_map(3)                    ,--: out std_logic_vector(15 downto 0);

        OUT_UP_VALID                => open                                    ,--: out std_logic;
        OUT_UP_LAST                 => open                                    ,--: out std_logic;
        OUT_UP_KEEP                 => open                                    ,--: out std_logic_vector(7 downto 0);
        OUT_UP_DATA                 => open                                    ,--: out std_logic_vector(63 downto 0);
        OUT_UP_INDEX                => open                                    ,--: out std_logic_vector(2 downto 0);
        OUT_UP_LINK_MAP             => open                                    ,--: out std_logic_vector(15 downto 0);

        PACKET_IS_CP                => rx_packet_is_cp(6)                      ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_UP                => open                                    ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_NDM               => rx_packet_is_ndm(6)                     ,--: out std_logic;
        PACKET_SCS                  => rx_packet_scs(6)                        ,--: out std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             => open                                    ,--: out std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          => open                                    ,--: out std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              => open                                    ,--: out std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            => open                                     --: out std_logic_vector(5 downto 0)
    );
    end generate;

    u_RIM_RS_UNUSED : if IMPL_RIM_RS = false generate
    rx_cp_ul_valid(3)               <= '0';
    rx_cp_ul_last(3)                <= '0';
    rx_cp_ul_keep(3)                <= (others => '0');
    rx_cp_ul_data(3)                <= (others => '0');
    rx_cp_ul_index(3)               <= (others => '0');
    rx_cp_ul_link_map(3)            <= (others => '0');
    rx_packet_is_cp(6)              <= (others => '0');
    rx_packet_is_ndm(6)             <= '0';
    rx_packet_scs(6)                <= (others => '0');
    end generate;

    u_NB_IoT : if IMPL_NB_IoT = true generate
    u_RX_HDR_STAMP : ORAN_HDR_STAMP_UNIT
    generic map(
        IMPL_CP                     => true                                    ,--: boolean := true;
        IMPL_UP                     => false                                   ,--: boolean := true;

        LINK_DIRECTION              => RX_LINK_DIRECTION                       ,--: std_logic := '0';
        DATA_INDEX                  => INDEX_NB_IoT                            ,--: natural := 0;
        NUM_LINK                    => MAX_NB_IoT                               --: natural := 16
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;

        PARAM_ID_EN                 => UL_PARAM_ID_EN(4)                       ,--: in  std_logic_vector(63 downto 0);
        PARAM_ID                    => UL_PARAM_ID(4)                          ,--: in  std_logic_array16(63 downto 0);
        PE_INDEX                    => UL_PE_INDEX(4)                          ,--: in  std_logic_array8(63 downto 0);
        SCS_CONFIG                  => UL_SCS_CONFIG(4)                        ,--: in  std_logic_array4(63 downto 0);
        ENABLE_NDM                  => (others => '0')                         ,--: in  std_logic_vector(63 downto 0);

        CNTUP_INVALID_ecpriVersion  => open                                    ,--: out std_logic;
        CNTUP_INVALID_ecpriC        => open                                    ,--: out std_logic;
        CNTUP_INVALID_ecpriMessage  => open                                    ,--: out std_logic;

        CNTUP_LENGTH_IS_NORMAL      => open                                    ,--: out std_logic;
        CNTUP_LENGTH_IS_LONG        => open                                    ,--: out std_logic;
        CNTUP_LENGTH_IS_SHORT       => open                                    ,--: out std_logic;

        IN_VALID                    => MAC_IC_RX_VALID                         ,--: in  std_logic;
        IN_LAST                     => MAC_IC_RX_LAST                          ,--: in  std_logic;
        IN_KEEP                     => MAC_IC_RX_KEEP                          ,--: in  std_logic_vector(7 downto 0);
        IN_DATA                     => MAC_IC_RX_DATA                          ,--: in  std_logic_vector(63 downto 0);
        IN_PE_INDEX                 => MAC_IC_RX_PE_INDEX                      ,--: in  std_logic_vector(2 downto 0);
        OUT_PE_INDEX                => open                                    ,

        OUT_CP_VALID                => rx_cp_ul_valid(4)                       ,--: out std_logic;
        OUT_CP_LAST                 => rx_cp_ul_last(4)                        ,--: out std_logic;
        OUT_CP_KEEP                 => rx_cp_ul_keep(4)                        ,--: out std_logic_vector(7 downto 0);
        OUT_CP_DATA                 => rx_cp_ul_data(4)                        ,--: out std_logic_vector(63 downto 0);
        OUT_CP_INDEX                => rx_cp_ul_index(4)                       ,--: out std_logic_vector(2 downto 0);
        OUT_CP_LINK_MAP             => rx_cp_ul_link_map(4)                    ,--: out std_logic_vector(15 downto 0);

        OUT_UP_VALID                => open                                    ,--: out std_logic;
        OUT_UP_LAST                 => open                                    ,--: out std_logic;
        OUT_UP_KEEP                 => open                                    ,--: out std_logic_vector(7 downto 0);
        OUT_UP_DATA                 => open                                    ,--: out std_logic_vector(63 downto 0);
        OUT_UP_INDEX                => open                                    ,--: out std_logic_vector(2 downto 0);
        OUT_UP_LINK_MAP             => open                                    ,--: out std_logic_vector(15 downto 0);

        PACKET_IS_CP                => rx_packet_is_cp(7)                      ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_UP                => open                                    ,--: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_NDM               => rx_packet_is_ndm(7)                     ,--: out std_logic;
        PACKET_SCS                  => rx_packet_scs(7)                        ,--: out std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             => open                                    ,--: out std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          => open                                    ,--: out std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              => open                                    ,--: out std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            => open                                     --: out std_logic_vector(5 downto 0)
    );
    end generate;

    u_NB_IoT_UNUSED : if IMPL_NB_IoT = false generate
    rx_cp_ul_valid(4)               <= '0';
    rx_cp_ul_last(4)                <= '0';
    rx_cp_ul_keep(4)                <= (others => '0');
    rx_cp_ul_data(4)                <= (others => '0');
    rx_cp_ul_index(4)               <= (others => '0');
    rx_cp_ul_link_map(4)            <= (others => '0');
    rx_packet_is_cp(7)              <= (others => '0');
    rx_packet_is_ndm(7)             <= '0';
    rx_packet_scs(7)                <= (others => '0');
    end generate;

--------------------------------------------------------------------------------
-- DL/UL C-Plane
--------------------------------------------------------------------------------

    u_CP_DL_VALIDATION : for i in 2 downto 0 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (rx_cp_dl_link_map(i) = 0) then
                output_enable_cp_dl(i) <= '0';
            else
                output_enable_cp_dl(i) <= '1';
            end if;
        end if;
    end process;
    end generate;

    u_CP_UL_VALIDATION : for i in 4 downto 0 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (rx_cp_ul_link_map(i) = 0) then
                output_enable_cp_ul(i) <= '0';
            else
                output_enable_cp_ul(i) <= '1';
            end if;
        end if;
    end process;
    end generate;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            buf_rx_cp_valid    <= rx_cp_dl_valid(0);
            buf_rx_cp_last     <= rx_cp_dl_last(0);
            buf_rx_cp_keep     <= rx_cp_dl_keep(0);
            buf_rx_cp_data     <= rx_cp_dl_data(0);
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            buf_rx_cp_index    <= rx_cp_dl_index(0)    or rx_cp_dl_index(1)    or rx_cp_dl_index(2)    or rx_cp_ul_index(0)    or rx_cp_ul_index(1)    or rx_cp_ul_index(2)    or rx_cp_ul_index(3)    or rx_cp_ul_index(4);
            buf_rx_cp_link_map <= rx_cp_dl_link_map(0) or rx_cp_dl_link_map(1) or rx_cp_dl_link_map(2) or rx_cp_ul_link_map(0) or rx_cp_ul_link_map(1) or rx_cp_ul_link_map(2) or rx_cp_ul_link_map(3) or rx_cp_ul_link_map(4);
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (output_enable_cp_dl = 0) and (output_enable_cp_ul = 0) then
                ORAN_RX_C64_VALID      <= '0';
                ORAN_RX_C64_LAST       <= '0';
                ORAN_RX_C64_KEEP       <= (others => '0');
                ORAN_RX_C64_DATA       <= (others => '0');
                ORAN_RX_C64_DATA_INDEX <= (others => '0');
                ORAN_RX_C64_LINK_MAP   <= (others => '0');
            else
                ORAN_RX_C64_VALID      <= buf_rx_cp_valid;
                ORAN_RX_C64_LAST       <= buf_rx_cp_last;
                ORAN_RX_C64_KEEP       <= buf_rx_cp_keep;
                ORAN_RX_C64_DATA       <= buf_rx_cp_data;
                ORAN_RX_C64_DATA_INDEX <= buf_rx_cp_index;
                ORAN_RX_C64_LINK_MAP   <= buf_rx_cp_link_map;
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------
-- DL U-Plane
--------------------------------------------------------------------------------

    u_UP_VALIDATION : for i in 1 downto 0 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (rx_up_link_map(i) = 0) then
                output_enable_up(i) <= '0';
            else
                output_enable_up(i) <= '1';
            end if;
        end if;
    end process;
    end generate;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            buf_rx_up_valid    <= rx_up_valid;
            buf_rx_up_last     <= rx_up_last;
            buf_rx_up_keep     <= rx_up_keep;
            buf_rx_up_data     <= rx_up_data;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            buf_rx_up_index    <= rx_up_index(0)    or rx_up_index(1);
            buf_rx_up_link_map <= rx_up_link_map(0) or rx_up_link_map(1);
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (output_enable_up = 0) then
                ORAN_RX_U64_VALID      <= '0';
                ORAN_RX_U64_LAST       <= '0';
                ORAN_RX_U64_KEEP       <= (others => '0');
                ORAN_RX_U64_DATA       <= (others => '0');
                ORAN_RX_U64_DATA_INDEX <= (others => '0');
                ORAN_RX_U64_LINK_MAP   <= (others => '0');
--                OUT_PE_INDEX           <= (others => '0');

            else
                ORAN_RX_U64_VALID      <= buf_rx_up_valid;
                ORAN_RX_U64_LAST       <= buf_rx_up_last;
                ORAN_RX_U64_KEEP       <= buf_rx_up_keep;
                ORAN_RX_U64_DATA       <= buf_rx_up_data;
                ORAN_RX_U64_DATA_INDEX <= buf_rx_up_index;
                ORAN_RX_U64_LINK_MAP   <= buf_rx_up_link_map;
--                OUT_PE_INDEX           <= s_pe_index_d;
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Measurement
--------------------------------------------------------------------------------

    detect_cp_dl <= rx_packet_is_cp(2) or rx_packet_is_cp(1) or rx_packet_is_cp(0);
    detect_cp_ul <= rx_packet_is_cp(7) or rx_packet_is_cp(6) or rx_packet_is_cp(5) or rx_packet_is_cp(4) or rx_packet_is_cp(3);
    detect_up_dl <= rx_packet_is_up(2) or rx_packet_is_up(1) or rx_packet_is_up(0);

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            PACKET_IS_CP_DL <= detect_cp_dl;
            PACKET_IS_CP_UL <= detect_cp_ul;
            PACKET_IS_UP_DL <= detect_up_dl;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            for i in 7 downto 0 loop
            if (rx_packet_is_cp(i) /= 0) or (rx_packet_is_up(i) /= 0) then
                PACKET_IS_NDM <= rx_packet_is_ndm(i);
                PACKET_SCS    <= rx_packet_scs(i);
            end if;
            end loop;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Statistics
--------------------------------------------------------------------------------

    RX_DL_CP_POSITION(0)            <= x"000000000000" & rx_cp_dl_link_map(0);
    RX_DL_CP_POSITION(1)            <= x"000000000000" & rx_cp_dl_link_map(1);
    RX_DL_CP_POSITION(2)            <= x"000000000000" & rx_cp_dl_link_map(2);
    RX_DL_CP_POSITION(3)            <= (others => '0');
    RX_DL_CP_POSITION(4)            <= (others => '0');
    RX_DL_CP_POSITION(5)            <= (others => '0');
    RX_DL_CP_POSITION(6)            <= (others => '0');
    RX_DL_CP_POSITION(7)            <= (others => '0');

    RX_DL_UP_POSITION(0)            <= x"000000000000" & rx_up_link_map(0);
    RX_DL_UP_POSITION(1)            <= x"000000000000" & rx_up_link_map(1);
    RX_DL_UP_POSITION(2)            <= (others => '0');
    RX_DL_UP_POSITION(3)            <= (others => '0');
    RX_DL_UP_POSITION(4)            <= (others => '0');
    RX_DL_UP_POSITION(5)            <= (others => '0');
    RX_DL_UP_POSITION(6)            <= (others => '0');
    RX_DL_UP_POSITION(7)            <= (others => '0');

    RX_UL_CP_POSITION(0)            <= x"000000000000" & rx_cp_ul_link_map(0);
    RX_UL_CP_POSITION(1)            <= x"000000000000" & rx_cp_ul_link_map(1);
    RX_UL_CP_POSITION(2)            <= x"000000000000" & rx_cp_ul_link_map(2);
    RX_UL_CP_POSITION(3)            <= x"000000000000" & rx_cp_ul_link_map(3);
    RX_UL_CP_POSITION(4)            <= x"000000000000" & rx_cp_ul_link_map(4);
    RX_UL_CP_POSITION(5)            <= (others => '0');
    RX_UL_CP_POSITION(6)            <= (others => '0');
    RX_UL_CP_POSITION(7)            <= (others => '0');

end BEHAVE;