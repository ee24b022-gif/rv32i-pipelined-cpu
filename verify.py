import subprocess
import sys
import golden_model

def run_rtl():
    print("Compiling and Running RTL simulation...")
    # Compile Verilog files
    compile_cmd = "iverilog -o cpu_sim cpu.v pc.v imem.v regfile.v imm_gen.v control_unit.v alu_control.v alu.v dmem.v cpu_tb.v"
    subprocess.run(compile_cmd.split(), check=True)
    
    # Run simulation and capture output
    result = subprocess.run(["vvp", "cpu_sim"], capture_output=True, text=True, check=True)
    return result.stdout

def main():
    # 1. Run RTL and get output
    rtl_out = run_rtl()
    
    # 2. Parse RTL register values from the testbench log
    rtl_regs = {}
    for line in rtl_out.splitlines():
        if line.startswith("x") and "=" in line:
            parts = line.split("=")
            reg_name = parts[0].split("(")[0].strip() # Extract "x1" from "x1 (expect 10)"
            reg_val = int(parts[1].split()[0])
            rtl_regs[reg_name] = reg_val

    # 3. Run Python simulation
    py_regs, _ = golden_model.run_simulation("imem.hex")
    
    # 4. Compare
    print("\nComparing RTL Registers vs Python Golden Model:")
    failed = False
    for idx in range(1, 15):
        reg_name = f"x{idx}"
        rtl_val = rtl_regs.get(reg_name, 0)
        # Convert unsigned 32-bit register from python simulation to signed integer
        py_val = golden_model.to_signed(py_regs[idx])
        
        match = "MATCH" if rtl_val == py_val else "MISMATCH"
        print(f"Reg {reg_name:<3}: RTL = {rtl_val:<4} | Python = {py_val:<4} -> {match}")
        if rtl_val != py_val:
            failed = True
            
    if failed:
        print("\nDIFF VERIFICATION: FAILED! ❌")
        sys.exit(1)
    else:
        print("\nDIFF VERIFICATION: SUCCESS! ALL MATCH!  ")

if __name__ == "__main__":
    main()