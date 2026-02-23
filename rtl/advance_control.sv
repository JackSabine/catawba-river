module advance_control (
    input logic clk,
    reset_if rst_if,
    input logic upstream_valid,
    input logic local_stall_request,
    input logic downstream_stall_request,
    input logic force_downstream_valid_low,

    output logic propagate_upstream_data,
    output logic downstream_valid,
    output logic request_upstream_stall
);

    logic next_downstream_valid;

    logic valid_local_stall_request;

    assign valid_local_stall_request = upstream_valid & local_stall_request;

    // Local Stall Request | Downstream Stall Request ||
    // (must verify valid) | (assumed to be valid)    || Output Valid Behavior | Upstream Stall
    // --------------------+--------------------------++-----------------------+----------------
    //                   0 |                        0 || Take upstream values  | No stall
    //                   0 |                        1 || Hold current values   | Stall upstream (if upstream_valid)
    //                   1 |                        0 || Set values to 0       | Stall upstream (if upstream_valid)
    //                   1 |                        1 || Hold current values   | Stall upstream (if upstream_valid)
    //                                                               ^
    //                                                    eventually, this case will turn into just a Local Stall Request
    //                                                    or no stall requests if the hazards clear up in time

    always_comb begin
        casez ({force_downstream_valid_low, valid_local_stall_request, downstream_stall_request})
            3'b1??: begin
                next_downstream_valid = 1'b0;
            end
            3'b000: begin
                next_downstream_valid = upstream_valid;
            end
            3'b001: begin
                next_downstream_valid = downstream_valid;
            end
            3'b010: begin
                next_downstream_valid = 1'b0;
            end
            3'b011: begin
                next_downstream_valid = downstream_valid;
            end
        endcase
    end


    always_ff @(posedge clk) begin
        if (rst_if.reset) begin
            downstream_valid <= 1'b0;
        end else begin
            downstream_valid <= next_downstream_valid;
        end
    end
    // Stall upstream if it has valid data and this stage or any downstream has a stall request
    // If upstream is not valid, don't propagate downstream requests and don't listen to local stall requests (allow upstream stages to operate)
    assign request_upstream_stall = (upstream_valid & downstream_stall_request) | valid_local_stall_request;

    // Only propagate if downstream is ready to accept data and nothing is stalling locally
    assign propagate_upstream_data = ~downstream_stall_request & ~valid_local_stall_request;
endmodule
