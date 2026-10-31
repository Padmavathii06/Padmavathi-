`timescale 1ns / 1ps
module tb_cru_reset;
    reg clk_in = 0;
    reg rst_l = 0;
    wire clk, rst, rst_n, por_done;
    always #5 clk_in = ~clk_in;

    cru #(.RESET_CYCLES(4)) u_cru (.clk_in(clk_in), .rst_l(rst_l), .clk(clk), .rst(rst), .rst_n(rst_n), .por_done(por_done));

    initial begin
        #20 rst_l = 1;
        #100;
        if (!por_done) $fatal(1, "por_done not asserted");
        $display("PASS cru reset sequence");
        $finish;
    end
endmodule
