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
--! 0.1 | mc | 13.07.2011 | File creation and Doxygen comments
--!
--! @author
--! mc : Matthieu Cattin, CERN (BE-CO-HT)
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- GNU LESSER GENERAL PUBLIC LICENSE
--------------------------------------------------------------------------------
-- This source file is free software; you can redistribute it and/or modify it
-- under the terms of the GNU Lesser General Public License as published by the
-- Free Software Foundation; either version 2.1 of the License, or (at your
-- option) any later version. This source is distributed in the hope that it
-- will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
-- of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU Lesser General Public License for more details. You should have
-- received a copy of the GNU Lesser General Public License along with this
-- source; if not, download it from http://www.gnu.org/licenses/lgpl-2.1.html
--------------------------------------------------------------------------------

--==============================================================================
--! Entity declaration for ddr3_ctrl
--==============================================================================
entity ddr3_ctrl is

  generic(
    --! Bank and port size selection
    g_BANK_PORT_SELECT   : string  := "BANK3_32B_32B";
    --! Core's clock period in ps
    g_MEMCLK_PERIOD      : integer := 3000;
    --! If TRUE, uses Xilinx calibration core (Input term, DQS centering)
    g_CALIB_SOFT_IP      : string  := "TRUE";
    --! User ports addresses maping (BANK_ROW_COLUMN or ROW_BANK_COLUMN)
    g_MEM_ADDR_ORDER     : string  := "ROW_BANK_COLUMN";
    --! Simulation mode
    g_SIMULATION         : string  := "FALSE";
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
    --! Port 0 byte address width
    g_P0_BYTE_ADDR_WIDTH : integer := 30;
    --! Wishbone port 1 data mask size (8-bit granularity)
    g_P1_MASK_SIZE       : integer := 4;
    --! Wishbone port 1 data width
    g_P1_DATA_PORT_SIZE  : integer := 32;
    --! Port 1 byte address width
    g_P1_BYTE_ADDR_WIDTH : integer := 30
    );

  port(
    ----------------------------------------------------------------------------
    -- Clock, control and status
    ----------------------------------------------------------------------------
    --! Clock input
    clk_i    : in  std_logic;
    --! Reset input (active low)
    rst_n_i  : in  std_logic;
    --! Status output
    status_o : out std_logic_vector(31 downto 0);

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
    wb0_addr_i  : in  std_logic_vector(31 downto 0);
    --! Wishbone bus data input
    wb0_data_i  : in  std_logic_vector(g_P0_DATA_PORT_SIZE - 1 downto 0);
    --! Wishbone bus data output
    wb0_data_o  : out std_logic_vector(g_P0_DATA_PORT_SIZE - 1 downto 0);
    --! Wishbone bus acknowledge
    wb0_ack_o   : out std_logic;
    --! Wishbone bus stall (for pipelined mode)
    wb0_stall_o : out std_logic;

    ----------------------------------------------------------------------------
    -- Status - Port 0
    ----------------------------------------------------------------------------
    --! Command FIFO empty
    p0_cmd_empty_o   : out std_logic;
    --! Command FIFO full
    p0_cmd_full_o    : out std_logic;
    --! Read FIFO full
    p0_rd_full_o     : out std_logic;
    --! Read FIFO empty
    p0_rd_empty_o    : out std_logic;
    --! Read FIFO count
    p0_rd_count_o    : out std_logic_vector(6 downto 0);
    --! Read FIFO overflow
    p0_rd_overflow_o : out std_logic;
    --! Read FIFO error (pointers unsynchronized, reset required)
    p0_rd_error_o    : out std_logic;
    --! Write FIFO full
    p0_wr_full_o     : out std_logic;
    --! Write FIFO empty
    p0_wr_empty_o    : out std_logic;
    --! Write FIFO count
    p0_wr_count_o    : out std_logic_vector(6 downto 0);
    --! Write FIFO underrun
    p0_wr_underrun_o : out std_logic;
    --! Write FIFO error (pointers unsynchronized, reset required)
    p0_wr_error_o    : out std_logic;

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
    wb1_addr_i  : in  std_logic_vector(31 downto 0);
    --! Wishbone bus data input
    wb1_data_i  : in  std_logic_vector(g_P1_DATA_PORT_SIZE - 1 downto 0);
    --! Wishbone bus data output
    wb1_data_o  : out std_logic_vector(g_P1_DATA_PORT_SIZE - 1 downto 0);
    --! Wishbone bus acknowledge
    wb1_ack_o   : out std_logic;
    --! Wishbone bus stall (for pipelined mode)
    wb1_stall_o : out std_logic;

    ----------------------------------------------------------------------------
    -- Status - Port 1
    ----------------------------------------------------------------------------
    --! Command FIFO empty
    p1_cmd_empty_o   : out std_logic;
    --! Command FIFO full
    p1_cmd_full_o    : out std_logic;
    --! Read FIFO full
    p1_rd_full_o     : out std_logic;
    --! Read FIFO empty
    p1_rd_empty_o    : out std_logic;
    --! Read FIFO count
    p1_rd_count_o    : out std_logic_vector(6 downto 0);
    --! Read FIFO overflow
    p1_rd_overflow_o : out std_logic;
    --! Read FIFO error (pointers unsynchronized, reset required)
    p1_rd_error_o    : out std_logic;
    --! Write FIFO full
    p1_wr_full_o     : out std_logic;
    --! Write FIFO empty
    p1_wr_empty_o    : out std_logic;
    --! Write FIFO count
    p1_wr_count_o    : out std_logic_vector(6 downto 0);
    --! Write FIFO underrun
    p1_wr_underrun_o : out std_logic;
    --! Write FIFO error (pointers unsynchronized, reset required)
    p1_wr_error_o    : out std_logic
    );

end entity ddr3_ctrl;



--==============================================================================
--! Architecure declaration for ddr3_ctrl
--==============================================================================
architecture rtl of ddr3_ctrl is

  ------------------------------------------------------------------------------
  -- Components declaration
  ------------------------------------------------------------------------------
  component ddr3_ctrl_wb
    generic(
      g_BYTE_ADDR_WIDTH : integer := 30;
      g_MASK_SIZE       : integer := 4;
      g_DATA_PORT_SIZE  : integer := 32
      );
    port(
      rst_n_i             : in  std_logic;
      ddr_cmd_clk_o       : out std_logic;
      ddr_cmd_en_o        : out std_logic;
      ddr_cmd_instr_o     : out std_logic_vector(2 downto 0);
      ddr_cmd_bl_o        : out std_logic_vector(5 downto 0);
      ddr_cmd_byte_addr_o : out std_logic_vector(g_BYTE_ADDR_WIDTH - 1 downto 0);
      ddr_cmd_empty_i     : in  std_logic;
      ddr_cmd_full_i      : in  std_logic;
      ddr_wr_clk_o        : out std_logic;
      ddr_wr_en_o         : out std_logic;
      ddr_wr_mask_o       : out std_logic_vector(g_MASK_SIZE - 1 downto 0);
      ddr_wr_data_o       : out std_logic_vector(g_DATA_PORT_SIZE - 1 downto 0);
      ddr_wr_full_i       : in  std_logic;
      ddr_wr_empty_i      : in  std_logic;
      ddr_wr_count_i      : in  std_logic_vector(6 downto 0);
      ddr_wr_underrun_i   : in  std_logic;
      ddr_wr_error_i      : in  std_logic;
      ddr_rd_clk_o        : out std_logic;
      ddr_rd_en_o         : out std_logic;
      ddr_rd_data_i       : in  std_logic_vector(g_DATA_PORT_SIZE - 1 downto 0);
      ddr_rd_full_i       : in  std_logic;
      ddr_rd_empty_i      : in  std_logic;
      ddr_rd_count_i      : in  std_logic_vector(6 downto 0);
      ddr_rd_overflow_i   : in  std_logic;
      ddr_rd_error_i      : in  std_logic;
      wb_clk_i            : in  std_logic;
      wb_sel_i            : in  std_logic_vector(g_MASK_SIZE - 1 downto 0);
      wb_cyc_i            : in  std_logic;
      wb_stb_i            : in  std_logic;
      wb_we_i             : in  std_logic;
      wb_addr_i           : in  std_logic_vector(31 downto 0);
      wb_data_i           : in  std_logic_vector(g_DATA_PORT_SIZE - 1 downto 0);
      wb_data_o           : out std_logic_vector(g_DATA_PORT_SIZE - 1 downto 0);
      wb_ack_o            : out std_logic;
      wb_stall_o          : out std_logic
      );
  end component ddr3_ctrl_wb;

  component ddr3_ctrl_wrapper
    generic(
      g_BANK_PORT_SELECT   : string  := "BANK3_32B_32B";
      g_MEMCLK_PERIOD      : integer := 3000;
      g_CALIB_SOFT_IP      : string  := "TRUE";
      g_MEM_ADDR_ORDER     : string  := "ROW_BANK_COLUMN";
      g_SIMULATION         : string  := "FALSE";
      g_NUM_DQ_PINS        : integer := 16;
      g_MEM_ADDR_WIDTH     : integer := 14;
      g_MEM_BANKADDR_WIDTH : integer := 3;
      g_P0_MASK_SIZE       : integer := 4;
      g_P0_DATA_PORT_SIZE  : integer := 32;
      g_P0_BYTE_ADDR_WIDTH : integer := 30;
      g_P1_MASK_SIZE       : integer := 4;
      g_P1_DATA_PORT_SIZE  : integer := 32;
      g_P1_BYTE_ADDR_WIDTH : integer := 30
      );
    port(
      clk_i              : in    std_logic;
      rst_n_i            : in    std_logic;
      calib_done_o       : out   std_logic;
      ddr3_dq_b          : inout std_logic_vector(g_NUM_DQ_PINS-1 downto 0);
      ddr3_a_o           : out   std_logic_vector(g_MEM_ADDR_WIDTH-1 downto 0);
      ddr3_ba_o          : out   std_logic_vector(g_MEM_BANKADDR_WIDTH-1 downto 0);
      ddr3_ras_n_o       : out   std_logic;
      ddr3_cas_n_o       : out   std_logic;
      ddr3_we_n_o        : out   std_logic;
      ddr3_odt_o         : out   std_logic;
      ddr3_rst_n_o       : out   std_logic;
      ddr3_cke_o         : out   std_logic;
      ddr3_dm_o          : out   std_logic;
      ddr3_udm_o         : out   std_logic;
      ddr3_dqs_p_b       : inout std_logic;
      ddr3_dqs_n_b       : inout std_logic;
      ddr3_udqs_p_b      : inout std_logic;
      ddr3_udqs_n_b      : inout std_logic;
      ddr3_clk_p_o       : out   std_logic;
      ddr3_clk_n_o       : out   std_logic;
      ddr3_rzq_b         : inout std_logic;
      ddr3_zio_b         : inout std_logic;
      p0_cmd_clk_i       : in    std_logic;
      p0_cmd_en_i        : in    std_logic;
      p0_cmd_instr_i     : in    std_logic_vector(2 downto 0);
      p0_cmd_bl_i        : in    std_logic_vector(5 downto 0);
      p0_cmd_byte_addr_i : in    std_logic_vector(g_P0_BYTE_ADDR_WIDTH - 1 downto 0);
      p0_cmd_empty_o     : out   std_logic;
      p0_cmd_full_o      : out   std_logic;
      p0_wr_clk_i        : in    std_logic;
      p0_wr_en_i         : in    std_logic;
      p0_wr_mask_i       : in    std_logic_vector(g_P0_MASK_SIZE - 1 downto 0);
      p0_wr_data_i       : in    std_logic_vector(g_P0_DATA_PORT_SIZE - 1 downto 0);
      p0_wr_full_o       : out   std_logic;
      p0_wr_empty_o      : out   std_logic;
      p0_wr_count_o      : out   std_logic_vector(6 downto 0);
      p0_wr_underrun_o   : out   std_logic;
      p0_wr_error_o      : out   std_logic;
      p0_rd_clk_i        : in    std_logic;
      p0_rd_en_i         : in    std_logic;
      p0_rd_data_o       : out   std_logic_vector(g_P0_DATA_PORT_SIZE - 1 downto 0);
      p0_rd_full_o       : out   std_logic;
      p0_rd_empty_o      : out   std_logic;
      p0_rd_count_o      : out   std_logic_vector(6 downto 0);
      p0_rd_overflow_o   : out   std_logic;
      p0_rd_error_o      : out   std_logic;
      p1_cmd_clk_i       : in    std_logic;
      p1_cmd_en_i        : in    std_logic;
      p1_cmd_instr_i     : in    std_logic_vector(2 downto 0);
      p1_cmd_bl_i        : in    std_logic_vector(5 downto 0);
      p1_cmd_byte_addr_i : in    std_logic_vector(g_P1_BYTE_ADDR_WIDTH - 1 downto 0);
      p1_cmd_empty_o     : out   std_logic;
      p1_cmd_full_o      : out   std_logic;
      p1_wr_clk_i        : in    std_logic;
      p1_wr_en_i         : in    std_logic;
      p1_wr_mask_i       : in    std_logic_vector(g_P1_MASK_SIZE - 1 downto 0);
      p1_wr_data_i       : in    std_logic_vector(g_P1_DATA_PORT_SIZE - 1 downto 0);
      p1_wr_full_o       : out   std_logic;
      p1_wr_empty_o      : out   std_logic;
      p1_wr_count_o      : out   std_logic_vector(6 downto 0);
      p1_wr_underrun_o   : out   std_logic;
      p1_wr_error_o      : out   std_logic;
      p1_rd_clk_i        : in    std_logic;
      p1_rd_en_i         : in    std_logic;
      p1_rd_data_o       : out   std_logic_vector(g_P1_DATA_PORT_SIZE - 1 downto 0);
      p1_rd_full_o       : out   std_logic;
      p1_rd_empty_o      : out   std_logic;
      p1_rd_count_o      : out   std_logic_vector(6 downto 0);
      p1_rd_overflow_o   : out   std_logic;
      p1_rd_error_o      : out   std_logic
      );
  end component ddr3_ctrl_wrapper;


  ------------------------------------------------------------------------------
  -- Signals declaration
  ------------------------------------------------------------------------------
  signal p0_cmd_clk       : std_logic;
  signal p0_cmd_en        : std_logic;
  signal p0_cmd_instr     : std_logic_vector(2 downto 0);
  signal p0_cmd_bl        : std_logic_vector(5 downto 0);
  signal p0_cmd_byte_addr : std_logic_vector(g_P0_BYTE_ADDR_WIDTH - 1 downto 0);
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

  signal p1_cmd_clk       : std_logic;
  signal p1_cmd_en        : std_logic;
  signal p1_cmd_instr     : std_logic_vector(2 downto 0);
  signal p1_cmd_bl        : std_logic_vector(5 downto 0);
  signal p1_cmd_byte_addr : std_logic_vector(g_P1_BYTE_ADDR_WIDTH - 1 downto 0);
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


  ------------------------------------------------------------------------------
  -- PORT 0
  ------------------------------------------------------------------------------
  cmp_ddr3_ctrl_wb_0 : ddr3_ctrl_wb
    generic map(
      g_BYTE_ADDR_WIDTH => g_P0_BYTE_ADDR_WIDTH,
      g_MASK_SIZE       => g_P0_MASK_SIZE,
      g_DATA_PORT_SIZE  => g_P0_DATA_PORT_SIZE
      )
    port map(
      rst_n_i             => rst_n_i,
      ddr_cmd_clk_o       => p0_cmd_clk,
      ddr_cmd_en_o        => p0_cmd_en,
      ddr_cmd_instr_o     => p0_cmd_instr,
      ddr_cmd_bl_o        => p0_cmd_bl,
      ddr_cmd_byte_addr_o => p0_cmd_byte_addr,
      ddr_cmd_empty_i     => p0_cmd_empty,
      ddr_cmd_full_i      => p0_cmd_full,
      ddr_wr_clk_o        => p0_wr_clk,
      ddr_wr_en_o         => p0_wr_en,
      ddr_wr_mask_o       => p0_wr_mask,
      ddr_wr_data_o       => p0_wr_data,
      ddr_wr_full_i       => p0_wr_full,
      ddr_wr_empty_i      => p0_wr_empty,
      ddr_wr_count_i      => p0_wr_count,
      ddr_wr_underrun_i   => p0_wr_underrun,
      ddr_wr_error_i      => p0_wr_error,
      ddr_rd_clk_o        => p0_rd_clk,
      ddr_rd_en_o         => p0_rd_en,
      ddr_rd_data_i       => p0_rd_data,
      ddr_rd_full_i       => p0_rd_full,
      ddr_rd_empty_i      => p0_rd_empty,
      ddr_rd_count_i      => p0_rd_count,
      ddr_rd_overflow_i   => p0_rd_overflow,
      ddr_rd_error_i      => p0_rd_error,
      wb_clk_i            => wb0_clk_i,
      wb_sel_i            => wb0_sel_i,
      wb_cyc_i            => wb0_cyc_i,
      wb_stb_i            => wb0_stb_i,
      wb_we_i             => wb0_we_i,
      wb_addr_i           => wb0_addr_i,
      wb_data_i           => wb0_data_i,
      wb_data_o           => wb0_data_o,
      wb_ack_o            => wb0_ack_o,
      wb_stall_o          => wb0_stall_o
      );

  ------------------------------------------------------------------------------
  -- PORT 1
  ------------------------------------------------------------------------------
  cmp_ddr3_ctrl_wb_1 : ddr3_ctrl_wb
    generic map(
      g_BYTE_ADDR_WIDTH => g_P1_BYTE_ADDR_WIDTH,
      g_MASK_SIZE       => g_P1_MASK_SIZE,
      g_DATA_PORT_SIZE  => g_P1_DATA_PORT_SIZE
      )
    port map(
      rst_n_i             => rst_n_i,
      ddr_cmd_clk_o       => p1_cmd_clk,
      ddr_cmd_en_o        => p1_cmd_en,
      ddr_cmd_instr_o     => p1_cmd_instr,
      ddr_cmd_bl_o        => p1_cmd_bl,
      ddr_cmd_byte_addr_o => p1_cmd_byte_addr,
      ddr_cmd_empty_i     => p1_cmd_empty,
      ddr_cmd_full_i      => p1_cmd_full,
      ddr_wr_clk_o        => p1_wr_clk,
      ddr_wr_en_o         => p1_wr_en,
      ddr_wr_mask_o       => p1_wr_mask,
      ddr_wr_data_o       => p1_wr_data,
      ddr_wr_full_i       => p1_wr_full,
      ddr_wr_empty_i      => p1_wr_empty,
      ddr_wr_count_i      => p1_wr_count,
      ddr_wr_underrun_i   => p1_wr_underrun,
      ddr_wr_error_i      => p1_wr_error,
      ddr_rd_clk_o        => p1_rd_clk,
      ddr_rd_en_o         => p1_rd_en,
      ddr_rd_data_i       => p1_rd_data,
      ddr_rd_full_i       => p1_rd_full,
      ddr_rd_empty_i      => p1_rd_empty,
      ddr_rd_count_i      => p1_rd_count,
      ddr_rd_overflow_i   => p1_rd_overflow,
      ddr_rd_error_i      => p1_rd_error,
      wb_clk_i            => wb1_clk_i,
      wb_sel_i            => wb1_sel_i,
      wb_cyc_i            => wb1_cyc_i,
      wb_stb_i            => wb1_stb_i,
      wb_we_i             => wb1_we_i,
      wb_addr_i           => wb1_addr_i,
      wb_data_i           => wb1_data_i,
      wb_data_o           => wb1_data_o,
      wb_ack_o            => wb1_ack_o,
      wb_stall_o          => wb1_stall_o
      );

  ------------------------------------------------------------------------------
  -- DDR controller wrapper
  ------------------------------------------------------------------------------
  cmp_ddr3_ctrl_wrapper : ddr3_ctrl_wrapper
    generic map(
      g_BANK_PORT_SELECT   => g_BANK_PORT_SELECT,
      g_MEMCLK_PERIOD      => g_MEMCLK_PERIOD,
      g_CALIB_SOFT_IP      => g_CALIB_SOFT_IP,
      g_MEM_ADDR_ORDER     => g_MEM_ADDR_ORDER,
      g_SIMULATION         => g_SIMULATION,
      g_NUM_DQ_PINS        => g_NUM_DQ_PINS,
      g_MEM_ADDR_WIDTH     => g_MEM_ADDR_WIDTH,
      g_MEM_BANKADDR_WIDTH => g_MEM_BANKADDR_WIDTH,
      g_P0_MASK_SIZE       => g_P0_MASK_SIZE,
      g_P0_DATA_PORT_SIZE  => g_P0_DATA_PORT_SIZE,
      g_P0_BYTE_ADDR_WIDTH => g_P0_BYTE_ADDR_WIDTH,
      g_P1_MASK_SIZE       => g_P1_MASK_SIZE,
      g_P1_DATA_PORT_SIZE  => g_P1_DATA_PORT_SIZE,
      g_P1_BYTE_ADDR_WIDTH => g_P1_BYTE_ADDR_WIDTH
      )
    port map(
      clk_i   => clk_i,
      rst_n_i => rst_n_i,

      calib_done_o  => status_o(0),
      ddr3_dq_b     => ddr3_dq_b,
      ddr3_a_o      => ddr3_a_o,
      ddr3_ba_o     => ddr3_ba_o,
      ddr3_ras_n_o  => ddr3_ras_n_o,
      ddr3_cas_n_o  => ddr3_cas_n_o,
      ddr3_we_n_o   => ddr3_we_n_o,
      ddr3_odt_o    => ddr3_odt_o,
      ddr3_rst_n_o  => ddr3_rst_n_o,
      ddr3_cke_o    => ddr3_cke_o,
      ddr3_dm_o     => ddr3_dm_o,
      ddr3_udm_o    => ddr3_udm_o,
      ddr3_dqs_p_b  => ddr3_dqs_p_b,
      ddr3_dqs_n_b  => ddr3_dqs_n_b,
      ddr3_udqs_p_b => ddr3_udqs_p_b,
      ddr3_udqs_n_b => ddr3_udqs_n_b,
      ddr3_clk_p_o  => ddr3_clk_p_o,
      ddr3_clk_n_o  => ddr3_clk_n_o,
      ddr3_rzq_b    => ddr3_rzq_b,
      ddr3_zio_b    => ddr3_zio_b,

      p0_cmd_clk_i       => p0_cmd_clk,
      p0_cmd_en_i        => p0_cmd_en,
      p0_cmd_instr_i     => p0_cmd_instr,
      p0_cmd_bl_i        => p0_cmd_bl,
      p0_cmd_byte_addr_i => p0_cmd_byte_addr,
      p0_cmd_empty_o     => p0_cmd_empty,
      p0_cmd_full_o      => p0_cmd_full,
      p0_wr_clk_i        => p0_wr_clk,
      p0_wr_en_i         => p0_wr_en,
      p0_wr_mask_i       => p0_wr_mask,
      p0_wr_data_i       => p0_wr_data,
      p0_wr_full_o       => p0_wr_full,
      p0_wr_empty_o      => p0_wr_empty,
      p0_wr_count_o      => p0_wr_count,
      p0_wr_underrun_o   => p0_wr_underrun,
      p0_wr_error_o      => p0_wr_error,
      p0_rd_clk_i        => p0_rd_clk,
      p0_rd_en_i         => p0_rd_en,
      p0_rd_data_o       => p0_rd_data,
      p0_rd_full_o       => p0_rd_full,
      p0_rd_empty_o      => p0_rd_empty,
      p0_rd_count_o      => p0_rd_count,
      p0_rd_overflow_o   => p0_rd_overflow,
      p0_rd_error_o      => p0_rd_error,

      p1_cmd_clk_i       => p1_cmd_clk,
      p1_cmd_en_i        => p1_cmd_en,
      p1_cmd_instr_i     => p1_cmd_instr,
      p1_cmd_bl_i        => p1_cmd_bl,
      p1_cmd_byte_addr_i => p1_cmd_byte_addr,
      p1_cmd_empty_o     => p1_cmd_empty,
      p1_cmd_full_o      => p1_cmd_full,
      p1_wr_clk_i        => p1_wr_clk,
      p1_wr_en_i         => p1_wr_en,
      p1_wr_mask_i       => p1_wr_mask,
      p1_wr_data_i       => p1_wr_data,
      p1_wr_full_o       => p1_wr_full,
      p1_wr_empty_o      => p1_wr_empty,
      p1_wr_count_o      => p1_wr_count,
      p1_wr_underrun_o   => p1_wr_underrun,
      p1_wr_error_o      => p1_wr_error,
      p1_rd_clk_i        => p1_rd_clk,
      p1_rd_en_i         => p1_rd_en,
      p1_rd_data_o       => p1_rd_data,
      p1_rd_full_o       => p1_rd_full,
      p1_rd_empty_o      => p1_rd_empty,
      p1_rd_count_o      => p1_rd_count,
      p1_rd_overflow_o   => p1_rd_overflow,
      p1_rd_error_o      => p1_rd_error
      );

  -- Status ports assignment
  p0_cmd_full_o    <= p0_cmd_full;
  p0_cmd_empty_o   <= p0_cmd_empty;
  p0_rd_full_o     <= p0_rd_full;
  p0_rd_empty_o    <= p0_rd_empty;
  p0_rd_count_o    <= p0_rd_count;
  p0_rd_overflow_o <= p0_rd_overflow;
  p0_rd_error_o    <= p0_rd_error;
  p0_wr_full_o     <= p0_wr_full;
  p0_wr_empty_o    <= p0_wr_empty;
  p0_wr_count_o    <= p0_wr_count;
  p0_wr_underrun_o <= p0_wr_underrun;
  p0_wr_error_o    <= p0_wr_error;

  p1_cmd_full_o    <= p1_cmd_full;
  p1_cmd_empty_o   <= p1_cmd_empty;
  p1_rd_full_o     <= p1_rd_full;
  p1_rd_empty_o    <= p1_rd_empty;
  p1_rd_count_o    <= p1_rd_count;
  p1_rd_overflow_o <= p1_rd_overflow;
  p1_rd_error_o    <= p1_rd_error;
  p1_wr_full_o     <= p1_wr_full;
  p1_wr_empty_o    <= p1_wr_empty;
  p1_wr_count_o    <= p1_wr_count;
  p1_wr_underrun_o <= p1_wr_underrun;
  p1_wr_error_o    <= p1_wr_error;


end architecture rtl;
--==============================================================================
--! Architecure end
--==============================================================================

