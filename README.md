# UART RTL Design and UVM Verification

SystemVerilog UART with independent TX and RX paths, verified using UVM.
The design uses a 12 MHz system clock, nominal 9600 baud, 16x oversampling,
8N1 frames with LSB-first data, and synchronous active-low reset.
Each path includes an 8-byte FIFO with combinational read data.

The functional requirements are defined in [uart_spec.md](uart_spec.md).

## Testcases

| ID | Testcase | Scenario | Expected result |
|---|---|---|---|
| TC-01 | `tc_reset` | Synchronous reset with host read/write requests | Reset takes priority; outputs and flags reset; only the post-reset byte is transmitted |
| TC-02 | `tc_tx_one` | Transmit one byte; change input without another write | Transmit `55` once; the subsequent input value is not transmitted |
| TC-03 | `tc_tx_multi` | Transmit multiple bytes | Accepted bytes are transmitted exactly once and in order |
| TC-04 | `tc_tx_full` | Fill TX FIFO and attempt additional writes | Full writes are rejected; previously accepted bytes are preserved and transmitted |
| TC-05 | `tc_tx_reset` | Reset during START, DATA and STOP, including queued TX data | Aborted and queued data is discarded; new bytes transmit correctly after reset |
| TC-06 | `tc_rx_one` | Receive and read one byte | Host reads the transmitted serial byte correctly |
| TC-07 | `tc_rx_multi` | Receive several bytes before host reads | Host reads all expected bytes in arrival order |
| TC-08 | `tc_rx_empty` | Read RX while empty, before and after a valid transfer | Empty reads return zero; subsequent valid reception and reading still work |
| TC-09 | `tc_rx_full` | Receive eight bytes without reading | RX full asserts; all eight bytes can be read in order |
| TC-10 | `tc_rx_overflow` | Receive an extra byte while RX FIFO is full | The new byte is discarded; the eight older bytes remain intact |
| TC-11 | `tc_rx_reset` | Reset with queued RX data and during START, DATA and STOP | Old data and partial frames are discarded; new frames are received correctly |
| TC-12 | `tc_full_duplex` | Concurrent serial transmission and reception | Both directions preserve their independent byte values and ordering |
| TC-13 | `tc_host_simultaneous` | Host reads RX and writes TX at the same edge, with RX empty/nonempty and TX full/not-full | Each operation is accepted or rejected independently according to its pre-edge flags |
| TC-14 | `tc_rx_back_to_back` | Receive frames with no additional idle after the stop bit | Receive `A5`, `3C` and `7E` in order without loss |
| TC-15 | `tc_wire_loopback` | Forward serial TX to serial RX in the testbench | Transmit `A5` and read the same byte back from RX, with no extra byte |
| TC-16 | `tc_echo` | Host reads a received byte and writes that byte to TX | Receive and read `A5`, then transmit the same byte |
| TC-17 | `tc_data_all_values` | Exercise every byte value in both directions | TX and RX correctly transfer all values from `00` through `FF` |
| TC-18 | `tc_tx_random` | Random TX byte values, transfer count and host write gaps | Accepted bytes are transmitted correctly and in order, with no pending expected data at completion |
| TC-19 | `tc_rx_random` | Random valid RX data, transfer count and host read gaps | Received bytes are read correctly and in order, with no pending expected data at completion |
| TC-20 | `tc_mixed_random` | Random TX, RX, concurrent TX/RX and reset actions | Non-aborted data is preserved and ordered; reset cancels old data without unexpected output |
