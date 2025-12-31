`include "catawba_macros.svh"

package catawba_params;
    typedef enum logic[3:0] {
        ADD  = 4'b0_000,
        SUB  = 4'b1_000,
        SLL  = 4'b0_001,
        SLT  = 4'b0_010,
        SLTU = 4'b0_011,
        XOR  = 4'b0_100,
        SRL  = 4'b0_101,
        SRA  = 4'b1_101,
        OR   = 4'b0_110,
        AND  = 4'b0_111,
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

    typedef enum logic [1:0] {
        STALL_ON_JUMP_OR_BRANCH = 2'b00,
        NORMAL_OPERATION,
        HALTED
    } fetch_state_e;

    parameter XLEN = 32;

    parameter RESET_PC = 32'h8000_0000; // Must agree with bootloader section dv/gcc/link.ld

    parameter ZICSR_ENABLED = 0;
endpackage
