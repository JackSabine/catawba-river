`ifndef CATAWBA_MACROS__SVH
  `define CATAWBA_MACROS__SVH

`define WORD        (32)
`define HALF        (16)
`define BYTE        (8)
`define NUM_REGS    (32)
`define REG_BITS    ($clog2(`NUM_REGS))
`define OPC_BITS    (7)

`define HALT_OPC    (7'h0)

`endif
