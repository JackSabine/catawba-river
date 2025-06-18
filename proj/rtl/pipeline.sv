module pipeline (
    input logic clk,

    reset_if rst_if,

    pipe_icache_if.pipe icache_if
);

fetch_decode_if fe_de_if();
fetch_execute_if fe_ex_if();
decode_execute_if de_ex_if();
execute_memory_if ex_mem_if();

fetch fe (
    .clk(clk),
    .rst_if(rst_if),
    .de_if(fe_de_if),
    .ex_if(fe_ex_if),
    .icache_if(icache_if)
);

decode de (
    .clk(clk),
    .fe_if(fe_de_if),
    .ex_if(de_ex_if)
);

execute ex (
    .clk(clk),
    .de_if(de_ex_if),
    .fe_if(fe_ex_if),
    .mem_if(ex_mem_if)
);

endmodule
