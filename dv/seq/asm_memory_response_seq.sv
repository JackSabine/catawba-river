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
        memory_t spike_init_instructions;
        `include "memory_maps.sv"

        // spike pc starts at 32'h00001000? why
        spike_init_instructions = '{
              32'h00001000: 32'h00000297 // auipc   t0, 0x0
            , 32'h00001004: 32'h02028593 // addi    a1, t0, 32
            , 32'h00001008: (ZICSR_ENABLED ?
                32'hf1402573 :  // csrr    a0, mhartid
                32'h00000513    // addi    a0, x0, 0
            )
            , 32'h0000100c: 32'h0182a283 // lw      t0, 24(t0)
            , 32'h00001010: 32'h00028067 // jr      t0
            , 32'h00001014: 32'h00000000 // reserved
            , 32'h00001018: 32'h80001000 // lower 32 bits of user program entry point (must match the text section start in ${WORKAREA}/dv/asm/link.ld)
            , 32'h0000101c: 32'h00000000 // upper 32 bits of user program entry point (not valid for 32 bit PC)
        };

        if (!asm_files.exists(asm_test)) begin
            `uvm_fatal(get_full_name(), $sformatf("No memory map found for ASM_TEST='%s'", asm_test))
        end

        this.seed_memory(spike_init_instructions);
        this.seed_memory(asm_files[asm_test]);

        super.body();
    endtask
endclass
