
interface execute_memory_if #(parameter XLEN = 32);
    import catawba_params::*;

    logic valid;
    logic halt;

    logic [XLEN-1:0] ex_result;
    logic [XLEN-1:0] rs2_word;

    instruction_t instruction;
    instruction_kind_t instruction_kind;
    logic is_mem_insn;

    logic stall_upstream;

    modport ex(
        output
            valid,
            halt,
            ex_result,
            rs2_word,
            instruction,
            instruction_kind,
            is_mem_insn,
        input
            stall_upstream
    );

    modport mem(
        input
            valid,
            halt,
            ex_result,
            rs2_word,
            instruction,
            instruction_kind,
            is_mem_insn,
        output
            stall_upstream
    );
endinterface
