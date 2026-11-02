# STM32_3 과제 11 — FPGA에서 MCU로 SPI 송신

실험 전 범위는 MCU 슬레이브 코드 Build와 FPGA 기능 시뮬레이션이다. 실제 배선·오실로스코프·MCU 수신 출력은 실험실에서 확인한다.

## 설계

- `src/spi_master_tx.v`: SPI Mode 0의 한 바이트 송신 회로. CS를 LOW로 내릴 때 첫 비트를 준비하고, 8개의 SCK 상승 에지에서 비트를 전달한다. 다음 비트는 SCK 하강 에지에서 준비한다.
- `src/task11_spi_master.v`: 50 MHz 입력 클록에서 1초 간격으로 송신을 시작한다. 기본 SCK는 50 MHz / (2 × 32) = 781.25 kHz이다. 전송값은 `55 → A5 → 00 → FF` 순서로 반복된다.
- `sim/tb_task11_spi_master.sv`: 네 프레임의 CS·SCK·MOSI 순서, 8비트 MSB 우선, SCK 반주기 및 전송 간격을 검사한다.
- `constraints/task11_spi_master.xdc`: FPGA 출력 핀 배정. 기능 시뮬레이션에는 사용하지 않는다.

## 시뮬레이션

`FPGA.code-workspace`를 VS Code에서 열고 **Terminal → Run Task → 02 Simulate**를 선택한다. 실험용 테스트벤치는 전송 간격만 1000 FPGA 클록(20 µs)으로 줄인다. SCK 반주기는 실제 설계와 같은 32 FPGA 클록(640 ns)으로 유지한다. 성공하면 `build/sim/run-.../simulation.log`에 PASS가 출력되고 `build/sim/wave.vcd`가 생성된다. **03 Open waveform** 작업으로 파형을 열 수 있다.

VaporView에서 `tb_task11_spi_master`의 `spi_cs_n`, `spi_sck`, `spi_mosi`, `dut`의 `start`, `done`, `dut.u_master`의 `latched_data`, `bit_index`, `state`를 추가한다. CS가 LOW인 동안 SCK 상승 에지 8개가 발생하며 MOSI가 `55`, `A5`, `00`, `FF`의 MSB부터 순서대로 나타나는지 확인한다. 현재 프레임의 값은 `latched_data`로 읽는다. `dut.tx_data`는 프레임 시작 직후 다음 송신값으로 바뀐다. 로그·파형 화면은 `../evidence/04_task11_fpga_to_mcu_spi/`에 보관한다.

## 보드 연결에 사용할 핀

| FPGA 신호 | 보드 표기 / PACKAGE_PIN | MCU 슬레이브 핀 |
|---|---|---|
| `spi_sck` | BDIO00 / F8 | PB3 · SPI1 SCK |
| `spi_mosi` | BDIO01 / E8 | PA7 · SPI1 MOSI |
| `spi_cs_n` | BDIO02 / A7 | PA4 · SPI1 NSS |
| GND | 보드 GND | MCU GND |

클록 B6, 리셋 K4는 보드 내부 신호다. 핀은 [LAB3 UART XDC](https://github.com/Glaysia/ece2_26_2_2/blob/main/verilog/lab3/07_uart_echo/constraints/lab3_uart_echo.xdc)와 [BDIO 핀맵 XDC](https://github.com/Glaysia/ece2_26_2_2/blob/main/verilog/extras/uart_keypad/constraints/uart_keypad_test.xdc)를 근거로 했다. 실제 연결 시 보드의 BDIO00~02 표기를 확인한다.
