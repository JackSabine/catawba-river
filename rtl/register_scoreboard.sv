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
            de_write_vector[r] = (de_write_port_select == r);
            wb_write_vector[r] = (wb_write_port_select == r);
        end
    end

    // stall on non-ready rd to prevent younger instructions from advancing
    // when the older writer of rd finishes

    // use_rsx | ready[rsx] || stall
    // --------+------------++------
    //   0     |     x      ||   0
    //   1     |     1      ||   0
    //   1     |     0      ||   1
    assign stall = (de_instruction_reads_rs1 & ~ready_bits[de_read_port_select_1]) |
                   (de_instruction_reads_rs2 & ~ready_bits[de_read_port_select_2]) |
                   (de_instruction_has_rd    & ~ready_bits[de_write_port_select]);

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
                unique0 if (wb_write_vector[r]) begin
                    ready_bits[r] <= 1'b1;
                end else if (de_valid & ~stall & de_instruction_has_rd & de_write_vector[r]) begin
                    ready_bits[r] <= 1'b0;
                end
            end
        end
    end
endmodule
