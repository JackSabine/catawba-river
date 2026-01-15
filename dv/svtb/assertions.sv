`include "catawba_macros.svh"
`include "uvm_macros.svh"

module register_scoreboard_assertions import uvm_pkg::*; (
    input logic clk,
    reset_if rst_if,
    input logic de_instruction_has_rd,
    input logic de_instruction_reads_rs1,
    input logic de_instruction_reads_rs2,
    input logic [`NUM_REGS-1:0] de_write_vector,
    input logic [`NUM_REGS-1:0] wb_write_vector,
    input logic [`REG_BITS-1:0] de_write_port_select,
    input logic [`REG_BITS-1:0] wb_write_port_select,
    input logic stall
);

    DE_WRITE_VECTOR_IS_ONEHOT0_AND_VALID: assert property (
        @(posedge clk) disable iff (rst_if.reset)
        !$isunknown(de_write_vector) && $onehot0(de_write_vector) && (de_write_vector[0] == 1'b0)
    ) else `uvm_error(
        "DE_WRITE_VECTOR_IS_ONEHOT0_AND_VALID",
        $sformatf("[%m]: de_write_vector in an invalid state (%032b)", de_write_vector)
    )

   WB_WRITE_VECTOR_IS_ONEHOT0_AND_VALID: assert property (
        @(posedge clk) disable iff (rst_if.reset)
        !$isunknown(wb_write_vector) && $onehot0(wb_write_vector) && (wb_write_vector[0] == 1'b0)
    ) else `uvm_error(
        "WB_WRITE_VECTOR_IS_ONEHOT0_AND_VALID",
        $sformatf("[%m]: wb_write_vector in an invalid state (%032b)", wb_write_vector)
    )
endmodule

bind register_scoreboard register_scoreboard_assertions reg_scoreboard_asserts (.*);

module csr_queue_assertions import uvm_pkg::*; #(
    parameter DEPTH = 2
) (
    input logic clk,
    input logic rst,
    input logic [DEPTH-1:0] search_valid_match,
    input logic push,
    input logic pop,
    input logic full,
    input logic empty,
    input logic search_read_fulfilled,
    input logic stall_incoming_write_req
);

    // assert no pop with empty
    NO_POP_WHEN_EMPTY: assert property (
        @(posedge clk) disable iff (rst)
        !(pop && empty)
    ) else `uvm_error(
        "NO_POP_WHEN_EMPTY",
        $sformatf("[%m]: pop asserted when queue is empty")
    )

    // assert search_valid_match is onehot0
    SEARCH_IS_ONEHOT0: assert property (
        @(posedge clk) disable iff (rst)
        !$isunknown(search_valid_match) && $onehot0(search_valid_match)
    ) else `uvm_error(
        "SEARCH_IS_ONEHOT0",
        $sformatf("[%m]: search_valid_match in an invalid state (%012b)", search_valid_match)
    )

    // no write when full
    NO_WRITE_WHEN_FULL: assert property (
        @(posedge clk) disable iff (rst)
        !(push && full)
    ) else `uvm_error(
        "NO_WRITE_WHEN_FULL",
        $sformatf("[%m]: write request when queue is full")
    )
endmodule

bind csr_queue csr_queue_assertions #(.DEPTH(DEPTH)) csr_queue_asserts (.*);
