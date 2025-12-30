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

    task run_phase(uvm_phase phase);
        asm_memory_response_seq icache_rsp_seq;
        base_memory_response_seq dcache_rsp_seq;

        // Don't raise an objection, that way it doesn't hold up the end of simulation
        icache_rsp_seq = asm_memory_response_seq::type_id::create(.name("icache_rsp_seq"));
        dcache_rsp_seq = base_memory_response_seq::type_id::create(.name("dcache_rsp_seq"));
        fork
            begin
                icache_rsp_seq.start(env.icache_rsp_agent.mrsp_seqr); // Runs forever
            end
            begin
                dcache_rsp_seq.start(env.dcache_rsp_agent.mrsp_seqr); // Runs forever
            end
        join_none
    endtask
endclass
