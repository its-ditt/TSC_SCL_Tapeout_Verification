// ============================================================
// Post-synthesis AXI / architectural memory monitor
// Uses the synthesized AXI interface rather than the SRAM macro
// implementation. This avoids dependence on an internal .mem[] array.
// ============================================================

integer ps_cpu_write_reqs = 0;
integer ps_cpu_read_reqs  = 0;
integer ps_aw_handshakes  = 0;
integer ps_w_handshakes   = 0;
integer ps_b_handshakes   = 0;
integer ps_ar_handshakes  = 0;
integer ps_r_handshakes   = 0;
integer ps_axi_errors     = 0;
integer ps_transport_errors = 0;
integer ps_scoreboard_errors = 0;
integer ps_scoreboard_passes = 0;

logic ps_read_pending;
logic [31:0] ps_pending_raddr;

logic [31:0] ps_shadow_mem [0:DMEM_WORDS-1];
logic [3:0]  ps_shadow_valid_bytes [0:DMEM_WORDS-1];

logic [31:0] ps_axi_awaddr_seen;
logic        ps_aw_seen;
logic        done_write_seen;

logic [31:0] ps_effective_waddr;
integer i;

always @(posedge clk) begin
    if (!rst_n) begin
        ps_cpu_write_reqs   = 0;
        ps_cpu_read_reqs    = 0;
        ps_aw_handshakes    = 0;
        ps_w_handshakes     = 0;
        ps_b_handshakes     = 0;
        ps_ar_handshakes    = 0;
        ps_r_handshakes     = 0;
        ps_axi_errors       = 0;
        ps_transport_errors = 0;
        ps_read_pending     = 1'b0;
        ps_aw_seen          = 1'b0;
        done_write_seen     = 1'b0;
        ps_axi_awaddr_seen  = 32'h0;
        ps_effective_waddr = 32'h0;

        for (i = 0; i < DMEM_WORDS; i = i + 1) begin
            ps_shadow_mem[i] = 32'hxxxxxxxx;
            ps_shadow_valid_bytes[i] = 4'b0000;
        end
    end
    else begin
        if (`SOC_HIER.MEM_WRITE)
            ps_cpu_write_reqs = ps_cpu_write_reqs + 1;
        if (`SOC_HIER.MEM_READ)
            ps_cpu_read_reqs = ps_cpu_read_reqs + 1;

        // --------------------------------------------------------
        // AXI write address channel
        // --------------------------------------------------------
        if (`SOC_HIER.axi_top.manager.axi_awvalid &&
            `SOC_HIER.axi_top.manager.axi_awready) begin
            ps_aw_handshakes = ps_aw_handshakes + 1;
            ps_axi_awaddr_seen = `SOC_HIER.axi_top.manager.axi_awaddr;
            ps_aw_seen = 1'b1;
        end

        // --------------------------------------------------------
        // AXI write data channel
        // --------------------------------------------------------
        if (`SOC_HIER.axi_top.manager.axi_wvalid &&
            `SOC_HIER.axi_top.manager.axi_wready) begin
            ps_w_handshakes = ps_w_handshakes + 1;

            // AW and W can legally handshake in the same cycle.
            if (`SOC_HIER.axi_top.manager.axi_awvalid &&
                `SOC_HIER.axi_top.manager.axi_awready)
                ps_effective_waddr = `SOC_HIER.axi_top.manager.axi_awaddr;
            else if (ps_aw_seen)
                ps_effective_waddr = ps_axi_awaddr_seen;
            else begin
                $error("POSTSYN AXI: W handshake occurred without an observed AW address");
                ps_transport_errors = ps_transport_errors + 1;
                ps_effective_waddr = 32'hxxxxxxxx;
            end

            // Shadow only what actually appeared on the synthesized AXI bus.
            if (!$isunknown(ps_effective_waddr)) begin
                if (`SOC_HIER.axi_top.manager.axi_wstrb[0]) begin
                    ps_shadow_mem[ps_effective_waddr[11:2]][7:0] =
                        `SOC_HIER.axi_top.manager.axi_wdata[7:0];
                    ps_shadow_valid_bytes[ps_effective_waddr[11:2]][0] = 1'b1;
                end
                if (`SOC_HIER.axi_top.manager.axi_wstrb[1]) begin
                    ps_shadow_mem[ps_effective_waddr[11:2]][15:8] =
                        `SOC_HIER.axi_top.manager.axi_wdata[15:8];
                    ps_shadow_valid_bytes[ps_effective_waddr[11:2]][1] = 1'b1;
                end
                if (`SOC_HIER.axi_top.manager.axi_wstrb[2]) begin
                    ps_shadow_mem[ps_effective_waddr[11:2]][23:16] =
                        `SOC_HIER.axi_top.manager.axi_wdata[23:16];
                    ps_shadow_valid_bytes[ps_effective_waddr[11:2]][2] = 1'b1;
                end
                if (`SOC_HIER.axi_top.manager.axi_wstrb[3]) begin
                    ps_shadow_mem[ps_effective_waddr[11:2]][31:24] =
                        `SOC_HIER.axi_top.manager.axi_wdata[31:24];
                    ps_shadow_valid_bytes[ps_effective_waddr[11:2]][3] = 1'b1;
                end

                if ((ps_effective_waddr == DONE_ADDR) &&
                    (`SOC_HIER.axi_top.manager.axi_wdata == DONE_VALUE) &&
                    (`SOC_HIER.axi_top.manager.axi_wstrb == 4'b1111)) begin
                    done_write_seen = 1'b1;
                end
            end
        end

        // --------------------------------------------------------
        // AXI write response channel
        // --------------------------------------------------------
        if (`SOC_HIER.axi_top.manager.axi_bvalid &&
            `SOC_HIER.axi_top.manager.axi_bready) begin
            ps_b_handshakes = ps_b_handshakes + 1;
            if (`SOC_HIER.axi_top.manager.axi_bresp !== 2'b00) begin
                $error("POSTSYN AXI: non-OKAY BRESP=%b",
                       `SOC_HIER.axi_top.manager.axi_bresp);
                ps_axi_errors = ps_axi_errors + 1;
            end
            ps_aw_seen = 1'b0;
        end

        // --------------------------------------------------------
        // AXI read address channel
        // --------------------------------------------------------
        if (`SOC_HIER.axi_top.manager.axi_arvalid &&
            `SOC_HIER.axi_top.manager.axi_arready) begin
            ps_ar_handshakes = ps_ar_handshakes + 1;
            ps_pending_raddr = `SOC_HIER.axi_top.manager.axi_araddr;
            ps_read_pending = 1'b1;
        end

        // --------------------------------------------------------
        // AXI read response channel
        // --------------------------------------------------------
        if (`SOC_HIER.axi_top.manager.axi_rvalid &&
            `SOC_HIER.axi_top.manager.axi_rready) begin
            ps_r_handshakes = ps_r_handshakes + 1;

            if (`SOC_HIER.axi_top.manager.axi_rresp !== 2'b00) begin
                $error("POSTSYN AXI: non-OKAY RRESP=%b",
                       `SOC_HIER.axi_top.manager.axi_rresp);
                ps_axi_errors = ps_axi_errors + 1;
            end

            if (ps_read_pending &&
                (ps_shadow_valid_bytes[ps_pending_raddr[11:2]] != 4'b0000)) begin

                if (ps_shadow_valid_bytes[ps_pending_raddr[11:2]][0] &&
                    (`SOC_HIER.axi_top.manager.axi_rdata[7:0] !==
                     ps_shadow_mem[ps_pending_raddr[11:2]][7:0])) begin
                    $error("POSTSYN AXI: RDATA byte0 mismatch addr=%08h", ps_pending_raddr);
                    ps_transport_errors = ps_transport_errors + 1;
                end

                if (ps_shadow_valid_bytes[ps_pending_raddr[11:2]][1] &&
                    (`SOC_HIER.axi_top.manager.axi_rdata[15:8] !==
                     ps_shadow_mem[ps_pending_raddr[11:2]][15:8])) begin
                    $error("POSTSYN AXI: RDATA byte1 mismatch addr=%08h", ps_pending_raddr);
                    ps_transport_errors = ps_transport_errors + 1;
                end

                if (ps_shadow_valid_bytes[ps_pending_raddr[11:2]][2] &&
                    (`SOC_HIER.axi_top.manager.axi_rdata[23:16] !==
                     ps_shadow_mem[ps_pending_raddr[11:2]][23:16])) begin
                    $error("POSTSYN AXI: RDATA byte2 mismatch addr=%08h", ps_pending_raddr);
                    ps_transport_errors = ps_transport_errors + 1;
                end

                if (ps_shadow_valid_bytes[ps_pending_raddr[11:2]][3] &&
                    (`SOC_HIER.axi_top.manager.axi_rdata[31:24] !==
                     ps_shadow_mem[ps_pending_raddr[11:2]][31:24])) begin
                    $error("POSTSYN AXI: RDATA byte3 mismatch addr=%08h", ps_pending_raddr);
                    ps_transport_errors = ps_transport_errors + 1;
                end
            end

            ps_read_pending = 1'b0;
        end
    end
end

function automatic logic [3:0] ps_valid_mask(input logic [31:0] addr);
    ps_valid_mask = ps_shadow_valid_bytes[addr[11:2]];
endfunction

function automatic logic [31:0] ps_shadow_word(input logic [31:0] addr);
    ps_shadow_word = ps_shadow_mem[addr[11:2]];
endfunction

task automatic ps_check_word(
    input logic [31:0] addr,
    input logic [31:0] expected,
    input string name
);
    logic [31:0] actual;
    begin
        actual = ps_shadow_word(addr);
        if ((ps_valid_mask(addr) !== 4'b1111) || (actual !== expected)) begin
            $error("POSTSYN SIGNATURE FAIL %-30s addr=%08h valid=%b expected=%08h observed=%08h",
                   name, addr, ps_valid_mask(addr), expected, actual);
            ps_scoreboard_errors++;
        end
        else begin
            ps_scoreboard_passes++;
            $display("POSTSYN SIGNATURE PASS %-30s addr=%08h value=%08h",
                     name, addr, actual);
        end
    end
endtask

task automatic ps_check_unwritten(
    input logic [31:0] addr,
    input string name
);
    begin
        if (ps_valid_mask(addr) !== 4'b0000) begin
            $error("POSTSYN NEGATIVE CHECK FAIL %-25s addr=%08h valid=%b",
                   name, addr, ps_valid_mask(addr));
            ps_scoreboard_errors++;
        end
        else begin
            ps_scoreboard_passes++;
            $display("POSTSYN NEGATIVE CHECK PASS %-25s addr=%08h",
                     name, addr);
        end
    end
endtask

task automatic run_post_synth_scoreboard();
    begin
        $display("\n============================================================");
        $display("POST-SYNTHESIS ARCHITECTURAL SCOREBOARD");
        $display("============================================================");

        if (ps_loader_word_writes !== PROGRAM_WORDS) begin
            $error("POSTSYN SCOREBOARD: loader writes expected=%0d actual=%0d",
                   PROGRAM_WORDS, ps_loader_word_writes);
            ps_scoreboard_errors++;
        end

        if (ps_loader_errors != 0) begin
            $error("POSTSYN SCOREBOARD: loader monitor errors=%0d", ps_loader_errors);
            ps_scoreboard_errors++;
        end

        if (!done_write_seen) begin
            $error("POSTSYN SCOREBOARD: DONE write not observed");
            ps_scoreboard_errors++;
            return;
        end

        ps_check_word(32'h00000200, 32'h0000000d, "MAIN 0x200");
        ps_check_word(32'h00000204, 32'h00000007, "MAIN 0x204");
        ps_check_word(32'h00000208, 32'h00000050, "MAIN 0x208");
        ps_check_word(32'h0000020c, 32'h00000001, "MAIN 0x20c");
        ps_check_word(32'h00000210, 32'h00000001, "MAIN 0x210");
        ps_check_word(32'h00000214, 32'h00000009, "MAIN 0x214");
        ps_check_word(32'h00000218, 32'h00000001, "MAIN 0x218");
        ps_check_word(32'h0000021c, 32'hffffffff, "MAIN 0x21c");
        ps_check_word(32'h00000220, 32'h0000000b, "MAIN 0x220");
        ps_check_word(32'h00000224, 32'h00000002, "MAIN 0x224");
        ps_check_word(32'h00000228, 32'h0000000f, "MAIN 0x228");
        ps_check_word(32'h0000022c, 32'h00000001, "MAIN 0x22c");
        ps_check_word(32'h00000230, 32'h00000000, "MAIN 0x230");
        ps_check_word(32'h00000234, 32'h000000fa, "MAIN 0x234");
        ps_check_word(32'h00000238, 32'h0000000f, "MAIN 0x238");
        ps_check_word(32'h0000023c, 32'h00000000, "MAIN 0x23c");
        ps_check_word(32'h00000240, 32'h00000028, "MAIN 0x240");
        ps_check_word(32'h00000244, 32'h00000005, "MAIN 0x244");
        ps_check_word(32'h00000248, 32'hfffffffc, "MAIN 0x248");
        ps_check_word(32'h0000024c, 32'h12345000, "MAIN 0x24c");
        ps_check_word(32'h00000250, 32'h000010b4, "MAIN 0x250");
        ps_check_word(32'h00000254, 32'h12345678, "MAIN 0x254");
        ps_check_word(32'h00000258, 32'h00005678, "MAIN 0x258");
        ps_check_word(32'h0000025c, 32'h00005678, "MAIN 0x25c");
        ps_check_word(32'h00000260, 32'h00000078, "MAIN 0x260");
        ps_check_word(32'h00000264, 32'h00000078, "MAIN 0x264");
        ps_check_word(32'h00000268, 32'hffff8001, "MAIN 0x268");
        ps_check_word(32'h0000026c, 32'h00008001, "MAIN 0x26c");
        ps_check_word(32'h00000270, 32'hffffff80, "MAIN 0x270");
        ps_check_word(32'h00000274, 32'h00000080, "MAIN 0x274");
        ps_check_word(32'h00000278, 32'h0000003f, "MAIN 0x278");
        ps_check_word(32'h0000027c, 32'h1234acf0, "MAIN 0x27c");
        ps_check_word(32'h00000280, 32'h00000001, "MAIN 0x280");
        ps_check_word(32'h00000284, 32'h00000001, "MAIN 0x284");
        ps_check_word(32'h00000288, 32'h00000001, "MAIN 0x288");
        ps_check_word(32'h0000028c, 32'h00000001, "MAIN 0x28c");
        ps_check_word(32'h00000290, 32'h00000001, "MAIN 0x290");
        ps_check_word(32'h00000294, 32'h00000001, "MAIN 0x294");
        ps_check_word(32'h0000029c, 32'h000001bc, "MAIN 0x29c");
        ps_check_word(32'h000002a4, 32'h000001d8, "MAIN 0x2a4");

        ps_check_unwritten(32'h00000298, "JAL wrong-path store");
        ps_check_unwritten(32'h000002a0, "JALR wrong-path store");

        ps_check_word(32'h00000300, 32'hffffffff, "EDGE 0x300");
        ps_check_word(32'h00000304, 32'hffffffff, "EDGE 0x304");
        ps_check_word(32'h00000308, 32'h00000001, "EDGE 0x308");
        ps_check_word(32'h0000030c, 32'h00000000, "EDGE 0x30c");
        ps_check_word(32'h00000310, 32'h00000001, "EDGE 0x310");
        ps_check_word(32'h00000314, 32'h00000000, "EDGE 0x314");
        ps_check_word(32'h00000318, 32'haaaaaaaa, "EDGE 0x318");
        ps_check_word(32'h0000031c, 32'hbeefbeef, "EDGE 0x31c");
        ps_check_word(32'h00000320, 32'hffffff80, "EDGE 0x320");
        ps_check_word(32'h00000324, 32'h00000080, "EDGE 0x324");
        ps_check_word(32'h00000328, 32'hffff8001, "EDGE 0x328");
        ps_check_word(32'h0000032c, 32'h00008001, "EDGE 0x32c");
        ps_check_word(32'h00000330, 32'h00000000, "EDGE 0x330");
        ps_check_word(32'h00000334, 32'h80000000, "EDGE 0x334");
        ps_check_word(32'h00000338, 32'h000002d4, "EDGE 0x338");
        ps_check_word(32'h0000033c, 32'hfffff800, "EDGE 0x33c");
        ps_check_word(32'h00000340, 32'h000007ff, "EDGE 0x340");

        $display("\nPOST-SYNTH AXI AW handshakes : %0d", ps_aw_handshakes);
        $display("POST-SYNTH AXI W handshakes  : %0d", ps_w_handshakes);
        $display("POST-SYNTH AXI B handshakes  : %0d", ps_b_handshakes);
        $display("POST-SYNTH AXI AR handshakes : %0d", ps_ar_handshakes);
        $display("POST-SYNTH AXI R handshakes  : %0d", ps_r_handshakes);
        $display("Scoreboard PASS              : %0d", ps_scoreboard_passes);
        $display("Scoreboard FAIL              : %0d", ps_scoreboard_errors);
    end
endtask
