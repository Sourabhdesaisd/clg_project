module if_stage_simple_btb (
    input  wire clk,
    input  wire rst,
    input  rst_im,
    input   write_en,
    input   [9:0] write_addr,
    input   [31:0] write_data,

    // Hazard stall from hazard unit
    input  wire pc_en,
  //  input  wire flush,

    // Signals from EX (branch/jump resolution)
    input  wire        modify_pc_ex,
    input  wire [31:0] update_pc_ex,
    input  wire [29:0] pc_ex,
    input  wire [31:0] jump_addr_ex,
    input  wire        update_btb_ex,
    input  wire        ex_branch_taken,

    // Outputs to IF/ID
    output wire [31:0] pc_if,
    output wire [31:0] instr_if,
    output wire        predictedTaken_if
  //  output wire [31:0] predictedTarget_if
);

    // ------------------------------------------------------
    // PC Register using pc_reg module
    // ------------------------------------------------------
    wire [31:0] pc_current; // WHAT: Current PC value WHY: Used for fetch and prediction HOW: Driven by PC register WHEN: Every cycle
    reg  [31:0] pc_next;    // WHAT: Next PC value WHY: Selects next fetch address HOW: Computed by control logic WHEN: Before next clock edge

    pc_reg u_pc_reg (
        .clk(clk),
        .rst(rst),
        .pc_en(pc_en),
        .next_pc(pc_next),
        .pc(pc_current)
    );

    assign pc_if = pc_current; // WHAT: Send PC to IF/ID WHY: Needed by next pipeline stage HOW: Direct wire assign WHEN: Every cycle

    // ------------------------------------------------------
    // BTB Prediction Lookup
    // ------------------------------------------------------
    wire        btb_valid;  // WHAT: BTB entry valid flag WHY: Avoid using garbage target HOW: Read from BTB entry WHEN: During fetch
    wire        btb_taken;  // WHAT: Predicted taken bit WHY: Decide branch direction early HOW: Stored prediction bit WHEN: BTB lookup
    wire [31:0] btb_target; // WHAT: Predicted target address WHY: Jump early on taken branch HOW: Stored target in BTB WHEN: BTB hit

    btb u_btb (
        .clk(clk),
        .rst(rst),

        // FETCH
        .pc(pc_current),
        .predict_valid(btb_valid),
        .predict_taken(btb_taken),
        .predict_target(btb_target),

        // UPDATE (from EX)
        .update_en(update_btb_ex),
        .update_pc(pc_ex),
        .actual_taken(ex_branch_taken),
        .update_target(jump_addr_ex)
    );

    assign predictedTaken_if  = btb_valid && btb_taken; // WHAT: Final predicted-taken signal WHY: Only trust valid BTB entries HOW: AND of valid and taken bits WHEN: IF stage
   // assign predictedTarget_if = predictedTaken_if ? btb_target : (pc_current + 32'd4);

    // ------------------------------------------------------
    // NEXT PC selection
    // Priority:
    // 1) modify_pc_ex (redirect)
    // 2) BTB prediction
    // 3) default sequential PC + 4
    // ------------------------------------------------------
    always @(modify_pc_ex or update_pc_ex or btb_valid or btb_taken or btb_target or pc_current) begin
        if (modify_pc_ex)
            pc_next = update_pc_ex; // WHAT: Redirect PC from EX stage WHY: Fix misprediction or jump HOW: Override all predictions WHEN: Branch resolved in EX
        else if (btb_valid && btb_taken)
            pc_next = btb_target; // WHAT: Use BTB target as next PC WHY: Fetch predicted branch target early HOW: BTB mux selection WHEN: Predicted taken
        else
            pc_next = pc_current + 32'd4; // WHAT: Sequential PC increment WHY: Normal instruction flow HOW: Add 4 to PC WHEN: No redirect or prediction
    end

    // ------------------------------------------------------
    // INSTRUCTION MEMORY
    // ------------------------------------------------------
    inst_mem u_imem (
	.clk(clk),
	.rst(rst_im),
        .pc(pc_current[11:2]), // WHAT: Word-aligned PC index WHY: Instruction memory is word addressed HOW: Drop lower 2 bits WHEN: Fetch stage
	.write_en(write_en),
	.write_addr(write_addr),
	.write_data(write_data),
        .instruction(instr_if) // WHAT: Fetched instruction WHY: Needed for decode stage HOW: Read from memory WHEN: Same cycle as PC
    );

endmodule
	
