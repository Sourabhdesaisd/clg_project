module hazard_unit (
    input  [4:0] id_rs1,
    input  [4:0] id_rs2,
    input  [6:0] opcode_id,
    input  [4:0] ex_rd,
    input        ex_load_inst,
    input        modify_pc_ex,
    output reg   pc_en,
  //  output reg   if_id_en,
   // output reg   if_id_flush,
    output reg   id_ex_flush
);

parameter OPCODE_RTYPE  =  7'b0110011 ;
parameter OPCODE_ITYPE  =  7'b0010011 ;
parameter OPCODE_ILOAD  =  7'b0000011 ;
parameter OPCODE_IJALR  =  7'b1100111 ;
parameter OPCODE_BTYPE  =  7'b1100011 ;
parameter OPCODE_STYPE  =  7'b0100011 ;
parameter OPCODE_JTYPE  =  7'b1101111 ;
parameter OPCODE_AUIPC  =  7'b0010111 ;
parameter OPCODE_UTYPE  =  7'b0110111 ;

    wire rs1_used = (opcode_id == OPCODE_RTYPE) ||
                    (opcode_id == OPCODE_ITYPE) ||
                    (opcode_id == OPCODE_ILOAD) ||
                    (opcode_id == OPCODE_STYPE) ||
                    (opcode_id == OPCODE_BTYPE) ||
                    (opcode_id == OPCODE_IJALR); // WHAT: Detect rs1 usage WHY: Not all instructions use rs1 HOW: Opcode-based check WHEN: Hazard detection

    wire rs2_used = (opcode_id == OPCODE_RTYPE) ||
                    (opcode_id == OPCODE_STYPE) ||
                    (opcode_id == OPCODE_BTYPE); // WHAT: Detect rs2 usage WHY: Only some instructions need rs2 HOW: Opcode-based check WHEN: Hazard detection

    wire load_use_hazard = ex_load_inst && // WHAT: Load-use hazard detect WHY: Load data not ready yet HOW: Combine conditions WHEN: EX?ID dependency
                           (ex_rd != 5'd0) && // WHAT: Ignore x0 WHY: x0 is always zero HOW: Register check WHEN: Hazard detection
                           ((rs1_used && (ex_rd == id_rs1)) || // WHAT: rs1 dependency WHY: ID needs EX load result HOW: Reg compare WHEN: Hazard
                            (rs2_used && (ex_rd == id_rs2))); // WHAT: rs2 dependency WHY: ID needs EX load result HOW: Reg compare WHEN: Hazard

    always @(modify_pc_ex or load_use_hazard) begin
        pc_en        = 1'b1; // WHAT: Default allow PC update WHY: Normal pipeline flow HOW: Enable PC WHEN: No hazard
       // if_id_en     = 1'b1;
      //  if_id_flush  = 1'b0;
        id_ex_flush  = 1'b0; // WHAT: Default no flush WHY: Keep instruction valid HOW: Deassert flush WHEN: No hazard

        if (modify_pc_ex) begin
            pc_en        = 1'b1; // WHAT: Allow PC redirect WHY: Branch/jump resolved HOW: Keep PC enabled WHEN: Mispredict fix
          //  if_id_en     = 1'b1;
          //  if_id_flush  = 1'b1;
            id_ex_flush  = 1'b1; // WHAT: Flush ID/EX WHY: Wrong-path instruction HOW: Insert bubble WHEN: PC redirected
        end else if (load_use_hazard) begin
            pc_en        = 1'b0; // WHAT: Stall PC WHY: Wait for load data HOW: Disable PC update WHEN: Load-use hazard
          //  if_id_en     = 1'b0;
          //  if_id_flush  = 1'b1;
            id_ex_flush  = 1'b1; // WHAT: Flush ID/EX WHY: Insert bubble to resolve hazard HOW: Kill instruction WHEN: Load-use stall
        end
    end
endmodule

