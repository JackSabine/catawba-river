`include "torrence_macros.svh"

class main_memory extends uvm_object;
    `uvm_object_utils(main_memory)

    local uint32_t memory [uint32_t];

    function new(string name = "");
        super.new(name);
    endfunction

    local function uint32_t compute_default_value(uint32_t addr);
        uint32_t result;

        if (addr < `RO_RW_MEMORY_BOUNDARY) begin
            // ICache Request (just pass a NOP === add x0, x0, #0)
            result = {'0, 7'b0010011};
        end else begin
            result = 0;
            while (addr != 0) begin
                result = (result * 16) + (addr % 16);
                addr = addr / 16;
            end
        end

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
endclass
