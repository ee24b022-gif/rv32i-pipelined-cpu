`timescale 1ns/1ps

module imem_tb;
    reg [31:0] addr;
    wire [31:0] rdata;

    // Instantiate UUT
    imem uut (
        .addr(addr),
        .rdata(rdata)
    );

    initial begin
        $dumpfile("imem_tb.vcd");
        $dumpvars(0, imem_tb);

        $display("Starting Instruction Memory testbench...");

        // Test 1: Read address 0 (should return DEADBEEF)
        addr = 32'd0;
        #10;
        $display("Addr %0d: rdata = %h (expect DEADBEEF)", addr, rdata);

        // Test 2: Read address 4 (should return CAFEBABE)
        addr = 32'd4;
        #10;
        $display("Addr %0d: rdata = %h (expect CAFEBABE)", addr, rdata);

        // Test 3: Unaligned read at address 1 (should round down to 0 and return DEADBEEF)
        addr = 32'd1;
        #10;
        $display("Addr %0d (unaligned): rdata = %h (expect DEADBEEF)", addr, rdata);

        // Test 4: Out-of-bounds read (should return 00000000 / NOP)
        addr = 32'd256;
        #10;
        $display("Addr %0d (out of bounds): rdata = %h (expect 00000000)", addr, rdata);

        $display("IMEM testbench complete.");
        $finish;
    end
endmodule