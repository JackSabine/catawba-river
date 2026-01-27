module store_queue #(
    parameter XLEN = 32,
    parameter DEPTH = 2
) (
    input logic clk,
    input logic rst,

    input logic [XLEN-1:0] req_address,
    input logic [XLEN-1:0] req_store_value,
    input memory_operation_size_e req_op_size,

    output logic stall_incoming_write_req,
    output logic [XLEN-1:0] search_read_value,
    output logic search_read_fulfilled,

    input logic push,
    input logic pop,

    output logic [XLEN-1:0] head_entry_req_address,
    output logic [XLEN-1:0] head_entry_store_value,
    output memory_operation_size_e head_entry_req_size,
    output logic head_entry_valid
);

localparam PTR_WIDTH = $clog2(DEPTH);

logic [DEPTH-1:0][XLEN-1:0] write_addresses;
logic [DEPTH-1:0][XLEN-1:0] write_values;
memory_operation_size_e write_sizes [DEPTH-1:0];
logic [DEPTH-1:0] valids;

// tail points to the next free entry, store points to the entry to be written
logic [PTR_WIDTH-1:0] tail_ptr, next_tail_ptr, store_ptr;

logic [DEPTH-1:0] search_match_vector;

always_ff @(posedge clk) begin
    if (rst) begin
        tail_ptr <= '0;
        valids <= '0;
    end else begin
        tail_ptr <= next_tail_ptr;

        for (int i = 0; i < DEPTH; i++) begin
            if (i == DEPTH-1) begin
                unique0 if (push & !pop & (i == store_ptr)) begin
                    // Take new data
                    write_addresses[i] <= req_address;
                    write_values[i] <= req_store_value;
                    write_sizes[i] <= req_op_size;
                    valids[i] <= 1'b1;
                end else if (!push & pop) begin
                    // Invalidate
                    valids[i] <= 1'b0;
                end
            end else begin
                unique0 if ((!push & pop) | (push & pop & (i != store_ptr))) begin
                    // Take i+1 data
                    write_addresses[i] <= write_addresses[i+1];
                    write_values[i] <= write_values[i+1];
                    write_sizes[i] <= write_sizes[i+1];
                    valids[i] <= valids[i+1];
                end else if (push & (i == store_ptr)) begin
                    // Take new data
                    write_addresses[i] <= req_address;
                    write_values[i] <= req_store_value;
                    write_sizes[i] <= req_op_size;
                    valids[i] <= 1'b1;
                end
            end
        end
    end
end

assign store_ptr = (push & pop) ? tail_ptr - 1 : tail_ptr;

always_comb begin
    casez ({push, pop})
        2'b11: next_tail_ptr = tail_ptr;
        2'b10: next_tail_ptr = tail_ptr + 1;
        2'b01: next_tail_ptr = tail_ptr - 1;
        default: next_tail_ptr = tail_ptr;
    endcase
end

assign head_entry_req_address = write_addresses[0];
assign head_entry_store_value = write_values[0];
assign head_entry_valid = valids[0];


always_comb begin
    for (int i = 0; i < DEPTH; i++) begin
        search_match_vector[i] = (valids[i] & (write_addresses[i] == req_address));
    end
end

assign search_read_fulfilled = |search_match_vector;

// priority decoder: highest index (youngest store) has priority
always_comb begin
    search_read_value = 'x;
    for (int i = 0; i < DEPTH; i++) begin
        if (search_match_vector[i]) begin
            search_read_value = write_values[i];
        end
    end
end

assign stall_incoming_write_req = (tail_ptr == 0) & valids[0] & push & !pop;

endmodule
