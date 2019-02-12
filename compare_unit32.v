module compare_unit32 (
    input  [31:0] rs_1,
    input  [31:0] rs_2,
    input  [3:0]  alu_ctrl,
    output reg [31:0] result_cmp
);
    always @(rs_1 or rs_2 or alu_ctrl) begin
        case (alu_ctrl)
            4'b1000: result_cmp = ($signed(rs_1) < $signed(rs_2)) ? 32'b1 : 32'b0;
            4'b1001: result_cmp = (rs_1 < rs_2) ? 32'b1 : 32'b0;
            default: result_cmp = 32'b0;
        endcase
    end
endmodule
