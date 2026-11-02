`timescale 1ns/1ps

module tb_task12_spi_link;
    localparam integer UART_DIV = 16;
    localparam integer UART_BIT_NS = UART_DIV * 20;

    reg clk_50mhz = 1'b0;
    always #10 clk_50mhz = ~clk_50mhz;
    reg rst_p = 1'b1;
    wire spi_sck;
    wire spi_mosi;
    wire spi_cs_n;
    wire uart_txd;
    integer sck_edges = 0;
    integer frame_checks = 0;
    integer spi_checks = 0;
    integer uart_checks = 0;
    integer bit_index;
    reg [7:0] uart_byte;
    reg [7:0] expected_spi [0:3];
    reg [7:0] expected_uart [0:15];

    // FPGA A: task 11 master. FPGA B: task 10 slave and UART output.
    task11_spi_master #(.INTERVAL_CYCLES(1000), .HALF_CYCLES(32)) fpga_a (
        .clk_50mhz(clk_50mhz), .rst_p(rst_p),
        .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_cs_n(spi_cs_n)
    );
    task10_spi_uart #(.UART_DIV(UART_DIV)) fpga_b (
        .clk_50mhz(clk_50mhz), .rst_p(rst_p),
        .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_cs_n(spi_cs_n),
        .uart_txd(uart_txd)
    );

    always @(negedge spi_cs_n) begin
        if (!rst_p)
            sck_edges = 0;
    end

    always @(posedge spi_sck) begin
        if (!rst_p) begin
            if (spi_cs_n !== 1'b0)
                $fatal(1, "SCK rose while CS was inactive");
            sck_edges = sck_edges + 1;
        end
    end

    always @(posedge spi_cs_n) begin
        if (!rst_p) begin
            if (sck_edges != 8)
                $fatal(1, "Frame %0d had %0d SCK rising edges", frame_checks, sck_edges);
            frame_checks = frame_checks + 1;
        end
    end

    always @(posedge clk_50mhz) begin
        if (!rst_p && fpga_b.rx_valid) begin
            if (spi_checks >= 4)
                $fatal(1, "Unexpected extra SPI byte %02X", fpga_b.rx_data);
            if (fpga_b.rx_data !== expected_spi[spi_checks])
                $fatal(1, "SPI byte %0d: expected %02X, got %02X",
                       spi_checks, expected_spi[spi_checks], fpga_b.rx_data);
            spi_checks = spi_checks + 1;
        end
    end

    // Decode UART start, eight data bits, and stop from FPGA B's TX wire.
    initial begin
        wait (!rst_p);
        while (uart_checks < 16) begin
            @(negedge uart_txd);
            #(UART_BIT_NS / 2);
            if (uart_txd !== 1'b0)
                $fatal(1, "UART start bit missing");
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1) begin
                #UART_BIT_NS;
                uart_byte[bit_index] = uart_txd;
            end
            #UART_BIT_NS;
            if (uart_txd !== 1'b1)
                $fatal(1, "UART stop bit missing");
            if (uart_byte !== expected_uart[uart_checks])
                $fatal(1, "UART char %0d: expected %02X, got %02X",
                       uart_checks, expected_uart[uart_checks], uart_byte);
            uart_checks = uart_checks + 1;
        end
    end

    initial begin
        expected_spi[0] = 8'h55;
        expected_spi[1] = 8'ha5;
        expected_spi[2] = 8'h00;
        expected_spi[3] = 8'hff;
        expected_uart[0]  = "5"; expected_uart[1]  = "5";
        expected_uart[2]  = 8'h0d; expected_uart[3]  = 8'h0a;
        expected_uart[4]  = "A"; expected_uart[5]  = "5";
        expected_uart[6]  = 8'h0d; expected_uart[7]  = 8'h0a;
        expected_uart[8]  = "0"; expected_uart[9]  = "0";
        expected_uart[10] = 8'h0d; expected_uart[11] = 8'h0a;
        expected_uart[12] = "F"; expected_uart[13] = "F";
        expected_uart[14] = 8'h0d; expected_uart[15] = 8'h0a;

        $dumpfile("wave.vcd");
        $dumpvars(0, tb_task12_spi_link);
        #100;
        rst_p = 1'b0;
        wait (frame_checks == 4 && spi_checks == 4 && uart_checks == 16);
        #100;
        if (fpga_b.overflow)
            $fatal(1, "FPGA B UART FIFO overflow");
        $display("PASS task12: 4 FPGA-to-FPGA SPI frames and UART hex output");
        $finish;
    end

    initial begin
        #150000;
        $fatal(1, "Timeout: frames=%0d SPI=%0d UART=%0d",
               frame_checks, spi_checks, uart_checks);
    end
endmodule
