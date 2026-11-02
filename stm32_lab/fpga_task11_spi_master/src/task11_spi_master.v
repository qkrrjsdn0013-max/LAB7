`timescale 1ns/1ps

// Board top: transmit one byte each second at 781.25 kHz SCK.
module task11_spi_master #(
    parameter integer INTERVAL_CYCLES = 50_000_000,
    parameter integer HALF_CYCLES = 32
) (
    input  wire clk_50mhz,
    input  wire rst_p,
    output wire spi_sck,
    output wire spi_mosi,
    output wire spi_cs_n
);
    localparam integer TIMER_W = (INTERVAL_CYCLES < 2) ? 1 : $clog2(INTERVAL_CYCLES);
    reg [TIMER_W-1:0] interval_count;
    reg [1:0] pattern_index;
    wire busy;
    wire done;
    wire start = (interval_count == INTERVAL_CYCLES - 1) && !busy;
    reg [7:0] tx_data;

    // The four patterns make bit order and all-zero/all-one cases visible.
    always @* begin
        case (pattern_index)
            2'd0: tx_data = 8'h55;
            2'd1: tx_data = 8'ha5;
            2'd2: tx_data = 8'h00;
            default: tx_data = 8'hff;
        endcase
    end

    always @(posedge clk_50mhz) begin
        if (rst_p) begin
            interval_count <= {TIMER_W{1'b0}};
            pattern_index  <= 2'd0;
        end else begin
            if (interval_count == INTERVAL_CYCLES - 1)
                interval_count <= {TIMER_W{1'b0}};
            else
                interval_count <= interval_count + 1'b1;
            if (start)
                pattern_index <= pattern_index + 2'd1;
        end
    end

    spi_master_tx #(.HALF_CYCLES(HALF_CYCLES)) u_master (
        .clk(clk_50mhz), .rst_p(rst_p),
        .start(start), .data_in(tx_data),
        .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_cs_n(spi_cs_n),
        .busy(busy), .done(done)
    );
endmodule
