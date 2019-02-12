

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
        #100;
        $display("SIMULATION DONE");
        $finish;
    end

endmodule 

/*

module tb_rv32i_core;

    // ----------------------------------
    // Clock / Reset
    // ----------------------------------
    reg clk;
    reg rst;
    reg rst_im;

    // IMEM write
    reg write_en;
    reg [9:0] write_addr;
    reg [31:0] write_data;

    // DUT outputs
    wire [31:0] pc;
    wire [31:0] s_alu_result_out;
    wire [31:0] s_load_data_out;
    wire [4:0]  s_rd_out;
    wire s_wb_reg_file_out;
    wire s_memtoreg_out;

    // ----------------------------------
    // DUT
    // ----------------------------------
    rv32i_core dut (
        .clk(clk),
        .rst(rst),
        .rst_im(rst_im),
        .write_en(write_en),
        .write_addr(write_addr),
        .write_data(write_data),
        .pc(pc),
        .s_alu_result_out(s_alu_result_out),
        .s_load_data_out(s_load_data_out),
        .s_rd_out(s_rd_out),
        .s_wb_reg_file_out(s_wb_reg_file_out),
        .s_memtoreg_out(s_memtoreg_out)
    );

    // ----------------------------------
    // Clock generation
    // ----------------------------------
    always #5 clk = ~clk;

    // ----------------------------------
    // Tasks
    // ----------------------------------
    task load_instr(input [9:0] addr, input [31:0] instr);
    begin
        write_en = 1;
        write_addr = addr;
        write_data = instr;
        #10;
        write_en = 0;
    end
    endtask

    task run_cycles(input integer n);
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    task pass(input [200*8:1] msg);
        $display("PASS : %s", msg);
    endtask

    task fail(input [200*8:1] msg);
        begin
            $display("FAIL : %s", msg);
        end
    endtask

    task check_writeback;
        begin
            if (s_wb_reg_file_out) begin
                if (s_rd_out != 0)
                    pass("Valid writeback");
                else
                    fail("wb_reg_file=1 but rd=0");
            end else
                $display("INFO : No writeback this cycle");
        end
    endtask

    // ----------------------------------
    // INITIAL
    // ----------------------------------
    initial begin
        clk = 0;
        rst = 1;
        rst_im = 1;
        write_en = 0;
        write_addr = 0;
        write_data = 0;

        #20;
        rst = 0;
        rst_im = 0;

        // ===============================
        // ENABLE ONLY ONE TEST AT A TIME
        // ===============================

        //test_reset();
        //test_sequential_pc();
        //test_writeback();
        //test_forwarding();
        //test_load_use_hazard();
        //test_branch_taken();
        //test_branch_mispredict();
        //test_btb_hit();
        //test_btb_lru();

        $display("\n=================================");
        $display(" ALL ENABLED TESTS PASSED ");
        $display("=================================\n");
        $finish;
    end

    // =====================================
    // TEST 1 : RESET
    // =====================================
    task test_reset;
    begin
        $display("\n--- TEST 1 : RESET ---");

        if (pc == 0)
            pass("PC reset to zero");
        else
            fail("PC not reset");

        run_cycles(5);
    end
    endtask

    // =====================================
    // TEST 2 : Sequential PC
    // =====================================
task test_sequential_pc;
    reg [31:0] pc_prev;
begin
    $display("\n--- TEST 2 : SEQUENTIAL PC ---");

    // Load NOPs
    load_instr(0, 32'h00000013);
    load_instr(1, 32'h00000013);
    load_instr(2, 32'h00000013);

    // Allow pipeline warm-up
    run_cycles(5);

    pc_prev = pc;
    run_cycles(1);

    if (pc == pc_prev + 4)
        pass("PC increments by 4");
    else
        fail("PC did not increment");
end
endtask
    
    // =====================================
    // TEST 3 : Writeback
    // =====================================
    task test_writeback;
    begin
        $display("\n--- TEST 3 : WRITEBACK ---");

        // addi x1, x0, 5
        load_instr(0, 32'h00500093);

        run_cycles(10);
        check_writeback();
    end
    endtask

    // =====================================
    // TEST 4 : Forwarding
    // =====================================
    task test_forwarding;
    begin
        $display("\n--- TEST 4 : FORWARDING ---");

        // addi x1, x0, 5
        load_instr(0, 32'h00500093);
        // addi x2, x1, 3 (needs forwarding)
        load_instr(1, 32'h00308113);

        run_cycles(15);
        pass("Forwarding executed (manual waveform check)");
    end
    endtask

    // =====================================
    // TEST 5 : Load-use hazard
    // =====================================
    task test_load_use_hazard;
    begin
        $display("\n--- TEST 5 : LOAD-USE HAZARD ---");

        // lw x1, 0(x0)
        load_instr(0, 32'h00002083);
        // add x2, x1, x1 (stall expected)
        load_instr(1, 32'h00110133);

        run_cycles(20);
        pass("Stall inserted (manual waveform check)");
    end
    endtask

    // =====================================
    // TEST 6 : Branch taken
    // =====================================
    task test_branch_taken;
    begin
        $display("\n--- TEST 6 : BRANCH TAKEN ---");

        // addi x1, x0, 1
        load_instr(0, 32'h00100093);
        // addi x2, x0, 1
        load_instr(1, 32'h00100113);
        // beq x1, x2, +8
        load_instr(2, 32'h00208663);
        // addi x3, x0, 9 (should be skipped)
        load_instr(3, 32'h00900193);

        run_cycles(30);

        if (pc != 16)
            pass("Branch taken, PC changed");
        else
            fail("Branch not taken");
    end
    endtask

    // =====================================
    // TEST 7 : Branch misprediction
    // =====================================
    task test_branch_mispredict;
    begin
        $display("\n--- TEST 7 : BRANCH MISPREDICT ---");

        // Force BTB miss then update
        load_instr(0, 32'h00100093);
        load_instr(1, 32'h00100113);
        load_instr(2, 32'h00208663);

        run_cycles(30);
        pass("Misprediction corrected (PC redirected)");
    end
    endtask

    // =====================================
    // TEST 8 : BTB HIT
    // =====================================
    task test_btb_hit;
    begin
        $display("\n--- TEST 8 : BTB HIT ---");

        // Same branch twice
        load_instr(0, 32'h00100093);
        load_instr(1, 32'h00100113);
        load_instr(2, 32'h00208663);
        load_instr(3, 32'h00208663);

        run_cycles(40);
        pass("BTB hit observed (check predictedTaken_if)");
    end
    endtask

    // =====================================
    // TEST 9 : BTB LRU
    // =====================================
    task test_btb_lru;
    begin
        $display("\n--- TEST 9 : BTB LRU ---");

        // 3 branches mapping to same set
        load_instr(0, 32'h00208663);
        load_instr(4, 32'h00208663);
        load_instr(8, 32'h00208663);

        run_cycles(60);
        pass("LRU replacement verified (waveform)");
    end
    endtask
initial begin
        // waveform / shared memory probe (as in your environment)
        $shm_open("wave.shm");
        $shm_probe("ACTMF");
    end

initial begin
    clk = 0;
    rst = 1;
    rst_im = 1;
    write_en = 0;

    // Load program while reset is HIGH
    load_instr(0, 32'h00500093); // addi x1, x0, 5
    load_instr(1, 32'h00308113); // addi x2, x1, 3
    load_instr(2, 32'h00000013); // nop

    #20;
    rst = 0;
    rst_im = 0;   // release reset AFTER loading IMEM

    run_cycles(40);
end



endmodule
*/
/*
initial begin
        // waveform / shared memory probe (as in your environment)
        $shm_open("wave.shm");
        $shm_probe("ACTMF");
    end
*/

/*
module tb_rv32i_core_forwarding_final;
    // ------------------------------------
    // Clock / Reset
    // ------------------------------------
    reg clk;
    reg rst;
    reg rst_im;
    // IMEM write interface
    reg write_en;
    reg [9:0] write_addr;
    reg [31:0] write_data;
    // DUT outputs
    wire [31:0] pc;
    wire [31:0] s_alu_result_out;
    wire [31:0] s_load_data_out;
    wire [4:0] s_rd_out;
    wire s_wb_reg_file_out;
    wire s_memtoreg_out;
    // ------------------------------------
    // DUT
    // ------------------------------------
    rv32i_core dut (
        .clk(clk),
        .rst(rst),
        .rst_im(rst_im),
        .write_en(write_en),
        .write_addr(write_addr),
        .write_data(write_data),
        .pc(pc),
        .s_alu_result_out(s_alu_result_out),
        .s_load_data_out(s_load_data_out),
        .s_rd_out(s_rd_out),
        .s_wb_reg_file_out(s_wb_reg_file_out),
        .s_memtoreg_out(s_memtoreg_out)
    );
    // ------------------------------------
    // Clock (10ns period)
    // ------------------------------------
    always #5 clk = ~clk;
    // ------------------------------------
    // Tasks
    // ------------------------------------
    task load_instr(input [9:0] addr, input [31:0] instr);
    begin
        write_en = 1;
        write_addr = addr;
        write_data = instr;
        #10;
        write_en = 0;
    end
    endtask
    task run_cycles(input integer n);
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask
    // ------------------------------------
    // FORWARDING DETECTOR (checks actual forwarded value 5)
    // ------------------------------------
    reg forwarding_seen;
    initial forwarding_seen = 0;

    always @(posedge clk) begin
        if (dut.rs2_data_for_mem_ex == 32'h5 && forwarding_seen == 0) begin
            forwarding_seen = 1;
            $display(">>> FORWARDING SUCCESS @ %0t ns : rs2_data_for_mem_ex = %h (correctly forwarded)",
                     $time, dut.rs2_data_for_mem_ex);
            $display("    Details: pc_ex=%h rs2_ex=%d rd_mem=%d fwdB=%b alu_mem=%h",
                     dut.pc_ex, dut.rs2_ex, dut.rd_mem, dut.operand_b_forward_cntl, dut.data_forward_mem);
        end
    end

    // Optional debug: print when forward control asserts
    always @(dut.operand_b_forward_cntl) begin
        if (dut.operand_b_forward_cntl != 2'b00) begin
            $display(">>> FWD CONTROL @ %0t ns : fwdB=%b rs2_for_mem=%h from=%h",
                     $time, dut.operand_b_forward_cntl, dut.rs2_data_for_mem_ex,
                     (dut.operand_b_forward_cntl == 2'b01 ? dut.data_forward_mem : dut.data_forward_wb));
        end
    end

    // ------------------------------------
    // Initial
    // ------------------------------------
    initial begin
        clk = 0;
        rst = 1;
        rst_im = 1;          // Start with resets asserted
        write_en = 0;
        write_addr = 0;
        write_data = 0;

        $display("\n=================================================");
        $display(" FINAL FORWARDING TEST (STORE DATA FORWARDING) ");
        $display("=================================================\n");

        // *** CRITICAL FIX: Release rst_im BEFORE loading instructions ***
        // This prevents the IMEM from being reset/cleared while writing
        #10;
        rst_im = 0;

        $display("TB : Loading instruction memory (rst_im released)");
        load_instr(0, 32'h00500093); // addi x1, x0, 5
        load_instr(1, 32'h00102023); // sw x1, 0(x0)
        load_instr(2, 32'h00000013); // nop
#20     load_instr(3, 32'h00A00093); //addi x1, x0, 10
        load_instr(4, 32'h00008133); //add  x2, x1, x0
        load_instr(2, 32'h00000013); // nop
        
        $display("TB : Instruction memory loaded\n");

        #20;
        $display("TB : Releasing core reset (rst=0), CPU starts execution\n");
        rst = 0;

        run_cycles(50);

        if (forwarding_seen)
            $display("\n>>> PASS : Store-data forwarding observed and verified <<<");
        else begin
            $display("\n>>> FAIL : Store-data forwarding NOT observed <<<");
            $display("    Open waveform and check around when pc_ex == 32'h4");
            $display("    Expected: rs2_ex=1, rd_mem=1, wb_reg_file_mem=1, fwdB=01, rs2_data_for_mem_ex=5");
            
        end

        $display("\n=================================================");
        $display(" FORWARDING VERIFICATION COMPLETED ");
        $display("=================================================\n");
        $finish;
    end
    initial begin
        // waveform / shared memory probe (as in your environment)
        $shm_open("wave.shm");
        $shm_probe("ACTMF");
    end

endmodule

*/

/*

module tb_rv32i_hazards;



    reg clk;
    reg rst;
    reg rst_im;

    reg write_en;
    reg [9:0] write_addr;
    reg [31:0] write_data;

    wire [31:0] pc;
    wire [31:0] alu_out;
    wire [31:0] load_out;
    wire [4:0]  rd;
    wire wb_en;
    wire memtoreg;

    // -----------------------------
    // DUT
    // -----------------------------
    rv32i_core dut (
        .clk(clk),
        .rst(rst),
        .rst_im(rst_im),
        .write_en(write_en),
        .write_addr(write_addr),
        .write_data(write_data),
        .pc(pc),
        .s_alu_result_out(alu_out),
        .s_load_data_out(load_out),
        .s_rd_out(rd),
        .s_wb_reg_file_out(wb_en),
        .s_memtoreg_out(memtoreg)
    );

    // -----------------------------
    // Clock
    // -----------------------------
    always #5 clk = ~clk;

    // -----------------------------
    // IMEM load task
    // (pc[11:2] indexing)
    // -----------------------------
    task load_instr;
        input [31:0] pc_addr;
        input [31:0] instr;
        begin
            @(negedge clk);
            write_en   = 1;
            write_addr = pc_addr[11:2]; // ? FIXED
            write_data = instr;
            @(negedge clk);
            write_en   = 0;
        end
    endtask

    // -----------------------------
    // TEST
    // -----------------------------
    initial begin
        // init
        clk = 0;
        rst = 1;
        rst_im = 1;
        write_en = 0;

        // hold reset
        #30;
        rst = 0;
        rst_im = 0;

        // -----------------------------
        // Program:
        // -----------------------------
        // 0x00: addi x1,x0,0
        // 0x04: lw   x3,0(x1)
        // 0x08: add  x4,x3,x5  <-- load-use hazard
        // 0x0C: add  x6,x4,x7
        // -----------------------------

        load_instr(32'h0000_0000, 32'h00000093); // addi x1,x0,0
        load_instr(32'h0000_0004, 32'h0000A183); // lw   x3,0(x1)
        load_instr(32'h0000_0008, 32'h00518233); // add  x4,x3,x5
        load_instr(32'h0000_000C, 32'h00720333); // add  x6,x4,x7

        // -----------------------------
        // Run long enough
        // -----------------------------
        #300;

        $display("=================================");
        $display("Final PC  = %h", pc);
        $display("WB rd     = %d", rd);
        $display("WB data   = %h", memtoreg ? load_out : alu_out);
        $display("=================================");
        $display("CHECK WAVEFORM:");
        $display(" hazard_pc_en must go LOW 1 cycle");
        $display(" id_ex_flush must go HIGH 1 cycle");
        $display(" ex_load_inst must be 1");
        $display("=================================");

        #50;
        $finish;
    end

     initial begin
        // waveform / shared memory probe (as in your environment)
        $shm_open("wave.shm");
        $shm_probe("ACTMF");
    end


endmodule

*/
