# Complete RISC-V RV32I-lite Python Golden Model Reference (Day 9)
def to_signed(val, bits=32):
    val = val & ((1 << bits) - 1)
    if val >= (1 << (bits - 1)):
        return val - (1 << bits)
    return val

def run_simulation(hex_file):
    regs = [0] * 32
    mem = {}
    
    # Read the instructions from imem.hex
    with open(hex_file, "r") as f:
        instructions = [line.strip() for line in f if line.strip()]
        
    pc = 0
    instructions_executed = 0
    limit = 1000 # Safety limit to prevent infinite loops
    
    while pc // 4 < len(instructions) and instructions_executed < limit:
        hex_inst = instructions[pc // 4]
        inst = int(hex_inst, 16)
        
        # NOP
        if inst == 0:
            pc += 4
            instructions_executed += 1
            continue
            
        opcode = inst & 0x7F
        rd = (inst >> 7) & 0x1F
        funct3 = (inst >> 12) & 0x07
        rs1 = (inst >> 15) & 0x1F
        rs2 = (inst >> 20) & 0x1F
        funct7 = (inst >> 25) & 0x7F
        
        # Decode Immediates
        # I-type
        imm_i = inst >> 20
        if imm_i >= 0x800: imm_i -= 0x1000
        
        # S-type
        imm_s = ((inst >> 25) & 0x7F) << 5 | ((inst >> 7) & 0x1F)
        if imm_s >= 0x800: imm_s -= 0x1000
        
        # B-type
        imm_b = (((inst >> 31) & 0x1) << 12) | \
                (((inst >> 7) & 0x1) << 11) | \
                (((inst >> 25) & 0x3F) << 5) | \
                (((inst >> 8) & 0xF) << 1)
        if imm_b >= 0x1000: imm_b -= 0x2000
        
        # J-type
        imm_j = (((inst >> 31) & 0x1) << 20) | \
                (((inst >> 12) & 0xFF) << 12) | \
                (((inst >> 20) & 0x1) << 11) | \
                (((inst >> 21) & 0x3FF) << 1)
        if imm_j >= 0x100000: imm_j -= 0x200000

        next_pc = pc + 4
        
        # R-type instructions
        if opcode == 0x33:
            if funct3 == 0x0 and funct7 == 0x00:   # ADD
                regs[rd] = regs[rs1] + regs[rs2]
            elif funct3 == 0x0 and funct7 == 0x20: # SUB
                regs[rd] = regs[rs1] - regs[rs2]
            elif funct3 == 0x7 and funct7 == 0x00: # AND
                regs[rd] = regs[rs1] & regs[rs2]
            elif funct3 == 0x6 and funct7 == 0x00: # OR
                regs[rd] = regs[rs1] | regs[rs2]
            elif funct3 == 0x4 and funct7 == 0x00: # XOR
                regs[rd] = regs[rs1] ^ regs[rs2]
            elif funct3 == 0x2 and funct7 == 0x00: # SLT
                regs[rd] = 1 if to_signed(regs[rs1]) < to_signed(regs[rs2]) else 0
        
        # I-type ALU instructions
        elif opcode == 0x13:
            if funct3 == 0x0:   # ADDI
                regs[rd] = regs[rs1] + imm_i
            elif funct3 == 0x7: # ANDI
                regs[rd] = regs[rs1] & imm_i
            elif funct3 == 0x6: # ORI
                regs[rd] = regs[rs1] | imm_i
            elif funct3 == 0x4: # XORI
                regs[rd] = regs[rs1] ^ imm_i
            elif funct3 == 0x2: # SLTI
                regs[rd] = 1 if to_signed(regs[rs1]) < imm_i else 0
                
        # Load instruction (LW)
        elif opcode == 0x03 and funct3 == 0x2:
            addr = regs[rs1] + imm_i
            regs[rd] = mem.get(addr, 0)
            
        # Store instruction (SW)
        elif opcode == 0x23 and funct3 == 0x2:
            addr = regs[rs1] + imm_s
            mem[addr] = regs[rs2] & 0xFFFFFFFF
            
        # Branch instructions
        elif opcode == 0x63:
            if funct3 == 0x0:   # BEQ
                if regs[rs1] == regs[rs2]:
                    next_pc = pc + imm_b
            elif funct3 == 0x1: # BNE
                if regs[rs1] != regs[rs2]:
                    next_pc = pc + imm_b
                    
        # Jump instruction (JAL)
        elif opcode == 0x6F:
            regs[rd] = pc + 4
            next_pc = pc + imm_j

        # Lock register x0 to 0
        regs[0] = 0
        
        # Mask registers to 32-bit unsigned bounds
        for i in range(32):
            regs[i] = regs[i] & 0xFFFFFFFF
            
        pc = next_pc
        instructions_executed += 1

    return regs