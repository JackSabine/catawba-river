assign probe_if.int_registers = dut.de.regfile.register_file;
assign probe_if.wb_halted = dut.mem_wb_if.halt;
assign probe_if.fe_halted = dut.fe_de_if.halt;
assign probe_if.clk = dut.clk;
