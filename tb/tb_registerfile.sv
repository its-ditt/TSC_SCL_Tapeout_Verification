`timescale 1ns / 1ps

module tb_RegFile;

    // ============================================================
    // DUT INPUTS
    // ============================================================

    logic        clk;
    logic        rst;

    logic        WE3;
    logic [4:0]  A1;
    logic [4:0]  A2;
    logic [4:0]  A3;

    logic [31:0] WD3;

    // ============================================================
    // DUT OUTPUTS
    // ============================================================

    logic [31:0] RD1;
    logic [31:0] RD2;

    // ============================================================
    // REFERENCE MODEL
    // ============================================================

    logic [31:0] model [0:31];

    integer i;
    integer pass_count;
    integer fail_count;

    // ============================================================
    // DUT
    // ============================================================

    registerfile dut (
        .clk(clk),
        .rst(rst),

        .WE3(WE3),

        .A1(A1),
        .A2(A2),
        .A3(A3),

        .WD3(WD3),

        .RD1(RD1),
        .RD2(RD2)
    );

    // ============================================================
    // CLOCK
    // ============================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end

    // ============================================================
    // MODEL RESET
    // ============================================================

    task reset_model;

        begin

            for (i = 0; i < 32; i = i + 1)
                model[i] = 32'b0;

        end

    endtask

    // ============================================================
    // APPLY RESET
    // ============================================================

    task apply_reset;

        begin

            rst = 1'b0;

            #2;

            reset_model;

            #3;

            rst = 1'b1;

            #1;

        end

    endtask

    // ============================================================
    // CHECK READ PORTS
    // ============================================================

    task check_reads;

        input [4:0] addr1;
        input [4:0] addr2;

        reg [31:0] expected1;
        reg [31:0] expected2;

        begin

            A1 = addr1;
            A2 = addr2;

            #1;

            expected1 = model[addr1];
            expected2 = model[addr2];

            if (addr1 == 5'd0)
                expected1 = 32'b0;

            if (addr2 == 5'd0)
                expected2 = 32'b0;

            if (RD1 !== expected1) begin

                $error(
                    "FAIL RD1 | A1=%0d | Expected=%h | Got=%h",
                    addr1,
                    expected1,
                    RD1
                );

                fail_count = fail_count + 1;

            end
            else begin

                $display(
                    "PASS RD1 | A1=%0d | Data=%h",
                    addr1,
                    RD1
                );

                pass_count = pass_count + 1;

            end

            if (RD2 !== expected2) begin

                $error(
                    "FAIL RD2 | A2=%0d | Expected=%h | Got=%h",
                    addr2,
                    expected2,
                    RD2
                );

                fail_count = fail_count + 1;

            end
            else begin

                $display(
                    "PASS RD2 | A2=%0d | Data=%h",
                    addr2,
                    RD2
                );

                pass_count = pass_count + 1;

            end

        end

    endtask

    // ============================================================
    // WRITE REGISTER
    // ============================================================

    task write_register;

        input [4:0] addr;
        input [31:0] data;

        begin

            @(negedge clk);

            A3 = addr;
            WD3 = data;
            WE3 = 1'b1;

            @(posedge clk);

            #1;

            WE3 = 1'b0;

            if (addr != 5'd0)
                model[addr] = data;

            $display(
                "WRITE | x%0d <= %h",
                addr,
                data
            );

        end

    endtask

    // ============================================================
    // INITIALIZATION
    // ============================================================

    initial begin

        rst = 1'b1;

        WE3 = 1'b0;

        A1 = 5'd0;
        A2 = 5'd0;
        A3 = 5'd0;

        WD3 = 32'b0;

        pass_count = 0;
        fail_count = 0;

        reset_model;

        $display("");
        $display("==============================================");
        $display("       REGISTER FILE FUNCTIONAL TEST");
        $display("==============================================");
        $display("");

        // ========================================================
        // RESET
        // ========================================================

        apply_reset;

        // Check x0 immediately after reset

        check_reads(5'd0, 5'd0);


        // ========================================================
        // BASIC WRITE / READ
        // ========================================================

        write_register(5'd1, 32'h12345678);

        check_reads(5'd1, 5'd0);


        write_register(5'd2, 32'hAAAAAAAA);

        check_reads(5'd1, 5'd2);


        // ========================================================
        // WRITE DIFFERENT REGISTERS
        // ========================================================

        write_register(5'd5, 32'h55555555);
        write_register(5'd10, 32'hAAAAAAAA);
        write_register(5'd15, 32'hFFFFFFFF);
        write_register(5'd31, 32'h80000000);

        check_reads(5'd5, 5'd10);
        check_reads(5'd15, 5'd31);


        // ========================================================
        // WRITE X0
        // ========================================================

        write_register(5'd0, 32'hDEADBEEF);

        check_reads(5'd0, 5'd1);


        // ========================================================
        // READ SAME REGISTER THROUGH BOTH PORTS
        // ========================================================

        check_reads(5'd5, 5'd5);


        // ========================================================
        // DATA RETENTION
        // ========================================================

        check_reads(5'd1, 5'd2);
        check_reads(5'd5, 5'd10);
        check_reads(5'd15, 5'd31);


        // ========================================================
        // REPEATED WRITE
        // ========================================================

        write_register(5'd7, 32'h11111111);
        check_reads(5'd7, 5'd7);

        write_register(5'd7, 32'h22222222);
        check_reads(5'd7, 5'd7);

        write_register(5'd7, 32'hFFFFFFFF);
        check_reads(5'd7, 5'd7);


        // ========================================================
        // SAME-CYCLE WRITE / READ FORWARDING
        // ========================================================

        @(negedge clk);

        A3 = 5'd12;
        WD3 = 32'hCAFEBABE;
        WE3 = 1'b1;

        A1 = 5'd12;
        A2 = 5'd12;

        #1;

        if (RD1 !== 32'hCAFEBABE) begin

            $error(
                "FAIL FORWARD RD1 | Expected=%h | Got=%h",
                32'hCAFEBABE,
                RD1
            );

            fail_count = fail_count + 1;

        end
        else begin

            $display(
                "PASS FORWARD RD1 | Data=%h",
                RD1
            );

            pass_count = pass_count + 1;

        end

        if (RD2 !== 32'hCAFEBABE) begin

            $error(
                "FAIL FORWARD RD2 | Expected=%h | Got=%h",
                32'hCAFEBABE,
                RD2
            );

            fail_count = fail_count + 1;

        end
        else begin

            $display(
                "PASS FORWARD RD2 | Data=%h",
                RD2
            );

            pass_count = pass_count + 1;

        end

        @(posedge clk);

        #1;

        WE3 = 1'b0;

        model[12] = 32'hCAFEBABE;


        // ========================================================
        // WRITE ALL REGISTERS
        // ========================================================

        for (i = 1; i < 32; i = i + 1) begin

            write_register(
                i[4:0],
                32'h10000000 + i
            );

        end


        // ========================================================
        // READ ALL REGISTERS
        // ========================================================

        for (i = 0; i < 32; i = i + 1) begin

            A1 = i[4:0];

            #1;

            if (i == 0) begin

                if (RD1 !== 32'b0) begin

                    $error(
                        "FAIL x0 | Expected=00000000 | Got=%h",
                        RD1
                    );

                    fail_count = fail_count + 1;

                end
                else begin

                    $display(
                        "PASS x0 | Data=%h",
                        RD1
                    );

                    pass_count = pass_count + 1;

                end

            end
            else begin

                if (RD1 !== model[i]) begin

                    $error(
                        "FAIL x%0d | Expected=%h | Got=%h",
                        i,
                        model[i],
                        RD1
                    );

                    fail_count = fail_count + 1;

                end
                else begin

                    $display(
                        "PASS x%0d | Data=%h",
                        i,
                        RD1
                    );

                    pass_count = pass_count + 1;

                end

            end

        end


        // ========================================================
        // FINAL CHECK OF X0
        // ========================================================

        A1 = 5'd0;
        A2 = 5'd0;

        #1;

        if ((RD1 !== 32'b0) || (RD2 !== 32'b0)) begin

            $error(
                "FAIL X0 FINAL | RD1=%h RD2=%h",
                RD1,
                RD2
            );

            fail_count = fail_count + 1;

        end
        else begin

            $display(
                "PASS X0 FINAL | RD1=%h RD2=%h",
                RD1,
                RD2
            );

            pass_count = pass_count + 1;

        end


        // ========================================================
        // SUMMARY
        // ========================================================

        $display("");
        $display("==============================================");
        $display("       REGISTER FILE VERIFICATION COMPLETE");
        $display("==============================================");

        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);

        $display("==============================================");
        $display("");

        if (fail_count == 0)
            $display("******** REGISTER FILE PASSED ********");
        else
            $display("******** REGISTER FILE FAILED ********");

        $display("");

        $finish;

    end

endmodule