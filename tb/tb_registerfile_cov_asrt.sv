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


    // ============================================================
    // REFERENCE MODEL
    // ============================================================

    logic [31:0] model_reg [0:31];

    integer i;

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
        // Read address 1
        // --------------------------------------------------------

        cp_A1 : coverpoint A1 {

            bins X0 = {5'd0};

            bins LOW_REGS = {[5'd1:5'd7]};

            bins MID_REGS = {[5'd8:5'd23]};

            bins HIGH_REGS = {[5'd24:5'd30]};

            bins X31 = {5'd31};

        }


        // --------------------------------------------------------
        // Read address 2
        // --------------------------------------------------------

        cp_A2 : coverpoint A2 {

            bins X0 = {5'd0};

            bins LOW_REGS = {[5'd1:5'd7]};

            bins MID_REGS = {[5'd8:5'd23]};

            bins HIGH_REGS = {[5'd24:5'd30]};

            bins X31 = {5'd31};

        }


        // --------------------------------------------------------
        // Write address
        // --------------------------------------------------------

        cp_A3 : coverpoint A3 {

            bins X0 = {5'd0};

            bins LOW_REGS = {[5'd1:5'd7]};

            bins MID_REGS = {[5'd8:5'd23]};

            bins HIGH_REGS = {[5'd24:5'd30]};

            bins X31 = {5'd31};

        }


        // --------------------------------------------------------
        // Write enable
        // --------------------------------------------------------

        cp_WE3 : coverpoint WE3 {

            bins WRITE_DISABLED = {1'b0};

            bins WRITE_ENABLED = {1'b1};

        }


        // --------------------------------------------------------
        // Important write data patterns
        // --------------------------------------------------------

        cp_WD3 : coverpoint WD3 {

            bins ZERO     = {32'h00000000};

            bins ONE      = {32'h00000001};

            bins ALL_ONES = {32'hFFFFFFFF};

            bins MIN_NEG  = {32'h80000000};

            bins MAX_POS  = {32'h7FFFFFFF};

            bins AA       = {32'hAAAAAAAA};

            bins 55       = {32'h55555555};

            bins OTHER = default;

        }


        // --------------------------------------------------------
        // Read data patterns
        // --------------------------------------------------------

        cp_RD1 : coverpoint RD1 {

            bins ZERO     = {32'h00000000};

            bins ONE      = {32'h00000001};

            bins ALL_ONES = {32'hFFFFFFFF};

            bins MIN_NEG  = {32'h80000000};

            bins MAX_POS  = {32'h7FFFFFFF};

            bins AA       = {32'hAAAAAAAA};

            bins 55       = {32'h55555555};

            bins OTHER = default;

        }


        cp_RD2 : coverpoint RD2 {

            bins ZERO     = {32'h00000000};

            bins ONE      = {32'h00000001};

            bins ALL_ONES = {32'hFFFFFFFF};

            bins MIN_NEG  = {32'h80000000};

            bins MAX_POS  = {32'h7FFFFFFF};

            bins AA       = {32'hAAAAAAAA};

            bins 55       = {32'h55555555};

            bins OTHER = default;

        }


        // --------------------------------------------------------
        // Important relationship:
        // write address == read address
        // --------------------------------------------------------

        write_read1_cross : cross cp_A3, cp_A1;

        write_read2_cross : cross cp_A3, cp_A2;

    endgroup


    regfile_coverage cov;


    // ============================================================
    // ASSERTION 1
    // x0 must always read zero
    // ============================================================

    always @(*) begin

        if (A1 == 5'd0) begin

            if (RD1 !== 32'h00000000) begin

                $error(
                    "ASSERTION FAILED: RD1/x0 != 0 | RD1=%h",
                    RD1
                );

                assertion_failures =
                    assertion_failures + 1;

            end

        end

    end


    always @(*) begin

        if (A2 == 5'd0) begin

            if (RD2 !== 32'h00000000) begin

                $error(
                    "ASSERTION FAILED: RD2/x0 != 0 | RD2=%h",
                    RD2
                );

                assertion_failures =
                    assertion_failures + 1;

            end

        end

    end


    // ============================================================
    // ASSERTION 2
    // Same-cycle forwarding on RD1
    // ============================================================

    always @(*) begin

        if (
            WE3 &&
            (A3 == A1) &&
            (A3 != 5'd0)
        ) begin

            if (RD1 !== WD3) begin

                $error(
                    "ASSERTION FAILED: RD1 forwarding | "
                    "A3=%0d WD3=%h RD1=%h",
                    A3,
                    WD3,
                    RD1
                );

                assertion_failures =
                    assertion_failures + 1;

            end

        end

    end


    // ============================================================
    // ASSERTION 3
    // Same-cycle forwarding on RD2
    // ============================================================

    always @(*) begin

        if (
            WE3 &&
            (A3 == A2) &&
            (A3 != 5'd0)
        ) begin

            if (RD2 !== WD3) begin

                $error(
                    "ASSERTION FAILED: RD2 forwarding | "
                    "A3=%0d WD3=%h RD2=%h",
                    A3,
                    WD3,
                    RD2
                );

                assertion_failures =
                    assertion_failures + 1;

            end

        end

    end


    // ============================================================
    // ASSERTION 4
    // x0 write must not affect read value
    // ============================================================

    always @(*) begin

        if (
            WE3 &&
            (A3 == 5'd0)
        ) begin

            if (RD1 !== 32'h00000000) begin

                $error(
                    "ASSERTION FAILED: x0 write affected RD1 | "
                    "RD1=%h",
                    RD1
                );

                assertion_failures =
                    assertion_failures + 1;

            end

        end

    end


    always @(*) begin

        if (
            WE3 &&
            (A3 == 5'd0)
        ) begin

            if (RD2 !== 32'h00000000) begin

                $error(
                    "ASSERTION FAILED: x0 write affected RD2 | "
                    "RD2=%h",
                    RD2
                );

                assertion_failures =
                    assertion_failures + 1;

            end

        end

    end


    // ============================================================
    // SAMPLE COVERAGE
    // ============================================================

    always @(*) begin

        cov.sample();

    end


    // ============================================================
    // INITIAL TEST SEQUENCE
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // Initialize
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
        // RESET
        // ========================================================

        rst = 1'b0;

        #2;

        rst = 1'b1;

        #2;


        // ========================================================
        // x0 READ
        // ========================================================

        A1 = 5'd0;
        A2 = 5'd0;

        #2;


        // ========================================================
        // BASIC WRITE
        // ========================================================

        @(negedge clk);

        A3  = 5'd1;
        WD3 = 32'h12345678;
        WE3 = 1'b1;

        @(posedge clk);

        #1;

        WE3 = 1'b0;

        A1 = 5'd1;
        A2 = 5'd0;

        #2;


        // ========================================================
        // WRITE IMPORTANT DATA PATTERNS
        // ========================================================

        @(negedge clk);

        A3  = 5'd2;
        WD3 = 32'hAAAAAAAA;
        WE3 = 1'b1;

        @(posedge clk);

        #1;

        WE3 = 1'b0;


        @(negedge clk);

        A3  = 5'd3;
        WD3 = 32'h55555555;
        WE3 = 1'b1;

        @(posedge clk);

        #1;

        WE3 = 1'b0;


        @(negedge clk);

        A3  = 5'd4;
        WD3 = 32'hFFFFFFFF;
        WE3 = 1'b1;

        @(posedge clk);

        #1;

        WE3 = 1'b0;


        @(negedge clk);

        A3  = 5'd5;
        WD3 = 32'h80000000;
        WE3 = 1'b1;

        @(posedge clk);

        #1;

        WE3 = 1'b0;


        @(negedge clk);

        A3  = 5'd6;
        WD3 = 32'h7FFFFFFF;
        WE3 = 1'b1;

        @(posedge clk);

        #1;

        WE3 = 1'b0;


        // ========================================================
        // READ BOTH PORTS
        // ========================================================

        A1 = 5'd1;
        A2 = 5'd2;

        #2;


        A1 = 5'd3;
        A2 = 5'd4;

        #2;


        A1 = 5'd5;
        A2 = 5'd6;

        #2;


        // ========================================================
        // SAME REGISTER ON BOTH READ PORTS
        // ========================================================

        A1 = 5'd3;
        A2 = 5'd3;

        #2;


        // ========================================================
        // FORWARDING RD1
        // ========================================================

        @(negedge clk);

        A3  = 5'd10;
        WD3 = 32'hCAFEBABE;
        WE3 = 1'b1;

        A1 = 5'd10;
        A2 = 5'd0;

        #2;


        // ========================================================
        // FORWARDING RD2
        // ========================================================

        A1 = 5'd0;
        A2 = 5'd10;

        #2;


        // ========================================================
        // FORWARDING BOTH PORTS
        // ========================================================

        A1 = 5'd10;
        A2 = 5'd10;

        #2;


        @(posedge clk);

        #1;

        WE3 = 1'b0;


        // ========================================================
        // x0 WRITE ATTEMPT
        // ========================================================

        @(negedge clk);

        A3  = 5'd0;
        WD3 = 32'hDEADBEEF;
        WE3 = 1'b1;

        A1 = 5'd0;
        A2 = 5'd0;

        #2;


        @(posedge clk);

        #1;

        WE3 = 1'b0;


        // ========================================================
        // x31
        // ========================================================

        @(negedge clk);

        A3  = 5'd31;
        WD3 = 32'hFFFFFFFF;
        WE3 = 1'b1;

        @(posedge clk);

        #1;

        WE3 = 1'b0;

        A1 = 5'd31;
        A2 = 5'd31;

        #2;


        // ========================================================
        // RANDOM STIMULUS
        // ========================================================

        repeat (200) begin

            A1 = $urandom_range(0,31);

            A2 = $urandom_range(0,31);

            A3 = $urandom_range(0,31);

            WD3 = $urandom;

            WE3 = $urandom_range(0,1);

            #1;

            if (WE3) begin

                @(posedge clk);

                #1;

            end

        end


        // ========================================================
        // FINAL x0 CHECK
        // ========================================================

        WE3 = 1'b0;

        A1 = 5'd0;
        A2 = 5'd0;

        #2;


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