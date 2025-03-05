module fetch (
    input logic clk,

    reset_if rst_if,

    fetch_decode_if.fe de_if,
    pipe_icache_if.pipe icache_if
);

logic [`WORD-1:0] pc, next_pc;

assign next_pc = pc + 'd4;

assign icache_if.pc = pc;
assign icache_if.req_valid = 1'b1;

always_ff @(posedge clk) begin
    if (rst_if.reset) begin
        pc <= '0;
        de_if.valid <= 1'b1;
    end else begin
        pc <= next_pc;
        de_if.valid <= icache_if.rsp_valid;
    end

    de_if.instruction = icache_if.instruction;
    de_if.next_pc <= next_pc;
end

endmodule
