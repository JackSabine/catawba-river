module writeback import catawba_params::*; #(
    parameter XLEN = 32
) (
    input logic clk,
    reset_if rst_if,

    execute_writeback_if.wb ex_if,
    writeback_rob_if.wb rob_if
);
    // logic write_enable;
    logic propagate_upstream_data;

    // assign write_enable = ex_if.valid & ex_if.instruction_kind inside {R_INST, I_INST, J_INST, U_INST};

    advance_control advance_ctrl (
        .clk(clk),
        .rst_if(rst_if),
        .upstream_valid(ex_if.valid),
        .local_stall_request(1'b0),
        .downstream_stall_request(1'b0),
        .force_downstream_valid_low(1'b0),

        .propagate_upstream_data(propagate_upstream_data),
        .downstream_valid(rob_if.valid),
        .request_upstream_stall()
    );

    `EXCEPTION_BEGIN
    `EXCEPTION_END

    `EXCEPTION_FLOPS(rob_if, ex_if)

    always_ff @(posedge clk) begin
        if (propagate_upstream_data) begin
            rob_if.result <= ex_if.ex_result;
            rob_if.rob_index <= ex_if.rob_index;
            // assign rob_if.rd = write_enable ? ex_if.instruction.rd : '0;
        end
    end
endmodule
