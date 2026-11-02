# STM32_3 과제 12 — FPGA 간 SPI 송수신

과제 11의 FPGA 마스터 송신 코드와 과제 10의 FPGA 슬레이브 수신·UART 코드의 사본을 한 프로젝트에 모아 통합 시뮬레이션한다. 이 과제에는 새로운 MCU 코드가 없다.

## 역할과 파일

- FPGA A 송신: `src/task11_spi_master.v`, `src/spi_master_tx.v`, `constraints/master.xdc`
- FPGA B 수신·PC 출력: `src/task10_spi_uart.v`, `src/spi_slave_rx.v`, `src/uart.v`, `constraints/slave.xdc`
- 통합 테스트벤치: `sim/tb_task12_spi_link.sv`

두 FPGA 역할을 별도 보드에 적용할 때는 A에 `task11_spi_master`를 top으로 지정하고 `master.xdc`만 사용한다. B에는 `task10_spi_uart`를 top으로 지정하고 `slave.xdc`만 사용한다. 두 XDC를 한 Vivado 프로젝트에 동시에 적용하지 않는다. 실험실에서 역할을 교대할 때는 각 보드의 top·XDC·비트스트림을 바꾸고 연결 방향을 다시 확인한다.

## 실험 전 시뮬레이션

`FPGA.code-workspace`를 VS Code에서 열고 **Terminal → Run Task → 02 Simulate**를 선택한다. 이 작업은 실제 보드 연결 없이 FPGA A의 SPI 출력을 FPGA B의 입력에 연결한다. `55`, `A5`, `00`, `FF` 네 프레임의 8개 SCK 상승 에지, 수신 바이트, UART의 두 자리 16진수 문자·줄바꿈을 검사한다. 성공하면 `build/sim/run-.../simulation.log`에 PASS가 출력되고 `build/sim/wave.vcd`가 생성된다.

**03 Open waveform**으로 열어 `tb_task12_spi_link`의 `spi_cs_n`, `spi_sck`, `spi_mosi`, `uart_txd`; `fpga_a.u_master`의 `latched_data`, `bit_index`; `fpga_b`의 `rx_data`, `rx_valid`, `tx_data`, `tx_valid`를 확인한다. `rx_valid`가 1일 때 `rx_data`가 `55 → A5 → 00 → FF`인지 보고, UART 로그는 테스트벤치의 직렬 비트 디코딩 결과와 함께 확인한다. 파형의 송신 간격은 시뮬레이션 시간을 줄이기 위해 20 µs이며 실제 설계는 1초다.

로그와 파형 화면은 `../evidence/05_task12_fpga_to_fpga_spi/`에 보관한다. 실험 전에는 시뮬레이션 결과까지만 기록하고 실제 FPGA 두 대의 송수신 결과는 실험 후에 기록한다.

## 실험실 연결 계획

FPGA A BDIO00(F8, SCK) → FPGA B BDIO00(F8), BDIO01(E8, MOSI) → BDIO01(E8), BDIO02(A7, CS) → BDIO02(A7), GND → GND로 연결한다. B의 USB UART 출력은 F6이다. 핀 근거는 [BDIO 핀맵 XDC](https://github.com/Glaysia/ece2_26_2_2/blob/main/verilog/extras/uart_keypad/constraints/uart_keypad_test.xdc)와 [LAB3 UART XDC](https://github.com/Glaysia/ece2_26_2_2/blob/main/verilog/lab3/07_uart_echo/constraints/lab3_uart_echo.xdc)다.
