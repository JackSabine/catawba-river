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
DPIC_SOURCES := get_environment_variable disassemble_rv32i

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

ASM_OBJECTS := $(addprefix ${WORKDIR}/,$(patsubst %.S, %.elf, $(shell find ${WORKAREA}/dv/asm -type f \( -name "*.S" \) -printf "%f\n")))

####################################################################
# Vivado output/rule aliases
XVLOG_WORK_FILE = $(WORKDIR)/xsim.dir/$(WORK)/$(WORK).rlx
XSIM_BINARY = $(WORKDIR)/xsim.dir/$(TB_TOP)_snapshot/xsimk

ASM_COMPILE_WORK_FILE = $(WORKDIR)/asm-complete

####################################################################
# Rules

$(WORKDIR)/%.so: $(DV_DPI_C)/%.c | $(WORKDIR)
	cd $(WORKDIR) && $(CC) $< -o $@ $(CFLAGS)

$(WORKDIR)/%.elf: ${WORKAREA}/dv/asm/%.S | $(WORKDIR)
	${RISCV}/bin/riscv64-unknown-elf-gcc -nostdlib -o $@ -T ${WORKAREA}/dv/asm/complex.ld $<

$(XVLOG_WORK_FILE): $(HDL_SENSITIVITY_LIST) | $(WORKDIR)
	@echo "----- Compiling HDL -----"
	cd $(WORKDIR) && xvlog $(UVM_XVLOG_FLAGS) $(COMPILE_LIST) $(XVLOG_FLAGS)

$(XSIM_BINARY): $(DPIC_SHARED_OBJECTS) $(XVLOG_WORK_FILE)
	@echo "----- Elaborating HDL -----"
	cd $(WORKDIR) && xelab -top $(TB_TOP) -snapshot $(TB_TOP)_snapshot -debug all $(UVM_XELAB_FLAGS) $(XELAB_FLAGS)

.PHONY: all
all: $(XSIM_BINARY) $(ASM_OBJECTS)
	@echo "----- Compilation complete -----"

$(WORKDIR):
	@mkdir $@

.PHONY: clean
clean:
	@rm -rf $(WORKDIR)

.PHONY: help
help:
	@echo "#### RULES ####"
	@echo "* all - compile with xvlog and xelab"
