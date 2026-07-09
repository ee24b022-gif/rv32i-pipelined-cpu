// Top-Level Single-Cycle RISC-V CPU
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

    // Interconnect wires
    wire [31:0] pc_next;
    wire [31:0] pc_out;
    wire [31:0] pc_plus4;
    wire [31:0] branch_target;
    wire [31:0] inst;

    // Control Unit wires
    wire reg_write;
    wire alu_src;
    wire mem_write;
    wire mem_read;
    wire [1:0] mem_to_reg;
    wire branch;
    wire jump;
    wire [1:0] alu_op;
    wire [1:0] imm_src;
    wire [3:0] alu_ctrl;

    // Register File wires
    wire [31:0] rdata1;
    wire [31:0] rdata2;
    wire [31:0] wdata;

    // Immediate Generator wire
    wire [31:0] imm_ext;

    // ALU wires
    wire [31:0] alu_op_b;
    wire [31:0] alu_result;
    wire zero;

    // Data Memory wire
    wire [31:0] rdata_mem;

    // --- Control and Datapath Logic ---

    // PC update logic: PC = PC+4 (normal) or PC+imm (JAL or Branch Taken)
    wire branch_taken;
    // inst[12] is funct3[0]: BEQ (0) or BNE (1)
    assign branch_taken = branch && ((inst[12] == 1'b0 && zero) || (inst[12] == 1'b1 && !zero));
    
    assign pc_plus4 = pc_out + 32'd4;
    assign branch_target = pc_out + imm_ext;
    assign pc_next = (jump || branch_taken) ? branch_target : pc_plus4;

    // Register File Write Back Multiplexer
    assign wdata = (mem_to_reg == 2'b10) ? pc_plus4 :
                   (mem_to_reg == 2'b01) ? rdata_mem :
                   alu_result;

    // ALU Input B Multiplexer
    assign alu_op_b = alu_src ? imm_ext : rdata2;

    // --- Module Instantiations ---

    // 1. Program Counter
    pc pc_inst (
        .clk(clk),
        .rst(rst),
        .pc_next(pc_next),
        .pc_out(pc_out)
    );

    // 2. Instruction Memory
    imem imem_inst (
        .addr(pc_out),
        .rdata(inst)
    );

    // 3. Control Unit
    control_unit control_inst (
        .opcode(inst[6:0]),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .jump(jump),
        .alu_op(alu_op),
        .imm_src(imm_src)
    );

    // 4. ALU Control
    alu_control alu_control_inst (
        .alu_op(alu_op),
        .funct3(inst[14:12]),
        .funct7(inst[31:25]),
        .opcode(inst[6:0]),
        .alu_ctrl(alu_ctrl)
    );

    // 5. Register File
    regfile regfile_inst (
        .clk(clk),
        .we(reg_write),
        .raddr1(inst[19:15]),
        .raddr2(inst[24:20]),
        .waddr(inst[11:7]),
        .wdata(wdata),
        .rdata1(rdata1),
        .rdata2(rdata2)
    );

    // 6. Immediate Generator
    imm_gen imm_gen_inst (
        .inst(inst),
        .imm_src(imm_src),
        .imm_ext(imm_ext)
    );

    // 7. ALU
    alu alu_inst (
        .a(rdata1),
        .b(alu_op_b),
        .alu_ctrl(alu_ctrl),
        .result(alu_result),
        .zero(zero)
    );

    // 8. Data Memory
    dmem dmem_inst (
        .clk(clk),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .addr(alu_result),
        .wdata(rdata2),
        .rdata(rdata_mem)
    );

    // Debug output assignments
    assign out_pc = pc_out;
    assign out_inst = inst;
    assign out_alu_result = alu_result;
    assign out_write_data = wdata;
    assign out_write_reg = inst[11:7];
    assign out_reg_write = reg_write;

endmodule