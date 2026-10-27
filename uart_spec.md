# UART - Functional and Verification Specification

## Document Information

| Field | Value |
|---|---|
| Document ID | UART-SPEC-001 |
| Version | 1.3 |
| Date | 2026-10-28 |
| DUT | `uart` |
| Verification methodology | UVM / SystemVerilog |
| Status | Functional baseline; coverage targets agreed |

This document defines required behavior independently of the RTL implementation.

## 1. Purpose and Scope

Implement independent UART TX and RX paths with one synchronous FIFO per path.
Support 8N1 frames, LSB first, at nominal 9600 baud with a 12 MHz system clock.
Reuse the registered-read `fifo_sync` contract with 8 entries per FIFO.

Parity, runtime configuration, bus interfaces, interrupts, flow control, error
outputs, malformed-frame handling and quantified jitter/baud-mismatch tolerance
are outside scope. Internal FSM, storage and staging implementation are unrestricted.

## 2. Functional Block Diagram

TX path: host write interface -> TX FIFO -> transmitter -> serial TX output.
RX path: serial RX input -> synchronizer -> receiver -> RX FIFO -> host read interface.
A baud generator supplies a shared clock enable; all blocks use `clk_i`.

## 3. Parameters

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

## 4. Port Specification

| Signal | Direction | Width | Description |
|---|---|---:|---|
| `clk_i` | input | 1 | System clock |
| `_rst_i` | input | 1 | Synchronous active-low reset |
| `uartrx_i` | input | 1 | Asynchronous serial input; idle high |
| `rdrx_en_i` | input | 1 | Host RX FIFO read request |
| `uarttx_i` | input | 8 | Host TX write data |
| `wrtx_en_i` | input | 1 | Host TX FIFO write request |
| `uartrx_o` | output | 8 | Registered RX FIFO read data |
| `rx_notem_o` | output | 1 | RX FIFO occupancy greater than zero |
| `rxfull_o` | output | 1 | RX FIFO occupancy equals 8 |
| `uarttx_o` | output | 1 | Serial output; idle high |
| `txfull_o` | output | 1 | TX FIFO occupancy equals 8 |

Flags represent stored FIFO bytes, excluding active or staged serial data.
There are no external busy, read-valid or error outputs.

## 5. Clocking and Sampling Rules

- All state updates occur on `posedge clk_i`; baud enable is not a separate clock.
- Parallel inputs meet synchronous timing. Synchronize `uartrx_i` before RX
  detection and sampling; a two-register synchronizer is recommended.
- Acceptance uses inputs and flags immediately before the edge. Check registered
  outputs after nonblocking assignments settle. A held request is evaluated each edge.
- Consume a one-clock baud enable every 78 edges, first on the 78th non-reset
  edge. A combinational tick may rise in the preceding cycle.
- Each TX symbol lasts 16 tick intervals. A complete frame lasts 1.040 ms,
  excluding additional idle. A full high stop interval precedes the next start.
- RX targets bit centers with 16x sampling: approximately 8 ticks to start center,
  then 16 ticks between sample centers, accounting for synchronization delay.
- RX accepts valid back-to-back frames with no extra idle at nominal-9600 and
  matched-divider peer timing, across serial start phases. Maximum TX start
  latency, inter-frame idle and wider timing tolerance remain unspecified.

## 6. Reset Behavior

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

## 8. Write Operation

Host TX acceptance: `_rst_i && wrtx_en_i && !txfull_before`.
Append accepted data to the TX FIFO. Reject full writes without overwriting data.
Without reset, transmit each accepted byte exactly once, in order, automatically
and independently of subsequent host writes or changes on `uarttx_i`.

RX produces exactly one FIFO write request per completed valid frame, with a
stable byte at the enqueue edge. Accept only when RX FIFO was not full before
that edge; otherwise discard the new byte and preserve older data. If retained,
RX-done is a one-clock completion event. Malformed-input delivery/rejection is
unspecified and excluded from baseline sign-off.

## 9. Read Operation

Host RX acceptance: `_rst_i && rdrx_en_i && rx_notempty_before`.
Return the oldest byte on registered `uartrx_o` after the accepted edge.
An empty read removes nothing and sets the output to zero. Without a read,
the output holds unless reset applies.

TX dequeues only available FIFO data and must obtain the registered read result
before serialization; another register cannot capture the newly updated FIFO
output at the same edge. If retained, TX-done is a one-clock frame-completion
pulse, low during ordinary idle, and distinct from FIFO dequeue control.

## 10. Simultaneous Read and Write

TX and RX operate independently and concurrently. For either FIFO, reset wins;
otherwise evaluate both requests using that FIFO's pre-edge state:

| State before edge | Read + write result |
|---|---|
| Neither empty nor full | Both accepted; oldest byte returned; occupancy unchanged |
| Full | Read accepted; write rejected; occupancy decreases by one |
| Empty | Write accepted; read rejected; read output zero; occupancy increases by one |

A simultaneous read does not rescue a full write. On an empty RX collision,
the newly enqueued byte is available only for a later host read.

## 12. Verification Architecture Requirements

Use UVM with host and serial agents (sequencer, driver, monitor), a scoreboard
and a coverage subscriber. UVM sequences generate stimulus; monitors publish
observed transactions through analysis ports.

Monitor pre-edge acceptance and settled outputs. Serial stimulus and decoding
must be independent of the DUT and support back-to-back frames. Exact FIFO
transfer checks may observe FIFO ports, never internal memory, pointers or FSMs.

Require reset/timing/interface assertions and a watchdog per test; watchdog
limits are harness settings. Include simulation wire loopback and buffered echo
alongside independent TX/RX checks. Echo waits for registered RX data, holds
pending bytes while TX is full, and discards them on reset.

## 13. Functional Coverage Requirements

These are verification targets, not claims of implemented tests or coverage bins.

| Category | Required coverage intent |
|---|---|
| Data | All 256 byte values in TX and RX; include `00`, `FF`, `55`, `AA`, `A5` |
| Activity | Idle, TX only, RX only, concurrent TX/RX |
| FIFO boundaries | Empty/full hits and transitions; accepted/rejected operations |
| Simultaneous operations | Read/write at normal, full and empty states of each FIFO |
| Reset | Idle, start, data, stop and queued-data conditions |
| RX timing | Back-to-back frames, start-phase variation, both peer timing profiles |
| Integration | Wire loopback and buffered echo |

Exclude malformed-frame behavior and unassigned tolerance limits. Functional,
statement and branch coverage must each reach >= 90%. Review reports and justify
exclusions; an aggregate percentage does not waive required functional checks.

## 14. Scoreboard Requirements

- TX: queue accepted host writes; compare independent decoded TX bytes for
  data, ordering, loss, duplication and framing. Rejected writes add no entry.
- RX: derive expected bytes from valid serial traffic; model accepted FIFO
  enqueues and overflow discards; compare accepted registered host reads in order.
- Check empty reads return zero and idle read output holds. Rejected reads do
  not pop the model; rejected writes do not change its contents.
- Check FIFO flags against occupancy using observed FIFO port transfers:
  `count_after = count_before + write_accept - read_accept`.
  Keep TX FIFO occupancy separate from staged/active and completed TX frames.
- On reset, clear models and cancel comparisons for aborted data. Expected
  values must not come from DUT shift registers or memory.

## 15. Definition of Done

| Criterion | Requirement |
|---|---|
| Functional checks | All applicable implemented tests pass; no unexplained watchdog expiry |
| Scoreboard mismatches | 0 |
| Unexpected assertion failures | 0 |
| Functional coverage | >= 90%; report reviewed |
| Statement coverage | >= 90%; report reviewed |
| Branch coverage | >= 90%; report reviewed |
| Traceability | Each functional requirement mapped to a test, assertion or inspection |
| Verification report | Record revision, simulator, tests, seeds, results and justified exclusions |

Testcase IDs and the detailed testcase inventory will be added when implemented.
