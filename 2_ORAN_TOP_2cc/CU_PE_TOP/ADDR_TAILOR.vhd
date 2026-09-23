--================================================================================
-- Filename     : ADDR_TAILOR.vhd
-- Author       : Taeyoup Kim (taeyoup.kim@samsung.com)
-- Description  : Address and Symbol Index Alignment  
----------------------------------------------------------------------------------
--     Date    |     By           |  Version | Description
----------------------------------------------------------------------------------
--  11-30-2020 | Taeyoup Kim      |    1.0   | Original Version  
--================================================================================
-- Copyright (c) 2020 SAMSUNG. All rights reserved.                               
--================================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


    entity ADDR_TAILOR is
    generic (
    SCS                      : natural := 30;
   	ADDR_WIDTH               : natural :=  3
    );
    port (    
    SUBFRAME_ID              : in  std_logic_vector(3 downto 0);
    SLOT_ID                  : in  std_logic_vector(5 downto 0);
    SYMBOL_ID                : in  std_logic_vector(5 downto 0);
    ADDR                     : out std_logic_vector(ADDR_WIDTH - 1 downto 0)  
    );
    end ADDR_TAILOR;

architecture BEHAVE of ADDR_TAILOR is

    signal INDEX : std_logic_vector( 1 downto 0) := (others => '0'); 
   
begin

    u_SCS_15_kHz : if SCS = 15 generate 

    ADDR <= SYMBOL_ID(ADDR_WIDTH - 1 downto 0);

    end generate;     
    
    u_SCS_30_kHz : if SCS = 30 generate 

    INDEX <= SUBFRAME_ID(0) & SLOT_ID(0);

    process (INDEX,SYMBOL_ID)
    begin
        case (INDEX) is
            when "00" => ADDR <=  SYMBOL_ID(ADDR_WIDTH - 1 downto 0);
            when "01" => ADDR <=  SYMBOL_ID(ADDR_WIDTH - 1 downto 0) + 6;
            when "10" => ADDR <=  SYMBOL_ID(ADDR_WIDTH - 1 downto 0) + 4;
            when "11" => ADDR <=  SYMBOL_ID(ADDR_WIDTH - 1 downto 0) + 2; 
            when others => ADDR <= SYMBOL_ID(ADDR_WIDTH - 1 downto 0);
        end case;
    end process;

    end generate; 
                                                        
end BEHAVE;

