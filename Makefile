# Vivado project makefile
#
# + project/
# | + dv/
# | | + svtb/
# | | | * file_list
# | | | * ${project}_pkg.sv
# | | + tests/
# | | | * file_list
# | | | * foo_test.sv
# | + rtl/
# | | * file_list
# | | * foo.sv
# | * Makefile (this file!)
# | * project.sh

.DEFAULT_GOAL := all

ifndef WORKAREA
  $(error You must define the project root by sourcing project.sh)
endif

NPROCS = $(shell grep -c 'processor' /proc/cpuinfo)
MAKEFLAGS += -j$(NPROCS)

####################################################################
# Manual configure

# DPI-C Modules/Filenames
DPIC_SOURCES := get_environment_variable disassemble_rv32i libspike_dpi

# xsim random number generation
RANDOM_NUMBER = $(shell shuf -i 0-4294967296 -n 1)
s = $(RANDOM_NUMBER)

# TB specification
TB_TOP := tb_top

# SUB-IPs to use
SUBIP := torrence-creek

####################################################################
# Output directory configuration
WORK := work
WORKDIR := $(WORKAREA)/$(WORK)

####################################################################
# DPI-C compilation settings
# Currently this is GCC 9.3.0 and modern linux OS contain GCC 13.3.0, which have incompatible GLIBC versions
# We can use xsc to compile the DPI-C files to avoid GLIBC issues
# If a modern GCC is required, you must statically link against libstdc++ and libgcc because xsim cannot dynamically link to versions it doesn't have

CC := xsc

SEARCH := -B/usr/lib/x86_64-linux-gnu
CFLAGS := $(addprefix --gcc_compile_options ",$(addsuffix ",$(INC) $(LIB) $(SEARCH)))

# Auto-generate shared object paths
DPIC_SHARED_OBJECTS := $(addsuffix .so,$(addprefix $(WORKDIR)/,$(DPIC_SOURCES)))

# Auto-generate shared object arg for XELAB
DPIC_SV_LIB_FLAGS := $(addprefix -sv_lib ,$(DPIC_SOURCES))

####################################################################
# HDL compilation/elaboration/simulation settings

# UVM flags
UVM_XVLOG_FLAGS := -L uvm
UVM_XELAB_FLAGS := -L uvm

# Other/non-UVM flags
XVLOG_FLAGS := --sv --incr --include ${WORKAREA}/dv/svtb --include ${WORKAREA}/dv/tests --include ${WORKAREA}/dv/probe $(addprefix --include ,$(foreach sip,$(SUBIP),${WORKAREA}/subip/$(sip)/dv/svtb))
XELAB_FLAGS := --timescale=1ns/1ns --override_timeprecision $(DPIC_SV_LIB_FLAGS)

COMPILE_LIST += $(foreach sip,$(SUBIP),$(addprefix ${WORKAREA}/subip/$(sip)/,$(shell cat ${WORKAREA}/subip/$(sip)/filelists/rtl.f)))
COMPILE_LIST += $(addprefix ${WORKAREA}/,$(shell cat ${WORKAREA}/filelists/rtl.f))
COMPILE_LIST += $(addprefix ${WORKAREA}/,$(shell cat ${WORKAREA}/filelists/dv.f))

HDL_SENSITIVITY_LIST := $(shell find ${WORKAREA}/ -type f \( -name "*.sv" -o -name "*.svh" -o -name "*.mk" \))

ASM_OBJECTS := $(addprefix ${WORKDIR}/,$(patsubst %.S, %.elf, $(shell find ${WORKAREA}/dv/code_tests -type f \( -name "*.S" \) -printf "%f\n")))
C_OBJECTS := $(addprefix ${WORKDIR}/,$(patsubst %.c, %.elf, $(shell find ${WORKAREA}/dv/code_tests -type f \( -name "*.c" \) -printf "%f\n")))
TEST_OBJECTS := $(ASM_OBJECTS) $(C_OBJECTS)
TEST_TXTS := $(patsubst %.elf, %.txt, $(TEST_OBJECTS))


####################################################################
# Vivado output/rule aliases
XVLOG_WORK_FILE = $(WORKDIR)/xsim.dir/$(WORK)/$(WORK).rlx
XSIM_BINARY = $(WORKDIR)/xsim.dir/$(TB_TOP)_snapshot/xsimk

ASM_COMPILE_WORK_FILE = $(WORKDIR)/asm-complete

####################################################################
# Spike
SPIKE_SUBIP = ${WORKAREA}/subip/riscv-isa-sim-dpi
SPIKE_BUILDDIR = $(SPIKE_SUBIP)/build
SPIKE_DPIDIR = $(SPIKE_SUBIP)/dpi
SPIKE_BIN = $(SPIKE_BUILDDIR)/spike

####################################################################
# Rules

$(SPIKE_BUILDDIR):
	@mkdir $@

$(SPIKE_BIN): | $(SPIKE_BUILDDIR)
	cd $(SPIKE_BUILDDIR) && ../configure --prefix=$(RISCV) && $(MAKE)

$(SPIKE_DPIDIR)/libspike_dpi.so: $(SPIKE_BIN)
	cd $(SPIKE_DPIDIR) && $(MAKE) all

.PHONY: spike
spike: $(SPIKE_DPIDIR)/libspike_dpi.so
	@echo "----- Spike compilation complete -----"

$(WORKDIR)/libspike_dpi.so: $(SPIKE_DPIDIR)/libspike_dpi.so | $(WORKDIR)
	@ln -s $< $@

$(WORKDIR)/%.so: $(DV_DPI_C)/%.c | $(WORKDIR)
	cd $(WORKDIR) && $(CC) $< -o $@ $(CFLAGS)

$(WORKDIR)/%.elf: ${WORKAREA}/dv/code_tests/%.S | $(WORKDIR)
	${RISCV}/bin/riscv64-unknown-elf-gcc -nostdlib -o $@ -T ${WORKAREA}/dv/gcc/link.ld ${WORKAREA}/dv/gcc/bootloader.S $< -march=rv32i_zicsr -mabi=ilp32 -O0

$(WORKDIR)/%.elf: ${WORKAREA}/dv/code_tests/%.c | $(WORKDIR)
	${RISCV}/bin/riscv64-unknown-elf-gcc -nostdlib -o $@ -T ${WORKAREA}/dv/gcc/link.ld ${WORKAREA}/dv/gcc/bootloader.S $< -march=rv32i_zicsr -mabi=ilp32 -O0

.PHONY: elf
elf: $(TEST_OBJECTS)
	@echo "----- Assembly compilation complete -----"

$(WORKDIR)/%.txt: $(WORKDIR)/%.elf | $(WORKDIR)
	@${WORKAREA}/scripts/disassemble_elf.py $< $@

.PHONY: memory_maps
memory_maps: $(TEST_TXTS)
	@echo "----- Memory map generation complete -----"

$(WORKDIR)/csr_core.sv: ${WORKAREA}/rtl/csr.csv ${WORKAREA}/scripts/gen_csr.py | $(WORKDIR)
	${WORKAREA}/scripts/gen_csr.py

$(XVLOG_WORK_FILE): $(HDL_SENSITIVITY_LIST) $(WORKDIR)/csr_core.sv | $(WORKDIR)
	@echo "----- Compiling HDL -----"
	cd $(WORKDIR) && xvlog $(UVM_XVLOG_FLAGS) $(COMPILE_LIST) $(XVLOG_FLAGS)

$(XSIM_BINARY): $(DPIC_SHARED_OBJECTS) $(XVLOG_WORK_FILE)
	@echo "----- Elaborating HDL -----"
	cd $(WORKDIR) && xelab -top $(TB_TOP) -snapshot $(TB_TOP)_snapshot -debug all $(UVM_XELAB_FLAGS) $(XELAB_FLAGS)

.PHONY: all
all: $(XSIM_BINARY) $(TEST_TXTS)
	@echo "----- Compilation complete -----"

$(WORKDIR):
	@mkdir $@

####################################################################
# Standalone unit tests (dv/unit_tests/*_tb.sv): small assert-based
# self-checks compiled/run directly with xvlog/xelab/xsim, independent of
# the full-chip COMPILE_LIST above.

UNIT_TEST_WORKDIR := $(WORKDIR)/unit_tests

.PHONY: test-store_queue
test-store_queue: | $(UNIT_TEST_WORKDIR)
	cd $(UNIT_TEST_WORKDIR) && xvlog --sv \
		${WORKAREA}/subip/torrence-creek/rtl/torrence_params.sv \
		${WORKAREA}/rtl/store_queue.sv \
		${WORKAREA}/dv/unit_tests/store_queue_tb.sv
	cd $(UNIT_TEST_WORKDIR) && xelab store_queue_tb -s store_queue_tb_snapshot
	cd $(UNIT_TEST_WORKDIR) && xsim store_queue_tb_snapshot -R

.PHONY: test-searchable_fifo
test-searchable_fifo: | $(UNIT_TEST_WORKDIR)
	cd $(UNIT_TEST_WORKDIR) && xvlog --sv \
		${WORKAREA}/rtl/common/fifo_ptrs.sv \
		${WORKAREA}/rtl/common/searchable_fifo.sv \
		${WORKAREA}/dv/unit_tests/searchable_fifo_tb.sv
	cd $(UNIT_TEST_WORKDIR) && xelab searchable_fifo_tb -s searchable_fifo_tb_snapshot
	cd $(UNIT_TEST_WORKDIR) && xsim searchable_fifo_tb_snapshot -R

$(UNIT_TEST_WORKDIR):
	@mkdir -p $@

####################################################################
# Synthesis area comparison: searchable_fifo (configured to match
# store_queue's geometry) vs. the hand-written store_queue. Scripts live
# in synth/ (gitignored, not checked in) so this can be re-run later.

SYNTH_PART := xc7a100tcsg324-1

.PHONY: synth-compare
synth-compare:
	vivado -mode batch -nolog -nojournal -source ${WORKAREA}/synth/synth_module.tcl -tclargs \
		generic_fifo_synth_top $(SYNTH_PART) \
		${WORKAREA}/subip/torrence-creek/rtl/torrence_params.sv \
		${WORKAREA}/rtl/common/searchable_fifo.sv \
		${WORKAREA}/synth/generic_fifo_synth_top.sv
	vivado -mode batch -nolog -nojournal -source ${WORKAREA}/synth/synth_module.tcl -tclargs \
		store_queue $(SYNTH_PART) \
		${WORKAREA}/subip/torrence-creek/rtl/torrence_params.sv \
		${WORKAREA}/rtl/store_queue.sv
	@echo "----- searchable_fifo (DEPTH=2, 32b) -----"
	@grep -A20 "Slice Logic$$" $(WORKAREA)/synth/reports/generic_fifo_synth_top.util.rpt
	@echo "----- store_queue -----"
	@grep -A20 "Slice Logic$$" $(WORKAREA)/synth/reports/store_queue.util.rpt

.PHONY: clean
clean:
	@rm -rf $(WORKDIR)

.PHONY: cleanspike
cleanspike:
	@rm -rf $(SPIKE_BUILDDIR)
	@rm -f $(SPIKE_DPIDIR)/libspike_dpi.a $(SPIKE_DPIDIR)/libspike_dpi.so $(WORKDIR)/libspike_dpi.so

.PHONY: help
help:
	@echo "#### RULES ####"
	@echo "* all - compile with xvlog and xelab"
	@echo "* test-store_queue - compile and run dv/unit_tests/store_queue_tb.sv"
	@echo "* test-searchable_fifo - compile and run dv/unit_tests/searchable_fifo_tb.sv"
	@echo "* synth-compare - synthesize searchable_fifo vs store_queue and diff utilization (synth/, gitignored)"
