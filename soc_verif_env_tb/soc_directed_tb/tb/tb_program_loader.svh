// ============================================================
// Program loader driver
// Drives the actual byte_loader inputs. The testbench never
// writes the instruction SRAM directly.
// ============================================================

task automatic load_program_through_byte_loader();
    int i, b;
    logic [7:0] byte_value;
    begin
        $display("\n============================================================");
        $display("SO C PROGRAM LOAD");
        $display("Program : %s", PROGRAM_FILE);
        $display("Words   : %0d", PROGRAM_WORDS);
        $display("============================================================");

        // Hold the CPU in boot-load mode.
        load_mode   = 1'b1;
        byte_strobe = 1'b0;
        data_in     = 8'h00;

        // Loader itself has an asynchronous reset from ext_rst_n.
        repeat (3) @(posedge clk);

        for (i = 0; i < PROGRAM_WORDS; i++) begin
            for (b = 0; b < 4; b++) begin
                byte_value = program_words[i][8*b +: 8];
                data_in = byte_value;
                byte_strobe = 1'b1;
                @(posedge clk);
                byte_strobe = 1'b0;

                // Leave a clean low-strobe cycle between bytes.
                @(posedge clk);
            end

            // The final byte sets instr_we in byte_loader using a
            // nonblocking assignment. One additional clock is needed
            // for the SRAM to observe the write-enable pulse.
            @(posedge clk);
        end

        // Verify the last write before switching the memory mux to CPU mode.
        @(posedge clk);

        if (dut.core_rst_n !== 1'b0)
            $error("BOOT ASSERTION: core is not held in reset during load_mode");

        $display("Instruction load complete. Verifying SRAM contents...");
        for (i = 0; i < PROGRAM_WORDS; i++) begin
            if (dut.Imem.mem[i][31:0] !== program_words[i]) begin
                $error("IMEM LOAD ERROR: word %0d expected=%08h actual=%08h",
                       i, program_words[i], dut.Imem.mem[i][31:0]);
                load_errors++;
            end
        end

        if (load_errors == 0)
            $display("IMEM verification: PASS (%0d words)", PROGRAM_WORDS);
        else
            $display("IMEM verification: FAIL (%0d errors)", load_errors);

        // Release load mode. core_rst_n becomes high because ext_rst_n
        // remains high.
        byte_strobe = 1'b0;
        data_in = 8'h00;
        load_mode = 1'b0;

        // Allow reset release and synchronous instruction SRAM to warm up.
        repeat (5) @(posedge clk);
    end
endtask
