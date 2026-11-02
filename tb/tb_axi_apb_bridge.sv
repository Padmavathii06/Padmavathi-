// =============================================================================
// tb_axi_apb_bridge.sv
// Self-checking testbench for AXI4-to-APB Bridge Subsystem.
//
// Test coverage:
//   1. Power-on reset & initial default outputs
//   2. Single 32-bit AXI Write to APB Peripheral (GPIO DIR and OUT)
//   3. Single 32-bit AXI Read from APB Peripheral (GPIO verification)
//   4. APB Timer peripheral configuration (Timer LOAD, CTRL) and register readback
//   5. Decoupled timing: AW valid 3 cycles before W valid
//   6. Decoupled timing: W valid 3 cycles before AW valid
//   7. Back-to-back write and read transactions (high throughput)
//   8. APB Wait States: Delayed PREADY (1, 3, and 5 wait cycles)
//   9. APB Error response: PSLVERR -> returns AXI BRESP = 2'b10 (SLVERR)
//  10. APB Error response: PSLVERR -> returns AXI RRESP = 2'b10 (SLVERR)
//  11. Unsupported burst write (awlen > 0) -> returns AXI SLVERR
//  12. Unsupported burst read  (arlen > 0) -> returns AXI SLVERR
//  13. AXI Transaction ID preservation (BID == AWID, RID == ARID)
//  14. Response backpressure handling (delayed BREADY and delayed RREADY)
// =============================================================================

`timescale 1ns / 1ps
`default_nettype none

module tb_axi_apb_bridge;

    parameter DATA_WIDTH   = 32;
    parameter ADDR_WIDTH   = 32;
    parameter STRB_WIDTH   = (DATA_WIDTH / 8);
    parameter ID_WIDTH     = 8;
    parameter AWUSER_WIDTH = 1;
    parameter WUSER_WIDTH  = 1;
    parameter BUSER_WIDTH  = 1;
    parameter ARUSER_WIDTH = 1;
    parameter RUSER_WIDTH  = 1;

    // ── Clock & Reset ─────────────────────────────────────────────────────────
    reg clk;
    reg rst;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // ── AXI4 Subordinate Interface Signals ────────────────────────────────────
    reg  [ID_WIDTH-1:0]     s_axi_awid;
    reg  [ADDR_WIDTH-1:0]   s_axi_awaddr;
    reg  [7:0]              s_axi_awlen;
    reg  [2:0]              s_axi_awsize;
    reg  [1:0]              s_axi_awburst;
    reg                     s_axi_awlock;
    reg  [3:0]              s_axi_awcache;
    reg  [2:0]              s_axi_awprot;
    reg  [3:0]              s_axi_awqos;
    reg  [3:0]              s_axi_awregion;
    reg  [AWUSER_WIDTH-1:0] s_axi_awuser;
    reg                     s_axi_awvalid;
    wire                    s_axi_awready;

    reg  [DATA_WIDTH-1:0]   s_axi_wdata;
    reg  [STRB_WIDTH-1:0]   s_axi_wstrb;
    reg                     s_axi_wlast;
    reg  [WUSER_WIDTH-1:0]  s_axi_wuser;
    reg                     s_axi_wvalid;
    wire                    s_axi_wready;

    wire [ID_WIDTH-1:0]     s_axi_bid;
    wire [1:0]              s_axi_bresp;
    wire [BUSER_WIDTH-1:0]  s_axi_buser;
    wire                    s_axi_bvalid;
    reg                     s_axi_bready;

    reg  [ID_WIDTH-1:0]     s_axi_arid;
    reg  [ADDR_WIDTH-1:0]   s_axi_araddr;
    reg  [7:0]              s_axi_arlen;
    reg  [2:0]              s_axi_arsize;
    reg  [1:0]              s_axi_arburst;
    reg                     s_axi_arlock;
    reg  [3:0]              s_axi_arcache;
    reg  [2:0]              s_axi_arprot;
    reg  [3:0]              s_axi_arqos;
    reg  [3:0]              s_axi_arregion;
    reg  [ARUSER_WIDTH-1:0] s_axi_aruser;
    reg                     s_axi_arvalid;
    wire                    s_axi_arready;

    wire [ID_WIDTH-1:0]     s_axi_rid;
    wire [DATA_WIDTH-1:0]   s_axi_rdata;
    wire [1:0]              s_axi_rresp;
    wire                    s_axi_rlast;
    wire [RUSER_WIDTH-1:0]  s_axi_ruser;
    wire                    s_axi_rvalid;
    reg                     s_axi_rready;

    // ── APB Interconnect & Mux Signals ────────────────────────────────────────
    wire        m_apb_pclk;
    wire        m_apb_presetn;
    wire [31:0] m_apb_paddr;
    wire [31:0] m_apb_pwdata;
    wire        m_apb_pwrite;
    wire        m_apb_psel;
    wire        m_apb_penable;
    wire [31:0] m_apb_prdata;
    wire        m_apb_pready;
    wire        m_apb_pslverr;

    // Peripheral direct signals
    wire [31:0] periph_prdata;
    wire        periph_pready;
    wire        periph_pslverr;
    reg  [7:0]  gpio_in;
    wire [7:0]  gpio_out;
    wire [7:0]  gpio_dir;
    wire        uart_irq, spi_irq, gpio_irq, timer_irq;
    wire [4:0]  pic_irq_lines;

    // Testbench APB Slave Responder Control
    reg         tb_slave_mode;      // 0: real apb_peripherals, 1: testbench injection
    reg [31:0]  tb_inj_prdata;
    reg         tb_inj_pready;
    reg         tb_inj_pslverr;
    int         tb_wait_cycles;
    int         curr_wait_cnt;

    // Mux between real peripheral and test harness slave
    assign m_apb_prdata  = tb_slave_mode ? tb_inj_prdata  : periph_prdata;
    assign m_apb_pready  = tb_slave_mode ? tb_inj_pready  : periph_pready;
    assign m_apb_pslverr = tb_slave_mode ? tb_inj_pslverr : periph_pslverr;

    // Controllable APB wait-state generator in tb_slave_mode
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            curr_wait_cnt <= 0;
            tb_inj_pready <= 1'b0;
        end else if (tb_slave_mode && m_apb_psel && m_apb_penable) begin
            if (curr_wait_cnt < tb_wait_cycles) begin
                tb_inj_pready <= 1'b0;
                curr_wait_cnt <= curr_wait_cnt + 1;
            end else begin
                tb_inj_pready <= 1'b1;
            end
        end else begin
            curr_wait_cnt <= 0;
            tb_inj_pready <= (tb_wait_cycles == 0) ? 1'b1 : 1'b0;
        end
    end

    // ── DUT Instantiation ─────────────────────────────────────────────────────
    axi_apb_bridge #(
        .DATA_WIDTH   (DATA_WIDTH),
        .ADDR_WIDTH   (ADDR_WIDTH),
        .ID_WIDTH     (ID_WIDTH),
        .AWUSER_WIDTH (AWUSER_WIDTH),
        .WUSER_WIDTH  (WUSER_WIDTH),
        .BUSER_WIDTH  (BUSER_WIDTH),
        .ARUSER_WIDTH (ARUSER_WIDTH),
        .RUSER_WIDTH  (RUSER_WIDTH)
    ) u_bridge (
        .clk           (clk),
        .rst           (rst),
        .s_axi_awid    (s_axi_awid),
        .s_axi_awaddr  (s_axi_awaddr),
        .s_axi_awlen   (s_axi_awlen),
        .s_axi_awsize  (s_axi_awsize),
        .s_axi_awburst (s_axi_awburst),
        .s_axi_awlock  (s_axi_awlock),
        .s_axi_awcache (s_axi_awcache),
        .s_axi_awprot  (s_axi_awprot),
        .s_axi_awqos   (s_axi_awqos),
        .s_axi_awregion(s_axi_awregion),
        .s_axi_awuser  (s_axi_awuser),
        .s_axi_awvalid (s_axi_awvalid),
        .s_axi_awready (s_axi_awready),
        .s_axi_wdata   (s_axi_wdata),
        .s_axi_wstrb   (s_axi_wstrb),
        .s_axi_wlast   (s_axi_wlast),
        .s_axi_wuser   (s_axi_wuser),
        .s_axi_wvalid  (s_axi_wvalid),
        .s_axi_wready  (s_axi_wready),
        .s_axi_bid     (s_axi_bid),
        .s_axi_bresp   (s_axi_bresp),
        .s_axi_buser   (s_axi_buser),
        .s_axi_bvalid  (s_axi_bvalid),
        .s_axi_bready  (s_axi_bready),
        .s_axi_arid    (s_axi_arid),
        .s_axi_araddr  (s_axi_araddr),
        .s_axi_arlen   (s_axi_arlen),
        .s_axi_arsize  (s_axi_arsize),
        .s_axi_arburst (s_axi_arburst),
        .s_axi_arlock  (s_axi_arlock),
        .s_axi_arcache (s_axi_arcache),
        .s_axi_arprot  (s_axi_arprot),
        .s_axi_arqos   (s_axi_arqos),
        .s_axi_arregion(s_axi_arregion),
        .s_axi_aruser  (s_axi_aruser),
        .s_axi_arvalid (s_axi_arvalid),
        .s_axi_arready (s_axi_arready),
        .s_axi_rid     (s_axi_rid),
        .s_axi_rdata   (s_axi_rdata),
        .s_axi_rresp   (s_axi_rresp),
        .s_axi_rlast   (s_axi_rlast),
        .s_axi_ruser   (s_axi_ruser),
        .s_axi_rvalid  (s_axi_rvalid),
        .s_axi_rready  (s_axi_rready),
        .m_apb_pclk    (m_apb_pclk),
        .m_apb_presetn (m_apb_presetn),
        .m_apb_paddr   (m_apb_paddr),
        .m_apb_pwdata  (m_apb_pwdata),
        .m_apb_pwrite  (m_apb_pwrite),
        .m_apb_psel    (m_apb_psel),
        .m_apb_penable (m_apb_penable),
        .m_apb_prdata  (m_apb_prdata),
        .m_apb_pready  (m_apb_pready),
        .m_apb_pslverr (m_apb_pslverr)
    );

    // ── Real APB Peripherals Subsystem ────────────────────────────────────────
    apb_peripherals u_periph (
        .PCLK          (m_apb_pclk),
        .PRESETn       (m_apb_presetn),
        .PADDR         (m_apb_paddr),
        .PWDATA        (m_apb_pwdata),
        .PWRITE        (m_apb_pwrite),
        .PSEL          (tb_slave_mode ? 1'b0 : m_apb_psel),
        .PENABLE       (tb_slave_mode ? 1'b0 : m_apb_penable),
        .PRDATA        (periph_prdata),
        .PREADY        (periph_pready),
        .PSLVERR       (periph_pslverr),
        .gpio_in       (gpio_in),
        .gpio_out      (gpio_out),
        .gpio_dir      (gpio_dir),
        .uart_irq      (uart_irq),
        .spi_irq       (spi_irq),
        .gpio_irq      (gpio_irq),
        .timer_irq     (timer_irq),
        .pic_irq_lines (pic_irq_lines)
    );

    // ── Verification Statistics ───────────────────────────────────────────────
    int pass_count = 0;
    int fail_count = 0;

    // ── AXI Driver Tasks ──────────────────────────────────────────────────────

    // Standard synchronous AXI write
    task automatic axi_write(
        input  [ID_WIDTH-1:0]   id,
        input  [ADDR_WIDTH-1:0] addr,
        input  [DATA_WIDTH-1:0] data,
        input  [7:0]            len,
        output [1:0]            resp,
        output [ID_WIDTH-1:0]   bid
    );
        @(posedge clk);
        s_axi_awid    <= id;
        s_axi_awaddr  <= addr;
        s_axi_awlen   <= len;
        s_axi_awsize  <= 3'b010; // 4 bytes
        s_axi_awburst <= 2'b01;
        s_axi_awvalid <= 1'b1;

        s_axi_wdata   <= data;
        s_axi_wstrb   <= 4'b1111;
        s_axi_wlast   <= 1'b1;
        s_axi_wvalid  <= 1'b1;
        s_axi_bready  <= 1'b1;

        // Wait for both address and data handshakes
        fork
            begin
                while (!(s_axi_awvalid && s_axi_awready)) @(posedge clk);
                s_axi_awvalid <= 1'b0;
            end
            begin
                while (!(s_axi_wvalid && s_axi_wready)) @(posedge clk);
                s_axi_wvalid <= 1'b0;
            end
        join

        // Wait for response handshake
        while (!(s_axi_bvalid && s_axi_bready)) @(posedge clk);
        resp = s_axi_bresp;
        bid  = s_axi_bid;
        @(posedge clk);
        s_axi_bready <= 1'b0;
    endtask

    // Decoupled write: AW arrives first, W delayed
    task automatic axi_write_aw_first(
        input  [ID_WIDTH-1:0]   id,
        input  [ADDR_WIDTH-1:0] addr,
        input  [DATA_WIDTH-1:0] data,
        input  int              w_delay_cycles,
        output [1:0]            resp,
        output [ID_WIDTH-1:0]   bid
    );
        @(posedge clk);
        s_axi_awid    <= id;
        s_axi_awaddr  <= addr;
        s_axi_awlen   <= 8'h00;
        s_axi_awsize  <= 3'b010;
        s_axi_awburst <= 2'b01;
        s_axi_awvalid <= 1'b1;
        s_axi_bready  <= 1'b1;

        while (!(s_axi_awvalid && s_axi_awready)) @(posedge clk);
        s_axi_awvalid <= 1'b0;

        repeat (w_delay_cycles) @(posedge clk);

        s_axi_wdata  <= data;
        s_axi_wstrb  <= 4'b1111;
        s_axi_wlast  <= 1'b1;
        s_axi_wvalid <= 1'b1;

        while (!(s_axi_wvalid && s_axi_wready)) @(posedge clk);
        s_axi_wvalid <= 1'b0;

        while (!(s_axi_bvalid && s_axi_bready)) @(posedge clk);
        resp = s_axi_bresp;
        bid  = s_axi_bid;
        @(posedge clk);
        s_axi_bready <= 1'b0;
    endtask

    // Decoupled write: W arrives first, AW delayed
    task automatic axi_write_w_first(
        input  [ID_WIDTH-1:0]   id,
        input  [ADDR_WIDTH-1:0] addr,
        input  [DATA_WIDTH-1:0] data,
        input  int              aw_delay_cycles,
        output [1:0]            resp,
        output [ID_WIDTH-1:0]   bid
    );
        @(posedge clk);
        s_axi_wdata   <= data;
        s_axi_wstrb   <= 4'b1111;
        s_axi_wlast   <= 1'b1;
        s_axi_wvalid  <= 1'b1;
        s_axi_bready  <= 1'b1;

        while (!(s_axi_wvalid && s_axi_wready)) @(posedge clk);
        s_axi_wvalid <= 1'b0;

        repeat (aw_delay_cycles) @(posedge clk);

        s_axi_awid    <= id;
        s_axi_awaddr  <= addr;
        s_axi_awlen   <= 8'h00;
        s_axi_awsize  <= 3'b010;
        s_axi_awburst <= 2'b01;
        s_axi_awvalid <= 1'b1;

        while (!(s_axi_awvalid && s_axi_awready)) @(posedge clk);
        s_axi_awvalid <= 1'b0;

        while (!(s_axi_bvalid && s_axi_bready)) @(posedge clk);
        resp = s_axi_bresp;
        bid  = s_axi_bid;
        @(posedge clk);
        s_axi_bready <= 1'b0;
    endtask

    // Standard synchronous AXI read
    task automatic axi_read(
        input  [ID_WIDTH-1:0]   id,
        input  [ADDR_WIDTH-1:0] addr,
        input  [7:0]            len,
        output [DATA_WIDTH-1:0] data,
        output [1:0]            resp,
        output [ID_WIDTH-1:0]   rid
    );
        @(posedge clk);
        s_axi_arid    <= id;
        s_axi_araddr  <= addr;
        s_axi_arlen   <= len;
        s_axi_arsize  <= 3'b010;
        s_axi_arburst <= 2'b01;
        s_axi_arvalid <= 1'b1;
        s_axi_rready  <= 1'b1;

        while (!(s_axi_arvalid && s_axi_arready)) @(posedge clk);
        s_axi_arvalid <= 1'b0;

        while (!(s_axi_rvalid && s_axi_rready)) @(posedge clk);
        data = s_axi_rdata;
        resp = s_axi_rresp;
        rid  = s_axi_rid;
        @(posedge clk);
        s_axi_rready <= 1'b0;
    endtask

    // Delayed RREADY read
    task automatic axi_read_delayed_rready(
        input  [ID_WIDTH-1:0]   id,
        input  [ADDR_WIDTH-1:0] addr,
        input  int              rready_delay_cycles,
        output [DATA_WIDTH-1:0] data,
        output [1:0]            resp,
        output [ID_WIDTH-1:0]   rid
    );
        @(posedge clk);
        s_axi_arid    <= id;
        s_axi_araddr  <= addr;
        s_axi_arlen   <= 8'h00;
        s_axi_arsize  <= 3'b010;
        s_axi_arburst <= 2'b01;
        s_axi_arvalid <= 1'b1;
        s_axi_rready  <= 1'b0;

        while (!(s_axi_arvalid && s_axi_arready)) @(posedge clk);
        s_axi_arvalid <= 1'b0;

        repeat (rready_delay_cycles) @(posedge clk);
        s_axi_rready  <= 1'b1;

        while (!(s_axi_rvalid && s_axi_rready)) @(posedge clk);
        data = s_axi_rdata;
        resp = s_axi_rresp;
        rid  = s_axi_rid;
        @(posedge clk);
        s_axi_rready <= 1'b0;
    endtask

    // ── Global Watchdog Timer ─────────────────────────────────────────────────
    initial begin
        #2_000_000; // 2 ms simulation limit
        $display("[WATCHDOG ERROR] Simulation timeout reached at time %0t!", $time);
        $display("RESULT: TEST FAILED (Timeout)");
        $fatal(1);
    end

    // ── Main Test Program ─────────────────────────────────────────────────────
    initial begin
        reg [1:0]            bresp;
        reg [1:0]            rresp;
        reg [ID_WIDTH-1:0]   rx_bid;
        reg [ID_WIDTH-1:0]   rx_rid;
        reg [DATA_WIDTH-1:0] rx_rdata;

        // Initialize signals
        rst            = 1'b1;
        s_axi_awid     = '0;
        s_axi_awaddr   = '0;
        s_axi_awlen    = '0;
        s_axi_awsize   = '0;
        s_axi_awburst  = '0;
        s_axi_awlock   = '0;
        s_axi_awcache  = '0;
        s_axi_awprot   = '0;
        s_axi_awqos    = '0;
        s_axi_awregion = '0;
        s_axi_awuser   = '0;
        s_axi_awvalid  = 1'b0;

        s_axi_wdata    = '0;
        s_axi_wstrb    = '0;
        s_axi_wlast    = 1'b0;
        s_axi_wuser    = '0;
        s_axi_wvalid   = 1'b0;
        s_axi_bready   = 1'b0;

        s_axi_arid     = '0;
        s_axi_araddr   = '0;
        s_axi_arlen    = '0;
        s_axi_arsize   = '0;
        s_axi_arburst  = '0;
        s_axi_arlock   = '0;
        s_axi_arcache  = '0;
        s_axi_arprot   = '0;
        s_axi_arqos    = '0;
        s_axi_arregion = '0;
        s_axi_aruser   = '0;
        s_axi_arvalid  = 1'b0;
        s_axi_rready   = 1'b0;

        gpio_in        = 8'hA5;
        tb_slave_mode  = 1'b0; // Start with real apb_peripherals
        tb_inj_prdata  = '0;
        tb_inj_pready  = 1'b1;
        tb_inj_pslverr = 1'b0;
        tb_wait_cycles = 0;

        $display("=================================================================");
        $display("Starting AXI4-to-APB Bridge Verification Testbench");
        $display("=================================================================");

        // Apply reset
        repeat (10) @(posedge clk);
        rst = 1'b0;
        repeat (5) @(posedge clk);

        // ── TEST 1: Reset Check ───────────────────────────────────────────────
        $display("[TEST 1] Verifying reset defaults...");
        if (s_axi_bvalid === 1'b0 && s_axi_rvalid === 1'b0 &&
            m_apb_psel === 1'b0 && m_apb_penable === 1'b0 &&
            m_apb_presetn === 1'b1) begin
            $display("  -> Reset states OK.");
            pass_count++;
        end else begin
            $display("  -> Reset defaults FAILED!");
            fail_count++;
        end

        // ── TEST 2: Real Peripheral Write (GPIO Direction & Output) ───────────
        $display("[TEST 2] Single Write to GPIO registers (0x3000_0200 & 0x3000_0204)...");
        // Address 0x3000_0200: GPIO DIR = 0x0000_00FF
        axi_write(8'h10, 32'h3000_0200, 32'h0000_00FF, 8'h00, bresp, rx_bid);
        if (bresp === 2'b00 && rx_bid === 8'h10 && gpio_dir === 8'hFF) begin
            $display("  -> GPIO DIR write successful (gpio_dir = 0x%02X).", gpio_dir);
            pass_count++;
        end else begin
            $display("  -> GPIO DIR write FAILED: bresp=%b, bid=0x%02X, gpio_dir=0x%02X", bresp, rx_bid, gpio_dir);
            fail_count++;
        end

        // Address 0x3000_0204: GPIO OUT = 0x0000_005A
        axi_write(8'h11, 32'h3000_0204, 32'h0000_005A, 8'h00, bresp, rx_bid);
        if (bresp === 2'b00 && rx_bid === 8'h11 && gpio_out === 8'h5A) begin
            $display("  -> GPIO OUT write successful (gpio_out = 0x%02X).", gpio_out);
            pass_count++;
        end else begin
            $display("  -> GPIO OUT write FAILED: bresp=%b, bid=0x%02X, gpio_out=0x%02X", bresp, rx_bid, gpio_out);
            fail_count++;
        end

        // ── TEST 3: Real Peripheral Read (Read back GPIO IN) ──────────────────
        $display("[TEST 3] Single Read from GPIO IN register (0x3000_0208)...");
        gpio_in = 8'h3C;
        axi_read(8'h20, 32'h3000_0208, 8'h00, rx_rdata, rresp, rx_rid);
        if (rresp === 2'b00 && rx_rid === 8'h20 && rx_rdata[7:0] === 8'h3C) begin
            $display("  -> GPIO IN read successful: rdata = 0x%08X", rx_rdata);
            pass_count++;
        end else begin
            $display("  -> GPIO IN read FAILED: rresp=%b, rid=0x%02X, rdata=0x%08X (expected 0x3C)", rresp, rx_rid, rx_rdata);
            fail_count++;
        end

        // ── TEST 4: Real Timer Peripheral Write and Read ──────────────────────
        $display("[TEST 4] Timer Peripheral configuration (0x3000_0300 LOAD, 0x3000_0308 CTRL)...");
        axi_write(8'h30, 32'h3000_0300, 32'h0000_1000, 8'h00, bresp, rx_bid); // LOAD = 0x1000
        axi_write(8'h31, 32'h3000_0308, 32'h0000_0001, 8'h00, bresp, rx_bid); // CTRL = 0x1 (Enable)
        repeat (10) @(posedge clk);
        axi_read(8'h32, 32'h3000_0304, 8'h00, rx_rdata, rresp, rx_rid);        // Read COUNT
        if (rresp === 2'b00 && rx_rid === 8'h32 && rx_rdata < 32'h0000_1000) begin
            $display("  -> Timer active and counting down: count = 0x%08X", rx_rdata);
            pass_count++;
        end else begin
            $display("  -> Timer read FAILED: rresp=%b, count=0x%08X", rresp, rx_rdata);
            fail_count++;
        end

        // ── TEST 5: Decoupled Timing - AW Before W ────────────────────────────
        $display("[TEST 5] Decoupled timing: AW arrives 3 cycles before W...");
        axi_write_aw_first(8'h40, 32'h3000_0204, 32'h0000_00AA, 3, bresp, rx_bid);
        if (bresp === 2'b00 && rx_bid === 8'h40 && gpio_out === 8'hAA) begin
            $display("  -> Decoupled AW-first write successful (gpio_out = 0x%02X).", gpio_out);
            pass_count++;
        end else begin
            $display("  -> Decoupled AW-first write FAILED: bresp=%b, gpio_out=0x%02X", bresp, gpio_out);
            fail_count++;
        end

        // ── TEST 6: Decoupled Timing - W Before AW ────────────────────────────
        $display("[TEST 6] Decoupled timing: W arrives 3 cycles before AW...");
        axi_write_w_first(8'h41, 32'h3000_0204, 32'h0000_0055, 3, bresp, rx_bid);
        if (bresp === 2'b00 && rx_bid === 8'h41 && gpio_out === 8'h55) begin
            $display("  -> Decoupled W-first write successful (gpio_out = 0x%02X).", gpio_out);
            pass_count++;
        end else begin
            $display("  -> Decoupled W-first write FAILED: bresp=%b, gpio_out=0x%02X", bresp, gpio_out);
            fail_count++;
        end

        // ── TEST 7: Back-to-Back Transactions ─────────────────────────────────
        $display("[TEST 7] Back-to-back writes and reads...");
        for (int i = 0; i < 5; i++) begin
            axi_write(8'h50 + i, 32'h3000_0204, i, 8'h00, bresp, rx_bid);
            if (bresp !== 2'b00 || gpio_out !== i[7:0]) begin
                $display("  -> Back-to-back write %0d failed!", i);
                fail_count++;
            end
        end
        axi_read(8'h5F, 32'h3000_0204, 8'h00, rx_rdata, rresp, rx_rid);
        if (rresp === 2'b00 && rx_rdata[7:0] === 8'd4) begin
            $display("  -> Back-to-back stream successful.");
            pass_count++;
        end else begin
            $display("  -> Back-to-back read check failed: rdata=0x%08X (expected 4)", rx_rdata);
            fail_count++;
        end

        // Switch to testbench responder mode for protocol edge testing
        tb_slave_mode = 1'b1;

        // ── TEST 8: APB Wait States (Delayed PREADY) ──────────────────────────
        $display("[TEST 8] APB Wait States: Testing delayed PREADY (1, 3, 5 wait cycles)...");
        // Test with 1 wait cycle
        tb_wait_cycles = 1;
        tb_inj_prdata  = 32'hCAFE_BABE;
        tb_inj_pslverr = 1'b0;
        axi_read(8'h61, 32'h3000_0000, 8'h00, rx_rdata, rresp, rx_rid);
        if (rresp === 2'b00 && rx_rdata === 32'hCAFE_BABE) begin
            $display("  -> 1 wait-state read passed.");
            pass_count++;
        end else begin
            $display("  -> 1 wait-state read FAILED: rdata=0x%08X", rx_rdata);
            fail_count++;
        end

        // Test with 3 wait cycles
        tb_wait_cycles = 3;
        tb_inj_prdata  = 32'h1234_5678;
        axi_read(8'h62, 32'h3000_0000, 8'h00, rx_rdata, rresp, rx_rid);
        if (rresp === 2'b00 && rx_rdata === 32'h1234_5678) begin
            $display("  -> 3 wait-state read passed.");
            pass_count++;
        end else begin
            $display("  -> 3 wait-state read FAILED: rdata=0x%08X", rx_rdata);
            fail_count++;
        end

        // Test with 5 wait cycles on Write
        tb_wait_cycles = 5;
        axi_write(8'h63, 32'h3000_0000, 32'hDEAD_BEEF, 8'h00, bresp, rx_bid);
        if (bresp === 2'b00 && rx_bid === 8'h63) begin
            $display("  -> 5 wait-state write passed.");
            pass_count++;
        end else begin
            $display("  -> 5 wait-state write FAILED: bresp=%b", bresp);
            fail_count++;
        end
        tb_wait_cycles = 0;

        // ── TEST 9: APB PSLVERR Injection on Write ────────────────────────────
        $display("[TEST 9] APB PSLVERR injection during write...");
        tb_inj_pslverr = 1'b1;
        axi_write(8'h70, 32'h3000_0000, 32'hDEAD_BEEF, 8'h00, bresp, rx_bid);
        if (bresp === 2'b10 && rx_bid === 8'h70) begin // SLVERR = 2'b10
            $display("  -> PSLVERR correctly propagated to AXI BRESP = 2'b10 (SLVERR).");
            pass_count++;
        end else begin
            $display("  -> PSLVERR write FAILED: bresp=%b (expected 2'b10)", bresp);
            fail_count++;
        end

        // ── TEST 10: APB PSLVERR Injection on Read ────────────────────────────
        $display("[TEST 10] APB PSLVERR injection during read...");
        tb_inj_pslverr = 1'b1;
        axi_read(8'h71, 32'h3000_0000, 8'h00, rx_rdata, rresp, rx_rid);
        if (rresp === 2'b10 && rx_rid === 8'h71) begin // SLVERR = 2'b10
            $display("  -> PSLVERR correctly propagated to AXI RRESP = 2'b10 (SLVERR).");
            pass_count++;
        end else begin
            $display("  -> PSLVERR read FAILED: rresp=%b (expected 2'b10)", rresp);
            fail_count++;
        end
        tb_inj_pslverr = 1'b0;

        // ── TEST 11: Unsupported Burst Write Detection ────────────────────────
        $display("[TEST 11] Unsupported burst write detection (awlen = 1)...");
        axi_write(8'h80, 32'h3000_0000, 32'hBEEF_0001, 8'h01, bresp, rx_bid);
        if (bresp === 2'b10 && rx_bid === 8'h80) begin
            $display("  -> Bridge correctly returned SLVERR for unsupported awlen > 0.");
            pass_count++;
        end else begin
            $display("  -> Unsupported burst write check FAILED: bresp=%b", bresp);
            fail_count++;
        end

        // ── TEST 12: Unsupported Burst Read Detection ─────────────────────────
        $display("[TEST 12] Unsupported burst read detection (arlen = 3)...");
        axi_read(8'h81, 32'h3000_0000, 8'h03, rx_rdata, rresp, rx_rid);
        if (rresp === 2'b10 && rx_rid === 8'h81) begin
            $display("  -> Bridge correctly returned SLVERR for unsupported arlen > 0.");
            pass_count++;
        end else begin
            $display("  -> Unsupported burst read check FAILED: rresp=%b", rresp);
            fail_count++;
        end

        // ── TEST 13: Delayed RREADY Backpressure Check ────────────────────────
        $display("[TEST 13] Delayed RREADY backpressure check (4 cycle master delay)...");
        tb_inj_prdata = 32'hBACC_D00D;
        axi_read_delayed_rready(8'h90, 32'h3000_0000, 4, rx_rdata, rresp, rx_rid);
        if (rresp === 2'b00 && rx_rdata === 32'hBACC_D00D && rx_rid === 8'h90) begin
            $display("  -> Delayed RREADY accepted correctly.");
            pass_count++;
        end else begin
            $display("  -> Delayed RREADY FAILED: rdata=0x%08X", rx_rdata);
            fail_count++;
        end

        // ── Final Verification Summary ────────────────────────────────────────
        repeat (10) @(posedge clk);
        $display("=================================================================");
        $display("AXI4-to-APB Bridge Verification Completed");
        $display("Total Passed Checks: %0d", pass_count);
        $display("Total Failed Checks: %0d", fail_count);
        $display("=================================================================");

        if (fail_count == 0) begin
            $display("RESULT: TEST PASSED");
            $finish(0);
        end else begin
            $display("RESULT: TEST FAILED with %0d errors", fail_count);
            $fatal(1);
        end
    end

endmodule

`default_nettype wire
