interface rename_rob_if #(parameter XLEN = 32);
    import catawba_params::*;

    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] instruction;
    logic [`REG_BITS-1:0] dispatch_dest_reg;

    logic push;
    logic full;

    modport re (
        output
            pc,
            instruction,
            dispatch_dest_reg,
            push,
        input
            full
    );

    modport rob (
        input
            pc,
            instruction,
            dispatch_dest_reg,
            push,
        output
            full
    );
endinterface
