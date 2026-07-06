interface writeback_rob_if #(parameter XLEN = 32);
    import catawba_params::*;

    logic valid;
    logic [XLEN-1:0] exception;
    logic [ROB_PTR_WIDTH-1:0] rob_index;

    logic [XLEN-1:0] result;

    modport wb (
        output
            valid,
            rob_index,
            exception,
            result
    );

    modport rt (
        input
            valid,
            rob_index,
            exception,
            result
    );
endinterface
