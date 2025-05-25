/*
 * Startup code for MinCPU RISC-V processor
 * Initializes the processor and calls main()
 */

.section .text.start
.global _start

_start:
    # Initialize stack pointer
    la sp, _sp
    
    # Initialize global pointer (not used in our simple system)
    # la gp, __global_pointer$
    
    # Clear BSS section
    la t0, _bss_start
    la t1, _bss_end
clear_bss:
    beq t0, t1, bss_done
    sw zero, 0(t0)
    addi t0, t0, 4
    j clear_bss
bss_done:

    # Copy initialized data from ROM to RAM
    la t0, _data_load_start
    la t1, _data_start
    la t2, _data_end
copy_data:
    beq t1, t2, data_done
    lw t3, 0(t0)
    sw t3, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4
    j copy_data
data_done:

    # Call main function
    call main
    
    # If main returns, loop forever
halt:
    j halt

# Simple exception handler (not implemented)
.global _exception_handler
_exception_handler:
    j _exception_handler 