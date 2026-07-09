import subprocess
import sys
import golden_model

def run_rtl():
    print("Compiling and Running RTL simulation...")
    # Compile Verilog files
    compile_cmd = "iverilog -o cpu_sim hazard_detection.v forwarding.v pipeline_regs.v cpu.v pc.v imem.v regfile.v imm_gen.v control_unit.v alu_control.v alu.v dmem.v cpu_tb.v"
    subprocess.run(compile_cmd.split(), check=True)
    
    # Run simulation and capture output
    result = subprocess.run(["vvp", "cpu_sim"], capture_output=True, text=True, check=True)
    return result.stdout

def main():
    # 1. Run RTL and get output
    rtl_out = run_rtl()
    
    # 2. Parse RTL register values from the dump block
    rtl_regs = [0] * 32
    in_dump = False
    for line in rtl_out.splitlines():
        if "--- REGISTER DUMP ---" in line:
            in_dump = True
            continue
        if "--- MEMORY DUMP ---" in line:
            in_dump = False
        if in_dump and "=" in line:
            parts = line.split("=")
            reg_idx = int(parts[0].replace("x", "").strip())
            reg_val = int(parts[1].strip())
            rtl_regs[reg_idx] = reg_val
            
    # 3. Run Python Golden Model simulation
    print("Running Python Golden Model...")
    python_regs = golden_model.run_simulation("imem.hex")
    
    # 4. Perform Diff
    print("\nComparing RTL Registers vs Python Golden Model:")
    print("--------------------------------------------------")
    mismatches = 0
    for i in range(32):
        rtl_val = rtl_regs[i]
        py_val = python_regs[i]
        match_str = "MATCH" if rtl_val == py_val else "MISMATCH ❌"
        if rtl_val != py_val:
            mismatches += 1
        print(f"Reg x{i:02d}: RTL = {rtl_val:10d} | Python = {py_val:10d} -> {match_str}")
        
    print("--------------------------------------------------")
    if mismatches == 0:
        print("\nDIFF VERIFICATION: SUCCESS! ALL MATCH! 🎉")
        sys.exit(0)
    else:
        print(f"\nDIFF VERIFICATION: FAILED! {mismatches} mismatches found. ❌")
        sys.exit(1)

if __name__ == "__main__":
    main()