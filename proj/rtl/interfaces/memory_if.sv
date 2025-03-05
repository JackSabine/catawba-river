
`include "macros.svh"

interface memory_if;
    import catawba_types::*;

    // Input to memory stage
    logic [`WORD-1:0]       next_pc;
    logic [`WORD-1:0]       mem_addr;
    logic [`WORD-1:0]       immediate;
    Mem_OpSize_e            opsize;
    logic                   read_enable;
    logic                   write_enable;
    logic                   signed_read;

    // Output from memory stage
    logic [`WORD-1:0]       memory_writeback;
    logic [`WORD-1:0]       immediate_writeback;
    logic                   misaligned_access_exception;

    // Memory IP nets
    logic [3:0]             memip_write_enable;
    logic                   memip_read_enable;
    logic [`WORD-1:0]       memip_addr;
    logic [`WORD-1:0]       memip_write_data;
    logic [`WORD-1:0]       memip_read_data;
    
    modport tb(
        // Signals from execute stage
        output next_pc, mem_addr, immediate, opsize, read_enable, write_enable, signed_read,
        // Signals to writeback stage
        input memory_writeback, immediate_writeback,

        // Signals to top level module
        output misaligned_access_exception,

        // Signals to memory IP
        input memip_write_enable, memip_read_enable, memip_addr, memip_write_data,
        // Signals from memory IP
        output memip_read_data
    );
              
    modport dut(
        // Signals from execute stage
        input next_pc, mem_addr, immediate, opsize, read_enable, write_enable, signed_read,
        // Signals to writeback stage
        output memory_writeback, immediate_writeback,
        
        // Signals to top level module
        output misaligned_access_exception,

        // Signals to memory IP
        output memip_write_enable, memip_read_enable, memip_addr, memip_write_data,
        // Signals from memory IP
        input memip_read_data
    );

endinterface
