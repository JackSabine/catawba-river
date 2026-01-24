module writeback import catawba_params::*; #(
    parameter XLEN = 32
) (
    input logic clk,

    execute_writeback_if.wb ex_if,
    writeback_decode_if.wb de_if
);
    logic write_enable;

    assign write_enable = ex_if.valid & ex_if.instruction_kind inside {R_INST, I_INST, J_INST, U_INST};

    assign de_if.result = ex_if.ex_result;
    assign de_if.rd = write_enable ? ex_if.instruction.rd : '0;
endmodule
