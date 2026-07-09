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

    initial begin
        $dumpfile("cpu_tb.vcd");
        $dumpvars(0, cpu_tb);

        $display("Starting Pipelined CPU Loop / Branch Flush Testbench...");
        clk = 0;
        rst = 1;
        
        #12;
        rst = 0;

        // Run for 55 cycles to allow the loop to run 5 times and terminate
        repeat (55) begin
            @(posedge clk); #1;
        end

        // Assert register values
        $display("\nVerifying Registers after Loop Execution:");
        $display("x1 (expect 0)   = %0d (loop counter decremented to 0)", uut.regfile_inst.registers[1]);
        $display("x2 (expect 1)   = %0d", uut.regfile_inst.registers[2]);
        $display("x3 (expect 15)  = %0d (sum of 5+4+3+2+1)", uut.regfile_inst.registers[3]);
        $display("x4 (expect 100) = %0d (loop exit success)", uut.regfile_inst.registers[4]);

        if (uut.regfile_inst.registers[1] == 0 &&
            uut.regfile_inst.registers[2] == 1 &&
            uut.regfile_inst.registers[3] == 15 &&
            uut.regfile_inst.registers[4] == 100) begin
            $display("\nLOOP AND BRANCH FLUSH VERIFICATION PASSED! 🎉");
        end else begin
            $display("\nLOOP AND BRANCH FLUSH VERIFICATION FAILED! ❌");
        end
        $finish;
    end
endmodule