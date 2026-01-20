# Out-of-context synthesis + utilization report for a single RTL module.
# Not part of the build; kept locally to re-run the generic_fifo vs
# store_queue area comparison later. Reports land in synth/reports/.
#
# Usage: vivado -mode batch -source synth_module.tcl \
#            -tclargs <top> <part> <src1> [src2 ...]

set top  [lindex $argv 0]
set part [lindex $argv 1]
set srcs [lrange $argv 2 end]

set report_dir "$::env(WORKAREA)/synth/reports"
file mkdir $report_dir

read_verilog -sv $srcs
synth_design -top $top -part $part -mode out_of_context

report_utilization     -file "$report_dir/${top}.util.rpt"
report_timing_summary  -file "$report_dir/${top}.timing.rpt"
