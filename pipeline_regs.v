// Pipelined Registers with Stall and Flush Control (Day 5)

// 1. IF/ID Pipeline Register
module if_id_reg (
    input wire clk,
    input wire rst,
    input wire stall_D,             // 1: Freeze PC and instruction in ID stage
    input wire flush_D,             // 1: Clear instruction to NOP
    input wire [31:0] pc_in,
    input wire [31:0] inst_in,
    output reg [31:0] pc_out,
    output reg [31:0] inst_out
);
    always @(posedge clk) begin
        if (rst || flush_D) begin
            pc_out   <= 32'b0;
            inst_out <= 32'b0;
        end else if (!stall_D) begin
            pc_out   <= pc_in;
            inst_out <= inst_in;
        end
        // If stall_D is 1, it holds its previous value (no change)
    end
endmodule

// 2. ID/EX Pipeline Register
module id_ex_reg (
    input wire clk,
    input wire rst,
    input wire flush_E,             // 1: Clear all control signals to 0 (insert bubble)
    
    // Control In
    input wire reg_write_in,
    input wire [1:0] mem_to_reg_in,
    input wire mem_read_in,
    input wire mem_write_in,
    input wire branch_in,
    input wire jump_in,
    input wire alu_src_in,
    input wire [1:0] alu_op_in,
    
    // Datapath In
    input wire [31:0] pc_in,
    input wire [31:0] rdata1_in,
    input wire [31:0] rdata2_in,
    input wire [31:0] imm_ext_in,
    input wire [4:0] rs1_in,
    input wire [4:0] rs2_in,
    input wire [4:0] rd_in,
    input wire [2:0] funct3_in,
    input wire [6:0] funct7_in,
    input wire [6:0] opcode_in,
    
    // Control Out
    output reg reg_write_out,
    output reg [1:0] mem_to_reg_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg branch_out,
    output reg jump_out,
    output reg alu_src_out,
    output reg [1:0] alu_op_out,
    
    // Datapath Out
    output reg [31:0] pc_out,
    output reg [31:0] rdata1_out,
    output reg [31:0] rdata2_out,
    output reg [31:0] imm_ext_out,
    output reg [4:0] rs1_out,
    output reg [4:0] rs2_out,
    output reg [4:0] rd_out,
    output reg [2:0] funct3_out,
    output reg [6:0] funct7_out,
    output reg [6:0] opcode_out
);
    always @(posedge clk) begin
        if (rst || flush_E) begin
            // Clear all control signals (inject bubble)
            reg_write_out  <= 1'b0;
            mem_to_reg_out <= 2'b00;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            branch_out     <= 1'b0;
            jump_out       <= 1'b0;
            alu_src_out    <= 1'b0;
            alu_op_out     <= 2'b00;
            // Clear datapath fields
            pc_out         <= 32'b0;
            rdata1_out     <= 32'b0;
            rdata2_out     <= 32'b0;
            imm_ext_out    <= 32'b0;
            rs1_out        <= 5'b0;
            rs2_out        <= 5'b0;
            rd_out         <= 5'b0;
            funct3_out     <= 3'b0;
            funct7_out     <= 7'b0;
            opcode_out     <= 7'b0;
        end else begin
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            branch_out     <= branch_in;
            jump_out       <= jump_in;
            alu_src_out    <= alu_src_in;
            alu_op_out     <= alu_op_in;
            pc_out         <= pc_in;
            rdata1_out     <= rdata1_in;
            rdata2_out     <= rdata2_in;
            imm_ext_out    <= imm_ext_in;
            rs1_out        <= rs1_in;
            rs2_out        <= rs2_in;
            rd_out         <= rd_in;
            funct3_out     <= funct3_in;
            funct7_out     <= funct7_in;
            opcode_out     <= opcode_in;
        end
    end
endmodule

// 3. EX/MEM Pipeline Register (unchanged, as we do not need to stall/flush MEM)
module ex_mem_reg (
    input wire clk,
    input wire rst,
    input wire reg_write_in,
    input wire [1:0] mem_to_reg_in,
    input wire mem_read_in,
    input wire mem_write_in,
    input wire branch_in,
    input wire jump_in,
    input wire [31:0] pc_in,
    input wire [31:0] branch_target_in,
    input wire [31:0] alu_result_in,
    input wire zero_in,
    input wire [31:0] rdata2_in,
    input wire [4:0] rd_in,
    input wire [2:0] funct3_in,
    output reg reg_write_out,
    output reg [1:0] mem_to_reg_out,
    output reg mem_read_out,
    output reg mem_write_out,
    output reg branch_out,
    output reg jump_out,
    output reg [31:0] pc_out,
    output reg [31:0] branch_target_out,
    output reg [31:0] alu_result_out,
    output reg zero_out,
    output reg [31:0] rdata2_out,
    output reg [4:0] rd_out,
    output reg [2:0] funct3_out
);
    always @(posedge clk) begin
        if (rst) begin
            reg_write_out     <= 1'b0;
            mem_to_reg_out    <= 2'b00;
            mem_read_out      <= 1'b0;
            mem_write_out     <= 1'b0;
            branch_out        <= 1'b0;
            jump_out          <= 1'b0;
            pc_out            <= 32'b0;
            branch_target_out <= 32'b0;
            alu_result_out    <= 32'b0;
            zero_out          <= 1'b0;
            rdata2_out        <= 32'b0;
            rd_out            <= 5'b0;
            funct3_out        <= 3'b0;
        end else begin
            reg_write_out     <= reg_write_in;
            mem_to_reg_out    <= mem_to_reg_in;
            mem_read_out      <= mem_read_in;
            mem_write_out     <= mem_write_in;
            branch_out        <= branch_in;
            jump_out          <= jump_in;
            pc_out            <= pc_in;
            branch_target_out <= branch_target_in;
            alu_result_out    <= alu_result_in;
            zero_out          <= zero_in;
            rdata2_out        <= rdata2_in;
            rd_out            <= rd_in;
            funct3_out        <= funct3_in;
        end
    end
endmodule

// 4. MEM/WB Pipeline Register (unchanged)
module mem_wb_reg (
    input wire clk,
    input wire rst,
    input wire reg_write_in,
    input wire [1:0] mem_to_reg_in,
    input wire [31:0] alu_result_in,
    input wire [31:0] rdata_mem_in,
    input wire [4:0] rd_in,
    input wire [31:0] pc_in,
    output reg reg_write_out,
    output reg [1:0] mem_to_reg_out,
    output reg [31:0] alu_result_out,
    output reg [31:0] rdata_mem_out,
    output reg [4:0] rd_out,
    output reg [31:0] pc_out
);
    always @(posedge clk) begin
        if (rst) begin
            reg_write_out  <= 1'b0;
            mem_to_reg_out <= 2'b00;
            alu_result_out <= 32'b0;
            rdata_mem_out  <= 32'b0;
            rd_out         <= 5'b0;
            pc_out         <= 32'b0;
        end else begin
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            alu_result_out <= alu_result_in;
            rdata_mem_out  <= rdata_mem_in;
            rd_out         <= rd_in;
            pc_out         <= pc_in;
        end
    end
endmodule