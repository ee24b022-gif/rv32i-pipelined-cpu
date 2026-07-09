`timescale 1ns/1ps

module dmem_tb;
    reg clk;
    reg mem_write;
    reg mem_read;
    reg [31:0] addr;
    reg [31:0] wdata;
    
    wire [31:0] rdata;

    // Instantiate UUT
    dmem uut (
        .clk(clk),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata)
    );

    // Toggle clock every 5ns
    always #5 clk = ~clk;

    initial begin
        $dumpfile("dmem_tb.vcd");
        $dumpvars(0, dmem_tb);

        $display("Starting Data Memory testbench...");
        clk = 0;
        mem_write = 0;
        mem_read = 0;
        addr = 32'h0;
        wdata = 32'h0;
        #1;

        // Test 1: Read uninitialized address 4 (expect 0)
        addr = 32'd4;
        mem_read = 1;
        #5;
        $display("Read empty addr 4: rdata = %h (expect 00000000)", rdata);

        // Test 2: Write CAFEBABE to address 4
        @(posedge clk); #1;
        mem_write = 1;
        mem_read = 0; // standard practice: disable read during write
        wdata = 32'hCAFEBABE;

        @(posedge clk); #1;
        mem_write = 0;
        mem_read = 1;
        #5;
        $display("Read back addr 4:  rdata = %h (expect CAFEBABE)", rdata);

        // Test 3: Attempt write with mem_write=0 (should fail to overwrite)
        @(posedge clk); #1;
        wdata = 32'hDEADBEEF; // try to write DEADBEEF
        
        @(posedge clk); #1;
        mem_read = 1;
        #5;
        $display("Read after disabled write: rdata = %h (expect CAFEBABE)", rdata);

        // Test 4: Out-of-bounds read (expect 0)
        addr = 32'd256;
        #5;
        $display("Out-of-bounds read: rdata = %h (expect 00000000)", rdata);

        $display("Data Memory testbench complete.");
        $finish;
    end
endmodule