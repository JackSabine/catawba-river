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

    memory_if.requester dcache_if
);

    // AGEN

    logic [XLEN-1:0] agen_result;

    assign agen_result = req_base_address + req_offset;

    // DCACHE WRAPPER

    logic [XLEN-1:0] sext_word, zext_word, load_result;

    memory_operation_size_e mem_op_size;

    assign mem_op_size = memory_operation_size_e'(instruction.funct3[1:0]);

    assign dcache_if.req_address = agen_result;
    assign dcache_if.req_operation = (instruction_kind == S_INST) ? STORE : LOAD;
    assign dcache_if.req_size = mem_op_size;
    assign dcache_if.req_store_word = req_store_word;
    assign dcache_if.req_valid = req_valid;

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

    assign busy = req_valid & ~dcache_if.req_fulfilled;
endmodule
