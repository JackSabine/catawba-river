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

    // Trap detection
    logic take_trap;
    logic [XLEN-1:0] trap_mcause;
    logic [XLEN-1:0] trap_mtval;
    logic [XLEN-1:0] csr_mtvec;

    // MRET detection
    logic do_mret;
    logic [XLEN-1:0] csr_mepc;

    assign stall_to_make_csr_op_atomic = `IS_CSR_INSN(de_if.instruction) & wb_has_valid_instruction;

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

    assign take_trap   = de_if.valid & propagate_upstream_data & `IS_TRAP_INSN(de_if.instruction);
    assign trap_mcause = `IS_EBREAK_INSN(de_if.instruction) ? 32'd3 : 32'd11;
    // EBREAK: mtval = faulting PC (spec §3.1.17); ECALL: mtval = 0
    assign trap_mtval  = `IS_EBREAK_INSN(de_if.instruction) ? de_if.pc : '0;

    // do_mret fires for exactly one cycle: when a valid mret commits from execute
    assign do_mret = de_if.valid & propagate_upstream_data & `IS_MRET_INSN(de_if.instruction);

    csr_wrapper #(
        .XLEN(XLEN)
    ) csr_wrapper (
        .clk(clk),
        .rst(rst_if.reset),
        .req_csr_address(de_if.operand_b[11:0]),
        .req_source_value(de_if.operand_a),
        .req_system_op(system_op_e'(de_if.instruction.funct3)),
        .req_rd_is_x0(`IS_RD_X0(de_if.instruction)),
        .req_rs_is_x0(`IS_RS_X0(de_if.instruction)),
        .req_valid(de_if.valid & `IS_CSR_INSN(de_if.instruction) & ~stall_to_make_csr_op_atomic),

        .hart_curr_privilege(hart_curr_privilege),

        .take_trap(take_trap),
        .trap_pc(de_if.pc),
        .trap_mcause_val(trap_mcause),
        .trap_mtval_val(trap_mtval),
        .do_mret(do_mret),
        .csr_mtvec(csr_mtvec),
        .csr_mepc(csr_mepc),
        .csr_mcause(),
        .csr_mtval(),

        .rsp_csr_value(csr_read_value)
    );

    memory memory (
        .clk(clk),
        .rst_if(rst_if),

        .req_valid(de_if.valid & `IS_MEM_INSN(de_if.instruction)),
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
        .force_downstream_valid_low(1'b0),

        .propagate_upstream_data(propagate_upstream_data),
        .downstream_valid(wb_if.valid),
        .request_upstream_stall(de_if.stall_upstream)
    );

    always_comb begin
        unique if (`IS_JUMP_INSN(de_if.instruction)) begin
            ex_result = de_if.pc_plus_4;
        end else if (`IS_CSR_INSN(de_if.instruction)) begin
            ex_result = csr_read_value;
        end else if (`IS_MEM_INSN(de_if.instruction) & memory_req_fulfilled) begin
            ex_result = memory_loaded_word;
        end else begin
            ex_result = alu_result;
        end
    end

    assign fe_if.jump_or_branch_valid = de_if.valid & (`IS_BRANCH_INSN(de_if.instruction) | `IS_JUMP_INSN(de_if.instruction));
    assign fe_if.jump_or_branch_next_pc = (branch_alu_result | `IS_JUMP_INSN(de_if.instruction)) ? alu_result : de_if.pc_plus_4;

    assign fe_if.take_trap      = take_trap;
    assign fe_if.trap_target_pc = csr_mtvec;

    assign fe_if.do_mret        = do_mret;
    assign fe_if.mret_target_pc = csr_mepc;

    always_ff @(posedge clk) begin
        if (propagate_upstream_data) begin
            wb_if.ex_result <= ex_result;

            wb_if.instruction <= de_if.instruction;
            wb_if.instruction_kind <= de_if.instruction_kind;

            wb_if.pc <= de_if.pc;
        end
    end
endmodule
