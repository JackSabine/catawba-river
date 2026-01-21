class commit_agent extends uvm_agent;
    `uvm_component_utils(commit_agent)

    uvm_analysis_port #(pipe_state_transaction) state_ap;

    commit_monitor cmt_mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        state_ap = new(.name("state_ap"), .parent(this));
        cmt_mon = commit_monitor::type_id::create(.name("cmt_mon"), .parent(this));
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        cmt_mon.state_ap.connect(state_ap);
    endfunction
endclass
