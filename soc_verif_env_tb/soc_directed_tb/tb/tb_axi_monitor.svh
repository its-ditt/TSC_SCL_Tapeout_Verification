// ============================================================
// AXI + CPU memory interface monitor
// ============================================================

always @(posedge clk) begin
    if (!rst_n) begin
        cpu_write_reqs <= 0;
        cpu_read_reqs  <= 0;
        aw_handshakes  <= 0;
        w_handshakes   <= 0;
        b_handshakes   <= 0;
        ar_handshakes  <= 0;
        r_handshakes   <= 0;
        axi_errors     <= 0;
        transport_errors <= 0;
        write_pending  <= 1'b0;
        read_pending   <= 1'b0;
        shadow_valid_words = '{default:1'b0};
        shadow_mem = '{default:32'd0};
    end
    else begin
        // CPU-side request observation.
        if (dut.cpu.MEM_WRITE) begin
            cpu_write_reqs <= cpu_write_reqs + 1;
            write_pending <= 1'b1;
            pending_waddr <= dut.cpu.MEM_ADDR;
            pending_wdata <= dut.cpu.MEM_WDATA;
            pending_wstrb <= dut.cpu.MEM_WSTRB;

            if (dut.cpu.MEM_WSTRB[0])
                shadow_mem[dut.cpu.MEM_ADDR[11:2]][7:0] <= dut.cpu.MEM_WDATA[7:0];
            if (dut.cpu.MEM_WSTRB[1])
                shadow_mem[dut.cpu.MEM_ADDR[11:2]][15:8] <= dut.cpu.MEM_WDATA[15:8];
            if (dut.cpu.MEM_WSTRB[2])
                shadow_mem[dut.cpu.MEM_ADDR[11:2]][23:16] <= dut.cpu.MEM_WDATA[23:16];
            if (dut.cpu.MEM_WSTRB[3])
                shadow_mem[dut.cpu.MEM_ADDR[11:2]][31:24] <= dut.cpu.MEM_WDATA[31:24];
            shadow_valid_words[dut.cpu.MEM_ADDR[11:2]] <= 1'b1;
        end

        if (dut.cpu.MEM_READ) begin
            cpu_read_reqs <= cpu_read_reqs + 1;
            read_pending <= 1'b1;
            pending_raddr <= dut.cpu.MEM_ADDR;
        end

        // AXI write channels.
        if (dut.axi_top.manager.axi_awvalid && dut.axi_top.manager.axi_awready) begin
            aw_handshakes <= aw_handshakes + 1;
            if (!write_pending) begin
                $error("AXI MONITOR: AW handshake without pending CPU write");
                transport_errors <= transport_errors + 1;
            end
            else if (dut.axi_top.manager.axi_awaddr !== pending_waddr) begin
                $error("AXI MONITOR: AWADDR mismatch expected=%08h actual=%08h",
                       pending_waddr, dut.axi_top.manager.axi_awaddr);
                transport_errors <= transport_errors + 1;
            end
        end

        if (dut.axi_top.manager.axi_wvalid && dut.axi_top.manager.axi_wready) begin
            w_handshakes <= w_handshakes + 1;
            if (!write_pending) begin
                $error("AXI MONITOR: W handshake without pending CPU write");
                transport_errors <= transport_errors + 1;
            end
            else begin
                if (dut.axi_top.manager.axi_wdata !== pending_wdata) begin
                    $error("AXI MONITOR: WDATA mismatch expected=%08h actual=%08h",
                           pending_wdata, dut.axi_top.manager.axi_wdata);
                    transport_errors <= transport_errors + 1;
                end
                if (dut.axi_top.manager.axi_wstrb !== pending_wstrb) begin
                    $error("AXI MONITOR: WSTRB mismatch expected=%b actual=%b",
                           pending_wstrb, dut.axi_top.manager.axi_wstrb);
                    transport_errors <= transport_errors + 1;
                end
            end
        end

        if (dut.axi_top.manager.axi_bvalid && dut.axi_top.manager.axi_bready) begin
            b_handshakes <= b_handshakes + 1;
            if (dut.axi_top.manager.axi_bresp !== 2'b00) begin
                $error("AXI MONITOR: non-OKAY BRESP=%b", dut.axi_top.manager.axi_bresp);
                axi_errors <= axi_errors + 1;
            end
            write_pending <= 1'b0;
        end

        // AXI read channel.
        if (dut.axi_top.manager.axi_arvalid && dut.axi_top.manager.axi_arready) begin
            ar_handshakes <= ar_handshakes + 1;
            if (!read_pending) begin
                $error("AXI MONITOR: AR handshake without pending CPU read");
                transport_errors <= transport_errors + 1;
            end
            else if (dut.axi_top.manager.axi_araddr !== pending_raddr) begin
                $error("AXI MONITOR: ARADDR mismatch expected=%08h actual=%08h",
                       pending_raddr, dut.axi_top.manager.axi_araddr);
                transport_errors <= transport_errors + 1;
            end
        end

        if (dut.axi_top.manager.axi_rvalid && dut.axi_top.manager.axi_rready) begin
            r_handshakes <= r_handshakes + 1;
            if (dut.axi_top.manager.axi_rresp !== 2'b00) begin
                $error("AXI MONITOR: non-OKAY RRESP=%b", dut.axi_top.manager.axi_rresp);
                axi_errors <= axi_errors + 1;
            end

            if (pending_raddr[11:2] < DMEM_WORDS && shadow_valid_words[pending_raddr[11:2]]) begin
                if (dut.axi_top.manager.axi_rdata !== shadow_mem[pending_raddr[11:2]]) begin
                    $error("AXI MONITOR: RDATA mismatch at %08h expected=%08h actual=%08h",
                           pending_raddr,
                           shadow_mem[pending_raddr[11:2]],
                           dut.axi_top.manager.axi_rdata);
                    transport_errors <= transport_errors + 1;
                end
            end
            read_pending <= 1'b0;
        end
    end
end
