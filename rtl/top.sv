module top #(
    parameter LINE_SIZE = 32,
    parameter ICACHE_SIZE = 1024,
    parameter ICACHE_ASSOC = 1,
    parameter DCACHE_SIZE = 1024,
    parameter DCACHE_ASSOC = 1,
    parameter L2_SIZE = 4096,
    parameter L2_ASSOC = 4,
    parameter XLEN = 32
) (
    input logic clk,
    reset_if rst_if,
    memory_if.requester hmem_if
);

    memory_if icache_req_if(clk);
    memory_if dcache_req_if(clk);

    cache_performance_if icache_perf_if(clk);
    cache_performance_if dcache_perf_if(clk);
    cache_performance_if l2cache_perf_if(clk);

    pipeline pipeline(
        .clk(clk),
        .rst_if(rst_if),
        .icache_if(icache_req_if),
        .dcache_if(dcache_req_if)
    );

    memory_system #(
        .XLEN(XLEN),
        .LINE_SIZE(LINE_SIZE),

        .ICACHE_SIZE(ICACHE_SIZE),
        .ICACHE_ASSOC(ICACHE_ASSOC),

        .DCACHE_SIZE(DCACHE_SIZE),
        .DCACHE_ASSOC(DCACHE_ASSOC),

        .L2_SIZE(L2_SIZE),
        .L2_ASSOC(L2_ASSOC)
    ) l1_l2_cache (
        .clk(clk),
        .rst_if(rst_if),
        .icache_req_if(icache_req_if),
        .dcache_req_if(dcache_req_if),
        .hmem_if(hmem_if),
        .icache_perf_if(icache_perf_if),
        .dcache_perf_if(dcache_perf_if),
        .l2_perf_if(l2cache_perf_if)
    );
endmodule