.section .text
.globl main

# Test: EBREAK causes a synchronous trap to mtvec.
# Expected after run:
#   a0 = 0xBEEFBEEF  (set in handler, proving trap was taken)
#   a1 = 3            (mcause for EBREAK)
#   a2 = address of the ebreak instruction (mepc)

main:
    # Install trap handler
    la      t0, trap_handler
    csrw    mtvec, t0

    # Poison sentinel: if trap doesn't redirect, a0 stays 0xDEAD
    li      a0, 0xDEAD

    ebreak                  # triggers trap; instruction after this is squashed

    # --- should NOT execute if trap works ---
    li      a0, 0xBAD1
    j       done

trap_handler:
    csrr    a1, mcause      # should = 3 (EBREAK)
    csrr    a2, mepc        # should = address of ebreak above
    li      a0, 0xBEEFBEEF # sentinel: trap was taken

done:
    ret                     # returns to bootloader halt via ra
