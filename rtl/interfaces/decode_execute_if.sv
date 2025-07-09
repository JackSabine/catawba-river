interface decode_execute_if #(parameter XLEN = 32);
    import catawba_params::*;

    logic valid;
    logic halt;

    logic [XLEN-1:0] rs1_word;
    logic [XLEN-1:0] rs2_word;
    logic [XLEN-1:0] next_pc;

    instruction_t instruction;
    instruction_kind_t instruction_kind;
    logic is_branch_insn;
    logic is_mem_insn;

    alu_operation_e alu_operation;
    branch_alu_operation_e branch_alu_operation;
    logic a_use_pc;
    logic b_use_imm;
    logic [XLEN-1:0] immediate;

    logic stall_upstream;

    modport de (
        output
            valid,
            halt,
            rs1_word,
            rs2_word,
            next_pc,
            instruction,
            instruction_kind,
            is_branch_insn,
            is_mem_insn,
            alu_operation,
            branch_alu_operation,
            a_use_pc,
            b_use_imm,
            immediate,
        input
            stall_upstream
    );

    modport ex (
        input
            valid,
            halt,
            rs1_word,
            rs2_word,
            next_pc,
            instruction,
            instruction_kind,
            is_branch_insn,
            is_mem_insn,
            alu_operation,
            branch_alu_operation,
            a_use_pc,
            b_use_imm,
            immediate,
        output
            stall_upstream
    );

endinterface
