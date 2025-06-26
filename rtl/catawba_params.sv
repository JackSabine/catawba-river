`include "catawba_macros.svh"

package catawba_params;
    // Should agree with the funct3 mapping (excluding signed/unsigned)
    typedef enum logic[1:0] {
        BYTE = 2'b00,
        HALF = 2'b01,
        WORD = 2'b10
    } memory_operation_size_e;

    typedef enum logic [1:0] {
        STORE = 2'b00,
        LOAD = 2'b01,
        CLFLUSH = 2'b11,
        MO_UNKNOWN = 2'bxx
    } memory_operation_e;

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

    typedef union packed {
        struct packed {
            logic [6:0] funct7;
            logic [`REG_BITS-1:0] rs2;
            logic [`REG_BITS-1:0] rs1;
            logic [2:0] funct3;
            logic [`REG_BITS-1:0] rd;
            logic [`OPC_BITS-1:0] opcode;
        } common;

        struct packed {
            logic [6:0] funct7;
            logic [`REG_BITS-1:0] rs2;
            logic [`REG_BITS-1:0] rs1;
            logic [2:0] funct3;
            logic [`REG_BITS-1:0] rd;
            logic [`OPC_BITS-1:0] opcode;
        } r_type;

        struct packed {
            logic [11:0] imm;
            logic [`REG_BITS-1:0] rs1;
            logic [2:0] funct3;
            logic [`REG_BITS-1:0] rd;
            logic [`OPC_BITS-1:0] opcode;
        } i_type;

        struct packed {
            logic [6:0] imm_11_5;
            logic [`REG_BITS-1:0] rs2;
            logic [`REG_BITS-1:0] rs1;
            logic [2:0] funct3;
            logic [4:0] imm_4_0;
            logic [`OPC_BITS-1:0] opcode;
        } s_type;

        struct packed {
            logic imm_12;
            logic [5:0] imm_10_5;
            logic [`REG_BITS-1:0] rs2;
            logic [`REG_BITS-1:0] rs1;
            logic [2:0] funct3;
            logic [3:0] imm_4_1;
            logic imm_11;
            logic [`OPC_BITS-1:0] opcode;
        } b_type;

        struct packed {
            logic [19:0] imm_31_12;
            logic [`REG_BITS-1:0] rd;
            logic [`OPC_BITS-1:0] opcode;
        } u_type;

        struct packed {
            logic imm_20;
            logic [9:0] imm_10_1;
            logic imm_11;
            logic [7:0] imm_19_12;
            logic [`REG_BITS-1:0] rd;
            logic [`OPC_BITS-1:0] opcode;
        } j_type;
    } instruction_t;
endpackage
