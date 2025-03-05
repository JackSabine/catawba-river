`include "macros.svh"

interface fetch_decode_if;
    import catawba_types::*;

    logic valid;

    logic [`WORD-1:0]       next_pc;
    instruction_t instruction;

    modport fe (
        output
            valid,
            next_pc,
            instruction
    );

    modport de (
        input
            valid,
            next_pc,
            instruction
    );
endinterface
