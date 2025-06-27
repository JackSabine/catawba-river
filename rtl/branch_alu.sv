module branch_alu import catawba_params::*; #(
    parameter XLEN = 32
) (
    input logic [XLEN-1:0] operand_a,
    input logic [XLEN-1:0] operand_b,
    input branch_alu_operation_e operation,

    output logic result
);

always_comb begin
    case (operation)
        EQ:      result = (operand_a == operand_b);
        NEQ:     result = (operand_a != operand_b);
        LT:      result = $signed(  operand_a) <  $signed(  operand_b);
        GTE:     result = $signed(  operand_a) >= $signed(  operand_b);
        LT_U:    result = $unsigned(operand_a) <  $unsigned(operand_b);
        GTE_U:   result = $unsigned(operand_a) >= $unsigned(operand_b);
        default: result = 'bx;
    endcase
end

endmodule
