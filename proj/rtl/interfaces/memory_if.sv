interface memory_if import catawba_types::*; #(
    parameter XLEN = 32
) (
    input bit clk
);
    logic [XLEN-1:0] req_address;
    memory_operation_e req_operation;
    memory_operation_size_e req_size;
    logic [XLEN-1:0] req_store_word;
    logic req_valid;

    logic [XLEN-1:0] req_loaded_word;
    logic req_fulfilled;

    modport requester (
        input req_loaded_word, req_fulfilled,
        output req_address, req_operation, req_size, req_store_word, req_valid
    );

    modport server (
        input req_address, req_operation, req_size, req_store_word, req_valid,
        output req_loaded_word, req_fulfilled
    );
endinterface
