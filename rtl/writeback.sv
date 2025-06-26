module writeback import catawba_params::*; #(
    parameter XLEN = 32
) (
    input logic clk,

    memory_writeback_if.wb mem_if,
    writeback_decode_if.wb de_if
);

    assign de_if.result = mem_if.is_mem_inst ? mem_if.load_result : mem_if.alu_result;
    assign de_if.rd = mem_if.instruction.common.rd;
    assign de_if.write_to_rd =
        mem_if.valid &
        mem_if.instruction_kind inside {R_INST, I_INST, J_INST, U_INST};

endmodule
