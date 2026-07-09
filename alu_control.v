// ALU Control Unit
// Decodes alu_op, funct3, funct7, and opcode to generate 4-bit ALU select codes:
// - 4'b0000: AND
// - 4'b0001: OR
// - 4'b0010: ADD
// - 4'b0011: XOR
// - 4'b0110: SUB
// - 4'b0111: SLT
module alu_control (
    input wire [1:0] alu_op,
    input wire [2:0] funct3,
    input wire [6:0] funct7,
    input wire [6:0] opcode,
    output reg [3:0] alu_ctrl
);
    always @(*) begin
        case (alu_op)
            2'b00: // Memory accesses (LW/SW) and JAL -> ADD
                alu_ctrl = 4'b0010;
            2'b01: // Branches (BEQ/BNE) -> SUB (for comparisons)
                alu_ctrl = 4'b0110;
            2'b10: begin // ALU R-type and I-type
                case (funct3)
                    3'b000: begin
                        // For ADD/SUB: R-type uses opcode[5]=1, funct7[5]=1 for SUB.
                        if (opcode[5] && funct7[5])
                            alu_ctrl = 4'b0110; // SUB
                        else
                            alu_ctrl = 4'b0010; // ADD / ADDI
                    end
                    3'b010: alu_ctrl = 4'b0111; // SLT / SLTI
                    3'b100: alu_ctrl = 4'b0011; // XOR / XORI
                    3'b110: alu_ctrl = 4'b0001; // OR / ORI
                    3'b111: alu_ctrl = 4'b0000; // AND / ANDI
                    default: alu_ctrl = 4'b0010;
                endcase
            end
            default: alu_ctrl = 4'b0010;
        endcase
    end
endmodule