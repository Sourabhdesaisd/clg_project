/*
module arithmetic_unit32 (
    input  [31:0] rs1,
    input  [31:0] rs2,
    input  [3:0]  alu_ctrl,
    output reg [31:0] result_alu,
    output       zero_flag,
    output reg   carry_flag,
    output   negative_flag,
    output reg   overflow_flag
);
    wire [32:0] add_ext = {1'b0, rs1} + {1'b0, rs2};
    wire [32:0] sub_ext = {1'b0, rs1} - {1'b0, rs2};

    always @(alu_ctrl or add_ext or sub_ext or rs2 or rs1 ) begin
        result_alu = 32'b0;
        carry_flag = 1'b0;
     //   negative_flag = 1'b0;
        overflow_flag = 1'b0;

        case (alu_ctrl)
            4'b0000: begin
                result_alu = add_ext[31:0];
                carry_flag = add_ext[32];
            end
            4'b0001: begin
                result_alu = sub_ext[31:0];
                carry_flag = sub_ext[32]; // borrow indicator style
            end
            4'b1010: begin
                result_alu = rs2; // LUI expects prepared imm
                carry_flag = 1'b0;
            end
            4'b1011: begin
                result_alu = add_ext[31:0]; // AUIPC: PC+imm expected as inputs
                carry_flag = add_ext[32];
            end
            default: begin
                result_alu = 32'b0;
                carry_flag = 1'b0;
            end
        endcase


        case (alu_ctrl)
            4'b0000: begin
                overflow_flag = (~rs1[31] & ~rs2[31] & result_alu[31]) |
                                ( rs1[31] & rs2[31] & ~result_alu[31]);
            end
            4'b0001: begin
                overflow_flag = ( rs1[31] & ~rs2[31] & ~result_alu[31]) |
                                (~rs1[31] &  rs2[31] &  result_alu[31]);
            end
            default: overflow_flag = 1'b0;
        endcase
    end
     assign   negative_flag = result_alu[31];
	
    assign zero_flag = (result_alu == 32'b0);
endmodule

*/

module arithmetic_unit32 (
    input  [31:0] rs1,        // rs1 or PC
    input  [31:0] rs2,        // rs2 or immediate (or imm_prepared for LUI)
    input  [3:0]  alu_ctrl,   // from alu_control

    output [31:0] result_alu,
    output        zero_flag,
    output reg    carry_flag,
    output reg    negative_flag,
    output reg    overflow_flag
);

    // --------------------------------------------------
    // Internal result (lint-clean, no output read)
    // --------------------------------------------------
    reg [31:0] alu_result_int;

    // --------------------------------------------------
    // 33-bit extended add/sub (for carry detection)
    // --------------------------------------------------
    wire [32:0] add_ext;
    wire [32:0] sub_ext;

    assign add_ext = {1'b0, rs1} + {1'b0, rs2};
    assign sub_ext = {1'b0, rs1} - {1'b0, rs2};

    // --------------------------------------------------
    // ALU combinational logic
    // (explicit sensitivity list  no *)
    // --------------------------------------------------
    always @(rs1[31] or rs2 or alu_ctrl or add_ext or sub_ext) begin
        // Defaults
        alu_result_int = 32'b0;
        carry_flag     = 1'b0;
        negative_flag  = 1'b0;
        overflow_flag  = 1'b0;

        case (alu_ctrl)

            // ADD / ADDI / LOAD / STORE / JALR
            4'b0000: begin
                alu_result_int = add_ext[31:0];
                carry_flag     = add_ext[32];
            end

            // SUB / branch compare
            4'b0001: begin
                alu_result_int = sub_ext[31:0];
                carry_flag     = sub_ext[32]; // no-borrow indicator
            end

            // LUI
            4'b1010: begin
                alu_result_int = rs2;
            end

            // AUIPC
            4'b1011: begin
                alu_result_int = add_ext[31:0];
                carry_flag     = add_ext[32];
            end

            default: begin
                alu_result_int = 32'hxxxxxxxx;
                carry_flag     = 1'bx;
            end
        endcase

        // Negative flag (sign bit)
        negative_flag = alu_result_int[31];

        // Signed overflow detection
        case (alu_ctrl)

            // ADD overflow
            4'b0000: begin
                overflow_flag =
                    (~rs1[31] & ~rs2[31] &  alu_result_int[31]) |
                    ( rs1[31] &  rs2[31] & ~alu_result_int[31]);
            end

            // SUB overflow
            4'b0001: begin
                overflow_flag =
                    ( rs1[31] & ~rs2[31] & ~alu_result_int[31]) |
                    (~rs1[31] &  rs2[31] &  alu_result_int[31]);
            end

            default: begin
                overflow_flag = 1'bx;
            end
        endcase
    end

    
    assign result_alu = alu_result_int;
    assign zero_flag  = (alu_result_int == 32'b0);

endmodule

