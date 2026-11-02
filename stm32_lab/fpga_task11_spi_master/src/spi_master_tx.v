`timescale 1ns/1ps

// One-byte SPI Mode 0 master. SCK idles LOW and data is MSB first.
module spi_master_tx #(
    parameter integer HALF_CYCLES = 32
) (
    input  wire       clk,
    input  wire       rst_p,
    input  wire       start,
    input  wire [7:0] data_in,
    output reg        spi_sck,
    output reg        spi_mosi,
    output reg        spi_cs_n,
    output wire       busy,
    output reg        done
);
    localparam integer HALF_W = (HALF_CYCLES < 2) ? 1 : $clog2(HALF_CYCLES);
    localparam [1:0] IDLE = 2'd0, LOW_HALF = 2'd1,
                     HIGH_HALF = 2'd2, END_HOLD = 2'd3;
    reg [1:0] state;
    reg [HALF_W-1:0] half_count;
    reg [2:0] bit_index;
    reg [7:0] latched_data;

    assign busy = (state != IDLE);

    always @(posedge clk) begin
        if (rst_p) begin
            spi_sck      <= 1'b0;
            spi_mosi     <= 1'b0;
            spi_cs_n     <= 1'b1;
            done         <= 1'b0;
            state        <= IDLE;
            half_count   <= {HALF_W{1'b0}};
            bit_index    <= 3'd7;
            latched_data <= 8'h00;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    spi_sck  <= 1'b0;
                    spi_cs_n <= 1'b1;
                    if (start) begin
                        latched_data <= data_in;
                        bit_index    <= 3'd7;
                        spi_mosi     <= data_in[7]; // Ready before the first rising edge.
                        spi_cs_n     <= 1'b0;
                        half_count   <= {HALF_W{1'b0}};
                        state        <= LOW_HALF;
                    end
                end
                LOW_HALF: begin
                    if (half_count == HALF_CYCLES - 1) begin
                        half_count <= {HALF_W{1'b0}};
                        spi_sck    <= 1'b1;
                        state      <= HIGH_HALF;
                    end else begin
                        half_count <= half_count + 1'b1;
                    end
                end
                HIGH_HALF: begin
                    if (half_count == HALF_CYCLES - 1) begin
                        half_count <= {HALF_W{1'b0}};
                        spi_sck    <= 1'b0;
                        if (bit_index == 3'd0) begin
                            state <= END_HOLD;
                        end else begin
                            bit_index <= bit_index - 3'd1;
                            spi_mosi  <= latched_data[bit_index - 3'd1];
                            state     <= LOW_HALF;
                        end
                    end else begin
                        half_count <= half_count + 1'b1;
                    end
                end
                END_HOLD: begin
                    if (half_count == HALF_CYCLES - 1) begin
                        half_count <= {HALF_W{1'b0}};
                        spi_cs_n   <= 1'b1;
                        spi_mosi   <= 1'b0;
                        done       <= 1'b1;
                        state      <= IDLE;
                    end else begin
                        half_count <= half_count + 1'b1;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
