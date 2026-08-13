`timescale 1ns / 1ps

module tb_RegFile_cov_asrt;

    // ============================================================
    // DUT SIGNALS
    // ============================================================

    logic        clk;
    logic        rst;

    logic        WE3;
    logic [4:0]  A1;
    logic [4:0]  A2;
    logic [4:0]  A3;

    logic [31:0] WD3;

    logic [31:0] RD1;
    logic [31:0] RD2;

    integer assertion_failures;


    // ============================================================
    // DUT
    // ============================================================

    registerfile dut (
        .clk  (clk),
        .rst  (rst),

        .WE3  (WE3),

        .A1   (A1),
        .A2   (A2),
        .A3   (A3),

        .WD3  (WD3),

        .RD1  (RD1),
        .RD2  (RD2)
    );


    // ============================================================
    // CLOCK
    // ============================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    // ============================================================
    // FUNCTIONAL COVERAGE
    // ============================================================

    covergroup regfile_coverage;

        // --------------------------------------------------------
        // Read Address 1
        // --------------------------------------------------------

        cp_A1 : coverpoint A1 {

            bins X0     = {5'd0};
            bins LOW    = {[5'd1:5'd7]};
            bins MIDDLE = {[5'd8:5'd23]};
            bins HIGH   = {[5'd24:5'd30]};
            bins X31    = {5'd31};

        }


        // --------------------------------------------------------
        // Read Address 2
        // --------------------------------------------------------

        cp_A2 : coverpoint A2 {

            bins X0     = {5'd0};
            bins LOW    = {[5'd1:5'd7]};
            bins MIDDLE = {[5'd8:5'd23]};
            bins HIGH   = {[5'd24:5'd30]};
            bins X31    = {5'd31};

        }


        // --------------------------------------------------------
        // Write Address
        // --------------------------------------------------------

        cp_A3 : coverpoint A3 {

            bins X0     = {5'd0};
            bins LOW    = {[5'd1:5'd7]};
            bins MIDDLE = {[5'd8:5'd23]};
            bins HIGH   = {[5'd24:5'd30]};
            bins X31    = {5'd31};

        }


        // --------------------------------------------------------
        // Write Enable
        // --------------------------------------------------------

        cp_WE3 : coverpoint WE3 {

            bins DISABLED = {1'b0};
            bins ENABLED  = {1'b1};

        }


        // --------------------------------------------------------
        // Write Data
        // --------------------------------------------------------

        cp_WD3 : coverpoint WD3 {

            bins ZERO_VALUE    = {32'h00000000};
            bins ONE_VALUE     = {32'h00000001};
            bins ALL_ONES      = {32'hFFFFFFFF};
            bins MIN_NEG       = {32'h80000000};
            bins MAX_POS       = {32'h7FFFFFFF};
            bins AA_PATTERN    = {32'hAAAAAAAA};
            bins FIVE_PATTERN  = {32'h55555555};

            bins OTHER = default;

        }


        // --------------------------------------------------------
        // Read Data 1
        // --------------------------------------------------------

        cp_RD1 : coverpoint RD1 {

            bins ZERO_VALUE    = {32'h00000000};
            bins ONE_VALUE     = {32'h00000001};
            bins ALL_ONES      = {32'hFFFFFFFF};
            bins MIN_NEG       = {32'h80000000};
            bins MAX_POS       = {32'h7FFFFFFF};
            bins AA_PATTERN    = {32'hAAAAAAAA};
            bins FIVE_PATTERN  = {32'h55555555};

            bins OTHER = default;

        }


        // --------------------------------------------------------
        // Read Data 2
        // --------------------------------------------------------

        cp_RD2 : coverpoint RD2 {

            bins ZERO_VALUE    = {32'h00000000};
            bins ONE_VALUE     = {32'h00000001};
            bins ALL_ONES      = {32'hFFFFFFFF};
            bins MIN_NEG       = {32'h80000000};
            bins MAX_POS       = {32'h7FFFFFFF};
            bins AA_PATTERN    = {32'hAAAAAAAA};
            bins FIVE_PATTERN  = {32'h55555555};

            bins OTHER = default;

        }


        // --------------------------------------------------------
        // Write/Read Address Relationships
        // --------------------------------------------------------

        cross_A3_A1 : cross cp_A3, cp_A1;

        cross_A3_A2 : cross cp_A3, cp_A2;

    endgroup


    regfile_coverage cov;


    // ============================================================
    // ASSERTION CHECK TASK
    // ============================================================

    task automatic check_assertions;

        begin

            // ----------------------------------------------------
            // ASSERTION 1
            // x0 must always read zero through RD1
            // ----------------------------------------------------

            if (A1 == 5'd0) begin

                if (RD1 !== 32'h00000000) begin

                    $error(
                        "ASSERTION FAILED: RD1 x0 != 0 | RD1=%h",
                        RD1
                    );

                    assertion_failures =
                        assertion_failures + 1;

                end

            end


            // ----------------------------------------------------
            // ASSERTION 2
            // x0 must always read zero through RD2
            // ----------------------------------------------------

            if (A2 == 5'd0) begin

                if (RD2 !== 32'h00000000) begin

                    $error(
                        "ASSERTION FAILED: RD2 x0 != 0 | RD2=%h",
                        RD2
                    );

                    assertion_failures =
                        assertion_failures + 1;

                end

            end


            // ----------------------------------------------------
            // ASSERTION 3
            // Same-cycle forwarding to RD1
            // ----------------------------------------------------

            if (
                WE3 &&
                (A3 == A1) &&
                (A3 != 5'd0)
            ) begin

                if (RD1 !== WD3) begin

                    $error(
                        "ASSERTION FAILED: RD1 forwarding | A3=%0d WD3=%h RD1=%h",
                        A3,
                        WD3,
                        RD1
                    );

                    assertion_failures =
                        assertion_failures + 1;

                end

            end


            // ----------------------------------------------------
            // ASSERTION 4
            // Same-cycle forwarding to RD2
            // ----------------------------------------------------

            if (
                WE3 &&
                (A3 == A2) &&
                (A3 != 5'd0)
            ) begin

                if (RD2 !== WD3) begin

                    $error(
                        "ASSERTION FAILED: RD2 forwarding | A3=%0d WD3=%h RD2=%h",
                        A3,
                        WD3,
                        RD2
                    );

                    assertion_failures =
                        assertion_failures + 1;

                end

            end

        end

    endtask


    // ============================================================
    // SAMPLE COVERAGE
    // ============================================================

    task automatic sample_coverage;

        begin

            cov.sample();

        end

    endtask


    // ============================================================
    // WRITE TEST
    // ============================================================

    task automatic write_test;

        input [4:0]  addr;
        input [31:0] data;

        begin

            @(negedge clk);

            A3  = addr;
            WD3 = data;
            WE3 = 1'b1;

            #1;

            sample_coverage;
            check_assertions;

            @(posedge clk);

            #1;

            WE3 = 1'b0;

        end

    endtask


    // ============================================================
    // READ TEST
    // ============================================================

    task automatic read_test;

        input [4:0] addr1;
        input [4:0] addr2;

        begin

            A1 = addr1;
            A2 = addr2;

            #1;

            sample_coverage;
            check_assertions;

        end

    endtask


    // ============================================================
    // FORWARDING TEST
    // ============================================================

    task automatic forwarding_test;

        input [4:0]  addr;
        input [31:0] data;

        begin

            @(negedge clk);

            A3  = addr;
            WD3 = data;
            WE3 = 1'b1;

            A1 = addr;
            A2 = addr;

            #1;

            sample_coverage;
            check_assertions;

            @(posedge clk);

            #1;

            WE3 = 1'b0;

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // Initialization
        // --------------------------------------------------------

        rst = 1'b1;

        WE3 = 1'b0;

        A1 = 5'd0;
        A2 = 5'd0;
        A3 = 5'd0;

        WD3 = 32'h00000000;

        assertion_failures = 0;

        cov = new();


        $display("");
        $display("================================================");
        $display(" REGISTER FILE ASSERTION + COVERAGE TEST");
        $display("================================================");
        $display("");


        // ========================================================
        // ASYNCHRONOUS RESET
        // ========================================================

        rst = 1'b0;

        #2;

        A1 = 5'd0;
        A2 = 5'd0;

        sample_coverage;
        check_assertions;

        rst = 1'b1;

        #2;


        // ========================================================
        // x0 READ
        // ========================================================

        read_test(5'd0, 5'd0);


        // ========================================================
        // BASIC DATA PATTERNS
        // ========================================================

        write_test(5'd1, 32'h00000000);
        write_test(5'd2, 32'h00000001);
        write_test(5'd3, 32'hFFFFFFFF);
        write_test(5'd4, 32'h80000000);
        write_test(5'd5, 32'h7FFFFFFF);
        write_test(5'd6, 32'hAAAAAAAA);
        write_test(5'd7, 32'h55555555);


        // ========================================================
        // READ DATA
        // ========================================================

        read_test(5'd1, 5'd2);
        read_test(5'd3, 5'd4);
        read_test(5'd5, 5'd6);
        read_test(5'd7, 5'd7);


        // ========================================================
        // RD1 / RD2 INDEPENDENCE
        // ========================================================

        read_test(5'd1, 5'd7);
        read_test(5'd7, 5'd1);
        read_test(5'd3, 5'd5);


        // ========================================================
        // RD1 FORWARDING
        // ========================================================

        forwarding_test(
            5'd10,
            32'hCAFEBABE
        );


        // ========================================================
        // RD2 FORWARDING
        // ========================================================

        @(negedge clk);

        A3  = 5'd11;
        WD3 = 32'hDEADBEEF;
        WE3 = 1'b1;

        A1 = 5'd0;
        A2 = 5'd11;

        #1;

        sample_coverage;
        check_assertions;

        @(posedge clk);

        #1;

        WE3 = 1'b0;


        // ========================================================
        // BOTH READ PORTS FORWARDING
        // ========================================================

        forwarding_test(
            5'd12,
            32'hFACEFACE
        );


        // ========================================================
        // WRITE X0
        //
        // This must be ignored.
        // We do NOT expect RD1/RD2 to become zero unless
        // A1/A2 themselves are zero.
        // ========================================================

        // First establish a known value in x13
        write_test(
            5'd13,
            32'h12345678
        );

        // Attempt to write x0
        write_test(
            5'd0,
            32'hDEADBEEF
        );

        // x0 must still be zero
        read_test(5'd0, 5'd0);

        // x13 must remain unchanged
        read_test(5'd13, 5'd13);


        // ========================================================
        // X31
        // ========================================================

        write_test(
            5'd31,
            32'hFFFFFFFF
        );

        read_test(
            5'd31,
            5'd31
        );


        // ========================================================
        // RANDOM READ ACTIVITY
        // ========================================================

        WE3 = 1'b0;

        repeat (200) begin

            A1 = $urandom_range(0,31);
            A2 = $urandom_range(0,31);

            #1;

            sample_coverage;
            check_assertions;

        end


        // ========================================================
        // RANDOM WRITE + FORWARDING ACTIVITY
        // ========================================================

        repeat (200) begin

            @(negedge clk);

            A3  = $urandom_range(0,31);
            WD3 = $urandom;
            WE3 = $urandom_range(0,1);

            A1 = $urandom_range(0,31);
            A2 = $urandom_range(0,31);

            #1;

            sample_coverage;
            check_assertions;

            @(posedge clk);

            #1;

            WE3 = 1'b0;

        end


        // ========================================================
        // FINAL X0 CHECK
        // ========================================================

        A1 = 5'd0;
        A2 = 5'd0;
        WE3 = 1'b0;

        #1;

        sample_coverage;
        check_assertions;


        // ========================================================
        // REPORT
        // ========================================================

        $display("");
        $display("================================================");
        $display(" REGISTER FILE VERIFICATION REPORT");
        $display("================================================");

        $display(
            "Functional Coverage = %0.2f%%",
            cov.get_coverage()
        );

        $display(
            "Assertion Failures = %0d",
            assertion_failures
        );

        $display("================================================");
        $display("");


        if (assertion_failures == 0) begin

            $display(
                "******** ASSERTIONS PASSED ********"
            );

        end
        else begin

            $display(
                "******** ASSERTIONS FAILED ********"
            );

        end


        $display("");

        $finish;

    end

endmodule