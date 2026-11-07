import uvm_pkg::*;
`include "uvm_macros.svh"
class uart_agent extends uvm_agent;
  `uvm_component_utils(uart_agent)
  uart_sequencer seqr; uart_driver drv; uart_monitor mon;
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon=new("mon",this);
    if(get_is_active()==UVM_ACTIVE) begin seqr=new("seqr",this); drv=new("drv",this); end
  endfunction
  function void connect_phase(uvm_phase phase);
    if(get_is_active()==UVM_ACTIVE) drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass
