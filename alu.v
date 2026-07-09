// Arithmetic Logic Unit (ALU)
// - Computes arithmetic and logical outputs based on a 4-bit select code.
// - Outputs a zero flag indicating if the result is 32'h0.
module alu (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0] alu_ctrl,
    output reg [31:0] result,
    output wire zero
);
    always @(*) begin
        case (alu_ctrl)
            4'b0000: // AND
                result = a & b;
            4'b0001: // OR
                result = a | b;
            4'b0010: // ADD
                result = a + b;
            4'b0011: // XOR
                result = a ^ b;
            4'b0110: // SUB
                result = a - b;
            4'b0111: // SLT (Signed Set Less Than)
                result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            default:
                result = 32'b0;
        endcase
    end

    // The zero flag is high if the result is exactly 0
    assign zero = (result == 32'b0);

endmodule