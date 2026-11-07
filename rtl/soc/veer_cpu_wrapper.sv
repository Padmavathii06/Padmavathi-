// =============================================================================
// VeeR EL2 CPU Wrapper with AXI4 64-to-32 Width Conversion
// =============================================================================
// Module: veer_cpu_wrapper
//
// Description:
//   Instantiates the official Western Digital / CHIPS Alliance VeeR EL2 CPU
//   (`el2_veer_wrapper`) configured with snapshot `default` (reset vector 0x1000_0000,
//   DCCM=0, ICCM=0).
//   Because VeeR EL2's native AXI4 IFU and LSU master ports are 64-bit, this wrapper
//   integrates two AXI4 width adapters (axi_adapter from verilog-axi) to convert
//   both IFU and LSU buses to the 32-bit AXI4 fabric used by the SoC interconnect.
//
// Target Simulators:
//   Synopsys VCS U-2023.03+ (college environment target per Makefile)
// =============================================================================

`timescale 1ns / 1ps

import el2_pkg::*;

module veer_cpu_wrapper #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 8,
    `include "el2_param.vh"
) (
    input  wire                   clk,
    input  wire                   rst_l,
    input  wire                   dbg_rst_l,

    // 32-bit AXI Manager 0: CPU Instruction Fetch Unit (IFU)
    output wire [ID_WIDTH-1:0]     m0_ifu_arid,
    output wire [ADDR_WIDTH-1:0]   m0_ifu_araddr,
    output wire [7:0]              m0_ifu_arlen,
    output wire [2:0]              m0_ifu_arsize,
    output wire [1:0]              m0_ifu_arburst,
    output wire                    m0_ifu_arlock,
    output wire [3:0]              m0_ifu_arcache,
    output wire [2:0]              m0_ifu_arprot,
    output wire [3:0]              m0_ifu_arqos,
    output wire [3:0]              m0_ifu_arregion,
    output wire                    m0_ifu_aruser,
    output wire                    m0_ifu_arvalid,
    input  wire                    m0_ifu_arready,
    input  wire [ID_WIDTH-1:0]     m0_ifu_rid,
    input  wire [DATA_WIDTH-1:0]   m0_ifu_rdata,
    input  wire [1:0]              m0_ifu_rresp,
    input  wire                    m0_ifu_rlast,
    input  wire                    m0_ifu_ruser,
    input  wire                    m0_ifu_rvalid,
    output wire                    m0_ifu_rready,

    // 32-bit AXI Manager 1: CPU Load/Store Unit (LSU)
    output wire [ID_WIDTH-1:0]     m1_lsu_awid,
    output wire [ADDR_WIDTH-1:0]   m1_lsu_awaddr,
    output wire [7:0]              m1_lsu_awlen,
    output wire [2:0]              m1_lsu_awsize,
    output wire [1:0]              m1_lsu_awburst,
    output wire                    m1_lsu_awlock,
    output wire [3:0]              m1_lsu_awcache,
    output wire [2:0]              m1_lsu_awprot,
    output wire [3:0]              m1_lsu_awqos,
    output wire [3:0]              m1_lsu_awregion,
    output wire                    m1_lsu_awuser,
    output wire                    m1_lsu_awvalid,
    input  wire                    m1_lsu_awready,
    output wire [DATA_WIDTH-1:0]   m1_lsu_wdata,
    output wire [DATA_WIDTH/8-1:0] m1_lsu_wstrb,
    output wire                    m1_lsu_wlast,
    output wire                    m1_lsu_wuser,
    output wire                    m1_lsu_wvalid,
    input  wire                    m1_lsu_wready,
    input  wire [ID_WIDTH-1:0]     m1_lsu_bid,
    input  wire [1:0]              m1_lsu_bresp,
    input  wire                    m1_lsu_buser,
    input  wire                    m1_lsu_bvalid,
    output wire                    m1_lsu_bready,
    output wire [ID_WIDTH-1:0]     m1_lsu_arid,
    output wire [ADDR_WIDTH-1:0]   m1_lsu_araddr,
    output wire [7:0]              m1_lsu_arlen,
    output wire [2:0]              m1_lsu_arsize,
    output wire [1:0]              m1_lsu_arburst,
    output wire                    m1_lsu_arlock,
    output wire [3:0]              m1_lsu_arcache,
    output wire [2:0]              m1_lsu_arprot,
    output wire [3:0]              m1_lsu_arqos,
    output wire [3:0]              m1_lsu_arregion,
    output wire                    m1_lsu_aruser,
    output wire                    m1_lsu_arvalid,
    input  wire                    m1_lsu_arready,
    input  wire [ID_WIDTH-1:0]     m1_lsu_rid,
    input  wire [DATA_WIDTH-1:0]   m1_lsu_rdata,
    input  wire [1:0]              m1_lsu_rresp,
    input  wire                    m1_lsu_rlast,
    input  wire                    m1_lsu_ruser,
    input  wire                    m1_lsu_rvalid,
    output wire                    m1_lsu_rready,

    // Interrupts & Controls
    input  wire                    timer_int,
    input  wire                    soft_int,
    input  wire [31:1]             extintsrc_req
);

    // 64-bit internal signals directly from VeeR EL2 wrapper
    wire [ID_WIDTH-1:0]   veer_ifu_arid;
    wire [31:0]           veer_ifu_araddr;
    wire [7:0]            veer_ifu_arlen;
    wire [2:0]            veer_ifu_arsize;
    wire [1:0]            veer_ifu_arburst;
    wire                  veer_ifu_arlock;
    wire [3:0]            veer_ifu_arcache;
    wire [2:0]            veer_ifu_arprot;
    wire [3:0]            veer_ifu_arqos;
    wire                  veer_ifu_arvalid;
    wire                  veer_ifu_arready;
    wire [ID_WIDTH-1:0]   veer_ifu_rid;
    wire [63:0]           veer_ifu_rdata;
    wire [1:0]            veer_ifu_rresp;
    wire                  veer_ifu_rlast;
    wire                  veer_ifu_rvalid;
    wire                  veer_ifu_rready;

    wire [ID_WIDTH-1:0]   veer_lsu_awid;
    wire [31:0]           veer_lsu_awaddr;
    wire [7:0]            veer_lsu_awlen;
    wire [2:0]            veer_lsu_awsize;
    wire [1:0]            veer_lsu_awburst;
    wire                  veer_lsu_awlock;
    wire [3:0]            veer_lsu_awcache;
    wire [2:0]            veer_lsu_awprot;
    wire [3:0]            veer_lsu_awqos;
    wire [3:0]            veer_lsu_awregion;
    wire                  veer_lsu_awvalid;
    wire                  veer_lsu_awready;
    wire [63:0]           veer_lsu_wdata;
    wire [7:0]            veer_lsu_wstrb;
    wire                  veer_lsu_wlast;
    wire                  veer_lsu_wvalid;
    wire                  veer_lsu_wready;
    wire [ID_WIDTH-1:0]   veer_lsu_bid;
    wire [1:0]            veer_lsu_bresp;
    wire                  veer_lsu_bvalid;
    wire                  veer_lsu_bready;
    wire [ID_WIDTH-1:0]   veer_lsu_arid;
    wire [31:0]           veer_lsu_araddr;
    wire [7:0]            veer_lsu_arlen;
    wire [2:0]            veer_lsu_arsize;
    wire [1:0]            veer_lsu_arburst;
    wire                  veer_lsu_arlock;
    wire [3:0]            veer_lsu_arcache;
    wire [2:0]            veer_lsu_arprot;
    wire [3:0]            veer_lsu_arqos;
    wire [3:0]            veer_lsu_arregion;
    wire                  veer_lsu_arvalid;
    wire                  veer_lsu_arready;
    wire [ID_WIDTH-1:0]   veer_lsu_rid;
    wire [63:0]           veer_lsu_rdata;
    wire [1:0]            veer_lsu_rresp;
    wire                  veer_lsu_rlast;
    wire                  veer_lsu_rvalid;
    wire                  veer_lsu_rready;

    // Reset vector: 0x1000_0000 (Boot ROM base address).
    // el2_veer_wrapper takes rst_vec[31:1] = 31'h0800_0000 (bit 0 implicit 0)
    localparam [31:1] RESET_VECTOR = 31'h0800_0000;

    // Memory export interface instance required by el2_veer_wrapper
    el2_mem_if el2_mem_export();

`include "icache_macros.svh"

    // Tie-off unused non-packed ICache signals
    `EL2_TIE_OFF_NON_PACKED

    // DCCM SRAM Banks (4 banks of 4096x39)
    wire [38:0] dccm_bank_fdout [pt.DCCM_NUM_BANKS-1:0];
    for (genvar di=0; di<pt.DCCM_NUM_BANKS; di++) begin: gen_dccm
        ram_4096x39 dccm_bank (
            .CLK  (el2_mem_export.clk),
            .ME   (el2_mem_export.dccm_clken[di]),
            .WE   (el2_mem_export.dccm_wren_bank[di]),
            .ADR  (el2_mem_export.dccm_addr_bank[di]),
            .D    ({el2_mem_export.dccm_wr_ecc_bank[di], el2_mem_export.dccm_wr_data_bank[di]}),
            .Q    (dccm_bank_fdout[di]),
            .ROP  (),
            .TEST1(1'b0),
            .RME  (1'b0),
            .RM   (4'b0000),
            .LS   (1'b0),
            .DS   (1'b0),
            .SD   (1'b0),
            .TEST_RNM(1'b0),
            .BC1  (1'b0),
            .BC2  (1'b0)
        );
        assign el2_mem_export.dccm_bank_dout[di] = dccm_bank_fdout[di][31:0];
        assign el2_mem_export.dccm_bank_ecc[di]  = dccm_bank_fdout[di][38:32];
    end

    // ICCM SRAM Banks (4 banks of 4096x39)
    wire [38:0] iccm_bank_fdout [pt.ICCM_NUM_BANKS-1:0];
    for (genvar ii=0; ii<pt.ICCM_NUM_BANKS; ii++) begin: gen_iccm
        ram_4096x39 iccm_bank (
            .CLK  (el2_mem_export.clk),
            .ME   (el2_mem_export.iccm_clken[ii]),
            .WE   (el2_mem_export.iccm_wren_bank[ii]),
            .ADR  (el2_mem_export.iccm_addr_bank[ii]),
            .D    ({el2_mem_export.iccm_bank_wr_ecc[ii], el2_mem_export.iccm_bank_wr_data[ii]}),
            .Q    (iccm_bank_fdout[ii]),
            .ROP  (),
            .TEST1(1'b0),
            .RME  (1'b0),
            .RM   (4'b0000),
            .LS   (1'b0),
            .DS   (1'b0),
            .SD   (1'b0),
            .TEST_RNM(1'b0),
            .BC1  (1'b0),
            .BC2  (1'b0)
        );
        assign el2_mem_export.iccm_bank_dout[ii] = iccm_bank_fdout[ii][31:0];
        assign el2_mem_export.iccm_bank_ecc[ii]  = iccm_bank_fdout[ii][38:32];
    end

    // ICache Data Packed SRAMs (2 banks of 512x142)
    for (genvar k=0; k<pt.ICACHE_BANKS_WAY; k++) begin: BANKS_WAY
        `EL2_PACKED_IC_DATA_SRAM(512,142,71,k)
    end

    // ICache Tag Packed SRAM (1 bank of 128x52)
    `EL2_IC_TAG_PACKED_SRAM(128,52)

    // Instantiate Genuine VeeR EL2 core
    el2_veer_wrapper u_cpu (
        .clk                    (clk),
        .rst_l                  (rst_l),
        .dbg_rst_l              (dbg_rst_l),
        .rst_vec                (RESET_VECTOR),
        .nmi_int                (1'b0),
        .nmi_vec                (31'd0),
        .jtag_id                (31'd0),

        // Trace (probes)
        .trace_rv_i_insn_ip     (),
        .trace_rv_i_address_ip  (),
        .trace_rv_i_valid_ip    (),
        .trace_rv_i_exception_ip(),
        .trace_rv_i_ecause_ip   (),
        .trace_rv_i_interrupt_ip(),
        .trace_rv_i_tval_ip     (),

        // LSU 64-bit AXI
        .lsu_axi_awvalid        (veer_lsu_awvalid),
        .lsu_axi_awready        (veer_lsu_awready),
        .lsu_axi_awid           (veer_lsu_awid),
        .lsu_axi_awaddr         (veer_lsu_awaddr),
        .lsu_axi_awregion       (veer_lsu_awregion),
        .lsu_axi_awlen          (veer_lsu_awlen),
        .lsu_axi_awsize         (veer_lsu_awsize),
        .lsu_axi_awburst        (veer_lsu_awburst),
        .lsu_axi_awlock         (veer_lsu_awlock),
        .lsu_axi_awcache        (veer_lsu_awcache),
        .lsu_axi_awprot         (veer_lsu_awprot),
        .lsu_axi_awqos          (veer_lsu_awqos),
        .lsu_axi_wvalid         (veer_lsu_wvalid),
        .lsu_axi_wready         (veer_lsu_wready),
        .lsu_axi_wdata          (veer_lsu_wdata),
        .lsu_axi_wstrb          (veer_lsu_wstrb),
        .lsu_axi_wlast          (veer_lsu_wlast),
        .lsu_axi_bvalid         (veer_lsu_bvalid),
        .lsu_axi_bready         (veer_lsu_bready),
        .lsu_axi_bresp          (veer_lsu_bresp),
        .lsu_axi_bid            (veer_lsu_bid),
        .lsu_axi_arvalid        (veer_lsu_arvalid),
        .lsu_axi_arready        (veer_lsu_arready),
        .lsu_axi_arid           (veer_lsu_arid),
        .lsu_axi_araddr         (veer_lsu_araddr),
        .lsu_axi_arregion       (veer_lsu_arregion),
        .lsu_axi_arlen          (veer_lsu_arlen),
        .lsu_axi_arsize         (veer_lsu_arsize),
        .lsu_axi_arburst        (veer_lsu_arburst),
        .lsu_axi_arlock         (veer_lsu_arlock),
        .lsu_axi_arcache        (veer_lsu_arcache),
        .lsu_axi_arprot         (veer_lsu_arprot),
        .lsu_axi_arqos          (veer_lsu_arqos),
        .lsu_axi_rvalid         (veer_lsu_rvalid),
        .lsu_axi_rready         (veer_lsu_rready),
        .lsu_axi_rid            (veer_lsu_rid),
        .lsu_axi_rdata          (veer_lsu_rdata),
        .lsu_axi_rresp          (veer_lsu_rresp),
        .lsu_axi_rlast          (veer_lsu_rlast),

        // IFU 64-bit AXI
        .ifu_axi_arvalid        (veer_ifu_arvalid),
        .ifu_axi_arready        (veer_ifu_arready),
        .ifu_axi_arid           (veer_ifu_arid),
        .ifu_axi_araddr         (veer_ifu_araddr),
        .ifu_axi_arlen          (veer_ifu_arlen),
        .ifu_axi_arsize         (veer_ifu_arsize),
        .ifu_axi_arburst        (veer_ifu_arburst),
        .ifu_axi_arlock         (veer_ifu_arlock),
        .ifu_axi_arcache        (veer_ifu_arcache),
        .ifu_axi_arprot         (veer_ifu_arprot),
        .ifu_axi_arqos          (veer_ifu_arqos),
        .ifu_axi_rvalid         (veer_ifu_rvalid),
        .ifu_axi_rready         (veer_ifu_rready),
        .ifu_axi_rid            (veer_ifu_rid),
        .ifu_axi_rdata          (veer_ifu_rdata),
        .ifu_axi_rresp          (veer_ifu_rresp),
        .ifu_axi_rlast          (veer_ifu_rlast),

        // Clock ratio / bus enables
        .lsu_bus_clk_en         (1'b1),
        .ifu_bus_clk_en         (1'b1),
        .dbg_bus_clk_en         (1'b1),
        .dma_bus_clk_en         (1'b1),

        // Interfaces & Interrupts
        .el2_icache_export      (el2_mem_export.veer_icache_src),
        .el2_mem_export         (el2_mem_export.veer_sram_src),
        .timer_int              (timer_int),
        .soft_int               (soft_int),
        .extintsrc_req          (extintsrc_req),
        .core_id                (28'd0),

        // Tie-offs for unused JTAG/debug ports
        .jtag_tck               (1'b0),
        .jtag_tms               (1'b0),
        .jtag_tdi               (1'b0),
        .jtag_trst_n            (1'b1),
        .jtag_tdo               (),
        .jtag_tdoEn             (),
        .mpc_debug_halt_req     (1'b0),
        .mpc_debug_run_req      (1'b0),
        .mpc_reset_run_req      (1'b1),
        .i_cpu_halt_req         (1'b0),
        .i_cpu_run_req          (1'b0),
        .scan_mode              (1'b0),
        .mbist_mode             (1'b0),

        // Tie-offs for unused IFU write channel
        .ifu_axi_awready        (1'b0),
        .ifu_axi_wready         (1'b0),
        .ifu_axi_bvalid         (1'b0),
        .ifu_axi_bresp          (2'b00),
        .ifu_axi_bid            ('0),

        // Tie-offs for unused System Bus (SB) AXI port
        .sb_axi_awready         (1'b0),
        .sb_axi_wready          (1'b0),
        .sb_axi_bvalid          (1'b0),
        .sb_axi_bresp           (2'b00),
        .sb_axi_bid             ('0),
        .sb_axi_arready         (1'b0),
        .sb_axi_rvalid          (1'b0),
        .sb_axi_rid             ('0),
        .sb_axi_rdata           (64'd0),
        .sb_axi_rresp           (2'b00),
        .sb_axi_rlast           (1'b0),

        // Tie-offs for unused DMA slave AXI port
        .dma_axi_awvalid        (1'b0),
        .dma_axi_awid           ('0),
        .dma_axi_awaddr         (32'd0),
        .dma_axi_awsize         (3'd0),
        .dma_axi_awprot         (3'd0),
        .dma_axi_awlen          (8'd0),
        .dma_axi_awburst        (2'd0),
        .dma_axi_wvalid         (1'b0),
        .dma_axi_wdata          (64'd0),
        .dma_axi_wstrb          (8'd0),
        .dma_axi_wlast          (1'b0),
        .dma_axi_bready         (1'b0),
        .dma_axi_arvalid        (1'b0),
        .dma_axi_arid           ('0),
        .dma_axi_araddr         (32'd0),
        .dma_axi_arsize         (3'd0),
        .dma_axi_arprot         (3'd0),
        .dma_axi_arlen          (8'd0),
        .dma_axi_arburst        (2'd0),
        .dma_axi_rready         (1'b0),

        // DMI Uncore tie-offs
        .dmi_core_enable        (1'b1),
        .dmi_uncore_enable      (1'b0),
        .dmi_uncore_rdata       (32'd0)
    );

    // =========================================================================
    // AXI4 Width Adapters: 64-bit CPU to 32-bit SoC Crossbar
    // =========================================================================

    // IFU Width Adapter (Read-only from CPU IFU)
    axi_adapter #(
        .ADDR_WIDTH    (ADDR_WIDTH),
        .S_DATA_WIDTH  (64),
        .M_DATA_WIDTH  (DATA_WIDTH),
        .ID_WIDTH      (ID_WIDTH)
    ) u_ifu_adapter (
        .clk           (clk),
        .rst           (!rst_l),

        // Slave side (64-bit from VeeR IFU)
        .s_axi_awid    ({ID_WIDTH{1'b0}}),
        .s_axi_awaddr  ({ADDR_WIDTH{1'b0}}),
        .s_axi_awlen   (8'd0),
        .s_axi_awsize  (3'd0),
        .s_axi_awburst (2'd0),
        .s_axi_awlock  (1'b0),
        .s_axi_awcache (4'd0),
        .s_axi_awprot  (3'd0),
        .s_axi_awqos   (4'd0),
        .s_axi_awregion(4'd0),
        .s_axi_awuser  (1'b0),
        .s_axi_awvalid (1'b0),
        .s_axi_awready (),
        .s_axi_wdata   (64'd0),
        .s_axi_wstrb   (8'd0),
        .s_axi_wlast   (1'b0),
        .s_axi_wuser   (1'b0),
        .s_axi_wvalid  (1'b0),
        .s_axi_wready  (),
        .s_axi_bid     (),
        .s_axi_bresp   (),
        .s_axi_buser   (),
        .s_axi_bvalid  (),
        .s_axi_bready  (1'b1),
        .s_axi_arid    (veer_ifu_arid),
        .s_axi_araddr  (veer_ifu_araddr),
        .s_axi_arlen   (veer_ifu_arlen),
        .s_axi_arsize  (veer_ifu_arsize),
        .s_axi_arburst (veer_ifu_arburst),
        .s_axi_arlock  (veer_ifu_arlock),
        .s_axi_arcache (veer_ifu_arcache),
        .s_axi_arprot  (veer_ifu_arprot),
        .s_axi_arqos   (veer_ifu_arqos),
        .s_axi_arregion(4'd0),
        .s_axi_aruser  (1'b0),
        .s_axi_arvalid (veer_ifu_arvalid),
        .s_axi_arready (veer_ifu_arready),
        .s_axi_rid     (veer_ifu_rid),
        .s_axi_rdata   (veer_ifu_rdata),
        .s_axi_rresp   (veer_ifu_rresp),
        .s_axi_rlast   (veer_ifu_rlast),
        .s_axi_ruser   (),
        .s_axi_rvalid  (veer_ifu_rvalid),
        .s_axi_rready  (veer_ifu_rready),

        // Master side (32-bit to SoC Interconnect S00)
        .m_axi_awid    (),
        .m_axi_awaddr  (),
        .m_axi_awlen   (),
        .m_axi_awsize  (),
        .m_axi_awburst (),
        .m_axi_awlock  (),
        .m_axi_awcache (),
        .m_axi_awprot  (),
        .m_axi_awqos   (),
        .m_axi_awregion(),
        .m_axi_awuser  (),
        .m_axi_awvalid (),
        .m_axi_awready (1'b1),
        .m_axi_wdata   (),
        .m_axi_wstrb   (),
        .m_axi_wlast   (),
        .m_axi_wuser   (),
        .m_axi_wvalid  (),
        .m_axi_wready  (1'b1),
        .m_axi_bid     ({ID_WIDTH{1'b0}}),
        .m_axi_bresp   (2'b00),
        .m_axi_buser   (1'b0),
        .m_axi_bvalid  (1'b0),
        .m_axi_bready  (),
        .m_axi_arid    (m0_ifu_arid),
        .m_axi_araddr  (m0_ifu_araddr),
        .m_axi_arlen   (m0_ifu_arlen),
        .m_axi_arsize  (m0_ifu_arsize),
        .m_axi_arburst (m0_ifu_arburst),
        .m_axi_arlock  (m0_ifu_arlock),
        .m_axi_arcache (m0_ifu_arcache),
        .m_axi_arprot  (m0_ifu_arprot),
        .m_axi_arqos   (m0_ifu_arqos),
        .m_axi_arregion(m0_ifu_arregion),
        .m_axi_aruser  (m0_ifu_aruser),
        .m_axi_arvalid (m0_ifu_arvalid),
        .m_axi_arready (m0_ifu_arready),
        .m_axi_rid     (m0_ifu_rid),
        .m_axi_rdata   (m0_ifu_rdata),
        .m_axi_rresp   (m0_ifu_rresp),
        .m_axi_rlast   (m0_ifu_rlast),
        .m_axi_ruser   (m0_ifu_ruser),
        .m_axi_rvalid  (m0_ifu_rvalid),
        .m_axi_rready  (m0_ifu_rready)
    );

    // LSU Width Adapter (Read & Write from CPU LSU)
    axi_adapter #(
        .ADDR_WIDTH    (ADDR_WIDTH),
        .S_DATA_WIDTH  (64),
        .M_DATA_WIDTH  (DATA_WIDTH),
        .ID_WIDTH      (ID_WIDTH)
    ) u_lsu_adapter (
        .clk           (clk),
        .rst           (!rst_l),

        // Slave side (64-bit from VeeR LSU)
        .s_axi_awid    (veer_lsu_awid),
        .s_axi_awaddr  (veer_lsu_awaddr),
        .s_axi_awlen   (veer_lsu_awlen),
        .s_axi_awsize  (veer_lsu_awsize),
        .s_axi_awburst (veer_lsu_awburst),
        .s_axi_awlock  (veer_lsu_awlock),
        .s_axi_awcache (veer_lsu_awcache),
        .s_axi_awprot  (veer_lsu_awprot),
        .s_axi_awqos   (veer_lsu_awqos),
        .s_axi_awregion(veer_lsu_awregion),
        .s_axi_awuser  (1'b0),
        .s_axi_awvalid (veer_lsu_awvalid),
        .s_axi_awready (veer_lsu_awready),
        .s_axi_wdata   (veer_lsu_wdata),
        .s_axi_wstrb   (veer_lsu_wstrb),
        .s_axi_wlast   (veer_lsu_wlast),
        .s_axi_wuser   (1'b0),
        .s_axi_wvalid  (veer_lsu_wvalid),
        .s_axi_wready  (veer_lsu_wready),
        .s_axi_bid     (veer_lsu_bid),
        .s_axi_bresp   (veer_lsu_bresp),
        .s_axi_buser   (),
        .s_axi_bvalid  (veer_lsu_bvalid),
        .s_axi_bready  (veer_lsu_bready),
        .s_axi_arid    (veer_lsu_arid),
        .s_axi_araddr  (veer_lsu_araddr),
        .s_axi_arlen   (veer_lsu_arlen),
        .s_axi_arsize  (veer_lsu_arsize),
        .s_axi_arburst (veer_lsu_arburst),
        .s_axi_arlock  (veer_lsu_arlock),
        .s_axi_arcache (veer_lsu_arcache),
        .s_axi_arprot  (veer_lsu_arprot),
        .s_axi_arqos   (veer_lsu_arqos),
        .s_axi_arregion(veer_lsu_arregion),
        .s_axi_aruser  (1'b0),
        .s_axi_arvalid (veer_lsu_arvalid),
        .s_axi_arready (veer_lsu_arready),
        .s_axi_rid     (veer_lsu_rid),
        .s_axi_rdata   (veer_lsu_rdata),
        .s_axi_rresp   (veer_lsu_rresp),
        .s_axi_rlast   (veer_lsu_rlast),
        .s_axi_ruser   (),
        .s_axi_rvalid  (veer_lsu_rvalid),
        .s_axi_rready  (veer_lsu_rready),

        // Master side (32-bit to SoC Interconnect S01)
        .m_axi_awid    (m1_lsu_awid),
        .m_axi_awaddr  (m1_lsu_awaddr),
        .m_axi_awlen   (m1_lsu_awlen),
        .m_axi_awsize  (m1_lsu_awsize),
        .m_axi_awburst (m1_lsu_awburst),
        .m_axi_awlock  (m1_lsu_awlock),
        .m_axi_awcache (m1_lsu_awcache),
        .m_axi_awprot  (m1_lsu_awprot),
        .m_axi_awqos   (m1_lsu_awqos),
        .m_axi_awregion(m1_lsu_awregion),
        .m_axi_awuser  (m1_lsu_awuser),
        .m_axi_awvalid (m1_lsu_awvalid),
        .m_axi_awready (m1_lsu_awready),
        .m_axi_wdata   (m1_lsu_wdata),
        .m_axi_wstrb   (m1_lsu_wstrb),
        .m_axi_wlast   (m1_lsu_wlast),
        .m_axi_wuser   (m1_lsu_wuser),
        .m_axi_wvalid  (m1_lsu_wvalid),
        .m_axi_wready  (m1_lsu_wready),
        .m_axi_bid     (m1_lsu_bid),
        .m_axi_bresp   (m1_lsu_bresp),
        .m_axi_buser   (m1_lsu_buser),
        .m_axi_bvalid  (m1_lsu_bvalid),
        .m_axi_bready  (m1_lsu_bready),
        .m_axi_arid    (m1_lsu_arid),
        .m_axi_araddr  (m1_lsu_araddr),
        .m_axi_arlen   (m1_lsu_arlen),
        .m_axi_arsize  (m1_lsu_arsize),
        .m_axi_arburst (m1_lsu_arburst),
        .m_axi_arlock  (m1_lsu_arlock),
        .m_axi_arcache (m1_lsu_arcache),
        .m_axi_arprot  (m1_lsu_arprot),
        .m_axi_arqos   (m1_lsu_arqos),
        .m_axi_arregion(m1_lsu_arregion),
        .m_axi_aruser  (m1_lsu_aruser),
        .m_axi_arvalid (m1_lsu_arvalid),
        .m_axi_arready (m1_lsu_arready),
        .m_axi_rid     (m1_lsu_rid),
        .m_axi_rdata   (m1_lsu_rdata),
        .m_axi_rresp   (m1_lsu_rresp),
        .m_axi_rlast   (m1_lsu_rlast),
        .m_axi_ruser   (m1_lsu_ruser),
        .m_axi_rvalid  (m1_lsu_rvalid),
        .m_axi_rready  (m1_lsu_rready)
    );

endmodule
