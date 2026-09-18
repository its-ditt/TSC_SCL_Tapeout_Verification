// ============================================================
// TB #1 - Simple PASS / FAIL Checks
// ============================================================
//
// No scoreboard
// No assertions
// No coverage
// No randomization
// No hazard checking
// ============================================================

integer pass_count = 0;
integer fail_count = 0;

// ------------------------------------------------------------
// Generic 32-bit check
// ------------------------------------------------------------

task automatic check_value(
    input string       test_name,
    input logic [31:0] actual,
    input logic [31:0] expected
);
    begin
        if (actual === expected) begin
            pass_count++;
            $display("[PASS] %-24s ACTUAL=%08h EXPECTED=%08h",
                     test_name, actual, expected);
        end
        else begin
            fail_count++;
            $display("[FAIL] %-24s ACTUAL=%08h EXPECTED=%08h",
                     test_name, actual, expected);
        end
    end
endtask

// ------------------------------------------------------------
// Register check
// ------------------------------------------------------------

task automatic check_register(
    input string       test_name,
    input int          reg_num,
    input logic [31:0] actual,
    input logic [31:0] expected
);
    begin
        check_value(
            $sformatf("%s (x%0d)", test_name, reg_num),
            actual,
            expected
        );
    end
endtask

// ------------------------------------------------------------
// Word memory check
// ------------------------------------------------------------

task automatic check_memory_word(
    input string       test_name,
    input logic [31:0] byte_address,
    input logic [31:0] expected
);
    logic [31:0] actual;

    begin
        if ((byte_address[1:0] == 2'b00) &&
            (byte_address[31:2] < DMEM_WORDS)) begin

            actual = data_memory[byte_address[31:2]];

            check_value(
                $sformatf("%s @ %08h", test_name, byte_address),
                actual,
                expected
            );

        end
        else begin
            fail_count++;
            $display("[FAIL] %-24s INVALID ADDRESS=%08h",
                     test_name, byte_address);
        end
    end
endtask

// ------------------------------------------------------------
// Halfword memory check
//
// byte_address[1] selects low/high halfword.
// ------------------------------------------------------------

task automatic check_memory_half(
    input string       test_name,
    input logic [31:0] byte_address,
    input logic [15:0] expected
);
    logic [15:0] actual;
    logic [31:0] word;

    begin
        if (byte_address[31:2] < DMEM_WORDS) begin

            word = data_memory[byte_address[31:2]];

            if (byte_address[1] == 1'b0)
                actual = word[15:0];
            else
                actual = word[31:16];

            check_value(
                $sformatf("%s @ %08h", test_name, byte_address),
                {16'h0000, actual},
                {16'h0000, expected}
            );

        end
        else begin
            fail_count++;
            $display("[FAIL] %-24s INVALID ADDRESS=%08h",
                     test_name, byte_address);
        end
    end
endtask

// ------------------------------------------------------------
// Byte memory check
// ------------------------------------------------------------

task automatic check_memory_byte(
    input string       test_name,
    input logic [31:0] byte_address,
    input logic [7:0]  expected
);
    logic [7:0] actual;
    logic [31:0] word;

    begin
        if (byte_address[31:2] < DMEM_WORDS) begin

            word = data_memory[byte_address[31:2]];

            case (byte_address[1:0])
                2'b00: actual = word[7:0];
                2'b01: actual = word[15:8];
                2'b10: actual = word[23:16];
                2'b11: actual = word[31:24];
            endcase

            check_value(
                $sformatf("%s @ %08h", test_name, byte_address),
                {24'h000000, actual},
                {24'h000000, expected}
            );

        end
        else begin
            fail_count++;
            $display("[FAIL] %-24s INVALID ADDRESS=%08h",
                     test_name, byte_address);
        end
    end
endtask

// ------------------------------------------------------------
// Final summary
// ------------------------------------------------------------

task automatic print_test_summary();
    begin
        $display("");
        $display("============================================================");
        $display("RV32I ISA DIRECTED TEST SUMMARY");
        $display("============================================================");
        $display("Tests Passed : %0d", pass_count);
        $display("Tests Failed : %0d", fail_count);
        $display("Total Checks : %0d", pass_count + fail_count);

        if (fail_count == 0)
            $display("TEST RESULT  : PASS");
        else
            $display("TEST RESULT  : FAIL");

        $display("============================================================");
    end
endtask