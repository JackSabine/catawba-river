interface decode_execute_if #(parameter XLEN = 32);
    import catawba_params::*;

    logic valid;

    logic [XLEN-1:0] rs1_word;
    logic [XLEN-1:0] rs2_word;
    logic [XLEN-1:0] pc, pc_plus_4;

    instruction_t instruction;
    instruction_kind_t instruction_kind;

    alu_operation_e alu_operation;
    branch_alu_operation_e branch_alu_operation;
    logic [XLEN-1:0] operand_a;
    logic [XLEN-1:0] operand_b;

    logic stall_upstream;

    modport de (
        output
            valid,
            rs1_word,
            rs2_word,
            pc,
            pc_plus_4,
            instruction,
            instruction_kind,
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
            rs1_word,
            rs2_word,
            pc,
            pc_plus_4,
            instruction,
            instruction_kind,
            alu_operation,
            branch_alu_operation,
            operand_a,
            operand_b,
        output
            stall_upstream
    );

endinterface
