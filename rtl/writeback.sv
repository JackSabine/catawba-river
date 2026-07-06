module writeback import catawba_params::*; #(
    parameter XLEN = 32
) (
    input logic clk,

    execute_writeback_if.wb ex_if,
    writeback_rob_if.wb rob_if
);
    // logic write_enable;

    // assign write_enable = ex_if.valid & ex_if.instruction_kind inside {R_INST, I_INST, J_INST, U_INST};

    assign rob_if.valid = ex_if.valid;
    assign rob_if.result = ex_if.ex_result;
    assign rob_if.exception = ex_if.exception;
    assign rob_if.rob_index = ex_if.rob_index;
    // assign rob_if.rd = write_enable ? ex_if.instruction.rd : '0;
endmodule
