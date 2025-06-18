module fetch import catawba_types::*; #(
    parameter XLEN = 32
) (
    input logic clk,

    reset_if rst_if,

    fetch_execute_if.fe ex_if,
    fetch_decode_if.fe de_if,
    pipe_icache_if.pipe icache_if
);

logic [XLEN-1:0] pc, next_pc, pc_plus_4;
logic downstream_valid;

// FSM
typedef enum logic [0:0] {
    STALL_ON_BRANCH = 1'b0,
    NORMAL_OPERATION = 1'b1
} fetch_state_e;

fetch_state_e fe_state, next_fe_state;
logic current_inst_is_branch;

assign current_inst_is_branch = (icache_if.instruction.common.opcode[6:2] == 5'b11000) & icache_if.rsp_valid;

always_comb begin
    casez (fe_state) 
        NORMAL_OPERATION: begin
            if (current_inst_is_branch) begin
                next_fe_state = STALL_ON_BRANCH;
            end else begin
                next_fe_state = NORMAL_OPERATION;
            end

            next_pc = pc_plus_4;
            downstream_valid = icache_if.rsp_valid;
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
assign icache_if.pc = pc;
assign icache_if.req_valid = 1'b1;

always_ff @(posedge clk) begin
    if (rst_if.reset) begin
        pc <= '0;
        de_if.valid <= 1'b1;
        fe_state <= NORMAL_OPERATION;
    end else begin
        pc <= next_pc;
        de_if.valid <= downstream_valid;
        fe_state <= next_fe_state;
    end

    de_if.instruction <= icache_if.instruction;
    de_if.next_pc <= next_pc;
end

endmodule
