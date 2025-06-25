interface writeback_decode_if #(parameter XLEN = 32);
    import catawba_types::*;

    logic [XLEN-1:0] result;
    logic [`REG_BITS-1:0] rd;
    logic write_to_rd;

    modport wb (
        output
            result,
            rd,
            write_to_rd
    );

    modport de (
        input
            result,
            rd,
            write_to_rd
    );
endinterface
