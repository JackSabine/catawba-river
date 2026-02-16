`include "catawba_macros.svh"

module register_scoreboard import catawba_params::*; #(
    parameter XLEN = 32,
    parameter NUM_REGISTERS = `NUM_REGS
) (
    input logic clk,
    reset_if rst_if,

    input logic de_valid,

    input instruction_kind_t de_instruction_kind,
    input logic [`REG_BITS-1:0] de_read_port_select_1,
    input logic [`REG_BITS-1:0] de_read_port_select_2,
    input logic [`REG_BITS-1:0] de_write_port_select,

    input logic [`REG_BITS-1:0] wb_write_port_select,

    input logic block_ready_bit_clear,

    output logic stall
);

    logic ready_bits [0:NUM_REGISTERS-1];

    logic de_instruction_has_rd, de_instruction_reads_rs1, de_instruction_reads_rs2;
    logic [NUM_REGISTERS-1:0] de_write_vector, wb_write_vector;

    assign de_instruction_has_rd = de_instruction_kind inside {R_INST, I_INST, U_INST, J_INST};
    assign de_instruction_reads_rs1 = de_instruction_kind inside {R_INST, I_INST, S_INST, B_INST};
    assign de_instruction_reads_rs2 = de_instruction_kind inside {R_INST,         S_INST, B_INST};


    assign de_write_vector[0] = 1'b0;
    assign wb_write_vector[0] = 1'b0;
    always_comb begin
        for (int r = 1; r < NUM_REGISTERS; r++) begin
            de_write_vector[r] = de_valid & (de_write_port_select == r);
            wb_write_vector[r] = (wb_write_port_select == r);
        end
    end

    // use_rx | ready[rx] || stall
    // -------+-----------++------
    //   0    |     x     ||   0
    //   1    |     1     ||   0
    //   1    |     0     ||   1

    // Stall on unready rd to prevent failures where de, ex, and wb have inst's writing to same rd.
    // In that case, the wb inst will ready rd while ex has a younger value to write for the inst in de.
    // This would cause the younger instruction to read wb's value instead of ex's value

    assign stall = (de_instruction_has_rd    & ~ready_bits[de_write_port_select] ) |
                   (de_instruction_reads_rs1 & ~ready_bits[de_read_port_select_1]) |
                   (de_instruction_reads_rs2 & ~ready_bits[de_read_port_select_2]);

    assign ready_bits[0] = 1'b1;

    always_ff @(posedge clk) begin
        if (rst_if.reset) begin
            for (int r = 1; r < NUM_REGISTERS; r++) begin
                ready_bits[r] = 1'b1;
            end
        end else begin
            // When wb_write_enable and de_instruction_has_rd are active while stall isn't active,
            // wb_write_port_select will not equal de_write_port_select
            for (int r = 1; r < NUM_REGISTERS; r++) begin
                if (de_valid & ~stall & de_instruction_has_rd & de_write_vector[r]) begin
                    if (~block_ready_bit_clear) begin
                        ready_bits[r] <= 1'b0;
                    end
                end else if (wb_write_vector[r]) begin
                    ready_bits[r] <= 1'b1;
                end
            end
        end
    end
endmodule
