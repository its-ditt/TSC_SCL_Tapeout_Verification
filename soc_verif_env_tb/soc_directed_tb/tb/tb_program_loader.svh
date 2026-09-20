// ============================================================
// Program loader driver
// ============================================================
// Canonical program source:
//     program_image.svh -> program_words[]
//
// The DUT is loaded through the real byte_loader interface.
// No external program file is opened or read by this TB.
// ============================================================

task automatic load_program_through_byte_loader();
    int i;
    int b;
    logic [7:0] byte_value;

    begin
        $display("\n============================================================");
        $display("SOC PROGRAM LOAD");
        $display("Source  : program_image.svh");
        $display("Words   : %0d", PROGRAM_WORDS);
        $display("============================================================");

        load_mode   = 1'b1;
        byte_strobe = 1'b0;
        data_in     = 8'h00;

        // Core remains in reset while load_mode is asserted.
        repeat (3) @(posedge clk);

        // Drive every program word through the actual byte-loader path.
        for (i = 0; i < PROGRAM_WORDS; i++) begin
            for (b = 0; b < 4; b++) begin
                byte_value = program_words[i][8*b +: 8];

                data_in = byte_value;
                byte_strobe = 1'b1;
                @(posedge clk);

                byte_strobe = 1'b0;
                @(posedge clk);
            end

            // Allow the loader/SRAM write pulse to settle.
            @(posedge clk);
        end

        @(posedge clk);

        if (dut.core_rst_n !== 1'b0) begin
            $error("LOAD ERROR: core reset was not held active during loading");
            load_errors++;
        end

        $display("Instruction load complete. Verifying SRAM contents...");

        // Verify the actual DUT SRAM, not a TB-side shadow memory.
        for (i = 0; i < PROGRAM_WORDS; i++) begin
            if (dut.Imem.mem[i][31:0] !== program_words[i]) begin
                $error("IMEM LOAD ERROR: word=%0d expected=%08h actual=%08h",
                       i, program_words[i], dut.Imem.mem[i][31:0]);
                load_errors++;
            end
        end

        if (load_errors == 0)
            $display("IMEM verification: PASS (%0d words)", PROGRAM_WORDS);
        else
            $display("IMEM verification: FAIL (%0d errors)", load_errors);

        byte_strobe = 1'b0;
        data_in = 8'h00;
        load_mode = 1'b0;

        repeat (5) @(posedge clk);
    end
endtask
