--------------------------------------------------------------------------------
--
-- Copyright (C) 2024, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com) / nhu.dong
-- Date     : 2024.03.11
--------------------------------------------------------------------------------
-- Function description
--   1. Performance sectionid_coupling_validation
--   2. Only for SCS 15kHz
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2024.03.11) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;

use WORK.ARRAY_TYPE.ALL;
use WORK.PKG_ORAN.ALL;

entity sectionid_coupling_validation is
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
end sectionid_coupling_validation;

architecture BEHAVE of sectionid_coupling_validation is
    
    constant SLOT_NUM : natural range 0 to 2**MU := 2**MU;
    constant SUBFRAME_NUM : natural range 0 to 4 := 4;
    
    type std_logic_array98                      is array(natural range <>) of std_logic_vector( MAX_SECTIONID_PER_PKT-1 downto 0);
    type std_logic_array98_array13               is array(natural range <>) of std_logic_array13( MAX_SECTIONID_PER_PKT-1 downto 0);
    signal dl_up_det_on_time_d              : std_logic_vector(MAX_SECTIONID_PER_PKT-1 downto 0)  := (others => '0');    

--    type subframes_slots_sectionids_array is array(natural range <>) of std_logic_array5_array13(SLOT_NUM-1 downto 0);
----    type subframes_slots_sectionids_array is array(natural range <>) of std_logic_array98_array13(SLOT_NUM-1 downto 0);
  
--    signal subframes_slots_sectionids_table : subframes_slots_sectionids_array(SUBFRAME_NUM-1 downto 0) := (others => (others => (others => ("1000000000000")))); -- sectionid: 13 bit width / 5 sectionids per pkt(slot) / SLOT_NUM slots per subframe / 2 consecutive subframes 

--    signal pkt_section_ids                  : std_logic_array5_array13(SLOT_NUM-1 downto 0) := (others => (others => ("1000000000000"))); --"1000000000000"; -- 4096: never reachable   
----    signal pkt_section_ids                  : std_logic_array98_array13(SLOT_NUM-1 downto 0) := (others => (others => ("1000000000000"))); --"1000000000000"; -- 4096: never reachable

--    signal pkt_section_ids_1_slot                  : std_logic_array13( MAX_SECTIONID_PER_PKT-1 downto 0) := (others => ("1000000000000")); --(others => ("1000000000000")); --"1000000000000"; -- 4096: never reachable
        
----    signal dl_up_section_id_coupling_result : std_logic_array5(SLOT_NUM -1 downto 0) := (others => (others => '0')); -- 0:
----    signal dl_cp_section_id_updated_check     : std_logic_array5(SLOT_NUM -1 downto 0) := (others => (others => '0')); -- 0:
----    signal dl_up_section_id_coupling_result : std_logic_array98(SLOT_NUM -1 downto 0) := (others => (others => '0')); -- 0:
----    signal dl_cp_section_id_updated_check     : std_logic_array98(SLOT_NUM -1 downto 0) := (others => (others => '0')); -- 0:

--    signal dl_up_section_id_coupling_result : std_logic_vector(MAX_SECTIONID_PER_PKT-1 downto 0) := (others => '0'); -- 0:
--    signal dl_cp_section_id_updated_check     : std_logic_vector(MAX_SECTIONID_PER_PKT-1 downto 0) := (others => '0'); -- 0: 
    
--    signal dl_up_excluded_rx_corrupt : std_logic := '0';
--    signal dl_up_rx_corrupt_happened : std_logic := '0';
    
--    signal addr : integer := 0;
    
--    signal s_rx_corrupt_sectionid   : std_logic_vector(3 downto 0) := (others => '0');
--    signal s_RX_CORRUPT_SECTIONID_check        : std_logic    ;            

-- new          
    type std_logic_array8_array13               is array(natural range <>) of std_logic_array13( MAX_SECTIONID_PER_PKT + 3 -1 downto 0);
    signal slots_sectionids_array               : std_logic_array8_array13(1 downto 0) := (others => (others => ("1000000000000"))); --"1000000000000"; -- 4096: never reachable
    
    signal slot_sectionids_array_hdr_match   : std_logic_vector(1 downto 0) := (others => '0');

    signal s_dl_up_section_id_coupling_result   : std_logic_array98(1 downto 0) := (others => (others => '0')); -- 0:
    signal s_dl_cp_section_id_updated_check     : std_logic_array98(1 downto 0) := (others => (others => '0')); -- 0:
    
    signal s_dl_up_excluded_rx_corrupt : std_logic_vector(1 downto 0) := (others => '0');
    signal s_dl_up_rx_corrupt_happened : std_logic_vector(1 downto 0) := (others => '0');
    signal s_dl_up_rx_corrupt_happened_or   : std_logic := '0';
    signal s_rx_corrupt_sectionid_new       : std_logic_vector(3 downto 0) := (others => '0');

    signal dl_cp_det_on_time              : std_logic;     
    signal dl_up_det_on_time              : std_logic; 

begin
    process (CLK)
    begin            
        if (CLK'event and CLK = '1') then
            if (RX_VLD_IN = '1') then
                dl_cp_det_on_time <= DL_CP_DETECT_ON_TIME;
                dl_up_det_on_time <= DL_UP_DETECT_ON_TIME;
            else
                dl_cp_det_on_time <= '0';
                dl_up_det_on_time <= '0';                    
            end if;        
        end if;
    end process;  
    
-- new, 1% resource increased
    process (CLK)
    begin            
        if (CLK'event and CLK = '1') then
            if (dl_cp_det_on_time = '1') then
                slots_sectionids_array(0) <= slots_sectionids_array(1);
                
                slots_sectionids_array(1)(0) <= slots_sectionids_array(1)(0)(12 downto 8) & RX_PACKET_FRAME_ID;     -- frame id
                slots_sectionids_array(1)(1) <= slots_sectionids_array(1)(1)(12 downto 4) & RX_PACKET_SUBFRAME_ID;  -- subframe id
                slots_sectionids_array(1)(2) <= slots_sectionids_array(1)(2)(12 downto 6) & RX_PACKET_SLOT_ID;      -- slot id
                slots_sectionids_array(1)(MAX_SECTIONID_PER_PKT+3-1 downto 3) <= PACKET_SECTION_ID;                 -- sectionid info    
            end if;        
        end if;
    end process;    
    
    u_SLOT_HDR_CHECK : for i_slot in 1 downto 0 generate
--       u_SECTIONID : for i_section in MAX_SECTIONID_PER_PKT-1 downto 0 generate
                   
            process (CLK)
            begin
                if (CLK'event and CLK = '1') then
                    
                    if (dl_up_det_on_time = '1') then
                        if ((RX_PACKET_FRAME_ID = slots_sectionids_array(i_slot)(0)(7 downto 0)) and (RX_PACKET_SUBFRAME_ID = slots_sectionids_array(i_slot)(1)(3 downto 0)) and (RX_PACKET_SLOT_ID = slots_sectionids_array(i_slot)(2)(5 downto 0))) then
                            slot_sectionids_array_hdr_match(i_slot) <= '1';
                        else
                            slot_sectionids_array_hdr_match(i_slot) <= '0';
                        end if; 
                    end if;                                                                                                                                          

                end if;
            end process; 
--        end generate;
    
    end generate;

    u_SLOT_SECTIONID_CHECK : for i_slot in 1 downto 0 generate
       u_SECTIONID : for i_section in MAX_SECTIONID_PER_PKT-1 downto 0 generate
                   
            process (CLK)
            begin
                if (CLK'event and CLK = '1') then
                    
                    if (dl_up_det_on_time = '1') then
                        if (slots_sectionids_array(i_slot)(i_section+3) = "1000000000000") then   -- section id = default => not updated
                            s_dl_cp_section_id_updated_check(i_slot)(i_section) <= '0';
                            s_dl_up_section_id_coupling_result(i_slot)(i_section) <= '0';                        
                        else                                                             -- section id != default => just been updated
                            s_dl_cp_section_id_updated_check(i_slot)(i_section) <= '1';
                        
                            if (slots_sectionids_array(i_slot)(i_section+3)(12 downto 0) = PACKET_SECTION_ID(i_section)) then
                                s_dl_up_section_id_coupling_result(i_slot)(i_section) <= '1';
                            else                    
                                s_dl_up_section_id_coupling_result(i_slot)(i_section) <= '0';
                            end if;
                        end if; 
                    end if;                                                                                                                                          

                end if;
            end process; 
        end generate;
    
    end generate;
    
    u_SLOT_CONDITION_COMBINE : for i_slot in 1 downto 0 generate
        process (CLK)
        begin
            if (CLK'event and CLK = '1') then
               
               if (s_dl_cp_section_id_updated_check(i_slot) = 0) then           
                   s_dl_up_excluded_rx_corrupt(i_slot) <= '1';
               else
                   s_dl_up_excluded_rx_corrupt(i_slot) <= '0';
                   
                   if (s_dl_up_section_id_coupling_result(i_slot) = 0) then                   
                       s_dl_up_rx_corrupt_happened(i_slot) <= '1';         
                   else
                       s_dl_up_rx_corrupt_happened(i_slot) <= '0';
                   end if;                         
               end if;
            end if;
        end process;
    end generate;
    
    
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            s_dl_up_rx_corrupt_happened_or <= (s_dl_up_rx_corrupt_happened(0) and slot_sectionids_array_hdr_match(0)) or (s_dl_up_rx_corrupt_happened(1) and slot_sectionids_array_hdr_match(1));
        end if;
    end process;
    
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            s_rx_corrupt_sectionid_new(0) <= s_dl_up_rx_corrupt_happened_or and dl_up_det_on_time_d(1);
            s_rx_corrupt_sectionid_new(3 downto 1) <= s_rx_corrupt_sectionid_new(2 downto 0);
        end if;
    end process;
    
    RX_CORRUPT_SECTIONID <= s_rx_corrupt_sectionid_new(0) or s_rx_corrupt_sectionid_new(1) or s_rx_corrupt_sectionid_new(2) or s_rx_corrupt_sectionid_new(3);
    
    process (CLK)
    begin
         if (CLK'event and CLK = '1') then
             dl_up_det_on_time_d <= dl_up_det_on_time_d(MAX_SECTIONID_PER_PKT-2 downto 0) & dl_up_det_on_time;
         end if;
    end process;
     
    
---- old, 10% resource increased---------------------------------------------------------------------------------------------------------------------------------------

--    u_SLOT : for i_slot in SLOT_NUM-1 downto 0 generate
----       u_SECTIONID : for i_section in MAX_SECTIONID_PER_PKT-1 downto 0 generate
       
--           process (CLK)
--           begin
--                if (CLK'event and CLK = '1') then
                                        
--                        case RX_PACKET_SUBFRAME_ID(1 downto 0) is 
--                        when "00" =>  
--                            if (dl_up_det_on_time = '1') then
                            
--                                if (to_integer(unsigned(RX_PACKET_SLOT_ID)) = i_slot) then
--                                    pkt_section_ids(i_slot) <= subframes_slots_sectionids_table(0)(i_slot);
--                                end if;                                
                            
--                                subframes_slots_sectionids_table(2)(i_slot) <= (others => ("1000000000000"));
--                                subframes_slots_sectionids_table(3)(i_slot) <= (others => ("1000000000000"));
                                
--                            else                                                                                          
                            
--                                if ((dl_cp_det_on_time = '1') and (to_integer(unsigned(RX_PACKET_SLOT_ID)) = i_slot) ) then                    
--                                    subframes_slots_sectionids_table(0)(i_slot) <= PACKET_SECTION_ID;
--                                end if;
                                
--                            end if;
--                        when "01" =>                              
--                            if (dl_up_det_on_time = '1') then
                            
--                                if (to_integer(unsigned(RX_PACKET_SLOT_ID)) = i_slot) then
--                                    pkt_section_ids(i_slot) <= subframes_slots_sectionids_table(1)(i_slot);
--                                end if;    
                                                            
--                                if (RX_PACKET_SUBFRAME_ID = 9) then
--                                    subframes_slots_sectionids_table(3)(i_slot) <= (others => ("1000000000000"));
--                                else
--                                    subframes_slots_sectionids_table(3)(i_slot) <= (others => ("1000000000000"));
--                                    subframes_slots_sectionids_table(0)(i_slot) <= (others => ("1000000000000"));
--                                end if;
                                
--                            else                                                                                          
                            
--                                if ((dl_cp_det_on_time = '1') and (to_integer(unsigned(RX_PACKET_SLOT_ID)) = i_slot) ) then                    
--                                    subframes_slots_sectionids_table(1)(i_slot) <= PACKET_SECTION_ID;
--                                end if;
                                
--                            end if;                                                    
--                        when "10" =>                              
--                            if (dl_up_det_on_time = '1') then
                            
--                                if (to_integer(unsigned(RX_PACKET_SLOT_ID)) = i_slot) then
--                                    pkt_section_ids(i_slot) <= subframes_slots_sectionids_table(2)(i_slot);
--                                end if;                                
                            
--                                subframes_slots_sectionids_table(0)(i_slot) <= (others => ("1000000000000"));
--                                subframes_slots_sectionids_table(1)(i_slot) <= (others => ("1000000000000"));
                                
--                            else                                                                                          
                            
--                                if ((dl_cp_det_on_time = '1') and (to_integer(unsigned(RX_PACKET_SLOT_ID)) = i_slot) ) then                    
--                                    subframes_slots_sectionids_table(2)(i_slot) <= PACKET_SECTION_ID;
--                                end if;
                                
--                            end if;                    
--                        when "11" =>                              
--                            if (dl_up_det_on_time = '1') then
                            
--                                if (to_integer(unsigned(RX_PACKET_SLOT_ID)) = i_slot) then
--                                    pkt_section_ids(i_slot) <= subframes_slots_sectionids_table(3)(i_slot);
--                                end if;                                
                            
--                                subframes_slots_sectionids_table(1)(i_slot) <= (others => ("1000000000000"));
--                                subframes_slots_sectionids_table(2)(i_slot) <= (others => ("1000000000000"));
                                
--                            else                                                                                          
                            
--                                if ((dl_cp_det_on_time = '1') and (to_integer(unsigned(RX_PACKET_SLOT_ID)) = i_slot) ) then                    
--                                    subframes_slots_sectionids_table(3)(i_slot) <= PACKET_SECTION_ID;
--                                end if;
                                
--                            end if;
--                        when others => 
--                            NULL;        
--                        end case;                                                                

--                end if;
--            end process; 
----        end generate;
    
--    end generate;
           
--    process (CLK)
--    begin
--        if (CLK'event and CLK = '1') then
--           addr <= to_integer(unsigned(RX_PACKET_SLOT_ID));

--           if (dl_up_det_on_time_d(0) = '1') then 
--               pkt_section_ids_1_slot <= pkt_section_ids(addr);
--           end if;           
--        end if;
--    end process;
                
----    u_SLOT_CHECK : for i_slot in SLOT_NUM-1 downto 0 generate

--        u_COUPLING : for i_section in MAX_SECTIONID_PER_PKT-1 downto 0 generate
--            process (CLK)
--            begin
--                if (CLK'event and CLK = '1') then
--                   if (dl_up_det_on_time_d(1) = '1') then 
--                       if (pkt_section_ids_1_slot(i_section) = "1000000000000") then   -- section id = default => not updated
--                           dl_cp_section_id_updated_check(i_section) <= '0';
--                           dl_up_section_id_coupling_result(i_section) <= '0';                        
--                       else                                                             -- section id != default => just been updated
--                           dl_cp_section_id_updated_check(i_section) <= '1';
                       
--                           if (pkt_section_ids_1_slot(i_section)(12 downto 0) = PACKET_SECTION_ID(i_section)) then
--                               dl_up_section_id_coupling_result(i_section) <= '1';
--                           else                    
--                               dl_up_section_id_coupling_result(i_section) <= '0';
--                           end if;
--                       end if;
--                   end if;           
--                end if;
--            end process;
--        end generate;
        
----    end generate;

    
--    process (CLK)
--    begin
--        if (CLK'event and CLK = '1') then
           
--           if (dl_cp_section_id_updated_check = 0) then           
--               dl_up_excluded_rx_corrupt <= '1';
--           else
--               dl_up_excluded_rx_corrupt <= '0';
               
--               if (dl_up_section_id_coupling_result = 0) then                   
--                   dl_up_rx_corrupt_happened <= '1';         
--               else
--                   dl_up_rx_corrupt_happened <= '0';
--               end if;                         
--           end if;
--        end if;
--    end process;
    
--    process (CLK)
--    begin
--        if (CLK'event and CLK = '1') then
--            s_rx_corrupt_sectionid(0) <= dl_up_rx_corrupt_happened and dl_up_det_on_time_d(2);
--            s_rx_corrupt_sectionid(3 downto 1) <= s_rx_corrupt_sectionid(2 downto 0);
--        end if;
--    end process;
    
--    s_RX_CORRUPT_SECTIONID_check <= s_rx_corrupt_sectionid(0) or s_rx_corrupt_sectionid(1) or s_rx_corrupt_sectionid(2) or s_rx_corrupt_sectionid(3);

end BEHAVE;