// Small control unit (decoding high-level control signals)
module control_unit(
    input  [6:0] opcode,
    input  [2:0] func3,
    input        func7,

    output reg ex_alu_src,
    output reg mem_write,
   // output reg mem_read,
    output reg [2:0] mem_load_type,
    output reg [1:0] mem_store_type,
    output reg wb_reg_file,
    output reg memtoreg,  //same memread
    output reg Branch_1,
    output reg jal,
    output reg jalr,
 //   output reg auipc,
 //   output reg lui,
    output reg [3:0] alu_ctrl
);
    always @(opcode or func7 or func3 ) begin
        
        case (opcode)
            7'b0110011: begin // R-type
		ex_alu_src = 1'b0; 	mem_write = 1'b0; //	mem_read = 1'b0; 
        mem_load_type = 3'b010;	 	mem_store_type = 2'b10;
        	memtoreg = 1'b0; 
            Branch_1 = 1'b0; 	jal = 1'b0; jalr = 1'b0;	 //auipc = 1'b0; lui = 1'b0;
        	alu_ctrl = 4'b0000; // WHAT: Default ALU op WHY: Safe initialization HOW: Assign ADD code WHEN: Enter R-type decode

                wb_reg_file = 1'b1; // WHAT: Enable register writeback WHY: R-type writes result HOW: Assert control signal WHEN: R-type instruction
                case (func3)
                    3'b000: alu_ctrl = func7 ? 4'b0001 : 4'b0000; // WHAT: Select ADD/SUB WHY: Based on func7 bit HOW: Conditional mux WHEN: R-type arithmetic
                    3'b111: alu_ctrl = 4'b0010; // WHAT: AND operation WHY: Logical AND instruction HOW: ALU control encoding WHEN: R-type
                    3'b110: alu_ctrl = 4'b0011; // WHAT: OR operation WHY: Logical OR instruction HOW: ALU control encoding WHEN: R-type
                    3'b100: alu_ctrl = 4'b0100; // WHAT: XOR operation WHY: Logical XOR instruction HOW: ALU control encoding WHEN: R-type
                    3'b001: alu_ctrl = 4'b0101; // WHAT: Shift left logical WHY: SLL instruction HOW: ALU control encoding WHEN: R-type
                    3'b101: alu_ctrl = func7 ? 4'b0111 : 4'b0110; // WHAT: Shift right arithmetic/logical WHY: Distinguish SRA/SRL HOW: func7 select WHEN: R-type
                    3'b010: alu_ctrl = 4'b1000; // WHAT: Set less than WHY: Signed compare HOW: ALU control encoding WHEN: R-type
                    3'b011: alu_ctrl = 4'b1001; // WHAT: Set less than unsigned WHY: Unsigned compare HOW: ALU control encoding WHEN: R-type
                endcase
            end
            7'b0010011: begin // I-type ALU
		mem_write = 1'b0;  //	mem_read = 1'b0; 
        mem_load_type = 3'b010;	 mem_store_type = 2'b10;
      		memtoreg = 1'b0; 	Branch_1 = 1'b0; 		jal = 1'b0; jalr = 1'b0; //auipc = 1'b0; 			lui = 1'b0;
        	alu_ctrl = 4'b0000; // WHAT: Default ALU op WHY: Safe initialization HOW: Assign ADD code WHEN: Enter I-type decode

                ex_alu_src = 1'b1; // WHAT: Select immediate as ALU operand WHY: I-type uses immediate HOW: Control mux select WHEN: Execute stage
                wb_reg_file = 1'b1; // WHAT: Enable register writeback WHY: I-type writes result HOW: Assert control WHEN: I-type
                case (func3)
                    3'b000: alu_ctrl = 4'b0000; // WHAT: ADD immediate WHY: ADDI instruction HOW: ALU control encoding WHEN: I-type
                    3'b111: alu_ctrl = 4'b0010; // WHAT: AND immediate WHY: ANDI instruction HOW: ALU control encoding WHEN: I-type
                    3'b110: alu_ctrl = 4'b0011; // WHAT: OR immediate WHY: ORI instruction HOW: ALU control encoding WHEN: I-type
                    3'b100: alu_ctrl = 4'b0100; // WHAT: XOR immediate WHY: XORI instruction HOW: ALU control encoding WHEN: I-type
                    3'b001: alu_ctrl = 4'b0101; // WHAT: Shift left immediate WHY: SLLI instruction HOW: ALU control encoding WHEN: I-type
                    3'b101: alu_ctrl = func7 ? 4'b0111 : 4'b0110; // WHAT: Shift right immediate WHY: Distinguish SRAI/SRLI HOW: func7 select WHEN: I-type
                    3'b010: alu_ctrl = 4'b1000; // WHAT: Set less than immediate WHY: SLTI instruction HOW: ALU control encoding WHEN: I-type
                    3'b011: alu_ctrl = 4'b1001; // WHAT: Set less than immediate unsigned WHY: SLTIU instruction HOW: ALU control encoding WHEN: I-type
                endcase
            end
            7'b0000011: begin // LOAD
		 mem_write = 1'b0;  	mem_load_type = 3'b010; 	mem_store_type = 2'b10;
       		 Branch_1 = 1'b0;		 jal = 1'b0; 			jalr = 1'b0; 	//	auipc = 1'b0; lui = 1'b0;
       		 alu_ctrl = 4'b0000; // WHAT: Use ALU for address calc WHY: Load needs address HOW: ADD base + imm WHEN: Execute stage
		
                ex_alu_src = 1'b1; // WHAT: Select immediate WHY: Load uses offset HOW: Mux control WHEN: Execute stage
                wb_reg_file = 1'b1; // WHAT: Enable writeback WHY: Loaded data written to reg HOW: Assert control WHEN: WB stage
                memtoreg = 1'b1; // WHAT: Select memory data for WB WHY: Load instruction HOW: WB mux select WHEN: Writeback
                case (func3)
                    3'b000: mem_load_type = 3'b000; // WHAT: Load byte WHY: LB instruction HOW: Type encoding WHEN: Memory stage
                    3'b001: mem_load_type = 3'b001; // WHAT: Load halfword WHY: LH instruction HOW: Type encoding WHEN: Memory stage
                    3'b010: mem_load_type = 3'b010; // WHAT: Load word WHY: LW instruction HOW: Type encoding WHEN: Memory stage
                    3'b100: mem_load_type = 3'b011; // WHAT: Load byte unsigned WHY: LBU instruction HOW: Type encoding WHEN: Memory stage
                    3'b101: mem_load_type = 3'b100; // WHAT: Load halfword unsigned WHY: LHU instruction HOW: Type encoding WHEN: Memory stage
                    default: mem_load_type = 3'b010; // WHAT: Default load type WHY: Safety HOW: Force LW WHEN: Invalid func3
                endcase
            end
            7'b0100011: begin // STORE
	 	// mem_read = 1'b0; 
         mem_load_type = 3'b010; 	mem_store_type = 2'b10;
        	wb_reg_file = 1'b0;	 memtoreg = 1'b0; 		Branch_1 = 1'b0;		 jal = 1'b0; jalr = 1'b0; //auipc = 1'b0; lui = 1'b0;
        	alu_ctrl = 4'b0000; // WHAT: Use ALU for address calc WHY: Store needs address HOW: ADD base + imm WHEN: Execute stage

                ex_alu_src = 1'b1; // WHAT: Select immediate WHY: Store uses offset HOW: Mux control WHEN: Execute stage
                mem_write = 1'b1; // WHAT: Enable memory write WHY: Store instruction HOW: Assert control WHEN: Memory stage
                case (func3)
                    3'b000: mem_store_type = 2'b00; // WHAT: Store byte WHY: SB instruction HOW: Type encoding WHEN: Memory stage
                    3'b001: mem_store_type = 2'b01; // WHAT: Store halfword WHY: SH instruction HOW: Type encoding WHEN: Memory stage
                    3'b010: mem_store_type = 2'b10; // WHAT: Store word WHY: SW instruction HOW: Type encoding WHEN: Memory stage
                    default: mem_store_type = 2'b10; // WHAT: Default store type WHY: Safety HOW: Force SW WHEN: Invalid func3
                endcase
            end
            7'b1100011: begin // BRANCH
		ex_alu_src = 1'b0;	 mem_write = 1'b0; //	mem_read = 1'b0; 
        mem_load_type = 3'b010; 	mem_store_type = 2'b10;
       		 wb_reg_file = 1'b0; 	 memtoreg = 1'b0; 	 jal = 1'b0;		 jalr = 1'b0; 		//	auipc = 1'b0; lui = 1'b0;
       
		
                Branch_1 = 1'b1; // WHAT: Enable branch decision WHY: Branch instruction detected HOW: Assert branch control WHEN: Execute stage
                alu_ctrl = 4'b0001; // WHAT: Use SUB for compare WHY: Equality check via zero flag HOW: ALU subtract WHEN: Branch compare
            end
            7'b1101111: begin // JAL
		ex_alu_src = 1'b0; 	mem_write = 1'b0;	// mem_read = 1'b0;
        mem_load_type = 3'b010; 	mem_store_type = 2'b10;
        	memtoreg = 1'b0;	 Branch_1 = 1'b0; 	 jalr = 1'b0;	//	 auipc = 1'b0; 			lui = 1'b0;
       		 alu_ctrl = 4'b0000; // WHAT: ALU not used for jump WHY: PC redirect handled elsewhere HOW: Safe default WHEN: JAL

                jal = 1'b1; // WHAT: Enable JAL control WHY: Unconditional jump HOW: Control signal WHEN: Decode
                wb_reg_file = 1'b1; // WHAT: Write return address WHY: rd gets PC+4 HOW: Enable WB WHEN: JAL
            end
            7'b1100111: begin // JALR
		 mem_write = 1'b0;	// mem_read = 1'b0; 
         mem_load_type = 3'b010; 	mem_store_type = 2'b10;
        	memtoreg = 1'b0; 	Branch_1 = 1'b0; 		jal = 1'b0;  		//	auipc = 1'b0; lui = 1'b0;
       		 alu_ctrl = 4'b0000; // WHAT: ALU not used for jump WHY: PC redirect handled elsewhere HOW: Safe default WHEN: JALR

                jalr = 1'b1; // WHAT: Enable JALR control WHY: Register-based jump HOW: Control signal WHEN: Decode
                ex_alu_src = 1'b1; // WHAT: Use immediate for address WHY: JALR uses offset HOW: Mux control WHEN: Execute
                wb_reg_file = 1'b1; // WHAT: Write return address WHY: rd gets PC+4 HOW: Enable WB WHEN: JALR
            end
            7'b0110111: begin // LUI
		ex_alu_src = 1'b1;	 mem_write = 1'b0; 	//mem_read = 1'b0;
        mem_load_type = 3'b010; 	mem_store_type = 2'b10;
       		  memtoreg = 1'b0;	 Branch_1 = 1'b0; 	jal = 1'b0;		 jalr = 1'b0; 		//	auipc = 1'b0; lui = 1'b0;
        

                wb_reg_file = 1'b1; // WHAT: Enable writeback WHY: LUI writes immediate HOW: Assert control WHEN: WB stage
                alu_ctrl = 4'b1010; // WHAT: Select LUI operation WHY: Load upper immediate HOW: ALU control encoding WHEN: Execute
            end
            7'b0010111: begin // AUIPC
		ex_alu_src = 1'b1; 	mem_write = 1'b0;	 mem_read = 1'b0;
        mem_load_type = 3'b010; 	mem_store_type = 2'b10;
       		 memtoreg = 1'b0; 	Branch_1 = 1'b0; 		jal = 1'b0;		 jalr = 1'b0; 	//		auipc = 1'b0; lui = 1'b0;
                
		wb_reg_file = 1'b1; // WHAT: Enable writeback WHY: AUIPC writes PC+imm HOW: Assert control WHEN: WB stage
                alu_ctrl = 4'b1011; // WHAT: Select AUIPC operation WHY: Add PC and immediate HOW: ALU control encoding WHEN: Execute
            end
            default: begin 
		// defaults
        	ex_alu_src = 1'b0; mem_write = 1'b0; mem_read = 1'b0;
            mem_load_type = 3'b010; mem_store_type = 2'b10;
      		  wb_reg_file = 1'b0; memtoreg = 1'b1; Branch_1 = 1'b0; jal = 1'b0; jalr = 1'b0;// auipc = 1'b0; lui = 1'b0;
      		  alu_ctrl = 4'b0000; // WHAT: Default ALU operation WHY: Safe no-op behavior HOW: Assign ADD WHEN: Invalid opcode

		end
        endcase
    end
endmodule

