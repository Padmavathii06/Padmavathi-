import uvm_pkg::*;
`include "uvm_macros.svh"
class uart_driver extends uvm_driver#(uart_transaction);
  `uvm_component_utils(uart_driver)
  virtual uart_if vif;
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual uart_if)::get(this,"","vif",vif))
      `uvm_fatal("DRV","virtual interface not found")
  endfunction
  task run_phase(uvm_phase phase);
    uart_transaction t;
    forever begin
      seq_item_port.get_next_item(t);
      if(t.is_write) begin
        @(posedge vif.clk);
        vif.drv_cb.PADDR<=t.addr; vif.drv_cb.PWDATA<=t.data; vif.drv_cb.PWRITE<=1; vif.drv_cb.PSEL<=1; vif.drv_cb.PENABLE<=0;
        @(posedge vif.clk); vif.drv_cb.PENABLE<=1;
        @(posedge vif.clk);
        while(!vif.drv_cb.PREADY) @(posedge vif.clk);
        vif.drv_cb.PSEL<=0; vif.drv_cb.PENABLE<=0;
      end else begin
        @(posedge vif.clk);
        vif.drv_cb.PADDR<=t.addr; vif.drv_cb.PWRITE<=0; vif.drv_cb.PSEL<=1; vif.drv_cb.PENABLE<=0;
        @(posedge vif.clk); vif.drv_cb.PENABLE<=1;
        @(posedge vif.clk);
        while(!vif.drv_cb.PREADY) @(posedge vif.clk);
        t.rdata=vif.drv_cb.PRDATA;
        vif.drv_cb.PSEL<=0; vif.drv_cb.PENABLE<=0;
      end
      seq_item_port.item_done();
    end
  endtask
endclass
