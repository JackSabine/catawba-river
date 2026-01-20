module load_store_queue #(
    parameter XLEN = 32,
    parameter DEPTH = 2
) (
    input logic clk,
    input logic rst,

    input logic [11:0] req_csr_address,
    input logic [XLEN-1:0] req_value_to_write,

    output logic stall_incoming_write_req,
    output logic [XLEN-1:0] search_read_value,
    output logic search_read_fulfilled,

    input logic push,
    input logic pop,

    output logic [11:0] head_entry_csr_address,
    output logic [XLEN-1:0] head_entry_value,
    output logic head_entry_valid
);

localparam PTR_WIDTH = $clog2(DEPTH);

logic [DEPTH-1:0][XLEN-1:0] write_addresses;
logic [DEPTH-1:0][XLEN-1:0] write_values;
logic [DEPTH-1:0] valids;

logic [PTR_WIDTH-1:0] head_ptr, tail_ptr;

logic head_ptr_phase, tail_ptr_phase;

logic [DEPTH-1:0] search_valid_match;
logic [DEPTH-1:0][XLEN-1:0] search_valid_match_values;
logic req_csr_address_matches_any_entry;

logic empty;
logic full;

assign empty = (head_ptr == tail_ptr) & (head_ptr_phase == tail_ptr_phase);
assign full  = (head_ptr == tail_ptr) & (head_ptr_phase != tail_ptr_phase) & !pop; // if popping this cycle, queue will be empty next cycle

// head increments after pop
// tail increments after push
always_ff @(posedge clk) begin
    if (rst) begin
        valids <= '0;
        head_ptr <= '0;
        head_ptr_phase <= '0;
        tail_ptr <= '0;
        tail_ptr_phase <= '0;
    end else begin
        if (push) begin
            {tail_ptr_phase, tail_ptr} <= {tail_ptr_phase, tail_ptr} + 'd1;
            csr_addresses[tail_ptr] <= req_csr_address;
            write_values[tail_ptr] <= req_value_to_write;
            valids[tail_ptr] <= 1'b1;
        end

        if (pop) begin
            {head_ptr_phase, head_ptr} <= {head_ptr_phase, head_ptr} + 'd1;
            valids[head_ptr] <= 1'b0;
        end
    end
end

always_comb begin
    for (int i = 0; i < DEPTH; i++) begin
        search_valid_match[i] = valids[i] & (csr_addresses[i] == req_csr_address);
        search_valid_match_values[i] = search_valid_match[i] ? write_values[i] : '0;
    end

    for (int bitpos = 0; bitpos < XLEN; bitpos++) begin
        search_read_value[bitpos] = 1'b0;
        for (int queueindex = 0; queueindex < DEPTH; queueindex++) begin
            search_read_value[bitpos] |= search_valid_match_values[queueindex][bitpos];
        end
    end
end


assign req_csr_address_matches_any_entry = |(search_valid_match);

assign search_read_fulfilled = req_csr_address_matches_any_entry;

assign stall_incoming_write_req = push & (full | req_csr_address_matches_any_entry);

endmodule
