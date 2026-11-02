`timescale 1ns/1ps

module tb_task10_spi_uart;
    localparam integer UART_DIV = 16;
    localparam integer UART_BIT_NS = UART_DIV * 20;

    reg clk_50mhz = 1'b0;
    always #10 clk_50mhz = ~clk_50mhz;
    reg rst_p = 1'b1;
    reg spi_sck = 1'b0;
    reg spi_mosi = 1'b0;
    reg spi_cs_n = 1'b1;
    wire uart_txd;
    integer rx_checks = 0;
    integer uart_checks = 0;
    integer j;
    reg [7:0] decoded_uart;
    reg [7:0] expected_spi [0:3];
    reg [7:0] expected_uart [0:15];

    task10_spi_uart #(.UART_DIV(UART_DIV)) dut (
        .clk_50mhz(clk_50mhz), .rst_p(rst_p),
        .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_cs_n(spi_cs_n),
        .uart_txd(uart_txd)
    );

    // 640 ns per half cycle gives an SPI SCK of 781.25 kHz.
    task spi_frame(input [7:0] value, input integer bits_to_send);
        integer bit_index;
        begin
            spi_sck = 1'b0;
            spi_cs_n = 1'b0;
            #200;
            for (bit_index = 7; bit_index > 7 - bits_to_send; bit_index = bit_index - 1) begin
                spi_mosi = value[bit_index];
                #640;
                spi_sck = 1'b1;
                #640;
                spi_sck = 1'b0;
            end
            #100;
            spi_cs_n = 1'b1;
            spi_mosi = 1'b0;
            #200;
        end
    endtask

    always @(posedge clk_50mhz) begin
        if (!rst_p && dut.rx_valid) begin
            if (rx_checks >= 4)
                $fatal(1, "Unexpected extra SPI byte %02X", dut.rx_data);
            if (dut.rx_data !== expected_spi[rx_checks])
                $fatal(1, "SPI byte %0d: expected %02X, got %02X",
                       rx_checks, expected_spi[rx_checks], dut.rx_data);
            rx_checks = rx_checks + 1;
        end
    end

    // Decode the actual UART TX wire, including start and stop bits.
    initial begin
        wait (!rst_p);
        while (uart_checks < 16) begin
            @(negedge uart_txd);
            #(UART_BIT_NS / 2);
            if (uart_txd !== 1'b0)
                $fatal(1, "UART start bit missing");
            for (j = 0; j < 8; j = j + 1) begin
                #UART_BIT_NS;
                decoded_uart[j] = uart_txd;
            end
            #UART_BIT_NS;
            if (uart_txd !== 1'b1)
                $fatal(1, "UART stop bit missing");
            if (decoded_uart !== expected_uart[uart_checks])
                $fatal(1, "UART char %0d: expected %02X, got %02X",
                       uart_checks, expected_uart[uart_checks], decoded_uart);
            uart_checks = uart_checks + 1;
        end
    end

    initial begin
        expected_spi[0] = 8'h55;
        expected_spi[1] = 8'ha5;
        expected_spi[2] = 8'h00;
        expected_spi[3] = 8'hff;
        // Text on the serial monitor should be: 55, A5, 00, FF.
        expected_uart[0]  = "5"; expected_uart[1]  = "5";
        expected_uart[2]  = 8'h0d; expected_uart[3]  = 8'h0a;
        expected_uart[4]  = "A"; expected_uart[5]  = "5";
        expected_uart[6]  = 8'h0d; expected_uart[7]  = 8'h0a;
        expected_uart[8]  = "0"; expected_uart[9]  = "0";
        expected_uart[10] = 8'h0d; expected_uart[11] = 8'h0a;
        expected_uart[12] = "F"; expected_uart[13] = "F";
        expected_uart[14] = 8'h0d; expected_uart[15] = 8'h0a;

        $dumpfile("wave.vcd");
        $dumpvars(0, tb_task10_spi_uart);
        #100;
        rst_p = 1'b0;
        #200;
        spi_frame(8'h55, 8);
        // A partial frame must be discarded when CS goes HIGH.
        spi_frame(8'hf0, 4);
        spi_frame(8'ha5, 8);
        spi_frame(8'h00, 8);
        spi_frame(8'hff, 8);
        wait (rx_checks == 4 && uart_checks == 16);
        #100;
        if (dut.overflow)
            $fatal(1, "UART FIFO overflow");
        $display("PASS task10: 4 SPI bytes, CS abort, UART hex output");
        $finish;
    end

    initial begin
        #250000;
        $fatal(1, "Timeout: SPI=%0d UART=%0d", rx_checks, uart_checks);
    end
endmodule
