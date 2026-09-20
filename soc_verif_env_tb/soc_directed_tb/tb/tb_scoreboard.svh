// ============================================================
// Final architectural scoreboard
// ============================================================
// Pass/fail checks are based on deterministic architectural signatures.
// The reference model remains non-gating diagnostic information.
//
// Important SRAM rule:
//   A word/byte that was never written is X, not 0.
//   Therefore the scoreboard never invents zeros for untouched SRAM.
// ============================================================

task automatic check_signature_word(
    input logic [31:0] addr,
    input logic [31:0] expected,
    input string section
);
    logic [31:0] actual;
    begin
        actual = dut.axi_top.ram_slave.Dmem.mem[addr[11:2]][31:0];

        if (actual !== expected) begin
            $error("%s SIGNATURE FAIL addr=%08h expected=%08h actual=%08h",
                   section, addr, expected, actual);
            scoreboard_errors++;
        end
        else begin
            scoreboard_passes++;
        end
    end
endtask

task automatic check_unwritten_word(
    input logic [31:0] addr,
    input string description
);
    logic [3:0] valid_mask;
    begin
        valid_mask = shadow_valid_bytes[addr[11:2]];

        if (valid_mask !== 4'b0000) begin
            $error("CONTROL NEGATIVE CHECK FAIL %-32s addr=%08h valid_mask=%b",
                   description, addr, valid_mask);
            scoreboard_errors++;
        end
        else begin
            $display("CONTROL NEGATIVE CHECK PASS %-32s addr=%08h remains unwritten",
                     description, addr);
            scoreboard_passes++;
        end
    end
endtask

task automatic check_edge_word(
    input logic [31:0] addr,
    input logic [31:0] expected,
    input string description
);
    logic [31:0] actual;
    begin
        actual = dut.axi_top.ram_slave.Dmem.mem[addr[11:2]][31:0];

        if (actual !== expected) begin
            $error("EDGE FAIL %-34s addr=%08h expected=%08h actual=%08h",
                   description, addr, expected, actual);
            edge_errors++;
            scoreboard_errors++;
        end
        else begin
            $display("EDGE PASS %-34s addr=%08h value=%08h",
                     description, addr, actual);
            edge_passes++;
            scoreboard_passes++;
        end
    end
endtask

task automatic run_reference_model_diagnostic();
    begin
        $display("\n============================================================");
        $display("REFERENCE MODEL DIAGNOSTIC (NON-GATING)");
        $display("============================================================");

        if (ref_error)
            $display("REFERENCE MODEL : DIAGNOSTIC ERROR");
        else
            $display("REFERENCE MODEL : reached completion");

        $display("Reference instructions executed : %0d", ref_steps);
        $display("Reference final PC              : %08h", ref_final_pc);
        $display("NOTE: Reference-model results do not determine pass/fail.");
    end
endtask

task automatic run_main_directed_scoreboard();
    begin
        $display("\n============================================================");
        $display("MAIN DIRECTED SIGNATURE SCOREBOARD");
        $display("============================================================");

        check_signature_word(32'h00000200, 32'h0000000d, "MAIN");
        check_signature_word(32'h00000204, 32'h00000007, "MAIN");
        check_signature_word(32'h00000208, 32'h00000050, "MAIN");
        check_signature_word(32'h0000020c, 32'h00000001, "MAIN");
        check_signature_word(32'h00000210, 32'h00000001, "MAIN");
        check_signature_word(32'h00000214, 32'h00000009, "MAIN");
        check_signature_word(32'h00000218, 32'h00000001, "MAIN");

        // PC 0x05c: sw x11, 28(x21), x11 = -1.
        check_signature_word(32'h0000021c, 32'hffffffff, "MAIN");

        check_signature_word(32'h00000220, 32'h0000000b, "MAIN");
        check_signature_word(32'h00000224, 32'h00000002, "MAIN");
        check_signature_word(32'h00000228, 32'h0000000f, "MAIN");
        check_signature_word(32'h0000022c, 32'h00000001, "MAIN");
        check_signature_word(32'h00000230, 32'h00000000, "MAIN");
        check_signature_word(32'h00000234, 32'h000000fa, "MAIN");
        check_signature_word(32'h00000238, 32'h0000000f, "MAIN");
        check_signature_word(32'h0000023c, 32'h00000000, "MAIN");
        check_signature_word(32'h00000240, 32'h00000028, "MAIN");
        check_signature_word(32'h00000244, 32'h00000005, "MAIN");

        // PC 0x0ac: sw x25, 72(x21), x25 = -4.
        check_signature_word(32'h00000248, 32'hfffffffc, "MAIN");

        check_signature_word(32'h0000024c, 32'h12345000, "MAIN");
        check_signature_word(32'h00000250, 32'h000010b4, "MAIN");
        check_signature_word(32'h00000254, 32'h12345678, "MAIN");
        check_signature_word(32'h00000258, 32'h00005678, "MAIN");
        check_signature_word(32'h0000025c, 32'h00005678, "MAIN");
        check_signature_word(32'h00000260, 32'h00000078, "MAIN");
        check_signature_word(32'h00000264, 32'h00000078, "MAIN");
        check_signature_word(32'h00000268, 32'hffff8001, "MAIN");
        check_signature_word(32'h0000026c, 32'h00008001, "MAIN");
        check_signature_word(32'h00000270, 32'hffffff80, "MAIN");
        check_signature_word(32'h00000274, 32'h00000080, "MAIN");
        check_signature_word(32'h00000278, 32'h0000003f, "MAIN");
        check_signature_word(32'h0000027c, 32'h1234acf0, "MAIN");
        check_signature_word(32'h00000280, 32'h00000001, "MAIN");
        check_signature_word(32'h00000284, 32'h00000001, "MAIN");
        check_signature_word(32'h00000288, 32'h00000001, "MAIN");
        check_signature_word(32'h0000028c, 32'h00000001, "MAIN");
        check_signature_word(32'h00000290, 32'h00000001, "MAIN");
        check_signature_word(32'h00000294, 32'h00000001, "MAIN");
        check_signature_word(32'h0000029c, 32'h000001bc, "MAIN");
        check_signature_word(32'h000002a4, 32'h000001d8, "MAIN");

        // These addresses are intentionally NOT checked as zero.
        // They correspond to wrong-path stores after JAL/JALR.
        // SRAM remains X unless a write actually occurs.
        check_unwritten_word(32'h00000298, "JAL wrong-path store");
        check_unwritten_word(32'h000002a0, "JALR wrong-path store");
    end
endtask

task automatic run_edge_case_scoreboard();
    begin
        edge_passes = 0;
        edge_errors = 0;

        $display("\n============================================================");
        $display("CONSTRAINED EDGE-CASE SCOREBOARD");
        $display("============================================================");

        $display("1. Immediate boundary: -2048 and +2047");
        $display("2. Signed ADD wraparound");
        $display("3. Arithmetic right shift preserves sign");
        $display("4. SLT vs SLTU boundary");
        $display("5. Register shift amount 32 is masked to 5 bits");
        $display("6. x0 remains immutable");
        $display("7. SB byte lanes 0/1/2/3");
        $display("8. SH lower and upper halfword lanes");
        $display("9. LB/LBU sign vs zero extension");
        $display("10. LH/LHU sign vs zero extension");
        $display("11. Backward branch taken once, then not taken");
        $display("12. Signed overflow: 0x7fffffff + 1");
        $display("13. JALR link value and bit-0 clearing");

        check_edge_word(32'h00000300, 32'hffffffff, "ADD signed wrap boundary");
        check_edge_word(32'h00000304, 32'hffffffff, "SRA sign preservation shift-31");
        check_edge_word(32'h00000308, 32'h00000001, "SLT signed boundary");
        check_edge_word(32'h0000030c, 32'h00000000, "SLTU unsigned boundary");
        check_edge_word(32'h00000310, 32'h00000001, "Register shift amount mask (32)");
        check_edge_word(32'h00000314, 32'h00000000, "x0 immutability");
        check_edge_word(32'h00000318, 32'haaaaaaaa, "SB all byte lanes");
        check_edge_word(32'h0000031c, 32'hbeefbeef, "SH low/high lanes");
        check_edge_word(32'h00000320, 32'hffffff80, "LB sign extension");
        check_edge_word(32'h00000324, 32'h00000080, "LBU zero extension");
        check_edge_word(32'h00000328, 32'hffff8001, "LH sign extension");
        check_edge_word(32'h0000032c, 32'h00008001, "LHU zero extension");
        check_edge_word(32'h00000330, 32'h00000000, "Backward branch taken/not-taken");
        check_edge_word(32'h00000334, 32'h80000000, "Signed overflow wrap");
        check_edge_word(32'h00000338, 32'h000002d4, "JALR link + bit0 clear");
        check_edge_word(32'h0000033c, 32'hfffff800, "ADDI minimum immediate");
        check_edge_word(32'h00000340, 32'h000007ff, "ADDI maximum immediate");

        $display("EDGE-CASE PASS : %0d", edge_passes);
        $display("EDGE-CASE FAIL : %0d", edge_errors);
    end
endtask

task automatic run_final_scoreboard();
    begin
        $display("\n============================================================");
        $display("FINAL ARCHITECTURAL SCOREBOARD");
        $display("============================================================");

        if (loader_word_writes !== PROGRAM_WORDS) begin
            $error("LOADER WRITE COUNT mismatch expected=%0d actual=%0d",
                   PROGRAM_WORDS, loader_word_writes);
            scoreboard_errors++;
        end

        if (loader_errors != 0) begin
            $error("Loader monitor errors = %0d", loader_errors);
            scoreboard_errors++;
        end

        if (!done_write_seen) begin
            $error("DONE AXI write completion was not observed");
            scoreboard_errors++;
            $display("MAIN/EDGE SIGNATURES : SKIPPED because completion was not observed.");
        end
        else begin
            $display("DONE AXI write: PASS");
            scoreboard_passes++;

            run_main_directed_scoreboard();
            run_edge_case_scoreboard();
        end

        run_reference_model_diagnostic();

        if (axi_errors != 0) begin
            $error("AXI response errors = %0d", axi_errors);
            scoreboard_errors++;
        end

        if (transport_errors != 0) begin
            $error("AXI transport errors = %0d", transport_errors);
            scoreboard_errors++;
        end

        if (control_errors != 0) begin
            $error("Control-flow monitor errors = %0d", control_errors);
            scoreboard_errors++;
        end

        if (forward_errors != 0) begin
            $error("Forwarding select errors = %0d", forward_errors);
            scoreboard_errors++;
        end

        $display("");
        $display("Fetched instructions observed : %0d", fetch_checks);
        $display("CPU read requests             : %0d", cpu_read_reqs);
        $display("CPU write requests            : %0d", cpu_write_reqs);
        $display("Main signature checks         : %0d", done_write_seen ? MAIN_SIGNATURE_COUNT : 0);
        $display("Edge-case checks              : %0d", done_write_seen ? EDGE_SIGNATURE_COUNT : 0);
        $display("Scoreboard PASS items         : %0d", scoreboard_passes);
        $display("Scoreboard ERROR items        : %0d", scoreboard_errors);
    end
endtask
