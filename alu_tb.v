`timescale 1ns/1ps

module alu_tb;
    reg [31:0] a;
    reg [31:0] b;
    reg [3:0] alu_ctrl;
    
    wire [31:0] result;
    wire zero;

    // Instantiate UUT
    alu uut (
        .a(a),
        .b(b),
        .alu_ctrl(alu_ctrl),
        .result(result),
        .zero(zero)
    );

    initial begin
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);

        $display("Starting ALU testbench...");

        // Test 1: ADD (15 + 10 = 25)
        a = 32'd15; b = 32'd10; alu_ctrl = 4'b0010;
        #10;
        $display("ADD: 15 + 10 = %d, zero = %b (expect 25, 0)", result, zero);

        // Test 2: SUB (15 - 15 = 0, zero should assert)
        a = 32'd15; b = 32'd15; alu_ctrl = 4'b0110;
        #10;
        $display("SUB: 15 - 15 = %d, zero = %b (expect 0, 1)", result, zero);

        // Test 3: AND (0x0F0F0F0F & 0xF0F0F0F0 = 0)
        a = 32'h0F0F0F0F; b = 32'hF0F0F0F0; alu_ctrl = 4'b0000;
        #10;
        $display("AND: %h & %h = %h, zero = %b (expect 00000000, 1)", a, b, result, zero);

        // Test 4: OR (0x0F0F0F0F | 0xF0F0F0F0 = 0xFFFFFFFF)
        a = 32'h0F0F0F0F; b = 32'hF0F0F0F0; alu_ctrl = 4'b0001;
        #10;
        $display("OR:  %h | %h = %h (expect ffffffff)", a, b, result);

        // Test 5: SLT signed check (-5 < 10)
        a = -32'd5; b = 32'd10; alu_ctrl = 4'b0111;
        #10;
        $display("SLT: %d < %d = %d (expect 1)", $signed(a), $signed(b), result);

        // Test 6: SLT signed check (10 < -5)
        a = 32'd10; b = -32'd5; alu_ctrl = 4'b0111;
        #10;
        $display("SLT: %d < %d = %d (expect 0)", $signed(a), $signed(b), result);

        $display("ALU testbench complete.");
        $finish;
    end
endmodule