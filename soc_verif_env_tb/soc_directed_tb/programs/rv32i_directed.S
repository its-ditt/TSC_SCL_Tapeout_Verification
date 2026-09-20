.text

# ================================================================
# RV32I directed SoC program
# The program intentionally has two parts:
#   1. instruction-functional checks
#   2. pipeline / forwarding / control-flow checks
#
# Base addresses used by the program:
#   x20 = 0x00000100   data area
#   x21 = 0x00000200   result area
#   x22 = 0x000003F0   completion marker
# ================================================================

start:
    addi x20, x0, 0x100
    addi x21, x0, 0x200
    addi x22, x0, 0x3f0

    # ------------------------------------------------------------
    # R-type arithmetic / logical instructions
    # ------------------------------------------------------------
    addi x1,  x0, 10
    addi x2,  x0, 3
    addi x3,  x0, -7

    add  x4,  x1, x2
    sub  x5,  x1, x2
    sll  x6,  x1, x2
    slt  x7,  x3, x2
    sltu x8,  x0, x2
    xor  x9,  x1, x2
    srl  x10, x1, x2
    sra  x11, x3, x2
    or   x12, x1, x2
    and  x13, x1, x2

    # Save representative R-type results
    sw   x4,  0(x21)
    sw   x5,  4(x21)
    sw   x6,  8(x21)
    sw   x7,  12(x21)
    sw   x8,  16(x21)
    sw   x9,  20(x21)
    sw   x10, 24(x21)
    sw   x11, 28(x21)
    sw   x12, 32(x21)
    sw   x13, 36(x21)

    # ------------------------------------------------------------
    # I-type ALU instructions
    # ------------------------------------------------------------
    addi  x14, x1, 5
    slti  x15, x3, -1
    sltiu x16, x3, 5
    xori  x17, x1, 0x0f0
    ori   x18, x1, 5
    andi  x19, x1, 0x0f0
    slli  x23, x1, 2
    srli  x24, x1, 1
    srai  x25, x3, 1

    sw x14, 40(x21)
    sw x15, 44(x21)
    sw x16, 48(x21)
    sw x17, 52(x21)
    sw x18, 56(x21)
    sw x19, 60(x21)
    sw x23, 64(x21)
    sw x24, 68(x21)
    sw x25, 72(x21)

    # ------------------------------------------------------------
    # U-type instructions
    # ------------------------------------------------------------
    lui   x26, 0x12345
    auipc x27, 0x00001

    sw x26, 76(x21)
    sw x27, 80(x21)

    # ------------------------------------------------------------
    # Store / load instructions
    # ------------------------------------------------------------
    # 0x12345678 at data address 0x100
    lui   x28, 0x12345
    addi  x28, x28, 0x678
    sw    x28, 0(x20)

    lw    x29, 0(x20)
    lh    x1,  0(x20)
    lhu   x2,  0(x20)
    lb    x3,  0(x20)
    lbu   x4,  0(x20)

    sw x29, 84(x21)
    sw x1,  88(x21)
    sw x2,  92(x21)
    sw x3,  96(x21)
    sw x4,  100(x21)

    # Signed halfword 0x8001 at 0x104
    lui   x5,  0xffff8
    addi  x5,  x5, 1
    sh    x5,  4(x20)
    lh    x6,  4(x20)
    lhu   x7,  4(x20)

    sw x6,  104(x21)
    sw x7,  108(x21)

    # Signed byte 0x80 at 0x106
    addi  x8,  x0, -128
    sb    x8,  6(x20)
    lb    x9,  6(x20)
    lbu   x10, 6(x20)

    sw x9,  112(x21)
    sw x10, 116(x21)

    # ------------------------------------------------------------
    # RAW forwarding case
    # ------------------------------------------------------------
    addi x11, x0, 21
    add  x12, x11, x11
    add  x13, x12, x11
    sw   x13, 120(x21)

    # ------------------------------------------------------------
    # Load-use hazard case
    # ------------------------------------------------------------
    lw   x14, 0(x20)
    add  x15, x14, x1
    sw   x15, 124(x21)

    # ------------------------------------------------------------
    # BEQ - taken
    # ------------------------------------------------------------
    addi x16, x0, 0
    beq  x1, x1, beq_taken
    addi x16, x0, 99
beq_taken:
    addi x16, x16, 1
    sw   x16, 128(x21)

    # ------------------------------------------------------------
    # BNE - not taken
    # ------------------------------------------------------------
    addi x17, x0, 0
    bne  x1, x1, bne_taken
    addi x17, x17, 1
bne_taken:
    sw   x17, 132(x21)

    # ------------------------------------------------------------
    # BLT - taken
    # ------------------------------------------------------------
    addi x18, x0, 0
    blt  x3, x2, blt_taken
    addi x18, x0, 99
blt_taken:
    addi x18, x18, 1
    sw   x18, 136(x21)

    # ------------------------------------------------------------
    # BGE - taken
    # ------------------------------------------------------------
    addi x19, x0, 0
    bge  x1, x2, bge_taken
    addi x19, x0, 99
bge_taken:
    addi x19, x19, 1
    sw   x19, 140(x21)

    # ------------------------------------------------------------
    # BLTU - taken
    # ------------------------------------------------------------
    addi x23, x0, 0
    bltu x0, x2, bltu_taken
    addi x23, x0, 99
bltu_taken:
    addi x23, x23, 1
    sw   x23, 144(x21)

    # ------------------------------------------------------------
    # BGEU - taken
    # ------------------------------------------------------------
    addi x24, x0, 0
    bgeu x2, x0, bgeu_taken
    addi x24, x0, 99
bgeu_taken:
    addi x24, x24, 1
    sw   x24, 148(x21)

    # ------------------------------------------------------------
    # JAL - link + wrong path suppression + dependent use
    # ------------------------------------------------------------
    jal  x25, jal_target
    addi x26, x0, 99
    sw   x26, 152(x21)
jal_target:
    addi x26, x25, 0
    sw   x26, 156(x21)

    # ------------------------------------------------------------
    # JALR - link + target + dependent use
    # ------------------------------------------------------------
    la   x27, jalr_target
    jalr x28, 0(x27)
    addi x29, x0, 99
    sw   x29, 160(x21)
jalr_target:
    addi x29, x28, 0
    sw   x29, 164(x21)

    # ------------------------------------------------------------
    # Final completion marker
    # ------------------------------------------------------------
    addi x30, x0, 1
    sw   x30, 0(x22)

    # No architectural need to execute beyond completion.
    nop
    nop
