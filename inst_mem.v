// inst_mem.v
// Simple 32-bit word-addressed instruction memory

module inst_mem (
	input clk,
	input rst,
 	input   [9:0] pc, 
	input   write_en,
	input   [9:0] write_addr,
	input   [31:0] write_data,
	
    output  [31:0] instruction
);
    reg [31:0] mem [0:1023]; // WHAT: Instruction memory array WHY: Stores program instructions HOW: 1024 words of 32-bit WHEN: Used during fetch
   
    integer i; // WHAT: Loop variable WHY: Needed for memory reset HOW: Used in for-loop WHEN: During reset

    initial begin
        $readmemh("instructions.hex", mem);  // optional
    end 

always@(posedge clk or posedge rst)
begin

if(rst)
begin

for(i=0; i<1024 ; i= i+1 )
mem[i] 		<= 		32'd0 				; // WHAT: Clear instruction memory WHY: Start from known state HOW: Loop writes zero to all entries WHEN: On reset

end

else if (write_en)

mem[write_addr] <= write_data ; // WHAT: Write instruction to memory WHY: Load program into IMEM HOW: Addressed write with enable WHEN: During programming phase

end

assign instruction = mem[pc]; // WHAT: Read instruction from memory WHY: Provide instruction to IF stage HOW: Combinational array read WHEN: Every fetch cycle

endmodule

