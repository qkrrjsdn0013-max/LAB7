# Combo II-DLD S75 / 50 MHz clock / 3.3 V FPGA I/O.
# Pin sources:
# https://github.com/Glaysia/ece2_26_2_2/blob/main/verilog/lab3/07_uart_echo/constraints/lab3_uart_echo.xdc
# https://github.com/Glaysia/ece2_26_2_2/blob/main/verilog/extras/uart_keypad/constraints/uart_keypad_test.xdc

# Board clock, reset button, and USB UART TX to PC.
set_property PACKAGE_PIN B6 [get_ports clk_50mhz]
set_property PACKAGE_PIN K4 [get_ports rst_p]
set_property PACKAGE_PIN F6 [get_ports uart_txd]

# FPGA expansion connector: BDIO00, BDIO01, BDIO02.
# Connect MCU PB3 (SCK), PA7 (MOSI), PB6 (CS) respectively.
set_property PACKAGE_PIN F8 [get_ports spi_sck]
set_property PACKAGE_PIN E8 [get_ports spi_mosi]
set_property PACKAGE_PIN A7 [get_ports spi_cs_n]

set_property IOSTANDARD LVCMOS33 [get_ports {clk_50mhz rst_p uart_txd spi_sck spi_mosi spi_cs_n}]
set_property PULLUP true [get_ports spi_cs_n]
create_clock -name clk_50mhz -period 20.000 [get_ports clk_50mhz]
