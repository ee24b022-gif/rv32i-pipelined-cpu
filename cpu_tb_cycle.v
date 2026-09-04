`timescale 1ns/1ps

// Cycle-accurate testbench for RV32I-Lite CPU verification
// Dumps all 32 registers EVERY CYCLE for cycle-by-cycle diffing against
// the golden model. Each cycle's dump is bracketed by markers so the
// verification script can parse individual cycle snapshots.
//
// Usage:
//   iverilog -o cpu_cycle_sim -D NUM_CYCLES=<N> \
//       hazard_detection.v forwarding.v pipeline_regs.v cpu.v pc.v imem.v \
//       regfile.v imm_gen.v control_unit.v alu_control.v alu.v dmem.v \
//       cpu_tb_cycle.v
//   vvp cpu_cycle_sim

module cpu_tb_cycle;
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
    integer cycle;

    // Allow NUM_CYCLES to be set via -D flag; default to 60
    `ifndef NUM_CYCLES
        `define NUM_CYCLES 60
    `endif

    initial begin
        $dumpfile("cpu_cycle_tb.vcd");
        $dumpvars(0, cpu_tb_cycle);

        clk = 0;
        rst = 1;

        #12;
        rst = 0;

        for (cycle = 0; cycle < `NUM_CYCLES; cycle = cycle + 1) begin
            @(posedge clk); #1;

            // Emit cycle-bracketed register dump
            $display("--- CYCLE %0d ---", cycle);
            for (i = 0; i < 32; i = i + 1) begin
                $display("x%0d = %0d", i, uut.regfile_inst.registers[i]);
            end
            $display("--- END CYCLE %0d ---", cycle);
        end

        // Final end-of-program dump (same format as cpu_tb.v for compatibility)
        $display("\n--- REGISTER DUMP ---");
        for (i = 0; i < 32; i = i + 1) begin
            $display("x%0d = %0d", i, uut.regfile_inst.registers[i]);
        end
        $display("--- MEMORY DUMP ---");
        $display("dmem[0] = %0d", uut.dmem_inst.ram[0]);
        $display("dmem[4] = %0d", uut.dmem_inst.ram[1]);
        $display("dmem[8] = %0d", uut.dmem_inst.ram[2]);

        $finish;
    end
endmodule
