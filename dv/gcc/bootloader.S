.section .text
.globl _bootloader

_bootloader:
        li      ra, 0
        la      sp, _sstack
        la      gp, _estack
        li      tp, 0
        la      fp, _sstack
        auipc   t0, 0x0
        addi    a1, t0, 32
        addi    a0, x0, 0
        la      t0, main
        jalr    t0
        1: j 1b