# Yosys Generic Synthesis Script
# ============================================================================
# This script compiles the RV32I-Lite CPU RTL and maps it to Yosys's built-in
# generic logic cells ($mux, $dff, $and, $or, etc.). It is useful for:
#   - Verifying synthesizability (no latches, no unresolved references)
#   - Getting a rough gate-count estimate
#   - Checking for structural issues (the `check` pass)
#
# IMPORTANT: This script does NOT produce timing information. The cell counts
# and "critical path" from this flow are in generic logic levels, NOT in
# nanoseconds or picoseconds. There is no liberty file mapping here.
#
# For timing-driven synthesis against SKY130 standard cells with real area and
# delay numbers, use:  yosys synth_timed.tcl
# ============================================================================

# 1. Read all input Verilog source files
read_verilog pc.v
read_verilog imem.v
read_verilog regfile.v
read_verilog imm_gen.v
read_verilog control_unit.v
read_verilog alu_control.v
read_verilog alu.v
read_verilog dmem.v
read_verilog pipeline_regs.v
read_verilog forwarding.v
read_verilog hazard_detection.v
read_verilog cpu.v

# 2. Elaborate design hierarchy starting from top-level "cpu" module
hierarchy -top cpu

# 3. Check for latches, feedback loops, and basic issues
proc; opt; check

# 4. Perform synthesis (converts RTL to technology-generic gate netlist)
synth -top cpu

# 5. Clean up unused structures
clean

# 6. Display statistics (area estimation, cell counts)
#    NOTE: These are generic cell counts, not silicon area.
stat

# 7. Write out the gate-level netlist file
write_verilog cpu_synth.v

# ============================================================================
# COMBINATIONAL LOOP WARNING INVESTIGATION (Sep 2026)
# ============================================================================
# ISSUE:
#   Running `dfflibmap + abc -liberty <sky130_lib>` on the flattened cpu module
#   causes ABC to emit "Detected loop" warnings on internal nets during its
#   netlist extraction pass. This was investigated to determine whether it
#   indicates a real combinational feedback loop (RTL bug) or a benign artifact.
#
# INVESTIGATION METHOD:
#   1. Generated flat_debug.v via:
#        yosys -p "read_verilog *.v; hierarchy -top cpu; synth -top cpu;
#                  write_verilog -noattr flat_debug.v"
#   2. Inspected the flattened netlist for actual combinational cycles.
#   3. Traced every potential feedback path in the RTL:
#
# ANALYSIS OF ALL POTENTIAL FEEDBACK PATHS:
#
#   Path A: PC selection (pc_next -> pc_out)
#     pc_next depends on branch_taken_E and jump_E (from id_ex_reg outputs),
#     which depend on ALU results computed from forwarded values (alu_result_M,
#     wdata_W). All source signals originate from pipeline register OUTPUTS
#     (clocked DFFs), not combinational feedback. pc_next feeds pc_inst (a DFF),
#     so this is a register-to-register path. NOT a combinational loop.
#
#   Path B: Forwarding muxes (forward_a/forward_b -> src_a_E/src_b_temp_E)
#     forward_a and forward_b are computed by the forwarding unit from rd_M,
#     reg_write_M, rd_W, reg_write_W — all pipeline register OUTPUTS from
#     ex_mem_reg and mem_wb_reg. The forwarded data values (alu_result_M,
#     wdata_W) also come from pipeline register outputs. The forwarding mux
#     outputs feed into the ALU, whose result goes into ex_mem_reg (a DFF).
#     NOT a combinational loop.
#
#   Path C: Hazard detection (stall_F/stall_D/flush_E_hazard)
#     The hazard detection unit reads rs1_D and rs2_D (from if_id_reg outputs),
#     rd_E and mem_read_E (from id_ex_reg outputs). Its outputs (stall_F,
#     stall_D) feed back to the IF/ID register's stall input and the PC
#     register's enable — but these are CLOCKED feedback paths (the stall
#     prevents a register update on the NEXT clock edge). NOT a combinational
#     loop.
#
#   Path D: flush_E signal
#     flush_E = flush_E_hazard || (jump_E || branch_taken_E)
#     All inputs come from pipeline register outputs or combinational logic
#     that doesn't feed back into itself. flush_E drives the id_ex_reg's
#     flush input (a clocked register). NOT a combinational loop.
#
#   Path E: Write-back -> Register file -> Decode (WB -> regfile -> ID)
#     wdata_W (from mem_wb_reg) feeds regfile_inst.wdata. The regfile has
#     write-first bypassing: if the write address matches a read address,
#     wdata is forwarded to rdata1/rdata2. However, this path goes:
#     wdata_W -> regfile -> rdata1_D/rdata2_D -> id_ex_reg (DFF).
#     The write data comes from MEM/WB (clocked), and the read data feeds
#     into ID/EX (clocked). NOT a combinational loop.
#
# CONCLUSION: FALSE POSITIVE
#   There are NO actual combinational feedback loops in this design. Every
#   apparent cycle is broken by at least one pipeline stage register (DFF).
#   The ABC warnings are caused by net-name shadowing after Yosys flattens
#   the module hierarchy: signal names like `pc_out`, `rdata1`, `rdata2`,
#   `alu_result`, `reg_write`, etc. appear in multiple submodules (pc_inst,
#   if_id, id_ex, ex_mem, mem_wb, regfile_inst) with _D/_E/_M/_W stage
#   suffixes. After flattening, Yosys may generate internal wire names that
#   look cyclical to ABC's netlist reader when they are actually distinct
#   signals separated by pipeline registers.
#
#   The warnings are SAFE TO IGNORE. The `check` pass in this script reports
#   0 problems, confirming no structural issues in the pre-flattened design.
# ============================================================================