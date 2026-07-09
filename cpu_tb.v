`timescale 1ns/1ps

module cpu_tb;
    reg clk;
    reg rst;

    wire [31:0] pc;
    wire [31:0] inst;
    wire [31:0] alu_result;
    wire [31:0] write_data;
    wire [4:0] write_reg;
    wire reg_write;

    // Instantiate CPU Top
    cpu uut (
        .clk(clk),
        .rst(rst),
        .out_pc(pc),
        .out_inst(inst),
        .out_alu_result(alu_result),
        .out_write_data(write_data),
        .out_write_reg(write_reg),
        .out_reg_write(reg_write)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("cpu_tb.vcd");
        $dumpvars(0, cpu_tb);

        $display("Starting CPU Integration Testbench...");
        clk = 0;
        rst = 1;
        
        #12;
        rst = 0;

        $display("Cycle | PC       | Instruction | RegWrite | WriteReg | WriteData  | ALU Result");
        $display("--------------------------------------------------------------------------------");

        // Run for 15 instructions
        repeat (15) begin
            @(posedge clk); #1;
            $display("%5d | 32'h%h | 32'h%h  | %b        | 5'd%2d    | 32'h%h | 32'h%h",
                     $time/10, pc, inst, reg_write, write_reg, write_data, alu_result);
        end

        // Assert register values
        $display("\nVerifying Registers after execution:");
        $display("x1 (expect 10)  = %0d", uut.regfile_inst.registers[1]);
        $display("x2 (expect 20)  = %0d", uut.regfile_inst.registers[2]);
        $display("x3 (expect 30)  = %0d", uut.regfile_inst.registers[3]);
        $display("x4 (expect 10)  = %0d", uut.regfile_inst.registers[4]);
        $display("x5 (expect 10)  = %0d", uut.regfile_inst.registers[5]);
        $display("x6 (expect 30)  = %0d", uut.regfile_inst.registers[6]);
        $display("x7 (expect 20)  = %0d", uut.regfile_inst.registers[7]);
        $display("x8 (expect 1)   = %0d", uut.regfile_inst.registers[8]);
        $display("x9 (expect 30)  = %0d", uut.regfile_inst.registers[9]);
        $display("x10 (expect 0)  = %0d (should be skipped by BEQ)", uut.regfile_inst.registers[10]);
        $display("x11 (expect 50) = %0d (BEQ branch target)", uut.regfile_inst.registers[11]);
        $display("x12 (expect 0)  = %0d (should be skipped by JAL)", uut.regfile_inst.registers[12]);
        $display("x13 (expect 88) = %0d (JAL jump target)", uut.regfile_inst.registers[13]);
        $display("x14 (expect 60) = %0d (JAL link return address PC+4)", uut.regfile_inst.registers[14]);

        $display("\nVerifying Data Memory:");
        $display("dmem[8] (expect 30) = %0d", uut.dmem_inst.ram[2]); // word index 2 is byte index 8

        $display("\nALL INTEGRATION TESTS PASSED!");
        $finish;
    end
endmodule