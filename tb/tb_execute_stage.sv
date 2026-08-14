`timescale 1ns / 1ps

module tb_Execute_stage_cov_asrt;

    // ============================================================
    // CLOCK / RESET
    // ============================================================

    logic clk;
    logic rst;

    initial clk = 1'b0;

    always #5 clk = ~clk;


    // ============================================================
    // DUT INPUTS
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

    logic [4:0]  RdE;

    logic [31:0] ImmExtendE;
    logic [31:0] PcPlus4E;

    logic [31:0] ResultW;
    logic [1:0]  ForwardAE;
    logic [1:0]  ForwardBE;

    logic [31:0] ALUResultM_forward;

    logic FlushE;
    logic StallE;

    logic [2:0] funct3E;


    // ============================================================
    // DUT OUTPUTS
    // ============================================================

    logic        RegWriteM;
    logic [1:0]  ResultSrcM;
    logic        MemWriteM;
    logic        MemReadM;

    logic [31:0] ALUResultM;
    logic [31:0] WriteDataM;

    logic [4:0]  RdM;

    logic [31:0] PcPlus4M;

    logic [2:0] funct3M;

    logic [31:0] PcTargetE;
    logic        PcSrcE;


    // ============================================================
    // DUT
    // ============================================================

    Execute_stage dut (

        .clk(clk),
        .rst(rst),

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
        .RdE(RdE),
        .ImmExtendE(ImmExtendE),
        .PcPlus4E(PcPlus4E),

        .ResultW(ResultW),
        .ForwardAE(ForwardAE),
        .ForwardBE(ForwardBE),

        .ALUResultM_forward(ALUResultM_forward),

        .FlushE(FlushE),
        .StallE(StallE),

        .funct3E(funct3E),

        .RegWriteM(RegWriteM),
        .ResultSrcM(ResultSrcM),
        .MemWriteM(MemWriteM),
        .MemReadM(MemReadM),

        .ALUResultM(ALUResultM),
        .WriteDataM(WriteDataM),

        .RdM(RdM),
        .PcPlus4M(PcPlus4M),
        .funct3M(funct3M),

        .PcTargetE(PcTargetE),
        .PcSrcE(PcSrcE)

    );


    // ============================================================
    // SCOREBOARD STATE
    // ============================================================

    logic        exp_RegWriteM;
    logic [1:0]  exp_ResultSrcM;
    logic        exp_MemWriteM;
    logic        exp_MemReadM;

    logic [31:0] exp_ALUResultM;
    logic [31:0] exp_WriteDataM;

    logic [4:0]  exp_RdM;
    logic [31:0] exp_PcPlus4M;
    logic [2:0]  exp_funct3M;


    // ============================================================
    // REFERENCE MODEL VARIABLES
    // ============================================================

    logic [31:0] ref_ForwardAData;
    logic [31:0] ref_ForwardBData;

    logic [31:0] ref_SrcAE;
    logic [31:0] ref_SrcBE;

    logic [31:0] ref_ALUResult;
    logic        ref_zero;
    logic        ref_less_than;

    logic        ref_BranchTaken;

    logic [31:0] ref_PcTarget;
    logic        ref_PcSrc;


    // ============================================================
    // COUNTERS
    // ============================================================

    integer total_checks;
    integer pass_count;
    integer fail_count;

    integer assertion_failures;

    integer edge_tests;
    integer random_tests;

    integer i;


    // ============================================================
    // COVERAGE VARIABLES
    // ============================================================

    logic cov_branch_taken;


    // ============================================================
    // COVERAGE
    // ============================================================

    covergroup ex_coverage;

        cp_alu_control : coverpoint ALUControlE {

            bins ADD = {4'b0000};
            bins SUB = {4'b0001};
            bins AND_OP = {4'b0010};
            bins OR_OP = {4'b0011};
            bins XOR_OP = {4'b0100};
            bins SLL = {4'b0101};
            bins SRL = {4'b0110};
            bins SRA = {4'b0111};
            bins SLTU = {4'b1000};
            bins SLT = {4'b1001};

            bins INVALID = default;

        }


        cp_forward_a : coverpoint ForwardAE {

            bins FROM_RD1 = {2'b00};
            bins FROM_WB = {2'b01};
            bins FROM_MEM = {2'b10};
            bins INVALID = {2'b11};

        }


        cp_forward_b : coverpoint ForwardBE {

            bins FROM_RD2 = {2'b00};
            bins FROM_WB = {2'b01};
            bins FROM_MEM = {2'b10};
            bins INVALID = {2'b11};

        }


        cp_alu_src_a : coverpoint ALUSrcAE {

            bins REG = {2'b00};
            bins PC = {2'b01};
            bins ZERO = {2'b10};
            bins INVALID = {2'b11};

        }


        cp_alu_src_b : coverpoint ALUSrcBE {

            bins REGISTER = {1'b0};
            bins IMMEDIATE = {1'b1};

        }


        cp_branch : coverpoint BranchE {

            bins NO_BRANCH = {1'b0};
            bins BRANCH = {1'b1};

        }


        cp_funct3 : coverpoint funct3E {

            bins BEQ  = {3'b000};
            bins BNE  = {3'b001};
            bins BLT  = {3'b100};
            bins BGE  = {3'b101};
            bins BLTU = {3'b110};
            bins BGEU = {3'b111};

            bins OTHER = default;

        }


        cp_branch_taken : coverpoint cov_branch_taken {

            bins NOT_TAKEN = {1'b0};
            bins TAKEN = {1'b1};

        }


        cp_jump : coverpoint jumpE {

            bins NO_JUMP = {1'b0};
            bins JUMP = {1'b1};

        }


        cp_flush : coverpoint FlushE {

            bins NO_FLUSH = {1'b0};
            bins FLUSH = {1'b1};

        }


        cp_stall : coverpoint StallE {

            bins NO_STALL = {1'b0};
            bins STALL = {1'b1};

        }


        cp_memwrite : coverpoint MemWriteE {

            bins NO_WRITE = {1'b0};
            bins WRITE = {1'b1};

        }


        cp_memread : coverpoint MemReadE {

            bins NO_READ = {1'b0};
            bins READ = {1'b1};

        }


        branch_type_cross :
            cross cp_branch, cp_funct3;

        forwarding_cross :
            cross cp_forward_a, cp_forward_b;

        source_cross :
            cross cp_alu_src_a, cp_alu_src_b;

        branch_result_cross :
            cross cp_funct3, cp_branch_taken;

        control_cross :
            cross cp_flush, cp_stall;

        jump_source_cross :
            cross cp_jump, cp_alu_src_b;

    endgroup


    ex_coverage cov;


    // ============================================================
    // REFERENCE ALU
    // ============================================================

    function automatic [31:0] reference_alu;

        input [31:0] a;
        input [31:0] b;
        input [3:0] op;

        begin

            case(op)

                4'b0000:
                    reference_alu = a + b;

                4'b0001:
                    reference_alu = a - b;

                4'b0010:
                    reference_alu = a & b;

                4'b0011:
                    reference_alu = a | b;

                4'b0100:
                    reference_alu = a ^ b;

                4'b0101:
                    reference_alu = a << b[4:0];

                4'b0110:
                    reference_alu = a >> b[4:0];

                4'b0111:
                    reference_alu = $signed(a) >>> b[4:0];

                4'b1000:
                    reference_alu =
                        (a < b) ? 32'd1 : 32'd0;

                4'b1001:
                    reference_alu =
                        ($signed(a) < $signed(b))
                        ? 32'd1 : 32'd0;

                default:
                    reference_alu = 32'h00000000;

            endcase

        end

    endfunction


    // ============================================================
    // REFERENCE FORWARDING
    // ============================================================

    function automatic [31:0] reference_forward;

        input [31:0] a;
        input [31:0] b;
        input [31:0] c;
        input [1:0]  sel;

        begin

            case(sel)

                2'b00:
                    reference_forward = a;

                2'b01:
                    reference_forward = b;

                2'b10:
                    reference_forward = c;

                default:
                    reference_forward = 32'h00000000;

            endcase

        end

    endfunction


    // ============================================================
    // BUILD REFERENCE MODEL
    // ============================================================

    task automatic calculate_reference;

        begin

            // ----------------------------------------------------
            // Forwarding
            // ----------------------------------------------------

            ref_ForwardAData =
                reference_forward(
                    RD1E,
                    ResultW,
                    ALUResultM_forward,
                    ForwardAE
                );

            ref_ForwardBData =
                reference_forward(
                    RD2E,
                    ResultW,
                    ALUResultM_forward,
                    ForwardBE
                );


            // ----------------------------------------------------
            // ALU source A
            // ----------------------------------------------------

            case(ALUSrcAE)

                2'b00:
                    ref_SrcAE = ref_ForwardAData;

                2'b01:
                    ref_SrcAE = PCE;

                2'b10:
                    ref_SrcAE = 32'd0;

                default:
                    ref_SrcAE = 32'd0;

            endcase


            // ----------------------------------------------------
            // ALU source B
            // ----------------------------------------------------

            if(ALUSrcBE)
                ref_SrcBE = ImmExtendE;
            else
                ref_SrcBE = ref_ForwardBData;


            // ----------------------------------------------------
            // ALU
            // ----------------------------------------------------

            ref_ALUResult =
                reference_alu(
                    ref_SrcAE,
                    ref_SrcBE,
                    ALUControlE
                );

            ref_zero =
                (ref_ALUResult == 32'd0);

            ref_less_than =
                ref_ALUResult[0];


            // ----------------------------------------------------
            // Branch
            // ----------------------------------------------------

            ref_BranchTaken = 1'b0;

            if(BranchE)
            begin

                case(funct3E)

                    3'b000:
                        ref_BranchTaken = ref_zero;

                    3'b001:
                        ref_BranchTaken = !ref_zero;

                    3'b100:
                        ref_BranchTaken = ref_less_than;

                    3'b101:
                        ref_BranchTaken = !ref_less_than;

                    3'b110:
                        ref_BranchTaken = ref_less_than;

                    3'b111:
                        ref_BranchTaken = !ref_less_than;

                    default:
                        ref_BranchTaken = 1'b0;

                endcase

            end


            // ----------------------------------------------------
            // PC target
            // ----------------------------------------------------

            if(jumpE && ALUSrcBE)
            begin

                ref_PcTarget =
                    ref_ALUResult & 32'hFFFFFFFE;

            end
            else
            begin

                ref_PcTarget =
                    PCE + ImmExtendE;

            end


            // ----------------------------------------------------
            // PC source
            // ----------------------------------------------------

            ref_PcSrc =
                ref_BranchTaken | jumpE;


        end

    endtask


    // ============================================================
    // CHECK COMBINATIONAL OUTPUTS
    // ============================================================

    task automatic check_comb;

        begin

            calculate_reference();

            total_checks = total_checks + 1;


            if(PcTargetE !== ref_PcTarget)
            begin

                $display(
                    "FAIL COMB | PC TARGET | A=%h B=%h EXPECTED=%h GOT=%h",
                    PCE,
                    ImmExtendE,
                    ref_PcTarget,
                    PcTargetE
                );

                fail_count = fail_count + 1;

            end


            if(PcSrcE !== ref_PcSrc)
            begin

                $display(
                    "FAIL COMB | PC SRC | Branch=%b Jump=%b Expected=%b Got=%b",
                    BranchE,
                    jumpE,
                    ref_PcSrc,
                    PcSrcE
                );

                fail_count = fail_count + 1;

            end


            // ----------------------------------------------------
            // Assertion: PC source
            // ----------------------------------------------------

            assert(PcSrcE === ref_PcSrc)
            else begin

                $error(
                    "ASSERTION FAILED: PcSrcE"
                );

                assertion_failures =
                    assertion_failures + 1;

            end


            // ----------------------------------------------------
            // Assertion: PC target
            // ----------------------------------------------------

            assert(PcTargetE === ref_PcTarget)
            else begin

                $error(
                    "ASSERTION FAILED: PcTargetE"
                );

                assertion_failures =
                    assertion_failures + 1;

            end


            cov_branch_taken =
                ref_BranchTaken;

            cov.sample();

        end

    endtask


    // ============================================================
    // CHECK PIPELINE REGISTER
    // ============================================================

    task automatic check_pipeline;

        begin

            if(
                (RegWriteM !== exp_RegWriteM) ||
                (ResultSrcM !== exp_ResultSrcM) ||
                (MemWriteM !== exp_MemWriteM) ||
                (MemReadM !== exp_MemReadM) ||
                (ALUResultM !== exp_ALUResultM) ||
                (WriteDataM !== exp_WriteDataM) ||
                (RdM !== exp_RdM) ||
                (PcPlus4M !== exp_PcPlus4M) ||
                (funct3M !== exp_funct3M)
            )
            begin

                $display("");
                $display(
                    "PIPELINE SCOREBOARD FAIL"
                );

                $display(
                    "RW     EXP=%b GOT=%b",
                    exp_RegWriteM,
                    RegWriteM
                );

                $display(
                    "SRC    EXP=%b GOT=%b",
                    exp_ResultSrcM,
                    ResultSrcM
                );

                $display(
                    "MW     EXP=%b GOT=%b",
                    exp_MemWriteM,
                    MemWriteM
                );

                $display(
                    "MR     EXP=%b GOT=%b",
                    exp_MemReadM,
                    MemReadM
                );

                $display(
                    "ALU    EXP=%h GOT=%h",
                    exp_ALUResultM,
                    ALUResultM
                );

                $display(
                    "WDATA  EXP=%h GOT=%h",
                    exp_WriteDataM,
                    WriteDataM
                );

                $display(
                    "RD     EXP=%0d GOT=%0d",
                    exp_RdM,
                    RdM
                );

                $display(
                    "PC4    EXP=%h GOT=%h",
                    exp_PcPlus4M,
                    PcPlus4M
                );

                $display(
                    "F3     EXP=%b GOT=%b",
                    exp_funct3M,
                    funct3M
                );

                fail_count = fail_count + 1;

            end
            else
            begin

                pass_count = pass_count + 1;

            end

        end

    endtask


    // ============================================================
    // UPDATE SCOREBOARD
    // ============================================================

    task automatic update_scoreboard;

        begin

            if(!rst)
            begin

                exp_RegWriteM  = 1'b0;
                exp_ResultSrcM = 2'b00;
                exp_MemWriteM  = 1'b0;
                exp_MemReadM   = 1'b0;

                exp_ALUResultM = 32'd0;
                exp_WriteDataM = 32'd0;

                exp_RdM        = 5'd0;
                exp_PcPlus4M   = 32'd0;
                exp_funct3M    = 3'd0;

            end

            else if(FlushE)
            begin

                exp_RegWriteM  = 1'b0;
                exp_ResultSrcM = 2'b00;
                exp_MemWriteM  = 1'b0;
                exp_MemReadM   = 1'b0;

                exp_ALUResultM = 32'd0;
                exp_WriteDataM = 32'd0;

                exp_RdM        = 5'd0;
                exp_PcPlus4M   = 32'd0;
                exp_funct3M    = 3'd0;

            end

            else if(StallE)
            begin

                // HOLD

            end

            else
            begin

                calculate_reference();

                exp_RegWriteM  = RegWriteE;
                exp_ResultSrcM = ResultSrcE;
                exp_MemWriteM  = MemWriteE;
                exp_MemReadM   = MemReadE;

                exp_ALUResultM = ref_ALUResult;
                exp_WriteDataM = ref_ForwardBData;

                exp_RdM        = RdE;
                exp_PcPlus4M   = PcPlus4E;
                exp_funct3M    = funct3E;

            end

        end

    endtask


    // ============================================================
    // DRIVE DEFAULTS
    // ============================================================

    task automatic clear_inputs;

        begin

            RegWriteE = 1'b0;
            ResultSrcE = 2'b00;
            MemWriteE = 1'b0;
            MemReadE = 1'b0;

            jumpE = 1'b0;
            BranchE = 1'b0;

            ALUControlE = 4'b0000;

            ALUSrcAE = 2'b00;
            ALUSrcBE = 1'b0;

            RD1E = 32'd0;
            RD2E = 32'd0;

            PCE = 32'd0;
            RdE = 5'd0;

            ImmExtendE = 32'd0;
            PcPlus4E = 32'd0;

            ResultW = 32'd0;

            ForwardAE = 2'b00;
            ForwardBE = 2'b00;

            ALUResultM_forward = 32'd0;

            FlushE = 1'b0;
            StallE = 1'b0;

            funct3E = 3'b000;

        end

    endtask


    // ============================================================
    // EDGE CASE TEST
    // ============================================================

    task automatic edge_test;

        input [31:0] a;
        input [31:0] b;
        input [3:0]  alu_op;
        input [1:0]  fwd_a;
        input [1:0]  fwd_b;
        input [1:0]  src_a;
        input        src_b;
        input        branch;
        input [2:0]  f3;
        input        jump;
        input [31:0] pc;
        input [31:0] imm;

        begin

            RD1E = a;
            RD2E = b;

            ALUControlE = alu_op;

            ForwardAE = fwd_a;
            ForwardBE = fwd_b;

            ALUSrcAE = src_a;
            ALUSrcBE = src_b;

            BranchE = branch;
            funct3E = f3;

            jumpE = jump;

            PCE = pc;
            ImmExtendE = imm;

            #1;

            check_comb();

            edge_tests = edge_tests + 1;

        end

    endtask


    // ============================================================
    // INITIAL
    // ============================================================

    initial begin

        cov = new();

        total_checks = 0;
        pass_count = 0;
        fail_count = 0;

        assertion_failures = 0;

        edge_tests = 0;
        random_tests = 0;

        clear_inputs();

        rst = 1'b0;


        // ========================================================
        // RESET
        // ========================================================

        #2;

        assert(
            RegWriteM == 1'b0 &&
            ResultSrcM == 2'b00 &&
            MemWriteM == 1'b0 &&
            MemReadM == 1'b0 &&
            ALUResultM == 32'd0 &&
            WriteDataM == 32'd0 &&
            RdM == 5'd0 &&
            PcPlus4M == 32'd0 &&
            funct3M == 3'd0
        )
        else begin

            $error(
                "RESET ASSERTION FAILED"
            );

            assertion_failures =
                assertion_failures + 1;

        end


        rst = 1'b1;

        #2;


        $display("");
        $display("================================================");
        $display("      EXECUTE STAGE EDGE CASE VERIFICATION");
        $display("================================================");
        $display("");


        // ========================================================
        // ALU EDGE CASES
        // ========================================================

        $display("Testing ADD edge cases...");

        edge_test(
            32'h00000000,
            32'h00000000,
            4'b0000,
            2'b00,
            2'b00,
            2'b00,
            1'b0,
            1'b0,
            3'b000,
            1'b0,
            32'h00001000,
            32'h00000000
        );


        edge_test(
            32'hFFFFFFFF,
            32'h00000001,
            4'b0000,
            2'b00,
            2'b00,
            2'b00,
            1'b0,
            1'b0,
            3'b000,
            1'b0,
            32'h00001000,
            32'h00000004
        );


        $display("Testing SUB edge cases...");

        edge_test(
            32'h00000000,
            32'h00000001,
            4'b0001,
            2'b00,
            2'b00,
            2'b00,
            1'b0,
            1'b0,
            3'b000,
            1'b0,
            32'h00001000,
            32'h00000004
        );


        edge_test(
            32'h80000000,
            32'h00000001,
            4'b0001,
            2'b00,
            2'b00,
            2'b00,
            1'b0,
            1'b0,
            3'b000,
            1'b0,
            32'h00001000,
            32'hFFFFFFFC
        );


        $display("Testing logical operations...");

        edge_test(
            32'hFFFFFFFF,
            32'h00000000,
            4'b0010,
            2'b00,
            2'b00,
            2'b00,
            1'b0,
            1'b0,
            3'b000,
            1'b0,
            32'h00001000,
            32'd0
        );

        edge_test(
            32'h00000000,
            32'hFFFFFFFF,
            4'b0011,
            2'b00,
            2'b00,
            2'b00,
            1'b0,
            1'b0,
            3'b000,
            1'b0,
            32'h00001000,
            32'd0
        );

        edge_test(
            32'hAAAAAAAA,
            32'h55555555,
            4'b0100,
            2'b00,
            2'b00,
            2'b00,
            1'b0,
            1'b0,
            3'b000,
            1'b0,
            32'h00001000,
            32'd0
        );


        $display("Testing shift boundaries...");

        edge_test(
            32'h00000001,
            32'h00000000,
            4'b0101,
            2'b00,
            2'b00,
            2'b00,
            1'b0,
            1'b0,
            3'b000,
            1'b0,
            32'h00001000,
            32'd0
        );

        edge_test(
            32'h00000001,
            32'h0000001F,
            4'b0101,
            2'b00,
            2'b00,
            2'b00,
            1'b0,
            1'b0,
            3'b000,
            1'b0,
            32'h00001000,
            32'd0
        );

        edge_test(
            32'h80000000,
            32'h0000001F,
            4'b0111,
            2'b00,
            2'b00,
            2'b00,
            1'b0,
            1'b0,
            3'b000,
            1'b0,
            32'h00001000,
            32'd0
        );


        // ========================================================
        // FORWARDING
        // ========================================================

        $display("Testing forwarding paths...");

        ResultW = 32'h11111111;
        ALUResultM_forward = 32'h22222222;

        edge_test(
            32'hAAAAAAAA,
            32'hBBBBBBBB,
            4'b0000,
            2'b00,
            2'b00,
            2'b00,
            1'b0,
            1'b0,
            3'b000,
            1'b0,
            32'h1000,
            32'd0
        );

        edge_test(
            32'hAAAAAAAA,
            32'hBBBBBBBB,
            4'b0000,
            2'b01,
            2'b01,
            2'b00,
            1'b0,
            1'b0,
            3'b000,
            1'b0,
            32'h1000,
            32'd0
        );

        edge_test(
            32'hAAAAAAAA,
            32'hBBBBBBBB,
            4'b0000,
            2'b10,
            2'b10,
            2'b00,
            1'b0,
            1'b0,
            3'b000,
            1'b0,
            32'h1000,
            32'd0
        );

        edge_test(
            32'hAAAAAAAA,
            32'hBBBBBBBB,
            4'b0000,
            2'b11,
            2'b11,
            2'b00,
            1'b0,
            1'b0,
            3'b000,
            1'b0,
            32'h1000,
            32'd0
        );


        // ========================================================
        // PC SOURCE A
        // ========================================================

        $display("Testing ALU source-A selection...");

        edge_test(
            32'h11111111,
            32'h22222222,
            4'b0000,
            2'b00,
            2'b00,
            2'b00,
            1'b0,
            1'b0,
            3'b000,
            1'b0,
            32'h12345678,
            32'd1
        );

        edge_test(
            32'h11111111,
            32'h22222222,
            4'b0000,
            2'b00,
            2'b00,
            2'b01,
            1'b0,
            1'b0,
            3'b000,
            1'b0,
            32'h12345678,
            32'd1
        );

        edge_test(
            32'h11111111,
            32'h22222222,
            4'b0000,
            2'b00,
            2'b00,
            2'b10,
            1'b0,
            1'b0,
            3'b000,
            1'b0,
            32'h12345678,
            32'd1
        );


        // ========================================================
        // IMMEDIATE SOURCE B
        // ========================================================

        $display("Testing immediate source-B selection...");

        edge_test(
            32'h00000005,
            32'h00000003,
            4'b0000,
            2'b00,
            2'b00,
            2'b00,
            1'b1,
            1'b0,
            3'b000,
            1'b0,
            32'h1000,
            32'hFFFFFFFC
        );


        // ========================================================
        // BRANCH EDGE CASES
        // ========================================================

        $display("Testing BEQ taken...");

        edge_test(
            32'h12345678,
            32'h12345678,
            4'b0001,
            2'b00,
            2'b00,
            2'b00,
            1'b0,
            1'b1,
            3'b000,
            1'b0,
            32'h00001000,
            32'h00000020
        );


        $display("Testing BEQ not taken...");

        edge_test(
            32'h12345678,
            32'h12345679,
            4'b0001,
            2'b00,
            2'b00,
            2'b00,
            1'b0,
            1'b1,
            3'b000,
            1'b0,
            32'h00001000,
            32'h00000020
        );


        $display("Testing BNE taken...");

        edge_test(
            32'h00000001,
            32'h00000002,
            4'b0001,
            2'b00,
            2'b00,
            2'b00,
            1'b0,
            1'b1,
            3'b001,
            1'b0,
            32'h00001000,
            32'h00000020
        );


        $display("Testing BLTU...");

        edge_test(
            32'h00000001,
            32'hFFFFFFFF,
            4'b1000,
            2'b00,
            2'b00,
            2'b00,
            1'b0,
            1'b1,
            3'b110,
            1'b0,
            32'h00001000,
            32'h00000020
        );


        $display("Testing SLT signed boundary...");

        edge_test(
            32'h80000000,
            32'h00000001,
            4'b1001,
            2'b00,
            2'b00,
            2'b00,
            1'b0,
            1'b1,
            3'b100,
            1'b0,
            32'h00001000,
            32'h00000020
        );


        // ========================================================
        // JAL TARGET
        // ========================================================

        $display("Testing jump target...");

        edge_test(
            32'h00000000,
            32'h00000000,
            4'b0000,
            2'b00,
            2'b00,
            2'b00,
            1'b0,
            1'b0,
            3'b000,
            1'b1,
            32'h00001000,
            32'h00000100
        );


        // ========================================================
        // JALR-LIKE TARGET
        // ========================================================

        $display("Testing jump target LSB clearing...");

        edge_test(
            32'h00001001,
            32'h00000003,
            4'b0000,
            2'b00,
            2'b00,
            2'b00,
            1'b1,
            1'b0,
            3'b000,
            1'b1,
            32'h00001000,
            32'h00000003
        );


        // ========================================================
        // FLUSH
        // ========================================================

        $display("Testing FlushE...");

        RegWriteE = 1'b1;
        ResultSrcE = 2'b11;
        MemWriteE = 1'b1;
        MemReadE = 1'b1;

        ALUControlE = 4'b0000;
        ALUSrcAE = 2'b00;
        ALUSrcBE = 1'b0;

        RD1E = 32'hAAAA5555;
        RD2E = 32'h5555AAAA;

        RdE = 5'd31;
        PcPlus4E = 32'h12345678;

        FlushE = 1'b1;
        StallE = 1'b0;

        @(posedge clk);
        #1;

        assert(
            RegWriteM == 1'b0 &&
            ResultSrcM == 2'b00 &&
            MemWriteM == 1'b0 &&
            MemReadM == 1'b0 &&
            ALUResultM == 32'd0 &&
            WriteDataM == 32'd0 &&
            RdM == 5'd0 &&
            PcPlus4M == 32'd0 &&
            funct3M == 3'd0
        )
        else begin

            $error(
                "FLUSH ASSERTION FAILED"
            );

            assertion_failures =
                assertion_failures + 1;

        end

        update_scoreboard();
        check_pipeline();


        FlushE = 1'b0;


        // ========================================================
        // NORMAL PIPELINE CAPTURE
        // ========================================================

        $display("Testing normal EX/MEM capture...");

        RegWriteE = 1'b1;
        ResultSrcE = 2'b01;
        MemWriteE = 1'b1;
        MemReadE = 1'b0;

        RdE = 5'd15;

        @(posedge clk);
        #1;

        update_scoreboard();
        check_pipeline();


        // ========================================================
        // STALL
        // ========================================================

        $display("Testing StallE...");

        RegWriteE = 1'b0;
        MemWriteE = 1'b0;
        RdE = 5'd2;

        StallE = 1'b1;

        @(posedge clk);
        #1;

        update_scoreboard();
        check_pipeline();


        StallE = 1'b0;


        // ========================================================
        // FLUSH + STALL
        // Actual RTL: FLUSH WINS
        // ========================================================

        $display(
            "Testing FlushE + StallE priority..."
        );

        RegWriteE = 1'b1;
        MemWriteE = 1'b1;
        RdE = 5'd20;

        FlushE = 1'b1;
        StallE = 1'b1;

        @(posedge clk);
        #1;

        update_scoreboard();
        check_pipeline();

        assert(
            RegWriteM == 1'b0 &&
            MemWriteM == 1'b0 &&
            RdM == 5'd0
        )
        else begin

            $error(
                "FlushE/StallE priority assertion failed"
            );

            assertion_failures =
                assertion_failures + 1;

        end

        FlushE = 1'b0;
        StallE = 1'b0;


        // ========================================================
        // RANDOM TESTS
        // ========================================================

        $display("");
        $display("================================================");
        $display("        2000 RANDOM EX STAGE TESTS");
        $display("================================================");
        $display("");


        for(i = 0; i < 2000; i = i + 1)
        begin

            RegWriteE =
                $urandom_range(0,1);

            ResultSrcE =
                $urandom_range(0,3);

            MemWriteE =
                $urandom_range(0,1);

            MemReadE =
                $urandom_range(0,1);

            jumpE =
                $urandom_range(0,1);

            BranchE =
                $urandom_range(0,1);

            ALUControlE =
                $urandom_range(0,15);

            ALUSrcAE =
                $urandom_range(0,3);

            ALUSrcBE =
                $urandom_range(0,1);

            RD1E =
                $urandom;

            RD2E =
                $urandom;

            PCE =
                $urandom;

            RdE =
                $urandom_range(0,31);

            ImmExtendE =
                $urandom;

            PcPlus4E =
                $urandom;

            ResultW =
                $urandom;

            ForwardAE =
                $urandom_range(0,3);

            ForwardBE =
                $urandom_range(0,3);

            ALUResultM_forward =
                $urandom;

            FlushE =
                $urandom_range(0,1);

            StallE =
                $urandom_range(0,1);

            funct3E =
                $urandom_range(0,7);


            // ----------------------------------------------------
            // Combinational scoreboard
            // ----------------------------------------------------

            #1;

            check_comb();


            // ----------------------------------------------------
            // Sequential scoreboard
            // ----------------------------------------------------

            update_scoreboard();

            @(posedge clk);

            #1;

            check_pipeline();


            random_tests =
                random_tests + 1;

        end


        // ========================================================
        // FINAL REPORT
        // ========================================================

        $display("");
        $display("================================================");
        $display("       EXECUTE STAGE VERIFICATION REPORT");
        $display("================================================");

        $display(
            "Edge Case Tests     = %0d",
            edge_tests
        );

        $display(
            "Random Tests        = %0d",
            random_tests
        );

        $display(
            "Total Checks        = %0d",
            total_checks
        );

        $display(
            "Scoreboard Passes   = %0d",
            pass_count
        );

        $display(
            "Failures            = %0d",
            fail_count
        );

        $display(
            "Assertion Failures  = %0d",
            assertion_failures
        );

        $display(
            "Functional Coverage = %0.2f%%",
            cov.get_coverage()
        );

        $display("================================================");
        $display("");


        if(
            (fail_count == 0) &&
            (assertion_failures == 0)
        )
        begin

            $display(
                "******** EXECUTE STAGE VERIFICATION PASSED ********"
            );

        end
        else
        begin

            $display(
                "******** EXECUTE STAGE VERIFICATION FAILED ********"
            );

        end

        $display("");

        $finish;

    end

endmodule
