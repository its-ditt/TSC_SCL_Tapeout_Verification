integer ps_assertion_failures = 0;

// ============================================================
// Post-synthesis assertions
// Keep properties limited to signals preserved in the supplied
// synthesized hierarchy.
// ============================================================

property ps_p_load_holds_core_reset;
    @(posedge clk) load_mode |-> (`SOC_HIER.core_rst_n == 1'b0);
endproperty
assert property (ps_p_load_holds_core_reset)
    else begin
        ps_assertion_failures++; $error("POSTSYN ASSERT: core reset not held during load_mode");
    end

property ps_p_loader_write_only_in_load;
    @(posedge clk) `SOC_HIER.instr_in.instr_we |-> load_mode;
endproperty
assert property (ps_p_loader_write_only_in_load)
    else begin
        ps_assertion_failures++; $error("POSTSYN ASSERT: instruction SRAM write outside load_mode");
    end

property ps_p_pc_aligned;
    @(posedge clk) disable iff (!rst_n)
        `SOC_HIER.cpu_PcD[1:0] == 2'b00;
endproperty
assert property (ps_p_pc_aligned)
    else begin
        ps_assertion_failures++; $error("POSTSYN ASSERT: decode PC misaligned %08h", `SOC_HIER.cpu_PcD);
    end

property ps_p_aw_stable;
    @(posedge clk) disable iff (!rst_n)
        `SOC_HIER.axi_top.manager.axi_awvalid &&
        !`SOC_HIER.axi_top.manager.axi_awready
        |=> $stable(`SOC_HIER.axi_top.manager.axi_awaddr);
endproperty
assert property (ps_p_aw_stable)
    else begin
        ps_assertion_failures++; $error("POSTSYN ASSERT: AWADDR changed while stalled");
    end

property ps_p_w_stable;
    @(posedge clk) disable iff (!rst_n)
        `SOC_HIER.axi_top.manager.axi_wvalid &&
        !`SOC_HIER.axi_top.manager.axi_wready
        |=> ($stable(`SOC_HIER.axi_top.manager.axi_wdata) &&
             $stable(`SOC_HIER.axi_top.manager.axi_wstrb));
endproperty
assert property (ps_p_w_stable)
    else begin
        ps_assertion_failures++; $error("POSTSYN ASSERT: WDATA/WSTRB changed while stalled");
    end

property ps_p_ar_stable;
    @(posedge clk) disable iff (!rst_n)
        `SOC_HIER.axi_top.manager.axi_arvalid &&
        !`SOC_HIER.axi_top.manager.axi_arready
        |=> $stable(`SOC_HIER.axi_top.manager.axi_araddr);
endproperty
assert property (ps_p_ar_stable)
    else begin
        ps_assertion_failures++; $error("POSTSYN ASSERT: ARADDR changed while stalled");
    end

property ps_p_branch_target_aligned;
    @(posedge clk) disable iff (!rst_n)
        `SOC_HIER.cpu_PcSrcE |-> (`SOC_HIER.cpu_PcTargetE[0] == 1'b0);
endproperty
assert property (ps_p_branch_target_aligned)
    else begin
        ps_assertion_failures++; $error("POSTSYN ASSERT: odd branch/jump target %08h", `SOC_HIER.cpu_PcTargetE);
    end

property ps_p_bresp_okay;
    @(posedge clk) disable iff (!rst_n)
        `SOC_HIER.axi_top.manager.axi_bvalid |->
        (`SOC_HIER.axi_top.manager.axi_bresp == 2'b00);
endproperty
assert property (ps_p_bresp_okay)
    else begin
        ps_assertion_failures++; $error("POSTSYN ASSERT: AXI BRESP not OKAY");
    end

property ps_p_rresp_okay;
    @(posedge clk) disable iff (!rst_n)
        `SOC_HIER.axi_top.manager.axi_rvalid |->
        (`SOC_HIER.axi_top.manager.axi_rresp == 2'b00);
endproperty
assert property (ps_p_rresp_okay)
    else begin
        ps_assertion_failures++; $error("POSTSYN ASSERT: AXI RRESP not OKAY");
    end
