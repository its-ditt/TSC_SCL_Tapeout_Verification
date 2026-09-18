// ============================================================
// TB #1 - RV32I Test Program Configuration / Expected Results
// ============================================================
//
// Program:
//     program.hex
//
// This file contains only constants needed by the main TB.
// The program itself is loaded by tb_loader.svh.
// ============================================================

localparam string PROGRAM_FILE = "program.hex";

// ------------------------------------------------------------
// Program setup
// ------------------------------------------------------------

localparam logic [31:0] DATA_BASE   = 32'h00000100; // x30
localparam logic [31:0] RESULT_BASE = 32'h00000300; // x31

// ------------------------------------------------------------
// Expected register results
// ------------------------------------------------------------

// Initial setup
localparam logic [31:0] EXP_X27 = 32'h0000000A;
localparam logic [31:0] EXP_X28 = 32'h00000003;
localparam logic [31:0] EXP_X29 = 32'hFFFFFFF9;
localparam logic [31:0] EXP_X30 = 32'h00000100;
localparam logic [31:0] EXP_X31 = 32'h00000300;

// R-type ALU
localparam logic [31:0] EXP_ADD  = 32'h0000000D; // 10 + 3
localparam logic [31:0] EXP_SUB  = 32'h00000007; // 10 - 3
localparam logic [31:0] EXP_SLL  = 32'h00000050; // 10 << 3
localparam logic [31:0] EXP_SLT  = 32'h00000001; // -7 < 3
localparam logic [31:0] EXP_SLTU = 32'h00000001; // 3 < 0xfffffff9, unsigned
localparam logic [31:0] EXP_XOR  = 32'h00000009;
localparam logic [31:0] EXP_SRL  = 32'h00000001; // 10 >> 3
localparam logic [31:0] EXP_SRA  = 32'hFFFFFFFF; // -7 >> 3
localparam logic [31:0] EXP_OR   = 32'h0000000B;
localparam logic [31:0] EXP_AND  = 32'h00000002;

// I-type ALU
localparam logic [31:0] EXP_ADDI  = 32'h0000000F; // 10 + 5
localparam logic [31:0] EXP_SLTI  = 32'h00000001; // -7 < -1
localparam logic [31:0] EXP_SLTIU = 32'h00000000; // 0xfffffff9 < 5, unsigned
localparam logic [31:0] EXP_XORI  = 32'h000000FA; // 10 xor 0xf0
localparam logic [31:0] EXP_ORI   = 32'h0000000F;
localparam logic [31:0] EXP_ANDI  = 32'h00000000;
localparam logic [31:0] EXP_SLLI  = 32'h00000028; // 10 << 2
localparam logic [31:0] EXP_SRLI  = 32'h00000005; // 10 >> 1
localparam logic [31:0] EXP_SRAI  = 32'hFFFFFFFC; // -7 >> 1

// Upper immediate
localparam logic [31:0] EXP_LUI   = 32'h12345000;

// AUIPC is PC-dependent:
// instruction PC = 0x00000094
// result = PC + 0x00001000
localparam logic [31:0] EXP_AUIPC = 32'h00001094;

// Loads
localparam logic [31:0] EXP_LW  = 32'h12345000;
localparam logic [31:0] EXP_LH  = 32'hFFFFFFF9;
localparam logic [31:0] EXP_LHU = 32'h0000FFF9;
localparam logic [31:0] EXP_LB  = 32'hFFFFFFF9;
localparam logic [31:0] EXP_LBU = 32'h000000F9;

// ------------------------------------------------------------
// Memory locations used by stores / loads
// ------------------------------------------------------------

// Data initialization
localparam logic [31:0] ADDR_DATA_SW  = DATA_BASE + 32'd0; // 0x100
localparam logic [31:0] ADDR_DATA_LW  = DATA_BASE + 32'd0; // 0x100

localparam logic [31:0] ADDR_DATA_SH  = DATA_BASE + 32'd4; // 0x104
localparam logic [31:0] ADDR_DATA_LH  = DATA_BASE + 32'd8; // 0x108

localparam logic [31:0] ADDR_DATA_SB  = DATA_BASE + 32'd6; // 0x106
localparam logic [31:0] ADDR_DATA_LB  = DATA_BASE + 32'd8; // 0x108

// After SW/SH/SB:
//   [0x100] = 0x12345000
//   [0x104] = 0x00F9FFF9
//   [0x108] = 0xFFFFFFF9
localparam logic [31:0] EXP_DATA_0100 = 32'h12345000;
localparam logic [31:0] EXP_DATA_0104 = 32'h00F9FFF9;
localparam logic [31:0] EXP_DATA_0108 = 32'hFFFFFFF9;

// ------------------------------------------------------------
// Result memory map
//
// x1..x19, x25, x26, x20..x24 are stored here by the program.
// ------------------------------------------------------------

localparam logic [31:0] ADDR_ADD   = RESULT_BASE + 32'd0;   // x1
localparam logic [31:0] ADDR_SUB   = RESULT_BASE + 32'd4;   // x2
localparam logic [31:0] ADDR_SLL   = RESULT_BASE + 32'd8;   // x3
localparam logic [31:0] ADDR_SLT   = RESULT_BASE + 32'd12;  // x4
localparam logic [31:0] ADDR_SLTU  = RESULT_BASE + 32'd16;  // x5
localparam logic [31:0] ADDR_XOR   = RESULT_BASE + 32'd20;  // x6
localparam logic [31:0] ADDR_SRL   = RESULT_BASE + 32'd24;  // x7
localparam logic [31:0] ADDR_SRA   = RESULT_BASE + 32'd28;  // x8
localparam logic [31:0] ADDR_OR    = RESULT_BASE + 32'd32;  // x9
localparam logic [31:0] ADDR_AND   = RESULT_BASE + 32'd36;  // x10

localparam logic [31:0] ADDR_ADDI  = RESULT_BASE + 32'd40;  // x11
localparam logic [31:0] ADDR_SLTI  = RESULT_BASE + 32'd44;  // x12
localparam logic [31:0] ADDR_SLTIU = RESULT_BASE + 32'd48;  // x13
localparam logic [31:0] ADDR_XORI  = RESULT_BASE + 32'd52;  // x14
localparam logic [31:0] ADDR_ORI   = RESULT_BASE + 32'd56;  // x15
localparam logic [31:0] ADDR_ANDI  = RESULT_BASE + 32'd60;  // x16
localparam logic [31:0] ADDR_SLLI  = RESULT_BASE + 32'd64;  // x17
localparam logic [31:0] ADDR_SRLI  = RESULT_BASE + 32'd68;  // x18
localparam logic [31:0] ADDR_SRAI  = RESULT_BASE + 32'd72;  // x19

localparam logic [31:0] ADDR_LUI   = RESULT_BASE + 32'd76;  // x25
localparam logic [31:0] ADDR_AUIPC = RESULT_BASE + 32'd80;  // x26

localparam logic [31:0] ADDR_LW    = RESULT_BASE + 32'd84;  // x20
localparam logic [31:0] ADDR_LH    = RESULT_BASE + 32'd88;  // x21
localparam logic [31:0] ADDR_LHU   = RESULT_BASE + 32'd92;  // x22
localparam logic [31:0] ADDR_LB    = RESULT_BASE + 32'd96;  // x23
localparam logic [31:0] ADDR_LBU   = RESULT_BASE + 32'd100; // x24

// ------------------------------------------------------------
// Branch markers
//
// 0 = not taken / marker untouched
// 1 = taken / branch target executed
// ------------------------------------------------------------

localparam logic [31:0] ADDR_BEQ  = RESULT_BASE + 32'd104; // 0x368
localparam logic [31:0] ADDR_BNE  = RESULT_BASE + 32'd108; // 0x36c
localparam logic [31:0] ADDR_BLT  = RESULT_BASE + 32'd112; // 0x370
localparam logic [31:0] ADDR_BGE  = RESULT_BASE + 32'd116; // 0x374
localparam logic [31:0] ADDR_BLTU = RESULT_BASE + 32'd120; // 0x378
localparam logic [31:0] ADDR_BGEU = RESULT_BASE + 32'd124; // 0x37c

localparam logic [31:0] EXP_BEQ  = 32'h00000000;
localparam logic [31:0] EXP_BNE  = 32'h00000001;
localparam logic [31:0] EXP_BLT  = 32'h00000001;
localparam logic [31:0] EXP_BGE  = 32'h00000001;
localparam logic [31:0] EXP_BLTU = 32'h00000000;
localparam logic [31:0] EXP_BGEU = 32'h00000001;

// ------------------------------------------------------------
// JAL / JALR
// ------------------------------------------------------------
//
// JAL:
//   instruction PC = 0x244
//   x5 = PC + 4 = 0x248
//   target = 0x250
//
// JALR:
//   instruction PC = 0x264
//   x5 = PC + 4 = 0x268
//   target = 0x270
// ------------------------------------------------------------

localparam logic [31:0] ADDR_JAL_FAIL = RESULT_BASE + 32'd132; // 0x384
localparam logic [31:0] ADDR_JAL_LINK = RESULT_BASE + 32'd128; // 0x380
localparam logic [31:0] ADDR_JAL_PASS = RESULT_BASE + 32'd136; // 0x388

localparam logic [31:0] ADDR_JALR_FAIL = RESULT_BASE + 32'd140; // 0x38c
localparam logic [31:0] ADDR_JALR_LINK = RESULT_BASE + 32'd144; // 0x390
localparam logic [31:0] ADDR_JALR_PASS = RESULT_BASE + 32'd148; // 0x394

localparam logic [31:0] EXP_JAL_FAIL  = 32'h00000000;
localparam logic [31:0] EXP_JAL_LINK  = 32'h00000248;
localparam logic [31:0] EXP_JAL_PASS  = 32'h00000001;

localparam logic [31:0] EXP_JALR_FAIL = 32'h00000000;
localparam logic [31:0] EXP_JALR_LINK = 32'h00000268;
localparam logic [31:0] EXP_JALR_PASS = 32'h00000001;