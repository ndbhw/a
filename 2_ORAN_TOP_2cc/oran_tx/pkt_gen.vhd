--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : Packet generator (O-RAN component)                            --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.15                                                    --
--                                                                            --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity PKT_GEN is
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        CLK_UP                      : in  std_logic;
        RST_UP                      : in  std_logic;

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
-- PRB packer
--------------------------------------------------------------------------------

        PACK_PORT_ID                : in  std_logic_vector(2 downto 0);
        PACK_VLAN_MODE              : in  std_logic_vector(1 downto 0);
        PACK_LENGTH                 : in  std_logic_vector(15 downto 0);

        PACK_VALID                  : in  std_logic;
        PACK_START                  : in  std_logic;
        PACK_LAST                   : in  std_logic;
        PACK_KEEP                   : in  std_logic_vector(3 downto 0);
        PACK_DATA                   : in  std_logic_vector(31 downto 0);

--------------------------------------------------------------------------------
-- U-Plane
--------------------------------------------------------------------------------

        TX_VALID                    : out std_logic;
        TX_START                    : out std_logic;
        TX_LAST                     : out std_logic;
        TX_DEST                     : out std_logic_vector(2 downto 0);
        TX_KEEP                     : out std_logic_vector(7 downto 0);
        TX_DATA                     : out std_logic_vector(63 downto 0)
    );
end PKT_GEN;

architecture BEHAVE of PKT_GEN is

    signal length_cnt               : std_logic_vector(2 downto 0) := (others => '1');
    signal length_addr              : std_logic_vector(11 downto 0) := (others => '0');
    signal length_insert            : std_logic_vector(3 downto 0) := (others => '0');

    component MTU_BUFFER is
    port (
        CLKA                        : in  std_logic;
        ENA                         : in  std_logic;
        WEA                         : in  std_logic_vector(3 downto 0);
        ADDRA                       : in  std_logic_vector(11 downto 0);
        DINA                        : in  std_logic_vector(35 downto 0);
        CLKB                        : in  std_logic;
        ENB                         : in  std_logic;
        ADDRB                       : in  std_logic_vector(10 downto 0);
        DOUTB                       : out std_logic_vector(71 downto 0)
    );
    end component;

    component MTU_BUFFER_EXT is
    port (
        CLKA                        : in  std_logic;
        ENA                         : in  std_logic;
        WEA                         : in  std_logic;
        ADDRA                       : in  std_logic_vector(11 downto 0);
        DINA                        : in  std_logic_vector(8 downto 0);
        CLKB                        : in  std_logic;
        ENB                         : in  std_logic;
        ADDRB                       : in  std_logic_vector(10 downto 0);
        DOUTB                       : out std_logic_vector(17 downto 0)
    );
    end component;

    constant LATENCY_BRAM           : natural := 3;

    signal ena                      : std_logic := '0';
    signal wea                      : std_logic_vector(3 downto 0) := (others => '0');
    signal addr                     : std_logic_vector(11 downto 0);
    signal addra                    : std_logic_vector(11 downto 0);
    signal dina                     : std_logic_vector(35 downto 0) := (others => '0');
    signal dina_ext                 : std_logic_vector(8 downto 0) := (others => '0');
    signal enb                      : std_logic_vector(LATENCY_BRAM-1 downto 0) := (others => '0');
    signal addrb                    : std_logic_vector(10 downto 0);
    signal doutb                    : std_logic_vector(71 downto 0);
    signal doutb_ext                : std_logic_vector(17 downto 0);

    signal addra_done               : std_logic_vector(10 downto 0);
    signal addr_update              : std_logic_vector(2 downto 0) := (others => '0');
    signal addr_end                 : std_logic_vector(10 downto 0);

    type fsm                        is (IDLE, TRANSACTION, POSTLOAD);
    signal fsm_tx                   : fsm;
    signal cnt_tx_state             : std_logic_vector(1 downto 0);

    signal rd_valid                 : std_logic_vector(LATENCY_BRAM downto 0) := (others => '0');

begin

--------------------------------------------------------------------------------
-- Write side
--------------------------------------------------------------------------------

    process (CLK_UP)
    begin
        if (CLK_UP'event and CLK_UP = '1') then
            if (PACK_START = '1') then
                length_cnt <= (others => '0');
            else
                if (length_cnt = 7) then
                    length_cnt <= length_cnt;
                else
                    length_cnt <= length_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK_UP)
    begin
        if (CLK_UP'event and CLK_UP = '1') then
            if (PACK_VLAN_MODE = "01") then
                if (length_cnt = 5) then
                    length_addr <= addra;
                end if;
            elsif (PACK_VLAN_MODE = "11") then
                if (length_cnt = 6) then
                    length_addr <= addra;
                end if;
            else
                if (length_cnt = 4) then
                    length_addr <= addra;
                end if;
            end if;
        end if;
    end process;

    process (CLK_UP)
    begin
        if (CLK_UP'event and CLK_UP = '1') then
            if (PACK_VALID = '1') and (PACK_LAST = '1') then
                length_insert <= (others => '1');
            else
                length_insert <= length_insert(2 downto 0) & '0';
            end if;
        end if;
    end process;

    process (CLK_UP)
    begin
        if (CLK_UP'event and CLK_UP = '1') then
            if    (PACK_LAST = '1') then
                ena <= '1';
                wea <= (others => '1');
            elsif (length_insert(0) = '1') then
                ena <= '1';
                wea <= "1100";
            else
                ena <= PACK_VALID;
                wea <= PACK_KEEP;
            end if;
        end if;
    end process;

    process (CLK_UP)
    begin
        if (CLK_UP'event and CLK_UP = '1') then
            dina(35) <= PACK_START;
            dina(26) <= PACK_LAST;
        end if;
    end process;

    process (CLK_UP)
    begin
        if (CLK_UP'event and CLK_UP = '1') then
            if (PACK_LAST = '1') then
                if    (PACK_KEEP = x"E") then
                    dina(17) <= '1';
                    dina(8)  <= '1';
                elsif (PACK_KEEP = x"C") then
                    dina(17) <= '1';
                    dina(8)  <= '0';
                elsif (PACK_KEEP = x"8") then
                    dina(17) <= '0';
                    dina(8)  <= '1';
                else
                    dina(17) <= '0';
                    dina(8)  <= '0';
                end if;
            else
                dina(17) <= '0';
                dina(8)  <= '0';
            end if;
        end if;
    end process;

    process (CLK_UP)
    begin
        if (CLK_UP'event and CLK_UP = '1') then
            if (PACK_LAST = '1') then
                if (PACK_KEEP(3) = '1') then
                    dina(34 downto 27) <= PACK_DATA(31 downto 24);
                else
                    dina(34 downto 27) <= (others => '0');
                end if;
                if (PACK_KEEP(3) = '1') then
                    dina(25 downto 18) <= PACK_DATA(23 downto 16);
                else
                    dina(25 downto 18) <= (others => '0');
                end if;
                if (PACK_KEEP(3) = '1') then
                    dina(16 downto 9)  <= PACK_DATA(15 downto 8);
                else
                    dina(16 downto 9)  <= (others => '0');
                end if;
                if (PACK_KEEP(3) = '1') then
                    dina(7 downto 0)   <= PACK_DATA(7 downto 0);
                else
                    dina(7 downto 0)   <= (others => '0');
                end if;
            else
                if (length_insert(0) = '1') then
                    dina(34 downto 27) <= PACK_LENGTH(15 downto 8);
                    dina(25 downto 18) <= PACK_LENGTH(7 downto 0);
                    dina(16 downto 9)  <= PACK_DATA(15 downto 8);
                    dina(7 downto 0)   <= PACK_DATA(7 downto 0);
                else
                    dina(34 downto 27) <= PACK_DATA(31 downto 24);
                    dina(25 downto 18) <= PACK_DATA(23 downto 16);
                    dina(16 downto 9)  <= PACK_DATA(15 downto 8);
                    dina(7 downto 0)   <= PACK_DATA(7 downto 0);
                end if;
            end if;
        end if;
    end process;

    process (CLK_UP)
    begin
        if (CLK_UP'event and CLK_UP = '1') then
            dina_ext <= "000000" & PACK_PORT_ID;
        end if;
    end process;

--------------------------------------------------------------------------------
-- MTU Buffer
--------------------------------------------------------------------------------

    process (RST_UP, CLK_UP)
    begin
        if (RST_UP = '1') then
            addr <= (others => '0');
        elsif (CLK_UP'event and CLK_UP = '1') then
            if    (PACK_VALID = '1') then
                if (PACK_LAST = '1') then
                    if (addr = 2560-1) or (addr = 2560-2) then
                        addr <= (others => '0');
                    else
                        if (addr(0) = '0') then
                            addr <= addr + 2;
                        else
                            addr <= addr + 1;
                        end if;
                    end if;
                else
                    if (PACK_KEEP(0) = '1') then
                        if (addr = 2560-1) then
                            addr <= (others => '0');
                        else
                            addr <= addr + 1;
                        end if;
                    else
                        addr <= addr;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (RST_UP, CLK_UP)
    begin
        if (RST_UP = '1') then
            addra <= (others => '0');
        elsif (CLK_UP'event and CLK_UP = '1') then
            if (length_insert(0) = '1') then
                addra <= length_addr;
            else
                addra <= addr;
            end if;
        end if;
    end process;

    process (RST_UP, CLK_UP)
    begin
        if (RST_UP = '1') then
            addra_done <= (others => '0');
        elsif (CLK_UP'event and CLK_UP = '1') then
            if (length_insert(0) = '1') then
                addra_done <= addra(11 downto 1);
            end if;
        end if;
    end process;

    u_BUFFER : MTU_BUFFER
    port map(
        CLKA                        => CLK_UP                                  ,--: in  std_logic;
        ENA                         => ena                                     ,--: in  std_logic;
        WEA                         => wea                                     ,--: in  std_logic_vector(3 downto 0);
        ADDRA                       => addra                                   ,--: in  std_logic_vector(11 downto 0);
        DINA                        => dina                                    ,--: in  std_logic_vector(35 downto 0);
        CLKB                        => CLK                                     ,--: in  std_logic;
        ENB                         => enb(LATENCY_BRAM-1)                     ,--: in  std_logic;
        ADDRB                       => addrb                                   ,--: in  std_logic_vector(10 downto 0);
        DOUTB                       => doutb                                    --: out std_logic_vector(71 downto 0)
    );

    u_BUFFER_EXT : MTU_BUFFER_EXT
    port map(
        CLKA                        => CLK_UP                                  ,--: in  std_logic;
        ENA                         => ena                                     ,--: in  std_logic;
        WEA                         => wea(0)                                  ,--: in  std_logic;
        ADDRA                       => addra                                   ,--: in  std_logic_vector(11 downto 0);
        DINA                        => dina_ext                                ,--: in  std_logic_vector(8 downto 0);
        CLKB                        => CLK                                     ,--: in  std_logic;
        ENB                         => enb(LATENCY_BRAM-1)                     ,--: in  std_logic;
        ADDRB                       => addrb                                   ,--: in  std_logic_vector(10 downto 0);
        DOUTB                       => doutb_ext                                --: out std_logic_vector(17 downto 0)
    );

    process (RST, CLK)
    begin
        if (RST = '1') then
            addr_end <= conv_std_logic_vector(1280-1, 11);
        elsif (CLK'event and CLK = '1') then
            if (addr_update(2 downto 1) ="01") then
                addr_end <= addra_done;
            end if;
        end if;
    end process;

    process (RST, CLK)
    begin
        if (RST = '1') then
            addrb <= conv_std_logic_vector(1280-1, 11);
        elsif (CLK'event and CLK = '1') then
            if (addrb = addr_end) then
                addrb <= addrb;
            else
                if (addrb = 1280-1) then
                    addrb <= (others => '0');
                else
                    addrb <= addrb + 1;
                end if;
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Read side
--------------------------------------------------------------------------------

    process (RST, CLK)
    begin
        if (RST = '1') then
            fsm_tx <= IDLE;
        elsif (CLK'event and CLK = '1') then
            case fsm_tx is
            when IDLE        =>
                if (addrb = addr_end) then
                    fsm_tx <= IDLE;
                else
                    fsm_tx <= TRANSACTION;
                end if;
            when TRANSACTION =>
                if (addrb = addr_end) then
                    fsm_tx <= POSTLOAD;
                else
                    fsm_tx <= TRANSACTION;
                end if;
            when POSTLOAD    =>
                if (cnt_tx_state = LATENCY_BRAM-1) then
                    fsm_tx <= IDLE;
                else
                    fsm_tx <= POSTLOAD;
                end if;
            when others      =>
                fsm_tx <= IDLE;
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_tx is
            when POSTLOAD    =>
                if (cnt_tx_state = LATENCY_BRAM-1) then
                    cnt_tx_state <= (others => '0');
                else
                    cnt_tx_state <= cnt_tx_state + 1;
                end if;
            when others      =>
                cnt_tx_state <= (others => '0');
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            addr_update <= addr_update(1 downto 0) & length_insert(3);
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (addrb = addr_end) then
                enb <= enb(LATENCY_BRAM-2 downto 0) & '0';
            else
                enb <= (others => '1');
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (addrb = addr_end) then
                rd_valid <= rd_valid(LATENCY_BRAM-1 downto 0) & '0';
            else
                rd_valid <= rd_valid(LATENCY_BRAM-1 downto 0) & '1';
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            TX_VALID <= rd_valid(LATENCY_BRAM);
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            TX_START <= doutb(35);                                              -- doutb(71) is useless because the only even operation can contain start signal
            TX_LAST  <= doutb(26) or doutb(62);                                 -- both doutb(26) and dboutb(62) can contain last signal
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            TX_DEST <= doutb_ext(2 downto 0);
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if    (doutb(62) = '1') then
                if    (doutb(53) = '1') and (doutb(44) = '1') then
                    TX_KEEP  <= x"7F";
                elsif (doutb(53) = '1') and (doutb(44) = '0') then
                    TX_KEEP  <= x"3F";
                elsif (doutb(53) = '0') and (doutb(44) = '1') then
                    TX_KEEP  <= x"1F";
                else
                    TX_KEEP  <= x"FF";
                end if;
            elsif (doutb(26) = '1') then
                if    (doutb(17) = '1') and (doutb(8) = '1') then
                    TX_KEEP  <= x"07";
                elsif (doutb(17) = '1') and (doutb(8) = '0') then
                    TX_KEEP  <= x"03";
                elsif (doutb(17) = '0') and (doutb(8) = '1') then
                    TX_KEEP  <= x"01";
                else
                    TX_KEEP  <= x"0F";
                end if;
            else
                TX_KEEP  <= x"FF"; 
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            TX_DATA <= doutb(43 downto 36) & doutb(52 downto 45) & doutb(61 downto 54) & doutb(70 downto 63) & doutb(7 downto 0) & doutb(16 downto 9) & doutb(25 downto 18) & doutb(34 downto 27);
        end if;
    end process;

end BEHAVE;