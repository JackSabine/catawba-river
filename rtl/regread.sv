module regread import catawba_params::*; (
    input logic clk,

    input logic [PRF_PTR_WIDTH-1:0] read_port_select_1,
    input logic [PRF_PTR_WIDTH-1:0] read_port_select_2,
    input logic [PRF_PTR_WIDTH-1:0] write_port_select,
    input logic [XLEN-1:0] write_port_data,

    output logic [XLEN-1:0] read_port_data_1,
    output logic [XLEN-1:0] read_port_data_2
);

    logic [XLEN-1:0] register_file [0:PRF_DEPTH-1];

    assign register_file[0] = '0;

    always_ff @(posedge clk) begin
        if (write_port_select != '0) begin
            register_file[write_port_select] <= write_port_data;
        end
    end

    assign read_port_data_1 = register_file[read_port_select_1];
    assign read_port_data_2 = register_file[read_port_select_2];
endmodule
