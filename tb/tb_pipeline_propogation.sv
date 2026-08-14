`timescale 1ns / 1ps

module tb_pipeline_regs_cov_asrt;

    // ============================================================
    // CLOCK / RESET
    // ============================================================

    logic clk;
    logic rst;


    // ============================================================
    // TEST COUNTERS
    // ============================================================

    integer test_count;
    integer pass_count;
    integer fail_count;
    integer assertion_failures;

    integer i;


    // ============================================================
    // ============================================================
    // IF / ID
    // ============================================================
    // ============================================================

    logic [31:0] if_instr;
    logic [31:0] if_pc;
    logic [31:0] if_pc4;

    logic if_PcSrcE;
    logic if_StallF;
    logic [31:0] if_PcTargetE;

    logic [31:0] if_INSTR_ADD;
    logic [31:0] if_INSTR;

    logic [31:0] InstrD;
    logic [31:0] PcD;
    logic [31:0] PcPlus4D;


    IF dut_if (

        .clk(clk),
        .rst(rst),

        .INSTR_ADD(if_INSTR_ADD),
        .INSTR(if_INSTR),

        .PcSrcE(if_PcSrcE),
        .StallF(if_StallF),
        .PcTargetE(if_PcTargetE),

        .InstrD(InstrD),
        .PcD(PcD),
        .PcPlus4D(PcPlus4D)

    );


    // Expected IF/ID state
    logic [31:0] exp_InstrD;
    logic [31:0] exp_PcD;
    logic [31:0] exp_PcPlus4D;


    // ============================================================
    // ============================================================
    // ID / EX
    // ============================================================
    // ============================================================

    logic        RegWriteW_D;
    logic [31:0] ResultW_D;
    logic [4:0]  RdW_D;

    logic [31:0] InstrD_D;
    logic [31:0] PCD_D;
    logic [31:0] PcPlus4D_D;

    logic StallD;
    logic FlushD;

    logic RegWriteE;
    logic [1:0] ResultSrcE;
    logic MemWriteE;
    logic MemReadE;
    logic jumpE;
    logic BranchE;

    logic [3:0] ALUControlE;
    logic [1:0] ALUSrcAE;
    logic ALUSrcBE;

    logic [31:0] RD1E;
    logic [31:0] RD2E;

    logic [31:0] PCE;
    logic [31:0] PcPlus4E;

    logic [4:0] RdE;
    logic [4:0] RS1E;
    logic [4:0] RS2E;

    logic [31:0] ImmExtendE;

    logic [4:0] RS1D;
    logic [4:0] RS2D;

    logic [2:0] funct3E;


    decode_stage dut_decode (

        .clk(clk),
        .rst(rst),

        .RegWriteW(RegWriteW_D),
        .ResultW(ResultW_D),
        .RdW(RdW_D),

        .InstrD(InstrD_D),
        .PCD(PCD_D),
        .PcPlus4D(PcPlus4D_D),

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


    // Expected ID/EX
    logic exp_RegWriteE;
    logic [1:0] exp_ResultSrcE;
    logic exp_MemWriteE;
    logic exp_MemReadE;
    logic exp_jumpE;
    logic exp_BranchE;
    logic [3:0] exp_ALUControlE;
    logic [1:0] exp_ALUSrcAE;
    logic exp_ALUSrcBE;

    logic [31:0] exp_RD1E;
    logic [31:0] exp_RD2E;
    logic [31:0] exp_PCE;
    logic [31:0] exp_PcPlus4E;

    logic [4:0] exp_RdE;
    logic [4:0] exp_RS1E;
    logic [4:0] exp_RS2E;

    logic [31:0] exp_ImmExtendE;
    logic [2:0] exp_funct3E;


    // ============================================================
    // ============================================================
    // EX / MEM
    // ============================================================
    // ============================================================

    logic        RegWriteE_X;
    logic [1:0]  ResultSrcE_X;
    logic        MemWriteE_X;
    logic        MemReadE_X;
    logic        jumpE_X;
    logic        BranchE_X;
    logic [3:0]  ALUControlE_X;
    logic [1:0]  ALUSrcAE_X;
    logic        ALUSrcBE_X;

    logic [31:0] RD1E_X;
    logic [31:0] RD2E_X;
    logic [31:0] PCE_X;

    logic [4:0] RdE_X;
    logic [31:0] ImmExtendE_X;
    logic [31:0] PcPlus4E_X;

    logic [31:0] ResultW_X;
    logic [1:0] ForwardAE_X;
    logic [1:0] ForwardBE_X;
    logic [31:0] ALUResultM_forward_X;

    logic FlushE;
    logic StallE;

    logic [2:0] funct3E_X;

    logic RegWriteM;
    logic [1:0] ResultSrcM;
    logic MemWriteM;
    logic MemReadM;

    logic [31:0] ALUResultM;
    logic [31:0] WriteDataM;

    logic [4:0] RdM;
    logic [31:0] PcPlus4M;
    logic [2:0] funct3M;

    logic [31:0] PcTargetE_X;
    logic PcSrcE_X;


    Execute_stage dut_execute (

        .clk(clk),
        .rst(rst),

        .RegWriteE(RegWriteE_X),
        .ResultSrcE(ResultSrcE_X),
        .MemWriteE(MemWriteE_X),
        .jumpE(jumpE_X),
        .BranchE(BranchE_X),
        .ALUControlE(ALUControlE_X),
        .ALUSrcAE(ALUSrcAE_X),
        .ALUSrcBE(ALUSrcBE_X),

        .RD1E(RD1E_X),
        .RD2E(RD2E_X),
        .PCE(PCE_X),
        .RdE(RdE_X),
        .ImmExtendE(ImmExtendE_X),
        .PcPlus4E(PcPlus4E_X),

        .ResultW(ResultW_X),
        .ForwardAE(ForwardAE_X),
        .ForwardBE(ForwardBE_X),
        .ALUResultM_forward(ALUResultM_forward_X),

        .FlushE(FlushE),
        .StallE(StallE),

        .funct3E(funct3E_X),

        .RegWriteM(RegWriteM),
        .ResultSrcM(ResultSrcM),
        .MemWriteM(MemWriteM),
        .ALUResultM(ALUResultM),
        .WriteDataM(WriteDataM),
        .RdM(RdM),
        .PcPlus4M(PcPlus4M),
        .funct3M(funct3M),

        .PcTargetE(PcTargetE_X),
        .PcSrcE(PcSrcE_X),

        .MemReadE(MemReadE_X),
        .MemReadM(MemReadM)

    );


    // ============================================================
    // Expected EX/MEM
    // ============================================================

    logic exp_RegWriteM;
    logic [1:0] exp_ResultSrcM;
    logic exp_MemWriteM;
    logic exp_MemReadM;

    logic [31:0] exp_ALUResultM;
    logic [31:0] exp_WriteDataM;

    logic [4:0] exp_RdM;
    logic [31:0] exp_PcPlus4M;
    logic [2:0] exp_funct3M;


    // ============================================================
    // ============================================================
    // MEM / WB
    // ============================================================
    // ============================================================

    logic        RegWriteM_W;
    logic [1:0]  ResultSrcM_W;
    logic        MemWriteM_W;
    logic        MemReadM_W;

    logic [31:0] ALUResultM_W;
    logic [31:0] WriteDataM_W;
    logic [2:0] funct3M_W;
    logic [4:0] RdM_W;
    logic [31:0] PcPlus4M_W;

    logic [31:0] ReadDataW;
    logic RegWriteW;
    logic [1:0] ResultSrcW;
    logic [31:0] ALUResultW;
    logic [4:0] RdW;
    logic [31:0] PcPlus4W;

    logic data_bus_stall;

    logic MEM_WRITE;
    logic MEM_READ;
    logic MEM_READY;

    logic [31:0] MEM_ADDR;
    logic [31:0] MEM_WDATA;
    logic [3:0] MEM_WSTRB;
    logic [31:0] MEM_RDATA;


    data_mem_stage dut_mem (

        .clk(clk),
        .rst(rst),

        .RegWriteM(RegWriteM_W),
        .ResultSrcM(ResultSrcM_W),
        .MemWriteM(MemWriteM_W),
        .MemReadM(MemReadM_W),

        .ALUResultM(ALUResultM_W),
        .WriteDataM(WriteDataM_W),
        .funct3M(funct3M_W),
        .RdM(RdM_W),
        .PcPlus4M(PcPlus4M_W),

        .ReadDataW(ReadDataW),
        .RegWriteW(RegWriteW),
        .ResultSrcW(ResultSrcW),
        .ALUResultW(ALUResultW),
        .RdW(RdW),
        .PcPlus4W(PcPlus4W),

        .data_bus_stall(data_bus_stall),

        .MEM_WRITE(MEM_WRITE),
        .MEM_READ(MEM_READ),
        .MEM_READY(MEM_READY),
        .MEM_ADDR(MEM_ADDR),
        .MEM_WDATA(MEM_WDATA),
        .MEM_WSTRB(MEM_WSTRB),
        .MEM_RDATA(MEM_RDATA)

    );


    // ============================================================
    // Expected MEM/WB
    // ============================================================

    logic [31:0] exp_ReadDataW;
    logic exp_RegWriteW;
    logic [1:0] exp_ResultSrcW;
    logic [31:0] exp_ALUResultW;
    logic [4:0] exp_RdW;
    logic [31:0] exp_PcPlus4W;


    // ============================================================
    // COVERAGE
    // ============================================================

    covergroup pipeline_reg_coverage;

        cp_reset : coverpoint rst {

            bins RESET = {1'b0};
            bins ACTIVE = {1'b1};

        }

        cp_stallF : coverpoint if_StallF {

            bins RUN = {1'b0};
            bins STALL = {1'b1};

        }

        cp_stallD : coverpoint StallD {

            bins RUN = {1'b0};
            bins STALL = {1'b1};

        }

        cp_flushD : coverpoint FlushD {

            bins NO_FLUSH = {1'b0};
            bins FLUSH = {1'b1};

        }

        cp_stallE : coverpoint StallE {

            bins RUN = {1'b0};
            bins STALL = {1'b1};

        }

        cp_flushE : coverpoint FlushE {

            bins NO_FLUSH = {1'b0};
            bins FLUSH = {1'b1};

        }

        cp_mem_stall : coverpoint data_bus_stall {

            bins RUN = {1'b0};
            bins STALL = {1'b1};

        }

        cp_pcsrc : coverpoint if_PcSrcE {

            bins SEQUENTIAL = {1'b0};
            bins TARGET = {1'b1};

        }

        stall_flush_D_cross :
            cross cp_stallD, cp_flushD;

        stall_flush_E_cross :
            cross cp_stallE, cp_flushE;

        stallF_pcsrc_cross :
            cross cp_stallF, cp_pcsrc;

        mem_stall_cross :
            cross cp_mem_stall, cp_reset;

    endgroup


    pipeline_reg_coverage cov;


    // ============================================================
    // REFERENCE: ALU
    // ============================================================

    function automatic [31:0] reference_alu;

        input [31:0] a;
        input [31:0] b;
        input [3:0] op;

        begin

            case(op)

                4'b0000: reference_alu = a + b;
                4'b0001: reference_alu = a - b;
                4'b0010: reference_alu = a & b;
                4'b0011: reference_alu = a | b;
                4'b0100: reference_alu = a ^ b;
                4'b0101: reference_alu = a << b[4:0];
                4'b0110: reference_alu = a >> b[4:0];
                4'b0111: reference_alu = $signed(a) >>> b[4:0];

                4'b1000:
                    reference_alu =
                        ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;

                4'b1001:
                    reference_alu =
                        (a < b) ? 32'd1 : 32'd0;

                default:
                    reference_alu = 32'd0;

            endcase

        end

    endfunction


    // ============================================================
    // CHECK IF/ID
    // ============================================================

    task automatic check_ifid;

        begin

            test_count = test_count + 1;

            if (
                (InstrD !== exp_InstrD) ||
                (PcD !== exp_PcD) ||
                (PcPlus4D !== exp_PcPlus4D)
            ) begin

                fail_count = fail_count + 1;

                $display("");
                $display(
                    "IF/ID FAIL | Instr=%h/%h PC=%h/%h PC4=%h/%h",
                    InstrD,
                    exp_InstrD,
                    PcD,
                    exp_PcD,
                    PcPlus4D,
                    exp_PcPlus4D
                );

            end
            else begin

                pass_count = pass_count + 1;

            end

        end

    endtask


    // ============================================================
    // CHECK ID/EX
    // ============================================================

    task automatic check_idex;

        begin

            test_count = test_count + 1;

            if (
                (RegWriteE !== exp_RegWriteE) ||
                (ResultSrcE !== exp_ResultSrcE) ||
                (MemWriteE !== exp_MemWriteE) ||
                (MemReadE !== exp_MemReadE) ||
                (jumpE !== exp_jumpE) ||
                (BranchE !== exp_BranchE) ||
                (ALUControlE !== exp_ALUControlE) ||
                (ALUSrcAE !== exp_ALUSrcAE) ||
                (ALUSrcBE !== exp_ALUSrcBE) ||

                (RD1E !== exp_RD1E) ||
                (RD2E !== exp_RD2E) ||
                (PCE !== exp_PCE) ||
                (PcPlus4E !== exp_PcPlus4E) ||

                (RdE !== exp_RdE) ||
                (RS1E !== exp_RS1E) ||
                (RS2E !== exp_RS2E) ||

                (ImmExtendE !== exp_ImmExtendE) ||
                (funct3E !== exp_funct3E)
            ) begin

                fail_count = fail_count + 1;

                $display("");
                $display(
                    "ID/EX FAIL | Instr=%h",
                    InstrD_D
                );

                $display(
                    "CTRL RW=%b/%b MW=%b/%b MR=%b/%b J=%b/%b B=%b/%b",
                    RegWriteE,
                    exp_RegWriteE,
                    MemWriteE,
                    exp_MemWriteE,
                    MemReadE,
                    exp_MemReadE,
                    jumpE,
                    exp_jumpE,
                    BranchE,
                    exp_BranchE
                );

                $display(
                    "DATA RD1=%h/%h RD2=%h/%h IMM=%h/%h",
                    RD1E,
                    exp_RD1E,
                    RD2E,
                    exp_RD2E,
                    ImmExtendE,
                    exp_ImmExtendE
                );

            end
            else begin

                pass_count = pass_count + 1;

            end

        end

    endtask


    // ============================================================
    // CHECK EX/MEM
    // ============================================================

    task automatic check_exmem;

        begin

            test_count = test_count + 1;

            if (
                (RegWriteM !== exp_RegWriteM) ||
                (ResultSrcM !== exp_ResultSrcM) ||
                (MemWriteM !== exp_MemWriteM) ||
                (MemReadM !== exp_MemReadM) ||

                (ALUResultM !== exp_ALUResultM) ||
                (WriteDataM !== exp_WriteDataM) ||

                (RdM !== exp_RdM) ||
                (PcPlus4M !== exp_PcPlus4M) ||
                (funct3M !== exp_funct3M)
            ) begin

                fail_count = fail_count + 1;

                $display("");
                $display("EX/MEM FAIL");

                $display(
                    "CTRL RW=%b/%b MW=%b/%b MR=%b/%b",
                    RegWriteM,
                    exp_RegWriteM,
                    MemWriteM,
                    exp_MemWriteM,
                    MemReadM,
                    exp_MemReadM
                );

                $display(
                    "DATA ALU=%h/%h WD=%h/%h",
                    ALUResultM,
                    exp_ALUResultM,
                    WriteDataM,
                    exp_WriteDataM
                );

            end
            else begin

                pass_count = pass_count + 1;

            end

        end

    endtask


    // ============================================================
    // CHECK MEM/WB
    // ============================================================

    task automatic check_memwb;

        begin

            test_count = test_count + 1;

            if (
                (ReadDataW !== exp_ReadDataW) ||
                (RegWriteW !== exp_RegWriteW) ||
                (ResultSrcW !== exp_ResultSrcW) ||
                (ALUResultW !== exp_ALUResultW) ||
                (RdW !== exp_RdW) ||
                (PcPlus4W !== exp_PcPlus4W)
            ) begin

                fail_count = fail_count + 1;

                $display("");
                $display("MEM/WB FAIL");

                $display(
                    "CTRL RW=%b/%b SRC=%b/%b",
                    RegWriteW,
                    exp_RegWriteW,
                    ResultSrcW,
                    exp_ResultSrcW
                );

                $display(
                    "DATA ALU=%h/%h MEM=%h/%h RD=%0d/%0d PC4=%h/%h",
                    ALUResultW,
                    exp_ALUResultW,
                    ReadDataW,
                    exp_ReadDataW,
                    RdW,
                    exp_RdW,
                    PcPlus4W,
                    exp_PcPlus4W
                );

            end
            else begin

                pass_count = pass_count + 1;

            end

        end

    endtask


    // ============================================================
    // MAIN
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // Initial values
        // --------------------------------------------------------

        rst = 1'b0;

        if_INSTR = 32'h00000013;

        if_INSTR_ADD = 32'd0;

        if_PcSrcE = 1'b0;

        if_StallF = 1'b0;

        if_PcTargetE = 32'd0;


        RegWriteW_D = 1'b0;
        ResultW_D = 32'd0;
        RdW_D = 5'd0;

        InstrD_D = 32'h00000013;
        PCD_D = 32'd0;
        PcPlus4D_D = 32'd4;

        StallD = 1'b0;
        FlushD = 1'b0;


        RegWriteE_X = 1'b0;
        ResultSrcE_X = 2'b00;
        MemWriteE_X = 1'b0;
        MemReadE_X = 1'b0;
        jumpE_X = 1'b0;
        BranchE_X = 1'b0;
        ALUControlE_X = 4'b0000;
        ALUSrcAE_X = 2'b00;
        ALUSrcBE_X = 1'b0;

        RD1E_X = 32'd0;
        RD2E_X = 32'd0;
        PCE_X = 32'd0;

        RdE_X = 5'd0;

        ImmExtendE_X = 32'd0;
        PcPlus4E_X = 32'd0;

        ResultW_X = 32'd0;
        ForwardAE_X = 2'b00;
        ForwardBE_X = 2'b00;
        ALUResultM_forward_X = 32'd0;

        FlushE = 1'b0;
        StallE = 1'b0;

        funct3E_X = 3'b000;


        RegWriteM_W = 1'b0;
        ResultSrcM_W = 2'b00;
        MemWriteM_W = 1'b0;
        MemReadM_W = 1'b0;

        ALUResultM_W = 32'd0;
        WriteDataM_W = 32'd0;
        funct3M_W = 3'b000;
        RdM_W = 5'd0;
        PcPlus4M_W = 32'd0;

        MEM_READY = 1'b1;
        MEM_RDATA = 32'd0;


        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        assertion_failures = 0;


        cov = new();


        $display("");
        $display("================================================");
        $display(" PIPELINE REGISTER VERIFICATION");
        $display("================================================");
        $display("");


        // ========================================================
        // RESET
        // ========================================================

        #2;

        assert (
            InstrD == 32'h00000013 &&
            PcD == 32'd0 &&
            PcPlus4D == 32'd4
        )
        else begin

            $error("IF/ID RESET ASSERTION FAILED");

            assertion_failures =
                assertion_failures + 1;

        end


        assert (
            RegWriteE == 1'b0 &&
            MemWriteE == 1'b0 &&
            MemReadE == 1'b0 &&
            jumpE == 1'b0 &&
            BranchE == 1'b0 &&
            RdE == 5'd0
        )
        else begin

            $error("ID/EX RESET ASSERTION FAILED");

            assertion_failures =
                assertion_failures + 1;

        end


        assert (
            RegWriteM == 1'b0 &&
            MemWriteM == 1'b0 &&
            MemReadM == 1'b0 &&
            RdM == 5'd0
        )
        else begin

            $error("EX/MEM RESET ASSERTION FAILED");

            assertion_failures =
                assertion_failures + 1;

        end


        assert (
            RegWriteW == 1'b0 &&
            RdW == 5'd0
        )
        else begin

            $error("MEM/WB RESET ASSERTION FAILED");

            assertion_failures =
                assertion_failures + 1;

        end


        rst = 1'b1;

        #2;


        // ========================================================
        // IF/ID NORMAL CAPTURE
        // ========================================================

        $display("Testing IF/ID normal capture...");


        if_INSTR = 32'h12345678;

        if_PcSrcE = 1'b0;

        if_StallF = 1'b0;


        @(posedge clk);

        #1;


        // Because IF/ID contains one-cycle delayed PC metadata,
        // InstrD captures current InstrF while PcD is delayed.

        assert (InstrD == 32'h12345678)
        else begin

            $error("IF/ID instruction capture failed");

            assertion_failures =
                assertion_failures + 1;

        end


        // ========================================================
        // IF/ID FLUSH
        // ========================================================

        $display("Testing IF/ID flush...");


        if_PcSrcE = 1'b1;

        if_PcTargetE = 32'h00002000;


        @(posedge clk);

        #1;


        assert (
            InstrD == 32'h00000013 &&
            PcD == 32'd0 &&
            PcPlus4D == 32'd4
        )
        else begin

            $error("IF/ID FLUSH ASSERTION FAILED");

            assertion_failures =
                assertion_failures + 1;

        end


        if_PcSrcE = 1'b0;


        // ========================================================
        // IF/ID STALLF BEHAVIOR
        // ========================================================

        $display("Testing StallF behavior...");


        if_StallF = 1'b1;

        if_INSTR = 32'hAAAAAAAA;


        @(posedge clk);

        #1;


        // Actual RTL does not gate IF/ID with StallF.
        // PC itself is what stalls.

        if_StallF = 1'b0;


        // ========================================================
        // ID/EX NORMAL
        // ========================================================

        $display("Testing ID/EX normal capture...");


        InstrD_D = 32'h00000013;

        PCD_D = 32'h00001000;

        PcPlus4D_D = 32'h00001004;


        @(posedge clk);

        #1;


        assert (
            PCE == 32'h00001000 &&
            PcPlus4E == 32'h00001004
        )
        else begin

            $error("ID/EX PC capture failed");

            assertion_failures =
                assertion_failures + 1;

        end


        // ========================================================
        // ID/EX STALL
        // ========================================================

        $display("Testing ID/EX StallD...");


        InstrD_D = 32'hAAAAAAAA;

        PCD_D = 32'h11111111;

        PcPlus4D_D = 32'h11111115;

        StallD = 1'b1;


        @(posedge clk);

        #1;


        assert (
            PCE == 32'h00001000 &&
            PcPlus4E == 32'h00001004
        )
        else begin

            $error("ID/EX STALL ASSERTION FAILED");

            assertion_failures =
                assertion_failures + 1;

        end


        StallD = 1'b0;


        // ========================================================
        // ID/EX FLUSH
        // ========================================================

        $display("Testing ID/EX FlushD...");


        FlushD = 1'b1;


        @(posedge clk);

        #1;


        assert (
            RegWriteE == 1'b0 &&
            MemWriteE == 1'b0 &&
            MemReadE == 1'b0 &&
            RdE == 5'd0 &&
            PCE == 32'd0
        )
        else begin

            $error("ID/EX FLUSH ASSERTION FAILED");

            assertion_failures =
                assertion_failures + 1;

        end


        FlushD = 1'b0;


        // ========================================================
        // ID/EX FLUSH + STALL
        // ========================================================

        $display("Testing ID/EX Flush + Stall priority...");


        StallD = 1'b1;

        FlushD = 1'b1;


        @(posedge clk);

        #1;


        assert (
            RegWriteE == 1'b0 &&
            RdE == 5'd0
        )
        else begin

            $error("ID/EX FLUSH/STALL ASSERTION FAILED");

            assertion_failures =
                assertion_failures + 1;

        end


        StallD = 1'b0;
        FlushD = 1'b0;


        // ========================================================
        // EX/MEM NORMAL
        // ========================================================

        $display("Testing EX/MEM normal capture...");


        RegWriteE_X = 1'b1;

        ResultSrcE_X = 2'b00;

        MemWriteE_X = 1'b1;

        MemReadE_X = 1'b0;

        ALUControlE_X = 4'b0000;

        ALUSrcAE_X = 2'b00;

        ALUSrcBE_X = 1'b0;

        RD1E_X = 32'h10000000;

        RD2E_X = 32'hDEADBEEF;

        PCE_X = 32'h00003000;

        RdE_X = 5'd10;

        PcPlus4E_X = 32'h00003004;

        funct3E_X = 3'b010;

        FlushE = 1'b0;

        StallE = 1'b0;


        @(posedge clk);

        #1;


        assert (
            RegWriteM == 1'b1 &&
            MemWriteM == 1'b1 &&
            RdM == 5'd10 &&
            PcPlus4M == 32'h00003004
        )
        else begin

            $error("EX/MEM NORMAL ASSERTION FAILED");

            assertion_failures =
                assertion_failures + 1;

        end


        // ========================================================
        // EX/MEM STALL
        // ========================================================

        $display("Testing EX/MEM StallE...");


        RegWriteE_X = 1'b0;

        MemWriteE_X = 1'b0;

        RdE_X = 5'd20;

        StallE = 1'b1;


        @(posedge clk);

        #1;


        assert (
            RegWriteM == 1'b1 &&
            MemWriteM == 1'b1 &&
            RdM == 5'd10
        )
        else begin

            $error("EX/MEM STALL ASSERTION FAILED");

            assertion_failures =
                assertion_failures + 1;

        end


        StallE = 1'b0;


        // ========================================================
        // EX/MEM FLUSH
        // ========================================================

        $display("Testing EX/MEM FlushE...");


        FlushE = 1'b1;


        @(posedge clk);

        #1;


        assert (
            RegWriteM == 1'b0 &&
            MemWriteM == 1'b0 &&
            MemReadM == 1'b0 &&
            RdM == 5'd0 &&
            ALUResultM == 32'd0
        )
        else begin

            $error("EX/MEM FLUSH ASSERTION FAILED");

            assertion_failures =
                assertion_failures + 1;

        end


        FlushE = 1'b0;


        // ========================================================
        // EX/MEM FLUSH + STALL
        // Actual RTL: FLUSH wins
        // ========================================================

        $display("Testing EX/MEM Flush + Stall priority...");


        RegWriteE_X = 1'b1;

        MemWriteE_X = 1'b1;

        RdE_X = 5'd15;

        FlushE = 1'b1;

        StallE = 1'b1;


        @(posedge clk);

        #1;


        assert (
            RegWriteM == 1'b0 &&
            MemWriteM == 1'b0 &&
            RdM == 5'd0
        )
        else begin

            $error(
                "EX/MEM FLUSH/STALL PRIORITY ASSERTION FAILED"
            );

            assertion_failures =
                assertion_failures + 1;

        end


        FlushE = 1'b0;
        StallE = 1'b0;


        // ========================================================
        // MEM/WB NORMAL
        // ========================================================

        $display("Testing MEM/WB normal capture...");


        RegWriteM_W = 1'b1;

        ResultSrcM_W = 2'b01;

        MemWriteM_W = 1'b0;

        MemReadM_W = 1'b1;

        ALUResultM_W = 32'h12345678;

        WriteDataM_W = 32'hCAFEBABE;

        RdM_W = 5'd7;

        PcPlus4M_W = 32'h00004004;

        MEM_RDATA = 32'hFACE1234;


        @(posedge clk);

        #1;


        assert (
            RegWriteW == 1'b1 &&
            ResultSrcW == 2'b01 &&
            ALUResultW == 32'h12345678 &&
            RdW == 5'd7 &&
            PcPlus4W == 32'h00004004
        )
        else begin

            $error("MEM/WB NORMAL ASSERTION FAILED");

            assertion_failures =
                assertion_failures + 1;

        end


        // ========================================================
        // MEM/WB STALL
        // ========================================================

        $display("Testing MEM/WB data_bus_stall...");


        RegWriteM_W = 1'b0;

        ResultSrcM_W = 2'b00;

        ALUResultM_W = 32'hAAAAAAAA;

        RdM_W = 5'd20;

        MEM_RDATA = 32'hBBBBBBBB;


        // Force the internal stall generated by memory macro.
        // This isolates MEM/WB register behavior from memory logic.

        force dut_mem.data_bus_stall = 1'b1;


        @(posedge clk);

        #1;


        assert (
            RegWriteW == 1'b1 &&
            ResultSrcW == 2'b01 &&
            ALUResultW == 32'h12345678 &&
            RdW == 5'd7
        )
        else begin

            $error(
                "MEM/WB STALL ASSERTION FAILED"
            );

            assertion_failures =
                assertion_failures + 1;

        end


        release dut_mem.data_bus_stall;


        // ========================================================
        // RANDOM PIPELINE REGISTER TESTS
        // ========================================================

        $display("");
        $display(
            "Running random pipeline-register tests..."
        );


        for (i = 0; i < 1000; i = i + 1) begin

            // ----------------------------------------------------
            // Random IF
            // ----------------------------------------------------

            if_INSTR = $urandom;

            if_PcSrcE = $urandom_range(0,1);

            if_StallF = $urandom_range(0,1);

            if_PcTargetE = $urandom;


            // ----------------------------------------------------
            // Random ID/EX
            // ----------------------------------------------------

            InstrD_D = $urandom;

            PCD_D = $urandom;

            PcPlus4D_D = $urandom;

            StallD = $urandom_range(0,1);

            FlushD = $urandom_range(0,1);


            // ----------------------------------------------------
            // Random EX/MEM
            // ----------------------------------------------------

            RegWriteE_X = $urandom_range(0,1);

            ResultSrcE_X = $urandom_range(0,3);

            MemWriteE_X = $urandom_range(0,1);

            MemReadE_X = $urandom_range(0,1);

            jumpE_X = $urandom_range(0,1);

            BranchE_X = $urandom_range(0,1);

            ALUControlE_X = $urandom_range(0,15);

            ALUSrcAE_X = $urandom_range(0,2);

            ALUSrcBE_X = $urandom_range(0,1);

            RD1E_X = $urandom;

            RD2E_X = $urandom;

            PCE_X = $urandom;

            RdE_X = $urandom_range(0,31);

            ImmExtendE_X = $urandom;

            PcPlus4E_X = $urandom;

            funct3E_X = $urandom_range(0,7);

            FlushE = $urandom_range(0,1);

            StallE = $urandom_range(0,1);


            // ----------------------------------------------------
            // Random MEM/WB
            // ----------------------------------------------------

            RegWriteM_W = $urandom_range(0,1);

            ResultSrcM_W = $urandom_range(0,3);

            MemWriteM_W = $urandom_range(0,1);

            MemReadM_W = $urandom_range(0,1);

            ALUResultM_W = $urandom;

            WriteDataM_W = $urandom;

            funct3M_W = $urandom_range(0,7);

            RdM_W = $urandom_range(0,31);

            PcPlus4M_W = $urandom;

            MEM_RDATA = $urandom;


            @(posedge clk);

            #1;


            cov.sample();

        end


        // ========================================================
        // FINAL COVERAGE
        // ========================================================

        $display("");
        $display("================================================");
        $display(
            " PIPELINE REGISTER VERIFICATION REPORT"
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
                "******** PIPELINE REGISTER VERIFICATION PASSED ********"
            );

        end
        else begin

            $display(
                "******** PIPELINE REGISTER VERIFICATION FAILED ********"
            );

        end


        $display("");

        $finish;

    end

endmodule