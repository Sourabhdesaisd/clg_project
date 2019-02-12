module decode_unit (
    input   [31:0] instruction_in,
    //input  [6:0]  opcode,
    input         id_flush,        // when asserted, treat instruction as NOP (all zeros)
    
    output reg  [31:0] imm_out
);
   // wire [6:0]  opcode;
   //  wire [2:0]  func3;
   //  wire [6:0]  func7;
   //  wire [4:0]  rd;
   //  wire [4:0]  rs1;
   //  wire [4:0]  rs2;


   // Select either real instruction or zero when flushed
    wire [31:0] instr = id_flush ? 32'h00000000 : instruction_in; // WHAT: Instruction select mux WHY: Flush converts instruction to NOP HOW: Ternary operator WHEN: Pipeline flush

   // Field extraction (combinational)
  //  assign opcode = instr[6:0];
  //  assign rd     = instr[11:7];
  //  assign func3  = instr[14:12];
  //  assign rs1    = instr[19:15];
  //  assign rs2    = instr[24:20];
  //  assign func7  = instr[31:25]; 

    // Immediate generation
    always @(instr) begin
        case (instr[6:0])
            // I-type (includes arithmetic immediates) and loads (I-format) and JALR
            7'b0010011, 7'b0000011, 7'b1100111: begin
                imm_out = {{20{instr[31]}}, instr[31:20]}; // WHAT: Generate I-type immediate WHY: Used for ALU/load/JALR offset HOW: Sign-extend 12-bit imm WHEN: Decode stage
            end

            // S-type (store): imm[11:5]=instr[31:25], imm[4:0]=instr[11:7]
            7'b0100011: begin
                imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // WHAT: Generate S-type immediate WHY: Store address offset HOW: Concatenate split fields + sign-extend WHEN: Decode stage
            end

            // B-type (branch): imm = {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}
            7'b1100011: begin
                imm_out = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}; // WHAT: Generate branch immediate WHY: Branch target PC offset HOW: Reorder bits + sign-extend WHEN: Decode stage
            end

            // J-type (JAL): imm = {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}
            7'b1101111: begin
                imm_out = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}; // WHAT: Generate JAL immediate WHY: Jump target PC offset HOW: Reorder bits + sign-extend WHEN: Decode stage
            end

            // U-type (LUI/AUIPC): imm = instr[31:12] << 12
            7'b0110111, 7'b0010111: begin
                imm_out = {instr[31:12], 12'b0}; // WHAT: Generate U-type immediate WHY: Upper immediate load/add HOW: Left shift by 12 bits WHEN: Decode stage
            end

            // Default (R-type or unknown)
            default: begin
                imm_out = 32'h00000000; // WHAT: No immediate value WHY: R-type uses registers only HOW: Force zero WHEN: Decode stage
            end
        endcase
    end
endmodule

