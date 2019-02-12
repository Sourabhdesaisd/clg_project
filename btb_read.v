// ======================================================
// btb_read.v
// Zero-cycle BTB read / hit detect (IF stage)
// Intentionally combinational
// ======================================================

module btb_read #(
    parameter TAGW = 27
)(
    input  [29:0] pc,

    // datm BTB file
    input         rd_valid0,
    input  [TAGW-1:0] rd_tag0,
    input         rd_valid1,
    input  [TAGW-1:0] rd_tag1,

    output [2:0]  set_index,
    output        hit0,
    output        hit1
);

    // -------------------------------
    // Zero-cycle decode
    // -------------------------------
    assign set_index = pc[2:0]; // WHAT: Extract BTB set index WHY: Select correct BTB set HOW: Use low PC bits WHEN: IF stage lookup

    assign hit0 = rd_valid0 && (rd_tag0 == pc[29:3]); // WHAT: Way0 hit detect WHY: Check if BTB entry matches PC HOW: Valid AND tag compare WHEN: BTB lookup
    assign hit1 = rd_valid1 && (rd_tag1 == pc[29:3]); // WHAT: Way1 hit detect WHY: Check if BTB entry matches PC HOW: Valid AND tag compare WHEN: BTB lookup

endmodule

