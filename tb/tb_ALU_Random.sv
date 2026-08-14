`timescale 1ns / 1ps

module tb_ALU_random_2000;

    // ============================================================
    // DUT SIGNALS
    // ============================================================

    logic [31:0] SrcAE;
    logic [31:0] SrcBE;
    logic [3:0]  ALUControlE;

    logic [31:0] ALUResult;
    logic        zeroE;
    logic        less_thanE;

    // ============================================================
    // TEST VARIABLES
    // ============================================================

    logic [31:0] expected_result;

    integer test_count;
    integer pass_count;
    integer fail_count;

    integer i;


    // ============================================================
    // DUT
    // ============================================================

    ALU dut (
        .SrcAE       (SrcAE),
        .SrcBE       (SrcBE),
        .ALUControlE (ALUControlE),
        .ALUResult   (ALUResult),
        .zeroE       (zeroE),
        .less_thanE  (less_thanE)
    );


    // ============================================================
    // CHECK RESULT
    // ============================================================

    task automatic check_result;

        input [31:0] a;
        input [31:0] b;
        input [3:0]  operation;
        input [31:0] expected;

        begin

            SrcAE       = a;
            SrcBE       = b;
            ALUControlE = operation;

            #1;

            test_count = test_count + 1;

            // ----------------------------------------------------
            // Check ALU result
            // ----------------------------------------------------

            if (ALUResult !== expected) begin

                $display(
                    "FAIL | Test=%0d | Op=%b | A=%h | B=%h | Expected=%h | Got=%h",
                    test_count,
                    operation,
                    a,
                    b,
                    expected,
                    ALUResult
                );

                fail_count = fail_count + 1;

            end
            else begin

                pass_count = pass_count + 1;

            end


            // ----------------------------------------------------
            // Check zero flag
            // ----------------------------------------------------

            if (zeroE !== (expected == 32'h00000000)) begin

                $display(
                    "ZERO FLAG FAIL | Test=%0d | Op=%b | Result=%h | zeroE=%b",
                    test_count,
                    operation,
                    ALUResult,
                    zeroE
                );

                fail_count = fail_count + 1;

            end

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        SrcAE       = 32'h00000000;
        SrcBE       = 32'h00000000;
        ALUControlE = 4'b0000;

        expected_result = 32'h00000000;

        test_count = 0;
        pass_count = 0;
        fail_count = 0;


        $display("");
        $display("================================================");
        $display("       ALU 2000 RANDOM ARITHMETIC TEST");
        $display("================================================");
        $display("");


        // ========================================================
        // 1000 RANDOM ADD TESTS
        // ========================================================

        $display("Running 1000 random ADD tests...");

        for (i = 0; i < 1000; i = i + 1) begin

            SrcAE = $urandom;
            SrcBE = $urandom;

            expected_result = SrcAE + SrcBE;

            check_result(
                SrcAE,
                SrcBE,
                4'b0000,
                expected_result
            );

        end


        // ========================================================
        // 1000 RANDOM SUB TESTS
        // ========================================================

        $display("Running 1000 random SUB tests...");

        for (i = 0; i < 1000; i = i + 1) begin

            SrcAE = $urandom;
            SrcBE = $urandom;

            expected_result = SrcAE - SrcBE;

            check_result(
                SrcAE,
                SrcBE,
                4'b0001,
                expected_result
            );

        end


        // ========================================================
        // FINAL REPORT
        // ========================================================

        $display("");
        $display("================================================");
        $display("             ALU RANDOM TEST REPORT");
        $display("================================================");

        $display(
            "Total Tests  = %0d",
            test_count
        );

        $display(
            "Passed       = %0d",
            pass_count
        );

        $display(
            "Failed       = %0d",
            fail_count
        );

        $display("================================================");
        $display("");


        if (fail_count == 0) begin

            $display(
                "******** 2000 RANDOM TESTS PASSED ********"
            );

        end
        else begin

            $display(
                "******** RANDOM TEST FAILED ********"
            );

        end

        $display("");

        $finish;

    end

endmodule