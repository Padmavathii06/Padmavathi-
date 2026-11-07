// UART VIP interface wrapping the SoC's internal UART registers
interface uart_vip_if (input logic clk, input logic rst_n);
  // Expose internal register taps (connected hierarchically in tb_top)
  logic [31:0] uart_ctrl;
  logic [31:0] uart_status;
  logic [31:0] uart_tx;
  logic [31:0] uart_rx;
  logic        uart_irq;

  clocking drv_cb @(posedge clk);
    output uart_tx, uart_ctrl, uart_rx;
    input  uart_status, uart_irq;
  endclocking

  clocking mon_cb @(posedge clk);
    input uart_ctrl, uart_status, uart_tx, uart_rx, uart_irq;
  endclocking
endinterface
