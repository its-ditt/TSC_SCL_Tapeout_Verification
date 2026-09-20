// ============================================================
// Processor-level monitor
// ============================================================

always @(posedge clk) begin
    if (rst_n && !load_mode && dut.core_rst_n) begin
        // A real instruction at Decode must correspond to the
        // program word addressed by its PC. NOP bubbles are ignored.
        if (dut.cpu.InstrD !== RV32I_NOP) begin
            fetch_checks <= fetch_checks + 1;
            if (dut.cpu.PcD[1:0] !== 2'b00) begin
                $error("FETCH MONITOR: misaligned PcD=%08h", dut.cpu.PcD);
                fetch_errors <= fetch_errors + 1;
            end
            else if (dut.cpu.PcD[31:2] >= PROGRAM_WORDS) begin
                $error("FETCH MONITOR: PC outside loaded program=%08h", dut.cpu.PcD);
                fetch_errors <= fetch_errors + 1;
            end
            else if (dut.cpu.InstrD !== program_words[dut.cpu.PcD[31:2]]) begin
                $error("FETCH MONITOR: PC/instruction mismatch PC=%08h expected=%08h actual=%08h",
                       dut.cpu.PcD,
                       program_words[dut.cpu.PcD[31:2]],
                       dut.cpu.InstrD);
                fetch_errors <= fetch_errors + 1;
            end
        end

        if (dut.cpu.ForwardAE == 2'b11 || dut.cpu.ForwardBE == 2'b11) begin
            $error("FORWARD MONITOR: illegal forwarding select AE=%b BE=%b",
                   dut.cpu.ForwardAE, dut.cpu.ForwardBE);
            forward_errors <= forward_errors + 1;
        end

        if (dut.cpu.PcSrcE && dut.cpu.PcTargetE[0]) begin
            $error("CONTROL MONITOR: odd branch/jump target=%08h", dut.cpu.PcTargetE);
            control_errors <= control_errors + 1;
        end
    end
end

// Boot-loader write monitor. The loader is the only legal source of
// instruction SRAM writes while load_mode is active.
always @(posedge clk) begin
    if (rst_n && load_mode && dut.instr_in.instr_we) begin
        if (loader_word_writes >= PROGRAM_WORDS) begin
            $error("LOADER MONITOR: more instruction writes than program words");
            loader_errors++;
        end
        else begin
            if (dut.instr_in.instr_waddr !== loader_word_writes * 4) begin
                $error("LOADER MONITOR: address mismatch word=%0d expected=%03h actual=%03h",
                       loader_word_writes,
                       loader_word_writes * 4,
                       dut.instr_in.instr_waddr);
                loader_errors++;
            end

            if (dut.instr_in.instr_wdata !== program_words[loader_word_writes]) begin
                $error("LOADER MONITOR: data mismatch word=%0d expected=%08h actual=%08h",
                       loader_word_writes,
                       program_words[loader_word_writes],
                       dut.instr_in.instr_wdata);
                loader_errors++;
            end
        end
        loader_word_writes++;
    end
end
