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

    CONFLICTING_WRITE_PORT_SELECTS: assert property (
        @(posedge clk) disable iff (rst_if.reset)
        (wb_write_vector != '0) & (~stall & de_instruction_has_rd) |-> wb_write_port_select != de_write_port_select
    ) else `uvm_error (
        "CONFLICTING_WRITE_PORT_SELECTS",
        $sformatf("[%m]: DE instruction is not stalling even though wb_write_port_select and de_write_port_select are equal")
    )

    WRITE_VECTOR_IS_ONEHOT0_AND_VALID: assert property (
        @(posedge clk) disable iff (rst_if.reset)
        !$isunknown(wb_write_vector) && $onehot0(wb_write_vector) && (wb_write_vector[0] == 1'b0)
    ) else `uvm_error(
        "WRITE_VECTOR_IS_ONEHOT0_AND_VALID",
        $sformatf("[%m]: wb_write_vector in an invalid state")
    )
endmodule
