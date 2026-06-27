# Copilot Instructions

## Project Overview

**catawba-river** is a RISC-V RV32I processor implementation in SystemVerilog, verified with a UVM testbench using Spike (the RISC-V ISA simulator) as a reference model. The sub-IP `torrence-creek` (git submodule) provides the `memory_if` interface used by the pipeline.

## Setup

Before running any command, source the project setup script from the repo root:

```bash
source project.sh
```

This sets the required `WORKAREA`, `WORKDIR`, `SCRIPTS_ROOT`, `DV_REGRESSION_LISTS_DIR`, and `RISCV` environment variables, activates the Python venv, and adds `qsim` to `PATH`.

- RISC-V toolchain is expected at `/opt/riscv`
- Python dependencies: `pip install -r requirements.txt` (bitarray, bitstring, riscv-assembler)

## Build, Test, and Simulation Commands

```bash
# Full build (compiles DPI-C .so files, generates csr_core.sv, runs xvlog + xelab)
make

# Clean build artifacts
make clean

# Build Spike DPI library (one-time, needed for scoreboard)
make spike

# Compile all assembly and C test programs to .elf
make elf

# Generate memory map .txt files from .elf files
make memory_maps

# Run a single test
qsim asm_test --plusargs ASM_TEST=0-simple-addi

# Run a regression (reads from dv/regressions/<name>)
qsim level0 -R

# Run with specific seed and verbosity
qsim asm_test --plusargs ASM_TEST=1-read-after-write --seed 12345 --uvm_verbosity UVM_HIGH

# Compile only (no simulation)
qsim asm_test -C

# Force rebuild then run
qsim asm_test --clean --plusargs ASM_TEST=2-loop

# Open waveform viewer for last run (requires Vivado GUI)
waves   # alias set by project.sh
```

`qsim` is a Python script at `scripts/qsim/qsim`. It calls `make`, then invokes `xsim` with the elaborated snapshot.

## Architecture

### RTL Pipeline (`rtl/`)

4-stage in-order pipeline: **Fetch → Decode → Execute → Writeback**

```
icache_if ──► fetch ──fe_de_if──► decode ──de_ex_if──► execute ──ex_wb_if──► writeback
                │                    ▲                    │
                └──fe_ex_if──────────┘                    ▼
                                                      dcache_if
                                    ◄──wb_de_if────── writeback
```

- **`pipeline.sv`** — top-level; instantiates all stages; `hart_curr_privilege` is hardwired to `2'b11` (Machine mode)
- **`rtl/interfaces/`** — all inter-stage bundles; each interface has a `stall_upstream` back-pressure signal
- **`advance_control.sv`** — centralized per-stage stall/flush logic; every stage instantiates one. Inputs: `upstream_valid`, `local_stall_request`, `downstream_stall_request`, `force_downstream_valid_low`. Outputs: `propagate_upstream_data`, `downstream_valid`, `request_upstream_stall`
- **`register_scoreboard.sv`** — one `ready_bit` per register; cleared when decode issues an instruction with `rd`, set when writeback commits. Stalls decode on RAW or WAW hazards
- **`work/csr_core.sv`** — **generated file** (`rtl/csr.csv` → `scripts/gen_csr.py`); never edit directly

**Halt** is `jal x0, 0` (`32'h0000006f`, macro `` `J1b ``). Reset PC is `0x8000_0000` (matches `dv/gcc/link.ld`).

---

### Stage-by-Stage Detail

#### Fetch (`rtl/fetch.sv`)

State machine with three states (`fetch_state_e`):
- `NORMAL_OPERATION` — increment PC each cycle an icache beat is fulfilled; detect halt/branch/jump
- `STALL_ON_JUMP_OR_BRANCH` — freeze PC and wait for execute to resolve the target via `fe_ex_if.jump_or_branch_valid` / `jump_or_branch_next_pc`; asserts `force_downstream_valid_low` on the cycle the redirect arrives to squash the in-flight instruction
- `HALTED` — freeze indefinitely

Fetch always issues a LOAD WORD to icache (`req_valid=1`, `req_size=WORD`). If the cache is not ready, the instruction is `'0` and `upstream_valid` to the downstream advance_control is `0`.

**Currently missing:** No mechanism to redirect fetch to `mtvec` (trap entry) or `mepc` (MRET). Adding this requires a new fetch state or overriding `next_pc` from a trap signal.

#### Decode (`rtl/decode.sv`)

Responsibilities:
- Immediate composition for all six encoding types (functions `r/i/s/b/u/j_type_inst`)
- Opcode → `instruction_kind_t` decode (drives the register scoreboard and writeback write-enable)
- ALU operation selection: for R-type, `{funct7[5], funct3}`; for I-type shift (SRA), same bit; all others default to ADD
- Branch ALU operation = `funct3` directly cast to `branch_alu_operation_e`
- Operand A mux: PC (branches, JAL, AUIPC), zero (LUI), zero-extended rs1 field (CSR-immediate), or rs1_word
- Operand B mux: immediate or rs2_word
- Stall from `register_scoreboard` (RAW/WAW); stall from execute propagated back via `ex_if.stall_upstream`

**ECALL/EBREAK/MRET** all decode as `I_INST` with opcode `7'b1110011` (system). They are not distinguished from CSR instructions in decode — all go to execute as `instruction_kind = I_INST`. Execute only checks `` `IS_CSR_INSN `` (funct3 ≠ 000), so ECALL/EBREAK/MRET (`funct3 == 000`) fall through to the default `ex_result = alu_result` path and are silently discarded.

#### Execute (`rtl/execute.sv`)

Sub-modules instantiated inside execute:
- **`alu`** — operates on `de_if.operand_a` and `de_if.operand_b`; result used for arithmetic, address calculation (JAL/JALR target), LUI/AUIPC
- **`branch_alu`** — operates on raw `rs1_word`/`rs2_word` (not the operand muxes); produces 1-bit branch taken/not-taken
- **`csr_wrapper`** — see CSR section below
- **`memory`** — AGEN (`base + offset`), dcache request, sub-word load extension (LB/LH/LBU/LHU via `funct3[1:0]` for size, `funct3[2]` for sign)

Result mux priority (combinational):
1. JUMP → `pc_plus_4` (link register value)
2. CSR → `csr_read_value`
3. MEM load (if fulfilled) → `memory_loaded_word`
4. Default → `alu_result`

Branch/jump PC feedback to fetch:
- `fe_if.jump_or_branch_valid` = `de_if.valid & (IS_BRANCH | IS_JUMP)`
- `fe_if.jump_or_branch_next_pc` = `alu_result` if branch taken or jump, else `pc_plus_4`

Execute stalls (`local_stall_request`) in two cases:
1. `stall_to_make_csr_op_atomic` — a CSR instruction in execute waits until writeback is empty (`~wb_has_valid_instruction`) to avoid read-modify-write races
2. `memory_busy` — a load/store is waiting for dcache

**Currently missing:** No trap detection. ECALL, EBREAK, illegal instructions, privilege violations, misaligned accesses, and CSR access errors are silently ignored.

#### Writeback (`rtl/writeback.sv`)

Write enable: `ex_if.valid & instruction_kind inside {R_INST, I_INST, J_INST, U_INST}`. S-type (store) and B-type (branch) do not write registers.

The `de_if.rd` port drives register file write select; set to `'0` (x0, which is always 1 and never written) when write is disabled. The `result` port is always `ex_if.ex_result`.

**Currently missing:** No MRET handling.

---

### CSR Subsystem

#### `csr_wrapper.sv`

Decodes access type from `system_op_e` (funct3):
- Privilege check from `req_csr_address[9:8]` vs `hart_curr_privilege`
- Read-only check from `req_csr_address[11:10] == 2'b11`
- Write suppression: CSRRS/CSRRC with rs1=x0 (or uimm=0) suppresses write (spec §2.6)
- Read suppression: CSRRW with rd=x0 suppresses read side effects
- RW/RS/RC operation on `csr_read_value` to produce `value_to_write`
- Exports `csr_mepc` and accepts `csr_mepc_hw_ovrd` / `csr_mepc_hw_ovrd_en` — the override enable is **hardwired to 0** (placeholder for trap entry)

#### `csr.sv` / `csr_core.sv` (generated)

All M-mode CSRs are present in the address space. The following are storage-only (generic `RW_CSR` flip-flops) with no functional behavior wired up:

| CSR | Address | Gap |
|-----|---------|-----|
| `mstatus` | `0x300` | No field-level logic: MIE, MPIE, MPP not driven by hardware; WPRI bits not masked on write |
| `mtvec` | `0x305` | Not connected to fetch redirect |
| `mepc` | `0x341` | HW override port exists but `csr_mepc_hw_ovrd_en = '0` |
| `mcause` | `0x342` | Never written by hardware |
| `mtval` | `0x343` | Never written by hardware |
| `mip` | `0x344` | No interrupt controller connected |
| `mie` | `0x304` | No interrupt logic |
| `mcycle` | `0xB00` | Not counting |
| `minstret` | `0xB02` | Not counting |

`invalid_csr_index` output is **hardwired to `1'b0`** — accessing an undefined CSR silently returns 0 instead of raising an illegal instruction exception.

---

### Implementation Gaps (RV32I + Zicsr)

The following spec-required behaviors are not yet implemented:

#### 1. ~~ECALL / EBREAK~~ ✅ Implemented
- Detected via `IS_TRAP_INSN` macro in fetch (stalls like branch/jump) and execute (fires `take_trap`)
- `take_trap` triggers all four CSR hardware overrides simultaneously: `mepc` ← faulting PC, `mcause` ← 11/3, `mtval` ← 0, `mstatus` fields updated (MPP/MPIE/MIE)
- Fetch redirects to `mtvec` when `take_trap` arrives from execute
- Tests: `dv/code_tests/7-ecall.S`, `dv/code_tests/8-ebreak.S`

#### 2. MRET (Privileged §3.3.2)
- Encoding: `opcode=1110011, funct3=000, rs2=00010, rs1=00000, rd=00000`
- Reaches execute and is discarded
- Requires: restore `mepc` → PC; set `mstatus.MIE = mstatus.MPIE`; set `mstatus.MPIE = 1`; set privilege to `mstatus.MPP`; set `mstatus.MPP = 0` (U-mode, or M-mode if only M supported)

#### 3. Trap Entry Hardware (Privileged §3.1.6, §3.1.7, §3.1.9)
- Required for exceptions and interrupts
- Must: flush fetch/decode/execute pipeline stages; write `mepc` with the faulting PC; write `mcause` with exception code; write `mtval` where applicable; update `mstatus` (save MIE→MPIE, clear MIE, save privilege→MPP); redirect fetch to `mtvec` (direct mode: `mtvec[31:2]<<2`; vectored mode for interrupts: base + 4×cause)

#### 4. `mstatus` Field Logic (Privileged §3.1.6)
- Fields `MIE` [3], `MPIE` [7], `MPP` [12:11] must be driven by hardware on trap entry/return
- WPRI fields must be masked to 0 on write
- `SD` [31] = 0 (no FP/V state for RV32I)

#### 5. Illegal Instruction Exception (Spec §2.8)
- Triggered by: opcode not in the defined set (currently `INST_UNDEFINED` in decode, silently dropped); insufficient CSR privilege (detected in `csr_wrapper` but `underprivileged_hart` is not exported); write to a read-only CSR (detected but not exported); access to undefined CSR (`invalid_csr_index` hardwired to 0)

#### 6. `mcycle` / `minstret` Counters (Spec §10)
- `mcycle`/`mcycleh` must increment every clock cycle
- `minstret`/`minstreth` must increment for every instruction that retires (commits at writeback with `ex_if.valid`)

#### 7. Interrupt Handling (Privileged §3.1.9)
- External, timer, software interrupts gated by `mstatus.MIE` and corresponding `mie` bits
- `mip` bits for pending interrupts must be connected to external interrupt sources

---

### DV Testbench (`dv/`)

UVM testbench structure:

- **`tb_top.sv`** — top module; instantiates DUT (`pipeline`), two `cache_bfm` instances (icache/dcache), clock, reset, and probes
- **`environment.sv`** — UVM env; contains `reset_agent`, `commit_agent`, and `scoreboard`
- **`scoreboard.sv`** — co-simulates Spike step-by-step via DPI-C; compares register file and data memory state after each committed instruction
- **`dv/agents/commit_agent/`** — monitors pipeline commit events, produces `pipe_state_transaction`
- **`dv/model/cache_bfm/`** — BFM that backs the memory interface; the `main_memory` object is shared between `cache_bfm` and `scoreboard`
- **`dv/probe/`** — probe interface and signal assignments for visibility into internal pipeline state

### Test Programs (`dv/code_tests/`)

Assembly (`.S`) and C (`.c`) programs compiled with `riscv64-unknown-elf-gcc` using `-march=rv32i_zicsr -mabi=ilp32 -O0`. The bootloader (`dv/gcc/bootloader.S`) and linker script (`dv/gcc/link.ld`) are prepended to every test. Programs must end with `jal x0, 0` (halt).

Compiled artifacts go to `work/` (`.elf` binaries, `.txt` memory maps).

### Regression Lists (`dv/regressions/`)

Plain text files, one test per line:
```
asm_test --plusargs ASM_TEST=<name>
```

## Key Conventions

### File Lists Control Compilation Order

`filelists/rtl.f` and `filelists/dv.f` explicitly list every file in compilation order. When adding a new RTL or DV file, add it to the appropriate filelist.

### CSR Definition Flow

CSRs are defined in `rtl/csr.csv`. Run `make` (or `scripts/gen_csr.py` directly) to regenerate `work/csr_core.sv`. The macros `` `RO_CSR `` and `` `RW_CSR `` (from `catawba_macros.svh`) are used inside the generated file. When a CSR needs hardware-driven writes (e.g., mepc on trap entry), add it to `csr.csv` with `Export from Module = Y` and connect the exported signal in `csr_wrapper.sv`.

### Instruction Encoding

The packed struct `instruction_t` (in `catawba_params.sv`) maps directly to RV32I encoding. Opcode pattern matching uses `` `IS_*_INSN(insn) `` macros with `=?=` (wildcard equality) for don't-care bits.

### Distinguishing ECALL / EBREAK / MRET / WFI from CSR Instructions

All system instructions share opcode `7'b1110011`. The decode module treats them all as `I_INST`. The distinguishing field is `funct3`:
- `3'b000` → ECALL/EBREAK/MRET/WFI (currently unhandled)
- `3'b001`–`3'b111` → CSR instructions (handled by `csr_wrapper`)

Within `funct3==000`, the `rs2` field (bits [24:20]) distinguishes: `00000`=ECALL, `00001`=EBREAK, `00010`=MRET, `00101`=WFI.

### UVM Config DB Pattern

Interfaces and shared objects are passed through `uvm_config_db` in `tb_top.sv`; components retrieve them in `build_phase` with a fatal assertion on failure.

### Spike DPI-C Integration

The scoreboard calls `spike_create`, `spike_step`, `spike_get_all_gprs`, and `spike_read_mem_word` — functions exposed by `subip/riscv-isa-sim-dpi/dpi/libspike_dpi.so`. This library must be built once with `make spike`.

### Submodules

- `subip/torrence-creek` — provides `memory_if` used by pipeline and cache BFM; also has its own `filelists/rtl.f`
- `subip/riscv-isa-sim-dpi` — Spike fork with DPI-C bindings

Run `git submodule update --init --recursive` after cloning.
