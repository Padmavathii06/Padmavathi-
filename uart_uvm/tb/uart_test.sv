import uvm_pkg::*;
`include "uvm_macros.svh"
class uart_test extends uvm_test;
  `uvm_component_utils(uart_test)
  uart_env env;
  function new(string name,uvm_component parent); super.new(name,parent); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env=new("env",this);
  endfunction
  task run_phase(uvm_phase phase);
    uart_sequence seq;
    phase.raise_objection(this);
    seq=new("seq"); seq.start(env.agt.seqr);
    #100;
    phase.drop_objection(this);
  endtask
endclass
