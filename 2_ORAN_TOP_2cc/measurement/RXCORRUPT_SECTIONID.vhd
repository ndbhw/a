
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.ARRAY_TYPE.ALL;
use WORK.PKG_ORAN.ALL;
use WORK.PKG_ORAN_ARRAY.ALL;

entity RXCORRUPT_SECTIONID is
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
end RXCORRUPT_SECTIONID;

architecture BEHAVE of RXCORRUPT_SECTIONID is

	component RATE_ADAPT_CP32_RXCR is
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
        IN_PE_INDEX               	: in  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

        OUT_READY                   : in  std_logic;
        OUT_VALID                   : out std_logic;
        OUT_LAST                    : out std_logic;
        OUT_DATA                    : out std_logic_vector(31 downto 0);
        OUT_PE_INDEX              	: out std_logic_vector(MAX_RU_ELEMENT-1 downto 0)
        
    );
    end component;
    
    signal s32_cp_up_valid          : std_logic;                                                       
    signal s32_cp_up_last           : std_logic;                                                       
    signal s32_cp_up_keep           : std_logic_vector(7 downto 0);                                    
    signal s32_cp_up_data           : std_logic_vector(31 downto 0);   
    signal s32_pe_index_d           : std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
    
    component DL_CP_UP_STAMPING_32 is
    generic (
        USAGE_TYPE0                 : boolean := false;
        USAGE_TYPE1                 : boolean := true;
        USAGE_TYPE3                 : boolean := true;
        USAGE_TYPE5                 : boolean := true;
        USAGE_TYPE6                 : boolean := false;
        USAGE_TYPE7                 : boolean := false;
        MAX_SECTIONID_PER_PKT       : natural := 5;
        NUM_LINK                    : natural := 16

    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;                            -- 245.76-MHz
        RST                         : in  std_logic;                            -- CLK

        PARAM_ID_EN                 : in  std_logic_vector(63 downto 0);
        PARAM_ID                    : in  std_logic_array16(63 downto 0);
        PE_INDEX                    : in  std_logic_array8(63 downto 0);
        SCS_CONFIG                  : in  std_logic_array4(63 downto 0);
        
--------------------------------------------------------------------------------
-- CU-Plane
--------------------------------------------------------------------------------

        CUP32_VALID                  : in  std_logic;
        CUP32_LAST                   : in  std_logic;
        CUP32_DATA                   : in  std_logic_vector(31 downto 0);
        IN_PE_INDEX               	: in  std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

----------------------------------------------------------------------------------
---- Packet stamp
----------------------------------------------------------------------------------

        PACKET_IS_CP                : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
        PACKET_IS_UP                : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

        PACKET_SCS                  : out std_logic_vector(3 downto 0) := (others => '0');
        PACKET_FRAME_ID             : out std_logic_vector(7 downto 0) := (others => '0');
        PACKET_SUBFRAME_ID          : out std_logic_vector(3 downto 0) := (others => '0');
        PACKET_SLOT_ID              : out std_logic_vector(5 downto 0) := (others => '0');
        PACKET_SYMBOL_ID            : out std_logic_vector(5 downto 0) := (others => '0');        
        PACKET_SECTION_ID           : out std_logic_array13(MAX_SECTIONID_PER_PKT-1 downto 0);
        
        OUT_CUP_LINK_MAP             : out std_logic_vector(NUM_LINK-1 downto 0) 
    );
    end component;    
    
--    component MEASUREMENT_SHORT is
--    generic (
--        NUM_TX                      : natural := 1;
--        MAX_SECTIONID_PER_PKT       : natural := 5
--    );
--    port (
----------------------------------------------------------------------------------
---- Clock & Reset
----------------------------------------------------------------------------------

--        CLK_CPUIF                   : in  std_logic;
--        RST_CPUIF                   : in  std_logic;

--        CLK_245p76MHz               : in  std_logic;                            -- 245.76-MHz

----------------------------------------------------------------------------------
---- Synchronization
----------------------------------------------------------------------------------

--        N_TA_OFFSET                 : in  std_logic_vector(15 downto 0);

--        REF_10msec                  : in  std_logic;                            -- Longer than 1-clocks@245.76-MHz
--        REF_SFN                     : in  std_logic_vector(7 downto 0);

----------------------------------------------------------------------------------
---- Control
----------------------------------------------------------------------------------

--        CAPTURE_PERIOD              : in  std_logic_vector(7 downto 0);

--        T2A_MAX_DL_CP_RX            : in  std_logic_array22(4 downto 0);
--        T2A_MIN_DL_CP_RX            : in  std_logic_array22(4 downto 0);
--        T2A_MAX_DL_UP_RX            : in  std_logic_array22(4 downto 0);
--        T2A_MIN_DL_UP_RX            : in  std_logic_array22(4 downto 0);
        

----------------------------------------------------------------------------------
---- Packet stamp for RX
----------------------------------------------------------------------------------
--        RX_VLD_IN                   : in std_logic;
--        RX_PACKET_CLK               : in  std_logic;

--        RX_PACKET_IS_CP_DL          : in  std_logic;
--        RX_PACKET_IS_UP_DL          : in  std_logic;
--        RX_PACKET_SCS               : in  std_logic_vector(3 downto 0);
--        RX_PACKET_FRAME_ID          : in  std_logic_vector(7 downto 0);
--        RX_PACKET_SUBFRAME_ID       : in  std_logic_vector(3 downto 0);
--        RX_PACKET_SLOT_ID           : in  std_logic_vector(5 downto 0);
--        RX_PACKET_SYMBOL_ID         : in  std_logic_vector(5 downto 0);
--        PACKET_SECTION_ID           : in  std_logic_array13(MAX_SECTIONID_PER_PKT-1 downto 0);

--        DL_CP_DETECT_ON_TIME        : out std_logic;
--        DL_CP_DETECT_EARLY          : out std_logic;
--        DL_CP_DETECT_LATE           : out std_logic;
--        DL_CP_DETECT_OOR            : out std_logic;
          
--        DL_UP_DETECT_ON_TIME        : out std_logic;      
--        DL_UP_DETECT_EARLY          : out std_logic;
--        DL_UP_DETECT_LATE           : out std_logic;
--        DL_UP_DETECT_OOR            : out std_logic    
--    );
--    end component;
    
    signal rx_packet_is_cp           : std_logic_vector(MAX_RU_ELEMENT-1 downto 0);
    signal rx_packet_is_up           : std_logic_vector(MAX_RU_ELEMENT-1 downto 0);    

    component MEASUREMENT_SHORT is
    generic (
        MAX_SECTIONID_PER_PKT       : natural := 5
    );
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

        N_TA_OFFSET                 : in  std_logic_vector(15 downto 0);

        REF_10msec                  : in  std_logic;                            -- Longer than 1-clocks@245.76-MHz
        REF_SFN                     : in  std_logic_vector(7 downto 0);

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------

        CAPTURE_PERIOD              : in  std_logic_vector(7 downto 0);

        T2A_MAX_DL_CP_RX            : in  std_logic_array22(4 downto 0);
        T2A_MIN_DL_CP_RX            : in  std_logic_array22(4 downto 0);
        T2A_MAX_DL_UP_RX            : in  std_logic_array22(4 downto 0);
        T2A_MIN_DL_UP_RX            : in  std_logic_array22(4 downto 0);
       
--------------------------------------------------------------------------------
-- Packet stamp for RX
--------------------------------------------------------------------------------

        RX_PACKET_CLK               : in  std_logic;
--        RX_VLD_IN                   : in std_logic;
        
        RX_PACKET_IS_CP_DL          : in  std_logic;
        RX_PACKET_IS_UP_DL          : in  std_logic;

        RX_PACKET_SCS               : in  std_logic_vector(3 downto 0);
        RX_PACKET_FRAME_ID          : in  std_logic_vector(7 downto 0);
        RX_PACKET_SUBFRAME_ID       : in  std_logic_vector(3 downto 0);
        RX_PACKET_SLOT_ID           : in  std_logic_vector(5 downto 0);
        RX_PACKET_SYMBOL_ID         : in  std_logic_vector(5 downto 0);
        PACKET_SECTION_ID           : in  std_logic_array13(MAX_SECTIONID_PER_PKT-1 downto 0);
        
        DL_CP_DETECT_ON_TIME        : out std_logic;
        DL_CP_DETECT_EARLY          : out std_logic;
        DL_CP_DETECT_LATE           : out std_logic;
        DL_CP_DETECT_OOR            : out std_logic;
          
        DL_UP_DETECT_ON_TIME        : out std_logic;      
        DL_UP_DETECT_EARLY          : out std_logic;
        DL_UP_DETECT_LATE           : out std_logic;
        DL_UP_DETECT_OOR            : out std_logic     
        
    );
    end component;

    signal rx_packet_scs            : std_logic_vector(3 downto 0); 
    signal rx_packet_frame_id       : std_logic_vector(7 downto 0); 
    signal rx_packet_subframe_id    : std_logic_vector(3 downto 0); 
    signal rx_packet_slot_id        : std_logic_vector(5 downto 0); 
    signal rx_packet_symbol_id      : std_logic_vector(5 downto 0);
    signal pkt_section_ids           : std_logic_array13(MAX_SECTIONID_PER_PKT-1 downto 0);
    signal rx_packet_link_map        : std_logic_vector(NUM_LINK-1 downto 0);
    
    signal dl_cp_det_on_time              : std_logic_vector(MAX_RU_ELEMENT-1 downto 0) := (others => '0');    
    signal dl_up_det_on_time              : std_logic_vector(MAX_RU_ELEMENT-1 downto 0) := (others => '0');

    component sectionid_coupling_validation is
    generic (
        MAX_SECTIONID_PER_PKT       : natural := 5;
        MU                          : natural := 6  -- numerology: 0 -> 6 

    );
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK_CPUIF                   : in  std_logic;
        RST_CPUIF                   : in  std_logic;

        CLK                         : in  std_logic;                            -- 245.76-MHz
        
--------------------------------------------------------------------------------
-- Packet stamp for RX
--------------------------------------------------------------------------------     
        RX_VLD_IN                   : in std_logic;   
        RX_PACKET_FRAME_ID          : in  std_logic_vector(7 downto 0);
        RX_PACKET_SUBFRAME_ID       : in  std_logic_vector(3 downto 0);
        RX_PACKET_SLOT_ID           : in  std_logic_vector(5 downto 0);
        RX_PACKET_SYMBOL_ID         : in  std_logic_vector(5 downto 0);
        PACKET_SECTION_ID           : in  std_logic_array13(MAX_SECTIONID_PER_PKT-1 downto 0);
        
        DL_CP_DETECT_ON_TIME        : in std_logic;          
        DL_UP_DETECT_ON_TIME        : in std_logic;
        
        RX_CORRUPT_SECTIONID        : out std_logic            
    );
    end component;
    
    type std_logic_array_numlink                      is array(natural range <>) of std_logic_vector( NUM_LINK-1 downto 0);
    signal s_rx_corrupt_sectionid_by_eaxc : std_logic_array_numlink(MAX_RU_ELEMENT -1 downto 0) := (others => (others => '0'));
    signal s_rx_corrupt_sectionid_by_pe : std_logic_vector(MAX_RU_ELEMENT -1 downto 0) := (others => '0'); 
 
    
begin

    u_RATE_ADAPT : RATE_ADAPT_CP32_RXCR
    generic map(
        NUM_OF_URAM                 => 1                                        --: natural := 16
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => RST                                     ,--: in  std_logic;

        CLK_CDC                     => CLK_CDC                                 ,--: in  std_logic;

        USAGE_DATA_BUFFER           => open                                    ,--: out std_logic_vector(31 downto 0);

        CNT_RX                      => open                                    ,--: out std_logic_vector(31 downto 0);
        CNT_LOST                    => open                                    ,--: out std_logic_vector(31 downto 0);

        IN_VALID                    =>  IN_VALID                            ,--: in  std_logic;
        IN_LAST                     =>  IN_LAST                             ,--: in  std_logic;
        IN_DATA                     =>  IN_DATA                             ,--: in  std_logic_vector(63 downto 0);
        IN_PE_INDEX                 =>  IN_PE_INDEX                         ,--: in  std_logic_vector(2 downto 0);
        
        OUT_READY                   => '1'                                     ,--: in  std_logic;
        OUT_VALID                   => s32_cp_up_valid                         ,--: out std_logic;
        OUT_LAST                    => s32_cp_up_last                          ,--: out std_logic;
        OUT_DATA                    => s32_cp_up_data                          ,--: out std_logic_vector(31 downto 0);
        OUT_PE_INDEX                => s32_pe_index_d                           --: out std_logic_vector(2 downto 0);
        
    );
    
    u_CP_UP_STAMPING_32 :  DL_CP_UP_STAMPING_32
    generic map(
        USAGE_TYPE0                 => false                                   ,--: boolean := false;
        USAGE_TYPE1                 => true                                    ,--: boolean := true;
        USAGE_TYPE3                 => true                                    ,--: boolean := true;
        USAGE_TYPE5                 => false                                   ,--: boolean := true;
        USAGE_TYPE6                 => false                                   ,--: boolean := false;
        USAGE_TYPE7                 => false                                   ,--: boolean := false
        MAX_SECTIONID_PER_PKT       => MAX_SECTIONID_PER_PKT                   ,
        NUM_LINK                    => NUM_LINK                                --: natural := 16

    )
    port map(
        CLK                         => CLK_CDC                                 ,--: in  std_logic;
        RST                         => RST                                     ,--: in  std_logic;

        PARAM_ID_EN                 => PARAM_ID_EN ,
        PARAM_ID                    => PARAM_ID    ,
        PE_INDEX                    => PE_INDEX    ,
        SCS_CONFIG                  => SCS_CONFIG  ,


        CUP32_VALID                 => s32_cp_up_valid                         ,--: in  std_logic;
        CUP32_LAST                  => s32_cp_up_last                          ,--: in  std_logic;
        CUP32_DATA                  => s32_cp_up_data                          ,--: in  std_logic_vector(31 downto 0);
        IN_PE_INDEX                 => s32_pe_index_d                          ,
        
        PACKET_IS_CP                => rx_packet_is_cp       ,
        PACKET_IS_UP                => rx_packet_is_up       ,
                                   
        PACKET_SCS                  => rx_packet_scs         ,
        PACKET_FRAME_ID             => rx_packet_frame_id    ,
        PACKET_SUBFRAME_ID          => rx_packet_subframe_id ,
        PACKET_SLOT_ID              => rx_packet_slot_id     ,
        PACKET_SYMBOL_ID            => rx_packet_symbol_id   ,
        PACKET_SECTION_ID           => pkt_section_ids       ,
                                
        OUT_CUP_LINK_MAP            => rx_packet_link_map
    );
    
    u_MEASUREMENT_by_PE : for i in MAX_RU_ELEMENT-1 downto 0 generate
        
        u_MEASUREMENT_SHORT : MEASUREMENT_SHORT
        generic map(
            MAX_SECTIONID_PER_PKT       => MAX_SECTIONID_PER_PKT
        )
        port map(
            CLK_CPUIF                   => CLK_CPUIF                               ,--: in  std_logic;
            RST_CPUIF                   => RST_CPUIF                               ,--: in  std_logic;
        
            CLK_245p76MHz               => CLK_CDC                                 ,--: in  std_logic
        
            N_TA_OFFSET                 => N_TA_OFFSET                             ,--: in  std_logic_vector(15 downto 0);
        
            REF_10msec                  => REF_10msec                              ,--: in  std_logic;
            REF_SFN                     => REF_SFN                                 ,--: in  std_logic_vector(7 downto 0);
        
            CAPTURE_PERIOD              => CAPTURE_PERIOD(i)                       ,--: in  std_logic_vector(7 downto 0);
        
            T2A_MAX_DL_CP_RX            => T2A_MAX_DL_CP_RX(i)                     ,--: in  std_logic_array22(4 downto 0);
            T2A_MIN_DL_CP_RX            => T2A_MIN_DL_CP_RX(i)                     ,--: in  std_logic_array22(4 downto 0);
            T2A_MAX_DL_UP_RX            => T2A_MAX_DL_UP_RX(i)                     ,--: in  std_logic_array22(4 downto 0);
            T2A_MIN_DL_UP_RX            => T2A_MIN_DL_UP_RX(i)                     ,--: in  std_logic_array22(4 downto 0);
            
            RX_PACKET_CLK               => CLK_CDC                                     ,--: in  std_logic;
            
            RX_PACKET_IS_CP_DL          => rx_packet_is_cp(i)                      ,--: in  std_logic;
            RX_PACKET_IS_UP_DL          => rx_packet_is_up(i)                      ,--: in  std_logic;
        
            RX_PACKET_SCS               => rx_packet_scs                              ,--: in  std_logic_vector(3 downto 0);
            RX_PACKET_FRAME_ID          => rx_packet_frame_id                         ,--: in  std_logic_vector(7 downto 0);
            RX_PACKET_SUBFRAME_ID       => rx_packet_subframe_id                      ,--: in  std_logic_vector(3 downto 0);
            RX_PACKET_SLOT_ID           => rx_packet_slot_id                          ,--: in  std_logic_vector(5 downto 0);
            RX_PACKET_SYMBOL_ID         => rx_packet_symbol_id                        ,--: in  std_logic_vector(5 downto 0);
            PACKET_SECTION_ID           => pkt_section_ids                          ,
            
            DL_CP_DETECT_ON_TIME        => dl_cp_det_on_time(i), 
            DL_CP_DETECT_EARLY          => open, 
            DL_CP_DETECT_LATE           => open, 
            DL_CP_DETECT_OOR            => open, 
                                        
            DL_UP_DETECT_ON_TIME        => dl_up_det_on_time(i), 
            DL_UP_DETECT_EARLY          => open, 
            DL_UP_DETECT_LATE           => open, 
            DL_UP_DETECT_OOR            => open 
        );
        
        u_MEASUREMENT_by_eAxC : for i_eaxc in NUM_LINK-1 downto 0 generate  -- change to actual : 7 downto 0
--        u_MEASUREMENT_by_eAxC : for i_eaxc in 7 downto 0 generate  -- change to actual : 7 downto 0
            -- section id validate instances for ontine pkt C-U
            u_sectionid_check: sectionid_coupling_validation
            generic map (
                MAX_SECTIONID_PER_PKT       => MAX_SECTIONID_PER_PKT,
                MU                          => 1
            )
            port map (
        --------------------------------------------------------------------------------
        -- Clock & Reset
        --------------------------------------------------------------------------------
        
                CLK_CPUIF                   =>  CLK_CPUIF,
                RST_CPUIF                   =>  RST_CPUIF,
                                            
                CLK                         =>  CLK_CDC,                           
                                             
        ---------------------------------------------------------------------------
        -- Packet stamp for RX              
        ---------------------------------------------------------------------------        
                RX_VLD_IN                   =>  rx_packet_link_map(i_eaxc)  ,

                RX_PACKET_FRAME_ID          =>  rx_packet_frame_id    ,
                RX_PACKET_SUBFRAME_ID       =>  rx_packet_subframe_id ,
                RX_PACKET_SLOT_ID           =>  rx_packet_slot_id     ,
                RX_PACKET_SYMBOL_ID         =>  rx_packet_symbol_id   ,
                PACKET_SECTION_ID           =>  pkt_section_ids       ,
                                             
                DL_CP_DETECT_ON_TIME        =>  dl_cp_det_on_time(i),          
                DL_UP_DETECT_ON_TIME        =>  dl_up_det_on_time(i),
                RX_CORRUPT_SECTIONID        =>  s_rx_corrupt_sectionid_by_eaxc(i)(i_eaxc)            
            );
        end generate;
        
        process (CLK_CDC)
        begin            
            if (CLK_CDC'event and CLK_CDC = '1') then
                RX_CORRUPT_SECTIONID(i) <=  s_rx_corrupt_sectionid_by_eaxc(i)(0) or  -- or to NUM_LINK
                                            s_rx_corrupt_sectionid_by_eaxc(i)(1) or 
                                            s_rx_corrupt_sectionid_by_eaxc(i)(2) or 
                                            s_rx_corrupt_sectionid_by_eaxc(i)(3) or 
                                            s_rx_corrupt_sectionid_by_eaxc(i)(4) or 
                                            s_rx_corrupt_sectionid_by_eaxc(i)(5) or 
                                            s_rx_corrupt_sectionid_by_eaxc(i)(6) or 
                                            s_rx_corrupt_sectionid_by_eaxc(i)(7);-- or
--                                            s_rx_corrupt_sectionid_by_eaxc(i)(8) or 
--                                            s_rx_corrupt_sectionid_by_eaxc(i)(9) or 
--                                            s_rx_corrupt_sectionid_by_eaxc(i)(10) or 
--                                            s_rx_corrupt_sectionid_by_eaxc(i)(11) or 
--                                            s_rx_corrupt_sectionid_by_eaxc(i)(12) or 
--                                            s_rx_corrupt_sectionid_by_eaxc(i)(13) or 
--                                            s_rx_corrupt_sectionid_by_eaxc(i)(14) or 
--                                            s_rx_corrupt_sectionid_by_eaxc(i)(15);        
            end if;
        end process;   
                                                                                   
    end generate;

end BEHAVE;