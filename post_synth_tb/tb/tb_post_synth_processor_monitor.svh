// ============================================================
// Post-synthesis processor monitor
// Uses only hierarchy visible in the supplied Genus netlist.
// ============================================================

integer ps_fetch_checks = 0;
integer ps_fetch_errors = 0;
integer ps_control_errors = 0;
integer ps_forward_errors = 0;

always @(posedge clk) begin
    if (rst_n && !load_mode && `SOC_HIER.core_rst_n) begin
        // Decode-stage instruction/PC alignment check.
        if (!$isunknown(`SOC_HIER.cpu_InstrD) &&
            (`SOC_HIER.cpu_InstrD !== RV32I_NOP)) begin
            ps_fetch_checks = ps_fetch_checks + 1;

            if (!$isunknown(`SOC_HIER.cpu_PcD[1:0]) &&
                (`SOC_HIER.cpu_PcD[1:0] !== 2'b00)) begin
                $error("POSTSYN FETCH: misaligned PcD=%08h", `SOC_HIER.cpu_PcD);
                ps_fetch_errors++;
            end

            if (!$isunknown(`SOC_HIER.cpu_PcD[31:2]) &&
                (`SOC_HIER.cpu_PcD[31:2] >= PROGRAM_WORDS)) begin
                $error("POSTSYN FETCH: PC outside loaded image=%08h", `SOC_HIER.cpu_PcD);
                ps_fetch_errors++;
            end
            else if (!$isunknown(`SOC_HIER.cpu_PcD[31:2]) &&
                     (`SOC_HIER.cpu_InstrD !== program_words[`SOC_HIER.cpu_PcD[31:2]])) begin
                $error("POSTSYN FETCH: PC/instruction mismatch PC=%08h expected=%08h actual=%08h",
                       `SOC_HIER.cpu_PcD,
                       program_words[`SOC_HIER.cpu_PcD[31:2]],
                       `SOC_HIER.cpu_InstrD);
                ps_fetch_errors++;
            end
        end

        if ((!$isunknown(`SOC_HIER.cpu_ForwardAE) && (`SOC_HIER.cpu_ForwardAE == 2'b11)) ||
            (!$isunknown(`SOC_HIER.cpu_ForwardBE) && (`SOC_HIER.cpu_ForwardBE == 2'b11))) begin
            $error("POSTSYN FORWARD: illegal select AE=%b BE=%b",
                   `SOC_HIER.cpu_ForwardAE,
                   `SOC_HIER.cpu_ForwardBE);
            ps_forward_errors++;
        end

        if (!$isunknown(`SOC_HIER.cpu_PcSrcE) &&
            `SOC_HIER.cpu_PcSrcE &&
            !$isunknown(`SOC_HIER.cpu_PcTargetE[0]) &&
            `SOC_HIER.cpu_PcTargetE[0]) begin
            $error("POSTSYN CONTROL: odd branch/jump target=%08h",
                   `SOC_HIER.cpu_PcTargetE);
            ps_control_errors++;
        end
    end
end
