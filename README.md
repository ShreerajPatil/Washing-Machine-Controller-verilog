# Washing Machine Controller (Verilog FSM)

A synchronous Finite State Machine (FSM) implemented in Verilog HDL to control the wash cycle of an automated washing machine. The design was developed and verified as part of a semester project at CHARUSAT.

## Overview

The controller sequences the washing machine through six operational states — **IDLE → SOAK → WASH → DRAIN → RINSE → SPIN → IDLE** — with synchronous state transitions driven by a system clock, an asynchronous active-high reset, and a high-priority emergency stop path from any active state back to IDLE.

## FSM States

| State  | Encoding | Output Active | Transition Condition       | Next State |
|--------|----------|----------------|-----------------------------|------------|
| IDLE   | 3'b000   | idle = 1       | start && !stop               | SOAK       |
| SOAK   | 3'b001   | soak = 1       | t_soak                       | WASH       |
| WASH   | 3'b010   | wash = 1       | t_wash                       | DRAIN      |
| DRAIN  | 3'b011   | drain = 1      | t_drain && t_rinse           | RINSE      |
| RINSE  | 3'b100   | rinse, drain = 1 | t_spin && t_drain && !t_rinse | SPIN     |
| SPIN   | 3'b101   | spin = 1       | !t_spin && !t_drain && !t_rinse | IDLE     |

Any non-IDLE state transitions immediately to IDLE if `stop` is asserted.

## State Diagram

![FSM State Diagram](images/state-diagram.png)

## Files

- `Code.md` — FSM controller module (state register + next-state/output logic)
- `Testbench.md` — Verilog testbench simulating a full wash cycle and emergency stop
- `images/` — State diagram and simulation waveform

## Simulation

The testbench drives a 50 MHz clock (20 ns period) and steps the FSM through a complete wash cycle, then verifies the emergency stop path.

![Simulation Waveform](Images/Testbench.png)

**Verified behavior:**
- Full sequential cycle: IDLE → SOAK → WASH → DRAIN → RINSE → SPIN → IDLE
- Compound transition logic between DRAIN, RINSE, and SPIN
- Emergency stop overrides the cycle from any active state

## How to Run

Simulate using any Verilog simulator (e.g. Icarus Verilog):

```bash
iverilog -o wm_tb code.v test.v
vvp wm_tb
```

This generates a `wm_tb.vcd` waveform file, viewable in GTKWave.

## Future Enhancements

- Replace timer qualifier inputs with real counter/timer modules for time-based control
- Add a 7-segment display decoder for current-state readout
- Add ERROR and PAUSE states for fault handling and mid-cycle pause
- Compare binary vs. one-hot state encoding for power/area trade-offs

## Author

Shreeraj Patil — B.Tech Electronics & Communication Engineering, CHARUSAT
