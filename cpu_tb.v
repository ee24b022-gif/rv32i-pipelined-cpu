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

    integer i;

    initial begin
        $dumpfile("cpu_tb.vcd");
        $dumpvars(0, cpu_tb);

        clk = 0;
        rst = 1;
        
        #12;
        rst = 0;

        // Run for 55 cycles to drain the program fully
        repeat (55) begin
            @(posedge clk); #1;
        end

        // Dump registers for Python verification
        $display("\n--- REGISTER DUMP ---");
        for (i = 0; i < 32; i = i + 1) begin
            $display("x%0d = %0d", i, uut.regfile_inst.registers[i]);
        end
        $display("--- MEMORY DUMP ---");
        $display("dmem[8] = %0d", uut.dmem_inst.ram[2]);

        $finish;
    end
endmodule