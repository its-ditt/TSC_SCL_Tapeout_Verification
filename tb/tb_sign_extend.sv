`timescale 1ns / 1ps

module tb_sign_extend_cov_asrt;

    // ============================================================
    // DUT SIGNALS
    // ============================================================

    logic [31:0] Instr;
    logic [31:0] ImmExtend;

    // ============================================================
    // TEST VARIABLES
    // ============================================================

    logic [31:0] expected_imm;

    integer test_count;
    integer pass_count;
    integer fail_count;
    integer assertion_failures;

    integer i;

    // ============================================================
    // DUT
    // ============================================================

    sign_extend dut (
        .Instr     (Instr),
        .ImmExtend (ImmExtend)
    );

    // ============================================================
    // REFERENCE MODEL
    // ============================================================

    function automatic [31:0] reference_imm;

        input [31:0] instruction;

        begin

            case (instruction[6:0])

                // I-type LOAD
                7'b0000011:
                    reference_imm =
                        {{20{instruction[31]}},
                         instruction[31:20]};

                // I-type ALU
                7'b0010011:
                    reference_imm =
                        {{20{instruction[31]}},
                         instruction[31:20]};

                // I-type JALR
                7'b1100111:
                    reference_imm =
                        {{20{instruction[31]}},
                         instruction[31:20]};

                // S-type STORE
                7'b0100011:
                    reference_imm =
                        {{20{instruction[31]}},
                         instruction[31:25],
                         instruction[11:7]};

                // B-type BRANCH
                7'b1100011:
                    reference_imm =
                        {{19{instruction[31]}},
                         instruction[31],
                         instruction[7],
                         instruction[30:25],
                         instruction[11:8],
                         1'b0};

                // J-type JAL
                7'b1101111:
                    reference_imm =
                        {{12{instruction[31]}},
                         instruction[19:12],
                         instruction[20],
                         instruction[30:21],
                         1'b0};

                // U-type LUI
                7'b0110111:
                    reference_imm =
                        {instruction[31:12],12'b0};

                // U-type AUIPC
                7'b0010111:
                    reference_imm =
                        {instruction[31:12],12'b0};

                // Invalid / unsupported opcode
                default:
                    reference_imm = 32'b0;

            endcase

        end

    endfunction

    // ============================================================
    // FUNCTIONAL COVERAGE
    // ============================================================

    covergroup sign_extend_coverage;

        // --------------------------------------------------------
        // Opcode coverage
        // --------------------------------------------------------

        cp_opcode : coverpoint Instr[6:0] {

            bins I_LOAD = {7'b0000011};

            bins I_ALU = {7'b0010011};

            bins I_JALR = {7'b1100111};

            bins S_TYPE = {7'b0100011};

            bins B_TYPE = {7'b1100011};

            bins J_TYPE = {7'b1101111};

            bins U_LUI = {7'b0110111};

            bins U_AUIPC = {7'b0010111};

            bins INVALID = default;

        }

        // --------------------------------------------------------
        // Sign bit coverage
        // --------------------------------------------------------

        cp_sign_bit : coverpoint Instr[31] {

            bins POSITIVE = {1'b0};

            bins NEGATIVE = {1'b1};

        }

        // --------------------------------------------------------
        // Immediate output sign
        // --------------------------------------------------------

        cp_output_sign : coverpoint ImmExtend[31] {

            bins POSITIVE = {1'b0};

            bins NEGATIVE = {1'b1};

        }

        // --------------------------------------------------------
        // Important output values
        // --------------------------------------------------------

        cp_output_value : coverpoint ImmExtend {

            bins ZERO = {32'h00000000};

            bins ONE = {32'h00000001};

            bins ALL_ONES = {32'hFFFFFFFF};

            bins MIN_VALUE = {32'h80000000};

            bins MAX_VALUE = {32'h7FFFFFFF};

            bins OTHER = default;

        }

        // --------------------------------------------------------
        // Opcode × sign
        // --------------------------------------------------------

        opcode_sign_cross : cross cp_opcode, cp_sign_bit;

    endgroup

    sign_extend_coverage cov;

    // ============================================================
    // CHECK TASK
    // ============================================================

    task automatic check_instruction;

        input [31:0] instruction;

        begin

            Instr = instruction;

            #1;

            expected_imm = reference_imm(instruction);

            test_count = test_count + 1;

            // ----------------------------------------------------
            // Behavioral / reference-model check
            // ----------------------------------------------------

            if (ImmExtend !== expected_imm) begin

                $display(
                    "FAIL | Test=%0d | Instr=%h | Opcode=%b | Expected=%h | Got=%h",
                    test_count,
                    instruction,
                    instruction[6:0],
                    expected_imm,
                    ImmExtend
                );

                fail_count = fail_count + 1;

            end
            else begin

                pass_count = pass_count + 1;

            end

            // ----------------------------------------------------
            // Immediate assertion
            // ----------------------------------------------------

            assert (ImmExtend === expected_imm)
            else begin

                $error(
                    "ASSERTION FAILED | Instr=%h | Expected=%h | Got=%h",
                    instruction,
                    expected_imm,
                    ImmExtend
                );

                assertion_failures =
                    assertion_failures + 1;

            end

            // ----------------------------------------------------
            // Coverage
            // ----------------------------------------------------

            cov.sample();

        end

    endtask

    // ============================================================
    // CREATE I-TYPE INSTRUCTION
    // ============================================================

    task automatic test_i_type;

        input [6:0] opcode;
        input [11:0] imm;

        reg [31:0] instruction;

        begin

            instruction = 32'b0;

            instruction[31:20] = imm;

            instruction[6:0] = opcode;

            check_instruction(instruction);

        end

    endtask

    // ============================================================
    // CREATE S-TYPE INSTRUCTION
    // ============================================================

    task automatic test_s_type;

        input [6:0] opcode;
        input [11:0] imm;

        reg [31:0] instruction;

        begin

            instruction = 32'b0;

            instruction[31:25] = imm[11:5];

            instruction[11:7] = imm[4:0];

            instruction[6:0] = opcode;

            check_instruction(instruction);

        end

    endtask

    // ============================================================
    // CREATE B-TYPE INSTRUCTION
    // ============================================================

    task automatic test_b_type;

        input [6:0] opcode;
        input [12:0] imm;

        reg [31:0] instruction;

        begin

            instruction = 32'b0;

            instruction[31] = imm[12];

            instruction[7] = imm[11];

            instruction[30:25] = imm[10:5];

            instruction[11:8] = imm[4:1];

            instruction[6:0] = opcode;

            check_instruction(instruction);

        end

    endtask

    // ============================================================
    // CREATE J-TYPE INSTRUCTION
    // ============================================================

    task automatic test_j_type;

        input [6:0] opcode;
        input [20:0] imm;

        reg [31:0] instruction;

        begin

            instruction = 32'b0;

            instruction[31] = imm[20];

            instruction[19:12] = imm[19:12];

            instruction[20] = imm[11];

            instruction[30:21] = imm[10:1];

            instruction[6:0] = opcode;

            check_instruction(instruction);

        end

    endtask

    // ============================================================
    // CREATE U-TYPE INSTRUCTION
    // ============================================================

    task automatic test_u_type;

        input [6:0] opcode;
        input [19:0] imm;

        reg [31:0] instruction;

        begin

            instruction = 32'b0;

            instruction[31:12] = imm;

            instruction[6:0] = opcode;

            check_instruction(instruction);

        end

    endtask

    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // Initialization
        // --------------------------------------------------------

        Instr = 32'b0;

        expected_imm = 32'b0;

        test_count = 0;

        pass_count = 0;

        fail_count = 0;

        assertion_failures = 0;

        cov = new();

        $display("");
        $display("================================================");
        $display(" SIGN EXTEND BLOCK VERIFICATION");
        $display("================================================");
        $display("");

        // ========================================================
        // I-TYPE LOAD
        // ========================================================

        $display("Testing I-type LOAD...");

        test_i_type(7'b0000011, 12'h000);

        test_i_type(7'b0000011, 12'h001);

        test_i_type(7'b0000011, 12'h7FF);

        test_i_type(7'b0000011, 12'h800);

        test_i_type(7'b0000011, 12'hFFF);

        // ========================================================
        // I-TYPE ALU
        // ========================================================

        $display("Testing I-type ALU...");

        test_i_type(7'b0010011, 12'h000);

        test_i_type(7'b0010011, 12'h001);

        test_i_type(7'b0010011, 12'h7FF);

        test_i_type(7'b0010011, 12'h800);

        test_i_type(7'b0010011, 12'hFFF);

        // ========================================================
        // I-TYPE JALR
        // ========================================================

        $display("Testing I-type JALR...");

        test_i_type(7'b1100111, 12'h000);

        test_i_type(7'b1100111, 12'h001);

        test_i_type(7'b1100111, 12'h7FF);

        test_i_type(7'b1100111, 12'h800);

        test_i_type(7'b1100111, 12'hFFF);

        // ========================================================
        // S-TYPE
        // ========================================================

        $display("Testing S-type...");

        test_s_type(7'b0100011, 12'h000);

        test_s_type(7'b0100011, 12'h001);

        test_s_type(7'b0100011, 12'h7FF);

        test_s_type(7'b0100011, 12'h800);

        test_s_type(7'b0100011, 12'hFFF);

        // ========================================================
        // B-TYPE
        // ========================================================

        $display("Testing B-type...");

        test_b_type(7'b1100011, 13'h0000);

        test_b_type(7'b1100011, 13'h0002);

        test_b_type(7'b1100011, 13'h0010);

        test_b_type(7'b1100011, 13'h0FFE);

        test_b_type(7'b1100011, 13'h1000);

        test_b_type(7'b1100011, 13'h1FFE);

        // ========================================================
        // J-TYPE
        // ========================================================

        $display("Testing J-type...");

        test_j_type(7'b1101111, 21'h000000);

        test_j_type(7'b1101111, 21'h000002);

        test_j_type(7'b1101111, 21'h000100);

        test_j_type(7'b1101111, 21'h0FFFFE);

        test_j_type(7'b1101111, 21'h100000);

        test_j_type(7'b1101111, 21'h1FFFFE);

        // ========================================================
        // U-TYPE LUI
        // ========================================================

        $display("Testing U-type LUI...");

        test_u_type(7'b0110111, 20'h00000);

        test_u_type(7'b0110111, 20'h00001);

        test_u_type(7'b0110111, 20'h7FFFF);

        test_u_type(7'b0110111, 20'h80000);

        test_u_type(7'b0110111, 20'hFFFFF);

        // ========================================================
        // U-TYPE AUIPC
        // ========================================================

        $display("Testing U-type AUIPC...");

        test_u_type(7'b0010111, 20'h00000);

        test_u_type(7'b0010111, 20'h00001);

        test_u_type(7'b0010111, 20'h7FFFF);

        test_u_type(7'b0010111, 20'h80000);

        test_u_type(7'b0010111, 20'hFFFFF);

        // ========================================================
        // INVALID OPCODES
        // ========================================================

        $display("Testing invalid opcodes...");

        check_instruction(32'h00000000);

        check_instruction(32'hFFFFFFFF);

        check_instruction(32'h0000007F);

        check_instruction(32'h00000013);

        check_instruction(32'h00000023);

        check_instruction(32'h00000063);

        check_instruction(32'h0000006F);

        check_instruction(32'h00000037);

        // ========================================================
        // RANDOM I-TYPE TESTS
        // ========================================================

        $display("Running random I-type tests...");

        for (i = 0; i < 250; i = i + 1) begin

            test_i_type(
                7'b0000011,
                $urandom
            );

            test_i_type(
                7'b0010011,
                $urandom
            );

            test_i_type(
                7'b1100111,
                $urandom
            );

        end

        // ========================================================
        // RANDOM S-TYPE TESTS
        // ========================================================

        $display("Running random S-type tests...");

        for (i = 0; i < 250; i = i + 1) begin

            test_s_type(
                7'b0100011,
                $urandom
            );

        end

        // ========================================================
        // RANDOM B-TYPE TESTS
        // ========================================================

        $display("Running random B-type tests...");

        for (i = 0; i < 250; i = i + 1) begin

            test_b_type(
                7'b1100011,
                $urandom
            );

        end

        // ========================================================
        // RANDOM J-TYPE TESTS
        // ========================================================

        $display("Running random J-type tests...");

        for (i = 0; i < 250; i = i + 1) begin

            test_j_type(
                7'b1101111,
                $urandom
            );

        end

        // ========================================================
        // RANDOM U-TYPE TESTS
        // ========================================================

        $display("Running random U-type tests...");

        for (i = 0; i < 250; i = i + 1) begin

            test_u_type(
                7'b0110111,
                $urandom
            );

            test_u_type(
                7'b0010111,
                $urandom
            );

        end

        // ========================================================
        // FINAL REPORT
        // ========================================================

        $display("");
        $display("================================================");
        $display(" SIGN EXTEND VERIFICATION REPORT");
        $display("================================================");

        $display(
            "Total Tests        = %0d",
            test_count
        );

        $display(
            "Passed             = %0d",
            pass_count
        );

        $display(
            "Failed             = %0d",
            fail_count
        );

        $display(
            "Assertion Failures = %0d",
            assertion_failures
        );

        $display(
            "Functional Coverage = %0.2f%%",
            cov.get_coverage()
        );

        $display("================================================");
        $display("");

        if (
            (fail_count == 0) &&
            (assertion_failures == 0)
        ) begin

            $display(
                "******** SIGN EXTEND VERIFICATION PASSED ********"
            );

        end
        else begin

            $display(
                "******** SIGN EXTEND VERIFICATION FAILED ********"
            );

        end

        $display("");

        $finish;

    end

endmodule