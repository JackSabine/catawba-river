module tb_top;
    import uvm_pkg::*;
    import catawba_pkg::*;
    import catawba_types::*;
    import catawba_params::*;
    import torrence_params::*;

    clock_config clk_config;

    bit clk_enabled = 1'b0;
    logic clk = 1'b0;
    reset_if rst_if(clk);

    memory_if icache_if(clk);
    memory_if dcache_if(clk);

    // Dut instantiation
    pipeline dut(
        .clk(clk),
        .rst_if(rst_if),
        .icache_if(icache_if),
        .dcache_if(dcache_if)
    );

    `include "catawba_probes.svh"

    bind register_scoreboard register_scoreboard_assertions reg_scoreboard_asserts (.*);

    function tb_string_t read_stage_insn(logic valid, instruction_t insn);
        string s;
        string reversed_s;
        tb_string_t tbs;
        tb_string_t reversed_tbs;

        s = disassemble_rv32i(bit'(valid), uint32_t'(insn));

        // Directly casting string to tb_string_t yields this:
        // string s = {'H', 'i', '\0'} --> tb_string_t tbs = {8'h0, 8'h0, ..., 8'h0, 'H', 'i'}
        // This makes the Vivado wave viewer display the string right-aligned
        //
        // To make the wave view show it left-aligned:
        // 1. Reverse the string:  {'H', 'i', '\0'} --> {'\0', 'i', 'H'}
        reversed_s = {<<byte{s}};
        // 2. Cast to tb_string_t: {'\0', 'i', 'H'} --> {8'h0, ..., 8'h0, 'i', 'H'}
        tbs = tb_string_t'(reversed_s);
        // 3. Reverse the tb_string_t: {8'h0, ..., 8'h0, 'i', 'H'} --> {'H', 'i', 8'h0, ... 8'h0}
        reversed_tbs = {<<byte{tbs}};

        return reversed_tbs;
    endfunction

    tb_string_t fe_insn, de_insn, ex_insn, mem_insn, wb_insn;

    always_comb fe_insn  = read_stage_insn(dut.fe.icache_if.req_fulfilled, dut.fe.instruction);
    always_comb de_insn  = read_stage_insn(dut.de.fe_if.valid,             dut.de.fe_if.instruction);
    always_comb ex_insn  = read_stage_insn(dut.ex.de_if.valid,             dut.ex.de_if.instruction);
    always_comb mem_insn = read_stage_insn(dut.mem.ex_if.valid,            dut.mem.ex_if.instruction);
    always_comb wb_insn  = read_stage_insn(dut.wb.mem_if.valid,            dut.wb.mem_if.instruction);

    initial begin
        @(posedge clk_enabled);

        forever begin
            #(clk_config.t_half_period);
            clk = ~clk;
        end
    end

    initial begin
        // Reset interface
        uvm_config_db #(virtual reset_if)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.*"),
            .field_name("reset_if"),
            .value(rst_if)
        );

        // icache interface
        uvm_config_db #(virtual memory_if)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.env.icache_rsp_agent.*"),
            .field_name("memory_responder_if"),
            .value(icache_if)
        );
        // dcache interface
        uvm_config_db #(virtual memory_if)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.env.dcache_rsp_agent.*"),
            .field_name("memory_responder_if"),
            .value(dcache_if)
        );

        // Clock configuration
        clk_config = clock_config::type_id::create("clk_config");
        assert(clk_config.randomize() with { t_period == 2; })
            else `uvm_fatal("tb_top", "Could not randomize clk_config")
        `uvm_info("tb_top", clk_config.sprint(), UVM_LOW)
        clk_enabled = 1'b1;

        uvm_config_db #(clock_config)::set(
            .cntxt(null),
            .inst_name("*"),
            .field_name("clock_config"),
            .value(clk_config)
        );

        // UVM test run
        run_test();
    end
endmodule
