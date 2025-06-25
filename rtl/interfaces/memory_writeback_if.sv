interface memory_writeback_if #(parameter XLEN = 32);
    import catawba_types::*;

    logic valid;

    logic [XLEN-1:0] alu_result;
    logic [XLEN-1:0] load_result;

    instruction_t instruction;
    instruction_kind_t instruction_kind;

    logic is_mem_inst;

    modport mem (
        output
            valid,
            alu_result,
            load_result,
            instruction,
            instruction_kind,
            is_mem_inst
    );

    modport wb (
        input
            valid,
            alu_result,
            load_result,
            instruction,
            instruction_kind,
            is_mem_inst
    );
endinterface
