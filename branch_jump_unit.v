// -------------------------------
// branch_jump_unit
// -------------------------------
module branch_jump_unit (
    // ---------- Inputs (from ID/EX controls) ----------
    input  branch_ex,           // branch instruction?
    input  jal_ex,              // JAL?
    input  jalr_ex,             // JALR?
    input  [2:0] func3_ex,      // branch type (BEQ/BNE/BLT/...)
    input  [31:0] pc_ex,        // PC of this instr
    input  [31:0] imm_ex,       // branch/jump offset
    input  predictedTaken_ex,   // BTB prediction forwarded to EX
    // ----- From ALU (flags for condition) ----------
    input  zero_flag,           // result == 0 (EQ)
    input  negative_flag,       // sign bit of result (N)
    input  carry_flag,          // carry-out = 1 -> NO borrow for subtraction
    input  overflow_flag,       // signed overflow (V)
    input  [31:0] op1_forwarded,// forwarded rs1 (for JALR target)
    // ----- Outputs (to hazard/IF/BTB) ----------
 //   output ex_branch_resolved,  // 1 if branch/jal/jalr in EX
    output ex_branch_taken,     // actual outcome (taken = 1)
   // output ex_predicted_taken,  // forwarded prediction
    output modify_pc_ex,        // 1 if mispredict (flush needed)
    output [31:0] update_pc_ex, // next PC: target or pc+4
    output [31:0] jump_addr_ex, // computed target (for BTB)
    output update_btb_ex        // 1 for every resolved control-flow (train)
);

    // Any control-flow instruction resolved in EX
    wire is_branch = branch_ex; // WHAT: Identify branch instruction WHY: Separate branch logic HOW: Direct assign WHEN: EX stage
    wire is_jal    = jal_ex; // WHAT: Identify JAL instruction WHY: Unconditional jump HOW: Direct assign WHEN: EX stage
    wire is_jalr   = jalr_ex; // WHAT: Identify JALR instruction WHY: Register-based jump HOW: Direct assign WHEN: EX stage
    wire any_ctrl  = is_branch | is_jal | is_jalr; // WHAT: Detect any control-flow instr WHY: Needed for BTB training HOW: OR combine WHEN: EX stage
//    assign ex_branch_resolved = any_ctrl;
//    assign ex_predicted_taken = predictedTaken_ex;

    // ----------------------------------------
    // Branch condition evaluation (from ALU flags)
    // For branches we assume ALU performed (rs1 - rs2)
    // ----------------------------------------
    reg branch_cond; // WHAT: Evaluated branch condition WHY: Decide taken/not taken HOW: From ALU flags WHEN: EX stage
    always @(zero_flag or negative_flag or overflow_flag or carry_flag or is_branch or func3_ex) begin
        if (is_branch) begin
            case (func3_ex)
                3'b000: branch_cond = zero_flag; // WHAT: BEQ condition WHY: Equal comparison HOW: Zero flag WHEN: Branch EX
                3'b001: branch_cond = ~zero_flag; // WHAT: BNE condition WHY: Not equal comparison HOW: Invert zero flag WHEN: Branch EX

                // Signed comparisons use N XOR V (standard two's complement)
                3'b100: branch_cond = (negative_flag ^ overflow_flag); // WHAT: BLT condition WHY: Signed less-than HOW: N^V logic WHEN: Branch EX
                3'b101: branch_cond = ~(negative_flag ^ overflow_flag); // WHAT: BGE condition WHY: Signed greater/equal HOW: Invert N^V WHEN: Branch EX

                // Unsigned comparisons use carry flag from subtraction
                3'b110: branch_cond = ~carry_flag; // WHAT: BLTU condition WHY: Unsigned less-than HOW: Borrow detect WHEN: Branch EX
                3'b111: branch_cond = carry_flag; // WHAT: BGEU condition WHY: Unsigned greater/equal HOW: No borrow detect WHEN: Branch EX

                default: branch_cond = 1'b0; // WHAT: Default not taken WHY: Safety HOW: Force zero WHEN: Invalid func3
            endcase
        end
	else
 		begin
			branch_cond = 1'b0; // WHAT: Not a branch WHY: Ignore flags HOW: Force zero WHEN: Non-branch instruction
		end

    end

    // JAL/JALR are always taken control-flow transfers
    wire jump_taken = is_jal | is_jalr; // WHAT: Jump always taken flag WHY: Jumps are unconditional HOW: OR logic WHEN: EX stage
    wire actual_taken = is_branch ? branch_cond : (jump_taken ? 1'b1 : 1'b0); // WHAT: Actual taken result WHY: Needed for redirect and training HOW: Mux select WHEN: EX stage
    assign ex_branch_taken = actual_taken; // WHAT: Export actual outcome WHY: Update BTB and hazard unit HOW: Wire assign WHEN: EX stage

    // ----------------------------------------
    // Target calculation
    // - Branch/JAL: pc + imm
    // - JALR: (rs1 + imm) with LSB cleared (RISC-V spec)
    // Use forwarded rs1 for JALR target calculation.
    // ----------------------------------------
    wire [31:0] target_branch_jal = pc_ex + imm_ex; // WHAT: Compute branch/JAL target WHY: PC-relative jump HOW: Add PC and immediate WHEN: EX stage
    wire [31:0] target_jalr       = (op1_forwarded + imm_ex) & 32'hFFFFFFFE; // WHAT: Compute JALR target WHY: Spec requires LSB=0 HOW: Add and mask WHEN: EX stage
    wire [31:0] computed_target = is_jalr ? target_jalr :
                                  is_jal  ? target_branch_jal :
                                            target_branch_jal; // WHAT: Select correct target WHY: Depends on instruction type HOW: Conditional mux WHEN: EX stage
    assign jump_addr_ex = computed_target; // WHAT: Export target address WHY: BTB update and PC redirect HOW: Wire assign WHEN: EX stage

    // ----------------------------------------
    // Mispredict detection and next-PC selection
    // ----------------------------------------
    wire [31:0] pc_plus_4 = pc_ex + 32'd4; // WHAT: Sequential next PC WHY: Default fetch path HOW: Add 4 WHEN: EX stage
    wire mispredict = (actual_taken ^ predictedTaken_ex); // WHAT: Detect misprediction WHY: Compare actual vs predicted HOW: XOR logic WHEN: EX stage
    assign modify_pc_ex = mispredict; // WHAT: Signal PC redirect WHY: Wrong-path fetch detected HOW: Wire assign WHEN: Mispredict
    assign update_pc_ex = mispredict ? (actual_taken ? computed_target : pc_plus_4) : pc_plus_4; // WHAT: Select corrected PC WHY: Fix misprediction HOW: Nested mux WHEN: EX stage

    // Train BTB/predictor on every resolved control-flow (branch/jal/jalr)
    assign update_btb_ex = any_ctrl; // WHAT: Enable BTB update WHY: Learn control-flow behavior HOW: Assert on any control instr WHEN: EX stage

endmodule

