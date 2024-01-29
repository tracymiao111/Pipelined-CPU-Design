riscv_mp2test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    lw x1, threshold    # x1 = 0x10
    lw x2, threshold    # x2 = 0x10
    lw x3, result       # x3 = 0x0

loop1: 
    addi x3, x3, 1
    bltu x3, x2, loop1

    lw x1, result
    addi x1, x1, 1
loop2:
    addi x3, x3, -1
    bge  x3, x1, loop2

    lw x3, threshold
loop3:
    addi x3, x3, -1
    bgeu x3, x1, loop3

loop4: 
    addi x3, x3, 1
    blt  x3, x2, loop4

    li  t0, 1
    la  t1, tohost
    sw  t0, 0(t1)
    sw  x0, 4(t1)
halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end.

.section .rodata

bad:        .word 0xdeadbeef
threshold:  .word 0x00000010
result:     .word 0x00000000
good:       .word 0x600d600d

.section ".tohost"
.globl tohost
tohost: .dword 0
.section ".fromhost"
.globl fromhost
fromhost: .dword 0