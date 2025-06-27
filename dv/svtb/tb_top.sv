module tb_top;
    import uvm_pkg::*;
    import catawba_pkg::*;

    clock_config clk_config;
    main_memory dut_memory_model;

    bit clk_enabled = 1'b0;
    logic clk = 1'b0;
    reset_if rst_if(clk);

    memory_if hmem_if(clk);

    // Dut instantiation
    top dut (
        .clk(clk),
        .rst_if(rst_if),
        .hmem_if(hmem_if)
    );

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

        // Higher memory interface
        uvm_config_db #(virtual memory_if)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.*"),
            .field_name("memory_responder_if"),
            .value(hmem_if)
        );

        dut_memory_model = main_memory::type_id::create(.name("dut_memory_model"), .parent(null));
        uvm_config_db #(main_memory)::set(
            .cntxt(null),
            .inst_name("uvm_test_top.*"),
            .field_name("dut_memory_model"),
            .value(dut_memory_model)
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
