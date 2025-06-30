module tb_top;
    import uvm_pkg::*;
    import catawba_pkg::*;
    import torrence_params::*;

    clock_config clk_config;
    main_memory insn_memory;
    main_memory data_memory;

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

        // pass instruction memory model to memory_rsp_agent for icache with a generic name
        insn_memory = main_memory::type_id::create(.name("insn_memory"), .parent(null));
        insn_memory.set_cache_type(ICACHE);
        uvm_config_db #(main_memory)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.env.icache_rsp_agent.*"),
            .field_name("dut_memory_model"),
            .value(insn_memory)
        );
        // pass data memory model to memory_rsp_agent for dcache with a generic name
        data_memory = main_memory::type_id::create(.name("data_memory"), .parent(null));
        data_memory.set_cache_type(DCACHE);
        uvm_config_db #(main_memory)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.env.dcache_rsp_agent.*"),
            .field_name("dut_memory_model"),
            .value(data_memory)
        );


        // pass the same instruction memory model under a special name for tests to manipulate
        uvm_config_db #(main_memory)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.*"),
            .field_name("insn_memory"),
            .value(insn_memory)
        );
        // pass the same data memory model under a special name for tests to examine
        uvm_config_db #(main_memory)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.*"),
            .field_name("data_memory"),
            .value(data_memory)
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
