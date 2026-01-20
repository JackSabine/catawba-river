`include "catawba_macros.svh"

interface decode_rename_if #(parameter XLEN = 32);
    import catawba_params::*;

    logic [XLEN-1:0] pc, pc_plus_4;
    instruction_t instruction;
    instruction_kind_t instruction_kind;

    alu_operation_e alu_operation;
    branch_alu_operation_e branch_alu_operation;

    logic [`REG_BITS-1:0] arf_rs1;
    logic [`REG_BITS-1:0] arf_rs2;
    logic [`REG_BITS-1:0] arf_rd;

    logic stall_upstream;

    modport decode (
        output
            pc,
            pc_plus_4,
            instruction,
            instruction_kind,
            alu_operation,
            branch_alu_operation,
            arf_rs1,
            arf_rs2,
            arf_rd,
        input
            stall_upstream
    );

    modport rename (
        input
            pc,
            pc_plus_4,
            instruction,
            instruction_kind,
            alu_operation,
            branch_alu_operation,
            arf_rs1,
            arf_rs2,
            arf_rd,
        output
            stall_upstream
    );
endinterface
