// Register File (RegFile)
// - 32 registers of 32-bit width.
// - x0 is hardwired to 0 (reads return 0, writes are ignored).
// - Read ports (rs1, rs2) are read asynchronously.
// - Write port (rd) updates on the rising clock edge when we (write-enable) is high.
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

    // Asynchronous reads: if address is 0, return 0; else return register value
    assign rdata1 = (raddr1 == 5'b0) ? 32'b0 : registers[raddr1];
    assign rdata2 = (raddr2 == 5'b0) ? 32'b0 : registers[raddr2];

    // Initialize all registers to 0 for a clean simulation startup
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 32'b0;
        end
    end

    // Synchronous write: occurs on rising edge of clk if enabled, ignoring x0
    always @(posedge clk) begin
        if (we && (waddr != 5'b0)) begin
            registers[waddr] <= wdata;
        end
    end

endmodule