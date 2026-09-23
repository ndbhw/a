--------------------------------------------------------------------------------
--
-- Copyright (C) 2024, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com)
-- Date     : 2024.03.11
--------------------------------------------------------------------------------
-- Function description
--   -. Performance measurement
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2024.03.11) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use WORK.ARRAY_TYPE.ALL;
use WORK.PKG_ORAN.ALL;

entity MEASUREMENT_SHORT is
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
end MEASUREMENT_SHORT;

architecture BEHAVE of MEASUREMENT_SHORT is

    signal prev_period              : std_logic_vector(7 downto 0);
    signal condi_reset              : std_logic;

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

    signal rst_245p76mhz            : std_logic;

    component REF_GEN is
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        N_TA_OFFSET                 : in  std_logic_vector(15 downto 0);

        IN_10msec                   : in  std_logic;
        IN_SFN                      : in  std_logic_vector(7 downto 0);

        OUT_10msec                  : out std_logic;
        OUT_SFN                     : out std_logic_vector(7 downto 0)
    );
    end component;

    signal ref_rx_window            : std_logic;
    signal ref_rx_sfn               : std_logic_vector(7 downto 0);

    component RX_WINDOW_SHORT is
    generic (
        SCS_CONFIG                  : natural := 0
    );
    port (
        CLK_CPUIF                   : in  std_logic;
        RST_CPUIF                   : in  std_logic;

        CLK_245p76MHz               : in  std_logic;

        WINDOW_START                : in  std_logic_vector(21 downto 0);
        WINDOW_END                  : in  std_logic_vector(21 downto 0);
        WINDOW_PERIOD               : in  std_logic_vector(7 downto 0);

        REF_10msec                  : in  std_logic;
        REF_SFN                     : in  std_logic_vector(7 downto 0);

        CLK_PACKET                  : in  std_logic;

        PACKET_EN                   : in  std_logic;
        PACKET_SCS                  : in  std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             : in  std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          : in  std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              : in  std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            : in  std_logic_vector(5 downto 0);
        
        DETECT_ON_TIME              : out std_logic;
        DETECT_EARLY                : out std_logic;
        DETECT_LATE                 : out std_logic;
        DETECT_OOR                  : out std_logic
    
    );
    end component;

    
--    signal dl_cp_det_on_time              : std_logic := '0';
--    signal dl_cp_det_early                : std_logic := '0';
--    signal dl_cp_det_late                 : std_logic := '0';
--    signal dl_cp_det_oor                  : std_logic := '0';

--    signal dl_up_det_on_time              : std_logic := '0';
--    signal dl_up_det_early                : std_logic := '0';
--    signal dl_up_det_late                 : std_logic := '0';
--    signal dl_up_det_oor                  : std_logic := '0';    

    signal dl_cp_det_on_time              : std_logic_vector(4 downto 0) := (others => '0');
    signal dl_cp_det_early                : std_logic_vector(4 downto 0) := (others => '0');
    signal dl_cp_det_late                 : std_logic_vector(4 downto 0) := (others => '0');
    signal dl_cp_det_oor                  : std_logic_vector(4 downto 0) := (others => '0');
    
    signal dl_up_det_on_time              : std_logic_vector(4 downto 0) := (others => '0');
    signal dl_up_det_early                : std_logic_vector(4 downto 0) := (others => '0');
    signal dl_up_det_late                 : std_logic_vector(4 downto 0) := (others => '0');
    signal dl_up_det_oor                  : std_logic_vector(4 downto 0) := (others => '0');    
    
begin

    DL_CP_DETECT_ON_TIME    <= dl_cp_det_on_time(0) or dl_cp_det_on_time(1) or dl_cp_det_on_time(2) or dl_cp_det_on_time(3) or dl_cp_det_on_time(4);
    DL_CP_DETECT_EARLY      <= dl_cp_det_early  (0) or dl_cp_det_early  (1) or dl_cp_det_early  (2) or dl_cp_det_early  (3) or dl_cp_det_early  (4);
    DL_CP_DETECT_LATE       <= dl_cp_det_late   (0) or dl_cp_det_late   (1) or dl_cp_det_late   (2) or dl_cp_det_late   (3) or dl_cp_det_late   (4);
    DL_CP_DETECT_OOR        <= dl_cp_det_oor    (0) or dl_cp_det_oor    (1) or dl_cp_det_oor    (2) or dl_cp_det_oor    (3) or dl_cp_det_oor    (4);
                         
    DL_UP_DETECT_ON_TIME    <= dl_up_det_on_time(0) or dl_up_det_on_time(1) or dl_up_det_on_time(2) or dl_up_det_on_time(3) or dl_up_det_on_time(4); 
    DL_UP_DETECT_EARLY      <= dl_up_det_early  (0) or dl_up_det_early  (1) or dl_up_det_early  (2) or dl_up_det_early  (3) or dl_up_det_early  (4); 
    DL_UP_DETECT_LATE       <= dl_up_det_late   (0) or dl_up_det_late   (1) or dl_up_det_late   (2) or dl_up_det_late   (3) or dl_up_det_late   (4); 
    DL_UP_DETECT_OOR        <= dl_up_det_oor    (0) or dl_up_det_oor    (1) or dl_up_det_oor    (2) or dl_up_det_oor    (3) or dl_up_det_oor    (4); 
    
--------------------------------------------------------------------------------
-- Conditional reset control
--------------------------------------------------------------------------------

    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            prev_period <= CAPTURE_PERIOD;
        end if;
    end process;

    process (RST_CPUIF, CLK_CPUIF)
    begin
        if (RST_CPUIF = '1') then
            condi_reset <= '1';
        elsif (CLK_CPUIF'event and CLK_CPUIF = '1') then
            if (CAPTURE_PERIOD = prev_period) then
                condi_reset <= '0';
            else
                condi_reset <= '1';
            end if;
        end if;
    end process;

    u_RST : RST_SYNC
    generic map(
        DLY_NUM                     => 4                                       ,--: natural := 4;
        MAX_FANOUT_NUM              => 200                                      --: integer := 200
    )
    port map(
        RST_IN                      => condi_reset                             ,--: in  std_logic;
        CLK                         => CLK_245p76MHz                           ,--: in  std_logic;
        RST_OUT                     => rst_245p76mhz                            --: out std_logic
    );

--------------------------------------------------------------------------------
-- Component mapping
--------------------------------------------------------------------------------

    u_RX_10msec : REF_GEN
    port map(
        CLK                         => CLK_245p76MHz                           ,--: in  std_logic;
        RST                         => rst_245p76mhz                           ,--: in  std_logic;

        N_TA_OFFSET                 => (others => '0')                         ,--: in  std_logic_vector(15 downto 0);

        IN_10msec                   => REF_10msec                              ,--: in  std_logic;
        IN_SFN                      => REF_SFN                                 ,--: in  std_logic_vector(7 downto 0);

        OUT_10msec                  => ref_rx_window                           ,--: out std_logic;
        OUT_SFN                     => ref_rx_sfn                               --: out std_logic_vector(7 downto 0)

    );

    u_RX_WINDOW_15kHz : if SCS_CONFIG_0 = true generate
    u_CP_DL : RX_WINDOW_SHORT
    generic map(
        SCS_CONFIG                  => 0                                        --: natural := 0
    )
    port map(
        CLK_CPUIF                   => CLK_CPUIF                               ,--: in  std_logic;
        RST_CPUIF                   => condi_reset                             ,--: in  std_logic;

        CLK_245p76MHz               => CLK_245p76MHz                           ,--: in  std_logic;

        WINDOW_START                => T2A_MAX_DL_CP_RX(0)                     ,--: in  std_logic_vector(21 downto 0);
        WINDOW_END                  => T2A_MIN_DL_CP_RX(0)                     ,--: in  std_logic_vector(21 downto 0);
        WINDOW_PERIOD               => CAPTURE_PERIOD                          ,--: in  std_logic_vector(7 downto 0);

        REF_10msec                  => ref_rx_window                           ,--: in  std_logic;
        REF_SFN                     => ref_rx_sfn                              ,--: in  std_logic_vector(7 downto 0);

        CLK_PACKET                  => RX_PACKET_CLK                           ,--: in  std_logic;

        PACKET_EN                   => RX_PACKET_IS_CP_DL                      ,--: in  std_logic;
        PACKET_SCS                  => RX_PACKET_SCS                           ,--: in  std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             => RX_PACKET_FRAME_ID                      ,--: in  std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          => RX_PACKET_SUBFRAME_ID                   ,--: in  std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              => RX_PACKET_SLOT_ID                       ,--: in  std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            => RX_PACKET_SYMBOL_ID                     ,--: in  std_logic_vector(5 downto 0)

        DETECT_ON_TIME              => dl_cp_det_on_time(0)   ,
        DETECT_EARLY                => dl_cp_det_early(0)     ,
        DETECT_LATE                 => dl_cp_det_late(0)      ,
        DETECT_OOR                  => dl_cp_det_oor(0)       

    );

    u_UP_DL : RX_WINDOW_SHORT
    generic map(
        SCS_CONFIG                  => 0                                        --: natural := 0
    )
    port map(
        CLK_CPUIF                   => CLK_CPUIF                               ,--: in  std_logic;
        RST_CPUIF                   => condi_reset                             ,--: in  std_logic;

        CLK_245p76MHz               => CLK_245p76MHz                           ,--: in  std_logic;

        WINDOW_START                => T2A_MAX_DL_UP_RX(0)                     ,--: in  std_logic_vector(21 downto 0);
        WINDOW_END                  => T2A_MIN_DL_UP_RX(0)                     ,--: in  std_logic_vector(21 downto 0);
        WINDOW_PERIOD               => CAPTURE_PERIOD                          ,--: in  std_logic_vector(7 downto 0);

        REF_10msec                  => ref_rx_window                           ,--: in  std_logic;
        REF_SFN                     => ref_rx_sfn                              ,--: in  std_logic_vector(7 downto 0);

        CLK_PACKET                  => RX_PACKET_CLK                           ,--: in  std_logic;

        PACKET_EN                   => RX_PACKET_IS_UP_DL                      ,--: in  std_logic;
        PACKET_SCS                  => RX_PACKET_SCS                           ,--: in  std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             => RX_PACKET_FRAME_ID                      ,--: in  std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          => RX_PACKET_SUBFRAME_ID                   ,--: in  std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              => RX_PACKET_SLOT_ID                       ,--: in  std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            => RX_PACKET_SYMBOL_ID                     ,--: in  std_logic_vector(5 downto 0)
        
        DETECT_ON_TIME              => dl_up_det_on_time(0)   , 
        DETECT_EARLY                => dl_up_det_early(0)     , 
        DETECT_LATE                 => dl_up_det_late(0)     , 
        DETECT_OOR                  => dl_up_det_oor(0)         
    );

    end generate;

    u_RX_WINDOW_30kHz : if SCS_CONFIG_1 = true generate
    u_CP_DL : RX_WINDOW_SHORT
    generic map(
        SCS_CONFIG                  => 1                                        --: natural := 0
    )
    port map(
        CLK_CPUIF                   => CLK_CPUIF                               ,--: in  std_logic;
        RST_CPUIF                   => condi_reset                             ,--: in  std_logic;

        CLK_245p76MHz               => CLK_245p76MHz                           ,--: in  std_logic;

        WINDOW_START                => T2A_MAX_DL_CP_RX(1)                     ,--: in  std_logic_vector(21 downto 0);
        WINDOW_END                  => T2A_MIN_DL_CP_RX(1)                     ,--: in  std_logic_vector(21 downto 0);
        WINDOW_PERIOD               => CAPTURE_PERIOD                          ,--: in  std_logic_vector(7 downto 0);

        REF_10msec                  => ref_rx_window                           ,--: in  std_logic;
        REF_SFN                     => ref_rx_sfn                              ,--: in  std_logic_vector(7 downto 0);

        CLK_PACKET                  => RX_PACKET_CLK                           ,--: in  std_logic;

        PACKET_EN                   => RX_PACKET_IS_CP_DL                      ,--: in  std_logic;

        PACKET_SCS                  => RX_PACKET_SCS                           ,--: in  std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             => RX_PACKET_FRAME_ID                      ,--: in  std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          => RX_PACKET_SUBFRAME_ID                   ,--: in  std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              => RX_PACKET_SLOT_ID                       ,--: in  std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            => RX_PACKET_SYMBOL_ID                     ,--: in  std_logic_vector(5 downto 0)

        DETECT_ON_TIME              => dl_cp_det_on_time(1)    ,
        DETECT_EARLY                => dl_cp_det_early(1)      ,
        DETECT_LATE                 => dl_cp_det_late(1)       ,
        DETECT_OOR                  => dl_cp_det_oor(1)        

    );

    u_UP_DL : RX_WINDOW_SHORT
    generic map(
        SCS_CONFIG                  => 1                                        --: natural := 0
    )
    port map(
        CLK_CPUIF                   => CLK_CPUIF                               ,--: in  std_logic;
        RST_CPUIF                   => condi_reset                             ,--: in  std_logic;

        CLK_245p76MHz               => CLK_245p76MHz                           ,--: in  std_logic;

        WINDOW_START                => T2A_MAX_DL_UP_RX(1)                     ,--: in  std_logic_vector(21 downto 0);
        WINDOW_END                  => T2A_MIN_DL_UP_RX(1)                     ,--: in  std_logic_vector(21 downto 0);
        WINDOW_PERIOD               => CAPTURE_PERIOD                          ,--: in  std_logic_vector(7 downto 0);

        REF_10msec                  => ref_rx_window                           ,--: in  std_logic;
        REF_SFN                     => ref_rx_sfn                              ,--: in  std_logic_vector(7 downto 0);

        CLK_PACKET                  => RX_PACKET_CLK                           ,--: in  std_logic;

        PACKET_EN                   => RX_PACKET_IS_UP_DL                      ,--: in  std_logic;
        PACKET_SCS                  => RX_PACKET_SCS                           ,--: in  std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             => RX_PACKET_FRAME_ID                      ,--: in  std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          => RX_PACKET_SUBFRAME_ID                   ,--: in  std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              => RX_PACKET_SLOT_ID                       ,--: in  std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            => RX_PACKET_SYMBOL_ID                     ,--: in  std_logic_vector(5 downto 0)
        
        DETECT_ON_TIME              => dl_up_det_on_time(1)    , 
        DETECT_EARLY                => dl_up_det_early(1)      , 
        DETECT_LATE                 => dl_up_det_late(1)       , 
        DETECT_OOR                  => dl_up_det_oor(1)          
    );

    end generate;

    u_RX_WINDOW_60kHz : if SCS_CONFIG_2 = true generate
    u_CP_DL : RX_WINDOW_SHORT
    generic map(
        SCS_CONFIG                  => 2                                        --: natural := 0
    )
    port map(
        CLK_CPUIF                   => CLK_CPUIF                               ,--: in  std_logic;
        RST_CPUIF                   => condi_reset                             ,--: in  std_logic;

        CLK_245p76MHz               => CLK_245p76MHz                           ,--: in  std_logic;

        WINDOW_START                => T2A_MAX_DL_CP_RX(2)                     ,--: in  std_logic_vector(21 downto 0);
        WINDOW_END                  => T2A_MIN_DL_CP_RX(2)                     ,--: in  std_logic_vector(21 downto 0);
        WINDOW_PERIOD               => CAPTURE_PERIOD                          ,--: in  std_logic_vector(7 downto 0);

        REF_10msec                  => ref_rx_window                           ,--: in  std_logic;
        REF_SFN                     => ref_rx_sfn                              ,--: in  std_logic_vector(7 downto 0);

        CLK_PACKET                  => RX_PACKET_CLK                           ,--: in  std_logic;

        PACKET_EN                   => RX_PACKET_IS_CP_DL                      ,--: in  std_logic;
        PACKET_SCS                  => RX_PACKET_SCS                           ,--: in  std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             => RX_PACKET_FRAME_ID                      ,--: in  std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          => RX_PACKET_SUBFRAME_ID                   ,--: in  std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              => RX_PACKET_SLOT_ID                       ,--: in  std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            => RX_PACKET_SYMBOL_ID                     ,--: in  std_logic_vector(5 downto 0)

        DETECT_ON_TIME              => dl_cp_det_on_time(2)    ,
        DETECT_EARLY                => dl_cp_det_early(2)      ,
        DETECT_LATE                 => dl_cp_det_late(2)       ,
        DETECT_OOR                  => dl_cp_det_oor(2)        

    );

    u_UP_DL : RX_WINDOW_SHORT
    generic map(
        SCS_CONFIG                  => 2                                        --: natural := 0
    )
    port map(
        CLK_CPUIF                   => CLK_CPUIF                               ,--: in  std_logic;
        RST_CPUIF                   => condi_reset                             ,--: in  std_logic;

        CLK_245p76MHz               => CLK_245p76MHz                           ,--: in  std_logic;

        WINDOW_START                => T2A_MAX_DL_UP_RX(2)                     ,--: in  std_logic_vector(21 downto 0);
        WINDOW_END                  => T2A_MIN_DL_UP_RX(2)                     ,--: in  std_logic_vector(21 downto 0);
        WINDOW_PERIOD               => CAPTURE_PERIOD                          ,--: in  std_logic_vector(7 downto 0);

        REF_10msec                  => ref_rx_window                           ,--: in  std_logic;
        REF_SFN                     => ref_rx_sfn                              ,--: in  std_logic_vector(7 downto 0);

        CLK_PACKET                  => RX_PACKET_CLK                           ,--: in  std_logic;

        PACKET_EN                   => RX_PACKET_IS_UP_DL                      ,--: in  std_logic;
        PACKET_SCS                  => RX_PACKET_SCS                           ,--: in  std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             => RX_PACKET_FRAME_ID                      ,--: in  std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          => RX_PACKET_SUBFRAME_ID                   ,--: in  std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              => RX_PACKET_SLOT_ID                       ,--: in  std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            => RX_PACKET_SYMBOL_ID                     ,--: in  std_logic_vector(5 downto 0)
        
        DETECT_ON_TIME              => dl_up_det_on_time(2)     , 
        DETECT_EARLY                => dl_up_det_early(2)       , 
        DETECT_LATE                 => dl_up_det_late(2)        , 
        DETECT_OOR                  => dl_up_det_oor(2)           
    );

    end generate;

    u_RX_WINDOW_120kHz : if SCS_CONFIG_3 = true generate
    u_CP_DL : RX_WINDOW_SHORT
    generic map(
        SCS_CONFIG                  => 3                                        --: natural := 0
    )
    port map(
        CLK_CPUIF                   => CLK_CPUIF                               ,--: in  std_logic;
        RST_CPUIF                   => condi_reset                             ,--: in  std_logic;

        CLK_245p76MHz               => CLK_245p76MHz                           ,--: in  std_logic;

        WINDOW_START                => T2A_MAX_DL_CP_RX(3)                     ,--: in  std_logic_vector(21 downto 0);
        WINDOW_END                  => T2A_MIN_DL_CP_RX(3)                     ,--: in  std_logic_vector(21 downto 0);
        WINDOW_PERIOD               => CAPTURE_PERIOD                          ,--: in  std_logic_vector(7 downto 0);

        REF_10msec                  => ref_rx_window                           ,--: in  std_logic;
        REF_SFN                     => ref_rx_sfn                              ,--: in  std_logic_vector(7 downto 0);

        CLK_PACKET                  => RX_PACKET_CLK                           ,--: in  std_logic;

        PACKET_EN                   => RX_PACKET_IS_CP_DL                      ,--: in  std_logic;
        PACKET_SCS                  => RX_PACKET_SCS                           ,--: in  std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             => RX_PACKET_FRAME_ID                      ,--: in  std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          => RX_PACKET_SUBFRAME_ID                   ,--: in  std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              => RX_PACKET_SLOT_ID                       ,--: in  std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            => RX_PACKET_SYMBOL_ID                     ,--: in  std_logic_vector(5 downto 0)

        DETECT_ON_TIME              => dl_cp_det_on_time (3)  ,
        DETECT_EARLY                => dl_cp_det_early   (3)  ,
        DETECT_LATE                 => dl_cp_det_late    (3)  ,
        DETECT_OOR                  => dl_cp_det_oor     (3)  

    );

    u_UP_DL : RX_WINDOW_SHORT
    generic map(
        SCS_CONFIG                  => 3                                        --: natural := 0
    )
    port map(
        CLK_CPUIF                   => CLK_CPUIF                               ,--: in  std_logic;
        RST_CPUIF                   => condi_reset                             ,--: in  std_logic;

        CLK_245p76MHz               => CLK_245p76MHz                           ,--: in  std_logic;

        WINDOW_START                => T2A_MAX_DL_UP_RX(3)                     ,--: in  std_logic_vector(21 downto 0);
        WINDOW_END                  => T2A_MIN_DL_UP_RX(3)                     ,--: in  std_logic_vector(21 downto 0);
        WINDOW_PERIOD               => CAPTURE_PERIOD                          ,--: in  std_logic_vector(7 downto 0);

        REF_10msec                  => ref_rx_window                           ,--: in  std_logic;
        REF_SFN                     => ref_rx_sfn                              ,--: in  std_logic_vector(7 downto 0);

        CLK_PACKET                  => RX_PACKET_CLK                           ,--: in  std_logic;

        PACKET_EN                   => RX_PACKET_IS_UP_DL                      ,--: in  std_logic;
        PACKET_SCS                  => RX_PACKET_SCS                           ,--: in  std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             => RX_PACKET_FRAME_ID                      ,--: in  std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          => RX_PACKET_SUBFRAME_ID                   ,--: in  std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              => RX_PACKET_SLOT_ID                       ,--: in  std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            => RX_PACKET_SYMBOL_ID                     ,--: in  std_logic_vector(5 downto 0)
        
        DETECT_ON_TIME              => dl_up_det_on_time (3)  , 
        DETECT_EARLY                => dl_up_det_early   (3)  , 
        DETECT_LATE                 => dl_up_det_late    (3)  , 
        DETECT_OOR                  => dl_up_det_oor     (3)    
    );

    end generate;

    u_RX_WINDOW_240kHz : if SCS_CONFIG_4 = true generate
    u_CP_DL : RX_WINDOW_SHORT
    generic map(
        SCS_CONFIG                  => 4                                        --: natural := 0
    )
    port map(
        CLK_CPUIF                   => CLK_CPUIF                               ,--: in  std_logic;
        RST_CPUIF                   => condi_reset                             ,--: in  std_logic;

        CLK_245p76MHz               => CLK_245p76MHz                           ,--: in  std_logic;

        WINDOW_START                => T2A_MAX_DL_CP_RX(4)                     ,--: in  std_logic_vector(21 downto 0);
        WINDOW_END                  => T2A_MIN_DL_CP_RX(4)                     ,--: in  std_logic_vector(21 downto 0);
        WINDOW_PERIOD               => CAPTURE_PERIOD                          ,--: in  std_logic_vector(7 downto 0);

        REF_10msec                  => ref_rx_window                           ,--: in  std_logic;
        REF_SFN                     => ref_rx_sfn                              ,--: in  std_logic_vector(7 downto 0);

        CLK_PACKET                  => RX_PACKET_CLK                           ,--: in  std_logic;

        PACKET_EN                   => RX_PACKET_IS_CP_DL                      ,--: in  std_logic;
        PACKET_SCS                  => RX_PACKET_SCS                           ,--: in  std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             => RX_PACKET_FRAME_ID                      ,--: in  std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          => RX_PACKET_SUBFRAME_ID                   ,--: in  std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              => RX_PACKET_SLOT_ID                       ,--: in  std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            => RX_PACKET_SYMBOL_ID                     ,--: in  std_logic_vector(5 downto 0)

        DETECT_ON_TIME              => dl_cp_det_on_time (4)  ,
        DETECT_EARLY                => dl_cp_det_early   (4)  ,
        DETECT_LATE                 => dl_cp_det_late    (4)  ,
        DETECT_OOR                  => dl_cp_det_oor     (4)  

    );

    u_UP_DL : RX_WINDOW_SHORT
    generic map(
        SCS_CONFIG                  => 4                                        --: natural := 0
    )
    port map(
        CLK_CPUIF                   => CLK_CPUIF                               ,--: in  std_logic;
        RST_CPUIF                   => condi_reset                             ,--: in  std_logic;

        CLK_245p76MHz               => CLK_245p76MHz                           ,--: in  std_logic;

        WINDOW_START                => T2A_MAX_DL_UP_RX(4)                     ,--: in  std_logic_vector(21 downto 0);
        WINDOW_END                  => T2A_MIN_DL_UP_RX(4)                     ,--: in  std_logic_vector(21 downto 0);
        WINDOW_PERIOD               => CAPTURE_PERIOD                          ,--: in  std_logic_vector(7 downto 0);

        REF_10msec                  => ref_rx_window                           ,--: in  std_logic;
        REF_SFN                     => ref_rx_sfn                              ,--: in  std_logic_vector(7 downto 0);

        CLK_PACKET                  => RX_PACKET_CLK                           ,--: in  std_logic;

        PACKET_EN                   => RX_PACKET_IS_UP_DL                      ,--: in  std_logic;
        PACKET_SCS                  => RX_PACKET_SCS                           ,--: in  std_logic_vector(3 downto 0);
        PACKET_FRAME_ID             => RX_PACKET_FRAME_ID                      ,--: in  std_logic_vector(7 downto 0);
        PACKET_SUBFRAME_ID          => RX_PACKET_SUBFRAME_ID                   ,--: in  std_logic_vector(3 downto 0);
        PACKET_SLOT_ID              => RX_PACKET_SLOT_ID                       ,--: in  std_logic_vector(5 downto 0);
        PACKET_SYMBOL_ID            => RX_PACKET_SYMBOL_ID                     ,--: in  std_logic_vector(5 downto 0)
        
        DETECT_ON_TIME              => dl_up_det_on_time (4)  , 
        DETECT_EARLY                => dl_up_det_early   (4)  , 
        DETECT_LATE                 => dl_up_det_late    (4)  , 
        DETECT_OOR                  => dl_up_det_oor     (4)    
    );

    end generate;

    
end BEHAVE;