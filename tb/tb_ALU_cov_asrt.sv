`timescale 1ns/1ps

module tb_ALU_cov_asrt;

    // ============================================================
    // DUT INPUTS
    // ============================================================

    logic [31:0] SrcAE;
    logic [31:0] SrcBE;
    logic [3:0]  ALUControlE;

    // ============================================================
    // DUT OUTPUTS
    // ============================================================

    logic [31:0] ALUResult;
    logic        zeroE;
    logic        less_thanE;

    // ============================================================
    // ASSERTION FAILURE COUNTER
    // ============================================================

    integer assertion_failures;

    // ============================================================
    // DUT
    // ============================================================

    ALU dut (
        .SrcAE(SrcAE),
        .SrcBE(SrcBE),
        .ALUControlE(ALUControlE),
        .ALUResult(ALUResult),
        .zeroE(zeroE),
        .less_thanE(less_thanE)
    );

    // ============================================================
    // FUNCTIONAL COVERAGE
    // ============================================================

    covergroup alu_coverage;

        // --------------------------------------------------------
        // ALU operation coverage
        // --------------------------------------------------------

        cp_operation : coverpoint ALUControlE {

            bins ADD  = {4'b0000};
            bins SUB  = {4'b0001};
            bins AND  = {4'b0010};
            bins OR   = {4'b0011};
            bins XOR  = {4'b0100};
            bins SLL  = {4'b0101};
            bins SRL  = {4'b0110};
            bins SRA  = {4'b0111};
            bins SLTU = {4'b1000};
            bins SLT  = {4'b1001};

            bins INVALID = {[4'b1010:4'b1111]};
        }

        // --------------------------------------------------------
        // Operand A coverage
        // --------------------------------------------------------

        cp_operand_a : coverpoint SrcAE {

            bins ZERO     = {32'h00000000};
            bins ONE      = {32'h00000001};
            bins MAX_POS  = {32'h7FFFFFFF};
            bins MIN_NEG  = {32'h80000000};
            bins ALL_ONES = {32'hFFFFFFFF};

            bins OTHER = default;
        }

        // --------------------------------------------------------
        // Operand B coverage
        // --------------------------------------------------------

        cp_operand_b : coverpoint SrcBE {

            bins ZERO      = {32'h00000000};
            bins ONE       = {32'h00000001};
            bins SHIFT_31  = {32'h0000001F};
            bins MAX_POS   = {32'h7FFFFFFF};
            bins MIN_NEG   = {32'h80000000};
            bins ALL_ONES  = {32'hFFFFFFFF};

            bins OTHER = default;
        }

        // --------------------------------------------------------
        // zeroE coverage
        // --------------------------------------------------------

        cp_zero : coverpoint zeroE {

            bins ZERO_RESULT = {1'b1};
            bins NONZERO_RESULT = {1'b0};
        }

        // --------------------------------------------------------
        // less_thanE coverage
        // --------------------------------------------------------

        cp_less_than : coverpoint less_thanE {

            bins LESS = {1'b1};
            bins NOT_LESS = {1'b0};
        }

    endgroup

    // Coverage object
    alu_coverage cov;

    // ============================================================
    // ASSERTION 1
    // zeroE must be 1 when ALUResult is zero
    // ============================================================

    always @(*) begin

        if (zeroE !== (ALUResult == 32'b0)) begin

            $error(
                "ASSERTION FAILED: zeroE mismatch | ALUResult=%h zeroE=%b",
                ALUResult,
                zeroE
            );

            assertion_failures = assertion_failures + 1;

        end

    end

    // ============================================================
    // ASSERTION 2
    // less_thanE currently follows ALUResult[0]
    // ============================================================

    always @(*) begin

        if (less_thanE !== ALUResult[0]) begin

            $error(
                "ASSERTION FAILED: less_thanE mismatch | ALUResult=%h less_thanE=%b",
                ALUResult,
                less_thanE
            );

            assertion_failures = assertion_failures + 1;

        end

    end

    // ============================================================
    // STIMULUS TASK
    // ============================================================

    task automatic apply_test;

        input [31:0] a;
        input [31:0] b;
        input [3:0]  ctrl;

        begin

            SrcAE = a;
            SrcBE = b;
            ALUControlE = ctrl;

            #1;

            cov.sample();

        end

    endtask

    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        // Initialize
        SrcAE = 32'b0;
        SrcBE = 32'b0;
        ALUControlE = 4'b0000;

        assertion_failures = 0;

        cov = new();

        $display("");
        $display("==============================================");
        $display("   ALU ASSERTION + COVERAGE VERIFICATION");
        $display("==============================================");
        $display("");

        // ========================================================
        // ADD
        // ========================================================

        apply_test(32'd10, 32'd20, 4'b0000);
        apply_test(32'd0, 32'd0, 4'b0000);
        apply_test(32'h7FFFFFFF, 32'd1, 4'b0000);
        apply_test(32'hFFFFFFFF, 32'd1, 4'b0000);

        // ========================================================
        // SUB
        // ========================================================

        apply_test(32'd20, 32'd10, 4'b0001);
        apply_test(32'd10, 32'd10, 4'b0001);
        apply_test(32'h80000000, 32'd1, 4'b0001);

        // ========================================================
        // AND
        // ========================================================

        apply_test(32'hFFFFFFFF, 32'hAAAAAAAA, 4'b0010);
        apply_test(32'hF0F0F0F0, 32'h0F0F0F0F, 4'b0010);
        apply_test(32'd0, 32'hFFFFFFFF, 4'b0010);

        // ========================================================
        // OR
        // ========================================================

        apply_test(32'hF0F0F0F0, 32'h0F0F0F0F, 4'b0011);
        apply_test(32'd0, 32'd0, 4'b0011);

        // ========================================================
        // XOR
        // ========================================================

        apply_test(32'hAAAAAAAA, 32'h55555555, 4'b0100);
        apply_test(32'hAAAAAAAA, 32'hAAAAAAAA, 4'b0100);

        // ========================================================
        // SLL
        // ========================================================

        apply_test(32'h00000001, 32'd0, 4'b0101);
        apply_test(32'h00000001, 32'd1, 4'b0101);
        apply_test(32'h00000001, 32'd31, 4'b0101);

        // ========================================================
        // SRL
        // ========================================================

        apply_test(32'h80000000, 32'd1, 4'b0110);
        apply_test(32'hFFFFFFFF, 32'd4, 4'b0110);
        apply_test(32'h80000000, 32'd31, 4'b0110);

        // ========================================================
        // SRA
        // ========================================================

        apply_test(32'h80000000, 32'd1, 4'b0111);
        apply_test(32'h80000000, 32'd4, 4'b0111);
        apply_test(32'hFFFFFFFF, 32'd4, 4'b0111);
        apply_test(32'h7FFFFFFF, 32'd1, 4'b0111);

        // ========================================================
        // SLTU
        // ========================================================

        apply_test(32'd5, 32'd10, 4'b1000);
        apply_test(32'd10, 32'd5, 4'b1000);
        apply_test(32'hFFFFFFFF, 32'd1, 4'b1000);
        apply_test(32'd1, 32'hFFFFFFFF, 4'b1000);

        // ========================================================
        // SLT
        // ========================================================

        apply_test(32'hFFFFFFFF, 32'd1, 4'b1001);
        apply_test(32'd1, 32'hFFFFFFFF, 4'b1001);
        apply_test(32'h80000000, 32'd0, 4'b1001);
        apply_test(32'h7FFFFFFF, 32'h80000000, 4'b1001);

        // ========================================================
        // INVALID CONTROL VALUES
        // ========================================================

        apply_test(32'h12345678, 32'h87654321, 4'b1010);
        apply_test(32'hFFFFFFFF, 32'hFFFFFFFF, 4'b1111);

        // ========================================================
        // RANDOM TESTS
        // ========================================================

        repeat (100) begin

            SrcAE = $urandom;
            SrcBE = $urandom;
            ALUControlE = $urandom_range(0, 15);

            #1;

            cov.sample();

        end

        // ========================================================
        // FINAL REPORT
        // ========================================================

        $display("");
        $display("==============================================");
        $display("        ALU VERIFICATION REPORT");
        $display("==============================================");

        $display(
            "Functional Coverage = %0.2f%%",
            cov.get_coverage()
        );

        $display(
            "Assertion Failures = %0d",
            assertion_failures
        );

        $display("==============================================");
        $display("");

        if (assertion_failures == 0) begin

            $display("******** ASSERTIONS PASSED ********");

        end
        else begin

            $display("******** ASSERTIONS FAILED ********");

        end

        $display("");

        $finish;

    end

endmodule