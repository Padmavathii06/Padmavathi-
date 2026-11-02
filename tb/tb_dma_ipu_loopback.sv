// =============================================================================
// tb_dma_ipu_loopback.sv
// Functional loopback verification for the DMA controller and AXI4 interconnect.
//
// Verification Architecture:
//   - Manager Port 0 (s00): Driven by local Testbench BFM (pre-load / read-back)
//   - Manager Port 1 (s01): Tied off (inactive)
//   - Manager Port 2 (s02): Tied off (inactive)
//   - Manager Port 3 (s03): Connected to dma_controller (DUT)
//   - Subordinate Port 0 (m00): Connected to axi_ram (SRAM 0x0000_0000..0x0FFF_FFFF)
//   - Subordinate Ports 1..3: Tied off safely
// =============================================================================

`timescale 1ns / 1ps
`default_nettype none

module tb_dma_ipu_loopback;

    // ── Parameters ────────────────────────────────────────────────────────────
    parameter DATA_WIDTH   = 32;
    parameter ADDR_WIDTH   = 32;
    parameter STRB_WIDTH   = DATA_WIDTH / 8;
    parameter ID_WIDTH     = 8;
    parameter AWUSER_WIDTH = 1;
    parameter WUSER_WIDTH  = 1;
    parameter BUSER_WIDTH  = 1;
    parameter ARUSER_WIDTH = 1;
    parameter RUSER_WIDTH  = 1;
    parameter MEM_WORDS    = 256;

    // Memory map for interconnect:
    // Region 0: 0x0000_0000 (SRAM) - 256MB window (width 28)
    // Region 1: 0x1000_0000 (Boot ROM)
    // Region 2: 0x2000_0000 (IPU Config)
    // Region 3: 0x3000_0000 (APB Peripherals)
    localparam [ADDR_WIDTH-1:0] BASE_ADDR [0:3] = '{
        32'h0000_0000,
        32'h1000_0000,
        32'h2000_0000,
        32'h3000_0000
    };
    localparam integer REGION_WIDTH [0:3] = '{28, 28, 12, 28};

    // ── Clock and Reset ───────────────────────────────────────────────────────
    reg clk;
    reg rst;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // ── S00: TB BFM Signals ───────────────────────────────────────────────────
    reg  [ID_WIDTH-1:0]     s00_axi_awid;
    reg  [ADDR_WIDTH-1:0]   s00_axi_awaddr;
    reg  [7:0]              s00_axi_awlen;
    reg  [2:0]              s00_axi_awsize;
    reg  [1:0]              s00_axi_awburst;
    reg                     s00_axi_awlock;
    reg  [3:0]              s00_axi_awcache;
    reg  [2:0]              s00_axi_awprot;
    reg  [3:0]              s00_axi_awqos;
    reg  [AWUSER_WIDTH-1:0] s00_axi_awuser;
    reg                     s00_axi_awvalid;
    wire                    s00_axi_awready;

    reg  [DATA_WIDTH-1:0]   s00_axi_wdata;
    reg  [STRB_WIDTH-1:0]   s00_axi_wstrb;
    reg                     s00_axi_wlast;
    reg  [WUSER_WIDTH-1:0]  s00_axi_wuser;
    reg                     s00_axi_wvalid;
    wire                    s00_axi_wready;

    wire [ID_WIDTH-1:0]     s00_axi_bid;
    wire [1:0]              s00_axi_bresp;
    wire [BUSER_WIDTH-1:0]  s00_axi_buser;
    wire                    s00_axi_bvalid;
    reg                     s00_axi_bready;

    reg  [ID_WIDTH-1:0]     s00_axi_arid;
    reg  [ADDR_WIDTH-1:0]   s00_axi_araddr;
    reg  [7:0]              s00_axi_arlen;
    reg  [2:0]              s00_axi_arsize;
    reg  [1:0]              s00_axi_arburst;
    reg                     s00_axi_arlock;
    reg  [3:0]              s00_axi_arcache;
    reg  [2:0]              s00_axi_arprot;
    reg  [3:0]              s00_axi_arqos;
    reg  [ARUSER_WIDTH-1:0] s00_axi_aruser;
    reg                     s00_axi_arvalid;
    wire                    s00_axi_arready;

    wire [ID_WIDTH-1:0]     s00_axi_rid;
    wire [DATA_WIDTH-1:0]   s00_axi_rdata;
    wire [1:0]              s00_axi_rresp;
    wire                    s00_axi_rlast;
    wire [RUSER_WIDTH-1:0]  s00_axi_ruser;
    wire                    s00_axi_rvalid;
    reg                     s00_axi_rready;

    // ── S03: DMA Controller Manager Signals ───────────────────────────────────
    wire [ID_WIDTH-1:0]     s03_axi_awid;
    wire [ADDR_WIDTH-1:0]   s03_axi_awaddr;
    wire [7:0]              s03_axi_awlen;
    wire [2:0]              s03_axi_awsize;
    wire [1:0]              s03_axi_awburst;
    wire                    s03_axi_awlock;
    wire [3:0]              s03_axi_awcache;
    wire [2:0]              s03_axi_awprot;
    wire [3:0]              s03_axi_awqos;
    wire [AWUSER_WIDTH-1:0] s03_axi_awuser;
    wire                    s03_axi_awvalid;
    wire                    s03_axi_awready;

    wire [DATA_WIDTH-1:0]   s03_axi_wdata;
    wire [STRB_WIDTH-1:0]   s03_axi_wstrb;
    wire                    s03_axi_wlast;
    wire [WUSER_WIDTH-1:0]  s03_axi_wuser;
    wire                    s03_axi_wvalid;
    wire                    s03_axi_wready;

    wire [ID_WIDTH-1:0]     s03_axi_bid;
    wire [1:0]              s03_axi_bresp;
    wire [BUSER_WIDTH-1:0]  s03_axi_buser;
    wire                    s03_axi_bvalid;
    wire                    s03_axi_bready;

    wire [ID_WIDTH-1:0]     s03_axi_arid;
    wire [ADDR_WIDTH-1:0]   s03_axi_araddr;
    wire [7:0]              s03_axi_arlen;
    wire [2:0]              s03_axi_arsize;
    wire [1:0]              s03_axi_arburst;
    wire                    s03_axi_arlock;
    wire [3:0]              s03_axi_arcache;
    wire [2:0]              s03_axi_arprot;
    wire [3:0]              s03_axi_arqos;
    wire [ARUSER_WIDTH-1:0] s03_axi_aruser;
    wire                    s03_axi_arvalid;
    wire                    s03_axi_arready;

    wire [ID_WIDTH-1:0]     s03_axi_rid;
    wire [DATA_WIDTH-1:0]   s03_axi_rdata;
    wire [1:0]              s03_axi_rresp;
    wire                    s03_axi_rlast;
    wire [RUSER_WIDTH-1:0]  s03_axi_ruser;
    wire                    s03_axi_rvalid;
    wire                    s03_axi_rready;

    // ── M00: Interconnect Master to SRAM Signals ──────────────────────────────
    wire [ID_WIDTH-1:0]     m00_axi_awid;
    wire [ADDR_WIDTH-1:0]   m00_axi_awaddr;
    wire [7:0]              m00_axi_awlen;
    wire [2:0]              m00_axi_awsize;
    wire [1:0]              m00_axi_awburst;
    wire                    m00_axi_awlock;
    wire [3:0]              m00_axi_awcache;
    wire [2:0]              m00_axi_awprot;
    wire [3:0]              m00_axi_awqos;
    wire [3:0]              m00_axi_awregion;
    wire [AWUSER_WIDTH-1:0] m00_axi_awuser;
    wire                    m00_axi_awvalid;
    wire                    m00_axi_awready;

    wire [DATA_WIDTH-1:0]   m00_axi_wdata;
    wire [STRB_WIDTH-1:0]   m00_axi_wstrb;
    wire                    m00_axi_wlast;
    wire [WUSER_WIDTH-1:0]  m00_axi_wuser;
    wire                    m00_axi_wvalid;
    wire                    m00_axi_wready;

    wire [ID_WIDTH-1:0]     m00_axi_bid;
    wire [1:0]              m00_axi_bresp;
    wire [BUSER_WIDTH-1:0]  m00_axi_buser;
    wire                    m00_axi_bvalid;
    wire                    m00_axi_bready;

    wire [ID_WIDTH-1:0]     m00_axi_arid;
    wire [ADDR_WIDTH-1:0]   m00_axi_araddr;
    wire [7:0]              m00_axi_arlen;
    wire [2:0]              m00_axi_arsize;
    wire [1:0]              m00_axi_arburst;
    wire                    m00_axi_arlock;
    wire [3:0]              m00_axi_arcache;
    wire [2:0]              m00_axi_arprot;
    wire [3:0]              m00_axi_arqos;
    wire [3:0]              m00_axi_arregion;
    wire [ARUSER_WIDTH-1:0] m00_axi_aruser;
    wire                    m00_axi_arvalid;
    wire                    m00_axi_arready;

    wire [ID_WIDTH-1:0]     m00_axi_rid;
    wire [DATA_WIDTH-1:0]   m00_axi_rdata;
    wire [1:0]              m00_axi_rresp;
    wire                    m00_axi_rlast;
    wire [RUSER_WIDTH-1:0]  m00_axi_ruser;
    wire                    m00_axi_rvalid;
    wire                    m00_axi_rready;

    // ── Unused Master Port Outputs (m01, m02, m03) ────────────────────────────
    wire [ID_WIDTH-1:0]     m01_axi_awid,    m02_axi_awid,    m03_axi_awid;
    wire [ADDR_WIDTH-1:0]   m01_axi_awaddr,  m02_axi_awaddr,  m03_axi_awaddr;
    wire [7:0]              m01_axi_awlen,   m02_axi_awlen,   m03_axi_awlen;
    wire [2:0]              m01_axi_awsize,  m02_axi_awsize,  m03_axi_awsize;
    wire [1:0]              m01_axi_awburst, m02_axi_awburst, m03_axi_awburst;
    wire                    m01_axi_awlock,  m02_axi_awlock,  m03_axi_awlock;
    wire [3:0]              m01_axi_awcache, m02_axi_awcache, m03_axi_awcache;
    wire [2:0]              m01_axi_awprot,  m02_axi_awprot,  m03_axi_awprot;
    wire [3:0]              m01_axi_awqos,   m02_axi_awqos,   m03_axi_awqos;
    wire [3:0]              m01_axi_awregion,m02_axi_awregion,m03_axi_awregion;
    wire [AWUSER_WIDTH-1:0] m01_axi_awuser,  m02_axi_awuser,  m03_axi_awuser;
    wire                    m01_axi_awvalid, m02_axi_awvalid, m03_axi_awvalid;

    wire [DATA_WIDTH-1:0]   m01_axi_wdata,   m02_axi_wdata,   m03_axi_wdata;
    wire [STRB_WIDTH-1:0]   m01_axi_wstrb,   m02_axi_wstrb,   m03_axi_wstrb;
    wire                    m01_axi_wlast,   m02_axi_wlast,   m03_axi_wlast;
    wire [WUSER_WIDTH-1:0]  m01_axi_wuser,   m02_axi_wuser,   m03_axi_wuser;
    wire                    m01_axi_wvalid,  m02_axi_wvalid,  m03_axi_wvalid;

    wire                    m01_axi_bready,  m02_axi_bready,  m03_axi_bready;

    wire [ID_WIDTH-1:0]     m01_axi_arid,    m02_axi_arid,    m03_axi_arid;
    wire [ADDR_WIDTH-1:0]   m01_axi_araddr,  m02_axi_araddr,  m03_axi_araddr;
    wire [7:0]              m01_axi_arlen,   m02_axi_arlen,   m03_axi_arlen;
    wire [2:0]              m01_axi_arsize,  m02_axi_arsize,  m03_axi_arsize;
    wire [1:0]              m01_axi_arburst, m02_axi_arburst, m03_axi_arburst;
    wire                    m01_axi_arlock,  m02_axi_arlock,  m03_axi_arlock;
    wire [3:0]              m01_axi_arcache, m02_axi_arcache, m03_axi_arcache;
    wire [2:0]              m01_axi_arprot,  m02_axi_arprot,  m03_axi_arprot;
    wire [3:0]              m01_axi_arqos,   m02_axi_arqos,   m03_axi_arqos;
    wire [3:0]              m01_axi_arregion,m02_axi_arregion,m03_axi_arregion;
    wire [ARUSER_WIDTH-1:0] m01_axi_aruser,  m02_axi_aruser,  m03_axi_aruser;
    wire                    m01_axi_arvalid, m02_axi_arvalid, m03_axi_arvalid;

    wire                    m01_axi_rready,  m02_axi_rready,  m03_axi_rready;

    // ── DMA Configuration and Status Registers ────────────────────────────────
    reg  [ADDR_WIDTH-1:0]   cfg_src_addr;
    reg  [ADDR_WIDTH-1:0]   cfg_dst_addr;
    reg  [15:0]             cfg_len;
    reg                     cfg_start;
    wire                    cfg_done;
    wire                    cfg_err;
    wire                    dma_irq;

    // ── DUT 1: 4x4 AXI Interconnect Wrapper ───────────────────────────────────
    axi_interconnect_wrap_4x4 #(
        .DATA_WIDTH   (DATA_WIDTH),
        .ADDR_WIDTH   (ADDR_WIDTH),
        .STRB_WIDTH   (STRB_WIDTH),
        .ID_WIDTH     (ID_WIDTH),
        .AWUSER_WIDTH (AWUSER_WIDTH),
        .WUSER_WIDTH  (WUSER_WIDTH),
        .BUSER_WIDTH  (BUSER_WIDTH),
        .ARUSER_WIDTH (ARUSER_WIDTH),
        .RUSER_WIDTH  (RUSER_WIDTH),
        .M_REGIONS    (1),
        .M00_BASE_ADDR(BASE_ADDR[0]),
        .M01_BASE_ADDR(BASE_ADDR[1]),
        .M02_BASE_ADDR(BASE_ADDR[2]),
        .M03_BASE_ADDR(BASE_ADDR[3]),
        .M00_ADDR_WIDTH(REGION_WIDTH[0]),
        .M01_ADDR_WIDTH(REGION_WIDTH[1]),
        .M02_ADDR_WIDTH(REGION_WIDTH[2]),
        .M03_ADDR_WIDTH(REGION_WIDTH[3])
    ) u_interconnect (
        .clk(clk),
        .rst(rst),

        // S00: TB BFM
        .s00_axi_awid    (s00_axi_awid),
        .s00_axi_awaddr  (s00_axi_awaddr),
        .s00_axi_awlen   (s00_axi_awlen),
        .s00_axi_awsize  (s00_axi_awsize),
        .s00_axi_awburst (s00_axi_awburst),
        .s00_axi_awlock  (s00_axi_awlock),
        .s00_axi_awcache (s00_axi_awcache),
        .s00_axi_awprot  (s00_axi_awprot),
        .s00_axi_awqos   (s00_axi_awqos),
        .s00_axi_awuser  (s00_axi_awuser),
        .s00_axi_awvalid (s00_axi_awvalid),
        .s00_axi_awready (s00_axi_awready),
        .s00_axi_wdata   (s00_axi_wdata),
        .s00_axi_wstrb   (s00_axi_wstrb),
        .s00_axi_wlast   (s00_axi_wlast),
        .s00_axi_wuser   (s00_axi_wuser),
        .s00_axi_wvalid  (s00_axi_wvalid),
        .s00_axi_wready  (s00_axi_wready),
        .s00_axi_bid     (s00_axi_bid),
        .s00_axi_bresp   (s00_axi_bresp),
        .s00_axi_buser   (s00_axi_buser),
        .s00_axi_bvalid  (s00_axi_bvalid),
        .s00_axi_bready  (s00_axi_bready),
        .s00_axi_arid    (s00_axi_arid),
        .s00_axi_araddr  (s00_axi_araddr),
        .s00_axi_arlen   (s00_axi_arlen),
        .s00_axi_arsize  (s00_axi_arsize),
        .s00_axi_arburst (s00_axi_arburst),
        .s00_axi_arlock  (s00_axi_arlock),
        .s00_axi_arcache (s00_axi_arcache),
        .s00_axi_arprot  (s00_axi_arprot),
        .s00_axi_arqos   (s00_axi_arqos),
        .s00_axi_aruser  (s00_axi_aruser),
        .s00_axi_arvalid (s00_axi_arvalid),
        .s00_axi_arready (s00_axi_arready),
        .s00_axi_rid     (s00_axi_rid),
        .s00_axi_rdata   (s00_axi_rdata),
        .s00_axi_rresp   (s00_axi_rresp),
        .s00_axi_rlast   (s00_axi_rlast),
        .s00_axi_ruser   (s00_axi_ruser),
        .s00_axi_rvalid  (s00_axi_rvalid),
        .s00_axi_rready  (s00_axi_rready),

        // S01: Unused (tied off)
        .s01_axi_awid    ({ID_WIDTH{1'b0}}),
        .s01_axi_awaddr  ({ADDR_WIDTH{1'b0}}),
        .s01_axi_awlen   (8'h00),
        .s01_axi_awsize  (3'b000),
        .s01_axi_awburst (2'b00),
        .s01_axi_awlock  (1'b0),
        .s01_axi_awcache (4'h0),
        .s01_axi_awprot  (3'b000),
        .s01_axi_awqos   (4'h0),
        .s01_axi_awuser  ({AWUSER_WIDTH{1'b0}}),
        .s01_axi_awvalid (1'b0),
        .s01_axi_awready (),
        .s01_axi_wdata   ({DATA_WIDTH{1'b0}}),
        .s01_axi_wstrb   ({STRB_WIDTH{1'b0}}),
        .s01_axi_wlast   (1'b0),
        .s01_axi_wuser   ({WUSER_WIDTH{1'b0}}),
        .s01_axi_wvalid  (1'b0),
        .s01_axi_wready  (),
        .s01_axi_bid     (),
        .s01_axi_bresp   (),
        .s01_axi_buser   (),
        .s01_axi_bvalid  (),
        .s01_axi_bready  (1'b0),
        .s01_axi_arid    ({ID_WIDTH{1'b0}}),
        .s01_axi_araddr  ({ADDR_WIDTH{1'b0}}),
        .s01_axi_arlen   (8'h00),
        .s01_axi_arsize  (3'b000),
        .s01_axi_arburst (2'b00),
        .s01_axi_arlock  (1'b0),
        .s01_axi_arcache (4'h0),
        .s01_axi_arprot  (3'b000),
        .s01_axi_arqos   (4'h0),
        .s01_axi_aruser  ({ARUSER_WIDTH{1'b0}}),
        .s01_axi_arvalid (1'b0),
        .s01_axi_arready (),
        .s01_axi_rid     (),
        .s01_axi_rdata   (),
        .s01_axi_rresp   (),
        .s01_axi_rlast   (),
        .s01_axi_ruser   (),
        .s01_axi_rvalid  (),
        .s01_axi_rready  (1'b0),

        // S02: Unused (tied off)
        .s02_axi_awid    ({ID_WIDTH{1'b0}}),
        .s02_axi_awaddr  ({ADDR_WIDTH{1'b0}}),
        .s02_axi_awlen   (8'h00),
        .s02_axi_awsize  (3'b000),
        .s02_axi_awburst (2'b00),
        .s02_axi_awlock  (1'b0),
        .s02_axi_awcache (4'h0),
        .s02_axi_awprot  (3'b000),
        .s02_axi_awqos   (4'h0),
        .s02_axi_awuser  ({AWUSER_WIDTH{1'b0}}),
        .s02_axi_awvalid (1'b0),
        .s02_axi_awready (),
        .s02_axi_wdata   ({DATA_WIDTH{1'b0}}),
        .s02_axi_wstrb   ({STRB_WIDTH{1'b0}}),
        .s02_axi_wlast   (1'b0),
        .s02_axi_wuser   ({WUSER_WIDTH{1'b0}}),
        .s02_axi_wvalid  (1'b0),
        .s02_axi_wready  (),
        .s02_axi_bid     (),
        .s02_axi_bresp   (),
        .s02_axi_buser   (),
        .s02_axi_bvalid  (),
        .s02_axi_bready  (1'b0),
        .s02_axi_arid    ({ID_WIDTH{1'b0}}),
        .s02_axi_araddr  ({ADDR_WIDTH{1'b0}}),
        .s02_axi_arlen   (8'h00),
        .s02_axi_arsize  (3'b000),
        .s02_axi_arburst (2'b00),
        .s02_axi_arlock  (1'b0),
        .s02_axi_arcache (4'h0),
        .s02_axi_arprot  (3'b000),
        .s02_axi_arqos   (4'h0),
        .s02_axi_aruser  ({ARUSER_WIDTH{1'b0}}),
        .s02_axi_arvalid (1'b0),
        .s02_axi_arready (),
        .s02_axi_rid     (),
        .s02_axi_rdata   (),
        .s02_axi_rresp   (),
        .s02_axi_rlast   (),
        .s02_axi_ruser   (),
        .s02_axi_rvalid  (),
        .s02_axi_rready  (1'b0),

        // S03: DMA Controller
        .s03_axi_awid    (s03_axi_awid),
        .s03_axi_awaddr  (s03_axi_awaddr),
        .s03_axi_awlen   (s03_axi_awlen),
        .s03_axi_awsize  (s03_axi_awsize),
        .s03_axi_awburst (s03_axi_awburst),
        .s03_axi_awlock  (s03_axi_awlock),
        .s03_axi_awcache (s03_axi_awcache),
        .s03_axi_awprot  (s03_axi_awprot),
        .s03_axi_awqos   (s03_axi_awqos),
        .s03_axi_awuser  (s03_axi_awuser),
        .s03_axi_awvalid (s03_axi_awvalid),
        .s03_axi_awready (s03_axi_awready),
        .s03_axi_wdata   (s03_axi_wdata),
        .s03_axi_wstrb   (s03_axi_wstrb),
        .s03_axi_wlast   (s03_axi_wlast),
        .s03_axi_wuser   (s03_axi_wuser),
        .s03_axi_wvalid  (s03_axi_wvalid),
        .s03_axi_wready  (s03_axi_wready),
        .s03_axi_bid     (s03_axi_bid),
        .s03_axi_bresp   (s03_axi_bresp),
        .s03_axi_buser   (s03_axi_buser),
        .s03_axi_bvalid  (s03_axi_bvalid),
        .s03_axi_bready  (s03_axi_bready),
        .s03_axi_arid    (s03_axi_arid),
        .s03_axi_araddr  (s03_axi_araddr),
        .s03_axi_arlen   (s03_axi_arlen),
        .s03_axi_arsize  (s03_axi_arsize),
        .s03_axi_arburst (s03_axi_arburst),
        .s03_axi_arlock  (s03_axi_arlock),
        .s03_axi_arcache (s03_axi_arcache),
        .s03_axi_arprot  (s03_axi_arprot),
        .s03_axi_arqos   (s03_axi_arqos),
        .s03_axi_aruser  (s03_axi_aruser),
        .s03_axi_arvalid (s03_axi_arvalid),
        .s03_axi_arready (s03_axi_arready),
        .s03_axi_rid     (s03_axi_rid),
        .s03_axi_rdata   (s03_axi_rdata),
        .s03_axi_rresp   (s03_axi_rresp),
        .s03_axi_rlast   (s03_axi_rlast),
        .s03_axi_ruser   (s03_axi_ruser),
        .s03_axi_rvalid  (s03_axi_rvalid),
        .s03_axi_rready  (s03_axi_rready),

        // M00: SRAM
        .m00_axi_awid    (m00_axi_awid),
        .m00_axi_awaddr  (m00_axi_awaddr),
        .m00_axi_awlen   (m00_axi_awlen),
        .m00_axi_awsize  (m00_axi_awsize),
        .m00_axi_awburst (m00_axi_awburst),
        .m00_axi_awlock  (m00_axi_awlock),
        .m00_axi_awcache (m00_axi_awcache),
        .m00_axi_awprot  (m00_axi_awprot),
        .m00_axi_awqos   (m00_axi_awqos),
        .m00_axi_awregion(m00_axi_awregion),
        .m00_axi_awuser  (m00_axi_awuser),
        .m00_axi_awvalid (m00_axi_awvalid),
        .m00_axi_awready (m00_axi_awready),
        .m00_axi_wdata   (m00_axi_wdata),
        .m00_axi_wstrb   (m00_axi_wstrb),
        .m00_axi_wlast   (m00_axi_wlast),
        .m00_axi_wuser   (m00_axi_wuser),
        .m00_axi_wvalid  (m00_axi_wvalid),
        .m00_axi_wready  (m00_axi_wready),
        .m00_axi_bid     (m00_axi_bid),
        .m00_axi_bresp   (m00_axi_bresp),
        .m00_axi_buser   (m00_axi_buser),
        .m00_axi_bvalid  (m00_axi_bvalid),
        .m00_axi_bready  (m00_axi_bready),
        .m00_axi_arid    (m00_axi_arid),
        .m00_axi_araddr  (m00_axi_araddr),
        .m00_axi_arlen   (m00_axi_arlen),
        .m00_axi_arsize  (m00_axi_arsize),
        .m00_axi_arburst (m00_axi_arburst),
        .m00_axi_arlock  (m00_axi_arlock),
        .m00_axi_arcache (m00_axi_arcache),
        .m00_axi_arprot  (m00_axi_arprot),
        .m00_axi_arqos   (m00_axi_arqos),
        .m00_axi_arregion(m00_axi_arregion),
        .m00_axi_aruser  (m00_axi_aruser),
        .m00_axi_arvalid (m00_axi_arvalid),
        .m00_axi_arready (m00_axi_arready),
        .m00_axi_rid     (m00_axi_rid),
        .m00_axi_rdata   (m00_axi_rdata),
        .m00_axi_rresp   (m00_axi_rresp),
        .m00_axi_rlast   (m00_axi_rlast),
        .m00_axi_ruser   (m00_axi_ruser),
        .m00_axi_rvalid  (m00_axi_rvalid),
        .m00_axi_rready  (m00_axi_rready),

        // M01: Unused
        .m01_axi_awid    (m01_axi_awid),
        .m01_axi_awaddr  (m01_axi_awaddr),
        .m01_axi_awlen   (m01_axi_awlen),
        .m01_axi_awsize  (m01_axi_awsize),
        .m01_axi_awburst (m01_axi_awburst),
        .m01_axi_awlock  (m01_axi_awlock),
        .m01_axi_awcache (m01_axi_awcache),
        .m01_axi_awprot  (m01_axi_awprot),
        .m01_axi_awqos   (m01_axi_awqos),
        .m01_axi_awregion(m01_axi_awregion),
        .m01_axi_awuser  (m01_axi_awuser),
        .m01_axi_awvalid (m01_axi_awvalid),
        .m01_axi_awready (1'b0),
        .m01_axi_wdata   (m01_axi_wdata),
        .m01_axi_wstrb   (m01_axi_wstrb),
        .m01_axi_wlast   (m01_axi_wlast),
        .m01_axi_wuser   (m01_axi_wuser),
        .m01_axi_wvalid  (m01_axi_wvalid),
        .m01_axi_wready  (1'b0),
        .m01_axi_bid     ({ID_WIDTH{1'b0}}),
        .m01_axi_bresp   (2'b11),
        .m01_axi_buser   ({BUSER_WIDTH{1'b0}}),
        .m01_axi_bvalid  (1'b0),
        .m01_axi_bready  (m01_axi_bready),
        .m01_axi_arid    (m01_axi_arid),
        .m01_axi_araddr  (m01_axi_araddr),
        .m01_axi_arlen   (m01_axi_arlen),
        .m01_axi_arsize  (m01_axi_arsize),
        .m01_axi_arburst (m01_axi_arburst),
        .m01_axi_arlock  (m01_axi_arlock),
        .m01_axi_arcache (m01_axi_arcache),
        .m01_axi_arprot  (m01_axi_arprot),
        .m01_axi_arqos   (m01_axi_arqos),
        .m01_axi_arregion(m01_axi_arregion),
        .m01_axi_aruser  (m01_axi_aruser),
        .m01_axi_arvalid (m01_axi_arvalid),
        .m01_axi_arready (1'b0),
        .m01_axi_rid     ({ID_WIDTH{1'b0}}),
        .m01_axi_rdata   ({DATA_WIDTH{1'b0}}),
        .m01_axi_rresp   (2'b11),
        .m01_axi_rlast   (1'b0),
        .m01_axi_ruser   ({RUSER_WIDTH{1'b0}}),
        .m01_axi_rvalid  (1'b0),
        .m01_axi_rready  (m01_axi_rready),

        // M02: Unused
        .m02_axi_awid    (m02_axi_awid),
        .m02_axi_awaddr  (m02_axi_awaddr),
        .m02_axi_awlen   (m02_axi_awlen),
        .m02_axi_awsize  (m02_axi_awsize),
        .m02_axi_awburst (m02_axi_awburst),
        .m02_axi_awlock  (m02_axi_awlock),
        .m02_axi_awcache (m02_axi_awcache),
        .m02_axi_awprot  (m02_axi_awprot),
        .m02_axi_awqos   (m02_axi_awqos),
        .m02_axi_awregion(m02_axi_awregion),
        .m02_axi_awuser  (m02_axi_awuser),
        .m02_axi_awvalid (m02_axi_awvalid),
        .m02_axi_awready (1'b0),
        .m02_axi_wdata   (m02_axi_wdata),
        .m02_axi_wstrb   (m02_axi_wstrb),
        .m02_axi_wlast   (m02_axi_wlast),
        .m02_axi_wuser   (m02_axi_wuser),
        .m02_axi_wvalid  (m02_axi_wvalid),
        .m02_axi_wready  (1'b0),
        .m02_axi_bid     ({ID_WIDTH{1'b0}}),
        .m02_axi_bresp   (2'b11),
        .m02_axi_buser   ({BUSER_WIDTH{1'b0}}),
        .m02_axi_bvalid  (1'b0),
        .m02_axi_bready  (m02_axi_bready),
        .m02_axi_arid    (m02_axi_arid),
        .m02_axi_araddr  (m02_axi_araddr),
        .m02_axi_arlen   (m02_axi_arlen),
        .m02_axi_arsize  (m02_axi_arsize),
        .m02_axi_arburst (m02_axi_arburst),
        .m02_axi_arlock  (m02_axi_arlock),
        .m02_axi_arcache (m02_axi_arcache),
        .m02_axi_arprot  (m02_axi_arprot),
        .m02_axi_arqos   (m02_axi_arqos),
        .m02_axi_arregion(m02_axi_arregion),
        .m02_axi_aruser  (m02_axi_aruser),
        .m02_axi_arvalid (m02_axi_arvalid),
        .m02_axi_arready (1'b0),
        .m02_axi_rid     ({ID_WIDTH{1'b0}}),
        .m02_axi_rdata   ({DATA_WIDTH{1'b0}}),
        .m02_axi_rresp   (2'b11),
        .m02_axi_rlast   (1'b0),
        .m02_axi_ruser   ({RUSER_WIDTH{1'b0}}),
        .m02_axi_rvalid  (1'b0),
        .m02_axi_rready  (m02_axi_rready),

        // M03: Unused
        .m03_axi_awid    (m03_axi_awid),
        .m03_axi_awaddr  (m03_axi_awaddr),
        .m03_axi_awlen   (m03_axi_awlen),
        .m03_axi_awsize  (m03_axi_awsize),
        .m03_axi_awburst (m03_axi_awburst),
        .m03_axi_awlock  (m03_axi_awlock),
        .m03_axi_awcache (m03_axi_awcache),
        .m03_axi_awprot  (m03_axi_awprot),
        .m03_axi_awqos   (m03_axi_awqos),
        .m03_axi_awregion(m03_axi_awregion),
        .m03_axi_awuser  (m03_axi_awuser),
        .m03_axi_awvalid (m03_axi_awvalid),
        .m03_axi_awready (1'b0),
        .m03_axi_wdata   (m03_axi_wdata),
        .m03_axi_wstrb   (m03_axi_wstrb),
        .m03_axi_wlast   (m03_axi_wlast),
        .m03_axi_wuser   (m03_axi_wuser),
        .m03_axi_wvalid  (m03_axi_wvalid),
        .m03_axi_wready  (1'b0),
        .m03_axi_bid     ({ID_WIDTH{1'b0}}),
        .m03_axi_bresp   (2'b11),
        .m03_axi_buser   ({BUSER_WIDTH{1'b0}}),
        .m03_axi_bvalid  (1'b0),
        .m03_axi_bready  (m03_axi_bready),
        .m03_axi_arid    (m03_axi_arid),
        .m03_axi_araddr  (m03_axi_araddr),
        .m03_axi_arlen   (m03_axi_arlen),
        .m03_axi_arsize  (m03_axi_arsize),
        .m03_axi_arburst (m03_axi_arburst),
        .m03_axi_arlock  (m03_axi_arlock),
        .m03_axi_arcache (m03_axi_arcache),
        .m03_axi_arprot  (m03_axi_arprot),
        .m03_axi_arqos   (m03_axi_arqos),
        .m03_axi_arregion(m03_axi_arregion),
        .m03_axi_aruser  (m03_axi_aruser),
        .m03_axi_arvalid (m03_axi_arvalid),
        .m03_axi_arready (1'b0),
        .m03_axi_rid     ({ID_WIDTH{1'b0}}),
        .m03_axi_rdata   ({DATA_WIDTH{1'b0}}),
        .m03_axi_rresp   (2'b11),
        .m03_axi_rlast   (1'b0),
        .m03_axi_ruser   ({RUSER_WIDTH{1'b0}}),
        .m03_axi_rvalid  (1'b0),
        .m03_axi_rready  (m03_axi_rready)
    );

    // ── DUT 2: DMA Controller ─────────────────────────────────────────────────
    dma_controller #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_WIDTH  (ID_WIDTH)
    ) u_dma (
        .clk           (clk),
        .rst           (rst),

        .m_axi_awid    (s03_axi_awid),
        .m_axi_awaddr  (s03_axi_awaddr),
        .m_axi_awlen   (s03_axi_awlen),
        .m_axi_awsize  (s03_axi_awsize),
        .m_axi_awburst (s03_axi_awburst),
        .m_axi_awlock  (s03_axi_awlock),
        .m_axi_awcache (s03_axi_awcache),
        .m_axi_awprot  (s03_axi_awprot),
        .m_axi_awqos   (s03_axi_awqos),
        .m_axi_awuser  (s03_axi_awuser),
        .m_axi_awvalid (s03_axi_awvalid),
        .m_axi_awready (s03_axi_awready),

        .m_axi_wdata   (s03_axi_wdata),
        .m_axi_wstrb   (s03_axi_wstrb),
        .m_axi_wlast   (s03_axi_wlast),
        .m_axi_wuser   (s03_axi_wuser),
        .m_axi_wvalid  (s03_axi_wvalid),
        .m_axi_wready  (s03_axi_wready),

        .m_axi_bid     (s03_axi_bid),
        .m_axi_bresp   (s03_axi_bresp),
        .m_axi_buser   (s03_axi_buser),
        .m_axi_bvalid  (s03_axi_bvalid),
        .m_axi_bready  (s03_axi_bready),

        .m_axi_arid    (s03_axi_arid),
        .m_axi_araddr  (s03_axi_araddr),
        .m_axi_arlen   (s03_axi_arlen),
        .m_axi_arsize  (s03_axi_arsize),
        .m_axi_arburst (s03_axi_arburst),
        .m_axi_arlock  (s03_axi_arlock),
        .m_axi_arcache (s03_axi_arcache),
        .m_axi_arprot  (s03_axi_arprot),
        .m_axi_arqos   (s03_axi_arqos),
        .m_axi_aruser  (s03_axi_aruser),
        .m_axi_arvalid (s03_axi_arvalid),
        .m_axi_arready (s03_axi_arready),

        .m_axi_rid     (s03_axi_rid),
        .m_axi_rdata   (s03_axi_rdata),
        .m_axi_rresp   (s03_axi_rresp),
        .m_axi_rlast   (s03_axi_rlast),
        .m_axi_ruser   (s03_axi_ruser),
        .m_axi_rvalid  (s03_axi_rvalid),
        .m_axi_rready  (s03_axi_rready),

        .cfg_src_addr  (cfg_src_addr),
        .cfg_dst_addr  (cfg_dst_addr),
        .cfg_len       (cfg_len),
        .cfg_start     (cfg_start),

        .cfg_done      (cfg_done),
        .cfg_err       (cfg_err),
        .dma_irq       (dma_irq)
    );

    // ── Subordinate Model: AXI RAM at M00 ─────────────────────────────────────
    axi_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .MEM_WORDS (MEM_WORDS)
    ) u_ram0 (
        .clk           (clk),
        .rst           (rst),

        .s_axi_awid    (m00_axi_awid),
        .s_axi_awaddr  (m00_axi_awaddr),
        .s_axi_awlen   (m00_axi_awlen),
        .s_axi_awsize  (m00_axi_awsize),
        .s_axi_awburst (m00_axi_awburst),
        .s_axi_awlock  (m00_axi_awlock),
        .s_axi_awcache (m00_axi_awcache),
        .s_axi_awprot  (m00_axi_awprot),
        .s_axi_awqos   (m00_axi_awqos),
        .s_axi_awregion(m00_axi_awregion),
        .s_axi_awuser  (m00_axi_awuser),
        .s_axi_awvalid (m00_axi_awvalid),
        .s_axi_awready (m00_axi_awready),

        .s_axi_wdata   (m00_axi_wdata),
        .s_axi_wstrb   (m00_axi_wstrb),
        .s_axi_wlast   (m00_axi_wlast),
        .s_axi_wuser   (m00_axi_wuser),
        .s_axi_wvalid  (m00_axi_wvalid),
        .s_axi_wready  (m00_axi_wready),

        .s_axi_bid     (m00_axi_bid),
        .s_axi_bresp   (m00_axi_bresp),
        .s_axi_buser   (m00_axi_buser),
        .s_axi_bvalid  (m00_axi_bvalid),
        .s_axi_bready  (m00_axi_bready),

        .s_axi_arid    (m00_axi_arid),
        .s_axi_araddr  (m00_axi_araddr),
        .s_axi_arlen   (m00_axi_arlen),
        .s_axi_arsize  (m00_axi_arsize),
        .s_axi_arburst (m00_axi_arburst),
        .s_axi_arlock  (m00_axi_arlock),
        .s_axi_arcache (m00_axi_arcache),
        .s_axi_arprot  (m00_axi_arprot),
        .s_axi_arqos   (m00_axi_arqos),
        .s_axi_arregion(m00_axi_arregion),
        .s_axi_aruser  (m00_axi_aruser),
        .s_axi_arvalid (m00_axi_arvalid),
        .s_axi_arready (m00_axi_arready),

        .s_axi_rid     (m00_axi_rid),
        .s_axi_rdata   (m00_axi_rdata),
        .s_axi_rresp   (m00_axi_rresp),
        .s_axi_rlast   (m00_axi_rlast),
        .s_axi_ruser   (m00_axi_ruser),
        .s_axi_rvalid  (m00_axi_rvalid),
        .s_axi_rready  (m00_axi_rready)
    );

    // ── Local BFM Tasks for S00 ───────────────────────────────────────────────
    task automatic bfm_write(
        input [ADDR_WIDTH-1:0] addr,
        input [DATA_WIDTH-1:0] data
    );
        int timeout;
        begin
            @(posedge clk);
            s00_axi_awid    <= 8'hA1;
            s00_axi_awaddr  <= addr;
            s00_axi_awlen   <= 8'd0;
            s00_axi_awsize  <= 3'b010; // 4 bytes
            s00_axi_awburst <= 2'b01;  // INCR
            s00_axi_awlock  <= 1'b0;
            s00_axi_awcache <= 4'h0;
            s00_axi_awprot  <= 3'b000;
            s00_axi_awqos   <= 4'h0;
            s00_axi_awuser  <= 1'b0;
            s00_axi_awvalid <= 1'b1;

            s00_axi_wdata   <= data;
            s00_axi_wstrb   <= 4'hF;
            s00_axi_wlast   <= 1'b1;
            s00_axi_wuser   <= 1'b0;
            s00_axi_wvalid  <= 1'b1;
            s00_axi_bready  <= 1'b1;

            fork
                begin
                    while (!s00_axi_awready) @(posedge clk);
                    @(posedge clk);
                    s00_axi_awvalid <= 1'b0;
                end
                begin
                    while (!s00_axi_wready) @(posedge clk);
                    @(posedge clk);
                    s00_axi_wvalid <= 1'b0;
                end
            join

            timeout = 0;
            while (!s00_axi_bvalid) begin
                @(posedge clk);
                timeout++;
                if (timeout > 500) begin
                    $display("[TB ERROR] bfm_write timeout waiting for bvalid at addr 0x%08h", addr);
                    $display("RESULT: TEST FAILED");
                    $fatal(1);
                end
            end
            @(posedge clk);
            s00_axi_bready <= 1'b0;
        end
    endtask

    task automatic bfm_read(
        input  [ADDR_WIDTH-1:0] addr,
        output [DATA_WIDTH-1:0] data,
        output [1:0]            resp
    );
        int timeout;
        begin
            @(posedge clk);
            s00_axi_arid    <= 8'hB2;
            s00_axi_araddr  <= addr;
            s00_axi_arlen   <= 8'd0;
            s00_axi_arsize  <= 3'b010; // 4 bytes
            s00_axi_arburst <= 2'b01;  // INCR
            s00_axi_arlock  <= 1'b0;
            s00_axi_arcache <= 4'h0;
            s00_axi_arprot  <= 3'b000;
            s00_axi_arqos   <= 4'h0;
            s00_axi_aruser  <= 1'b0;
            s00_axi_arvalid <= 1'b1;
            s00_axi_rready  <= 1'b1;

            while (!s00_axi_arready) @(posedge clk);
            @(posedge clk);
            s00_axi_arvalid <= 1'b0;

            timeout = 0;
            while (!s00_axi_rvalid) begin
                @(posedge clk);
                timeout++;
                if (timeout > 500) begin
                    $display("[TB ERROR] bfm_read timeout waiting for rvalid at addr 0x%08h", addr);
                    $display("RESULT: TEST FAILED");
                    $fatal(1);
                end
            end
            data = s00_axi_rdata;
            resp = s00_axi_rresp;
            @(posedge clk);
            s00_axi_rready <= 1'b0;
        end
    endtask

    // ── Test Execution ────────────────────────────────────────────────────────
    integer i;
    reg [DATA_WIDTH-1:0] exp_data [0:15];
    reg [DATA_WIDTH-1:0] rd_data;
    reg [1:0]            rd_resp;
    integer              timeout_cnt;

    initial begin
        $display("================================================================");
        $display(" Starting DMA Loopback & Crossbar Verification");
        $display("================================================================");

        // Reset initialization
        rst             = 1'b1;
        s00_axi_awvalid = 1'b0;
        s00_axi_wvalid  = 1'b0;
        s00_axi_bready  = 1'b0;
        s00_axi_arvalid = 1'b0;
        s00_axi_rready  = 1'b0;
        s00_axi_awid    = '0;
        s00_axi_awaddr  = '0;
        s00_axi_awlen   = '0;
        s00_axi_awsize  = '0;
        s00_axi_awburst = '0;
        s00_axi_awlock  = '0;
        s00_axi_awcache = '0;
        s00_axi_awprot  = '0;
        s00_axi_awqos   = '0;
        s00_axi_awuser  = '0;
        s00_axi_wdata   = '0;
        s00_axi_wstrb   = '0;
        s00_axi_wlast   = '0;
        s00_axi_wuser   = '0;
        s00_axi_arid    = '0;
        s00_axi_araddr  = '0;
        s00_axi_arlen   = '0;
        s00_axi_arsize  = '0;
        s00_axi_arburst = '0;
        s00_axi_arlock  = '0;
        s00_axi_arcache = '0;
        s00_axi_arprot  = '0;
        s00_axi_arqos   = '0;
        s00_axi_aruser  = '0;

        cfg_src_addr    = 32'h0;
        cfg_dst_addr    = 32'h0;
        cfg_len         = 16'h0;
        cfg_start       = 1'b0;

        // Apply reset for 10 cycles
        repeat (10) @(posedge clk);
        rst = 1'b0;
        repeat (5) @(posedge clk);
        $display("[INFO] Reset release complete at time %0t", $time);

        // ---------------------------------------------------------------------
        // TEST 1: Single 32-bit Word DMA Copy (len = 1)
        // ---------------------------------------------------------------------
        $display("\n--- Test 1: Single 32-bit Word Transfer ---");
        // Write source location 0x0000_0010 with 0xDEADBEEF
        bfm_write(32'h0000_0010, 32'hDEAD_BEEF);
        // Clear destination location 0x0000_0110
        bfm_write(32'h0000_0110, 32'h0000_0000);

        // Verify pre-condition
        bfm_read(32'h0000_0110, rd_data, rd_resp);
        if (rd_data !== 32'h0000_0000) begin
            $display("[FAIL] Dest addr 0x0000_0110 not cleared before copy");
            $display("RESULT: TEST FAILED");
            $fatal(1);
        end

        // Trigger DMA
        cfg_src_addr = 32'h0000_0010;
        cfg_dst_addr = 32'h0000_0110;
        cfg_len      = 16'd1;
        cfg_start    = 1'b1;
        @(posedge clk);
        cfg_start    = 1'b0;

        // Wait for completion
        timeout_cnt = 0;
        while (!cfg_done) begin
            @(posedge clk);
            timeout_cnt++;
            if (timeout_cnt > 1000) begin
                $display("[FAIL] Test 1: Timeout waiting for cfg_done");
                $display("RESULT: TEST FAILED");
                $fatal(1);
            end
        end

        if (cfg_err !== 1'b0) begin
            $display("[FAIL] Test 1: DMA reported unexpected error (cfg_err=1)");
            $display("RESULT: TEST FAILED");
            $fatal(1);
        end

        // Verify copied data via BFM read
        bfm_read(32'h0000_0110, rd_data, rd_resp);
        if (rd_data !== 32'hDEAD_BEEF) begin
            $display("[FAIL] Test 1: Data mismatch! Expected 0xDEADBEEF, got 0x%08h", rd_data);
            $display("RESULT: TEST FAILED");
            $fatal(1);
        end
        $display("[PASS] Test 1: Copied 1 word successfully (0x%08h)", rd_data);

        // ---------------------------------------------------------------------
        // TEST 2: Multi-Word DMA Transfer (len = 8 words)
        // ---------------------------------------------------------------------
        $display("\n--- Test 2: Multi-Word DMA Transfer (8 words) ---");
        for (i = 0; i < 8; i = i + 1) begin
            exp_data[i] = 32'h1000_0000 | (i << 8) | (8'hAA ^ i);
            bfm_write(32'h0000_0020 + (i * 4), exp_data[i]);
            bfm_write(32'h0000_0120 + (i * 4), 32'h0000_0000);
        end

        // Trigger DMA
        cfg_src_addr = 32'h0000_0020;
        cfg_dst_addr = 32'h0000_0120;
        cfg_len      = 16'd8;
        cfg_start    = 1'b1;
        @(posedge clk);
        cfg_start    = 1'b0;

        // Verify busy rejection: pulsing cfg_start while busy should not restart/corrupt
        @(posedge clk);
        cfg_start    = 1'b1;
        cfg_len      = 16'd1; // Attempt spurious override
        @(posedge clk);
        cfg_start    = 1'b0;

        // Wait for completion
        timeout_cnt = 0;
        while (!cfg_done) begin
            @(posedge clk);
            timeout_cnt++;
            if (timeout_cnt > 2000) begin
                $display("[FAIL] Test 2: Timeout waiting for cfg_done");
                $display("RESULT: TEST FAILED");
                $fatal(1);
            end
        end

        if (cfg_err !== 1'b0) begin
            $display("[FAIL] Test 2: DMA reported unexpected error (cfg_err=1)");
            $display("RESULT: TEST FAILED");
            $fatal(1);
        end

        // Verify all 8 words
        for (i = 0; i < 8; i = i + 1) begin
            bfm_read(32'h0000_0120 + (i * 4), rd_data, rd_resp);
            if (rd_data !== exp_data[i]) begin
                $display("[FAIL] Test 2: Word %0d mismatch! Expected 0x%08h, got 0x%08h",
                         i, exp_data[i], rd_data);
                $display("RESULT: TEST FAILED");
                $fatal(1);
            end
            $display("       Word %0d: 0x%08h == 0x%08h [OK]", i, rd_data, exp_data[i]);
        end
        $display("[PASS] Test 2: Multi-word transfer (8 words) verified successfully");

        // ---------------------------------------------------------------------
        // TEST 3: Status Latching and Re-arm Check
        // ---------------------------------------------------------------------
        $display("\n--- Test 3: Status Latching & Re-arm Check ---");
        // Verify cfg_done is held high
        repeat (10) @(posedge clk);
        if (cfg_done !== 1'b1) begin
            $display("[FAIL] Test 3: cfg_done did not remain latched high");
            $display("RESULT: TEST FAILED");
            $fatal(1);
        end

        // Start a new 1-word transfer; cfg_done should immediately clear
        bfm_write(32'h0000_0050, 32'hCAFE_BABE);
        cfg_src_addr = 32'h0000_0050;
        cfg_dst_addr = 32'h0000_0150;
        cfg_len      = 16'd1;
        cfg_start    = 1'b1;
        @(posedge clk);
        cfg_start    = 1'b0;

        if (cfg_done !== 1'b0) begin
            $display("[FAIL] Test 3: cfg_done did not clear upon new cfg_start");
            $display("RESULT: TEST FAILED");
            $fatal(1);
        end

        timeout_cnt = 0;
        while (!cfg_done) begin
            @(posedge clk);
            timeout_cnt++;
            if (timeout_cnt > 1000) begin
                $display("[FAIL] Test 3: Timeout waiting for re-armed transfer completion");
                $display("RESULT: TEST FAILED");
                $fatal(1);
            end
        end

        bfm_read(32'h0000_0150, rd_data, rd_resp);
        if (rd_data !== 32'hCAFE_BABE) begin
            $display("[FAIL] Test 3: Re-arm data mismatch! Expected 0xCAFEBABE, got 0x%08h", rd_data);
            $display("RESULT: TEST FAILED");
            $fatal(1);
        end
        $display("[PASS] Test 3: Status latching and clearing on re-arm verified");

        // ---------------------------------------------------------------------
        // TEST 4: Error Handling on Unmapped Address (DECERR)
        // ---------------------------------------------------------------------
        $display("\n--- Test 4: Error Handling on Unmapped Address ---");
        // Address 0xF000_0000 is not mapped to any region in the 4x4 crossbar.
        // Interconnect should generate DECERR (2'b11).
        cfg_src_addr = 32'hF000_0000;
        cfg_dst_addr = 32'h0000_0100;
        cfg_len      = 16'd1;
        cfg_start    = 1'b1;
        @(posedge clk);
        cfg_start    = 1'b0;

        timeout_cnt = 0;
        while (!cfg_err) begin
            @(posedge clk);
            timeout_cnt++;
            if (timeout_cnt > 1000) begin
                $display("[FAIL] Test 4: Timeout waiting for cfg_err on unmapped read");
                $display("RESULT: TEST FAILED");
                $fatal(1);
            end
        end

        if (dma_irq !== 1'b1) begin
            $display("[FAIL] Test 4: dma_irq was not asserted upon error");
            $display("RESULT: TEST FAILED");
            $fatal(1);
        end
        $display("[PASS] Test 4: DECERR correctly detected; cfg_err=1 and dma_irq=1");

        // ---------------------------------------------------------------------
        // All Tests Completed Successfully
        // ---------------------------------------------------------------------
        repeat (10) @(posedge clk);
        $display("\n================================================================");
        $display("RESULT: TEST PASSED");
        $display("================================================================");
        $finish;
    end

endmodule

`default_nettype wire
