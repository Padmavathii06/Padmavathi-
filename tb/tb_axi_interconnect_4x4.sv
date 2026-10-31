// =============================================================================
// AXI4 interconnect 4x4 testbench
//
// Configuration decision
// ----------------------
// The SoC specification (section 2.2 and 3.3) defines exactly four AXI4
// manager ports (CPU IFU, CPU LSU, Debug/sb, DMA) and four AXI4 subordinate
// ports (SRAM, Boot ROM, IPU config, APB/AHB bridge).  The interconnect is
// therefore a 4x4 crossbar, not a 4x9 crossbar.  A 4x9 implementation would
// add five unused subordinate ports and the associated decode/arbitration
// logic for no architectural benefit.
//
// Port mapping used below
// -----------------------
//   s00 -> CPU IFU        m00 -> System SRAM
//   s01 -> CPU LSU        m01 -> Boot ROM
//   s02 -> Debug/sb       m02 -> IPU config
//   s03 -> DMA            m03 -> APB/AHB bridge
//
// The testbench is self-checking:
//   * every manager port reads every subordinate region before any writes
//     (verifies read decode/routing and the reset memory pattern),
//   * every manager port writes and reads back every subordinate region
//     (verifies write data, write response, read data and read response),
//   * an unmapped address is checked for a DECERR response,
//   * concurrent requests from all four manager ports exercise arbitration,
//   * concurrent requests from all four managers to the same subordinate
//     verify that arbitration serialises transactions without data loss,
//   * the AXI slave models report any address that was routed to the wrong
//     subordinate port and any protocol violation.
// =============================================================================

`timescale 1ns / 1ps

module tb_axi_interconnect_4x4;

    parameter DATA_WIDTH   = 32;
    parameter ADDR_WIDTH   = 32;
    parameter STRB_WIDTH   = DATA_WIDTH / 8;
    parameter ID_WIDTH     = 8;

    parameter AWUSER_WIDTH = 1;
    parameter WUSER_WIDTH  = 1;
    parameter BUSER_WIDTH  = 1;
    parameter ARUSER_WIDTH = 1;
    parameter RUSER_WIDTH  = 1;

    localparam integer S_COUNT   = 4;
    localparam integer M_COUNT   = 4;
    localparam integer MEM_WORDS = 256;

    // Fixed SoC memory map.  Each region is aligned and non-overlapping.
    //   M00 SRAM      0x0000_0000 .. 0x0FFF_FFFF  (256 MiB)
    //   M01 Boot ROM  0x1000_0000 .. 0x1FFF_FFFF  (256 MiB)
    //   M02 IPU regs  0x2000_0000 .. 0x2000_0FFF  (4 KiB)
    //   M03 APB       0x3000_0000 .. 0x3FFF_FFFF  (256 MiB)
    localparam [ADDR_WIDTH-1:0] BASE_ADDR [0:3] = '{
        32'h0000_0000,
        32'h1000_0000,
        32'h2000_0000,
        32'h3000_0000
    };
    localparam integer REGION_WIDTH [0:3] = '{28, 28, 12, 28};

    localparam [1:0] RESP_OKAY   = 2'b00;
    localparam [1:0] RESP_SLVERR = 2'b10;
    localparam [1:0] RESP_DECERR = 2'b11;

    reg clk;
    reg rst;

    // =========================================================================
    // Manager-side (AXI slave interfaces of the DUT) driven by the testbench
    // =========================================================================

    logic [ID_WIDTH-1:0]     s_awid   [0:3];
    logic [ADDR_WIDTH-1:0]   s_awaddr [0:3];
    logic [7:0]              s_awlen  [0:3];
    logic [2:0]              s_awsize [0:3];
    logic [1:0]              s_awburst[0:3];
    logic                    s_awlock [0:3];
    logic [3:0]              s_awcache[0:3];
    logic [2:0]              s_awprot [0:3];
    logic [3:0]              s_awqos  [0:3];
    logic [AWUSER_WIDTH-1:0] s_awuser [0:3];
    logic                    s_awvalid[0:3];
    wire                     s_awready[0:3];

    logic [DATA_WIDTH-1:0]   s_wdata  [0:3];
    logic [STRB_WIDTH-1:0]   s_wstrb  [0:3];
    logic                    s_wlast  [0:3];
    logic [WUSER_WIDTH-1:0]  s_wuser  [0:3];
    logic                    s_wvalid [0:3];
    wire                     s_wready [0:3];

    wire [ID_WIDTH-1:0]      s_bid    [0:3];
    wire [1:0]               s_bresp  [0:3];
    wire [BUSER_WIDTH-1:0]   s_buser  [0:3];
    wire                     s_bvalid [0:3];
    logic                    s_bready [0:3];

    logic [ID_WIDTH-1:0]     s_arid   [0:3];
    logic [ADDR_WIDTH-1:0]   s_araddr [0:3];
    logic [7:0]              s_arlen  [0:3];
    logic [2:0]              s_arsize [0:3];
    logic [1:0]              s_arburst[0:3];
    logic                    s_arlock [0:3];
    logic [3:0]              s_arcache[0:3];
    logic [2:0]              s_arprot [0:3];
    logic [3:0]              s_arqos  [0:3];
    logic [ARUSER_WIDTH-1:0] s_aruser [0:3];
    logic                    s_arvalid[0:3];
    wire                     s_arready[0:3];

    wire [ID_WIDTH-1:0]      s_rid    [0:3];
    wire [DATA_WIDTH-1:0]    s_rdata  [0:3];
    wire [1:0]               s_rresp  [0:3];
    wire                     s_rlast  [0:3];
    wire [RUSER_WIDTH-1:0]   s_ruser  [0:3];
    wire                     s_rvalid [0:3];
    logic                    s_rready [0:3];

    // =========================================================================
    // Subordinate-side (AXI master interfaces of the DUT) driven by the models
    // =========================================================================

    wire [ID_WIDTH-1:0]      m_awid   [0:3];
    wire [ADDR_WIDTH-1:0]    m_awaddr [0:3];
    wire [7:0]               m_awlen  [0:3];
    wire [2:0]               m_awsize [0:3];
    wire [1:0]               m_awburst[0:3];
    wire                     m_awlock [0:3];
    wire [3:0]               m_awcache[0:3];
    wire [2:0]               m_awprot [0:3];
    wire [3:0]               m_awqos  [0:3];
    wire [3:0]               m_awregion[0:3];
    wire [AWUSER_WIDTH-1:0]  m_awuser [0:3];
    wire                     m_awvalid[0:3];
    wire                     m_awready[0:3];

    wire [DATA_WIDTH-1:0]    m_wdata  [0:3];
    wire [STRB_WIDTH-1:0]    m_wstrb  [0:3];
    wire                     m_wlast  [0:3];
    wire [WUSER_WIDTH-1:0]   m_wuser  [0:3];
    wire                     m_wvalid [0:3];
    wire                     m_wready [0:3];

    wire [ID_WIDTH-1:0]      m_bid    [0:3];
    wire [1:0]               m_bresp  [0:3];
    wire [BUSER_WIDTH-1:0]   m_buser  [0:3];
    wire                     m_bvalid [0:3];
    wire                     m_bready [0:3];

    wire [ID_WIDTH-1:0]      m_arid   [0:3];
    wire [ADDR_WIDTH-1:0]    m_araddr [0:3];
    wire [7:0]               m_arlen  [0:3];
    wire [2:0]               m_arsize [0:3];
    wire [1:0]               m_arburst[0:3];
    wire                     m_arlock [0:3];
    wire [3:0]               m_arcache[0:3];
    wire [2:0]               m_arprot [0:3];
    wire [3:0]               m_arqos  [0:3];
    wire [3:0]               m_arregion[0:3];
    wire [ARUSER_WIDTH-1:0]  m_aruser [0:3];
    wire                     m_arvalid[0:3];
    wire                     m_arready[0:3];

    wire [ID_WIDTH-1:0]      m_rid    [0:3];
    wire [DATA_WIDTH-1:0]    m_rdata  [0:3];
    wire [1:0]               m_rresp  [0:3];
    wire                     m_rlast  [0:3];
    wire [RUSER_WIDTH-1:0]   m_ruser  [0:3];
    wire                     m_rvalid [0:3];
    wire                     m_rready [0:3];

    wire [31:0]              m_route_errors    [0:3];
    wire [31:0]              m_protocol_errors [0:3];

    // =========================================================================
    // DUT
    // =========================================================================

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
    ) dut (
        .clk(clk),
        .rst(rst),

        // S00
        .s00_axi_awid(s_awid[0]),
        .s00_axi_awaddr(s_awaddr[0]),
        .s00_axi_awlen(s_awlen[0]),
        .s00_axi_awsize(s_awsize[0]),
        .s00_axi_awburst(s_awburst[0]),
        .s00_axi_awlock(s_awlock[0]),
        .s00_axi_awcache(s_awcache[0]),
        .s00_axi_awprot(s_awprot[0]),
        .s00_axi_awqos(s_awqos[0]),
        .s00_axi_awuser(s_awuser[0]),
        .s00_axi_awvalid(s_awvalid[0]),
        .s00_axi_awready(s_awready[0]),
        .s00_axi_wdata(s_wdata[0]),
        .s00_axi_wstrb(s_wstrb[0]),
        .s00_axi_wlast(s_wlast[0]),
        .s00_axi_wuser(s_wuser[0]),
        .s00_axi_wvalid(s_wvalid[0]),
        .s00_axi_wready(s_wready[0]),
        .s00_axi_bid(s_bid[0]),
        .s00_axi_bresp(s_bresp[0]),
        .s00_axi_buser(s_buser[0]),
        .s00_axi_bvalid(s_bvalid[0]),
        .s00_axi_bready(s_bready[0]),
        .s00_axi_arid(s_arid[0]),
        .s00_axi_araddr(s_araddr[0]),
        .s00_axi_arlen(s_arlen[0]),
        .s00_axi_arsize(s_arsize[0]),
        .s00_axi_arburst(s_arburst[0]),
        .s00_axi_arlock(s_arlock[0]),
        .s00_axi_arcache(s_arcache[0]),
        .s00_axi_arprot(s_arprot[0]),
        .s00_axi_arqos(s_arqos[0]),
        .s00_axi_aruser(s_aruser[0]),
        .s00_axi_arvalid(s_arvalid[0]),
        .s00_axi_arready(s_arready[0]),
        .s00_axi_rid(s_rid[0]),
        .s00_axi_rdata(s_rdata[0]),
        .s00_axi_rresp(s_rresp[0]),
        .s00_axi_rlast(s_rlast[0]),
        .s00_axi_ruser(s_ruser[0]),
        .s00_axi_rvalid(s_rvalid[0]),
        .s00_axi_rready(s_rready[0]),

        // S01
        .s01_axi_awid(s_awid[1]),
        .s01_axi_awaddr(s_awaddr[1]),
        .s01_axi_awlen(s_awlen[1]),
        .s01_axi_awsize(s_awsize[1]),
        .s01_axi_awburst(s_awburst[1]),
        .s01_axi_awlock(s_awlock[1]),
        .s01_axi_awcache(s_awcache[1]),
        .s01_axi_awprot(s_awprot[1]),
        .s01_axi_awqos(s_awqos[1]),
        .s01_axi_awuser(s_awuser[1]),
        .s01_axi_awvalid(s_awvalid[1]),
        .s01_axi_awready(s_awready[1]),
        .s01_axi_wdata(s_wdata[1]),
        .s01_axi_wstrb(s_wstrb[1]),
        .s01_axi_wlast(s_wlast[1]),
        .s01_axi_wuser(s_wuser[1]),
        .s01_axi_wvalid(s_wvalid[1]),
        .s01_axi_wready(s_wready[1]),
        .s01_axi_bid(s_bid[1]),
        .s01_axi_bresp(s_bresp[1]),
        .s01_axi_buser(s_buser[1]),
        .s01_axi_bvalid(s_bvalid[1]),
        .s01_axi_bready(s_bready[1]),
        .s01_axi_arid(s_arid[1]),
        .s01_axi_araddr(s_araddr[1]),
        .s01_axi_arlen(s_arlen[1]),
        .s01_axi_arsize(s_arsize[1]),
        .s01_axi_arburst(s_arburst[1]),
        .s01_axi_arlock(s_arlock[1]),
        .s01_axi_arcache(s_arcache[1]),
        .s01_axi_arprot(s_arprot[1]),
        .s01_axi_arqos(s_arqos[1]),
        .s01_axi_aruser(s_aruser[1]),
        .s01_axi_arvalid(s_arvalid[1]),
        .s01_axi_arready(s_arready[1]),
        .s01_axi_rid(s_rid[1]),
        .s01_axi_rdata(s_rdata[1]),
        .s01_axi_rresp(s_rresp[1]),
        .s01_axi_rlast(s_rlast[1]),
        .s01_axi_ruser(s_ruser[1]),
        .s01_axi_rvalid(s_rvalid[1]),
        .s01_axi_rready(s_rready[1]),

        // S02
        .s02_axi_awid(s_awid[2]),
        .s02_axi_awaddr(s_awaddr[2]),
        .s02_axi_awlen(s_awlen[2]),
        .s02_axi_awsize(s_awsize[2]),
        .s02_axi_awburst(s_awburst[2]),
        .s02_axi_awlock(s_awlock[2]),
        .s02_axi_awcache(s_awcache[2]),
        .s02_axi_awprot(s_awprot[2]),
        .s02_axi_awqos(s_awqos[2]),
        .s02_axi_awuser(s_awuser[2]),
        .s02_axi_awvalid(s_awvalid[2]),
        .s02_axi_awready(s_awready[2]),
        .s02_axi_wdata(s_wdata[2]),
        .s02_axi_wstrb(s_wstrb[2]),
        .s02_axi_wlast(s_wlast[2]),
        .s02_axi_wuser(s_wuser[2]),
        .s02_axi_wvalid(s_wvalid[2]),
        .s02_axi_wready(s_wready[2]),
        .s02_axi_bid(s_bid[2]),
        .s02_axi_bresp(s_bresp[2]),
        .s02_axi_buser(s_buser[2]),
        .s02_axi_bvalid(s_bvalid[2]),
        .s02_axi_bready(s_bready[2]),
        .s02_axi_arid(s_arid[2]),
        .s02_axi_araddr(s_araddr[2]),
        .s02_axi_arlen(s_arlen[2]),
        .s02_axi_arsize(s_arsize[2]),
        .s02_axi_arburst(s_arburst[2]),
        .s02_axi_arlock(s_arlock[2]),
        .s02_axi_arcache(s_arcache[2]),
        .s02_axi_arprot(s_arprot[2]),
        .s02_axi_arqos(s_arqos[2]),
        .s02_axi_aruser(s_aruser[2]),
        .s02_axi_arvalid(s_arvalid[2]),
        .s02_axi_arready(s_arready[2]),
        .s02_axi_rid(s_rid[2]),
        .s02_axi_rdata(s_rdata[2]),
        .s02_axi_rresp(s_rresp[2]),
        .s02_axi_rlast(s_rlast[2]),
        .s02_axi_ruser(s_ruser[2]),
        .s02_axi_rvalid(s_rvalid[2]),
        .s02_axi_rready(s_rready[2]),

        // S03
        .s03_axi_awid(s_awid[3]),
        .s03_axi_awaddr(s_awaddr[3]),
        .s03_axi_awlen(s_awlen[3]),
        .s03_axi_awsize(s_awsize[3]),
        .s03_axi_awburst(s_awburst[3]),
        .s03_axi_awlock(s_awlock[3]),
        .s03_axi_awcache(s_awcache[3]),
        .s03_axi_awprot(s_awprot[3]),
        .s03_axi_awqos(s_awqos[3]),
        .s03_axi_awuser(s_awuser[3]),
        .s03_axi_awvalid(s_awvalid[3]),
        .s03_axi_awready(s_awready[3]),
        .s03_axi_wdata(s_wdata[3]),
        .s03_axi_wstrb(s_wstrb[3]),
        .s03_axi_wlast(s_wlast[3]),
        .s03_axi_wuser(s_wuser[3]),
        .s03_axi_wvalid(s_wvalid[3]),
        .s03_axi_wready(s_wready[3]),
        .s03_axi_bid(s_bid[3]),
        .s03_axi_bresp(s_bresp[3]),
        .s03_axi_buser(s_buser[3]),
        .s03_axi_bvalid(s_bvalid[3]),
        .s03_axi_bready(s_bready[3]),
        .s03_axi_arid(s_arid[3]),
        .s03_axi_araddr(s_araddr[3]),
        .s03_axi_arlen(s_arlen[3]),
        .s03_axi_arsize(s_arsize[3]),
        .s03_axi_arburst(s_arburst[3]),
        .s03_axi_arlock(s_arlock[3]),
        .s03_axi_arcache(s_arcache[3]),
        .s03_axi_arprot(s_arprot[3]),
        .s03_axi_arqos(s_arqos[3]),
        .s03_axi_aruser(s_aruser[3]),
        .s03_axi_arvalid(s_arvalid[3]),
        .s03_axi_arready(s_arready[3]),
        .s03_axi_rid(s_rid[3]),
        .s03_axi_rdata(s_rdata[3]),
        .s03_axi_rresp(s_rresp[3]),
        .s03_axi_rlast(s_rlast[3]),
        .s03_axi_ruser(s_ruser[3]),
        .s03_axi_rvalid(s_rvalid[3]),
        .s03_axi_rready(s_rready[3]),

        // Masters
        // M00
        .m00_axi_awid(m_awid[0]),
        .m00_axi_awaddr(m_awaddr[0]),
        .m00_axi_awlen(m_awlen[0]),
        .m00_axi_awsize(m_awsize[0]),
        .m00_axi_awburst(m_awburst[0]),
        .m00_axi_awlock(m_awlock[0]),
        .m00_axi_awcache(m_awcache[0]),
        .m00_axi_awprot(m_awprot[0]),
        .m00_axi_awqos(m_awqos[0]),
        .m00_axi_awregion(m_awregion[0]),
        .m00_axi_awuser(m_awuser[0]),
        .m00_axi_awvalid(m_awvalid[0]),
        .m00_axi_awready(m_awready[0]),
        .m00_axi_wdata(m_wdata[0]),
        .m00_axi_wstrb(m_wstrb[0]),
        .m00_axi_wlast(m_wlast[0]),
        .m00_axi_wuser(m_wuser[0]),
        .m00_axi_wvalid(m_wvalid[0]),
        .m00_axi_wready(m_wready[0]),
        .m00_axi_bid(m_bid[0]),
        .m00_axi_bresp(m_bresp[0]),
        .m00_axi_buser(m_buser[0]),
        .m00_axi_bvalid(m_bvalid[0]),
        .m00_axi_bready(m_bready[0]),
        .m00_axi_arid(m_arid[0]),
        .m00_axi_araddr(m_araddr[0]),
        .m00_axi_arlen(m_arlen[0]),
        .m00_axi_arsize(m_arsize[0]),
        .m00_axi_arburst(m_arburst[0]),
        .m00_axi_arlock(m_arlock[0]),
        .m00_axi_arcache(m_arcache[0]),
        .m00_axi_arprot(m_arprot[0]),
        .m00_axi_arqos(m_arqos[0]),
        .m00_axi_arregion(m_arregion[0]),
        .m00_axi_aruser(m_aruser[0]),
        .m00_axi_arvalid(m_arvalid[0]),
        .m00_axi_arready(m_arready[0]),
        .m00_axi_rid(m_rid[0]),
        .m00_axi_rdata(m_rdata[0]),
        .m00_axi_rresp(m_rresp[0]),
        .m00_axi_rlast(m_rlast[0]),
        .m00_axi_ruser(m_ruser[0]),
        .m00_axi_rvalid(m_rvalid[0]),
        .m00_axi_rready(m_rready[0]),

        // M01
        .m01_axi_awid(m_awid[1]),
        .m01_axi_awaddr(m_awaddr[1]),
        .m01_axi_awlen(m_awlen[1]),
        .m01_axi_awsize(m_awsize[1]),
        .m01_axi_awburst(m_awburst[1]),
        .m01_axi_awlock(m_awlock[1]),
        .m01_axi_awcache(m_awcache[1]),
        .m01_axi_awprot(m_awprot[1]),
        .m01_axi_awqos(m_awqos[1]),
        .m01_axi_awregion(m_awregion[1]),
        .m01_axi_awuser(m_awuser[1]),
        .m01_axi_awvalid(m_awvalid[1]),
        .m01_axi_awready(m_awready[1]),
        .m01_axi_wdata(m_wdata[1]),
        .m01_axi_wstrb(m_wstrb[1]),
        .m01_axi_wlast(m_wlast[1]),
        .m01_axi_wuser(m_wuser[1]),
        .m01_axi_wvalid(m_wvalid[1]),
        .m01_axi_wready(m_wready[1]),
        .m01_axi_bid(m_bid[1]),
        .m01_axi_bresp(m_bresp[1]),
        .m01_axi_buser(m_buser[1]),
        .m01_axi_bvalid(m_bvalid[1]),
        .m01_axi_bready(m_bready[1]),
        .m01_axi_arid(m_arid[1]),
        .m01_axi_araddr(m_araddr[1]),
        .m01_axi_arlen(m_arlen[1]),
        .m01_axi_arsize(m_arsize[1]),
        .m01_axi_arburst(m_arburst[1]),
        .m01_axi_arlock(m_arlock[1]),
        .m01_axi_arcache(m_arcache[1]),
        .m01_axi_arprot(m_arprot[1]),
        .m01_axi_arqos(m_arqos[1]),
        .m01_axi_arregion(m_arregion[1]),
        .m01_axi_aruser(m_aruser[1]),
        .m01_axi_arvalid(m_arvalid[1]),
        .m01_axi_arready(m_arready[1]),
        .m01_axi_rid(m_rid[1]),
        .m01_axi_rdata(m_rdata[1]),
        .m01_axi_rresp(m_rresp[1]),
        .m01_axi_rlast(m_rlast[1]),
        .m01_axi_ruser(m_ruser[1]),
        .m01_axi_rvalid(m_rvalid[1]),
        .m01_axi_rready(m_rready[1]),

        // M02
        .m02_axi_awid(m_awid[2]),
        .m02_axi_awaddr(m_awaddr[2]),
        .m02_axi_awlen(m_awlen[2]),
        .m02_axi_awsize(m_awsize[2]),
        .m02_axi_awburst(m_awburst[2]),
        .m02_axi_awlock(m_awlock[2]),
        .m02_axi_awcache(m_awcache[2]),
        .m02_axi_awprot(m_awprot[2]),
        .m02_axi_awqos(m_awqos[2]),
        .m02_axi_awregion(m_awregion[2]),
        .m02_axi_awuser(m_awuser[2]),
        .m02_axi_awvalid(m_awvalid[2]),
        .m02_axi_awready(m_awready[2]),
        .m02_axi_wdata(m_wdata[2]),
        .m02_axi_wstrb(m_wstrb[2]),
        .m02_axi_wlast(m_wlast[2]),
        .m02_axi_wuser(m_wuser[2]),
        .m02_axi_wvalid(m_wvalid[2]),
        .m02_axi_wready(m_wready[2]),
        .m02_axi_bid(m_bid[2]),
        .m02_axi_bresp(m_bresp[2]),
        .m02_axi_buser(m_buser[2]),
        .m02_axi_bvalid(m_bvalid[2]),
        .m02_axi_bready(m_bready[2]),
        .m02_axi_arid(m_arid[2]),
        .m02_axi_araddr(m_araddr[2]),
        .m02_axi_arlen(m_arlen[2]),
        .m02_axi_arsize(m_arsize[2]),
        .m02_axi_arburst(m_arburst[2]),
        .m02_axi_arlock(m_arlock[2]),
        .m02_axi_arcache(m_arcache[2]),
        .m02_axi_arprot(m_arprot[2]),
        .m02_axi_arqos(m_arqos[2]),
        .m02_axi_arregion(m_arregion[2]),
        .m02_axi_aruser(m_aruser[2]),
        .m02_axi_arvalid(m_arvalid[2]),
        .m02_axi_arready(m_arready[2]),
        .m02_axi_rid(m_rid[2]),
        .m02_axi_rdata(m_rdata[2]),
        .m02_axi_rresp(m_rresp[2]),
        .m02_axi_rlast(m_rlast[2]),
        .m02_axi_ruser(m_ruser[2]),
        .m02_axi_rvalid(m_rvalid[2]),
        .m02_axi_rready(m_rready[2]),

        // M03
        .m03_axi_awid(m_awid[3]),
        .m03_axi_awaddr(m_awaddr[3]),
        .m03_axi_awlen(m_awlen[3]),
        .m03_axi_awsize(m_awsize[3]),
        .m03_axi_awburst(m_awburst[3]),
        .m03_axi_awlock(m_awlock[3]),
        .m03_axi_awcache(m_awcache[3]),
        .m03_axi_awprot(m_awprot[3]),
        .m03_axi_awqos(m_awqos[3]),
        .m03_axi_awregion(m_awregion[3]),
        .m03_axi_awuser(m_awuser[3]),
        .m03_axi_awvalid(m_awvalid[3]),
        .m03_axi_awready(m_awready[3]),
        .m03_axi_wdata(m_wdata[3]),
        .m03_axi_wstrb(m_wstrb[3]),
        .m03_axi_wlast(m_wlast[3]),
        .m03_axi_wuser(m_wuser[3]),
        .m03_axi_wvalid(m_wvalid[3]),
        .m03_axi_wready(m_wready[3]),
        .m03_axi_bid(m_bid[3]),
        .m03_axi_bresp(m_bresp[3]),
        .m03_axi_buser(m_buser[3]),
        .m03_axi_bvalid(m_bvalid[3]),
        .m03_axi_bready(m_bready[3]),
        .m03_axi_arid(m_arid[3]),
        .m03_axi_araddr(m_araddr[3]),
        .m03_axi_arlen(m_arlen[3]),
        .m03_axi_arsize(m_arsize[3]),
        .m03_axi_arburst(m_arburst[3]),
        .m03_axi_arlock(m_arlock[3]),
        .m03_axi_arcache(m_arcache[3]),
        .m03_axi_arprot(m_arprot[3]),
        .m03_axi_arqos(m_arqos[3]),
        .m03_axi_arregion(m_arregion[3]),
        .m03_axi_aruser(m_aruser[3]),
        .m03_axi_arvalid(m_arvalid[3]),
        .m03_axi_arready(m_arready[3]),
        .m03_axi_rid(m_rid[3]),
        .m03_axi_rdata(m_rdata[3]),
        .m03_axi_rresp(m_rresp[3]),
        .m03_axi_rlast(m_rlast[3]),
        .m03_axi_ruser(m_ruser[3]),
        .m03_axi_rvalid(m_rvalid[3]),
        .m03_axi_rready(m_rready[3])
    );

    // =========================================================================
    // Subordinate memory models
    // =========================================================================

    genvar gi;
    generate
        for (gi = 0; gi < M_COUNT; gi = gi + 1) begin : g_subordinate
            axi_slave_model #(
                .DATA_WIDTH   (DATA_WIDTH),
                .ADDR_WIDTH   (ADDR_WIDTH),
                .STRB_WIDTH   (STRB_WIDTH),
                .ID_WIDTH     (ID_WIDTH),
                .AWUSER_WIDTH (AWUSER_WIDTH),
                .WUSER_WIDTH  (WUSER_WIDTH),
                .BUSER_WIDTH  (BUSER_WIDTH),
                .ARUSER_WIDTH (ARUSER_WIDTH),
                .RUSER_WIDTH  (RUSER_WIDTH),
                .MEM_WORDS    (MEM_WORDS),
                .ID           (gi),
                .BASE_ADDR    (BASE_ADDR[gi]),
                .REGION_WIDTH (REGION_WIDTH[gi])
            ) slave (
                .clk(clk),
                .rst(rst),
                .awid(m_awid[gi]),
                .awaddr(m_awaddr[gi]),
                .awlen(m_awlen[gi]),
                .awsize(m_awsize[gi]),
                .awburst(m_awburst[gi]),
                .awlock(m_awlock[gi]),
                .awcache(m_awcache[gi]),
                .awprot(m_awprot[gi]),
                .awqos(m_awqos[gi]),
                .awuser(m_awuser[gi]),
                .awvalid(m_awvalid[gi]),
                .awready(m_awready[gi]),
                .wdata(m_wdata[gi]),
                .wstrb(m_wstrb[gi]),
                .wlast(m_wlast[gi]),
                .wuser(m_wuser[gi]),
                .wvalid(m_wvalid[gi]),
                .wready(m_wready[gi]),
                .bid(m_bid[gi]),
                .bresp(m_bresp[gi]),
                .buser(m_buser[gi]),
                .bvalid(m_bvalid[gi]),
                .bready(m_bready[gi]),
                .arid(m_arid[gi]),
                .araddr(m_araddr[gi]),
                .arlen(m_arlen[gi]),
                .arsize(m_arsize[gi]),
                .arburst(m_arburst[gi]),
                .arlock(m_arlock[gi]),
                .arcache(m_arcache[gi]),
                .arprot(m_arprot[gi]),
                .arqos(m_arqos[gi]),
                .aruser(m_aruser[gi]),
                .arvalid(m_arvalid[gi]),
                .arready(m_arready[gi]),
                .rid(m_rid[gi]),
                .rdata(m_rdata[gi]),
                .rresp(m_rresp[gi]),
                .rlast(m_rlast[gi]),
                .ruser(m_ruser[gi]),
                .rvalid(m_rvalid[gi]),
                .rready(m_rready[gi]),
                .route_errors(m_route_errors[gi]),
                .protocol_errors(m_protocol_errors[gi])
            );
        end
    endgenerate

    // =========================================================================
    // Clock
    // =========================================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // =========================================================================
    // Scoreboard and helpers
    // =========================================================================

    reg [DATA_WIDTH-1:0] ref_mem [0:3][0:MEM_WORDS-1];
    integer errors;

    function automatic int addr_to_master(input [ADDR_WIDTH-1:0] addr);
        begin
            if (addr <= 32'h0FFF_FFFF)
                addr_to_master = 0;
            else if (addr >= 32'h1000_0000 && addr <= 32'h1FFF_FFFF)
                addr_to_master = 1;
            else if (addr >= 32'h2000_0000 && addr <= 32'h2000_0FFF)
                addr_to_master = 2;
            else if (addr >= 32'h3000_0000 && addr <= 32'h3FFF_FFFF)
                addr_to_master = 3;
            else
                addr_to_master = -1;
        end
    endfunction

    function automatic int addr_to_index(input [ADDR_WIDTH-1:0] addr);
        begin
            addr_to_index = (addr >> 2) & (MEM_WORDS - 1);
        end
    endfunction

    task automatic check_value(input string name, input [31:0] got, input [31:0] exp);
        begin
            if (got !== exp) begin
                errors = errors + 1;
                $display("ERROR: %s: got 0x%08h, expected 0x%08h (time %0t)",
                         name, got, exp, $time);
            end
        end
    endtask

    // =========================================================================
    // AXI4 master BFM tasks
    // =========================================================================

    task automatic axi_write(
        input int                port,
        input [ADDR_WIDTH-1:0]   addr,
        input [DATA_WIDTH-1:0]   data,
        input [ID_WIDTH-1:0]     id
    );
        reg [1:0]        bresp;
        reg [ID_WIDTH-1:0] bid;
        int              m;
        begin
            @(negedge clk);

            s_awid[port]    = id;
            s_awaddr[port]  = addr;
            s_awlen[port]   = 8'd0;
            s_awsize[port]  = 3'b010;      // 4 bytes
            s_awburst[port] = 2'b01;       // INCR
            s_awlock[port]  = 1'b0;
            s_awcache[port] = 4'b0000;
            s_awprot[port]  = 3'b000;
            s_awqos[port]   = 4'b0000;
            s_awuser[port]  = '0;
            s_awvalid[port] = 1'b1;

            s_wdata[port]   = data;
            s_wstrb[port]   = {STRB_WIDTH{1'b1}};
            s_wlast[port]   = 1'b1;
            s_wuser[port]   = '0;
            s_wvalid[port]  = 1'b1;

            // AW and W may be accepted in different cycles by this crossbar.
            fork
                begin
                    do @(posedge clk); while (!s_awready[port]);
                end
                begin
                    do @(posedge clk); while (!s_wready[port]);
                end
            join

            @(negedge clk);
            s_awvalid[port] = 1'b0;
            s_wvalid[port]  = 1'b0;

            while (!s_bvalid[port])
                @(posedge clk);

            bresp = s_bresp[port];
            bid   = s_bid[port];

            check_value("write bid", bid, id);

            m = addr_to_master(addr);
            if (m < 0) begin
                check_value("write unmapped bresp", bresp, RESP_DECERR);
            end else begin
                check_value("write bresp", bresp, RESP_OKAY);
                ref_mem[m][addr_to_index(addr)] = data;
            end

            @(posedge clk);
        end
    endtask

    task automatic axi_read(
        input  int               port,
        input  [ADDR_WIDTH-1:0]  addr,
        output [DATA_WIDTH-1:0]  data,
        input  [ID_WIDTH-1:0]    id
    );
        reg [1:0]          rresp;
        reg [ID_WIDTH-1:0] rid;
        int                m;
        begin
            @(negedge clk);

            s_arid[port]    = id;
            s_araddr[port]  = addr;
            s_arlen[port]   = 8'd0;
            s_arsize[port]  = 3'b010;      // 4 bytes
            s_arburst[port] = 2'b01;       // INCR
            s_arlock[port]  = 1'b0;
            s_arcache[port] = 4'b0000;
            s_arprot[port]  = 3'b000;
            s_arqos[port]   = 4'b0000;
            s_aruser[port]  = '0;
            s_arvalid[port] = 1'b1;

            do @(posedge clk); while (!s_arready[port]);

            @(negedge clk);
            s_arvalid[port] = 1'b0;

            while (!s_rvalid[port])
                @(posedge clk);

            data  = s_rdata[port];
            rresp = s_rresp[port];
            rid   = s_rid[port];

            check_value("read rid", rid, id);
            check_value("read rlast", s_rlast[port], 1'b1);

            m = addr_to_master(addr);
            if (m < 0) begin
                check_value("read unmapped rresp", rresp, RESP_DECERR);
                check_value("read unmapped rdata", data, 32'h0000_0000);
            end else begin
                check_value("read rresp", rresp, RESP_OKAY);
                check_value("read rdata", data, ref_mem[m][addr_to_index(addr)]);
            end

            @(posedge clk);
        end
    endtask

    // =========================================================================
    // Test sequence
    // =========================================================================

    integer p, m, a, k;
    reg [ADDR_WIDTH-1:0] test_addr;
    reg [DATA_WIDTH-1:0] test_data;
    reg [DATA_WIDTH-1:0] read_data;
    reg [ID_WIDTH-1:0]   test_id;

    initial begin
        errors = 0;

        // Mirror of the memory contents in the subordinate models.
        for (m = 0; m < M_COUNT; m = m + 1) begin
            for (k = 0; k < MEM_WORDS; k = k + 1) begin
                ref_mem[m][k] = 32'hA000_0000 + (m * 32'h0100_0000) + k;
            end
        end

        // Initialise all manager-side inputs.
        for (p = 0; p < S_COUNT; p = p + 1) begin
            s_awid[p]    = '0;
            s_awaddr[p]  = '0;
            s_awlen[p]   = 8'd0;
            s_awsize[p]  = 3'b010;
            s_awburst[p] = 2'b01;
            s_awlock[p]  = 1'b0;
            s_awcache[p] = 4'b0000;
            s_awprot[p]  = 3'b000;
            s_awqos[p]   = 4'b0000;
            s_awuser[p]  = '0;
            s_awvalid[p] = 1'b0;

            s_wdata[p]   = '0;
            s_wstrb[p]   = '0;
            s_wlast[p]   = 1'b1;
            s_wuser[p]   = '0;
            s_wvalid[p]  = 1'b0;

            s_bready[p]  = 1'b1;

            s_arid[p]    = '0;
            s_araddr[p]  = '0;
            s_arlen[p]   = 8'd0;
            s_arsize[p]  = 3'b010;
            s_arburst[p] = 2'b01;
            s_arlock[p]  = 1'b0;
            s_arcache[p] = 4'b0000;
            s_arprot[p]  = 3'b000;
            s_arqos[p]   = 4'b0000;
            s_aruser[p]  = '0;
            s_arvalid[p] = 1'b0;

            s_rready[p]  = 1'b1;
        end

        rst = 1'b1;
        repeat (5) @(posedge clk);
        rst = 1'b0;
        repeat (2) @(posedge clk);

        // ---------------------------------------------------------------------
        $display("");
        $display("========================================================");
        $display("TEST 1: read reset pattern from all 4 manager ports");
        $display("        to all 4 subordinate regions");
        $display("========================================================");

        for (p = 0; p < S_COUNT; p = p + 1) begin
            for (m = 0; m < M_COUNT; m = m + 1) begin
                for (a = 0; a < 8; a = a + 1) begin
                    test_addr = BASE_ADDR[m] + (a * 4);
                    test_id   = 8'h10 + p;
                    axi_read(p, test_addr, read_data, test_id);
                end
            end
        end

        // ---------------------------------------------------------------------
        $display("");
        $display("========================================================");
        $display("TEST 2: write/read matrix, all manager ports to all");
        $display("        subordinate regions");
        $display("========================================================");

        for (p = 0; p < S_COUNT; p = p + 1) begin
            for (m = 0; m < M_COUNT; m = m + 1) begin
                for (a = 0; a < 8; a = a + 1) begin
                    test_addr = BASE_ADDR[m] + (a * 4);
                    test_data = 32'hC000_0000 | (p << 12) | (m << 8) | a;
                    test_id   = 8'h20 + p;

                    axi_write(p, test_addr, test_data, test_id);
                    axi_read(p, test_addr, read_data, test_id);
                end
            end
        end

        // ---------------------------------------------------------------------
        $display("");
        $display("========================================================");
        $display("TEST 3: unmapped address returns DECERR");
        $display("========================================================");

        axi_read(0, 32'h9000_0000, read_data, 8'hEE);
        axi_write(1, 32'h9000_0000, 32'hDEAD_BEEF, 8'hEF);

        // ---------------------------------------------------------------------
        $display("");
        $display("========================================================");
        $display("TEST 4: concurrent requests from all manager ports");
        $display("        to four different subordinates");
        $display("========================================================");

        fork
            axi_write(0, BASE_ADDR[0] + 32'h40, 32'h1111_0000, 8'h30);
            axi_write(1, BASE_ADDR[1] + 32'h40, 32'h2222_0000, 8'h31);
            axi_write(2, BASE_ADDR[2] + 32'h40, 32'h3333_0000, 8'h32);
            axi_write(3, BASE_ADDR[3] + 32'h40, 32'h4444_0000, 8'h33);
        join

        axi_read(0, BASE_ADDR[0] + 32'h40, read_data, 8'h40);
        axi_read(1, BASE_ADDR[1] + 32'h40, read_data, 8'h41);
        axi_read(2, BASE_ADDR[2] + 32'h40, read_data, 8'h42);
        axi_read(3, BASE_ADDR[3] + 32'h40, read_data, 8'h43);

        // ---------------------------------------------------------------------
        $display("");
        $display("========================================================");
        $display("TEST 5: concurrent requests from all manager ports");
        $display("        to the SAME subordinate (arbitration)");
        $display("========================================================");

        // All four managers target SRAM with different addresses.  The
        // crossbar must serialise them without dropping or corrupting any
        // write.  Each read-back is compared against the write value by the
        // scoreboard in axi_read().
        fork
            axi_write(0, BASE_ADDR[0] + 32'h80, 32'hA000_0000, 8'h50);
            axi_write(1, BASE_ADDR[0] + 32'h84, 32'hA000_0001, 8'h51);
            axi_write(2, BASE_ADDR[0] + 32'h88, 32'hA000_0002, 8'h52);
            axi_write(3, BASE_ADDR[0] + 32'h8C, 32'hA000_0003, 8'h53);
        join

        axi_read(0, BASE_ADDR[0] + 32'h80, read_data, 8'h60);
        axi_read(1, BASE_ADDR[0] + 32'h84, read_data, 8'h61);
        axi_read(2, BASE_ADDR[0] + 32'h88, read_data, 8'h62);
        axi_read(3, BASE_ADDR[0] + 32'h8C, read_data, 8'h63);

        // ---------------------------------------------------------------------
        $display("");
        $display("========================================================");
        $display("TEST 6: subordinate model routing/protocol checks");
        $display("========================================================");

        for (m = 0; m < M_COUNT; m = m + 1) begin
            check_value("route_errors",   m_route_errors[m],    32'd0);
            check_value("protocol_errors", m_protocol_errors[m], 32'd0);
        end

        // ---------------------------------------------------------------------
        $display("");
        $display("========================================================");
        if (errors == 0) begin
            $display("RESULT: TEST PASSED");
            $display("========================================================");
            $display("");
            $finish;
        end else begin
            $display("RESULT: TEST FAILED with %0d error(s)", errors);
            $display("========================================================");
            $display("");
            // Non-zero exit status so that `make interconnect` fails too.
            $fatal(1, "self-check failed");
        end
    end

    // Watchdog: a stuck handshake must fail the run instead of hanging.
    initial begin
        #200_000_000;
        $fatal(1, "TIMEOUT: simulation did not finish");
    end

    // =========================================================================
    // Waveform dump (optional: run with +fsdb)
    // =========================================================================

    initial begin
        if ($test$plusargs("fsdb")) begin
            $fsdbDumpfile("dump.fsdb");
            $fsdbDumpvars(0, tb_axi_interconnect_4x4);
        end
    end

endmodule


// =============================================================================
// Simple AXI4 subordinate memory model
//
// Supports single-beat transactions (arlen = awlen = 0).  It returns OKAY for
// addresses inside its region and SLVERR for an address that should never have
// been routed to it.  The model also exposes counters so the testbench can
// verify that no transaction was mis-routed and no protocol rule was broken.
// =============================================================================

module axi_slave_model #(
    parameter DATA_WIDTH   = 32,
    parameter ADDR_WIDTH   = 32,
    parameter STRB_WIDTH   = DATA_WIDTH / 8,
    parameter ID_WIDTH     = 8,
    parameter AWUSER_WIDTH = 1,
    parameter WUSER_WIDTH  = 1,
    parameter BUSER_WIDTH  = 1,
    parameter ARUSER_WIDTH = 1,
    parameter RUSER_WIDTH  = 1,
    parameter integer MEM_WORDS    = 256,
    parameter integer MEM_IDX_BITS = 8,
    parameter integer ID           = 0,
    parameter [ADDR_WIDTH-1:0] BASE_ADDR    = 0,
    parameter integer REGION_WIDTH = 32
) (
    input  wire clk,
    input  wire rst,

    input  wire [ID_WIDTH-1:0]     awid,
    input  wire [ADDR_WIDTH-1:0]   awaddr,
    input  wire [7:0]              awlen,
    input  wire [2:0]              awsize,
    input  wire [1:0]              awburst,
    input  wire                    awlock,
    input  wire [3:0]              awcache,
    input  wire [2:0]              awprot,
    input  wire [3:0]              awqos,
    input  wire [AWUSER_WIDTH-1:0] awuser,
    input  wire                    awvalid,
    output wire                    awready,

    input  wire [DATA_WIDTH-1:0]   wdata,
    input  wire [STRB_WIDTH-1:0]   wstrb,
    input  wire                    wlast,
    input  wire [WUSER_WIDTH-1:0]  wuser,
    input  wire                    wvalid,
    output wire                    wready,

    output wire [ID_WIDTH-1:0]     bid,
    output wire [1:0]              bresp,
    output wire [BUSER_WIDTH-1:0]  buser,
    output wire                    bvalid,
    input  wire                    bready,

    input  wire [ID_WIDTH-1:0]     arid,
    input  wire [ADDR_WIDTH-1:0]   araddr,
    input  wire [7:0]              arlen,
    input  wire [2:0]              arsize,
    input  wire [1:0]              arburst,
    input  wire                    arlock,
    input  wire [3:0]              arcache,
    input  wire [2:0]              arprot,
    input  wire [3:0]              arqos,
    input  wire [ARUSER_WIDTH-1:0] aruser,
    input  wire                    arvalid,
    output wire                    arready,

    output wire [ID_WIDTH-1:0]     rid,
    output wire [DATA_WIDTH-1:0]   rdata,
    output wire [1:0]              rresp,
    output wire                    rlast,
    output wire [RUSER_WIDTH-1:0]  ruser,
    output wire                    rvalid,
    input  wire                    rready,

    output reg  [31:0]             route_errors,
    output reg  [31:0]             protocol_errors
);

    reg [DATA_WIDTH-1:0] mem [0:MEM_WORDS-1];

    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg [ID_WIDTH-1:0]   awid_reg;
    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [STRB_WIDTH-1:0] wstrb_reg;
    reg                  aw_hs;
    reg                  w_hs;

    reg                  bvalid_reg;
    reg [ID_WIDTH-1:0]   bid_reg;
    reg [1:0]            bresp_reg;

    reg [ADDR_WIDTH-1:0] araddr_reg;
    reg [ID_WIDTH-1:0]   arid_reg;
    reg [DATA_WIDTH-1:0] rdata_reg;
    reg [1:0]            rresp_reg;
    reg                  rvalid_reg;

    integer i;
    integer b;

    assign awready = !aw_hs && !bvalid_reg;
    assign wready  = !w_hs  && !bvalid_reg;

    assign bid    = bid_reg;
    assign bresp  = bresp_reg;
    assign buser  = {BUSER_WIDTH{1'b0}};
    assign bvalid = bvalid_reg;

    assign arready = !rvalid_reg;

    assign rid    = arid_reg;
    assign rdata  = rdata_reg;
    assign rresp  = rresp_reg;
    assign rlast  = 1'b1;
    assign ruser  = {RUSER_WIDTH{1'b0}};
    assign rvalid = rvalid_reg;

    function automatic in_region(input [ADDR_WIDTH-1:0] addr);
        begin
            in_region = (addr >> REGION_WIDTH) == (BASE_ADDR >> REGION_WIDTH);
        end
    endfunction

    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1) begin
            mem[i] = 32'hA000_0000 + (ID * 32'h0100_0000) + i;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            aw_hs           <= 1'b0;
            w_hs            <= 1'b0;
            bvalid_reg      <= 1'b0;
            bid_reg         <= {ID_WIDTH{1'b0}};
            bresp_reg       <= 2'b00;
            rvalid_reg      <= 1'b0;
            arid_reg        <= {ID_WIDTH{1'b0}};
            rdata_reg       <= {DATA_WIDTH{1'b0}};
            rresp_reg       <= 2'b00;
            route_errors    <= 32'd0;
            protocol_errors <= 32'd0;
        end else begin
            // Write address handshake
            if (awvalid && awready) begin
                aw_hs       <= 1'b1;
                awaddr_reg  <= awaddr;
                awid_reg    <= awid;

                if (!in_region(awaddr)) begin
                    route_errors <= route_errors + 32'd1;
                end
                if (awlen != 8'd0) begin
                    protocol_errors <= protocol_errors + 32'd1;
                end
            end

            // Write data handshake
            if (wvalid && wready) begin
                w_hs      <= 1'b1;
                wdata_reg <= wdata;
                wstrb_reg <= wstrb;

                if (!wlast) begin
                    protocol_errors <= protocol_errors + 32'd1;
                end
            end

            // Commit the write once both AW and W have been accepted.
            if (aw_hs && w_hs && !bvalid_reg) begin
                for (b = 0; b < STRB_WIDTH; b = b + 1) begin
                    if (wstrb_reg[b]) begin
                        mem[awaddr_reg[2 +: MEM_IDX_BITS]][b*8 +: 8] <= wdata_reg[b*8 +: 8];
                    end
                end

                bvalid_reg <= 1'b1;
                bid_reg    <= awid_reg;
                bresp_reg  <= in_region(awaddr_reg) ? 2'b00 : 2'b10;
                aw_hs      <= 1'b0;
                w_hs       <= 1'b0;
            end

            if (bvalid_reg && bready) begin
                bvalid_reg <= 1'b0;
            end

            // Read address handshake / read response handshake
            if (arvalid && arready) begin
                araddr_reg <= araddr;
                arid_reg   <= arid;
                rdata_reg  <= mem[araddr[2 +: MEM_IDX_BITS]];
                rresp_reg  <= in_region(araddr) ? 2'b00 : 2'b10;
                rvalid_reg <= 1'b1;

                if (!in_region(araddr)) begin
                    route_errors <= route_errors + 32'd1;
                end
                if (arlen != 8'd0) begin
                    protocol_errors <= protocol_errors + 32'd1;
                end
            end else if (rvalid_reg && rready) begin
                rvalid_reg <= 1'b0;
            end
        end
    end

endmodule
