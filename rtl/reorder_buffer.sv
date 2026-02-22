module reorder_buffer import catawba_params::*; (
    input logic clk,
    input logic rst,

    rename_rob_if.rob rename_if,
    retire_rob_if.rob retire_if,

    writeback_rob_if.rob writeback_if
);

typedef struct packed {
    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] instruction;
    logic [XLEN-1:0] result;
    logic exception;
    // logic mispredicted;
    logic ready;
    logic [`REG_BITS-1:0] dest_reg;
    // logic [LSQ_PTR_WIDTH-1:0] lsq_index;
} rob_entry_t;

rob_entry_t rob[ROB_DEPTH];
logic [ROB_PTR_WIDTH-1:0] head;
logic head_phase;
logic [ROB_PTR_WIDTH-1:0] tail;
logic tail_phase;

assign rename_if.full  = (head == tail) && (head_phase != tail_phase);
assign retire_if.empty = (head == tail) && (head_phase == tail_phase);
assign head_ready = rob[head].ready & ~retire_if.empty;

assign retire_if.head_pc = rob[head].pc;
assign retire_if.head_instruction = rob[head].instruction;
assign retire_if.head_dest_reg = rob[head].dest_reg;
assign retire_if.head_result = rob[head].result;
assign retire_if.head_exception = rob[head].exception;

logic legal_push;
logic legal_pop;

assign legal_push = rename_if.push && !full;
assign legal_pop  = retire_if.pop && !empty;


always_ff @(posedge clk) begin
    if (rst) begin
        head <= '0;
        head_phase <= 1'b0;
        tail <= '0;
        tail_phase <= 1'b0;
    end else begin
        if (legal_push) {tail_phase, tail} <= {tail_phase, tail} + 'd1;
        if (legal_pop)  {head_phase, head} <= {head_phase, head} + 'd1;
    end
end

always_ff @(posedge clk) begin
    for (genvar i = 0; i < ROB_DEPTH; i++) begin
        unique0 if (writeback_if.valid && (writeback_if.rob_index == i)) begin
            rob[i].result = writeback_if.result;
            rob[i].exception = writeback_if.exception;
            rob[i].ready = 1'b1; // Mark as ready when writeback occurs
        end else if (legal_push && (tail == i)) begin
            rob[tail].pc = rename_if.pc;
            rob[tail].instruction = rename_if.instruction;
            rob[tail].dest_reg = rename_if.dispatch_dest_reg;
            rob[tail].ready = 1'b0; // Initially not ready
            rob[tail].exception = 1'b0; // No exception initially
            // rob[tail].mispredicted = 1'b0; // No misprediction initially
        end
    end
end

endmodule