`timescale 1ns / 1ps

module tb_pipeline_top;

    // ============================================================
    // 1. Configuration
    // ============================================================

    localparam int IMEM_WORDS = 1024;
    localparam int DMEM_WORDS = 1024;
    localparam int RUN_CYCLES = 1500;

    // ============================================================
    // 2. Clock / reset
    // ============================================================

    logic clk;
    logic rst_n;

    initial begin
        clk = 1'b0;
    end

    always #5 clk = ~clk;

    // ============================================================
    // 3. Processor interfaces
    // ============================================================

    // Instruction memory
    logic [31:0] INSTR_ADD;
    logic [31:0] INSTR;

    // Data memory
    logic        MEM_WRITE;
    logic        MEM_READ;
    logic        MEM_READY;
    logic [31:0] MEM_ADDR;
    logic [31:0] MEM_WDATA;
    logic [3:0]  MEM_WSTRB;
    logic [31:0] MEM_RDATA;

    // Debug output
    logic [31:0] debug_out;

    // ============================================================
    // 4. Test program configuration
    // ============================================================

    `include "tb_test_program.svh"

    // ============================================================
    // 5. TB memories
    // ============================================================

    logic [31:0] instruction_memory [0:IMEM_WORDS-1];
    logic [31:0] data_memory [0:DMEM_WORDS-1];



    // ============================================================
    // 6. TB support files
    // ============================================================

    // Program loader
    `include "tb_loader.svh"

    // External instruction-memory model
    `include "tb_instr_mem.svh"

    // External data-memory model
    // This file declares data_memory[] and DMEM_WORDS.
    `include "tb_datamem.svh"

    // PASS / FAIL tasks
    `include "tb_checks.svh"

    // ============================================================
    // 7. DUT
    // ============================================================

    pipeline_top dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .debug_out (debug_out),

        .MEM_WRITE (MEM_WRITE),
        .MEM_READ  (MEM_READ),
        .MEM_READY (MEM_READY),
        .MEM_ADDR  (MEM_ADDR),
        .MEM_WDATA  (MEM_WDATA),
        .MEM_WSTRB (MEM_WSTRB),
        .MEM_RDATA (MEM_RDATA),

        .INSTR_ADD (INSTR_ADD),
        .INSTR     (INSTR)
    );

    // ============================================================
    // 8. Reset
    // ============================================================

    task automatic reset_dut();
        begin
            rst_n = 1'b0;

            repeat (5)
                @(posedge clk);

            #1;
            rst_n = 1'b1;

            repeat (2)
                @(posedge clk);
        end
    endtask

    // ============================================================
    // 9. Run program
    // ============================================================

    task automatic run_program();
        begin
            $display("");
            $display("============================================================");
            $display("RV32I ISA DIRECTED TEST");
            $display("Program : %s", PROGRAM_FILE);
            $display("============================================================");

            repeat (RUN_CYCLES)
                @(posedge clk);

            #1;

            $display("Program execution complete.");
        end
    endtask

    // ============================================================
    // 10. ISA result checks
    // ============================================================

    task automatic check_isa_results();

        begin
            $display("");
            $display("============================================================");
            $display("Checking instruction results");
            $display("============================================================");

            // ----------------------------------------------------
            // R-type ALU
            // ----------------------------------------------------

            check_memory_word("ADD",  ADDR_ADD,  EXP_ADD);
            check_memory_word("SUB",  ADDR_SUB,  EXP_SUB);
            check_memory_word("SLL",  ADDR_SLL,  EXP_SLL);
            check_memory_word("SLT",  ADDR_SLT,  EXP_SLT);
            check_memory_word("SLTU", ADDR_SLTU, EXP_SLTU);
            check_memory_word("XOR",  ADDR_XOR,  EXP_XOR);
            check_memory_word("SRL",  ADDR_SRL,  EXP_SRL);
            check_memory_word("SRA",  ADDR_SRA,  EXP_SRA);
            check_memory_word("OR",   ADDR_OR,   EXP_OR);
            check_memory_word("AND",  ADDR_AND,  EXP_AND);

            // ----------------------------------------------------
            // I-type ALU
            // ----------------------------------------------------

            check_memory_word("ADDI",  ADDR_ADDI,  EXP_ADDI);
            check_memory_word("SLTI",  ADDR_SLTI,  EXP_SLTI);
            check_memory_word("SLTIU", ADDR_SLTIU, EXP_SLTIU);
            check_memory_word("XORI",  ADDR_XORI,  EXP_XORI);
            check_memory_word("ORI",   ADDR_ORI,   EXP_ORI);
            check_memory_word("ANDI",  ADDR_ANDI,  EXP_ANDI);
            check_memory_word("SLLI",  ADDR_SLLI,  EXP_SLLI);
            check_memory_word("SRLI",  ADDR_SRLI,  EXP_SRLI);
            check_memory_word("SRAI",  ADDR_SRAI,  EXP_SRAI);

            // ----------------------------------------------------
            // Upper-immediate
            // ----------------------------------------------------

            check_memory_word("LUI",   ADDR_LUI,   EXP_LUI);
            check_memory_word("AUIPC", ADDR_AUIPC, EXP_AUIPC);

            // ----------------------------------------------------
            // Store instructions
            // ----------------------------------------------------

            check_memory_word(
                "SW",
                ADDR_DATA_SW,
                EXP_DATA_0100
            );

            check_memory_word(
                "SH/SB",
                ADDR_DATA_SH,
                EXP_DATA_0104
            );

            check_memory_word(
                "SW for loads",
                ADDR_DATA_LH,
                EXP_DATA_0108
            );

            // ----------------------------------------------------
            // Load instructions
            //
            // The program stores each loaded value into result
            // memory immediately after the load.
            // ----------------------------------------------------

            check_memory_word("LW",  ADDR_LW,  EXP_LW);
            check_memory_word("LH",  ADDR_LH,  EXP_LH);
            check_memory_word("LHU", ADDR_LHU, EXP_LHU);
            check_memory_word("LB",  ADDR_LB,  EXP_LB);
            check_memory_word("LBU", ADDR_LBU, EXP_LBU);

            // ----------------------------------------------------
            // Branch instructions
            // ----------------------------------------------------

            check_memory_word("BEQ",  ADDR_BEQ,  EXP_BEQ);
            check_memory_word("BNE",  ADDR_BNE,  EXP_BNE);
            check_memory_word("BLT",  ADDR_BLT,  EXP_BLT);
            check_memory_word("BGE",  ADDR_BGE,  EXP_BGE);
            check_memory_word("BLTU", ADDR_BLTU, EXP_BLTU);
            check_memory_word("BGEU", ADDR_BGEU, EXP_BGEU);

            // ----------------------------------------------------
            // JAL
            // ----------------------------------------------------

            check_memory_word(
                "JAL link",
                ADDR_JAL_LINK,
                EXP_JAL_LINK
            );

            check_memory_word(
                "JAL wrong-path",
                ADDR_JAL_FAIL,
                EXP_JAL_FAIL
            );

            check_memory_word(
                "JAL target",
                ADDR_JAL_PASS,
                EXP_JAL_PASS
            );

            // ----------------------------------------------------
            // JALR
            // ----------------------------------------------------

            check_memory_word(
                "JALR link",
                ADDR_JALR_LINK,
                EXP_JALR_LINK
            );

            check_memory_word(
                "JALR wrong-path",
                ADDR_JALR_FAIL,
                EXP_JALR_FAIL
            );

            check_memory_word(
                "JALR target",
                ADDR_JALR_PASS,
                EXP_JALR_PASS
            );

        end

    endtask

    // ============================================================
    // 11. Main test
    // ============================================================

    initial begin

        rst_n = 1'b0;

        // Load instruction program into TB instruction memory.
        load_program(PROGRAM_FILE);

        // Initialize processor-side TB data memory.
        init_data_memory();

        // Reset DUT.
        reset_dut();

        // Execute the complete directed program.
        run_program();

        // Check architectural effects.
        check_isa_results();

        // Print final result.
        print_test_summary();

        if (fail_count == 0)
            $display("******** RV32I ISA TEST PASSED ********");
        else
            $display("******** RV32I ISA TEST FAILED ********");

        $finish;

    end

endmodule