interface writeback_decode_if #(parameter XLEN = 32);
    import catawba_params::*;

    logic [XLEN-1:0] result;
    logic [`REG_BITS-1:0] rd;

    modport wb (
        output
            result,
            rd
    );

    modport de (
        input
            result,
            rd
    );
endinterface
