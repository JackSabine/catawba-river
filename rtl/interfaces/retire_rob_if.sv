interface retire_rob_if #(parameter XLEN = 32);
    import catawba_params::*;

    logic pop;

    logic empty;

    logic head_ready;
    logic [XLEN-1:0] head_pc;
    logic [XLEN-1:0] head_instruction;
    logic [`REG_BITS-1:0] head_dest_reg;
    logic [XLEN-1:0] head_result;
    logic head_exception_posted;
    exception_code_e head_exception_code;

    modport rob (
        output
            empty,
            head_ready,
            head_pc,
            head_instruction,
            head_dest_reg,
            head_result,
            head_exception_posted,
            head_exception_code,
        input
            pop
    );

    modport rt (
        input
            empty,
            head_ready,
            head_pc,
            head_instruction,
            head_dest_reg,
            head_result,
            head_exception_posted,
            head_exception_code,
        output
            pop
    );
endinterface
