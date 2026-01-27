`include "catawba_macros.svh"

module memory import catawba_params::*; import torrence_params::*; #(
    parameter XLEN = 32
) (
    input logic clk,
    reset_if rst_if,


    input logic req_valid,
    input logic [XLEN-1:0] req_base_address,
    input logic [XLEN-1:0] req_offset,
    input logic [XLEN-1:0] req_store_word,
    input instruction_t instruction,
    input instruction_kind_t instruction_kind,

    output logic [XLEN-1:0] req_loaded_word,
    output logic req_fulfilled,

    output logic busy,

    output logic head_entry_can_retire,

    memory_if.requester dcache_if
);

    logic [XLEN-1:0] head_entry_req_address;
    logic [XLEN-1:0] head_entry_store_value;
    memory_operation_size_e head_entry_req_size;
    logic head_entry_valid;

    logic stall_incoming_write_req;

    // AGEN

    logic [XLEN-1:0] agen_result;

    assign agen_result = req_base_address + req_offset;

    store_queue #(
        .XLEN(XLEN),
        .DEPTH(4)
    ) store_queue (
        .clk(clk),
        .rst(rst_if.reset),

        .req_address(agen_result),
        .req_store_value(req_store_word),

        .stall_incoming_write_req(stall_incoming_write_req), // FIXME: stall if store_queue full
        .search_read_value(),        // FIXME: used for loads
        .search_read_fulfilled(),    // FIXME: used for loads

        .push((instruction_kind == S_INST) & req_valid),
        .pop(retire_store & head_entry_can_retire), // FIXME: connect to retire/rob

        .head_entry_req_address(head_entry_req_address),
        .head_entry_store_value(head_entry_store_value),
        .head_entry_req_size(head_entry_req_size),
        .head_entry_valid(head_entry_valid)
    );

    // DCACHE WRAPPER

    logic [XLEN-1:0] sext_word, zext_word, load_result;

    memory_operation_size_e mem_op_size;

    assign mem_op_size = retire_store ? head_entry_req_size : memory_operation_size_e'(instruction.funct3[1:0]);

    assign dcache_if.req_address = retire_store ? head_entry_req_address : agen_result;
    assign dcache_if.req_operation = retire_store ? STORE : LOAD;
    assign dcache_if.req_size = mem_op_size;
    assign dcache_if.req_store_word = head_entry_store_value;
    assign dcache_if.req_valid = retire_store ? head_entry_valid : req_valid;

    always_comb begin
        casez (mem_op_size)
            BYTE: begin
                sext_word = {{`WORD-`BYTE{dcache_if.req_loaded_word[`BYTE-1]}}, dcache_if.req_loaded_word[`BYTE-1:0]};
                zext_word = {{`WORD-`BYTE{1'b0}}, dcache_if.req_loaded_word[`BYTE-1:0]};
            end
            HALF: begin
                sext_word = {{`WORD-`HALF{dcache_if.req_loaded_word[`HALF-1]}}, dcache_if.req_loaded_word[`HALF-1:0]};
                zext_word = {{`WORD-`HALF{1'b0}}, dcache_if.req_loaded_word[`HALF-1:0]};
            end
            WORD: begin
                sext_word = dcache_if.req_loaded_word;
                zext_word = dcache_if.req_loaded_word;
            end
            default: begin
                sext_word = 'x;
                zext_word = 'x;
            end
        endcase

        load_result = instruction.funct3[2] ? zext_word : sext_word;
    end

    assign req_loaded_word = load_result;
    assign req_fulfilled = dcache_if.req_fulfilled;

    // stall if retiring a store instruction OR if store queue is full
    assign busy = retire_store | stall_incoming_write_req;

    assign head_entry_can_retire = store_queue.head_entry_valid & dcache_if.req_fulfilled;
endmodule

// retire_store is to be asserted when the ROB has reached a store instruction at its head
// it will hold this until it receives a head_entry_can_retire signal from the store queue
