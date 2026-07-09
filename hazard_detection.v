// Hazard Detection Unit (Day 7)
// Detects load-use hazards (LW instruction followed immediately by a dependent instruction)
// and stalls the pipeline for 1 clock cycle to allow the memory load to complete.
module hazard_detection (
    input wire [4:0] rs1_D,         // rs1 address in Decode stage
    input wire [4:0] rs2_D,         // rs2 address in Decode stage
    input wire [4:0] rd_E,          // rd destination register in Execute stage
    input wire mem_read_E,          // 1: Instruction in EX is a load (LW)
    output reg stall_F,             // 1: Freeze PC register
    output reg stall_D,             // 1: Freeze IF/ID register
    output reg flush_E              // 1: Clear ID/EX register (insert bubble)
);

    always @(*) begin
        // If the instruction in EX is a load (mem_read_E is high)
        // and its destination (rd_E) is read by the instruction in Decode (rs1_D or rs2_D)
        // and it's not x0, we must stall the pipeline.
        if (mem_read_E && (rd_E != 5'b0) && ((rd_E == rs1_D) || (rd_E == rs2_D))) begin
            stall_F = 1'b1;  // Freeze PC
            stall_D = 1'b1;  // Freeze IF/ID register (keeps instruction in ID stage)
            flush_E = 1'b1;  // Inject bubble in EX stage
        end else begin
            stall_F = 1'b0;
            stall_D = 1'b0;
            flush_E = 1'b0;
        end
    end
endmodule