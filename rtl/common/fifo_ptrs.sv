module fifo_ptrs #(
    parameter int unsigned PTR_WIDTH = 4
) (
    input logic clk,
    input logic rst,

    input  logic push,
    input  logic pop,
    output logic full,
    output logic empty,
    output logic [PTR_WIDTH-1:0] head,
    output logic [PTR_WIDTH-1:0] tail
);

logic head_phase;
logic tail_phase;

assign full  = (head == tail) && (head_phase != tail_phase);
assign empty = (head == tail) && (head_phase == tail_phase);

always_ff @(posedge clk) begin
    if (rst) begin
        head <= '0;
        head_phase <= 1'b0;
        tail <= '0;
        tail_phase <= 1'b0;
    end else begin
        if (push) {tail_phase, tail} <= {tail_phase, tail} + 'd1;
        if (pop)  {head_phase, head} <= {head_phase, head} + 'd1;
    end
end

NO_POP_WHEN_EMPTY: assert property (
    disable iff (rst)
    @(posedge clk) pop |-> !empty
) else $error("generic_fifo: pop asserted when empty");

NO_PUSH_WHEN_FULL: assert property (
    disable iff (rst)
    @(posedge clk) push |-> !full
) else $error("generic_fifo: push asserted when full");

endmodule
