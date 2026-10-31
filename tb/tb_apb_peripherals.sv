`timescale 1ns/1ps
module tb_apb_peripherals;
    reg PCLK=0, PRESETn=0;
    always #5 PCLK = ~PCLK;

    reg [31:0] PADDR, PWDATA;
    reg PWRITE, PSEL, PENABLE;
    wire [31:0] PRDATA;
    wire PREADY, PSLVERR;
    reg [7:0] gpio_in=8'hA5;
    wire [7:0] gpio_out, gpio_dir;
    wire uart_irq, spi_irq, gpio_irq, timer_irq;
    wire [4:0] pic_irq_lines;

    apb_peripherals dut(
        .PCLK(PCLK), .PRESETn(PRESETn),
        .PADDR(PADDR), .PWDATA(PWDATA), .PWRITE(PWRITE),
        .PSEL(PSEL), .PENABLE(PENABLE), .PRDATA(PRDATA),
        .PREADY(PREADY), .PSLVERR(PSLVERR),
        .gpio_in(gpio_in), .gpio_out(gpio_out), .gpio_dir(gpio_dir),
        .uart_irq(uart_irq), .spi_irq(spi_irq), .gpio_irq(gpio_irq),
        .timer_irq(timer_irq), .pic_irq_lines(pic_irq_lines)
    );

    task apb_write(input [31:0] a, input [31:0] d);
        begin
            @(posedge PCLK); PADDR=a; PWDATA=d; PWRITE=1; PSEL=1; PENABLE=0;
            @(posedge PCLK); PENABLE=1;
            @(posedge PCLK); PSEL=0; PENABLE=0;
        end
    endtask
    task apb_read(input [31:0] a, output [31:0] d);
        begin
            @(posedge PCLK); PADDR=a; PWRITE=0; PSEL=1; PENABLE=0;
            @(posedge PCLK); PENABLE=1;
            @(posedge PCLK); d=PRDATA; PSEL=0; PENABLE=0;
        end
    endtask

    reg [31:0] r;
    initial begin
        #20 PRESETn=1;
        // GPIO
        apb_write(32'h200, 32'hFF); // dir
        apb_write(32'h204, 32'h3C); // out
        apb_read(32'h204, r); if (r[7:0]!=8'h3C) $fatal;
        apb_read(32'h208, r); if (r[7:0]!=8'hA5) $fatal;
        // Timer
        apb_write(32'h300, 32'd5); // load
        apb_write(32'h308, 32'h3); // ctrl enable+irq
        repeat(20) @(posedge PCLK);
        apb_read(32'h30C, r); // status
        // UART reg rw
        apb_write(32'h008, 32'h55); // txdata
        apb_read(32'h008, r); if (r!=32'h55) $fatal;
        // SPI
        apb_write(32'h108, 32'hAA);
        apb_read(32'h108, r); if (r!=32'hAA) $fatal;
        // PIC
        apb_write(32'h400, 32'h1F);
        apb_read(32'h400, r); if (r!=32'h1F) $fatal;
        $display("RESULT: TEST PASSED");
        $finish;
    end
endmodule