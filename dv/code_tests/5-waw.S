.section .text
.globl main

main:
    addi sp, sp, -4
    li   t1, 0x10000000
    li   t2, 15
    sw   t1, 0(sp)
loop:
    addi t2, t2, -1
    beq  t2, x0, end_loop
    add  t0, t0, 1
    lw   t0, 0(sp)
    add  t0, t0, 1
    lw   t0, 0(sp)
    j    loop
end_loop:
    addi sp, sp, 4
    ret
