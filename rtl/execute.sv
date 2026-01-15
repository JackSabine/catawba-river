`include "catawba_macros.svh"

module execute import catawba_params::*; #(
    parameter XLEN = 32
) (
    input logic clk,
    reset_if rst_if,

    input logic [1:0] hart_curr_privilege,

    fetch_execute_if.ex fe_if,
    decode_execute_if.ex de_if,
    execute_memory_if.ex mem_if
);

    logic [XLEN-1:0] alu_result;
    logic branch_alu_result;

    logic propagate_upstream_data;

    logic [XLEN-1:0] csr_read_value;

    logic local_stall_request;

    alu #(
        .XLEN(XLEN)
    ) alu (
        .operand_a(de_if.operand_a),
        .operand_b(de_if.operand_b),
        .operation(de_if.alu_operation),
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

    assign fe_if.jump_or_branch_valid = de_if.valid & (de_if.is_branch_insn | de_if.is_jump_insn);
    assign fe_if.jump_or_branch_next_pc = (branch_alu_result | de_if.is_jump_insn) ? alu_result : de_if.pc_plus_4;

    csr_wrapper #(
        .XLEN(XLEN)
    ) csr_wrapper (
        .clk(clk),
        .rst(rst_if.reset),
        .req_csr_address(de_if.operand_b[11:0]),
        .req_source_value(de_if.operand_a),
        .req_system_op(system_op_e'(de_if.instruction.funct3)),
        .req_rd_is_x0(de_if.rd_is_x0),
        .req_rs_is_x0(de_if.rs_is_x0),
        .req_valid(de_if.valid & de_if.is_csr_insn),
        .retire_csr_instruction(1'b0),
        .stall_incoming_csr_req(local_stall_request),

        .hart_curr_privilege(hart_curr_privilege),
        .rsp_csr_value(csr_read_value)
    );

    advance_control advance_ctrl (
        .clk(clk),
        .rst_if(rst_if),
        .upstream_valid(de_if.valid),
        .local_stall_request(local_stall_request),
        .downstream_stall_request(mem_if.stall_upstream),
        .upstream_halt(de_if.halt),

        .propagate_upstream_data(propagate_upstream_data),
        .downstream_valid(mem_if.valid),
        .downstream_halt(mem_if.halt),
        .request_upstream_stall(de_if.stall_upstream)
    );

    logic [XLEN-1:0] ex_result;
    always_comb begin
        unique if (de_if.is_jump_insn) begin
            ex_result = de_if.pc_plus_4;
        end else if (de_if.is_csr_insn) begin
            ex_result = csr_read_value;
        end else begin
            ex_result = alu_result;
        end
    end

    always_ff @(posedge clk) begin
        if (propagate_upstream_data) begin
            mem_if.rs2_word <= de_if.rs2_word;
            mem_if.ex_result <= ex_result;

            mem_if.instruction <= de_if.instruction;
            mem_if.instruction_kind <= de_if.instruction_kind;
            mem_if.is_mem_insn <= de_if.is_mem_insn;
        end
    end
endmodule
