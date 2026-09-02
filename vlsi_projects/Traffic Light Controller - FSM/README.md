# Traffic Light Controller FSM

This project implements a Moore finite state machine (FSM) in Verilog to control traffic lights for North-South (NS) and East-West (EW) directions based on vehicle detection on the EW approach.

## Overview

The traffic light controller manages traffic signals at an intersection using a synchronous Moore FSM. It prioritizes NS traffic flow while responding to EW vehicle detection, ensuring NS traffic gets a minimum green time before yielding to EW traffic.

As a Moore machine, the outputs depend only on the current state, providing glitch-free outputs that change synchronously with state transitions.

## Design Details

### Inputs
- `i_clk_100M`: Clock signal (100 MHz, positive edge triggered)
- `i_rst_p`: Asynchronous reset (active high)
- `i_EW_vd`: EW vehicle detection input (1 = vehicle present on EW approach)

### Outputs (active high)
- `o_NS_red`, `o_NS_yellow`, `o_NS_green`: NS traffic light signals
- `o_EW_red`, `o_EW_yellow`, `o_EW_green`: EW traffic light signals

### State Machine
The FSM uses 3 states (requiring 2 bits) to control the traffic light sequence:

- **ST_NSG** (2'b00): NS Green / EW Red
- **ST_YEL** (2'b01): NS Yellow / EW Yellow (transition state)
- **ST_EWG** (2'b10): EW Green / NS Red

### State Transition Table
| Current State | Condition                          | Next State | NS Lights         | EW Lights         |
|---------------|------------------------------------|------------|-------------------|-------------------|
| ST_NSG        | counter < 25 OR i_EW_vd = 0        | ST_NSG     | Green, Red, Red   | Red, Red, Green   |
| ST_NSG        | counter ≥ 25 AND i_EW_vd = 1       | ST_YEL     | Red, Yellow, Red  | Red, Yellow, Red  |
| ST_YEL        | counter < 5                        | ST_YEL     | Red, Yellow, Red  | Red, Yellow, Red  |
| ST_YEL        | counter ≥ 5 AND i_EW_vd = 1        | ST_EWG     | Red, Red, Green   | Green, Red, Red   |
| ST_YEL        | counter ≥ 5 AND i_EW_vd = 0        | ST_NSG     | Green, Red, Red   | Red, Red, Green   |
| ST_EWG        | counter < 25 AND i_EW_vd = 1       | ST_EWG     | Red, Red, Green   | Green, Red, Red   |
| ST_EWG        | counter ≥ 25 OR i_EW_vd = 0        | ST_YEL     | Red, Yellow, Red  | Red, Yellow, Red  |

### Operation
1. On reset (`i_rst_p = 1`), the FSM returns to state ST_NSG (NS Green/EW Red).
2. On each clock cycle (rising edge of `i_clk_100M`), the FSM transitions based on the current state, counter value, and EW vehicle detection:
   - ST_NSG: Remains NS green until 25 cycles AND EW vehicle detected, then goes to yellow
   - ST_YEL: Holds yellow for 5 cycles, then goes to EW green if EW vehicle still present, else returns to NS green
   - ST_EWG: Remains EW green while EW vehicle present AND less than 25 cycles, then goes to yellow
3. The outputs are determined solely by the current state (Moore machine):
   - NS Green  = (state == ST_NSG)
   - NS Yellow = (state == ST_YEL)
   - NS Red    = (state == ST_EWG)
   - EW Red    = (state == ST_NSG)
   - EW Yellow = (state == ST_YEL)
   - EW Green  = (state == ST_EWG)

### Timing Behavior
As a synchronous Moore machine with internal counter:
- State changes occur on the rising edge of `i_clk_100M`
- Outputs change synchronously with state changes (one clock delay after inputs)
- Minimum NS green time: 25 clock cycles
- Yellow duration: 5 clock cycles
- Maximum EW green time: 25 clock cycles (limited by counter or EW vehicle presence)
- Counter resets to 0 whenever state changes

## Files

- `tlc_fsm_top.v`: Main Verilog implementation of the traffic light controller FSM
- `tlc_fsm_tb.v`: Testbench for verifying the controller functionality with various vehicle detection scenarios
- `tlc_fsm.xpr`: Vivado project file
- `tlc_fsm.sim`: Simulation directory

## Simulation

To verify the traffic light controller functionality:
1. Open the Vivado project (`tlc_fsm.xpr`)
2. Set `tlc_fsm_top` as the top module
3. Run the behavioral simulation
4. Observe the waveform to verify correct behavior:
   - After reset: NS Green / EW Red
   - With EW vehicle detection: NS Green (≥25 cyc) → Yellow (5 cyc) → EW Green (while vehicles present, max 25 cyc) → Yellow (5 cyc) → NS Green
   - Without EW vehicles: NS Green held indefinitely

## Waveform

<img width="1562" height="777" alt="tlc_fsm" src="https://github.com/user-attachments/assets/33e2d433-a378-4d5d-8cf2-251bc4fe4699" />

Expected simulation waveform shows:
- Clock signal (`i_clk_100M`) running at 100 MHz
- Reset pulse (`i_rst_p`) initializing the FSM
- EW vehicle detection (`i_EW_vd`) triggering state transitions
- Traffic light outputs (`o_NS_*`, `o_EW_*`) changing synchronously with clock edges
- Correct sequencing: ST_NSG → ST_YEL → ST_EWG → ST_YEL → ST_NSG ...

## Implementation Notes

- The design uses a synchronous reset (active high) though treated as synchronous due to the always@(posedge i_clk_100M) block
- Next-state logic and output logic are implemented in separate always blocks for clarity
- Internal 6-bit counter tracks time-in-state for green/yellow timing control
- State parameters are defined using binary values for clarity and readability
- Designed as an educational demonstration of FSM-based traffic control systems

## License

This project is provided as-is for educational purposes.
