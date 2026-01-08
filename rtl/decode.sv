module decode import catawba_params::*; #(
    parameter XLEN = 32
) (
    input logic clk,
    reset_if rst_if,

    fetch_decode_if.de fe_if,
    decode_execute_if.de ex_if,
    writeback_decode_if.de wb_if
);

    function void r_type_inst(output instruction_kind_t instruction_kind, output logic [XLEN-1:0] composed_immediate);
        instruction_kind = R_INST;
        composed_immediate = 'x;
    endfunction

    function void i_type_inst(output instruction_kind_t instruction_kind, output logic [XLEN-1:0] composed_immediate);
        instruction_kind = I_INST;
        composed_immediate = {{21{fe_if.instruction[31]}}, fe_if.instruction[30:20]};
    endfunction

    function void s_type_inst(output instruction_kind_t instruction_kind, output logic [XLEN-1:0] composed_immediate);
        instruction_kind = S_INST;
        composed_immediate = {{21{fe_if.instruction[31]}}, fe_if.instruction[30:25], fe_if.instruction[11:8], fe_if.instruction[7]};
    endfunction

    function void b_type_inst(output instruction_kind_t instruction_kind, output logic [XLEN-1:0] composed_immediate);
        instruction_kind = B_INST;
        composed_immediate = {{20{fe_if.instruction[31]}}, fe_if.instruction[7], fe_if.instruction[30:25], fe_if.instruction[11:8], 1'b0};
    endfunction

    function void u_type_inst(output instruction_kind_t instruction_kind, output logic [XLEN-1:0] composed_immediate);
        instruction_kind = U_INST;
        composed_immediate = {fe_if.instruction[31:12], 12'b0};
    endfunction

    function void j_type_inst(output instruction_kind_t instruction_kind, output logic [XLEN-1:0] composed_immediate);
        instruction_kind = J_INST;
        composed_immediate = {{12{fe_if.instruction[31]}}, fe_if.instruction[19:12], fe_if.instruction[20], fe_if.instruction[30:21], 1'b0};
    endfunction

    function void invalid_inst(output instruction_kind_t instruction_kind, output logic [XLEN-1:0] composed_immediate);
        instruction_kind = INST_UNDEFINED;
        composed_immediate = 'x;
    endfunction

    logic [`REG_BITS-1:0] rs1_index, rs2_index, de_rd_index, wb_rd_index;
    logic [XLEN-1:0] rs1_word, rs2_word;

    logic [XLEN-1:0] composed_immediate;
    logic a_use_pc_or_zero;
    logic b_use_imm;

    logic funct7_alu_control;
    alu_operation_e alu_operation;

    branch_alu_operation_e branch_alu_operation;

    instruction_kind_t instruction_kind;
    logic is_math_insn;
    logic is_branch_insn;
    logic is_jump_insn;
    logic is_mem_insn;
    logic is_lui_insn;

    logic is_csr_insn;
    logic is_csr_insn_with_uimm;
    logic rd_is_x0;
    logic rs_is_x0;

    logic scoreboard_stall;

    logic local_stall_request;
    logic propagate_upstream_data;

    logic [XLEN-1:0] operand_a, operand_b;

    assign rs1_index = fe_if.instruction.rs1;
    assign rs2_index = fe_if.instruction.rs2;
    assign de_rd_index = fe_if.instruction.rd;
    assign wb_rd_index = wb_if.rd;

    register_file regfile (
        .clk(clk),
        .read_port_select_1(rs1_index),
        .read_port_select_2(rs2_index),
        .write_port_select(wb_rd_index),
        .write_port_data(wb_if.result),

        .read_port_data_1(rs1_word),
        .read_port_data_2(rs2_word)
    );

    register_scoreboard regscoreboard (
        .clk(clk),
        .rst_if(rst_if),

        .de_valid(fe_if.valid),

        .de_instruction_kind(instruction_kind),
        .de_read_port_select_1(rs1_index),
        .de_read_port_select_2(rs2_index),
        .de_write_port_select(de_rd_index),

        .wb_write_port_select(wb_rd_index),

        .block_ready_bit_clear(ex_if.stall_upstream),

        .stall(scoreboard_stall)
    );

    always_comb begin
        a_use_pc_or_zero = fe_if.instruction.opcode[6:2] inside {
            5'b11000, // branch
            5'b11011, // jal
            5'b01101, // lui
            5'b00101  // auipc
        };
        b_use_imm = (instruction_kind != R_INST);

        funct7_alu_control = 1'b0;
        casez (instruction_kind)
            R_INST: funct7_alu_control = fe_if.instruction.funct7[5];
            I_INST: funct7_alu_control = (alu_operation_e'(fe_if.instruction.funct3) == SRA) ? fe_if.instruction.funct7[5] : 1'b0;
            default: funct7_alu_control = 1'b0;
        endcase
    end

    assign alu_operation = is_math_insn ? alu_operation_e'({funct7_alu_control, fe_if.instruction.funct3}) : ADD;
    assign branch_alu_operation = branch_alu_operation_e'(fe_if.instruction.funct3);

    always_comb begin
        if (a_use_pc_or_zero) begin
            if (is_lui_insn) begin
                operand_a = '0;
            end else begin
                operand_a = fe_if.pc;
            end
        end else begin
            if (is_csr_insn_with_uimm) begin
                // For CSR instructions with immediate, operand A is zext(rs1)
                operand_a = {27'b0, fe_if.instruction.rs1};
            end else begin
                operand_a = rs1_word;
            end
        end
        operand_b = b_use_imm ? composed_immediate : rs2_word;
    end


    assign is_math_insn = (fe_if.instruction.opcode =?= 7'b0?10011);
    assign is_branch_insn = (instruction_kind == B_INST);
    assign is_jump_insn = (fe_if.instruction.opcode =?= 7'b110z111);
    assign is_mem_insn = (fe_if.instruction.opcode =?= 7'b0z00011);
    assign is_lui_insn = (fe_if.instruction.opcode == 7'b0110111);
    assign is_csr_insn = (fe_if.instruction.opcode == 7'b1110011) &
                         (fe_if.instruction.funct3 != 3'b000); // Exclude ecall/ebreak
    assign is_csr_insn_with_uimm = is_csr_insn & (fe_if.instruction.funct3[2] == 1'b1); // CSRxI instructions
    assign rd_is_x0 = (fe_if.instruction.rd  == '0);
    assign rs_is_x0 = (fe_if.instruction.rs1 == '0);

    always_comb begin
        unique casez (fe_if.instruction.opcode)
            7'b0110011: r_type_inst(instruction_kind, composed_immediate); // R-type
            7'b0010011: i_type_inst(instruction_kind, composed_immediate); // I-type ALU
            7'b0000011: i_type_inst(instruction_kind, composed_immediate); // I-type load
            7'b1100111: i_type_inst(instruction_kind, composed_immediate); // I-type jalr
            7'b0100011: s_type_inst(instruction_kind, composed_immediate); // S-type store
            7'b1100011: b_type_inst(instruction_kind, composed_immediate); // B-type branch
            7'b0110111: u_type_inst(instruction_kind, composed_immediate); // U-type lui
            7'b0010111: u_type_inst(instruction_kind, composed_immediate); // U-type auipc
            7'b1101111: j_type_inst(instruction_kind, composed_immediate); // J-type jal
            7'b1110011: i_type_inst(instruction_kind, composed_immediate); // I-type system (CSR, ecall, ebreak)
            default:    invalid_inst(instruction_kind, composed_immediate);
        endcase
    end

    advance_control advance_ctrl (
        .clk(clk),
        .rst_if(rst_if),
        .upstream_valid(fe_if.valid),
        .local_stall_request(local_stall_request),
        .downstream_stall_request(ex_if.stall_upstream),
        .upstream_halt(fe_if.halt),

        .propagate_upstream_data(propagate_upstream_data),
        .downstream_valid(ex_if.valid),
        .downstream_halt(ex_if.halt),
        .request_upstream_stall(fe_if.stall_upstream)
    );

    always_ff @(posedge clk) begin
        if (propagate_upstream_data) begin
            ex_if.rs1_word <= rs1_word;
            ex_if.rs2_word <= rs2_word;
            ex_if.pc <= fe_if.pc;
            ex_if.pc_plus_4 <= fe_if.pc_plus_4;
            ex_if.instruction <= fe_if.instruction;
            ex_if.instruction_kind <= instruction_kind;
            ex_if.is_branch_insn <= is_branch_insn;
            ex_if.is_jump_insn <= is_jump_insn;
            ex_if.is_mem_insn <= is_mem_insn;
            ex_if.alu_operation <= alu_operation;
            ex_if.branch_alu_operation <= branch_alu_operation;
            ex_if.operand_a <= operand_a;
            ex_if.operand_b <= operand_b;
            ex_if.rd_is_x0 <= rd_is_x0;
            ex_if.rs_is_x0 <= rs_is_x0;
            ex_if.is_csr_insn <= is_csr_insn;
        end
    end

    assign local_stall_request = scoreboard_stall;
endmodule
