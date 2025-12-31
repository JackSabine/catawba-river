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
	${RISCV}/bin/riscv64-unknown-elf-gcc -nostdlib -o $@ -T ${WORKAREA}/dv/gcc/link.ld $< ${WORKAREA}/dv/gcc/bootloader.S -march=rv32i -mabi=ilp32 -O0

$(WORKDIR)/%.elf: ${WORKAREA}/dv/code_tests/%.c | $(WORKDIR)
	${RISCV}/bin/riscv64-unknown-elf-gcc -nostdlib -o $@ -T ${WORKAREA}/dv/gcc/link.ld $< ${WORKAREA}/dv/gcc/bootloader.S -march=rv32i -mabi=ilp32 -O0

.PHONY: elf
elf: $(TEST_OBJECTS)
	@echo "----- Assembly compilation complete -----"

$(WORKDIR)/memory_maps.sv: $(TEST_OBJECTS)
	${WORKAREA}/scripts/disassemble_elf.py $(WORKDIR) $(WORKDIR)/memory_maps.sv

$(XVLOG_WORK_FILE): $(HDL_SENSITIVITY_LIST) | $(WORKDIR)
	@echo "----- Compiling HDL -----"
	cd $(WORKDIR) && xvlog $(UVM_XVLOG_FLAGS) $(COMPILE_LIST) $(XVLOG_FLAGS)

$(XSIM_BINARY): $(DPIC_SHARED_OBJECTS) $(XVLOG_WORK_FILE) $(WORKDIR)/memory_maps.sv
	@echo "----- Elaborating HDL -----"
	cd $(WORKDIR) && xelab -top $(TB_TOP) -snapshot $(TB_TOP)_snapshot -debug all $(UVM_XELAB_FLAGS) $(XELAB_FLAGS)

.PHONY: all
all: $(XSIM_BINARY)
	@echo "----- Compilation complete -----"

$(WORKDIR):
	@mkdir $@

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
