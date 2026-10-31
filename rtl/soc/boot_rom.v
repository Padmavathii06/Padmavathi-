// Boot ROM mapped on interconnect master port m01.
// Read-only memory holding startup firmware.
`timescale 1ns / 1ps

module boot_rom #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter MEM_WORDS  = 256,
    parameter INIT_FILE  = ""
) (
    input  wire                   clk,
    input  wire                   rst,

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
    output reg                    s_axi_arready,

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

    wire [ADDR_WIDTH-1:0] word_addr = s_axi_araddr >> 2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= 0;
            s_axi_rid     <= 0;
            s_axi_rresp   <= 0;
            s_axi_rlast   <= 0;
            s_axi_ruser   <= 0;
        end else begin
            s_axi_arready <= s_axi_arvalid;
            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rid    <= s_axi_arid;
                s_axi_rdata  <= mem[word_addr % MEM_WORDS];
                s_axi_rresp  <= 2'b00;
                s_axi_rlast  <= 1'b1;
                s_axi_rvalid <= 1'b1;
                s_axi_ruser  <= s_axi_aruser;
            end else if (s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end
endmodule
