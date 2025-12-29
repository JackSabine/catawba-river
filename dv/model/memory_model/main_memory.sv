class main_memory extends uvm_object;
    `uvm_object_utils(main_memory)

    local memory_t memory;
    local cache_type_e cache_type;

    function new(string name = "");
        super.new(name);
    endfunction

    local function uint32_t compute_default_value(uint32_t addr);
        uint32_t result;

        case (this.cache_type)
            ICACHE: result = `NOP;
            DCACHE: begin
                result = 0;
                while (addr != 0) begin
                    result = (result * 16) + (addr % 16);
                    addr = addr / 16;
                end
            end
            default: result = 32'hABCD_DCBA;
        endcase

        return result;
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

        return resp;
    endfunction

    function void tb_write(uint32_t addr, uint32_t data);
        memory[addr] = data;
    endfunction

    function memory_t tb_pull_memory();
        return this.memory;
    endfunction

    function void set_cache_type(cache_type_e cache_type);
        this.cache_type = cache_type;
    endfunction

    function cache_type_e get_cache_type();
        return this.cache_type;
    endfunction
endclass
