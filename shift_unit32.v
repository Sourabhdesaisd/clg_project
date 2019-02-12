/*module shift_unit32 (
    input  [31:0] rs1,
    input  [31:0] rs2,
    input  [3:0]  alu_ctrl,
    output reg [31:0] result_shift
);
    wire [4:0] shamt = rs2[4:0];
    always @(rs1 or shamt or alu_ctrl) begin
        case (alu_ctrl)
            4'b0101: result_shift = rs1 << shamt;
            4'b0110: result_shift = rs1 >> shamt;
            4'b0111: result_shift = $signed(rs1) >>> shamt;
            default: result_shift = 32'b0;
        endcase
    end
endmodule*/

/*
module shift_unit32 (
    input  wire [31:0] rs1,          // RS1 value
    input  wire [4:0]  rs2,          // shift amount (RV32)
    input  wire [3:0]  alu_ctrl,     // ALU control
    output reg  [31:0] result_shift
);

    wire [4:0] shamt;
    assign shamt = rs2;

    // --------------------------------------------------
    // Combinational shift logic (EX-stage)
    // --------------------------------------------------
    always @(rs1 or shamt or alu_ctrl) begin
        // Default assignment (clears CAS_NR_DEFX, no latch)
        result_shift = 32'b0;

        case (alu_ctrl)

            // SLL / SLLI
            4'b0101: begin
                result_shift = rs1 << shamt;
            end

            // SRL / SRLI
            4'b0110: begin
                result_shift = rs1 >> shamt;
            end

            // SRA / SRAI (lint-safe arithmetic shift)
            4'b0111: begin
                if (shamt != 5'd0) begin
                    result_shift =
                        (rs1 >> shamt) |
                        ({32{rs1[31]}} << (32 - shamt));
                end
                else begin
                    result_shift = rs1;
                end
            end

            default: begin
                result_shift = 32'b0;
            end
        endcase
    end

endmodule
*/
module shift_unit32 (
    input  [31:0] rs1,        // RS1 value
    input  [4:0]  rs2,        // shift amount (RV32)
    input  [3:0]  alu_ctrl,   // ALU control
    output reg [31:0] result_shift
);
    wire [4:0] shamt;
    assign shamt = rs2;
    // Combinational shift logic (EX-stage submodule)
    always @(rs1 or shamt or alu_ctrl) begin
        // Default assignment (clears CAS_NR_DEFX)
        result_shift = 32'b0;
        case (alu_ctrl)
            // SLL / SLLI
            4'b0101:
                result_shift = rs1 << shamt;
            // SRL / SRLI
            4'b0110:
                result_shift = rs1 >> shamt;
            // SRA / SRAI (lint-safe arithmetic shift)
            4'b0111: begin
                if (shamt != 5'd0)
                    result_shift = (rs1 >> shamt) |
                                   ({32{rs1[31]}} <<
                                    (6'd32 - {1'b0, shamt}));
                else
                    result_shift = rs1;
            end
	default:
            result_shift = 32'hxxxxxxxx;
        endcase
    end
endmodule

