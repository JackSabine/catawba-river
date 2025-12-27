`include "catawba_macros.svh"

package catawba_types;
    typedef int unsigned uint32_t;
    typedef byte unsigned uint8_t;
    typedef longint unsigned uint64_t;
    typedef int int32_t;

    typedef uint32_t memory_t [uint32_t];

    typedef logic [`TB_STRING_NUM_BITS-1:0] tb_string_t;
endpackage
