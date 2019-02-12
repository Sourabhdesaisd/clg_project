// ======================================================
// dynamic_branch_predictor.v
// 2-bit saturating counter predictor
// ======================================================

module dynamic_branch_predictor (
    input  wire        clk,
    input  wire        rst,
    input  wire        update_en,

    input  wire [1:0]  curr_state,
    input  wire        actual_taken,

    output reg  [1:0]  next_state
);

    reg [1:0] state_n; // WHAT: Internal next-state variable WHY: Hold combinational FSM result HOW: Temporary register WHEN: Before clock update

    // --------------------------------------------------
    // Combinational next-state logic (INTERNAL ONLY)
    // --------------------------------------------------
    always @(curr_state or actual_taken) begin
        state_n = curr_state; // WHAT: Default hold state WHY: Avoid unintended changes HOW: Assign current state WHEN: No transition

        if (actual_taken) begin
            case (curr_state)
                2'b00: state_n = 2'b01; // WHAT: Move toward taken WHY: Branch was taken HOW: Increment counter WHEN: Strong NT ? Weak NT
                2'b01: state_n = 2'b10; // WHAT: Move to taken WHY: Branch was taken HOW: Increment counter WHEN: Weak NT ? Weak T
                2'b10: state_n = 2'b11; // WHAT: Strengthen taken WHY: Branch was taken HOW: Increment counter WHEN: Weak T ? Strong T
                2'b11: state_n = 2'b11; // WHAT: Saturate at strong taken WHY: Already strongest state HOW: Hold value WHEN: Strong T
            endcase
        end
        else begin
            case (curr_state)
                2'b00: state_n = 2'b00; // WHAT: Stay strong not taken WHY: Branch not taken HOW: Hold counter WHEN: Strong NT
                2'b01: state_n = 2'b00; // WHAT: Move toward not taken WHY: Branch not taken HOW: Decrement counter WHEN: Weak NT ? Strong NT
                2'b10: state_n = 2'b01; // WHAT: Move toward not taken WHY: Branch not taken HOW: Decrement counter WHEN: Weak T ? Weak NT
                2'b11: state_n = 2'b10; // WHAT: Weaken taken WHY: Branch not taken HOW: Decrement counter WHEN: Strong T ? Weak T
            endcase
        end
    end

    // --------------------------------------------------
    // REGISTERED OUTPUT (Superlint requirement)
    // --------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            next_state <= 2'b01;   // WHAT: Reset predictor state WHY: Safe default is weakly not taken HOW: Assign constant WHEN: Reset
        else if (update_en)
            next_state <= state_n; // WHAT: Update predictor state WHY: Learn branch behavior HOW: Register combinational result WHEN: Branch resolves
    end

endmodule

