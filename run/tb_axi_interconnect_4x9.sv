`timescale 1ns / 1ps

module tb_axi_interconnect_wrap_4x9;

    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;
    parameter STRB_WIDTH = 4;
    parameter ID_WIDTH   = 8;

    parameter AWUSER_WIDTH = 1;
    parameter WUSER_WIDTH  = 1;
    parameter BUSER_WIDTH  = 1;
    parameter ARUSER_WIDTH = 1;
    parameter RUSER_WIDTH  = 1;

    reg clk;
    reg rst;

    // ============================================================
    // S00-S03 AXI SLAVE-SIDE INPUTS
    // ============================================================

    reg  [ID_WIDTH-1:0]   s00_axi_awid;
    reg  [ADDR_WIDTH-1:0] s00_axi_awaddr;
    reg  [7:0]            s00_axi_awlen;
    reg  [2:0]            s00_axi_awsize;
    reg  [1:0]            s00_axi_awburst;
    reg                   s00_axi_awlock;
    reg  [3:0]            s00_axi_awcache;
    reg  [2:0]            s00_axi_awprot;
    reg  [3:0]            s00_axi_awqos;
    reg  [AWUSER_WIDTH-1:0] s00_axi_awuser;
    reg                   s00_axi_awvalid;
    wire                  s00_axi_awready;

    reg  [DATA_WIDTH-1:0] s00_axi_wdata;
    reg  [STRB_WIDTH-1:0] s00_axi_wstrb;
    reg                   s00_axi_wlast;
    reg  [WUSER_WIDTH-1:0] s00_axi_wuser;
    reg                   s00_axi_wvalid;
    wire                  s00_axi_wready;

    wire [ID_WIDTH-1:0]     s00_axi_bid;
    wire [1:0]             s00_axi_bresp;
    wire [BUSER_WIDTH-1:0] s00_axi_buser;
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


    // ============================================================
    // S01
    // ============================================================

    wire [ID_WIDTH-1:0]   s01_axi_awid = 0;
    wire [ADDR_WIDTH-1:0] s01_axi_awaddr = 0;
    wire [7:0]            s01_axi_awlen = 0;
    wire [2:0]            s01_axi_awsize = 0;
    wire [1:0]            s01_axi_awburst = 0;
    wire                  s01_axi_awlock = 0;
    wire [3:0]            s01_axi_awcache = 0;
    wire [2:0]            s01_axi_awprot = 0;
    wire [3:0]            s01_axi_awqos = 0;
    wire [AWUSER_WIDTH-1:0] s01_axi_awuser = 0;
    wire                    s01_axi_awvalid = 0;
    wire                    s01_axi_awready;

    wire [DATA_WIDTH-1:0] s01_axi_wdata = 0;
    wire [STRB_WIDTH-1:0] s01_axi_wstrb = 0;
    wire                   s01_axi_wlast = 0;
    wire [WUSER_WIDTH-1:0] s01_axi_wuser = 0;
    wire                   s01_axi_wvalid = 0;
    wire                   s01_axi_wready;

    wire [ID_WIDTH-1:0]   s01_axi_bid;
    wire [1:0]             s01_axi_bresp;
    wire [BUSER_WIDTH-1:0] s01_axi_buser;
    wire                   s01_axi_bvalid;
    wire                   s01_axi_bready = 1;

    wire [ID_WIDTH-1:0]   s01_axi_arid = 0;
    wire [ADDR_WIDTH-1:0] s01_axi_araddr = 0;
    wire [7:0]            s01_axi_arlen = 0;
    wire [2:0]            s01_axi_arsize = 0;
    wire [1:0]            s01_axi_arburst = 0;
    wire                  s01_axi_arlock = 0;
    wire [3:0]            s01_axi_arcache = 0;
    wire [2:0]            s01_axi_arprot = 0;
    wire [3:0]            s01_axi_arqos = 0;
    wire [ARUSER_WIDTH-1:0] s01_axi_aruser = 0;
    wire                    s01_axi_arvalid = 0;
    wire                    s01_axi_arready;

    wire [ID_WIDTH-1:0]    s01_axi_rid;
    wire [DATA_WIDTH-1:0] s01_axi_rdata;
    wire [1:0]             s01_axi_rresp;
    wire                   s01_axi_rlast;
    wire [RUSER_WIDTH-1:0] s01_axi_ruser;
    wire                   s01_axi_rvalid;
    wire                   s01_axi_rready = 1;


    // ============================================================
    // S02
    // ============================================================

    wire [ID_WIDTH-1:0]   s02_axi_awid = 0;
    wire [ADDR_WIDTH-1:0] s02_axi_awaddr = 0;
    wire [7:0]            s02_axi_awlen = 0;
    wire [2:0]            s02_axi_awsize = 0;
    wire [1:0]            s02_axi_awburst = 0;
    wire                  s02_axi_awlock = 0;
    wire [3:0]            s02_axi_awcache = 0;
    wire [2:0]            s02_axi_awprot = 0;
    wire [3:0]            s02_axi_awqos = 0;
    wire [AWUSER_WIDTH-1:0] s02_axi_awuser = 0;
    wire                    s02_axi_awvalid = 0;
    wire                    s02_axi_awready;

    wire [DATA_WIDTH-1:0] s02_axi_wdata = 0;
    wire [STRB_WIDTH-1:0] s02_axi_wstrb = 0;
    wire                   s02_axi_wlast = 0;
    wire [WUSER_WIDTH-1:0] s02_axi_wuser = 0;
    wire                   s02_axi_wvalid = 0;
    wire                   s02_axi_wready;

    wire [ID_WIDTH-1:0]    s02_axi_bid;
    wire [1:0]             s02_axi_bresp;
    wire [BUSER_WIDTH-1:0] s02_axi_buser;
    wire                   s02_axi_bvalid;
    wire                   s02_axi_bready = 1;

    wire [ID_WIDTH-1:0]   s02_axi_arid = 0;
    wire [ADDR_WIDTH-1:0] s02_axi_araddr = 0;
    wire [7:0]            s02_axi_arlen = 0;
    wire [2:0]            s02_axi_arsize = 0;
    wire [1:0]            s02_axi_arburst = 0;
    wire                  s02_axi_arlock = 0;
    wire [3:0]            s02_axi_arcache = 0;
    wire [2:0]            s02_axi_arprot = 0;
    wire [3:0]            s02_axi_arqos = 0;
    wire [ARUSER_WIDTH-1:0] s02_axi_aruser = 0;
    wire                    s02_axi_arvalid = 0;
    wire                    s02_axi_arready;

    wire [ID_WIDTH-1:0]    s02_axi_rid;
    wire [DATA_WIDTH-1:0] s02_axi_rdata;
    wire [1:0]             s02_axi_rresp;
    wire                   s02_axi_rlast;
    wire [RUSER_WIDTH-1:0] s02_axi_ruser;
    wire                   s02_axi_rvalid;
    wire                   s02_axi_rready = 1;


    // ============================================================
    // S03
    // ============================================================

    wire [ID_WIDTH-1:0]   s03_axi_awid = 0;
    wire [ADDR_WIDTH-1:0] s03_axi_awaddr = 0;
    wire [7:0]            s03_axi_awlen = 0;
    wire [2:0]            s03_axi_awsize = 0;
    wire [1:0]            s03_axi_awburst = 0;
    wire                  s03_axi_awlock = 0;
    wire [3:0]            s03_axi_awcache = 0;
    wire [2:0]            s03_axi_awprot = 0;
    wire [3:0]            s03_axi_awqos = 0;
    wire [AWUSER_WIDTH-1:0] s03_axi_awuser = 0;
    wire                    s03_axi_awvalid = 0;
    wire                    s03_axi_awready;

    wire [DATA_WIDTH-1:0] s03_axi_wdata = 0;
    wire [STRB_WIDTH-1:0] s03_axi_wstrb = 0;
    wire                   s03_axi_wlast = 0;
    wire [WUSER_WIDTH-1:0] s03_axi_wuser = 0;
    wire                   s03_axi_wvalid = 0;
    wire                   s03_axi_wready;

    wire [ID_WIDTH-1:0]    s03_axi_bid;
    wire [1:0]             s03_axi_bresp;
    wire [BUSER_WIDTH-1:0] s03_axi_buser;
    wire                   s03_axi_bvalid;
    wire                   s03_axi_bready = 1;

    wire [ID_WIDTH-1:0]   s03_axi_arid = 0;
    wire [ADDR_WIDTH-1:0] s03_axi_araddr = 0;
    wire [7:0]            s03_axi_arlen = 0;
    wire [2:0]            s03_axi_arsize = 0;
    wire [1:0]            s03_axi_arburst = 0;
    wire                  s03_axi_arlock = 0;
    wire [3:0]            s03_axi_arcache = 0;
    wire [2:0]            s03_axi_arprot = 0;
    wire [3:0]            s03_axi_arqos = 0;
    wire [ARUSER_WIDTH-1:0] s03_axi_aruser = 0;
    wire                    s03_axi_arvalid = 0;
    wire                    s03_axi_arready;

    wire [ID_WIDTH-1:0]    s03_axi_rid;
    wire [DATA_WIDTH-1:0] s03_axi_rdata;
    wire [1:0]             s03_axi_rresp;
    wire                   s03_axi_rlast;
    wire [RUSER_WIDTH-1:0] s03_axi_ruser;
    wire                   s03_axi_rvalid;
    wire                   s03_axi_rready = 1;


    // ============================================================
    // MASTER M00
    // ============================================================

    wire [ID_WIDTH-1:0]   m00_axi_awid;
    wire [ADDR_WIDTH-1:0] m00_axi_awaddr;
    wire [7:0]            m00_axi_awlen;
    wire [2:0]            m00_axi_awsize;
    wire [1:0]            m00_axi_awburst;
    wire                  m00_axi_awlock;
    wire [3:0]            m00_axi_awcache;
    wire [2:0]            m00_axi_awprot;
    wire [3:0]            m00_axi_awqos;
    wire [3:0]            m00_axi_awregion;
    wire [AWUSER_WIDTH-1:0] m00_axi_awuser;
    wire                   m00_axi_awvalid;
    reg                    m00_axi_awready = 1;

    wire [DATA_WIDTH-1:0] m00_axi_wdata;
    wire [STRB_WIDTH-1:0] m00_axi_wstrb;
    wire                   m00_axi_wlast;
    wire [WUSER_WIDTH-1:0] m00_axi_wuser;
    wire                   m00_axi_wvalid;
    reg                    m00_axi_wready = 1;

    reg [ID_WIDTH-1:0]     m00_axi_bid = 0;
    reg [1:0]              m00_axi_bresp = 0;
    reg [BUSER_WIDTH-1:0]  m00_axi_buser = 0;
    reg                    m00_axi_bvalid = 0;
    wire                   m00_axi_bready;

    wire [ID_WIDTH-1:0]    m00_axi_arid;
    wire [ADDR_WIDTH-1:0]  m00_axi_araddr;
    wire [7:0]             m00_axi_arlen;
    wire [2:0]             m00_axi_arsize;
    wire [1:0]             m00_axi_arburst;
    wire                   m00_axi_arlock;
    wire [3:0]             m00_axi_arcache;
    wire [2:0]             m00_axi_arprot;
    wire [3:0]             m00_axi_arqos;
    wire [3:0]             m00_axi_arregion;
    wire [ARUSER_WIDTH-1:0] m00_axi_aruser;
    wire                    m00_axi_arvalid;
    reg                     m00_axi_arready = 1;

    reg [ID_WIDTH-1:0]      m00_axi_rid = 0;
    reg [DATA_WIDTH-1:0]    m00_axi_rdata = 0;
    reg [1:0]               m00_axi_rresp = 0;
    reg                     m00_axi_rlast = 1;
    reg [RUSER_WIDTH-1:0]   m00_axi_ruser = 0;
    reg                     m00_axi_rvalid = 0;
    wire                    m00_axi_rready;


    // ============================================================
    // MASTER M01
    // ============================================================

    wire [ID_WIDTH-1:0]    m01_axi_awid;
    wire [ADDR_WIDTH-1:0]  m01_axi_awaddr;
    wire [7:0]             m01_axi_awlen;
    wire [2:0]             m01_axi_awsize;
    wire [1:0]             m01_axi_awburst;
    wire                    m01_axi_awlock;
    wire [3:0]             m01_axi_awcache;
    wire [2:0]             m01_axi_awprot;
    wire [3:0]             m01_axi_awqos;
    wire [3:0]             m01_axi_awregion;
    wire [AWUSER_WIDTH-1:0] m01_axi_awuser;
    wire                    m01_axi_awvalid;
    reg                     m01_axi_awready = 1;

    wire [DATA_WIDTH-1:0]   m01_axi_wdata;
    wire [STRB_WIDTH-1:0]   m01_axi_wstrb;
    wire                    m01_axi_wlast;
    wire [WUSER_WIDTH-1:0]  m01_axi_wuser;
    wire                    m01_axi_wvalid;
    reg                     m01_axi_wready = 1;

    wire [ID_WIDTH-1:0]     m01_axi_bid = 0;
    wire [1:0]              m01_axi_bresp = 0;
    wire [BUSER_WIDTH-1:0]  m01_axi_buser = 0;
    wire                    m01_axi_bvalid = 0;
    wire                    m01_axi_bready;

    wire [ID_WIDTH-1:0]     m01_axi_arid;
    wire [ADDR_WIDTH-1:0]   m01_axi_araddr;
    wire [7:0]              m01_axi_arlen;
    wire [2:0]              m01_axi_arsize;
    wire [1:0]              m01_axi_arburst;
    wire                    m01_axi_arlock;
    wire [3:0]              m01_axi_arcache;
    wire [2:0]              m01_axi_arprot;
    wire [3:0]              m01_axi_arqos;
    wire [3:0]              m01_axi_arregion;
    wire [ARUSER_WIDTH-1:0] m01_axi_aruser;
    wire                    m01_axi_arvalid;
    reg                     m01_axi_arready = 1;

    wire [ID_WIDTH-1:0]     m01_axi_rid = 0;
    wire [DATA_WIDTH-1:0]   m01_axi_rdata = 0;
    wire [1:0]              m01_axi_rresp = 0;
    wire                    m01_axi_rlast = 1;
    wire [RUSER_WIDTH-1:0]  m01_axi_ruser = 0;
    wire                    m01_axi_rvalid = 0;
    wire                    m01_axi_rready;


    // ============================================================
    // MASTER M02
    // ============================================================

    wire [ID_WIDTH-1:0]   m02_axi_awid;
    wire [ADDR_WIDTH-1:0] m02_axi_awaddr;
    wire [7:0]            m02_axi_awlen;
    wire [2:0]            m02_axi_awsize;
    wire [1:0]            m02_axi_awburst;
    wire                  m02_axi_awlock;
    wire [3:0]            m02_axi_awcache;
    wire [2:0]            m02_axi_awprot;
    wire [3:0]            m02_axi_awqos;
    wire [3:0]            m02_axi_awregion;
    wire [AWUSER_WIDTH-1:0] m02_axi_awuser;
    wire                  m02_axi_awvalid;
    reg                   m02_axi_awready = 1;

    wire [DATA_WIDTH-1:0] m02_axi_wdata;
    wire [STRB_WIDTH-1:0] m02_axi_wstrb;
    wire                  m02_axi_wlast;
    wire [WUSER_WIDTH-1:0] m02_axi_wuser;
    wire                  m02_axi_wvalid;
    reg                   m02_axi_wready = 1;

    wire [ID_WIDTH-1:0]   m02_axi_bid = 0;
    wire [1:0]            m02_axi_bresp = 0;
    wire [BUSER_WIDTH-1:0] m02_axi_buser = 0;
    wire                  m02_axi_bvalid = 0;
    wire                  m02_axi_bready;

    wire [ID_WIDTH-1:0]   m02_axi_arid;
    wire [ADDR_WIDTH-1:0] m02_axi_araddr;
    wire [7:0]            m02_axi_arlen;
    wire [2:0]            m02_axi_arsize;
    wire [1:0]            m02_axi_arburst;
    wire                  m02_axi_arlock;
    wire [3:0]            m02_axi_arcache;
    wire [2:0]            m02_axi_arprot;
    wire [3:0]            m02_axi_arqos;
    wire [3:0]            m02_axi_arregion;
    wire [ARUSER_WIDTH-1:0] m02_axi_aruser;
    wire                  m02_axi_arvalid;
    reg                   m02_axi_arready = 1;

    wire [ID_WIDTH-1:0]   m02_axi_rid = 0;
    wire [DATA_WIDTH-1:0] m02_axi_rdata = 0;
    wire [1:0]            m02_axi_rresp = 0;
    wire                  m02_axi_rlast = 1;
    wire [RUSER_WIDTH-1:0] m02_axi_ruser = 0;
    wire                  m02_axi_rvalid = 0;
    wire                  m02_axi_rready;


    // ============================================================
    // MASTER M03
    // ============================================================

    wire [ID_WIDTH-1:0] m03_axi_awid;
    wire [ADDR_WIDTH-1:0] m03_axi_awaddr;
    wire [7:0] m03_axi_awlen;
    wire [2:0] m03_axi_awsize;
    wire [1:0] m03_axi_awburst;
    wire m03_axi_awlock;
    wire [3:0] m03_axi_awcache;
    wire [2:0] m03_axi_awprot;
    wire [3:0] m03_axi_awqos;
    wire [3:0] m03_axi_awregion;
    wire [AWUSER_WIDTH-1:0] m03_axi_awuser;
    wire m03_axi_awvalid;
    reg m03_axi_awready = 1;

    wire [DATA_WIDTH-1:0] m03_axi_wdata;
    wire [STRB_WIDTH-1:0] m03_axi_wstrb;
    wire m03_axi_wlast;
    wire [WUSER_WIDTH-1:0] m03_axi_wuser;
    wire m03_axi_wvalid;
    reg m03_axi_wready = 1;

    wire [ID_WIDTH-1:0] m03_axi_bid = 0;
    wire [1:0] m03_axi_bresp = 0;
    wire [BUSER_WIDTH-1:0] m03_axi_buser = 0;
    wire m03_axi_bvalid = 0;
    wire m03_axi_bready;

    wire [ID_WIDTH-1:0] m03_axi_arid;
    wire [ADDR_WIDTH-1:0] m03_axi_araddr;
    wire [7:0] m03_axi_arlen;
    wire [2:0] m03_axi_arsize;
    wire [1:0] m03_axi_arburst;
    wire m03_axi_arlock;
    wire [3:0] m03_axi_arcache;
    wire [2:0] m03_axi_arprot;
    wire [3:0] m03_axi_arqos;
    wire [3:0] m03_axi_arregion;
    wire [ARUSER_WIDTH-1:0] m03_axi_aruser;
    wire m03_axi_arvalid;
    reg m03_axi_arready = 1;

    wire [ID_WIDTH-1:0] m03_axi_rid = 0;
    wire [DATA_WIDTH-1:0] m03_axi_rdata = 0;
    wire [1:0] m03_axi_rresp = 0;
    wire m03_axi_rlast = 1;
    wire [RUSER_WIDTH-1:0] m03_axi_ruser = 0;
    wire m03_axi_rvalid = 0;
    wire m03_axi_rready;


    // ============================================================
    // MASTER M04
    // ============================================================

    wire [ID_WIDTH-1:0] m04_axi_awid;
    wire [ADDR_WIDTH-1:0] m04_axi_awaddr;
    wire [7:0] m04_axi_awlen;
    wire [2:0] m04_axi_awsize;
    wire [1:0] m04_axi_awburst;
    wire m04_axi_awlock;
    wire [3:0] m04_axi_awcache;
    wire [2:0] m04_axi_awprot;
    wire [3:0] m04_axi_awqos;
    wire [3:0] m04_axi_awregion;
    wire [AWUSER_WIDTH-1:0] m04_axi_awuser;
    wire m04_axi_awvalid;
    reg m04_axi_awready = 1;

    wire [DATA_WIDTH-1:0] m04_axi_wdata;
    wire [STRB_WIDTH-1:0] m04_axi_wstrb;
    wire m04_axi_wlast;
    wire [WUSER_WIDTH-1:0] m04_axi_wuser;
    wire m04_axi_wvalid;
    reg m04_axi_wready = 1;

    wire [ID_WIDTH-1:0] m04_axi_bid = 0;
    wire [1:0] m04_axi_bresp = 0;
    wire [BUSER_WIDTH-1:0] m04_axi_buser = 0;
    wire m04_axi_bvalid = 0;
    wire m04_axi_bready;

    wire [ID_WIDTH-1:0] m04_axi_arid;
    wire [ADDR_WIDTH-1:0] m04_axi_araddr;
    wire [7:0] m04_axi_arlen;
    wire [2:0] m04_axi_arsize;
    wire [1:0] m04_axi_arburst;
    wire m04_axi_arlock;
    wire [3:0] m04_axi_arcache;
    wire [2:0] m04_axi_arprot;
    wire [3:0] m04_axi_arqos;
    wire [3:0] m04_axi_arregion;
    wire [ARUSER_WIDTH-1:0] m04_axi_aruser;
    wire m04_axi_arvalid;
    reg m04_axi_arready = 1;

    wire [ID_WIDTH-1:0] m04_axi_rid = 0;
    wire [DATA_WIDTH-1:0] m04_axi_rdata = 0;
    wire [1:0] m04_axi_rresp = 0;
    wire m04_axi_rlast = 1;
    wire [RUSER_WIDTH-1:0] m04_axi_ruser = 0;
    wire m04_axi_rvalid = 0;
    wire m04_axi_rready;


    // ============================================================
    // MASTER M05
    // ============================================================

    wire [ID_WIDTH-1:0] m05_axi_awid;
    wire [ADDR_WIDTH-1:0] m05_axi_awaddr;
    wire [7:0] m05_axi_awlen;
    wire [2:0] m05_axi_awsize;
    wire [1:0] m05_axi_awburst;
    wire m05_axi_awlock;
    wire [3:0] m05_axi_awcache;
    wire [2:0] m05_axi_awprot;
    wire [3:0] m05_axi_awqos;
    wire [3:0] m05_axi_awregion;
    wire [AWUSER_WIDTH-1:0] m05_axi_awuser;
    wire m05_axi_awvalid;
    reg m05_axi_awready = 1;

    wire [DATA_WIDTH-1:0] m05_axi_wdata;
    wire [STRB_WIDTH-1:0] m05_axi_wstrb;
    wire m05_axi_wlast;
    wire [WUSER_WIDTH-1:0] m05_axi_wuser;
    wire m05_axi_wvalid;
    reg m05_axi_wready = 1;

    wire [ID_WIDTH-1:0] m05_axi_bid = 0;
    wire [1:0] m05_axi_bresp = 0;
    wire [BUSER_WIDTH-1:0] m05_axi_buser = 0;
    wire m05_axi_bvalid = 0;
    wire m05_axi_bready;

    wire [ID_WIDTH-1:0] m05_axi_arid;
    wire [ADDR_WIDTH-1:0] m05_axi_araddr;
    wire [7:0] m05_axi_arlen;
    wire [2:0] m05_axi_arsize;
    wire [1:0] m05_axi_arburst;
    wire m05_axi_arlock;
    wire [3:0] m05_axi_arcache;
    wire [2:0] m05_axi_arprot;
    wire [3:0] m05_axi_arqos;
    wire [3:0] m05_axi_arregion;
    wire [ARUSER_WIDTH-1:0] m05_axi_aruser;
    wire m05_axi_arvalid;
    reg m05_axi_arready = 1;

    wire [ID_WIDTH-1:0] m05_axi_rid = 0;
    wire [DATA_WIDTH-1:0] m05_axi_rdata = 0;
    wire [1:0] m05_axi_rresp = 0;
    wire m05_axi_rlast = 1;
    wire [RUSER_WIDTH-1:0] m05_axi_ruser = 0;
    wire m05_axi_rvalid = 0;
    wire m05_axi_rready;


    // ============================================================
    // MASTER M06
    // ============================================================

    wire [ID_WIDTH-1:0] m06_axi_awid;
    wire [ADDR_WIDTH-1:0] m06_axi_awaddr;
    wire [7:0] m06_axi_awlen;
    wire [2:0] m06_axi_awsize;
    wire [1:0] m06_axi_awburst;
    wire m06_axi_awlock;
    wire [3:0] m06_axi_awcache;
    wire [2:0] m06_axi_awprot;
    wire [3:0] m06_axi_awqos;
    wire [3:0] m06_axi_awregion;
    wire [AWUSER_WIDTH-1:0] m06_axi_awuser;
    wire m06_axi_awvalid;
    reg m06_axi_awready = 1;

    wire [DATA_WIDTH-1:0] m06_axi_wdata;
    wire [STRB_WIDTH-1:0] m06_axi_wstrb;
    wire m06_axi_wlast;
    wire [WUSER_WIDTH-1:0] m06_axi_wuser;
    wire m06_axi_wvalid;
    reg m06_axi_wready = 1;

    wire [ID_WIDTH-1:0] m06_axi_bid = 0;
    wire [1:0] m06_axi_bresp = 0;
    wire [BUSER_WIDTH-1:0] m06_axi_buser = 0;
    wire m06_axi_bvalid = 0;
    wire m06_axi_bready;

    wire [ID_WIDTH-1:0] m06_axi_arid;
    wire [ADDR_WIDTH-1:0] m06_axi_araddr;
    wire [7:0] m06_axi_arlen;
    wire [2:0] m06_axi_arsize;
    wire [1:0] m06_axi_arburst;
    wire m06_axi_arlock;
    wire [3:0] m06_axi_arcache;
    wire [2:0] m06_axi_arprot;
    wire [3:0] m06_axi_arqos;
    wire [3:0] m06_axi_arregion;
    wire [ARUSER_WIDTH-1:0] m06_axi_aruser;
    wire m06_axi_arvalid;
    reg m06_axi_arready = 1;

    wire [ID_WIDTH-1:0] m06_axi_rid = 0;
    wire [DATA_WIDTH-1:0] m06_axi_rdata = 0;
    wire [1:0] m06_axi_rresp = 0;
    wire m06_axi_rlast = 1;
    wire [RUSER_WIDTH-1:0] m06_axi_ruser = 0;
    wire m06_axi_rvalid = 0;
    wire m06_axi_rready;


    // ============================================================
    // MASTER M07
    // ============================================================

    wire [ID_WIDTH-1:0] m07_axi_awid;
    wire [ADDR_WIDTH-1:0] m07_axi_awaddr;
    wire [7:0] m07_axi_awlen;
    wire [2:0] m07_axi_awsize;
    wire [1:0] m07_axi_awburst;
    wire m07_axi_awlock;
    wire [3:0] m07_axi_awcache;
    wire [2:0] m07_axi_awprot;
    wire [3:0] m07_axi_awqos;
    wire [3:0] m07_axi_awregion;
    wire [AWUSER_WIDTH-1:0] m07_axi_awuser;
    wire m07_axi_awvalid;
    reg m07_axi_awready = 1;

    wire [DATA_WIDTH-1:0] m07_axi_wdata;
    wire [STRB_WIDTH-1:0] m07_axi_wstrb;
    wire m07_axi_wlast;
    wire [WUSER_WIDTH-1:0] m07_axi_wuser;
    wire m07_axi_wvalid;
    reg m07_axi_wready = 1;

    wire [ID_WIDTH-1:0] m07_axi_bid = 0;
    wire [1:0] m07_axi_bresp = 0;
    wire [BUSER_WIDTH-1:0] m07_axi_buser = 0;
    wire m07_axi_bvalid = 0;
    wire m07_axi_bready;

    wire [ID_WIDTH-1:0] m07_axi_arid;
    wire [ADDR_WIDTH-1:0] m07_axi_araddr;
    wire [7:0] m07_axi_arlen;
    wire [2:0] m07_axi_arsize;
    wire [1:0] m07_axi_arburst;
    wire m07_axi_arlock;
    wire [3:0] m07_axi_arcache;
    wire [2:0] m07_axi_arprot;
    wire [3:0] m07_axi_arqos;
    wire [3:0] m07_axi_arregion;
    wire [ARUSER_WIDTH-1:0] m07_axi_aruser;
    wire m07_axi_arvalid;
    reg m07_axi_arready = 1;

    wire [ID_WIDTH-1:0] m07_axi_rid = 0;
    wire [DATA_WIDTH-1:0] m07_axi_rdata = 0;
    wire [1:0] m07_axi_rresp = 0;
    wire m07_axi_rlast = 1;
    wire [RUSER_WIDTH-1:0] m07_axi_ruser = 0;
    wire m07_axi_rvalid = 0;
    wire m07_axi_rready;


    // ============================================================
    // MASTER M08
    // ============================================================

    wire [ID_WIDTH-1:0] m08_axi_awid;
    wire [ADDR_WIDTH-1:0] m08_axi_awaddr;
    wire [7:0] m08_axi_awlen;
    wire [2:0] m08_axi_awsize;
    wire [1:0] m08_axi_awburst;
    wire m08_axi_awlock;
    wire [3:0] m08_axi_awcache;
    wire [2:0] m08_axi_awprot;
    wire [3:0] m08_axi_awqos;
    wire [3:0] m08_axi_awregion;
    wire [AWUSER_WIDTH-1:0] m08_axi_awuser;
    wire m08_axi_awvalid;
    reg m08_axi_awready = 1;

    wire [DATA_WIDTH-1:0] m08_axi_wdata;
    wire [STRB_WIDTH-1:0] m08_axi_wstrb;
    wire m08_axi_wlast;
    wire [WUSER_WIDTH-1:0] m08_axi_wuser;
    wire m08_axi_wvalid;
    reg m08_axi_wready = 1;

    wire [ID_WIDTH-1:0] m08_axi_bid = 0;
    wire [1:0] m08_axi_bresp = 0;
    wire [BUSER_WIDTH-1:0] m08_axi_buser = 0;
    wire m08_axi_bvalid = 0;
    wire m08_axi_bready;

    wire [ID_WIDTH-1:0] m08_axi_arid;
    wire [ADDR_WIDTH-1:0] m08_axi_araddr;
    wire [7:0] m08_axi_arlen;
    wire [2:0] m08_axi_arsize;
    wire [1:0] m08_axi_arburst;
    wire m08_axi_arlock;
    wire [3:0] m08_axi_arcache;
    wire [2:0] m08_axi_arprot;
    wire [3:0] m08_axi_arqos;
    wire [3:0] m08_axi_arregion;
    wire [ARUSER_WIDTH-1:0] m08_axi_aruser;
    wire m08_axi_arvalid;
    reg m08_axi_arready = 1;

    wire [ID_WIDTH-1:0] m08_axi_rid = 0;
    wire [DATA_WIDTH-1:0] m08_axi_rdata = 0;
    wire [1:0] m08_axi_rresp = 0;
    wire m08_axi_rlast = 1;
    wire [RUSER_WIDTH-1:0] m08_axi_ruser = 0;
    wire m08_axi_rvalid = 0;
    wire m08_axi_rready;


    // ============================================================
    // DUT
    // ============================================================

    axi_interconnect_wrap_4x9 #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_WIDTH(ID_WIDTH),

        .M_REGIONS(1),

        .M00_BASE_ADDR(32'h00000000),
        .M01_BASE_ADDR(32'h10000000),
        .M02_BASE_ADDR(32'h20000000),
        .M03_BASE_ADDR(32'h30000000),
        .M04_BASE_ADDR(32'h40000000),
        .M05_BASE_ADDR(32'h50000000),
        .M06_BASE_ADDR(32'h60000000),
        .M07_BASE_ADDR(32'h70000000),
        .M08_BASE_ADDR(32'h80000000),

        .M00_ADDR_WIDTH({1{32'd15}}),
        .M01_ADDR_WIDTH({1{32'd15}}),
        .M02_ADDR_WIDTH({1{32'd15}}),
        .M03_ADDR_WIDTH({1{32'd15}}),
        .M04_ADDR_WIDTH({1{32'd15}}),
        .M05_ADDR_WIDTH({1{32'd15}}),
        .M06_ADDR_WIDTH({1{32'd15}}),
        .M07_ADDR_WIDTH({1{32'd15}}),
        .M08_ADDR_WIDTH({1{32'd15}})
    )
    dut (
        .clk(clk),
        .rst(rst),

        // ========================================================
        // S00
        // ========================================================

        .s00_axi_awid(s00_axi_awid),
        .s00_axi_awaddr(s00_axi_awaddr),
        .s00_axi_awlen(s00_axi_awlen),
        .s00_axi_awsize(s00_axi_awsize),
        .s00_axi_awburst(s00_axi_awburst),
        .s00_axi_awlock(s00_axi_awlock),
        .s00_axi_awcache(s00_axi_awcache),
        .s00_axi_awprot(s00_axi_awprot),
        .s00_axi_awqos(s00_axi_awqos),
        .s00_axi_awuser(s00_axi_awuser),
        .s00_axi_awvalid(s00_axi_awvalid),
        .s00_axi_awready(s00_axi_awready),

        .s00_axi_wdata(s00_axi_wdata),
        .s00_axi_wstrb(s00_axi_wstrb),
        .s00_axi_wlast(s00_axi_wlast),
        .s00_axi_wuser(s00_axi_wuser),
        .s00_axi_wvalid(s00_axi_wvalid),
        .s00_axi_wready(s00_axi_wready),

        .s00_axi_bid(s00_axi_bid),
        .s00_axi_bresp(s00_axi_bresp),
        .s00_axi_buser(s00_axi_buser),
        .s00_axi_bvalid(s00_axi_bvalid),
        .s00_axi_bready(s00_axi_bready),

        .s00_axi_arid(s00_axi_arid),
        .s00_axi_araddr(s00_axi_araddr),
        .s00_axi_arlen(s00_axi_arlen),
        .s00_axi_arsize(s00_axi_arsize),
        .s00_axi_arburst(s00_axi_arburst),
        .s00_axi_arlock(s00_axi_arlock),
        .s00_axi_arcache(s00_axi_arcache),
        .s00_axi_arprot(s00_axi_arprot),
        .s00_axi_arqos(s00_axi_arqos),
        .s00_axi_aruser(s00_axi_aruser),
        .s00_axi_arvalid(s00_axi_arvalid),
        .s00_axi_arready(s00_axi_arready),

        .s00_axi_rid(s00_axi_rid),
        .s00_axi_rdata(s00_axi_rdata),
        .s00_axi_rresp(s00_axi_rresp),
        .s00_axi_rlast(s00_axi_rlast),
        .s00_axi_ruser(s00_axi_ruser),
        .s00_axi_rvalid(s00_axi_rvalid),
        .s00_axi_rready(s00_axi_rready),

        // ========================================================
        // S01
        // ========================================================

        .s01_axi_awid(s01_axi_awid),
        .s01_axi_awaddr(s01_axi_awaddr),
        .s01_axi_awlen(s01_axi_awlen),
        .s01_axi_awsize(s01_axi_awsize),
        .s01_axi_awburst(s01_axi_awburst),
        .s01_axi_awlock(s01_axi_awlock),
        .s01_axi_awcache(s01_axi_awcache),
        .s01_axi_awprot(s01_axi_awprot),
        .s01_axi_awqos(s01_axi_awqos),
        .s01_axi_awuser(s01_axi_awuser),
        .s01_axi_awvalid(s01_axi_awvalid),
        .s01_axi_awready(s01_axi_awready),

        .s01_axi_wdata(s01_axi_wdata),
        .s01_axi_wstrb(s01_axi_wstrb),
        .s01_axi_wlast(s01_axi_wlast),
        .s01_axi_wuser(s01_axi_wuser),
        .s01_axi_wvalid(s01_axi_wvalid),
        .s01_axi_wready(s01_axi_wready),

        .s01_axi_bid(s01_axi_bid),
        .s01_axi_bresp(s01_axi_bresp),
        .s01_axi_buser(s01_axi_buser),
        .s01_axi_bvalid(s01_axi_bvalid),
        .s01_axi_bready(s01_axi_bready),

        .s01_axi_arid(s01_axi_arid),
        .s01_axi_araddr(s01_axi_araddr),
        .s01_axi_arlen(s01_axi_arlen),
        .s01_axi_arsize(s01_axi_arsize),
        .s01_axi_arburst(s01_axi_arburst),
        .s01_axi_arlock(s01_axi_arlock),
        .s01_axi_arcache(s01_axi_arcache),
        .s01_axi_arprot(s01_axi_arprot),
        .s01_axi_arqos(s01_axi_arqos),
        .s01_axi_aruser(s01_axi_aruser),
        .s01_axi_arvalid(s01_axi_arvalid),
        .s01_axi_arready(s01_axi_arready),

        .s01_axi_rid(s01_axi_rid),
        .s01_axi_rdata(s01_axi_rdata),
        .s01_axi_rresp(s01_axi_rresp),
        .s01_axi_rlast(s01_axi_rlast),
        .s01_axi_ruser(s01_axi_ruser),
        .s01_axi_rvalid(s01_axi_rvalid),
        .s01_axi_rready(s01_axi_rready),

        // ========================================================
        // S02
        // ========================================================

        .s02_axi_awid(s02_axi_awid),
        .s02_axi_awaddr(s02_axi_awaddr),
        .s02_axi_awlen(s02_axi_awlen),
        .s02_axi_awsize(s02_axi_awsize),
        .s02_axi_awburst(s02_axi_awburst),
        .s02_axi_awlock(s02_axi_awlock),
        .s02_axi_awcache(s02_axi_awcache),
        .s02_axi_awprot(s02_axi_awprot),
        .s02_axi_awqos(s02_axi_awqos),
        .s02_axi_awuser(s02_axi_awuser),
        .s02_axi_awvalid(s02_axi_awvalid),
        .s02_axi_awready(s02_axi_awready),

        .s02_axi_wdata(s02_axi_wdata),
        .s02_axi_wstrb(s02_axi_wstrb),
        .s02_axi_wlast(s02_axi_wlast),
        .s02_axi_wuser(s02_axi_wuser),
        .s02_axi_wvalid(s02_axi_wvalid),
        .s02_axi_wready(s02_axi_wready),

        .s02_axi_bid(s02_axi_bid),
        .s02_axi_bresp(s02_axi_bresp),
        .s02_axi_buser(s02_axi_buser),
        .s02_axi_bvalid(s02_axi_bvalid),
        .s02_axi_bready(s02_axi_bready),

        .s02_axi_arid(s02_axi_arid),
        .s02_axi_araddr(s02_axi_araddr),
        .s02_axi_arlen(s02_axi_arlen),
        .s02_axi_arsize(s02_axi_arsize),
        .s02_axi_arburst(s02_axi_arburst),
        .s02_axi_arlock(s02_axi_arlock),
        .s02_axi_arcache(s02_axi_arcache),
        .s02_axi_arprot(s02_axi_arprot),
        .s02_axi_arqos(s02_axi_arqos),
        .s02_axi_aruser(s02_axi_aruser),
        .s02_axi_arvalid(s02_axi_arvalid),
        .s02_axi_arready(s02_axi_arready),

        .s02_axi_rid(s02_axi_rid),
        .s02_axi_rdata(s02_axi_rdata),
        .s02_axi_rresp(s02_axi_rresp),
        .s02_axi_rlast(s02_axi_rlast),
        .s02_axi_ruser(s02_axi_ruser),
        .s02_axi_rvalid(s02_axi_rvalid),
        .s02_axi_rready(s02_axi_rready),

        // ========================================================
        // S03
        // ========================================================

        .s03_axi_awid(s03_axi_awid),
        .s03_axi_awaddr(s03_axi_awaddr),
        .s03_axi_awlen(s03_axi_awlen),
        .s03_axi_awsize(s03_axi_awsize),
        .s03_axi_awburst(s03_axi_awburst),
        .s03_axi_awlock(s03_axi_awlock),
        .s03_axi_awcache(s03_axi_awcache),
        .s03_axi_awprot(s03_axi_awprot),
        .s03_axi_awqos(s03_axi_awqos),
        .s03_axi_awuser(s03_axi_awuser),
        .s03_axi_awvalid(s03_axi_awvalid),
        .s03_axi_awready(s03_axi_awready),

        .s03_axi_wdata(s03_axi_wdata),
        .s03_axi_wstrb(s03_axi_wstrb),
        .s03_axi_wlast(s03_axi_wlast),
        .s03_axi_wuser(s03_axi_wuser),
        .s03_axi_wvalid(s03_axi_wvalid),
        .s03_axi_wready(s03_axi_wready),

        .s03_axi_bid(s03_axi_bid),
        .s03_axi_bresp(s03_axi_bresp),
        .s03_axi_buser(s03_axi_buser),
        .s03_axi_bvalid(s03_axi_bvalid),
        .s03_axi_bready(s03_axi_bready),

        .s03_axi_arid(s03_axi_arid),
        .s03_axi_araddr(s03_axi_araddr),
        .s03_axi_arlen(s03_axi_arlen),
        .s03_axi_arsize(s03_axi_arsize),
        .s03_axi_arburst(s03_axi_arburst),
        .s03_axi_arlock(s03_axi_arlock),
        .s03_axi_arcache(s03_axi_arcache),
        .s03_axi_arprot(s03_axi_arprot),
        .s03_axi_arqos(s03_axi_arqos),
        .s03_axi_aruser(s03_axi_aruser),
        .s03_axi_arvalid(s03_axi_arvalid),
        .s03_axi_arready(s03_axi_arready),

        .s03_axi_rid(s03_axi_rid),
        .s03_axi_rdata(s03_axi_rdata),
        .s03_axi_rresp(s03_axi_rresp),
        .s03_axi_rlast(s03_axi_rlast),
        .s03_axi_ruser(s03_axi_ruser),
        .s03_axi_rvalid(s03_axi_rvalid),
        .s03_axi_rready(s03_axi_rready),

        // ========================================================
        // M00
        // ========================================================

        .m00_axi_awid(m00_axi_awid),
        .m00_axi_awaddr(m00_axi_awaddr),
        .m00_axi_awlen(m00_axi_awlen),
        .m00_axi_awsize(m00_axi_awsize),
        .m00_axi_awburst(m00_axi_awburst),
        .m00_axi_awlock(m00_axi_awlock),
        .m00_axi_awcache(m00_axi_awcache),
        .m00_axi_awprot(m00_axi_awprot),
        .m00_axi_awqos(m00_axi_awqos),
        .m00_axi_awregion(m00_axi_awregion),
        .m00_axi_awuser(m00_axi_awuser),
        .m00_axi_awvalid(m00_axi_awvalid),
        .m00_axi_awready(m00_axi_awready),

        .m00_axi_wdata(m00_axi_wdata),
        .m00_axi_wstrb(m00_axi_wstrb),
        .m00_axi_wlast(m00_axi_wlast),
        .m00_axi_wuser(m00_axi_wuser),
        .m00_axi_wvalid(m00_axi_wvalid),
        .m00_axi_wready(m00_axi_wready),

        .m00_axi_bid(m00_axi_bid),
        .m00_axi_bresp(m00_axi_bresp),
        .m00_axi_buser(m00_axi_buser),
        .m00_axi_bvalid(m00_axi_bvalid),
        .m00_axi_bready(m00_axi_bready),

        .m00_axi_arid(m00_axi_arid),
        .m00_axi_araddr(m00_axi_araddr),
        .m00_axi_arlen(m00_axi_arlen),
        .m00_axi_arsize(m00_axi_arsize),
        .m00_axi_arburst(m00_axi_arburst),
        .m00_axi_arlock(m00_axi_arlock),
        .m00_axi_arcache(m00_axi_arcache),
        .m00_axi_arprot(m00_axi_arprot),
        .m00_axi_arqos(m00_axi_arqos),
        .m00_axi_arregion(m00_axi_arregion),
        .m00_axi_aruser(m00_axi_aruser),
        .m00_axi_arvalid(m00_axi_arvalid),
        .m00_axi_arready(m00_axi_arready),

        .m00_axi_rid(m00_axi_rid),
        .m00_axi_rdata(m00_axi_rdata),
        .m00_axi_rresp(m00_axi_rresp),
        .m00_axi_rlast(m00_axi_rlast),
        .m00_axi_ruser(m00_axi_ruser),
        .m00_axi_rvalid(m00_axi_rvalid),
        .m00_axi_rready(m00_axi_rready),

        // ========================================================
        // M01
        // ========================================================

        .m01_axi_awid(m01_axi_awid),
        .m01_axi_awaddr(m01_axi_awaddr),
        .m01_axi_awlen(m01_axi_awlen),
        .m01_axi_awsize(m01_axi_awsize),
        .m01_axi_awburst(m01_axi_awburst),
        .m01_axi_awlock(m01_axi_awlock),
        .m01_axi_awcache(m01_axi_awcache),
        .m01_axi_awprot(m01_axi_awprot),
        .m01_axi_awqos(m01_axi_awqos),
        .m01_axi_awregion(m01_axi_awregion),
        .m01_axi_awuser(m01_axi_awuser),
        .m01_axi_awvalid(m01_axi_awvalid),
        .m01_axi_awready(m01_axi_awready),

        .m01_axi_wdata(m01_axi_wdata),
        .m01_axi_wstrb(m01_axi_wstrb),
        .m01_axi_wlast(m01_axi_wlast),
        .m01_axi_wuser(m01_axi_wuser),
        .m01_axi_wvalid(m01_axi_wvalid),
        .m01_axi_wready(m01_axi_wready),

        .m01_axi_bid(m01_axi_bid),
        .m01_axi_bresp(m01_axi_bresp),
        .m01_axi_buser(m01_axi_buser),
        .m01_axi_bvalid(m01_axi_bvalid),
        .m01_axi_bready(m01_axi_bready),

        .m01_axi_arid(m01_axi_arid),
        .m01_axi_araddr(m01_axi_araddr),
        .m01_axi_arlen(m01_axi_arlen),
        .m01_axi_arsize(m01_axi_arsize),
        .m01_axi_arburst(m01_axi_arburst),
        .m01_axi_arlock(m01_axi_arlock),
        .m01_axi_arcache(m01_axi_arcache),
        .m01_axi_arprot(m01_axi_arprot),
        .m01_axi_arqos(m01_axi_arqos),
        .m01_axi_arregion(m01_axi_arregion),
        .m01_axi_aruser(m01_axi_aruser),
        .m01_axi_arvalid(m01_axi_arvalid),
        .m01_axi_arready(m01_axi_arready),

        .m01_axi_rid(m01_axi_rid),
        .m01_axi_rdata(m01_axi_rdata),
        .m01_axi_rresp(m01_axi_rresp),
        .m01_axi_rlast(m01_axi_rlast),
        .m01_axi_ruser(m01_axi_ruser),
        .m01_axi_rvalid(m01_axi_rvalid),
        .m01_axi_rready(m01_axi_rready)
    );


    // ============================================================
    // CLOCK
    // ============================================================

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    // ============================================================
    // TEST
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // Initial values
        // --------------------------------------------------------

        rst = 1;

        s00_axi_awid    = 0;
        s00_axi_awaddr  = 0;
        s00_axi_awlen   = 0;
        s00_axi_awsize  = 3'b010;
        s00_axi_awburst = 2'b01;
        s00_axi_awlock  = 0;
        s00_axi_awcache = 0;
        s00_axi_awprot  = 0;
        s00_axi_awqos   = 0;
        s00_axi_awuser  = 0;
        s00_axi_awvalid = 0;

        s00_axi_wdata   = 0;
        s00_axi_wstrb   = 4'b1111;
        s00_axi_wlast   = 1;
        s00_axi_wuser   = 0;
        s00_axi_wvalid  = 0;

        s00_axi_bready  = 1;

        s00_axi_arid    = 0;
        s00_axi_araddr  = 0;
        s00_axi_arlen   = 0;
        s00_axi_arsize  = 3'b010;
        s00_axi_arburst = 2'b01;
        s00_axi_arlock  = 0;
        s00_axi_arcache = 0;
        s00_axi_arprot  = 0;
        s00_axi_arqos   = 0;
        s00_axi_aruser  = 0;
        s00_axi_arvalid = 0;

        s00_axi_rready  = 1;

        #100;

        rst = 0;

        #50;


        // ========================================================
        // TEST 1: Write to M00
        // ========================================================

        $display("========================================");
        $display("TEST 1: WRITE TO M00");
        $display("========================================");

        @(posedge clk);

        s00_axi_awid    <= 8'h01;
        s00_axi_awaddr  <= 32'h00000010;
        s00_axi_awvalid <= 1'b1;

        s00_axi_wdata   <= 32'h12345678;
        s00_axi_wvalid  <= 1'b1;
        s00_axi_wlast   <= 1'b1;

        @(posedge clk);

        while (!s00_axi_awready)
            @(posedge clk);

        s00_axi_awvalid <= 1'b0;
        s00_axi_wvalid  <= 1'b0;

        #20;

        $display("S00 Address = %h", s00_axi_awaddr);
        $display("M00 Address = %h", m00_axi_awaddr);
        $display("M00 Data    = %h", m00_axi_wdata);
        $display("M00 Valid   = %b", m00_axi_awvalid);


        // ========================================================
        // TEST 2: Write to M01
        // M01 BASE ADDRESS = 0x10000000
        // ========================================================

        $display("========================================");
        $display("TEST 2: WRITE TO M01");
        $display("========================================");

        @(posedge clk);

        s00_axi_awid    <= 8'h02;

        // IMPORTANT:
        // M01 base address is 0x10000000.
        // Therefore use 0x10000010 for M01.
        s00_axi_awaddr  <= 32'h10000010;

        s00_axi_awvalid <= 1'b1;

        s00_axi_wdata   <= 32'hAABBCCDD;
        s00_axi_wvalid  <= 1'b1;
        s00_axi_wlast   <= 1'b1;

        $display("TEST 2: AWVALID=%b AWADDR=%h",
                 s00_axi_awvalid,
                 s00_axi_awaddr);

        repeat(20) begin
            @(posedge clk);

            $display(
                "Time=%0t AWVALID=%b AWREADY=%b AWADDR=%h | M01_AWVALID=%b M01_AWREADY=%b",
                $time,
                s00_axi_awvalid,
                s00_axi_awready,
                s00_axi_awaddr,
                m01_axi_awvalid,
                m01_axi_awready
            );
        end

        s00_axi_awvalid <= 1'b0;
        s00_axi_wvalid  <= 1'b0;

        #20;

        $display("S00 Address = %h", s00_axi_awaddr);
        $display("M01 Address = %h", m01_axi_awaddr);
        $display("M01 Data    = %h", m01_axi_wdata);
        $display("M01 Valid   = %b", m01_axi_awvalid);


        // ========================================================
        // End simulation
        // ========================================================

        #100;

        $display("========================================");
        $display("SIMULATION FINISHED");
        $display("========================================");

        $finish;

    end


    // ============================================================
    // WAVEFORM
    // ============================================================

    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars("+all");
        $fsdbDumpSVA();
        $fsdbDumpMDA();
    end

endmodule
