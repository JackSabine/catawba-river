`include "macros.svh"

interface decode_if;
    import catawba_types::*;

    // Input to decode stage
    logic [`WORD-1:0]       next_pc;
    logic [`WORD-1:0]       instruction;

    // Output from decode stage
endinterface
