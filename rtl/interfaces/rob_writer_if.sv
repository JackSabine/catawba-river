interface rob_writer_if #(parameter XLEN = 32);
    import catawba_params::*;

    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] instruction;
    logic [`REG_BITS-1:0] dest_reg;
    logic [ROB_PTR_WIDTH-1:0] rob_index;

    logic push;
    logic full;

    modport writer (
        output
            pc,
            instruction,
            dest_reg,
            push,
        input
            full,
            rob_index
    );

    modport rob (
        input
            pc,
            instruction,
            dest_reg,
            push,
        output
            full,
            rob_index
    );
endinterface
