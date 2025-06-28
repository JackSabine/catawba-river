module alu import catawba_params::*; #(
    parameter XLEN = 32
) (
    input logic [XLEN-1:0] operand_a,
    input logic [XLEN-1:0] operand_b,
    input alu_operation_e operation,

    output logic [XLEN-1:0] result
);

always_comb begin
    case (operation)
        ADD: result = operand_a + operand_b;
        SUB: result = operand_a - operand_b;
        XOR: result = operand_a ^ operand_b;
        OR : result = operand_a | operand_b;
        AND: result = operand_a & operand_b;

        SLL: result = operand_a <<  operand_b[4:0];
        SRL: result = operand_a >>  operand_b[4:0];
        SRA: result = operand_a >>> operand_b[4:0];

        SLT : result = $signed(  operand_a) < $signed(  operand_b);
        SLTU: result = $unsigned(operand_a) < $unsigned(operand_b);

        default: result = 'x;
    endcase
end

endmodule