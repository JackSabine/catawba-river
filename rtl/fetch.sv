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
logic downstream_valid;

instruction_t instruction;

// FSM
typedef enum logic [0:0] {
    STALL_ON_BRANCH = 1'b0,
    NORMAL_OPERATION = 1'b1
} fetch_state_e;

fetch_state_e fe_state, next_fe_state;
logic current_inst_is_branch;

assign current_inst_is_branch = (instruction.common.opcode[6:2] == 5'b11000) & icache_if.req_fulfilled;

always_comb begin
    casez (fe_state)
        NORMAL_OPERATION: begin
            if (current_inst_is_branch) begin
                next_fe_state = STALL_ON_BRANCH;
                next_pc = pc;
            end else begin
                next_fe_state = NORMAL_OPERATION;
                next_pc = icache_if.req_fulfilled ? pc_plus_4 : pc;
            end

            downstream_valid = icache_if.req_fulfilled;
        end

        STALL_ON_BRANCH: begin
            if (pc_plus_4 == ex_if.branch_inst_next_pc) begin
                next_fe_state = NORMAL_OPERATION;

                if (ex_if.take_branch) next_pc = ex_if.branch_target_pc;
                else                   next_pc = pc_plus_4;
            end else begin
                next_fe_state = STALL_ON_BRANCH;

                next_pc = pc;
            end

            downstream_valid = 1'b0;
        end
    endcase
end
// End FSM

assign pc_plus_4 = pc + 'd4;

always_ff @(posedge clk) begin
    if (rst_if.reset) begin
        pc <= '0;
        de_if.valid <= 1'b0;
        fe_state <= NORMAL_OPERATION;
    end else begin
        if (~de_if.stall_upstream) begin
            pc <= next_pc;
            de_if.valid <= downstream_valid;
            fe_state <= next_fe_state;
        end
    end

    if (~de_if.stall_upstream) begin
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
