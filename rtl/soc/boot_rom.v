// Boot ROM mapped on interconnect master port m01.
// Read-only memory holding startup firmware. Write transactions are accepted
// and completed with SLVERR so that an AXI master cannot deadlock the fabric.
`timescale 1ns / 1ps
`default_nettype none

module boot_rom #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter MEM_WORDS  = 256,
    parameter INIT_FILE  = ""
) (
    input  wire                   clk,
    input  wire                   rst,

    // Write address
    input  wire [7:0]             s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  wire [7:0]             s_axi_awlen,
    input  wire [2:0]             s_axi_awsize,
    input  wire [1:0]             s_axi_awburst,
    input  wire                   s_axi_awlock,
    input  wire [3:0]             s_axi_awcache,
    input  wire [2:0]             s_axi_awprot,
    input  wire [3:0]             s_axi_awqos,
    input  wire [3:0]             s_axi_awregion,
    input  wire                   s_axi_awuser,
    input  wire                   s_axi_awvalid,
    output wire                   s_axi_awready,

    // Write data
    input  wire [DATA_WIDTH-1:0]   s_axi_wdata,
    input  wire [DATA_WIDTH/8-1:0] s_axi_wstrb,
    input  wire                   s_axi_wlast,
    input  wire                   s_axi_wuser,
    input  wire                   s_axi_wvalid,
    output wire                   s_axi_wready,

    // Write response
    output reg  [7:0]             s_axi_bid,
    output reg  [1:0]             s_axi_bresp,
    output reg                    s_axi_buser,
    output reg                    s_axi_bvalid,
    input  wire                   s_axi_bready,

    // Read address
    input  wire [7:0]             s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]   s_axi_araddr,
    input  wire [7:0]             s_axi_arlen,
    input  wire [2:0]             s_axi_arsize,
    input  wire [1:0]             s_axi_arburst,
    input  wire                   s_axi_arlock,
    input  wire [3:0]             s_axi_arcache,
    input  wire [2:0]             s_axi_arprot,
    input  wire [3:0]             s_axi_arqos,
    input  wire [3:0]             s_axi_arregion,
    input  wire                   s_axi_aruser,
    input  wire                   s_axi_arvalid,
    output wire                   s_axi_arready,

    // Read data
    output reg  [7:0]             s_axi_rid,
    output reg  [DATA_WIDTH-1:0]   s_axi_rdata,
    output reg  [1:0]             s_axi_rresp,
    output reg                    s_axi_rlast,
    output reg                    s_axi_ruser,
    output reg                    s_axi_rvalid,
    input  wire                   s_axi_rready
);
    reg [DATA_WIDTH-1:0] mem [0:MEM_WORDS-1];

    integer i;
    initial begin
        for (i = 0; i < MEM_WORDS; i = i + 1) mem[i] = 32'h00000013; // nop
        if (INIT_FILE != "") $readmemh(INIT_FILE, mem);
    end

    // Write side (SLVERR)
    reg aw_done, w_done;
    reg [ADDR_WIDTH-1:0] aw_addr;
    reg [7:0]            aw_id;
    assign s_axi_awready = !aw_done && !s_axi_bvalid;
    assign s_axi_wready  = !w_done  && !s_axi_bvalid;

    // Read side
    assign s_axi_arready = !s_axi_rvalid;

    always @(posedge clk) begin
        if (rst) begin
            aw_done      <= 1'b0;
            w_done       <= 1'b0;
            aw_addr      <= {ADDR_WIDTH{1'b0}};
            aw_id        <= 8'd0;
            s_axi_bvalid <= 1'b0;
            s_axi_bid    <= 8'd0;
            s_axi_bresp  <= 2'b00;
            s_axi_buser  <= 1'b0;

            s_axi_rvalid <= 1'b0;
            s_axi_rid    <= 8'd0;
            s_axi_rdata  <= {DATA_WIDTH{1'b0}};
            s_axi_rresp  <= 2'b00;
            s_axi_rlast  <= 1'b0;
            s_axi_ruser  <= 1'b0;
        end else begin
            if (s_axi_awvalid && s_axi_awready) begin
                aw_done <= 1'b1;
                aw_addr <= s_axi_awaddr;
                aw_id   <= s_axi_awid;
            end
            if (s_axi_wvalid && s_axi_wready) begin
                w_done <= 1'b1;
            end
            if (aw_done && w_done && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bid    <= aw_id;
                s_axi_bresp  <= 2'b10; // SLVERR: read-only
                s_axi_buser  <= 1'b0;
                aw_done      <= 1'b0;
                w_done       <= 1'b0;
            end
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end

            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rid    <= s_axi_arid;
                s_axi_rdata  <= mem[(s_axi_araddr >> 2) % MEM_WORDS];
                s_axi_rresp  <= 2'b00;
                s_axi_rlast  <= 1'b1;
                s_axi_rvalid <= 1'b1;
                s_axi_ruser  <= s_axi_aruser;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
`default_nettype wire