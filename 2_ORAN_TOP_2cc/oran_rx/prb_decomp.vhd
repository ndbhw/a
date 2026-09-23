--------------------------------------------------------------------------------
--                                                                            --
-- Copyright (C) 2020, Samsung Electronics Co., LTD. All Right Reserved.      --
--                                                                            --
-- Function   : IQ decompressor (O-RAN component)                             --
--                                                                            --
-- Author     : jaekyu.no (jaekyu.no@samsung.com)                             --
-- Department : Hardware R&D Group 1 (Network Division)                       --
-- Release    : 2020.04.15                                                    --
--                                                                            --
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PRB_DECOMP is
    port (
--------------------------------------------------------------------------------
-- Clock
--------------------------------------------------------------------------------

        CLK                         : in  std_logic;
        RST                         : in  std_logic;

--------------------------------------------------------------------------------
-- Control
--------------------------------------------------------------------------------

        COMP_EXP_OFFSET             : in  std_logic_vector(4 downto 0);

--------------------------------------------------------------------------------
-- Compressed data
--------------------------------------------------------------------------------

        COMP_FRAME_ID               : in  std_logic_vector(7 downto 0);
        COMP_SUBFRAME_ID            : in  std_logic_vector(3 downto 0);
        COMP_SLOT_ID                : in  std_logic_vector(5 downto 0);
        COMP_SYMBOL_ID              : in  std_logic_vector(5 downto 0);
        COMP_USER                   : in  std_logic_vector(62 downto 0);

        COMP_HDR                    : in  std_logic_vector(7 downto 0);
        COMP_PARAM                  : in  std_logic_vector(7 downto 0);

        COMP_VALID                  : in  std_logic;
        COMP_TICK                   : in  std_logic;
        COMP_DATA_I                 : in  std_logic_vector(15 downto 0);
        COMP_DATA_Q                 : in  std_logic_vector(15 downto 0);

--------------------------------------------------------------------------------
-- Decompressed data
--------------------------------------------------------------------------------

        IQ_FRAME_ID                 : out std_logic_vector(7 downto 0);
        IQ_SUBFRAME_ID              : out std_logic_vector(3 downto 0);
        IQ_SLOT_ID                  : out std_logic_vector(5 downto 0);
        IQ_SYMBOL_ID                : out std_logic_vector(5 downto 0);
        IQ_USER                     : out std_logic_vector(62 downto 0);

        IQ_VALID                    : out std_logic;
        IQ_TICK                     : out std_logic;
        IQ_DATA_I                   : out std_logic_vector(15 downto 0);
        IQ_DATA_Q                   : out std_logic_vector(15 downto 0)
    );
end PRB_DECOMP;

architecture BEHAVE of PRB_DECOMP is

    component DECOMP is
    port (
        CLK_245                     : in  std_logic;
        RST                         : in  std_logic;
        I_DECOMP_MODE               : in  std_logic_vector(1 downto 0);
        I_DECOMP_ENABLE             : in  std_logic;
        I_DECOMP_DATA_I             : in  std_logic_vector(15 downto 0);
        I_DECOMP_DATA_Q             : in  std_logic_vector(15 downto 0);
        I_DECOMP_RB_START_TIC       : in  std_logic;
        I_DECOMP_EXP                : in  std_logic_vector(3 downto 0);
        I_DECOMP_EXP_OFFSET         : in  std_logic_vector(4 downto 0);
        I_DECOMP_FRAME_ID           : in  std_logic_vector(7 downto 0);
        I_DECOMP_SUBFRAME_ID        : in  std_logic_vector(3 downto 0);
        I_DECOMP_SLOT_ID            : in  std_logic_vector(5 downto 0);
        I_DECOMP_SYMBOL_ID          : in  std_logic_vector(5 downto 0);
        I_DECOMP_USER               : in  std_logic_vector(19 downto 0);
        O_DECOMP_VALID              : out std_logic;
        O_DECOMP_DATA_I             : out std_logic_vector(15 downto 0);
        O_DECOMP_DATA_Q             : out std_logic_vector(15 downto 0);
        O_DECOMP_RB_START_TIC       : out std_logic;
        O_DECOMP_MODE               : out std_logic_vector(1 downto 0);
        O_DECOMP_FRAME_ID           : out std_logic_vector(7 downto 0);
        O_DECOMP_SUBFRAME_ID        : out std_logic_vector(3 downto 0);
        O_DECOMP_SLOT_ID            : out std_logic_vector(5 downto 0);
        O_DECOMP_SYMBOL_ID          : out std_logic_vector(5 downto 0);
        O_DECOMP_USER               : out std_logic_vector(19 downto 0)
    );
    end component;

    signal i_bf_decomp_enable       : std_logic;
    signal i_bf_decomp_data_i       : std_logic_vector(15 downto 0);
    signal i_bf_decomp_data_q       : std_logic_vector(15 downto 0);
    signal i_bf_decomp_rb_start_tic : std_logic;
    signal i_bf_decomp_exp          : std_logic_vector(3 downto 0);
    signal o_bf_decomp_valid        : std_logic;
    signal o_bf_decomp_data_i       : std_logic_vector(15 downto 0);
    signal o_bf_decomp_data_q       : std_logic_vector(15 downto 0);
    signal o_bf_decomp_rb_start_tic : std_logic;

begin

--------------------------------------------------------------------------------
-- Timing information
--------------------------------------------------------------------------------
--   If the processing time is longer than 12-clocks,
--   more registers should be added.
--------------------------------------------------------------------------------

    process (RST, CLK)
    begin
        if (RST = '1') then
            IQ_FRAME_ID    <= (others => '0');
            IQ_SUBFRAME_ID <= (others => '0');
            IQ_SLOT_ID     <= (others => '0');
            IQ_SYMBOL_ID   <= (others => '0');
            IQ_USER        <= (others => '0');
        elsif (CLK'event and CLK = '1') then
            if (o_bf_decomp_rb_start_tic = '1') then
                IQ_FRAME_ID    <= COMP_FRAME_ID;
                IQ_SUBFRAME_ID <= COMP_SUBFRAME_ID;
                IQ_SLOT_ID     <= COMP_SLOT_ID;
                IQ_SYMBOL_ID   <= COMP_SYMBOL_ID;
                IQ_USER        <= COMP_USER;
            end if;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Uncomp + BFP
--------------------------------------------------------------------------------

    process (CLK)
    begin
        if (CLK'event and CLK = '1') then
            i_bf_decomp_enable       <= COMP_VALID;
            i_bf_decomp_data_i       <= COMP_DATA_I;
            i_bf_decomp_data_q       <= COMP_DATA_Q;
            if (COMP_HDR(3 downto 0) = x"1") then                               -- BFP
                i_bf_decomp_rb_start_tic <= COMP_TICK;
                i_bf_decomp_exp          <= COMP_PARAM(3 downto 0);
            else                                                                -- Uncomp (Set EXP to 0)
                i_bf_decomp_rb_start_tic <= COMP_TICK;
                i_bf_decomp_exp          <= (others => '0');
            end if;
        end if;
    end process;

    process (RST, CLK)
    begin
        if (RST = '1') then
            IQ_VALID  <= '0';
            IQ_DATA_I <= (others => '0');
            IQ_DATA_Q <= (others => '0');
            IQ_TICK   <= '0';
        elsif (CLK'event and CLK = '1') then
            IQ_VALID  <= o_bf_decomp_valid;
            IQ_DATA_I <= o_bf_decomp_data_i;
            IQ_DATA_Q <= o_bf_decomp_data_q;
            IQ_TICK   <= o_bf_decomp_rb_start_tic;
        end if;
    end process;

--------------------------------------------------------------------------------
-- Component mapping
--------------------------------------------------------------------------------

    u_DECOMP : DECOMP
    port map(
        CLK_245                     => CLK                                     ,--: in  std_logic;
        RST                         => RST                                     ,--: in  std_logic;
        I_DECOMP_MODE               => COMP_HDR(1 downto 0)                    ,--: in  std_logic_vector(1 downto 0);
        I_DECOMP_ENABLE             => i_bf_decomp_enable                      ,--: in  std_logic;
        I_DECOMP_DATA_I             => i_bf_decomp_data_i                      ,--: in  std_logic_vector(15 downto 0);
        I_DECOMP_DATA_Q             => i_bf_decomp_data_q                      ,--: in  std_logic_vector(15 downto 0);
        I_DECOMP_RB_START_TIC       => i_bf_decomp_rb_start_tic                ,--: in  std_logic;
        I_DECOMP_EXP                => i_bf_decomp_exp                         ,--: in  std_logic_vector(3 downto 0);
        I_DECOMP_EXP_OFFSET         => COMP_EXP_OFFSET                         ,--: in  std_logic_vector(4 downto 0);
        I_DECOMP_FRAME_ID           => (others => '0')                         ,--: in  std_logic_vector(7 downto 0);
        I_DECOMP_SUBFRAME_ID        => (others => '0')                         ,--: in  std_logic_vector(3 downto 0);
        I_DECOMP_SLOT_ID            => (others => '0')                         ,--: in  std_logic_vector(5 downto 0);
        I_DECOMP_SYMBOL_ID          => (others => '0')                         ,--: in  std_logic_vector(5 downto 0);
        I_DECOMP_USER               => (others => '0')                         ,--: in  std_logic_vector(19 downto 0);
        O_DECOMP_VALID              => o_bf_decomp_valid                       ,--: out std_logic;
        O_DECOMP_DATA_I             => o_bf_decomp_data_i                      ,--: out std_logic_vector(15 downto 0);
        O_DECOMP_DATA_Q             => o_bf_decomp_data_q                      ,--: out std_logic_vector(15 downto 0);
        O_DECOMP_RB_START_TIC       => o_bf_decomp_rb_start_tic                ,--: out std_logic;
        O_DECOMP_MODE               => open                                    ,--: out std_logic_vector(1 downto 0);
        O_DECOMP_FRAME_ID           => open                                    ,--: out std_logic_vector(7 downto 0);
        O_DECOMP_SUBFRAME_ID        => open                                    ,--: out std_logic_vector(3 downto 0);
        O_DECOMP_SLOT_ID            => open                                    ,--: out std_logic_vector(5 downto 0);
        O_DECOMP_SYMBOL_ID          => open                                    ,--: out std_logic_vector(5 downto 0);
        O_DECOMP_USER               => open                                     --: out std_logic_vector(19 downto 0)
    );

end BEHAVE;