class environment extends uvm_env;
    `uvm_component_utils(environment)

    reset_agent rst_agent;
    scoreboard sb;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        rst_agent  = reset_agent::type_id::create(.name("rst_agent"), .parent(this));
        sb         = scoreboard::type_id::create(.name("sb"), .parent(this));
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction
endclass