interface execute_writeback_if #(parameter XLEN = 32);
    import catawba_params::*;

    logic valid;
    logic halt;

    logic [XLEN-1:0] ex_result;

    instruction_t instruction;
    instruction_kind_t instruction_kind;

    modport ex (
        output
            valid,
            halt,
            ex_result,
            instruction,
            instruction_kind
    );

    modport wb (
        input
            valid,
            halt,
            ex_result,
            instruction,
            instruction_kind
    );
endinterface
