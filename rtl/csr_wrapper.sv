module csr_wrapper import catawba_params::*; #(
    parameter XLEN = 32
) (
    input  logic            clk,
    input  logic            rst,
    input  logic [11:0]     req_csr_address,
    input  logic [XLEN-1:0] req_source_value,
    input  system_op_e      req_system_op,
    input  logic            req_rd_is_x0,
    input  logic            req_rs_is_x0,
    input  logic            req_valid,

    input  logic            retire_csr_instruction,

    input  logic [1:0]      hart_curr_privilege,
    output logic [XLEN-1:0] rsp_csr_value,
    output logic            stall_incoming_csr_req
);

logic [1:0] req_csr_address_rw;
logic [1:0] req_csr_address_privilege_required;
assign req_csr_address_rw = req_csr_address[11:10];
assign req_csr_address_privilege_required = req_csr_address[9:8];

logic underprivileged_hart;
always_comb begin : privilege_check
    casez (hart_curr_privilege)
        2'b11: underprivileged_hart = 1'b0;
        2'b10: underprivileged_hart = (req_csr_address_privilege_required == 2'b11);
        2'b01: underprivileged_hart = req_csr_address_privilege_required[1];
        2'b00: underprivileged_hart = |(req_csr_address_privilege_required);
        default: underprivileged_hart = 1'b1;
    endcase
end

logic csr_is_ro;
assign csr_is_ro = (req_csr_address_rw == 2'b11);

// valid write unless:
logic req_valid_write;
assign req_valid_write =
    req_valid &
    ~underprivileged_hart &
    ~csr_is_ro &
    ~(req_system_op[1] & ( // csrrs/csrrc op AND
        ( req_system_op[2] & req_source_value == '0) | // immediate type, value is zero OR
        (~req_system_op[2] & req_rs_is_x0)             // reg type, source reg is x0
    ));

// valid read unless: csrrw op AND rd is x0
logic req_valid_read;
assign req_valid_read =
    req_valid &
    ~underprivileged_hart;

logic req_trigger_read_side_effects;
assign req_trigger_read_side_effects =
    req_valid_read &
    ~(req_system_op[1:0] == 2'b01 & req_rd_is_x0);

logic [XLEN-1:0] csr_read_value;
logic [XLEN-1:0] computed_value_to_write;

system_csr_op_e csr_op;
assign csr_op = system_csr_op_e'(req_system_op[1:0]);

always_comb begin
    casez (csr_op)
        RW: computed_value_to_write = req_source_value;
        RS: computed_value_to_write = req_source_value | csr_read_value;
        RC: computed_value_to_write = ~req_source_value & csr_read_value;
        default: begin
            // Illegal
            computed_value_to_write = '0;
        end
    endcase
end

logic [XLEN-1:0] queue_csr_read_value;
logic            queue_read_fulfilled;

logic [11:0] queue_head_entry_csr_address;
logic [XLEN-1:0] queue_head_entry_value;
logic queue_head_entry_valid;

csr_queue csr_queue (
    .clk(clk),
    .rst(rst),
    .req_csr_address(req_csr_address),
    .req_value_to_write(computed_value_to_write),
    .push(req_valid_write),
    .pop(retire_csr_instruction),
    .search_read_value(queue_csr_read_value),
    .search_read_fulfilled(queue_read_fulfilled),
    .stall_incoming_write_req(stall_incoming_csr_req),
    .head_entry_csr_address(queue_head_entry_csr_address),
    .head_entry_value(queue_head_entry_value),
    .head_entry_valid(queue_head_entry_valid)
);

logic invalid_csr_index;
logic [XLEN-1:0] core_csr_read_value;

logic [11:0] read_csr_address;
assign read_csr_address = req_csr_address;

assign csr_read_value = queue_read_fulfilled ? queue_csr_read_value : core_csr_read_value;

// gen_csr.py begin
csr_core #(
    .XLEN(XLEN)
) csr_core_inst (
    .clk,
    .rst,
    .read_csr_address,
    .queue_head_entry_csr_address,
    .queue_head_entry_value,
    .queue_head_entry_valid,
    .core_csr_read_value,
    .invalid_csr_index
);
// gen_csr.py end

assign rsp_csr_value = req_valid_read ? csr_read_value : '0;

endmodule
