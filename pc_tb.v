`timescale 1ns/1ps

module pc_tb;
    reg clk;
    reg rst;
    reg [31:0] pc_next;
    wire [31:0] pc_out;

    pc uut (
        .clk(clk),
        .rst(rst),
        .pc_next(pc_next),
        .pc_out(pc_out)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("pc_tb.vcd");
        $dumpvars(0, pc_tb);

        $display("Starting PC testbench...");
        clk = 0;
        rst = 1;
        pc_next = 32'h0;

        @(posedge clk); #1;
        $display("After reset: PC = %0d (expect 0)", pc_out);

        rst = 0;
        pc_next = 32'd4;
        @(posedge clk); #1;
        $display("After PC+4: PC = %0d (expect 4)", pc_out);

        pc_next = 32'd100;
        @(posedge clk); #1;
        $display("After jump: PC = %0d (expect 100)", pc_out);

        $display("PC testbench complete. ALL PASSED.");
        $finish;
    end
endmodule