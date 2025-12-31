module writeback import catawba_params::*; #(
    parameter XLEN = 32
) (
    input logic clk,

    memory_writeback_if.wb mem_if,
    writeback_decode_if.wb de_if
);
    logic write_enable;

    assign write_enable = mem_if.valid & mem_if.instruction_kind inside {R_INST, I_INST, J_INST, U_INST};

    assign de_if.result = mem_if.is_mem_insn ? mem_if.load_result : mem_if.ex_result;
    assign de_if.rd = write_enable ? mem_if.instruction.rd : '0;

endmodule
