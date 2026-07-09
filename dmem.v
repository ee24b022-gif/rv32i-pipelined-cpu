// Data Memory (DMEM)
// - 64-word (256-byte) RAM initialized to 0.
// - Synchronous writes on rising edge of clk if mem_write is high.
// - Asynchronous reads if mem_read is high.
module dmem (
    input wire clk,
    input wire mem_write,           // write enable
    input wire mem_read,            // read enable
    input wire [31:0] addr,         // byte address
    input wire [31:0] wdata,        // write data
    output wire [31:0] rdata        // read data
);
    reg [31:0] ram [0:63];

    // Asynchronous read: output RAM value if enabled and in-bounds; else output 0
    assign rdata = (mem_read && (addr[31:8] == 24'b0)) ? ram[addr[7:2]] : 32'b0;

    // Initialize all memory locations to 0
    integer i;
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            ram[i] = 32'b0;
        end
    end

    // Synchronous write
    always @(posedge clk) begin
        if (mem_write && (addr[31:8] == 24'b0)) begin
            ram[addr[7:2]] <= wdata;
        end
    end

endmodule