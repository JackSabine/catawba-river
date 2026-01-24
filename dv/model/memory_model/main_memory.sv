class main_memory extends uvm_object;
    `uvm_object_utils(main_memory)

    local memory_t memory;

    function new(string name = "");
        super.new(name);
    endfunction

    local function uint32_t compute_default_value(uint32_t addr);
        return 32'h0;
    endfunction

    function memory_response_t read(uint32_t addr, memory_operation_size_e op_size);
        memory_response_t resp;

        resp.req_word = memory.exists(addr) ?
            memory[addr] :
            compute_default_value(addr);

        return resp;
    endfunction

    function memory_response_t write(uint32_t addr, memory_operation_size_e op_size, uint32_t data);
        memory_response_t resp;

        resp = this.read(addr, op_size);
        memory[addr] = data;

        `uvm_info(
            get_full_name(),
            $sformatf("Received write to address 0x%08h with data 0x%08h", addr, data),
            UVM_MEDIUM
        )

        return resp;
    endfunction

    function void tb_write(uint32_t addr, uint32_t data);
        memory[addr] = data;
    endfunction

    function memory_t tb_pull_memory();
        return this.memory;
    endfunction
endclass
