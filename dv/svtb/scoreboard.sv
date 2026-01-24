`include "catawba_macros.svh"

`uvm_analysis_imp_decl ( _observed_state )

class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    uvm_analysis_imp_observed_state #(pipe_state_transaction, scoreboard) aport_observed_state;

    uvm_tlm_fifo #(pipe_state_transaction) expected_fifo;
    uvm_tlm_fifo #(pipe_state_transaction) observed_fifo;

    bit test_passed;
    uint32_t vector_count, pass_count, fail_count;

    virtual catawba_probe_if probe_if;
    main_memory dut_memory_model;

    function void setup_spike();
        string asm_test;
        string elf_path;

        if (!$value$plusargs("ASM_TEST=%s", asm_test)) begin
            `uvm_fatal(get_full_name(), "ASM_TEST not specified for asm_memory_response_seq")
        end

        spike_set_isa("RV32I");

        elf_path = {get_environment_variable("WORKDIR"), "/", asm_test, ".elf"};
        `uvm_info(get_full_name(), $sformatf("spike is loading %s", elf_path), UVM_LOW)
        spike_create(elf_path);

        spike_set_pc(RESET_PC);
        `uvm_info(get_full_name(), $sformatf("spike PC set to 0x%08x", RESET_PC), UVM_LOW)
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        aport_observed_state = new("aport_observed_state", this);

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
            .field_name("dut_memory_model"),
            .value(dut_memory_model)
        )) else `uvm_fatal(get_full_name(), "Couldn't get dut_memory_model from uvm_config_db")

        setup_spike();
    endfunction

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void produce_next_spike_commit();
        int32_t status;
        pipe_state_transaction expected_pipe_state_tx;
        uint64_t int_regs[32];
        memory_t dut_data_memory;

        expected_pipe_state_tx = pipe_state_transaction::type_id::create(.name("expected_pipe_state_tx"), .contxt(get_full_name()));

        expected_pipe_state_tx.pc = spike_get_pc(0);

        status = spike_step();
        if (status) begin
            `uvm_error(get_full_name(), $sformatf("spike_step returned a non-zero code %0d", status))
        end

        status = spike_get_all_gprs(0, int_regs);
        if (status == 32) foreach (int_regs[i]) expected_pipe_state_tx.int_regs[i] = uint32_t'(int_regs[i]);
        else `uvm_error(get_full_name(), $sformatf("spike_get_all_gprs returned a non-32 code %0d", status))

        dut_data_memory = dut_memory_model.tb_pull_memory();
        foreach (dut_data_memory[i]) begin
            expected_pipe_state_tx.data_memory[i] = spike_read_mem_word(i);
            `uvm_info(get_full_name(), $sformatf("spike_read_mem_word(0x%08x) returned %08x", i, expected_pipe_state_tx.data_memory[i]), UVM_HIGH)
        end

        void'(expected_fifo.try_put(expected_pipe_state_tx));

        `uvm_info(get_full_name(), $sformatf("Spike state %s", expected_pipe_state_tx.convert2string()), UVM_HIGH)
    endfunction

    function void write_observed_state(pipe_state_transaction tx);
        void'(observed_fifo.try_put(tx));

        produce_next_spike_commit();
    endfunction

    task run_phase(uvm_phase phase);
        pipe_state_transaction expected_tx, observed_tx;
        string printout_str;
        string name;

        name = "scoreboard comparer";
        forever begin
            `uvm_info(name, "WAITING for expected output", UVM_DEBUG)
            expected_fifo.get(expected_tx);
            `uvm_info(name, "WAITING for observed output", UVM_DEBUG)
            observed_fifo.get(observed_tx);


            printout_str = {
                "\n\n#####################################\n",
                    "  EXPECTED (BFM) vs. OBSERVED (RTL)\n",
                    "#####################################\n",
                expected_tx.print_comparison(observed_tx),
                "\n"
            };

            if (observed_tx.compare(expected_tx)) begin
                vector_pass();
                `uvm_info("Proc State PASS: ", printout_str, UVM_HIGH)
            end else begin
                vector_fail();
                `uvm_error("Proc State FAIL: ", printout_str)
            end
        end
    endtask

    function void check_phase(uvm_phase phase);
        uvm_report_server server;
        pipe_state_transaction expected_tx, observed_tx;
        string printout_str;
        bit other_reason_to_fail;

        super.check_phase(phase);

        other_reason_to_fail = 1'b0;

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

    function void final_phase(uvm_phase phase);
        super.final_phase(phase);
        spike_delete();

        `uvm_info(get_full_name(), $sformatf("Simulation ending at time %0t ns", $time()), UVM_LOW)
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
