interface writeback_rob_if #(parameter XLEN = 32);
    import catawba_params::*;

    logic [XLEN-1:0] result;
    logic [`REG_BITS-1:0] rd;
    logic exception;
    logic valid;

    logic [ROB_PTR_WIDTH-1:0] rob_index;

    modport wb (
        output
            result,
            rd,
            exception,
            valid,
            rob_index
    );

    modport de (
        input
            result,
            rd,
            exception,
            valid,
            rob_index
    );
endinterface
