`include "uvm_macros.svh"
`include "macros.svh"

package catawba_pkg;
    import uvm_pkg::*;
    import catawba_types::*;

    `include "dpi-c.sv"
    `include "../common/randomizable_2d_array.sv"

    `include "../seq/reset_transaction.sv"

    `include "../configs/clock_config.sv"

    `include "../seq/reset_seq.sv"

    `include "../agents/reset_agent/reset_sequencer.sv"
    `include "../agents/reset_agent/reset_driver.sv"
    `include "../agents/reset_agent/reset_agent.sv"

    `include "scoreboard.sv"
    `include "environment.sv"

    `include "tests.sv"
endpackage
