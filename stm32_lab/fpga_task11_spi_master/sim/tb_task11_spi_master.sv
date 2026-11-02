`timescale 1ns/1ps

module tb_task11_spi_master;
    localparam integer INTERVAL_CYCLES = 1000;
    localparam integer HALF_CYCLES = 32;
    localparam integer CLK_PERIOD_NS = 20;
    localparam integer HALF_NS = HALF_CYCLES * CLK_PERIOD_NS;
    localparam integer FRAME_INTERVAL_NS = INTERVAL_CYCLES * CLK_PERIOD_NS;

    reg clk_50mhz = 1'b0;
    always #10 clk_50mhz = ~clk_50mhz;
    reg rst_p = 1'b1;
    wire spi_sck;
    wire spi_mosi;
    wire spi_cs_n;
    reg [7:0] expected [0:3];
    integer frame_index;
    integer bit_index;
    integer frame_checks = 0;
    time frame_start;
    time previous_start = 0;
    time previous_fall;
    time rise_time;

    task11_spi_master #(
        .INTERVAL_CYCLES(INTERVAL_CYCLES),
        .HALF_CYCLES(HALF_CYCLES)
    ) dut (
        .clk_50mhz(clk_50mhz), .rst_p(rst_p),
        .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_cs_n(spi_cs_n)
    );

    initial begin
        expected[0] = 8'h55;
        expected[1] = 8'ha5;
        expected[2] = 8'h00;
        expected[3] = 8'hff;
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_task11_spi_master);
        #100;
        rst_p = 1'b0;

        for (frame_index = 0; frame_index < 4; frame_index = frame_index + 1) begin
            @(negedge spi_cs_n);
            frame_start = $time;
            #1;
            if (spi_sck !== 1'b0 || spi_mosi !== expected[frame_index][7])
                $fatal(1, "Frame %0d: first bit not ready before SCK rises", frame_index);
            if (frame_index > 0 && frame_start - previous_start != FRAME_INTERVAL_NS)
                $fatal(1, "Frame interval: expected %0d ns, got %0t ns",
                       FRAME_INTERVAL_NS, frame_start - previous_start);
            previous_start = frame_start;

            for (bit_index = 7; bit_index >= 0; bit_index = bit_index - 1) begin
                @(posedge spi_sck);
                rise_time = $time;
                if (spi_cs_n !== 1'b0 || spi_mosi !== expected[frame_index][bit_index])
                    $fatal(1, "Frame %0d bit %0d: expected %b, got %b",
                           frame_index, bit_index, expected[frame_index][bit_index], spi_mosi);
                if (bit_index == 7) begin
                    if (rise_time - frame_start != HALF_NS)
                        $fatal(1, "First bit setup time mismatch");
                end else if (rise_time - previous_fall != HALF_NS) begin
                    $fatal(1, "SCK LOW duration mismatch");
                end

                @(negedge spi_sck);
                previous_fall = $time;
                if (previous_fall - rise_time != HALF_NS)
                    $fatal(1, "SCK HIGH duration mismatch");
                #1;
                if (bit_index > 0 && spi_mosi !== expected[frame_index][bit_index - 1])
                    $fatal(1, "MOSI did not prepare next bit on SCK falling edge");
            end

            @(posedge spi_cs_n);
            #1;
            if (spi_sck !== 1'b0 || !dut.done)
                $fatal(1, "CS released before final falling edge/hold time");
            frame_checks = frame_checks + 1;
        end

        $display("PASS task11: 4 SPI frames, 1 MHz limit, Mode 0 timing, 1-second interval setting");
        $finish;
    end

    initial begin
        #110000;
        $fatal(1, "Timeout after %0d completed frames", frame_checks);
    end
endmodule
