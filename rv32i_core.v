



module rv32i_core (
    input clk,
    input rst,
    input rst_im,
    input write_en,
    input [9:0] write_addr,
    input [31:0] write_data,
    output [31:0] pc,
    output [31:0] s_alu_result_out ,
    output [31:0] s_load_data_out ,
    output [4:0] s_rd_out ,
    output s_wb_reg_file_out,
    output s_memtoreg_out
    );
    // -------------------------
    // IF Stage <-> IF/ID wires
    // -------------------------
    wire [31:0] pc_if;
    wire [31:0] instr_if;
    wire predictedTaken_if;

    // -------------------------
    // Hazard wires
    // -------------------------
    wire hazard_pc_en;
    wire hazard_id_ex_flush;

    // -------------------------
    // IF/ID pipeline regs
    // -------------------------
    wire [31:0] pc_id;
    wire [31:0] instr_id;
    wire predictedTaken_id;

    // -------------------------
    // Decode outputs (top_decode)
    // -------------------------
    wire [31:0] imm_id;
    wire [31:0] rs1_data_id;
    wire [31:0] rs2_data_id;

    // Control outputs from top_decode
    wire ex_alu_src_id;
    wire mem_write_id;
    wire [2:0] mem_load_type_id;
    wire [1:0] mem_store_type_id;
    wire wb_reg_file_id;
    wire memtoreg_id;
    wire branch_id;
    wire jal_id;
    wire jalr_id;
    wire [3:0] alu_ctrl_id;

    // -------------------------
    // ID/EX pipeline regs
    // -------------------------
    wire [31:0] pc_ex;
    wire predictedTaken_ex;

    wire [2:0] func3_ex;
    wire [4:0] rd_ex;
    wire [4:0] rs1_addr_ex;
    wire [4:0] rs2_addr_ex;
    wire [31:0] imm_ex;
    wire [31:0] rs1_data_ex;
    wire [31:0] rs2_data_ex;

    wire ex_alu_src_ex;
    wire mem_write_ex;
    wire [2:0] mem_load_type_ex;
    wire [1:0] mem_store_type_ex;
    wire wb_reg_file_ex;
    wire memtoreg_ex;
    wire branch_ex_wires;
    wire jal_ex;
    wire jalr_ex;
    wire [3:0] alu_ctrl_ex;

    // -------------------------
    // Forwarding control
    // -------------------------
    wire [1:0] operand_a_forward_cntl;
    wire [1:0] operand_b_forward_cntl;

    // -------------------------
    // EX outputs and ALU flags
    // -------------------------
    wire [31:0] alu_result_ex;
    wire zero_flag_ex;
    wire negative_flag_ex;
    wire carry_flag_ex;
    wire overflow_flag_ex;
    wire [31:0] rs2_data_for_mem_ex;
    wire [31:0] op1_selected_ex;

    // -------------------------
    // Branch unit outputs (direct from EX)
    // -------------------------
    wire ex_branch_taken;
    wire ex_modify_pc;
    wire [31:0] ex_update_pc;
    wire [31:0] ex_jump_addr;
    wire ex_update_btb;

    // -------------------------
    // EX/MEM pipeline regs
    // -------------------------
    wire [31:0] alu_result_mem;
    wire [31:0] rs2_data_mem;
    wire [4:0] rd_mem;
    wire mem_write_mem;
    wire [2:0] mem_load_type_mem;
    wire [1:0] mem_store_type_mem;
    wire wb_reg_file_mem;
    wire memtoreg_mem;

    // -------------------------
    // MEM stage outputs
    // -------------------------
   // wire [31:0] alu_result_for_wb;
    wire [31:0] load_wb_data;
  //  wire [4:0] rd_for_wb;
  //  wire wb_reg_file_out;
  //  wire memtoreg_out;

    // -------------------------
    // MEM/WB pipeline regs
    // -------------------------
    wire [31:0] alu_result_wb;
    wire [31:0] load_data_wb;
    wire [4:0] rd_wb;
    wire wb_reg_file_wb;
    wire memtoreg_wb;

    // -------------------------
    // Forwarding sources
    // -------------------------
    wire [31:0] data_forward_mem;
    wire [31:0] data_forward_wb;

    // -------------------------
    // WB stage outputs to regfile
    // -------------------------
    wire [31:0] wb_write_data;
    wire [4:0] wb_write_addr;
    wire wb_write_en;

    // =====================================================
    // 1) IF stage
    // =====================================================
    if_stage_simple_btb u_if (
        .clk(clk),
        .rst(rst),
        .pc_en(hazard_pc_en),
        .modify_pc_ex(ex_modify_pc),
        .update_pc_ex(ex_update_pc),
        .pc_ex(pc_ex[31:2]),
        .jump_addr_ex(ex_jump_addr),
        .update_btb_ex(ex_update_btb),
        .ex_branch_taken(ex_branch_taken),
        .pc_if(pc_if),
        .instr_if(instr_if),
        .predictedTaken_if(predictedTaken_if),
        .write_en(write_en),
        .write_addr(write_addr),
        .write_data(write_data),
        .rst_im(rst_im)
    );

    assign pc = pc_if;

    // =====================================================
    // 2) IF/ID pipeline register
    // =====================================================
    if_id_pipe u_if_id (
        .clk(clk), .rst(rst),
        .en(hazard_pc_en),
        .flush(hazard_id_ex_flush),
        .pc_in(pc_if),
        .instr_in(instr_if),
        .predictedTaken_in(predictedTaken_if),
        .pc_id(pc_id),
        .instr_id(instr_id),
        .predictedTaken_id(predictedTaken_id)
    );

    // =====================================================
    // 3) Decode stage
    // =====================================================
    top_decode u_decode (
        .clk(clk),
        .instruction_in(instr_id),
       // .id_flush(hazard_id_ex_flush),
        .wb_wr_en(wb_write_en),
        .wb_wr_addr(wb_write_addr),
        .wb_wr_data(wb_write_data),
        .imm_out(imm_id),
        .rs1_data(rs1_data_id),
        .rs2_data(rs2_data_id),
        .ex_alu_src(ex_alu_src_id),
        .mem_write(mem_write_id),
        .mem_load_type(mem_load_type_id),
        .mem_store_type(mem_store_type_id),
        .wb_reg_file(wb_reg_file_id),
        .memtoreg(memtoreg_id),
        .Branch_1(branch_id),
        .jal(jal_id),
        .jalr(jalr_id),
        .alu_ctrl(alu_ctrl_id)
    );

    // =====================================================
    // 4) Hazard unit
    // =====================================================
    hazard_unit u_hazard (
        .id_rs1(instr_id[19:15]),
        .id_rs2(instr_id[24:20]),
        .opcode_id(instr_id[6:0]),
        .modify_pc_ex(ex_modify_pc),
        .pc_en(hazard_pc_en),
        .ex_rd(rd_ex),
    .ex_load_inst(memtoreg_ex),
        
        .id_ex_flush(hazard_id_ex_flush)
    );

    // =====================================================
    // 5) ID/EX pipeline register
    // =====================================================
    id_ex_pipe u_id_ex (
        .clk(clk), .rst(rst),
        .en(hazard_pc_en),
        .flush(hazard_id_ex_flush),
        .pc_id(pc_id),
        .predictedTaken_id(predictedTaken_id),
        .func3(instr_id[14:12]),
        .rd(instr_id[11:7]),
        .rs1_addrs(instr_id[19:15]),
        .rs2_addrs(instr_id[24:20]),
        .imm_out(imm_id),
        .rs1_data(rs1_data_id),
        .rs2_data(rs2_data_id),
        .ex_alu_src(ex_alu_src_id),
        .mem_write(mem_write_id),
        .mem_load_type(mem_load_type_id),
        .mem_store_type(mem_store_type_id),
        .wb_reg_file(wb_reg_file_id),
        .memtoreg(memtoreg_id),
        .Branch_1(branch_id),
        .jal(jal_id),
        .jalr(jalr_id),
        .alu_ctrl(alu_ctrl_id),
        .pc_ex(pc_ex),
        .predictedTaken_ex(predictedTaken_ex),
        .func3_ex(func3_ex),
        .rd_ex(rd_ex),
        .rs1_addr_ex(rs1_addr_ex),
        .rs2_addr_ex(rs2_addr_ex),
        .imm_ex(imm_ex),
        .rs1_data_ex(rs1_data_ex),
        .rs2_data_ex(rs2_data_ex),
        .ex_alu_src_ex(ex_alu_src_ex),
        .mem_write_ex(mem_write_ex),
        .mem_load_type_ex(mem_load_type_ex),
        .mem_store_type_ex(mem_store_type_ex),
        .wb_reg_file_ex(wb_reg_file_ex),
        .memtoreg_ex(memtoreg_ex),
        .branch_ex(branch_ex_wires),
        .jal_ex(jal_ex),
        .jalr_ex(jalr_ex),
        .alu_ctrl_ex(alu_ctrl_ex)
    );

    // =====================================================
    // 6) Forwarding unit
    // =====================================================
    forwarding_unit u_fwd (
        .rs1_addr_ex(rs1_addr_ex),
        .rs2_addr_ex(rs2_addr_ex),
        .exmem_regwrite(wb_reg_file_mem),
        .exmem_rd(rd_mem),
        .memwb_regwrite(wb_reg_file_wb),
        .memwb_rd(rd_wb),
        .operand_a_forward_cntl(operand_a_forward_cntl),
        .operand_b_forward_cntl(operand_b_forward_cntl)
    );

    // =====================================================
    // 7) Execute stage (SLIM — no control pass-through)
    // =====================================================
    execute_stage u_exe (
        .rs1_data_ex(rs1_data_ex),
        .rs2_data_ex(rs2_data_ex),
        .imm_ex(imm_ex),
        .ex_alu_src_ex(ex_alu_src_ex),
        .alu_ctrl_ex(alu_ctrl_ex),
        .operand_a_forward_cntl(operand_a_forward_cntl),
        .operand_b_forward_cntl(operand_b_forward_cntl),
        .data_forward_mem(data_forward_mem),
        .data_forward_wb(data_forward_wb),
        .alu_result_ex(alu_result_ex),
        .zero_flag_ex(zero_flag_ex),
        .negative_flag_ex(negative_flag_ex),
        .carry_flag_ex(carry_flag_ex),
        .overflow_flag_ex(overflow_flag_ex),
        .rs2_data_for_mem_ex(rs2_data_for_mem_ex),
        .op1_selected_ex(op1_selected_ex)
    );

    // =====================================================
    // 8) Branch / Jump unit
    // =====================================================
    branch_jump_unit u_branch (
        .branch_ex(branch_ex_wires),
        .jal_ex(jal_ex),
        .jalr_ex(jalr_ex),
        .func3_ex(func3_ex),
        .pc_ex(pc_ex),
        .imm_ex(imm_ex),
        .predictedTaken_ex(predictedTaken_ex),
        .zero_flag(zero_flag_ex),
        .negative_flag(negative_flag_ex),
        .carry_flag(carry_flag_ex),
        .overflow_flag(overflow_flag_ex),
        .op1_forwarded(op1_selected_ex),
        .ex_branch_taken(ex_branch_taken),
        .modify_pc_ex(ex_modify_pc),
        .update_pc_ex(ex_update_pc),
        .jump_addr_ex(ex_jump_addr),
        .update_btb_ex(ex_update_btb)
    );

    // =====================================================
    // 9) EX/MEM pipeline register (controls bypassed directly from ID/EX)
    // =====================================================
    ex_mem_pipe u_ex_mem (
        .clk(clk), .rst(rst),
        .alu_result_ex(alu_result_ex),              // from execute_stage
        .rs2_data_ex(rs2_data_for_mem_ex),          // from execute_stage
        .rd_ex(rd_ex),                              // bypassed direct from ID/EX
        .mem_write_ex(mem_write_ex),                // bypassed direct from ID/EX
        .mem_load_type_ex(mem_load_type_ex),        // bypassed direct from ID/EX
        .mem_store_type_ex(mem_store_type_ex),      // bypassed direct from ID/EX
        .wb_reg_file_ex(wb_reg_file_ex),            // bypassed direct from ID/EX
        .memtoreg_ex(memtoreg_ex),                  // bypassed direct from ID/EX
        .alu_result_mem(alu_result_mem),
        .rs2_data_mem(rs2_data_mem),
        .rd_mem(rd_mem),
        .mem_write_mem(mem_write_mem),
        .mem_load_type_mem(mem_load_type_mem),
        .mem_store_type_mem(mem_store_type_mem),
        .wb_reg_file_mem(wb_reg_file_mem),
        .memtoreg_mem(memtoreg_mem)
    );

    assign data_forward_mem = alu_result_mem;

 /*   // =====================================================
    // 10) MEM stage
    // =====================================================
    mem_stage u_mem (
        .clk(clk),
        .alu_result_mem(alu_result_mem),
        .rs2_data_mem(rs2_data_mem),
        .rd_mem(rd_mem),
        .mem_write_mem(mem_write_mem),
        .mem_load_type_mem(mem_load_type_mem),
        .mem_store_type_mem(mem_store_type_mem),
        .wb_reg_file_mem(wb_reg_file_mem),
        .memtoreg_mem(memtoreg_mem),
        .alu_result_for_wb(alu_result_for_wb),
        .load_wb_data(load_wb_data),
        .rd_for_wb(rd_for_wb),
        .wb_reg_file_out(wb_reg_file_out),
        .memtoreg_out(memtoreg_out)
    );

    // =====================================================
    // 11) MEM/WB pipeline register
    // =====================================================
    mem_wb_pipe u_mem_wb (
        .clk(clk), .rst(rst),
        .alu_result_in(alu_result_for_wb),
        .load_data_in(load_wb_data),
        .rd_in(rd_for_wb),
        .wb_reg_file_in(wb_reg_file_out),
        .memtoreg_in(memtoreg_out),
        .alu_result_out(alu_result_wb),
        .load_data_out(load_data_wb),
        .rd_out(rd_wb),
        .wb_reg_file_out(wb_reg_file_wb),
        .memtoreg_out(memtoreg_wb)
    );
*/
 // MEM stage (slim — only produces load data)
mem_stage u_mem (
    .clk(clk),
    .alu_result_mem(alu_result_mem[11:2]),
    .rs2_data_mem(rs2_data_mem),
    .mem_write_mem(mem_write_mem),
    .mem_load_type_mem(mem_load_type_mem),
    .mem_store_type_mem(mem_store_type_mem),
    .memtoreg_mem(memtoreg_mem),        // used as mem_read
    .load_wb_data(load_wb_data)         // direct to mem_wb_pipe below
);

// MEM/WB pipe — bypass ALU result, rd, wb_reg_file, memtoreg directly from MEM registers
mem_wb_pipe u_mem_wb (
    .clk(clk),
    .rst(rst),
    .alu_result_in(alu_result_mem),     // bypassed direct (non-load ALU result)
    .load_data_in(load_wb_data),        // from slim mem_stage
    .rd_in(rd_mem),                     // bypassed direct
    .wb_reg_file_in(wb_reg_file_mem),   // bypassed direct
    .memtoreg_in(memtoreg_mem),         // bypassed direct
    .alu_result_out(alu_result_wb),
    .load_data_out(load_data_wb),
    .rd_out(rd_wb),
    .wb_reg_file_out(wb_reg_file_wb),
    .memtoreg_out(memtoreg_wb)
);
    assign data_forward_wb = (memtoreg_wb) ? load_data_wb : alu_result_wb;
    assign wb_write_addr = rd_wb;

    // =====================================================
    // 12) WB stage
    // =====================================================
    wb_stage u_wb (
        .alu_result_wb(alu_result_wb),
        .load_data_wb(load_data_wb),
        .rd_wb(rd_wb),
        .wb_reg_file_wb(wb_reg_file_wb),
        .memtoreg_wb(memtoreg_wb),
        .wb_write_data(wb_write_data),
      //  .wb_write_addr(wb_write_addr),
        .wb_write_en(wb_write_en)
    ); 

    assign s_alu_result_out  = alu_result_wb;
    assign s_load_data_out   = load_data_wb;
    assign s_rd_out          = rd_wb;
    assign s_wb_reg_file_out = wb_reg_file_wb;
    assign s_memtoreg_out    = memtoreg_wb;
endmodule
