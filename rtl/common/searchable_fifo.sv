module searchable_fifo #(
    parameter type fifo_data_t = logic,
    parameter type fifo_key_t = logic,
    parameter int unsigned DEPTH = 8
) (
    input logic clk,
    input logic rst,

    input  logic       push,
    input  fifo_key_t  push_key,
    input  fifo_data_t push_data,

    input  logic       pop,
    output fifo_key_t  head_key,
    output fifo_data_t head_data,

    output logic full,
    output logic empty,

    input  fifo_key_t  search_key,
    output logic       search_hit,
    output fifo_data_t search_data
);

localparam int unsigned PTR_WIDTH = $clog2(DEPTH);

fifo_key_t  key_mem[DEPTH];
fifo_data_t     mem[DEPTH];

logic [PTR_WIDTH-1:0] head;
logic [PTR_WIDTH-1:0] tail;
logic [DEPTH-1:0] valid;
logic [DEPTH-1:0] match;
logic [DEPTH-1:0] priority_mask;
logic [PTR_WIDTH-1:0] rotated_idx;
logic [PTR_WIDTH-1:0] search_idx;

assign head_data =     mem[head];
assign head_key  = key_mem[head];

always_ff @(posedge clk) begin
    for (int i = 0; i < DEPTH; i++) begin
        if (push && (tail == i)) begin
            mem[i]     <= push_data;
            key_mem[i] <= push_key;
        end
    end
end

always_ff @(posedge clk) begin
    for (int i = 0; i < DEPTH; i++) begin : valid_bits
        if (rst) begin
            valid[i] <= 1'b0;
        end else if (push && (tail == i)) begin
            valid[i] <= 1'b1;
        end else if (pop && (head == i)) begin
            valid[i] <= 1'b0;
        end
    end
end

always_comb begin : search
    for (int i = 0; i < DEPTH; i++) begin : search_entries
        match[i] = valid[i] & (key_mem[i] == search_key);
    end

    search_hit = |match;

    // Rotate so head is priority 0; highest set index in rotated space is
    // the most-recently-pushed match (closest to tail).
    priority_mask = {2{match}} >> head;

    rotated_idx = '0;
    for (int i = 0; i < DEPTH; i++) begin
        if (priority_mask[i]) rotated_idx = PTR_WIDTH'(i);
    end

    // Undo the rotation with a plain add: since DEPTH is a power of 2,
    // PTR_WIDTH-bit wraparound is mod DEPTH for free.
    search_idx = head + rotated_idx;

    search_data = mem[search_idx];
end



// The search index math (head + rotated_idx) relies on DEPTH being an exact
// power of 2 so PTR_WIDTH-bit wraparound is mod DEPTH for free.
generate
    if ((DEPTH & (DEPTH - 1)) != 0) $error("generic_fifo: DEPTH (%0d) must be a power of 2", DEPTH);
endgenerate

fifo_ptrs #(
    .PTR_WIDTH(PTR_WIDTH)
) fifo_ptrs (
    .clk,
    .rst,
    .push,
    .pop,
    .full,
    .empty,
    .head,
    .tail
);

endmodule
