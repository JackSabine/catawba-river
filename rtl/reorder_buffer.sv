module reorder_buffer import catawba_params::*; (
    input logic clk,
    reset_if rst_if,

    rob_writer_if.rob wr_if,
    retire_rob_if.rob rt_if,

    writeback_rob_if.rob wb_if
);

typedef struct packed {
    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] instruction;
    logic [XLEN-1:0] result;
    logic exception_posted;
    exception_code_e exception_code;
    // logic mispredicted;
    logic ready;
    logic [`REG_BITS-1:0] dest_reg;
} rob_entry_t;

rob_entry_t rob[ROB_DEPTH];
logic [ROB_PTR_WIDTH-1:0] head;
logic [ROB_PTR_WIDTH-1:0] tail;


assign rt_if.head_ready            = rob[head].ready & ~rt_if.empty;
assign rt_if.head_pc               = rob[head].pc;
assign rt_if.head_instruction      = rob[head].instruction;
assign rt_if.head_dest_reg         = rob[head].dest_reg;
assign rt_if.head_result           = rob[head].result;
assign rt_if.head_exception_posted = rob[head].exception_posted;
assign rt_if.head_exception_code   = rob[head].exception_code;


genvar i;
always_ff @(posedge clk) begin
    for (i = 0; i < ROB_DEPTH; i++) begin : rob_entries
        unique0 if (wb_if.valid && (wb_if.rob_index == i)) begin
            rob[i].result = wb_if.result;
            rob[i].exception_code = wb_if.exception_code;
            rob[i].exception_posted = wb_if.exception_posted;
            rob[i].ready = 1'b1; // Mark as ready when writeback occurs
        end else if (wr_if.push && (tail == i)) begin
            rob[tail].pc = wr_if.pc;
            rob[tail].instruction = wr_if.instruction;
            rob[tail].dest_reg = wr_if.dest_reg;
            rob[tail].ready = 1'b0; // Initially not ready
            rob[tail].exception_posted = 1'b0; // No exception posted initially
            rob[tail].exception_code = EXC_NONE; // No exception initially
            // rob[tail].mispredicted = 1'b0; // No misprediction initially
        end
    end
end

fifo_ptrs #(
    .PTR_WIDTH(ROB_PTR_WIDTH)
) rob_ptrs (
    .clk,
    .rst(rst_if.reset),
    .push(wr_if.push),
    .pop(rt_if.pop),
    .full(wr_if.full),
    .empty(rt_if.empty),
    .head,
    .tail
);

endmodule