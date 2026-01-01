.section .text
.globl main

main:
    addi t0, x0, 1
    beq x0, x0, around
    addi t1, x0, 2
around:
    addi t2, x0, 3
    ret
