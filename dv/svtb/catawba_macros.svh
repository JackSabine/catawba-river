`ifndef CATAWBA_MACROS__SVH
  `define CATAWBA_MACROS__SVH

`define WORD        (32)
`define HALF        (16)
`define BYTE        (8)
`define NUM_REGS    (32)
`define REG_BITS    ($clog2(`NUM_REGS))
`define OPC_BITS    (7)

`define NOP         (32'h00000013) // addi x0, x0, 0
`define J1b         (32'h0000006f) // jal x0, 0

`define TB_STRING_MAX_CHARS (31)
`define TB_STRING_NUM_BITS ( (`TB_STRING_MAX_CHARS + 1) * 8)

`define IS_HALT_INSN(insn)          (insn == `J1b)
`define IS_MATH_INSN(insn)          (insn.opcode =?= 7'b0?10011)
`define IS_BRANCH_INSN(insn)        (insn.opcode  == 7'b1100011)
`define IS_JUMP_INSN(insn)          (insn.opcode =?= 7'b110z111)
`define IS_MEM_INSN(insn)           (insn.opcode =?= 7'b0z00011)
`define IS_LUI_INSN(insn)           (insn.opcode  == 7'b0110111)
`define IS_CSR_INSN(insn)           ((insn.opcode == 7'b1110011) & (insn.funct3 != 3'b000))
`define IS_CSR_INSN_WITH_UIMM(insn) (`IS_CSR_INSN(insn) & (insn.funct3[2] == 1'b1))
`define IS_RD_X0(insn)              (insn.rd  == '0)
`define IS_RS_X0(insn)              (insn.rs1 == '0)


`define RO_CSR(CSR_NAME, ADDRESS, CONST_VALUE) \
    logic [XLEN-1:0] csr_``CSR_NAME; \
    assign csr_``CSR_NAME = CONST_VALUE; \
    assign csr_array[ADDRESS] = csr_``CSR_NAME;

`define RW_CSR(CSR_NAME, ADDRESS, CLK, RST, RST_VAL, REQ_ADDRESS, REQ_WRITE_VAL) \
    logic [XLEN-1:0] csr_``CSR_NAME; \
    always_ff @(posedge CLK) begin \
        if (RST) begin \
            csr_``CSR_NAME <= RST_VAL; \
        end else begin \
            if (REQ_ADDRESS == ADDRESS) begin \
                csr_``CSR_NAME <= REQ_WRITE_VAL; \
            end \
        end \
    end \
    assign csr_array[ADDRESS] = csr_``CSR_NAME;

`endif
