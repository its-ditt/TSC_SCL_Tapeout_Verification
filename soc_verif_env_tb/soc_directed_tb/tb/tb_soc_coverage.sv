`timescale 1ns/1ps

module tb_soc_coverage;

    localparam int CLK_PERIOD    = 10;
    localparam int PROGRAM_WORDS = 190;
    localparam int RUN_CYCLES   = 6000;

    logic clk;
    logic rst_n;
    logic load_mode;
    logic [7:0] data_in;
    logic byte_strobe;
    logic [31:0] debug_out;

    logic [31:0] program_words [0:PROGRAM_WORDS-1];

    `include "program_image.svh"

    logic [31:0] cov_instr;
    logic [6:0]  cov_opcode;
    logic [2:0]  cov_funct3;
    logic [6:0]  cov_funct7;
    logic [3:0]  cov_wstrb;
    logic        cov_mem_read;
    logic        cov_mem_write;

    integer loader_byte_count;
    integer imem_errors;
    integer instr_sample_count;
    integer non_nop_instr_count;
    integer axi_read_count;
    integer axi_write_count;
    integer cov_debug_count;

    // ------------------------------------------------------------
    // Functional coverage
    // ------------------------------------------------------------
    covergroup soc_functional_cg;

        cp_opcode : coverpoint cov_opcode iff (
            rst_n && !load_mode &&
            cov_instr != 32'h00000013 &&
            !$isunknown(cov_instr)
        ) {
            bins R_TYPE = {7'b0110011};
            bins I_ALU  = {7'b0010011};
            bins LOAD   = {7'b0000011};
            bins STORE  = {7'b0100011};
            bins BRANCH = {7'b1100011};
            bins JAL    = {7'b1101111};
            bins JALR   = {7'b1100111};
            bins LUI    = {7'b0110111};
            bins AUIPC  = {7'b0010111};
        }

        cp_funct3 : coverpoint cov_funct3 iff (
            rst_n && !load_mode &&
            cov_instr != 32'h00000013 &&
            !$isunknown(cov_instr)
        ) {
            bins f3_000 = {3'b000};
            bins f3_001 = {3'b001};
            bins f3_010 = {3'b010};
            bins f3_011 = {3'b011};
            bins f3_100 = {3'b100};
            bins f3_101 = {3'b101};
            bins f3_110 = {3'b110};
            bins f3_111 = {3'b111};
        }

        cp_r_funct7 : coverpoint cov_funct7 iff (
            rst_n && !load_mode &&
            cov_opcode == 7'b0110011 &&
            !$isunknown(cov_instr)
        ) {
            bins normal  = {7'b0000000};
            bins sub_sra = {7'b0100000};
        }

        cp_load_type : coverpoint cov_funct3 iff (
            rst_n && !load_mode &&
            cov_opcode == 7'b0000011 &&
            !$isunknown(cov_instr)
        ) {
            bins LB  = {3'b000};
            bins LH  = {3'b001};
            bins LW  = {3'b010};
            bins LBU = {3'b100};
            bins LHU = {3'b101};
        }

        cp_store_type : coverpoint cov_funct3 iff (
            rst_n && !load_mode &&
            cov_opcode == 7'b0100011 &&
            !$isunknown(cov_instr)
        ) {
            bins SB = {3'b000};
            bins SH = {3'b001};
            bins SW = {3'b010};
        }

        cp_branch_type : coverpoint cov_funct3 iff (
            rst_n && !load_mode &&
            cov_opcode == 7'b1100011 &&
            !$isunknown(cov_instr)
        ) {
            bins BEQ  = {3'b000};
            bins BNE  = {3'b001};
            bins BLT  = {3'b100};
            bins BGE  = {3'b101};
            bins BLTU = {3'b110};
            bins BGEU = {3'b111};
        }

        cp_wstrb : coverpoint cov_wstrb iff (
            rst_n && !load_mode &&
            cov_mem_write &&
            !$isunknown(cov_wstrb)
        ) {
            bins byte0   = {4'b0001};
            bins byte1   = {4'b0010};
            bins byte2   = {4'b0100};
            bins byte3   = {4'b1000};
            bins half_lo = {4'b0011};
            bins half_hi = {4'b1100};
            bins word    = {4'b1111};
        }

        cp_mem_activity : coverpoint {cov_mem_read, cov_mem_write}
            iff (rst_n && !load_mode) {
            bins idle  = {2'b00};
            bins read  = {2'b10};
            bins write = {2'b01};
        }

        cx_opcode_funct3 : cross cp_opcode, cp_funct3;

    endgroup

    soc_functional_cg cov = new();

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------
    soc_top dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .load_mode   (load_mode),
        .data_in     (data_in),
        .byte_strobe (byte_strobe),
        .debug_out   (debug_out)
    );

    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ------------------------------------------------------------
    // Load through the real SoC loader.
    //
    // IMPORTANT:
    // ext rst_n must be HIGH during loading.
    // byte_loader uses ext_rst_n as its own reset.
    // The CPU remains in reset because core_rst_n =
    // ext_rst_n & ~load_mode.
    // ------------------------------------------------------------
    task automatic load_program();
        int i, b;
        logic [7:0] byte_value;

        begin
            rst_n       = 1'b0;
            load_mode   = 1'b0;
            data_in     = 8'h00;
            byte_strobe = 1'b0;

            repeat (3) @(posedge clk);

            // Release byte_loader reset, but keep CPU reset active.
            rst_n     = 1'b1;
            load_mode = 1'b1;

            repeat (2) @(posedge clk);

            for (i = 0; i < PROGRAM_WORDS; i++) begin
                for (b = 0; b < 4; b++) begin

                    byte_value = program_words[i][8*b +: 8];

                    data_in     = byte_value;
                    byte_strobe = 1'b1;

                    @(posedge clk);

                    byte_strobe = 1'b0;
                    loader_byte_count++;

                    @(posedge clk);
                end
            end

            data_in = 8'h00;

            // Give final instruction write time to land in SRAM.
            repeat (3) @(posedge clk);

            // Verify the actual DUT instruction SRAM before execution.
            imem_errors = 0;

            for (i = 0; i < PROGRAM_WORDS; i++) begin
                if (dut.Imem.mem[i][31:0] !== program_words[i]) begin
                    if (imem_errors < 10) begin
                        $display("IMEM ERROR word=%0d expected=%08h actual=%08h",
                                 i, program_words[i], dut.Imem.mem[i][31:0]);
                    end
                    imem_errors++;
                end
            end

            $display("IMEM word0 : expected=%08h actual=%08h",
                     program_words[0], dut.Imem.mem[0][31:0]);
            $display("IMEM word1 : expected=%08h actual=%08h",
                     program_words[1], dut.Imem.mem[1][31:0]);

            if (imem_errors != 0) begin
                $display("IMEM verification: FAIL (%0d errors)", imem_errors);
                $finish;
            end
            else begin
                $display("IMEM verification: PASS (%0d words)", PROGRAM_WORDS);
            end

            // Release the processor from core reset.
            load_mode = 1'b0;

            repeat (5) @(posedge clk);
        end
    endtask

    // ------------------------------------------------------------
    // Sample after the positive-edge pipeline activity.
    // ------------------------------------------------------------
    always @(negedge clk) begin
        if (rst_n && !load_mode) begin

            cov_instr     = dut.cpu.InstrD;
            cov_opcode    = cov_instr[6:0];
            cov_funct3    = cov_instr[14:12];
            cov_funct7    = cov_instr[31:25];
            cov_mem_read  = dut.MEM_READ;
            cov_mem_write = dut.MEM_WRITE;
            cov_wstrb     = dut.MEM_WSTRB;

            instr_sample_count++;

            if (!$isunknown(cov_instr) && cov_instr != 32'h00000013) begin
                non_nop_instr_count++;

                if (cov_debug_count < 30) begin
                    $display("COV OBS %0d: PC=%08h INSTR=%08h OPCODE=%02h F3=%0h F7=%02h",
                             cov_debug_count,
                             dut.cpu.InstrD === cov_instr ? dut.cpu.PcD : dut.cpu.PcD,
                             cov_instr,
                             cov_opcode,
                             cov_funct3,
                             cov_funct7);
                    cov_debug_count++;
                end
            end

            if (dut.MEM_READ)
                axi_read_count++;

            if (dut.MEM_WRITE)
                axi_write_count++;

            cov.sample();
        end
    end

    // ------------------------------------------------------------
    // Run
    // ------------------------------------------------------------
    initial begin

        loader_byte_count   = 0;
        imem_errors         = 0;
        instr_sample_count  = 0;
        non_nop_instr_count = 0;
        axi_read_count      = 0;
        axi_write_count     = 0;
        cov_debug_count     = 0;

        cov_instr     = 32'h00000013;
        cov_opcode    = 7'b0;
        cov_funct3    = 3'b0;
        cov_funct7    = 7'b0;
        cov_wstrb     = 4'b0;
        cov_mem_read  = 1'b0;
        cov_mem_write = 1'b0;

        load_program();

        $display("");
        $display("============================================================");
        $display("SOC FUNCTIONAL COVERAGE RUN");
        $display("============================================================");

        repeat (RUN_CYCLES) @(posedge clk);
        #1;

        $display("");
        $display("============================================================");
        $display("SOC FUNCTIONAL COVERAGE SUMMARY");
        $display("============================================================");
        $display("Overall functional coverage : %0.2f%%",
                 cov.get_coverage());
        $display("Opcode coverage             : %0.2f%%",
                 cov.cp_opcode.get_coverage());
        $display("funct3 coverage             : %0.2f%%",
                 cov.cp_funct3.get_coverage());
        $display("R-type funct7 coverage      : %0.2f%%",
                 cov.cp_r_funct7.get_coverage());
        $display("Load type coverage          : %0.2f%%",
                 cov.cp_load_type.get_coverage());
        $display("Store type coverage         : %0.2f%%",
                 cov.cp_store_type.get_coverage());
        $display("Branch type coverage        : %0.2f%%",
                 cov.cp_branch_type.get_coverage());
        $display("WSTRB coverage              : %0.2f%%",
                 cov.cp_wstrb.get_coverage());
        $display("Memory activity coverage    : %0.2f%%",
                 cov.cp_mem_activity.get_coverage());
        $display("Opcode x funct3 coverage    : %0.2f%%",
                 cov.cx_opcode_funct3.get_coverage());
        $display("Decode observations         : %0d",
                 instr_sample_count);
        $display("Non-NOP instructions        : %0d",
                 non_nop_instr_count);
        $display("Memory read requests        : %0d",
                 axi_read_count);
        $display("Memory write requests       : %0d",
                 axi_write_count);
        $display("Loader bytes driven         : %0d",
                 loader_byte_count);
        $display("============================================================");

        $finish;
    end

endmodule
