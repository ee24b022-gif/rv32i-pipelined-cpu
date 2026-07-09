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

        $display("Starting Pipelined CPU Skeleton Testbench...");
        clk = 0;
        rst = 1;
        
        #12;
        rst = 0;

        $display("Cycle | PC       | RegWrite | WriteReg | WriteData  | ALU Result");
        $display("----------------------------------------------------------------");

        // Run for 24 cycles to execute the entire program through all pipeline stages
        repeat (24) begin
            @(posedge clk); #1;
            $display("%5d | 32'h%h | %b        | 5'd%2d    | 32'h%h | 32'h%h",
                     $time/10, pc, reg_write, write_reg, write_data, alu_result);
        end

        // Assert register values
        $display("\nVerifying Registers after execution:");
        $display("x1 (expect 10)  = %0d", uut.regfile_inst.registers[1]);
        $display("x2 (expect 20)  = %0d", uut.regfile_inst.registers[2]);
        $display("x3 (expect 30)  = %0d", uut.regfile_inst.registers[3]);
        $display("x9 (expect 30)  = %0d", uut.regfile_inst.registers[9]);

        $display("\nVerifying Data Memory:");
        $display("dmem[8] (expect 30) = %0d", uut.dmem_inst.ram[2]); // word index 2 is byte index 8

        if (uut.regfile_inst.registers[1] == 10 &&
            uut.regfile_inst.registers[2] == 20 &&
            uut.regfile_inst.registers[3] == 30 &&
            uut.regfile_inst.registers[9] == 30 &&
            uut.dmem_inst.ram[2] == 30) begin
            $display("\nPIPELINE SKELETON VERIFICATION PASSED! 🎉");
        end else begin
            $display("\nPIPELINE SKELETON VERIFICATION FAILED! ❌");
        end
        $finish;
    end
endmodule