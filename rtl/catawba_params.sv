`include "catawba_macros.svh"

package catawba_params;
    typedef enum logic[3:0] {
        ADD = 4'b0000,
        SUB,
        XOR,
        OR,
        AND,
        SHIFT_LEFT,
        SHIFT_RIGHT,
        SHIFT_RIGHT_ARITHMETIC,
        SET_LESS_THAN,
        SET_LESS_THAN_UNSIGNED,
        ALU_OP_UNDEFINED = 'x
    } alu_operation_e;

    typedef enum logic [2:0] {
        EQ = 3'b000,
        NEQ,
        LT,
        GTE,
        LT_U,
        GTE_U,
        BRANCH_OP_UNDEFINED = 'x
    } branch_alu_operation_e;

    typedef enum logic [2:0] {
        R_INST = 3'b000,
        I_INST,
        S_INST,
        B_INST,
        U_INST,
        J_INST,
        INST_UNDEFINED = 'x
    } instruction_kind_t;

    typedef struct packed {
        logic [6:0] funct7;
        logic [`REG_BITS-1:0] rs2;
        logic [`REG_BITS-1:0] rs1;
        logic [2:0] funct3;
        logic [`REG_BITS-1:0] rd;
        logic [`OPC_BITS-1:0] opcode;
    } instruction_t;
endpackage
