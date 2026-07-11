interface execute_writeback_if #(parameter XLEN = 32);
    import catawba_params::*;

    logic valid;
    logic exception_posted;
    exception_code_e exception_code;
    logic [ROB_PTR_WIDTH-1:0] rob_index;

    logic [XLEN-1:0] pc;

    logic [XLEN-1:0] ex_result;

    instruction_t instruction;
    instruction_kind_t instruction_kind;

    modport ex (
        output
            valid,
            exception_posted,
            exception_code,
            rob_index,
            pc,
            ex_result,
            instruction,
            instruction_kind
    );

    modport wb (
        input
            valid,
            exception_posted,
            exception_code,
            rob_index,
            pc,
            ex_result,
            instruction,
            instruction_kind
    );
endinterface
