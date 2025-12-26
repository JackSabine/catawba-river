.section .text

.globl _start

_start:
    addi x1, x0, 7
    addi x2, x1, 5

1: j 1b
