# Combo II-DLD S75. See README for source pin maps.
set_property PACKAGE_PIN B6 [get_ports clk_50mhz]
set_property PACKAGE_PIN K4 [get_ports rst_p]

# FPGA A BDIO00 -> FPGA B BDIO00 (SCK)
set_property PACKAGE_PIN F8 [get_ports spi_sck]
# FPGA A BDIO01 -> FPGA B BDIO01 (MOSI)
set_property PACKAGE_PIN E8 [get_ports spi_mosi]
# FPGA A BDIO02 -> FPGA B BDIO02 (CS)
set_property PACKAGE_PIN A7 [get_ports spi_cs_n]

set_property IOSTANDARD LVCMOS33 [get_ports {clk_50mhz rst_p spi_sck spi_mosi spi_cs_n}]
set_property DRIVE 8 [get_ports {spi_sck spi_mosi spi_cs_n}]
set_property SLEW SLOW [get_ports {spi_sck spi_mosi spi_cs_n}]
create_clock -name clk_50mhz -period 20.000 [get_ports clk_50mhz]
