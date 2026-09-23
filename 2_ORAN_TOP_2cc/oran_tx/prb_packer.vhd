--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : PRB packer (xRAN component)                                   --
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

use WORK.ARRAY_TYPE.ALL;
use WORK.PKG_ORAN.ALL;
use WORK.PKG_ORAN_ARRAY.ALL;

entity PRB_PACKER is
    port (
--------------------------------------------------------------------------------
-- Clock & Reset
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;
        RST                         : in  std_logic;

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------

        PARAM_RU_MAC                : in  std_logic_array48(7 downto 0);
        PARAM_PORT_INDEX            : in  std_logic_array3(7 downto 0);
        PARAM_DU_MAC                : in  std_logic_array48(7 downto 0);
        PARAM_VLAN0_EN              : in  std_logic_vector(7 downto 0);
        PARAM_VLAN0_VID             : in  std_logic_array12(7 downto 0);
        PARAM_VLAN1_EN              : in  std_logic_vector(7 downto 0);
        PARAM_VLAN1_VID             : in  std_logic_array12(7 downto 0);

--------------------------------------------------------------------------------
-- RB header
--------------------------------------------------------------------------------

        RB_PE_INDEX                 : in  std_logic_vector(2 downto 0);
        RB_eAxC_ID                  : in  std_logic_vector(15 downto 0);
        RB_SEQUENCE_ID              : in  std_logic_vector(15 downto 0);
        RB_HEADER_APP               : in  std_logic_vector(31 downto 0);
        RB_HEADER_APP_ACK           : out std_logic;
        RB_HEADER_SEC               : in  std_logic_vector(31 downto 0);
        RB_HEADER_SEC_ACK           : out std_logic;

        PE_TRANSMITTED              : out std_logic_vector(MAX_RU_ELEMENT-1 downto 0);

--------------------------------------------------------------------------------
-- Compression block
--------------------------------------------------------------------------------

        COMP_HDR                    : in  std_logic_vector(8 downto 0);
        COMP_PARAM                  : in  std_logic_vector(7 downto 0);

        COMP_VALID                  : in  std_logic;
        COMP_TICK                   : in  std_logic;
        COMP_DATA_I                 : in  std_logic_vector(15 downto 0);
        COMP_DATA_Q                 : in  std_logic_vector(15 downto 0);
        COMP_USER                   : in  std_logic_vector(15 downto 0);

--------------------------------------------------------------------------------
-- Packet generator
--------------------------------------------------------------------------------

        PACK_PORT_ID                : out std_logic_vector(2 downto 0);
        PACK_VLAN_MODE              : out std_logic_vector(1 downto 0);
        PACK_LENGTH                 : out std_logic_vector(15 downto 0);

        PACK_VALID                  : out std_logic;
        PACK_START                  : out std_logic;
        PACK_LAST                   : out std_logic;
        PACK_KEEP                   : out std_logic_vector(3 downto 0);
        PACK_DATA                   : out std_logic_vector(31 downto 0)
    );
end PRB_PACKER;

architecture BEHAVE of PRB_PACKER is

    component PRB_N_TO_32 is
    generic (
        UNCOMP_1B                   : boolean := true;
        UNCOMP_2B                   : boolean := true;
        UNCOMP_3B                   : boolean := true;
        UNCOMP_4B                   : boolean := true;
        UNCOMP_5B                   : boolean := true;
        UNCOMP_6B                   : boolean := true;
        UNCOMP_7B                   : boolean := true;
        UNCOMP_8B                   : boolean := true;
        UNCOMP_9B                   : boolean := true;
        UNCOMP_10B                  : boolean := true;
        UNCOMP_11B                  : boolean := true;
        UNCOMP_12B                  : boolean := true;
        UNCOMP_13B                  : boolean := true;
        UNCOMP_14B                  : boolean := true;
        UNCOMP_15B                  : boolean := true;
        UNCOMP_16B                  : boolean := true;
        COMP_1B                     : boolean := true;
        COMP_2B                     : boolean := true;
        COMP_3B                     : boolean := true;
        COMP_4B                     : boolean := true;
        COMP_5B                     : boolean := true;
        COMP_6B                     : boolean := true;
        COMP_7B                     : boolean := true;
        COMP_8B                     : boolean := true;
        COMP_9B                     : boolean := true;
        COMP_10B                    : boolean := true;
        COMP_11B                    : boolean := true;
        COMP_12B                    : boolean := true;
        COMP_13B                    : boolean := true;
        COMP_14B                    : boolean := true;
        COMP_15B                    : boolean := true;
        COMP_16B                    : boolean := true
    );
    port (
        CLK                         : in  std_logic;
        RST                         : in  std_logic;

        COMP_HDR                    : in  std_logic_vector(8 downto 0);
        COMP_PARAM                  : in  std_logic_vector(7 downto 0);

        COMP_VALID                  : in  std_logic;
        COMP_TICK                   : in  std_logic;
        COMP_DATA_I                 : in  std_logic_vector(15 downto 0);
        COMP_DATA_Q                 : in  std_logic_vector(15 downto 0);
        COMP_USER                   : in  std_logic_vector(15 downto 0);

        PRB_COMP_HDR                : out std_logic_vector(8 downto 0);

        PRB_VALID                   : out std_logic;
        PRB_TICK                    : out std_logic;
        PRB_KEEP                    : out std_logic_vector(3 downto 0);
        PRB_DATA                    : out std_logic_vector(31 downto 0);
        PRB_USER                    : out std_logic_vector(15 downto 0)
    );
    end component;

    signal conv_comp_hdr            : std_logic_vector(8 downto 0);
    signal conv_valid               : std_logic;
    signal conv_tick                : std_logic;
    signal conv_keep                : std_logic_vector(3 downto 0);
    signal conv_data                : std_logic_vector(31 downto 0);
    signal conv_user                : std_logic_vector(15 downto 0);

    type fsm                        is (IDLE, HDR_APP, HDR_SEC, HDR_COMP, PRB, EXT);
    signal fsm_tx                   : fsm;
    signal cnt_tx_state             : std_logic_vector(3 downto 0);

    signal buf_valid                : std_logic;
    signal buf_tick                 : std_logic;
    signal buf_last                 : std_logic;
    signal buf_end                  : std_logic;
    signal buf_keep                 : std_logic_vector(3 downto 0);
    signal buf_data                 : std_logic_vector(31 downto 0);

    signal prb_valid                : std_logic;
    signal prb_tick                 : std_logic;
    signal prb_last                 : std_logic;
    signal prb_end                  : std_logic;
    signal prb_keep                 : std_logic_vector(3 downto 0);
    signal prb_data                 : std_logic_vector(31 downto 0);

    signal not_aligned_valid        : std_logic;
    signal not_aligned_tick         : std_logic;
    signal not_aligned_last         : std_logic;
    signal not_aligned_end          : std_logic;
    signal not_aligned_keep         : std_logic_vector(3 downto 0);
    signal not_aligned_data         : std_logic_vector(31 downto 0);

    signal tx_port_id               : std_logic_vector(2 downto 0) := (others => '0');
    signal dst_mac                  : std_logic_vector(47 downto 0) := (others => '0');
    signal src_mac                  : std_logic_vector(47 downto 0) := (others => '0');
    signal vlan0_mode               : std_logic := '0';
    signal vlan0_tci                : std_logic_vector(11 downto 0) := (others => '0');
    signal vlan1_mode               : std_logic := '0';
    signal vlan1_tci                : std_logic_vector(11 downto 0) := (others => '0');

    signal align_position           : std_logic_vector(1 downto 0) := (others => '0');
    signal merged_tick              : std_logic := '0';
    signal merged_valid             : std_logic := '0';
    signal merged_start             : std_logic := '0';
    signal merged_end               : std_logic := '0';
    signal merged_keep              : std_logic_vector(3 downto 0) := (others => '0');
    signal merged_data              : std_logic_vector(31 downto 0) := (others => '0');
    signal merged_done              : std_logic := '0';

    signal merged_init              : std_logic := '0';
    signal merged_bytes             : std_logic_vector(15 downto 0) := (others => '0');
    signal merged_extension         : std_logic := '0';
    signal cnt_extension            : std_logic_vector(15 downto 0) := (others => '0');

    component BYTE_ALIGN_32 is
    port (
        CLK                         : in  std_logic;

        ALIGN_START                 : in  std_logic;
        ALIGN_POSITION              : in  std_logic_vector(1 downto 0);

        VALID_IN                    : in  std_logic;
        LAST_IN                     : in  std_logic;
        KEEP_IN                     : in  std_logic_vector(3 downto 0);
        DATA_IN                     : in  std_logic_vector(31 downto 0);

        VALID_OUT                   : out std_logic;
        LAST_OUT                    : out std_logic;
        KEEP_OUT                    : out std_logic_vector(3 downto 0);
        DATA_OUT                    : out std_logic_vector(31 downto 0)
    );
    end component;

    signal aligned_prb_valid        : std_logic;
    signal aligned_prb_start        : std_logic_vector(2 downto 0) := (others => '0');
    signal aligned_prb_end          : std_logic;
    signal aligned_prb_keep         : std_logic_vector(3 downto 0);
    signal aligned_prb_data         : std_logic_vector(31 downto 0);

begin

--------------------------------------------------------------------------------
-- Conversion
--------------------------------------------------------------------------------

    u_N_to_32 : PRB_N_TO_32
    generic map(
        UNCOMP_1B                   => RX_UNCOMP_1B                            ,--: boolean := true;
        UNCOMP_2B                   => RX_UNCOMP_2B                            ,--: boolean := true;
        UNCOMP_3B                   => RX_UNCOMP_3B                            ,--: boolean := true;
        UNCOMP_4B                   => RX_UNCOMP_4B                            ,--: boolean := true;
        UNCOMP_5B                   => RX_UNCOMP_5B                            ,--: boolean := true;
        UNCOMP_6B                   => RX_UNCOMP_6B                            ,--: boolean := true;
        UNCOMP_7B                   => RX_UNCOMP_7B                            ,--: boolean := true;
        UNCOMP_8B                   => RX_UNCOMP_8B                            ,--: boolean := true;
        UNCOMP_9B                   => RX_UNCOMP_9B                            ,--: boolean := true;
        UNCOMP_10B                  => RX_UNCOMP_10B                           ,--: boolean := true;
        UNCOMP_11B                  => RX_UNCOMP_11B                           ,--: boolean := true;
        UNCOMP_12B                  => RX_UNCOMP_12B                           ,--: boolean := true;
        UNCOMP_13B                  => RX_UNCOMP_13B                           ,--: boolean := true;
        UNCOMP_14B                  => RX_UNCOMP_14B                           ,--: boolean := true;
        UNCOMP_15B                  => RX_UNCOMP_15B                           ,--: boolean := true;
        UNCOMP_16B                  => RX_UNCOMP_16B                           ,--: boolean := true;
        COMP_1B                     => RX_COMP_1B                              ,--: boolean := true;
        COMP_2B                     => RX_COMP_2B                              ,--: boolean := true;
        COMP_3B                     => RX_COMP_3B                              ,--: boolean := true;
        COMP_4B                     => RX_COMP_4B                              ,--: boolean := true;
        COMP_5B                     => RX_COMP_5B                              ,--: boolean := true;
        COMP_6B                     => RX_COMP_6B                              ,--: boolean := true;
        COMP_7B                     => RX_COMP_7B                              ,--: boolean := true;
        COMP_8B                     => RX_COMP_8B                              ,--: boolean := true;
        COMP_9B                     => RX_COMP_9B                              ,--: boolean := true;
        COMP_10B                    => RX_COMP_10B                             ,--: boolean := true;
        COMP_11B                    => RX_COMP_11B                             ,--: boolean := true;
        COMP_12B                    => RX_COMP_12B                             ,--: boolean := true;
        COMP_13B                    => RX_COMP_13B                             ,--: boolean := true;
        COMP_14B                    => RX_COMP_14B                             ,--: boolean := true;
        COMP_15B                    => RX_COMP_15B                             ,--: boolean := true;
        COMP_16B                    => RX_COMP_16B                              --: boolean := true
    )
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;
        RST                         => RST                                     ,--: in  std_logic;

        COMP_HDR                    => COMP_HDR                                ,--: in  std_logic_vector(8 downto 0);
        COMP_PARAM                  => COMP_PARAM                              ,--: in  std_logic_vector(7 downto 0);

        COMP_VALID                  => COMP_VALID                              ,--: in  std_logic;
        COMP_TICK                   => COMP_TICK                               ,--: in  std_logic;
        COMP_DATA_I                 => COMP_DATA_I                             ,--: in  std_logic_vector(15 downto 0);
        COMP_DATA_Q                 => COMP_DATA_Q                             ,--: in  std_logic_vector(15 downto 0);
        COMP_USER                   => COMP_USER                               ,--: in  std_logic_vector(15 downto 0);

        PRB_COMP_HDR                => conv_comp_hdr                           ,--: out std_logic_vector(8 downto 0);

        PRB_VALID                   => conv_valid                              ,--: out std_logic;
        PRB_TICK                    => conv_tick                               ,--: out std_logic;
        PRB_KEEP                    => conv_keep                               ,--: out std_logic_vector(3 downto 0);
        PRB_DATA                    => conv_data                               ,--: out std_logic_vector(31 downto 0);
        PRB_USER                    => conv_user                                --: out std_logic_vector(15 downto 0)
    );

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            buf_valid <= conv_valid;
            buf_tick  <= conv_tick;
            buf_last  <= conv_user(1);
            buf_end   <= conv_user(2);
            buf_keep  <= conv_keep;
            buf_data  <= conv_data;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            prb_valid <= buf_valid;
            prb_tick  <= buf_tick;
            if (conv_valid = '0') and (buf_valid = '1') then
                prb_last  <= buf_last;
                prb_end   <= buf_end;
            else
                prb_last  <= '0';
                prb_end   <= '0';
            end if;
            prb_keep  <= buf_keep;
            prb_data  <= buf_data;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            not_aligned_valid <= prb_valid;
            not_aligned_tick  <= prb_tick;
            not_aligned_last  <= prb_last;
            not_aligned_end   <= prb_end;
            not_aligned_keep  <= prb_keep;
            not_aligned_data  <= prb_data;
        end if;
    end process;

--------------------------------------------------------------------------------
-- TX
--------------------------------------------------------------------------------

    process (RST, CLK)
    begin
        if (RST = '1') then
            fsm_tx <= IDLE;
        elsif (CLK'event and CLK = '1') then
            case fsm_tx is
            when IDLE     =>
                if (COMP_TICK = '1') then
                    fsm_tx <= HDR_APP;
                else
                    fsm_tx <= IDLE;
                end if;
            when HDR_APP  =>
                if (cnt_tx_state = 8) then
                    fsm_tx <= HDR_SEC;
                else
                    fsm_tx <= HDR_APP;
                end if;
            when HDR_SEC  =>
                if (conv_tick = '1') then
                    if (conv_comp_hdr(8) = '0') then
                        fsm_tx <= PRB;
                    else
                        fsm_tx <= HDR_COMP;
                    end if;
                else
                    fsm_tx <= HDR_SEC;
                end if;
            when HDR_COMP =>
                fsm_tx <= PRB;
            when PRB      =>
                if (not_aligned_last = '1') then
                    if (not_aligned_end = '1') then
                        if (merged_extension = '1') then
                            fsm_tx <= EXT;
                        else
                            fsm_tx <= IDLE;
                        end if;
                    else
                        fsm_tx <= HDR_SEC;
                    end if;
                else
                    fsm_tx <= PRB;
                end if;
            when EXT      =>
                if (cnt_tx_state = cnt_extension(5 downto 2)) then
                    fsm_tx <= IDLE;
                else
                    fsm_tx <= EXT;
                end if;
            when others   =>
                fsm_tx <= IDLE;
            end case;
        end if;
    end process;

    process (RST, CLK)
    begin
        if (RST = '1') then
            cnt_tx_state <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            case fsm_tx is
            when HDR_APP  =>
                cnt_tx_state <= cnt_tx_state + 1;
            when EXT      =>
                cnt_tx_state <= cnt_tx_state + 1;
            when others   =>
                cnt_tx_state <= (others => '0');
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_tx is
            when HDR_APP  =>
                if (cnt_tx_state = 8) then
                    RB_HEADER_APP_ACK <= '1';
                    RB_HEADER_SEC_ACK <= '0';
                else
                    RB_HEADER_APP_ACK <= '0';
                    RB_HEADER_SEC_ACK <= '0';
                end if;
            when HDR_SEC  =>
                RB_HEADER_APP_ACK <= '0';
                RB_HEADER_SEC_ACK <= conv_tick;
            when others   =>
                RB_HEADER_APP_ACK <= '0';
                RB_HEADER_SEC_ACK <= '0';
            end case;
        end if;
    end process;

    u_PE_TRANSMIT : for i in MAX_RU_ELEMENT-1 downto 0 generate
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_tx is
            when HDR_APP  =>
                if (cnt_tx_state = 8) then
                    if (RB_PE_INDEX = i) then
                        PE_TRANSMITTED(i) <= '1';
                    else
                        PE_TRANSMITTED(i) <= '0';
                    end if;
                else
                    PE_TRANSMITTED(i) <= '0';
                end if;
            when others   =>
                PE_TRANSMITTED(i) <= '0';
            end case;
        end if;
    end process;
    end generate;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_tx is
            when IDLE     =>
                if    (RB_PE_INDEX = 1) then
                    tx_port_id <= PARAM_PORT_INDEX(1);
                    dst_mac    <= PARAM_DU_MAC(1);
                    src_mac    <= PARAM_RU_MAC(1);
                    vlan0_mode <= PARAM_VLAN0_EN(1);
                    vlan0_tci  <= PARAM_VLAN0_VID(1);
                    vlan1_mode <= PARAM_VLAN1_EN(1);
                    vlan1_tci  <= PARAM_VLAN1_VID(1);
                elsif (RB_PE_INDEX = 2) then
                    tx_port_id <= PARAM_PORT_INDEX(2);
                    dst_mac    <= PARAM_DU_MAC(2);
                    src_mac    <= PARAM_RU_MAC(2);
                    vlan0_mode <= PARAM_VLAN0_EN(2);
                    vlan0_tci  <= PARAM_VLAN0_VID(2);
                    vlan1_mode <= PARAM_VLAN1_EN(2);
                    vlan1_tci  <= PARAM_VLAN1_VID(2);
                elsif (RB_PE_INDEX = 3) then
                    tx_port_id <= PARAM_PORT_INDEX(3);
                    dst_mac    <= PARAM_DU_MAC(3);
                    src_mac    <= PARAM_RU_MAC(3);
                    vlan0_mode <= PARAM_VLAN0_EN(3);
                    vlan0_tci  <= PARAM_VLAN0_VID(3);
                    vlan1_mode <= PARAM_VLAN1_EN(3);
                    vlan1_tci  <= PARAM_VLAN1_VID(3);
                elsif (RB_PE_INDEX = 4) then
                    tx_port_id <= PARAM_PORT_INDEX(4);
                    dst_mac    <= PARAM_DU_MAC(4);
                    src_mac    <= PARAM_RU_MAC(4);
                    vlan0_mode <= PARAM_VLAN0_EN(4);
                    vlan0_tci  <= PARAM_VLAN0_VID(4);
                    vlan1_mode <= PARAM_VLAN1_EN(4);
                    vlan1_tci  <= PARAM_VLAN1_VID(4);
                elsif (RB_PE_INDEX = 5) then
                    tx_port_id <= PARAM_PORT_INDEX(5);
                    dst_mac    <= PARAM_DU_MAC(5);
                    src_mac    <= PARAM_RU_MAC(5);
                    vlan0_mode <= PARAM_VLAN0_EN(5);
                    vlan0_tci  <= PARAM_VLAN0_VID(5);
                    vlan1_mode <= PARAM_VLAN1_EN(5);
                    vlan1_tci  <= PARAM_VLAN1_VID(5);
                elsif (RB_PE_INDEX = 6) then
                    tx_port_id <= PARAM_PORT_INDEX(6);
                    dst_mac    <= PARAM_DU_MAC(6);
                    src_mac    <= PARAM_RU_MAC(6);
                    vlan0_mode <= PARAM_VLAN0_EN(6);
                    vlan0_tci  <= PARAM_VLAN0_VID(6);
                    vlan1_mode <= PARAM_VLAN1_EN(6);
                    vlan1_tci  <= PARAM_VLAN1_VID(6);
                elsif (RB_PE_INDEX = 7) then
                    tx_port_id <= PARAM_PORT_INDEX(7);
                    dst_mac    <= PARAM_DU_MAC(7);
                    src_mac    <= PARAM_RU_MAC(7);
                    vlan0_mode <= PARAM_VLAN0_EN(7);
                    vlan0_tci  <= PARAM_VLAN0_VID(7);
                    vlan1_mode <= PARAM_VLAN1_EN(7);
                    vlan1_tci  <= PARAM_VLAN1_VID(7);
                else
                    tx_port_id <= PARAM_PORT_INDEX(0);
                    dst_mac    <= PARAM_DU_MAC(0);
                    src_mac    <= PARAM_RU_MAC(0);
                    vlan0_mode <= PARAM_VLAN0_EN(0);
                    vlan0_tci  <= PARAM_VLAN0_VID(0);
                    vlan1_mode <= PARAM_VLAN1_EN(0);
                    vlan1_tci  <= PARAM_VLAN1_VID(0);
                end if;
            when others   =>
                NULL;
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_tx is
            when HDR_APP  =>
                if    (vlan0_mode = '1') and (vlan1_mode = '0') then
                    if    (cnt_tx_state = 0) then
                        merged_tick  <= '1';
                        merged_valid <= '1';
                        merged_start <= '1';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= dst_mac(47 downto 16);
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 1) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= dst_mac(15 downto 0) & src_mac(47 downto 32);
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 2) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= src_mac(31 downto 0);
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 3) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= x"8100" & x"E"& vlan0_tci;
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 4) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= x"AEFE1000";
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 5) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= x"0000" & RB_eAxC_ID;
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 6) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= RB_SEQUENCE_ID & RB_HEADER_APP(31 downto 16);
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 7) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1100";
                        merged_data  <= RB_HEADER_APP(15 downto 0) & x"0000";
                        merged_done  <= '0';
                    else
                        merged_tick  <= '0';
                        merged_valid <= '0';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= (others => '0');
                        merged_data  <= (others => '0');
                        merged_done  <= '0';
                    end if;
                elsif (vlan0_mode = '1') and (vlan1_mode = '1') then
                    if    (cnt_tx_state = 0) then
                        merged_tick  <= '1';
                        merged_valid <= '1';
                        merged_start <= '1';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= dst_mac(47 downto 16);
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 1) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= dst_mac(15 downto 0) & src_mac(47 downto 32);
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 2) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= src_mac(31 downto 0);
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 3) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= x"8100" & x"E"& vlan0_tci;
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 4) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= x"8100" & x"E"& vlan1_tci;
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 5) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= x"AEFE1000";
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 6) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= x"0000" & RB_eAxC_ID;
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 7) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= RB_SEQUENCE_ID & RB_HEADER_APP(31 downto 16);
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 8) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1100";
                        merged_data  <= RB_HEADER_APP(15 downto 0) & x"0000";
                        merged_done  <= '0';
                    else
                        merged_tick  <= '0';
                        merged_valid <= '0';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= (others => '0');
                        merged_data  <= (others => '0');
                        merged_done  <= '0';
                    end if;
                else
                    if    (cnt_tx_state = 0) then
                        merged_tick  <= '1';
                        merged_valid <= '1';
                        merged_start <= '1';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= dst_mac(47 downto 16);
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 1) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= dst_mac(15 downto 0) & src_mac(47 downto 32);
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 2) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= src_mac(31 downto 0);
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 3) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= x"AEFE1000";
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 4) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= x"0000" & RB_eAxC_ID;
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 5) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1111";
                        merged_data  <= RB_SEQUENCE_ID & RB_HEADER_APP(31 downto 16);
                        merged_done  <= '0';
                    elsif (cnt_tx_state = 6) then
                        merged_tick  <= '0';
                        merged_valid <= '1';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= "1100";
                        merged_data  <= RB_HEADER_APP(15 downto 0) & x"0000";
                        merged_done  <= '0';
                    else
                        merged_tick  <= '0';
                        merged_valid <= '0';
                        merged_start <= '0';
                        merged_end   <= '0';
                        merged_keep  <= (others => '0');
                        merged_data  <= (others => '0');
                        merged_done  <= '0';
                    end if;
                end if;
            when HDR_SEC  =>
                if (conv_tick = '1') then
                    merged_tick  <= '1';
                    merged_valid <= '1';
                    merged_start <= '0';
                    merged_end   <= '0';
                    merged_keep  <= "1111";
                    merged_data  <= RB_HEADER_SEC;
                    merged_done  <= '0';
                else
                    merged_tick  <= '0';
                    merged_valid <= '0';
                    merged_start <= '0';
                    merged_end   <= '0';
                    merged_keep  <= (others => '0');
                    merged_data  <= (others => '0');
                    merged_done  <= '0';
                end if;
            when HDR_COMP =>
                merged_tick  <= '0';
                merged_valid <= '1';
                merged_start <= '0';
                merged_end   <= '0';
                merged_keep  <= "1100";
                merged_data  <= conv_comp_hdr(7 downto 0) & x"000000";
                merged_done  <= '0';
            when PRB      =>
                merged_tick  <= not_aligned_tick;
                merged_valid <= not_aligned_valid;
                merged_start <= '0';
                if (merged_extension = '1') then
                    merged_end   <= '0';
                else
                    merged_end   <= not_aligned_end;
                end if;
                merged_keep  <= not_aligned_keep;
                merged_data  <= not_aligned_data;
                merged_done  <= not_aligned_end;
            when EXT      =>
                if (cnt_tx_state = 0) then
                    merged_tick  <= '1';
                else
                    merged_tick  <= '0';
                end if;
                merged_valid <= '1';
                merged_start <= '0';
                if (cnt_tx_state = cnt_extension(5 downto 2)) then
                    merged_end   <= '1';
                else
                    merged_end   <= '0';
                end if;
                if (cnt_tx_state = cnt_extension(5 downto 2)) then
                    if    (cnt_extension(1 downto 0) = 1) then
                        merged_keep  <= "1000";
                    elsif (cnt_extension(1 downto 0) = 2) then
                        merged_keep  <= "1100";
                    elsif (cnt_extension(1 downto 0) = 3) then
                        merged_keep  <= "1110";
                    else
                        merged_keep  <= "1111";
                    end if;
                else
                    merged_keep  <= "1111";
                end if;
                merged_data  <= (others => '0');
                merged_done  <= '0';
            when others   =>
                merged_tick  <= '0';
                merged_valid <= '0';
                merged_start <= '0';
                merged_end   <= '0';
                merged_keep  <= (others => '0');
                merged_data  <= (others => '0');
                merged_done  <= '0';
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            case fsm_tx is
            when HDR_APP  =>
                merged_init <= '1';
            when others   =>
                merged_init <= '0';
            end case;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (merged_init = '1') then
                merged_bytes <= x"0008";
            else
                if    (merged_keep = x"F") then
                    merged_bytes <= merged_bytes + 4;
                elsif (merged_keep = x"E") or (merged_keep = x"7") then
                    merged_bytes <= merged_bytes + 3;
                elsif (merged_keep = x"C") or (merged_keep = x"3") then
                    merged_bytes <= merged_bytes + 2;
                elsif (merged_keep = x"8") or (merged_keep = x"1") then
                    merged_bytes <= merged_bytes + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (merged_done = '1') then
                if    (merged_keep = x"F") then
                    PACK_LENGTH <= merged_bytes + 4;
                elsif (merged_keep = x"E") or (merged_keep = x"7") then
                    PACK_LENGTH <= merged_bytes + 3;
                elsif (merged_keep = x"C") or (merged_keep = x"3") then
                    PACK_LENGTH <= merged_bytes + 2;
                elsif (merged_keep = x"8") or (merged_keep = x"1") then
                    PACK_LENGTH <= merged_bytes + 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (merged_init = '1') then
                merged_extension <= '1';
            else
                if (merged_bytes = 32) then
                    if (prb_end = '1') then
                        if (prb_keep = x"8") then
                            merged_extension <= '1';
                        else
                            merged_extension <= '0';
                        end if; 
                    else
                        merged_extension <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (merged_init = '1') then
                cnt_extension <= conv_std_logic_vector(38, 16);
            else
                if (prb_end = '1') then
                    if    (prb_keep = x"F") then
                        cnt_extension <= cnt_extension - merged_bytes - 8;
                    elsif (prb_keep = x"E") then
                        cnt_extension <= cnt_extension - merged_bytes - 7;
                    elsif (prb_keep = x"C") then
                        cnt_extension <= cnt_extension - merged_bytes - 6;
                    elsif (prb_keep = x"8") then
                        cnt_extension <= cnt_extension - merged_bytes - 5;
                    end if; 
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (merged_end = '1') then
                align_position <= "00";
            else
                if    (merged_keep = x"E") then
                    align_position <= align_position + 3;
                elsif (merged_keep = x"C") then
                    align_position <= align_position + 2;
                elsif (merged_keep = x"8") then
                    align_position <= align_position + 1;
                end if;
            end if;
        end if;
    end process;

    u_ALIGN : BYTE_ALIGN_32
    port map(
        CLK                         => CLK                                     ,--: in  std_logic;

        ALIGN_START                 => merged_tick                             ,--: in  std_logic;
        ALIGN_POSITION              => align_position                          ,--: in  std_logic_vector(1 downto 0);

        VALID_IN                    => merged_valid                            ,--: in  std_logic;
        LAST_IN                     => merged_end                              ,--: in  std_logic;
        KEEP_IN                     => merged_keep                             ,--: in  std_logic_vector(3 downto 0);
        DATA_IN                     => merged_data                             ,--: in  std_logic_vector(31 downto 0);

        VALID_OUT                   => aligned_prb_valid                       ,--: out std_logic;
        LAST_OUT                    => aligned_prb_end                         ,--: out std_logic;
        KEEP_OUT                    => aligned_prb_keep                        ,--: out std_logic_vector(3 downto 0);
        DATA_OUT                    => aligned_prb_data                         --: out std_logic_vector(31 downto 0)
    );

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            aligned_prb_start <= aligned_prb_start(1 downto 0) & merged_start;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (aligned_prb_start(2) = '1') then
                PACK_PORT_ID   <= tx_port_id;
                PACK_VLAN_MODE <= vlan1_mode & vlan0_mode;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            PACK_VALID <= aligned_prb_valid;
            PACK_START <= aligned_prb_start(2);
            PACK_LAST  <= aligned_prb_end;
            PACK_KEEP  <= aligned_prb_keep;
            PACK_DATA  <= aligned_prb_data;
        end if;
    end process;

end BEHAVE;