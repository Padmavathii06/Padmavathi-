import uvm_pkg::*;
`include "uvm_macros.svh"
class uart_sequence extends uvm_sequence#(uart_transaction);
  `uvm_object_utils(uart_sequence)
  function new(string name="uart_sequence"); super.new(name); endfunction
  task body();
    uart_transaction t;
    // write uart_tx then read back
    t=new("t"); t.is_write=1; t.addr=32'h3000_0008; t.data=32'h0000_0041; start_item(t); finish_item(t);
    t=new("t"); t.is_write=0; t.addr=32'h3000_0008; start_item(t); finish_item(t);
  endtask
endclass
