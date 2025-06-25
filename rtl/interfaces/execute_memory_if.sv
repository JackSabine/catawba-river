
interface execute_memory_if #(parameter XLEN = 32);
    import catawba_types::*;

    logic valid;

    logic [XLEN-1:0] alu_result;
    logic [XLEN-1:0] rs2_word;

    instruction_t instruction;
    instruction_kind_t instruction_kind;
    logic is_mem_inst;

    logic stall_upstream;

    modport ex(
        output
            valid,
            alu_result,
            rs2_word,
            instruction,
            instruction_kind,
            is_mem_inst,
        input
            stall_upstream
    );

    modport mem(
        input
            valid,
            alu_result,
            rs2_word,
            instruction,
            instruction_kind,
            is_mem_inst,
        output
            stall_upstream
    );
endinterface
