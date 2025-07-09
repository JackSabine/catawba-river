module advance_control (
    input logic clk,
    reset_if rst_if,
    input logic upstream_valid,
    input logic local_stall_request,
    input logic downstream_stall_request,
    input logic upstream_halt,

    output logic propagate_upstream_data,
    output logic downstream_valid,
    output logic downstream_halt,
    output logic request_upstream_stall
);

    logic next_downstream_valid;
    logic next_downstream_halt;

    logic valid_local_stall_request;

    assign valid_local_stall_request = upstream_valid & local_stall_request;

    // Local Stall Request | Downstream Stall Request ||
    // (must verify valid) | (assumed to be valid)    || Output Valid/Halt Behavior | Upstream Stall
    // --------------------+--------------------------++----------------------------+----------------
    //                   0 |                        0 || Take upstream values       | No stall
    //                   0 |                        1 || Hold current values        | Stall upstream (if upstream_valid)
    //                   1 |                        0 || Set values to 0            | Stall upstream (if upstream_valid)
    //                   1 |                        1 || Hold current values        | Stall upstream (if upstream_valid)
    //                                                               ^
    //                                                    eventually, this case will turn into just a Local Stall Request
    //                                                    or no stall requests if the hazards clear up in time

    always_comb begin
        casez ({valid_local_stall_request, downstream_stall_request})
            2'b00: begin
                next_downstream_valid = upstream_valid & ~upstream_halt;
                next_downstream_halt = upstream_halt;
            end
            2'b01: begin
                next_downstream_valid = downstream_valid;
                next_downstream_halt = downstream_halt;
            end
            2'b10: begin
                next_downstream_valid = 1'b0;
                next_downstream_halt = 1'b0;
            end
            2'b11: begin
                next_downstream_valid = downstream_valid;
                next_downstream_halt = downstream_halt;
            end
        endcase
    end


    always_ff @(posedge clk) begin
        if (rst_if.reset) begin
            downstream_valid <= 1'b0;
            downstream_halt <= 1'b0;
        end else begin
            downstream_valid <= next_downstream_valid;
            downstream_halt <= next_downstream_halt;
        end
    end
    //                           don't stall if current stage invalid (catch-up)
    assign request_upstream_stall = (upstream_valid & downstream_stall_request) | valid_local_stall_request;
    assign propagate_upstream_data = ~request_upstream_stall;
endmodule
