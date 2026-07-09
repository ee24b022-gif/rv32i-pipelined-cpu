`timescale 1ns/1ps

module imm_gen_tb;
    reg [31:0] inst;
    reg [1:0] imm_src;
    wire [31:0] imm_ext;

    // Instantiate UUT
    imm_gen uut (
        .inst(inst),
        .imm_src(imm_src),
        .imm_ext(imm_ext)
    );

    initial begin
        $dumpfile("imm_gen_tb.vcd");
        $dumpvars(0, imm_gen_tb);

        $display("Starting Immediate Generator testbench...");

        // Test 1: I-type negative value (-5)
        // Instruction: ADDI x1, x2, -5 (hex FFB10093)
        inst = 32'hFFB10093;
        imm_src = 2'b00;
        #10;
        $display("I-type (expect -5):  %d (hex: %h)", $signed(imm_ext), imm_ext);

        // Test 2: S-type positive value (8)
        // Instruction: SW x3, 8(x4) (hex 00322423)
        inst = 32'h00322423;
        imm_src = 2'b01;
        #10;
        $display("S-type (expect 8):   %d (hex: %h)", $signed(imm_ext), imm_ext);

        // Test 3: B-type negative value (-4)
        // Instruction: BEQ x1, x2, -4 (hex FE208EE3)
        inst = 32'hFE208EE3;
        imm_src = 2'b10;
        #10;
        $display("B-type (expect -4):  %d (hex: %h)", $signed(imm_ext), imm_ext);

        // Test 4: J-type positive value (20)
        // Instruction: JAL x1, 20 (hex 014000EF)
        // imm[20] = 0, imm[10:1] = 10'd10 (binary 0000001010), imm[11] = 0, imm[19:12] = 8'd0
        inst = 32'h014000EF;
        imm_src = 2'b11;
        #10;
        $display("J-type (expect 20):  %d (hex: %h)", $signed(imm_ext), imm_ext);

        $display("Immediate Generator testbench complete.");
        $finish;
    end
endmodule