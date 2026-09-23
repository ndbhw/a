--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : IQ compressor (O-RAN component)                               --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.15                                                    --
--                                                                            --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use WORK.ARRAY_TYPE.ALL;

entity PRB_COMP is
    port (
--------------------------------------------------------------------------------
-- Clock
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;
        RST                         : in  std_logic;

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------

        COMP_EXP_OFFSET             : in  std_logic_array5(7 downto 0);
        COMP_GAIN_OFFSET            : in  std_logic_array11(7 downto 0);
        COMP_SCALE_GAIN_OFFSET      : in  std_logic_array4(7 downto 0);

--------------------------------------------------------------------------------
-- RB header
--------------------------------------------------------------------------------

        RB_PATH                     : in  std_logic_vector(2 downto 0);

--------------------------------------------------------------------------------
-- Uncompressed data
--------------------------------------------------------------------------------

        IQ_COMP_HDR                 : in  std_logic_vector(8 downto 0);

        IQ_VALID                    : in  std_logic;
        IQ_TICK                     : in  std_logic;
        IQ_DATA_I                   : in  std_logic_vector(15 downto 0);
        IQ_DATA_Q                   : in  std_logic_vector(15 downto 0);
        IQ_USER                     : in  std_logic_vector(15 downto 0);

--------------------------------------------------------------------------------
-- Compressed data
--------------------------------------------------------------------------------

        COMP_HDR                    : out std_logic_vector(8 downto 0);
        COMP_PARAM                  : out std_logic_vector(7 downto 0);

        COMP_VALID                  : out std_logic;
        COMP_TICK                   : out std_logic;
        COMP_DATA_I                 : out std_logic_vector(15 downto 0);
        COMP_DATA_Q                 : out std_logic_vector(15 downto 0);
        COMP_USER                   : out std_logic_vector(15 downto 0)
    );
end PRB_COMP;

architecture BEHAVE of PRB_COMP is

    constant MAX_BUFFER            : natural := 3;                              -- roundup(processing delay / 12, 0)

    signal comp_hdr_buf             : std_logic_array9(MAX_BUFFER-1 downto 0) := (others => (others => '0'));
    signal comp_user_buf            : std_logic_array16(MAX_BUFFER-1 downto 0) := (others => (others => '0'));
    signal index_wr                 : natural range 0 to MAX_BUFFER;
    signal index_rd                 : natural range 0 to MAX_BUFFER;

    component COMP is
    port (
        CLK_245                     : in  std_logic;
        RST                         : in  std_logic;
        I_COMP_MODE                 : in  std_logic_vector(1 downto 0);
        I_COMP_GAIN_OFFSET          : in  std_logic_vector(10 downto 0);
        I_COMP_SCALE_GAIN_OFFSET    : in  std_logic_vector(3 downto 0);
        I_COMP_EXP_OFFSET           : in  std_logic_vector(4 downto 0);
        I_COMP_ENABLE               : in  std_logic;
        I_COMP_DATA_I               : in  std_logic_vector(15 downto 0);
        I_COMP_DATA_Q               : in  std_logic_vector(15 downto 0);
        I_COMP_RB_START_TIC         : in  std_logic;
        I_COMP_UDIQWIDTH            : in  std_logic_vector(3 downto 0);
        I_COMP_FRAME_ID             : in  std_logic_vector(7 downto 0);
        I_COMP_SUBFRAME_ID          : in  std_logic_vector(3 downto 0);
        I_COMP_SLOT_ID              : in  std_logic_vector(5 downto 0);
        I_COMP_SYMBOL_ID            : in  std_logic_vector(3 downto 0);
        I_COMP_USER                 : in  std_logic_vector(15 downto 0);
        O_COMP_VALID                : out std_logic;
        O_COMP_DATA_I               : out std_logic_vector(15 downto 0);
        O_COMP_DATA_Q               : out std_logic_vector(15 downto 0);
        O_COMP_RB_START_TIC         : out std_logic;
        O_COMP_EXP                  : out std_logic_vector(3 downto 0);
        O_COMP_MODE                 : out std_logic_vector(1 downto 0);
        O_COMP_UDIQWIDTH            : out std_logic_vector(3 downto 0);
        O_COMP_FRAME_ID             : out std_logic_vector(7 downto 0);
        O_COMP_SUBFRAME_ID          : out std_logic_vector(3 downto 0);
        O_COMP_SLOT_ID              : out std_logic_vector(5 downto 0);
        O_COMP_SYMBOL_ID            : out std_logic_vector(3 downto 0);
        O_COMP_USER                 : out std_logic_vector(15 downto 0)
    );
    end component;

    signal i_bf_gain_offset         : std_logic_vector(10 downto 0);
    signal i_bf_scale_gain_offset   : std_logic_vector(3 downto 0);
    signal i_bf_exp_offset          : std_logic_vector(4 downto 0);
    signal i_bf_comp_enable         : std_logic := '0';
    signal i_bf_comp_data_i         : std_logic_vector(15 downto 0) := (others => '0');
    signal i_bf_comp_data_q         : std_logic_vector(15 downto 0) := (others => '0');
    signal i_bf_comp_rb_start_tic   : std_logic := '0';
    signal i_bf_comp_udiqwidth      : std_logic_vector(3 downto 0) := (others => '0');
    signal o_bf_comp_valid          : std_logic;
    signal o_bf_comp_data_i         : std_logic_vector(15 downto 0);
    signal o_bf_comp_data_q         : std_logic_vector(15 downto 0);
    signal o_bf_comp_exp_valid      : std_logic;
    signal o_bf_comp_exp            : std_logic_vector(3 downto 0);

begin

    -- continuous RBs
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (IQ_TICK = '1') and (IQ_USER(0) = '1') then
                if (IQ_COMP_HDR(3 downto 0) = "0000") then
                    i_bf_comp_udiqwidth    <= (others => '0');
                else
                    i_bf_comp_udiqwidth    <= IQ_COMP_HDR(7 downto 4);
                end if;
            end if;
        end if;
    end process;

    -- every RB
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (IQ_TICK = '1') then
                if    (RB_PATH = 1) then
                    i_bf_exp_offset        <= COMP_EXP_OFFSET(1);
                    i_bf_gain_offset       <= COMP_GAIN_OFFSET(1);
                    i_bf_scale_gain_offset <= COMP_SCALE_GAIN_OFFSET(1);
                elsif (RB_PATH = 2) then
                    i_bf_exp_offset        <= COMP_EXP_OFFSET(2);
                    i_bf_gain_offset       <= COMP_GAIN_OFFSET(2);
                    i_bf_scale_gain_offset <= COMP_SCALE_GAIN_OFFSET(2);
                elsif (RB_PATH = 3) then
                    i_bf_exp_offset        <= COMP_EXP_OFFSET(3);
                    i_bf_gain_offset       <= COMP_GAIN_OFFSET(3);
                    i_bf_scale_gain_offset <= COMP_SCALE_GAIN_OFFSET(3);
                elsif (RB_PATH = 4) then
                    i_bf_exp_offset        <= COMP_EXP_OFFSET(4);
                    i_bf_gain_offset       <= COMP_GAIN_OFFSET(4);
                    i_bf_scale_gain_offset <= COMP_SCALE_GAIN_OFFSET(4);
                elsif (RB_PATH = 5) then
                    i_bf_exp_offset        <= COMP_EXP_OFFSET(5);
                    i_bf_gain_offset       <= COMP_GAIN_OFFSET(5);
                    i_bf_scale_gain_offset <= COMP_SCALE_GAIN_OFFSET(5);
                elsif (RB_PATH = 6) then
                    i_bf_exp_offset        <= COMP_EXP_OFFSET(6);
                    i_bf_gain_offset       <= COMP_GAIN_OFFSET(6);
                    i_bf_scale_gain_offset <= COMP_SCALE_GAIN_OFFSET(6);
                elsif (RB_PATH = 7) then
                    i_bf_exp_offset        <= COMP_EXP_OFFSET(7);
                    i_bf_gain_offset       <= COMP_GAIN_OFFSET(7);
                    i_bf_scale_gain_offset <= COMP_SCALE_GAIN_OFFSET(7);
                else
                    i_bf_exp_offset        <= COMP_EXP_OFFSET(0);
                    i_bf_gain_offset       <= COMP_GAIN_OFFSET(0);
                    i_bf_scale_gain_offset <= COMP_SCALE_GAIN_OFFSET(0);
                end if;
            end if;
        end if;
    end process;

    -- every RE
    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            i_bf_comp_enable       <= IQ_VALID;
            i_bf_comp_data_i       <= IQ_DATA_I;
            i_bf_comp_data_q       <= IQ_DATA_Q;
            i_bf_comp_rb_start_tic <= IQ_TICK;
        end if;
    end process;

    process (RST, CLK)
    begin
        if (RST = '1') then
            index_wr <= 0;
            index_rd <= 0;
        elsif (CLK'event and CLK = '1') then
            if (IQ_TICK = '1') then
                if (o_bf_comp_exp_valid = '1') then
                    index_wr <= index_wr;
                else
                    index_wr <= index_wr + 1;
                end if;
            elsif (o_bf_comp_exp_valid = '1') then
                if (index_wr = 0) then
                    index_wr <= 0;
                else
                    index_wr <= index_wr - 1;
                end if;
            end if;
            if (IQ_TICK = '1') then
                if (o_bf_comp_exp_valid = '1') then
                    index_rd <= index_rd;
                else
                    index_rd <= index_wr;
                end if;
            elsif (o_bf_comp_exp_valid = '1') then
                if (index_rd = 0) then
                    index_rd <= 0;
                else
                    index_rd <= index_rd - 1;
                end if;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (IQ_TICK = '1') then
                comp_hdr_buf  <= comp_hdr_buf(MAX_BUFFER-2 downto 0) & IQ_COMP_HDR;
                comp_user_buf <= comp_user_buf(MAX_BUFFER-2 downto 0) & IQ_USER;
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            if (o_bf_comp_exp_valid = '1') then
                COMP_HDR    <= comp_hdr_buf(index_rd);
                COMP_USER   <= comp_user_buf(index_rd);
            end if;
        end if;
    end process;

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            COMP_PARAM  <= x"0" & o_bf_comp_exp;
            COMP_VALID  <= o_bf_comp_valid;
            COMP_TICK   <= o_bf_comp_exp_valid;
            COMP_DATA_I <= o_bf_comp_data_i;
            COMP_DATA_Q <= o_bf_comp_data_q;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Component mapping
--------------------------------------------------------------------------------

    u_COMP : COMP
    port map(
        CLK_245                     => CLK                                     ,--: in  std_logic;
        RST                         => RST                                     ,--: in  std_logic;
        I_COMP_MODE                 => IQ_COMP_HDR(1 downto 0)                 ,--: in  std_logic_vector(1 downto 0);
        I_COMP_GAIN_OFFSET          => i_bf_gain_offset                        ,--: in  std_logic_vector(10 downto 0);
        I_COMP_SCALE_GAIN_OFFSET    => i_bf_scale_gain_offset                  ,--: in  std_logic_vector(3 downto 0);
        I_COMP_EXP_OFFSET           => i_bf_exp_offset                         ,--: in  std_logic_vector(4 downto 0);
        I_COMP_ENABLE               => i_bf_comp_enable                        ,--: in  std_logic;
        I_COMP_DATA_I               => i_bf_comp_data_i                        ,--: in  std_logic_vector(15 downto 0);
        I_COMP_DATA_Q               => i_bf_comp_data_q                        ,--: in  std_logic_vector(15 downto 0);
        I_COMP_RB_START_TIC         => i_bf_comp_rb_start_tic                  ,--: in  std_logic;
        I_COMP_UDIQWIDTH            => i_bf_comp_udiqwidth                     ,--: in  std_logic_vector(3 downto 0);
        I_COMP_FRAME_ID             => (others => '0')                         ,--: in  std_logic_vector(7 downto 0);
        I_COMP_SUBFRAME_ID          => (others => '0')                         ,--: in  std_logic_vector(3 downto 0);
        I_COMP_SLOT_ID              => (others => '0')                         ,--: in  std_logic_vector(5 downto 0);
        I_COMP_SYMBOL_ID            => (others => '0')                         ,--: in  std_logic_vector(3 downto 0);
        I_COMP_USER                 => (others => '0')                         ,--: in  std_logic_vector(15 downto 0);
        O_COMP_VALID                => o_bf_comp_valid                         ,--: out std_logic;
        O_COMP_DATA_I               => o_bf_comp_data_i                        ,--: out std_logic_vector(15 downto 0);
        O_COMP_DATA_Q               => o_bf_comp_data_q                        ,--: out std_logic_vector(15 downto 0);
        O_COMP_RB_START_TIC         => o_bf_comp_exp_valid                     ,--: out std_logic;
        O_COMP_EXP                  => o_bf_comp_exp                           ,--: out std_logic_vector(3 downto 0);
        O_COMP_MODE                 => open                                    ,--: out std_logic_vector(1 downto 0);
        O_COMP_UDIQWIDTH            => open                                    ,--: out std_logic_vector(3 downto 0);
        O_COMP_FRAME_ID             => open                                    ,--: out std_logic_vector(7 downto 0);
        O_COMP_SUBFRAME_ID          => open                                    ,--: out std_logic_vector(3 downto 0);
        O_COMP_SLOT_ID              => open                                    ,--: out std_logic_vector(5 downto 0);
        O_COMP_SYMBOL_ID            => open                                    ,--: out std_logic_vector(3 downto 0);
        O_COMP_USER                 => open                                     --: out std_logic_vector(15 downto 0)
    );

end BEHAVE;