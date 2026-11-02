`timescale 1ns/1ps

// Report each received SPI byte as two ASCII hex digits followed by CR/LF.
module task10_spi_uart #(
    parameter integer UART_DIV = 5208
) (
    input  wire clk_50mhz,
    input  wire rst_p,
    input  wire spi_sck,
    input  wire spi_mosi,
    input  wire spi_cs_n,
    output wire uart_txd
);
    localparam integer FIFO_DEPTH = 8;
    wire [7:0] rx_data;
    wire rx_valid;
    spi_slave_rx u_spi_rx (
        .clk(clk_50mhz), .rst_p(rst_p),
        .spi_sck(spi_sck), .spi_mosi(spi_mosi), .spi_cs_n(spi_cs_n),
        .data(rx_data), .valid(rx_valid)
    );

    // The MCU sends once per second. This small FIFO also holds short TB bursts.
    reg [7:0] fifo [0:FIFO_DEPTH-1];
    reg [2:0] wr_ptr;
    reg [2:0] rd_ptr;
    reg [3:0] fifo_count;
    reg overflow;
    reg [7:0] current_byte;
    reg [1:0] char_index;
    reg [1:0] state;
    localparam [1:0] IDLE = 2'd0, SEND = 2'd1, WAIT_UART = 2'd2;

    wire tx_ready;
    wire tx_valid = (state == SEND) && tx_ready;
    reg [7:0] tx_data;
    wire fifo_pop = (state == IDLE) && (fifo_count != 0);
    wire fifo_push = rx_valid && ((fifo_count < FIFO_DEPTH) || fifo_pop);

    function [7:0] hex_ascii;
        input [3:0] nibble;
        begin
            if (nibble < 4'd10)
                hex_ascii = 8'h30 + nibble;
            else
                hex_ascii = 8'h41 + (nibble - 4'd10);
        end
    endfunction

    always @* begin
        case (char_index)
            2'd0: tx_data = hex_ascii(current_byte[7:4]);
            2'd1: tx_data = hex_ascii(current_byte[3:0]);
            2'd2: tx_data = 8'h0d;
            default: tx_data = 8'h0a;
        endcase
    end

    uart_tx #(.DIV(UART_DIV)) u_uart_tx (
        .clk(clk_50mhz), .rst_p(rst_p),
        .valid(tx_valid), .data(tx_data),
        .ready(tx_ready), .tx(uart_txd)
    );

    always @(posedge clk_50mhz) begin
        if (rst_p) begin
            wr_ptr       <= 3'd0;
            rd_ptr       <= 3'd0;
            fifo_count   <= 4'd0;
            overflow     <= 1'b0;
            current_byte <= 8'h00;
            char_index   <= 2'd0;
            state        <= IDLE;
        end else begin
            if (fifo_push) begin
                fifo[wr_ptr] <= rx_data;
                wr_ptr <= wr_ptr + 3'd1;
            end else if (rx_valid) begin
                overflow <= 1'b1;
            end
            if (fifo_pop) begin
                current_byte <= fifo[rd_ptr];
                rd_ptr <= rd_ptr + 3'd1;
            end
            case ({fifo_push, fifo_pop})
                2'b10: fifo_count <= fifo_count + 4'd1;
                2'b01: fifo_count <= fifo_count - 4'd1;
                default: fifo_count <= fifo_count;
            endcase

            case (state)
                IDLE: if (fifo_pop) begin
                    char_index <= 2'd0;
                    state <= SEND;
                end
                SEND: if (tx_ready)
                    state <= WAIT_UART;
                WAIT_UART: if (tx_ready) begin
                    if (char_index == 2'd3)
                        state <= IDLE;
                    else begin
                        char_index <= char_index + 2'd1;
                        state <= SEND;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
