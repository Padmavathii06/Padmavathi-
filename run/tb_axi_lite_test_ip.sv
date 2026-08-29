`timescale 1ns / 1ps

module tb_axi_lite_test_ip;

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;

    reg clk;
    reg rst_n;

    //============================================================
    // WRITE ADDRESS
    //============================================================

    reg  [ADDR_WIDTH-1:0] s_axi_awaddr;
    reg                   s_axi_awvalid;
    wire                  s_axi_awready;

    //============================================================
    // WRITE DATA
    //============================================================

    reg  [DATA_WIDTH-1:0] s_axi_wdata;
    reg  [DATA_WIDTH/8-1:0] s_axi_wstrb;
    reg                   s_axi_wvalid;
    wire                  s_axi_wready;

    //============================================================
    // WRITE RESPONSE
    //============================================================

    wire [1:0] s_axi_bresp;
    wire       s_axi_bvalid;
    reg        s_axi_bready;

    //============================================================
    // READ ADDRESS
    //============================================================

    reg  [ADDR_WIDTH-1:0] s_axi_araddr;
    reg                   s_axi_arvalid;
    wire                  s_axi_arready;

    //============================================================
    // READ DATA
    //============================================================

    wire [DATA_WIDTH-1:0] s_axi_rdata;
    wire [1:0]            s_axi_rresp;
    wire                  s_axi_rvalid;
    reg                   s_axi_rready;


    //============================================================
    // DUT
    //============================================================

    axi_lite_test_ip #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (

        .S_AXI_ACLK     (clk),
        .S_AXI_ARESETN  (rst_n),

        .S_AXI_AWADDR   (s_axi_awaddr),
        .S_AXI_AWVALID  (s_axi_awvalid),
        .S_AXI_AWREADY  (s_axi_awready),

        .S_AXI_WDATA    (s_axi_wdata),
        .S_AXI_WSTRB    (s_axi_wstrb),
        .S_AXI_WVALID   (s_axi_wvalid),
        .S_AXI_WREADY   (s_axi_wready),

        .S_AXI_BRESP    (s_axi_bresp),
        .S_AXI_BVALID   (s_axi_bvalid),
        .S_AXI_BREADY   (s_axi_bready),

        .S_AXI_ARADDR   (s_axi_araddr),
        .S_AXI_ARVALID  (s_axi_arvalid),
        .S_AXI_ARREADY  (s_axi_arready),

        .S_AXI_RDATA    (s_axi_rdata),
        .S_AXI_RRESP    (s_axi_rresp),
        .S_AXI_RVALID   (s_axi_rvalid),
        .S_AXI_RREADY   (s_axi_rready)
    );


    //============================================================
    // CLOCK
    //============================================================

    initial begin
        clk = 0;

        forever #5 clk = ~clk;
    end


    //============================================================
    // WRITE TASK
    //============================================================

    task axi_write;

        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;

        begin

            @(posedge clk);

            s_axi_awaddr  <= addr;
            s_axi_awvalid <= 1'b1;

            s_axi_wdata   <= data;
            s_axi_wstrb   <= 4'b1111;
            s_axi_wvalid  <= 1'b1;

            wait (s_axi_awready && s_axi_wready);

            @(posedge clk);

            s_axi_awvalid <= 1'b0;
            s_axi_wvalid  <= 1'b0;

            wait (s_axi_bvalid);

            @(posedge clk);

            s_axi_bready <= 1'b1;

            @(posedge clk);

            s_axi_bready <= 1'b0;

            $display("WRITE: ADDR = %h DATA = %h",
                     addr, data);

        end

    endtask


    //============================================================
    // READ TASK
    //============================================================

    task axi_read;

        input  [ADDR_WIDTH-1:0] addr;
        output [DATA_WIDTH-1:0] data;

        begin

            @(posedge clk);

            s_axi_araddr  <= addr;
            s_axi_arvalid <= 1'b1;

            wait (s_axi_arready);

            @(posedge clk);

            s_axi_arvalid <= 1'b0;

            wait (s_axi_rvalid);

            data = s_axi_rdata;

            $display("READ : ADDR = %h DATA = %h",
                     addr, data);

            @(posedge clk);

            s_axi_rready <= 1'b1;

            @(posedge clk);

            s_axi_rready <= 1'b0;

        end

    endtask


    //============================================================
    // TEST
    //============================================================

    reg [31:0] read_data;

    initial begin

        // Initial values

        rst_n = 1'b0;

        s_axi_awaddr  = 0;
        s_axi_awvalid = 0;

        s_axi_wdata   = 0;
        s_axi_wstrb   = 0;
        s_axi_wvalid  = 0;

        s_axi_bready  = 0;

        s_axi_araddr  = 0;
        s_axi_arvalid = 0;

        s_axi_rready  = 0;


        // Reset

        #100;

        rst_n = 1'b1;

        #20;


        //========================================================
        // TEST 1
        // Write CONTROL = 1
        //========================================================

        axi_write(
            32'h00000000,
            32'h00000001
        );


        //========================================================
        // TEST 2
        // Write DATA_A
        //========================================================

        axi_write(
            32'h00000004,
            32'h0000000A
        );


        //========================================================
        // TEST 3
        // Write DATA_B
        //========================================================

        axi_write(
            32'h00000008,
            32'h00000014
        );


        //========================================================
        // READ BACK
        //========================================================

        axi_read(
            32'h00000000,
            read_data
        );

        axi_read(
            32'h00000004,
            read_data
        );

        axi_read(
            32'h00000008,
            read_data
        );

        axi_read(
            32'h0000000C,
            read_data
        );


        #100;

        $display("========================================");
        $display("AXI4-LITE IP TEST FINISHED");
        $display("========================================");

        $finish;

    end


    //============================================================
    // FSDB
    //============================================================

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars("+all");
    $fsdbDumpSVA();
    $fsdbDumpMDA();
end

endmodule
