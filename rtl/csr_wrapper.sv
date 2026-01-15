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

    input  logic [1:0]      hart_curr_privilege,
    output logic [XLEN-1:0] rsp_csr_value
);

logic [1:0] req_csr_address_rw;
logic [1:0] req_csr_address_privilege_required;
logic csr_is_ro;
logic underprivileged_hart;
logic req_valid_write;
logic req_valid_read;
logic req_trigger_read_side_effects;
logic [XLEN-1:0] csr_read_value;
logic [XLEN-1:0] value_to_write;
system_csr_op_e csr_op;
logic invalid_csr_index;
logic [31:0] csr_mepc;
logic [31:0] csr_mepc_hw_ovrd;
logic        csr_mepc_hw_ovrd_en;

assign req_csr_address_rw = req_csr_address[11:10];
assign req_csr_address_privilege_required = req_csr_address[9:8];

always_comb begin : privilege_check
    casez (hart_curr_privilege)
        2'b11: underprivileged_hart = 1'b0;
        2'b10: underprivileged_hart = (req_csr_address_privilege_required == 2'b11);
        2'b01: underprivileged_hart = req_csr_address_privilege_required[1];
        2'b00: underprivileged_hart = |(req_csr_address_privilege_required);
        default: underprivileged_hart = 1'b1;
    endcase
end

assign csr_is_ro = (req_csr_address_rw == 2'b11);

// valid write unless:
assign req_valid_write =
    req_valid &
    ~underprivileged_hart &
    ~csr_is_ro &
    ~(req_system_op[1] & ( // csrrs/csrrc op AND
        ( req_system_op[2] & req_source_value == '0) | // immediate type, value is zero OR
        (~req_system_op[2] & req_rs_is_x0)             // reg type, source reg is x0
    ));

// valid read unless: csrrw op AND rd is x0
assign req_valid_read =
    req_valid &
    ~underprivileged_hart;

assign req_trigger_read_side_effects =
    req_valid_read &
    ~(req_system_op[1:0] == 2'b01 & req_rd_is_x0);

assign csr_op = system_csr_op_e'(req_system_op[1:0]);

always_comb begin
    casez (csr_op)
        RW: value_to_write = req_source_value;
        RS: value_to_write = req_source_value | csr_read_value;
        RC: value_to_write = ~req_source_value & csr_read_value;
        default: begin
            // Illegal
            value_to_write = '0;
        end
    endcase
end


assign csr_mepc_hw_ovrd_en = '0;

// gen_csr.py begin
csr_core #(
    .XLEN(XLEN)
) csr_core_inst (
    .clk,
    .rst,
    .req_csr_address,
    .req_valid_read,
    .req_valid_write,
    .value_to_write,
    .req_trigger_read_side_effects,
    .csr_read_value,
    .invalid_csr_index,
    .csr_mepc,
    .csr_mepc_hw_ovrd,
    .csr_mepc_hw_ovrd_en
);
// gen_csr.py end

assign rsp_csr_value = req_valid_read ? csr_read_value : '0;

endmodule
