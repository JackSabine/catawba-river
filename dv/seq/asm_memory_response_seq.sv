class asm_memory_response_seq extends base_memory_response_seq;
    `uvm_object_utils(asm_memory_response_seq)

    string asm_test;

    function new(string name = "");
        super.new(name);

        if (!$value$plusargs("ASM_TEST=%s", asm_test)) begin
            `uvm_fatal(get_full_name(), "ASM_TEST not specified for asm_memory_response_seq")
        end
    endfunction

    virtual task body();
        `include "memory_maps.sv"

        if (!asm_files.exists(asm_test)) begin
            `uvm_fatal(get_full_name(), $sformatf("No memory map found for ASM_TEST='%s'", asm_test))
        end

        this.seed_memory(asm_files[asm_test]);

        super.body();
    endtask
endclass
