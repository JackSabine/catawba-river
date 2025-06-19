module tb_top;
    import uvm_pkg::*;
    import catawba_pkg::*;

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
