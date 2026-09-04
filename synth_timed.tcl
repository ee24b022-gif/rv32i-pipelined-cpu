# Yosys Timing-Driven Synthesis Script — SKY130 HD (tt/025C/1.80V)
# ============================================================================
# This script maps the RV32I-Lite CPU to real SKY130 standard cells, producing
# a technology-mapped gate-level netlist with meaningful area numbers.
#
# PREREQUISITES:
#   1. Yosys installed           (brew install yosys)
#   2. SKY130 liberty file       (sky130_fd_sc_hd__tt_025C_1v80.lib)
#      Download from: https://github.com/google/skywater-pdk-libs-sky130_fd_sc_hd/tree/main/timing
#      Place in this directory or set LIB_PATH below.
#
# USAGE:
#   yosys synth_timed.tcl
#
# OUTPUTS:
#   cpu_sky130.v    — SKY130-mapped gate-level netlist
#   flat_debug.v    — pre-ABC flattened netlist (for loop-warning diagnosis)
#   timing_report.txt — Yosys topological longest-path report (logic levels only)
#
# NOTE ON REAL TIMING (Fmax):
#   Yosys does NOT include a built-in static timing analysis engine that reports
#   delays in nanoseconds. The `ltp` pass reports the topological longest path
#   in logic levels, NOT in real time units.
#   To obtain an actual Fmax in MHz, run OpenSTA against the mapped netlist:
#     ./run_sta.sh
#   See run_sta.sh for details.
# ============================================================================

# --- Liberty file path (override via: yosys -D LIB_PATH=<path> synth_timed.tcl) ---
# If LIB_PATH is not set externally, default to local directory
if {![info exists ::env(LIB_PATH)]} {
    set lib "sky130_fd_sc_hd__tt_025C_1v80.lib"
} else {
    set lib $::env(LIB_PATH)
}

# 1. Read RTL sources
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

# 2. Elaborate design hierarchy
hierarchy -top cpu

# 3. Generic synthesis (technology-independent optimization)
synth -top cpu

# 4. Write flattened pre-ABC netlist for loop-warning diagnosis
#    See "Combinational Loop Warning" note in synth.tcl for context.
write_verilog -noattr flat_debug.v

# 5. Map flip-flops to SKY130 DFF cells
dfflibmap -liberty $lib

# 6. Map combinational logic to SKY130 standard cells via ABC
#    NOTE: ABC may emit "Detected loop" warnings on internal nets after
#    flattening. These have been investigated and confirmed as FALSE POSITIVES
#    caused by net-name shadowing across pipeline stages (e.g. pc_out, rdata1
#    appear in multiple submodules; after flattening they alias to similar names
#    that ABC's netlist reader interprets as cycles). There are no actual
#    combinational feedback loops in the RTL — every apparent feedback path is
#    broken by pipeline stage registers (clocked DFFs). See synth.tcl for the
#    full investigation notes.
abc -liberty $lib

# 7. Final cleanup
clean

# 8. Print area and cell statistics against the liberty file
stat -liberty $lib

# 9. Topological longest-path report (logic levels, NOT nanoseconds)
tee -o timing_report.txt ltp -noff

# 10. Write the final SKY130-mapped netlist
write_verilog -noattr cpu_sky130.v

log "========================================================================"
log "Synthesis complete. Outputs:"
log "  cpu_sky130.v       — SKY130-mapped gate-level netlist"
log "  flat_debug.v       — pre-ABC flattened netlist (diagnostic)"
log "  timing_report.txt  — topological longest path (logic levels)"
log ""
log "For REAL timing (Fmax in MHz), run: ./run_sta.sh"
log "========================================================================"
