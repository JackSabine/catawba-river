.section .text
.globl main

main:
    li t0, 15
    sw t0, 0(sp)
    lw t0, 0(sp)
    ret
