.section .bootloader

.globl _bootloader

_bootloader:
        auipc   t0, 0x0
        addi    a1, t0, 32
        addi    a0, x0, 0
        li      t0, 0x80001000
        jr      t0
