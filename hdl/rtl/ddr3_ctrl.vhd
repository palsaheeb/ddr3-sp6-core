--==============================================================================
--! @file ddr3_ctrl.vhd
--==============================================================================

--! Standard library
library IEEE;
--! Standard packages
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
--! Specific packages

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- DDR3 Controller
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--! @brief
--! Wishbone to DDR3 interface
--------------------------------------------------------------------------------
--! @details
--! Wishbone to DDR3 interface for Xilinx FPGA with MCB (Memory Controller
--! Block). This core is based on the code generated by Xilinx CoreGen for
--! the MCB. It is designed for 16-bit data bus DDR2 memories and has 2 WB
--! ports of 32-bit.
--------------------------------------------------------------------------------
--! @version
--! 0.1 | mc | 09.08.2010 | File creation and Doxygen comments
--!
--! @author
--! mc : Matthieu Cattin, CERN (BE-CO-HT)
--------------------------------------------------------------------------------


--==============================================================================
--! Entity declaration for ddr3_ctrl
--==============================================================================
entity ddr3_ctrl is

  generic(
    --! Core's clock period in ps
    g_MEMCLK_PERIOD      : integer := 3000;
    --! Core's reset polarity (1=active low, 0=active high)
    g_RST_ACT_LOW        : integer := 1;
    --! Core's clock type (SINGLE_ENDED or DIFFERENTIAL)
    g_INPUT_CLK_TYPE     : string  := "SINGLE_ENDED";
    --! If TRUE, uses Xilinx calibration core (Input term, DQS centering)
    g_CALIB_SOFT_IP      : string  := "TRUE";
    --! User ports addresses maping (BANK_ROW_COLUMN or ROW_BANK_COLUMN)
    g_MEM_ADDR_ORDER     : string  := "ROW_BANK_COLUMN";
    --! Skip calibration phase (for faster simulation)
    g_MC_CALIB_BYPASS    : string  := "NO";
    --! DDR3 data port width
    g_NUM_DQ_PINS        : integer := 16;
    --! DDR3 address port width
    g_MEM_ADDR_WIDTH     : integer := 14;
    --! DDR3 bank address width
    g_MEM_BANKADDR_WIDTH : integer := 3;
    --! Wishbone port 0 data mask size (8-bit granularity)
    g_P0_MASK_SIZE       : integer := 4;
    --! Wishbone port 0 data width
    g_P0_DATA_PORT_SIZE  : integer := 32;
    --! Wishbone port 1 data mask size (8-bit granularity)
    g_P1_MASK_SIZE       : integer := 4;
    --! Wishbone port 1 data width
    g_P1_DATA_PORT_SIZE  : integer := 32
    );

  port(
    ----------------------------------------------------------------------------
    -- Clocks and reset
    ----------------------------------------------------------------------------
    --! Core's differential clock input (pos)
    --clk_p_i : in std_logic;
    --! Core's differential clock input (neg)
    --clk_n_i : in std_logic;
    --! Core's clock input
    clk_i   : in std_logic;
    --! Core's reset input (active low)
    rst_n_i : in std_logic;

    ----------------------------------------------------------------------------
    -- Status
    ----------------------------------------------------------------------------
    --! Indicates end of calibration sequence at startup
    calib_done : out std_logic;

    ----------------------------------------------------------------------------
    -- DDR3 interface
    ----------------------------------------------------------------------------
    --! DDR3 data bus
    ddr3_dq_b     : inout std_logic_vector(g_NUM_DQ_PINS-1 downto 0);
    --! DDR3 address bus
    ddr3_a_o      : out   std_logic_vector(g_MEM_ADDR_WIDTH-1 downto 0);
    --! DDR3 bank address
    ddr3_ba_o     : out   std_logic_vector(g_MEM_BANKADDR_WIDTH-1 downto 0);
    --! DDR3 row address strobe
    ddr3_ras_n_o  : out   std_logic;
    --! DDR3 column address strobe
    ddr3_cas_n_o  : out   std_logic;
    --! DDR3 write enable
    ddr3_we_n_o   : out   std_logic;
    --! DDR3 on-die termination
    ddr3_odt_o    : out   std_logic;
    --! DDR3 reset
    ddr3_rst_n_o  : out   std_logic;
    --! DDR3 clock enable
    ddr3_cke_o    : out   std_logic;
    --! DDR3 lower byte data mask
    ddr3_dm_o     : out   std_logic;
    --! DDR3 upper byte data mask
    ddr3_udm_o    : out   std_logic;
    --! DDR3 lower byte data strobe (pos)
    ddr3_dqs_p_b  : inout std_logic;
    --! DDR3 lower byte data strobe (neg)
    ddr3_dqs_n_b  : inout std_logic;
    --! DDR3 upper byte data strobe (pos)
    ddr3_udqs_p_b : inout std_logic;
    --! DDR3 upper byte data strobe (pos)
    ddr3_udqs_n_b : inout std_logic;
    --! DDR3 clock (pos)
    ddr3_clk_p_o  : out   std_logic;
    --! DDR3 clock (neg)
    ddr3_clk_n_o  : out   std_logic;
    --! MCB internal termination calibration resistor
    ddr3_rzq_b    : inout std_logic;
    --! MCB internal termination calibration
    ddr3_zio_b    : inout std_logic;

    ----------------------------------------------------------------------------
    -- Wishbone bus - Port 0
    ----------------------------------------------------------------------------
    --! Wishbone bus clock
    wb0_clk_i   : in  std_logic;
    --! Wishbone bus byte select
    wb0_sel_i   : in  std_logic_vector(g_P0_MASK_SIZE - 1 downto 0);
    --! Wishbone bus cycle select
    wb0_cyc_i   : in  std_logic;
    --! Wishbone bus cycle strobe
    wb0_stb_i   : in  std_logic;
    --! Wishbone bus write enable
    wb0_we_i    : in  std_logic;
    --! Wishbone bus address
    wb0_addr_i  : in  std_logic_vector(29 downto 0);
    --! Wishbone bus data input
    wb0_data_i  : in  std_logic_vector(g_P0_DATA_PORT_SIZE - 1 downto 0);
    --! Wishbone bus data output
    wb0_data_o  : out std_logic_vector(g_P0_DATA_PORT_SIZE - 1 downto 0);
    --! Wishbone bus acknowledge
    wb0_ack_o   : out std_logic;
    --! Wishbone bus stall (for pipelined mode)
    wb0_stall_o : out std_logic;

    ----------------------------------------------------------------------------
    -- Wishbone bus - Port 1
    ----------------------------------------------------------------------------
    --! Wishbone bus clock
    wb1_clk_i   : in  std_logic;
    --! Wishbone bus byte select
    wb1_sel_i   : in  std_logic_vector(g_P0_MASK_SIZE - 1 downto 0);
    --! Wishbone bus cycle select
    wb1_cyc_i   : in  std_logic;
    --! Wishbone bus cycle strobe
    wb1_stb_i   : in  std_logic;
    --! Wishbone bus write enable
    wb1_we_i    : in  std_logic;
    --! Wishbone bus address
    wb1_addr_i  : in  std_logic_vector(29 downto 0);
    --! Wishbone bus data input
    wb1_data_i  : in  std_logic_vector(g_P0_DATA_PORT_SIZE - 1 downto 0);
    --! Wishbone bus data output
    wb1_data_o  : out std_logic_vector(g_P0_DATA_PORT_SIZE - 1 downto 0);
    --! Wishbone bus acknowledge
    wb1_ack_o   : out std_logic;
    --! Wishbone bus stall (for pipelined mode)
    wb1_stall_o : out std_logic
    );

end entity ddr3_ctrl;



--==============================================================================
--! Architecure declaration for ddr3_ctrl
--==============================================================================
architecture rtl of ddr3_ctrl is

  ------------------------------------------------------------------------------
  -- Components declaration
  ------------------------------------------------------------------------------

  --! DDR controller component generated from Xilinx CoreGen
  component ddr_controller_sp605
    generic
      (
        C3_P0_MASK_SIZE       : integer := 4;
        C3_P0_DATA_PORT_SIZE  : integer := 32;
        C3_P1_MASK_SIZE       : integer := 4;
        C3_P1_DATA_PORT_SIZE  : integer := 32;
        C3_MEMCLK_PERIOD      : integer := 3000;
        C3_RST_ACT_LOW        : integer := 0;
        C3_INPUT_CLK_TYPE     : string  := "SINGLE_ENDED";
        C3_CALIB_SOFT_IP      : string  := "TRUE";
        C3_MEM_ADDR_ORDER     : string  := "ROW_BANK_COLUMN";
        C3_NUM_DQ_PINS        : integer := 16;
        C3_MEM_ADDR_WIDTH     : integer := 14;
        C3_MEM_BANKADDR_WIDTH : integer := 3;
        C3_MC_CALIB_BYPASS    : string  := "NO"
        );

    port
      (
        mcb3_dram_dq        : inout std_logic_vector(C3_NUM_DQ_PINS-1 downto 0);
        mcb3_dram_a         : out   std_logic_vector(C3_MEM_ADDR_WIDTH-1 downto 0);
        mcb3_dram_ba        : out   std_logic_vector(C3_MEM_BANKADDR_WIDTH-1 downto 0);
        mcb3_dram_ras_n     : out   std_logic;
        mcb3_dram_cas_n     : out   std_logic;
        mcb3_dram_we_n      : out   std_logic;
        mcb3_dram_odt       : out   std_logic;
        mcb3_dram_reset_n   : out   std_logic;
        mcb3_dram_cke       : out   std_logic;
        mcb3_dram_dm        : out   std_logic;
        mcb3_dram_udqs      : inout std_logic;
        mcb3_dram_udqs_n    : inout std_logic;
        mcb3_rzq            : inout std_logic;
        mcb3_zio            : inout std_logic;
        mcb3_dram_udm       : out   std_logic;
        --c3_sys_clk_p        : in    std_logic;
        --c3_sys_clk_n        : in    std_logic;
        c3_sys_clk          : in    std_logic;
        c3_sys_rst_n        : in    std_logic;
        c3_calib_done       : out   std_logic;
        c3_clk0             : out   std_logic;
        c3_rst0             : out   std_logic;
        mcb3_dram_dqs       : inout std_logic;
        mcb3_dram_dqs_n     : inout std_logic;
        mcb3_dram_ck        : out   std_logic;
        mcb3_dram_ck_n      : out   std_logic;
        c3_p0_cmd_clk       : in    std_logic;
        c3_p0_cmd_en        : in    std_logic;
        c3_p0_cmd_instr     : in    std_logic_vector(2 downto 0);
        c3_p0_cmd_bl        : in    std_logic_vector(5 downto 0);
        c3_p0_cmd_byte_addr : in    std_logic_vector(29 downto 0);
        c3_p0_cmd_empty     : out   std_logic;
        c3_p0_cmd_full      : out   std_logic;
        c3_p0_wr_clk        : in    std_logic;
        c3_p0_wr_en         : in    std_logic;
        c3_p0_wr_mask       : in    std_logic_vector(C3_P0_MASK_SIZE - 1 downto 0);
        c3_p0_wr_data       : in    std_logic_vector(C3_P0_DATA_PORT_SIZE - 1 downto 0);
        c3_p0_wr_full       : out   std_logic;
        c3_p0_wr_empty      : out   std_logic;
        c3_p0_wr_count      : out   std_logic_vector(6 downto 0);
        c3_p0_wr_underrun   : out   std_logic;
        c3_p0_wr_error      : out   std_logic;
        c3_p0_rd_clk        : in    std_logic;
        c3_p0_rd_en         : in    std_logic;
        c3_p0_rd_data       : out   std_logic_vector(C3_P0_DATA_PORT_SIZE - 1 downto 0);
        c3_p0_rd_full       : out   std_logic;
        c3_p0_rd_empty      : out   std_logic;
        c3_p0_rd_count      : out   std_logic_vector(6 downto 0);
        c3_p0_rd_overflow   : out   std_logic;
        c3_p0_rd_error      : out   std_logic;
        c3_p1_cmd_clk       : in    std_logic;
        c3_p1_cmd_en        : in    std_logic;
        c3_p1_cmd_instr     : in    std_logic_vector(2 downto 0);
        c3_p1_cmd_bl        : in    std_logic_vector(5 downto 0);
        c3_p1_cmd_byte_addr : in    std_logic_vector(29 downto 0);
        c3_p1_cmd_empty     : out   std_logic;
        c3_p1_cmd_full      : out   std_logic;
        c3_p1_wr_clk        : in    std_logic;
        c3_p1_wr_en         : in    std_logic;
        c3_p1_wr_mask       : in    std_logic_vector(C3_P1_MASK_SIZE - 1 downto 0);
        c3_p1_wr_data       : in    std_logic_vector(C3_P1_DATA_PORT_SIZE - 1 downto 0);
        c3_p1_wr_full       : out   std_logic;
        c3_p1_wr_empty      : out   std_logic;
        c3_p1_wr_count      : out   std_logic_vector(6 downto 0);
        c3_p1_wr_underrun   : out   std_logic;
        c3_p1_wr_error      : out   std_logic;
        c3_p1_rd_clk        : in    std_logic;
        c3_p1_rd_en         : in    std_logic;
        c3_p1_rd_data       : out   std_logic_vector(C3_P1_DATA_PORT_SIZE - 1 downto 0);
        c3_p1_rd_full       : out   std_logic;
        c3_p1_rd_empty      : out   std_logic;
        c3_p1_rd_count      : out   std_logic_vector(6 downto 0);
        c3_p1_rd_overflow   : out   std_logic;
        c3_p1_rd_error      : out   std_logic
        );
  end component ddr_controller_sp605;

  ------------------------------------------------------------------------------
  -- Types declaration
  ------------------------------------------------------------------------------
  type t_wb_fsm_states is (WB_IDLE, WB_WRITE, WB_READ, WB_READ_WAIT, WB_READ_ACK);

  ------------------------------------------------------------------------------
  -- Signals declaration
  ------------------------------------------------------------------------------
  signal wb0_fsm_state    : t_wb_fsm_states := WB_IDLE;
  signal p0_cmd_clk       : std_logic;
  signal p0_cmd_en        : std_logic;
  signal p0_cmd_instr     : std_logic_vector(2 downto 0);
  signal p0_cmd_bl        : std_logic_vector(5 downto 0);
  signal p0_cmd_byte_addr : std_logic_vector(29 downto 0);
  signal p0_cmd_empty     : std_logic;
  signal p0_cmd_full      : std_logic;
  signal p0_wr_clk        : std_logic;
  signal p0_wr_en         : std_logic;
  signal p0_wr_mask       : std_logic_vector(g_P0_MASK_SIZE - 1 downto 0);
  signal p0_wr_data       : std_logic_vector(g_P0_DATA_PORT_SIZE - 1 downto 0);
  signal p0_wr_full       : std_logic;
  signal p0_wr_empty      : std_logic;
  signal p0_wr_count      : std_logic_vector(6 downto 0);
  signal p0_wr_underrun   : std_logic;
  signal p0_wr_error      : std_logic;
  signal p0_rd_clk        : std_logic;
  signal p0_rd_en         : std_logic;
  signal p0_rd_data       : std_logic_vector(g_P0_DATA_PORT_SIZE - 1 downto 0);
  signal p0_rd_full       : std_logic;
  signal p0_rd_empty      : std_logic;
  signal p0_rd_count      : std_logic_vector(6 downto 0);
  signal p0_rd_overflow   : std_logic;
  signal p0_rd_error      : std_logic;

  signal wb1_fsm_state    : t_wb_fsm_states := WB_IDLE;
  signal p1_cmd_clk       : std_logic;
  signal p1_cmd_en        : std_logic;
  signal p1_cmd_instr     : std_logic_vector(2 downto 0);
  signal p1_cmd_bl        : std_logic_vector(5 downto 0);
  signal p1_cmd_byte_addr : std_logic_vector(29 downto 0);
  signal p1_cmd_empty     : std_logic;
  signal p1_cmd_full      : std_logic;
  signal p1_wr_clk        : std_logic;
  signal p1_wr_en         : std_logic;
  signal p1_wr_mask       : std_logic_vector(g_P1_MASK_SIZE - 1 downto 0);
  signal p1_wr_data       : std_logic_vector(g_P1_DATA_PORT_SIZE - 1 downto 0);
  signal p1_wr_full       : std_logic;
  signal p1_wr_empty      : std_logic;
  signal p1_wr_count      : std_logic_vector(6 downto 0);
  signal p1_wr_underrun   : std_logic;
  signal p1_wr_error      : std_logic;
  signal p1_rd_clk        : std_logic;
  signal p1_rd_en         : std_logic;
  signal p1_rd_data       : std_logic_vector(g_P1_DATA_PORT_SIZE - 1 downto 0);
  signal p1_rd_full       : std_logic;
  signal p1_rd_empty      : std_logic;
  signal p1_rd_count      : std_logic_vector(6 downto 0);
  signal p1_rd_overflow   : std_logic;
  signal p1_rd_error      : std_logic;

--==============================================================================
--! Architecure begin
--==============================================================================
begin

  cmp_ddr_controller : ddr_controller_sp605
    generic map (
      C3_P0_MASK_SIZE       => g_P0_MASK_SIZE,
      C3_P0_DATA_PORT_SIZE  => g_P0_DATA_PORT_SIZE,
      C3_P1_MASK_SIZE       => g_P1_MASK_SIZE,
      C3_P1_DATA_PORT_SIZE  => g_P1_DATA_PORT_SIZE,
      C3_MEMCLK_PERIOD      => g_MEMCLK_PERIOD,
      C3_RST_ACT_LOW        => g_RST_ACT_LOW,
      C3_INPUT_CLK_TYPE     => g_INPUT_CLK_TYPE,
      C3_CALIB_SOFT_IP      => g_CALIB_SOFT_IP,
      C3_MEM_ADDR_ORDER     => g_MEM_ADDR_ORDER,
      C3_NUM_DQ_PINS        => g_NUM_DQ_PINS,
      C3_MEM_ADDR_WIDTH     => g_MEM_ADDR_WIDTH,
      C3_MEM_BANKADDR_WIDTH => g_MEM_BANKADDR_WIDTH,
      C3_MC_CALIB_BYPASS    => g_MC_CALIB_BYPASS
      )
    port map (
      --c3_sys_clk_p  => clk_p_i,
      --c3_sys_clk_n  => clk_n_i,
      c3_sys_clk    => clk_i,
      c3_sys_rst_n  => rst_n_i,
      c3_clk0       => open,
      c3_rst0       => open,
      c3_calib_done => calib_done,

      mcb3_dram_dq      => ddr3_dq_b,
      mcb3_dram_a       => ddr3_a_o,
      mcb3_dram_ba      => ddr3_ba_o,
      mcb3_dram_ras_n   => ddr3_ras_n_o,
      mcb3_dram_cas_n   => ddr3_cas_n_o,
      mcb3_dram_we_n    => ddr3_we_n_o,
      mcb3_dram_odt     => ddr3_odt_o,
      mcb3_dram_cke     => ddr3_cke_o,
      mcb3_dram_ck      => ddr3_clk_p_o,
      mcb3_dram_ck_n    => ddr3_clk_n_o,
      mcb3_dram_dqs     => ddr3_dqs_p_b,
      mcb3_dram_dqs_n   => ddr3_dqs_n_b,
      mcb3_dram_reset_n => ddr3_rst_n_o,
      mcb3_dram_udqs    => ddr3_udqs_p_b,  -- for X16 parts
      mcb3_dram_udqs_n  => ddr3_udqs_n_b,  -- for X16 parts
      mcb3_dram_udm     => ddr3_udm_o,     -- for X16 parts
      mcb3_dram_dm      => ddr3_dm_o,
      mcb3_rzq          => ddr3_rzq_b,
      mcb3_zio          => ddr3_zio_b,

      c3_p0_cmd_clk       => p0_cmd_clk,
      c3_p0_cmd_en        => p0_cmd_en,
      c3_p0_cmd_instr     => p0_cmd_instr,
      c3_p0_cmd_bl        => p0_cmd_bl,
      c3_p0_cmd_byte_addr => p0_cmd_byte_addr,
      c3_p0_cmd_empty     => p0_cmd_empty,
      c3_p0_cmd_full      => p0_cmd_full,
      c3_p0_wr_clk        => p0_wr_clk,
      c3_p0_wr_en         => p0_wr_en,
      c3_p0_wr_mask       => p0_wr_mask,
      c3_p0_wr_data       => p0_wr_data,
      c3_p0_wr_full       => p0_wr_full,
      c3_p0_wr_empty      => p0_wr_empty,
      c3_p0_wr_count      => p0_wr_count,
      c3_p0_wr_underrun   => p0_wr_underrun,
      c3_p0_wr_error      => p0_wr_error,
      c3_p0_rd_clk        => p0_rd_clk,
      c3_p0_rd_en         => p0_rd_en,
      c3_p0_rd_data       => p0_rd_data,
      c3_p0_rd_full       => p0_rd_full,
      c3_p0_rd_empty      => p0_rd_empty,
      c3_p0_rd_count      => p0_rd_count,
      c3_p0_rd_overflow   => p0_rd_overflow,
      c3_p0_rd_error      => p0_rd_error,

      c3_p1_cmd_clk       => p1_cmd_clk,
      c3_p1_cmd_en        => p1_cmd_en,
      c3_p1_cmd_instr     => p1_cmd_instr,
      c3_p1_cmd_bl        => p1_cmd_bl,
      c3_p1_cmd_byte_addr => p1_cmd_byte_addr,
      c3_p1_cmd_empty     => p1_cmd_empty,
      c3_p1_cmd_full      => p1_cmd_full,
      c3_p1_wr_clk        => p1_wr_clk,
      c3_p1_wr_en         => p1_wr_en,
      c3_p1_wr_mask       => p1_wr_mask,
      c3_p1_wr_data       => p1_wr_data,
      c3_p1_wr_full       => p1_wr_full,
      c3_p1_wr_empty      => p1_wr_empty,
      c3_p1_wr_count      => p1_wr_count,
      c3_p1_wr_underrun   => p1_wr_underrun,
      c3_p1_wr_error      => p1_wr_error,
      c3_p1_rd_clk        => p1_rd_clk,
      c3_p1_rd_en         => p1_rd_en,
      c3_p1_rd_data       => p1_rd_data,
      c3_p1_rd_full       => p1_rd_full,
      c3_p1_rd_empty      => p1_rd_empty,
      c3_p1_rd_count      => p1_rd_count,
      c3_p1_rd_overflow   => p1_rd_overflow,
      c3_p1_rd_error      => p1_rd_error
      );

  ------------------------------------------------------------------------------
  -- Port 0 to wishbone interface
  ------------------------------------------------------------------------------

  -- Port 0 clocking
  p0_cmd_clk <= wb0_clk_i;
  p0_wr_clk  <= wb0_clk_i;
  p0_rd_clk  <= wb0_clk_i;

  p_p0_wb_interface : process (wb0_clk_i)
  begin
    if (rising_edge(wb0_clk_i)) then
      if (rst_n_i = '0') then
        wb0_fsm_state    <= WB_IDLE;
        wb0_ack_o        <= '0';
        wb0_data_o       <= (others => '0');
        --wb0_stall_o      <= '0';
        p0_cmd_en        <= '0';
        p0_cmd_byte_addr <= (others => '0');
        p0_cmd_bl        <= (others => '0');
        p0_cmd_instr     <= (others => '0');
        p0_wr_data       <= (others => '0');
        p0_wr_mask       <= (others => '0');
        p0_wr_en         <= '0';
        p0_rd_en         <= '0';
      else
        case wb0_fsm_state is

          when WB_IDLE =>
            if (wb0_cyc_i = '1' and wb0_stb_i = '1' and wb0_we_i = '1') then
              -- Write from wishbone
              p0_rd_en         <= '0';
              wb0_ack_o        <= '1';
              p0_cmd_en        <= '1';
              p0_cmd_instr     <= "000";
              p0_cmd_bl        <= "000001";
              p0_cmd_byte_addr <= wb0_addr_i;
              p0_wr_mask       <= "0000";
              p0_wr_data       <= wb0_data_i;
              p0_wr_en         <= '1';
            elsif (wb0_cyc_i = '1' and wb0_stb_i = '1' and wb0_we_i = '0') then
              -- Read from wishbone
              p0_wr_en         <= '0';
              wb0_ack_o        <= '0';
              p0_cmd_en        <= '1';
              p0_cmd_instr     <= "001";
              p0_cmd_bl        <= "000001";
              p0_cmd_byte_addr <= wb0_addr_i;
              wb0_fsm_state    <= WB_READ_WAIT;
            else
              wb0_ack_o <= '0';
              p0_cmd_en <= '0';
              p0_wr_en  <= '0';
              p0_rd_en  <= '0';
            end if;

          when WB_READ_WAIT =>
            p0_cmd_en  <= '0';
            p0_rd_en   <= not(p0_rd_empty);
            wb0_ack_o  <= p0_rd_en;
            wb0_data_o <= p0_rd_data;
            if (p0_rd_en = '1') then
              wb0_fsm_state <= WB_IDLE;
            end if;

          when others => null;
                         
        end case;
      end if;
    end if;
  end process p_p0_wb_interface;

  -- Port 0 pipelined mode compatibility
  wb0_stall_o <= p0_cmd_full or p0_wr_full or p0_rd_full;


  ------------------------------------------------------------------------------
  -- Port 1 to wishbone interface
  ------------------------------------------------------------------------------

  -- Port 1 clocking
  p1_cmd_clk <= wb1_clk_i;
  p1_wr_clk  <= wb1_clk_i;
  p1_rd_clk  <= wb1_clk_i;

  p_p1_wb_interface : process (wb1_clk_i)
  begin
    if (rising_edge(wb1_clk_i)) then
      if (rst_n_i = '0') then
        wb1_fsm_state    <= WB_IDLE;
        wb1_ack_o        <= '0';
        wb1_data_o       <= (others => '0');
        --wb1_stall_o      <= '0';
        p1_cmd_en        <= '0';
        p1_cmd_byte_addr <= (others => '0');
        p1_cmd_bl        <= (others => '0');
        p1_cmd_instr     <= (others => '0');
        p1_wr_data       <= (others => '0');
        p1_wr_mask       <= (others => '0');
        p1_wr_en         <= '0';
        p1_rd_en         <= '0';
      else
        case wb1_fsm_state is

          when WB_IDLE =>
            if (wb1_cyc_i = '1' and wb1_stb_i = '1' and wb1_we_i = '1') then
              -- Write from wishbone
              p1_rd_en         <= '0';
              wb1_ack_o        <= '1';
              p1_cmd_en        <= '1';
              p1_cmd_instr     <= "000";
              p1_cmd_bl        <= "000001";
              p1_cmd_byte_addr <= wb1_addr_i;
              p1_wr_mask       <= "0000";
              p1_wr_data       <= wb1_data_i;
              p1_wr_en         <= '1';
            elsif (wb1_cyc_i = '1' and wb1_stb_i = '1' and wb1_we_i = '0') then
              -- Read from wishbone
              p1_wr_en         <= '0';
              wb1_ack_o        <= '0';
              p1_cmd_en        <= '1';
              p1_cmd_instr     <= "001";
              p1_cmd_bl        <= "000001";
              p1_cmd_byte_addr <= wb1_addr_i;
              wb1_fsm_state    <= WB_READ_WAIT;
            else
              wb1_ack_o <= '0';
              p1_cmd_en <= '0';
              p1_wr_en  <= '0';
              p1_rd_en  <= '0';
            end if;

          when WB_READ_WAIT =>
            p1_cmd_en  <= '0';
            p1_rd_en   <= not(p1_rd_empty);
            wb1_ack_o  <= p1_rd_en;
            wb1_data_o <= p1_rd_data;
            if (p1_rd_en = '1') then
              wb1_fsm_state <= WB_IDLE;
            end if;

          when others => null;
                         
        end case;
      end if;
    end if;
  end process p_p1_wb_interface;

  -- Port 1 pipelined mode compatibility
  wb1_stall_o <= p1_cmd_full or p1_wr_full or p1_rd_full;


end architecture rtl;
--==============================================================================
--! Architecure end
--==============================================================================

