module alu import catawba_types::*; #(
    parameter XLEN = 32
) (
    input wire [XLEN-1:0] operand_a,
    input wire [XLEN-1:0] operand_b,
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

        SHIFT_LEFT            : result = operand_a <<  operand_b;
        SHIFT_RIGHT           : result = operand_a >>  operand_b;
        SHIFT_RIGHT_ARITHMETIC: result = operand_a >>> operand_b;

        SET_LESS_THAN         : result = $signed(  operand_a) < $signed(  operand_b);
        SET_LESS_THAN_UNSIGNED: result = $unsigned(operand_a) < $unsigned(operand_b);

        default: begin
            result = 'bx;
        end
    endcase
end

endmodule