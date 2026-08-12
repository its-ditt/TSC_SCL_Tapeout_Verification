`timescale 1ns/1ps

module tb_ALU;

    logic [31:0] SrcAE;
    logic [31:0] SrcBE;
    logic [3:0]  ALUControlE;

    logic [31:0] ALUResult;
    logic        zeroE;
    logic        less_thanE;

    int pass_count = 0;
    int fail_count = 0;

    ALU dut (
        .SrcAE(SrcAE),
        .SrcBE(SrcBE),
        .ALUControlE(ALUControlE),
        .ALUResult(ALUResult),
        .zeroE(zeroE),
        .less_thanE(less_thanE)
    );

    task automatic check(
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [3:0]  ctrl,
        input logic [31:0] expected
    );

        logic expected_zero;
        logic expected_less;

        begin
            SrcAE = a;
            SrcBE = b;
            ALUControlE = ctrl;

            #1;

            expected_zero = (expected == 32'd0);
            expected_less = expected[0];

            if (ALUResult !== expected ||
                zeroE     !== expected_zero ||
                less_thanE !== expected_less) begin

                $error(
                    "FAIL | A=%h B=%h CTRL=%b | EXP=%h Z=%b LT=%b | GOT=%h Z=%b LT=%b",
                    a, b, ctrl,
                    expected, expected_zero, expected_less,
                    ALUResult, zeroE, less_thanE
                );

                fail_count++;
            end
            else begin
                pass_count++;

                $display(
                    "PASS | A=%h B=%h CTRL=%b | RESULT=%h Z=%b LT=%b",
                    a, b, ctrl,
                    ALUResult, zeroE, less_thanE
                );
            end
        end

    endtask


    initial begin

        $display("\n========================================");
        $display("        ALU BLOCK VERIFICATION");
        $display("========================================\n");


        // ==========================================
        // ADD
        // ==========================================

        check(32'd10, 32'd20, 4'b0000, 32'd30);
        check(32'd0, 32'd0, 4'b0000, 32'd0);
        check(32'hFFFFFFFF, 32'd1, 4'b0000, 32'd0);
        check(32'h7FFFFFFF, 32'd1, 4'b0000, 32'h80000000);


        // ==========================================
        // SUB
        // ==========================================

        check(32'd20, 32'd10, 4'b0001, 32'd10);
        check(32'd10, 32'd20, 4'b0001, 32'hFFFFFFF6);
        check(32'd5, 32'd5, 4'b0001, 32'd0);
        check(32'h80000000, 32'd1, 4'b0001, 32'h7FFFFFFF);


        // ==========================================
        // AND
        // ==========================================

        check(32'hFFFFFFFF, 32'hAAAAAAAA, 4'b0010, 32'hAAAAAAAA);
        check(32'hF0F0F0F0, 32'h0F0F0F0F, 4'b0010, 32'h00000000);
        check(32'd0, 32'hFFFFFFFF, 4'b0010, 32'd0);


        // ==========================================
        // OR
        // ==========================================

        check(32'hF0F0F0F0, 32'h0F0F0F0F, 4'b0011, 32'hFFFFFFFF);
        check(32'd0, 32'd0, 4'b0011, 32'd0);


        // ==========================================
        // XOR
        // ==========================================

        check(32'hAAAAAAAA, 32'h55555555, 4'b0100, 32'hFFFFFFFF);
        check(32'hAAAAAAAA, 32'hAAAAAAAA, 4'b0100, 32'd0);


        // ==========================================
        // SLL
        // ==========================================

        check(32'h00000001, 32'd1, 4'b0101, 32'h00000002);
        check(32'h00000001, 32'd31, 4'b0101, 32'h80000000);
        check(32'hFFFFFFFF, 32'd4, 4'b0101, 32'hFFFFFFF0);
        check(32'h12345678, 32'd0, 4'b0101, 32'h12345678);


        // ==========================================
        // SRL
        // ==========================================

        check(32'h80000000, 32'd1, 4'b0110, 32'h40000000);
        check(32'hFFFFFFFF, 32'd4, 4'b0110, 32'h0FFFFFFF);
        check(32'h80000000, 32'd31, 4'b0110, 32'h00000001);


        // ==========================================
        // SRA
        // ==========================================

        check(32'h80000000, 32'd1, 4'b0111, 32'hC0000000);
        check(32'h80000000, 32'd4, 4'b0111, 32'hF8000000);
        check(32'hFFFFFFFF, 32'd4, 4'b0111, 32'hFFFFFFFF);
        check(32'h7FFFFFFF, 32'd1, 4'b0111, 32'h3FFFFFFF);


        // ==========================================
        // SLTU
        // ==========================================

        check(32'd5, 32'd10, 4'b1000, 32'd1);
        check(32'd10, 32'd5, 4'b1000, 32'd0);

        check(32'hFFFFFFFF, 32'd1, 4'b1000, 32'd0);
        check(32'd1, 32'hFFFFFFFF, 4'b1000, 32'd1);


        // ==========================================
        // SLT
        // ==========================================

        check(32'hFFFFFFFF, 32'd1, 4'b1001, 32'd1);
        check(32'd1, 32'hFFFFFFFF, 4'b1001, 32'd0);

        check(32'h80000000, 32'd0, 4'b1001, 32'd1);
        check(32'h7FFFFFFF, 32'h80000000, 4'b1001, 32'd0);


        // ==========================================
        // DEFAULT / ILLEGAL
        // ==========================================

        check(32'h12345678, 32'h87654321, 4'b1010, 32'd0);
        check(32'hFFFFFFFF, 32'hFFFFFFFF, 4'b1111, 32'd0);


        // ==========================================
        // SUMMARY
        // ==========================================

        $display("\n========================================");
        $display("ALU VERIFICATION COMPLETE");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);
        $display("========================================\n");

        if (fail_count == 0)
            $display("******** ALU BLOCK PASSED ********");
        else
            $display("******** ALU BLOCK FAILED ********");

        $finish;

    end

endmodule