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
