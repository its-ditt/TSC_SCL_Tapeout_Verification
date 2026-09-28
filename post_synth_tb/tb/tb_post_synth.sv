`timescale 1ns/1ps

module tb_post_synth;
    `include "tb_post_synth_config.svh"

    logic clk;
    logic rst_n;
    logic load_mode;
    logic [1:0] data_in;
    logic qbit_strobe;
    wire [31:0] result_out;

    logic [31:0] program_words [0:PROGRAM_WORDS-1];

    // Reference-model state is retained as a diagnostic only.
    logic [31:0] ref_regs [0:31];
    logic [31:0] ref_mem [0:DMEM_WORDS-1];
    logic [3:0]  ref_mem_valid_bytes [0:DMEM_WORDS-1];
    logic        ref_error;
    integer      ref_steps;
    logic [31:0] ref_final_pc;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Actual synthesized top from the supplied Genus netlist.
    soc_top_wrapper dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .load_mode   (load_mode),
        .data_in     (data_in),
        .qbit_strobe (qbit_strobe),
        .result_out  (result_out)
    );

    `include "program_image.svh"
    `include "tb_reference_model.svh"
    `include "tb_post_synth_loader.svh"
    `include "tb_post_synth_processor_monitor.svh"
    `include "tb_post_synth_axi_monitor.svh"
    `include "tb_post_synth_assertions.svh"

`ifdef ENABLE_SDF
    initial begin
        $display("POST-SYNTH: scheduling SDF annotation: %s", `POSTSYN_SDF_FILE);
        $sdf_annotate(`POSTSYN_SDF_FILE, dut);
    end
`endif

    initial begin
        rst_n       = 1'b0;
        load_mode   = 1'b0;
        data_in     = 2'b00;
        qbit_strobe = 1'b0;

        repeat (5) @(posedge clk);
        build_reference_model();

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        load_program_post_synth();

        if (ps_loader_errors != 0 || ps_loader_word_writes != PROGRAM_WORDS) begin
            $display("\nPOST-SYNTH TEST ABORTED DURING PROGRAM LOAD");
            $display("Loader errors: %0d", ps_loader_errors);
            $finish;
        end

        $display("\n============================================================");
        $display("RUNNING POST-SYNTHESIS GATE-LEVEL PROGRAM");
        $display("============================================================");

        begin : run_wait
            int cyc;
            for (cyc = 0; cyc < MAX_RUN_CYCLES; cyc++) begin
                @(posedge clk);
                if (done_write_seen) begin
                    $display("POST-SYNTH DONE write observed after %0d run cycles", cyc + 1);
                    disable run_wait;
                end
            end

            if (!done_write_seen) begin
                $error("POST-SYNTH TIMEOUT: DONE write not observed within %0d cycles",
                       MAX_RUN_CYCLES);
            end
        end

        repeat (5) @(posedge clk);
        run_post_synth_scoreboard();

        $display("\n============================================================");
        $display("POST-SYNTHESIS VERIFICATION SUMMARY");
        $display("============================================================");
        $display("Loader errors        : %0d", ps_loader_errors);
        $display("Fetch errors         : %0d", ps_fetch_errors);
        $display("Control errors       : %0d", ps_control_errors);
        $display("Forward errors       : %0d", ps_forward_errors);
        $display("Transport errors     : %0d", ps_transport_errors);
        $display("AXI response errors  : %0d", ps_axi_errors);
        $display("Scoreboard errors    : %0d", ps_scoreboard_errors);
        $display("Assertion failures   : %0d", ps_assertion_failures);
        $display("============================================================");

        if ((ps_loader_errors == 0) &&
            (ps_fetch_errors == 0) &&
            (ps_control_errors == 0) &&
            (ps_forward_errors == 0) &&
            (ps_transport_errors == 0) &&
            (ps_axi_errors == 0) &&
            (ps_scoreboard_errors == 0) &&
            (ps_assertion_failures == 0) &&
            done_write_seen &&
            !ref_error) begin
            $display("******** POST-SYNTHESIS FUNCTIONAL GLS : PASS ********");
        end
        else begin
            $display("******** POST-SYNTHESIS FUNCTIONAL GLS : FAIL ********");
        end

        $finish;
    end
endmodule
