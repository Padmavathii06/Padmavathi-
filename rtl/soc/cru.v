// Clock & Reset Unit (CRU).
// Generates the system clock and handles active-low rst_l sequencing
// into active-high reset domains.
`timescale 1ns / 1ps

module cru #(
    parameter RESET_CYCLES = 8
) (
    input  wire  clk_in,
    input  wire  rst_l,        // active-low async reset in
    output wire  clk,          // system clock
    output reg   rst,          // active-high reset, sequenced
    output reg   rst_n,        // active-low reset, sequenced
    output reg   por_done      // power-on reset complete
);
    assign clk = clk_in;

    reg [$clog2(RESET_CYCLES+1)-1:0] cnt;
    always @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            cnt     <= 0;
            rst     <= 1'b1;
            rst_n   <= 1'b0;
            por_done<= 1'b0;
        end else begin
            if (cnt < RESET_CYCLES) begin
                cnt <= cnt + 1;
                rst <= 1'b1;
                rst_n <= 1'b0;
                por_done <= 1'b0;
            end else begin
                rst <= 1'b0;
                rst_n <= 1'b1;
                por_done <= 1'b1;
            end
        end
    end
endmodule
