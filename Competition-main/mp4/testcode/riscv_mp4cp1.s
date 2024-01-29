.align 4

.section .rodata

a:              .word 0x900d900d     # ===== first set begin
ab:             .word 0x00000010     # 64
abc:            .word 0x00000000     # 96
abcd:           .word 0x600d600d     # 128
aa:             .word 0x900d900d     # 160
bb:             .word 0x00000010     # 192
cc:             .word 0x00000000     # 224
dd:             .word 0x600d600d     # ===== first set end
aaa:            .word 0x900d900d     # ===== second set begin
bbb:            .word 0x00000010     # 
ccc:            .word 0x00000000     # 
ddd:            .word 0x600d600d     # 
abcde:          .word 0x900d900d     # 
abcdef:         .word 0x00000010     # 
abcdefg:        .word 0x00000000     # 
abcdefgh:       .word 0x600d600d     # ===== second set end
Hardly_sleeping:            .word 0x900d900d     # third set begin
Always_anxious:             .word 0x00000010     # 56
Pretend_fine:               .word 0x00000000     # 60
Pretty_dead_inside:         .word 0x600d600d     # 64
Yelling_to_void:            .word 0x900d900d     # 52


.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # la x2, threshold
    auipc x2, 0
    auipc x10, 0
    auipc x1, 0
    addi x3, x3, 100
    addi x4, x4, 128
    add x4, x3, x4
    and x3, x2, x3
    # or x1, x3, x2
    lw x10, abc
    lw x11, abcd
    lw x11, Yelling_to_void
    # lw x12, Pretty_dead_inside
    # la x1, aaa
    # sb x10, (x1)
    nop
    nop
    nop
    nop
    # lh   x13, (x10)
    # lh   x11, 2(x10)
    # lb   x12, -1(x10)
    # nop
    # nop
    # nop
    # sb  x4, 228(x2) 
    # sw  x10, 232(x2)
    # sh  x10, 242(x2)
    # # sw
    # # sh


    # # lw x1, (x2)
    # not  x1, x1
    # xor  x3, x3, x3
    # addi x8, x8, 1
    # addi x4, x4, 1
    # addi x2, x2, 132
    # addi x1, x1, 120
    # addi x3, x3, 120
    # and  x9, x9, 0
    # or   x8, x8, 1
    # nop
    # nop
    # nop
    # nop
    # add x4, x3, x2
    # nop
    # lw x1, (x2) # strange rd_wdata error
    # nop
    # nop
    # nop
    # nop
    # add x3, x1, x2

    andi x3, x3, 0
    andi x2, x2, 0
    addi x2, x2, 5     
LOOP1:
    beq x3, x2, END_LOOP1 
    addi x3, x3, 1
    jal LOOP1   
END_LOOP1:


    # for golden spike to stall
    li  t0, 1     
    la  t1, tohost
    sw  t0, 0(t1)       # 40
    sw  x0, 4(t1)       # 44
halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below.   # 48
                      # Your own programs should also make use
                      # of an infinite loop at the end.

.section .rodata

bad:        .word 0xdeadbeef     # 52
threshold:  .word 0x00000010     # 56
result:     .word 0x00000000     # 60
good:       .word 0x600d600d     # 64

.section ".tohost"
.globl tohost
tohost: .dword 0                 # 68
.section ".fromhost"
.globl fromhost
fromhost: .dword 0
