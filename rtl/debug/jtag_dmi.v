// Minimal RISC-V JTAG/DMI debug module scaffold (Task 7).
`timescale 1ns / 1ps

module jtag_dmi #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 7
) (
    input  wire tck,
    input  wire tms,
    input  wire tdi,
    output reg  tdo,
    output reg  tdo_oe,

    input  wire clk,
    input  wire rst,

    output reg  halt_req,
    input  wire halted,
    output reg  resume_req,

    output reg  [ADDR_WIDTH-1:0] dmi_addr,
    output reg  [DATA_WIDTH-1:0] dmi_wdata,
    output reg                   dmi_wr,
    input  wire [DATA_WIDTH-1:0] dmi_rdata,
    input  wire [1:0]           dmi_stat
);

    reg state; // 0=IDLE/capture, 1=shift/update
    reg [31:0] shift_reg;

    always @(posedge tck or posedge rst) begin
        if (rst) begin
            state <= 1'b0;
            shift_reg <= 32'd0;
            tdo <= 1'b0; tdo_oe <= 1'b0;
            halt_req <= 1'b0; resume_req <= 1'b0;
            dmi_addr <= 0; dmi_wdata <= 0; dmi_wr <= 1'b0;
        end else begin
            if (state == 1'b0) begin
                // capture
                if (tms == 1'b0) begin
                    state <= 1'b1;
                    shift_reg <= 32'h00000000;
                    tdo <= 1'b0; tdo_oe <= 1'b1;
                end
            end else begin
                if (tms == 1'b0) begin
                    // shift
                    tdo <= shift_reg[0];
                    tdo_oe <= 1'b1;
                    shift_reg <= {tdi, shift_reg[31:1]};
                end else begin
                    // update
                    state <= 1'b0;
                    tdo_oe <= 1'b0;
                    halt_req <= shift_reg[31];
                    resume_req <= shift_reg[30];
                    dmi_addr <= shift_reg[6:0];
                    dmi_wr <= shift_reg[7];
                end
            end
        end
    end
endmodule