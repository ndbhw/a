--================================================================================
-- Project name : Verizon C-band NR RT8808 (8T8R 320W RU)                                     
-- Filename     : CP_MEMORY.vhd                                                    
-- Author       : Taeyoup Kim (taeyoup.kim@samsung.com)                           
-- Description  : Simple Dual-Port RAM with single clock                       
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

    entity CP_MEMORY is 
    generic 
    (
    VENDOR         : string  := "XILINX";   
 	  ADDR_WIDTH     : natural := 9;  
 	  DATA_WIDTH     : natural := 40 
    );
    port 
    (
    CLK            : in  std_logic;                                
    WEA            : in  std_logic;  
    ENA            : in  std_logic;                                
    ENB            : in  std_logic;                                                              
    ADDRA          : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    ADDRB          : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    DIA            : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    DOB            : out std_logic_vector(DATA_WIDTH - 1 downto 0) 
    );
    end CP_MEMORY;

architecture BEHAVE of CP_MEMORY is


    component XILINX_MEM_SDP is
    generic 
    (
    	ADDR_WIDTH   : natural := 9;
    	DATA_WIDTH   : natural := 40
    );
    port
    (
      clk          : in  std_logic;
      ena          : in  std_logic;
      enb          : in  std_logic;
      wea          : in  std_logic;
      addra        : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
      addrb        : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
      dia          : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
      dob          : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
    end component;

    component INTEL_MEM_SDP is
    generic 
    (
    	ADDR_WIDTH   : natural := 9;
    	DATA_WIDTH   : natural := 40
    );    
    port 
    (
    	clk		       : in std_logic;
    	waddr	       : in natural range 0 to 2**ADDR_WIDTH - 1;
    	raddr	       : in natural range 0 to 2**ADDR_WIDTH - 1;
    	data	       : in std_logic_vector((DATA_WIDTH-1) downto 0);
    	ce		       : in std_logic := '1';
    	we		       : in std_logic := '1';
    	re		       : in std_logic := '1';
    	q		         : out std_logic_vector((DATA_WIDTH -1) downto 0)
    );    
    end component;

    -- for INTEL 
    signal i_addra : natural range 0 to 2**ADDR_WIDTH - 1 := 0; 
    signal i_addrb : natural range 0 to 2**ADDR_WIDTH - 1 := 0;


begin


    u_CP_MEM_GEN_X : if VENDOR = "XILINX" generate 

    -- latency : 1 clk
    DL_CP_MEM : XILINX_MEM_SDP 
    generic map 
    (
    	ADDR_WIDTH   => ADDR_WIDTH,
    	DATA_WIDTH   => DATA_WIDTH 
    )
    port map(
      clk          => CLK, 
      wea          => WEA, 
      ena          => ENA, 
      enb          => ENB, 
      addra        => ADDRA,   
      addrb        => ADDRB,   
      dia          => DIA, 
      dob          => DOB    
    );    

    end generate;  

    u_CP_MEM_GEN_I : if VENDOR = "INTEL" generate 

    i_addra <= conv_integer(ADDRA);
    i_addrb <= conv_integer(ADDRB);

    -- latency : 1 clk
    DL_CP_MEM : INTEL_MEM_SDP 
    generic map 
    (
    	ADDR_WIDTH   => ADDR_WIDTH,
    	DATA_WIDTH   => DATA_WIDTH 
    )
    port map(
    	clk		       => CLK,       
    	waddr	       => i_addra,   
    	raddr	       => i_addrb,   
    	data	       => DIA,       
    	ce		       => '1',       
    	we		       => ENA,       
    	re		       => ENB,       
    	q		         => DOB       
    );    

    end generate; 


end BEHAVE;