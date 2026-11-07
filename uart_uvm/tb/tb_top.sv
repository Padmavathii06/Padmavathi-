import uvm_pkg::*;
`include "uvm_macros.svh"

module tb_top;
  logic clk=0, rst_n=1;
  always #5 clk=~clk;
  initial begin rst_n=0; #20 rst_n=1; end

  uart_if uart_interface(clk,rst_n);

  // DUT: APB peripherals (contains UART registers)
  apb_peripherals u_dut (
    .PCLK(clk), .PRESETn(rst_n),
    .PADDR(uart_interface.PADDR), .PWDATA(uart_interface.PWDATA),
    .PWRITE(uart_interface.PWRITE), .PSEL(uart_interface.PSEL),
    .PENABLE(uart_interface.PENABLE), .PRDATA(uart_interface.PRDATA),
    .PREADY(uart_interface.PREADY), .PSLVERR(uart_interface.PSLVERR),
    .gpio_in(8'b0), .gpio_out(), .gpio_dir(),
    .uart_irq(), .spi_irq(), .gpio_irq(), .timer_irq(), .pic_irq_lines()
  );

  initial begin
    uvm_config_db#(virtual uart_if)::set(null,"*","vif",uart_interface);
    run_test("uart_test");
  end
endmodule
