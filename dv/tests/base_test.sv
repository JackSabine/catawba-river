class base_test extends uvm_test;
    `uvm_component_utils(base_test)

    environment env;
    main_memory dut_memory_model;

    virtual catawba_probe_if probe_if;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        uvm_root::get().set_timeout(50us, 1);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = environment::type_id::create(.name("env"), .parent(this));
        dut_memory_model = main_memory::type_id::create(.name("dut_memory_model"), .parent(this));

        uvm_config_db #(main_memory)::set(
            .cntxt(uvm_root::get()),
            .inst_name("*"),
            .field_name("dut_memory_model"),
            .value(dut_memory_model)
        );

        assert(uvm_config_db #(virtual catawba_probe_if)::get(
            .cntxt(this),
            .inst_name("*"),
            .field_name("probe_if"),
            .value(probe_if)
        )) else `uvm_fatal(get_full_name(), "Couldn't retrieve probe_if from uvm_config_db")
    endfunction

    virtual task reset_phase(uvm_phase phase);
        reset_seq rst_seq;

        phase.raise_objection(this);

        rst_seq = reset_seq::type_id::create(.name("rst_seq"));
        assert(rst_seq.randomize()) else `uvm_fatal(get_full_name(), "Couldn't randomize rst_seq");
        `uvm_info(get_full_name(), rst_seq.convert2string(), UVM_LOW)
        rst_seq.start(env.rst_agent.rst_seqr);

        phase.drop_objection(this);
    endtask

    virtual task main_phase(uvm_phase phase);
        phase.raise_objection(this);

        wait (probe_if.fe_halted);

        phase.drop_objection(this);
    endtask

    virtual task shutdown_phase(uvm_phase phase);
        phase.raise_objection(this);

        wait (probe_if.wb_halted);
        repeat (4) @(posedge probe_if.clk);

        phase.drop_objection(this);
    endtask
endclass
