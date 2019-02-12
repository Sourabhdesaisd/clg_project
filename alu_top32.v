// -------------------------------
// ALU Top and subunits
// -------------------------------
module alu_top32 (
    input  [31:0] rs1,
    input  [31:0] rs2,
    input  [3:0]  alu_ctrl,
    output [31:0] alu_result,
    output        zero_flag,
    output        negative_flag,
    output        carry_flag,
    output        overflow_flag
);
    wire [31:0] result_arith;
    wire [31:0] result_logic;
    wire [31:0] result_shift;
    wire [31:0] result_cmp;
    wire zf, nf, cf, of_1;

    arithmetic_unit32 u_arith (
        .rs1(rs1), .rs2(rs2), .alu_ctrl(alu_ctrl),
        .result_alu(result_arith), .zero_flag(zf),
        .carry_flag(cf), .negative_flag(nf), .overflow_flag(of_1)
    );

    logical_unit32 u_logic (
        .rs1(rs1), .rs2(rs2), .alu_ctrl(alu_ctrl),
        .result_alu(result_logic)
    );

    shift_unit32 u_shift (
        .rs1(rs1), .rs2(rs2[4:0]), .alu_ctrl(alu_ctrl),
        .result_shift(result_shift)
    );

    compare_unit32 u_cmp (
        .rs_1(rs1), .rs_2(rs2), .alu_ctrl(alu_ctrl),
        .result_cmp(result_cmp)
    );

    reg [31:0] result_final;
    always @(result_arith or alu_ctrl or  result_logic or result_shift or result_cmp) begin
        case (alu_ctrl)
            4'b0000, 4'b0001, 4'b1010, 4'b1011: result_final = result_arith;
            4'b0010, 4'b0011, 4'b0100:          result_final = result_logic;
            4'b0101, 4'b0110, 4'b0111:          result_final = result_shift;
            4'b1000, 4'b1001:                   result_final = result_cmp;
            default: result_final = 32'b0;
        endcase
    end

    assign alu_result = result_final;
    assign zero_flag = zf;
    assign carry_flag = cf;
    assign negative_flag = nf;
    assign overflow_flag = of_1;
endmodule
