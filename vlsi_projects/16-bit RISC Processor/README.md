# 16-Bit Processor

A multi-cycle 16-bit RISC-style processor written in Verilog, developed and simulated in Vivado 2024.1.2. Target board: Numato Mimas A7 Mini (Artix-7 `xc7a35tftg256-1`).

## Architecture

- 16-bit data path and instruction word, 8 general-purpose registers (R0-R7)
- 6-state one-hot FSM (fetch → decode → reg read → ALU → reg write → PC update)
- Control FSM on `posedge clk`; data path (PC, RAM, decoder, regfile, ALU) on `negedge clk`
- Branch resolved in the ALU (`O_shldBranch`); target is the ALU result, loaded into the PC

### Modules

| Module | File | Function |
|---|---|---|
| `ctrl_unit` | `rtl/ctrl_unit.v` | One-hot state machine; generates `enfetch/endec/enrgrd/enalu/enrgwr/enmem` |
| `pc_unit` | `rtl/pc_unit.v` | Program counter: `00` hold, `01` increment, `10` load, `11` clear |
| `fake_ram` | `rtl/fake_ram.v` | 9-word behavioural memory preloaded with a test program |
| `inst_dec` | `rtl/inst_dec.v` | Splits instruction into opcode, register selects, immediate; derives reg-write enable |
| `reg_file` | `rtl/reg_file.v` | 8 × 16-bit registers, two read ports, one write port |
| `alu` | `rtl/alu.v` | Arithmetic, logic, shift, compare, jump-target/branch-condition generation |

### Control sequence

| State | Enable | Action |
|---|---|---|
| S0 | `enfetch` | Instruction fetched from RAM at PC |
| S1 | `endec` | Instruction decoded |
| S2 | `enrgrd` | Operands A, B read from register file |
| S3 | `enalu` | ALU executes |
| S4 | `enrgrd` + `enrgwr` | Result written back (if `regwe`) |
| S5 | `enmem` | PC incremented (or loaded if branch taken) |

## Instruction format

```
15      11 10    8 7     5 4     2 1 0
+---------+-------+-------+-------+---+
|  aluop  | selA  | selB  | selD  | - |
+---------+-------+-------+-------+---+
                  \_______ imm[7:0] ___/   (overlaps selB/selD)
```

`aluop[4:1]` selects the operation, `aluop[0]` (LSB) is a modifier.

| aluop[4:1] | Mnemonic | Operation | LSB = 1 |
|---|---|---|---|
| 0 | ADD | `A + B` | signed |
| 1 | SUB | `A - B` | signed |
| 2 | OR | `A \| B` | - |
| 3 | AND | `A & B` | - |
| 4 | XOR | `A ^ B` | - |
| 5 | NOT | `~A` | - |
| 8 | LOAD | `{8'h00, imm}` | `{imm, 8'h00}` |
| 9 | CMP | flag vector (below) | signed compare |
| 10 | SHL | `A << B[3:0]` | - |
| 11 | SHR | `A >> B[3:0]` | - |
| 12 | JMPA | PC ← `imm` | PC ← `A` |
| 13 | JMPR | PC ← `A`, if `B[{lsb, imm[1:0]}]` | selects flag bits 4-7 |

**CMP result bits:** `[0]` A==B, `[1]` A==0, `[2]` B==0, `[3]` A>B, `[4]` A<B.

Register write is disabled for opcode groups `0111`, `1100` (JMPA), `1101` (JMPR).

## Repository layout

```
.
├── rtl/
│   ├── alu.v
│   ├── ctrl_unit.v
│   ├── fake_ram.v
│   ├── inst_dec.v
│   ├── pc_unit.v
│   └── reg_file.v
├── tb/
│   ├── main_test.v            # full-system testbench (top)
│   ├── regfile_unittest.v     # reg_file unit test
│   └── decoder_unitests.v     # inst_dec unit test
├── docs/
│   └── waveforms/             # simulation screenshots
├── docs/
│   └── waveforms/             # XSim screenshots used in this README
├── vivado/
│   └── 16-Bit_Processor.xpr   # Vivado project (sources referenced from ../rtl, ../tb)
├── .gitignore
└── README.md
```

## Build / simulate

Requires Vivado 2024.1.x.

1. Open `vivado/16-Bit_Processor.xpr`.
2. **Flow Navigator → Simulation → Run Simulation → Run Behavioral Simulation**.

Default simulation top is `main_test`; set `regfile_unittest` or `decoder_unittests` as top for unit-level runs. Generated directories (`.cache`, `.hw`, `.sim`, `.ip_user_files`, `.runs`) are git-ignored and recreated by Vivado.

### Testbench notes

- `main_test` holds `reset` high for 20 ns, then releases it; the preloaded program in `fake_ram` begins executing from address 0.
- Reg-file write enable is gated externally: `enrgwr = regwe & update`.
- PC opcode in `main_test`: `reset → 11`, `shldBranch → 10`, `enmem → 01`, else `00`.

## Simulation results

### Full system (`main_test`, 0-1000 ns)

![main_test waveform](docs/waveforms/main_test.png)

Reset is held for the first 20 ns (`opcode = 11`, PC cleared). The PC then steps `0000 → 0006`, fetching `80fe`, `89ed`, `2220`, `8301`, `8401`, `0370`, `c004`. `c004` is `JMPA` with `imm = 04`: `shldBranch` asserts, `dataD = 0004` is loaded into the PC (`opcode = 10`), and execution loops `0004 → 0005 → 0006 → 0004` for the rest of the run. The `enfetch/endec/enrgrd/enalu/enrgwr/enmem` strobes show the six-state sequence repeating once per instruction.

### Instruction decoder (`decoder_unittests`)

![decoder waveform](docs/waveforms/decoder_unittest.png)

With `I_Inst = 0x1704`, outputs update on the falling clock edge once `I_En` is high: `aluop = 02`, `selA = 7`, `selB = 0`, `selD = 1`, `imm = 0004`, `regwe = 1`.

### Register file (`regfile_unittest`)

![regfile waveform](docs/waveforms/regfile_unittest.png)

Writes are gated by `I_we`: `R0 = ffff` and `R4 = 4444` are written, `R2` is written with `2222` then overwritten with `3333`, and the `feed` value presented while `I_we = 0` is not stored. Final state is `R0 = ffff`, `R2 = 3333`, `R4 = 4444`, with both read ports returning `4444` when `selA = selB = 4`.

## Simulation results

### Full system (`main_test`, 1 µs)

![main_test waveform](docs/waveforms/main_test.png)

- Reset (`opcode = 11`) holds PC at `0000` for the first 20 ns.
- Control strobes fire in order each instruction: `enfetch → endec → enrgrd → enalu → enrgrd + enrgwr → enmem`.
- PC steps `0000 → 0006`; `c004` (JMPA, `imm = 04`) raises `shldBranch`, PC loads `0004` from the ALU result, and the program loops `0004 → 0005 → 0006 → 0004`.
- `shldBranch` and `opcode` show `X` until the first ALU operation completes (see Status).

### Instruction decoder (`decoder_unitests`)

![decoder waveform](docs/waveforms/decoder_unittest.png)

`I_Inst = 0x1704` with `I_En` asserted at 20 ns. Outputs latch on the next `negedge`: `aluop = 0x02` (SUB, unsigned), `selA = 7`, `selB = 0`, `selD = 1`, `imm = 0x0004`, `regwe = 1`.

### Register file (`regfile_unittest`)

![regfile waveform](docs/waveforms/regfile_unittest.png)

- Writes with `I_we = 1`: R0 ← `ffff`, R2 ← `2222` then overwritten by `3333`, R4 ← `4444`.
- Write to R0 with `I_we = 0` (`I_dataD = feed`) is ignored; R0 stays `ffff`.
- Read ports are registered: with `selA = selB = 4`, `O_dataA` and `O_dataB` both settle to `4444`.
- Final state: R0 = `ffff`, R2 = `3333`, R4 = `4444`, others `0000`.

## Status

- Simulation only: no synthesizable top-level wrapper or XDC constraints yet.
- `fake_ram` is behavioural (9 words, hard-coded program).
- `alu` has no initial value for `O_shldBranch`, so it (and the PC opcode derived from it) is `X` in `main_test` until the first ALU operation.

## Tools

Vivado 2024.1.2 · Verilog-2001 · XSim
