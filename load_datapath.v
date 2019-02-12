// mem_stage_and_data_path_fixed.v
// Corrected load/store datapath + data memory + mem_stage wiring.
// Small, safe fix: correct halfword extraction for little-endian layout.


module load_datapath (
    input  [2:0]  load_type,
    input  [31:0] mem_data_in,
    input  [1:0] addr,
    output reg  [31:0] read_data
);
    // byte lanes (little-endian)
    wire [7:0]  byte0 = mem_data_in[7:0];
    wire [7:0]  byte1 = mem_data_in[15:8];
    wire [7:0]  byte2 = mem_data_in[23:16];
    wire [7:0]  byte3 = mem_data_in[31:24];

    // halfwords for little-endian: low half (bytes[1:0]), high half (bytes[3:2])
    wire [15:0] half0 = {byte1, byte0}; // addr[1] == 0 -> bytes [1:0]
    wire [15:0] half1 = {byte3, byte2}; // addr[1] == 1 -> bytes [3:2]

    // selected byte depending on addr[1:0]
    wire [7:0] selected_byte = (addr[1:0] == 2'b00) ? byte0 :
                               (addr[1:0] == 2'b01) ? byte1 :
                               (addr[1:0] == 2'b10) ? byte2 :
                                                      byte3;

    // select halfword by addr[1]
    wire [15:0] selected_half = (addr[1] == 1'b0) ? half0 : half1;

    always @(load_type or selected_byte or selected_half or mem_data_in) begin
        case (load_type)
            3'b000: begin // LB - sign-extend byte
                read_data = {{24{selected_byte[7]}}, selected_byte};
            end
            3'b011: begin // LBU - zero-extend byte
                read_data = {24'b0, selected_byte};
            end
            3'b001: begin // LH - sign-extend halfword
                read_data = {{16{selected_half[15]}}, selected_half};
            end
            3'b100: begin // LHU - zero-extend halfword
                read_data = {16'b0, selected_half};
            end
            3'b010: begin // LW - full word
                read_data = mem_data_in;
            end
            default: begin
                read_data = 32'h00000000;
            end
        endcase
    end
endmodule










