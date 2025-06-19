
interface execute_memory_if #(parameter XLEN = 32);
    import catawba_types::*;

    logic valid;

    logic [XLEN-1:0] alu_result;
    logic [XLEN-1:0] rs2_word;

    logic [XLEN-1:0] instruction;

    modport ex(
        output
            valid,
            alu_result,
            rs2_word,
            instruction
    );
              
    modport mem(
        input
            valid,
            alu_result,
            rs2_word,
            instruction
    );
endinterface
