// ======================================================
// btb_file.v  (BTB Storage Arrays: TAG, VALID, TARGET,
//              2-bit STATE predictor, and LRU bit)
// ======================================================
module btb_file #(
    parameter SETS = 8,
    parameter WAYS = 2,
    parameter TAGW = 27
)(
    input                   clk,
    input                   rst,

    // --- READ PORT --------
    input  [2:0]            rd_set,
   // input  [0:0]            rd_way0,   
    output                  rd_valid0,
    output [TAGW-1:0]       rd_tag0,
    output [31:0]           rd_target0,
    output [1:0]            rd_state0,

   // input  [0:0]            rd_way1,
    output                  rd_valid1,
    output [TAGW-1:0]       rd_tag1,
    output [31:0]           rd_target1,
    output [1:0]            rd_state1,

    // --- WRITE PORT --------
    input                   wr_en,
    input  [2:0]            wr_set,
    input                   wr_way,     // 0 or 1
    input                   wr_valid,
    input  [TAGW-1:0]       wr_tag,
    input  [31:0]           wr_target,
    input  [1:0]            wr_state,

    // LRU
    output                  rd_lru,
    input                   wr_lru_en,
    input                   wr_lru_val
);

    // ================= Arrays =================
    reg                valid_arr  [SETS-1:0][WAYS-1:0]; // WHAT: Valid bits per set and way WHY: Mark used BTB entries HOW: 2D register array WHEN: Read and write access
    reg [TAGW-1:0]     tag_arr    [SETS-1:0][WAYS-1:0]; // WHAT: Tag storage WHY: Identify branch PC uniquely HOW: Stored per entry WHEN: BTB lookup
    reg [31:0]         target_arr [SETS-1:0][WAYS-1:0]; // WHAT: Target address storage WHY: Jump target for prediction HOW: Stored per BTB entry WHEN: On hit
    reg [1:0]          state_arr  [SETS-1:0][WAYS-1:0]; // WHAT: 2-bit predictor state WHY: Predict taken/not taken HOW: Saturating counter bits WHEN: Fetch and update
    reg                lru        [SETS-1:0]; // WHAT: LRU bit per set WHY: Choose replacement way HOW: 1-bit policy for 2 ways WHEN: BTB update

    // ============= READ ACCESS =============
    assign rd_valid0  = valid_arr[rd_set][0]; // WHAT: Read valid bit of way0 WHY: Check if entry exists HOW: Index array with set and way WHEN: BTB lookup
    assign rd_tag0    = tag_arr[rd_set][0]; // WHAT: Read tag of way0 WHY: Compare with PC tag HOW: Array read WHEN: Fetch stage
    assign rd_target0 = target_arr[rd_set][0]; // WHAT: Read target of way0 WHY: Use for predicted PC HOW: Array read WHEN: BTB hit
    assign rd_state0  = state_arr[rd_set][0]; // WHAT: Read predictor state of way0 WHY: Predict branch direction HOW: Array read WHEN: Fetch stage

    assign rd_valid1  = valid_arr[rd_set][1]; // WHAT: Read valid bit of way1 WHY: Check if entry exists HOW: Index array with set and way WHEN: BTB lookup
    assign rd_tag1    = tag_arr[rd_set][1]; // WHAT: Read tag of way1 WHY: Compare with PC tag HOW: Array read WHEN: Fetch stage
    assign rd_target1 = target_arr[rd_set][1]; // WHAT: Read target of way1 WHY: Use for predicted PC HOW: Array read WHEN: BTB hit
    assign rd_state1  = state_arr[rd_set][1]; // WHAT: Read predictor state of way1 WHY: Predict branch direction HOW: Array read WHEN: Fetch stage

    assign rd_lru     = lru[rd_set]; // WHAT: Read LRU bit of set WHY: Decide replacement way HOW: Indexed read WHEN: Update stage

    // ============= WRITE ACCESS =============
    integer i,j; // WHAT: Loop variables WHY: Iterate sets and ways HOW: Used in nested loops WHEN: Reset

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i=0; i<SETS; i=i+1) begin
                lru[i] <= 1'b0; // WHAT: Reset LRU bits WHY: Start with known replacement state HOW: Set to zero WHEN: Reset
                for (j=0; j<WAYS; j=j+1) begin
                    valid_arr[i][j]  <= 1'b0; // WHAT: Clear valid bits WHY: Mark entries empty HOW: Set to zero WHEN: Reset
                    tag_arr[i][j]    <= {TAGW{1'b0}}; // WHAT: Clear tags WHY: Remove stale tags HOW: Fill with zeros WHEN: Reset
                    target_arr[i][j] <= 32'b0; // WHAT: Clear target addresses WHY: Avoid wrong jumps HOW: Set to zero WHEN: Reset
                    state_arr[i][j]  <= 2'b01; // WHAT: Initialize predictor state WHY: Weakly not taken is safe default HOW: Set FSM state WHEN: Reset
                end
            end
        end
        else begin
            if (wr_en) begin
                valid_arr [wr_set][wr_way] <= wr_valid; // WHAT: Write valid bit WHY: Allocate or update entry HOW: Indexed write WHEN: Branch resolved
                tag_arr   [wr_set][wr_way] <= wr_tag; // WHAT: Write tag WHY: Identify branch PC HOW: Indexed write WHEN: BTB update
                target_arr[wr_set][wr_way] <= wr_target; // WHAT: Write target WHY: Store resolved jump address HOW: Indexed write WHEN: Branch taken
                state_arr [wr_set][wr_way] <= wr_state; // WHAT: Write predictor state WHY: Learn branch behavior HOW: FSM update WHEN: After execution
            end

            if (wr_lru_en)
                lru[wr_set] <= wr_lru_val; // WHAT: Update LRU bit WHY: Track most recently used way HOW: Write new value WHEN: After access
        end
    end

endmodule

