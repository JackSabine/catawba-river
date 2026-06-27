.section .text
.globl main

# Test: MRET returns from a trap handler back to the instruction after ECALL.
# Expected after run:
#   a0 = 0xCAFECAFE  (set after mret returns, proving mret redirected correctly)
#   a1 = 11           (mcause for M-mode ECALL, read in handler)
#   a2 = 0            (confirms the post-mret fall-through path ran, not the dead path)

main:
    # Install trap handler
    la      t0, trap_handler
    csrw    mtvec, t0

    # Poison sentinels
    li      a0, 0xDEAD
    li      a2, 0xBAD2      # should be overwritten to 0 after mret

    ecall                   # triggers trap; mret should return here+4

    # --- mret lands here (ecall PC + 4) ---
    li      a0, 0xCAFECAFE  # sentinel: mret returned to correct PC
    li      a2, 0           # clear a2 to confirm post-mret path
    j       done

    # --- should NOT execute ---
    li      a0, 0xBAD1
    j       done

trap_handler:
    csrr    a1, mcause      # should = 11 (ECALL from M-mode)
    csrr    t1, mepc        # mepc points to the ecall instruction
    addi    t1, t1, 4       # advance past ecall so mret returns to next insn
    csrw    mepc, t1
    mret                    # return; restores MIE from MPIE

done:
    ret                     # returns to bootloader halt via ra
