`include "catawba_macros.svh"

module execute import catawba_params::*; #(
    parameter XLEN = 32
) (
    input logic clk,

    fetch_execute_if.ex fe_if,
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

    assign fe_if.take_branch = (de_if.instruction_kind == B_INST) & branch_alu_result;
    assign fe_if.branch_target_pc = de_if.next_pc + de_if.immediate;
    assign fe_if.branch_inst_next_pc = de_if.next_pc;

    always_ff @(posedge clk) begin
        if (~mem_if.stall_upstream) begin
            mem_if.rs2_word <= de_if.rs2_word;
            mem_if.alu_result <= alu_result;

            mem_if.instruction <= de_if.instruction;
            mem_if.instruction_kind <= de_if.instruction_kind;
            mem_if.is_mem_inst <= de_if.is_mem_inst;
        end
    end

    assign de_if.stall_upstream = de_if.valid & (mem_if.stall_upstream);
endmodule
