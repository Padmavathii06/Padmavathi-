// =============================================================================
// AXI4-to-APB Bridge — Synchronous Bridge Subsystem
//
// Bridges AXI4 crossbar master port m03 (0x3000_0000 - 0x3FFF_FFFF)
// to AMBA APB peripheral subsystem (UART, SPI, GPIO, Timer, PIC).
//
// Architecture & Features:
//   - AXI4 Subordinate interface matches crossbar port m03_axi_* exactly.
//   - APB Master interface matches apb_peripherals.v slave interface exactly.
//   - Decoupled AW / W channel acceptance (AW before W, W before AW, or concurrent).
//   - Two-phase standard APB transfer generation: SETUP phase followed by ACCESS phase.
//   - Supports APB wait-states (PREADY flow control).
//   - Preserves AXI transaction IDs (BID = AWID, RID = ARID).
//   - Error reporting: PSLVERR or unsupported bursts (awlen > 0, arlen > 0)
//     safely return AXI SLVERR (2'b10) response.
// =============================================================================

`timescale 1ns / 1ps
`default_nettype none

module axi_apb_bridge #(
    parameter DATA_WIDTH   = 32,
    parameter ADDR_WIDTH   = 32,
    parameter STRB_WIDTH   = (DATA_WIDTH / 8),
    parameter ID_WIDTH     = 8,
    parameter AWUSER_WIDTH = 1,
    parameter WUSER_WIDTH  = 1,
    parameter BUSER_WIDTH  = 1,
    parameter ARUSER_WIDTH = 1,
    parameter RUSER_WIDTH  = 1
) (
    // ── Clock & Reset ─────────────────────────────────────────────────────────
    input  wire                   clk,
    input  wire                   rst,          // active-high synchronous reset

    // ── AXI4 Slave Write Address Channel (matches m03_axi_aw*) ────────────────
    input  wire [ID_WIDTH-1:0]     s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  wire [7:0]              s_axi_awlen,
    input  wire [2:0]              s_axi_awsize,
    input  wire [1:0]              s_axi_awburst,
    input  wire                    s_axi_awlock,
    input  wire [3:0]              s_axi_awcache,
    input  wire [2:0]              s_axi_awprot,
    input  wire [3:0]              s_axi_awqos,
    input  wire [3:0]              s_axi_awregion,
    input  wire [AWUSER_WIDTH-1:0] s_axi_awuser,
    input  wire                    s_axi_awvalid,
    output wire                    s_axi_awready,

    // ── AXI4 Slave Write Data Channel (matches m03_axi_w*) ────────────────────
    input  wire [DATA_WIDTH-1:0]   s_axi_wdata,
    input  wire [STRB_WIDTH-1:0]   s_axi_wstrb,
    input  wire                    s_axi_wlast,
    input  wire [WUSER_WIDTH-1:0]  s_axi_wuser,
    input  wire                    s_axi_wvalid,
    output wire                    s_axi_wready,

    // ── AXI4 Slave Write Response Channel (matches m03_axi_b*) ────────────────
    output reg  [ID_WIDTH-1:0]     s_axi_bid,
    output reg  [1:0]              s_axi_bresp,
    output reg  [BUSER_WIDTH-1:0]  s_axi_buser,
    output reg                     s_axi_bvalid,
    input  wire                    s_axi_bready,

    // ── AXI4 Slave Read Address Channel (matches m03_axi_ar*) ─────────────────
    input  wire [ID_WIDTH-1:0]     s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]   s_axi_araddr,
    input  wire [7:0]              s_axi_arlen,
    input  wire [2:0]              s_axi_arsize,
    input  wire [1:0]              s_axi_arburst,
    input  wire                    s_axi_arlock,
    input  wire [3:0]              s_axi_arcache,
    input  wire [2:0]              s_axi_arprot,
    input  wire [3:0]              s_axi_arqos,
    input  wire [3:0]              s_axi_arregion,
    input  wire [ARUSER_WIDTH-1:0] s_axi_aruser,
    input  wire                    s_axi_arvalid,
    output wire                    s_axi_arready,

    // ── AXI4 Slave Read Data Channel (matches m03_axi_r*) ─────────────────────
    output reg  [ID_WIDTH-1:0]     s_axi_rid,
    output reg  [DATA_WIDTH-1:0]   s_axi_rdata,
    output reg  [1:0]              s_axi_rresp,
    output reg                     s_axi_rlast,
    output reg  [RUSER_WIDTH-1:0]  s_axi_ruser,
    output reg                     s_axi_rvalid,
    input  wire                    s_axi_rready,

    // ── APB Master Interface (matches apb_peripherals.v) ──────────────────────
    output wire                    m_apb_pclk,
    output wire                    m_apb_presetn,
    output reg  [31:0]             m_apb_paddr,
    output reg  [31:0]             m_apb_pwdata,
    output reg                     m_apb_pwrite,
    output reg                     m_apb_psel,
    output reg                     m_apb_penable,
    input  wire [31:0]             m_apb_prdata,
    input  wire                    m_apb_pready,
    input  wire                    m_apb_pslverr
);

    // Pass clock and inverted reset directly to APB domain
    assign m_apb_pclk    = clk;
    assign m_apb_presetn = !rst;

    // ── AXI Response Codes ────────────────────────────────────────────────────
    localparam [1:0]
        RESP_OKAY   = 2'b00,
        RESP_SLVERR = 2'b10;

    // ── FSM State Encoding ────────────────────────────────────────────────────
    localparam [2:0]
        ST_IDLE         = 3'd0,
        ST_APB_SETUP_WR = 3'd1,
        ST_APB_ACC_WR   = 3'd2,
        ST_WR_RESP      = 3'd3,
        ST_APB_SETUP_RD = 3'd4,
        ST_APB_ACC_RD   = 3'd5,
        ST_RD_RESP      = 3'd6,
        ST_DRAIN_WR     = 3'd7;

    reg [2:0] state;

    // ── Decoupled Latching Registers ──────────────────────────────────────────
    reg                  aw_latched;
    reg                  w_latched;
    reg                  ar_latched;

    reg [ID_WIDTH-1:0]   latched_awid;
    reg [ADDR_WIDTH-1:0] latched_awaddr;
    reg [7:0]            latched_awlen;
    reg [2:0]            latched_awsize;
    reg [1:0]            latched_awburst;

    reg [DATA_WIDTH-1:0] latched_wdata;
    reg [STRB_WIDTH-1:0] latched_wstrb;
    reg                  latched_wlast;

    reg [ID_WIDTH-1:0]   latched_arid;
    reg [ADDR_WIDTH-1:0] latched_araddr;
    reg [7:0]            latched_arlen;
    reg [2:0]            latched_arsize;
    reg [1:0]            latched_arburst;
    reg [ARUSER_WIDTH-1:0] latched_aruser;

    // Flag whether bridge is actively executing an APB transaction or response
    wire apb_busy = (state != ST_IDLE);

    // AXI Channel Readiness
    // AW and W can be accepted independently in IDLE or when not busy
    assign s_axi_awready = (!aw_latched) && (!apb_busy) && (!s_axi_bvalid);
    assign s_axi_wready  = (state == ST_DRAIN_WR) || ((!w_latched) && (!apb_busy) && (!s_axi_bvalid));
    assign s_axi_arready = (!ar_latched) && (!apb_busy) && (!s_axi_rvalid);

    // Check if both address and data are present for write
    wire write_req_ready = (aw_latched || (s_axi_awvalid && s_axi_awready)) &&
                           (w_latched  || (s_axi_wvalid  && s_axi_wready));

    // Check if read address is present
    wire read_req_ready  = (ar_latched || (s_axi_arvalid && s_axi_arready));

    // Priority flag for round-robin arbitration when both R and W are ready
    reg last_service_was_write;

    // Arbitration decisions in ST_IDLE
    wire start_write = (state == ST_IDLE) && write_req_ready && (!read_req_ready || !last_service_was_write);
    wire start_read  = (state == ST_IDLE) && read_req_ready && (!write_req_ready || last_service_was_write);

    // Effective write signals (latched or direct)
    wire [ID_WIDTH-1:0]   eff_awid    = aw_latched ? latched_awid    : s_axi_awid;
    wire [ADDR_WIDTH-1:0] eff_awaddr  = aw_latched ? latched_awaddr  : s_axi_awaddr;
    wire [7:0]            eff_awlen   = aw_latched ? latched_awlen   : s_axi_awlen;
    wire [2:0]            eff_awsize  = aw_latched ? latched_awsize  : s_axi_awsize;
    wire [1:0]            eff_awburst = aw_latched ? latched_awburst : s_axi_awburst;
    wire [DATA_WIDTH-1:0] eff_wdata   = w_latched  ? latched_wdata   : s_axi_wdata;
    wire                  eff_wlast   = w_latched  ? latched_wlast   : s_axi_wlast;

    // Effective read signals (latched or direct)
    wire [ID_WIDTH-1:0]   eff_arid    = ar_latched ? latched_arid    : s_axi_arid;
    wire [ADDR_WIDTH-1:0] eff_araddr  = ar_latched ? latched_araddr  : s_axi_araddr;
    wire [7:0]            eff_arlen   = ar_latched ? latched_arlen   : s_axi_arlen;
    wire [2:0]            eff_arsize  = ar_latched ? latched_arsize  : s_axi_arsize;
    wire [1:0]            eff_arburst = ar_latched ? latched_arburst : s_axi_arburst;
    wire [ARUSER_WIDTH-1:0] eff_aruser = ar_latched ? latched_aruser : s_axi_aruser;

    // Unsupported transaction detection
    // APB only supports 32-bit single-beat transfers (len == 0, size <= 2, burst != 2'b10)
    wire aw_unsupported = (eff_awlen != 8'h00) || (eff_awsize > 3'b010) || (eff_awburst == 2'b10);
    wire ar_unsupported = (eff_arlen != 8'h00) || (eff_arsize > 3'b010) || (eff_arburst == 2'b10);

    // ── Main Bridge FSM & Logic ───────────────────────────────────────────────
    always @(posedge clk) begin
        if (rst) begin
            state                  <= ST_IDLE;
            aw_latched             <= 1'b0;
            w_latched              <= 1'b0;
            ar_latched             <= 1'b0;
            last_service_was_write <= 1'b0;

            latched_awid           <= {ID_WIDTH{1'b0}};
            latched_awaddr         <= {ADDR_WIDTH{1'b0}};
            latched_awlen          <= 8'h00;
            latched_awsize         <= 3'b000;
            latched_awburst        <= 2'b00;
            latched_wdata          <= {DATA_WIDTH{1'b0}};
            latched_wstrb          <= {STRB_WIDTH{1'b0}};
            latched_wlast          <= 1'b0;

            latched_arid           <= {ID_WIDTH{1'b0}};
            latched_araddr         <= {ADDR_WIDTH{1'b0}};
            latched_arlen          <= 8'h00;
            latched_arsize         <= 3'b000;
            latched_arburst        <= 2'b00;
            latched_aruser         <= {ARUSER_WIDTH{1'b0}};

            // APB outputs
            m_apb_paddr            <= 32'h0000_0000;
            m_apb_pwdata           <= 32'h0000_0000;
            m_apb_pwrite           <= 1'b0;
            m_apb_psel             <= 1'b0;
            m_apb_penable          <= 1'b0;

            // AXI response outputs
            s_axi_bid              <= {ID_WIDTH{1'b0}};
            s_axi_bresp            <= RESP_OKAY;
            s_axi_buser            <= {BUSER_WIDTH{1'b0}};
            s_axi_bvalid           <= 1'b0;

            s_axi_rid              <= {ID_WIDTH{1'b0}};
            s_axi_rdata            <= {DATA_WIDTH{1'b0}};
            s_axi_rresp            <= RESP_OKAY;
            s_axi_rlast            <= 1'b0;
            s_axi_ruser            <= {RUSER_WIDTH{1'b0}};
            s_axi_rvalid           <= 1'b0;

        end else begin

            // ── Latch incoming AW if arrived alone ────────────────────────────
            if (s_axi_awvalid && s_axi_awready && !start_write) begin
                aw_latched      <= 1'b1;
                latched_awid    <= s_axi_awid;
                latched_awaddr  <= s_axi_awaddr;
                latched_awlen   <= s_axi_awlen;
                latched_awsize  <= s_axi_awsize;
                latched_awburst <= s_axi_awburst;
            end

            // ── Latch incoming W if arrived alone ─────────────────────────────
            if (s_axi_wvalid && s_axi_wready && (state != ST_DRAIN_WR) && !start_write) begin
                w_latched      <= 1'b1;
                latched_wdata  <= s_axi_wdata;
                latched_wstrb  <= s_axi_wstrb;
                latched_wlast  <= s_axi_wlast;
            end

            // ── Latch incoming AR if read request cannot start immediately ───
            if (s_axi_arvalid && s_axi_arready && !start_read) begin
                ar_latched      <= 1'b1;
                latched_arid    <= s_axi_arid;
                latched_araddr  <= s_axi_araddr;
                latched_arlen   <= s_axi_arlen;
                latched_arsize  <= s_axi_arsize;
                latched_arburst <= s_axi_arburst;
                latched_aruser  <= s_axi_aruser;
            end

            case (state)

                // ── IDLE: Arbitrate between Write and Read ────────────────────
                ST_IDLE: begin
                    m_apb_psel    <= 1'b0;
                    m_apb_penable <= 1'b0;

                    if (start_write) begin
                        aw_latched             <= 1'b0;
                        w_latched              <= 1'b0;
                        last_service_was_write <= 1'b1;

                        if (aw_unsupported) begin
                            // Reject unsupported burst without touching APB peripheral (zero side effects)
                            m_apb_psel    <= 1'b0;
                            m_apb_penable <= 1'b0;
                            m_apb_pwrite  <= 1'b0;

                            if (eff_wlast) begin
                                s_axi_bid    <= eff_awid;
                                s_axi_bresp  <= RESP_SLVERR;
                                s_axi_bvalid <= 1'b1;
                                state        <= ST_WR_RESP;
                            end else begin
                                // Drain remaining beats of unsupported burst
                                latched_awid <= eff_awid;
                                state        <= ST_DRAIN_WR;
                            end

                        end else begin
                            // Valid single-beat 32-bit write: enter APB SETUP phase
                            m_apb_psel    <= 1'b1;
                            m_apb_penable <= 1'b0;
                            m_apb_pwrite  <= 1'b1;
                            m_apb_paddr   <= eff_awaddr;
                            m_apb_pwdata  <= eff_wdata;

                            latched_awid  <= eff_awid;
                            latched_awlen <= eff_awlen;

                            state         <= ST_APB_SETUP_WR;
                        end

                    end else if (start_read) begin
                        ar_latched             <= 1'b0;
                        last_service_was_write <= 1'b0;

                        if (ar_unsupported) begin
                            // Reject unsupported burst without touching APB peripheral (zero side effects)
                            m_apb_psel    <= 1'b0;
                            m_apb_penable <= 1'b0;
                            m_apb_pwrite  <= 1'b0;

                            s_axi_rid     <= eff_arid;
                            s_axi_rdata   <= 32'h0000_0000;
                            s_axi_rresp   <= RESP_SLVERR;
                            s_axi_rlast   <= 1'b1;
                            s_axi_ruser   <= eff_aruser;
                            s_axi_rvalid  <= 1'b1;

                            state         <= ST_RD_RESP;

                        end else begin
                            // Valid single-beat 32-bit read: enter APB SETUP phase
                            m_apb_psel     <= 1'b1;
                            m_apb_penable  <= 1'b0;
                            m_apb_pwrite   <= 1'b0;
                            m_apb_paddr    <= eff_araddr;

                            latched_arid   <= eff_arid;
                            latched_arlen  <= eff_arlen;
                            latched_aruser <= eff_aruser;

                            state          <= ST_APB_SETUP_RD;
                        end
                    end
                end

                // ── Drain Remaining Write Beats for Unsupported Burst ─────────
                ST_DRAIN_WR: begin
                    m_apb_psel    <= 1'b0;
                    m_apb_penable <= 1'b0;
                    if (s_axi_wvalid && s_axi_wready) begin
                        if (s_axi_wlast) begin
                            s_axi_bid    <= latched_awid;
                            s_axi_bresp  <= RESP_SLVERR;
                            s_axi_bvalid <= 1'b1;
                            state        <= ST_WR_RESP;
                        end
                    end
                end

                // ── APB Write: SETUP Phase ───────────────────────────────────
                ST_APB_SETUP_WR: begin
                    // Move from SETUP to ACCESS phase: assert PENABLE
                    m_apb_penable <= 1'b1;
                    state         <= ST_APB_ACC_WR;
                end

                // ── APB Write: ACCESS Phase (wait for PREADY) ─────────────────
                ST_APB_ACC_WR: begin
                    if (m_apb_pready) begin
                        m_apb_psel    <= 1'b0;
                        m_apb_penable <= 1'b0;

                        s_axi_bid     <= latched_awid;
                        s_axi_bvalid  <= 1'b1;
                        s_axi_bresp   <= m_apb_pslverr ? RESP_SLVERR : RESP_OKAY;

                        state <= ST_WR_RESP;
                    end
                end

                // ── Write Response: Wait for BREADY ───────────────────────────
                ST_WR_RESP: begin
                    if (s_axi_bvalid && s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        state        <= ST_IDLE;
                    end
                end

                // ── APB Read: SETUP Phase ────────────────────────────────────
                ST_APB_SETUP_RD: begin
                    m_apb_penable <= 1'b1;
                    state         <= ST_APB_ACC_RD;
                end

                // ── APB Read: ACCESS Phase (wait for PREADY) ──────────────────
                ST_APB_ACC_RD: begin
                    if (m_apb_pready) begin
                        m_apb_psel    <= 1'b0;
                        m_apb_penable <= 1'b0;

                        s_axi_rid     <= latched_arid;
                        s_axi_rdata   <= m_apb_prdata;
                        s_axi_rlast   <= 1'b1;
                        s_axi_ruser   <= latched_aruser;
                        s_axi_rvalid  <= 1'b1;
                        s_axi_rresp   <= m_apb_pslverr ? RESP_SLVERR : RESP_OKAY;

                        state <= ST_RD_RESP;
                    end
                end

                // ── Read Response: Wait for RREADY ────────────────────────────
                ST_RD_RESP: begin
                    if (s_axi_rvalid && s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        state        <= ST_IDLE;
                    end
                end

                default: state <= ST_IDLE;

            endcase
        end
    end

endmodule

`default_nettype wire
