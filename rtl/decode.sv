module decode import catawba_params::*; #(
    parameter XLEN = 32
) (
    input logic clk,
    reset_if rst_if,

    fetch_decode_if.de fe_if,
    decode_execute_if.de ex_if,
    writeback_decode_if.de wb_if
);

    logic [`REG_BITS-1:0] rs1_index, rs2_index;
    logic [XLEN-1:0] rs1_word, rs2_word;

    logic a_use_pc;

    logic [XLEN-1:0] composed_immediate;
    logic b_use_imm;

    alu_operation_e alu_operation;

    branch_alu_operation_e branch_alu_operation;

    instruction_kind_t instruction_kind;
    logic is_mem_inst;

    logic scoreboard_stall;


    assign rs1_index = fe_if.instruction.rs1;
    assign rs2_index = fe_if.instruction.rs2;

    register_file regfile (
        .clk(clk),
        .read_port_select_1(rs1_index),
        .read_port_select_2(rs2_index),
        .write_port_select(wb_if.rd),
        .write_port_data(wb_if.result),
        .write_enable(wb_if.write_to_rd),

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
        .de_write_port_select(fe_if.instruction.rd),

        .wb_write_port_select(wb_if.rd),
        .wb_write_enable(wb_if.write_to_rd),

        .stall(scoreboard_stall)
    );

    always_comb begin
        a_use_pc = fe_if.instruction.opcode[6:2] inside {
            5'b11000, // branch
            5'b11011, // jal
            5'b11001, // jalr
            5'b01101, // lui
            5'b00101  // auipc
        };
        b_use_imm = (instruction_kind != R_INST);
    end

    always_comb begin
        alu_operation = alu_operation_e'({fe_if.instruction.funct7[6], fe_if.instruction.funct3});
        branch_alu_operation = branch_alu_operation_e'(fe_if.instruction.funct3);
    end

    always_comb begin
        is_mem_inst = fe_if.instruction.opcode =?= 7'b0z000zz;

        unique casez (fe_if.instruction.opcode)
        7'b01100??: begin
            instruction_kind = R_INST;
            composed_immediate = 'x;
        end
        7'b00?00??: begin
            instruction_kind = I_INST;
            composed_immediate = {{21{fe_if.instruction[31]}}, fe_if.instruction[30:20]};
        end
        7'b11?01??: begin
            instruction_kind = I_INST;
            composed_immediate = {{21{fe_if.instruction[31]}}, fe_if.instruction[30:20]};
        end
        7'b01000??: begin
            instruction_kind = S_INST;
            composed_immediate = {{21{fe_if.instruction[31]}}, fe_if.instruction[30:25], fe_if.instruction[11:8], fe_if.instruction[7]};
        end
        7'b11000??: begin
            instruction_kind = B_INST;
            composed_immediate = {{20{fe_if.instruction[31]}}, fe_if.instruction[7], fe_if.instruction[30:25], fe_if.instruction[11:8], 1'b0};
        end
        7'b0?101??: begin
            instruction_kind = U_INST;
            composed_immediate = {fe_if.instruction[31:12], 12'b0};
        end
        7'b11011??: begin
            instruction_kind = J_INST;
            composed_immediate = {{12{fe_if.instruction[31]}}, fe_if.instruction[19:12], fe_if.instruction[20], fe_if.instruction[30:21], 1'b0};
        end
        default: begin
            instruction_kind = INST_UNDEFINED;
            composed_immediate = 'x;
        end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst_if.reset) begin
            ex_if.valid <= 1'b0;
            ex_if.halt <= 1'b0;
        end else if (~ex_if.stall_upstream) begin
            ex_if.valid <= fe_if.valid;
            ex_if.halt <= fe_if.halt;
        end

        if (~ex_if.stall_upstream) begin
            ex_if.rs1_word <= rs1_word;
            ex_if.rs2_word <= rs2_word;
            ex_if.next_pc <= fe_if.next_pc;
            ex_if.instruction <= fe_if.instruction;
            ex_if.instruction_kind <= instruction_kind;
            ex_if.is_mem_inst <= is_mem_inst;
            ex_if.immediate <= composed_immediate;
            ex_if.alu_operation <= alu_operation;
            ex_if.branch_alu_operation <= branch_alu_operation;
            ex_if.a_use_pc <= a_use_pc;
            ex_if.b_use_imm <= b_use_imm;
        end
    end

    assign fe_if.stall_upstream = fe_if.valid & (ex_if.stall_upstream | scoreboard_stall);
endmodule
