module reorder_buffer import catawba_params::*; (
    input logic clk,
    input logic rst,

    input logic [31:0] dispatch_pc,
    input logic [31:0] dispatch_instruction,
    input logic [`REG_BITS-1:0] dispatch_dest_reg,

    input logic push,
    input logic pop,

    output logic full,
    output logic empty,

    output logic head_ready,
    output logic [31:0] head_pc,
    output logic [31:0] head_instruction,
    output logic [`REG_BITS-1:0] head_dest_reg,
    output logic [XLEN-1:0] head_result,
    output logic head_exception
);

typedef struct packed {
    logic [31:0] pc;
    logic [31:0] instruction;
    logic [XLEN-1:0] result;
    logic exception;
    logic ready;
    logic [`REG_BITS-1:0] dest_reg;
    logic [LSQ_PTR_WIDTH-1:0] lsq_index;
} rob_entry_t;

rob_entry_t rob[ROB_DEPTH];
logic [ROB_PTR_WIDTH-1:0] head;
logic head_phase;
logic [ROB_PTR_WIDTH-1:0] tail;
logic tail_phase;

assign full  = (head == tail) && (head_phase != tail_phase);
assign empty = (head == tail) && (head_phase == tail_phase);
assign head_ready = rob[head].ready & ~empty;

assign head_pc = rob[head].pc;
assign head_instruction = rob[head].instruction;
assign head_dest_reg = rob[head].dest_reg;
assign head_result = rob[head].result;
assign head_exception = rob[head].exception;


always_ff @(posedge clk) begin
    if (rst) begin
        head <= '0;
        head_phase <= 1'b0;
        tail <= '0;
        tail_phase <= 1'b0;
    end else begin
        if (push && !full) begin
            rob[tail].pc = dispatch_pc;
            rob[tail].instruction = dispatch_instruction;
            rob[tail].dest_reg = dispatch_dest_reg;
            rob[tail].ready = 1'b0; // Initially not ready
            rob[tail].exception = 1'b0; // No exception initially

            {tail_phase, tail} <= {tail_phase, tail} + 'd1;
        end

        if (pop && !empty) begin
            // Commit the instruction at head
            // Handle result, exceptions, etc.

            {head_phase, head} <= {head_phase, head} + 'd1;
        end
    end
end

endmodule