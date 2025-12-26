.section .text

.globl _start

_start:
    addi x1, x0, 1
    beq x0, x0, around
    addi x2, x0, 2
around:
    addi x3, x0, 3

1: j 1b
