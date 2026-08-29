`timescale 1ns / 1ps

module axi_lite_test_ip #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                     S_AXI_ACLK,
    input  wire                     S_AXI_ARESETN,

    //============================================================
    // AXI4-Lite WRITE ADDRESS CHANNEL
    //============================================================
    input  wire [ADDR_WIDTH-1:0]    S_AXI_AWADDR,
    input  wire                     S_AXI_AWVALID,
    output wire                     S_AXI_AWREADY,

    //============================================================
    // AXI4-Lite WRITE DATA CHANNEL
    //============================================================
    input  wire [DATA_WIDTH-1:0]    S_AXI_WDATA,
    input  wire [DATA_WIDTH/8-1:0]  S_AXI_WSTRB,
    input  wire                     S_AXI_WVALID,
    output wire                     S_AXI_WREADY,

    //============================================================
    // AXI4-Lite WRITE RESPONSE CHANNEL
    //============================================================
    output reg  [1:0]               S_AXI_BRESP,
    output reg                      S_AXI_BVALID,
    input  wire                     S_AXI_BREADY,

    //============================================================
    // AXI4-Lite READ ADDRESS CHANNEL
    //============================================================
    input  wire [ADDR_WIDTH-1:0]    S_AXI_ARADDR,
    input  wire                     S_AXI_ARVALID,
    output wire                     S_AXI_ARREADY,

    //============================================================
    // AXI4-Lite READ DATA CHANNEL
    //============================================================
    output reg  [DATA_WIDTH-1:0]    S_AXI_RDATA,
    output reg  [1:0]               S_AXI_RRESP,
    output reg                      S_AXI_RVALID,
    input  wire                     S_AXI_RREADY
);

    //============================================================
    // INTERNAL REGISTERS
    //============================================================

    reg [DATA_WIDTH-1:0] control_reg;
    reg [DATA_WIDTH-1:0] data_a_reg;
    reg [DATA_WIDTH-1:0] data_b_reg;
    reg [DATA_WIDTH-1:0] result_reg;

    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg                  awaddr_valid;

    reg [DATA_WIDTH-1:0] wdata_reg;
    reg [DATA_WIDTH/8-1:0] wstrb_reg;
    reg                   wdata_valid;

    reg                  araddr_valid;
    reg [ADDR_WIDTH-1:0] araddr_reg;

    //============================================================
    // READY SIGNALS
    //============================================================

    assign S_AXI_AWREADY = !awaddr_valid && !S_AXI_BVALID;
    assign S_AXI_WREADY  = !wdata_valid  && !S_AXI_BVALID;
    assign S_AXI_ARREADY = !araddr_valid && !S_AXI_RVALID;

    //============================================================
    // WRITE CHANNEL
    //============================================================

    always @(posedge S_AXI_ACLK) begin

        if (!S_AXI_ARESETN) begin

            awaddr_reg   <= 0;
            awaddr_valid <= 0;

            wdata_reg    <= 0;
            wstrb_reg    <= 0;
            wdata_valid  <= 0;

            S_AXI_BVALID <= 0;
            S_AXI_BRESP  <= 2'b00;

            control_reg  <= 0;
            data_a_reg   <= 0;
            data_b_reg   <= 0;
            result_reg   <= 0;

        end
        else begin

            //====================================================
            // Capture WRITE ADDRESS
            //====================================================

            if (S_AXI_AWVALID && S_AXI_AWREADY) begin
                awaddr_reg   <= S_AXI_AWADDR;
                awaddr_valid <= 1'b1;
            end

            //====================================================
            // Capture WRITE DATA
            //====================================================

            if (S_AXI_WVALID && S_AXI_WREADY) begin
                wdata_reg   <= S_AXI_WDATA;
                wstrb_reg   <= S_AXI_WSTRB;
                wdata_valid <= 1'b1;
            end

            //====================================================
            // Perform WRITE when ADDRESS + DATA are available
            //====================================================

            if (awaddr_valid && wdata_valid && !S_AXI_BVALID) begin

                case (awaddr_reg[5:2])

                    // 0x00 : CONTROL
                    4'h0: begin
                        if (wstrb_reg[0])
                            control_reg[7:0] <= wdata_reg[7:0];

                        if (wstrb_reg[1])
                            control_reg[15:8] <= wdata_reg[15:8];

                        if (wstrb_reg[2])
                            control_reg[23:16] <= wdata_reg[23:16];

                        if (wstrb_reg[3])
                            control_reg[31:24] <= wdata_reg[31:24];
                    end

                    // 0x04 : DATA_A
                    4'h1: begin
                        if (wstrb_reg[0])
                            data_a_reg[7:0] <= wdata_reg[7:0];

                        if (wstrb_reg[1])
                            data_a_reg[15:8] <= wdata_reg[15:8];

                        if (wstrb_reg[2])
                            data_a_reg[23:16] <= wdata_reg[23:16];

                        if (wstrb_reg[3])
                            data_a_reg[31:24] <= wdata_reg[31:24];
                    end

                    // 0x08 : DATA_B
                    4'h2: begin
                        if (wstrb_reg[0])
                            data_b_reg[7:0] <= wdata_reg[7:0];

                        if (wstrb_reg[1])
                            data_b_reg[15:8] <= wdata_reg[15:8];

                        if (wstrb_reg[2])
                            data_b_reg[23:16] <= wdata_reg[23:16];

                        if (wstrb_reg[3])
                            data_b_reg[31:24] <= wdata_reg[31:24];
                    end

                    // 0x0C : RESULT
                    4'h3: begin
                        if (wstrb_reg[0])
                            result_reg[7:0] <= wdata_reg[7:0];

                        if (wstrb_reg[1])
                            result_reg[15:8] <= wdata_reg[15:8];

                        if (wstrb_reg[2])
                            result_reg[23:16] <= wdata_reg[23:16];

                        if (wstrb_reg[3])
                            result_reg[31:24] <= wdata_reg[31:24];
                    end

                    default: begin
                    end

                endcase

                // WRITE RESPONSE = OKAY
                S_AXI_BRESP  <= 2'b00;
                S_AXI_BVALID <= 1'b1;

                awaddr_valid <= 1'b0;
                wdata_valid  <= 1'b0;
            end

            //====================================================
            // Complete WRITE RESPONSE
            //====================================================

            if (S_AXI_BVALID && S_AXI_BREADY) begin
                S_AXI_BVALID <= 1'b0;
            end

        end
    end

    //============================================================
    // READ CHANNEL
    //============================================================

    always @(posedge S_AXI_ACLK) begin

        if (!S_AXI_ARESETN) begin

            araddr_reg   <= 0;
            araddr_valid <= 0;

            S_AXI_RDATA  <= 0;
            S_AXI_RRESP  <= 2'b00;
            S_AXI_RVALID <= 1'b0;

        end
        else begin

            //====================================================
            // Capture READ ADDRESS
            //====================================================

            if (S_AXI_ARVALID && S_AXI_ARREADY) begin

                araddr_reg   <= S_AXI_ARADDR;
                araddr_valid <= 1'b1;

            end

            //====================================================
            // Generate READ DATA
            //====================================================

            if (araddr_valid && !S_AXI_RVALID) begin

                case (araddr_reg[5:2])

                    // 0x00 : CONTROL
                    4'h0:
                        S_AXI_RDATA <= control_reg;

                    // 0x04 : DATA_A
                    4'h1:
                        S_AXI_RDATA <= data_a_reg;

                    // 0x08 : DATA_B
                    4'h2:
                        S_AXI_RDATA <= data_b_reg;

                    // 0x0C : RESULT
                    4'h3:
                        S_AXI_RDATA <= result_reg;

                    default:
                        S_AXI_RDATA <= 32'h00000000;

                endcase

                S_AXI_RRESP  <= 2'b00;
                S_AXI_RVALID <= 1'b1;

                araddr_valid <= 1'b0;
            end

            //====================================================
            // Complete READ
            //====================================================

            if (S_AXI_RVALID && S_AXI_RREADY) begin
                S_AXI_RVALID <= 1'b0;
            end

        end
    end

endmodule
