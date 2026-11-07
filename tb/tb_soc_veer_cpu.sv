`timescale 1ns / 1ps

// =============================================================================
// Comprehensive SoC + Real VeeR EL2 CPU Testbench
// =============================================================================
// Verifies:
// 1. Genuine Western Digital / CHIPS Alliance VeeR EL2 CPU boot from 0x1000_0000
// 2. Instruction fetch from SoC Boot ROM via 64->32 AXI IFU width adapter
// 3. Execution of compiled C firmware (sw/test.c)
// 4. Data store to SoC SRAM via 64->32 AXI LSU width adapter
// 5. Verification of signature 0xC0FFEE00 at SRAM address 0x0000_0100
// =============================================================================

module tb_soc_veer_cpu;
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;
    parameter ID_WIDTH   = 8;

    reg clk;
    reg rst_l;
    reg dbg_rst_l;

    // IFU 32-bit AXI Manager bus (CPU wrapper -> SoC)
    wire [ID_WIDTH-1:0]     m0_ifu_arid;
    wire [ADDR_WIDTH-1:0]   m0_ifu_araddr;
    wire [7:0]              m0_ifu_arlen;
    wire [2:0]              m0_ifu_arsize;
    wire [1:0]              m0_ifu_arburst;
    wire                    m0_ifu_arlock;
    wire [3:0]              m0_ifu_arcache;
    wire [2:0]              m0_ifu_arprot;
    wire [3:0]              m0_ifu_arqos;
    wire [3:0]              m0_ifu_arregion;
    wire                    m0_ifu_aruser;
    wire                    m0_ifu_arvalid;
    wire                    m0_ifu_arready;
    wire [ID_WIDTH-1:0]     m0_ifu_rid;
    wire [DATA_WIDTH-1:0]   m0_ifu_rdata;
    wire [1:0]              m0_ifu_rresp;
    wire                    m0_ifu_rlast;
    wire                    m0_ifu_ruser;
    wire                    m0_ifu_rvalid;
    wire                    m0_ifu_rready;

    // LSU 32-bit AXI Manager bus (CPU wrapper -> SoC)
    wire [ID_WIDTH-1:0]     m1_lsu_awid;
    wire [ADDR_WIDTH-1:0]   m1_lsu_awaddr;
    wire [7:0]              m1_lsu_awlen;
    wire [2:0]              m1_lsu_awsize;
    wire [1:0]              m1_lsu_awburst;
    wire                    m1_lsu_awlock;
    wire [3:0]              m1_lsu_awcache;
    wire [2:0]              m1_lsu_awprot;
    wire [3:0]              m1_lsu_awqos;
    wire [3:0]              m1_lsu_awregion;
    wire                    m1_lsu_awuser;
    wire                    m1_lsu_awvalid;
    wire                    m1_lsu_awready;
    wire [DATA_WIDTH-1:0]   m1_lsu_wdata;
    wire [DATA_WIDTH/8-1:0] m1_lsu_wstrb;
    wire                    m1_lsu_wlast;
    wire                    m1_lsu_wuser;
    wire                    m1_lsu_wvalid;
    wire                    m1_lsu_wready;
    wire [ID_WIDTH-1:0]     m1_lsu_bid;
    wire [1:0]              m1_lsu_bresp;
    wire                    m1_lsu_buser;
    wire                    m1_lsu_bvalid;
    wire                    m1_lsu_bready;
    wire [ID_WIDTH-1:0]     m1_lsu_arid;
    wire [ADDR_WIDTH-1:0]   m1_lsu_araddr;
    wire [7:0]              m1_lsu_arlen;
    wire [2:0]              m1_lsu_arsize;
    wire [1:0]              m1_lsu_arburst;
    wire                    m1_lsu_arlock;
    wire [3:0]              m1_lsu_arcache;
    wire [2:0]              m1_lsu_arprot;
    wire [3:0]              m1_lsu_arqos;
    wire [3:0]              m1_lsu_arregion;
    wire                    m1_lsu_aruser;
    wire                    m1_lsu_arvalid;
    wire                    m1_lsu_arready;
    wire [ID_WIDTH-1:0]     m1_lsu_rid;
    wire [DATA_WIDTH-1:0]   m1_lsu_rdata;
    wire [1:0]              m1_lsu_rresp;
    wire                    m1_lsu_rlast;
    wire                    m1_lsu_ruser;
    wire                    m1_lsu_rvalid;
    wire                    m1_lsu_rready;

    // Tie-off idle signals for unused managers m2 (Debug) and m3 (DMA Loopback)
    wire [ID_WIDTH-1:0]     z_id    = {ID_WIDTH{1'b0}};
    wire [ADDR_WIDTH-1:0]   z_addr  = {ADDR_WIDTH{1'b0}};
    wire [DATA_WIDTH-1:0]   z_data  = {DATA_WIDTH{1'b0}};
    wire [DATA_WIDTH/8-1:0] z_strb  = {(DATA_WIDTH/8){1'b0}};

    // =========================================================================
    // Real Western Digital / CHIPS Alliance VeeR EL2 CPU Wrapper
    // =========================================================================
    veer_cpu_wrapper #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) u_cpu_wrapper (
        .clk             (clk),
        .rst_l           (rst_l),
        .dbg_rst_l       (dbg_rst_l),

        // IFU
        .m0_ifu_arid     (m0_ifu_arid),
        .m0_ifu_araddr   (m0_ifu_araddr),
        .m0_ifu_arlen    (m0_ifu_arlen),
        .m0_ifu_arsize   (m0_ifu_arsize),
        .m0_ifu_arburst  (m0_ifu_arburst),
        .m0_ifu_arlock   (m0_ifu_arlock),
        .m0_ifu_arcache  (m0_ifu_arcache),
        .m0_ifu_arprot   (m0_ifu_arprot),
        .m0_ifu_arqos    (m0_ifu_arqos),
        .m0_ifu_arregion (m0_ifu_arregion),
        .m0_ifu_aruser   (m0_ifu_aruser),
        .m0_ifu_arvalid  (m0_ifu_arvalid),
        .m0_ifu_arready  (m0_ifu_arready),
        .m0_ifu_rid      (m0_ifu_rid),
        .m0_ifu_rdata    (m0_ifu_rdata),
        .m0_ifu_rresp    (m0_ifu_rresp),
        .m0_ifu_rlast    (m0_ifu_rlast),
        .m0_ifu_ruser    (m0_ifu_ruser),
        .m0_ifu_rvalid   (m0_ifu_rvalid),
        .m0_ifu_rready   (m0_ifu_rready),

        // LSU
        .m1_lsu_awid     (m1_lsu_awid),
        .m1_lsu_awaddr   (m1_lsu_awaddr),
        .m1_lsu_awlen    (m1_lsu_awlen),
        .m1_lsu_awsize   (m1_lsu_awsize),
        .m1_lsu_awburst  (m1_lsu_awburst),
        .m1_lsu_awlock   (m1_lsu_awlock),
        .m1_lsu_awcache  (m1_lsu_awcache),
        .m1_lsu_awprot   (m1_lsu_awprot),
        .m1_lsu_awqos    (m1_lsu_awqos),
        .m1_lsu_awregion (m1_lsu_awregion),
        .m1_lsu_awuser   (m1_lsu_awuser),
        .m1_lsu_awvalid  (m1_lsu_awvalid),
        .m1_lsu_awready  (m1_lsu_awready),
        .m1_lsu_wdata    (m1_lsu_wdata),
        .m1_lsu_wstrb    (m1_lsu_wstrb),
        .m1_lsu_wlast    (m1_lsu_wlast),
        .m1_lsu_wuser    (m1_lsu_wuser),
        .m1_lsu_wvalid   (m1_lsu_wvalid),
        .m1_lsu_wready   (m1_lsu_wready),
        .m1_lsu_bid      (m1_lsu_bid),
        .m1_lsu_bresp    (m1_lsu_bresp),
        .m1_lsu_buser    (m1_lsu_buser),
        .m1_lsu_bvalid   (m1_lsu_bvalid),
        .m1_lsu_bready   (m1_lsu_bready),
        .m1_lsu_arid     (m1_lsu_arid),
        .m1_lsu_araddr   (m1_lsu_araddr),
        .m1_lsu_arlen    (m1_lsu_arlen),
        .m1_lsu_arsize   (m1_lsu_arsize),
        .m1_lsu_arburst  (m1_lsu_arburst),
        .m1_lsu_arlock   (m1_lsu_arlock),
        .m1_lsu_arcache  (m1_lsu_arcache),
        .m1_lsu_arprot   (m1_lsu_arprot),
        .m1_lsu_arqos    (m1_lsu_arqos),
        .m1_lsu_arregion (m1_lsu_arregion),
        .m1_lsu_aruser   (m1_lsu_aruser),
        .m1_lsu_arvalid  (m1_lsu_arvalid),
        .m1_lsu_arready  (m1_lsu_arready),
        .m1_lsu_rid      (m1_lsu_rid),
        .m1_lsu_rdata    (m1_lsu_rdata),
        .m1_lsu_rresp    (m1_lsu_rresp),
        .m1_lsu_rlast    (m1_lsu_rlast),
        .m1_lsu_ruser    (m1_lsu_ruser),
        .m1_lsu_rvalid   (m1_lsu_rvalid),
        .m1_lsu_rready   (m1_lsu_rready),

        // Interrupts
        .timer_int       (1'b0),
        .soft_int        (1'b0),
        .extintsrc_req   (31'd0)
    );

    // =========================================================================
    // SoC Top Level Instance
    // =========================================================================
    soc_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) u_soc (
        .clk             (clk),
        .rst_l           (rst_l),

        // Port 0: Driven by VeeR EL2 IFU
        .m0_awid         (z_id),
        .m0_awaddr       (z_addr),
        .m0_awlen        (8'd0),
        .m0_awsize       (3'd0),
        .m0_awburst      (2'd0),
        .m0_awlock       (1'b0),
        .m0_awcache      (4'd0),
        .m0_awprot       (3'd0),
        .m0_awqos        (4'd0),
        .m0_awregion     (4'd0),
        .m0_awuser       (1'b0),
        .m0_awvalid      (1'b0),
        .m0_awready      (),
        .m0_wdata        (z_data),
        .m0_wstrb        (z_strb),
        .m0_wlast        (1'b0),
        .m0_wuser        (1'b0),
        .m0_wvalid       (1'b0),
        .m0_wready       (),
        .m0_bid          (),
        .m0_bresp        (),
        .m0_buser        (),
        .m0_bvalid       (),
        .m0_bready       (1'b1),
        .m0_arid         (m0_ifu_arid),
        .m0_araddr       (m0_ifu_araddr),
        .m0_arlen        (m0_ifu_arlen),
        .m0_arsize       (m0_ifu_arsize),
        .m0_arburst      (m0_ifu_arburst),
        .m0_arlock       (m0_ifu_arlock),
        .m0_arcache      (m0_ifu_arcache),
        .m0_arprot       (m0_ifu_arprot),
        .m0_arqos        (m0_ifu_arqos),
        .m0_arregion     (m0_ifu_arregion),
        .m0_aruser       (m0_ifu_aruser),
        .m0_arvalid      (m0_ifu_arvalid),
        .m0_arready      (m0_ifu_arready),
        .m0_rid          (m0_ifu_rid),
        .m0_rdata        (m0_ifu_rdata),
        .m0_rresp        (m0_ifu_rresp),
        .m0_rlast        (m0_ifu_rlast),
        .m0_ruser        (m0_ifu_ruser),
        .m0_rvalid       (m0_ifu_rvalid),
        .m0_rready       (m0_ifu_rready),

        // Port 1: Driven by VeeR EL2 LSU
        .m1_awid         (m1_lsu_awid),
        .m1_awaddr       (m1_lsu_awaddr),
        .m1_awlen        (m1_lsu_awlen),
        .m1_awsize       (m1_lsu_awsize),
        .m1_awburst      (m1_lsu_awburst),
        .m1_awlock       (m1_lsu_awlock),
        .m1_awcache      (m1_lsu_awcache),
        .m1_awprot       (m1_lsu_awprot),
        .m1_awqos        (m1_lsu_awqos),
        .m1_awregion     (m1_lsu_awregion),
        .m1_awuser       (m1_lsu_awuser),
        .m1_awvalid      (m1_lsu_awvalid),
        .m1_awready      (m1_lsu_awready),
        .m1_wdata        (m1_lsu_wdata),
        .m1_wstrb        (m1_lsu_wstrb),
        .m1_wlast        (m1_lsu_wlast),
        .m1_wuser        (m1_lsu_wuser),
        .m1_wvalid       (m1_lsu_wvalid),
        .m1_wready       (m1_lsu_wready),
        .m1_bid          (m1_lsu_bid),
        .m1_bresp        (m1_lsu_bresp),
        .m1_buser        (m1_lsu_buser),
        .m1_bvalid       (m1_lsu_bvalid),
        .m1_bready       (m1_lsu_bready),
        .m1_arid         (m1_lsu_arid),
        .m1_araddr       (m1_lsu_araddr),
        .m1_arlen        (m1_lsu_arlen),
        .m1_arsize       (m1_lsu_arsize),
        .m1_arburst      (m1_lsu_arburst),
        .m1_arlock       (m1_lsu_arlock),
        .m1_arcache      (m1_lsu_arcache),
        .m1_arprot       (m1_lsu_arprot),
        .m1_arqos        (m1_lsu_arqos),
        .m1_arregion     (m1_lsu_arregion),
        .m1_aruser       (m1_lsu_aruser),
        .m1_arvalid      (m1_lsu_arvalid),
        .m1_arready      (m1_lsu_arready),
        .m1_rid          (m1_lsu_rid),
        .m1_rdata        (m1_lsu_rdata),
        .m1_rresp        (m1_lsu_rresp),
        .m1_rlast        (m1_lsu_rlast),
        .m1_ruser        (m1_lsu_ruser),
        .m1_rvalid       (m1_lsu_rvalid),
        .m1_rready       (m1_lsu_rready),

        // Port 2: Idle (Debug / System Bus)
        .m2_awid(z_id), .m2_awaddr(z_addr), .m2_awlen(8'd0), .m2_awsize(3'd0),
        .m2_awburst(2'd0), .m2_awlock(1'b0), .m2_awcache(4'd0), .m2_awprot(3'd0),
        .m2_awqos(4'd0), .m2_awregion(4'd0), .m2_awuser(1'b0), .m2_awvalid(1'b0),
        .m2_awready(), .m2_wdata(z_data), .m2_wstrb(z_strb), .m2_wlast(1'b0),
        .m2_wuser(1'b0), .m2_wvalid(1'b0), .m2_wready(), .m2_bid(), .m2_bresp(),
        .m2_buser(), .m2_bvalid(), .m2_bready(1'b1),
        .m2_arid(z_id), .m2_araddr(z_addr), .m2_arlen(8'd0), .m2_arsize(3'd0),
        .m2_arburst(2'd0), .m2_arlock(1'b0), .m2_arcache(4'd0), .m2_arprot(3'd0),
        .m2_arqos(4'd0), .m2_arregion(4'd0), .m2_aruser(1'b0), .m2_arvalid(1'b0),
        .m2_arready(), .m2_rid(), .m2_rdata(), .m2_rresp(), .m2_rlast(),
        .m2_ruser(), .m2_rvalid(), .m2_rready(1'b1),

        // Port 3: Idle (DMA Loopback)
        .m3_awid(z_id), .m3_awaddr(z_addr), .m3_awlen(8'd0), .m3_awsize(3'd0),
        .m3_awburst(2'd0), .m3_awlock(1'b0), .m3_awcache(4'd0), .m3_awprot(3'd0),
        .m3_awqos(4'd0), .m3_awregion(4'd0), .m3_awuser(1'b0), .m3_awvalid(1'b0),
        .m3_awready(), .m3_wdata(z_data), .m3_wstrb(z_strb), .m3_wlast(1'b0),
        .m3_wuser(1'b0), .m3_wvalid(1'b0), .m3_wready(), .m3_bid(), .m3_bresp(),
        .m3_buser(), .m3_bvalid(), .m3_bready(1'b1),
        .m3_arid(z_id), .m3_araddr(z_addr), .m3_arlen(8'd0), .m3_arsize(3'd0),
        .m3_arburst(2'd0), .m3_arlock(1'b0), .m3_arcache(4'd0), .m3_arprot(3'd0),
        .m3_arqos(4'd0), .m3_arregion(4'd0), .m3_aruser(1'b0), .m3_arvalid(1'b0),
        .m3_arready(), .m3_rid(), .m3_rdata(), .m3_rresp(), .m3_rlast(),
        .m3_ruser(), .m3_rvalid(), .m3_rready(1'b1)
    );

    // =========================================================================
    // Clock Generation: 100 MHz (10ns period)
    // =========================================================================
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // =========================================================================
    // Trace & Bus Monitoring
    // =========================================================================
    integer ifu_fetch_count = 0;
    integer lsu_write_count = 0;
    integer retired_count   = 0;
    reg     pass_detected   = 1'b0;

    // Monitor instruction retirement via VeeR EL2 internal trace ports
    always @(posedge clk) begin
        if (rst_l && u_cpu_wrapper.u_cpu.trace_rv_i_valid_ip) begin
            retired_count = retired_count + 1;
            $display("[VeeR RETIRE #%0d] Time=%0t | PC = 0x%08x | INSN = 0x%08x",
                     retired_count, $time,
                     u_cpu_wrapper.u_cpu.trace_rv_i_address_ip,
                     u_cpu_wrapper.u_cpu.trace_rv_i_insn_ip);
        end
    end


    // Detailed AXI Boot ROM and IFU bus trace
    always @(posedge clk) begin
        if (u_soc.r1_arvalid || u_soc.r1_arready || u_soc.r1_rvalid || u_soc.r1_rready) begin
            $display("[ROM BUS] Time=%0t | ARVAL=%b ARRDY=%b ARADDR=0x%h ARLEN=%0d | RVAL=%b RRDY=%b RDATA=0x%h RLAST=%b",
                     $time, u_soc.r1_arvalid, u_soc.r1_arready, u_soc.r1_araddr, u_soc.r1_arlen,
                     u_soc.r1_rvalid, u_soc.r1_rready, u_soc.r1_rdata, u_soc.r1_rlast);
        end
        if (m0_ifu_rvalid || m0_ifu_rready) begin
            $display("[IFU 32] Time=%0t | RVAL=%b RRDY=%b RDATA=0x%h RLAST=%b RID=%0d",
                     $time, m0_ifu_rvalid, m0_ifu_rready, m0_ifu_rdata, m0_ifu_rlast, m0_ifu_rid);
        end
        if (u_cpu_wrapper.veer_ifu_arvalid || u_cpu_wrapper.veer_ifu_arready || u_cpu_wrapper.veer_ifu_rvalid || u_cpu_wrapper.veer_ifu_rready) begin
            $display("[CPU 64 IFU] Time=%0t | ARVAL=%b ARRDY=%b ARADDR=0x%h ARLEN=%0d | RVAL=%b RRDY=%b RDATA=0x%h RLAST=%b",
                     $time, u_cpu_wrapper.veer_ifu_arvalid, u_cpu_wrapper.veer_ifu_arready, u_cpu_wrapper.veer_ifu_araddr, u_cpu_wrapper.veer_ifu_arlen,
                     u_cpu_wrapper.veer_ifu_rvalid, u_cpu_wrapper.veer_ifu_rready, u_cpu_wrapper.veer_ifu_rdata, u_cpu_wrapper.veer_ifu_rlast);
        end
    end


// Monitor IFU Boot ROM fetches
    always @(posedge clk) begin
        if (m0_ifu_arvalid && m0_ifu_arready) begin
            ifu_fetch_count = ifu_fetch_count + 1;
            $display("[AXI IFU FETCH #%0d] Time=%0t | ARADDR = 0x%08x | LEN = %0d | SIZE = %0d",
                     ifu_fetch_count, $time, m0_ifu_araddr, m0_ifu_arlen, m0_ifu_arsize);
        end
    end

    // Monitor LSU SRAM stores
    always @(posedge clk) begin
        if (m1_lsu_awvalid && m1_lsu_awready) begin
            $display("[AXI LSU WRITE ADDR] Time=%0t | AWADDR = 0x%08x", $time, m1_lsu_awaddr);
        end
        if (m1_lsu_wvalid && m1_lsu_wready) begin
            lsu_write_count = lsu_write_count + 1;
            $display("[AXI LSU WRITE DATA #%0d] Time=%0t | WDATA = 0x%08x | STRB = %b",
                     lsu_write_count, $time, m1_lsu_wdata, m1_lsu_wstrb);
        end
    end

    // Check for target write 0xC0FFEE00 to SRAM address 0x0000_0100 (mem index 64)
    always @(posedge clk) begin
        if (u_soc.u_ram0.mem[64] == 32'hC0FFEE00 && !pass_detected) begin
            pass_detected = 1'b1;
            $display("\n==========================================================================");
            $display("                       *** SIMULATION PASSED ***                          ");
            $display("==========================================================================");
            $display("[SUCCESS] Real VeeR EL2 CPU booted from reset vector 0x1000_0000!");
            $display("[SUCCESS] Boot ROM firmware (sw/test.c) successfully executed!");
            $display("[SUCCESS] SRAM Address 0x00000100 (mem[64]) wrote signature: 0x%08x", u_soc.u_ram0.mem[64]);
            $display("--------------------------------------------------------------------------");
            $display("Subsystem Test Status Breakdown (read from SoC SRAM):");
            $display("  [1] System SRAM R/W Test (0x00000104)      : 0x%08x (%s)", u_soc.u_ram0.mem[65], (u_soc.u_ram0.mem[65]==1) ? "PASS" : "FAIL");
            $display("  [2] Boot ROM Read Test   (0x00000108)      : 0x%08x (%s)", u_soc.u_ram0.mem[66], (u_soc.u_ram0.mem[66]==1) ? "PASS" : "FAIL");
            $display("  [3] IPU Configuration    (0x0000010C)      : 0x%08x (%s)", u_soc.u_ram0.mem[67], (u_soc.u_ram0.mem[67]==1) ? "PASS" : "FAIL");
            $display("  [4] APB GPIO Test        (0x00000110)      : 0x%08x (%s)", u_soc.u_ram0.mem[68], (u_soc.u_ram0.mem[68]==1) ? "PASS" : "FAIL");
            $display("  [5] APB Timer Test       (0x00000114)      : 0x%08x (%s)", u_soc.u_ram0.mem[69], (u_soc.u_ram0.mem[69]==1) ? "PASS" : "FAIL");
            $display("  [6] APB UART Test        (0x00000118)      : 0x%08x (%s)", u_soc.u_ram0.mem[70], (u_soc.u_ram0.mem[70]==1) ? "PASS" : "FAIL");
            $display("  [7] APB SPI Test         (0x0000011C)      : 0x%08x (%s)", u_soc.u_ram0.mem[71], (u_soc.u_ram0.mem[71]==1) ? "PASS" : "FAIL");
            $display("  [8] APB PIC Test         (0x00000120)      : 0x%08x (%s)", u_soc.u_ram0.mem[72], (u_soc.u_ram0.mem[72]==1) ? "PASS" : "FAIL");
            $display("  [>] Total Tests Passed   (0x00000124)      : %0d / 8", u_soc.u_ram0.mem[73]);
            $display("--------------------------------------------------------------------------");
            $display("[SUCCESS] Total Instructions Retired : %0d", retired_count);
            $display("[SUCCESS] Total IFU Fetches          : %0d", ifu_fetch_count);
            $display("[SUCCESS] Total LSU Stores           : %0d", lsu_write_count);
            $display("==========================================================================\n");
            #50;
            $finish;
        end
    end

    // =========================================================================
    // Simulation Control & Reset Sequence
    // =========================================================================
    initial begin
        $display("==========================================================================");
        $display("  STARTING VEER EL2 SoC REAL CPU FIRMWARE VALIDATION (Synopsys VCS)      ");
        $display("==========================================================================");
        $display("Firmware Target: sw/test.c (Writes 0xC0FFEE00 to SRAM 0x00000100)");
        $display("Reset Vector:    0x10000000 (SoC Boot ROM)");
        $display("Expected Signature at SRAM 0x00000100: 0xC0FFEE00");
        $display("==========================================================================\n");

        // Proper reset sequence with 1 -> 0 transition to trigger all negedge reset flops
        rst_l     = 1'b1;
        dbg_rst_l = 1'b1;
        #10;
        @(posedge clk);
        rst_l     = 1'b0;
        dbg_rst_l = 1'b0;

        // Hold reset for 100 ns
        #100;
        @(posedge clk);
        rst_l     = 1'b1;
        dbg_rst_l = 1'b1;
        $display("[TESTBENCH] Reset deasserted at Time=%0t. VeeR EL2 CPU starting execution...", $time);

        // Timeout Watchdog: 200,000 ns (20,000 cycles)
        #200000;
        $display("\n[ERROR] Watchdog timeout reached (200 us)!");
        $display("[ERROR] Current SRAM[64] = 0x%08x (Expected: 0xC0FFEE00)", u_soc.u_ram0.mem[64]);
        $display("[ERROR] Instructions Retired: %0d | IFU Fetches: %0d | LSU Stores: %0d",
                 retired_count, ifu_fetch_count, lsu_write_count);
        $fatal(1, "VeeR EL2 SoC firmware execution timed out without writing signature!");
    end

`ifdef FSDB
    initial begin
        $fsdbDumpfile("build/veer_cpu.fsdb");
        $fsdbDumpvars(0, tb_soc_veer_cpu);
        $fsdbDumpMDA();
    end
`endif

endmodule
