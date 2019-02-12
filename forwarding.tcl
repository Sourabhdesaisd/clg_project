puts "=========================================="
puts " Loading forwarding waveform (SimVision)"
puts "=========================================="

# Clear old waves
wave delete *

# Clock / reset
wave add tb_rv32i_core_forwarding_final.clk
wave add tb_rv32i_core_forwarding_final.rst
wave add tb_rv32i_core_forwarding_final.rst_im

# PC & instruction flow
wave add tb_rv32i_core_forwarding_final.dut.pc
wave add tb_rv32i_core_forwarding_final.dut.instr_if
wave add tb_rv32i_core_forwarding_final.dut.instr_id

# EX stage registers
wave add tb_rv32i_core_forwarding_final.dut.rs1_ex
wave add tb_rv32i_core_forwarding_final.dut.rs2_ex
wave add tb_rv32i_core_forwarding_final.dut.rd_mem

# Forwarding control
wave add tb_rv32i_core_forwarding_final.dut.operand_a_forward_cntl
wave add tb_rv32i_core_forwarding_final.dut.operand_b_forward_cntl

# Forwarding data paths
wave add tb_rv32i_core_forwarding_final.dut.data_forward_mem
wave add tb_rv32i_core_forwarding_final.dut.data_forward_wb

# EX datapath
wave add tb_rv32i_core_forwarding_final.dut.op1_selected_ex
wave add tb_rv32i_core_forwarding_final.dut.alu_result_ex

# MEM/WB
wave add tb_rv32i_core_forwarding_final.dut.alu_result_mem
wave add tb_rv32i_core_forwarding_final.dut.wb_reg_file_mem

puts "=========================================="
puts " Forwarding waveform loaded successfully"
puts "=========================================="

