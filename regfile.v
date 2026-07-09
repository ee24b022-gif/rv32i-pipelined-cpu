// Register File with Internal Write-to-Read Bypassing (Write-First)
module regfile (
    input wire clk,
    input wire we,                  // write enable
    input wire [4:0] raddr1,        // rs1 read address
    input wire [4:0] raddr2,        // rs2 read address
    input wire [4:0] waddr,         // rd write address
    input wire [31:0] wdata,        // write data
    output wire [31:0] rdata1,      // rs1 read data output
    output wire [31:0] rdata2       // rs2 read data output
);
    reg [31:0] registers [0:31];

    // Asynchronous reads with internal bypassing:
    // If we are currently writing to the same register we are reading (and it's not x0),
    // output the write data (wdata) immediately instead of the stale register value.
    assign rdata1 = (we && (waddr == raddr1) && (raddr1 != 5'b0)) ? wdata : 
                    ((raddr1 == 5'b0) ? 32'b0 : registers[raddr1]);

    assign rdata2 = (we && (waddr == raddr2) && (raddr2 != 5'b0)) ? wdata : 
                    ((raddr2 == 5'b0) ? 32'b0 : registers[raddr2]);

    // Initialize all registers to 0
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 32'b0;
        end
    end

    // Synchronous write
    always @(posedge clk) begin
        if (we && (waddr != 5'b0)) begin
            registers[waddr] <= wdata;
        end
    end

endmodule