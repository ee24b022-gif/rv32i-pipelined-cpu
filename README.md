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
* [synth.tcl](synth.tcl) - Yosys generic synthesis script (no timing, gate-count only).
* [synth_timed.tcl](synth_timed.tcl) - Yosys timing-driven synthesis targeting SKY130 HD standard cells.
* [run_sta.sh](run_sta.sh) - OpenSTA helper script for real Fmax analysis.

---

## 🧪 Verification Methodology
This core is verified using an automated **Python Co-Simulation Diff Harness**.

## 🧪 Verification Methodology
This core is verified using an automated Python Co-Simulation Diff Harness. 

 [ Assembly Hex ] ──┬──► [ Python Golden ISA Model ] ──► [ Py Register Log ]
                    │                                          │
                    ▼                                          ▼
             [ RTL Core (iverilog) ] ─────────────────► [ RTL Register Log ] ──► [ Diff Script ]

1. **Self-Directed Tests**: Direct hazards tested on custom dependent sequences to confirm exact stalling and bypassing cycles.
2. **Loop/Control Tests**: Loop program counting from 5 to 0 executed to verify control flushes, branch redirection, and register file writing.
3. **Golden Model Comparisons**: The register logs from the Verilog gate-level state dump are compared side-by-side with the Python Golden Model output at execution termination.

To run the automated verification suite:


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