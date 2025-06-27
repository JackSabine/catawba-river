interface fetch_decode_if #(parameter XLEN = 32);
    import catawba_params::*;

    logic valid;
    logic halt;

    logic [XLEN-1:0] next_pc;
    instruction_t instruction;

    logic stall_upstream;

    modport fe (
        output
            valid,
            halt,
            next_pc,
            instruction,
        input
            stall_upstream
    );

    modport de (
        input
            valid,
            halt,
            next_pc,
            instruction,
        output
            stall_upstream
    );
endinterface
