// ============================================================
// Post-synthesis program loader
// Drives the real qbit_loader path through top-level chip pins.
// No direct SRAM write is performed by the testbench.
// ============================================================

integer ps_loader_word_writes = 0;
integer ps_loader_errors = 0;

always @(posedge clk) begin
    if (rst_n && load_mode && `SOC_HIER.instr_in.instr_we) begin
        if (ps_loader_word_writes >= PROGRAM_WORDS) begin
            $error("POSTSYN LOAD: extra instruction write observed");
            ps_loader_errors++;
        end
        else begin
            if (`SOC_HIER.instr_in.instr_waddr !== ps_loader_word_writes * 4) begin
                $error("POSTSYN LOAD: address mismatch word=%0d expected=%0d actual=%0d",
                       ps_loader_word_writes,
                       ps_loader_word_writes * 4,
                       `SOC_HIER.instr_in.instr_waddr);
                ps_loader_errors++;
            end

            if (`SOC_HIER.instr_in.instr_wdata !== program_words[ps_loader_word_writes]) begin
                $error("POSTSYN LOAD: data mismatch word=%0d expected=%08h actual=%08h",
                       ps_loader_word_writes,
                       program_words[ps_loader_word_writes],
                       `SOC_HIER.instr_in.instr_wdata);
                ps_loader_errors++;
            end
        end
        ps_loader_word_writes++;
    end
end

task automatic load_program_post_synth();
    int i, q;
    logic [1:0] qbit_value;
    integer expected_qbits;
    begin
        $display("\n============================================================");
        $display("POST-SYNTHESIS PROGRAM LOAD");
        $display("Program words : %0d", PROGRAM_WORDS);
        $display("Transport     : 16 x 2-bit transfers / instruction");
        $display("============================================================");

        ps_loader_word_writes = 0;
        ps_loader_errors = 0;
        expected_qbits = PROGRAM_WORDS * 16;

        load_mode   = 1'b1;
        data_in     = 2'b00;
        qbit_strobe = 1'b0;

        repeat (3) @(posedge clk);

        for (i = 0; i < PROGRAM_WORDS; i++) begin
            for (q = 0; q < 16; q++) begin
                qbit_value = program_words[i][2*q +: 2];
                data_in = qbit_value;
                qbit_strobe = 1'b1;
                @(posedge clk);
                qbit_strobe = 1'b0;
                @(posedge clk);
            end

            // Permit the registered instr_we pulse to reach the SRAM macro.
            @(posedge clk);
        end

        @(posedge clk);

        if (`SOC_HIER.core_rst_n !== 1'b0) begin
            $error("POSTSYN LOAD: core_rst_n must remain low during load_mode");
            ps_loader_errors++;
        end

        if (`SOC_HIER.instr_in.qbit_cnt !== 4'd0) begin
            $error("POSTSYN LOAD: qbit_cnt not zero after final word: %0d",
                   `SOC_HIER.instr_in.qbit_cnt);
            ps_loader_errors++;
        end

        if (`SOC_HIER.instr_in.addr_cnt !== PROGRAM_WORDS * 4) begin
            $error("POSTSYN LOAD: addr_cnt mismatch expected=%0d actual=%0d",
                   PROGRAM_WORDS * 4,
                   `SOC_HIER.instr_in.addr_cnt);
            ps_loader_errors++;
        end

        if (ps_loader_word_writes !== PROGRAM_WORDS) begin
            $error("POSTSYN LOAD: instruction write count mismatch expected=%0d actual=%0d",
                   PROGRAM_WORDS, ps_loader_word_writes);
            ps_loader_errors++;
        end

        qbit_strobe = 1'b0;
        data_in = 2'b00;
        load_mode = 1'b0;

        repeat (5) @(posedge clk);

        if (ps_loader_errors == 0)
            $display("POST-SYNTH LOAD : PASS (%0d words / %0d qbit transfers)",
                     PROGRAM_WORDS, expected_qbits);
        else
            $display("POST-SYNTH LOAD : FAIL (%0d errors)", ps_loader_errors);
    end
endtask
