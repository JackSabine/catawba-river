interface fetch_decode_if #(parameter XLEN = 32);
    import catawba_params::*;

    logic valid;

    logic [XLEN-1:0] pc, pc_plus_4;
    instruction_t instruction;

    logic stall_upstream;

    modport fe (
        output
            valid,
            pc,
            pc_plus_4,
            instruction,
        input
            stall_upstream
    );

    modport de (
        input
            valid,
            pc,
            pc_plus_4,
            instruction,
        output
            stall_upstream
    );
endinterface
