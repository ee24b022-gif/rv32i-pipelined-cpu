// Instruction Memory (IMEM)
// A 64-word (256-byte) ROM loaded with your machine instructions via $readmemh.
// It takes a 32-bit byte address and outputs a 32-bit instruction.
module imem (
    input wire [31:0] addr,
    output wire [31:0] rdata
);
    reg [31:0] rom [0:63];

    initial begin
        // Loads program instructions in hex format from a text file
        $readmemh("imem.hex", rom);
    end

    // Standard RISC-V instructions are 32-bit (4-byte) aligned.
    // We shift the byte address right by 2 (divide by 4) to index our word array.
    // If the address is out of bounds, we return a NOP instruction (32'h00000000).
    assign rdata = (addr[31:8] == 24'b0) ? rom[addr[7:2]] : 32'b0;

endmodule