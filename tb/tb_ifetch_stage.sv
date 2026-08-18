`timescale 1ns / 1ps

module tb_IF_cov_asrt;

    // ============================================================
    // CLOCK / RESET
    // ============================================================

    logic clk;
    logic rst;

    initial clk = 1'b0;
    always #5 clk = ~clk;


    // ============================================================
    // DUT INTERFACE
    // ============================================================

    logic [31:0] INSTR_ADD;
    logic [31:0] INSTR;

    logic        PcSrcE;
    logic        StallF;
    logic [31:0] PcTargetE;

    logic [31:0] InstrD;
    logic [31:0] PcD;
    logic [31:0] PcPlus4D;


    // ============================================================
    // SYNCHRONOUS INSTRUCTION MEMORY MODEL
    //
    // Address seen at cycle N is returned on cycle N+1.
    // This models the external synchronous SRAM/macro timing.
    // ============================================================

    logic [31:0] imem [0:255];

    integer i;

    always @(posedge clk or negedge rst) begin
        if (!rst)
            INSTR <= 32'h00000013;
        else
            INSTR <= imem[INSTR_ADD[9:2]];
    end


    // ============================================================
    // DUT
    // ============================================================

    IF dut (
        .clk       (clk),
        .rst       (rst),
        .INSTR_ADD (INSTR_ADD),
        .INSTR     (INSTR),
        .PcSrcE    (PcSrcE),
        .StallF    (StallF),
        .PcTargetE (PcTargetE),
        .InstrD    (InstrD),
        .PcD       (PcD),
        .PcPlus4D  (PcPlus4D)
    );


    // ============================================================
    // INDEPENDENT REFERENCE MODEL
    // ============================================================

    logic [31:0] r_pc;

    logic [31:0] r_instr_f;
    logic [31:0] r_instr_f_pc;
    logic        r_instr_f_valid;

    logic [31:0] r_pcd_delay;
    logic [31:0] r_pc4d_delay;

    logic [31:0] r_instr_d;
    logic [31:0] r_pcd;
    logic [31:0] r_pc4d;
    logic [31:0] r_instr_d_pc;
    logic        r_instr_d_valid;

    logic        r_pcsrc_delay;
    logic        r_stall_reg;

    logic [31:0] r_sinstr;
    logic [31:0] r_sinstr_pc;
    logic        r_sinstr_valid;

    // Per-cycle model events used for assertions and coverage.
    logic        model_flush_this_cycle;
    logic        model_stall_entry;
    logic        model_stall_release;


    // ============================================================
    // SCOREBOARD / ASSERTION COUNTERS
    // ============================================================

    integer scoreboard_checks;
    integer scoreboard_passes;
    integer scoreboard_failures;
    integer assertion_failures;

    integer edge_cases;
    integer random_cases;


    // ============================================================
    // COVERAGE
    // ============================================================

    logic cov_flush;
    logic cov_stall_entry;
    logic cov_stall_release;
    logic cov_valid_instruction;

    covergroup if_coverage;

        cp_stall : coverpoint StallF {
            bins RUN   = {1'b0};
            bins STALL = {1'b1};
        }

        cp_pcsrc : coverpoint PcSrcE {
            bins SEQUENTIAL = {1'b0};
            bins REDIRECT   = {1'b1};
        }

        cp_flush : coverpoint cov_flush {
            bins NO_FLUSH = {1'b0};
            bins FLUSH    = {1'b1};
        }

        cp_stall_entry : coverpoint cov_stall_entry {
            bins NO_ENTRY = {1'b0};
            bins ENTRY    = {1'b1};
        }

        cp_stall_release : coverpoint cov_stall_release {
            bins NO_RELEASE = {1'b0};
            bins RELEASE    = {1'b1};
        }

        cp_valid : coverpoint cov_valid_instruction {
            bins BUBBLE = {1'b0};
            bins VALID  = {1'b1};
        }

        cp_pc_low : coverpoint PcD[1:0] {
            bins ALIGNED = {2'b00};
            bins OTHER   = default;
        }

        cp_opcode : coverpoint InstrD[6:0] {
            bins R      = {7'b0110011};
            bins I      = {7'b0010011};
            bins LOAD   = {7'b0000011};
            bins STORE  = {7'b0100011};
            bins BRANCH = {7'b1100011};
            bins JAL    = {7'b1101111};
            bins JALR   = {7'b1100111};
            bins LUI    = {7'b0110111};
            bins AUIPC  = {7'b0010111};
            bins OTHER  = default;
        }

        stall_flush_cross : cross cp_stall, cp_flush;
        redirect_stall_cross : cross cp_pcsrc, cp_stall;
        stall_transition_cross : cross cp_stall_entry, cp_stall_release;

    endgroup

    if_coverage cov;


    // ============================================================
    // MEMORY IMAGE
    // ============================================================

    task automatic init_memory;
        integer m;
        begin
            for (m = 0; m < 256; m = m + 1)
                imem[m] = 32'h00000013;

            // Sequential stream: PC = 0,4,8,...
            imem[0]  = 32'h00100093;
            imem[1]  = 32'h00200113;
            imem[2]  = 32'h00300193;
            imem[3]  = 32'h00400213;
            imem[4]  = 32'h00500293;
            imem[5]  = 32'h00600313;
            imem[6]  = 32'h00700393;
            imem[7]  = 32'h00800413;

            // Target 0x40
            imem[16] = 32'h10100093;
            imem[17] = 32'h10200113;
            imem[18] = 32'h10300193;
            imem[19] = 32'h10400213;

            // Target 0x80
            imem[32] = 32'h20100093;
            imem[33] = 32'h20200113;
            imem[34] = 32'h20300193;
            imem[35] = 32'h20400213;

            // Target 0x100
            imem[64] = 32'h30100093;
            imem[65] = 32'h30200113;
            imem[66] = 32'h30300193;
            imem[67] = 32'h30400213;
        end
    endtask


    // ============================================================
    // REFERENCE RESET
    // ============================================================

    task automatic reset_model;
        begin
            r_pc = 32'h00000000;

            r_instr_f = 32'h00000013;
            r_instr_f_pc = 32'h00000000;
            r_instr_f_valid = 1'b0;

            r_pcd_delay = 32'h00000000;
            r_pc4d_delay = 32'h00000000;

            r_instr_d = 32'h00000013;
            r_pcd = 32'h00000000;
            r_pc4d = 32'h00000004;
            r_instr_d_pc = 32'h00000000;
            r_instr_d_valid = 1'b0;

            r_pcsrc_delay = 1'b0;
            r_stall_reg = 1'b0;

            r_sinstr = 32'h00000013;
            r_sinstr_pc = 32'h00000000;
            r_sinstr_valid = 1'b0;

            model_flush_this_cycle = 1'b0;
            model_stall_entry = 1'b0;
            model_stall_release = 1'b0;
        end
    endtask


    // ============================================================
    // CYCLE ACCURATE REFERENCE MODEL
    //
    // The model uses OLD state for all RHS values, exactly as
    // nonblocking assignments in the DUT require.
    // ============================================================

    task automatic model_step;

        reg [31:0] old_pc;
        reg [31:0] old_instr_f;
        reg [31:0] old_instr_f_pc;
        reg        old_instr_f_valid;

        reg [31:0] old_pcd_delay;
        reg [31:0] old_pc4d_delay;

        reg [31:0] old_instr_d;
        reg [31:0] old_pcd;
        reg [31:0] old_pc4d;
        reg [31:0] old_instr_d_pc;
        reg        old_instr_d_valid;

        reg        old_pcsrc_delay;
        reg        old_stall_reg;

        reg [31:0] old_sinstr;
        reg [31:0] old_sinstr_pc;
        reg        old_sinstr_valid;

        reg [31:0] old_pc4f;
        reg [31:0] next_pc;
        reg        flush_now;

        begin
            old_pc = r_pc;

            old_instr_f = r_instr_f;
            old_instr_f_pc = r_instr_f_pc;
            old_instr_f_valid = r_instr_f_valid;

            old_pcd_delay = r_pcd_delay;
            old_pc4d_delay = r_pc4d_delay;

            old_instr_d = r_instr_d;
            old_pcd = r_pcd;
            old_pc4d = r_pc4d;
            old_instr_d_pc = r_instr_d_pc;
            old_instr_d_valid = r_instr_d_valid;

            old_pcsrc_delay = r_pcsrc_delay;
            old_stall_reg = r_stall_reg;

            old_sinstr = r_sinstr;
            old_sinstr_pc = r_sinstr_pc;
            old_sinstr_valid = r_sinstr_valid;

            old_pc4f = old_pc + 32'd4;

            // ----------------------------------------------------
            // RESET
            // ----------------------------------------------------
            if (!rst) begin
                reset_model();
            end
            else begin

                // ------------------------------------------------
                // PC register
                // ------------------------------------------------
                if (!StallF) begin
                    if (PcSrcE)
                        next_pc = PcTargetE;
                    else
                        next_pc = old_pc4f;

                    r_pc = next_pc;
                end
                else begin
                    r_pc = old_pc;
                end

                // ------------------------------------------------
                // Per-cycle events.
                // ------------------------------------------------
                flush_now = PcSrcE | old_pcsrc_delay;
                model_flush_this_cycle = flush_now;
                model_stall_entry = StallF && !old_stall_reg;
                model_stall_release = (!StallF) && old_stall_reg;

                if (flush_now) begin
                    r_instr_d = 32'h00000013;
                    r_pcd = 32'h00000000;
                    r_pc4d = 32'h00000004;
                    r_pcd_delay = 32'h00000000;
                    r_pc4d_delay = 32'h00000000;

                    r_instr_d_pc = 32'h00000000;
                    r_instr_d_valid = 1'b0;
                end
                else if (StallF) begin
                    r_instr_d = old_instr_d;
                    r_pcd = old_pcd;
                    r_pc4d = old_pc4d;
                    r_pcd_delay = old_pcd_delay;
                    r_pc4d_delay = old_pc4d_delay;

                    r_instr_d_pc = old_instr_d_pc;
                    r_instr_d_valid = old_instr_d_valid;
                end
                else if (old_stall_reg) begin
                    // Stall release path in DUT.
                    r_instr_d = old_sinstr;
                    r_pcd_delay = old_pc;
                    r_pc4d_delay = old_pc4f;
                    r_pcd = old_pcd_delay;
                    r_pc4d = old_pc4d_delay;

                    r_instr_d_pc = old_sinstr_pc;
                    r_instr_d_valid = old_sinstr_valid;
                end
                else begin
                    r_instr_d = old_instr_f;
                    r_pcd_delay = old_pc;
                    r_pc4d_delay = old_pc4f;
                    r_pcd = old_pcd_delay;
                    r_pc4d = old_pc4d_delay;

                    r_instr_d_pc = old_instr_f_pc;
                    r_instr_d_valid = old_instr_f_valid;
                end

                // ------------------------------------------------
                // Delayed redirect
                // ------------------------------------------------
                r_pcsrc_delay = PcSrcE;

                // ------------------------------------------------
                // Stall history
                // ------------------------------------------------
                r_stall_reg = StallF;

                // ------------------------------------------------
                // Capture instruction at stall entry.
                // The reference model ALSO captures the instruction's
                // PC. The DUT does not: this is intentionally useful
                // for exposing any instruction/PC desynchronization.
                // ------------------------------------------------
                if (StallF && !old_stall_reg) begin
                    r_sinstr = old_instr_f;
                    r_sinstr_pc = old_instr_f_pc;
                    r_sinstr_valid = old_instr_f_valid;
                end

                // ------------------------------------------------
                // Synchronous SRAM response.
                // Address sampled from OLD PC.
                // ------------------------------------------------
                r_instr_f = imem[old_pc[9:2]];
                r_instr_f_pc = old_pc;
                r_instr_f_valid = 1'b1;
            end
        end
    endtask


    // ============================================================
    // SCOREBOARD CHECK
    // ============================================================

    task automatic scoreboard_check;
        begin
            scoreboard_checks = scoreboard_checks + 1;

            if ((InstrD !== r_instr_d) ||
                (PcD !== r_pcd) ||
                (PcPlus4D !== r_pc4d)) begin

                scoreboard_failures = scoreboard_failures + 1;

                $display("");
                $display("IF SCOREBOARD FAILURE");
                $display("Time = %0t", $time);
                $display("StallF=%b PcSrcE=%b PcTargetE=%h", StallF, PcSrcE, PcTargetE);
                $display("InstrD   EXP=%h GOT=%h", r_instr_d, InstrD);
                $display("PcD      EXP=%h GOT=%h", r_pcd, PcD);
                $display("PcPlus4D EXP=%h GOT=%h", r_pc4d, PcPlus4D);
                $display("EXP INSTR-PC=%h VALID=%b", r_instr_d_pc, r_instr_d_valid);
            end
            else begin
                scoreboard_passes = scoreboard_passes + 1;
            end

            // ----------------------------------------------------
            // Independent interface invariant: instruction address
            // must remain word aligned for RV32I.
            // ----------------------------------------------------
            assert (INSTR_ADD[1:0] == 2'b00)
            else begin
                $error("ASSERTION FAILED: INSTR_ADD is not 4-byte aligned: %h", INSTR_ADD);
                assertion_failures = assertion_failures + 1;
            end

            // ----------------------------------------------------
            // Valid decoded instruction must carry the same PC as
            // the reference association.
            // This catches the special stall replay problem.
            // ----------------------------------------------------
            if (r_instr_d_valid) begin
                assert (r_instr_d_pc == r_pcd)
                else begin
                    $error("REFERENCE INVARIANT FAILED: instruction/PC association mismatch in model");
                    assertion_failures = assertion_failures + 1;
                end

                // This check is intentionally architectural, not a
                // copy of a DUT internal equation.
                assert (PcPlus4D == (PcD + 32'd4))
                else begin
                    $error("ASSERTION FAILED: valid instruction has bad PC+4: PC=%h PC4=%h", PcD, PcPlus4D);
                    assertion_failures = assertion_failures + 1;
                end
            end

            // ----------------------------------------------------
            // During a real redirect flush, Decode must see NOP.
            // ----------------------------------------------------
            if (model_flush_this_cycle) begin
                assert (InstrD == 32'h00000013)
                else begin
                    $error("ASSERTION FAILED: redirect flush did not produce NOP");
                    assertion_failures = assertion_failures + 1;
                end
            end

            // ----------------------------------------------------
            // Stall invariant: while stalled, IF/ID state must not
            // change unless FlushIF is simultaneously asserted.
            // We check this using saved DUT outputs below.
            // ----------------------------------------------------

            cov_flush = model_flush_this_cycle;
            cov_stall_entry = model_stall_entry;
            cov_stall_release = model_stall_release;
            cov_valid_instruction = r_instr_d_valid;

            cov.sample();
        end
    endtask


    // ============================================================
    // ONE CLOCK
    // ============================================================

    task automatic step;
        begin
            @(posedge clk);
            #1;
            model_step();
            #1;
            scoreboard_check();
        end
    endtask


    // ============================================================
    // STALL-HOLD ASSERTION TEST
    // ============================================================

    task automatic check_stall_hold;
        reg [31:0] old_instr;
        reg [31:0] old_pc;
        reg [31:0] old_pc4;
        begin
            old_instr = InstrD;
            old_pc = PcD;
            old_pc4 = PcPlus4D;

            StallF = 1'b1;
            PcSrcE = 1'b0;

            repeat (3) begin
                step();

                assert (InstrD === old_instr &&
                        PcD === old_pc &&
                        PcPlus4D === old_pc4)
                else begin
                    $error("ASSERTION FAILED: IF/ID changed during StallF");
                    assertion_failures = assertion_failures + 1;
                end
            end

            StallF = 1'b0;
        end
    endtask


    // ============================================================
    // DIRECTED TESTS
    // ============================================================

    task automatic sequential_test;
        begin
            $display("Testing sequential synchronous fetch...");
            StallF = 1'b0;
            PcSrcE = 1'b0;
            repeat (12) step();
            edge_cases = edge_cases + 1;
        end
    endtask

    task automatic one_cycle_stall_test;
        begin
            $display("Testing one-cycle stall...");
            step();
            StallF = 1'b1;
            step();
            StallF = 1'b0;
            step();
            step();
            edge_cases = edge_cases + 1;
        end
    endtask

    task automatic long_stall_test;
        begin
            $display("Testing multi-cycle stall...");
            StallF = 1'b1;
            check_stall_hold();
            StallF = 1'b0;
            repeat (4) step();
            edge_cases = edge_cases + 1;
        end
    endtask

    task automatic redirect_test;
        begin
            $display("Testing redirect and delayed flush...");

            StallF = 1'b0;
            PcSrcE = 1'b0;
            repeat (4) step();

            PcTargetE = 32'h00000040;
            PcSrcE = 1'b1;
            step();

            // PcSrcE is now removed; PcSrcE_delay still causes
            // the second flush cycle.
            PcSrcE = 1'b0;
            step();

            repeat (5) step();
            edge_cases = edge_cases + 1;
        end
    endtask

    task automatic redirect_back_to_back_test;
        begin
            $display("Testing back-to-back redirects...");

            PcTargetE = 32'h00000040;
            PcSrcE = 1'b1;
            step();

            PcTargetE = 32'h00000080;
            PcSrcE = 1'b1;
            step();

            PcSrcE = 1'b0;
            repeat (6) step();

            edge_cases = edge_cases + 1;
        end
    endtask

    task automatic stall_redirect_test;
        begin
            $display("Testing StallF + PcSrcE interaction...");

            StallF = 1'b0;
            PcSrcE = 1'b0;
            repeat (3) step();

            // Important corner case: PC module gives StallF
            // priority over PC redirect.
            StallF = 1'b1;
            PcSrcE = 1'b1;
            PcTargetE = 32'h00000080;
            step();

            PcSrcE = 1'b0;
            step();

            StallF = 1'b0;
            repeat (5) step();

            edge_cases = edge_cases + 1;
        end
    endtask

    task automatic stall_release_association_test;
        begin
            $display("Testing stall-release instruction/PC association...");

            StallF = 1'b0;
            PcSrcE = 1'b0;
            repeat (4) step();

            // Enter stall at a known instruction-response boundary.
            StallF = 1'b1;
            step();
            step();

            // Release.
            StallF = 1'b0;
            step();
            step();
            step();

            edge_cases = edge_cases + 1;
        end
    endtask


    // ============================================================
    // RANDOM TESTS
    // ============================================================

    task automatic random_test;
        integer n;
        begin
            $display("Running 2000 random IF scenarios...");

            for (n = 0; n < 2000; n = n + 1) begin

                StallF = $urandom_range(0, 1);
                PcSrcE = $urandom_range(0, 1);

                // Aligned target addresses only.
                PcTargetE = {$urandom_range(0, 255), 2'b00};

                step();

                random_cases = random_cases + 1;
            end
        end
    endtask


    // ============================================================
    // MAIN
    // ============================================================

    initial begin

        init_memory();
        reset_model();
        cov = new();

        scoreboard_checks = 0;
        scoreboard_passes = 0;
        scoreboard_failures = 0;
        assertion_failures = 0;
        edge_cases = 0;
        random_cases = 0;

        StallF = 1'b0;
        PcSrcE = 1'b0;
        PcTargetE = 32'h00000000;
        rst = 1'b0;

        $display("");
        $display("================================================");
        $display("           IF STAGE VERIFICATION");
        $display("   SYNCHRONOUS SRAM / TWO-CYCLE FETCH MODEL");
        $display("================================================");
        $display("");

        // --------------------------------------------------------
        // RESET
        // --------------------------------------------------------

        repeat (2) @(posedge clk);
        #1;

        assert (InstrD === 32'h00000013 &&
                PcD === 32'h00000000 &&
                PcPlus4D === 32'h00000004)
        else begin
            $error("RESET ASSERTION FAILED");
            assertion_failures = assertion_failures + 1;
        end

        rst = 1'b1;

        // --------------------------------------------------------
        // Directed cases, individually reset so that each case
        // starts from a clean IF state.
        // --------------------------------------------------------

        sequential_test();

        rst = 1'b0;
        reset_model();
        repeat (2) @(posedge clk);
        rst = 1'b1;

        one_cycle_stall_test();

        rst = 1'b0;
        reset_model();
        repeat (2) @(posedge clk);
        rst = 1'b1;

        long_stall_test();

        rst = 1'b0;
        reset_model();
        repeat (2) @(posedge clk);
        rst = 1'b1;

        stall_release_association_test();

        rst = 1'b0;
        reset_model();
        repeat (2) @(posedge clk);
        rst = 1'b1;

        redirect_test();

        rst = 1'b0;
        reset_model();
        repeat (2) @(posedge clk);
        rst = 1'b1;

        redirect_back_to_back_test();

        rst = 1'b0;
        reset_model();
        repeat (2) @(posedge clk);
        rst = 1'b1;

        stall_redirect_test();

        // --------------------------------------------------------
        // Random
        // --------------------------------------------------------

        rst = 1'b0;
        reset_model();
        repeat (2) @(posedge clk);
        rst = 1'b1;

        random_test();

        // --------------------------------------------------------
        // REPORT
        // --------------------------------------------------------

        $display("");
        $display("================================================");
        $display("              IF VERIFICATION REPORT");
        $display("================================================");

        $display("Directed Edge Cases   = %0d", edge_cases);
        $display("Random Cases          = %0d", random_cases);
        $display("Scoreboard Checks     = %0d", scoreboard_checks);
        $display("Scoreboard Passes     = %0d", scoreboard_passes);
        $display("Scoreboard Failures   = %0d", scoreboard_failures);
        $display("Assertion Failures    = %0d", assertion_failures);
        $display("Functional Coverage   = %0.2f%%", cov.get_coverage());

        $display("================================================");
        $display("");

        if ((scoreboard_failures == 0) &&
            (assertion_failures == 0)) begin
            $display("******** IF VERIFICATION PASSED ********");
        end
        else begin
            $display("******** IF VERIFICATION FAILED ********");
        end

        $display("");
        $finish;

    end

endmodule

