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
    --! Set to TRUE for simulation
    g_SIMULATION         : string  := "FALSE";
    --! If TRUE, uses Xilinx calibration core (Input term, DQS centering)
    g_CALIB_SOFT_IP      : string  := "TRUE";
    --! User ports addresses maping (BANK_ROW_COLUMN or ROW_BANK_COLUMN)
    g_MEM_ADDR_ORDER     : string  := "ROW_BANK_COLUMN";
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
    wb0_addr_i  : in  std_logic_vector(27 downto 0);
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
    wb1_sel_i   : in  std_logic_vector(g_P1_MASK_SIZE - 1 downto 0);
    --! Wishbone bus cycle select
    wb1_cyc_i   : in  std_logic;
    --! Wishbone bus cycle strobe
    wb1_stb_i   : in  std_logic;
    --! Wishbone bus write enable
    wb1_we_i    : in  std_logic;
    --! Wishbone bus address
    wb1_addr_i  : in  std_logic_vector(27 downto 0);
    --! Wishbone bus data input
    wb1_data_i  : in  std_logic_vector(g_P1_DATA_PORT_SIZE - 1 downto 0);
    --! Wishbone bus data output
    wb1_data_o  : out std_logic_vector(g_P1_DATA_PORT_SIZE - 1 downto 0);
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
  component ddr_controller_bank1
    generic
      (
        C1_P0_MASK_SIZE       : integer := 4;
        C1_P0_DATA_PORT_SIZE  : integer := 32;
        C1_P1_MASK_SIZE       : integer := 4;
        C1_P1_DATA_PORT_SIZE  : integer := 32;
        C1_MEMCLK_PERIOD      : integer := 3000;
        C1_RST_ACT_LOW        : integer := 0;
        C1_INPUT_CLK_TYPE     : string  := "SINGLE_ENDED";
        C1_CALIB_SOFT_IP      : string  := "TRUE";
        C1_SIMULATION         : string  := "FALSE";
        DEBUG_EN              : integer := 0;
        C1_MEM_ADDR_ORDER     : string  := "ROW_BANK_COLUMN";
        C1_NUM_DQ_PINS        : integer := 16;
        C1_MEM_ADDR_WIDTH     : integer := 14;
        C1_MEM_BANKADDR_WIDTH : integer := 3
        );

    port
      (

        mcb1_dram_dq        : inout std_logic_vector(C1_NUM_DQ_PINS-1 downto 0);
        mcb1_dram_a         : out   std_logic_vector(C1_MEM_ADDR_WIDTH-1 downto 0);
        mcb1_dram_ba        : out   std_logic_vector(C1_MEM_BANKADDR_WIDTH-1 downto 0);
        mcb1_dram_ras_n     : out   std_logic;
        mcb1_dram_cas_n     : out   std_logic;
        mcb1_dram_we_n      : out   std_logic;
        mcb1_dram_odt       : out   std_logic;
        mcb1_dram_reset_n   : out   std_logic;
        mcb1_dram_cke       : out   std_logic;
        mcb1_dram_dm        : out   std_logic;
        mcb1_dram_udqs      : inout std_logic;
        mcb1_dram_udqs_n    : inout std_logic;
        mcb1_rzq            : inout std_logic;
        mcb1_dram_udm       : out   std_logic;
        c1_sys_clk          : in    std_logic;
        c1_sys_rst_n        : in    std_logic;
        c1_calib_done       : out   std_logic;
        c1_clk0             : out   std_logic;
        c1_rst0             : out   std_logic;
        mcb1_dram_dqs       : inout std_logic;
        mcb1_dram_dqs_n     : inout std_logic;
        mcb1_dram_ck        : out   std_logic;
        mcb1_dram_ck_n      : out   std_logic;
        c1_p0_cmd_clk       : in    std_logic;
        c1_p0_cmd_en        : in    std_logic;
        c1_p0_cmd_instr     : in    std_logic_vector(2 downto 0);
        c1_p0_cmd_bl        : in    std_logic_vector(5 downto 0);
        c1_p0_cmd_byte_addr : in    std_logic_vector(29 downto 0);
        c1_p0_cmd_empty     : out   std_logic;
        c1_p0_cmd_full      : out   std_logic;
        c1_p0_wr_clk        : in    std_logic;
        c1_p0_wr_en         : in    std_logic;
        c1_p0_wr_mask       : in    std_logic_vector(C1_P0_MASK_SIZE - 1 downto 0);
        c1_p0_wr_data       : in    std_logic_vector(C1_P0_DATA_PORT_SIZE - 1 downto 0);
        c1_p0_wr_full       : out   std_logic;
        c1_p0_wr_empty      : out   std_logic;
        c1_p0_wr_count      : out   std_logic_vector(6 downto 0);
        c1_p0_wr_underrun   : out   std_logic;
        c1_p0_wr_error      : out   std_logic;
        c1_p0_rd_clk        : in    std_logic;
        c1_p0_rd_en         : in    std_logic;
        c1_p0_rd_data       : out   std_logic_vector(C1_P0_DATA_PORT_SIZE - 1 downto 0);
        c1_p0_rd_full       : out   std_logic;
        c1_p0_rd_empty      : out   std_logic;
        c1_p0_rd_count      : out   std_logic_vector(6 downto 0);
        c1_p0_rd_overflow   : out   std_logic;
        c1_p0_rd_error      : out   std_logic;
        c1_p1_cmd_clk       : in    std_logic;
        c1_p1_cmd_en        : in    std_logic;
        c1_p1_cmd_instr     : in    std_logic_vector(2 downto 0);
        c1_p1_cmd_bl        : in    std_logic_vector(5 downto 0);
        c1_p1_cmd_byte_addr : in    std_logic_vector(29 downto 0);
        c1_p1_cmd_empty     : out   std_logic;
        c1_p1_cmd_full      : out   std_logic;
        c1_p1_wr_clk        : in    std_logic;
        c1_p1_wr_en         : in    std_logic;
        c1_p1_wr_mask       : in    std_logic_vector(C1_P1_MASK_SIZE - 1 downto 0);
        c1_p1_wr_data       : in    std_logic_vector(C1_P1_DATA_PORT_SIZE - 1 downto 0);
        c1_p1_wr_full       : out   std_logic;
        c1_p1_wr_empty      : out   std_logic;
        c1_p1_wr_count      : out   std_logic_vector(6 downto 0);
        c1_p1_wr_underrun   : out   std_logic;
        c1_p1_wr_error      : out   std_logic;
        c1_p1_rd_clk        : in    std_logic;
        c1_p1_rd_en         : in    std_logic;
        c1_p1_rd_data       : out   std_logic_vector(C1_P1_DATA_PORT_SIZE - 1 downto 0);
        c1_p1_rd_full       : out   std_logic;
        c1_p1_rd_empty      : out   std_logic;
        c1_p1_rd_count      : out   std_logic_vector(6 downto 0);
        c1_p1_rd_overflow   : out   std_logic;
        c1_p1_rd_error      : out   std_logic
        );
  end component ddr_controller_bank1;

  ------------------------------------------------------------------------------
  -- Constants declaration
  ------------------------------------------------------------------------------
  constant c_P0_BURST_LENGTH : integer := 32;  -- must not exceed 63
  constant c_P1_BURST_LENGTH : integer := 32;  -- must not exceed 63

  constant c_FIFO_ALMOST_FULL : std_logic_vector(6 downto 0) := std_logic_vector(to_unsigned(57, 7));

  ------------------------------------------------------------------------------
  -- Types declaration
  ------------------------------------------------------------------------------
  type t_wb_fsm_states is (WB_IDLE, WB_WRITE, WB_READ, WB_READ_WAIT);

  ------------------------------------------------------------------------------
  -- Signals declaration
  ------------------------------------------------------------------------------
  signal wb0_fsm_state    : t_wb_fsm_states := WB_IDLE;
  signal rst0_n           : std_logic;
  signal wb0_cyc_d        : std_logic;
  signal wb0_cyc_f_edge   : std_logic;
  signal wb0_cyc_r_edge   : std_logic;
  signal wb0_stb_d        : std_logic;
  signal wb0_stb_f_edge   : std_logic;
  signal wb0_we_d         : std_logic;
  signal wb0_we_f_edge    : std_logic;
  signal wb0_addr_d       : std_logic_vector(27 downto 0);
  signal p0_burst_cnt     : unsigned(5 downto 0);
  signal p0_cmd_clk       : std_logic;
  signal p0_cmd_en        : std_logic;
  signal p0_cmd_en_d      : std_logic;
  signal p0_cmd_en_r_edge : std_logic;
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
  signal rst1_n           : std_logic;
  signal wb1_cyc_d        : std_logic;
  signal wb1_cyc_f_edge   : std_logic;
  signal wb1_cyc_r_edge   : std_logic;
  signal wb1_stb_d        : std_logic;
  signal wb1_stb_f_edge   : std_logic;
  signal wb1_we_d         : std_logic;
  signal wb1_we_f_edge    : std_logic;
  signal wb1_addr_d       : std_logic_vector(27 downto 0);
  signal p1_burst_cnt     : unsigned(5 downto 0);
  signal p1_cmd_clk       : std_logic;
  signal p1_cmd_en        : std_logic;
  signal p1_cmd_en_d      : std_logic;
  signal p1_cmd_en_r_edge : std_logic;
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

  cmp_ddr_controller : ddr_controller_bank1
    generic map (
      C1_P0_MASK_SIZE       => g_P0_MASK_SIZE,
      C1_P0_DATA_PORT_SIZE  => g_P0_DATA_PORT_SIZE,
      C1_P1_MASK_SIZE       => g_P1_MASK_SIZE,
      C1_P1_DATA_PORT_SIZE  => g_P1_DATA_PORT_SIZE,
      C1_MEMCLK_PERIOD      => g_MEMCLK_PERIOD,
      C1_RST_ACT_LOW        => g_RST_ACT_LOW,
      C1_INPUT_CLK_TYPE     => g_INPUT_CLK_TYPE,
      C1_CALIB_SOFT_IP      => g_CALIB_SOFT_IP,
      C1_SIMULATION         => g_SIMULATION,
      C1_MEM_ADDR_ORDER     => g_MEM_ADDR_ORDER,
      C1_NUM_DQ_PINS        => g_NUM_DQ_PINS,
      C1_MEM_ADDR_WIDTH     => g_MEM_ADDR_WIDTH,
      C1_MEM_BANKADDR_WIDTH => g_MEM_BANKADDR_WIDTH
      )
    port map (
      c1_sys_clk    => clk_i,
      c1_sys_rst_n  => rst_n_i,
      c1_clk0       => open,
      c1_rst0       => open,
      c1_calib_done => calib_done,

      mcb1_dram_dq      => ddr3_dq_b,
      mcb1_dram_a       => ddr3_a_o,
      mcb1_dram_ba      => ddr3_ba_o,
      mcb1_dram_ras_n   => ddr3_ras_n_o,
      mcb1_dram_cas_n   => ddr3_cas_n_o,
      mcb1_dram_we_n    => ddr3_we_n_o,
      mcb1_dram_odt     => ddr3_odt_o,
      mcb1_dram_cke     => ddr3_cke_o,
      mcb1_dram_ck      => ddr3_clk_p_o,
      mcb1_dram_ck_n    => ddr3_clk_n_o,
      mcb1_dram_dqs     => ddr3_dqs_p_b,
      mcb1_dram_dqs_n   => ddr3_dqs_n_b,
      mcb1_dram_reset_n => ddr3_rst_n_o,
      mcb1_dram_udqs    => ddr3_udqs_p_b,  -- for X16 parts
      mcb1_dram_udqs_n  => ddr3_udqs_n_b,  -- for X16 parts
      mcb1_dram_udm     => ddr3_udm_o,     -- for X16 parts
      mcb1_dram_dm      => ddr3_dm_o,
      mcb1_rzq          => ddr3_rzq_b,
      --mcb1_zio          => ddr3_zio_b,

      c1_p0_cmd_clk       => p0_cmd_clk,
      c1_p0_cmd_en        => p0_cmd_en,
      c1_p0_cmd_instr     => p0_cmd_instr,
      c1_p0_cmd_bl        => p0_cmd_bl,
      c1_p0_cmd_byte_addr => p0_cmd_byte_addr,
      c1_p0_cmd_empty     => p0_cmd_empty,
      c1_p0_cmd_full      => p0_cmd_full,
      c1_p0_wr_clk        => p0_wr_clk,
      c1_p0_wr_en         => p0_wr_en,
      c1_p0_wr_mask       => p0_wr_mask,
      c1_p0_wr_data       => p0_wr_data,
      c1_p0_wr_full       => p0_wr_full,
      c1_p0_wr_empty      => p0_wr_empty,
      c1_p0_wr_count      => p0_wr_count,
      c1_p0_wr_underrun   => p0_wr_underrun,
      c1_p0_wr_error      => p0_wr_error,
      c1_p0_rd_clk        => p0_rd_clk,
      c1_p0_rd_en         => p0_rd_en,
      c1_p0_rd_data       => p0_rd_data,
      c1_p0_rd_full       => p0_rd_full,
      c1_p0_rd_empty      => p0_rd_empty,
      c1_p0_rd_count      => p0_rd_count,
      c1_p0_rd_overflow   => p0_rd_overflow,
      c1_p0_rd_error      => p0_rd_error,

      c1_p1_cmd_clk       => p1_cmd_clk,
      c1_p1_cmd_en        => p1_cmd_en,
      c1_p1_cmd_instr     => p1_cmd_instr,
      c1_p1_cmd_bl        => p1_cmd_bl,
      c1_p1_cmd_byte_addr => p1_cmd_byte_addr,
      c1_p1_cmd_empty     => p1_cmd_empty,
      c1_p1_cmd_full      => p1_cmd_full,
      c1_p1_wr_clk        => p1_wr_clk,
      c1_p1_wr_en         => p1_wr_en,
      c1_p1_wr_mask       => p1_wr_mask,
      c1_p1_wr_data       => p1_wr_data,
      c1_p1_wr_full       => p1_wr_full,
      c1_p1_wr_empty      => p1_wr_empty,
      c1_p1_wr_count      => p1_wr_count,
      c1_p1_wr_underrun   => p1_wr_underrun,
      c1_p1_wr_error      => p1_wr_error,
      c1_p1_rd_clk        => p1_rd_clk,
      c1_p1_rd_en         => p1_rd_en,
      c1_p1_rd_data       => p1_rd_data,
      c1_p1_rd_full       => p1_rd_full,
      c1_p1_rd_empty      => p1_rd_empty,
      c1_p1_rd_count      => p1_rd_count,
      c1_p1_rd_overflow   => p1_rd_overflow,
      c1_p1_rd_error      => p1_rd_error
      );

  ddr3_zio_b <= 'Z';
  --ddr3_odt_o <= '0';


  ------------------------------------------------------------------------------
  -- Port 0 to wishbone interface
  ------------------------------------------------------------------------------

  -- Reset sync to wb0_clk_i
  p_rst0_sync : process (rst_n_i, wb0_clk_i)
  begin
    if (rst_n_i = '0') then
      rst0_n <= '0';
    elsif rising_edge(wb0_clk_i) then
      rst0_n <= '1';
    end if;
  end process p_rst0_sync;

  -- Clocking
  p0_cmd_clk <= wb0_clk_i;
  p0_wr_clk  <= wb0_clk_i;
  p0_rd_clk  <= wb0_clk_i;

  p_p0_wb_interface : process (wb0_clk_i)
  begin
    if (rising_edge(wb0_clk_i)) then
      if (rst0_n = '0') then
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
              wb0_ack_o        <= '0';
              p0_cmd_en        <= '0';
              p0_cmd_instr     <= "000";
              p0_cmd_bl        <= "000000";
              p0_cmd_byte_addr <= wb0_addr_i & "00";
              p0_wr_mask       <= "0000";
              p0_wr_data       <= wb0_data_i;
              p0_wr_en         <= '1';
              wb0_fsm_state    <= WB_WRITE;
            elsif (wb0_cyc_i = '1' and wb0_stb_i = '1' and wb0_we_i = '0') then
              -- Read from wishbone
              p0_wr_en         <= '0';
              wb0_ack_o        <= '0';
              p0_cmd_en        <= '0';
              p0_cmd_instr     <= "001";
              p0_cmd_bl        <= "000000";
              p0_cmd_byte_addr <= wb0_addr_i & "00";
              wb0_fsm_state    <= WB_READ;
            else
              wb0_ack_o <= '0';
              p0_cmd_en <= '0';
              p0_wr_en  <= '0';
              p0_rd_en  <= '0';
            end if;

          when WB_WRITE =>
            wb0_ack_o     <= '1';
            p0_cmd_en     <= '1';
            wb0_fsm_state <= WB_IDLE;

          when WB_READ =>
            p0_cmd_en     <= '1';
            wb0_fsm_state <= WB_READ_WAIT;

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

  -- Reset sync to wb1_clk_i
  p_rst1_sync : process (rst_n_i, wb1_clk_i)
  begin
    if (rst_n_i = '0') then
      rst1_n <= '0';
    elsif rising_edge(wb1_clk_i) then
      rst1_n <= '1';
    end if;
  end process p_rst1_sync;

  -- Clocking
  p1_cmd_clk <= wb1_clk_i;
  p1_wr_clk  <= wb1_clk_i;
  p1_rd_clk  <= wb1_clk_i;

  p_p1_wb_interface : process (wb1_clk_i)
  begin
    if (rising_edge(wb1_clk_i)) then
      if (rst1_n = '0') then
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
              wb1_ack_o        <= '0';
              p1_cmd_en        <= '0';
              p1_cmd_instr     <= "000";
              p1_cmd_bl        <= "000000";
              p1_cmd_byte_addr <= wb1_addr_i & "00";
              p1_wr_mask       <= "0000";
              p1_wr_data       <= wb1_data_i;
              p1_wr_en         <= '1';
              wb1_fsm_state    <= WB_WRITE;
            elsif (wb1_cyc_i = '1' and wb1_stb_i = '1' and wb1_we_i = '0') then
              -- Read from wishbone
              p1_wr_en         <= '0';
              wb1_ack_o        <= '0';
              p1_cmd_en        <= '0';
              p1_cmd_instr     <= "001";
              p1_cmd_bl        <= "000000";
              p1_cmd_byte_addr <= wb1_addr_i & "00";
              wb1_fsm_state    <= WB_READ;
            else
              wb1_ack_o <= '0';
              p1_cmd_en <= '0';
              p1_wr_en  <= '0';
              p1_rd_en  <= '0';
            end if;

          when WB_WRITE =>
            wb1_ack_o     <= '1';
            p1_cmd_en     <= '1';
            wb1_fsm_state <= WB_IDLE;

          when WB_READ =>
            p1_cmd_en     <= '1';
            wb1_fsm_state <= WB_READ_WAIT;

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
