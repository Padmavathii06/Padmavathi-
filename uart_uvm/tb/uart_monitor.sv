import uvm_pkg::*;
`include "uvm_macros.svh"
class uart_monitor extends uvm_monitor;
  `uvm_component_utils(uart_monitor)
  virtual uart_if vif;
  uvm_analysis_port#(uart_transaction) ap;
  function new(string name, uvm_component parent); super.new(name,parent); ap=new("ap",this); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual uart_if)::get(this,"","vif",vif))
      `uvm_fatal("MON","virtual interface not found")
  endfunction
  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      if(vif.mon_cb.PSEL && vif.mon_cb.PENABLE && vif.mon_cb.PREADY) begin
        uart_transaction t=new();
        t.is_write=vif.mon_cb.PWRITE;
        t.addr=vif.mon_cb.PADDR;
        if(t.is_write) t.data=vif.mon_cb.PWDATA; else t.rdata=vif.mon_cb.PRDATA;
        ap.write(t);
      end
    end
  endtask
endclass
