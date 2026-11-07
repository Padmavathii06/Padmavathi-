interface uart_if (input logic clk, input logic rst_n);
  logic [31:0] PADDR, PWDATA, PRDATA;
  logic        PSEL, PENABLE, PWRITE, PREADY, PSLVERR;
  clocking drv_cb @(posedge clk); output PADDR,PWDATA,PSEL,PENABLE,PWRITE; input PRDATA,PREADY,PSLVERR; endclocking
  clocking mon_cb @(posedge clk); input PADDR,PWDATA,PRDATA,PSEL,PENABLE,PWRITE,PREADY,PSLVERR; endclocking
endinterface
