riscv_mp2cp2test.s:
.align 4

.section .rodata  # read-only data section
bad:        .word 0xdeadbeef
threshold:  .word 0x00000040
result:     .word 0x00000000
good:       .word 0x600d600d
something:   .word 0xffff220d
somebb:      .word 0x00000000
somedd:      .word 0x00000000

.section .text  # this is needed for the kernel to run the code
.globl _start   # kinda like main function in c, where the program starts

_start:
    lw x1, something
    lb x2, something
    lh x3, something
    lhu x4, something
    lbu x5, something
    andi x1, x1, 0
    andi x2, x2, 0
    xori x2, x1, 0x33


    la t1, result       
    sw x2, 0(t1)    # the 'rt' in the handbook refer to the address of the label
                    # sw cannot compute the offset of label, so we need to use register to store label addr

    ori x1, x1, 0x10 # x1 = x1 || 16 
    slli x2, x2, 10 # x2 = x2 << 32 logical
    srli t2, t2, 10 # t2 = t2 >> 32 logical
    lui t2, 0
    lui x2, 0

loop_one:
    bgeu x2, x1, loop_two_end
    addi t2, t2, 10
    addi x2, x2, 1
    beq x0, x0, loop_one

loop_two:
    beqz x2, loop_two_end
    addi x2, x2, -1
    addi t2, t2, -1
    beq x0, x0, loop_two     

loop_two_end:
    lui  x1, 8     # X3 <= 8
    addi x1, x1, -8
    seqz x1, x1
    andi x1, x1, 0
    addi x1, x1, -12
    srai x2, x1, 10

    andi x3, x3, -5
    lui x2, 2
loop_three:
    blt x2, x3, loop_three_end
    addi x2, x2, -2
    beq x0, x0, loop_three
loop_three_end:
    
    andi t3, t3, 0
    addi t3, t3, 5
loop_four:
    addi t3, t3, -1
    bne x0, t3, loop_four
    sb t3, somebb, x1
    sh x3, somedd, x1





# =============================================================================================
    li  t0, 1
    la  t1, tohost
    sw  t0, 0(t1)
    sw  x0, 4(t1)
halt:
    beq x0, x0, halt        # A good infinite loop

badword:                    # Something went wrong with the code
    lw x1, bad
badloop:
    beq x1, x1, badloop


.section ".tohost"
.globl tohost
tohost: .dword 0
.section ".fromhost"
.globl fromhost
fromhost: .dword 0
