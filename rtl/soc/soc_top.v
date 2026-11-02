// VeeR EL2 SoC top-level (skeleton for Task 4).
// Spec reset is active-low rst_l; interconnect/RTL use active-high rst.
`timescale 1ns / 1ps

module soc_top #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 8
) (
    input  wire                   clk,
    input  wire                   rst_l,   // active-low per spec

    // Manager port 0: CPU IFU (exposed for verification)
    input  wire [ID_WIDTH-1:0]     m0_awid, input wire [ADDR_WIDTH-1:0] m0_awaddr,
    input  wire [7:0]              m0_awlen, input wire [2:0] m0_awsize, input wire [1:0] m0_awburst,
    input  wire                    m0_awlock, input wire [3:0] m0_awcache, input wire [2:0] m0_awprot,
    input  wire [3:0]              m0_awqos, input wire [3:0] m0_awregion, input wire m0_awuser,
    input  wire                    m0_awvalid, output wire m0_awready,
    input  wire [DATA_WIDTH-1:0]    m0_wdata, input wire [DATA_WIDTH/8-1:0] m0_wstrb,
    input  wire                    m0_wlast, input wire m0_wuser, input wire m0_wvalid, output wire m0_wready,
    output wire [ID_WIDTH-1:0]      m0_bid, output wire [1:0] m0_bresp, output wire m0_buser,
    output wire                    m0_bvalid, input  wire m0_bready,
    input  wire [ID_WIDTH-1:0]      m0_arid, input wire [ADDR_WIDTH-1:0] m0_araddr,
    input  wire [7:0]              m0_arlen, input wire [2:0] m0_arsize, input wire [1:0] m0_arburst,
    input  wire                    m0_arlock, input wire [3:0] m0_arcache, input wire [2:0] m0_arprot,
    input  wire [3:0]              m0_arqos, input wire [3:0] m0_arregion, input wire m0_aruser,
    input  wire                    m0_arvalid, output wire m0_arready,
    output wire [ID_WIDTH-1:0]      m0_rid, output wire [DATA_WIDTH-1:0] m0_rdata,
    output wire [1:0]              m0_rresp, output wire m0_rlast, output wire m0_ruser,
    output wire                    m0_rvalid, input  wire m0_rready,

    // Manager port 1: CPU LSU
    input  wire [ID_WIDTH-1:0]     m1_awid, input wire [ADDR_WIDTH-1:0] m1_awaddr,
    input  wire [7:0]              m1_awlen, input wire [2:0] m1_awsize, input wire [1:0] m1_awburst,
    input  wire                    m1_awlock, input wire [3:0] m1_awcache, input wire [2:0] m1_awprot,
    input  wire [3:0]              m1_awqos, input wire [3:0] m1_awregion, input wire m1_awuser,
    input  wire                    m1_awvalid, output wire m1_awready,
    input  wire [DATA_WIDTH-1:0]    m1_wdata, input wire [DATA_WIDTH/8-1:0] m1_wstrb,
    input  wire                    m1_wlast, input wire m1_wuser, input wire m1_wvalid, output wire m1_wready,
    output wire [ID_WIDTH-1:0]      m1_bid, output wire [1:0] m1_bresp, output wire m1_buser,
    output wire                    m1_bvalid, input  wire m1_bready,
    input  wire [ID_WIDTH-1:0]      m1_arid, input wire [ADDR_WIDTH-1:0] m1_araddr,
    input  wire [7:0]              m1_arlen, input wire [2:0] m1_arsize, input wire [1:0] m1_arburst,
    input  wire                    m1_arlock, input wire [3:0] m1_arcache, input wire [2:0] m1_arprot,
    input  wire [3:0]              m1_arqos, input wire [3:0] m1_arregion, input wire m1_aruser,
    input  wire                    m1_arvalid, output wire m1_arready,
    output wire [ID_WIDTH-1:0]      m1_rid, output wire [DATA_WIDTH-1:0] m1_rdata,
    output wire [1:0]              m1_rresp, output wire m1_rlast, output wire m1_ruser,
    output wire                    m1_rvalid, input  wire m1_rready,

    // Manager port 2: Debug/sb
    input  wire [ID_WIDTH-1:0]     m2_awid, input wire [ADDR_WIDTH-1:0] m2_awaddr,
    input  wire [7:0]              m2_awlen, input wire [2:0] m2_awsize, input wire [1:0] m2_awburst,
    input  wire                    m2_awlock, input wire [3:0] m2_awcache, input wire [2:0] m2_awprot,
    input  wire [3:0]              m2_awqos, input wire [3:0] m2_awregion, input wire m2_awuser,
    input  wire                    m2_awvalid, output wire m2_awready,
    input  wire [DATA_WIDTH-1:0]    m2_wdata, input wire [DATA_WIDTH/8-1:0] m2_wstrb,
    input  wire                    m2_wlast, input wire m2_wuser, input wire m2_wvalid, output wire m2_wready,
    output wire [ID_WIDTH-1:0]      m2_bid, output wire [1:0] m2_bresp, output wire m2_buser,
    output wire                    m2_bvalid, input  wire m2_bready,
    input  wire [ID_WIDTH-1:0]      m2_arid, input wire [ADDR_WIDTH-1:0] m2_araddr,
    input  wire [7:0]              m2_arlen, input wire [2:0] m2_arsize, input wire [1:0] m2_arburst,
    input  wire                    m2_arlock, input wire [3:0] m2_arcache, input wire [2:0] m2_arprot,
    input  wire [3:0]              m2_arqos, input wire [3:0] m2_arregion, input wire m2_aruser,
    input  wire                    m2_arvalid, output wire m2_arready,
    output wire [ID_WIDTH-1:0]      m2_rid, output wire [DATA_WIDTH-1:0] m2_rdata,
    output wire [1:0]              m2_rresp, output wire m2_rlast, output wire m2_ruser,
    output wire                    m2_rvalid, input  wire m2_rready,

    // Manager port 3: DMA
    input  wire [ID_WIDTH-1:0]     m3_awid, input wire [ADDR_WIDTH-1:0] m3_awaddr,
    input  wire [7:0]              m3_awlen, input wire [2:0] m3_awsize, input wire [1:0] m3_awburst,
    input  wire                    m3_awlock, input wire [3:0] m3_awcache, input wire [2:0] m3_awprot,
    input  wire [3:0]              m3_awqos, input wire [3:0] m3_awregion, input wire m3_awuser,
    input  wire                    m3_awvalid, output wire m3_awready,
    input  wire [DATA_WIDTH-1:0]    m3_wdata, input wire [DATA_WIDTH/8-1:0] m3_wstrb,
    input  wire                    m3_wlast, input wire m3_wuser, input wire m3_wvalid, output wire m3_wready,
    output wire [ID_WIDTH-1:0]      m3_bid, output wire [1:0] m3_bresp, output wire m3_buser,
    output wire                    m3_bvalid, input  wire m3_bready,
    input  wire [ID_WIDTH-1:0]      m3_arid, input wire [ADDR_WIDTH-1:0] m3_araddr,
    input  wire [7:0]              m3_arlen, input wire [2:0] m3_arsize, input wire [1:0] m3_arburst,
    input  wire                    m3_arlock, input wire [3:0] m3_arcache, input wire [2:0] m3_arprot,
    input  wire [3:0]              m3_arqos, input wire [3:0] m3_arregion, input wire m3_aruser,
    input  wire                    m3_arvalid, output wire m3_arready,
    output wire [ID_WIDTH-1:0]      m3_rid, output wire [DATA_WIDTH-1:0] m3_rdata,
    output wire [1:0]              m3_rresp, output wire m3_rlast, output wire m3_ruser,
    output wire                    m3_rvalid, input  wire m3_rready
);

    // Clock/reset unit: active-low rst_l in, sequenced active-high rst out.
    wire rst;
    cru #(.RESET_CYCLES(8)) u_cru (
        .clk_in (clk),
        .rst_l  (rst_l),
        .clk    (),
        .rst    (rst),
        .rst_n  (),
        .por_done()
    );

    // Internal subordinate (interconnect -> RAM) wires
    wire [7:0] r0_awid;
    wire [ADDR_WIDTH-1:0] r0_awaddr;
    wire [7:0] r0_awlen;
    wire [2:0] r0_awsize;
    wire [1:0] r0_awburst;
    wire r0_awlock;
    wire [3:0] r0_awcache;
    wire [2:0] r0_awprot;
    wire [3:0] r0_awqos;
    wire [3:0] r0_awregion;
    wire r0_awuser;
    wire r0_awvalid;
    wire r0_awready;
    wire [DATA_WIDTH-1:0] r0_wdata;
    wire [DATA_WIDTH/8-1:0] r0_wstrb;
    wire r0_wlast;
    wire r0_wuser;
    wire r0_wvalid;
    wire r0_wready;
    wire [7:0] r0_bid;
    wire [1:0] r0_bresp;
    wire r0_buser;
    wire r0_bvalid;
    wire r0_bready;
    wire [7:0] r0_arid;
    wire [ADDR_WIDTH-1:0] r0_araddr;
    wire [7:0] r0_arlen;
    wire [2:0] r0_arsize;
    wire [1:0] r0_arburst;
    wire r0_arlock;
    wire [3:0] r0_arcache;
    wire [2:0] r0_arprot;
    wire [3:0] r0_arqos;
    wire [3:0] r0_arregion;
    wire r0_aruser;
    wire r0_arvalid;
    wire r0_arready;
    wire [7:0] r0_rid;
    wire [DATA_WIDTH-1:0] r0_rdata;
    wire [1:0] r0_rresp;
    wire r0_rlast;
    wire r0_ruser;
    wire r0_rvalid;
    wire r0_rready;
    wire [7:0] r1_awid;
    wire [ADDR_WIDTH-1:0] r1_awaddr;
    wire [7:0] r1_awlen;
    wire [2:0] r1_awsize;
    wire [1:0] r1_awburst;
    wire r1_awlock;
    wire [3:0] r1_awcache;
    wire [2:0] r1_awprot;
    wire [3:0] r1_awqos;
    wire [3:0] r1_awregion;
    wire r1_awuser;
    wire r1_awvalid;
    wire r1_awready;
    wire [DATA_WIDTH-1:0] r1_wdata;
    wire [DATA_WIDTH/8-1:0] r1_wstrb;
    wire r1_wlast;
    wire r1_wuser;
    wire r1_wvalid;
    wire r1_wready;
    wire [7:0] r1_bid;
    wire [1:0] r1_bresp;
    wire r1_buser;
    wire r1_bvalid;
    wire r1_bready;
    wire [7:0] r1_arid;
    wire [ADDR_WIDTH-1:0] r1_araddr;
    wire [7:0] r1_arlen;
    wire [2:0] r1_arsize;
    wire [1:0] r1_arburst;
    wire r1_arlock;
    wire [3:0] r1_arcache;
    wire [2:0] r1_arprot;
    wire [3:0] r1_arqos;
    wire [3:0] r1_arregion;
    wire r1_aruser;
    wire r1_arvalid;
    wire r1_arready;
    wire [7:0] r1_rid;
    wire [DATA_WIDTH-1:0] r1_rdata;
    wire [1:0] r1_rresp;
    wire r1_rlast;
    wire r1_ruser;
    wire r1_rvalid;
    wire r1_rready;
    wire [7:0] r2_awid;
    wire [ADDR_WIDTH-1:0] r2_awaddr;
    wire [7:0] r2_awlen;
    wire [2:0] r2_awsize;
    wire [1:0] r2_awburst;
    wire r2_awlock;
    wire [3:0] r2_awcache;
    wire [2:0] r2_awprot;
    wire [3:0] r2_awqos;
    wire [3:0] r2_awregion;
    wire r2_awuser;
    wire r2_awvalid;
    wire r2_awready;
    wire [DATA_WIDTH-1:0] r2_wdata;
    wire [DATA_WIDTH/8-1:0] r2_wstrb;
    wire r2_wlast;
    wire r2_wuser;
    wire r2_wvalid;
    wire r2_wready;
    wire [7:0] r2_bid;
    wire [1:0] r2_bresp;
    wire r2_buser;
    wire r2_bvalid;
    wire r2_bready;
    wire [7:0] r2_arid;
    wire [ADDR_WIDTH-1:0] r2_araddr;
    wire [7:0] r2_arlen;
    wire [2:0] r2_arsize;
    wire [1:0] r2_arburst;
    wire r2_arlock;
    wire [3:0] r2_arcache;
    wire [2:0] r2_arprot;
    wire [3:0] r2_arqos;
    wire [3:0] r2_arregion;
    wire r2_aruser;
    wire r2_arvalid;
    wire r2_arready;
    wire [7:0] r2_rid;
    wire [DATA_WIDTH-1:0] r2_rdata;
    wire [1:0] r2_rresp;
    wire r2_rlast;
    wire r2_ruser;
    wire r2_rvalid;
    wire r2_rready;
    wire [7:0] r3_awid;
    wire [ADDR_WIDTH-1:0] r3_awaddr;
    wire [7:0] r3_awlen;
    wire [2:0] r3_awsize;
    wire [1:0] r3_awburst;
    wire r3_awlock;
    wire [3:0] r3_awcache;
    wire [2:0] r3_awprot;
    wire [3:0] r3_awqos;
    wire [3:0] r3_awregion;
    wire r3_awuser;
    wire r3_awvalid;
    wire r3_awready;
    wire [DATA_WIDTH-1:0] r3_wdata;
    wire [DATA_WIDTH/8-1:0] r3_wstrb;
    wire r3_wlast;
    wire r3_wuser;
    wire r3_wvalid;
    wire r3_wready;
    wire [7:0] r3_bid;
    wire [1:0] r3_bresp;
    wire r3_buser;
    wire r3_bvalid;
    wire r3_bready;
    wire [7:0] r3_arid;
    wire [ADDR_WIDTH-1:0] r3_araddr;
    wire [7:0] r3_arlen;
    wire [2:0] r3_arsize;
    wire [1:0] r3_arburst;
    wire r3_arlock;
    wire [3:0] r3_arcache;
    wire [2:0] r3_arprot;
    wire [3:0] r3_arqos;
    wire [3:0] r3_arregion;
    wire r3_aruser;
    wire r3_arvalid;
    wire r3_arready;
    wire [7:0] r3_rid;
    wire [DATA_WIDTH-1:0] r3_rdata;
    wire [1:0] r3_rresp;
    wire r3_rlast;
    wire r3_ruser;
    wire r3_rvalid;
    wire r3_rready;


    // Internal subordinate AXI ports (interconnect master side)
    wire [31:0] s_awid [0:3], s_awaddr [0:3]; // placeholders not used
    // We instead connect interconnect's m00..m03 to axi_ram instances directly.

    // Interconnect instance (generated 4x4 wrapper)
    // Manager ports connected to top-level manager ports.
    axi_interconnect_wrap_4x4 #(
        .DATA_WIDTH   (DATA_WIDTH),
        .ADDR_WIDTH   (ADDR_WIDTH),
        .ID_WIDTH     (ID_WIDTH),
        .M_REGIONS    (1),
        .M00_BASE_ADDR(32'h0000_0000),
        .M01_BASE_ADDR(32'h1000_0000),
        .M02_BASE_ADDR(32'h2000_0000),
        .M03_BASE_ADDR(32'h3000_0000),
        .M00_ADDR_WIDTH(28),
        .M01_ADDR_WIDTH(28),
        .M02_ADDR_WIDTH(12),
        .M03_ADDR_WIDTH(28)
    ) u_xbar (
        // S00 CPU IFU
        .s00_axi_awid(m0_awid), .s00_axi_awaddr(m0_awaddr), .s00_axi_awlen(m0_awlen),
        .s00_axi_awsize(m0_awsize), .s00_axi_awburst(m0_awburst), .s00_axi_awlock(m0_awlock),
        .s00_axi_awcache(m0_awcache), .s00_axi_awprot(m0_awprot), .s00_axi_awqos(m0_awqos),
        .s00_axi_awvalid(m0_awvalid),
        .s00_axi_awready(m0_awready),
        .s00_axi_wdata(m0_wdata), .s00_axi_wstrb(m0_wstrb), .s00_axi_wlast(m0_wlast),
        .s00_axi_wuser(m0_wuser), .s00_axi_wvalid(m0_wvalid), .s00_axi_wready(m0_wready),
        .s00_axi_bid(m0_bid), .s00_axi_bresp(m0_bresp), .s00_axi_buser(m0_buser),
        .s00_axi_bvalid(m0_bvalid), .s00_axi_bready(m0_bready),
        .s00_axi_arid(m0_arid), .s00_axi_araddr(m0_araddr), .s00_axi_arlen(m0_arlen),
        .s00_axi_arsize(m0_arsize), .s00_axi_arburst(m0_arburst), .s00_axi_arlock(m0_arlock),
        .s00_axi_arcache(m0_arcache), .s00_axi_arprot(m0_arprot), .s00_axi_arqos(m0_arqos),
        .s00_axi_arvalid(m0_arvalid),
        .s00_axi_arready(m0_arready),
        .s00_axi_rid(m0_rid), .s00_axi_rdata(m0_rdata), .s00_axi_rresp(m0_rresp),
        .s00_axi_rlast(m0_rlast), .s00_axi_ruser(m0_ruser), .s00_axi_rvalid(m0_rvalid),
        .s00_axi_rready(m0_rready),

        // S01 CPU LSU
        .s01_axi_awid(m1_awid), .s01_axi_awaddr(m1_awaddr), .s01_axi_awlen(m1_awlen),
        .s01_axi_awsize(m1_awsize), .s01_axi_awburst(m1_awburst), .s01_axi_awlock(m1_awlock),
        .s01_axi_awcache(m1_awcache), .s01_axi_awprot(m1_awprot), .s01_axi_awqos(m1_awqos),
        .s01_axi_awvalid(m1_awvalid),
        .s01_axi_awready(m1_awready),
        .s01_axi_wdata(m1_wdata), .s01_axi_wstrb(m1_wstrb), .s01_axi_wlast(m1_wlast),
        .s01_axi_wuser(m1_wuser), .s01_axi_wvalid(m1_wvalid), .s01_axi_wready(m1_wready),
        .s01_axi_bid(m1_bid), .s01_axi_bresp(m1_bresp), .s01_axi_buser(m1_buser),
        .s01_axi_bvalid(m1_bvalid), .s01_axi_bready(m1_bready),
        .s01_axi_arid(m1_arid), .s01_axi_araddr(m1_araddr), .s01_axi_arlen(m1_arlen),
        .s01_axi_arsize(m1_arsize), .s01_axi_arburst(m1_arburst), .s01_axi_arlock(m1_arlock),
        .s01_axi_arcache(m1_arcache), .s01_axi_arprot(m1_arprot), .s01_axi_arqos(m1_arqos),
        .s01_axi_arvalid(m1_arvalid),
        .s01_axi_arready(m1_arready),
        .s01_axi_rid(m1_rid), .s01_axi_rdata(m1_rdata), .s01_axi_rresp(m1_rresp),
        .s01_axi_rlast(m1_rlast), .s01_axi_ruser(m1_ruser), .s01_axi_rvalid(m1_rvalid),
        .s01_axi_rready(m1_rready),

        // S02 Debug
        .s02_axi_awid(m2_awid), .s02_axi_awaddr(m2_awaddr), .s02_axi_awlen(m2_awlen),
        .s02_axi_awsize(m2_awsize), .s02_axi_awburst(m2_awburst), .s02_axi_awlock(m2_awlock),
        .s02_axi_awcache(m2_awcache), .s02_axi_awprot(m2_awprot), .s02_axi_awqos(m2_awqos),
        .s02_axi_awvalid(m2_awvalid),
        .s02_axi_awready(m2_awready),
        .s02_axi_wdata(m2_wdata), .s02_axi_wstrb(m2_wstrb), .s02_axi_wlast(m2_wlast),
        .s02_axi_wuser(m2_wuser), .s02_axi_wvalid(m2_wvalid), .s02_axi_wready(m2_wready),
        .s02_axi_bid(m2_bid), .s02_axi_bresp(m2_bresp), .s02_axi_buser(m2_buser),
        .s02_axi_bvalid(m2_bvalid), .s02_axi_bready(m2_bready),
        .s02_axi_arid(m2_arid), .s02_axi_araddr(m2_araddr), .s02_axi_arlen(m2_arlen),
        .s02_axi_arsize(m2_arsize), .s02_axi_arburst(m2_arburst), .s02_axi_arlock(m2_arlock),
        .s02_axi_arcache(m2_arcache), .s02_axi_arprot(m2_arprot), .s02_axi_arqos(m2_arqos),
        .s02_axi_arvalid(m2_arvalid),
        .s02_axi_arready(m2_arready),
        .s02_axi_rid(m2_rid), .s02_axi_rdata(m2_rdata), .s02_axi_rresp(m2_rresp),
        .s02_axi_rlast(m2_rlast), .s02_axi_ruser(m2_ruser), .s02_axi_rvalid(m2_rvalid),
        .s02_axi_rready(m2_rready),

        // S03 DMA
        .s03_axi_awid(m3_awid), .s03_axi_awaddr(m3_awaddr), .s03_axi_awlen(m3_awlen),
        .s03_axi_awsize(m3_awsize), .s03_axi_awburst(m3_awburst), .s03_axi_awlock(m3_awlock),
        .s03_axi_awcache(m3_awcache), .s03_axi_awprot(m3_awprot), .s03_axi_awqos(m3_awqos),
        .s03_axi_awvalid(m3_awvalid),
        .s03_axi_awready(m3_awready),
        .s03_axi_wdata(m3_wdata), .s03_axi_wstrb(m3_wstrb), .s03_axi_wlast(m3_wlast),
        .s03_axi_wuser(m3_wuser), .s03_axi_wvalid(m3_wvalid), .s03_axi_wready(m3_wready),
        .s03_axi_bid(m3_bid), .s03_axi_bresp(m3_bresp), .s03_axi_buser(m3_buser),
        .s03_axi_bvalid(m3_bvalid), .s03_axi_bready(m3_bready),
        .s03_axi_arid(m3_arid), .s03_axi_araddr(m3_araddr), .s03_axi_arlen(m3_arlen),
        .s03_axi_arsize(m3_arsize), .s03_axi_arburst(m3_arburst), .s03_axi_arlock(m3_arlock),
        .s03_axi_arcache(m3_arcache), .s03_axi_arprot(m3_arprot), .s03_axi_arqos(m3_arqos),
        .s03_axi_arvalid(m3_arvalid),
        .s03_axi_arready(m3_arready),
        .s03_axi_rid(m3_rid), .s03_axi_rdata(m3_rdata), .s03_axi_rresp(m3_rresp),
        .s03_axi_rlast(m3_rlast), .s03_axi_ruser(m3_ruser), .s03_axi_rvalid(m3_rvalid),
        .s03_axi_rready(m3_rready),


        .m00_axi_awid(r0_awid),
        .m00_axi_awaddr(r0_awaddr),
        .m00_axi_awlen(r0_awlen),
        .m00_axi_awsize(r0_awsize),
        .m00_axi_awburst(r0_awburst),
        .m00_axi_awlock(r0_awlock),
        .m00_axi_awcache(r0_awcache),
        .m00_axi_awprot(r0_awprot),
        .m00_axi_awqos(r0_awqos),
        .m00_axi_awuser(r0_awuser),
        .m00_axi_awvalid(r0_awvalid),
        .m00_axi_awready(r0_awready),
        .m00_axi_wdata(r0_wdata),
        .m00_axi_wstrb(r0_wstrb),
        .m00_axi_wlast(r0_wlast),
        .m00_axi_wuser(r0_wuser),
        .m00_axi_wvalid(r0_wvalid),
        .m00_axi_wready(r0_wready),
        .m00_axi_bid(r0_bid),
        .m00_axi_bresp(r0_bresp),
        .m00_axi_buser(r0_buser),
        .m00_axi_bvalid(r0_bvalid),
        .m00_axi_bready(r0_bready),
        .m00_axi_arid(r0_arid),
        .m00_axi_araddr(r0_araddr),
        .m00_axi_arlen(r0_arlen),
        .m00_axi_arsize(r0_arsize),
        .m00_axi_arburst(r0_arburst),
        .m00_axi_arlock(r0_arlock),
        .m00_axi_arcache(r0_arcache),
        .m00_axi_arprot(r0_arprot),
        .m00_axi_arqos(r0_arqos),
        .m00_axi_aruser(r0_aruser),
        .m00_axi_arvalid(r0_arvalid),
        .m00_axi_arready(r0_arready),
        .m00_axi_rid(r0_rid),
        .m00_axi_rdata(r0_rdata),
        .m00_axi_rresp(r0_rresp),
        .m00_axi_rlast(r0_rlast),
        .m00_axi_ruser(r0_ruser),
        .m00_axi_rvalid(r0_rvalid),
        .m00_axi_rready(r0_rready),
        .m01_axi_awid(r1_awid),
        .m01_axi_awaddr(r1_awaddr),
        .m01_axi_awlen(r1_awlen),
        .m01_axi_awsize(r1_awsize),
        .m01_axi_awburst(r1_awburst),
        .m01_axi_awlock(r1_awlock),
        .m01_axi_awcache(r1_awcache),
        .m01_axi_awprot(r1_awprot),
        .m01_axi_awqos(r1_awqos),
        .m01_axi_awuser(r1_awuser),
        .m01_axi_awvalid(r1_awvalid),
        .m01_axi_awready(r1_awready),
        .m01_axi_wdata(r1_wdata),
        .m01_axi_wstrb(r1_wstrb),
        .m01_axi_wlast(r1_wlast),
        .m01_axi_wuser(r1_wuser),
        .m01_axi_wvalid(r1_wvalid),
        .m01_axi_wready(r1_wready),
        .m01_axi_bid(r1_bid),
        .m01_axi_bresp(r1_bresp),
        .m01_axi_buser(r1_buser),
        .m01_axi_bvalid(r1_bvalid),
        .m01_axi_bready(r1_bready),
        .m01_axi_arid(r1_arid),
        .m01_axi_araddr(r1_araddr),
        .m01_axi_arlen(r1_arlen),
        .m01_axi_arsize(r1_arsize),
        .m01_axi_arburst(r1_arburst),
        .m01_axi_arlock(r1_arlock),
        .m01_axi_arcache(r1_arcache),
        .m01_axi_arprot(r1_arprot),
        .m01_axi_arqos(r1_arqos),
        .m01_axi_aruser(r1_aruser),
        .m01_axi_arvalid(r1_arvalid),
        .m01_axi_arready(r1_arready),
        .m01_axi_rid(r1_rid),
        .m01_axi_rdata(r1_rdata),
        .m01_axi_rresp(r1_rresp),
        .m01_axi_rlast(r1_rlast),
        .m01_axi_ruser(r1_ruser),
        .m01_axi_rvalid(r1_rvalid),
        .m01_axi_rready(r1_rready),
        .m02_axi_awid(r2_awid),
        .m02_axi_awaddr(r2_awaddr),
        .m02_axi_awlen(r2_awlen),
        .m02_axi_awsize(r2_awsize),
        .m02_axi_awburst(r2_awburst),
        .m02_axi_awlock(r2_awlock),
        .m02_axi_awcache(r2_awcache),
        .m02_axi_awprot(r2_awprot),
        .m02_axi_awqos(r2_awqos),
        .m02_axi_awuser(r2_awuser),
        .m02_axi_awvalid(r2_awvalid),
        .m02_axi_awready(r2_awready),
        .m02_axi_wdata(r2_wdata),
        .m02_axi_wstrb(r2_wstrb),
        .m02_axi_wlast(r2_wlast),
        .m02_axi_wuser(r2_wuser),
        .m02_axi_wvalid(r2_wvalid),
        .m02_axi_wready(r2_wready),
        .m02_axi_bid(r2_bid),
        .m02_axi_bresp(r2_bresp),
        .m02_axi_buser(r2_buser),
        .m02_axi_bvalid(r2_bvalid),
        .m02_axi_bready(r2_bready),
        .m02_axi_arid(r2_arid),
        .m02_axi_araddr(r2_araddr),
        .m02_axi_arlen(r2_arlen),
        .m02_axi_arsize(r2_arsize),
        .m02_axi_arburst(r2_arburst),
        .m02_axi_arlock(r2_arlock),
        .m02_axi_arcache(r2_arcache),
        .m02_axi_arprot(r2_arprot),
        .m02_axi_arqos(r2_arqos),
        .m02_axi_aruser(r2_aruser),
        .m02_axi_arvalid(r2_arvalid),
        .m02_axi_arready(r2_arready),
        .m02_axi_rid(r2_rid),
        .m02_axi_rdata(r2_rdata),
        .m02_axi_rresp(r2_rresp),
        .m02_axi_rlast(r2_rlast),
        .m02_axi_ruser(r2_ruser),
        .m02_axi_rvalid(r2_rvalid),
        .m02_axi_rready(r2_rready),
        .m03_axi_awid(r3_awid),
        .m03_axi_awaddr(r3_awaddr),
        .m03_axi_awlen(r3_awlen),
        .m03_axi_awsize(r3_awsize),
        .m03_axi_awburst(r3_awburst),
        .m03_axi_awlock(r3_awlock),
        .m03_axi_awcache(r3_awcache),
        .m03_axi_awprot(r3_awprot),
        .m03_axi_awqos(r3_awqos),
        .m03_axi_awuser(r3_awuser),
        .m03_axi_awvalid(r3_awvalid),
        .m03_axi_awready(r3_awready),
        .m03_axi_wdata(r3_wdata),
        .m03_axi_wstrb(r3_wstrb),
        .m03_axi_wlast(r3_wlast),
        .m03_axi_wuser(r3_wuser),
        .m03_axi_wvalid(r3_wvalid),
        .m03_axi_wready(r3_wready),
        .m03_axi_bid(r3_bid),
        .m03_axi_bresp(r3_bresp),
        .m03_axi_buser(r3_buser),
        .m03_axi_bvalid(r3_bvalid),
        .m03_axi_bready(r3_bready),
        .m03_axi_arid(r3_arid),
        .m03_axi_araddr(r3_araddr),
        .m03_axi_arlen(r3_arlen),
        .m03_axi_arsize(r3_arsize),
        .m03_axi_arburst(r3_arburst),
        .m03_axi_arlock(r3_arlock),
        .m03_axi_arcache(r3_arcache),
        .m03_axi_arprot(r3_arprot),
        .m03_axi_arqos(r3_arqos),
        .m03_axi_aruser(r3_aruser),
        .m03_axi_arvalid(r3_arvalid),
        .m03_axi_arready(r3_arready),
        .m03_axi_rid(r3_rid),
        .m03_axi_rdata(r3_rdata),
        .m03_axi_rresp(r3_rresp),
        .m03_axi_rlast(r3_rlast),
        .m03_axi_ruser(r3_ruser),
        .m03_axi_rvalid(r3_rvalid),
        .m03_axi_rready(r3_rready),

        .clk(clk), .rst(rst)
    );



    axi_ram #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) u_ram0 (
        .s_axi_awid(r0_awid),
        .s_axi_awaddr(r0_awaddr),
        .s_axi_awlen(r0_awlen),
        .s_axi_awsize(r0_awsize),
        .s_axi_awburst(r0_awburst),
        .s_axi_awlock(r0_awlock),
        .s_axi_awcache(r0_awcache),
        .s_axi_awprot(r0_awprot),
        .s_axi_awqos(r0_awqos),
        .s_axi_awuser(r0_awuser),
        .s_axi_awvalid(r0_awvalid),
        .s_axi_awready(r0_awready),
        .s_axi_wdata(r0_wdata),
        .s_axi_wstrb(r0_wstrb),
        .s_axi_wlast(r0_wlast),
        .s_axi_wuser(r0_wuser),
        .s_axi_wvalid(r0_wvalid),
        .s_axi_wready(r0_wready),
        .s_axi_bid(r0_bid),
        .s_axi_bresp(r0_bresp),
        .s_axi_buser(r0_buser),
        .s_axi_bvalid(r0_bvalid),
        .s_axi_bready(r0_bready),
        .s_axi_arid(r0_arid),
        .s_axi_araddr(r0_araddr),
        .s_axi_arlen(r0_arlen),
        .s_axi_arsize(r0_arsize),
        .s_axi_arburst(r0_arburst),
        .s_axi_arlock(r0_arlock),
        .s_axi_arcache(r0_arcache),
        .s_axi_arprot(r0_arprot),
        .s_axi_arqos(r0_arqos),
        .s_axi_aruser(r0_aruser),
        .s_axi_arvalid(r0_arvalid),
        .s_axi_arready(r0_arready),
        .s_axi_rid(r0_rid),
        .s_axi_rdata(r0_rdata),
        .s_axi_rresp(r0_rresp),
        .s_axi_rlast(r0_rlast),
        .s_axi_ruser(r0_ruser),
        .s_axi_rvalid(r0_rvalid),
        .s_axi_rready(r0_rready),
        .clk(clk), .rst(rst)
    );

    boot_rom #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .MEM_WORDS(256), .INIT_FILE("rtl/soc/bootrom.hex")) u_ram1 (        .clk(clk), .rst(rst),
        .s_axi_awid(r1_awid),
        .s_axi_awaddr(r1_awaddr),
        .s_axi_awlen(r1_awlen),
        .s_axi_awsize(r1_awsize),
        .s_axi_awburst(r1_awburst),
        .s_axi_awlock(r1_awlock),
        .s_axi_awcache(r1_awcache),
        .s_axi_awprot(r1_awprot),
        .s_axi_awqos(r1_awqos),
        .s_axi_awregion(r1_awregion),
        .s_axi_awuser(r1_awuser),
        .s_axi_awvalid(r1_awvalid),
        .s_axi_awready(r1_awready),
        .s_axi_wdata(r1_wdata),
        .s_axi_wstrb(r1_wstrb),
        .s_axi_wlast(r1_wlast),
        .s_axi_wuser(r1_wuser),
        .s_axi_wvalid(r1_wvalid),
        .s_axi_wready(r1_wready),
        .s_axi_bid(r1_bid),
        .s_axi_bresp(r1_bresp),
        .s_axi_buser(r1_buser),
        .s_axi_bvalid(r1_bvalid),
        .s_axi_bready(r1_bready),
        .s_axi_arid(r1_arid),
        .s_axi_araddr(r1_araddr),
        .s_axi_arlen(r1_arlen),
        .s_axi_arsize(r1_arsize),
        .s_axi_arburst(r1_arburst),
        .s_axi_arlock(r1_arlock),
        .s_axi_arcache(r1_arcache),
        .s_axi_arprot(r1_arprot),
        .s_axi_arqos(r1_arqos),
        .s_axi_arregion(r1_arregion),
        .s_axi_aruser(r1_aruser),
        .s_axi_arvalid(r1_arvalid),
        .s_axi_arready(r1_arready),
        .s_axi_rid(r1_rid),
        .s_axi_rdata(r1_rdata),
        .s_axi_rresp(r1_rresp),
        .s_axi_rlast(r1_rlast),
        .s_axi_ruser(r1_ruser),
        .s_axi_rvalid(r1_rvalid),
        .s_axi_rready(r1_rready)
    );

    ipu_config #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH)) u_ram2 (
        .clk(clk), .rst(rst),
        .s_axi_awid(r2_awid),
        .s_axi_awaddr(r2_awaddr),
        .s_axi_awlen(r2_awlen),
        .s_axi_awsize(r2_awsize),
        .s_axi_awburst(r2_awburst),
        .s_axi_awlock(r2_awlock),
        .s_axi_awcache(r2_awcache),
        .s_axi_awprot(r2_awprot),
        .s_axi_awqos(r2_awqos),
        .s_axi_awregion(r2_awregion),
        .s_axi_awuser(r2_awuser),
        .s_axi_awvalid(r2_awvalid),
        .s_axi_awready(r2_awready),
        .s_axi_wdata(r2_wdata),
        .s_axi_wstrb(r2_wstrb),
        .s_axi_wlast(r2_wlast),
        .s_axi_wuser(r2_wuser),
        .s_axi_wvalid(r2_wvalid),
        .s_axi_wready(r2_wready),
        .s_axi_bid(r2_bid),
        .s_axi_bresp(r2_bresp),
        .s_axi_buser(r2_buser),
        .s_axi_bvalid(r2_bvalid),
        .s_axi_bready(r2_bready),
        .s_axi_arid(r2_arid),
        .s_axi_araddr(r2_araddr),
        .s_axi_arlen(r2_arlen),
        .s_axi_arsize(r2_arsize),
        .s_axi_arburst(r2_arburst),
        .s_axi_arlock(r2_arlock),
        .s_axi_arcache(r2_arcache),
        .s_axi_arprot(r2_arprot),
        .s_axi_arqos(r2_arqos),
        .s_axi_arregion(r2_arregion),
        .s_axi_aruser(r2_aruser),
        .s_axi_arvalid(r2_arvalid),
        .s_axi_arready(r2_arready),
        .s_axi_rid(r2_rid),
        .s_axi_rdata(r2_rdata),
        .s_axi_rresp(r2_rresp),
        .s_axi_rlast(r2_rlast),
        .s_axi_ruser(r2_ruser),
        .s_axi_rvalid(r2_rvalid),
        .s_axi_rready(r2_rready),
        .ipu_done_irq(),
        .ipu_err_irq()
    );

    // AXI-to-APB bridge for the APB peripheral region (m03)
    wire [31:0] apb_paddr;
    wire [31:0] apb_pwdata;
    wire        apb_pwrite;
    wire        apb_psel;
    wire        apb_penable;
    wire [31:0] apb_prdata;
    wire        apb_pready;
    wire        apb_pslverr;
    wire [7:0]  apb_gpio_out;
    wire [7:0]  apb_gpio_dir;

    axi_apb_bridge #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH)) u_ram3 (
        .clk(clk), .rst(rst),
        .s_axi_awid(r3_awid),
        .s_axi_awaddr(r3_awaddr),
        .s_axi_awlen(r3_awlen),
        .s_axi_awsize(r3_awsize),
        .s_axi_awburst(r3_awburst),
        .s_axi_awlock(r3_awlock),
        .s_axi_awcache(r3_awcache),
        .s_axi_awprot(r3_awprot),
        .s_axi_awqos(r3_awqos),
        .s_axi_awregion(r3_awregion),
        .s_axi_awuser(r3_awuser),
        .s_axi_awvalid(r3_awvalid),
        .s_axi_awready(r3_awready),
        .s_axi_wdata(r3_wdata),
        .s_axi_wstrb(r3_wstrb),
        .s_axi_wlast(r3_wlast),
        .s_axi_wuser(r3_wuser),
        .s_axi_wvalid(r3_wvalid),
        .s_axi_wready(r3_wready),
        .s_axi_bid(r3_bid),
        .s_axi_bresp(r3_bresp),
        .s_axi_buser(r3_buser),
        .s_axi_bvalid(r3_bvalid),
        .s_axi_bready(r3_bready),
        .s_axi_arid(r3_arid),
        .s_axi_araddr(r3_araddr),
        .s_axi_arlen(r3_arlen),
        .s_axi_arsize(r3_arsize),
        .s_axi_arburst(r3_arburst),
        .s_axi_arlock(r3_arlock),
        .s_axi_arcache(r3_arcache),
        .s_axi_arprot(r3_arprot),
        .s_axi_arqos(r3_arqos),
        .s_axi_arregion(r3_arregion),
        .s_axi_aruser(r3_aruser),
        .s_axi_arvalid(r3_arvalid),
        .s_axi_arready(r3_arready),
        .s_axi_rid(r3_rid),
        .s_axi_rdata(r3_rdata),
        .s_axi_rresp(r3_rresp),
        .s_axi_rlast(r3_rlast),
        .s_axi_ruser(r3_ruser),
        .s_axi_rvalid(r3_rvalid),
        .s_axi_rready(r3_rready),
        .m_apb_pclk(),
        .m_apb_presetn(),
        .m_apb_paddr(apb_paddr),
        .m_apb_pwdata(apb_pwdata),
        .m_apb_pwrite(apb_pwrite),
        .m_apb_psel(apb_psel),
        .m_apb_penable(apb_penable),
        .m_apb_prdata(apb_prdata),
        .m_apb_pready(apb_pready),
        .m_apb_pslverr(apb_pslverr)
    );

    // APB peripheral subsystem behind the AXI-to-APB bridge
    apb_peripherals u_apb (
        .PCLK     (clk),
        .PRESETn  (!rst),
        .PADDR    (apb_paddr),
        .PWDATA   (apb_pwdata),
        .PWRITE   (apb_pwrite),
        .PSEL     (apb_psel),
        .PENABLE  (apb_penable),
        .PRDATA   (apb_prdata),
        .PREADY   (apb_pready),
        .PSLVERR  (apb_pslverr),
        .gpio_in  (8'd0),
        .gpio_out (apb_gpio_out),
        .gpio_dir (apb_gpio_dir),
        .uart_irq (),
        .spi_irq  (),
        .gpio_irq (),
        .timer_irq(),
        .pic_irq_lines()
    );

endmodule
