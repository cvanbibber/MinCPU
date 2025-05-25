/*
 * Linker script for MinCPU RISC-V processor
 * Defines memory layout and section placement
 */

ENTRY(_start)

MEMORY
{
    /* Instruction memory - starts at 0x1000 (4KB offset) */
    IMEM (rx)  : ORIGIN = 0x00001000, LENGTH = 8K
    
    /* Data memory - starts at 0x10000 */
    DMEM (rw)  : ORIGIN = 0x00010000, LENGTH = 8K
    
    /* Stack memory - top of data memory */
    STACK (rw) : ORIGIN = 0x00011F00, LENGTH = 256
}

SECTIONS
{
    /* Text section - program code */
    .text : {
        *(.text.start)      /* Startup code first */
        *(.text)            /* Main program code */
        *(.text.*)
        . = ALIGN(4);
    } > IMEM
    
    /* Read-only data */
    .rodata : {
        *(.rodata)
        *(.rodata.*)
        . = ALIGN(4);
    } > IMEM
    
    /* Initialized data */
    .data : {
        _data_start = .;
        *(.data)
        *(.data.*)
        . = ALIGN(4);
        _data_end = .;
    } > DMEM AT > IMEM
    
    /* Uninitialized data */
    .bss : {
        _bss_start = .;
        *(.bss)
        *(.bss.*)
        *(COMMON)
        . = ALIGN(4);
        _bss_end = .;
    } > DMEM
    
    /* Stack */
    .stack : {
        . = ALIGN(4);
        _stack_bottom = .;
        . = . + LENGTH(STACK);
        _stack_top = .;
    } > STACK
    
    /* Discard debug sections */
    /DISCARD/ : {
        *(.comment)
        *(.debug*)
    }
}

/* Define stack pointer */
PROVIDE(_sp = _stack_top);

/* Define data copy addresses */
PROVIDE(_data_load_start = LOADADDR(.data));
PROVIDE(_data_load_end = LOADADDR(.data) + SIZEOF(.data)); 