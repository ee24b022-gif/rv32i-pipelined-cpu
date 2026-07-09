`timescale 1ns/1ps

module regfile_tb;
    reg clk;
    reg we;
    reg [4:0] raddr1;
    reg [4:0] raddr2;
    reg [4:0] waddr;
    reg [31:0] wdata;
    
    wire [31:0] rdata1;
    wire [31:0] rdata2;

    // Instantiate UUT
    regfile uut (
        .clk(clk),
        .we(we),
        .raddr1(raddr1),
        .raddr2(raddr2),
        .waddr(waddr),
        .wdata(wdata),
        .rdata1(rdata1),
        .rdata2(rdata2)
    );

    // Toggle clock every 5ns
    always #5 clk = ~clk;

    initial begin
        $dumpfile("regfile_tb.vcd");
        $dumpvars(0, regfile_tb);

        $display("Starting Register File testbench...");
        clk = 0;
        we = 0;
        raddr1 = 5'd0;
        raddr2 = 5'd5;
        waddr = 5'd0;
        wdata = 32'h0;
        #1;

        // Test 1: Check initial zeros
        $display("Init: x0 = %h, x5 = %h (expect both 0)", rdata1, rdata2);

        // Test 2: Write 32'hDEADBEEF to x5 (should succeed)
        @(posedge clk); #1;
        we = 1;
        waddr = 5'd5;
        wdata = 32'hDEADBEEF;
        raddr1 = 5'd5; // monitor x5 asynchronously

        @(posedge clk); #1;
        $display("After write: x5 = %h (expect DEADBEEF)", rdata1);

        // Test 3: Write 32'hCAFEBABE to x0 (should be ignored)
        waddr = 5'd0;
        wdata = 32'hCAFEBABE;
        raddr1 = 5'd0; // monitor x0

        @(posedge clk); #1;
        $display("After write to x0: x0 = %h (expect 00000000)", rdata1);

        // Test 4: Write to x10 with we=0 (should be ignored)
        we = 0;
        waddr = 5'd10;
        wdata = 32'h12345678;
        raddr2 = 5'd10; // monitor x10

        @(posedge clk); #1;
        $display("After write (we=0): x10 = %h (expect 00000000)", rdata2);

        $display("Register File testbench complete.");
        $finish;
    end
endmodule