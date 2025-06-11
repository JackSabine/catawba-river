`include "macros.svh"

module execute import catawba_types::*; #(
    parameter XLEN = 32
) (
    input logic clk,

    decode_execute_if.ex de_if,
    execute_memory_if.ex mem_if
);

    logic [XLEN-1:0] alu_result;
    logic [XLEN-1:0] alu_operand_a, alu_operand_b;
    logic branch_alu_result;

    assign alu_operand_a = de_if.a_use_pc ? de_if.next_pc : de_if.rs1_word;
    assign alu_operand_b = de_if.b_use_imm ? de_if.immediate : de_if.rs2_word;

    alu #(
        .XLEN(XLEN)
    ) alu (
        .operand_a(alu_operand_a),
        .operand_b(alu_operand_b),
        .operation(de_ex_if.alu_operation),
        .result(alu_result)
    );

    branch_alu #(
        .XLEN(XLEN)
    ) branch_alu (
        .operand_a(de_if.rs1_word),
        .operand_b(de_if.rs2_word),
        .operation(de_if.branch_alu_operation),
        .result(branch_alu_result)
    );

    assign take_branch = de_if.is_branch_inst && branch_alu_result;

    always_ff @(posedge clk) begin
        mem_if.rs2_word <= de_if.rs2_word;
        mem_if.alu_result <= alu_result;

        mem_if.instruction <= de_if.instruction;
    end

endmodule