interface fetch_execute_if #(parameter XLEN = 32);
    import catawba_params::*;

    logic take_trap;
    logic [XLEN-1:0] trap_target_pc;
    logic jump_or_branch_valid;
    logic [XLEN-1:0] jump_or_branch_next_pc;

    modport fe (
        input
            take_trap,
            trap_target_pc,
            jump_or_branch_valid,
            jump_or_branch_next_pc
    );

    modport ex (
        output
            take_trap,
            trap_target_pc,
            jump_or_branch_valid,
            jump_or_branch_next_pc
    );
endinterface
