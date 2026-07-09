# Simple RISC-V RV32I-lite Python Golden Model Reference
# Mimics CPU instruction-by-instruction execution to generate reference register values.

def to_signed(val, bits=32):
    """Converts an unsigned integer into a signed integer for signed comparisons."""
    val = val & ((1 << bits) - 1)
    if val >= (1 << (bits - 1)):
        return val - (1 << bits)
    return val

def run_simulation(hex_file):
    # Initialize 32 registers to 0, and data memory dictionary
    regs = [0] * 32
    mem = {}
    
    # Read the instructions from imem.hex
    with open(hex_file, "r") as f:
        instructions = [line.strip() for line in f if line.strip()]
        
    pc = 0
    cycle = 0
    
    # Run the simulation loop
    while pc // 4 < len(instructions):
        hex_inst = instructions[pc // 4]
        inst = int(hex_inst, 16)
        
        # If instruction is 0, treat it as NOP and move forward
        if inst == 0:
            pc += 4
            continue
            
        # Decode standard RISC-V fields
        opcode   = inst & 0x7F
        rd       = (inst >> 7) & 0x1F
        funct3   = (inst >> 12) & 0x07
        rs1      = (inst >> 15) & 0x1F
        rs2      = (inst >> 20) & 0x1F
        funct7   = (inst >> 25) & 0x7F
        
        # Extract and sign-extend I-type immediate
        imm_i = inst >> 20
        if imm_i >= 0x800: imm_i -= 0x1000

        # Extract and sign-extend S-type immediate
        imm_s = ((inst >> 25) << 5) | ((inst >> 7) & 0x1F)
        if imm_s >= 0x800: imm_s -= 0x1000

        # Extract and sign-extend B-type immediate
        imm_b = (((inst >> 31) & 1) << 12) | (((inst >> 7) & 1) << 11) | (((inst >> 25) & 0x3F) << 5) | (((inst >> 8) & 0xF) << 1)
        if imm_b >= 0x1000: imm_b -= 0x2000

        # Extract and sign-extend J-type immediate
        imm_j = (((inst >> 31) & 1) << 20) | (((inst >> 12) & 0xFF) << 12) | (((inst >> 20) & 1) << 11) | (((inst >> 21) & 0x3FF) << 1)
        if imm_j >= 0x100000: imm_j -= 0x200000

        # Execute Instruction based on Opcode
        next_pc = pc + 4
        
        if opcode == 0x33: # R-type (ADD, SUB, AND, OR, XOR, SLT)
            if funct3 == 0:
                if funct7 == 0x20: regs[rd] = regs[rs1] - regs[rs2] # SUB
                else:              regs[rd] = regs[rs1] + regs[rs2] # ADD
            elif funct3 == 0x7:    regs[rd] = regs[rs1] & regs[rs2] # AND
            elif funct3 == 0x6:    regs[rd] = regs[rs1] | regs[rs2] # OR
            elif funct3 == 0x4:    regs[rd] = regs[rs1] ^ regs[rs2] # XOR
            elif funct3 == 0x2:    regs[rd] = 1 if to_signed(regs[rs1]) < to_signed(regs[rs2]) else 0 # SLT
            
        elif opcode == 0x13: # I-type ALU (ADDI, ANDI, ORI, SLTI)
            if funct3 == 0:      regs[rd] = regs[rs1] + imm_i # ADDI
            elif funct3 == 0x7:  regs[rd] = regs[rs1] & imm_i # ANDI
            elif funct3 == 0x6:  regs[rd] = regs[rs1] | imm_i # ORI
            elif funct3 == 0x2:  regs[rd] = 1 if to_signed(regs[rs1]) < imm_i else 0 # SLTI
            
        elif opcode == 0x03: # LW (Load Word)
            addr = regs[rs1] + imm_i
            regs[rd] = mem.get(addr, 0)
            
        elif opcode == 0x23: # SW (Store Word)
            addr = regs[rs1] + imm_s
            mem[addr] = regs[rs2]
            
        elif opcode == 0x63: # B-type Branches (BEQ, BNE)
            val1 = to_signed(regs[rs1])
            val2 = to_signed(regs[rs2])
            if funct3 == 0x0 and val1 == val2: next_pc = pc + imm_b # BEQ
            if funct3 == 0x1 and val1 != val2: next_pc = pc + imm_b # BNE
            
        elif opcode == 0x6F: # JAL (Jump and Link)
            regs[rd] = pc + 4
            next_pc = pc + imm_j

        # Keep register x0 locked to 0
        regs[0] = 0
        
        # Limit register values to 32-bit unsigned bounds for display
        for i in range(32):
            regs[i] = regs[i] & 0xFFFFFFFF
            
        pc = next_pc
        cycle += 1
        
    return regs, mem

if __name__ == "__main__":
    r, m = run_simulation("imem.hex")
    print("Expected Register States from Python Model:")
    for idx in [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]:
        print(f"x{idx} = {to_signed(r[idx])}")