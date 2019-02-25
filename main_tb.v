

module main_tb;

    reg clk;
    reg rst;
    reg rst_im;
       reg   write_en;
       reg   [9:0] write_addr;
       reg   [31:0] write_data;

    wire [31:0] pc;
    wire [31:0]    s_alu_result_out ; 
    wire [31:0]    s_load_data_out ;
    wire [4:0]    s_rd_out  ;     
    wire     s_wb_reg_file_out;
    wire     s_memtoreg_out  ; 
 

    // Instantiate the core/top (change name if your top is different)
    rv32i_core dut (
        .clk(clk),
        .rst(rst),
	.rst_im(rst_im),
	.write_en(write_en),
	.write_addr(write_addr),
	.write_data(write_data),
        .pc(pc),
        .s_alu_result_out (s_alu_result_out),
        .s_load_data_out (s_load_data_out), 
        .s_rd_out (s_rd_out) ,       
        .s_wb_reg_file_out(s_wb_reg_file_out),
        .s_memtoreg_out (s_memtoreg_out)   



    );

    initial begin
        // waveform / shared memory probe (as in your environment)
        $shm_open("wave.shm");
        $shm_probe("ACTMF");
    end

    // Clock generation: 10ns period
    initial begin
        clk = 1;
        forever #5 clk = ~clk;
    end
    
	initial begin
	rst_im =0;
         write_en  = 1'b0;
	write_addr = 0;
	write_data = 0;
     end

    // Test stimulus
    initial begin
        // Apply reset
        rst = 1;
        #10;       // Hold reset for 20ns
        rst = 0;

        // Run simulation for N ns then finish (adjust as needed)
        #300;
        $display("SIMULATION DONE");
        $finish;
    end

endmodule 


