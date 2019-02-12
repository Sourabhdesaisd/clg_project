// -------------------------------
// forwarding_unit
// -------------------------------
module forwarding_unit (
    input  [4:0] rs1_ex,
    input  [4:0] rs2_ex,
    input        exmem_regwrite,
    input  [4:0] exmem_rd,
    input        memwb_regwrite,
    input  [4:0] memwb_rd,
    output reg  [1:0] operand_a_forward_cntl,
    output reg  [1:0] operand_b_forward_cntl
);
    always @(exmem_regwrite or exmem_rd or exmem_rd or rs1_ex or memwb_rd or memwb_regwrite or  rs2_ex) begin
        operand_a_forward_cntl = 2'b00; // WHAT: Default no forwarding for operand A WHY: Use register file value HOW: Assign zero code WHEN: No hazard
        operand_b_forward_cntl = 2'b00; // WHAT: Default no forwarding for operand B WHY: Use register file value HOW: Assign zero code WHEN: No hazard

        // Operand A (rs1) - EX/MEM priority
        if (exmem_regwrite && (exmem_rd != 5'd0) && (exmem_rd == rs1_ex)) begin
            operand_a_forward_cntl = 2'b01; // WHAT: Forward from EX/MEM WHY: Latest value available HOW: Select EX/MEM mux WHEN: EX hazard
        end else if (memwb_regwrite && (memwb_rd != 5'd0) && (memwb_rd == rs1_ex)) begin
            operand_a_forward_cntl = 2'b10; // WHAT: Forward from MEM/WB WHY: Value available one stage later HOW: Select MEM/WB mux WHEN: MEM hazard
        end

        // Operand B (rs2)
        if (exmem_regwrite && (exmem_rd != 5'd0) && (exmem_rd == rs2_ex)) begin
            operand_b_forward_cntl = 2'b01; // WHAT: Forward from EX/MEM WHY: Latest value available HOW: Select EX/MEM mux WHEN: EX hazard
        end else if (memwb_regwrite && (memwb_rd != 5'd0) && (memwb_rd == rs2_ex)) begin
            operand_b_forward_cntl = 2'b10; // WHAT: Forward from MEM/WB WHY: Value available one stage later HOW: Select MEM/WB mux WHEN: MEM hazard
        end
    end
endmodule

