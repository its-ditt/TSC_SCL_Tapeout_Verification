`timescale 1ns/1ps
`include "tb_config.svh"
module tb_soc_top;

    // ============================================================
    // DUT inputs / outputs
    // ============================================================
    logic clk;
    logic rst_n;
    logic load_mode;
    logic [7:0] data_in;
    logic byte_strobe;
    logic [31:0] debug_out;

    // ============================================================
    // Program image
    // ============================================================
    logic [31:0] program_words [0:PROGRAM_WORDS-1];

    // ============================================================
    // Reference model state
    // ============================================================
    logic [31:0] ref_regs [0:31];
    logic [31:0] ref_mem [0:DMEM_WORDS-1];
    logic        ref_mem_valid [0:DMEM_WORDS-1];
    logic        ref_error;
    integer      ref_steps;
    logic [31:0] ref_final_pc;

    // Transport shadow memory
    logic [31:0] shadow_mem [0:DMEM_WORDS-1];
    logic        shadow_valid_words [0:DMEM_WORDS-1];

    // ============================================================
    // Counters / diagnostics
    // ============================================================
    integer load_errors = 0;
    integer loader_word_writes = 0;
    integer loader_errors = 0;
    integer scoreboard_passes = 0;
    integer scoreboard_errors = 0;
    integer assertion_failures = 0;
    integer fetch_checks = 0;
    integer fetch_errors = 0;
    integer control_errors = 0;
    integer forward_errors = 0;
    integer transport_errors = 0;
    integer axi_errors = 0;

    integer cpu_write_reqs = 0;
    integer cpu_read_reqs  = 0;
    integer aw_handshakes = 0;
    integer w_handshakes  = 0;
    integer b_handshakes  = 0;
    integer ar_handshakes = 0;
    integer r_handshakes  = 0;

    logic write_pending;
    logic read_pending;
    logic [31:0] pending_waddr;
    logic [31:0] pending_wdata;
    logic [3:0] pending_wstrb;
    logic [31:0] pending_raddr;

    // ============================================================
    // Clock
    // ============================================================
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // ============================================================
    // DUT
    // ============================================================
    soc_top dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .debug_out   (debug_out),
        .load_mode   (load_mode),
        .data_in     (data_in),
        .byte_strobe (byte_strobe)
    );

    

    // Program image is generated from the assembly source before simulation.
    `include "program_image.svh"
    `include "tb_reference_model.svh"
    `include "tb_program_loader.svh"
    `include "tb_axi_monitor.svh"
    `include "tb_processor_monitor.svh"
    `include "tb_scoreboard.svh"
    `include "tb_assertions.svh"
    `include "tb_coverage.svh"

    // ============================================================
    // Main test
    // ============================================================
    initial begin
        rst_n       = 1'b0;
        load_mode   = 1'b0;
        data_in     = 8'h00;
        byte_strobe = 1'b0;

        // Build architectural expectation from the intended program.
        // This does not use DUT internal state.
        repeat (3) @(posedge clk);
        build_reference_model();

        // External reset for loader + SoC.
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        // Boot-load the exact program through the real byte_loader path.
        load_program_through_byte_loader();

        // Run until the real processor writes DONE_ADDR = 1.
        $display("\n============================================================");
        $display("RUNNING FULL SOC DIRECTED PROGRAM");
        $display("============================================================");

        begin : run_wait
            int cyc;
            for (cyc = 0; cyc < MAX_RUN_CYCLES; cyc++) begin
                @(posedge clk);
                if (dut.axi_top.ram_slave.Dmem.mem[DONE_ADDR[11:2]][31:0] === DONE_VALUE) begin
                    $display("Completion marker observed after %0d run cycles", cyc+1);
                    disable run_wait;
                end
            end

            $error("TIMEOUT: completion marker not reached within %0d cycles", MAX_RUN_CYCLES);
            scoreboard_errors++;
        end

        // Give the final write-response / pipeline state a few cycles to settle.
        repeat (5) @(posedge clk);

        run_final_scoreboard();

        $display("\n============================================================");
        $display("SOC DIRECTED TEST SUMMARY");
        $display("============================================================");
        $display("Load errors          : %0d", load_errors);
        $display("Fetch errors         : %0d", fetch_errors);
        $display("Control errors       : %0d", control_errors);
        $display("Forwarding errors    : %0d", forward_errors);
        $display("Transport errors     : %0d", transport_errors);
        $display("AXI response errors  : %0d", axi_errors);
        $display("Assertion failures   : %0d", assertion_failures);
        $display("Scoreboard errors    : %0d", scoreboard_errors);
        $display("============================================================");

        if ((load_errors == 0) &&
            (fetch_errors == 0) &&
            (control_errors == 0) &&
            (forward_errors == 0) &&
            (transport_errors == 0) &&
            (axi_errors == 0) &&
            (assertion_failures == 0) &&
            (scoreboard_errors == 0) &&
            !ref_error) begin
            $display("******** FULL SOC DIRECTED TEST : PASS ********");
        end
        else begin
            $display("******** FULL SOC DIRECTED TEST : FAIL ********");
        end

        $finish;
    end

endmodule
