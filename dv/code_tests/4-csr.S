.section .text
.globl main

main:
    csrr t0, mhartid
    csrwi mscratch, 0x1A
    li t1, 0xAAAAAAAA
    csrrs t2, mscratch, t1
    csrrc t3, mscratch, t1
    ret
