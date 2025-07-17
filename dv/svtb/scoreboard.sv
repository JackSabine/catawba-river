`include "catawba_macros.svh"

`uvm_analysis_imp_decl ( _expected_state )

class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    uvm_analysis_imp_expected_state #(pipe_state_transaction, scoreboard) aport_expected_state;

    uvm_tlm_fifo #(pipe_state_transaction) expected_fifo;
    uvm_tlm_fifo #(pipe_state_transaction) observed_fifo;

    bit test_passed;
    uint32_t vector_count, pass_count, fail_count;

    virtual catawba_probe_if probe_if;
    main_memory data_memory_model;

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        aport_expected_state = new("aport_expected_state", this);

        expected_fifo = new("expected_fifo", this);
        observed_fifo = new("observed_fifo", this);

        assert(uvm_config_db #(virtual catawba_probe_if)::get(
            .cntxt(this),
            .inst_name("*"),
            .field_name("probe_if"),
            .value(probe_if)
        )) else `uvm_fatal(get_full_name(), "Couldn't retrieve probe_if from uvm_config_db")

        assert(uvm_config_db #(main_memory)::get(
            .cntxt(this),
            .inst_name("*"),
            .field_name("data_memory"),
            .value(data_memory_model)
        )) else `uvm_fatal(get_full_name(), "Couldn't get data_memory from uvm_config_db")
    endfunction

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void write_expected_state(pipe_state_transaction tx);
        void'(expected_fifo.try_put(tx));
    endfunction

    function void extract_phase(uvm_phase phase);
        pipe_state_transaction observed_pipe_state_tx;

        observed_pipe_state_tx = pipe_state_transaction::type_id::create(.name("observed_pipe_state_tx"), .contxt(get_full_name()));

        for (uint32_t i = 0; i < `NUM_REGS; i++) begin
            if (!$isunknown(this.probe_if.int_registers[i])) begin
                `uvm_info(get_full_name(), $sformatf("Register x%0d had a value of %0d", i, this.probe_if.int_registers[i]), UVM_MEDIUM)
                observed_pipe_state_tx.int_regs[i] = this.probe_if.int_registers[i];
            end
        end

        observed_pipe_state_tx.data_memory = data_memory_model.tb_pull_memory();

        `uvm_info(get_full_name(), {"Pushing observed tx\n:::", observed_pipe_state_tx.convert2string()}, UVM_DEBUG)

        void'(observed_fifo.try_put(observed_pipe_state_tx));
    endfunction

    function void check_phase(uvm_phase phase);
        uvm_report_server server;
        pipe_state_transaction expected_tx, observed_tx;
        string printout_str;
        bit other_reason_to_fail;

        super.check_phase(phase);

        other_reason_to_fail = 1'b0;

        if (expected_fifo.is_empty()) begin
            `uvm_error(get_full_name(), "expected_fifo should have at least 1 entry")
            other_reason_to_fail = 1'b1;
        end
        if (observed_fifo.is_empty()) begin
            `uvm_error(get_full_name(), "observed_fifo should have at least 1 entry")
            other_reason_to_fail = 1'b1;
        end

        while (!expected_fifo.is_empty() && !observed_fifo.is_empty()) begin
            `uvm_info(get_full_name(), $sformatf("expected_fifo has %0d entries and observed_fifo has %0d entries", expected_fifo.used(), observed_fifo.used()), UVM_DEBUG)
            void'(expected_fifo.try_get(expected_tx));
            void'(observed_fifo.try_get(observed_tx));

            printout_str = $sformatf(
                {
                    "\n*OBSERVED*:\n%s",
                    "\n*EXPECTED*:\n%s"
                },
                observed_tx.convert2string(),
                expected_tx.convert2string()
            );

            if (observed_tx.compare(expected_tx)) begin
                vector_pass();
                `uvm_info("Proc State PASS: ", printout_str, UVM_HIGH)
            end else begin
                vector_fail();
                `uvm_error("Proc State FAIL: ", printout_str)
            end
        end

        if (expected_fifo.used() != 0 ||  observed_fifo.used() != 0) begin
            `uvm_error(get_full_name(), $sformatf("expected_fifo has %0d leftover entries and observed_fifo has %0d leftover entries", expected_fifo.used(), observed_fifo.used()))
            other_reason_to_fail = 1'b1;
        end

        server = uvm_report_server::get_server();

        test_passed = (vector_count != 0) && (fail_count == 0) && (other_reason_to_fail == 1'b0) && (server.get_severity_count(UVM_ERROR) == 0);
    endfunction

    function void report_phase(uvm_phase phase);
        string report_str;
        string pass_fail_str;

        super.report_phase(phase);

        if (test_passed) begin
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
        end else begin
            pass_fail_str = {
                "\n\n",
                "---------------------------------------------------\n",
                "-                   TEST FAILED                   -\n",
                "---------------------------------------------------\n",
                "\n"
            };

            report_str = {
                report_str,
                pass_fail_str
            };

            `uvm_error("FAILED", report_str)
        end
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
