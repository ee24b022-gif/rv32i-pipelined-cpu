// 5-Stage Pipelined RV32I-Lite CPU (Pipeline Skeleton - Day 4)
module cpu (
    input wire clk,
    input wire rst,
    // Debug ports to print states in testbench
    output wire [31:0] out_pc,
    output wire [31:0] out_inst,
    output wire [31:0] out_alu_result,
    output wire [31:0] out_write_data,
    output wire [4:0] out_write_reg,
    output wire out_reg_write
);

    // =========================================================================
    // 1. FETCH (IF) STAGE
    // =========================================================================
    wire [31:0] pc_next;
    wire [31:0] pc_out;
    wire [31:0] pc_plus4_F;
    wire [31:0] inst_F;

    assign pc_plus4_F = pc_out + 32'd4;

    pc pc_inst (
        .clk(clk),
        .rst(rst),
        .pc_next(pc_next),
        .pc_out(pc_out)
    );

    imem imem_inst (
        .addr(pc_out),
        .rdata(inst_F)
    );

    // =========================================================================
    // IF/ID Pipeline Register
    // =========================================================================
    wire [31:0] pc_D, inst_D;
    
        if_id_reg if_id (
        .clk(clk), .rst(rst),
        .stall_D(1'b0),          // Tied to 0 for now (no stall)
        .flush_D(1'b0),          // Tied to 0 for now (no flush)
        .pc_in(pc_out), .inst_in(inst_F),
        .pc_out(pc_D), .inst_out(inst_D)
    );

    // =========================================================================
    // 2. DECODE (ID) STAGE
    // =========================================================================
    wire reg_write_D, alu_src_D, mem_write_D, mem_read_D, branch_D, jump_D;
    wire [1:0] mem_to_reg_D, alu_op_D, imm_src_D;
    wire [31:0] rdata1_D, rdata2_D, imm_ext_D;

    control_unit control_inst (
        .opcode(inst_D[6:0]),
        .reg_write(reg_write_D),
        .alu_src(alu_src_D),
        .mem_write(mem_write_D),
        .mem_read(mem_read_D),
        .mem_to_reg(mem_to_reg_D),
        .branch(branch_D),
        .jump(jump_D),
        .alu_op(alu_op_D),
        .imm_src(imm_src_D)
    );

    // RegFile Write signals come back from WB stage (W)
    wire reg_write_W;
    wire [4:0] rd_W;
    wire [31:0] wdata_W;

    regfile regfile_inst (
        .clk(clk),
        .we(reg_write_W),
        .raddr1(inst_D[19:15]),
        .raddr2(inst_D[24:20]),
        .waddr(rd_W),
        .wdata(wdata_W),
        .rdata1(rdata1_D),
        .rdata2(rdata2_D)
    );

    imm_gen imm_gen_inst (
        .inst(inst_D),
        .imm_src(imm_src_D),
        .imm_ext(imm_ext_D)
    );

    // =========================================================================
    // ID/EX Pipeline Register
    // =========================================================================
    wire reg_write_E, mem_read_E, mem_write_E, branch_E, jump_E, alu_src_E;
    wire [1:0] mem_to_reg_E, alu_op_E;
    wire [31:0] pc_E, rdata1_E, rdata2_E, imm_ext_E;
    wire [4:0] rs1_E, rs2_E, rd_E;
    wire [2:0] funct3_E;
    wire [6:0] funct7_E, opcode_E;

        id_ex_reg id_ex (
        .clk(clk), .rst(rst),
        .flush_E(1'b0),          // Tied to 0 for now (no flush)
        .reg_write_in(reg_write_D), .mem_to_reg_in(mem_to_reg_D),
        .mem_read_in(mem_read_D), .mem_write_in(mem_write_D),
        .branch_in(branch_D), .jump_in(jump_D),
        .alu_src_in(alu_src_D), .alu_op_in(alu_op_D),
        .pc_in(pc_D), .rdata1_in(rdata1_D), .rdata2_in(rdata2_D),
        .imm_ext_in(imm_ext_D),
        .rs1_in(inst_D[19:15]), .rs2_in(inst_D[24:20]), .rd_in(inst_D[11:7]),
        .funct3_in(inst_D[14:12]), .funct7_in(inst_D[31:25]), .opcode_in(inst_D[6:0]),
        
        .reg_write_out(reg_write_E), .mem_to_reg_out(mem_to_reg_E),
        .mem_read_out(mem_read_E), .mem_write_out(mem_write_E),
        .branch_out(branch_E), .jump_out(jump_E),
        .alu_src_out(alu_src_E), .alu_op_out(alu_op_E),
        .pc_out(pc_E), .rdata1_out(rdata1_E), .rdata2_out(rdata2_E),
        .imm_ext_out(imm_ext_E),
        .rs1_out(rs1_E), .rs2_out(rs2_E), .rd_out(rd_E),
        .funct3_out(funct3_E), .funct7_out(funct7_E), .opcode_out(opcode_E)
    );

    // =========================================================================
    // 3. EXECUTE (EX) STAGE
    // =========================================================================
    wire [3:0] alu_ctrl_E;
    wire [31:0] alu_op_b_E;
    wire [31:0] alu_result_E;
    wire zero_E;
    wire [31:0] branch_target_E;

    alu_control alu_control_inst (
        .alu_op(alu_op_E),
        .funct3(funct3_E),
        .funct7(funct7_E),
        .opcode(opcode_E),
        .alu_ctrl(alu_ctrl_E)
    );

    // ALU Input B Multiplexer
    assign alu_op_b_E = alu_src_E ? imm_ext_E : rdata2_E;

    alu alu_inst (
        .a(rdata1_E),
        .b(alu_op_b_E),
        .alu_ctrl(alu_ctrl_E),
        .result(alu_result_E),
        .zero(zero_E)
    );

    assign branch_target_E = pc_E + imm_ext_E;

    // Branches resolved in EX stage
    wire branch_taken_E;
    assign branch_taken_E = branch_E && ((funct3_E[0] == 1'b0 && zero_E) || (funct3_E[0] == 1'b1 && !zero_E));

    // PC Select Logic (routed back to IF stage)
    assign pc_next = (jump_E || branch_taken_E) ? branch_target_E : pc_plus4_F;

    // =========================================================================
    // EX/MEM Pipeline Register
    // =========================================================================
    wire reg_write_M, mem_read_M, mem_write_M, branch_M, jump_M, zero_M;
    wire [1:0] mem_to_reg_M;
    wire [31:0] pc_M, branch_target_M, alu_result_M, rdata2_M;
    wire [4:0] rd_M;
    wire [2:0] funct3_M;

    ex_mem_reg ex_mem (
        .clk(clk), .rst(rst),
        .reg_write_in(reg_write_E), .mem_to_reg_in(mem_to_reg_E),
        .mem_read_in(mem_read_E), .mem_write_in(mem_write_E),
        .branch_in(branch_E), .jump_in(jump_E),
        .pc_in(pc_E), .branch_target_in(branch_target_E),
        .alu_result_in(alu_result_E), .zero_in(zero_E), .rdata2_in(rdata2_E),
        .rd_in(rd_E), .funct3_in(funct3_E),
        
        .reg_write_out(reg_write_M), .mem_to_reg_out(mem_to_reg_M),
        .mem_read_out(mem_read_M), .mem_write_out(mem_write_M),
        .branch_out(branch_M), .jump_out(jump_M),
        .pc_out(pc_M), .branch_target_out(branch_target_M),
        .alu_result_out(alu_result_M), .zero_out(zero_M), .rdata2_out(rdata2_M),
        .rd_out(rd_M), .funct3_out(funct3_M)
    );

    // =========================================================================
    // 4. MEMORY (MEM) STAGE
    // =========================================================================
    wire [31:0] rdata_mem_M;

    dmem dmem_inst (
        .clk(clk),
        .mem_write(mem_write_M),
        .mem_read(mem_read_M),
        .addr(alu_result_M),
        .wdata(rdata2_M),
        .rdata(rdata_mem_M)
    );

    // =========================================================================
    // MEM/WB Pipeline Register
    // =========================================================================
    wire [1:0] mem_to_reg_W;
    wire [31:0] alu_result_W, rdata_mem_W, pc_W;

    mem_wb_reg mem_wb (
        .clk(clk), .rst(rst),
        .reg_write_in(reg_write_M), .mem_to_reg_in(mem_to_reg_M),
        .alu_result_in(alu_result_M), .rdata_mem_in(rdata_mem_M),
        .rd_in(rd_M), .pc_in(pc_M),
        
        .reg_write_out(reg_write_W), .mem_to_reg_out(mem_to_reg_W),
        .alu_result_out(alu_result_W), .rdata_mem_out(rdata_mem_W),
        .rd_out(rd_W), .pc_out(pc_W)
    );

    // =========================================================================
    // 5. WRITE BACK (WB) STAGE
    // =========================================================================
    assign wdata_W = (mem_to_reg_W == 2'b10) ? (pc_W + 32'd4) :
                     (mem_to_reg_W == 2'b01) ? rdata_mem_W :
                     alu_result_W;

    // =========================================================================
    // Debug output assignments (points to the retiring write-back stage)
    // =========================================================================
    assign out_pc = pc_W;
    assign out_inst = 32'b0; // set to 0 for simplified pipeline trace
    assign out_alu_result = alu_result_W;
    assign out_write_data = wdata_W;
    assign out_write_reg = rd_W;
    assign out_reg_write = reg_write_W;

endmodule