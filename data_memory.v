module data_memory (
    input          clk,
    input          mem_read,
    input          mem_write,
    input   [9:0] addr,          // byte address
    input   [31:0] write_data,    // from store datapath
    input   [3:0]  byte_enable,   // from store datapath
    output  [31:0] mem_data_out   // to load datapath
);
        parameter MEM_BYTES = 1024;
    parameter ADDR_BITS = 10;   // log2(1024)

    reg [7:0] mem [MEM_BYTES-1 : 0];

    wire [ADDR_BITS-1:0] mem_addr = addr[ADDR_BITS-1:0];

    integer i;
    initial begin
        for(i=0;i<1024;i=i+1)
            mem[i] = 8'b0; // avoid X in simulation
    end

    // WRITE — Byte controlled
    always @(posedge clk) begin
        if (mem_write) begin
          /*  if (byte_enable[0]) mem[addr]     <= write_data[7:0];
            if (byte_enable[1]) mem[addr+1]   <= write_data[15:8];
            if (byte_enable[2]) mem[addr+2]   <= write_data[23:16];
            if (byte_enable[3]) mem[addr+3]   <= write_data[31:24];*/

	    if (byte_enable[0]) mem[mem_addr] <= write_data[7:0];
            if (byte_enable[1]) mem[mem_addr + {{(ADDR_BITS-1){1'b0}}, 1'b1}] <= write_data[15:8];
            if (byte_enable[2]) mem[mem_addr + {{(ADDR_BITS-2){1'b0}}, 2'b10}] <= write_data[23:16];
            if (byte_enable[3]) mem[mem_addr + {{(ADDR_BITS-2){1'b0}}, 2'b11}] <= write_data[31:24];	
        end
    end

    // READ — Form 32-bit word from 4 bytes (combinational)
   /* always @(mem_read  or addr ) begin
        if (mem_read) begin
            mem_data_out = { mem[addr+3], mem[addr+2], mem[addr+1], mem[addr] };
        end else begin
            mem_data_out = 32'b0;
        end 
    end */
assign mem_data_out = mem_read ? { mem[mem_addr + {{(ADDR_BITS-2){1'b0}}, 2'b11}],
             			   mem[mem_addr + {{(ADDR_BITS-2){1'b0}}, 2'b10}],
             			   mem[mem_addr + {{(ADDR_BITS-1){1'b0}}, 1'b1}],
           		           mem[mem_addr]  } : 32'b0 ;
endmodule


