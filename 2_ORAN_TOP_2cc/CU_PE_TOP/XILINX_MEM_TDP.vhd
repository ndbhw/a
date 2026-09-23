library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

Library xpm;
use xpm.vcomponents.all;

 
entity XILINX_MEM_TDP is
    generic 
   	(
   		ADDR_WIDTH : natural := 13;
   		DATA_WIDTH : natural := 72
   	);
    port (
      CLK        : in  std_logic;
      ENA        : in  std_logic;
      ADDRA      : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
      DINA       : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
                 
      ENB        : in  std_logic;
      WEB        : in  std_logic;     
      ADDRB      : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
      DOUTB      : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end XILINX_MEM_TDP;

 
architecture behavior of XILINX_MEM_TDP is 

    
BEGIN

-- xpm_memory_tdpram: True Dual Port RAM
-- Xilinx Parameterized Macro, version 2020.1

xpm_memory_tdpram_inst : xpm_memory_tdpram
generic map (
   ADDR_WIDTH_A => ADDR_WIDTH,              -- DECIMAL
   ADDR_WIDTH_B => ADDR_WIDTH,              -- DECIMAL
   AUTO_SLEEP_TIME => 0,                    -- DECIMAL
   BYTE_WRITE_WIDTH_A => DATA_WIDTH,        -- DECIMAL
   BYTE_WRITE_WIDTH_B => DATA_WIDTH,        -- DECIMAL
   CASCADE_HEIGHT => 4,                     -- DECIMAL
   CLOCKING_MODE => "common_clock",         -- String
   ECC_MODE => "no_ecc",                    -- String
   MEMORY_INIT_FILE => "none",              -- String
   MEMORY_INIT_PARAM => "0",                -- String
   MEMORY_OPTIMIZATION => "true",           -- String
   MEMORY_PRIMITIVE => "ultra",             -- String  --"auto",      
   MEMORY_SIZE => DATA_WIDTH*2**ADDR_WIDTH, -- DECIMAL -- 2048,             
   MESSAGE_CONTROL => 0,                    -- DECIMAL
   READ_DATA_WIDTH_A => DATA_WIDTH,         -- DECIMAL
   READ_DATA_WIDTH_B => DATA_WIDTH,         -- DECIMAL
   READ_LATENCY_A => 6,                     -- DECIMAL
   READ_LATENCY_B => 6,                     -- DECIMAL
   READ_RESET_VALUE_A => "0",               -- String
   READ_RESET_VALUE_B => "0",               -- String
   RST_MODE_A => "SYNC",                    -- String
   RST_MODE_B => "SYNC",                    -- String
   SIM_ASSERT_CHK => 0,                     -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
   USE_EMBEDDED_CONSTRAINT => 0,            -- DECIMAL
   USE_MEM_INIT => 1,                       -- DECIMAL
   WAKEUP_TIME => "disable_sleep",          -- String
   WRITE_DATA_WIDTH_A => DATA_WIDTH,        -- DECIMAL
   WRITE_DATA_WIDTH_B => DATA_WIDTH,        -- DECIMAL
   WRITE_MODE_A => "no_change",             -- String
   WRITE_MODE_B => "no_change"              -- String
)                                     
port map (                            
   dbiterra => open,                        -- 1-bit output: Status signal to indicate double bit error occurrence
                                            -- on the data output of port A.
                                            
   dbiterrb => open,                        -- 1-bit output: Status signal to indicate double bit error occurrence
                                            -- on the data output of port A.
                                            
   douta => open,                           -- READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
   doutb => DOUTB,                          -- READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
   sbiterra => open,                        -- 1-bit output: Status signal to indicate single bit error occurrence
                                            -- on the data output of port A.
                                            
   sbiterrb => open,                        -- 1-bit output: Status signal to indicate single bit error occurrence
                                            -- on the data output of port B.
                                            
   addra => ADDRA,                          -- ADDR_WIDTH_A-bit input: Address for port A write and read operations.
   addrb => ADDRB,                          -- ADDR_WIDTH_B-bit input: Address for port B write and read operations.
   clka => CLK,                             -- 1-bit input: Clock signal for port A. Also clocks port B when
                                            -- parameter CLOCKING_MODE is "common_clock".
                                            
   clkb => CLK,                             -- 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                            -- "independent_clock". Unused when parameter CLOCKING_MODE is
                                            -- "common_clock".
                                            
   dina => DINA,                            -- WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
   dinb => x"FF_0000_0000_0000_0000",       -- WRITE_DATA_WIDTH_B-bit input: Data input for port B write operations.
   ena => ENA,                              -- 1-bit input: Memory enable signal for port A. Must be high on clock
                                            -- cycles when read or write operations are initiated. Pipelined
                                            -- internally.
                                            
   enb => ENB,                              -- 1-bit input: Memory enable signal for port B. Must be high on clock
                                            -- cycles when read or write operations are initiated. Pipelined
                                            -- internally.
                                            
   injectdbiterra => '0',                   -- 1-bit input: Controls double bit error injection on input data when
                                            -- ECC enabled (Error injection capability is not available in
                                            -- "decode_only" mode).
                                            
   injectdbiterrb => '0',                   -- 1-bit input: Controls double bit error injection on input data when
                                            -- ECC enabled (Error injection capability is not available in
                                            -- "decode_only" mode).
                                            
   injectsbiterra => '0',                   -- 1-bit input: Controls single bit error injection on input data when
                                            -- ECC enabled (Error injection capability is not available in
                                            -- "decode_only" mode).
                                            
   injectsbiterrb => '0',                   -- 1-bit input: Controls single bit error injection on input data when
                                            -- ECC enabled (Error injection capability is not available in
                                            -- "decode_only" mode).
                                            
   regcea => ENA,                           -- 1-bit input: Clock Enable for the last register stage on the output
                                            -- data path.
                                            
   regceb => ENB,                           -- 1-bit input: Clock Enable for the last register stage on the output
                                            -- data path.
                                            
   rsta => '0',                             -- 1-bit input: Reset signal for the final port A output register
                                            -- stage. Synchronously resets output port douta to the value specified
                                            -- by parameter READ_RESET_VALUE_A.
                                            
   rstb => '0',                             -- 1-bit input: Reset signal for the final port B output register
                                            -- stage. Synchronously resets output port doutb to the value specified
                                            -- by parameter READ_RESET_VALUE_B.
                                            
   sleep => '0',                            -- 1-bit input: sleep signal to enable the dynamic power saving feature.
   wea => "1",                              -- WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                            -- for port A input data port dina. 1 bit wide when word-wide writes
                                            -- are used. In byte-wide write configurations, each bit controls the
                                            -- writing one byte of dina to address addra. For example, to
                                            -- synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                            -- is 32, wea would be 4'b0010.
                                            
   web(0) => WEB                            -- WRITE_DATA_WIDTH_B/BYTE_WRITE_WIDTH_B-bit input: Write enable vector
                                            -- for port B input data port dinb. 1 bit wide when word-wide writes
                                            -- are used. In byte-wide write configurations, each bit controls the
                                            -- writing one byte of dinb to address addrb. For example, to
                                            -- synchronously write only bits [15-8] of dinb when WRITE_DATA_WIDTH_B
                                            -- is 32, web would be 4'b0010.

);

-- End of xpm_memory_tdpram_inst instantiation    

	    			    
END;
