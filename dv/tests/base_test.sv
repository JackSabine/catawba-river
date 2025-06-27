class base_test extends uvm_test;
    `uvm_component_utils(base_test)

    environment env;

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
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
    endfunction

    task reset_phase(uvm_phase phase);
        reset_seq rst_seq;

        phase.raise_objection(this);

        rst_seq = reset_seq::type_id::create(.name("rst_seq"));
        assert(rst_seq.randomize()) else `uvm_fatal(get_full_name(), "Couldn't randomize rst_seq");
        rst_seq.print();
        rst_seq.start(env.rst_agent.rst_seqr);

        phase.drop_objection(this);
    endtask

    task run_phase(uvm_phase phase);
        memory_response_seq mem_rsp_seq;

        // Don't raise an objection, that way it doesn't hold up the end of simulation
        mem_rsp_seq = memory_response_seq::type_id::create(.name("mem_rsp_seq"));
        mem_rsp_seq.start(env.mem_rsp_agent.mrsp_seqr); // Runs forever
    endtask

    virtual task main_phase(uvm_phase phase);
        phase.raise_objection(this);

        #10000ns;

        phase.drop_objection(this);
    endtask
endclass
