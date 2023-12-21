`include "macros.svh"

module register_file #(
    parameter XLEN = 32,
    parameter NUM_REGISTERS = 32
) (
    input wire clk,

    input wire [`REG_BITS-1:0] read_port_select_1,
    input wire [`REG_BITS-1:0] read_port_select_2,
    input wire [`REG_BITS-1:0] write_port_select,
    input wire [XLEN-1:0] write_port_data,
    input wire write_enable,

    output wire [XLEN-1:0] read_port_data_1,
    output wire [XLEN-1:0] read_port_data_2
);

    logic [XLEN-1:0] register_file [1:NUM_REGISTERS-1]; // Start at 1 so [0] maps to empty reg

    always_ff @(posedge clk) begin
        if (write_enable && |write_port_select) begin
            register_file[write_port_select] <= write_port_data;
        end
    end

    assign read_port_data_1 = read_port_select_1 != 'd0 ? register_file[read_port_select_1] : XLEN'('d0);
    assign read_port_data_2 = read_port_select_2 != 'd0 ? register_file[read_port_select_2] : XLEN'('d0);
endmodule