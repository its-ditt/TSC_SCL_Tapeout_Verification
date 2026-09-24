// ============================================================
// Processor-level monitor
// ============================================================
// Deliberately does not associate InstrD/PcD cycle-by-cycle with
// a reference fetch stream. That timing relation is implementation
// dependent because the DUT uses synchronous instruction SRAM,
// stalls and redirect flushing.
// ============================================================

always @(posedge clk) begin 
    if (rst_n && !load_mode && dut.core_rst_n) begin

        // Basic fetch sanity only: deterministic decoded PC alignment.
        if (!$isunknown(dut.cpu.InstrD) &&
            dut.cpu.InstrD !== RV32I_NOP) begin
            fetch_checks <= fetch_checks + 1;

            if (!$isunknown(dut.cpu.PcD[1:0]) &&
                dut.cpu.PcD[1:0] !== 2'b00) begin
                $error("FETCH MONITOR: misaligned decode PC=%08h", dut.cpu.PcD);
                fetch_errors <= fetch_errors + 1;
            end
        end

        if (dut.cpu.ForwardAE == 2'b11 ||
            dut.cpu.ForwardBE == 2'b11) begin
            $error("FORWARD MONITOR: illegal forwarding select AE=%b BE=%b",
                   dut.cpu.ForwardAE, dut.cpu.ForwardBE);
            forward_errors <= forward_errors + 1;
        end

        if (dut.cpu.PcSrcE && !$isunknown(dut.cpu.PcTargetE[0]) &&
            dut.cpu.PcTargetE[0]) begin
            $error("CONTROL MONITOR: odd branch/jump target=%08h",
                   dut.cpu.PcTargetE);
            control_errors <= control_errors + 1;
        end
    end
end

// Boot-loader write monitor.
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

            if (dut.instr_in.instr_wdata !==
                program_words[loader_word_writes]) begin
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
