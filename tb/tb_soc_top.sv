`timescale 1ns / 1ps

module tb_soc_top;
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;
    parameter ID_WIDTH   = 8;

    reg clk;
    reg rst_l;
    integer errors;

    // Manager 0 ports
    reg  [ID_WIDTH-1:0] m0_awid; reg [ADDR_WIDTH-1:0] m0_awaddr; reg [7:0] m0_awlen;
    reg [2:0] m0_awsize; reg [1:0] m0_awburst; reg m0_awlock; reg [3:0] m0_awcache; reg [2:0] m0_awprot;
    reg [3:0] m0_awqos; reg [3:0] m0_awregion; reg m0_awuser; reg m0_awvalid;
    wire m0_awready;
    reg [DATA_WIDTH-1:0] m0_wdata; reg [DATA_WIDTH/8-1:0] m0_wstrb; reg m0_wlast; reg m0_wuser; reg m0_wvalid;
    wire m0_wready;
    wire [ID_WIDTH-1:0] m0_bid; wire [1:0] m0_bresp; wire m0_buser; wire m0_bvalid; reg m0_bready;
    reg [ID_WIDTH-1:0] m0_arid; reg [ADDR_WIDTH-1:0] m0_araddr; reg [7:0] m0_arlen; reg [2:0] m0_arsize;
    reg [1:0] m0_arburst; reg m0_arlock; reg [3:0] m0_arcache; reg [2:0] m0_arprot; reg [3:0] m0_arqos;
    reg [3:0] m0_arregion; reg m0_aruser; reg m0_arvalid; wire m0_arready;
    wire [ID_WIDTH-1:0] m0_rid; wire [DATA_WIDTH-1:0] m0_rdata; wire [1:0] m0_rresp; wire m0_rlast;
    wire m0_ruser; wire m0_rvalid; reg m0_rready;

    // Tie off other managers to idle
    // (connect minimal zero ports)
    reg  [ID_WIDTH-1:0] z_awid=0; reg [ADDR_WIDTH-1:0] z_awaddr=0; reg [7:0] z_awlen=0;
    reg [2:0] z_awsize=3'b010; reg [1:0] z_awburst=2'b01; reg z_awlock=0; reg [3:0] z_awcache=0; reg [2:0] z_awprot=0;
    reg [3:0] z_awqos=0; reg [3:0] z_awregion=0; reg z_awuser=0; reg z_awvalid=0;
    reg [DATA_WIDTH-1:0] z_wdata=0; reg [DATA_WIDTH/8-1:0] z_wstrb=0; reg z_wlast=1; reg z_wuser=0; reg z_wvalid=0;
    reg z_bready=1;
    reg [ID_WIDTH-1:0] z_arid=0; reg [ADDR_WIDTH-1:0] z_araddr=0; reg [7:0] z_arlen=0; reg [2:0] z_arsize=3'b010;
    reg [1:0] z_arburst=2'b01; reg z_arlock=0; reg [3:0] z_arcache=0; reg [2:0] z_arprot=0; reg [3:0] z_arqos=0;
    reg [3:0] z_arregion=0; reg z_aruser=0; reg z_arvalid=0; reg z_rready=1;

    soc_top #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .ID_WIDTH(ID_WIDTH)) dut (
        .clk(clk), .rst_l(rst_l),

        .m0_awid(m0_awid), .m0_awaddr(m0_awaddr), .m0_awlen(m0_awlen), .m0_awsize(m0_awsize),
        .m0_awburst(m0_awburst), .m0_awlock(m0_awlock), .m0_awcache(m0_awcache), .m0_awprot(m0_awprot),
        .m0_awqos(m0_awqos), .m0_awregion(m0_awregion), .m0_awuser(m0_awuser), .m0_awvalid(m0_awvalid),
        .m0_awready(m0_awready),
        .m0_wdata(m0_wdata), .m0_wstrb(m0_wstrb), .m0_wlast(m0_wlast), .m0_wuser(m0_wuser),
        .m0_wvalid(m0_wvalid), .m0_wready(m0_wready),
        .m0_bid(m0_bid), .m0_bresp(m0_bresp), .m0_buser(m0_buser), .m0_bvalid(m0_bvalid), .m0_bready(m0_bready),
        .m0_arid(m0_arid), .m0_araddr(m0_araddr), .m0_arlen(m0_arlen), .m0_arsize(m0_arsize),
        .m0_arburst(m0_arburst), .m0_arlock(m0_arlock), .m0_arcache(m0_arcache), .m0_arprot(m0_arprot),
        .m0_arqos(m0_arqos), .m0_arregion(m0_arregion), .m0_aruser(m0_aruser), .m0_arvalid(m0_arvalid),
        .m0_arready(m0_arready),
        .m0_rid(m0_rid), .m0_rdata(m0_rdata), .m0_rresp(m0_rresp), .m0_rlast(m0_rlast),
        .m0_ruser(m0_ruser), .m0_rvalid(m0_rvalid), .m0_rready(m0_rready),

        // m1
        .m1_awid(z_awid), .m1_awaddr(z_awaddr), .m1_awlen(z_awlen), .m1_awsize(z_awsize),
        .m1_awburst(z_awburst), .m1_awlock(z_awlock), .m1_awcache(z_awcache), .m1_awprot(z_awprot),
        .m1_awqos(z_awqos), .m1_awregion(z_awregion), .m1_awuser(z_awuser), .m1_awvalid(z_awvalid),
        .m1_awready(), .m1_wdata(z_wdata), .m1_wstrb(z_wstrb), .m1_wlast(z_wlast), .m1_wuser(z_wuser),
        .m1_wvalid(z_wvalid), .m1_wready(), .m1_bid(), .m1_bresp(), .m1_buser(), .m1_bvalid(), .m1_bready(z_bready),
        .m1_arid(z_arid), .m1_araddr(z_araddr), .m1_arlen(z_arlen), .m1_arsize(z_arsize),
        .m1_arburst(z_arburst), .m1_arlock(z_arlock), .m1_arcache(z_arcache), .m1_arprot(z_arprot),
        .m1_arqos(z_arqos), .m1_arregion(z_arregion), .m1_aruser(z_aruser), .m1_arvalid(z_arvalid),
        .m1_arready(), .m1_rid(), .m1_rdata(), .m1_rresp(), .m1_rlast(), .m1_ruser(), .m1_rvalid(), .m1_rready(z_rready),

        // m2
        .m2_awid(z_awid), .m2_awaddr(z_awaddr), .m2_awlen(z_awlen), .m2_awsize(z_awsize),
        .m2_awburst(z_awburst), .m2_awlock(z_awlock), .m2_awcache(z_awcache), .m2_awprot(z_awprot),
        .m2_awqos(z_awqos), .m2_awregion(z_awregion), .m2_awuser(z_awuser), .m2_awvalid(z_awvalid),
        .m2_awready(), .m2_wdata(z_wdata), .m2_wstrb(z_wstrb), .m2_wlast(z_wlast), .m2_wuser(z_wuser),
        .m2_wvalid(z_wvalid), .m2_wready(), .m2_bid(), .m2_bresp(), .m2_buser(), .m2_bvalid(), .m2_bready(z_bready),
        .m2_arid(z_arid), .m2_araddr(z_araddr), .m2_arlen(z_arlen), .m2_arsize(z_arsize),
        .m2_arburst(z_arburst), .m2_arlock(z_arlock), .m2_arcache(z_arcache), .m2_arprot(z_arprot),
        .m2_arqos(z_arqos), .m2_arregion(z_arregion), .m2_aruser(z_aruser), .m2_arvalid(z_arvalid),
        .m2_arready(), .m2_rid(), .m2_rdata(), .m2_rresp(), .m2_rlast(), .m2_ruser(), .m2_rvalid(), .m2_rready(z_rready),

        // m3
        .m3_awid(z_awid), .m3_awaddr(z_awaddr), .m3_awlen(z_awlen), .m3_awsize(z_awsize),
        .m3_awburst(z_awburst), .m3_awlock(z_awlock), .m3_awcache(z_awcache), .m3_awprot(z_awprot),
        .m3_awqos(z_awqos), .m3_awregion(z_awregion), .m3_awuser(z_awuser), .m3_awvalid(z_awvalid),
        .m3_awready(), .m3_wdata(z_wdata), .m3_wstrb(z_wstrb), .m3_wlast(z_wlast), .m3_wuser(z_wuser),
        .m3_wvalid(z_wvalid), .m3_wready(), .m3_bid(), .m3_bresp(), .m3_buser(), .m3_bvalid(), .m3_bready(z_bready),
        .m3_arid(z_arid), .m3_araddr(z_araddr), .m3_arlen(z_arlen), .m3_arsize(z_arsize),
        .m3_arburst(z_arburst), .m3_arlock(z_arlock), .m3_arcache(z_arcache), .m3_arprot(z_arprot),
        .m3_arqos(z_arqos), .m3_arregion(z_arregion), .m3_aruser(z_aruser), .m3_arvalid(z_arvalid),
        .m3_arready(), .m3_rid(), .m3_rdata(), .m3_rresp(), .m3_rlast(), .m3_ruser(), .m3_rvalid(), .m3_rready(z_rready)
    );

    task axi_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
        begin
            @(negedge clk);
            m0_awid=0; m0_awaddr=addr; m0_awlen=0; m0_awsize=3'b010; m0_awburst=2'b01; m0_awlock=0; m0_awcache=0;
            m0_awprot=0; m0_awqos=0; m0_awregion=0; m0_awuser=0; m0_awvalid=1;
            m0_wdata=data; m0_wstrb=4'hF; m0_wlast=1; m0_wuser=0; m0_wvalid=1;
            fork
                begin
                    do begin
                        @(posedge clk);
                        $display("DBG awready=%b awvalid=%b time=%0t", m0_awready, m0_awvalid, $time);
                    end while(!m0_awready);
                end
                begin
                    do begin
                        @(posedge clk);
                        $display("DBG wready=%b wvalid=%b time=%0t", m0_wready, m0_wvalid, $time);
                    end while(!m0_wready);
                end
            join
            @(negedge clk); m0_awvalid=0; m0_wvalid=0;
            begin
                integer t;
                for (t=0; t<50 && !m0_bvalid; t=t+1) begin
                    @(posedge clk);
                    $display("DBG bvalid=%b bready=%b time=%0t", m0_bvalid, m0_bready, $time);
                end
            end
            if (!m0_bvalid) begin $display("NO BVALID"); end
            if (m0_bresp !== 2'b00) begin errors=errors+1; $display("ERROR bresp %0d", m0_bresp); end
            @(posedge clk);
        end
    endtask

    task axi_read(input [ADDR_WIDTH-1:0] addr, output [DATA_WIDTH-1:0] data);
        begin
            @(negedge clk);
            m0_arid=0; m0_araddr=addr; m0_arlen=0; m0_arsize=3'b010; m0_arburst=2'b01; m0_arlock=0;
            m0_arcache=0; m0_arprot=0; m0_arqos=0; m0_arregion=0; m0_aruser=0; m0_arvalid=1;
            do @(posedge clk); while(!m0_arready);
            @(negedge clk); m0_arvalid=0;
            while(!m0_rvalid) @(posedge clk);
            data=m0_rdata;
            if (m0_rresp !== 2'b00) begin errors=errors+1; $display("ERROR rresp %0d", m0_rresp); end
            @(posedge clk);
        end
    endtask

    reg [DATA_WIDTH-1:0] rd;
    initial begin
        clk=0; forever #5 clk=~clk;
    end
    initial begin
        errors=0;
        rst_l=1'b0;
        m0_bready=1; m0_rready=1; m0_awvalid=0; m0_wvalid=0; m0_arvalid=0;
        repeat(5) @(posedge clk);
        rst_l=1'b1;
        repeat(12) @(posedge clk);

        $display("=================================================");
        $display("TEST 1: SRAM write and read (0x0000_0040)");
        $display("=================================================");
        axi_write(32'h0000_0040, 32'hCAFEBABE);
        axi_read(32'h0000_0040, rd);
        $display("SRAM READ: exp CAFEBABE, got %h", rd);
        if (rd !== 32'hCAFEBABE) begin errors=errors+1; $display("ERROR: SRAM mismatch %h", rd); end

        $display("=================================================");
        $display("TEST 2: Boot ROM read firmware (0x1000_0000)");
        $display("=================================================");
        axi_read(32'h1000_0000, rd);
        $display("BOOT ROM word 0: %h", rd);
        if (rd !== 32'hf0040117) begin errors=errors+1; $display("ERROR: Boot ROM word 0 mismatch: exp f0040117, got %h", rd); end

        axi_read(32'h1000_0004, rd);
        $display("BOOT ROM word 1: %h", rd);
        if (rd !== 32'h00010113) begin errors=errors+1; $display("ERROR: Boot ROM word 1 mismatch: exp 00010113, got %h", rd); end

        $display("=================================================");
        $display("TEST 3: IPU config register write and read (0x2000_0008)");
        $display("=================================================");
        axi_write(32'h2000_0008, 32'd1920);
        axi_read(32'h2000_0008, rd);
        $display("IPU FRAME WIDTH: exp 00000780 (1920), got %h", rd);
        if (rd !== 32'd1920) begin errors=errors+1; $display("ERROR: IPU FRAME WIDTH mismatch %h", rd); end

        $display("=================================================");
        $display("TEST 4: APB peripheral write and read (0x3000_0300 Timer LOAD)");
        $display("=================================================");
        axi_write(32'h3000_0300, 32'h0000_5678);
        axi_read(32'h3000_0300, rd);
        $display("APB Timer LOAD: exp 00005678, got %h", rd);
        if (rd !== 32'h0000_5678) begin errors=errors+1; $display("ERROR: APB Timer LOAD mismatch %h", rd); end

        if (errors==0) begin $display("RESULT: TEST PASSED"); $finish; end
        else begin $display("RESULT: TEST FAILED %0d", errors); $fatal(1,"fail"); end
    end
    initial begin #1_000_000; $fatal(1,"TIMEOUT"); end
endmodule