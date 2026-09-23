--------------------------------------------------------------------------------
--
-- Copyright (C) 2025, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com) / nhu.dong
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

entity RX_CORRUPT_PCID_eCPRI_Payload is
    generic (        
        IMPL_CP                     : boolean := true;
        IMPL_UP                     : boolean := true;

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
end RX_CORRUPT_PCID_eCPRI_Payload;

architecture BEHAVE of RX_CORRUPT_PCID_eCPRI_Payload is

    signal cnt                      : std_logic_vector(2 downto 0) := (others => '0');

    signal matched_version          : std_logic := '0';
    signal matched_id               : std_logic_vector(NUM_LINK-1 downto 0) := (others => '0');
    signal matched_pe               : std_logic_vector(NUM_LINK-1 downto 0) := (others => '0');
    
    signal matched_payload_version  : std_logic := '0';
    signal message_type             : std_logic_vector(7 downto 0);

    signal version                  : std_logic_vector(3 downto 0);
    signal c                        : std_logic_vector(0 downto 0);
    signal message                  : std_logic_vector(7 downto 0);
    signal payload                  : std_logic_vector(15 downto 0);
    signal datadirection            : std_logic;
    signal eaxc_id                  : std_logic_vector(15 downto 0);

    signal payload_version           : std_logic_vector(2 downto 0);
    
    signal c_plane                  : std_logic;
    signal u_plane                  : std_logic;
    signal match_message_type       : std_logic;
	
    signal rx_corrupt               	   : std_logic_vector(2 downto 0) := (others => '0');
    signal s_rx_corrupt_pcid               : std_logic_vector(2 downto 0) := (others => '0');
    signal s_rx_corrupt_ecpri_version      : std_logic_vector(2 downto 0) := (others => '0');
    signal s_rx_corrupt_payload_version    : std_logic_vector(2 downto 0) := (others => '0');
    
    signal condition0               : std_logic := '0';
    signal condition1               : std_logic_vector(1 downto 0) := (others => '0');

    signal output_enable            : std_logic_vector(1 downto 0) := (others => '0');

begin

--------------------------------------------------------------------------------
-- Parameters
--------------------------------------------------------------------------------
       
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (IN_VALID = '1') then
                if (IN_LAST = '1') then
                    cnt <= (others => '0');
                else
                    if (cnt = 7) then
                        cnt <= cnt;
                    else
                        cnt <= cnt + 1;
                    end if;
                end if;
--            else
--                cnt <= (others => '0');
            end if;
        end if;
    end process;

    version            <= IN_DATA(7 downto 4);
    c                  <= IN_DATA(0 downto 0);
    message            <= IN_DATA(15 downto 8);
    payload            <= IN_DATA(23 downto 16) & IN_DATA(31 downto 24);
    datadirection      <= IN_DATA(7);
    message_type       <= IN_DATA(15 downto 8);
    payload_version    <= IN_DATA(6 downto 4);

    eaxc_id            <= IN_DATA(39 downto 32) & IN_DATA(47 downto 40);
	
--------------------------------------------------------------------------------
-- RX_Corrupt: eCPRIversion, payloadversion, pcid
--------------------------------------------------------------------------------
    RX_CORRUPT_PCID_eCPRIVERSION_PAYLOADVERSION <= rx_corrupt(0)                    or rx_corrupt(1)                    or rx_corrupt(2); -- stretch 3 clk 156.25
    RX_CORRUPT_PCID                             <= s_rx_corrupt_pcid(0)             or s_rx_corrupt_pcid(1)             or s_rx_corrupt_pcid(2); -- stretch 3 clk 156.25
    RX_CORRUPT_eCPRIVERSION                     <= s_rx_corrupt_ecpri_version(0)    or s_rx_corrupt_ecpri_version(1)    or s_rx_corrupt_ecpri_version(2); -- stretch 3 clk 156.25
    RX_CORRUPT_PAYLOADVERSION                   <= s_rx_corrupt_payload_version(0)  or s_rx_corrupt_payload_version(1)  or s_rx_corrupt_payload_version(2); -- stretch 3 clk 156.25
    
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (cnt = 2) then         
                if (u_plane = '1') then        
                    rx_corrupt(0) <= not (matched_version and matched_payload_version and ( matched_id(0) 
                                                                                         or matched_id(1) 
                                                                                         or matched_id(2) 
                                                                                         or matched_id(3) 
                                                                                         or matched_id(4) 
                                                                                         or matched_id(5) 
                                                                                         or matched_id(6) 
                                                                                         or matched_id(7) ) );
                    s_rx_corrupt_pcid(0) <= not ( matched_id(0)
                                          or matched_id(1) 
                                          or matched_id(2) 
                                          or matched_id(3) 
                                          or matched_id(4) 
                                          or matched_id(5) 
                                          or matched_id(6) 
                                          or matched_id(7) );           
                    
                    s_rx_corrupt_ecpri_version(0) <= not matched_version;
                    
                    s_rx_corrupt_payload_version(0) <= not matched_payload_version;
                                                                                                             
                else 
                    if (c_plane = '1') then
                        rx_corrupt(0) <= not (matched_version and matched_payload_version);
                        
                        s_rx_corrupt_ecpri_version(0) <= not matched_version;
                    
                        s_rx_corrupt_payload_version(0) <= not matched_payload_version;                        
                    end if;
                end if;                                                                                                     
                                                                                            
            else
                rx_corrupt(0)                         <= '0';    
                s_rx_corrupt_pcid(0)                  <= '0';
                s_rx_corrupt_ecpri_version(0)         <= '0';                 
                s_rx_corrupt_payload_version(0)       <= '0';  
                      
            end if;
            rx_corrupt(2 downto 1)                    <= rx_corrupt(1 downto 0);
            s_rx_corrupt_pcid(2 downto 1)             <= s_rx_corrupt_pcid(1 downto 0)           ;
            s_rx_corrupt_ecpri_version(2 downto 1)    <= s_rx_corrupt_ecpri_version(1 downto 0)  ;                 
            s_rx_corrupt_payload_version(2 downto 1)  <= s_rx_corrupt_payload_version(1 downto 0);  
        end if;
    end process;



--------------------------------------------------------------------------------
-- ecpriVersion, ecpriConcatenate (eCPRI layer)
--------------------------------------------------------------------------------
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (IN_VALID /= '0') and (IN_LAST = '1') then
                match_message_type <= '0';
            else
                if (cnt = 0) then
                    if (message_type = x"02") then -- message_type C
                        c_plane <= '1';
                    else
                        c_plane <= '0';
                    end if;
                    if (message_type = x"00") then -- U
                        u_plane <= '1';
                        match_message_type <= '1';
                    else
                        u_plane <= '0';
                        match_message_type <= '0';
                    end if;         
                end if;
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------
-- ecpriRtcid/ecpriPcid (eCPRI layer)
--------------------------------------------------------------------------------

    u_DL_PARAM_ID : for i in NUM_LINK-1 downto 0 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (IN_VALID = '1') and (IN_LAST = '1') then
            if (IN_LAST = '1') then
                matched_id(i) <= '0';
            else
                if (cnt = 0) then
                    if (eaxc_id = PARAM_ID(i)) then
                        matched_id(i) <= PARAM_ID_EN(i);
                    else
                        matched_id(i) <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
    end generate;

--------------------------------------------------------------------------------
-- dataDirection (O-RAN layer)
--------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (IN_VALID = '1') and (IN_LAST = '1') then
            if (IN_LAST = '1') then
                matched_payload_version <= '0';
            else
                if (cnt = 1) then
                    
                    if (payload_version = "001") then
                        matched_payload_version <= '1';
                    else
                        matched_payload_version <= '0';
                    end if;
                    
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
--            if (IN_VALID = '1') and (IN_LAST = '1') then
            if (IN_LAST = '1') then
                matched_version <= '0';
            else
                if (cnt = 0) then
                    if (version = "0001") then
                        matched_version <= '1';
                    else
                        matched_version <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
   
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (cnt = 1) then
                for i in MAX_RU_ELEMENT-1 downto 0 loop
                if (IN_PE_INDEX(i) = '1') then                    
                    RX_CORRUPT_OF_PE(i) <= '1';                                            
                else
                    RX_CORRUPT_OF_PE(i) <= '0';
                end if;
                end loop;
            else
                if (cnt = 0) then
                    RX_CORRUPT_OF_PE <= (others => '0');
                end if;
            end if;
        end if;
    end process;

end BEHAVE;