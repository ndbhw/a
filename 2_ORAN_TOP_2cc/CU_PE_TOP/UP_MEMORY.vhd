--================================================================================
-- Project name : Verizon C-band NR RT8808 (8T8R 320W RU)                                        
-- Filename     : UP_MEMORY.vhd                                                   
-- Author       : Taeyoup Kim (taeyoup.kim@samsung.com)                           
-- Description  : True Dual-Port RAM with single clock                             
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

    entity UP_MEMORY is 
    generic 
    (
    VENDOR         : string  := "XILINX";   
    ADDR_WIDTH     : natural := 13;
   	DATA_WIDTH     : natural := 72
    );
    port 
    (
    CLK            : in  std_logic;
    ENA            : in  std_logic;                             
    ENB            : in  std_logic;
    WEB            : in  std_logic;     
    ADDRA          : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    ADDRB          : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    DINA           : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    DOUTB          : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
    end UP_MEMORY;

architecture BEHAVE of UP_MEMORY is


    component XILINX_MEM_TDP is
    generic 
   	(
   		ADDR_WIDTH   : natural := 13;
   		DATA_WIDTH   : natural := 72
   	);             
    port (         
      CLK          : in  std_logic;
      ENA          : in  std_logic;
      ADDRA        : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
      DINA         : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
                   
      ENB          : in  std_logic;
      WEB          : in  std_logic;     
      ADDRB        : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
      DOUTB        : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
    end component;


    component INTEL_MEM_TDP is
    generic 
    (
   		ADDR_WIDTH   : natural := 13;
   		DATA_WIDTH   : natural := 72
    );             
    port           
    (              
		  clk		       : in std_logic;
		  addr_a	     : in natural range 0 to 2**ADDR_WIDTH - 1;
		  addr_b	     : in natural range 0 to 2**ADDR_WIDTH - 1;
		  data_a	     : in std_logic_vector((DATA_WIDTH-1) downto 0);
		  data_b	     : in std_logic_vector((DATA_WIDTH-1) downto 0);
		  we_a	       : in std_logic := '1';
		  we_b	       : in std_logic := '1';
		  q_a		       : out std_logic_vector((DATA_WIDTH -1) downto 0);
		  q_b		       : out std_logic_vector((DATA_WIDTH -1) downto 0)
    );    
    end component;

    -- for INTEL
    signal i_addra : natural range 0 to 2**ADDR_WIDTH - 1 := 0;  
    signal i_addrb : natural range 0 to 2**ADDR_WIDTH - 1 := 0;  
    signal i_doutb : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');  

begin


    u_UP_MEM_GEN_X : if VENDOR = "XILINX" generate 

    -- latency : 2 clk
    UP_MEM : XILINX_MEM_TDP 
    generic map 
    (
    	ADDR_WIDTH   => ADDR_WIDTH,
    	DATA_WIDTH   => DATA_WIDTH 
    )
    port map(
      CLK          => CLK,        
      ENA          => ENA,        
      ADDRA        => ADDRA,      
      DINA         => DINA,                                                                          
      ENB          => ENB,        
      WEB          => WEB,        
      ADDRB        => ADDRB,      
      DOUTB        => DOUTB       
  
    );    

    end generate;  

    u_UP_MEM_GEN_I : if VENDOR = "INTEL" generate 

    i_addra <= conv_integer(ADDRA);
    i_addrb <= conv_integer(ADDRB);

    -- latency : 1 clk
    UP_MEM : INTEL_MEM_TDP 
    generic map 
    (
    	ADDR_WIDTH   => ADDR_WIDTH,
    	DATA_WIDTH   => DATA_WIDTH 
    )
    port map(
		  clk		       => CLK,                        
		  addr_a	     => i_addra,                    
		  addr_b	     => i_addrb,                    
		  data_a	     => DINA,                       
		  data_b	     => x"FF_0000_0000_0000_0000", 
		  we_a	       => ENA,                        
		  we_b	       => WEB,                        
		  q_a		       => open,                       
		  q_b		       => i_doutb                    
    );    

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
           DOUTB <= i_doutb;              
        end if;
    end process;

    end generate; 


end BEHAVE;