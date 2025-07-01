class base_test extends uvm_test;
    `uvm_component_utils(base_test)

    environment env;
    main_memory insn_memory;
    main_memory data_memory;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        uvm_root::get().set_timeout(100000ns, 1);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = environment::type_id::create(.name("env"), .parent(this));
        insn_memory = main_memory::type_id::create(.name("insn_memory"), .parent(this));
        insn_memory.set_cache_type(ICACHE);
        data_memory = main_memory::type_id::create(.name("data_memory"), .parent(this));
        data_memory.set_cache_type(DCACHE);

        uvm_config_db #(main_memory)::set(
            .cntxt(this),
            .inst_name("env.icache_rsp_agent.*"),
            .field_name("dut_memory_model"),
            .value(insn_memory)
        );

        uvm_config_db #(main_memory)::set(
            .cntxt(this),
            .inst_name("env.dcache_rsp_agent.*"),
            .field_name("dut_memory_model"),
            .value(data_memory)
        );
        uvm_config_db #(main_memory)::set(
            .cntxt(this),
            .inst_name("env.sb.*"),
            .field_name("data_memory"),
            .value(data_memory)
        );
    endfunction

    virtual task reset_phase(uvm_phase phase);
        reset_seq rst_seq;

        phase.raise_objection(this);

        rst_seq = reset_seq::type_id::create(.name("rst_seq"));
        assert(rst_seq.randomize()) else `uvm_fatal(get_full_name(), "Couldn't randomize rst_seq");
        rst_seq.print();
        rst_seq.start(env.rst_agent.rst_seqr);

        phase.drop_objection(this);
    endtask

    virtual task run_phase(uvm_phase phase);
        base_memory_response_seq icache_rsp_seq;
        base_memory_response_seq dcache_rsp_seq;

        // Don't raise an objection, that way it doesn't hold up the end of simulation
        icache_rsp_seq = base_memory_response_seq::type_id::create(.name("icache_rsp_seq"));
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
