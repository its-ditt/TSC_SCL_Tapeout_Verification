// ============================================================
// Final architectural scoreboard
// ============================================================

task automatic run_final_scoreboard();
    int i;
    logic [31:0] actual_reg;
    logic [31:0] actual_mem;
    begin
        $display("\n============================================================");
        $display("FINAL ARCHITECTURAL SCOREBOARD");
        $display("============================================================");

        // Reference-model health.
        if (ref_error) begin
            $error("REFERENCE MODEL reported an error; final architectural result is invalid");
            scoreboard_errors++;
        end

        // x0 invariant and complete architectural register state.
        for (i = 0; i < 32; i++) begin
            actual_reg = dut.cpu.decode.register_file.reg_file[i];

            if (actual_reg !== ref_regs[i]) begin
                $error("REG FAIL x%0d expected=%08h actual=%08h",
                       i, ref_regs[i], actual_reg);
                scoreboard_errors++;
            end
            else begin
                scoreboard_passes++;
            end
        end

        if (loader_word_writes !== PROGRAM_WORDS) begin
            $error("LOADER WRITE COUNT mismatch expected=%0d actual=%0d", PROGRAM_WORDS, loader_word_writes);
            scoreboard_errors++;
        end
        if (loader_errors != 0) begin
            $error("Loader monitor errors = %0d", loader_errors);
            scoreboard_errors++;
        end

        // Completion marker.
        actual_mem = dut.axi_top.ram_slave.Dmem.mem[DONE_ADDR[11:2]][31:0];
        if (actual_mem !== DONE_VALUE) begin
            $error("DONE MARKER FAIL addr=%08h expected=%08h actual=%08h",
                   DONE_ADDR, DONE_VALUE, actual_mem);
            scoreboard_errors++;
        end
        else begin
            $display("DONE marker: PASS");
            scoreboard_passes++;
        end

        // Compare all architectural memory locations touched by the
        // reference program. Untouched SRAM locations are not compared
        // because the macro does not reset its full array.
        for (i = 0; i < DMEM_WORDS; i++) begin
            if (ref_mem_valid[i]) begin
                actual_mem = dut.axi_top.ram_slave.Dmem.mem[i][31:0];
                if (actual_mem !== ref_mem[i]) begin
                    $error("MEM FAIL word=%0d addr=%08h expected=%08h actual=%08h",
                           i, i*4, ref_mem[i], actual_mem);
                    scoreboard_errors++;
                end
                else begin
                    scoreboard_passes++;
                end
            end
        end

        // Interface-level counters must match the number of CPU requests.
        if (aw_handshakes !== cpu_write_reqs) begin
            $error("AXI AW COUNT mismatch CPU=%0d AXI=%0d", cpu_write_reqs, aw_handshakes);
            scoreboard_errors++;
        end
        if (w_handshakes !== cpu_write_reqs) begin
            $error("AXI W COUNT mismatch CPU=%0d AXI=%0d", cpu_write_reqs, w_handshakes);
            scoreboard_errors++;
        end
        if (b_handshakes !== cpu_write_reqs) begin
            $error("AXI B COUNT mismatch CPU=%0d AXI=%0d", cpu_write_reqs, b_handshakes);
            scoreboard_errors++;
        end
        if (ar_handshakes !== cpu_read_reqs) begin
            $error("AXI AR COUNT mismatch CPU=%0d AXI=%0d", cpu_read_reqs, ar_handshakes);
            scoreboard_errors++;
        end
        if (r_handshakes !== cpu_read_reqs) begin
            $error("AXI R COUNT mismatch CPU=%0d AXI=%0d", cpu_read_reqs, r_handshakes);
            scoreboard_errors++;
        end

        if (axi_errors != 0) begin
            $error("AXI protocol/response errors = %0d", axi_errors);
            scoreboard_errors++;
        end

        if (transport_errors != 0) begin
            $error("AXI transport errors = %0d", transport_errors);
            scoreboard_errors++;
        end

        if (fetch_errors != 0) begin
            $error("Instruction fetch errors = %0d", fetch_errors);
            scoreboard_errors++;
        end

        if (control_errors != 0) begin
            $error("Control-flow errors = %0d", control_errors);
            scoreboard_errors++;
        end

        if (forward_errors != 0) begin
            $error("Forwarding select errors = %0d", forward_errors);
            scoreboard_errors++;
        end

        $display("");
        $display("Reference instructions executed : %0d", ref_steps);
        $display("Fetched instructions checked    : %0d", fetch_checks);
        $display("CPU read requests              : %0d", cpu_read_reqs);
        $display("CPU write requests             : %0d", cpu_write_reqs);
        $display("Scoreboard PASS items          : %0d", scoreboard_passes);
        $display("Scoreboard ERROR items         : %0d", scoreboard_errors);
    end
endtask
