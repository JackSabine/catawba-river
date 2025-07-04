class asm_test extends base_test;
    `uvm_component_utils(asm_test)

    asm_memory_response_seq icache_rsp_seq;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        icache_rsp_seq = asm_memory_response_seq::type_id::create(.name("icache_rsp_seq"));
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        icache_rsp_seq.expected_pipe_state_ap.connect(env.sb.aport_expected_state);
    endfunction

    task run_phase(uvm_phase phase);
        base_memory_response_seq dcache_rsp_seq;

        // Don't raise an objection, that way it doesn't hold up the end of simulation
        dcache_rsp_seq = base_memory_response_seq::type_id::create(.name("dcache_rsp_seq"));
        icache_rsp_seq.start(env.icache_rsp_agent.mrsp_seqr); // Runs forever
        dcache_rsp_seq.start(env.dcache_rsp_agent.mrsp_seqr); // Runs forever
    endtask

    virtual task main_phase(uvm_phase phase);
        phase.raise_objection(this);

        #100ns;

        phase.drop_objection(this);
    endtask
endclass
