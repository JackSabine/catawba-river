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

`endif
