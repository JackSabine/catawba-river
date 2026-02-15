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

    function memory_t read_memory_file(string filename);
        int fd;
        string line;
        logic [31:0] addr;
        logic [31:0] data;
        memory_t mem;
        int scan_result;
        int i;

        fd = $fopen(filename, "r");
        if (fd == 0) begin
            `uvm_fatal(get_full_name(), $sformatf("Failed to open file: %s", filename))
        end

        i = 1;

        while (!$feof(fd)) begin
            if ($fgets(line, fd)) begin
                scan_result = $sscanf(line, "%h: %h", addr, data);
                if (scan_result == 2) begin
                    mem[addr] = data;
                end else begin
                    `uvm_warning(get_full_name(), $sformatf("Skipping malformed line %0d in %s: %s", i, filename, line))
                end
                i++;
            end
        end

        $fclose(fd);
        return mem;
    endfunction

    function void seed_memory(uint32_t defaults [uint32_t]);
        uint32_t addr;
        foreach (defaults[addr]) begin
            dut_memory_model.tb_write(addr, defaults[addr]);
        end
    endfunction

    function void start_of_simulation_phase(uvm_phase phase);
        string asm_test;
        memory_t mem;

        super.start_of_simulation_phase(phase);

        if (!$value$plusargs("ASM_TEST=%s", asm_test)) begin
            `uvm_fatal(get_full_name(), "ASM_TEST not specified for asm_memory_response_seq")
        end

        mem = read_memory_file({get_environment_variable("WORKDIR"), "/", asm_test, ".txt"});
        this.seed_memory(mem);

        `uvm_info(
            get_full_name(),
            $sformatf("Seeded memory for ASM_TEST='%s'", asm_test),
            UVM_LOW
        )
    endfunction
endclass
