// APB peripheral subsystem: UART, SPI, GPIO, Timer, PIC register slaves.
// Address map (word addresses, base per peripheral):
//  0x0000 UART  : 0 CTRL, 1 STATUS, 2 TXDATA, 3 RXDATA
//  0x0100 SPI   : 0 CTRL, 1 STATUS, 2 TXDATA, 3 RXDATA
//  0x0200 GPIO  : 0 DIR, 1 OUT, 2 IN, 3 IRQMASK
//  0x0300 Timer : 0 LOAD, 1 COUNT, 2 CTRL, 3 STATUS
//  0x0400 PIC   : 0 MASK, 1 PEND, 2 PRIO
module apb_peripherals (
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire [31:0] PADDR,
    input  wire [31:0] PWDATA,
    input  wire        PWRITE,
    input  wire        PSEL,
    input  wire        PENABLE,
    output reg  [31:0] PRDATA,
    output wire        PREADY,
    output wire        PSLVERR,
    // GPIO external
    input  wire [7:0]  gpio_in,
    output reg  [7:0]  gpio_out,
    output reg  [7:0]  gpio_dir,
    // IRQ lines
    output wire        uart_irq,
    output wire        spi_irq,
    output wire        gpio_irq,
    output wire        timer_irq,
    output wire [4:0]  pic_irq_lines
);

    assign PREADY = 1'b1;
    assign PSLVERR = 1'b0;

    // Register banks
    reg [31:0] uart_ctrl, uart_status, uart_tx, uart_rx;
    reg [31:0] spi_ctrl, spi_status, spi_tx, spi_rx;
    reg [31:0] gpio_irqmask;
    reg [31:0] timer_load, timer_count, timer_ctrl, timer_status;
    reg [31:0] pic_mask, pic_pend, pic_prio;

    // Timer
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            timer_count <= 0; timer_status <= 0;
        end else if (timer_ctrl[0]) begin
            if (timer_count == 0) begin
                timer_count <= timer_load;
                timer_status <= 1;
            end else timer_count <= timer_count - 1;
        end
    end

    assign timer_irq = timer_status & timer_ctrl[1];

    // IRQs simple
    assign uart_irq = uart_status[0];
    assign spi_irq  = spi_status[0];
    assign gpio_irq = |(gpio_in & gpio_irqmask[7:0]);
    assign pic_irq_lines = {timer_irq, gpio_irq, spi_irq, uart_irq, 1'b0};

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            uart_ctrl<=0; uart_status<=0; uart_tx<=0; uart_rx<=0;
            spi_ctrl<=0; spi_status<=0; spi_tx<=0; spi_rx<=0;
            gpio_dir<=0; gpio_out<=0; gpio_irqmask<=0;
            timer_load<=0; timer_ctrl<=0; timer_status<=0;
            pic_mask<=0; pic_pend<=0; pic_prio<=0;
        end else if (PSEL && PENABLE && PWRITE) begin
            case (PADDR[11:8])
                4'h0: case (PADDR[3:2])
                    2'd0: uart_ctrl <= PWDATA;
                    2'd1: uart_status <= PWDATA;
                    2'd2: uart_tx <= PWDATA;
                    2'd3: uart_rx <= PWDATA;
                endcase
                4'h1: case (PADDR[3:2])
                    2'd0: spi_ctrl <= PWDATA;
                    2'd1: spi_status <= PWDATA;
                    2'd2: spi_tx <= PWDATA;
                    2'd3: spi_rx <= PWDATA;
                endcase
                4'h2: case (PADDR[3:2])
                    2'd0: gpio_dir <= PWDATA[7:0];
                    2'd1: gpio_out <= PWDATA[7:0];
                    2'd2: ; // IN read-only
                    2'd3: gpio_irqmask <= PWDATA;
                endcase
                4'h3: case (PADDR[3:2])
                    2'd0: timer_load <= PWDATA;
                    2'd1: ; // count ro
                    2'd2: timer_ctrl <= PWDATA;
                    2'd3: timer_status <= PWDATA;
                endcase
                4'h4: case (PADDR[3:2])
                    2'd0: pic_mask <= PWDATA;
                    2'd1: pic_pend <= PWDATA;
                    2'd2: pic_prio <= PWDATA;
                endcase
            endcase
        end
    end

    always @(*) begin
        PRDATA = 0;
        if (PSEL) begin
            case (PADDR[11:8])
                4'h0: case (PADDR[3:2])
                    2'd0: PRDATA = uart_ctrl;
                    2'd1: PRDATA = uart_status;
                    2'd2: PRDATA = uart_tx;
                    2'd3: PRDATA = uart_rx;
                endcase
                4'h1: case (PADDR[3:2])
                    2'd0: PRDATA = spi_ctrl;
                    2'd1: PRDATA = spi_status;
                    2'd2: PRDATA = spi_tx;
                    2'd3: PRDATA = spi_rx;
                endcase
                4'h2: case (PADDR[3:2])
                    2'd0: PRDATA = {24'b0,gpio_dir};
                    2'd1: PRDATA = {24'b0,gpio_out};
                    2'd2: PRDATA = {24'b0,gpio_in};
                    2'd3: PRDATA = gpio_irqmask;
                endcase
                4'h3: case (PADDR[3:2])
                    2'd0: PRDATA = timer_load;
                    2'd1: PRDATA = timer_count;
                    2'd2: PRDATA = timer_ctrl;
                    2'd3: PRDATA = timer_status;
                endcase
                4'h4: case (PADDR[3:2])
                    2'd0: PRDATA = pic_mask;
                    2'd1: PRDATA = pic_pend;
                    2'd2: PRDATA = pic_prio;
                endcase
            endcase
        end
    end
endmodule