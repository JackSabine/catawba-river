interface execute_writeback_if #(parameter XLEN = 32);
    import catawba_params::*;

    logic valid;
    logic [XLEN-1:0] pc;

    logic [XLEN-1:0] ex_result;

    instruction_t instruction;
    instruction_kind_t instruction_kind;

    modport ex (
        output
            valid,
            pc,
            ex_result,
            instruction,
            instruction_kind
    );

    modport wb (
        input
            valid,
            pc,
            ex_result,
            instruction,
            instruction_kind
    );
endinterface
