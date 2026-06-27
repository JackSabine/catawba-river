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

    // Trap entry inputs (driven by execute on ecall/ebreak)
    input  logic            take_trap,
    input  logic [XLEN-1:0] trap_pc,
    input  logic [XLEN-1:0] trap_mcause_val,
    output logic [XLEN-1:0] csr_mtvec,

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

// mepc hw override (trap entry: save faulting PC)
logic [31:0] csr_mepc;
logic [31:0] csr_mepc_hw_ovrd;
logic        csr_mepc_hw_ovrd_en;

// mstatus hw override (trap entry: update MIE/MPIE/MPP fields)
logic [31:0] csr_mstatus;
logic [31:0] csr_mstatus_hw_ovrd;
logic        csr_mstatus_hw_ovrd_en;

// mcause hw override (trap entry: set exception code)
logic [31:0] csr_mcause_hw_ovrd;
logic        csr_mcause_hw_ovrd_en;

// mtval hw override (trap entry: 0 for ecall/ebreak)
logic [31:0] csr_mtval_hw_ovrd;
logic        csr_mtval_hw_ovrd_en;

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


assign csr_mepc_hw_ovrd    = trap_pc;
assign csr_mepc_hw_ovrd_en = take_trap;

// Trap entry: mcause = exception code (11 for M-mode ecall, 3 for ebreak)
assign csr_mcause_hw_ovrd    = trap_mcause_val;
assign csr_mcause_hw_ovrd_en = take_trap;

// Trap entry: mtval = 0 for ecall/ebreak
assign csr_mtval_hw_ovrd    = '0;
assign csr_mtval_hw_ovrd_en = take_trap;

// Trap entry: mstatus field update
//   MPP  [12:11] = hart_curr_privilege (save current privilege mode)
//   MPIE [7]     = old MIE             (save old interrupt-enable)
//   MIE  [3]     = 0                   (disable interrupts during trap)
assign csr_mstatus_hw_ovrd = {
    csr_mstatus[XLEN-1:13],  // upper bits preserved
    hart_curr_privilege,      // [12:11] MPP = current privilege
    csr_mstatus[10:8],        // [10:8] preserved
    csr_mstatus[3],           // [7] MPIE = old MIE
    csr_mstatus[6:4],         // [6:4] preserved
    1'b0,                     // [3] MIE = 0
    csr_mstatus[2:0]          // [2:0] preserved
};
assign csr_mstatus_hw_ovrd_en = take_trap;

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
    .csr_mstatus,
    .csr_mstatus_hw_ovrd,
    .csr_mstatus_hw_ovrd_en,
    .csr_mtvec,
    .csr_mepc,
    .csr_mepc_hw_ovrd,
    .csr_mepc_hw_ovrd_en,
    .csr_mcause_hw_ovrd,
    .csr_mcause_hw_ovrd_en,
    .csr_mtval_hw_ovrd,
    .csr_mtval_hw_ovrd_en
);
// gen_csr.py end

assign rsp_csr_value = req_valid_read ? csr_read_value : '0;

endmodule
