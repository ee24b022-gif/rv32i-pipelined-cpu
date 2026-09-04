#!/usr/bin/env bash
# ============================================================================
# run_sta.sh — Run OpenSTA against the SKY130-mapped netlist to get real Fmax
# ============================================================================
#
# PREREQUISITES:
#   1. OpenSTA installed (https://github.com/The-OpenROAD-Project/OpenSTA)
#      macOS:   brew install opensta
#      Linux:   Build from source or use OpenROAD package
#   2. SKY130 liberty file (sky130_fd_sc_hd__tt_025C_1v80.lib) in this directory
#   3. cpu_sky130.v netlist produced by: yosys synth_timed.tcl
#
# USAGE:
#   ./run_sta.sh [clock_period_ns]
#
#   clock_period_ns: target clock period in nanoseconds (default: 10.0 = 100 MHz)
#
# OUTPUT:
#   Prints setup timing report showing worst-case path delay and slack.
#   Fmax = 1 / (clock_period - slack)  if slack is positive
#   Fmax = 1 / actual_critical_path_delay  from the report
# ============================================================================

set -euo pipefail

LIB="${LIB_PATH:-sky130_fd_sc_hd__tt_025C_1v80.lib}"
NETLIST="cpu_sky130.v"
CLOCK_PERIOD="${1:-10.0}"

# Validate prerequisites
if ! command -v sta &>/dev/null; then
    echo "ERROR: OpenSTA ('sta') is not installed or not in PATH."
    echo ""
    echo "Install OpenSTA:"
    echo "  macOS:  brew install opensta"
    echo "  Linux:  See https://github.com/The-OpenROAD-Project/OpenSTA#build"
    echo ""
    echo "Alternatively, if you have OpenROAD installed, its built-in STA can"
    echo "be used with similar TCL commands."
    exit 1
fi

if [ ! -f "$LIB" ]; then
    echo "ERROR: Liberty file not found: $LIB"
    echo ""
    echo "Download sky130_fd_sc_hd__tt_025C_1v80.lib from:"
    echo "  https://github.com/google/skywater-pdk-libs-sky130_fd_sc_hd/tree/main/timing"
    echo ""
    echo "Or set LIB_PATH environment variable to point to your copy."
    exit 1
fi

if [ ! -f "$NETLIST" ]; then
    echo "ERROR: Mapped netlist not found: $NETLIST"
    echo "Run 'yosys synth_timed.tcl' first to produce the SKY130-mapped netlist."
    exit 1
fi

echo "=== OpenSTA Timing Analysis ==="
echo "  Liberty:      $LIB"
echo "  Netlist:      $NETLIST"
echo "  Clock period: ${CLOCK_PERIOD} ns"
echo ""

# Generate OpenSTA TCL script
STA_SCRIPT=$(mktemp /tmp/sta_cpu_XXXXXX.tcl)
cat > "$STA_SCRIPT" <<EOF
# OpenSTA timing analysis for RV32I-Lite CPU
read_liberty $LIB
read_verilog $NETLIST
link_design cpu

# Create a virtual clock — the CPU's clk input
create_clock -name clk -period $CLOCK_PERIOD [get_ports clk]

# Set input/output delays (conservative: 0 ns for inputs, 0 ns for outputs)
set_input_delay  -clock clk 0.0 [all_inputs]
set_output_delay -clock clk 0.0 [all_outputs]

# Report the worst setup timing path
report_checks -path_delay max -fields {slew cap input_pins nets} -digits 4

# Report the worst hold timing path
report_checks -path_delay min -fields {slew cap input_pins nets} -digits 4

# Report design statistics
report_design_area

puts ""
puts "========================================================================"
puts "To compute Fmax:"
puts "  Read the 'data arrival time' from the max-delay report above."
puts "  Fmax = 1000 / data_arrival_time_ns  (in MHz)"
puts "========================================================================"

exit
EOF

sta "$STA_SCRIPT"
rm -f "$STA_SCRIPT"
