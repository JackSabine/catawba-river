.section .text
.globl main

# Test: ECALL causes a synchronous trap to mtvec.
# Expected after run:
#   a0 = 0xCAFECAFE  (set in handler, proving trap was taken)
#   a1 = 11           (mcause for M-mode ECALL)
#   a2 = address of the ecall instruction (mepc)

main:
    # Install trap handler
    la      t0, trap_handler
    csrw    mtvec, t0

    # Poison sentinel: if trap doesn't redirect, a0 stays 0xDEAD
    li      a0, 0xDEAD

    ecall                   # triggers trap; instruction after this is squashed

    # --- should NOT execute if trap works ---
    li      a0, 0xBAD1
    j       done

trap_handler:
    csrr    a1, mcause      # should = 11 (ECALL from M-mode)
    csrr    a2, mepc        # should = address of ecall above
    li      a0, 0xCAFECAFE # sentinel: trap was taken

done:
    ret                     # returns to bootloader halt via ra
