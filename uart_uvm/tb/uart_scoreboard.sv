import uvm_pkg::*;
`include "uvm_macros.svh"
class uart_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(uart_scoreboard)
  uvm_analysis_imp#(uart_transaction,uart_scoreboard) imp;
  function new(string name,uvm_component parent); super.new(name,parent); imp=new("imp",this); endfunction
  function void write(uart_transaction t);
    if(t.is_write) `uvm_info("SCB",$sformatf("WRITE addr=%h data=%h",t.addr,t.data),UVM_LOW)
    else `uvm_info("SCB",$sformatf("READ  addr=%h data=%h",t.addr,t.rdata),UVM_LOW)
  endfunction
endclass
