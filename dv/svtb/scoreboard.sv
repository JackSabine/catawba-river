class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    clock_config clk_config;

    uint32_t vector_count, pass_count, fail_count;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    function new (string name, uvm_component parent);
        super.new(name, parent);

        assert(uvm_config_db #(clock_config)::get(
            .cntxt(null),
            .inst_name("*"),
            .field_name("clock_config"),
            .value(clk_config)
        )) else `uvm_fatal(get_full_name(), "Couldn't get clock_config from config db")
    endfunction

    function void predictor();
    endfunction

    function void observer();
    endfunction

    task comparer();
    endtask

    task run_phase(uvm_phase phase);
        fork
        join
    endtask

    function void extract_phase(uvm_phase phase);
    endfunction

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
    endfunction

    function void report_phase(uvm_phase phase);
        string report_str;
        string pass_fail_str;

        super.report_phase(phase);

        pass_fail_str = {
            "\n\n",
            "---------------------------------------------------\n",
            "-                   TEST PASSED                   -\n",
            "---------------------------------------------------\n",
            "\n"
        };

        report_str = {
            report_str,
            pass_fail_str
        };

        `uvm_info("PASSED", report_str, UVM_LOW)
    endfunction

    function void vector_pass();
        vector_count++;
        pass_count++;
    endfunction

    function void vector_fail();
        vector_count++;
        fail_count++;
    endfunction
endclass
