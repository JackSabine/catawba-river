`include "macros.svh"

interface execute_if;
    import catawba_types::*;

    // Input to execute stage
    logic [`WORD-1:0]       next_pc;
    logic [`WORD-1:0]       rf_rs1;
    logic [`WORD-1:0]       rf_rs2;
    logic [`WORD-1:0]       immediate;
    logic [`REG_BITS-1:0]   rd;


    // Output from execute stage

    // Passthrough control signals to later stages
    logic                   memory_write_enable_pass_input;
    logic                   memory_write_enable_pass_output;

endinterface
