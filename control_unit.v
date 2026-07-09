// Main Control Unit
// Decodes the 7-bit opcode to generate all datapath control signals.
module control_unit (
    input wire [6:0] opcode,
    output reg reg_write,
    output reg alu_src,
    output reg mem_write,
    output reg mem_read,
    output reg [1:0] mem_to_reg,  // 00: ALU, 01: Memory, 10: PC+4
    output reg branch,
    output reg jump,
    output reg [1:0] alu_op,       // 00: ADD, 01: SUB, 10: ALU-decodes
    output reg [1:0] imm_src       // 00: I-type, 01: S-type, 10: B-type, 11: J-type
);
    always @(*) begin
        case (opcode)
            7'b0110011: begin // R-type (ADD, SUB, AND, OR, XOR, SLT)
                reg_write  = 1'b1;
                alu_src    = 1'b0;
                mem_write  = 1'b0;
                mem_read   = 1'b0;
                mem_to_reg = 2'b00;
                branch     = 1'b0;
                jump       = 1'b0;
                alu_op     = 2'b10;
                imm_src    = 2'b00; // don't care
            end
            7'b0010011: begin // I-type ALU (ADDI, ANDI, ORI, SLTI)
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_write  = 1'b0;
                mem_read   = 1'b0;
                mem_to_reg = 2'b00;
                branch     = 1'b0;
                jump       = 1'b0;
                alu_op     = 2'b10;
                imm_src    = 2'b00;
            end
            7'b0000011: begin // LW (Load Word)
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_write  = 1'b0;
                mem_read   = 1'b1;
                mem_to_reg = 2'b01;
                branch     = 1'b0;
                jump       = 1'b0;
                alu_op     = 2'b00;
                imm_src    = 2'b00;
            end
            7'b0100011: begin // SW (Store Word)
                reg_write  = 1'b0;
                alu_src    = 1'b1;
                mem_write  = 1'b1;
                mem_read   = 1'b0;
                mem_to_reg = 2'b00; // don't care
                branch     = 1'b0;
                jump       = 1'b0;
                alu_op     = 2'b00;
                imm_src    = 2'b01;
            end
            7'b1100011: begin // B-type Branches (BEQ, BNE)
                reg_write  = 1'b0;
                alu_src    = 1'b0;
                mem_write  = 1'b0;
                mem_read   = 1'b0;
                mem_to_reg = 2'b00; // don't care
                branch     = 1'b1;
                jump       = 1'b0;
                alu_op     = 2'b01;
                imm_src    = 2'b10;
            end
            7'b1101111: begin // JAL (Jump and Link)
                reg_write  = 1'b1;
                alu_src    = 1'b0; // don't care
                mem_write  = 1'b0;
                mem_read   = 1'b0;
                mem_to_reg = 2'b10; // PC + 4 goes to rd register
                branch     = 1'b0;
                jump       = 1'b1;
                alu_op     = 2'b00; // don't care
                imm_src    = 2'b11;
            end
            default: begin // NOP / default safe state
                reg_write  = 1'b0;
                alu_src    = 1'b0;
                mem_write  = 1'b0;
                mem_read   = 1'b0;
                mem_to_reg = 2'b00;
                branch     = 1'b0;
                jump       = 1'b0;
                alu_op     = 2'b00;
                imm_src    = 2'b00;
            end
        endcase
    end
endmodule