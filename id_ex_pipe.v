module id_ex_pipe (
input  clk,
input  rst,
input  en,
input  flush,
input  [31:0] pc_id,
input         predictedTaken_id,
input  [2:0] func3,
input  [4:0] rd,
input  [4:0] rs1_addrs,
input  [4:0] rs2_addrs,
input  [31:0] imm_out,
input  [31:0] rs1_data,
input  [31:0] rs2_data,
input  ex_alu_src,
input  mem_write,
input  [2:0]  mem_load_type,
input  [1:0]  mem_store_type,
input  wb_reg_file,
input  memtoreg,
input  Branch_1,
input  jal,
input  jalr,
input  [3:0] alu_ctrl,
output reg [31:0] pc_ex,
output reg        predictedTaken_ex,
output reg [2:0] func3_ex,
output reg [4:0] rd_ex,
output reg [4:0] rs1_addr_ex,
output reg [4:0] rs2_addr_ex,
output reg [31:0] imm_ex,
output reg [31:0] rs1_data_ex,
output reg [31:0] rs2_data_ex,
output reg ex_alu_src_ex,
output reg mem_write_ex,
output reg [2:0]  mem_load_type_ex,
output reg [1:0]  mem_store_type_ex,
output reg wb_reg_file_ex,
output reg memtoreg_ex,
output reg branch_ex,
output reg jal_ex,
output reg jalr_ex,
output reg [3:0] alu_ctrl_ex
);

parameter NOP_INSTR = 32'h00000013;

always @(posedge clk or posedge rst) begin
if (rst) begin
    pc_ex               <= 32'h0;
    predictedTaken_ex   <= 1'b0;
    func3_ex            <= 3'd0;
    rd_ex               <= 5'd0;
    rs2_addr_ex              <= 5'd0;
    rs2_addr_ex              <= 5'd0;
    imm_ex              <= 32'h0;
    rs1_data_ex         <= 32'h0;
    rs2_data_ex         <= 32'h0;
    ex_alu_src_ex       <= 1'b0;
    mem_write_ex        <= 1'b0;
    mem_load_type_ex    <= 3'b111;
    mem_store_type_ex   <= 2'b11;
    wb_reg_file_ex      <= 1'b0;
    memtoreg_ex         <= 1'b0;
    branch_ex           <= 1'b0;
    jal_ex              <= 1'b0;
    jalr_ex             <= 1'b0;
    alu_ctrl_ex         <= 4'b0;
    end 
else if (flush) begin
    pc_ex               <= 32'h0;
    predictedTaken_ex   <= 1'b0;
    func3_ex            <= 3'd0;
    rd_ex               <= 5'd0;
    rs2_addr_ex              <= 5'd0;
    rs2_addr_ex              <= 5'd0;
    imm_ex              <= 32'h0;
    rs1_data_ex         <= 32'h0;
    rs2_data_ex         <= 32'h0;
    ex_alu_src_ex       <= 1'b0;
    mem_write_ex        <= 1'b0;
    mem_load_type_ex    <= 3'b111;
    mem_store_type_ex   <= 2'b11;
    wb_reg_file_ex      <= 1'b0;
    memtoreg_ex         <= 1'b0;
    branch_ex           <= 1'b0;
    jal_ex              <= 1'b0;
    jalr_ex             <= 1'b0;
    alu_ctrl_ex         <= 4'b0;
    end 
else if (en) begin
    pc_ex               <= pc_id;
    predictedTaken_ex   <= predictedTaken_id;
    func3_ex            <= func3;
    rd_ex               <= rd;
    rs1_addr_ex              <= rs1_addrs;
    rs2_addr_ex              <= rs2_addrs;
    imm_ex              <= imm_out;
    rs1_data_ex         <= rs1_data;
    rs2_data_ex         <= rs2_data;
    ex_alu_src_ex       <= ex_alu_src;
    mem_write_ex        <= mem_write;
    mem_load_type_ex    <= mem_load_type;
    mem_store_type_ex   <= mem_store_type;
    wb_reg_file_ex      <= wb_reg_file;
    memtoreg_ex         <= memtoreg;
    branch_ex           <= Branch_1;
    jal_ex              <= jal;
    jalr_ex             <= jalr;
    alu_ctrl_ex         <= alu_ctrl;
    end
end
endmodule
