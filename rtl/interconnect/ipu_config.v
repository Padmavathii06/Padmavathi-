// =============================================================================
// IPU Configuration Register Block — AXI4 Subordinate
//
// Mapped at: 0x2000_0000 - 0x2000_0FFF (4 KiB address aperture, port m02)
// Language: Verilog 2001 (synthesizable)
//
// Register Map (word-aligned offsets):
//   0x00: IPU_CTRL         (R/W) [0]=start, [1]=stop, [2]=soft_reset, [5:4]=mode
//   0x04: IPU_STATUS       (RO)  [0]=busy, [1]=done, [2]=err, [3]=fifo_of, [4]=fifo_uf
//   0x08: IPU_FRAME_WIDTH  (R/W) Image width in pixels
//   0x0C: IPU_FRAME_HEIGHT (R/W) Image height in lines
//   0x10: IPU_SRC_ADDR     (R/W) Source buffer base address in SRAM
//   0x14: IPU_DST_ADDR     (R/W) Destination buffer base address in SRAM
//   0x18: IPU_IRQ_MASK     (R/W) [0]=done_ie, [1]=err_ie
//   0x1C: IPU_IRQ_STATUS   (W1C) [0]=done_irq, [1]=err_irq (Write-1-to-Clear)
//   0x20 .. 0x40:
//         IPU_KERNEL_COEFF[0..8] (R/W) 9x 32-bit 3x3 convolution coefficients
// =============================================================================

`timescale 1ns / 1ps
`default_nettype none

module ipu_config #(
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

    // ── AXI4 Slave Write Address Channel ──────────────────────────────────────
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

    // ── AXI4 Slave Write Data Channel ─────────────────────────────────────────
    input  wire [DATA_WIDTH-1:0]   s_axi_wdata,
    input  wire [STRB_WIDTH-1:0]   s_axi_wstrb,
    input  wire                    s_axi_wlast,
    input  wire [WUSER_WIDTH-1:0]  s_axi_wuser,
    input  wire                    s_axi_wvalid,
    output wire                    s_axi_wready,

    // ── AXI4 Slave Write Response Channel ─────────────────────────────────────
    output reg  [ID_WIDTH-1:0]     s_axi_bid,
    output reg  [1:0]              s_axi_bresp,
    output reg  [BUSER_WIDTH-1:0]  s_axi_buser,
    output reg                     s_axi_bvalid,
    input  wire                    s_axi_bready,

    // ── AXI4 Slave Read Address Channel ───────────────────────────────────────
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

    // ── AXI4 Slave Read Data Channel ──────────────────────────────────────────
    output reg  [ID_WIDTH-1:0]     s_axi_rid,
    output reg  [DATA_WIDTH-1:0]   s_axi_rdata,
    output reg  [1:0]              s_axi_rresp,
    output reg                     s_axi_rlast,
    output reg  [RUSER_WIDTH-1:0]  s_axi_ruser,
    output reg                     s_axi_rvalid,
    input  wire                    s_axi_rready,

    // ── Interrupt Outputs ─────────────────────────────────────────────────────
    output wire                    ipu_done_irq,
    output wire                    ipu_err_irq
);

    // ── AXI Response Codes ────────────────────────────────────────────────────
    localparam [1:0]
        RESP_OKAY   = 2'b00,
        RESP_SLVERR = 2'b10;

    // ── Register Offsets (Word-aligned, lower 12 bits) ─────────────────────────
    localparam [11:0]
        ADDR_IPU_CTRL         = 12'h000,
        ADDR_IPU_STATUS       = 12'h004,
        ADDR_IPU_FRAME_WIDTH  = 12'h008,
        ADDR_IPU_FRAME_HEIGHT = 12'h00C,
        ADDR_IPU_SRC_ADDR     = 12'h010,
        ADDR_IPU_DST_ADDR     = 12'h014,
        ADDR_IPU_IRQ_MASK     = 12'h018,
        ADDR_IPU_IRQ_STATUS   = 12'h01C,
        ADDR_IPU_KERNEL_0     = 12'h020,
        ADDR_IPU_KERNEL_8     = 12'h040;

    // ── Internal Registers ────────────────────────────────────────────────────
    reg [31:0] reg_ctrl;
    reg [31:0] reg_status;
    reg [31:0] reg_frame_width;
    reg [31:0] reg_frame_height;
    reg [31:0] reg_src_addr;
    reg [31:0] reg_dst_addr;
    reg [31:0] reg_irq_mask;
    reg [31:0] reg_irq_status;
    reg [31:0] reg_kernel_coeff [0:8];

    // ── Handshake Tracking Registers ──────────────────────────────────────────
    reg                  aw_done;
    reg                  w_done;
    reg [ID_WIDTH-1:0]   aw_id_latched;
    reg [ADDR_WIDTH-1:0] aw_addr_latched;
    reg [DATA_WIDTH-1:0] w_data_latched;
    reg [STRB_WIDTH-1:0] w_strb_latched;

    // Ready handshake rules:
    // - Ready to accept address when not already holding one and not waiting for B handshake
    // - Ready to accept data when not already holding data and not waiting for B handshake
    // - Ready to accept read address when not actively holding an unacknowledged read beat
    assign s_axi_awready = (!aw_done) && (!s_axi_bvalid);
    assign s_axi_wready  = (!w_done)  && (!s_axi_bvalid);
    assign s_axi_arready = (!s_axi_rvalid);

    // Effective write signals: either already latched from earlier cycle or arriving now
    wire effective_aw_valid = aw_done || (s_axi_awvalid && s_axi_awready);
    wire effective_w_valid  = w_done  || (s_axi_wvalid && s_axi_wready);

    wire [ID_WIDTH-1:0]   effective_aw_id   = aw_done ? aw_id_latched   : s_axi_awid;
    wire [ADDR_WIDTH-1:0] effective_aw_addr = aw_done ? aw_addr_latched : s_axi_awaddr;
    wire [DATA_WIDTH-1:0] effective_w_data  = w_done  ? w_data_latched  : s_axi_wdata;
    wire [STRB_WIDTH-1:0] effective_w_strb  = w_done  ? w_strb_latched  : s_axi_wstrb;

    // ── Address Offset Decoder Helper ─────────────────────────────────────────
    wire [11:0] wr_offset = effective_aw_addr[11:0];
    wire [11:0] rd_offset = s_axi_araddr[11:0];

    // Check if write address is within valid register range
    wire wr_addr_valid = (wr_offset <= ADDR_IPU_KERNEL_8) && (wr_offset[1:0] == 2'b00);

    // Helper task to apply byte enables
    function [31:0] apply_wstrb;
        input [31:0] current_val;
        input [31:0] new_val;
        input [3:0]  strb;
        begin
            apply_wstrb[7:0]   = strb[0] ? new_val[7:0]   : current_val[7:0];
            apply_wstrb[15:8]  = strb[1] ? new_val[15:8]  : current_val[15:8];
            apply_wstrb[23:16] = strb[2] ? new_val[23:16] : current_val[23:16];
            apply_wstrb[31:24] = strb[3] ? new_val[31:24] : current_val[31:24];
        end
    endfunction

    // ── Interrupt Generation ──────────────────────────────────────────────────
    assign ipu_done_irq = reg_irq_status[0] & reg_irq_mask[0];
    assign ipu_err_irq  = reg_irq_status[1] & reg_irq_mask[1];

    // ── Write Channel Synchronous Logic ───────────────────────────────────────
    integer ki;
    always @(posedge clk) begin
        if (rst) begin
            aw_done         <= 1'b0;
            w_done          <= 1'b0;
            aw_id_latched   <= {ID_WIDTH{1'b0}};
            aw_addr_latched <= {ADDR_WIDTH{1'b0}};
            w_data_latched  <= {DATA_WIDTH{1'b0}};
            w_strb_latched  <= {STRB_WIDTH{1'b0}};

            s_axi_bvalid    <= 1'b0;
            s_axi_bid       <= {ID_WIDTH{1'b0}};
            s_axi_bresp     <= RESP_OKAY;
            s_axi_buser     <= {BUSER_WIDTH{1'b0}};

            // Register defaults
            reg_ctrl         <= 32'h0000_0000;
            reg_status       <= 32'h0000_0000;
            reg_frame_width  <= 32'h0000_0040; // Default: 64 pixels
            reg_frame_height <= 32'h0000_0040; // Default: 64 lines
            reg_src_addr     <= 32'h0000_0000;
            reg_dst_addr     <= 32'h0000_0000;
            reg_irq_mask     <= 32'h0000_0000;
            reg_irq_status   <= 32'h0000_0000;

            for (ki = 0; ki < 9; ki = ki + 1) begin
                reg_kernel_coeff[ki] <= 32'h0000_0000;
            end

        end else begin
            // ── Latch Address if arrived alone ────────────────────────────────
            if (s_axi_awvalid && s_axi_awready && !effective_w_valid) begin
                aw_done         <= 1'b1;
                aw_id_latched   <= s_axi_awid;
                aw_addr_latched <= s_axi_awaddr;
            end

            // ── Latch Data if arrived alone ───────────────────────────────────
            if (s_axi_wvalid && s_axi_wready && !effective_aw_valid) begin
                w_done         <= 1'b1;
                w_data_latched <= s_axi_wdata;
                w_strb_latched <= s_axi_wstrb;
            end

            // ── Commit Write when both Address and Data are present ───────────
            if (effective_aw_valid && effective_w_valid && !s_axi_bvalid) begin
                aw_done <= 1'b0;
                w_done  <= 1'b0;

                s_axi_bid    <= effective_aw_id;
                s_axi_buser  <= {BUSER_WIDTH{1'b0}};
                s_axi_bvalid <= 1'b1;

                if (!wr_addr_valid) begin
                    // Out-of-bounds register address within 4KB aperture
                    s_axi_bresp <= RESP_SLVERR;
                end else begin
                    s_axi_bresp <= RESP_OKAY;

                    case (wr_offset)
                        ADDR_IPU_CTRL: begin
                            reg_ctrl <= apply_wstrb(reg_ctrl, effective_w_data, effective_w_strb);
                            // Soft-reset bit requested: clear registers
                            if (effective_w_strb[0] && effective_w_data[2]) begin
                                reg_ctrl         <= 32'h0000_0000;
                                reg_status       <= 32'h0000_0000;
                                reg_src_addr     <= 32'h0000_0000;
                                reg_dst_addr     <= 32'h0000_0000;
                                reg_irq_status   <= 32'h0000_0000;
                            end
                            // Start bit pulse: set busy, clear done/error
                            else if (effective_w_strb[0] && effective_w_data[0]) begin
                                reg_status[0] <= 1'b1; // busy
                                reg_status[1] <= 1'b0; // done
                                reg_status[2] <= 1'b0; // error
                            end
                            // Stop bit pulse: clear busy
                            else if (effective_w_strb[0] && effective_w_data[1]) begin
                                reg_status[0] <= 1'b0; // busy
                            end
                        end

                        ADDR_IPU_STATUS: begin
                            // Read-only status register: software writes ignored
                        end

                        ADDR_IPU_FRAME_WIDTH: begin
                            reg_frame_width <= apply_wstrb(reg_frame_width, effective_w_data, effective_w_strb);
                        end

                        ADDR_IPU_FRAME_HEIGHT: begin
                            reg_frame_height <= apply_wstrb(reg_frame_height, effective_w_data, effective_w_strb);
                        end

                        ADDR_IPU_SRC_ADDR: begin
                            reg_src_addr <= apply_wstrb(reg_src_addr, effective_w_data, effective_w_strb);
                        end

                        ADDR_IPU_DST_ADDR: begin
                            reg_dst_addr <= apply_wstrb(reg_dst_addr, effective_w_data, effective_w_strb);
                        end

                        ADDR_IPU_IRQ_MASK: begin
                            reg_irq_mask <= apply_wstrb(reg_irq_mask, effective_w_data, effective_w_strb);
                        end

                        ADDR_IPU_IRQ_STATUS: begin
                            // Write-1-to-Clear (W1C)
                            if (effective_w_strb[0]) begin
                                if (effective_w_data[0]) reg_irq_status[0] <= 1'b0;
                                if (effective_w_data[1]) reg_irq_status[1] <= 1'b0;
                            end
                        end

                        default: begin
                            // Kernel coefficients: 0x20 .. 0x40
                            if (wr_offset >= ADDR_IPU_KERNEL_0 && wr_offset <= ADDR_IPU_KERNEL_8) begin
                                reg_kernel_coeff[(wr_offset - ADDR_IPU_KERNEL_0) >> 2] <=
                                    apply_wstrb(reg_kernel_coeff[(wr_offset - ADDR_IPU_KERNEL_0) >> 2],
                                                effective_w_data, effective_w_strb);
                            end
                        end
                    endcase
                end
            end

            // ── Clear Write Response on B Handshake ───────────────────────────
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // ── Read Channel Synchronous Logic ────────────────────────────────────────
    wire rd_addr_valid = (rd_offset <= ADDR_IPU_KERNEL_8) && (rd_offset[1:0] == 2'b00);

    always @(posedge clk) begin
        if (rst) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rdata  <= {DATA_WIDTH{1'b0}};
            s_axi_rresp  <= RESP_OKAY;
            s_axi_rid    <= {ID_WIDTH{1'b0}};
            s_axi_rlast  <= 1'b0;
            s_axi_ruser  <= {RUSER_WIDTH{1'b0}};
        end else begin
            // ── Accept Read Address & Output Registered Read Data ─────────────
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rid    <= s_axi_arid;
                s_axi_rlast  <= 1'b1; // Single-beat read response
                s_axi_ruser  <= s_axi_aruser;

                if (!rd_addr_valid) begin
                    s_axi_rresp <= RESP_SLVERR;
                    s_axi_rdata <= 32'hDEAD_0001; // Diagnostic decode fault word
                end else begin
                    s_axi_rresp <= RESP_OKAY;

                    case (rd_offset)
                        ADDR_IPU_CTRL:         s_axi_rdata <= reg_ctrl;
                        ADDR_IPU_STATUS:       s_axi_rdata <= reg_status;
                        ADDR_IPU_FRAME_WIDTH:  s_axi_rdata <= reg_frame_width;
                        ADDR_IPU_FRAME_HEIGHT: s_axi_rdata <= reg_frame_height;
                        ADDR_IPU_SRC_ADDR:     s_axi_rdata <= reg_src_addr;
                        ADDR_IPU_DST_ADDR:     s_axi_rdata <= reg_dst_addr;
                        ADDR_IPU_IRQ_MASK:     s_axi_rdata <= reg_irq_mask;
                        ADDR_IPU_IRQ_STATUS:   s_axi_rdata <= reg_irq_status;
                        default: begin
                            if (rd_offset >= ADDR_IPU_KERNEL_0 && rd_offset <= ADDR_IPU_KERNEL_8) begin
                                s_axi_rdata <= reg_kernel_coeff[(rd_offset - ADDR_IPU_KERNEL_0) >> 2];
                            end else begin
                                s_axi_rdata <= 32'h0000_0000;
                            end
                        end
                    endcase
                end
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule

`default_nettype wire
