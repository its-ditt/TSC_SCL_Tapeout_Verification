// ============================================================
// Fundamental SoC assertions
// ============================================================
// Assertions intentionally focus on stable architectural/interface
// rules rather than reproducing the implementation's timing logic.
// ============================================================

property p_core_held_in_reset_during_load;
    @(posedge clk) load_mode |-> (dut.core_rst_n == 1'b0);
endproperty
assert property (p_core_held_in_reset_during_load)
    else begin
        $error("ASSERT: CPU core was not held in reset during load_mode");
        assertion_failures++;
    end

property p_imem_write_only_in_load_mode;
    @(posedge clk) dut.IMEM_WE |-> load_mode;
endproperty
assert property (p_imem_write_only_in_load_mode)
    else begin
        $error("ASSERT: instruction SRAM write occurred outside load mode");
        assertion_failures++;
    end

property p_loader_write_only_in_load_mode;
    @(posedge clk) dut.instr_in.instr_we |-> load_mode;
endproperty
assert property (p_loader_write_only_in_load_mode)
    else begin
        $error("ASSERT: byte_loader generated instruction write outside load mode");
        assertion_failures++;
    end

property p_fetch_address_aligned;
    @(posedge clk) disable iff (!rst_n) dut.cpu.INSTR_ADD[1:0] == 2'b00;
endproperty
assert property (p_fetch_address_aligned)
    else begin
        $error("ASSERT: instruction address is not word aligned: %08h", dut.cpu.INSTR_ADD);
        assertion_failures++;
    end

property p_x0_zero;
    @(posedge clk) dut.cpu.decode.register_file.reg_file[0] == 32'd0;
endproperty
assert property (p_x0_zero)
    else begin
        $error("ASSERT: x0 was modified");
        assertion_failures++;
    end

property p_aw_stable_until_handshake;
    @(posedge clk) disable iff (!rst_n)
        dut.axi_top.manager.axi_awvalid && !dut.axi_top.manager.axi_awready
        |=> $stable(dut.axi_top.manager.axi_awaddr);
endproperty
assert property (p_aw_stable_until_handshake)
    else begin
        $error("ASSERT: AXI AWADDR changed while AWVALID && !AWREADY");
        assertion_failures++;
    end

property p_w_stable_until_handshake;
    @(posedge clk) disable iff (!rst_n)
        dut.axi_top.manager.axi_wvalid && !dut.axi_top.manager.axi_wready
        |=> ($stable(dut.axi_top.manager.axi_wdata) &&
             $stable(dut.axi_top.manager.axi_wstrb));
endproperty
assert property (p_w_stable_until_handshake)
    else begin
        $error("ASSERT: AXI WDATA/WSTRB changed while WVALID && !WREADY");
        assertion_failures++;
    end

property p_ar_stable_until_handshake;
    @(posedge clk) disable iff (!rst_n)
        dut.axi_top.manager.axi_arvalid && !dut.axi_top.manager.axi_arready
        |=> $stable(dut.axi_top.manager.axi_araddr);
endproperty
assert property (p_ar_stable_until_handshake)
    else begin
        $error("ASSERT: AXI ARADDR changed while ARVALID && !ARREADY");
        assertion_failures++;
    end

property p_branch_target_aligned;
    @(posedge clk) disable iff (!rst_n)
        dut.cpu.PcSrcE |-> dut.cpu.PcTargetE[0] == 1'b0;
endproperty
assert property (p_branch_target_aligned)
    else begin
        $error("ASSERT: odd branch/jump target %08h", dut.cpu.PcTargetE);
        assertion_failures++;
    end

property p_bresp_okay;
    @(posedge clk) disable iff (!rst_n)
        dut.axi_top.manager.axi_bvalid |-> dut.axi_top.manager.axi_bresp == 2'b00;
endproperty
assert property (p_bresp_okay)
    else begin
        $error("ASSERT: AXI write response is not OKAY");
        assertion_failures++;
    end

property p_rresp_okay;
    @(posedge clk) disable iff (!rst_n)
        dut.axi_top.manager.axi_rvalid |-> dut.axi_top.manager.axi_rresp == 2'b00;
endproperty
assert property (p_rresp_okay)
    else begin
        $error("ASSERT: AXI read response is not OKAY");
        assertion_failures++;
    end
