// Forwarding Unit (Day 6)
// Resolves Read-After-Write (RAW) data hazards by routing data directly 
// from MEM and WB stages back to the ALU inputs in the EX stage.
module forwarding (
    input wire [4:0] rs1_E,         // rs1 address in EX stage
    input wire [4:0] rs2_E,         // rs2 address in EX stage
    input wire [4:0] rd_M,          // rd destination address in MEM stage
    input wire reg_write_M,         // RegWrite signal in MEM stage
    input wire [4:0] rd_W,          // rd destination address in WB stage
    input wire reg_write_W,         // RegWrite signal in WB stage
    output reg [1:0] forward_a,     // Selector for ALU Input A mux
    output reg [1:0] forward_b      // Selector for ALU Input B mux
);

    always @(*) begin
        // --- Forwarding Logic for ALU Input A ---
        
        // 1. EX Hazard (from MEM stage): Prioritize most recent result
        if (reg_write_M && (rd_M != 5'b0) && (rd_M == rs1_E)) begin
            forward_a = 2'b01; // Forward from MEM stage
        end
        // 2. MEM Hazard (from WB stage)
        else if (reg_write_W && (rd_W != 5'b0) && (rd_W == rs1_E)) begin
            forward_a = 2'b10; // Forward from WB stage
        end
        // 3. No Hazard: Read from register file
        else begin
            forward_a = 2'b00;
        end

        // --- Forwarding Logic for ALU Input B ---
        
        // 1. EX Hazard (from MEM stage): Prioritize most recent result
        if (reg_write_M && (rd_M != 5'b0) && (rd_M == rs2_E)) begin
            forward_b = 2'b01; // Forward from MEM stage
        end
        // 2. MEM Hazard (from WB stage)
        else if (reg_write_W && (rd_W != 5'b0) && (rd_W == rs2_E)) begin
            forward_b = 2'b10; // Forward from WB stage
        end
        // 3. No Hazard: Read from register file
        else begin
            forward_b = 2'b00;
        end
    end
endmodule