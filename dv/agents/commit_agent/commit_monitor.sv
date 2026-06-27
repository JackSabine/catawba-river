class commit_monitor extends uvm_monitor;
    `uvm_component_utils(commit_monitor)

    uvm_analysis_port #(pipe_state_transaction) state_ap;

    virtual catawba_probe_if probe_if;
    main_memory dut_memory_model;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        assert(uvm_config_db #(virtual catawba_probe_if)::get(
            .cntxt(this),
            .inst_name("*"),
            .field_name("probe_if"),
            .value(probe_if)
        )) else `uvm_fatal(get_full_name(), "Couldn't get probe_if from config db")

        assert(uvm_config_db #(main_memory)::get(
            .cntxt(this),
            .inst_name("*"),
            .field_name("dut_memory_model"),
            .value(dut_memory_model)
        )) else `uvm_fatal(get_full_name(), "Couldn't get dut_memory_model from uvm_config_db")

        state_ap = new(.name("state_ap"), .parent(this));
    endfunction

    task run_phase(uvm_phase phase);
        pipe_state_transaction state_tx;

        super.run_phase(phase);

        forever begin
            @(negedge probe_if.clk); // FIXME: cheating a little here, should sample on posedge but don't want to see the memory write from the next instruction - fix when store queue added

            if (probe_if.commit_valid) begin
                state_tx = pipe_state_transaction::type_id::create(.name("state_tx"));

                state_tx.pc = this.probe_if.wb_pc;

                for (uint32_t i = 0; i < `NUM_REGS; i++) begin
                    if (!$isunknown(this.probe_if.int_registers[i])) begin
                        state_tx.int_regs[i] = this.probe_if.int_registers[i];
                    end
                end

                if (this.probe_if.wb_rd != 0) begin
                    `uvm_info(get_full_name(), $sformatf("Substituting reg value from commit: x%0d = 0x%08h", this.probe_if.wb_rd, this.probe_if.wb_rd_value), UVM_MEDIUM)
                    state_tx.int_regs[this.probe_if.wb_rd] = this.probe_if.wb_rd_value;
                end

                state_tx.data_memory = dut_memory_model.tb_pull_memory();

                // Capture tracked CSR values at commit time
                state_tx.csrs[32'h300] = this.probe_if.csr_mstatus;
                state_tx.csrs[32'h305] = this.probe_if.csr_mtvec;
                state_tx.csrs[32'h341] = this.probe_if.csr_mepc;
                state_tx.csrs[32'h342] = this.probe_if.csr_mcause;
                state_tx.csrs[32'h343] = this.probe_if.csr_mtval;

                `uvm_info(get_full_name(), $sformatf("dut PC: 0x%08X -- insn: %s", state_tx.pc, disassemble_rv32i(1'b1, uint32_t'(this.probe_if.wb_instruction))), UVM_LOW)

                `uvm_info(get_full_name(), $sformatf("Committing state %s", state_tx.convert2string()), UVM_HIGH)

                state_ap.write(state_tx);
            end
        end
    endtask
endclass