--------------------------------------------------------------------------------
--
-- Copyright (C) 2022, Samsung Electronics Co., LTD. All Right Reserved.
--
-- Author   : jaekyu.no (jaekyu.no@samsung.com) / nhu.dong
-- Date     : 2022.02.16
--------------------------------------------------------------------------------
-- Function description
--   1. Performance measurement component
--   2. RX window monitoring
--------------------------------------------------------------------------------
-- Change log
--   Rev 1 (2022.02.16) - initial release
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity rx_corrupt_counter is
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
end rx_corrupt_counter;

architecture BEHAVE of rx_corrupt_counter is

    signal update_long_pulse        : std_logic_vector(15 downto 0) := (others => '0');
    signal update_buf               : std_logic_vector(2 downto 0) := (others => '0');
    signal update_cnt_sec           : std_logic_vector(6 downto 0) := (others => '0');
    signal update_cnt               : std_logic_vector(7 downto 0) := (others => '0');
    signal update_en                : std_logic := '0';
    signal update_en_d                : std_logic;
    signal update_en_dd                : std_logic;

    signal update_en_or                : std_logic;



    signal rx_corrupt_sectionid_or:    std_logic;

    signal rx_corrupt_sectionid_100m:    std_logic_vector(3 downto 0) := (others => '0');
    signal s_rx_corrupt_ecpriversion_payloadversion_pcid_100m: std_logic_vector(3 downto 0) := (others => '0');
    signal s_rx_corrupt_ecpriversion_100m       : std_logic_vector(3 downto 0) := (others => '0');
    signal s_rx_corrupt_pcid_100m               : std_logic_vector(3 downto 0) := (others => '0');
    signal s_rx_corrupt_payloadversion_100m     : std_logic_vector(3 downto 0) := (others => '0');

    signal cnt_rx_corrupt_sectionid                              : std_logic_vector(63 downto 0) := (others => '0');
    signal cnt_rx_corrupt_ecpriversion_payloadversion_pcid       : std_logic_vector(63 downto 0) := (others => '0');
    signal cnt_rx_corrupt_ecpriversion                           : std_logic_vector(63 downto 0) := (others => '0');
    signal cnt_rx_corrupt_pcid                                   : std_logic_vector(63 downto 0) := (others => '0');
    signal cnt_rx_corrupt_payloadversion                         : std_logic_vector(63 downto 0) := (others => '0');
    
    signal s_cnt_rx_corrupt : std_logic_vector(63 downto 0) := (others => '0');
    
begin

--    process (CLK_245p76MHz)
--    begin
--        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
--            update_en_d <= UPDATE_EN_IN;
--            update_en_dd <= update_en_d;
--        end if;
--    end process;
    
--    update_en_or <= UPDATE_EN_IN or update_en_d or update_en_dd;
    
    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            update_en <= UPDATE_EN_IN; --update_en_or;
        end if;
    end process;
    
--    process (CLK_CPUIF)
--    begin
--        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
--            update_en <= UPDATE_EN_IN;
--        end if;
--    end process;

    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            if (update_en = '1') then
            
                CNT_RX_CORRUPT                          <= s_cnt_rx_corrupt;         
                CNT_RX_SECTIONID                        <= cnt_rx_corrupt_sectionid;                                                   
                CNT_RX_PCID_eCPRIVERSION_PAYLOADVERSION <= cnt_rx_corrupt_ecpriversion_payloadversion_pcid;     
                CNT_RX_PCID                             <= cnt_rx_corrupt_pcid;                                                     
                CNT_RX_eCPRIVERSION                     <= cnt_rx_corrupt_ecpriversion;                                                     
                CNT_RX_PAYLOADVERSION                   <= cnt_rx_corrupt_payloadversion;                                         
               
            end if;
        end if;
    end process;

	process (CLK_245p76MHz)
    begin
        if (CLK_245p76MHz'event and CLK_245p76MHz = '1') then
            rx_corrupt_sectionid_or <= RX_CORRUPT_SECTIONID; --(0) or RX_CORRUPT_SECTIONID(1);            
        end if;
    end process;
    
    process (CLK_CPUIF)
    begin
        if (CLK_CPUIF'event and CLK_CPUIF = '1') then
            rx_corrupt_sectionid_100m <= rx_corrupt_sectionid_100m( 2 downto 0) & rx_corrupt_sectionid_or;
            s_rx_corrupt_ecpriversion_payloadversion_pcid_100m <= s_rx_corrupt_ecpriversion_payloadversion_pcid_100m(2 downto 0) & (RX_CORRUPT_PCID_eCPRIVERSION_PAYLOADVERSION and RX_CORRUPT_OF_PE);
            
            s_rx_corrupt_ecpriversion_100m      <= s_rx_corrupt_ecpriversion_100m(2 downto 0) & (RX_CORRUPT_eCPRIVERSION and RX_CORRUPT_OF_PE);
            s_rx_corrupt_pcid_100m              <= s_rx_corrupt_pcid_100m(2 downto 0) & (RX_CORRUPT_PCID and RX_CORRUPT_OF_PE);
            s_rx_corrupt_payloadversion_100m    <= s_rx_corrupt_payloadversion_100m(2 downto 0) & (RX_CORRUPT_PAYLOADVERSION and RX_CORRUPT_OF_PE);
  
        end if;
    end process;
    
    
    process (RST_CPUIF, CLK_CPUIF)
    begin
        if (RST_CPUIF = '1') then
            s_cnt_rx_corrupt <= (others => '0');
        elsif (CLK_CPUIF'event and CLK_CPUIF = '1') then
            if (update_en = '1') then
                if ((s_rx_corrupt_ecpriversion_payloadversion_pcid_100m(3 downto 2) = "01") or (rx_corrupt_sectionid_100m(3 downto 2) = "01") ) then
                    s_cnt_rx_corrupt <= x"0000000000000001";
                else
                    s_cnt_rx_corrupt <= x"0000000000000000";
                end if;
                
                if (s_rx_corrupt_ecpriversion_payloadversion_pcid_100m(3 downto 2) = "01") then
                    cnt_rx_corrupt_ecpriversion_payloadversion_pcid <= x"0000000000000001";
                else
                    cnt_rx_corrupt_ecpriversion_payloadversion_pcid <= x"0000000000000000";
                end if;
                
                if (rx_corrupt_sectionid_100m(3 downto 2) = "01") then
                    cnt_rx_corrupt_sectionid <= x"0000000000000001";
                else
                    cnt_rx_corrupt_sectionid <= x"0000000000000000";
                end if;
                
                if (s_rx_corrupt_ecpriversion_100m(3 downto 2) = "01") then
                    cnt_rx_corrupt_ecpriversion <= x"0000000000000001";
                else
                    cnt_rx_corrupt_ecpriversion <= x"0000000000000000";
                end if;
                
                if (s_rx_corrupt_pcid_100m(3 downto 2) = "01") then
                    cnt_rx_corrupt_pcid <= x"0000000000000001";
                else
                    cnt_rx_corrupt_pcid <= x"0000000000000000";
                end if;
                
                if (s_rx_corrupt_payloadversion_100m(3 downto 2) = "01") then
                    cnt_rx_corrupt_payloadversion <= x"0000000000000001";
                else
                    cnt_rx_corrupt_payloadversion <= x"0000000000000000";
                end if;
            else
                if ((s_rx_corrupt_ecpriversion_payloadversion_pcid_100m(3 downto 2) = "01") or (rx_corrupt_sectionid_100m(3 downto 2) = "01") ) then
                    s_cnt_rx_corrupt <= s_cnt_rx_corrupt + 1;            
                end if;
                
                if (s_rx_corrupt_ecpriversion_payloadversion_pcid_100m(3 downto 2) = "01") then
                    cnt_rx_corrupt_ecpriversion_payloadversion_pcid <= cnt_rx_corrupt_ecpriversion_payloadversion_pcid + 1;            
                end if;
                
                if (rx_corrupt_sectionid_100m(3 downto 2) = "01") then
                    cnt_rx_corrupt_sectionid <= cnt_rx_corrupt_sectionid + 1;            
                end if;
                
                if (s_rx_corrupt_ecpriversion_100m(3 downto 2) = "01") then
                    cnt_rx_corrupt_ecpriversion <= cnt_rx_corrupt_ecpriversion + 1;            
                end if;
                
                if (s_rx_corrupt_pcid_100m(3 downto 2) = "01") then
                    cnt_rx_corrupt_pcid <= cnt_rx_corrupt_pcid + 1;            
                end if;
                
                if (s_rx_corrupt_payloadversion_100m(3 downto 2) = "01") then
                    cnt_rx_corrupt_payloadversion <= cnt_rx_corrupt_payloadversion + 1;            
                end if;

            end if;
               
        end if;
    end process;

end BEHAVE;