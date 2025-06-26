interface fetch_execute_if #(parameter XLEN = 32);
    import catawba_params::*;

    logic take_branch;
    logic [XLEN-1:0] branch_target_pc;
    logic [XLEN-1:0] branch_inst_next_pc;

    modport fe (
        input
            take_branch,
            branch_target_pc,
            branch_inst_next_pc
    );

    modport ex (
        output
            take_branch,
            branch_target_pc,
            branch_inst_next_pc
    );
endinterface
