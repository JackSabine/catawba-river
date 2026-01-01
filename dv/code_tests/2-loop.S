.section .text
.globl main

main:
    addi t0, x0, 3
    addi t1, x0, 0

loop:
    addi t1, t1, 7
    addi t0, t0, -1
    bne t0, x0, loop
    ret
