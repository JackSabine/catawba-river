`include "macros.svh"

module execute import catawba_types::*; #(
    parameter XLEN = 32
) (
    input logic [XLEN-1:0] read_port_data_1,
    input logic [XLEN-1:0] read_port_data_2,
    input logic [XLEN-1:0] immediate,
    input logic [XLEN-1:0] next_pc,

    input logic alu_use_pc,
    input logic alu_use_imm,
    input alu_operation_e alu_operation,
    input branch_alu_operation_e branch_alu_operation,

    input logic is_branch_inst,

    output logic take_branch,
    output logic [XLEN-1:0] alu_output,
    output logic [XLEN-1:0] read_port_data_for_memory
);

logic [XLEN-1:0] alu_operand_a, alu_operand_b;
logic branch_alu_result;

assign alu_operand_a = alu_use_pc ? next_pc : read_port_data_1;
assign alu_operand_b = alu_use_imm ? immediate : read_port_data_2;

alu #(
    .XLEN(XLEN)
) alu (
    .operand_a(alu_operand_a),
    .operand_b(alu_operand_b),
    .operation(alu_operation),
    .result(alu_output)
);

branch_alu branch_alu (
    .operand_a(read_port_data_1),
    .operand_b(read_port_data_2),
    .branch_type(branch_alu_operation),
    .result(branch_alu_result)
);

assign take_branch = is_branch_inst && branch_alu_result;

assign read_port_data_for_memory = read_port_data_2;

endmodule