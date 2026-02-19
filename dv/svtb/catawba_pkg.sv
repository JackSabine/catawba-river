`include "uvm_macros.svh"
`include "catawba_macros.svh"

package catawba_pkg;
    import uvm_pkg::*;
    import catawba_types::*;
    import catawba_params::*;
    import torrence_params::*;

    `include "dpi-c.sv"
    `include "../common/randomizable_2d_array.sv"

    `include "../seq/reset_transaction.sv"
    `include "../seq/pipe_state_transaction.sv"

    `include "../model/memory_model/files.sv"
    `include "../configs/clock_config.sv"

    `include "../seq/reset_seq.sv"

    `include "../agents/reset_agent/reset_sequencer.sv"
    `include "../agents/reset_agent/reset_driver.sv"
    `include "../agents/reset_agent/reset_agent.sv"

    `include "../agents/commit_agent/commit_monitor.sv"
    `include "../agents/commit_agent/commit_agent.sv"

    `include "scoreboard.sv"
    `include "environment.sv"

    `include "tests.sv"
endpackage
