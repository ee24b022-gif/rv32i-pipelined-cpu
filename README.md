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
* **Frequency & Synthesis**: Checked with zero errors and synthesized to a gate count of **10,122 generic standard cells** using Yosys.

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
* [synth.tcl](synth.tcl) - Yosys synthesis execution script.

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

## 📊 Synthesis & Resource Utilization (Yosys)
Synthesis was performed using the open-source Yosys compiler to verify that the Verilog code is fully synthesizable and free of latches.

* **Top Module**: cpu
* **Total Synthesized Gates**: 10,122 cells
  * MUX cells: 4,337
  * DFF cells (Registers): 3,586
  * Logic gates: 2,199
* **Linting / DRC**: `CHECK pass: Found and reported 0 problems` (Zero combinatorial feedback loops, zero latches, timing-clean).

---

## 🔬 Critical Path STA (Static Timing Analysis)
Using Yosys's ltp topological path analyzer, the physical critical path was isolated within the Execute stage:
* **Start**: Output of id_ex_reg (holding current operands).
* **Path**: Forwarding Multiplexers -> ALU Operand Mux -> 32-bit ALU Carry Chain.
* **End**: Setup of the ex_mem_reg register.
* **Optimization Potential**: To target higher frequencies, the 32-bit carry chain can be pipelined or branch target resolution can be moved to the Decode stage.