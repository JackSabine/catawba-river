module csr #(
    parameter XLEN = 32
) (
    input logic clk,
    input logic rst,
    input logic [11:0] csr_address,
    input logic read,
    input logic write,
    input logic [XLEN-1:0] value_to_write,
    input logic trigger_read_side_effects,
    output logic [XLEN-1:0] csr_read_value,
    output logic invalid_csr_index
);

logic [4095:0][XLEN-1:0] csr_array;

`RO_CSR(mvendorid,  12'hF11, 32'hBEEF_C0DE)
`RO_CSR(marchid,    12'hF12, 32'h0123_4567)
`RO_CSR(mimpid,     12'hF13, 32'h0000_0001)
`RO_CSR(mhartid,    12'hF14, '0)
`RO_CSR(mconfigptr, 12'hF15, '0) // Not yet implemented

`RW_CSR(mstatus,    12'h300, clk, rst, 0, csr_address, value_to_write) // Needs driver logic
`RW_CSR(mstatush,   12'h310, clk, rst, 0, csr_address, value_to_write) // Needs driver logic
`RW_CSR(misa,       12'h301, clk, rst, 32'h4000_0100, csr_address, value_to_write) // Needs persistent read logic for NotImplemented exception
`RW_CSR(medeleg,    12'h302, clk, rst, 0, csr_address, value_to_write)
`RW_CSR(mideleg,    12'h303, clk, rst, 0, csr_address, value_to_write)
`RW_CSR(mie,        12'h304, clk, rst, 0, csr_address, value_to_write) // No interrupt logic yet
`RW_CSR(mtvec,      12'h305, clk, rst, 0, csr_address, value_to_write) // Traps have nowhere to jump yet
`RW_CSR(medelegh,   12'h312, clk, rst, 0, csr_address, value_to_write)
`RW_CSR(mscratch,   12'h340, clk, rst, 0, csr_address, value_to_write)
`RW_CSR(mepc,       12'h341, clk, rst, 0, csr_address, value_to_write) // No exception logic yet
`RW_CSR(mcause,     12'h342, clk, rst, 0, csr_address, value_to_write) // No handling of exception causes yet
`RW_CSR(mtval,      12'h343, clk, rst, 0, csr_address, value_to_write) // No trap logic yet
`RW_CSR(mip,        12'h344, clk, rst, 0, csr_address, value_to_write) // No interrupt logic yet
`RW_CSR(mtinst,     12'h34A, clk, rst, 0, csr_address, value_to_write)
`RW_CSR(mtval2,     12'h34B, clk, rst, 0, csr_address, value_to_write)

`RW_CSR(menvcfg,    12'h30A, clk, rst, 0, csr_address, value_to_write) // Not implemented
`RW_CSR(menvcfgh,   12'h31A, clk, rst, 0, csr_address, value_to_write)
`RW_CSR(mseccfg,    12'h747, clk, rst, 0, csr_address, value_to_write) // Not implemented
`RW_CSR(mseccfgh,   12'h757, clk, rst, 0, csr_address, value_to_write)

assign csr_read_value = csr_array[csr_address];
assign invalid_csr_index = 1'b0;

endmodule