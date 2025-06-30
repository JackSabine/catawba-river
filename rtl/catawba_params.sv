`include "catawba_macros.svh"

package catawba_params;
    typedef enum logic[3:0] {
        ADD  = 4'b0_000,
        SUB  = 4'b1_000,
        SLL  = 4'b?_001,
        SLT  = 4'b?_010,
        SLTU = 4'b?_011,
        XOR  = 4'b?_100,
        SRL  = 4'b0_101,
        SRA  = 4'b1_101,
        OR   = 4'b?_110,
        AND  = 4'b?_111,
        ALU_OP_UNDEFINED = 'x
    } alu_operation_e;

    typedef enum logic [2:0] {
        EQ  = 3'b000,
        NE  = 3'b001,
        LT  = 3'b100,
        GE  = 3'b101,
        LTU = 3'b110,
        GEU = 3'b111,
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

    parameter XLEN = 32;
endpackage
