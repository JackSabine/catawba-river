class asm_memory_response_seq extends base_memory_response_seq;
    `uvm_object_utils(asm_memory_response_seq)

    uvm_analysis_port #(pipe_state_transaction) expected_pipe_state_ap;

    string asm_test;

    function new(string name = "");
        super.new(name);

        if (!$value$plusargs("ASM_TEST=%s", asm_test)) begin
            `uvm_fatal(get_full_name(), "ASM_TEST not specified for asm_memory_response_seq")
        end

        expected_pipe_state_ap = new(.name("expected_pipe_state_ap"), .parent(m_sequencer));
    endfunction

    function memory_t read_assembled();
        int fd;
        uint32_t address;
        uint32_t data;
        memory_t memory;

        fd = $fopen({get_environment_variable("WORKAREA"), "/dv/asm/", asm_test, "/assembled.txt"}, "r");

        if (fd) `uvm_info(get_full_name(), $sformatf("Opened %s successfully :)", asm_test), UVM_HIGH)
        else `uvm_error(get_full_name(), $sformatf("Couldn't open %s :(", asm_test))

        address = 0;
        while ($fscanf(fd, "%32b", data) == 1) begin
            `uvm_info(get_full_name(), $sformatf("Placing %32b at address 0x%08h", data, address), UVM_HIGH)
            memory[address] = data;
            address += 4; // instructions are 4 bytes wide, next insn falls 4 steps away
        end

        $fclose(fd);

        return memory;
    endfunction

    function pipe_state_transaction read_result();
        int fd;
        uint32_t line_number;
        string line;
        uint32_t index;
        uint32_t data;

        pipe_state_transaction pipe_state_tx;

        pipe_state_tx = pipe_state_transaction::type_id::create(.name("pipe_state_tx"), .contxt(get_full_name()));

        fd = $fopen({get_environment_variable("WORKAREA"), "/dv/asm/", asm_test, "/result"}, "r");

        if (fd) `uvm_info(get_full_name(), $sformatf("Opened result for asm_test %s successfully", asm_test), UVM_DEBUG)
        else `uvm_error(get_full_name(), $sformatf("Couldn't open result for asm_test %s", asm_test))

        // Replace $fscanf calls with $sscanf, read the line with $fgets and then pass to $fscanf
        // $fscanf, even when it fails, is destructive and moves the read pointer

        line_number = 1;
        while ($fgets(line, fd)) begin
            if (
                $sscanf(line, "x%0d: 0x%08h", index, data) == 2 ||
                $sscanf(line, "x%0d: 0b%32b", index, data) == 2 ||
                $sscanf(line, "x%0d: %0d", index, data) == 2
            ) begin
                if (index < `NUM_REGS) begin
                    pipe_state_tx.int_regs[index] = data;
                    `uvm_info(get_full_name(), $sformatf("Expecting %0d/0x%08h/0b%32b in register %0d", data, data, data, index), UVM_HIGH)
                end else begin
                    `uvm_error(get_full_name(), $sformatf("While reading asm result file, encountered an out of range register index %0d", index))
                end
            end else if (
                $sscanf(line, "0x%08h: 0x%08h", index, data) == 2 ||
                $sscanf(line, "0x%08h: 0b%32b", index, data) == 2 ||
                $sscanf(line, "0x%08h: %d", index, data) == 2
            ) begin
                `uvm_info(get_full_name(), $sformatf("Expecting %0d/0x%08h/0b%32b at index 0x%08h", data, data, data, index), UVM_HIGH)
                pipe_state_tx.data_memory[index++] = data;
            end else begin
                `uvm_error(get_full_name(), $sformatf("Discarding line %0d that did not match any pattern: `%s`", line_number, line))
            end

            line_number++;
        end

        $fclose(fd);

        return pipe_state_tx;
    endfunction

    virtual task body();
        memory_t memory;
        pipe_state_transaction expected_pipe_state_tx;

        memory = this.read_assembled();
        this.seed_memory(memory);

        expected_pipe_state_tx = this.read_result();
        `uvm_info(get_full_name(), {"Pushing expected tx\n:::", expected_pipe_state_tx.convert2string()}, UVM_DEBUG)
        expected_pipe_state_ap.write(expected_pipe_state_tx);

        super.body();
    endtask
endclass
