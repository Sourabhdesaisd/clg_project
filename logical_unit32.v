module logical_unit32 (
    input  [31:0] rs1,
    input  [31:0] rs2,
    input  [3:0]  alu_ctrl,
    output reg [31:0] result_alu
);
    always @( rs1 or rs2 or alu_ctrl) begin
        case (alu_ctrl)
            4'b0010: result_alu = rs1 & rs2;
            4'b0011: result_alu = rs1 | rs2;
            4'b0100: result_alu = rs1 ^ rs2;
            default: result_alu = 32'b0;
        endcase
    end
endmodule
