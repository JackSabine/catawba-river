.section .text

.globl main

main:
    addi x1, x0, 7
    addi x2, x1, 5

1: j 1b
