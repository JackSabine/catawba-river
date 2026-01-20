module pipeline (
    input logic clk,

    reset_if rst_if,

    memory_if.requester icache_if,
    memory_if.requester dcache_if
);

logic [1:0] hart_curr_privilege;

assign hart_curr_privilege = 2'b11; // Machine mode

fetch_decode_if fe_de_if();
fetch_execute_if fe_ex_if();
decode_execute_if de_ex_if();
execute_writeback_if ex_wb_if();
writeback_decode_if wb_de_if();

fetch fe (
    .clk(clk),
    .rst_if(rst_if),
    .de_if(fe_de_if),
    .ex_if(fe_ex_if),
    .icache_if(icache_if)
);

decode de (
    .clk(clk),
    .rst_if(rst_if),
    .fe_if(fe_de_if),
    .ex_if(de_ex_if),
    .wb_if(wb_de_if)
);

execute ex (
    .clk(clk),
    .rst_if(rst_if),
    .hart_curr_privilege(hart_curr_privilege),
    .wb_has_valid_instruction(ex_wb_if.valid),
    .de_if(de_ex_if),
    .fe_if(fe_ex_if),
    .wb_if(ex_wb_if),
    .dcache_if(dcache_if)
);

writeback wb (
    .clk(clk),
    .ex_if(ex_wb_if),
    .de_if(wb_de_if)
);

reorder_buffer rob (
    .clk(clk),
    .rst(rst_if.reset),
    .dispatch_pc(de_ex_if.pc),
    .dispatch_instruction(de_ex_if.instruction),
    .dispatch_dest_reg(de_ex_if.instruction.rd),
    .push(de_ex_if.valid),
    .pop(wb_de_if.valid),
    .full(),
    .empty(),
    .head_ready(),
    .head_pc(),
    .head_instruction(),
    .head_dest_reg(),
    .head_result(),
    .head_exception()
);


endmodule
