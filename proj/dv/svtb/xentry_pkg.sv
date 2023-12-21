package xentry_pkg;
    typedef enum logic[1:0] {BYTE = 2'b01, HALF = 2'b00, WORD = 2'b10} Mem_OpSize_e;

    typedef enum logic[3:0] {
        ADD = 4'b0000,
        SUB,
        XOR,
        OR,
        AND,
        SHIFT_LEFT,
        SHIFT_RIGHT,
        SHIFT_RIGHT_ARITHMETIC,
        SET_LESS_THAN,
        SET_LESS_THAN_UNSIGNED
    } alu_operation_e;

    typedef enum logic [2:0] {
        EQUAL = 3'b000,
        NOT_EQUAL,
        LESS_THAN,
        GREATER_THAN_OR_EQUAL,
        LESS_THAN_UNSIGNED,
        GREATER_THAN_OR_EQUAL_UNSIGNED
    } branch_alu_operation_e;

endpackage: xentry_pkg