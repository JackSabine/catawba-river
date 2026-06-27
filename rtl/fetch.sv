module fetch import catawba_params::*; import torrence_params::*; #(
    parameter XLEN = 32
) (
    input logic clk,

    reset_if rst_if,

    fetch_execute_if.fe ex_if,
    fetch_decode_if.fe de_if,
    memory_if.requester icache_if
);

logic [XLEN-1:0] pc, next_pc, pc_plus_4;

instruction_t instruction;

logic local_stall_request;
logic propagate_upstream_data;
logic force_downstream_valid_low;

fetch_state_e fe_state, next_fe_state;

assign pc_plus_4 = pc + 'd4;

always_comb begin
    local_stall_request = 1'b0;
    force_downstream_valid_low = 1'b0;

    casez (fe_state)
        NORMAL_OPERATION: begin
            if (`IS_HALT_INSN(instruction)) begin
                next_fe_state = HALTED;
                next_pc = pc;
            end else if (`IS_TRAP_INSN(instruction)) begin
                next_fe_state = STALL_ON_TRAP;
                next_pc = pc;
            end else if (`IS_BRANCH_INSN(instruction) | `IS_JUMP_INSN(instruction)) begin
                next_fe_state = STALL_ON_JUMP_OR_BRANCH;
                next_pc = pc;
            end else begin
                next_fe_state = NORMAL_OPERATION;
                next_pc = icache_if.req_fulfilled ? pc_plus_4 : pc;
            end
        end

        STALL_ON_JUMP_OR_BRANCH: begin
            if (ex_if.jump_or_branch_valid) begin
                next_fe_state = NORMAL_OPERATION;
                next_pc = ex_if.jump_or_branch_next_pc;
                force_downstream_valid_low = 1'b1;
            end else begin
                next_fe_state = STALL_ON_JUMP_OR_BRANCH;
                next_pc = pc;
                local_stall_request = 1'b1;
            end
        end

        STALL_ON_TRAP: begin
            if (ex_if.take_trap) begin
                next_fe_state = NORMAL_OPERATION;
                next_pc = ex_if.trap_target_pc;
                force_downstream_valid_low = 1'b1;
            end else begin
                next_fe_state = STALL_ON_TRAP;
                next_pc = pc;
                local_stall_request = 1'b1;
            end
        end

        HALTED: begin
            next_fe_state = HALTED;
            next_pc = pc;
        end
    endcase
end

advance_control advance_ctrl (
    .clk(clk),
    .rst_if(rst_if),
    .upstream_valid(icache_if.req_fulfilled),
    .local_stall_request(local_stall_request),
    .downstream_stall_request(de_if.stall_upstream),
    .force_downstream_valid_low(force_downstream_valid_low),

    .propagate_upstream_data(propagate_upstream_data),
    .downstream_valid(de_if.valid),
    .request_upstream_stall()
);

always_ff @(posedge clk) begin
    if (rst_if.reset) begin
        pc <= RESET_PC;
        fe_state <= NORMAL_OPERATION;
    end else if (propagate_upstream_data) begin
        pc <= next_pc;
        fe_state <= next_fe_state;
    end

    if (propagate_upstream_data) begin
        de_if.instruction <= instruction;
        de_if.pc <= pc;
        de_if.pc_plus_4 <= pc_plus_4;
    end
end

assign icache_if.req_address = pc;
assign icache_if.req_operation = LOAD;
assign icache_if.req_size = WORD;
assign icache_if.req_store_word = 'x;
assign icache_if.req_valid = 1'b1;

assign instruction = icache_if.req_fulfilled ? icache_if.req_loaded_word : '0;

endmodule
