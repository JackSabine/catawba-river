interface fetch_execute_if #(parameter XLEN = 32);
    import catawba_params::*;

    logic jump_or_branch_valid;
    logic [XLEN-1:0] jump_or_branch_next_pc;

    modport fe (
        input
            jump_or_branch_valid,
            jump_or_branch_next_pc
    );

    modport ex (
        output
            jump_or_branch_valid,
            jump_or_branch_next_pc
    );
endinterface
