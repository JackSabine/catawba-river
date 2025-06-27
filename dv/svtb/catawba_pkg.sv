`include "uvm_macros.svh"
`include "catawba_macros.svh"

package catawba_pkg;
    import uvm_pkg::*;
    import catawba_types::*;
    import catawba_params::*;
    import torrence_params::*;

    `include "dpi-c.sv"
    `include "../common/randomizable_2d_array.sv"

    `include "../seq/memory_transaction.sv"
    `include "../seq/reset_transaction.sv"

    `include "../model/memory_model/files.sv"
    `include "../configs/clock_config.sv"

    `include "../seq/memory_response_seq.sv"
    `include "../seq/reset_seq.sv"

    `include "../agents/memory_rsp_agent/memory_rsp_sequencer.sv"
    `include "../agents/memory_rsp_agent/memory_rsp_driver.sv"
    `include "../agents/memory_rsp_agent/memory_rsp_monitor.sv"
    `include "../agents/memory_rsp_agent/memory_rsp_agent.sv"

    `include "../agents/reset_agent/reset_sequencer.sv"
    `include "../agents/reset_agent/reset_driver.sv"
    `include "../agents/reset_agent/reset_agent.sv"

    `include "scoreboard.sv"
    `include "environment.sv"

    `include "tests.sv"
endpackage
