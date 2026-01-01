OUTPUT_ARCH("riscv")

ENTRY(_bootloader)

SECTIONS
{
    . = 0x80000000;
    .text : ALIGN(4K)
    {
        *(.text)
        *(.text.init)
    }

    .data : ALIGN(4K)
    {
        *(.data)
    }

    .stack : ALIGN(4K)
    {
        _estack = .;
        . += 128K;
        _sstack = .;
    }

    .fromhost : ALIGN(4K)
    {
        *(.fromhost)
    }

}
