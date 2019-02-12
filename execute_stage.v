module execute_stage (
    input  wire [31:0] rs1_data_ex,
    input  wire [31:0] rs2_data_ex,
    input  wire [31:0] imm_ex,

    input  wire        ex_alu_src_ex,
    input  wire [3:0]  alu_ctrl_ex,

    input  wire [1:0]  operand_a_forward_cntl,
    input  wire [1:0]  operand_b_forward_cntl,
    input  wire [31:0] data_forward_mem,
    input  wire [31:0] data_forward_wb,

    output wire [31:0] alu_result_ex,
    output wire        zero_flag_ex,
    output wire        negative_flag_ex,
    output wire        carry_flag_ex,
    output wire        overflow_flag_ex,
    output wire [31:0] rs2_data_for_mem_ex,  // forwarded rs2 (for store)

    output wire [31:0] op1_selected_ex       // debug
);
    // Forwarding muxes
    reg [31:0] op1_sel; // WHAT: Selected operand A WHY: Resolve data hazards HOW: Forwarding mux WHEN: EX stage
    reg [31:0] op2_sel; // WHAT: Selected operand B WHY: Resolve data hazards HOW: Forwarding mux WHEN: EX stage
    always @(rs1_data_ex or rs2_data_ex or data_forward_mem or data_forward_wb or operand_a_forward_cntl or operand_b_forward_cntl) begin
        op1_sel = rs1_data_ex; // WHAT: Default operand A WHY: No forwarding needed HOW: Use register value WHEN: No hazard
        op2_sel = rs2_data_ex; // WHAT: Default operand B WHY: No forwarding needed HOW: Use register value WHEN: No hazard

        case (operand_a_forward_cntl)
            2'b01: op1_sel = data_forward_mem; // WHAT: Forward A from MEM stage WHY: Latest value available HOW: Select MEM data WHEN: EX/MEM hazard
            2'b10: op1_sel = data_forward_wb; // WHAT: Forward A from WB stage WHY: Value available later HOW: Select WB data WHEN: MEM/WB hazard
            default: op1_sel = rs1_data_ex; // WHAT: No forwarding WHY: No dependency HOW: Keep register data WHEN: No hazard
        endcase

        case (operand_b_forward_cntl)
            2'b01: op2_sel = data_forward_mem; // WHAT: Forward B from MEM stage WHY: Latest value available HOW: Select MEM data WHEN: EX/MEM hazard
            2'b10: op2_sel = data_forward_wb; // WHAT: Forward B from WB stage WHY: Value available later HOW: Select WB data WHEN: MEM/WB hazard
            default: op2_sel = rs2_data_ex; // WHAT: No forwarding WHY: No dependency HOW: Keep register data WHEN: No hazard
        endcase
    end

    assign op1_selected_ex = op1_sel; // WHAT: Export selected op1 WHY: Debug visibility HOW: Wire assign WHEN: EX stage

    // ALU-src mux
    wire [31:0] op2_final = ex_alu_src_ex ? imm_ex : op2_sel; // WHAT: Select ALU operand B WHY: Immediate vs register HOW: Mux by control WHEN: EX stage

    // ALU instance
    wire [31:0] alu_result_w; // WHAT: ALU result internal WHY: Connect ALU output HOW: Wire WHEN: EX stage
    wire zf_w, nf_w, cf_w, of_w; // WHAT: ALU flags WHY: Used for branch decision HOW: Flag outputs WHEN: EX stage
    alu_top32 u_alu_top (
        .rs1(op1_sel),
        .rs2(op2_final),
        .alu_ctrl(alu_ctrl_ex),
        .alu_result(alu_result_w),
        .zero_flag(zf_w),
        .negative_flag(nf_w),
        .carry_flag(cf_w),
        .overflow_flag(of_w)
    );

    assign alu_result_ex       = alu_result_w; // WHAT: Export ALU result WHY: Used by MEM/WB stages HOW: Wire assign WHEN: EX stage
    assign zero_flag_ex        = zf_w; // WHAT: Export zero flag WHY: Branch compare HOW: Wire assign WHEN: EX stage
    assign negative_flag_ex    = nf_w; // WHAT: Export negative flag WHY: Signed compare HOW: Wire assign WHEN: EX stage
    assign carry_flag_ex       = cf_w; // WHAT: Export carry flag WHY: Unsigned compare HOW: Wire assign WHEN: EX stage
    assign overflow_flag_ex    = of_w; // WHAT: Export overflow flag WHY: Signed compare HOW: Wire assign WHEN: EX stage
    assign rs2_data_for_mem_ex = op2_sel; // WHAT: Forward rs2 data for store WHY: Store uses rs2 value HOW: Forwarded mux output WHEN: MEM stage
endmodule

