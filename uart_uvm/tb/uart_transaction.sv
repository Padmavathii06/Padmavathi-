import uvm_pkg::*;
`include "uvm_macros.svh"
class uart_transaction extends uvm_sequence_item;
  rand bit        is_write;
  rand bit [31:0] addr;
  rand bit [31:0] data;
  bit [31:0]      rdata;
  `uvm_object_utils_begin(uart_transaction)
    `uvm_field_int(is_write,UVM_ALL_ON)
    `uvm_field_int(addr,UVM_ALL_ON)
    `uvm_field_int(data,UVM_ALL_ON)
    `uvm_field_int(rdata,UVM_ALL_ON)
  `uvm_object_utils_end
  function new(string name="uart_transaction"); super.new(name); endfunction
endclass
