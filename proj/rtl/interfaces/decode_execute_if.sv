interface decode_execute_if #(parameter XLEN = 32);
    import catawba_types::*;

    logic valid;

    logic [XLEN-1:0] rs1_word;
    logic [XLEN-1:0] rs2_word;
    logic [XLEN-1:0] next_pc;

    instruction_t instruction;
    instruction_kind_t instruction_kind;
    logic is_mem_inst;

    alu_operation_e alu_operation;
    branch_alu_operation_e branch_alu_operation;
    logic a_use_pc;
    logic b_use_imm;
    logic [XLEN-1:0] immediate;

    modport de (
        output
            valid,
            rs1_word,
            rs2_word,
            next_pc,
            instruction,
            instruction_kind,
            is_mem_inst,
            alu_operation,
            branch_alu_operation,
            a_use_pc,
            b_use_imm,
            immediate
    );

    modport ex (
        input
            valid,
            rs1_word,
            rs2_word,
            next_pc,
            instruction,
            instruction_kind,
            is_mem_inst,
            alu_operation,
            branch_alu_operation,
            a_use_pc,
            b_use_imm,
            immediate
    );

endinterface
