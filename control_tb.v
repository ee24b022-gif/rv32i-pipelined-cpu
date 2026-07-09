`timescale 1ns/1ps

module control_tb;
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [6:0] funct7;

    wire reg_write;
    wire alu_src;
    wire mem_write;
    wire mem_read;
    wire [1:0] mem_to_reg;
    wire branch;
    wire jump;
    wire [1:0] alu_op;
    wire [1:0] imm_src;
    wire [3:0] alu_ctrl;

    // Instantiate Control Unit
    control_unit main_ctrl (
        .opcode(opcode),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .jump(jump),
        .alu_op(alu_op),
        .imm_src(imm_src)
    );

    // Instantiate ALU Control
    alu_control alu_ctrl_inst (
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7(funct7),
        .opcode(opcode),
        .alu_ctrl(alu_ctrl)
    );

    initial begin
        $dumpfile("control_tb.vcd");
        $dumpvars(0, control_tb);

        $display("Starting Control Unit testbench...");

        // Test 1: R-type ADD
        opcode = 7'b0110011; funct3 = 3'b000; funct7 = 7'b0000000;
        #10;
        $display("ADD: reg_write=%b, alu_src=%b, mem_to_reg=%b, alu_ctrl=%b (expect 1, 0, 00, 0010)", 
                 reg_write, alu_src, mem_to_reg, alu_ctrl);

        // Test 2: R-type SUB
        funct7 = 7'b0100000;
        #10;
        $display("SUB: alu_ctrl=%b (expect 0110)", alu_ctrl);

        // Test 3: LW Load
        opcode = 7'b0000011; funct3 = 3'b010;
        #10;
        $display("LW:  reg_write=%b, alu_src=%b, mem_read=%b, mem_to_reg=%b (expect 1, 1, 1, 01)", 
                 reg_write, alu_src, mem_read, mem_to_reg);

        // Test 4: SW Store
        opcode = 7'b0100011; funct3 = 3'b010;
        #10;
        $display("SW:  reg_write=%b, alu_src=%b, mem_write=%b (expect 0, 1, 1)", 
                 reg_write, alu_src, mem_write);

        // Test 5: JAL Jump
        opcode = 7'b1101111;
        #10;
        $display("JAL: reg_write=%b, jump=%b, mem_to_reg=%b, imm_src=%b (expect 1, 1, 10, 11)", 
                 reg_write, jump, mem_to_reg, imm_src);

        $display("Control Unit testbench complete.");
        $finish;
    end
endmodule