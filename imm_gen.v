// Immediate Generator (ImmGen)
// - Extracts and sign-extends immediates based on the imm_src selector.
module imm_gen (
    input wire [31:0] inst,
    input wire [1:0] imm_src,
    output reg [31:0] imm_ext
);
    always @(*) begin
        case (imm_src)
            2'b00: // I-type (ALU immediate, LW load)
                imm_ext = { {20{inst[31]}}, inst[31:20] };
            2'b01: // S-type (SW store)
                imm_ext = { {20{inst[31]}}, inst[31:25], inst[11:7] };
            2'b10: // B-type (BEQ, BNE branches)
                imm_ext = { {19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0 };
            2'b11: // J-type (JAL jump)
                imm_ext = { {12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0 };
            default:
                imm_ext = 32'b0;
        endcase
    end
endmodule