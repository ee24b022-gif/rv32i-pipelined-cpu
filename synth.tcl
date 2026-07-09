# Yosys Synthesis Script (Day 10)
# Compiles your Verilog RTL files and maps them to generic logic gates.

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
stat

# 7. Write out the gate-level netlist file
write_verilog cpu_synth.v