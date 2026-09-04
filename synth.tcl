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