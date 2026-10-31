# UART - Functional and Verification Specification

## Document Information

| Field | Value |
|---|---|
| Document ID | UART-SPEC-001 |
| DUT | `uart` |
| Verification methodology | UVM / SystemVerilog |
| Status | Functional baseline; coverage targets agreed |

This document defines required behavior independently of the RTL implementation.

## 1. Purpose and Scope

Implement independent UART TX and RX paths with one synchronous FIFO per path.
Support 8N1 frames, LSB first, at nominal 9600 baud with a 12 MHz system clock.
Use two single-clock `fifo_sync` instances with asynchronous (combinational)
read outputs and 8 entries per FIFO. Writes, pointers and occupancy update on
the rising clock edge.

Parity, runtime configuration, bus interfaces, interrupts, flow control, error
outputs, malformed-frame handling and quantified jitter/baud-mismatch tolerance
are outside scope. Internal FSM, storage and staging implementation are unrestricted.

## 2. Parameters

Baseline values below do not require arbitrary parameter support or new ports.

| Item | Value | Description |
|---|---:|---|
| System clock | 12 MHz | Common system clock |
| `DATA_WIDTH` | 8 | FIFO entry width and UART data bits |
| `DEPTH` | 8 | Stored entries in each FIFO |
| `BAUDTICK` | 78 | System-clock cycles per baud enable |
| Oversampling | 16 | Enables per serial bit |
| Frame format | 8N1 | One low start, eight data, one high stop bit |
| Nominal peer baud | 9600 bit/s | Peer bit duration approximately 104.166667 us |
| Actual TX baud | 9615.384615 bit/s | 12 MHz / (78 x 16); error approximately +0.160256% |
| TX bit duration | 104 us | Exactly 1248 system-clock cycles |

## 3. Port Specification

| Signal | Direction | Width | Description |
|---|---|---:|---|
| `clk_i` | input | 1 | System clock |
| `_rst_i` | input | 1 | Synchronous active-low reset |
| `uartrx_i` | input | 1 | Asynchronous serial input; idle high |
| `rdrx_en_i` | input | 1 | Host RX FIFO read request |
| `uarttx_i` | input | 8 | Host TX write data |
| `wrtx_en_i` | input | 1 | Host TX FIFO write request |
| `uartrx_o` | output | 8 | Combinational RX FIFO read data; oldest byte when `rdrx_en_i && rx_notem_o`, otherwise zero |
| `rx_notem_o` | output | 1 | RX FIFO occupancy greater than zero |
| `rxfull_o` | output | 1 | RX FIFO occupancy equals 8 |
| `uarttx_o` | output | 1 | Serial output; idle high |
| `txfull_o` | output | 1 | TX FIFO occupancy equals 8 |

Flags represent stored FIFO bytes, excluding active or staged serial data.
There are no external busy, read-valid or error outputs.
Each internal FIFO exposes `not_empty=1` when its occupancy is greater than zero;
the RX instance connects this flag to `rx_notem_o`.

## 4. Clocking and Sampling Rules

- All UART blocks use `clk_i`; stored state updates on the rising edge.
- Baud tick is a clock enable generated every 78 system-clock cycles.
  Each UART bit spans 16 tick intervals.
- Synchronize the serial RX input before processing; RX samples at bit centers.
- FIFO reads are combinational; writes and pointer updates occur on the rising edge.
- In the testbench, sample FIFO read data and transfer acceptance before state
  updates; check reset results and status flags after updates settle.

## 5. Reset Behavior

When `_rst_i=0` at a rising edge, reset takes priority over all transfers.

| Element | Required result after reset edge |
|---|---|
| Serial TX | `uarttx_o=1`; partial frame aborted |
| TX/RX controllers | Idle; partial, active and staged data discarded |
| TX FIFO | Empty; `txfull_o=0` |
| RX FIFO | Empty; `rx_notem_o=0`, `rxfull_o=0` |
| RX read data | `uartrx_o=0` |
| Baud generator | Phase reset; tick low after the edge |
| Completion events | Cleared; reset generates no completion |

Reset acts only at rising edges; supply at least one reset edge before use.
Logical invalidation is sufficient; memory clearing is unnecessary. Pre-reset
data must not reappear. Restore serial idle before a fresh frame after reset;
recovery of a frame overlapping reset is unspecified.

## 6. Write Operation

Host TX acceptance: `_rst_i && wrtx_en_i && !txfull_before`.
Append accepted data to the TX FIFO. Reject full writes without overwriting data.
Without reset, transmit each accepted byte exactly once, in order, automatically
and independently of subsequent host writes or changes on `uarttx_i`.

RX produces exactly one FIFO write request per completed valid frame, with a
stable byte at the enqueue edge. Accept only when RX FIFO was not full before
that edge; otherwise discard the new byte and preserve older data. If retained,
RX-done is a one-clock completion event. Malformed-input delivery/rejection is
unspecified and excluded from baseline sign-off.

## 7. Read Operation

Host RX acceptance: `_rst_i && rdrx_en_i && rx_notempty_before`.
Here `rx_notempty_before` is the pre-edge value of `rx_notem_o`.

When `rdrx_en_i && rx_notem_o`, `uartrx_o` presents the oldest stored byte
combinationally before the read edge. An accepted read removes that byte at the
rising edge. Afterwards, the output reflects the updated FIFO state and read
request: the next oldest byte if both remain valid, otherwise zero.

When no read is requested or the FIFO is empty, `uartrx_o=0`; it does not retain
the previous read result. An empty read removes no entry. Reset has priority
over accepting transfers, as defined in Section 5.

TX dequeues only available FIFO data. It may capture valid combinational FIFO
read data at the same edge that accepts the dequeue, provided the data is stable
before that edge. If retained, TX-done is a one-clock frame-completion
pulse, low during ordinary idle, and distinct from FIFO dequeue control.

## 8. Simultaneous Read and Write

TX and RX operate independently and concurrently. For either FIFO, reset wins;
otherwise evaluate both requests using that FIFO's pre-edge state:

| State before edge | Read + write result |
|---|---|
| Neither empty nor full | Both accepted; oldest byte returned; occupancy unchanged |
| Full | Read accepted; write rejected; occupancy decreases by one |
| Empty | Write accepted; read rejected; pre-edge read output zero; occupancy increases by one |

A simultaneous read does not rescue a full write. On an empty RX collision,
the newly enqueued byte may become visible after the write if the read request
remains asserted, but it is removed only by a later accepted host read.

## 9. Verification Architecture Requirements

Use UVM with host and serial agents (sequencer, driver, monitor), a scoreboard
and a coverage subscriber. UVM sequences generate stimulus; monitors publish
observed transactions through analysis ports.

Monitor pre-edge acceptance and FIFO read data, and post-update reset results
and status. Serial stimulus and decoding
must be independent of the DUT and support back-to-back frames. Exact FIFO
transfer checks may observe FIFO ports, never internal memory, pointers or FSMs.

Verification checks correct byte values and ordering, loss and duplication,
FIFO full-write rejection and empty-read rejection, reset clearing and frame
abortion, consecutive frames, and concurrent TX/RX. Dedicated timing tests and
assertions measuring baud-tick intervals, bit/frame durations or serial start
phase variation are outside the verification scope.

Require reset and interface assertions and a watchdog per test; watchdog
limits are harness settings. Include simulation wire loopback and buffered echo
alongside independent TX/RX checks. Echo captures valid combinational RX data
at an accepted read edge, holds pending bytes while TX is full, and discards
them on reset.

## 10. Functional Coverage Requirements

These are verification targets, not claims of implemented tests or coverage bins.

| Category | Required coverage intent |
|---|---|
| Data | All 256 byte values in TX and RX; include `00`, `FF`, `55`, `AA`, `A5` |
| Activity | Idle, TX only, RX only, concurrent TX/RX |
| FIFO boundaries | Empty/full hits and transitions; accepted/rejected operations |
| Simultaneous operations | Read/write at normal, full and empty states of each FIFO |
| Reset | Idle, start, data, stop and queued-data conditions |
| Consecutive frames | Valid back-to-back frames received without data loss or duplication |
| Integration | Wire loopback and buffered echo |

Exclude malformed-frame behavior and unassigned tolerance limits. Functional,
statement and branch coverage must each reach >= 90%. Review reports and justify
exclusions; an aggregate percentage does not waive required functional checks.

## 11. Scoreboard Requirements

- TX: queue accepted host writes; compare independent decoded TX bytes for
  data, ordering, loss, duplication and framing. Rejected writes add no entry.
- RX: derive expected bytes from valid serial traffic; model accepted FIFO
  enqueues and overflow discards; compare accepted host read data sampled before
  pointer updates, in order.
- Check read output is zero when the FIFO is empty or no read is requested.
  Rejected reads do
  not pop the model; rejected writes do not change its contents.
- Check FIFO flags against occupancy using observed FIFO port transfers:
  `count_after = count_before + write_accept - read_accept`.
  Keep TX FIFO occupancy separate from staged/active and completed TX frames.
- On reset, clear models and cancel comparisons for aborted data. Expected
  values must not come from DUT shift registers or memory.

## 12. Definition of Done

| Criterion | Requirement |
|---|---|
| Functional checks | All applicable implemented tests pass; no unexplained watchdog expiry |
| Scoreboard mismatches | 0 |
| Unexpected assertion failures | 0 |
| Functional coverage | >= 90%; report reviewed |
| Statement coverage | >= 90%; report reviewed |
| Branch coverage | >= 90%; report reviewed |
| Traceability | Each functional requirement mapped to a test, assertion or inspection |
| Verification report | Record simulator, tests, seeds, results and justified exclusions |

Testcase IDs and the detailed testcase inventory will be added when implemented.
