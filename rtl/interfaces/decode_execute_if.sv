interface decode_execute_if #(parameter XLEN = 32);
    import catawba_params::*;

    logic valid;
    logic halt;

    logic [XLEN-1:0] rs1_word;
    logic [XLEN-1:0] rs2_word;
    logic [XLEN-1:0] pc, pc_plus_4;

    instruction_t instruction;
    instruction_kind_t instruction_kind;
    logic is_branch_insn;
    logic is_jump_insn;
    logic is_mem_insn;

    alu_operation_e alu_operation;
    branch_alu_operation_e branch_alu_operation;
    logic [XLEN-1:0] operand_a;
    logic [XLEN-1:0] operand_b;

    logic stall_upstream;

    modport de (
        output
            valid,
            halt,
            rs1_word,
            rs2_word,
            pc,
            pc_plus_4,
            instruction,
            instruction_kind,
            is_branch_insn,
            is_jump_insn,
            is_mem_insn,
            alu_operation,
            branch_alu_operation,
            operand_a,
            operand_b,
        input
            stall_upstream
    );

    modport ex (
        input
            valid,
            halt,
            rs1_word,
            rs2_word,
            pc,
            pc_plus_4,
            instruction,
            instruction_kind,
            is_branch_insn,
            is_jump_insn,
            is_mem_insn,
            alu_operation,
            branch_alu_operation,
            operand_a,
            operand_b,
        output
            stall_upstream
    );

endinterface
