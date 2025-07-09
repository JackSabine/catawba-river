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

fetch_state_e fe_state, next_fe_state;
logic current_inst_is_branch;
logic current_inst_is_halt;

assign current_inst_is_branch = (instruction.opcode[6:2] == 5'b11000) & icache_if.req_fulfilled;
assign current_inst_is_halt = (instruction.opcode[1:0] == 2'b00) & icache_if.req_fulfilled;

assign pc_plus_4 = pc + 'd4;

always_comb begin
    local_stall_request = 1'b0;

    casez (fe_state)
        NORMAL_OPERATION: begin
            if (current_inst_is_halt) begin
                next_fe_state = HALTED;
                next_pc = pc;
            end else if (current_inst_is_branch) begin
                next_fe_state = STALL_ON_BRANCH;
                next_pc = pc;
            end else begin
                next_fe_state = NORMAL_OPERATION;
                next_pc = icache_if.req_fulfilled ? pc_plus_4 : pc;
            end
        end

        STALL_ON_BRANCH: begin
            if (pc_plus_4 == ex_if.branch_inst_next_pc) begin
                next_fe_state = NORMAL_OPERATION;
                next_pc = ex_if.take_branch ? ex_if.branch_target_pc : pc_plus_4;
            end else begin
                next_fe_state = STALL_ON_BRANCH;
                next_pc = pc;
            end

            local_stall_request = 1'b1;
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
    .upstream_halt(current_inst_is_halt),

    .propagate_upstream_data(propagate_upstream_data),
    .downstream_valid(de_if.valid),
    .downstream_halt(de_if.halt),
    .request_upstream_stall()
);

always_ff @(posedge clk) begin
    if (rst_if.reset) begin
        pc <= '0;
        fe_state <= NORMAL_OPERATION;
    end else if (propagate_upstream_data) begin
        pc <= next_pc;
        fe_state <= next_fe_state;
    end

    if (propagate_upstream_data) begin
        de_if.instruction <= instruction;
        de_if.next_pc <= next_pc;
    end
end

assign icache_if.req_address = pc;
assign icache_if.req_operation = LOAD;
assign icache_if.req_size = WORD;
assign icache_if.req_store_word = 'x;
assign icache_if.req_valid = 1'b1;

assign instruction = icache_if.req_loaded_word;

endmodule
