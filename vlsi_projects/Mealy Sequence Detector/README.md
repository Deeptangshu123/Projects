# Mealy Sequence Detector

This project implements a Mealy finite state machine (FSM) in Verilog to detect the binary sequence "1010". The detector asserts an output signal when the sequence is detected in the input bit stream.

## Overview

The sequence detector is designed as a Mealy machine, where the output depends on both the current state and the current input. This allows for potentially faster detection compared to a Moore machine, as the output can be asserted as soon as the sequence is completed without waiting for the next clock cycle.

## Design Details

### Inputs
- `i_clock`: Clock signal (positive edge triggered)
- `i_reset`: Asynchronous reset (active high)
- `i_btn`: Input bit stream (serial input)

### Outputs
- `o_led`: Sequence detection indicator (asserted high when "1010" is detected)

### State Machine
The FSM uses 5 states (requiring 3 bits) to track the progress through the sequence:

- **s0**: Initial state, waiting for first '1'
- **s1**: Received first '1', waiting for '0'
- **s2**: Received "10", waiting for '1'
- **s3**: Received "101", waiting for '0' (sequence completion)
- **s4**: Sequence "1010" detected (output asserted)

### State Transition Table
| Current State | Input = 0 | Input = 1 | Output |
|---------------|-----------|-----------|--------|
| s0            | s0        | s1        | 0      |
| s1            | s2        | s1        | 0      |
| s2            | s0        | s3        | 0      |
| s3            | s4        | s1        | 0      |
| s4            | s0        | s1        | 1      |

### Operation
1. On reset, the FSM returns to state s0.
2. On each clock cycle, the FSM transitions based on the current state and input bit:
   - s0: If input=1 → s1 (start of potential sequence), else remain in s0
   - s1: If input=0 → s2 (got "10"), else stay in s1 (waiting for first 0)
   - s2: If input=0 → s0 (reset, no match), else → s3 (got "101")
   - s3: If input=0 → s4 (sequence "1010" detected!), else → s1 (could be start of new sequence)
   - s4: If input=0 → s0 (reset after detection), else → s1 (start looking for new sequence)
3. The output `o_led` is asserted (high) only when the FSM is in state s4, indicating that the "1010" sequence has just been completed.

## Timing Behavior
As a Mealy machine, the output changes in response to inputs without waiting for the clock edge:
- The output goes high immediately when the FSM transitions to state s4 (upon receiving the fourth bit '0' in the sequence)
- The output goes low immediately when the FSM transitions out of state s4 (on the next clock cycle)

## Files

- `seq_1010.v`: Main Verilog implementation of the sequence detector
- `seq_1010_tb.v`: Original testbench for verifying the detector functionality
- `seq_1010_tb_enhanced.v`: Enhanced self-checking testbench with detailed reporting
- `seq_1010_tb_overlap.v`: Special testbench for testing overlapping sequences
- `seq_detect.xpr`: Vivado project file
- `seq_detect.hw`: Hardware implementation directory
- `seq_detect.sim`: Simulation directory

## Simulation

Multiple testbenches are provided to verify different aspects of the detector:

### Original Testbench (`seq_1010_tb.v`)
Applies a predefined bit stream to the detector and monitors the output. The test sequence includes multiple instances of "1010" to verify correct detection.

### Enhanced Testbench (`seq_1010_tb_enhanced.v`)
Features:
- Self-checking with expected outputs
- Clock synchronization for stimulus application
- Reset functionality testing
- Recovery testing after reset
- Waveform dumping for visualization

### Overlap Testbench (`seq_1010_tb_overlap.v`)
Specifically designed to test overlapping sequences like "101010" which should detect two consecutive "1010" sequences.

To run any simulation:
1. Open the Vivado project (`seq_detect.xpr`)
2. Set the desired testbench as the top module
3. Run the behavioral simulation
4. Observe the waveform and console output to verify correct behavior

## Waveform
<img width="1543" height="420" alt="Screenshot 2024-11-09 192030" src="https://github.com/user-attachments/assets/2146d535-5301-492f-853d-f9aad78205ae" />


The waveform shows the input bit stream (din), clock (clk), reset (rst), and output (dout). The output pulses high whenever the "1010" sequence is detected in the input.

## Implementation Notes

- The design uses synchronous resetting for the state register (though the reset is asynchronous in the sensitivity list, it's treated as synchronous due to the always@(posedge i_clock) block)
- Next-state logic is implemented in a combinational always block
- Output is driven by a continuous assignment based on the current state
- State parameters are defined using binary values for clarity and readability

## License

This project is provided as-is for educational purposes. See the LICENSE file for details.
