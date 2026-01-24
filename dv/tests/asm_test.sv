class asm_test extends base_test;
    `uvm_component_utils(asm_test)

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    function void seed_memory(uint32_t defaults [uint32_t]);
        uint32_t addr;
        foreach (defaults[addr]) begin
            dut_memory_model.tb_write(addr, defaults[addr]);
        end
    endfunction

    function void start_of_simulation_phase(uvm_phase phase);
        string asm_test;
        `include "memory_maps.sv"

        super.start_of_simulation_phase(phase);

        if (!$value$plusargs("ASM_TEST=%s", asm_test)) begin
            `uvm_fatal(get_full_name(), "ASM_TEST not specified for asm_memory_response_seq")
        end


        if (!asm_files.exists(asm_test)) begin
            `uvm_fatal(get_full_name(), $sformatf("No memory map found for ASM_TEST='%s'", asm_test))
        end

        seed_memory(asm_files[asm_test]);
        `uvm_info(
            get_full_name(),
            $sformatf("Seeded memory for ASM_TEST='%s'", asm_test),
            UVM_LOW
        )
    endfunction
endclass
