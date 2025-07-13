// ****************************************************
// *                                                  *
// * https://github.com/andportnoy/riscv-disassembler *
// *                                                  *
// ****************************************************

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <assert.h>
#include <svdpi.h>

enum format {R, I, S, B, U, J, H};

struct {
    uint8_t opcode; /* 7-bit */
    enum format fmt;
} opcodefmt[] = {
    {0x37, U},
    {0x17, U},
    {0x6f, J},
    {0x67, I},
    {0x63, B},
    {0x03, I},
    {0x23, S},
    {0x13, I},
    {0x33, R},
    {0x0f, I},
    {0x73, I},
    {0x00, H} // Custom HALT
};

union encoding {
    uint32_t insn;
    struct { /* generic */
        uint32_t opcode :7;
        uint32_t rd     :5;
        uint32_t funct3 :3;
        uint32_t rs1    :5;
        uint32_t rs2    :5;
        uint32_t funct7 :7;
    };
    struct {
        uint32_t opcode :7;
        uint32_t rd     :5;
        uint32_t funct3 :3;
        uint32_t rs1    :5;
        uint32_t rs2    :5;
        uint32_t funct7 :7;
    } r;
    struct {
        uint32_t opcode :7;
        uint32_t rd     :5;
        uint32_t funct3 :3;
        uint32_t rs1    :5;
        int32_t i11_0  :12; /* sign extension */
    } i;
    struct {
        uint32_t opcode :7;
        uint32_t i4_0   :5;
        uint32_t funct3 :3;
        uint32_t rs1    :5;
        uint32_t rs2    :5;
        int32_t i11_5  :7; /* sign extension */
    } s;
    struct {
        uint32_t opcode :7;
        uint32_t i11    :1;
        uint32_t i4_1   :4;
        uint32_t funct3 :3;
        uint32_t rs1    :5;
        uint32_t rs2    :5;
        uint32_t i10_5  :6;
        int32_t i12    :1; /* sign extension */
    } b;
    struct {
        uint32_t opcode :7;
        uint32_t rd     :5;
        uint32_t i31_12 :20;
    } u;
    struct {
        uint32_t opcode :7;
        uint32_t rd     :5;
        uint32_t i19_12 :8;
        uint32_t i11    :1;
        uint32_t i10_1  :10;
        int32_t i20    :1; /* sign extension */
    } j;
};

int format(uint8_t opcode) {
    for (int i=0, n=sizeof opcodefmt/sizeof opcodefmt[0]; i<n; ++i)
        if (opcode == opcodefmt[i].opcode)
            return opcodefmt[i].fmt;
    return -1;
}

char *name(uint32_t insn) {
    union encoding e = {insn};
    switch (format(e.opcode)) {
    case R: switch (e.funct3) {
        case 0: return e.funct7? "sub": "add";
        case 1: return "sll";
        case 2: return "slt";
        case 3: return "sltu";
        case 4: return "xor";
        case 5: return e.funct7? "sra": "srl";
        case 6: return "or";
        case 7: return "and";
        } break;
    case I: switch(e.opcode) {
        case 0x67: return "jalr";
        case 0x03: switch (e.funct3) {
               case 0: return "lb";
               case 1: return "lh";
               case 2: return "lw";
               case 4: return "lbu";
               case 5: return "lhu";
               } break;
        case 0x13: switch (e.funct3) {
               case 0: return "addi";
               case 1: return "slli";
               case 2: return "slti";
               case 3: return "sltiu";
               case 4: return "xori";
               case 5: return e.funct7? "srai": "srli";
               case 6: return "ori";
               case 7: return "andi";
               } break;
        case 0x0f: switch (e.funct3) {
               case 0: return "fence";
               case 1: return "fence.i";
               } break;
        case 0x73: switch (e.funct3) {
               case 0: return e.rs2? "ebreak": "ecall";
               case 1: return "csrrw";
               case 2: return "csrrs";
               case 3: return "csrrc";
               case 5: return "csrrwi";
               case 6: return "csrrsi";
               case 7: return "csrrci";
               } break;
        } break;
    case S: switch(e.funct3) {
        case 0: return "sb";
        case 1: return "sh";
        case 2: return "sw";
        } break;
    case B: switch(e.funct3) {
        case 0: return "beq";
        case 1: return "bne";
        case 4: return "blt";
        case 5: return "bge";
        case 6: return "bltu";
        case 7: return "bgeu";
        } break;
    case U: switch(e.opcode) {
        case 0x37: return "lui";
        case 0x17: return "auipc";
        } break;
    case J: return "jal";
    case H: return "HALT";
    }

    return NULL;
}

#define OP0_MAX_LEN (3)
#define OP0_BUF_LEN ((OP0_MAX_LEN) + 1)

char *op0(uint32_t insn) {
    union encoding e = {insn};
    char *name = calloc(OP0_BUF_LEN, sizeof *name);
    switch (format(e.opcode)) {
        case R: snprintf(name, OP0_BUF_LEN, "x%d", e.rd);  break;
        case I: snprintf(name, OP0_BUF_LEN, "x%d", e.rd);  break;
        case S: snprintf(name, OP0_BUF_LEN, "x%d", e.rs2); break;
        case B: snprintf(name, OP0_BUF_LEN, "x%d", e.rs1); break;
        case U: snprintf(name, OP0_BUF_LEN, "x%d", e.rd);  break;
        case J: snprintf(name, OP0_BUF_LEN, "x%d", e.rd);  break;
    }
    return name;
}

#define OP1_MAX_LEN (6)
#define OP1_BUF_LEN ((OP1_MAX_LEN) + 1)

char *op1(uint32_t insn) {
    union encoding e = {insn};
    char *name = calloc(OP1_BUF_LEN, sizeof *name);
    switch (format(e.opcode)) {
        case R: snprintf(name, OP1_BUF_LEN, "x%d", e.rs1);              break;
        case I: snprintf(name, OP1_BUF_LEN, "x%d", e.rs1);              break;
        case S: snprintf(name, OP1_BUF_LEN, "x%d", e.rs1);              break;
        case B: snprintf(name, OP1_BUF_LEN, "x%d", e.rs2);              break;
        case U: snprintf(name, OP1_BUF_LEN, "%X", e.u.i31_12);          break;
        case J: snprintf(name, OP1_BUF_LEN, "%X", (e.j.i20    <<20) |
                                                  (e.j.i19_12 <<12) |
                                                  (e.j.i11    <<11) |
                                                  (e.j.i10_1  << 1));   break;
    }
    return name;
}

#define OP2_MAX_LEN (4)
#define OP2_BUF_LEN ((OP2_MAX_LEN) + 1)

char *op2(uint32_t insn) {
    union encoding e = {insn};
    char *name = calloc(OP2_BUF_LEN, sizeof *name);
    switch (format(e.opcode)) {
        case R: snprintf(name, OP2_BUF_LEN, "x%d", e.rs2);                    break;
        case I: snprintf(name, OP2_BUF_LEN, "%X", e.i.i11_0);                 break;
        case S: snprintf(name, OP2_BUF_LEN, "%X", (e.s.i11_5<<5) | e.s.i4_0); break;
        case B: snprintf(name, OP2_BUF_LEN, "%X", (e.b.i12   <<12) |
                                                  (e.b.i11   <<11) |
                                                  (e.b.i10_5 << 5) |
                                                  (e.b.i4_1  << 1));          break;
        case U:                                                               break;
        case J:                                                               break;
    }
    return name;
}

#define LONGEST_INSN_LEN (6)
#define MAX_STRING_LEN ((LONGEST_INSN_LEN) + (OP0_MAX_LEN) + (OP1_MAX_LEN) + (OP2_MAX_LEN))
#define BUFFER_SIZE ((MAX_STRING_LEN) + 1)

const char *disassemble_rv32i(uint8_t valid, uint32_t insn) {
    uint8_t characters_written;
    char *s = (char *) calloc((BUFFER_SIZE), sizeof(char));
    if (valid) {
        characters_written = snprintf(s, (BUFFER_SIZE), "%s %s %s %s", name(insn), op0(insn), op1(insn), op2(insn));
    }
    else {
        characters_written = snprintf(s, (BUFFER_SIZE), ":)");
    }

    if (characters_written == -1 || characters_written >= BUFFER_SIZE) {
        // Error copying the whole string
        strncpy(s, "Insn %8X", (BUFFER_SIZE));
    }
    return (const char *) s;
}
