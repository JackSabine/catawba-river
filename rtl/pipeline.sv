module pipeline (
    input logic clk,

    reset_if rst_if,

    memory_if.requester icache_if,
    memory_if.requester dcache_if
);

fetch_decode_if fe_de_if();
fetch_execute_if fe_ex_if();
decode_execute_if de_ex_if();
execute_memory_if ex_mem_if();
memory_writeback_if mem_wb_if();
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
    .de_if(de_ex_if),
    .fe_if(fe_ex_if),
    .mem_if(ex_mem_if)
);

memory mem (
    .clk(clk),
    .ex_if(ex_mem_if),
    .wb_if(mem_wb_if),
    .dcache_if(dcache_if)
);

writeback wb (
    .clk(clk),
    .mem_if(mem_wb_if),
    .de_if(wb_de_if)
);

endmodule
