`timescale 1ns/1ps
// AHB-to-APB bridge (single APB slave port, multiple APB peripherals).
// Maps AHB transactions into APB transfers. Peripherals are selected by
// address bits [15:12]. Supports 32-bit read/write.

module ahb_apb_bridge (
    input  wire        HCLK,
    input  wire        HRESETn,
    // AHB slave interface
    input  wire [31:0] HADDR,
    input  wire [31:0] HWDATA,
    input  wire        HWRITE,
    input  wire [2:0]  HSIZE,
    input  wire [1:0]  HTRANS,
    input  wire        HSEL,
    input  wire        HREADYin,
    output reg  [31:0] HRDATA,
    output reg         HREADYout,
    output reg  [1:0]  HRESP,
    // APB master interface
    output reg  [31:0] PADDR,
    output reg  [31:0] PWDATA,
    output reg         PWRITE,
    output reg         PSEL,
    output reg         PENABLE,
    input  wire [31:0] PRDATA,
    input  wire        PREADY,
    input  wire        PSLVERR
);

    localparam IDLE   = 2'b00;
    localparam SETUP  = 2'b01;
    localparam ACCESS = 2'b10;

    reg [1:0] state;
    reg [31:0] addr_latch;
    reg        write_latch;
    reg [31:0] wdata_latch;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            state <= IDLE;
            PSEL <= 0; PENABLE <= 0; PWRITE <= 0;
            PADDR <= 0; PWDATA <= 0;
            HREADYout <= 1; HRESP <= 2'b00; HRDATA <= 0;
            addr_latch <= 0; write_latch <= 0; wdata_latch <= 0;
        end else begin
            case (state)
                IDLE: begin
                    PSEL <= 0; PENABLE <= 0; HREADYout <= 1; HRESP <= 2'b00;
                    if (HSEL && HREADYin && HTRANS[1]) begin
                        addr_latch  <= HADDR;
                        write_latch <= HWRITE;
                        wdata_latch <= HWDATA;
                        state <= SETUP;
                        HREADYout <= 0;
                    end
                end
                SETUP: begin
                    PADDR   <= addr_latch;
                    PWDATA  <= wdata_latch;
                    PWRITE  <= write_latch;
                    PSEL    <= 1;
                    PENABLE <= 0;
                    state   <= ACCESS;
                end
                ACCESS: begin
                    PENABLE <= 1;
                    if (PREADY) begin
                        if (!write_latch) HRDATA <= PRDATA;
                        HRESP <= PSLVERR ? 2'b01 : 2'b00;
                        HREADYout <= 1;
                        PSEL <= 0; PENABLE <= 0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule