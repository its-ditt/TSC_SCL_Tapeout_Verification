`timescale 1ns / 1ps

module tb_decode_stage_cov_asrt;

    // ============================================================
    // CLOCK / RESET
    // ============================================================

    logic clk;
    logic rst;


    // ============================================================
    // WRITEBACK INPUTS
    // ============================================================

    logic        RegWriteW;
    logic [31:0] ResultW;
    logic [4:0]  RdW;


    // ============================================================
    // DECODE INPUTS
    // ============================================================

    logic [31:0] InstrD;
    logic [31:0] PCD;
    logic [31:0] PcPlus4D;

    logic StallD;
    logic FlushD;


    // ============================================================
    // DECODE OUTPUTS
    // ============================================================

    logic        RegWriteE;
    logic [1:0]  ResultSrcE;
    logic        MemWriteE;
    logic        MemReadE;
    logic        jumpE;
    logic        BranchE;

    logic [3:0]  ALUControlE;

    logic [1:0]  ALUSrcAE;
    logic        ALUSrcBE;

    logic [31:0] RD1E;
    logic [31:0] RD2E;

    logic [31:0] PCE;
    logic [31:0] PcPlus4E;

    logic [4:0]  RdE;
    logic [4:0]  RS1E;
    logic [4:0]  RS2E;

    logic [31:0] ImmExtendE;

    logic [4:0]  RS1D;
    logic [4:0]  RS2D;

    logic [2:0]  funct3E;


    // ============================================================
    // REFERENCE REGISTER FILE
    // ============================================================

    logic [31:0] model_reg [0:31];


    // ============================================================
    // EXPECTED VALUES
    // ============================================================

    logic        exp_RegWrite;
    logic [1:0]  exp_ResultSrc;
    logic        exp_MemWrite;
    logic        exp_MemRead;
    logic        exp_jump;
    logic        exp_Branch;

    logic [3:0]  exp_ALUControl;

    logic [1:0]  exp_ALUSrcA;
    logic        exp_ALUSrcB;

    logic [31:0] exp_RD1;
    logic [31:0] exp_RD2;

    logic [31:0] exp_PC;
    logic [31:0] exp_PcPlus4;

    logic [4:0]  exp_Rd;
    logic [4:0]  exp_RS1;
    logic [4:0]  exp_RS2;

    logic [31:0] exp_Imm;

    logic [2:0]  exp_funct3;


    // ============================================================
    // PREVIOUS ID/EX STATE
    // Used for StallD verification
    // ============================================================

    logic        prev_RegWrite;
    logic [1:0]  prev_ResultSrc;
    logic        prev_MemWrite;
    logic        prev_MemRead;
    logic        prev_jump;
    logic        prev_Branch;

    logic [3:0]  prev_ALUControl;

    logic [1:0]  prev_ALUSrcA;
    logic        prev_ALUSrcB;

    logic [31:0] prev_RD1;
    logic [31:0] prev_RD2;

    logic [31:0] prev_PC;
    logic [31:0] prev_PcPlus4;

    logic [4:0]  prev_Rd;
    logic [4:0]  prev_RS1;
    logic [4:0]  prev_RS2;

    logic [31:0] prev_Imm;

    logic [2:0]  prev_funct3;


    // ============================================================
    // TEST COUNTERS
    // ============================================================

    integer test_count;
    integer pass_count;
    integer fail_count;
    integer assertion_failures;

    integer i;


    // ============================================================
    // DUT
    // ============================================================

    decode_stage dut (

        .clk(clk),
        .rst(rst),

        .RegWriteW(RegWriteW),
        .ResultW(ResultW),
        .RdW(RdW),

        .InstrD(InstrD),
        .PCD(PCD),
        .PcPlus4D(PcPlus4D),

        .StallD(StallD),
        .FlushD(FlushD),

        .RegWriteE(RegWriteE),
        .ResultSrcE(ResultSrcE),
        .MemWriteE(MemWriteE),
        .MemReadE(MemReadE),
        .jumpE(jumpE),
        .BranchE(BranchE),

        .ALUControlE(ALUControlE),

        .ALUSrcAE(ALUSrcAE),
        .ALUSrcBE(ALUSrcBE),

        .RD1E(RD1E),
        .RD2E(RD2E),

        .PCE(PCE),
        .PcPlus4E(PcPlus4E),

        .RdE(RdE),
        .RS1E(RS1E),
        .RS2E(RS2E),

        .ImmExtendE(ImmExtendE),

        .RS1D(RS1D),
        .RS2D(RS2D),

        .funct3E(funct3E)

    );


    // ============================================================
    // CLOCK
    // ============================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    // ============================================================
    // FUNCTIONAL COVERAGE
    // ============================================================

    covergroup decode_coverage;

        // --------------------------------------------------------
        // Opcode
        // --------------------------------------------------------

        cp_opcode : coverpoint InstrD[6:0] {

            bins R_TYPE = {7'b0110011};

            bins I_TYPE = {7'b0010011};

            bins LOAD = {7'b0000011};

            bins STORE = {7'b0100011};

            bins BRANCH = {7'b1100011};

            bins JAL = {7'b1101111};

            bins JALR = {7'b1100111};

            bins AUIPC = {7'b0010111};

            bins LUI = {7'b0110111};

            bins INVALID = default;

        }


        // --------------------------------------------------------
        // funct3
        // --------------------------------------------------------

        cp_funct3 : coverpoint InstrD[14:12] {

            bins F3_000 = {3'b000};
            bins F3_001 = {3'b001};
            bins F3_010 = {3'b010};
            bins F3_011 = {3'b011};
            bins F3_100 = {3'b100};
            bins F3_101 = {3'b101};
            bins F3_110 = {3'b110};
            bins F3_111 = {3'b111};

        }


        // --------------------------------------------------------
        // funct7 bit
        // --------------------------------------------------------

        cp_funct7 : coverpoint InstrD[30] {

            bins ZERO = {1'b0};

            bins ONE = {1'b1};

        }


        // --------------------------------------------------------
        // RS1
        // --------------------------------------------------------

        cp_rs1 : coverpoint InstrD[19:15] {

            bins X0 = {5'd0};

            bins LOW = {[5'd1:5'd7]};

            bins MID = {[5'd8:5'd23]};

            bins HIGH = {[5'd24:5'd30]};

            bins X31 = {5'd31};

        }


        // --------------------------------------------------------
        // RS2
        // --------------------------------------------------------

        cp_rs2 : coverpoint InstrD[24:20] {

            bins X0 = {5'd0};

            bins LOW = {[5'd1:5'd7]};

            bins MID = {[5'd8:5'd23]};

            bins HIGH = {[5'd24:5'd30]};

            bins X31 = {5'd31};

        }


        // --------------------------------------------------------
        // RD
        // --------------------------------------------------------

        cp_rd : coverpoint InstrD[11:7] {

            bins X0 = {5'd0};

            bins LOW = {[5'd1:5'd7]};

            bins MID = {[5'd8:5'd23]};

            bins HIGH = {[5'd24:5'd30]};

            bins X31 = {5'd31};

        }


        // --------------------------------------------------------
        // Stall
        // --------------------------------------------------------

        cp_stall : coverpoint StallD {

            bins NO_STALL = {1'b0};

            bins STALL = {1'b1};

        }


        // --------------------------------------------------------
        // Flush
        // --------------------------------------------------------

        cp_flush : coverpoint FlushD {

            bins NO_FLUSH = {1'b0};

            bins FLUSH = {1'b1};

        }


        // --------------------------------------------------------
        // Result source
        // --------------------------------------------------------

        cp_resultsrc : coverpoint ResultSrcE {

            bins ALU_RESULT = {2'b00};

            bins MEMORY = {2'b01};

            bins PC_PLUS_4 = {2'b10};

            bins RESERVED = {2'b11};

        }


        // --------------------------------------------------------
        // Hazard combination
        // --------------------------------------------------------

        stall_flush_cross : cross cp_stall, cp_flush;


        // --------------------------------------------------------
        // Opcode / funct3
        // --------------------------------------------------------

        opcode_funct3_cross : cross cp_opcode, cp_funct3;

    endgroup


    decode_coverage cov;


    // ============================================================
    // RV32I IMMEDIATE REFERENCE MODEL
    // ============================================================

    function automatic [31:0] reference_imm;

        input [31:0] instr;

        begin

            case (instr[6:0])

                // I-type
                7'b0000011,
                7'b0010011,
                7'b1100111:

                    reference_imm =
                        {{20{instr[31]}},
                         instr[31:20]};


                // S-type
                7'b0100011:

                    reference_imm =
                        {{20{instr[31]}},
                         instr[31:25],
                         instr[11:7]};


                // B-type
                7'b1100011:

                    reference_imm =
                        {{19{instr[31]}},
                         instr[31],
                         instr[7],
                         instr[30:25],
                         instr[11:8],
                         1'b0};


                // J-type
                7'b1101111:

                    reference_imm =
                        {{12{instr[31]}},
                         instr[19:12],
                         instr[20],
                         instr[30:21],
                         1'b0};


                // U-type
                7'b0110111,
                7'b0010111:

                    reference_imm =
                        {instr[31:12],12'b0};


                default:

                    reference_imm = 32'b0;

            endcase

        end

    endfunction


    // ============================================================
    // RV32I ALU CONTROL REFERENCE MODEL
    // ============================================================

    function automatic [3:0] reference_alu;

        input [6:0] opcode;
        input [2:0] funct3;
        input       funct7;

        begin

            case (opcode)

                // ------------------------------------------------
                // Branch
                // ------------------------------------------------

                7'b1100011:

                    case (funct3)

                        3'b000,
                        3'b001:
                            reference_alu = 4'b0001;

                        3'b100,
                        3'b101:
                            reference_alu = 4'b1001;

                        3'b110,
                        3'b111:
                            reference_alu = 4'b1000;

                        default:
                            reference_alu = 4'b0000;

                    endcase


                // ------------------------------------------------
                // R / I arithmetic
                // ------------------------------------------------

                7'b0110011,
                7'b0010011:

                    case (funct3)

                        3'b000:

                            begin

                                if (
                                    (opcode == 7'b0110011) &&
                                    funct7
                                )
                                    reference_alu = 4'b0001;
                                else
                                    reference_alu = 4'b0000;

                            end


                        3'b001:
                            reference_alu = 4'b0101;


                        3'b010:
                            reference_alu = 4'b1000;


                        3'b011:
                            reference_alu = 4'b1001;


                        3'b100:
                            reference_alu = 4'b0100;


                        3'b101:

                            begin

                                if (funct7)
                                    reference_alu = 4'b0111;
                                else
                                    reference_alu = 4'b0110;

                            end


                        3'b110:
                            reference_alu = 4'b0011;


                        3'b111:
                            reference_alu = 4'b0010;


                        default:
                            reference_alu = 4'b0000;

                    endcase


                default:

                    reference_alu = 4'b0000;

            endcase

        end

    endfunction


    // ============================================================
    // CONTROL REFERENCE MODEL
    // ============================================================

    task automatic calculate_expected;

        input [31:0] instr;

        begin

            exp_RegWrite   = 1'b0;
            exp_ResultSrc  = 2'b00;
            exp_MemWrite   = 1'b0;
            exp_MemRead    = 1'b0;
            exp_jump       = 1'b0;
            exp_Branch     = 1'b0;

            exp_ALUSrcA    = 2'b00;
            exp_ALUSrcB    = 1'b0;

            exp_ALUControl = 4'b0000;


            case (instr[6:0])

                // ------------------------------------------------
                // R TYPE
                // ------------------------------------------------

                7'b0110011:

                    begin

                        exp_RegWrite = 1'b1;

                        exp_ALUSrcA = 2'b00;

                        exp_ALUSrcB = 1'b0;

                        exp_ALUControl =
                            reference_alu(
                                instr[6:0],
                                instr[14:12],
                                instr[30]
                            );

                    end


                // ------------------------------------------------
                // I TYPE
                // ------------------------------------------------

                7'b0010011:

                    begin

                        exp_RegWrite = 1'b1;

                        exp_ALUSrcA = 2'b00;

                        exp_ALUSrcB = 1'b1;

                        exp_ALUControl =
                            reference_alu(
                                instr[6:0],
                                instr[14:12],
                                instr[30]
                            );

                    end


                // ------------------------------------------------
                // LOAD
                // ------------------------------------------------

                7'b0000011:

                    begin

                        exp_RegWrite = 1'b1;

                        exp_ResultSrc = 2'b01;

                        exp_MemRead = 1'b1;

                        exp_ALUSrcA = 2'b00;

                        exp_ALUSrcB = 1'b1;

                        exp_ALUControl = 4'b0000;

                    end


                // ------------------------------------------------
                // STORE
                // ------------------------------------------------

                7'b0100011:

                    begin

                        exp_MemWrite = 1'b1;

                        exp_ALUSrcA = 2'b00;

                        exp_ALUSrcB = 1'b1;

                        exp_ALUControl = 4'b0000;

                    end


                // ------------------------------------------------
                // BRANCH
                // ------------------------------------------------

                7'b1100011:

                    begin

                        exp_Branch = 1'b1;

                        exp_ALUSrcA = 2'b00;

                        exp_ALUSrcB = 1'b0;

                        exp_ALUControl =
                            reference_alu(
                                instr[6:0],
                                instr[14:12],
                                instr[30]
                            );

                    end


                // ------------------------------------------------
                // JAL
                // ------------------------------------------------

                7'b1101111:

                    begin

                        exp_RegWrite = 1'b1;

                        exp_ResultSrc = 2'b10;

                        exp_jump = 1'b1;

                    end


                // ------------------------------------------------
                // JALR
                // ------------------------------------------------

                7'b1100111:

                    begin

                        exp_RegWrite = 1'b1;

                        exp_ResultSrc = 2'b10;

                        exp_jump = 1'b1;

                        exp_ALUSrcB = 1'b1;

                    end


                // ------------------------------------------------
                // AUIPC
                // ------------------------------------------------

                7'b0010111:

                    begin

                        exp_RegWrite = 1'b1;

                        exp_ALUSrcA = 2'b01;

                        exp_ALUSrcB = 1'b1;

                        exp_ALUControl = 4'b0000;

                    end


                // ------------------------------------------------
                // LUI
                // ------------------------------------------------

                7'b0110111:

                    begin

                        exp_RegWrite = 1'b1;

                        exp_ALUSrcA = 2'b10;

                        exp_ALUSrcB = 1'b1;

                        exp_ALUControl = 4'b0000;

                    end


                // ------------------------------------------------
                // INVALID
                // ------------------------------------------------

                default:

                    begin

                        exp_RegWrite = 1'b0;

                        exp_ResultSrc = 2'b00;

                        exp_MemWrite = 1'b0;

                        exp_MemRead = 1'b0;

                        exp_jump = 1'b0;

                        exp_Branch = 1'b0;

                        exp_ALUSrcA = 2'b00;

                        exp_ALUSrcB = 1'b0;

                        exp_ALUControl = 4'b0000;

                    end

            endcase

        end

    endtask


    // ============================================================
    // R-TYPE ENCODER
    // ============================================================

    function automatic [31:0] make_r;

        input [2:0] funct3;
        input       funct7;
        input [4:0] rs1;
        input [4:0] rs2;
        input [4:0] rd;

        begin

            make_r = 32'b0;

            make_r[6:0] = 7'b0110011;

            make_r[14:12] = funct3;

            make_r[30] = funct7;

            make_r[19:15] = rs1;

            make_r[24:20] = rs2;

            make_r[11:7] = rd;

        end

    endfunction


    // ============================================================
    // I-TYPE ENCODER
    // ============================================================

    function automatic [31:0] make_i;

        input [6:0] opcode;
        input [2:0] funct3;
        input [4:0] rs1;
        input [4:0] rd;
        input [11:0] imm;

        begin

            make_i = 32'b0;

            make_i[6:0] = opcode;

            make_i[14:12] = funct3;

            make_i[19:15] = rs1;

            make_i[11:7] = rd;

            make_i[31:20] = imm;

        end

    endfunction


    // ============================================================
    // S-TYPE ENCODER
    // ============================================================

    function automatic [31:0] make_s;

        input [2:0] funct3;
        input [4:0] rs1;
        input [4:0] rs2;
        input [11:0] imm;

        begin

            make_s = 32'b0;

            make_s[6:0] = 7'b0100011;

            make_s[14:12] = funct3;

            make_s[19:15] = rs1;

            make_s[24:20] = rs2;

            make_s[31:25] = imm[11:5];

            make_s[11:7] = imm[4:0];

        end

    endfunction


    // ============================================================
    // B-TYPE ENCODER
    // ============================================================

    function automatic [31:0] make_b;

        input [2:0] funct3;
        input [4:0] rs1;
        input [4:0] rs2;
        input [12:0] imm;

        begin

            make_b = 32'b0;

            make_b[6:0] = 7'b1100011;

            make_b[14:12] = funct3;

            make_b[19:15] = rs1;

            make_b[24:20] = rs2;

            make_b[31] = imm[12];

            make_b[7] = imm[11];

            make_b[30:25] = imm[10:5];

            make_b[11:8] = imm[4:1];

        end

    endfunction


    // ============================================================
    // U-TYPE ENCODER
    // ============================================================

    function automatic [31:0] make_u;

        input [6:0] opcode;
        input [4:0] rd;
        input [19:0] imm;

        begin

            make_u = 32'b0;

            make_u[6:0] = opcode;

            make_u[11:7] = rd;

            make_u[31:12] = imm;

        end

    endfunction


    // ============================================================
    // J-TYPE ENCODER
    // ============================================================

    function automatic [31:0] make_j;

        input [4:0] rd;
        input [20:0] imm;

        begin

            make_j = 32'b0;

            make_j[6:0] = 7'b1101111;

            make_j[11:7] = rd;

            make_j[31] = imm[20];

            make_j[19:12] = imm[19:12];

            make_j[20] = imm[11];

            make_j[30:21] = imm[10:1];

        end

    endfunction


    // ============================================================
    // OUTPUT CHECK
    // ============================================================

    task automatic check_outputs;

        input [31:0] instruction;

        begin

            test_count = test_count + 1;


            if (
                (RegWriteE   !== exp_RegWrite)   ||
                (ResultSrcE  !== exp_ResultSrc)  ||
                (MemWriteE   !== exp_MemWrite)   ||
                (MemReadE    !== exp_MemRead)    ||
                (jumpE       !== exp_jump)       ||
                (BranchE     !== exp_Branch)     ||
                (ALUControlE !== exp_ALUControl) ||
                (ALUSrcAE    !== exp_ALUSrcA)   ||
                (ALUSrcBE    !== exp_ALUSrcB)   ||

                (RD1E        !== exp_RD1)        ||
                (RD2E        !== exp_RD2)        ||

                (PCE         !== exp_PC)         ||
                (PcPlus4E    !== exp_PcPlus4)    ||

                (RdE         !== exp_Rd)        ||
                (RS1E        !== exp_RS1)        ||
                (RS2E        !== exp_RS2)        ||

                (ImmExtendE  !== exp_Imm)       ||
                (funct3E     !== exp_funct3)
            ) begin

                fail_count = fail_count + 1;

                $display("");
                $display(
                    "FAIL | TEST=%0d | INSTR=%h",
                    test_count,
                    instruction
                );

                $display(
                    "CTRL | RW=%b/%b RS=%b/%b MW=%b/%b MR=%b/%b J=%b/%b B=%b/%b",
                    RegWriteE,
                    exp_RegWrite,
                    ResultSrcE,
                    exp_ResultSrc,
                    MemWriteE,
                    exp_MemWrite,
                    MemReadE,
                    exp_MemRead,
                    jumpE,
                    exp_jump,
                    BranchE,
                    exp_Branch
                );

                $display(
                    "ALU  | CTRL=%b/%b A=%b/%b B=%b/%b",
                    ALUControlE,
                    exp_ALUControl,
                    ALUSrcAE,
                    exp_ALUSrcA,
                    ALUSrcBE,
                    exp_ALUSrcB
                );

                $display(
                    "DATA | RD1=%h/%h RD2=%h/%h IMM=%h/%h",
                    RD1E,
                    exp_RD1,
                    RD2E,
                    exp_RD2,
                    ImmExtendE,
                    exp_Imm
                );

                $display(
                    "META | PC=%h/%h PC4=%h/%h RD=%0d/%0d RS1=%0d/%0d RS2=%0d/%0d",
                    PCE,
                    exp_PC,
                    PcPlus4E,
                    exp_PcPlus4,
                    RdE,
                    exp_Rd,
                    RS1E,
                    exp_RS1,
                    RS2E,
                    exp_RS2
                );

            end
            else begin

                pass_count = pass_count + 1;

            end


            // ====================================================
            // ASSERTIONS
            // ====================================================

            assert (RegWriteE === exp_RegWrite)
            else begin
                $error("RegWrite assertion failed");
                assertion_failures = assertion_failures + 1;
            end

            assert (ResultSrcE === exp_ResultSrc)
            else begin
                $error("ResultSrc assertion failed");
                assertion_failures = assertion_failures + 1;
            end

            assert (MemWriteE === exp_MemWrite)
            else begin
                $error("MemWrite assertion failed");
                assertion_failures = assertion_failures + 1;
            end

            assert (MemReadE === exp_MemRead)
            else begin
                $error("MemRead assertion failed");
                assertion_failures = assertion_failures + 1;
            end

            assert (jumpE === exp_jump)
            else begin
                $error("Jump assertion failed");
                assertion_failures = assertion_failures + 1;
            end

            assert (BranchE === exp_Branch)
            else begin
                $error("Branch assertion failed");
                assertion_failures = assertion_failures + 1;
            end

            assert (ALUControlE === exp_ALUControl)
            else begin
                $error("ALUControl assertion failed");
                assertion_failures = assertion_failures + 1;
            end

            assert (ALUSrcAE === exp_ALUSrcA)
            else begin
                $error("ALUSrcA assertion failed");
                assertion_failures = assertion_failures + 1;
            end

            assert (ALUSrcBE === exp_ALUSrcB)
            else begin
                $error("ALUSrcB assertion failed");
                assertion_failures = assertion_failures + 1;
            end

            assert (RD1E === exp_RD1)
            else begin
                $error("RD1 assertion failed");
                assertion_failures = assertion_failures + 1;
            end

            assert (RD2E === exp_RD2)
            else begin
                $error("RD2 assertion failed");
                assertion_failures = assertion_failures + 1;
            end

            assert (PCE === exp_PC)
            else begin
                $error("PC assertion failed");
                assertion_failures = assertion_failures + 1;
            end

            assert (PcPlus4E === exp_PcPlus4)
            else begin
                $error("PC+4 assertion failed");
                assertion_failures = assertion_failures + 1;
            end

            assert (RdE === exp_Rd)
            else begin
                $error("Rd assertion failed");
                assertion_failures = assertion_failures + 1;
            end

            assert (RS1E === exp_RS1)
            else begin
                $error("RS1 assertion failed");
                assertion_failures = assertion_failures + 1;
            end

            assert (RS2E === exp_RS2)
            else begin
                $error("RS2 assertion failed");
                assertion_failures = assertion_failures + 1;
            end

            assert (ImmExtendE === exp_Imm)
            else begin
                $error("Immediate assertion failed");
                assertion_failures = assertion_failures + 1;
            end

            assert (funct3E === exp_funct3)
            else begin
                $error("funct3 assertion failed");
                assertion_failures = assertion_failures + 1;
            end

        end

    endtask


    // ============================================================
    // APPLY ONE TEST CYCLE
    // ============================================================

    task automatic drive_and_check;

        input [31:0] instruction;
        input [31:0] pc;
        input [31:0] pc4;
        input        stall;
        input        flush;

        begin

            InstrD = instruction;

            PCD = pc;

            PcPlus4D = pc4;

            StallD = stall;

            FlushD = flush;


            // ----------------------------------------------------
            // Decode reference model
            // ----------------------------------------------------

            calculate_expected(instruction);


            exp_RS1 = instruction[19:15];

            exp_RS2 = instruction[24:20];

            exp_Rd = instruction[11:7];

            exp_funct3 = instruction[14:12];

            exp_Imm = reference_imm(instruction);


            // ----------------------------------------------------
            // Register-file reference model
            // ----------------------------------------------------

            if (instruction[19:15] == 5'd0)

                exp_RD1 = 32'b0;

            else if (
                RegWriteW &&
                (RdW != 5'd0) &&
                (RdW == instruction[19:15])
            )

                exp_RD1 = ResultW;

            else

                exp_RD1 = model_reg[instruction[19:15]];


            if (instruction[24:20] == 5'd0)

                exp_RD2 = 32'b0;

            else if (
                RegWriteW &&
                (RdW != 5'd0) &&
                (RdW == instruction[24:20])
            )

                exp_RD2 = ResultW;

            else

                exp_RD2 = model_reg[instruction[24:20]];


            // ----------------------------------------------------
            // Reset
            // ----------------------------------------------------

            if (!rst) begin

                exp_RegWrite = 1'b0;
                exp_ResultSrc = 2'b00;
                exp_MemWrite = 1'b0;
                exp_MemRead = 1'b0;
                exp_jump = 1'b0;
                exp_Branch = 1'b0;
                exp_ALUControl = 4'b0000;
                exp_ALUSrcA = 2'b00;
                exp_ALUSrcB = 1'b0;

                exp_RD1 = 32'b0;
                exp_RD2 = 32'b0;

                exp_PC = 32'b0;
                exp_PcPlus4 = 32'b0;

                exp_Rd = 5'b0;
                exp_RS1 = 5'b0;
                exp_RS2 = 5'b0;

                exp_Imm = 32'b0;

                exp_funct3 = 3'b0;

            end


            // ----------------------------------------------------
            // Flush has priority over Stall
            // ----------------------------------------------------

            else if (flush) begin

                exp_RegWrite = 1'b0;
                exp_ResultSrc = 2'b00;
                exp_MemWrite = 1'b0;
                exp_MemRead = 1'b0;
                exp_jump = 1'b0;
                exp_Branch = 1'b0;
                exp_ALUControl = 4'b0000;
                exp_ALUSrcA = 2'b00;
                exp_ALUSrcB = 1'b0;

                exp_RD1 = 32'b0;
                exp_RD2 = 32'b0;

                exp_PC = 32'b0;
                exp_PcPlus4 = 32'b0;

                exp_Rd = 5'b0;
                exp_RS1 = 5'b0;
                exp_RS2 = 5'b0;

                exp_Imm = 32'b0;

                exp_funct3 = 3'b0;

            end


            // ----------------------------------------------------
            // Stall holds previous ID/EX state
            // ----------------------------------------------------

            else if (stall) begin

                exp_RegWrite = prev_RegWrite;
                exp_ResultSrc = prev_ResultSrc;
                exp_MemWrite = prev_MemWrite;
                exp_MemRead = prev_MemRead;
                exp_jump = prev_jump;
                exp_Branch = prev_Branch;

                exp_ALUControl = prev_ALUControl;

                exp_ALUSrcA = prev_ALUSrcA;
                exp_ALUSrcB = prev_ALUSrcB;

                exp_RD1 = prev_RD1;
                exp_RD2 = prev_RD2;

                exp_PC = prev_PC;
                exp_PcPlus4 = prev_PcPlus4;

                exp_Rd = prev_Rd;
                exp_RS1 = prev_RS1;
                exp_RS2 = prev_RS2;

                exp_Imm = prev_Imm;

                exp_funct3 = prev_funct3;

            end


            // ----------------------------------------------------
            // Normal capture
            // ----------------------------------------------------

            else begin

                exp_PC = pc;

                exp_PcPlus4 = pc4;

            end


            // ----------------------------------------------------
            // Clock the ID/EX register
            // ----------------------------------------------------

            @(posedge clk);

            #1;


            check_outputs(instruction);


            // ----------------------------------------------------
            // Coverage
            // ----------------------------------------------------

            cov.sample();


            // ----------------------------------------------------
            // Update reference register file
            // ----------------------------------------------------

            if (
                RegWriteW &&
                (RdW != 5'd0)
            )

                model_reg[RdW] = ResultW;


            model_reg[0] = 32'b0;


            // ----------------------------------------------------
            // Save expected pipeline state
            // ----------------------------------------------------

            if (rst && !flush && !stall) begin

                prev_RegWrite = exp_RegWrite;
                prev_ResultSrc = exp_ResultSrc;
                prev_MemWrite = exp_MemWrite;
                prev_MemRead = exp_MemRead;
                prev_jump = exp_jump;
                prev_Branch = exp_Branch;

                prev_ALUControl = exp_ALUControl;

                prev_ALUSrcA = exp_ALUSrcA;
                prev_ALUSrcB = exp_ALUSrcB;

                prev_RD1 = exp_RD1;
                prev_RD2 = exp_RD2;

                prev_PC = exp_PC;
                prev_PcPlus4 = exp_PcPlus4;

                prev_Rd = exp_Rd;
                prev_RS1 = exp_RS1;
                prev_RS2 = exp_RS2;

                prev_Imm = exp_Imm;

                prev_funct3 = exp_funct3;

            end


            if (rst && flush) begin

                prev_RegWrite = 1'b0;
                prev_ResultSrc = 2'b00;
                prev_MemWrite = 1'b0;
                prev_MemRead = 1'b0;
                prev_jump = 1'b0;
                prev_Branch = 1'b0;

                prev_ALUControl = 4'b0000;

                prev_ALUSrcA = 2'b00;
                prev_ALUSrcB = 1'b0;

                prev_RD1 = 32'b0;
                prev_RD2 = 32'b0;

                prev_PC = 32'b0;
                prev_PcPlus4 = 32'b0;

                prev_Rd = 5'b0;
                prev_RS1 = 5'b0;
                prev_RS2 = 5'b0;

                prev_Imm = 32'b0;

                prev_funct3 = 3'b0;

            end

        end

    endtask


    // ============================================================
    // SEED REGISTER FILE
    // ============================================================

    task automatic seed_registers;

        begin

            RegWriteW = 1'b1;

            ResultW = 32'h11111111;
            RdW = 5'd1;

            @(posedge clk);
            #1;


            ResultW = 32'h22222222;
            RdW = 5'd2;

            @(posedge clk);
            #1;


            ResultW = 32'h33333333;
            RdW = 5'd3;

            @(posedge clk);
            #1;


            ResultW = 32'hAAAAAAAA;
            RdW = 5'd31;

            @(posedge clk);
            #1;


            RegWriteW = 1'b0;

            ResultW = 32'b0;

            RdW = 5'd0;


            model_reg[1] = 32'h11111111;

            model_reg[2] = 32'h22222222;

            model_reg[3] = 32'h33333333;

            model_reg[31] = 32'hAAAAAAAA;

            model_reg[0] = 32'b0;

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        InstrD = 32'b0;

        PCD = 32'h00001000;

        PcPlus4D = 32'h00001004;

        RegWriteW = 1'b0;

        ResultW = 32'b0;

        RdW = 5'd0;

        StallD = 1'b0;

        FlushD = 1'b0;


        test_count = 0;

        pass_count = 0;

        fail_count = 0;

        assertion_failures = 0;


        for (i = 0; i < 32; i = i + 1)

            model_reg[i] = 32'b0;


        prev_RegWrite = 1'b0;
        prev_ResultSrc = 2'b00;
        prev_MemWrite = 1'b0;
        prev_MemRead = 1'b0;
        prev_jump = 1'b0;
        prev_Branch = 1'b0;

        prev_ALUControl = 4'b0000;

        prev_ALUSrcA = 2'b00;
        prev_ALUSrcB = 1'b0;

        prev_RD1 = 32'b0;
        prev_RD2 = 32'b0;

        prev_PC = 32'b0;
        prev_PcPlus4 = 32'b0;

        prev_Rd = 5'b0;
        prev_RS1 = 5'b0;
        prev_RS2 = 5'b0;

        prev_Imm = 32'b0;

        prev_funct3 = 3'b0;


        cov = new();


        $display("");
        $display("================================================");
        $display(" DECODE STAGE VERIFICATION");
        $display("================================================");
        $display("");


        // ========================================================
        // RESET
        // ========================================================

        rst = 1'b0;

        #2;


        assert (
            RegWriteE == 1'b0 &&
            MemWriteE == 1'b0 &&
            MemReadE == 1'b0 &&
            jumpE == 1'b0 &&
            BranchE == 1'b0 &&
            RdE == 5'd0
        )
        else begin

            $error("RESET ASSERTION FAILED");

            assertion_failures =
                assertion_failures + 1;

        end


        rst = 1'b1;

        #2;


        // ========================================================
        // SEED REGISTER FILE
        // ========================================================

        seed_registers();


        // ========================================================
        // EDGE CASES
        // ========================================================

        $display("Running directed RV32I edge cases...");


        // ADD
        drive_and_check(
            make_r(3'b000,1'b0,5'd1,5'd2,5'd4),
            32'h00001000,
            32'h00001004,
            1'b0,
            1'b0
        );


        // SUB
        drive_and_check(
            make_r(3'b000,1'b1,5'd1,5'd2,5'd4),
            32'h00001004,
            32'h00001008,
            1'b0,
            1'b0
        );


        // SLL
        drive_and_check(
            make_r(3'b001,1'b0,5'd1,5'd2,5'd4),
            32'h00001008,
            32'h0000100C,
            1'b0,
            1'b0
        );


        // SLT
        drive_and_check(
            make_r(3'b010,1'b0,5'd1,5'd2,5'd4),
            32'h0000100C,
            32'h00001010,
            1'b0,
            1'b0
        );


        // SLTU
        drive_and_check(
            make_r(3'b011,1'b0,5'd1,5'd2,5'd4),
            32'h00001010,
            32'h00001014,
            1'b0,
            1'b0
        );


        // XOR
        drive_and_check(
            make_r(3'b100,1'b0,5'd1,5'd2,5'd4),
            32'h00001014,
            32'h00001018,
            1'b0,
            1'b0
        );


        // SRL
        drive_and_check(
            make_r(3'b101,1'b0,5'd1,5'd2,5'd4),
            32'h00001018,
            32'h0000101C,
            1'b0,
            1'b0
        );


        // SRA
        drive_and_check(
            make_r(3'b101,1'b1,5'd1,5'd2,5'd4),
            32'h0000101C,
            32'h00001020,
            1'b0,
            1'b0
        );


        // OR
        drive_and_check(
            make_r(3'b110,1'b0,5'd1,5'd2,5'd4),
            32'h00001020,
            32'h00001024,
            1'b0,
            1'b0
        );


        // AND
        drive_and_check(
            make_r(3'b111,1'b0,5'd1,5'd2,5'd4),
            32'h00001024,
            32'h00001028,
            1'b0,
            1'b0
        );


        // ADDI positive
        drive_and_check(
            make_i(7'b0010011,3'b000,5'd1,5'd5,12'h001),
            32'h00001028,
            32'h0000102C,
            1'b0,
            1'b0
        );


        // ADDI negative boundary
        drive_and_check(
            make_i(7'b0010011,3'b000,5'd1,5'd5,12'h800),
            32'h0000102C,
            32'h00001030,
            1'b0,
            1'b0
        );


        // SLLI
        drive_and_check(
            make_i(7'b0010011,3'b001,5'd1,5'd5,12'h01F),
            32'h00001030,
            32'h00001034,
            1'b0,
            1'b0
        );


        // SRLI
        drive_and_check(
            make_i(7'b0010011,3'b101,5'd1,5'd5,12'h01F),
            32'h00001034,
            32'h00001038,
            1'b0,
            1'b0
        );


        // SRAI
        drive_and_check(
            make_i(7'b0010011,3'b101,5'd1,5'd5,12'h41F),
            32'h00001038,
            32'h0000103C,
            1'b0,
            1'b0
        );


        // LOAD
        drive_and_check(
            make_i(7'b0000011,3'b010,5'd1,5'd6,12'h001),
            32'h0000103C,
            32'h00001040,
            1'b0,
            1'b0
        );


        // LOAD negative immediate
        drive_and_check(
            make_i(7'b0000011,3'b010,5'd1,5'd6,12'hFFF),
            32'h00001040,
            32'h00001044,
            1'b0,
            1'b0
        );


        // STORE
        drive_and_check(
            make_s(3'b010,5'd1,5'd2,12'h001),
            32'h00001044,
            32'h00001048,
            1'b0,
            1'b0
        );


        // STORE negative immediate
        drive_and_check(
            make_s(3'b010,5'd31,5'd31,12'h800),
            32'h00001048,
            32'h0000104C,
            1'b0,
            1'b0
        );


        // BEQ
        drive_and_check(
            make_b(3'b000,5'd1,5'd2,13'h0002),
            32'h0000104C,
            32'h00001050,
            1'b0,
            1'b0
        );


        // BNE
        drive_and_check(
            make_b(3'b001,5'd1,5'd2,13'h1FFE),
            32'h00001050,
            32'h00001054,
            1'b0,
            1'b0
        );


        // BLT
        drive_and_check(
            make_b(3'b100,5'd1,5'd2,13'h0002),
            32'h00001054,
            32'h00001058,
            1'b0,
            1'b0
        );


        // BGE
        drive_and_check(
            make_b(3'b101,5'd1,5'd2,13'h1000),
            32'h00001058,
            32'h0000105C,
            1'b0,
            1'b0
        );


        // BLTU
        drive_and_check(
            make_b(3'b110,5'd1,5'd2,13'h0002),
            32'h0000105C,
            32'h00001060,
            1'b0,
            1'b0
        );


        // BGEU
        drive_and_check(
            make_b(3'b111,5'd1,5'd2,13'h1FFE),
            32'h00001060,
            32'h00001064,
            1'b0,
            1'b0
        );


        // JAL
        drive_and_check(
            make_j(5'd1,21'h000002),
            32'h00001064,
            32'h00001068,
            1'b0,
            1'b0
        );


        // JAL max negative
        drive_and_check(
            make_j(5'd31,21'h1FFFFE),
            32'h00001068,
            32'h0000106C,
            1'b0,
            1'b0
        );


        // JALR
        drive_and_check(
            make_i(7'b1100111,3'b000,5'd1,5'd1,12'hFFF),
            32'h0000106C,
            32'h00001070,
            1'b0,
            1'b0
        );


        // LUI
        drive_and_check(
            make_u(7'b0110111,5'd5,20'hFFFFF),
            32'h00001070,
            32'h00001074,
            1'b0,
            1'b0
        );


        // AUIPC
        drive_and_check(
            make_u(7'b0010111,5'd5,20'h80000),
            32'h00001074,
            32'h00001078,
            1'b0,
            1'b0
        );


        // x0 / x0 / x0
        drive_and_check(
            make_r(3'b000,1'b0,5'd0,5'd0,5'd0),
            32'h00001078,
            32'h0000107C,
            1'b0,
            1'b0
        );


        // x31 everywhere
        drive_and_check(
            make_r(3'b000,1'b0,5'd31,5'd31,5'd31),
            32'h0000107C,
            32'h00001080,
            1'b0,
            1'b0
        );


        // Invalid opcode
        drive_and_check(
            32'hFFFFFFFF,
            32'h00001080,
            32'h00001084,
            1'b0,
            1'b0
        );


        // ========================================================
        // WRITEBACK FORWARDING EDGE CASE
        // ========================================================

        $display("Testing register-file writeback forwarding...");

        RegWriteW = 1'b1;

        ResultW = 32'hDEADBEEF;

        RdW = 5'd7;


        drive_and_check(
            make_r(3'b000,1'b0,5'd7,5'd2,5'd8),
            32'h00001084,
            32'h00001088,
            1'b0,
            1'b0
        );


        RegWriteW = 1'b0;

        ResultW = 32'b0;

        RdW = 5'd0;


        // ========================================================
        // STALL EDGE CASE
        // ========================================================

        $display("Testing StallD...");


        drive_and_check(
            make_i(
                7'b0010011,
                3'b000,
                5'd1,
                5'd10,
                12'h001
            ),
            32'h00001088,
            32'h0000108C,
            1'b0,
            1'b0
        );


        drive_and_check(
            make_i(
                7'b0010011,
                3'b000,
                5'd2,
                5'd20,
                12'h002
            ),
            32'h0000108C,
            32'h00001090,
            1'b1,
            1'b0
        );


        // ========================================================
        // FLUSH EDGE CASE
        // ========================================================

        $display("Testing FlushD...");


        drive_and_check(
            make_r(
                3'b000,
                1'b0,
                5'd1,
                5'd2,
                5'd21
            ),
            32'h00001090,
            32'h00001094,
            1'b0,
            1'b1
        );


        // ========================================================
        // FLUSH + STALL
        // FLUSH MUST WIN
        // ========================================================

        $display("Testing FlushD + StallD priority...");


        drive_and_check(
            make_r(
                3'b000,
                1'b0,
                5'd1,
                5'd2,
                5'd22
            ),
            32'h00001094,
            32'h00001098,
            1'b1,
            1'b1
        );


        // ========================================================
        // RANDOM VALID RV32I TESTS
        // ========================================================

        $display("");

        $display(
            "Running 2000 random RV32I decode tests..."
        );


        for (i = 0; i < 2000; i = i + 1) begin

            case ($urandom_range(0,8))

                // R
                0:

                    drive_and_check(
                        make_r(
                            $urandom_range(0,7),
                            $urandom_range(0,1),
                            $urandom_range(0,31),
                            $urandom_range(0,31),
                            $urandom_range(0,31)
                        ),
                        $urandom,
                        $urandom,
                        1'b0,
                        1'b0
                    );


                // I
                1:

                    drive_and_check(
                        make_i(
                            7'b0010011,
                            $urandom_range(0,7),
                            $urandom_range(0,31),
                            $urandom_range(0,31),
                            $urandom
                        ),
                        $urandom,
                        $urandom,
                        1'b0,
                        1'b0
                    );


                // LOAD
                2:

                    drive_and_check(
                        make_i(
                            7'b0000011,
                            $urandom_range(0,4),
                            $urandom_range(0,31),
                            $urandom_range(0,31),
                            $urandom
                        ),
                        $urandom,
                        $urandom,
                        1'b0,
                        1'b0
                    );


                // STORE
                3:

                    drive_and_check(
                        make_s(
                            $urandom_range(0,2),
                            $urandom_range(0,31),
                            $urandom_range(0,31),
                            $urandom
                        ),
                        $urandom,
                        $urandom,
                        1'b0,
                        1'b0
                    );


                // BRANCH
                4:

                    drive_and_check(
                        make_b(
                            $urandom_range(0,7),
                            $urandom_range(0,31),
                            $urandom_range(0,31),
                            $urandom
                        ),
                        $urandom,
                        $urandom,
                        1'b0,
                        1'b0
                    );


                // JAL
                5:

                    drive_and_check(
                        make_j(
                            $urandom_range(0,31),
                            $urandom
                        ),
                        $urandom,
                        $urandom,
                        1'b0,
                        1'b0
                    );


                // JALR
                6:

                    drive_and_check(
                        make_i(
                            7'b1100111,
                            3'b000,
                            $urandom_range(0,31),
                            $urandom_range(0,31),
                            $urandom
                        ),
                        $urandom,
                        $urandom,
                        1'b0,
                        1'b0
                    );


                // LUI
                7:

                    drive_and_check(
                        make_u(
                            7'b0110111,
                            $urandom_range(0,31),
                            $urandom
                        ),
                        $urandom,
                        $urandom,
                        1'b0,
                        1'b0
                    );


                // AUIPC
                default:

                    drive_and_check(
                        make_u(
                            7'b0010111,
                            $urandom_range(0,31),
                            $urandom
                        ),
                        $urandom,
                        $urandom,
                        1'b0,
                        1'b0
                    );

            endcase

        end


        // ========================================================
        // RANDOM HAZARD-CONTROL TESTS
        // ========================================================

        $display("");

        $display(
            "Running 500 random StallD/FlushD tests..."
        );


        for (i = 0; i < 500; i = i + 1) begin

            drive_and_check(
                $urandom,
                $urandom,
                $urandom,
                $urandom_range(0,1),
                $urandom_range(0,1)
            );

        end


        // ========================================================
        // FINAL REPORT
        // ========================================================

        $display("");

        $display("================================================");

        $display(
            " DECODE STAGE VERIFICATION REPORT"
        );

        $display("================================================");

        $display(
            "Total Tests        = %0d",
            test_count
        );

        $display(
            "Passed             = %0d",
            pass_count
        );

        $display(
            "Failed             = %0d",
            fail_count
        );

        $display(
            "Assertion Failures = %0d",
            assertion_failures
        );

        $display(
            "Functional Coverage = %0.2f%%",
            cov.get_coverage()
        );

        $display("================================================");

        $display("");


        if (
            (fail_count == 0) &&
            (assertion_failures == 0)
        ) begin

            $display(
                "******** DECODE STAGE VERIFICATION PASSED ********"
            );

        end
        else begin

            $display(
                "******** DECODE STAGE VERIFICATION FAILED ********"
            );

        end


        $display("");

        $finish;

    end

endmodule