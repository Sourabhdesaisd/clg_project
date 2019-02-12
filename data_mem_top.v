module data_mem_top (
    input         clk,
    input         mem_read,
    input         mem_write,
    input  [2:0]  load_type,   // 000 LB, 001 LH, 010 LW, 011 LBU, 100 LHU
    input  [1:0]  store_type,  // 00 SB, 01 SH, 10 SW
    input  [9:0] addr,        // ALU result (byte address)
    input  [31:0] rs2_data,    // data to store (from register file)
    output [31:0] read_data    // load result to register file
);
    wire [31:0] mem_write_data;
    wire [3:0]  byte_enable;
    wire [31:0] mem_data_out;

    // STORE DATAPATH
    store_datapath u_store (
        .store_type(store_type),
        .write_data(rs2_data),
        .addr(addr[1:0]),
        .mem_write_data(mem_write_data),
        .byte_enable(byte_enable)
    );

    // DATA MEMORY (byte-addressable)
    data_memory u_mem (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .addr(addr),
        .write_data(mem_write_data),
        .byte_enable(byte_enable),
        .mem_data_out(mem_data_out)
    );

    // LOAD DATAPATH
    load_datapath u_load (
        .load_type(load_type),
        .mem_data_in(mem_data_out),
        .addr(addr[1:0]),
        .read_data(read_data)
    );
endmodule


