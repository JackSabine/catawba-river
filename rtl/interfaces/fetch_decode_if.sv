interface fetch_decode_if #(parameter XLEN = 32);
    import catawba_params::*;

    logic valid;
    logic exception_posted;
    exception_code_e exception_code;

    logic [XLEN-1:0] pc, pc_plus_4;
    instruction_t instruction;


    logic stall_upstream;

    modport fe (
        output
            valid,
            exception_posted,
            exception_code,
            pc,
            pc_plus_4,
            instruction,
        input
            stall_upstream
    );

    modport de (
        input
            valid,
            exception_posted,
            exception_code,
            pc,
            pc_plus_4,
            instruction,
        output
            stall_upstream
    );
endinterface
