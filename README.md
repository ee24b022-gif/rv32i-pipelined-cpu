# 5-Stage Hazard-Aware RV32I-Lite Pipelined CPU Core

A synthesizable 32-bit RISC-V pipelined processor core implementing the RV32I-Lite instruction subset, with full hazard resolution (forwarding, stalling, and flushing), verified against a Python golden ISA model.

## 🚀 Key Microarchitecture Specifications

* **ISA**: RISC-V RV32I-Lite — 16 instructions: ADD, SUB, AND, OR, XOR, SLT, ADDI, ANDI, ORI, XORI, SLTI, LW, SW, BEQ, BNE, JAL.
  (Defined in [control_unit.v](control_unit.v) opcode decode, lines 16–94.)
* **Pipeline**: 5 synchronous stages — IF → ID → EX → MEM → WB.
  (Assembled in [cpu.v](cpu.v); stage registers in [pipeline_regs.v](pipeline_regs.v).)
* **RAW Hazard Resolution**:
  * **EX→EX and MEM→EX Forwarding**: The forwarding unit ([forwarding.v](forwarding.v)) checks `rd_M` and `rd_W` against `rs1_E`/`rs2_E` and drives mux selects `forward_a`/`forward_b` (encoding: `2'b01` = from MEM stage, `2'b10` = from WB stage, `2'b00` = register file). The forwarding muxes are in [cpu.v](cpu.v), lines 163–178.
  * **Write-First Register File**: [regfile.v](regfile.v) bypasses `wdata` to `rdata1`/`rdata2` on same-cycle write-read address match (lines 17–21).
* **Load-Use Stall**: [hazard_detection.v](hazard_detection.v) detects `mem_read_E && (rd_E == rs1_D || rd_E == rs2_D)` and asserts `stall_F`, `stall_D`, `flush_E` for exactly 1 cycle.
* **Control Hazards**: Branch/jump decisions are resolved in EX. Taken branches and JAL assert `flush_D` and `flush_E` (2-cycle penalty), redirecting the PC via `branch_target_E` ([cpu.v](cpu.v), lines 191–198).
* **Memories**: 64-word (256-byte) IMEM ROM ([imem.v](imem.v), loaded via `$readmemh("imem.hex")`), 64-word DMEM RAM ([dmem.v](dmem.v), synchronous write, asynchronous read).

---

## 🛠️ Repository File Structure

**RTL Sources** (all Verilog):
* [cpu.v](cpu.v) — Top-level module wiring all pipeline stages, forwarding, and hazard detection.
* [pipeline_regs.v](pipeline_regs.v) — IF/ID, ID/EX, EX/MEM, MEM/WB stage registers with stall/flush control.
* [forwarding.v](forwarding.v) — EX-hazard and MEM-hazard forwarding mux select logic.
* [hazard_detection.v](hazard_detection.v) — Load-use dependency detection and 1-cycle stall generation.
* [regfile.v](regfile.v) — 32×32-bit register file with write-first bypass.
* [alu.v](alu.v) — 32-bit ALU (AND, OR, ADD, XOR, SUB, SLT).
* [alu_control.v](alu_control.v) — Decodes `alu_op` + `funct3` + `funct7` → 4-bit ALU select.
* [control_unit.v](control_unit.v) — Opcode → control signal decoder.
* [imem.v](imem.v) — 64-word instruction ROM (loaded from `imem.hex`).
* [dmem.v](dmem.v) — 64-word data RAM.
* [pc.v](pc.v) — Program counter register.
* [imm_gen.v](imm_gen.v) — Immediate extractor/sign-extender (I/S/B/J types).

**Verification**:
* [verify.py](verify.py) — Multi-program verification harness with end-of-program and cycle-accurate diff modes.
* [golden_model.py](golden_model.py) — Python ISA reference model (`run_simulation` and `run_simulation_cycle_trace`).
* [cpu_tb.v](cpu_tb.v) — Testbench that runs 55 cycles and dumps final register state.
* [cpu_tb_cycle.v](cpu_tb_cycle.v) — Testbench that dumps all 32 registers every cycle (for `--cycle-accurate` mode).
* [tests/](tests/) — 5 directed test programs (`.hex` files); see Verification section below.

**Synthesis**:
* [synth.tcl](synth.tcl) — Yosys generic-cell synthesis script. Produces `cpu_synth.v` (generic gate netlist). No timing information.
* [synth_timed.tcl](synth_timed.tcl) — Yosys SKY130 HD technology-mapping script (`dfflibmap` + `abc -liberty`). Requires a local copy of the SKY130 liberty file. Has **not been run** yet (no `cpu_sky130.v` output exists in the repo).
* [run_sta.sh](run_sta.sh) — Shell script to run OpenSTA for real Fmax timing. Requires OpenSTA and the mapped netlist from `synth_timed.tcl`.

---

## 🧪 Verification Methodology

The CPU is verified by comparing RTL register state (from Icarus Verilog simulation) against a Python golden ISA model ([golden_model.py](golden_model.py)).

```
 [ Test .hex ] ──┬──► [ Python Golden Model ] ──► [ Expected Registers ]
                 │                                        │
                 ▼                                        ▼
          [ RTL (iverilog) ] ──────────────────► [ RTL Registers ] ──► [ Diff ]
```

### Test Programs

Five directed test programs exist in `tests/`:

| Test | File | What it covers |
|------|------|----------------|
| RAW Forwarding | `tests/test_raw_forwarding.hex` | Countdown loop exercising EX→EX forwarding (ADD depends on previous SUB), MEM→EX forwarding, and branch+JAL. 8 real instructions. |
| Load-Use Stall | `tests/test_load_use.hex` | Three LW→dependent-instruction sequences (LW then ADD, LW then SUB, LW then ADDI), each requiring a 1-cycle pipeline stall. 12 real instructions. |
| Branch & Jump | `tests/test_branch_jump.hex` | BEQ taken, BEQ not-taken, BNE taken, BNE not-taken, JAL forward. Verifies that flushed instructions (after taken branches) do NOT write registers. 14 real instructions. |
| Store-Load | `tests/test_store_load.hex` | SW then LW to same address, overwrite-and-re-read, store-of-forwarded-value. 16 real instructions. |
| ALU Operations | `tests/test_alu_ops.hex` | All 6 R-type ops (ADD, SUB, AND, OR, XOR, SLT) and 5 I-type ops (ADDI, ANDI, ORI, XORI, SLTI), including negative-number cases. 18 real instructions. |

### Running Verification

```bash
# Prerequisites: iverilog (Icarus Verilog), python3

# Default: run imem.hex, compare 32 registers at end of program
python3 verify.py

# Run all 5 directed tests (end-of-program diff)
python3 verify.py --all

# Run a single specific test
python3 verify.py --test tests/test_load_use.hex

# Cycle-accurate mode: dump and diff registers every cycle
python3 verify.py --all --cycle-accurate

# Adjust simulation length (default 60 cycles)
python3 verify.py --all --cycle-accurate --num-cycles 80
```

**End-of-program mode** (default, fast): Compares all 32 registers once at program termination. Catches most functional bugs.

**Cycle-accurate mode** (`--cycle-accurate`, opt-in): Uses `cpu_tb_cycle.v` to dump the register file every cycle. The harness reports which registers changed at which cycle, and performs a final end-of-program diff. This catches hazard bugs that produce wrong intermediate values but happen to self-correct before program end (e.g., a forwarding error masked by a later write to the same register).

> **Limitation**: The cycle-accurate mode currently tracks register-change events and performs a final-state diff. It does not yet do a strict per-cycle comparison against the golden model's per-instruction snapshots (which would require precise pipeline-latency alignment). The `golden_model.run_simulation_cycle_trace()` function exists to support this in the future.

---

## 📊 Synthesis & Resource Utilization

### Generic Synthesis (Yosys)

The generic synthesis script ([synth.tcl](synth.tcl)) has been run. Its output (`cpu_synth.v`) is committed in the repo. It maps to Yosys's built-in generic cells (`$mux`, `$dff`, `$and`, `$or`, etc.) — these are **not** real standard cells and carry no timing or area information.

```bash
# Prerequisites: yosys (brew install yosys)
yosys synth.tcl
```

* **Top Module**: `cpu`
* **Generic Cell Count**: ~10,122 (from the committed `cpu_synth.v`)
  * MUX cells: ~4,337
  * DFF cells: ~3,586
  * Logic gates: ~2,199
* **`check` pass**: 0 problems reported (no latches, no undriven nets).

> These numbers are rough gate-equivalent counts, not silicon area.

### Timing-Driven Synthesis (SKY130 HD) — Script Exists, Not Yet Run

[synth_timed.tcl](synth_timed.tcl) maps the design to the SKY130 HD typical-corner standard-cell library (`sky130_fd_sc_hd__tt_025C_1v80.lib`) using `dfflibmap` + `abc -liberty`. It is **committed but has not been executed** — no `cpu_sky130.v`, `flat_debug.v`, or `timing_report.txt` output exists in the repo.

```bash
# Prerequisites:
#   1. yosys (brew install yosys)
#   2. sky130_fd_sc_hd__tt_025C_1v80.lib in this directory
#      (download from https://github.com/google/skywater-pdk-libs-sky130_fd_sc_hd/tree/main/timing)
yosys synth_timed.tcl
```

**ABC "Detected loop" warnings**: When this script is run, ABC may emit "Detected loop" warnings during technology mapping. These have been investigated and documented in [synth.tcl](synth.tcl) (lines 49–118) as **false positives** — every apparent feedback path in the pipeline is broken by clocked pipeline-stage registers. The warnings are caused by net-name shadowing after Yosys flattens the module hierarchy. See the `COMBINATIONAL LOOP WARNING INVESTIGATION` comment block in `synth.tcl` for the full per-path analysis.

---

## 🔬 Critical Path Analysis

**No static timing analysis has been performed.** Neither Yosys's `ltp` (topological longest path, which reports logic-level depth only, not nanoseconds) nor OpenSTA (which reports real delay in ns) has been run against this design to produce committed timing results.

[run_sta.sh](run_sta.sh) is provided to run OpenSTA against the SKY130-mapped netlist once it is produced by `synth_timed.tcl`:

```bash
# Prerequisites: opensta (brew install opensta), cpu_sky130.v from synth_timed.tcl
./run_sta.sh [clock_period_ns]    # default: 10.0 ns = 100 MHz target
```

**Expected critical path** (from manual RTL inspection, not measured): The longest combinational path is expected to run through the Execute stage — from the `id_ex_reg` outputs, through the forwarding muxes (`forward_a`/`forward_b` select → `src_a_E`/`src_b_temp_E`), the ALU source mux (`alu_op_b_E`), the 32-bit ALU carry chain, to the `ex_mem_reg` setup. This is a structural observation from the RTL, not a timed measurement.

**Optimization opportunities** (if timing closure is needed): Pipeline the 32-bit adder/subtractor, or move branch-target computation to the Decode stage to shorten the EX critical path.