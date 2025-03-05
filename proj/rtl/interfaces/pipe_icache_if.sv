`include "macros.svh"

interface pipe_icache_if;
    import catawba_types::*;

    logic req_valid;
    logic [`WORD-1:0] pc;

    instruction_t instruction;
    logic rsp_valid;

    modport pipe (
        output
            req_valid,
            pc,
        input
            instruction,
            rsp_valid
    );

    modport icache (
        input
            req_valid,
            pc,
        output
            instruction,
            rsp_valid
    );
endinterface
