catawba_probe_if probe_if();

`include "probe_assigns.svh"

initial begin
    uvm_config_db #(virtual catawba_probe_if)::set(
        .cntxt(null),
        .inst_name("uvm_test_top.*"),
        .field_name("probe_if"),
        .value(probe_if)
    );
end
