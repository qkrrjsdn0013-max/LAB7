`timescale 1ns/1ps

// SPI Mode 0 slave receiver. External pins are sampled by the 50 MHz FPGA clock.
module spi_slave_rx (
    input  wire       clk,
    input  wire       rst_p,
    input  wire       spi_sck,
    input  wire       spi_mosi,
    input  wire       spi_cs_n,
    output reg  [7:0] data,
    output reg        valid
);
    (* ASYNC_REG = "TRUE" *) reg [1:0] sck_sync;
    (* ASYNC_REG = "TRUE" *) reg [1:0] mosi_sync;
    (* ASYNC_REG = "TRUE" *) reg [1:0] cs_sync;
    reg sck_prev;
    reg [7:0] shift;
    reg [2:0] bit_count;

    always @(posedge clk) begin
        if (rst_p) begin
            sck_sync  <= 2'b00;
            mosi_sync <= 2'b00;
            cs_sync   <= 2'b11;
            sck_prev  <= 1'b0;
            shift     <= 8'h00;
            bit_count <= 3'd0;
            data      <= 8'h00;
            valid     <= 1'b0;
        end else begin
            sck_sync  <= {sck_sync[0], spi_sck};
            mosi_sync <= {mosi_sync[0], spi_mosi};
            cs_sync   <= {cs_sync[0], spi_cs_n};
            sck_prev  <= sck_sync[1];
            valid     <= 1'b0;

            if (cs_sync[1]) begin
                shift     <= 8'h00;
                bit_count <= 3'd0;
            end else if (sck_sync[1] && !sck_prev) begin
                shift <= {shift[6:0], mosi_sync[1]};
                if (bit_count == 3'd7) begin
                    data      <= {shift[6:0], mosi_sync[1]};
                    valid     <= 1'b1;
                    bit_count <= 3'd0;
                end else begin
                    bit_count <= bit_count + 3'd1;
                end
            end
        end
    end
endmodule
