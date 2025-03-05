interface memory_writeback_if #(parameter XLEN = 32);
    import catawba_types::*;

    logic [XLEN-1:0] alu_result;
    logic [XLEN-1:0] memory_read;

    logic [XLEN-1:0] instruction;

    modport mem (
        output
            alu_result,
            memory_read,
            instruction
    );

    modport wb (
        input
            alu_result,
            memory_read,
            instruction
    );
endinterface
