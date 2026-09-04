# 5-Stage Hazard-Aware RV32I-Lite Pipelined CPU Core

A portfolio-ready, synthesizable 32-bit RISC-V pipelined processor core implementing the RV32I-Lite instruction subset. This core features full hazard resolution (bypassing, stalling, and flushes) and is verified against a Python Golden Model reference.

## 🚀 Key Microarchitecture Specifications
* **ISA**: RISC-V RV32I-Lite (ADD, SUB, AND, OR, XOR, SLT, ADDI, ANDI, ORI, XORI, SLTI, LW, SW, BEQ, BNE, JAL).
* **Pipeline Structure**: 5 synchronous stages (`IF` - Fetch, `ID` - Decode, `EX` - Execute, `MEM` - Memory, `WB` - Write Back).
* **RAW Hazard Resolution**: 
  * **Forwarding (Bypassing)**: Routes data from `EX/MEM` and `MEM/WB` stages directly back to the ALU inputs in the `EX` stage. (Zero stalls on ALU-to-ALU dependencies).
  * **Write-First RegFile**: Same-cycle write-to-read register bypassing in the `ID` stage.
* **Load-Use Stall Logic**: Detects `LW` instruction dependencies and stalls the pipeline for exactly 1 cycle (freezing PC and `IF/ID` stages while injecting a bubble into `ID/EX`).
* **Control Hazard Resolution**: Resolves branch/jump decisions in the `EX` stage; flushes `IF/ID` and `ID/EX` stages (2-cycle branch penalty) and redirects the PC on taken branches or jumps.
* **Synthesis**: Verified synthesizable (zero errors, zero latches) with ~10,122 generic cells via Yosys. Timing-driven synthesis against SKY130 HD available via `synth_timed.tcl`.

---

## 🛠️ Repository File Structure
* [cpu.v](cpu.v) - Top-level CPU wrapper connecting stages, forwarding, and hazard units.
* [pipeline_regs.v](pipeline_regs.v) - Synchronous pipeline stage registers with stall/flush inputs.
* [forwarding.v](forwarding.v) - Data hazard detection and ALU source routing.
* [hazard_detection.v](hazard_detection.v) - Load-use dependency detection and pipeline stall logic.
* [regfile.v](regfile.v) - 32x32-bit register file with internal same-cycle bypassing.
* [alu.v](alu.v) & [alu_control.v](alu_control.v) - Arithmetic logic unit and execution decoder.
* [control_unit.v](control_unit.v) - Central opcode decoder.
* [dmem.v](dmem.v) & [imem.v](imem.v) - RAM and ROM memory structures.
* [verify.py](verify.py) & [golden_model.py](golden_model.py) - Co-simulation verification harness and ISA model.
* [cpu_tb.v](cpu_tb.v) & [cpu_tb_cycle.v](cpu_tb_cycle.v) - End-of-program and cycle-accurate testbenches.
* [tests/](tests/) - Directed test programs (.hex) covering forwarding, stalls, branches, memory, and ALU ops.
* [synth.tcl](synth.tcl) - Yosys generic synthesis script (no timing, gate-count only).
* [synth_timed.tcl](synth_timed.tcl) - Yosys timing-driven synthesis targeting SKY130 HD standard cells.
* [run_sta.sh](run_sta.sh) - OpenSTA helper script for real Fmax analysis.

---

## 🧪 Verification Methodology

This core is verified using an automated **Python Co-Simulation Diff Harness** that compares RTL register state against a Python golden ISA model.

```
 [ Test Hex ] ──┬──► [ Python Golden ISA Model ] ──► [ Expected Registers ]
                │                                          │
                ▼                                          ▼
         [ RTL Core (iverilog) ] ─────────────────► [ RTL Registers ] ──► [ Diff ]
```

### Test Programs

| Test | File | Coverage |
|------|------|----------|
| RAW Forwarding | `tests/test_raw_forwarding.hex` | EX→EX and MEM→EX forwarding, countdown loop |
| Load-Use Stall | `tests/test_load_use.hex` | LW→dependent instruction stall, multiple patterns |
| Branch & Jump | `tests/test_branch_jump.hex` | BEQ/BNE taken/not-taken, JAL, flush verification |
| Store-Load | `tests/test_store_load.hex` | SW→LW same address, overwrite and re-read |
| ALU Operations | `tests/test_alu_ops.hex` | All R-type and I-type ALU ops including negative numbers |

### Running Verification

```bash
# Default: run the original test (end-of-program register diff)
python3 verify.py

# Run all directed tests
python3 verify.py --all

# Run a specific test
python3 verify.py --test tests/test_load_use.hex

# Cycle-accurate mode: diff registers every cycle (catches transient bugs)
python3 verify.py --all --cycle-accurate

# Custom cycle count
python3 verify.py --all --cycle-accurate --num-cycles 80
```

**End-of-program mode** (default): Compares all 32 architectural registers at program termination. Fast, catches most bugs.

**Cycle-accurate mode** (`--cycle-accurate`): Dumps and compares the register file every simulation cycle. Catches hazard bugs that produce incorrect intermediate values even if the final state is correct (e.g., a forwarding bug that self-corrects after a pipeline drain).


---

## 📊 Synthesis & Resource Utilization

### Generic Synthesis (Yosys)
Generic synthesis verifies that the RTL is fully synthesizable (no latches, no unresolved references) and provides a rough gate-count estimate using Yosys's built-in generic cells.

```bash
# Prerequisites: brew install yosys
yosys synth.tcl
```

* **Top Module**: cpu
* **Total Synthesized Generic Cells**: ~10,122
  * MUX cells: ~4,337
  * DFF cells (Registers): ~3,586
  * Logic gates: ~2,199
* **Linting / DRC**: `CHECK pass: Found and reported 0 problems` (zero latches detected).

> **Note**: These are generic cell counts, not silicon-area numbers. No timing information is produced by this flow.

### Timing-Driven Synthesis (SKY130 HD)
For real standard-cell area and a technology-mapped netlist suitable for static timing analysis:

```bash
# Prerequisites:
#   1. brew install yosys
#   2. Download sky130_fd_sc_hd__tt_025C_1v80.lib into this directory
#      from: https://github.com/google/skywater-pdk-libs-sky130_fd_sc_hd/tree/main/timing
yosys synth_timed.tcl
```

This maps flip-flops via `dfflibmap` and combinational logic via `abc` to the SKY130 HD typical-corner library (tt/025°C/1.80V), producing:
* `cpu_sky130.v` — SKY130-mapped gate-level netlist
* `flat_debug.v` — pre-ABC flattened netlist (for diagnostic inspection)
* `timing_report.txt` — topological longest-path report (logic levels)

---

## 🔬 Static Timing Analysis (Fmax)

Yosys does **not** include a built-in STA engine that reports delays in nanoseconds. The `ltp` pass reports the topological longest path in logic levels only.

To obtain an actual **Fmax** in MHz, run OpenSTA against the SKY130-mapped netlist:

```bash
# Prerequisites: brew install opensta  (or build from source)
./run_sta.sh [clock_period_ns]
```

This creates a virtual clock on the `clk` port, runs setup/hold timing analysis, and reports the worst-case data arrival time. Fmax is computed as:

```
Fmax (MHz) = 1000 / data_arrival_time (ns)
```

**Expected critical path** (from RTL analysis): Output of `id_ex_reg` → Forwarding Muxes → ALU Operand Mux → 32-bit ALU Carry Chain → Setup of `ex_mem_reg`.

**Optimization potential**: To target higher frequencies, the 32-bit carry chain can be pipelined or branch target resolution can be moved to the Decode stage.