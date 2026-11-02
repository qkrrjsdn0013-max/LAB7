# STM32_3 과제 10 — MCU에서 FPGA로 SPI 전송

이 프로젝트는 실험 전 검증용 FPGA 설계다. MCU는 과제 8의 SPI 마스터 송신 코드를 그대로 사용한다. FPGA는 SPI Mode 0으로 한 바이트를 받고, 받은 값을 `55\r\n`처럼 두 자리 16진수 텍스트로 UART에 보낸다. 실제 보드 연결과 수신 결과는 실험실에서 확인한다.

## 파일

- `src/spi_slave_rx.v`: CS가 LOW일 때 SCK 상승 에지 8개를 세어 MSB부터 수신한다. CS 해제 시 부분 프레임을 버린다.
- `src/uart.v`: LAB3의 `lab3_25_uart_echo/src/uart.v`에서 복사한 UART 송신·수신 모듈이다. 이번 설계는 `uart_tx`만 사용한다.
- `src/task10_spi_uart.v`: 수신값을 ASCII 16진수 두 글자와 CR/LF로 출력한다. 짧은 연속 입력을 위해 8바이트 FIFO를 둔다.
- `sim/tb_task10_spi_uart.sv`: `55`, `A5`, `00`, `FF`와 중간에 끊긴 프레임을 검사한다. UART TX의 실제 직렬 비트도 디코딩하여 비교한다.
- `constraints/task10_spi_uart.xdc`: Combo II-DLD S75 보드의 클록·리셋·USB UART 및 BDIO 확장 핀 배정. 논리 시뮬레이션에는 사용되지 않는다.

## 시뮬레이션 실행

`FPGA.code-workspace`를 VS Code에서 열고 **Terminal → Run Task → 02 Simulate**를 선택한다. 이 작업은 `simulation.json`에 적힌 파일만 컴파일하고 테스트벤치를 실행한다. 결과는 `build/sim` 아래에 생성된다. `simulation.log`의 PASS 문구와 `wave.vcd`의 `spi_cs_n`, `spi_sck`, `spi_mosi`, `dut.u_spi_rx.bit_count`, `dut.rx_data`, `dut.rx_valid`, `uart_txd`를 확인한다. 파형은 **03 Open waveform** 작업으로 열 수 있다.

테스트벤치는 시뮬레이션 시간을 줄이기 위해 UART 분주값을 16으로 바꾼다. 실제 FPGA 기본값은 50 MHz에서 9600 baud에 해당하는 5208이다. SPI 반주기는 640 ns로 두어 781.25 kHz를 모델링한다.

실행 후 로그·파형과 필요한 화면 캡처를 `../evidence/03_task10_mcu_to_fpga_spi/`에 보관한다. 시뮬레이션 PASS는 테스트벤치 조건의 기능 확인이며 실제 보드 동작 결과는 아니다.

VaporView에서는 왼쪽 VaporView 아이콘을 눌러 NETLIST를 열고, `tb_task10_spi_uart`의 `spi_cs_n`, `spi_sck`, `spi_mosi`를 더블 클릭한다. 이어서 `dut`의 `rx_data`, `rx_valid`, `tx_data`, `tx_valid`, `uart_txd`와 `dut.u_spi_rx`의 `bit_count`를 더블 클릭해 파형에 추가한다. `rx_data`와 `tx_data`는 16진수, `bit_count`는 10진수로 표시하면 읽기 쉽다. `Ctrl+0`으로 전체 시간을 맞춘 후 수신 구간으로 확대한다. `rx_valid`가 1인 네 지점의 `rx_data`는 순서대로 `55`, `A5`, `00`, `FF`여야 한다.

## 이후 보드 연결

실험 당일에는 MCU PB3(SCK) → FPGA BDIO00(F8), MCU PA7(MOSI) → FPGA BDIO01(E8), MCU PB6(CS) → FPGA BDIO02(A7), GND → GND로 연결한다. FPGA `uart_txd`는 보드의 USB UART 출력 F6에 배정했다. 이 배정은 저장소의 XDC 핀표를 따른 것이며, 실제 점퍼선을 꽂을 때 보드 커넥터의 BDIO00~02 표시를 확인한다.
