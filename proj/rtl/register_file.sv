`include "macros.svh"

module register_file #(
    parameter XLEN = 32,
    parameter NUM_REGISTERS = 32
) (
    input logic clk,

    input logic [`REG_BITS-1:0] read_port_select_1,
    input logic [`REG_BITS-1:0] read_port_select_2,
    input logic [`REG_BITS-1:0] write_port_select,
    input logic [XLEN-1:0] write_port_data,
    input logic write_enable,

    output logic [XLEN-1:0] read_port_data_1,
    output logic [XLEN-1:0] read_port_data_2
);

    logic [XLEN-1:0] register_file [1:NUM_REGISTERS-1]; // Start at 1 so [0] maps to empty reg

    always_ff @(posedge clk) begin
        if (write_enable && |write_port_select) begin
            register_file[write_port_select] <= write_port_data;
        end
    end

    assign read_port_data_1 = read_port_select_1 != '0 ? register_file[read_port_select_1] : '0;
    assign read_port_data_2 = read_port_select_2 != '0 ? register_file[read_port_select_2] : '0;
endmodule