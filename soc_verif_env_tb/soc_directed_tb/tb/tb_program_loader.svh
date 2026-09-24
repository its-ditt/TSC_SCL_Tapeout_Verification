// ============================================================
// LEGACY BYTE-WIDTH LOADER TASK (COMMENTED - retained for traceability)
// ============================================================
// Kept intentionally for traceability. This version targeted the
// previous 8-bit byte_loader interface and must not be compiled
// as the active task with the current qbit_loader.
//
// /*
//// ============================================================
// Program loader driver
// ============================================================
// Canonical program source:
//     program_image.svh -> program_words[]
//
// The DUT is loaded through the real byte_loader interface.
// No external program file is opened or read by this TB.
// ============================================================

// task automatic load_program_through_byte_loader();
//     int i;
//     int b;
//     logic [1:0] byte_value;

//     begin
//         $display("\n============================================================");
//         $display("SOC PROGRAM LOAD");
//         $display("Source  : program_image.svh");
//         $display("Words   : %0d", PROGRAM_WORDS);
//         $display("============================================================");

//         load_mode   = 1'b1;
//         byte_strobe = 1'b0;
//         data_in     = 2'b00;

        // Core remains in reset while load_mode is asserted.
//         repeat (3) @(posedge clk);

        // Drive every program word through the actual byte-loader path.
//         for (i = 0; i < PROGRAM_WORDS; i++) begin
//             for (b = 0; b < 16; b++) begin
//                 byte_value = program_words[i][2*b +: 2];

//                 data_in = byte_value;
//                 byte_strobe = 1'b1;
//                 @(posedge clk);

//                 byte_strobe = 1'b0;
//                 @(posedge clk);
//             end

            // Allow the loader/SRAM write pulse to settle.
//             @(posedge clk);
//         end

//         @(posedge clk);

//         if (dut.core_rst_n !== 1'b0) begin
//             $error("LOAD ERROR: core reset was not held active during loading");
//             load_errors++;
//         end

//         $display("Instruction load complete. Verifying SRAM contents...");

        // Verify the actual DUT SRAM, not a TB-side shadow memory.
//         for (i = 0; i < PROGRAM_WORDS; i++) begin
//             if (dut.Imem.mem[i][31:0] !== program_words[i]) begin
//                 $error("IMEM LOAD ERROR: word=%0d expected=%08h actual=%08h",
//                        i, program_words[i], dut.Imem.mem[i][31:0]);
//                 load_errors++;
//             end
//         end

//         if (load_errors == 0)
//             $display("IMEM verification: PASS (%0d words)", PROGRAM_WORDS);
//         else
//             $display("IMEM verification: FAIL (%0d errors)", load_errors);

//         byte_strobe = 1'b0;
//         data_in =2'b00;
//         load_mode = 1'b0;

//         repeat (5) @(posedge clk);
//     end
// endtask

// */

// ============================================================
// CURRENT 2-BIT QBIT LOADER TASK
// ============================================================
// Canonical program source:
//     program_image.svh -> program_words[]
//
// The DUT is loaded through the real qbit_loader interface.
// One instruction is transmitted as 16 x 2-bit transfers.
// No external program file is opened or read by this TB.
// ============================================================

task automatic load_program_through_qbit_loader();
    int i;
    int b;
    int qbits_sent;
    logic [1:0] qbit_value;

    begin
        qbits_sent = 0;

        $display("\n============================================================");
        $display("SOC PROGRAM LOAD");
        $display("Source  : program_image.svh");
        $display("Words   : %0d", PROGRAM_WORDS);
        $display("Transfer: 16 qbits/word (2 bits per transfer)");
        $display("============================================================");

        if (!rst_n) begin
            $error("LOAD ERROR: rst_n must be HIGH before qbit loading starts");
            load_errors++;
        end

        load_mode   = 1'b1;
        qbit_strobe = 1'b0;
        data_in     = 2'b00;

        repeat (3) @(posedge clk);

        for (i = 0; i < PROGRAM_WORDS; i++) begin
            for (b = 0; b < 16; b++) begin
                qbit_value = program_words[i][2*b +: 2];

                data_in     = qbit_value;
                qbit_strobe = 1'b1;
                @(posedge clk);

                qbit_strobe = 1'b0;
                @(posedge clk);

                qbits_sent++;
            end

            // instr_we is registered by the loader, so allow the SRAM
            // write pulse to be observed on the next clock edge.
            @(posedge clk);
        end

        @(posedge clk);

        if (qbits_sent != PROGRAM_WORDS * 16) begin
            $error("LOAD ERROR: qbit transfer count mismatch expected=%0d actual=%0d",
                   PROGRAM_WORDS * 16, qbits_sent);
            load_errors++;
        end

        if (dut.instr_in.qbit_cnt !== 4'd0) begin
            $error("LOAD ERROR: qbit_cnt did not return to 0 after word completion: %0d",
                   dut.instr_in.qbit_cnt);
            load_errors++;
        end

        if (dut.instr_in.addr_cnt !== PROGRAM_WORDS * 4) begin
            $error("LOAD ERROR: loader address counter mismatch expected=%0d actual=%0d",
                   PROGRAM_WORDS * 4, dut.instr_in.addr_cnt);
            load_errors++;
        end

        if (dut.core_rst_n !== 1'b0) begin
            $error("LOAD ERROR: core reset was not held active during loading");
            load_errors++;
        end

        $display("Instruction load complete. Verifying SRAM contents...");

        // The existing design uses byte addresses 0,4,8,... for instruction
        // locations, matching the CPU PC and the previous working byte loader.
        for (i = 0; i < PROGRAM_WORDS; i++) begin
            //if (dut.Imem.mem[i*4][31:0] !== program_words[i]) begin
            logic [31:0] actual_imem;
            actual_imem = dut.Imem.mem[i][31:0];
            if (actual_imem !== program_words[i]) begin
                $error("IMEM LOAD ERROR: byte-address=%0d word=%0d expected=%08h actual=%08h",
                       //i*4, i, program_words[i], dut.Imem.mem[i*4][31:0]);
                       i, i, program_words[i], dut.Imem.mem[i][31:0]);
                load_errors++;
            end
        end

        $display("IMEM word0 : expected=%08h actual=%08h",
                 program_words[0], dut.Imem.mem[0][31:0]);
        $display("IMEM word1 : expected=%08h actual=%08h",
                 program_words[1], dut.Imem.mem[1][31:0]); //prev Imem.mem[4][31:0]

        if (load_errors == 0)
            $display("IMEM verification: PASS (%0d words)", PROGRAM_WORDS);
        else
            $display("IMEM verification: FAIL (%0d errors)", load_errors);

        qbit_strobe = 1'b0;
        data_in     = 2'b00;
        load_mode   = 1'b0;

        repeat (5) @(posedge clk);
    end
endtask

