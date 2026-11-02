/* Minimal startup for a RISC-V (RV32) test program. */
.section .text.init
.globl _start
_start:
    la      sp, _stack_top
    call    main
1:
    j       1b
