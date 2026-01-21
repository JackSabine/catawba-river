`include "catawba_macros.svh"

module execute import catawba_params::*; #(
    parameter XLEN = 32
) (
    input logic clk,
    reset_if rst_if,

    input logic [1:0] hart_curr_privilege,

    input logic wb_has_valid_instruction,

    fetch_execute_if.ex fe_if,
    decode_execute_if.ex de_if,
    execute_writeback_if.ex wb_if,
    memory_if.requester dcache_if
);
    logic propagate_upstream_data;

    logic branch_alu_result;


    logic [XLEN-1:0] alu_result;

    logic [XLEN-1:0] csr_read_value;

    logic [XLEN-1:0] memory_loaded_word;
    logic memory_req_fulfilled;

    logic [XLEN-1:0] ex_result;


    logic local_stall_request;
    logic memory_busy;
    logic stall_to_make_csr_op_atomic;

    assign stall_to_make_csr_op_atomic = de_if.is_csr_insn & wb_has_valid_instruction;

    assign local_stall_request = stall_to_make_csr_op_atomic | memory_busy;

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
        .req_valid(de_if.valid & de_if.is_csr_insn & ~stall_to_make_csr_op_atomic),

        .hart_curr_privilege(hart_curr_privilege),
        .rsp_csr_value(csr_read_value)
    );

    memory memory (
        .clk(clk),
        .rst_if(rst_if),

        .req_valid(de_if.valid & de_if.is_mem_insn),
        .req_base_address(de_if.operand_a),
        .req_offset(de_if.operand_b),
        .req_store_word(de_if.rs2_word),
        .instruction(de_if.instruction),
        .instruction_kind(de_if.instruction_kind),

        .req_loaded_word(memory_loaded_word),
        .req_fulfilled(memory_req_fulfilled),
        .busy(memory_busy),

        .dcache_if(dcache_if)
    );

    advance_control advance_ctrl (
        .clk(clk),
        .rst_if(rst_if),
        .upstream_valid(de_if.valid),
        .local_stall_request(local_stall_request),
        .downstream_stall_request(1'b0),
        .upstream_halt(de_if.halt),
        .force_downstream_valid_and_halt_low(1'b0),

        .propagate_upstream_data(propagate_upstream_data),
        .downstream_valid(wb_if.valid),
        .downstream_halt(wb_if.halt),
        .request_upstream_stall(de_if.stall_upstream)
    );

    always_comb begin
        unique if (de_if.is_jump_insn) begin
            ex_result = de_if.pc_plus_4;
        end else if (de_if.is_csr_insn) begin
            ex_result = csr_read_value;
        end else if (de_if.is_mem_insn & memory_req_fulfilled) begin
            ex_result = memory_loaded_word;
        end else begin
            ex_result = alu_result;
        end
    end

    assign fe_if.jump_or_branch_valid = de_if.valid & (de_if.is_branch_insn | de_if.is_jump_insn);
    assign fe_if.jump_or_branch_next_pc = (branch_alu_result | de_if.is_jump_insn) ? alu_result : de_if.pc_plus_4;

    always_ff @(posedge clk) begin
        if (propagate_upstream_data) begin
            wb_if.ex_result <= ex_result;

            wb_if.instruction <= de_if.instruction;
            wb_if.instruction_kind <= de_if.instruction_kind;

            wb_if.pc <= de_if.pc;
        end
    end
endmodule
