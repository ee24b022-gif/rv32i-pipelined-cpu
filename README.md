# Hazard-Aware 5-Stage Pipelined RV32I-Lite CPU Core

A 5-stage pipelined RISC-V CPU core designed and verified in RTL Verilog. This project is built incrementally over a 2-week sprint, moving from a single-cycle golden model reference to a fully pipelined, hazard-forwarded design with synthesis and Static Timing Analysis (STA) timing closure.

---

## 1. Project Specifications & Goals
Rather than building a standard "ALU + FSM" class project, this design is focused on modeling realistic microarchitectural behaviors, verification coverage, and PPA (Power, Performance, Area) analysis.

### Microarchitecture Features:
* **Pipeline Structure**: Classic 5-stage design (`IF` $\rightarrow$ `ID` $\rightarrow$ `EX` $\rightarrow$ `MEM` $\rightarrow$ `WB`).
* **Hazard Forwarding**: Data forwarding paths from `EX/MEM` $\rightarrow$ `EX` and `MEM/WB` $\rightarrow$ `EX` to minimize stalls.
* **Load-Use Handling**: 1-cycle hardware stall generation for RAW hazards involving memory loads.
* **Control Hazard Resolution**: Branch resolution handled in the `EX` stage with a 2-cycle branch flush mechanism.
* **Timing & Synthesis**: Synthesized via `Yosys` and analyzed with `OpenSTA` to calculate critical path delays and maximum clock frequency ($F_{max}$).

---

## 2. Supported Instruction Set (RV32I-Lite)
The core implements a subset of 15 instructions using standard RISC-V 32-bit integer encodings:

| Instruction | Type | Opcode (`inst[6:0]`) | funct3 (`inst[14:12]`) | funct7 (`inst[31:25]`) | Action |
|---|---|---|---|---|---|
| **ADD** | R | `0110011` | `000` | `0000000` | `rd = rs1 + rs2` |
| **SUB** | R | `0110011` | `000` | `0100000` | `rd = rs1 - rs2` |
| **AND** | R | `0110011` | `111` | `0000000` | `rd = rs1 & rs2` |
| **OR** | R | `0110011` | `110` | `0000000` | `rd = rs1 \| rs2` |
| **XOR** | R | `0110011` | `100` | `0000000` | `rd = rs1 ^ rs2` |
| **SLT** | R | `0110011` | `010` | `0000000` | `rd = (rs1 < rs2) ? 1 : 0` (signed) |
| **ADDI** | I | `0010011` | `000` | N/A | `rd = rs1 + imm` |
| **ANDI** | I | `0010011` | `111` | N/A | `rd = rs1 & imm` |
| **ORI** | I | `0010011` | `110` | N/A | `rd = rs1 \| imm` |
| **SLTI** | I | `0010011` | `010` | N/A | `rd = (rs1 < imm) ? 1 : 0` (signed) |
| **LW** | I | `0000011` | `010` | N/A | `rd = Mem[rs1 + imm]` (Load Word) |
| **SW** | S | `0100011` | `010` | N/A | `Mem[rs1 + imm] = rs2` (Store Word) |
| **BEQ** | B | `1100011` | `000` | N/A | Branch if `rs1 == rs2` |
| **BNE** | B | `1100011` | `001` | N/A | Branch if `rs1 != rs2` |
| **JAL** | J | `1101111` | N/A | N/A | `rd = PC + 4; PC = PC + imm` (Jump and Link) |

---

## 3. 2-Week Incremental Roadmap
* [ ] **Day 1**: ISA specification, single-cycle datapath diagram, toolchain smoke test.
* [ ] **Day 2**: Single-cycle reference CPU implementation.
* [ ] **Day 3**: Python golden model reference & RTL diff harness.
* [ ] **Day 4**: Pipelined skeleton (independent instruction execution).
* [ ] **Day 5**: Control signal propagation and bubble insertion.
* [ ] **Day 6**: RAW data hazard resolution (EX/MEM and MEM/WB forwarding).
* [ ] **Day 7**: Load-use hazard stalling logic.
* [ ] **Day 8**: Branch control hazard handling (EX-stage resolution & pipeline flushing).
* [ ] **Day 9**: Self-checking testbench integration & directed hazard suite.
* [ ] **Day 10**: Constrained-random instruction stream regression testing.
* [ ] **Day 11**: Functional coverage mapping (instruction & hazard bins).
* [ ] **Day 12**: RTL Synthesis with `Yosys` (gate count and area analysis).
* [ ] **Day 13**: Static Timing Analysis (STA) via `OpenSTA` (critical path & $F_{max}$).
* [ ] **Day 14**: Verification report and final documentation.

---

## 4. Verification Methodology
To ensure design correctness without relying on manual waveform inspection:
1. **Python Golden Model**: A transaction-level Python model acts as a reference.
2. **Self-Checking Co-Simulation**: A diff script compares the RTL register values against the Python model output after every retired instruction.
3. **Randomized Test Streams**: Constrained-random assembly generator validates boundary conditions.
4. **Coverage Mapping**: Functional coverage tracks that every instruction and forwarding path is hit by the test suite.

---

## 5. Synthesis & Timing (PPA Metrics)
*(Metrics will be populated upon completion of Days 12 and 13)*

| Category | Metric | Value |
|---|---|---|
| **Synthesis** | Gate / Cell Count | *TBD* |
| **Synthesis** | Estimated Cell Area | *TBD* |
| **Timing** | Max Clock Frequency ($F_{max}$) | *TBD* |
| **Timing** | Critical Path | *TBD* |
| **Performance** | Benchmarked CPI | *TBD* |
| **Code** | RTL Lines of Code | *TBD* |
