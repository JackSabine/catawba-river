module decode import catawba_types::*; #(
    parameter XLEN = 32
) (
    input logic clk,

    fetch_decode_if.de fe_if,
    decode_execute_if.de ex_if
);

    logic [`REG_BITS-1:0] rs1_index, rs2_index, rd_index;
    logic [XLEN-1:0] rs1_word, rs2_word;

    logic a_use_pc;

    logic [XLEN-1:0] composed_immediate;
    logic b_use_imm;

    alu_operation_e alu_operation;

    logic is_branch_inst;
    branch_alu_operation_e branch_alu_operation;

    instruction_type_t inst_type;


    assign rs1_index = fe_if.instruction[19:15];
    assign rs2_index = fe_if.instruction[24:20];

    assign rd_index = '0; // Take from WB stage

    register_file regfile (
        .clk(clk),
        .read_port_select_1(rs1_index),
        .read_port_select_2(rs2_index),
        .write_port_select(rd_index),
        .write_port_data('0),
        .write_enable('0),

        .read_port_data_1(rs1_word),
        .read_port_data_2(rs2_word)
    );

    always_comb begin
        unique casez (fe_if.instruction.common.funct3)
        3'h0: alu_operation = fe_if.instruction.common.funct7[6] ? SUB : ADD;
        3'h1: alu_operation = SHIFT_LEFT;
        3'h2: alu_operation = SET_LESS_THAN;
        3'h3: alu_operation = SET_LESS_THAN_UNSIGNED;
        3'h4: alu_operation = XOR;
        3'h5: alu_operation = fe_if.instruction.common.funct7[6] ? SHIFT_RIGHT : SHIFT_RIGHT_ARITHMETIC;
        3'h6: alu_operation = OR;
        3'h7: alu_operation = AND;
        default: alu_operation = ALU_OP_UNDEFINED;
        endcase
    end

    always_comb begin
        unique casez (fe_if.instruction.b_type.funct3)
        3'h0: branch_alu_operation = EQ;
        3'h1: branch_alu_operation = NEQ;
        3'h4: branch_alu_operation = LT;
        3'h5: branch_alu_operation = GTE;
        3'h6: branch_alu_operation = LT_U;
        3'h7: branch_alu_operation = GTE_U;
        default: branch_alu_operation = BRANCH_OP_UNDEFINED;
        endcase
    end

    always_comb begin
        is_branch_inst = 1'b0;

        unique casez (fe_if.instruction.common.opcode)
        7'b01100??: begin
            inst_type = R_INST;
            composed_immediate = 'x;
        end
        7'b00?00??: begin
            inst_type = I_INST;
            composed_immediate = fe_if.instruction.i_type.imm;
        end
        7'b11?01??: begin
            inst_type = I_INST;
            composed_immediate = fe_if.instruction.i_type.imm;
        end
        7'b01000??: begin
            inst_type = S_INST;
            composed_immediate = {fe_if.instruction.s_type.imm_11_5, fe_if.instruction.s_type.imm_4_0};
        end
        7'b11000??: begin
            inst_type = B_INST;
            is_branch_inst = 1'b1;
            composed_immediate = {
                fe_if.instruction.b_type.imm_12,
                fe_if.instruction.b_type.imm_11,
                fe_if.instruction.b_type.imm_10_5,
                fe_if.instruction.b_type.imm_4_1,
                1'b0
            };
        end
        7'b0?101??: begin
            inst_type = U_INST;
            composed_immediate = {
                fe_if.instruction.u_type.imm_31_12,
                12'b0
            };
        end
        7'b11011??: begin
            inst_type = J_INST;
            composed_immediate = {
                fe_if.instruction.j_type.imm_20,
                fe_if.instruction.j_type.imm_19_12,
                fe_if.instruction.j_type.imm_11,
                fe_if.instruction.j_type.imm_10_1,
                1'b0
            };
        end
        default: begin
            inst_type = INST_UNDEFINED;
            composed_immediate = 'x;
            is_branch_inst = 'x;
        end
        endcase
    end

    always_ff @(posedge clk) begin
        ex_if.rs1_word <= rs1_word;
        ex_if.rs2_word <= rs2_word;
        ex_if.next_pc <= fe_if.next_pc;
        ex_if.instruction <= fe_if.instruction;
        ex_if.immediate <= composed_immediate;
        ex_if.branch_alu_operation <= branch_alu_operation;
        ex_if.a_use_pc <= a_use_pc;
        ex_if.b_use_imm <= b_use_imm;
        ex_if.is_branch_inst <= is_branch_inst;
    end

endmodule
