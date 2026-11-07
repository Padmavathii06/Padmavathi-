import uvm_pkg::*;
`include "uvm_macros.svh"
class uart_env extends uvm_env;
  `uvm_component_utils(uart_env)
  uart_agent agt; uart_scoreboard scb;
  function new(string name,uvm_component parent); super.new(name,parent); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt=new("agt",this); scb=new("scb",this);
  endfunction
  function void connect_phase(uvm_phase phase);
    agt.mon.ap.connect(scb.imp);
  endfunction
endclass
