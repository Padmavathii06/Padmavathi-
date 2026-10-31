`timescale 1ns / 1ps

module tb_jtag_dmi;
    reg tck, tms, tdi;
    wire tdo, tdo_oe;
    reg clk, rst;
    wire halt_req, resume_req;
    reg halted;
    wire [6:0] dmi_addr;
    wire [31:0] dmi_wdata;
    wire dmi_wr;
    reg [31:0] dmi_rdata;
    reg [1:0] dmi_stat;

    jtag_dmi #(.DATA_WIDTH(32), .ADDR_WIDTH(7)) dut (
        .tck(tck), .tms(tms), .tdi(tdi), .tdo(tdo), .tdo_oe(tdo_oe),
        .clk(clk), .rst(rst),
        .halt_req(halt_req), .halted(halted), .resume_req(resume_req),
        .dmi_addr(dmi_addr), .dmi_wdata(dmi_wdata), .dmi_wr(dmi_wr),
        .dmi_rdata(dmi_rdata), .dmi_stat(dmi_stat)
    );

    integer errors;
    initial begin clk=0; forever #5 clk=~clk; end
    initial begin tck=0; forever #10 tck=~tck; end

    task jtag_shift(input [31:0] val);
        integer i;
        begin
            tms=0; // enter shift
            for (i=0;i<32;i=i+1) begin
                tdi = val[i];
                @(posedge tck);
            end
        end
    endtask

    initial begin
        errors=0;
        rst=1; tms=1; tdi=0; halted=0; dmi_rdata=0; dmi_stat=0;
        #40; rst=0;
        #40;
        // capture + shift 32 bits (halt bit in MSB)
        tms=0; @(posedge tck); // capture
        jtag_shift(32'h80000000);
        // update
        tms=1; @(posedge tck);
        tms=0; @(posedge tck);
        #20;
        if (halt_req !== 1'b1) begin errors=errors+1; $display("ERROR halt_req not asserted"); end
        if (errors==0) begin $display("RESULT: TEST PASSED"); end
        else begin $display("RESULT: TEST FAILED %0d", errors); $fatal(1,"fail"); end
        $finish;
    end
    initial begin #1000000; $fatal(1,"TIMEOUT"); end
endmodule