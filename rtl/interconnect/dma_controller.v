// =============================================================================
// DMA Controller — memory-to-memory, AXI4 manager on crossbar port s03
//
// Design constraints (verified against axi_interconnect_wrap_4x4.v):
//   DATA_WIDTH = 32, ADDR_WIDTH = 32, ID_WIDTH = 8
//   AWUSER_WIDTH = WUSER_WIDTH = BUSER_WIDTH = ARUSER_WIDTH = RUSER_WIDTH = 1
//   All *USER_ENABLE = 0  →  user signals ignored by crossbar; tied to 0 here
//   Reset: active-high rst (matches crossbar, axi_ram, boot_rom, soc_top)
//   Single-beat only: awlen=0, arlen=0, awsize=arsize=3'b010 (4 bytes)
//
// Configuration interface:
//   cfg_src_addr  — source byte address (word-aligned)
//   cfg_dst_addr  — destination byte address (word-aligned)
//   cfg_len       — number of 32-bit words to transfer [15:0]
//   cfg_start     — single-cycle pulse to start; ignored while BUSY
//
// Status outputs:
//   cfg_done      — held high after transfer completes; cleared on next start/rst
//   cfg_err       — held high if any AXI response != OKAY; cleared on next start/rst
//   dma_irq       — level IRQ, mirrors cfg_done | cfg_err; cleared on next start/rst
//
// State machine (7 states):
//   IDLE → RD_ADDR → RD_DATA → WR_ADDR → WR_DATA → WR_RESP → (IDLE or loop)
//                ↘ (rresp error)                 ↘ (bresp error)
//                                               ERR
// =============================================================================

`timescale 1ns / 1ps
`default_nettype none

module dma_controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 8
) (
    // ── Clock & Reset ─────────────────────────────────────────────────────────
    input  wire                    clk,
    input  wire                    rst,          // active-high (matches crossbar)

    // ── AXI4 Manager Interface → crossbar s03_axi_* ──────────────────────────
    // Write Address Channel
    output reg  [ID_WIDTH-1:0]     m_axi_awid,
    output reg  [ADDR_WIDTH-1:0]   m_axi_awaddr,
    output reg  [7:0]              m_axi_awlen,
    output reg  [2:0]              m_axi_awsize,
    output reg  [1:0]              m_axi_awburst,
    output reg                     m_axi_awlock,
    output reg  [3:0]              m_axi_awcache,
    output reg  [2:0]              m_axi_awprot,
    output reg  [3:0]              m_axi_awqos,
    output reg                     m_axi_awuser,
    output reg                     m_axi_awvalid,
    input  wire                    m_axi_awready,

    // Write Data Channel
    output reg  [DATA_WIDTH-1:0]   m_axi_wdata,
    output reg  [DATA_WIDTH/8-1:0] m_axi_wstrb,
    output reg                     m_axi_wlast,
    output reg                     m_axi_wuser,
    output reg                     m_axi_wvalid,
    input  wire                    m_axi_wready,

    // Write Response Channel
    input  wire [ID_WIDTH-1:0]     m_axi_bid,
    input  wire [1:0]              m_axi_bresp,
    input  wire                    m_axi_buser,
    input  wire                    m_axi_bvalid,
    output reg                     m_axi_bready,

    // Read Address Channel
    output reg  [ID_WIDTH-1:0]     m_axi_arid,
    output reg  [ADDR_WIDTH-1:0]   m_axi_araddr,
    output reg  [7:0]              m_axi_arlen,
    output reg  [2:0]              m_axi_arsize,
    output reg  [1:0]              m_axi_arburst,
    output reg                     m_axi_arlock,
    output reg  [3:0]              m_axi_arcache,
    output reg  [2:0]              m_axi_arprot,
    output reg  [3:0]              m_axi_arqos,
    output reg                     m_axi_aruser,
    output reg                     m_axi_arvalid,
    input  wire                    m_axi_arready,

    // Read Data Channel
    input  wire [ID_WIDTH-1:0]     m_axi_rid,
    input  wire [DATA_WIDTH-1:0]   m_axi_rdata,
    input  wire [1:0]              m_axi_rresp,
    input  wire                    m_axi_rlast,
    input  wire                    m_axi_ruser,
    input  wire                    m_axi_rvalid,
    output reg                     m_axi_rready,

    // ── Configuration Interface ───────────────────────────────────────────────
    input  wire [ADDR_WIDTH-1:0]   cfg_src_addr,
    input  wire [ADDR_WIDTH-1:0]   cfg_dst_addr,
    input  wire [15:0]             cfg_len,      // words to transfer (not bytes)
    input  wire                    cfg_start,    // single-cycle pulse

    // ── Status Outputs ────────────────────────────────────────────────────────
    output reg                     cfg_done,     // latched; cleared by rst or next start
    output reg                     cfg_err,      // latched; cleared by rst or next start
    output reg                     dma_irq       // level; mirrors cfg_done | cfg_err
);

    // ── FSM state encoding ────────────────────────────────────────────────────
    localparam [2:0]
        ST_IDLE    = 3'd0,
        ST_RD_ADDR = 3'd1,
        ST_RD_DATA = 3'd2,
        ST_WR_ADDR = 3'd3,
        ST_WR_DATA = 3'd4,
        ST_WR_RESP = 3'd5,
        ST_ERR     = 3'd6;

    // ── AXI fixed values for single-beat 32-bit transfers ─────────────────────
    localparam [7:0]  AXI_LEN   = 8'h00;       // single beat
    localparam [2:0]  AXI_SIZE  = 3'b010;       // 4 bytes
    localparam [1:0]  AXI_BURST = 2'b01;        // INCR
    localparam [7:0]  DMA_ID    = 8'h01;        // fixed AXI ID for DMA
    localparam [1:0]  AXI_OKAY  = 2'b00;

    // ── Internal registers ────────────────────────────────────────────────────
    reg  [2:0]           state;
    reg  [ADDR_WIDTH-1:0] src_ptr;
    reg  [ADDR_WIDTH-1:0] dst_ptr;
    reg  [15:0]           word_cnt;
    reg  [DATA_WIDTH-1:0] data_buf;

    // ── FSM ───────────────────────────────────────────────────────────────────
    always @(posedge clk) begin
        if (rst) begin
            state           <= ST_IDLE;
            src_ptr         <= {ADDR_WIDTH{1'b0}};
            dst_ptr         <= {ADDR_WIDTH{1'b0}};
            word_cnt        <= 16'h0;
            data_buf        <= {DATA_WIDTH{1'b0}};

            // AXI outputs — all deasserted
            m_axi_awid      <= {ID_WIDTH{1'b0}};
            m_axi_awaddr    <= {ADDR_WIDTH{1'b0}};
            m_axi_awlen     <= 8'h00;
            m_axi_awsize    <= 3'b000;
            m_axi_awburst   <= 2'b00;
            m_axi_awlock    <= 1'b0;
            m_axi_awcache   <= 4'h0;
            m_axi_awprot    <= 3'b000;
            m_axi_awqos     <= 4'h0;
            m_axi_awuser    <= 1'b0;
            m_axi_awvalid   <= 1'b0;

            m_axi_wdata     <= {DATA_WIDTH{1'b0}};
            m_axi_wstrb     <= {(DATA_WIDTH/8){1'b0}};
            m_axi_wlast     <= 1'b0;
            m_axi_wuser     <= 1'b0;
            m_axi_wvalid    <= 1'b0;

            m_axi_bready    <= 1'b0;

            m_axi_arid      <= {ID_WIDTH{1'b0}};
            m_axi_araddr    <= {ADDR_WIDTH{1'b0}};
            m_axi_arlen     <= 8'h00;
            m_axi_arsize    <= 3'b000;
            m_axi_arburst   <= 2'b00;
            m_axi_arlock    <= 1'b0;
            m_axi_arcache   <= 4'h0;
            m_axi_arprot    <= 3'b000;
            m_axi_arqos     <= 4'h0;
            m_axi_aruser    <= 1'b0;
            m_axi_arvalid   <= 1'b0;

            m_axi_rready    <= 1'b0;

            // Status
            cfg_done        <= 1'b0;
            cfg_err         <= 1'b0;
            dma_irq         <= 1'b0;

        end else begin
            case (state)

                // ── IDLE ──────────────────────────────────────────────────────
                ST_IDLE: begin
                    if (cfg_start) begin
                        // Accept new transfer; clear previous status
                        cfg_done  <= 1'b0;
                        cfg_err   <= 1'b0;
                        dma_irq   <= 1'b0;

                        if (cfg_len == 16'h0) begin
                            // Zero length requested; complete immediately
                            cfg_done <= 1'b1;
                            dma_irq  <= 1'b1;
                            state    <= ST_IDLE;
                        end else begin
                            // Snapshot configuration
                            src_ptr   <= cfg_src_addr;
                            dst_ptr   <= cfg_dst_addr;
                            word_cnt  <= cfg_len;

                            // Issue first read address immediately
                            m_axi_arid    <= DMA_ID;
                            m_axi_araddr  <= cfg_src_addr;
                            m_axi_arlen   <= AXI_LEN;
                            m_axi_arsize  <= AXI_SIZE;
                            m_axi_arburst <= AXI_BURST;
                            m_axi_arlock  <= 1'b0;
                            m_axi_arcache <= 4'h0;
                            m_axi_arprot  <= 3'b000;
                            m_axi_arqos   <= 4'h0;
                            m_axi_aruser  <= 1'b0;
                            m_axi_arvalid <= 1'b1;

                            state <= ST_RD_ADDR;
                        end
                    end
                end

                // ── RD_ADDR: wait for arready ─────────────────────────────────
                ST_RD_ADDR: begin
                    if (m_axi_arready) begin
                        m_axi_arvalid <= 1'b0;
                        m_axi_rready  <= 1'b1;
                        state         <= ST_RD_DATA;
                    end
                end

                // ── RD_DATA: wait for rvalid; latch data ──────────────────────
                ST_RD_DATA: begin
                    if (m_axi_rvalid) begin
                        m_axi_rready <= 1'b0;
                        if (m_axi_rresp != AXI_OKAY) begin
                            cfg_err <= 1'b1;
                            dma_irq <= 1'b1;
                            state   <= ST_ERR;
                        end else begin
                            // Latch read data; set up write address
                            data_buf      <= m_axi_rdata;

                            m_axi_awid    <= DMA_ID;
                            m_axi_awaddr  <= dst_ptr;
                            m_axi_awlen   <= AXI_LEN;
                            m_axi_awsize  <= AXI_SIZE;
                            m_axi_awburst <= AXI_BURST;
                            m_axi_awlock  <= 1'b0;
                            m_axi_awcache <= 4'h0;
                            m_axi_awprot  <= 3'b000;
                            m_axi_awqos   <= 4'h0;
                            m_axi_awuser  <= 1'b0;
                            m_axi_awvalid <= 1'b1;

                            state <= ST_WR_ADDR;
                        end
                    end
                end

                // ── WR_ADDR: wait for awready ─────────────────────────────────
                ST_WR_ADDR: begin
                    if (m_axi_awready) begin
                        m_axi_awvalid <= 1'b0;

                        // Present write data
                        m_axi_wdata  <= data_buf;
                        m_axi_wstrb  <= {(DATA_WIDTH/8){1'b1}};  // all byte lanes
                        m_axi_wlast  <= 1'b1;                      // single beat
                        m_axi_wuser  <= 1'b0;
                        m_axi_wvalid <= 1'b1;

                        state <= ST_WR_DATA;
                    end
                end

                // ── WR_DATA: wait for wready ──────────────────────────────────
                ST_WR_DATA: begin
                    if (m_axi_wready) begin
                        m_axi_wvalid <= 1'b0;
                        m_axi_wlast  <= 1'b0;
                        m_axi_bready <= 1'b1;
                        state        <= ST_WR_RESP;
                    end
                end

                // ── WR_RESP: wait for bvalid ──────────────────────────────────
                ST_WR_RESP: begin
                    if (m_axi_bvalid) begin
                        m_axi_bready <= 1'b0;

                        if (m_axi_bresp != AXI_OKAY) begin
                            cfg_err <= 1'b1;
                            dma_irq <= 1'b1;
                            state   <= ST_ERR;
                        end else begin
                            // Advance pointers
                            src_ptr  <= src_ptr + {{(ADDR_WIDTH-3){1'b0}}, 3'd4};
                            dst_ptr  <= dst_ptr + {{(ADDR_WIDTH-3){1'b0}}, 3'd4};
                            word_cnt <= word_cnt - 16'h1;

                            if (word_cnt == 16'h1) begin
                                // Last word done
                                cfg_done <= 1'b1;
                                dma_irq  <= 1'b1;
                                state    <= ST_IDLE;
                            end else begin
                                // Next read: updated src_ptr takes one extra cycle
                                // to be registered, so we use (src_ptr + 4) directly
                                m_axi_arid    <= DMA_ID;
                                m_axi_araddr  <= src_ptr + {{(ADDR_WIDTH-3){1'b0}}, 3'd4};
                                m_axi_arlen   <= AXI_LEN;
                                m_axi_arsize  <= AXI_SIZE;
                                m_axi_arburst <= AXI_BURST;
                                m_axi_arlock  <= 1'b0;
                                m_axi_arcache <= 4'h0;
                                m_axi_arprot  <= 3'b000;
                                m_axi_arqos   <= 4'h0;
                                m_axi_aruser  <= 1'b0;
                                m_axi_arvalid <= 1'b1;

                                state <= ST_RD_ADDR;
                            end
                        end
                    end
                end

                // ── ERR: hold until next cfg_start ────────────────────────────
                ST_ERR: begin
                    // cfg_err and dma_irq remain asserted.
                    // A new cfg_start clears status and starts a new transfer.
                    if (cfg_start) begin
                        cfg_err  <= 1'b0;
                        dma_irq  <= 1'b0;
                        cfg_done <= 1'b0;

                        if (cfg_len == 16'h0) begin
                            cfg_done <= 1'b1;
                            dma_irq  <= 1'b1;
                            state    <= ST_IDLE;
                        end else begin
                            src_ptr  <= cfg_src_addr;
                            dst_ptr  <= cfg_dst_addr;
                            word_cnt <= cfg_len;

                            m_axi_arid    <= DMA_ID;
                            m_axi_araddr  <= cfg_src_addr;
                            m_axi_arlen   <= AXI_LEN;
                            m_axi_arsize  <= AXI_SIZE;
                            m_axi_arburst <= AXI_BURST;
                            m_axi_arlock  <= 1'b0;
                            m_axi_arcache <= 4'h0;
                            m_axi_arprot  <= 3'b000;
                            m_axi_arqos   <= 4'h0;
                            m_axi_aruser  <= 1'b0;
                            m_axi_arvalid <= 1'b1;

                            state <= ST_RD_ADDR;
                        end
                    end
                end

                default: state <= ST_IDLE;

            endcase
        end
    end

endmodule

`default_nettype wire
