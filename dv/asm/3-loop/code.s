addi x1 x0 3
addi x2 x0 0

loop:
    addi x2 x2 7
    addi x1 x1 -1
    bne x1 x0 loop
