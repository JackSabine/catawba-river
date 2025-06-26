`include "catawba_macros.svh"

module memory import catawba_params::*; import torrence_params::*; #(
    parameter XLEN = 32
) (
    input logic clk,

    execute_memory_if.mem ex_if,
    memory_writeback_if.mem wb_if,
    memory_if.requester dcache_if
);

    logic mem_req_valid;
    memory_operation_size_e mem_op_size;

    logic [XLEN-1:0] sext_word, zext_word, load_result;

    assign mem_req_valid = ex_if.valid & ex_if.is_mem_inst;
    assign mem_op_size = memory_operation_size_e'(ex_if.instruction.common.funct3[1:0]);

    assign dcache_if.req_address = ex_if.alu_result;
    assign dcache_if.req_operation = (ex_if.instruction_kind == S_INST) ? STORE : LOAD;
    assign dcache_if.req_size = mem_op_size;
    assign dcache_if.req_store_word = ex_if.rs2_word;
    assign dcache_if.req_valid = mem_req_valid;

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

        load_result = ex_if.instruction.common.funct3[2] ? zext_word : sext_word;
    end

    always_ff @(posedge clk) begin
        wb_if.valid <= ex_if.valid;
        wb_if.alu_result <= ex_if.alu_result;
        wb_if.load_result <= load_result;
        wb_if.instruction <= ex_if.instruction;
        wb_if.instruction_kind <= ex_if.instruction_kind;
        wb_if.is_mem_inst <= ex_if.is_mem_inst;
    end

    assign ex_if.stall_upstream = ex_if.valid & (ex_if.is_mem_inst & ~dcache_if.req_fulfilled);
endmodule
