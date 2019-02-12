// ======================================================
// btb_write.v
// BTB update logic with 2-bit predictor integration
// ======================================================

module btb_write #(
    parameter TAGW = 27
)(
    input  wire clk,
    input  wire rst,
    // ---------------- UPDATE ----------------
    input              update_en,
    input      [29:0]  update_pc,
    input              actual_taken,
    input      [31:0]  update_target,

    // ---------------- READ (for hit detect) ----------------
    input              rd_valid0_upd,
    input      [TAGW-1:0] rd_tag0_upd,
    input              rd_valid1_upd,
    input      [TAGW-1:0] rd_tag1_upd,
    input              rd_lru_upd,

    // ---------------- WRITE to BTB FILE ----------------
    output reg         wr_en,
    output reg  [2:0]  wr_set,
    output reg         wr_way,
    output reg         wr_valid,
    output reg  [TAGW-1:0] wr_tag,
    output reg  [31:0] wr_target,
    output reg  [1:0]  wr_state,

    // ---------------- LRU ----------------
    output reg         wr_lru_en,
    output reg         wr_lru_val,

   // ---------------- PREDICTOR ----------------
    input      [1:0]   state0_in,
    input      [1:0]   state1_in
  //  output     [1:0]   next_state0,
  //  output     [1:0]   next_state1
);

    // --------------------------------------------------
    // PC decode
    // --------------------------------------------------
    wire [2:0]        upd_set; // WHAT: Update set index WHY: Select BTB set to update HOW: From PC bits WHEN: Branch resolved
    wire [TAGW-1:0]   upd_tag; // WHAT: Update tag WHY: Identify branch instruction HOW: From PC upper bits WHEN: BTB update

    assign upd_set = update_pc[2:0]; // WHAT: Extract set index WHY: Index into BTB arrays HOW: PC bit slicing WHEN: Update stage
    assign upd_tag = update_pc[29:3]; // WHAT: Extract tag WHY: Match and store branch PC HOW: PC bit slicing WHEN: Update stage

    // --------------------------------------------------
    // Predictor next-state wires
    // --------------------------------------------------
    wire [1:0] next_state0; // WHAT: Next predictor state for way0 WHY: Learn branch behavior HOW: FSM transition WHEN: After branch resolves
    wire [1:0] next_state1; // WHAT: Next predictor state for way1 WHY: Learn branch behavior HOW: FSM transition WHEN: After branch resolves

    //assign next_state0 = next_state0_int;
    //assign next_state1 = next_state1_int;

    // --------------------------------------------------
    // Predictor instances (pure combinational)
    // --------------------------------------------------
   dynamic_branch_predictor dp0 (
    .clk          (clk),
    .rst          (rst),
    .update_en    (update_en),
    .curr_state   (state0_in),
    .actual_taken (actual_taken),
    .next_state   (next_state0) // WHAT: Compute next state for way0 WHY: Update predictor FSM HOW: Based on actual outcome WHEN: Update
);

dynamic_branch_predictor dp1 (
    .clk          (clk),
    .rst          (rst),
    .update_en    (update_en),
    .curr_state   (state1_in),
    .actual_taken (actual_taken),
    .next_state   (next_state1) // WHAT: Compute next state for way1 WHY: Update predictor FSM HOW: Based on actual outcome WHEN: Update
);
	

    // --------------------------------------------------
    // Hit detection
    // --------------------------------------------------
    wire hit0; // WHAT: Update hit on way0 WHY: Update existing entry HOW: Valid and tag compare WHEN: Update stage
    wire hit1; // WHAT: Update hit on way1 WHY: Update existing entry HOW: Valid and tag compare WHEN: Update stage

    assign hit0 = rd_valid0_upd && (rd_tag0_upd ==update_pc[29:3]); // WHAT: Way0 update hit detect WHY: Identify matching entry HOW: Valid AND tag compare WHEN: BTB update
    assign hit1 = rd_valid1_upd && (rd_tag1_upd == update_pc[29:3]); // WHAT: Way1 update hit detect WHY: Identify matching entry HOW: Valid AND tag compare WHEN: BTB update

    // --------------------------------------------------
    // Write / Replace Logic (COMBINATIONAL)
    // --------------------------------------------------
    always @( update_en
           or upd_set
           or upd_tag
           or actual_taken
           or update_target
           or rd_valid0_upd
           or rd_valid1_upd
           or rd_lru_upd
           or hit0
           or hit1
           or next_state0
           or next_state1
    )
    begin
        // ---------------- DEFAULTS (NO LATCH) ----------------
        wr_en       = 1'b0; // WHAT: Default no write WHY: Avoid unintended updates HOW: Explicit assignment WHEN: Every evaluation
        wr_set      = 3'd0; // WHAT: Default set index WHY: Safe value HOW: Constant assign WHEN: No update
        wr_way      = 1'b0; // WHAT: Default way select WHY: Safe value HOW: Constant assign WHEN: No update
        wr_valid    = 1'b0; // WHAT: Default valid bit WHY: Prevent accidental allocation HOW: Constant assign WHEN: No update
        wr_tag      = {TAGW{1'b0}}; // WHAT: Default tag WHY: Avoid X propagation HOW: Zero fill WHEN: No update
        wr_target   = 32'd0; // WHAT: Default target WHY: Avoid wrong jump HOW: Zero assign WHEN: No update
        wr_state    = 2'd0; // WHAT: Default predictor state WHY: Safe value HOW: Constant assign WHEN: No update
        wr_lru_en   = 1'b0; // WHAT: Default no LRU update WHY: Avoid unwanted replacement change HOW: Constant assign WHEN: No update
        wr_lru_val  = 1'b0; // WHAT: Default LRU value WHY: Safe value HOW: Constant assign WHEN: No update

        if (update_en) begin
            wr_set = upd_set; // WHAT: Select set to update WHY: Write correct BTB set HOW: From decoded PC WHEN: Update enabled

            // ---------- HIT WAY 0 ----------
            if (hit0) begin
                wr_en       = 1'b1; // WHAT: Enable write WHY: Update existing entry HOW: Assert write enable WHEN: Hit in way0
                wr_way      = 1'b0; // WHAT: Select way0 WHY: Entry matched in way0 HOW: Hard select WHEN: Hit0
                wr_valid    = 1'b1; // WHAT: Keep entry valid WHY: Entry is used HOW: Set valid bit WHEN: Update
                wr_tag      = upd_tag; // WHAT: Rewrite tag WHY: Ensure correct tag stored HOW: From update PC WHEN: Update
                wr_state    = next_state0; // WHAT: Update predictor state WHY: Learn branch behavior HOW: Use FSM output WHEN: Branch resolved
                wr_target   = update_target; // WHAT: Update target address WHY: Store correct jump target HOW: From EX stage WHEN: Branch taken
                wr_lru_en   = 1'b1; // WHAT: Enable LRU update WHY: Mark this way as recently used HOW: Assert enable WHEN: Hit
                wr_lru_val  = 1'b1; // WHAT: Set LRU value WHY: Way0 was used HOW: Write policy bit WHEN: After access
            end

            // ---------- HIT WAY 1 ----------
            else if (hit1) begin
                wr_en       = 1'b1; // WHAT: Enable write WHY: Update existing entry HOW: Assert write enable WHEN: Hit in way1
                wr_way      = 1'b1; // WHAT: Select way1 WHY: Entry matched in way1 HOW: Hard select WHEN: Hit1
                wr_valid    = 1'b1; // WHAT: Keep entry valid WHY: Entry is used HOW: Set valid bit WHEN: Update
                wr_tag      = upd_tag; // WHAT: Rewrite tag WHY: Ensure correct tag stored HOW: From update PC WHEN: Update
                wr_state    = next_state1; // WHAT: Update predictor state WHY: Learn branch behavior HOW: Use FSM output WHEN: Branch resolved
                wr_target   = update_target; // WHAT: Update target address WHY: Store correct jump target HOW: From EX stage WHEN: Branch taken
                wr_lru_en   = 1'b1; // WHAT: Enable LRU update WHY: Mark this way as recently used HOW: Assert enable WHEN: Hit
                wr_lru_val  = 1'b0; // WHAT: Set LRU value WHY: Way1 was used HOW: Write policy bit WHEN: After access
            end

            // ---------- MISS ----------
            else begin
                wr_en       = 1'b1; // WHAT: Enable write WHY: Allocate new BTB entry HOW: Assert write enable WHEN: Miss
                wr_valid    = 1'b1; // WHAT: Mark entry valid WHY: New entry allocated HOW: Set valid bit WHEN: Allocation
                wr_tag      = upd_tag; // WHAT: Write new tag WHY: Identify new branch HOW: From update PC WHEN: Allocation
                wr_state    = actual_taken ? 2'b10 : 2'b01; // WHAT: Initialize predictor WHY: Start near correct state HOW: Based on outcome WHEN: First insert
                wr_target   = update_target; // WHAT: Store target WHY: Needed for next prediction HOW: From resolved jump WHEN: Allocation
                wr_lru_en   = 1'b1; // WHAT: Enable LRU update WHY: Mark new entry as used HOW: Assert enable WHEN: Allocation

                // Replacement decision
                if (!rd_valid0_upd) begin
                    wr_way     = 1'b0; // WHAT: Choose way0 WHY: Empty slot available HOW: Prefer invalid entry WHEN: Miss
                    wr_lru_val = 1'b1; // WHAT: Mark way0 as recent WHY: It was just used HOW: LRU update WHEN: Allocation
                end
                else if (!rd_valid1_upd) begin
                    wr_way     = 1'b1; // WHAT: Choose way1 WHY: Empty slot available HOW: Prefer invalid entry WHEN: Miss
                    wr_lru_val = 1'b0; // WHAT: Mark way1 as recent WHY: It was just used HOW: LRU update WHEN: Allocation
                end
                else if (rd_lru_upd == 1'b0) begin
                    wr_way     = 1'b0; // WHAT: Replace way0 WHY: LRU says way0 is old HOW: LRU policy WHEN: Both valid
                    wr_lru_val = 1'b1; // WHAT: Update LRU WHY: New way used HOW: Set opposite bit WHEN: Replacement
                end
                else begin
                    wr_way     = 1'b1; // WHAT: Replace way1 WHY: LRU says way1 is old HOW: LRU policy WHEN: Both valid
                    wr_lru_val = 1'b0; // WHAT: Update LRU WHY: New way used HOW: Set opposite bit WHEN: Replacement
                end
            end
        end
    end

endmodule

