`timescale 1ns / 1ps

module tb_pipeline_top;

    // ============================================================
    // SECTION 1
    // PARAMETERS / CONSTANTS
    // ============================================================

    parameter integer CLK_PERIOD = 10;


    // ============================================================
    // SECTION 2
    // DUT SIGNAL DECLARATIONS
    // ============================================================

    // ------------------------------------------------------------
    // Clock / Reset
    // ------------------------------------------------------------

    logic clk;
    logic rst_n;


    // ------------------------------------------------------------
    // Debug
    // ------------------------------------------------------------

    logic [31:0] debug_out;


    // ------------------------------------------------------------
    // Data Memory Interface
    // ------------------------------------------------------------

    logic        MEM_WRITE;
    logic        MEM_READ;
    logic        MEM_READY;

    logic [31:0] MEM_ADDR;
    logic [31:0] MEM_WDATA;
    logic [3:0]  MEM_WSTRB;

    logic [31:0] MEM_RDATA;


    // ------------------------------------------------------------
    // Instruction Memory Interface
    // ------------------------------------------------------------

    logic [31:0] INSTR_ADD;
    logic [31:0] INSTR;


    // ============================================================
    // SECTION 3
    // TESTBENCH INTERNAL VARIABLES
    // ============================================================

    integer test_count;
    integer pass_count;
    integer fail_count;
    integer assertion_failures;

    integer i;


    // ============================================================
    // SECTION 4
    // DUT INSTANTIATION
    // ============================================================

    pipeline_top dut (

        // Clock / Reset
        .clk        (clk),
        .rst_n      (rst_n),

        // Debug
        .debug_out  (debug_out),

        // Data Memory Interface
        .MEM_WRITE  (MEM_WRITE),
        .MEM_READ   (MEM_READ),
        .MEM_READY  (MEM_READY),
        .MEM_ADDR   (MEM_ADDR),
        .MEM_WDATA  (MEM_WDATA),
        .MEM_WSTRB  (MEM_WSTRB),
        .MEM_RDATA  (MEM_RDATA),

        // Instruction Memory Interface
        .INSTR_ADD  (INSTR_ADD),
        .INSTR      (INSTR)

    );


    // ============================================================
    // SECTION 5
    // CLOCK GENERATION
    // ============================================================

    initial begin

        clk = 1'b0;

        forever begin

            #(CLK_PERIOD / 2);
            clk = ~clk;

        end

    end

    // ============================================================
    // SECTION 6
    // FUNCTIONAL COVERAGE
    // ============================================================

    // ------------------------------------------------------------
    // Coverage sampling variables
    // ------------------------------------------------------------

    logic [6:0] cov_opcode;
    logic [2:0] cov_funct3;
    logic [6:0] cov_funct7;

    logic       cov_mem_read;
    logic       cov_mem_write;

    logic       cov_branch_taken;
    logic       cov_branch_not_taken;

    logic       cov_hazard_event;

    integer     cov_mem_latency;


    // ------------------------------------------------------------
    // Processor Functional Coverage
    // ------------------------------------------------------------

    covergroup processor_coverage;

        // ========================================================
        // Instruction Opcode Coverage
        // ========================================================

        cp_opcode : coverpoint cov_opcode {

            bins R_TYPE      = {7'b0110011};

            bins I_TYPE_ALU  = {7'b0010011};

            bins LOAD        = {7'b0000011};

            bins STORE       = {7'b0100011};

            bins BRANCH      = {7'b1100011};

            bins JAL         = {7'b1101111};

            bins JALR        = {7'b1100111};

            bins LUI         = {7'b0110111};

            bins AUIPC       = {7'b0010111};

        }


        // ========================================================
        // funct3 Coverage
        // ========================================================

        cp_funct3 : coverpoint cov_funct3 {

            bins values[] = {[0:7]};

        }


        // ========================================================
        // Memory Read / Write Coverage
        // ========================================================

        cp_mem_read : coverpoint cov_mem_read {

            bins no_read = {0};
            bins read    = {1};

        }


        cp_mem_write : coverpoint cov_mem_write {

            bins no_write = {0};
            bins write    = {1};

        }


        // ========================================================
        // Branch Outcome Coverage
        // ========================================================

        cp_branch_taken : coverpoint cov_branch_taken {

            bins not_taken = {0};
            bins taken     = {1};

        }


        cp_branch_not_taken : coverpoint cov_branch_not_taken {

            bins not_taken = {0};
            bins taken     = {1};

        }


        // ========================================================
        // Hazard Coverage
        // ========================================================

        cp_hazard : coverpoint cov_hazard_event {

            bins no_hazard = {0};
            bins hazard    = {1};

        }


        // ========================================================
        // Memory Latency Coverage
        // ========================================================

        cp_mem_latency : coverpoint cov_mem_latency {

            bins zero_cycle  = {0};

            bins one_cycle   = {1};

            bins two_cycle   = {2};

            bins multi_cycle = {[3:10]};

        }


        // ========================================================
        // Important Cross Coverage
        // ========================================================

        cross_opcode_memory :
            cross cp_opcode,
                  cp_mem_read,
                  cp_mem_write;


        cross_branch_outcome :
            cross cp_opcode,
                  cp_branch_taken;

    endgroup


    // ============================================================
    // Coverage Instance
    // ============================================================

    processor_coverage cov;


    initial begin

        cov = new();

    end

    // ============================================================
    // SECTION 7
    // SYNCHRONOUS INSTRUCTION MEMORY MODEL
    // ============================================================

    // ------------------------------------------------------------
    // Instruction Memory
    // ------------------------------------------------------------

    localparam integer IMEM_WORDS = 1024;

    logic [31:0] instr_mem [0:IMEM_WORDS-1];

    logic [31:0] instr_addr_reg;


    // ------------------------------------------------------------
    // Initialize Instruction Memory
    //
    // Default instruction = RV32I NOP
    // addi x0, x0, 0
    // ------------------------------------------------------------

    integer imem_init_i;

    initial begin

        for (
            imem_init_i = 0;
            imem_init_i < IMEM_WORDS;
            imem_init_i = imem_init_i + 1
        ) begin

            instr_mem[imem_init_i] = 32'h00000013;

        end

    end


    // ------------------------------------------------------------
    // Synchronous SRAM Address Capture
    //
    // The memory macro captures the address on the clock edge.
    // ------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            instr_addr_reg <= 32'd0;

        end
        else begin

            instr_addr_reg <= INSTR_ADD;

        end

    end


    // ------------------------------------------------------------
    // Synchronous Instruction Read Response
    //
    // The instruction corresponding to the registered address is
    // returned after address capture.
    // ------------------------------------------------------------

    always_comb begin

        if (instr_addr_reg[31:2] < IMEM_WORDS)
            INSTR = instr_mem[instr_addr_reg[31:2]];

        else
            INSTR = 32'h00000013;

    end

    // ============================================================
    // SECTION 8
    // DATA MEMORY MODEL
    // ============================================================

    // ------------------------------------------------------------
    // Data Memory
    // ------------------------------------------------------------

    localparam integer DMEM_WORDS = 1024;

    logic [31:0] data_mem [0:DMEM_WORDS-1];


    // ------------------------------------------------------------
    // Memory Model State
    // ------------------------------------------------------------

    logic        mem_transaction_active;
    logic        mem_is_read;
    logic        mem_is_write;

    logic [31:0] mem_addr_reg;
    logic [31:0] mem_wdata_reg;
    logic [3:0]  mem_wstrb_reg;

    integer      mem_delay_count;
    integer      mem_response_delay;


    // ------------------------------------------------------------
    // Configurable Memory Response Latency
    //
    // Default:
    // 1-cycle response latency
    //
    // Directed and random tests can change this later.
    // ------------------------------------------------------------

    initial begin

        mem_response_delay = 1;

    end


    // ------------------------------------------------------------
    // Data Memory Initialization
    // ------------------------------------------------------------

    integer dmem_init_i;

    initial begin

        for (
            dmem_init_i = 0;
            dmem_init_i < DMEM_WORDS;
            dmem_init_i = dmem_init_i + 1
        ) begin

            data_mem[dmem_init_i] = 32'd0;

        end

    end


    // ------------------------------------------------------------
    // Default Memory Outputs
    // ------------------------------------------------------------

    always_comb begin

        MEM_READY = 1'b0;
        MEM_RDATA = 32'd0;

        // A read response is provided only when the active
        // transaction has completed.
        if (
            mem_transaction_active &&
            mem_is_read &&
            (mem_delay_count == 0)
        ) begin

            MEM_READY = 1'b1;

            if (mem_addr_reg[31:2] < DMEM_WORDS)
                MEM_RDATA = data_mem[mem_addr_reg[31:2]];
            else
                MEM_RDATA = 32'd0;

        end


        // Write completion also produces MEM_READY.
        if (
            mem_transaction_active &&
            mem_is_write &&
            (mem_delay_count == 0)
        ) begin

            MEM_READY = 1'b1;

        end

    end


    // ------------------------------------------------------------
    // Memory Transaction Controller
    // ------------------------------------------------------------

    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            mem_transaction_active <= 1'b0;

            mem_is_read  <= 1'b0;
            mem_is_write <= 1'b0;

            mem_addr_reg  <= 32'd0;
            mem_wdata_reg <= 32'd0;
            mem_wstrb_reg <= 4'd0;

            mem_delay_count <= 0;

        end

        else begin

            // ----------------------------------------------------
            // No active transaction:
            // Capture a new processor memory request.
            // ----------------------------------------------------

            if (!mem_transaction_active) begin

                if (MEM_READ || MEM_WRITE) begin

                    mem_transaction_active <= 1'b1;

                    mem_is_read  <= MEM_READ;
                    mem_is_write <= MEM_WRITE;

                    mem_addr_reg  <= MEM_ADDR;
                    mem_wdata_reg <= MEM_WDATA;
                    mem_wstrb_reg <= MEM_WSTRB;

                    mem_delay_count <= mem_response_delay;

                end

            end


            // ----------------------------------------------------
            // Active transaction:
            // Wait for configured response delay.
            // ----------------------------------------------------

            else begin

                if (mem_delay_count > 0) begin

                    mem_delay_count <=
                        mem_delay_count - 1;

                end

                // ------------------------------------------------
                // Transaction completes
                // ------------------------------------------------

                else begin

                    // Write data to memory.
                    if (mem_is_write) begin

                        if (
                            mem_addr_reg[31:2]
                            < DMEM_WORDS
                        ) begin

                            if (mem_wstrb_reg[0])
                                data_mem[mem_addr_reg[31:2]][7:0]
                                    <= mem_wdata_reg[7:0];

                            if (mem_wstrb_reg[1])
                                data_mem[mem_addr_reg[31:2]][15:8]
                                    <= mem_wdata_reg[15:8];

                            if (mem_wstrb_reg[2])
                                data_mem[mem_addr_reg[31:2]][23:16]
                                    <= mem_wdata_reg[23:16];

                            if (mem_wstrb_reg[3])
                                data_mem[mem_addr_reg[31:2]][31:24]
                                    <= mem_wdata_reg[31:24];

                        end

                    end


                    // End transaction.
                    mem_transaction_active <= 1'b0;

                    mem_is_read  <= 1'b0;
                    mem_is_write <= 1'b0;

                end

            end

        end

    end

        // ============================================================
    // SECTION 9
    // INDEPENDENT ARCHITECTURAL REFERENCE MODEL
    // ============================================================


    // ------------------------------------------------------------
    // Architectural State
    // ------------------------------------------------------------

    logic [31:0] ref_regs [0:31];

    logic [31:0] ref_pc;


    // ------------------------------------------------------------
    // Reference Execution Variables
    // ------------------------------------------------------------

    logic [31:0] ref_instr;

    logic [6:0]  ref_opcode;
    logic [2:0]  ref_funct3;
    logic [6:0]  ref_funct7;

    logic [4:0]  ref_rs1;
    logic [4:0]  ref_rs2;
    logic [4:0]  ref_rd;


    logic [31:0] ref_rs1_data;
    logic [31:0] ref_rs2_data;

    logic [31:0] ref_result;

    logic [31:0] ref_next_pc;


    // ------------------------------------------------------------
    // Reference Memory Operation Information
    // ------------------------------------------------------------

    logic        ref_mem_read;
    logic        ref_mem_write;

    logic [31:0] ref_mem_addr;
    logic [31:0] ref_mem_wdata;
    logic [3:0]  ref_mem_wstrb;


    // ------------------------------------------------------------
    // Reference Execution Counters
    // ------------------------------------------------------------

    integer ref_instruction_count;

        // ------------------------------------------------------------
    // Initialize Reference Architectural State
    // ------------------------------------------------------------

    task automatic init_reference_model;

        integer ref_init_i;

        begin

            ref_pc = 32'd0;

            ref_instr = 32'h00000013;

            ref_mem_read  = 1'b0;
            ref_mem_write = 1'b0;

            ref_mem_addr  = 32'd0;
            ref_mem_wdata = 32'd0;
            ref_mem_wstrb = 4'd0;

            ref_instruction_count = 0;


            // Initialize all registers

            for (
                ref_init_i = 0;
                ref_init_i < 32;
                ref_init_i = ref_init_i + 1
            ) begin

                ref_regs[ref_init_i] = 32'd0;

            end


            // x0 is permanently zero

            ref_regs[0] = 32'd0;

        end

    endtask

        // ------------------------------------------------------------
    // Sign Extension Helpers
    // ------------------------------------------------------------

    function automatic [31:0] sign_extend_12;

        input [11:0] value;

        begin

            sign_extend_12 =
                {{20{value[11]}}, value};

        end

    endfunction


    function automatic [31:0] sign_extend_13;

        input [12:0] value;

        begin

            sign_extend_13 =
                {{19{value[12]}}, value};

        end

    endfunction


    function automatic [31:0] sign_extend_21;

        input [20:0] value;

        begin

            sign_extend_21 =
                {{11{value[20]}}, value};

        end

    endfunction

        // ------------------------------------------------------------
    // I-Type Immediate
    // ------------------------------------------------------------

    function automatic [31:0] ref_imm_i;

        input [31:0] instr;

        begin

            ref_imm_i =
                {{20{instr[31]}}, instr[31:20]};

        end

    endfunction


    // ------------------------------------------------------------
    // S-Type Immediate
    // ------------------------------------------------------------

    function automatic [31:0] ref_imm_s;

        input [31:0] instr;

        begin

            ref_imm_s =
                {{20{instr[31]}},
                 instr[31:25],
                 instr[11:7]};

        end

    endfunction


    // ------------------------------------------------------------
    // B-Type Immediate
    // ------------------------------------------------------------

    function automatic [31:0] ref_imm_b;

        input [31:0] instr;

        begin

            ref_imm_b =
                {{19{instr[31]}},
                 instr[31],
                 instr[7],
                 instr[30:25],
                 instr[11:8],
                 1'b0};

        end

    endfunction


    // ------------------------------------------------------------
    // U-Type Immediate
    // ------------------------------------------------------------

    function automatic [31:0] ref_imm_u;

        input [31:0] instr;

        begin

            ref_imm_u =
                {instr[31:12], 12'b0};

        end

    endfunction


    // ------------------------------------------------------------
    // J-Type Immediate
    // ------------------------------------------------------------

    function automatic [31:0] ref_imm_j;

        input [31:0] instr;

        begin

            ref_imm_j =
                {{11{instr[31]}},
                 instr[31],
                 instr[19:12],
                 instr[20],
                 instr[30:21],
                 1'b0};

        end

    endfunction

        // ============================================================
    // SECTION 9E
    // REFERENCE INSTRUCTION EXECUTION
    // ============================================================

    task automatic execute_reference_instruction;

        logic [31:0] instr;

        logic [6:0] opcode;
        logic [2:0] funct3;
        logic [6:0] funct7;

        logic [4:0] rs1;
        logic [4:0] rs2;
        logic [4:0] rd;

        logic [31:0] rs1_data;
        logic [31:0] rs2_data;

        logic [31:0] result;
        logic [31:0] next_pc;

        logic [31:0] imm_i;
        logic [31:0] imm_s;
        logic [31:0] imm_b;
        logic [31:0] imm_u;
        logic [31:0] imm_j;

        logic        branch_taken;

        begin

            // ----------------------------------------------------
            // Fetch from reference program memory
            // ----------------------------------------------------

            if (ref_pc[31:2] < IMEM_WORDS)
                instr = instr_mem[ref_pc[31:2]];
            else
                instr = 32'h00000013;


            // ----------------------------------------------------
            // Decode
            // ----------------------------------------------------

            opcode = instr[6:0];
            funct3 = instr[14:12];
            funct7 = instr[31:25];

            rs1 = instr[19:15];
            rs2 = instr[24:20];
            rd  = instr[11:7];


            // ----------------------------------------------------
            // Read architectural register state
            // ----------------------------------------------------

            if (rs1 == 5'd0)
                rs1_data = 32'd0;
            else
                rs1_data = ref_regs[rs1];

            if (rs2 == 5'd0)
                rs2_data = 32'd0;
            else
                rs2_data = ref_regs[rs2];


            // ----------------------------------------------------
            // Generate immediates
            // ----------------------------------------------------

            imm_i = ref_imm_i(instr);
            imm_s = ref_imm_s(instr);
            imm_b = ref_imm_b(instr);
            imm_u = ref_imm_u(instr);
            imm_j = ref_imm_j(instr);


            // ----------------------------------------------------
            // Default values
            // ----------------------------------------------------

            result       = 32'd0;
            next_pc      = ref_pc + 32'd4;

            branch_taken = 1'b0;

            ref_mem_read  = 1'b0;
            ref_mem_write = 1'b0;

            ref_mem_addr  = 32'd0;
            ref_mem_wdata = 32'd0;
            ref_mem_wstrb = 4'd0;


            // ====================================================
            // Decode / Execute
            // ====================================================

            case (opcode)


                // =================================================
                // R-TYPE
                // =================================================

                7'b0110011: begin

                    case (funct3)

                        // ADD / SUB
                        3'b000: begin

                            if (funct7 == 7'b0000000)
                                result = rs1_data + rs2_data;

                            else if (funct7 == 7'b0100000)
                                result = rs1_data - rs2_data;

                        end


                        // SLL
                        3'b001:
                            result =
                                rs1_data << rs2_data[4:0];


                        // SLT
                        3'b010:
                            result =
                                ($signed(rs1_data) <
                                 $signed(rs2_data))
                                ? 32'd1
                                : 32'd0;


                        // SLTU
                        3'b011:
                            result =
                                (rs1_data < rs2_data)
                                ? 32'd1
                                : 32'd0;


                        // XOR
                        3'b100:
                            result =
                                rs1_data ^ rs2_data;


                        // SRL / SRA
                        3'b101: begin

                            if (funct7 == 7'b0000000)

                                result =
                                    rs1_data >>
                                    rs2_data[4:0];

                            else if (funct7 == 7'b0100000)

                                result =
                                    $signed(rs1_data) >>>
                                    rs2_data[4:0];

                        end


                        // OR
                        3'b110:
                            result =
                                rs1_data | rs2_data;


                        // AND
                        3'b111:
                            result =
                                rs1_data & rs2_data;

                    endcase


                    if (rd != 5'd0)
                        ref_regs[rd] = result;

                end


                // =================================================
                // I-TYPE ALU
                // =================================================

                7'b0010011: begin

                    case (funct3)

                        // ADDI
                        3'b000:
                            result =
                                rs1_data + imm_i;


                        // SLLI
                        3'b001:
                            result =
                                rs1_data <<
                                instr[24:20];


                        // SLTI
                        3'b010:
                            result =
                                ($signed(rs1_data) <
                                 $signed(imm_i))
                                ? 32'd1
                                : 32'd0;


                        // SLTIU
                        3'b011:
                            result =
                                (rs1_data < imm_i)
                                ? 32'd1
                                : 32'd0;


                        // XORI
                        3'b100:
                            result =
                                rs1_data ^ imm_i;


                        // SRLI / SRAI
                        3'b101: begin

                            if (instr[30] == 1'b0)

                                result =
                                    rs1_data >>
                                    instr[24:20];

                            else

                                result =
                                    $signed(rs1_data) >>>
                                    instr[24:20];

                        end


                        // ORI
                        3'b110:
                            result =
                                rs1_data | imm_i;


                        // ANDI
                        3'b111:
                            result =
                                rs1_data & imm_i;

                    endcase


                    if (rd != 5'd0)
                        ref_regs[rd] = result;

                end


                // =================================================
                // LOAD
                // =================================================

                7'b0000011: begin

                    ref_mem_read = 1'b1;

                    ref_mem_addr =
                        rs1_data + imm_i;


                    if (
                        ref_mem_addr[31:2]
                        < DMEM_WORDS
                    ) begin

                        case (funct3)

                            // LB
                            3'b000:
                                result =
                                    {{24{
                                        data_mem[
                                            ref_mem_addr[31:2]
                                        ][
                                            (ref_mem_addr[1:0] * 8)
                                            + 7
                                        ]
                                    }},
                                    data_mem[
                                        ref_mem_addr[31:2]
                                    ][
                                        (ref_mem_addr[1:0] * 8)
                                        +: 8
                                    ]};


                            // LH
                            3'b001:
                                result =
                                    {{16{
                                        data_mem[
                                            ref_mem_addr[31:2]
                                        ][
                                            (ref_mem_addr[1] * 16)
                                            + 15
                                        ]
                                    }},
                                    data_mem[
                                        ref_mem_addr[31:2]
                                    ][
                                        (ref_mem_addr[1] * 16)
                                        +: 16
                                    ]};


                            // LW
                            3'b010:
                                result =
                                    data_mem[
                                        ref_mem_addr[31:2]
                                    ];


                            // LBU
                            3'b100:
                                result =
                                    {
                                        24'd0,
                                        data_mem[
                                            ref_mem_addr[31:2]
                                        ][
                                            (ref_mem_addr[1:0] * 8)
                                            +: 8
                                        ]
                                    };


                            // LHU
                            3'b101:
                                result =
                                    {
                                        16'd0,
                                        data_mem[
                                            ref_mem_addr[31:2]
                                        ][
                                            (ref_mem_addr[1] * 16)
                                            +: 16
                                        ]
                                    };

                            default:
                                result = 32'd0;

                        endcase

                    end
                    else begin

                        result = 32'd0;

                    end


                    if (rd != 5'd0)
                        ref_regs[rd] = result;

                end


                // =================================================
                // STORE
                // =================================================

                7'b0100011: begin

                    ref_mem_write = 1'b1;

                    ref_mem_addr =
                        rs1_data + imm_s;

                    ref_mem_wdata =
                        rs2_data;


                    case (funct3)

                        // SB
                        3'b000:
                            ref_mem_wstrb =
                                4'b0001 <<
                                ref_mem_addr[1:0];


                        // SH
                        3'b001:
                            ref_mem_wstrb =
                                ref_mem_addr[1]
                                ? 4'b1100
                                : 4'b0011;


                        // SW
                        3'b010:
                            ref_mem_wstrb =
                                4'b1111;

                        default:
                            ref_mem_wstrb =
                                4'b0000;

                    endcase


                    if (
                        ref_mem_addr[31:2]
                        < DMEM_WORDS
                    ) begin

                        if (ref_mem_wstrb[0])
                            data_mem[
                                ref_mem_addr[31:2]
                            ][7:0] =
                                ref_mem_wdata[7:0];

                        if (ref_mem_wstrb[1])
                            data_mem[
                                ref_mem_addr[31:2]
                            ][15:8] =
                                ref_mem_wdata[15:8];

                        if (ref_mem_wstrb[2])
                            data_mem[
                                ref_mem_addr[31:2]
                            ][23:16] =
                                ref_mem_wdata[23:16];

                        if (ref_mem_wstrb[3])
                            data_mem[
                                ref_mem_addr[31:2]
                            ][31:24] =
                                ref_mem_wdata[31:24];

                    end

                end


                // =================================================
                // BRANCH
                // =================================================

                7'b1100011: begin

                    case (funct3)

                        // BEQ
                        3'b000:
                            branch_taken =
                                (rs1_data == rs2_data);


                        // BNE
                        3'b001:
                            branch_taken =
                                (rs1_data != rs2_data);


                        // BLT
                        3'b100:
                            branch_taken =
                                ($signed(rs1_data) <
                                 $signed(rs2_data));


                        // BGE
                        3'b101:
                            branch_taken =
                                ($signed(rs1_data) >=
                                 $signed(rs2_data));


                        // BLTU
                        3'b110:
                            branch_taken =
                                (rs1_data < rs2_data);


                        // BGEU
                        3'b111:
                            branch_taken =
                                (rs1_data >= rs2_data);

                        default:
                            branch_taken =
                                1'b0;

                    endcase


                    if (branch_taken)
                        next_pc =
                            ref_pc + imm_b;

                end


                // =================================================
                // JAL
                // =================================================

                7'b1101111: begin

                    result =
                        ref_pc + 32'd4;

                    if (rd != 5'd0)
                        ref_regs[rd] =
                            result;

                    next_pc =
                        ref_pc + imm_j;

                end


                // =================================================
                // JALR
                // =================================================

                7'b1100111: begin

                    result =
                        ref_pc + 32'd4;

                    if (rd != 5'd0)
                        ref_regs[rd] =
                            result;

                    next_pc =
                        (rs1_data + imm_i) &
                        32'hFFFFFFFE;

                end


                // =================================================
                // LUI
                // =================================================

                7'b0110111: begin

                    result = imm_u;

                    if (rd != 5'd0)
                        ref_regs[rd] =
                            result;

                end


                // =================================================
                // AUIPC
                // =================================================

                7'b0010111: begin

                    result =
                        ref_pc + imm_u;

                    if (rd != 5'd0)
                        ref_regs[rd] =
                            result;

                end


                // =================================================
                // Unsupported / NOP
                // =================================================

                default: begin

                    // No architectural state change

                end

            endcase


            // ----------------------------------------------------
            // Enforce architectural x0
            // ----------------------------------------------------

            ref_regs[0] = 32'd0;


            // ----------------------------------------------------
            // Commit PC
            // ----------------------------------------------------

            ref_pc =
                next_pc;


            ref_instruction_count =
                ref_instruction_count + 1;

        end

    endtask

        // ============================================================
    // SECTION 10
    // TEST CONTROL AND RESET TASKS
    // ============================================================


    // ------------------------------------------------------------
    // Apply Processor Reset
    // ------------------------------------------------------------

    task automatic apply_reset;

        begin

            // Drive reset active
            rst_n = 1'b0;

            // Default external memory inputs
            INSTR      = 32'h00000013;

            MEM_READY  = 1'b0;
            MEM_RDATA  = 32'd0;

            // Hold reset for multiple clock cycles
            repeat (3) @(posedge clk);

            // Release reset
            rst_n = 1'b1;

            // Allow DUT state to settle
            @(posedge clk);

        end

    endtask


    // ------------------------------------------------------------
    // Initialize Complete Test Environment
    // ------------------------------------------------------------

    task automatic initialize_test;

        integer init_i;

        begin

            // ----------------------------------------------------
            // Reset verification counters
            // ----------------------------------------------------

            test_count = 0;
            pass_count = 0;
            fail_count = 0;

            assertion_failures = 0;


            // ----------------------------------------------------
            // Clear instruction memory
            // ----------------------------------------------------

            for (
                init_i = 0;
                init_i < IMEM_WORDS;
                init_i = init_i + 1
            ) begin

                instr_mem[init_i] =
                    32'h00000013;

            end


            // ----------------------------------------------------
            // Clear data memory
            // ----------------------------------------------------

            for (
                init_i = 0;
                init_i < DMEM_WORDS;
                init_i = init_i + 1
            ) begin

                data_mem[init_i] =
                    32'd0;

            end


            // ----------------------------------------------------
            // Initialize reference model
            // ----------------------------------------------------

            init_reference_model();


            // ----------------------------------------------------
            // Initialize memory transaction state
            // ----------------------------------------------------

            mem_transaction_active = 1'b0;

            mem_is_read  = 1'b0;
            mem_is_write = 1'b0;

            mem_addr_reg  = 32'd0;
            mem_wdata_reg = 32'd0;
            mem_wstrb_reg = 4'd0;

            mem_delay_count = 0;


            // ----------------------------------------------------
            // Default memory latency
            // ----------------------------------------------------

            mem_response_delay = 1;


            // ----------------------------------------------------
            // Apply processor reset
            // ----------------------------------------------------

            apply_reset();

        end

    endtask


    // ------------------------------------------------------------
    // Load Program Instruction
    // ------------------------------------------------------------

    task automatic load_instruction;

        input integer      address;
        input logic [31:0] instruction;

        integer word_index;

        begin

            word_index =
                address >> 2;


            if (
                (word_index >= 0) &&
                (word_index < IMEM_WORDS)
            ) begin

                instr_mem[word_index] =
                    instruction;

            end

            else begin

                $error(
                    "PROGRAM LOAD ERROR | ADDRESS=%h",
                    address
                );

                fail_count =
                    fail_count + 1;

            end

        end

    endtask


    // ------------------------------------------------------------
    // Wait Specified Number of Processor Cycles
    // ------------------------------------------------------------

    task automatic run_cycles;

        input integer cycles;

        integer cycle_i;

        begin

            for (
                cycle_i = 0;
                cycle_i < cycles;
                cycle_i = cycle_i + 1
            ) begin

                @(posedge clk);

            end

        end

    endtask


    // ------------------------------------------------------------
    // Processor Timeout Protection
    // ------------------------------------------------------------

    task automatic run_with_timeout;

        input integer max_cycles;

        integer timeout_cycle;

        begin

            for (
                timeout_cycle = 0;
                timeout_cycle < max_cycles;
                timeout_cycle = timeout_cycle + 1
            ) begin

                @(posedge clk);

            end

            $error(
                "PROCESSOR TIMEOUT | MAX CYCLES=%0d",
                max_cycles
            );

            fail_count =
                fail_count + 1;

        end

    endtask

    // ============================================================
    // SECTION 11
    // ARCHITECTURAL SCOREBOARD
    // ============================================================


    // ------------------------------------------------------------
    // Scoreboard State
    // ------------------------------------------------------------

    integer scoreboard_checks;
    integer scoreboard_passes;
    integer scoreboard_failures;

    integer register_index;
    integer memory_index;

    logic [31:0] expected_value;
    logic [31:0] actual_value;


    // ============================================================
    // CHECK SINGLE REGISTER
    // ============================================================

    task automatic check_register;

        input integer reg_index;

        logic [31:0] expected_reg_value;
        logic [31:0] actual_reg_value;

        begin

            // ----------------------------------------------------
            // Architectural x0 is always zero
            // ----------------------------------------------------

            if (reg_index == 0)

                expected_reg_value =
                    32'd0;

            else

                expected_reg_value =
                    ref_regs[reg_index];


            // ----------------------------------------------------
            // DUT architectural register observation
            //
            // NOTE:
            // This hierarchical path must be aligned with the
            // actual processor/register-file RTL during integration.
            // ----------------------------------------------------

            actual_reg_value =
                dut.RegFile.regs[reg_index];


            scoreboard_checks =
                scoreboard_checks + 1;


            if (
                actual_reg_value
                !==
                expected_reg_value
            ) begin

                $display("");

                $display(
                    "================================================"
                );

                $display(
                    "SCOREBOARD REGISTER FAIL"
                );

                $display(
                    "Time       = %0t",
                    $time
                );

                $display(
                    "Register   = x%0d",
                    reg_index
                );

                $display(
                    "Expected   = %h",
                    expected_reg_value
                );

                $display(
                    "Actual     = %h",
                    actual_reg_value
                );

                $display(
                    "================================================"
                );

                scoreboard_failures =
                    scoreboard_failures + 1;

                fail_count =
                    fail_count + 1;

            end

            else begin

                scoreboard_passes =
                    scoreboard_passes + 1;

            end

        end

    endtask


    // ============================================================
    // CHECK COMPLETE REGISTER FILE
    // ============================================================

    task automatic check_register_file;

        integer i;

        begin

            for (
                i = 0;
                i < 32;
                i = i + 1
            ) begin

                check_register(i);

            end

        end

    endtask


    // ============================================================
    // CHECK SINGLE MEMORY WORD
    // ============================================================

    task automatic check_memory_word;

        input integer word_index;

        logic [31:0] expected_memory_value;
        logic [31:0] actual_memory_value;

        begin

            expected_memory_value =
                ref_data_mem[word_index];


            actual_memory_value =
                dut_data_mem[word_index];


            scoreboard_checks =
                scoreboard_checks + 1;


            if (
                actual_memory_value
                !==
                expected_memory_value
            ) begin

                $display("");

                $display(
                    "================================================"
                );

                $display(
                    "SCOREBOARD MEMORY FAIL"
                );

                $display(
                    "Time       = %0t",
                    $time
                );

                $display(
                    "Word Index = %0d",
                    word_index
                );

                $display(
                    "Address    = %h",
                    word_index * 4
                );

                $display(
                    "Expected   = %h",
                    expected_memory_value
                );

                $display(
                    "Actual     = %h",
                    actual_memory_value
                );

                $display(
                    "================================================"
                );

                scoreboard_failures =
                    scoreboard_failures + 1;

                fail_count =
                    fail_count + 1;

            end

            else begin

                scoreboard_passes =
                    scoreboard_passes + 1;

            end

        end

    endtask


    // ============================================================
    // CHECK DATA MEMORY RANGE
    // ============================================================

    task automatic check_memory_range;

        input integer start_word;
        input integer number_of_words;

        integer i;

        begin

            for (
                i = start_word;
                i < (start_word + number_of_words);
                i = i + 1
            ) begin

                check_memory_word(i);

            end

        end

    endtask


    // ============================================================
    // CHECK COMPLETE ARCHITECTURAL STATE
    // ============================================================

    task automatic check_architectural_state;

        input integer memory_words_to_check;

        begin

            $display("");

            $display(
                "Checking architectural register state..."
            );

            check_register_file();


            $display(
                "Checking architectural memory state..."
            );

            check_memory_range(
                0,
                memory_words_to_check
            );


            // ----------------------------------------------------
            // Architectural PC comparison intentionally postponed
            // ----------------------------------------------------
            //
            // The DUT PC may legally be ahead of the reference
            // architectural PC because instructions are in flight.
            //
            // We will compare PC only at a defined program
            // completion / drain point.
            // ----------------------------------------------------

        end

    endtask


    // ============================================================
    // INITIALIZE SCOREBOARD
    // ============================================================

    task automatic initialize_scoreboard;

        begin

            scoreboard_checks   = 0;
            scoreboard_passes   = 0;
            scoreboard_failures = 0;

        end

    endtask


    // ============================================================
    // PRINT SCOREBOARD REPORT
    // ============================================================

    task automatic print_scoreboard_report;

        begin

            $display("");

            $display(
                "================================================"
            );

            $display(
                "         ARCHITECTURAL SCOREBOARD REPORT"
            );

            $display(
                "================================================"
            );

            $display(
                "Total Checks = %0d",
                scoreboard_checks
            );

            $display(
                "Passed       = %0d",
                scoreboard_passes
            );

            $display(
                "Failed       = %0d",
                scoreboard_failures
            );

            $display(
                "================================================"
            );

        end

    endtask


    // ============================================================
    // SECTION 12
    // PROCESSOR ASSERTIONS
    // ============================================================


    // ------------------------------------------------------------
    // Assertion bookkeeping
    // ------------------------------------------------------------

    integer assertion_checks;
    integer assertion_failures;


    // ------------------------------------------------------------
    // Previous-cycle state
    // ------------------------------------------------------------

    logic        prev_mem_transaction_active;
    logic [31:0] prev_mem_addr;
    logic        prev_mem_is_read;
    logic        prev_mem_is_write;

    logic [31:0] prev_instr_addr;


    // ============================================================
    // INITIALIZE ASSERTION STATE
    // ============================================================

    initial begin

        assertion_checks = 0;
        assertion_failures = 0;

        prev_mem_transaction_active = 1'b0;
        prev_mem_addr = 32'd0;
        prev_mem_is_read = 1'b0;
        prev_mem_is_write = 1'b0;

        prev_instr_addr = 32'd0;

    end


    // ============================================================
    // CLOCKED ASSERTION CHECKER
    // ============================================================

    always @(posedge clk) begin

        if (rst_n) begin


            // ====================================================
            // ASSERTION 1
            // x0 in DUT register file must remain zero
            //
            // Replace hierarchy during final integration if needed.
            // ====================================================

            assertion_checks =
                assertion_checks + 1;

            assert (
                dut.RegFile.regs[0]
                ===
                32'd0
            )

            else begin

                $error(
                    "ASSERTION FAILED: DUT x0 is not zero | x0=%h",
                    dut.RegFile.regs[0]
                );

                assertion_failures =
                    assertion_failures + 1;

                fail_count =
                    fail_count + 1;

            end


            // ====================================================
            // ASSERTION 2
            // A memory transaction cannot simultaneously be
            // both read and write.
            // ====================================================

            assertion_checks =
                assertion_checks + 1;

            assert (
                !(
                    mem_transaction_active &&
                    mem_is_read &&
                    mem_is_write
                )
            )

            else begin

                $error(
                    "ASSERTION FAILED: MEMORY MODEL HAS "
                    "SIMULTANEOUS READ AND WRITE"
                );

                assertion_failures =
                    assertion_failures + 1;

                fail_count =
                    fail_count + 1;

            end


            // ====================================================
            // ASSERTION 3
            // Active memory transaction address remains stable.
            //
            // This checks the TB memory transaction capture model,
            // not the DUT internal memory-stage implementation.
            // ====================================================

            if (
                prev_mem_transaction_active &&
                mem_transaction_active
            ) begin

                assertion_checks =
                    assertion_checks + 1;

                assert (
                    mem_addr_reg
                    ===
                    prev_mem_addr
                )

                else begin

                    $error(
                        "ASSERTION FAILED: ACTIVE MEMORY "
                        "TRANSACTION ADDRESS CHANGED | "
                        "PREV=%h CURRENT=%h",
                        prev_mem_addr,
                        mem_addr_reg
                    );

                    assertion_failures =
                        assertion_failures + 1;

                    fail_count =
                        fail_count + 1;

                end

            end


            // ====================================================
            // ASSERTION 4
            // Read/write type must remain stable during an active
            // memory transaction.
            // ====================================================

            if (
                prev_mem_transaction_active &&
                mem_transaction_active
            ) begin

                assertion_checks =
                    assertion_checks + 1;

                assert (
                    (mem_is_read == prev_mem_is_read) &&
                    (mem_is_write == prev_mem_is_write)
                )

                else begin

                    $error(
                        "ASSERTION FAILED: MEMORY TRANSACTION "
                        "TYPE CHANGED WHILE ACTIVE"
                    );

                    assertion_failures =
                        assertion_failures + 1;

                    fail_count =
                        fail_count + 1;

                end

            end


            // ====================================================
            // ASSERTION 5
            // MEM_READY must only be asserted for an active
            // transaction.
            // ====================================================

            if (MEM_READY) begin

                assertion_checks =
                    assertion_checks + 1;

                assert (
                    mem_transaction_active
                )

                else begin

                    $error(
                        "ASSERTION FAILED: MEM_READY WITHOUT "
                        "ACTIVE MEMORY TRANSACTION"
                    );

                    assertion_failures =
                        assertion_failures + 1;

                    fail_count =
                        fail_count + 1;

                end

            end


            // ====================================================
            // ASSERTION 6
            // Write strobes should not contain X/Z during a store
            // transaction.
            // ====================================================

            if (
                mem_transaction_active &&
                mem_is_write
            ) begin

                assertion_checks =
                    assertion_checks + 1;

                assert (
                    !$isunknown(mem_wstrb_reg)
                )

                else begin

                    $error(
                        "ASSERTION FAILED: UNKNOWN MEMORY "
                        "WRITE STROBE | WSTRB=%b",
                        mem_wstrb_reg
                    );

                    assertion_failures =
                        assertion_failures + 1;

                    fail_count =
                        fail_count + 1;

                end

            end


            // ====================================================
            // ASSERTION 7
            // Instruction memory address must be word aligned.
            //
            // RV32I instructions are 32 bits in this processor.
            // ====================================================

            assertion_checks =
                assertion_checks + 1;

            assert (
                INSTR_ADD[1:0]
                == 2'b00
            )

            else begin

                $error(
                    "ASSERTION FAILED: UNALIGNED INSTRUCTION "
                    "ADDRESS | ADDR=%h",
                    INSTR_ADD
                );

                assertion_failures =
                    assertion_failures + 1;

                fail_count =
                    fail_count + 1;

            end


            // ====================================================
            // ASSERTION 8
            // DUT memory request address must not contain X/Z when
            // a request is issued.
            // ====================================================

            if (
                MEM_READ ||
                MEM_WRITE
            ) begin

                assertion_checks =
                    assertion_checks + 1;

                assert (
                    !$isunknown(MEM_ADDR)
                )

                else begin

                    $error(
                        "ASSERTION FAILED: MEMORY REQUEST "
                        "HAS UNKNOWN ADDRESS | ADDR=%h",
                        MEM_ADDR
                    );

                    assertion_failures =
                        assertion_failures + 1;

                    fail_count =
                        fail_count + 1;

                end

            end

        end


        // ========================================================
        // Capture assertion history
        // ========================================================

        prev_mem_transaction_active =
            mem_transaction_active;

        prev_mem_addr =
            mem_addr_reg;

        prev_mem_is_read =
            mem_is_read;

        prev_mem_is_write =
            mem_is_write;

        prev_instr_addr =
            INSTR_ADD;

    end

        // ============================================================
    // SECTION 14
    // EXTENDED DIRECTED CONTROL-FLOW TESTS
    // ============================================================


    // ============================================================
    // DIRECTED TEST 7
    // JAL TEST
    // ============================================================

    task automatic test_jal;

        begin

            $display("");
            $display("================================================");
            $display("DIRECTED TEST 7: JAL");
            $display("================================================");

            initialize_test();
            initialize_scoreboard();


            // ----------------------------------------------------
            // Program
            //
            // 0x00: JAL x1,+8
            //       x1 should receive PC+4 = 0x04
            //
            // 0x04: ADDI x2,x0,1   (must be skipped)
            //
            // 0x08: ADDI x2,x0,2   (jump target)
            // ----------------------------------------------------

            load_instruction(
                32'h00000000,
                32'h008000EF       // JAL x1,+8
            );

            load_instruction(
                32'h00000004,
                32'h00100113       // ADDI x2,x0,1
            );

            load_instruction(
                32'h00000008,
                32'h00200113       // ADDI x2,x0,2
            );


            run_cycles(60);


            // Reference execution:
            // JAL at 0x00
            // ADDI at 0x08

            execute_reference_instruction();
            execute_reference_instruction();


            check_architectural_state(16);

            print_scoreboard_report();

        end

    endtask


    // ============================================================
    // DIRECTED TEST 8
    // JALR TEST
    // ============================================================

    task automatic test_jalr;

        begin

            $display("");
            $display("================================================");
            $display("DIRECTED TEST 8: JALR");
            $display("================================================");

            initialize_test();
            initialize_scoreboard();


            // ----------------------------------------------------
            // Program
            //
            // x1 = 16
            //
            // JALR x2,0(x1)
            //
            // target = 0x10
            //
            // x2 should receive PC+4 = 0x08
            // ----------------------------------------------------

            load_instruction(
                32'h00000000,
                32'h01000093       // ADDI x1,x0,16
            );

            load_instruction(
                32'h00000004,
                32'h00008167       // JALR x2,0(x1)
            );

            load_instruction(
                32'h00000008,
                32'h00100193       // ADDI x3,x0,1 (skip)
            );

            load_instruction(
                32'h0000000C,
                32'h00200193       // ADDI x3,x0,2 (skip)
            );

            load_instruction(
                32'h00000010,
                32'h00300193       // ADDI x3,x0,3
            );


            run_cycles(70);


            // Reference:
            // ADDI x1
            // JALR
            // ADDI at 0x10

            execute_reference_instruction();
            execute_reference_instruction();
            execute_reference_instruction();


            check_architectural_state(16);

            print_scoreboard_report();

        end

    endtask


    // ============================================================
    // DIRECTED TEST 9
    // NEGATIVE BRANCH OFFSET / BACKWARD LOOP
    // ============================================================

    task automatic test_backward_branch;

        begin

            $display("");
            $display("================================================");
            $display("DIRECTED TEST 9: BACKWARD BRANCH LOOP");
            $display("================================================");

            initialize_test();
            initialize_scoreboard();


            // ----------------------------------------------------
            // Program
            //
            // x1 = 0
            // x2 = 5
            //
            // LOOP:
            // x1 = x1 + 1
            //
            // if (x1 < x2)
            //     branch back
            //
            // Expected final x1 = 5
            // ----------------------------------------------------

            load_instruction(
                32'h00000000,
                32'h00000093       // ADDI x1,x0,0
            );

            load_instruction(
                32'h00000004,
                32'h00500113       // ADDI x2,x0,5
            );

            load_instruction(
                32'h00000008,
                32'h00108093       // ADDI x1,x1,1
            );

            // BLT x1,x2,-4
            load_instruction(
                32'h0000000C,
                32'hFE20CEE3
            );


            run_cycles(120);


            // Execute exact architectural instruction count:
            //
            // setup = 2
            // loop body executed 5 times
            // branch executed 5 times
            //
            // total = 12

            execute_reference_instruction();
            execute_reference_instruction();

            execute_reference_instruction();
            execute_reference_instruction();

            execute_reference_instruction();
            execute_reference_instruction();

            execute_reference_instruction();
            execute_reference_instruction();

            execute_reference_instruction();
            execute_reference_instruction();

            execute_reference_instruction();
            execute_reference_instruction();


            check_architectural_state(16);

            print_scoreboard_report();

        end

    endtask


    // ============================================================
    // DIRECTED TEST 10
    // SIGNED BRANCH TEST
    // ============================================================

    task automatic test_signed_branch;

        begin

            $display("");
            $display("================================================");
            $display("DIRECTED TEST 10: SIGNED BRANCH");
            $display("================================================");

            initialize_test();
            initialize_scoreboard();


            // x1 = -1
            // x2 = 1
            //
            // BLT x1,x2,+8
            //
            // Signed comparison must treat -1 < 1

            load_instruction(
                32'h00000000,
                32'hFFF00093       // ADDI x1,x0,-1
            );

            load_instruction(
                32'h00000004,
                32'h00100113       // ADDI x2,x0,1
            );

            load_instruction(
                32'h00000008,
                32'h0020C463       // BLT x1,x2,+8
            );

            load_instruction(
                32'h0000000C,
                32'h00100193       // skipped
            );

            load_instruction(
                32'h00000010,
                32'h00200193       // target
            );


            run_cycles(60);


            execute_reference_instruction();
            execute_reference_instruction();
            execute_reference_instruction();
            execute_reference_instruction();


            check_architectural_state(16);

            print_scoreboard_report();

        end

    endtask


    // ============================================================
    // DIRECTED TEST 11
    // UNSIGNED BRANCH TEST
    // ============================================================

    task automatic test_unsigned_branch;

        begin

            $display("");
            $display("================================================");
            $display("DIRECTED TEST 11: UNSIGNED BRANCH");
            $display("================================================");

            initialize_test();
            initialize_scoreboard();


            // x1 = -1 = 0xFFFFFFFF
            // x2 = 1
            //
            // BLTU x2,x1,+8
            //
            // Unsigned:
            // 1 < 0xFFFFFFFF => TRUE

            load_instruction(
                32'h00000000,
                32'hFFF00093
            );

            load_instruction(
                32'h00000004,
                32'h00100113
            );

            load_instruction(
                32'h00000008,
                32'h00116463       // BLTU x2,x1,+8
            );

            load_instruction(
                32'h0000000C,
                32'h00100193       // skipped
            );

            load_instruction(
                32'h00000010,
                32'h00200193       // target
            );


            run_cycles(60);


            execute_reference_instruction();
            execute_reference_instruction();
            execute_reference_instruction();
            execute_reference_instruction();


            check_architectural_state(16);

            print_scoreboard_report();

        end

    endtask


    // ============================================================
    // DIRECTED TEST 12
    // LUI
    // ============================================================

    task automatic test_lui;

        begin

            $display("");
            $display("================================================");
            $display("DIRECTED TEST 12: LUI");
            $display("================================================");

            initialize_test();
            initialize_scoreboard();


            // LUI x1,0x12345
            //
            // Expected:
            // x1 = 0x12345000

            load_instruction(
                32'h00000000,
                32'h123450B7
            );


            run_cycles(30);


            execute_reference_instruction();


            check_architectural_state(16);

            print_scoreboard_report();

        end

    endtask


    // ============================================================
    // DIRECTED TEST 13
    // AUIPC
    // ============================================================

    task automatic test_auipc;

        begin

            $display("");
            $display("================================================");
            $display("DIRECTED TEST 13: AUIPC");
            $display("================================================");

            initialize_test();
            initialize_scoreboard();


            // ----------------------------------------------------
            // AUIPC x1,0x00001
            //
            // At PC = 0:
            //
            // x1 = PC + 0x00001000
            //
            // Expected:
            // x1 = 0x00001000
            // ----------------------------------------------------

            load_instruction(
                32'h00000000,
                32'h00001097
            );


            run_cycles(30);


            execute_reference_instruction();


            check_architectural_state(16);

            print_scoreboard_report();

        end

    endtask

        // ============================================================
    // SECTION 15
    // RV32I INSTRUCTION ENCODING FUNCTIONS
    // ============================================================


    // ============================================================
    // R-TYPE
    //
    // 31          25 24   20 19   15 14  12 11    7 6        0
    // -----------------------------------------------------------
    // funct7         rs2      rs1   funct3    rd    opcode
    // ============================================================

    function automatic [31:0] encode_r_type;

        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;

        begin

            encode_r_type = {
                funct7,
                rs2,
                rs1,
                funct3,
                rd,
                opcode
            };

        end

    endfunction


    // ============================================================
    // I-TYPE
    //
    // 31                20 19   15 14  12 11    7 6        0
    // -----------------------------------------------------------
    // immediate[11:0]       rs1   funct3    rd    opcode
    // ============================================================

    function automatic [31:0] encode_i_type;

        input [11:0] imm;
        input [4:0]  rs1;
        input [2:0]  funct3;
        input [4:0]  rd;
        input [6:0]  opcode;

        begin

            encode_i_type = {
                imm,
                rs1,
                funct3,
                rd,
                opcode
            };

        end

    endfunction


    // ============================================================
    // S-TYPE
    //
    // 31       25 24   20 19   15 14  12 11        7 6    0
    // -----------------------------------------------------------
    // imm[11:5]   rs2      rs1   funct3  imm[4:0] opcode
    // ============================================================

    function automatic [31:0] encode_s_type;

        input [11:0] imm;
        input [4:0]  rs2;
        input [4:0]  rs1;
        input [2:0]  funct3;
        input [6:0]  opcode;

        begin

            encode_s_type = {
                imm[11:5],
                rs2,
                rs1,
                funct3,
                imm[4:0],
                opcode
            };

        end

    endfunction


    // ============================================================
    // B-TYPE
    //
    // Branch immediate represents a byte offset.
    // Bit 0 is always zero.
    //
    // Instruction encoding:
    //
    // imm[12]      -> bit 31
    // imm[10:5]    -> bits 30:25
    // imm[4:1]     -> bits 11:8
    // imm[11]      -> bit 7
    // ============================================================

    function automatic [31:0] encode_b_type;

        input signed [12:0] imm;
        input [4:0]        rs2;
        input [4:0]        rs1;
        input [2:0]        funct3;
        input [6:0]        opcode;

        begin

            encode_b_type = {
                imm[12],
                imm[10:5],
                rs2,
                rs1,
                funct3,
                imm[4:1],
                imm[11],
                opcode
            };

        end

    endfunction


    // ============================================================
    // U-TYPE
    //
    // 31                             12 11    7 6        0
    // -----------------------------------------------------------
    // immediate[31:12]                   rd    opcode
    // ============================================================

    function automatic [31:0] encode_u_type;

        input [19:0] imm20;
        input [4:0]  rd;
        input [6:0]  opcode;

        begin

            encode_u_type = {
                imm20,
                rd,
                opcode
            };

        end

    endfunction


    // ============================================================
    // J-TYPE
    //
    // Immediate represents byte offset.
    // Bit 0 is always zero.
    //
    // Instruction encoding:
    //
    // imm[20]      -> bit 31
    // imm[10:1]    -> bits 30:21
    // imm[11]      -> bit 20
    // imm[19:12]   -> bits 19:12
    // ============================================================

    function automatic [31:0] encode_j_type;

        input signed [20:0] imm;
        input [4:0]        rd;
        input [6:0]        opcode;

        begin

            encode_j_type = {
                imm[20],
                imm[10:1],
                imm[11],
                imm[19:12],
                rd,
                opcode
            };

        end

    endfunction

        // ============================================================
    // RV32I OPCODE CONSTANTS
    // ============================================================

    localparam [6:0] OPCODE_OP        = 7'b0110011;
    localparam [6:0] OPCODE_OP_IMM    = 7'b0010011;
    localparam [6:0] OPCODE_LOAD      = 7'b0000011;
    localparam [6:0] OPCODE_STORE     = 7'b0100011;
    localparam [6:0] OPCODE_BRANCH    = 7'b1100011;
    localparam [6:0] OPCODE_JALR      = 7'b1100111;
    localparam [6:0] OPCODE_JAL       = 7'b1101111;
    localparam [6:0] OPCODE_LUI       = 7'b0110111;
    localparam [6:0] OPCODE_AUIPC     = 7'b0010111;

        // ============================================================
    // SECTION 16
    // PROGRAM EXECUTION AND REFERENCE SYNCHRONIZATION
    // ============================================================


    // ============================================================
    // RUN DUT FOR SPECIFIED NUMBER OF CLOCK CYCLES
    // ============================================================

    task automatic run_cycles;

        input integer cycles;

        integer cycle;

        begin

            for (
                cycle = 0;
                cycle < cycles;
                cycle = cycle + 1
            ) begin

                @(posedge clk);

            end

        end

    endtask

        // ============================================================
    // EXECUTE REFERENCE PROGRAM
    //
    // This is instruction-count based.
    //
    // It is intentionally independent of DUT cycles.
    // ============================================================

    task automatic execute_reference_program;

        input integer instruction_count;

        integer executed;

        begin

            executed = 0;

            while (
                executed < instruction_count
            ) begin

                execute_reference_instruction();

                executed = executed + 1;

            end

        end

    endtask

        // ============================================================
    // LOAD ONE INSTRUCTION INTO PROGRAM MEMORY
    // ============================================================

    task automatic load_program_instruction;

        input [31:0] address;
        input [31:0] instruction;

        integer word_index;

        begin

            word_index = address >> 2;


            // ----------------------------------------------------
            // DUT instruction memory image
            // ----------------------------------------------------

            dut_instr_mem[word_index] =
                instruction;


            // ----------------------------------------------------
            // Reference instruction memory image
            // ----------------------------------------------------

            ref_instr_mem[word_index] =
                instruction;

        end

    endtask

        // ============================================================
    // CLEAR PROGRAM MEMORY
    // ============================================================

    task automatic clear_program_memory;

        integer index;

        begin

            for (
                index = 0;
                index < INSTR_MEM_DEPTH;
                index = index + 1
            ) begin

                // RISC-V architectural NOP
                //
                // ADDI x0,x0,0

                dut_instr_mem[index] =
                    32'h00000013;

                ref_instr_mem[index] =
                    32'h00000013;

            end

        end

    endtask

        // ============================================================
    // CLEAR REFERENCE AND DUT DATA MEMORY
    // ============================================================

    task automatic clear_data_memory;

        integer index;

        begin

            for (
                index = 0;
                index < DATA_MEM_DEPTH;
                index = index + 1
            ) begin

                dut_data_mem[index] =
                    32'd0;

                ref_data_mem[index] =
                    32'd0;

            end

        end

    endtask

        // ============================================================
    // INITIALIZE PROGRAM ENVIRONMENT
    // ============================================================

    task automatic initialize_program_environment;

        begin

            clear_program_memory();

            clear_data_memory();

            initialize_scoreboard();

        end

    endtask

        // ============================================================
    // SECTION 17
    // RANDOM LEGAL RV32I INSTRUCTION GENERATION
    // ============================================================


    // ============================================================
    // RANDOM REGISTER
    //
    // By default we avoid x0 as a destination because writes to x0
    // do not change architectural state and reduce useful coverage.
    // ============================================================

    function automatic [4:0] random_destination_register;

        begin

            random_destination_register =
                $urandom_range(1, 31);

        end

    endfunction


    // ============================================================
    // RANDOM SOURCE REGISTER
    //
    // x0 is allowed as a source.
    // ============================================================

    function automatic [4:0] random_source_register;

        begin

            random_source_register =
                $urandom_range(0, 31);

        end

    endfunction


    // ============================================================
    // RANDOM ALIGNED MEMORY OFFSET
    //
    // Range is deliberately small initially so random accesses stay
    // within the testbench data memory model.
    //
    // Returns a signed 12-bit immediate.
    // ============================================================

    function automatic signed [11:0] random_memory_offset;

        integer random_word_offset;

        begin

            random_word_offset =
                $urandom_range(0, 31);

            random_memory_offset =
                random_word_offset * 4;

        end

    endfunction


    // ============================================================
    // RANDOM ARITHMETIC IMMEDIATE
    // ============================================================

    function automatic signed [11:0] random_i_immediate;

        integer random_value;

        begin

            random_value =
                $urandom_range(0, 4095);

            random_i_immediate =
                random_value;

        end

    endfunction


    // ============================================================
    // RANDOM U-TYPE IMMEDIATE
    // ============================================================

    function automatic [19:0] random_u_immediate;

        begin

            random_u_immediate =
                $urandom;

        end

    endfunction


    // ============================================================
    // RANDOM R-TYPE ALU INSTRUCTION
    //
    // Supported:
    //
    // ADD
    // SUB
    // AND
    // OR
    // XOR
    // SLT
    // SLTU
    // SLL
    // SRL
    // SRA
    // ============================================================

    function automatic [31:0] random_r_type_instruction;

        integer operation;

        logic [4:0] rd;
        logic [4:0] rs1;
        logic [4:0] rs2;

        begin

            rd =
                random_destination_register();

            rs1 =
                random_source_register();

            rs2 =
                random_source_register();

            operation =
                $urandom_range(0, 9);

            case (operation)

                // ADD
                0:
                    random_r_type_instruction =
                        encode_r_type(
                            7'b0000000,
                            rs2,
                            rs1,
                            3'b000,
                            rd,
                            OPCODE_OP
                        );


                // SUB
                1:
                    random_r_type_instruction =
                        encode_r_type(
                            7'b0100000,
                            rs2,
                            rs1,
                            3'b000,
                            rd,
                            OPCODE_OP
                        );


                // SLL
                2:
                    random_r_type_instruction =
                        encode_r_type(
                            7'b0000000,
                            rs2,
                            rs1,
                            3'b001,
                            rd,
                            OPCODE_OP
                        );


                // SLT
                3:
                    random_r_type_instruction =
                        encode_r_type(
                            7'b0000000,
                            rs2,
                            rs1,
                            3'b010,
                            rd,
                            OPCODE_OP
                        );


                // SLTU
                4:
                    random_r_type_instruction =
                        encode_r_type(
                            7'b0000000,
                            rs2,
                            rs1,
                            3'b011,
                            rd,
                            OPCODE_OP
                        );


                // XOR
                5:
                    random_r_type_instruction =
                        encode_r_type(
                            7'b0000000,
                            rs2,
                            rs1,
                            3'b100,
                            rd,
                            OPCODE_OP
                        );


                // SRL
                6:
                    random_r_type_instruction =
                        encode_r_type(
                            7'b0000000,
                            rs2,
                            rs1,
                            3'b101,
                            rd,
                            OPCODE_OP
                        );


                // SRA
                7:
                    random_r_type_instruction =
                        encode_r_type(
                            7'b0100000,
                            rs2,
                            rs1,
                            3'b101,
                            rd,
                            OPCODE_OP
                        );


                // OR
                8:
                    random_r_type_instruction =
                        encode_r_type(
                            7'b0000000,
                            rs2,
                            rs1,
                            3'b110,
                            rd,
                            OPCODE_OP
                        );


                // AND
                default:
                    random_r_type_instruction =
                        encode_r_type(
                            7'b0000000,
                            rs2,
                            rs1,
                            3'b111,
                            rd,
                            OPCODE_OP
                        );

            endcase

        end

    endfunction


    // ============================================================
    // RANDOM I-TYPE ALU INSTRUCTION
    //
    // Initial random generator includes:
    //
    // ADDI
    // SLTI
    // SLTIU
    // XORI
    // ORI
    // ANDI
    //
    // Shift-immediates are handled separately because their
    // immediate encoding is constrained.
    // ============================================================

    function automatic [31:0] random_i_type_instruction;

        integer operation;

        logic [4:0] rd;
        logic [4:0] rs1;

        logic signed [11:0] imm;

        begin

            rd =
                random_destination_register();

            rs1 =
                random_source_register();

            imm =
                random_i_immediate();

            operation =
                $urandom_range(0, 5);

            case (operation)

                // ADDI
                0:
                    random_i_type_instruction =
                        encode_i_type(
                            imm,
                            rs1,
                            3'b000,
                            rd,
                            OPCODE_OP_IMM
                        );


                // SLTI
                1:
                    random_i_type_instruction =
                        encode_i_type(
                            imm,
                            rs1,
                            3'b010,
                            rd,
                            OPCODE_OP_IMM
                        );


                // SLTIU
                2:
                    random_i_type_instruction =
                        encode_i_type(
                            imm,
                            rs1,
                            3'b011,
                            rd,
                            OPCODE_OP_IMM
                        );


                // XORI
                3:
                    random_i_type_instruction =
                        encode_i_type(
                            imm,
                            rs1,
                            3'b100,
                            rd,
                            OPCODE_OP_IMM
                        );


                // ORI
                4:
                    random_i_type_instruction =
                        encode_i_type(
                            imm,
                            rs1,
                            3'b110,
                            rd,
                            OPCODE_OP_IMM
                        );


                // ANDI
                default:
                    random_i_type_instruction =
                        encode_i_type(
                            imm,
                            rs1,
                            3'b111,
                            rd,
                            OPCODE_OP_IMM
                        );

            endcase

        end

    endfunction


    // ============================================================
    // RANDOM LOAD INSTRUCTION
    //
    // Initial whole-processor random testing uses LW only.
    //
    // This avoids false failures if byte/halfword memory semantics
    // have not yet been confirmed in the processor integration.
    // ============================================================

    function automatic [31:0] random_load_instruction;

        logic [4:0] rd;
        logic [4:0] rs1;

        logic signed [11:0] imm;

        begin

            rd =
                random_destination_register();

            rs1 =
                random_source_register();

            imm =
                random_memory_offset();

            random_load_instruction =
                encode_i_type(
                    imm,
                    rs1,
                    3'b010,
                    rd,
                    OPCODE_LOAD
                );

        end

    endfunction


    // ============================================================
    // RANDOM STORE INSTRUCTION
    //
    // Initial whole-processor random testing uses SW only.
    // ============================================================

    function automatic [31:0] random_store_instruction;

        logic [4:0] rs1;
        logic [4:0] rs2;

        logic signed [11:0] imm;

        begin

            rs1 =
                random_source_register();

            rs2 =
                random_source_register();

            imm =
                random_memory_offset();

            random_store_instruction =
                encode_s_type(
                    imm,
                    rs2,
                    rs1,
                    3'b010,
                    OPCODE_STORE
                );

        end

    endfunction


    // ============================================================
    // RANDOM LUI
    // ============================================================

    function automatic [31:0] random_lui_instruction;

        logic [4:0] rd;
        logic [19:0] imm20;

        begin

            rd =
                random_destination_register();

            imm20 =
                random_u_immediate();

            random_lui_instruction =
                encode_u_type(
                    imm20,
                    rd,
                    OPCODE_LUI
                );

        end

    endfunction


    // ============================================================
    // RANDOM AUIPC
    // ============================================================

    function automatic [31:0] random_auipc_instruction;

        logic [4:0] rd;
        logic [19:0] imm20;

        begin

            rd =
                random_destination_register();

            imm20 =
                random_u_immediate();

            random_auipc_instruction =
                encode_u_type(
                    imm20,
                    rd,
                    OPCODE_AUIPC
                );

        end

    endfunction

        // ============================================================
    // SECTION 18
    // RANDOM PROGRAM CONSTRUCTION
    // ============================================================


    // ============================================================
    // RANDOM PROGRAM CONFIGURATION
    // ============================================================

    localparam integer RANDOM_PROGRAM_LENGTH = 200;

    localparam integer RANDOM_ALU_WEIGHT     = 40;
    localparam integer RANDOM_IMM_WEIGHT     = 25;
    localparam integer RANDOM_LOAD_WEIGHT    = 10;
    localparam integer RANDOM_STORE_WEIGHT   = 10;
    localparam integer RANDOM_LUI_WEIGHT     = 8;
    localparam integer RANDOM_AUIPC_WEIGHT   = 7;


    // ============================================================
    // BUILD RANDOM STRAIGHT-LINE PROGRAM
    // ============================================================

    task automatic build_random_program;

        input integer program_length;

        integer index;
        integer instruction_class;

        logic [31:0] instruction;

        begin

            // ----------------------------------------------------
            // Clear existing program first
            // ----------------------------------------------------

            clear_program_memory();


            // ----------------------------------------------------
            // Generate instructions
            // ----------------------------------------------------

            for (
                index = 0;
                index < program_length;
                index = index + 1
            ) begin


                // ------------------------------------------------
                // Weighted random selection
                //
                // Range: 0 to 99
                // ------------------------------------------------

                instruction_class =
                    $urandom_range(0, 99);


                // ------------------------------------------------
                // R-TYPE ALU
                // 0 - 39
                // ------------------------------------------------

                if (
                    instruction_class <
                    RANDOM_ALU_WEIGHT
                ) begin

                    instruction =
                        random_r_type_instruction();

                end


                // ------------------------------------------------
                // I-TYPE ALU
                // 40 - 64
                // ------------------------------------------------

                else if (
                    instruction_class <
                    (
                        RANDOM_ALU_WEIGHT +
                        RANDOM_IMM_WEIGHT
                    )
                ) begin

                    instruction =
                        random_i_type_instruction();

                end


                // ------------------------------------------------
                // LOAD
                // 65 - 74
                // ------------------------------------------------

                else if (
                    instruction_class <
                    (
                        RANDOM_ALU_WEIGHT +
                        RANDOM_IMM_WEIGHT +
                        RANDOM_LOAD_WEIGHT
                    )
                ) begin

                    instruction =
                        random_load_instruction();

                end


                // ------------------------------------------------
                // STORE
                // 75 - 84
                // ------------------------------------------------

                else if (
                    instruction_class <
                    (
                        RANDOM_ALU_WEIGHT +
                        RANDOM_IMM_WEIGHT +
                        RANDOM_LOAD_WEIGHT +
                        RANDOM_STORE_WEIGHT
                    )
                ) begin

                    instruction =
                        random_store_instruction();

                end


                // ------------------------------------------------
                // LUI
                // ------------------------------------------------

                else if (
                    instruction_class <
                    (
                        RANDOM_ALU_WEIGHT +
                        RANDOM_IMM_WEIGHT +
                        RANDOM_LOAD_WEIGHT +
                        RANDOM_STORE_WEIGHT +
                        RANDOM_LUI_WEIGHT
                    )
                ) begin

                    instruction =
                        random_lui_instruction();

                end


                // ------------------------------------------------
                // AUIPC
                // ------------------------------------------------

                else begin

                    instruction =
                        random_auipc_instruction();

                end


                // ------------------------------------------------
                // Load into both program images
                // ------------------------------------------------

                load_program_instruction(
                    index * 4,
                    instruction
                );

            end

        end

    endtask

        // ============================================================
    // INSERT FORWARDING DEPENDENCY SEQUENCE
    // ============================================================

    task automatic insert_dependency_sequence;

        input integer start_index;

        logic [4:0] reg_a;
        logic [4:0] reg_b;
        logic [4:0] reg_c;

        begin

            reg_a =
                random_destination_register();

            reg_b =
                random_destination_register();

            reg_c =
                random_destination_register();


            // ----------------------------------------------------
            // reg_a = x0 + random immediate
            // ----------------------------------------------------

            load_program_instruction(
                (start_index + 0) * 4,

                encode_i_type(
                    random_i_immediate(),
                    5'd0,
                    3'b000,
                    reg_a,
                    OPCODE_OP_IMM
                )
            );


            // ----------------------------------------------------
            // reg_b = reg_a + random immediate
            //
            // RAW dependency
            // ----------------------------------------------------

            load_program_instruction(
                (start_index + 1) * 4,

                encode_i_type(
                    random_i_immediate(),
                    reg_a,
                    3'b000,
                    reg_b,
                    OPCODE_OP_IMM
                )
            );


            // ----------------------------------------------------
            // reg_c = reg_b + reg_a
            //
            // Back-to-back dependency chain
            // ----------------------------------------------------

            load_program_instruction(
                (start_index + 2) * 4,

                encode_r_type(
                    7'b0000000,
                    reg_a,
                    reg_b,
                    3'b000,
                    reg_c,
                    OPCODE_OP
                )
            );

        end

    endtask

        // ============================================================
    // SECTION 19
    // SAFE RANDOM MEMORY ADDRESSING
    // ============================================================


    // ============================================================
    // RESERVED REGISTER USED AS RANDOM TEST MEMORY BASE
    //
    // x30 is reserved only inside generated random programs.
    //
    // The program initializes:
    //
    // x30 = 0
    //
    // All generated LW/SW operations use x30 as rs1.
    // ============================================================

    localparam [4:0] RANDOM_MEM_BASE_REG = 5'd30;


    // ============================================================
    // RANDOM ALIGNED WORD OFFSET
    //
    // RISC-V load/store immediates are byte offsets.
    //
    // The returned offset is:
    //
    // 0, 4, 8, 12, ...
    //
    // Limited by both:
    //
    // DATA_MEM_DEPTH
    // signed 12-bit immediate range
    // ============================================================

    function automatic signed [11:0] random_safe_memory_offset;

        integer max_word_index;
        integer random_word_index;

        begin

            // ----------------------------------------------------
            // Maximum positive byte offset representable by
            // a signed 12-bit immediate is 2047.
            //
            // Largest aligned positive offset is therefore 2044.
            // ----------------------------------------------------

            max_word_index = DATA_MEM_DEPTH - 1;


            if (max_word_index > 511) begin

                max_word_index = 511;

            end


            random_word_index =
                $urandom_range(
                    0,
                    max_word_index
                );


            random_safe_memory_offset =
                random_word_index * 4;

        end

    endfunction

        // ============================================================
    // INITIALIZE RANDOM PROGRAM MEMORY BASE
    //
    // ADDI x30, x0, 0
    //
    // x30 becomes the base address used by generated LW/SW.
    // ============================================================

    task automatic initialize_random_memory_base;

        input integer program_index;

        begin

            load_program_instruction(

                program_index * 4,

                encode_i_type(
                    12'd0,
                    5'd0,
                    3'b000,
                    RANDOM_MEM_BASE_REG,
                    OPCODE_OP_IMM
                )

            );

        end

    endtask

        // ============================================================
    // RANDOM SAFE LOAD
    //
    // LW rd, offset(x30)
    //
    // x30 is the controlled memory base register.
    // ============================================================

    function automatic [31:0] random_load_instruction;

        logic [4:0] rd;

        logic signed [11:0] imm;

        begin

            rd =
                random_destination_register();

            // Avoid using x30 as destination because x30 is
            // reserved as the memory base register.
            while (
                rd == RANDOM_MEM_BASE_REG
            ) begin

                rd =
                    random_destination_register();

            end


            imm =
                random_safe_memory_offset();


            random_load_instruction =
                encode_i_type(
                    imm,
                    RANDOM_MEM_BASE_REG,
                    3'b010,
                    rd,
                    OPCODE_LOAD
                );

        end

    endfunction

        // ============================================================
    // RANDOM SAFE STORE
    //
    // SW rs2, offset(x30)
    // ============================================================

    function automatic [31:0] random_store_instruction;

        logic [4:0] rs2;

        logic signed [11:0] imm;

        begin

            rs2 =
                random_source_register();

            imm =
                random_safe_memory_offset();


            random_store_instruction =
                encode_s_type(
                    imm,
                    rs2,
                    RANDOM_MEM_BASE_REG,
                    3'b010,
                    OPCODE_STORE
                );

        end

    endfunction

        // ============================================================
    // INSERT STORE -> LOAD SEQUENCE
    // ============================================================

    task automatic insert_store_load_sequence;

        input integer start_index;

        logic [4:0] data_reg;
        logic [4:0] load_reg;

        logic signed [11:0] offset;

        logic signed [11:0] value;

        begin

            data_reg =
                random_destination_register();

            while (
                data_reg == RANDOM_MEM_BASE_REG
            ) begin

                data_reg =
                    random_destination_register();

            end


            load_reg =
                random_destination_register();

            while (
                (load_reg == RANDOM_MEM_BASE_REG) ||
                (load_reg == data_reg)
            ) begin

                load_reg =
                    random_destination_register();

            end


            offset =
                random_safe_memory_offset();

            value =
                random_i_immediate();


            // ----------------------------------------------------
            // ADDI data_reg, x0, value
            // ----------------------------------------------------

            load_program_instruction(

                (start_index + 0) * 4,

                encode_i_type(
                    value,
                    5'd0,
                    3'b000,
                    data_reg,
                    OPCODE_OP_IMM
                )

            );


            // ----------------------------------------------------
            // SW data_reg, offset(x30)
            // ----------------------------------------------------

            load_program_instruction(

                (start_index + 1) * 4,

                encode_s_type(
                    offset,
                    data_reg,
                    RANDOM_MEM_BASE_REG,
                    3'b010,
                    OPCODE_STORE
                )

            );


            // ----------------------------------------------------
            // LW load_reg, offset(x30)
            // ----------------------------------------------------

            load_program_instruction(

                (start_index + 2) * 4,

                encode_i_type(
                    offset,
                    RANDOM_MEM_BASE_REG,
                    3'b010,
                    load_reg,
                    OPCODE_LOAD
                )

            );

        end

    endtask

        // ============================================================
    // INSERT LOAD -> ALU IMMEDIATE DEPENDENCY
    // ============================================================

    task automatic insert_load_use_i_dependency;

        input integer start_index;

        logic [4:0] load_reg;
        logic [4:0] result_reg;

        logic signed [11:0] offset;
        logic signed [11:0] imm;

        begin

            load_reg =
                random_destination_register();

            while (
                load_reg == RANDOM_MEM_BASE_REG
            ) begin

                load_reg =
                    random_destination_register();

            end


            result_reg =
                random_destination_register();

            while (
                (result_reg == RANDOM_MEM_BASE_REG) ||
                (result_reg == load_reg)
            ) begin

                result_reg =
                    random_destination_register();

            end


            offset =
                random_safe_memory_offset();

            imm =
                random_i_immediate();


            // ----------------------------------------------------
            // LW load_reg, offset(x30)
            // ----------------------------------------------------

            load_program_instruction(

                (start_index + 0) * 4,

                encode_i_type(
                    offset,
                    RANDOM_MEM_BASE_REG,
                    3'b010,
                    load_reg,
                    OPCODE_LOAD
                )

            );


            // ----------------------------------------------------
            // ADDI result_reg, load_reg, imm
            // ----------------------------------------------------

            load_program_instruction(

                (start_index + 1) * 4,

                encode_i_type(
                    imm,
                    load_reg,
                    3'b000,
                    result_reg,
                    OPCODE_OP_IMM
                )

            );

        end

    endtask

        // ============================================================
    // INSERT LOAD -> R-TYPE DEPENDENCY
    // ============================================================

    task automatic insert_load_use_r_dependency;

        input integer start_index;

        logic [4:0] load_reg;
        logic [4:0] source_reg;
        logic [4:0] result_reg;

        logic signed [11:0] offset;

        begin

            load_reg =
                random_destination_register();

            while (
                load_reg == RANDOM_MEM_BASE_REG
            ) begin

                load_reg =
                    random_destination_register();

            end


            source_reg =
                random_source_register();

            while (
                source_reg == RANDOM_MEM_BASE_REG
            ) begin

                source_reg =
                    random_source_register();

            end


            result_reg =
                random_destination_register();

            while (
                (result_reg == RANDOM_MEM_BASE_REG) ||
                (result_reg == load_reg)
            ) begin

                result_reg =
                    random_destination_register();

            end


            offset =
                random_safe_memory_offset();


            // ----------------------------------------------------
            // LW load_reg, offset(x30)
            // ----------------------------------------------------

            load_program_instruction(

                (start_index + 0) * 4,

                encode_i_type(
                    offset,
                    RANDOM_MEM_BASE_REG,
                    3'b010,
                    load_reg,
                    OPCODE_LOAD
                )

            );


            // ----------------------------------------------------
            // ADD result_reg, load_reg, source_reg
            // ----------------------------------------------------

            load_program_instruction(

                (start_index + 1) * 4,

                encode_r_type(
                    7'b0000000,
                    source_reg,
                    load_reg,
                    3'b000,
                    result_reg,
                    OPCODE_OP
                )

            );

        end

    endtask

        // ============================================================
    // INSERT MEMORY OVERWRITE SEQUENCE
    // ============================================================

    task automatic insert_memory_overwrite_sequence;

        input integer start_index;

        logic [4:0] data_reg;
        logic [4:0] load_reg;

        logic signed [11:0] offset;

        logic signed [11:0] value1;
        logic signed [11:0] value2;

        begin

            data_reg =
                random_destination_register();

            while (
                data_reg == RANDOM_MEM_BASE_REG
            ) begin

                data_reg =
                    random_destination_register();

            end


            load_reg =
                random_destination_register();

            while (
                (load_reg == RANDOM_MEM_BASE_REG) ||
                (load_reg == data_reg)
            ) begin

                load_reg =
                    random_destination_register();

            end


            offset =
                random_safe_memory_offset();

            value1 =
                random_i_immediate();

            value2 =
                random_i_immediate();


            // ADDI data_reg, x0, value1

            load_program_instruction(

                (start_index + 0) * 4,

                encode_i_type(
                    value1,
                    5'd0,
                    3'b000,
                    data_reg,
                    OPCODE_OP_IMM
                )

            );


            // SW data_reg, offset(x30)

            load_program_instruction(

                (start_index + 1) * 4,

                encode_s_type(
                    offset,
                    data_reg,
                    RANDOM_MEM_BASE_REG,
                    3'b010,
                    OPCODE_STORE
                )

            );


            // ADDI data_reg, x0, value2

            load_program_instruction(

                (start_index + 2) * 4,

                encode_i_type(
                    value2,
                    5'd0,
                    3'b000,
                    data_reg,
                    OPCODE_OP_IMM
                )

            );


            // SW data_reg, offset(x30)

            load_program_instruction(

                (start_index + 3) * 4,

                encode_s_type(
                    offset,
                    data_reg,
                    RANDOM_MEM_BASE_REG,
                    3'b010,
                    OPCODE_STORE
                )

            );


            // LW load_reg, offset(x30)

            load_program_instruction(

                (start_index + 4) * 4,

                encode_i_type(
                    offset,
                    RANDOM_MEM_BASE_REG,
                    3'b010,
                    load_reg,
                    OPCODE_LOAD
                )

            );

        end

    endtask

        // ============================================================
    // BUILD RANDOM MEMORY HAZARD PROGRAM
    // ============================================================

    task automatic build_random_memory_hazard_program;

        integer index;

        begin

            // ----------------------------------------------------
            // Start from clean program memory
            // ----------------------------------------------------

            clear_program_memory();


            // ----------------------------------------------------
            // x30 = 0
            // ----------------------------------------------------

            initialize_random_memory_base(0);


            index = 1;


            // ----------------------------------------------------
            // Generate repeated memory stress sequences
            // ----------------------------------------------------

            while (
                index < (RANDOM_PROGRAM_LENGTH - 6)
            ) begin

                case (
                    $urandom_range(0, 3)
                )


                    // --------------------------------------------
                    // Store -> Load
                    // Uses 3 instructions
                    // --------------------------------------------

                    0:
                    begin

                        insert_store_load_sequence(
                            index
                        );

                        index =
                            index + 3;

                    end


                    // --------------------------------------------
                    // Load -> Immediate dependency
                    // Uses 2 instructions
                    // --------------------------------------------

                    1:
                    begin

                        insert_load_use_i_dependency(
                            index
                        );

                        index =
                            index + 2;

                    end


                    // --------------------------------------------
                    // Load -> R-type dependency
                    // Uses 2 instructions
                    // --------------------------------------------

                    2:
                    begin

                        insert_load_use_r_dependency(
                            index
                        );

                        index =
                            index + 2;

                    end


                    // --------------------------------------------
                    // Memory overwrite
                    // Uses 5 instructions
                    // --------------------------------------------

                    default:
                    begin

                        insert_memory_overwrite_sequence(
                            index
                        );

                        index =
                            index + 5;

                    end

                endcase

            end


            // ----------------------------------------------------
            // Remaining program memory already contains NOPs
            // because clear_program_memory() initializes with NOP.
            // ----------------------------------------------------

        end

    endtask





        // ============================================================
    // SECTION 20
    // BOUNDED RANDOM CONTROL-FLOW GENERATION
    // ============================================================


    // ============================================================
    // CONTROL FLOW CONFIGURATION
    // ============================================================

    localparam integer MAX_FORWARD_BRANCH_WORDS = 8;
    localparam integer MAX_FORWARD_JAL_WORDS    = 8;


        // ============================================================
    // RANDOM BRANCH FUNCT3
    //
    // BEQ   000
    // BNE   001
    // BLT   100
    // BGE   101
    // BLTU  110
    // BGEU  111
    // ============================================================

    function automatic [2:0] random_branch_funct3;

        integer branch_type;

        begin

            branch_type =
                $urandom_range(0, 5);

            case (branch_type)

                0:
                    random_branch_funct3 =
                        3'b000;     // BEQ

                1:
                    random_branch_funct3 =
                        3'b001;     // BNE

                2:
                    random_branch_funct3 =
                        3'b100;     // BLT

                3:
                    random_branch_funct3 =
                        3'b101;     // BGE

                4:
                    random_branch_funct3 =
                        3'b110;     // BLTU

                default:
                    random_branch_funct3 =
                        3'b111;     // BGEU

            endcase

        end

    endfunction

        // ============================================================
    // SAFE FORWARD BRANCH OFFSET
    //
    // current_index = branch instruction word index
    // program_length = total number of valid program words
    //
    // Returns a positive aligned byte offset.
    // ============================================================

    function automatic signed [12:0]
    random_forward_branch_offset;

        input integer current_index;
        input integer program_length;

        integer max_words;
        integer jump_words;

        begin

            max_words =
                program_length -
                current_index -
                1;


            if (
                max_words >
                MAX_FORWARD_BRANCH_WORDS
            ) begin

                max_words =
                    MAX_FORWARD_BRANCH_WORDS;

            end


            // ----------------------------------------------------
            // If no forward target exists, return +4.
            //
            // Caller should avoid placing a branch at the final
            // program word.
            // ----------------------------------------------------

            if (
                max_words < 1
            ) begin

                jump_words =
                    1;

            end
            else begin

                jump_words =
                    $urandom_range(
                        1,
                        max_words
                    );

            end


            random_forward_branch_offset =
                jump_words * 4;

        end

    endfunction

        // ============================================================
    // GENERATE RANDOM FORWARD BRANCH
    //
    // The branch target always remains inside the generated
    // program when called with a valid current index.
    // ============================================================

    function automatic [31:0]
    random_branch_instruction;

        input integer current_index;
        input integer program_length;

        logic [4:0] rs1;
        logic [4:0] rs2;

        logic [2:0] funct3;

        logic signed [12:0] offset;

        begin

            rs1 =
                random_source_register();

            rs2 =
                random_source_register();

            funct3 =
                random_branch_funct3();

            offset =
                random_forward_branch_offset(
                    current_index,
                    program_length
                );


            random_branch_instruction =
                encode_b_type(
                    offset,
                    rs2,
                    rs1,
                    funct3,
                    OPCODE_BRANCH
                );

        end

    endfunction

        // ============================================================
    // SAFE FORWARD JAL OFFSET
    // ============================================================

    function automatic signed [20:0]
    random_forward_jal_offset;

        input integer current_index;
        input integer program_length;

        integer max_words;
        integer jump_words;

        begin

            max_words =
                program_length -
                current_index -
                1;


            if (
                max_words >
                MAX_FORWARD_JAL_WORDS
            ) begin

                max_words =
                    MAX_FORWARD_JAL_WORDS;

            end


            if (
                max_words < 1
            ) begin

                jump_words =
                    1;

            end
            else begin

                jump_words =
                    $urandom_range(
                        1,
                        max_words
                    );

            end


            random_forward_jal_offset =
                jump_words * 4;

        end

    endfunction

        // ============================================================
    // RANDOM FORWARD JAL
    //
    // JAL rd, forward_offset
    // ============================================================

    function automatic [31:0]
    random_jal_instruction;

        input integer current_index;
        input integer program_length;

        logic [4:0] rd;

        logic signed [20:0] offset;

        begin

            rd =
                random_destination_register();


            while (
                rd == RANDOM_MEM_BASE_REG
            ) begin

                rd =
                    random_destination_register();

            end


            offset =
                random_forward_jal_offset(
                    current_index,
                    program_length
                );


            random_jal_instruction =
                encode_j_type(
                    offset,
                    rd,
                    OPCODE_JAL
                );

        end

    endfunction

        // ============================================================
    // INSERT CONTROLLED FORWARD JALR SEQUENCE
    //
    // Instruction 0:
    //
    // ADDI target_reg, x0, target_address
    //
    // Instruction 1:
    //
    // JALR link_reg, target_reg, 0
    //
    // Target is always:
    //
    // - forward
    // - 4-byte aligned
    // - inside generated program
    // ============================================================

    task automatic insert_controlled_jalr_sequence;

        input integer start_index;
        input integer program_length;

        logic [4:0] target_reg;
        logic [4:0] link_reg;

        integer max_target_index;
        integer target_index;

        integer target_address;

        begin

            target_reg =
                random_destination_register();

            while (
                target_reg == RANDOM_MEM_BASE_REG
            ) begin

                target_reg =
                    random_destination_register();

            end


            link_reg =
                random_destination_register();

            while (
                (link_reg == RANDOM_MEM_BASE_REG) ||
                (link_reg == target_reg)
            ) begin

                link_reg =
                    random_destination_register();

            end


            // ----------------------------------------------------
            // Need at least:
            //
            // start_index     = ADDI
            // start_index + 1 = JALR
            //
            // Target must be beyond JALR.
            // ----------------------------------------------------

            max_target_index =
                program_length - 1;


            if (
                max_target_index >
                (start_index + MAX_FORWARD_JAL_WORDS)
            ) begin

                max_target_index =
                    start_index +
                    MAX_FORWARD_JAL_WORDS;

            end


            if (
                max_target_index <
                (start_index + 2)
            ) begin

                target_index =
                    start_index + 2;

            end
            else begin

                target_index =
                    $urandom_range(
                        start_index + 2,
                        max_target_index
                    );

            end


            target_address =
                target_index * 4;


            // ----------------------------------------------------
            // ADDI target_reg, x0, target_address
            // ----------------------------------------------------

            load_program_instruction(

                start_index * 4,

                encode_i_type(
                    target_address[11:0],
                    5'd0,
                    3'b000,
                    target_reg,
                    OPCODE_OP_IMM
                )

            );


            // ----------------------------------------------------
            // JALR link_reg, target_reg, 0
            // ----------------------------------------------------

            load_program_instruction(

                (start_index + 1) * 4,

                encode_i_type(
                    12'd0,
                    target_reg,
                    3'b000,
                    link_reg,
                    OPCODE_JALR
                )

            );

        end

    endtask

        // ============================================================
    // BUILD RANDOM CONTROL-FLOW PROGRAM
    // ============================================================

    task automatic build_random_control_flow_program;

        input integer program_length;

        integer index;
        integer instruction_class;

        logic [31:0] instruction;

        begin

            clear_program_memory();


            // ----------------------------------------------------
            // Reserve x30 as memory base.
            // ----------------------------------------------------

            initialize_random_memory_base(0);


            index = 1;


            // ----------------------------------------------------
            // Keep final four locations as NOPs.
            // ----------------------------------------------------

            while (
                index <
                (program_length - 4)
            ) begin

                instruction_class =
                    $urandom_range(
                        0,
                        99
                    );


                // ------------------------------------------------
                // 0 - 34
                //
                // R-type ALU
                // ------------------------------------------------

                if (
                    instruction_class < 35
                ) begin

                    instruction =
                        random_r_type_instruction();


                    load_program_instruction(
                        index * 4,
                        instruction
                    );

                    index =
                        index + 1;

                end


                // ------------------------------------------------
                // 35 - 59
                //
                // I-type ALU
                // ------------------------------------------------

                else if (
                    instruction_class < 60
                ) begin

                    instruction =
                        random_i_type_instruction();


                    load_program_instruction(
                        index * 4,
                        instruction
                    );

                    index =
                        index + 1;

                end


                // ------------------------------------------------
                // 60 - 69
                //
                // Load
                // ------------------------------------------------

                else if (
                    instruction_class < 70
                ) begin

                    instruction =
                        random_load_instruction();


                    load_program_instruction(
                        index * 4,
                        instruction
                    );

                    index =
                        index + 1;

                end


                // ------------------------------------------------
                // 70 - 79
                //
                // Store
                // ------------------------------------------------

                else if (
                    instruction_class < 80
                ) begin

                    instruction =
                        random_store_instruction();


                    load_program_instruction(
                        index * 4,
                        instruction
                    );

                    index =
                        index + 1;

                end


                // ------------------------------------------------
                // 80 - 87
                //
                // Branch
                // ------------------------------------------------

                else if (
                    instruction_class < 88
                ) begin

                    instruction =
                        random_branch_instruction(
                            index,
                            program_length - 4
                        );


                    load_program_instruction(
                        index * 4,
                        instruction
                    );

                    index =
                        index + 1;

                end


                // ------------------------------------------------
                // 88 - 93
                //
                // JAL
                // ------------------------------------------------

                else if (
                    instruction_class < 94
                ) begin

                    instruction =
                        random_jal_instruction(
                            index,
                            program_length - 4
                        );


                    load_program_instruction(
                        index * 4,
                        instruction
                    );

                    index =
                        index + 1;

                end


                // ------------------------------------------------
                // 94 - 97
                //
                // Controlled JALR
                //
                // Needs two program words.
                // ------------------------------------------------

                else if (
                    instruction_class < 98
                ) begin

                    if (
                        index <
                        (program_length - 6)
                    ) begin

                        insert_controlled_jalr_sequence(
                            index,
                            program_length - 4
                        );


                        index =
                            index + 2;

                    end
                    else begin

                        instruction =
                            random_i_type_instruction();


                        load_program_instruction(
                            index * 4,
                            instruction
                        );


                        index =
                            index + 1;

                    end

                end


                // ------------------------------------------------
                // 98 - 99
                //
                // U-type
                // ------------------------------------------------

                else begin

                    if (
                        $urandom_range(0, 1) == 0
                    ) begin

                        instruction =
                            random_lui_instruction();

                    end
                    else begin

                        instruction =
                            random_auipc_instruction();

                    end


                    load_program_instruction(
                        index * 4,
                        instruction
                    );


                    index =
                        index + 1;

                end

            end

        end

    endtask

        // ============================================================
    // SECTION 21
    // PC-DRIVEN REFERENCE EXECUTION CONTROLLER
    // ============================================================


    localparam [31:0] RV32I_NOP = 32'h00000013;


    // ------------------------------------------------------------
    // Safety bound.
    //
    // The generated control-flow program contains only forward
    // branches/jumps, so execution should naturally terminate.
    //
    // This bound exists only to prevent the testbench from hanging
    // forever if either:
    //
    // 1. a generator bug creates unexpected control flow
    // 2. the reference model is modified incorrectly
    //
    // It is NOT used as an expected DUT cycle count.
    // ------------------------------------------------------------

    localparam integer REFERENCE_MAX_STEPS_MULTIPLIER = 4;

        // ============================================================
    // REFERENCE BRANCH DECISION
    // ============================================================

    function automatic logic reference_branch_taken;

        input logic [2:0]  funct3;

        input logic [31:0] rs1_value;

        input logic [31:0] rs2_value;

        begin

            case (funct3)

                // BEQ
                3'b000:
                begin

                    reference_branch_taken =
                        (rs1_value == rs2_value);

                end


                // BNE
                3'b001:
                begin

                    reference_branch_taken =
                        (rs1_value != rs2_value);

                end


                // BLT
                3'b100:
                begin

                    reference_branch_taken =
                        ($signed(rs1_value) <
                         $signed(rs2_value));

                end


                // BGE
                3'b101:
                begin

                    reference_branch_taken =
                        ($signed(rs1_value) >=
                         $signed(rs2_value));

                end


                // BLTU
                3'b110:
                begin

                    reference_branch_taken =
                        (rs1_value < rs2_value);

                end


                // BGEU
                3'b111:
                begin

                    reference_branch_taken =
                        (rs1_value >= rs2_value);

                end


                default:
                begin

                    reference_branch_taken =
                        1'b0;

                end

            endcase

        end

    endfunction

        // ============================================================
    // REFERENCE WORD LOAD
    // ============================================================

    function automatic [31:0] reference_memory_load_word;

        input logic [31:0] byte_address;

        integer word_index;

        begin

            word_index =
                byte_address >> 2;


            // ----------------------------------------------------
            // Do not silently wrap an illegal address.
            //
            // A wraparound here would hide an RTL address bug.
            // ----------------------------------------------------

            if (
                (word_index < 0) ||
                (word_index >= DATA_MEM_DEPTH)
            ) begin

                $error(
                    "REFERENCE MODEL MEMORY READ OUT OF RANGE | ADDR=%h INDEX=%0d",
                    byte_address,
                    word_index
                );

                reference_memory_load_word =
                    32'h00000000;

            end
            else begin

                reference_memory_load_word =
                    reference_data_memory[word_index];

            end

        end

    endfunction

        // ============================================================
    // REFERENCE WORD STORE
    // ============================================================

    task automatic reference_memory_store_word;

        input logic [31:0] byte_address;

        input logic [31:0] write_data;

        integer word_index;

        begin

            word_index =
                byte_address >> 2;


            // ----------------------------------------------------
            // Again, never silently wrap the address.
            // ----------------------------------------------------

            if (
                (word_index < 0) ||
                (word_index >= DATA_MEM_DEPTH)
            ) begin

                $error(
                    "REFERENCE MODEL MEMORY WRITE OUT OF RANGE | ADDR=%h INDEX=%0d DATA=%h",
                    byte_address,
                    word_index,
                    write_data
                );

            end
            else begin

                reference_data_memory[word_index] =
                    write_data;

            end

        end

    endtask

        // ============================================================
    // REFERENCE REGISTER READ
    // ============================================================

    function automatic [31:0] reference_register_read;

        input logic [4:0] register_index;

        begin

            if (
                register_index == 5'd0
            ) begin

                reference_register_read =
                    32'h00000000;

            end
            else begin

                reference_register_read =
                    reference_registers[
                        register_index
                    ];

            end

        end

    endfunction

        // ============================================================
    // REFERENCE REGISTER WRITE
    // ============================================================

    task automatic reference_register_write;

        input logic [4:0]  register_index;

        input logic [31:0] write_data;

        begin

            if (
                register_index != 5'd0
            ) begin

                reference_registers[
                    register_index
                ] =
                    write_data;

            end


            // Architectural x0 is always zero.

            reference_registers[0] =
                32'h00000000;

        end

    endtask


    // ============================================================
    // REFERENCE INSTRUCTION FETCH
    // ============================================================

    function automatic [31:0] reference_instruction_fetch;

        input logic [31:0] byte_pc;

        integer instruction_index;

        begin

            instruction_index =
                byte_pc >> 2;


            if (
                (instruction_index < 0) ||
                (instruction_index >= INSTR_MEM_DEPTH)
            ) begin

                reference_instruction_fetch =
                    RV32I_NOP;

            end
            else begin

                reference_instruction_fetch =
                    instruction_memory[
                        instruction_index
                    ];

            end

        end

    endfunction


    // ============================================================
    // EXECUTE ONE REFERENCE RV32I INSTRUCTION
    // ============================================================

    task automatic execute_reference_instruction;

        input  logic [31:0] current_pc;

        output logic [31:0] next_pc;

        output logic [31:0] executed_instruction;


        logic [6:0] opcode;
        logic [2:0] funct3;
        logic [6:0] funct7;

        logic [4:0] rs1;
        logic [4:0] rs2;
        logic [4:0] rd;


        logic [31:0] rs1_value;
        logic [31:0] rs2_value;


        logic signed [31:0] immediate_i;
        logic signed [31:0] immediate_s;
        logic signed [31:0] immediate_b;
        logic signed [31:0] immediate_j;
        logic signed [31:0] immediate_u;


        logic [31:0] result;

        logic [31:0] effective_address;

        logic branch_taken;


        begin

            // ----------------------------------------------------
            // FETCH
            // ----------------------------------------------------

            executed_instruction =
                reference_instruction_fetch(
                    current_pc
                );


            // ----------------------------------------------------
            // DECODE FIELDS
            // ----------------------------------------------------

            opcode =
                executed_instruction[6:0];

            rd =
                executed_instruction[11:7];

            funct3 =
                executed_instruction[14:12];

            rs1 =
                executed_instruction[19:15];

            rs2 =
                executed_instruction[24:20];

            funct7 =
                executed_instruction[31:25];


            // ----------------------------------------------------
            // READ REGISTER OPERANDS
            // ----------------------------------------------------

            rs1_value =
                reference_register_read(
                    rs1
                );

            rs2_value =
                reference_register_read(
                    rs2
                );


            // ----------------------------------------------------
            // DEFAULT NEXT PC
            // ----------------------------------------------------

            next_pc =
                current_pc + 32'd4;


            result =
                32'h00000000;

            effective_address =
                32'h00000000;

            branch_taken =
                1'b0;


            // ----------------------------------------------------
            // IMMEDIATE GENERATION
            // ----------------------------------------------------

            immediate_i =
                $signed({
                    {20{
                        executed_instruction[31]
                    }},
                    executed_instruction[31:20]
                });


            immediate_s =
                $signed({
                    {20{
                        executed_instruction[31]
                    }},
                    executed_instruction[31:25],
                    executed_instruction[11:7]
                });


            immediate_b =
                $signed({
                    {19{
                        executed_instruction[31]
                    }},
                    executed_instruction[31],
                    executed_instruction[7],
                    executed_instruction[30:25],
                    executed_instruction[11:8],
                    1'b0
                });


            immediate_u =
                $signed({
                    executed_instruction[31:12],
                    12'b000000000000
                });


            immediate_j =
                $signed({
                    {11{
                        executed_instruction[31]
                    }},
                    executed_instruction[31],
                    executed_instruction[19:12],
                    executed_instruction[20],
                    executed_instruction[30:21],
                    1'b0
                });


            // ====================================================
            // EXECUTE
            // ====================================================

            case (opcode)


                // =================================================
                // R-TYPE
                // =================================================

                OPCODE_OP:
                begin

                    case (funct3)

                        // ADD / SUB

                        3'b000:
                        begin

                            if (
                                funct7 == 7'b0000000
                            ) begin

                                result =
                                    rs1_value +
                                    rs2_value;

                            end
                            else if (
                                funct7 == 7'b0100000
                            ) begin

                                result =
                                    rs1_value -
                                    rs2_value;

                            end

                        end


                        // SLL

                        3'b001:
                        begin

                            result =
                                rs1_value <<
                                rs2_value[4:0];

                        end


                        // SLT

                        3'b010:
                        begin

                            result =
                                (
                                    $signed(rs1_value) <
                                    $signed(rs2_value)
                                );

                        end


                        // SLTU

                        3'b011:
                        begin

                            result =
                                (
                                    rs1_value <
                                    rs2_value
                                );

                        end


                        // XOR

                        3'b100:
                        begin

                            result =
                                rs1_value ^
                                rs2_value;

                        end


                        // SRL / SRA

                        3'b101:
                        begin

                            if (
                                funct7 == 7'b0000000
                            ) begin

                                result =
                                    rs1_value >>
                                    rs2_value[4:0];

                            end
                            else if (
                                funct7 == 7'b0100000
                            ) begin

                                result =
                                    $signed(rs1_value) >>>
                                    rs2_value[4:0];

                            end

                        end


                        // OR

                        3'b110:
                        begin

                            result =
                                rs1_value |
                                rs2_value;

                        end


                        // AND

                        3'b111:
                        begin

                            result =
                                rs1_value &
                                rs2_value;

                        end


                        default:
                        begin

                            result =
                                32'h00000000;

                        end

                    endcase


                    reference_register_write(
                        rd,
                        result
                    );

                end


                // =================================================
                // I-TYPE ALU
                // =================================================

                OPCODE_OP_IMM:
                begin

                    case (funct3)


                        // ADDI

                        3'b000:
                        begin

                            result =
                                rs1_value +
                                immediate_i;

                        end


                        // SLTI

                        3'b010:
                        begin

                            result =
                                (
                                    $signed(rs1_value) <
                                    immediate_i
                                );

                        end


                        // SLTIU

                        3'b011:
                        begin

                            result =
                                (
                                    rs1_value <
                                    $unsigned(immediate_i)
                                );

                        end


                        // XORI

                        3'b100:
                        begin

                            result =
                                rs1_value ^
                                immediate_i;

                        end


                        // ORI

                        3'b110:
                        begin

                            result =
                                rs1_value |
                                immediate_i;

                        end


                        // ANDI

                        3'b111:
                        begin

                            result =
                                rs1_value &
                                immediate_i;

                        end


                        // SLLI

                        3'b001:
                        begin

                            result =
                                rs1_value <<
                                executed_instruction[24:20];

                        end


                        // SRLI / SRAI

                        3'b101:
                        begin

                            if (
                                executed_instruction[31:25] ==
                                7'b0000000
                            ) begin

                                result =
                                    rs1_value >>
                                    executed_instruction[24:20];

                            end
                            else if (
                                executed_instruction[31:25] ==
                                7'b0100000
                            ) begin

                                result =
                                    $signed(rs1_value) >>>
                                    executed_instruction[24:20];

                            end

                        end


                        default:
                        begin

                            result =
                                32'h00000000;

                        end

                    endcase


                    reference_register_write(
                        rd,
                        result
                    );

                end


                // =================================================
                // LOAD
                //
                // Current random generator produces LW.
                // =================================================

                OPCODE_LOAD:
                begin

                    effective_address =
                        rs1_value +
                        immediate_i;


                    case (funct3)


                        // LW

                        3'b010:
                        begin

                            result =
                                reference_memory_load_word(
                                    effective_address
                                );


                            reference_register_write(
                                rd,
                                result
                            );

                        end


                        default:
                        begin

                            $error(
                                "REFERENCE MODEL: unsupported LOAD funct3=%b PC=%h",
                                funct3,
                                current_pc
                            );

                        end

                    endcase

                end


                // =================================================
                // STORE
                //
                // Current random generator produces SW.
                // =================================================

                OPCODE_STORE:
                begin

                    effective_address =
                        rs1_value +
                        immediate_s;


                    case (funct3)


                        // SW

                        3'b010:
                        begin

                            reference_memory_store_word(
                                effective_address,
                                rs2_value
                            );

                        end


                        default:
                        begin

                            $error(
                                "REFERENCE MODEL: unsupported STORE funct3=%b PC=%h",
                                funct3,
                                current_pc
                            );

                        end

                    endcase

                end


                // =================================================
                // BRANCH
                // =================================================

                OPCODE_BRANCH:
                begin

                    branch_taken =
                        reference_branch_taken(
                            funct3,
                            rs1_value,
                            rs2_value
                        );


                    if (
                        branch_taken
                    ) begin

                        next_pc =
                            current_pc +
                            immediate_b;

                    end

                end


                // =================================================
                // JAL
                // =================================================

                OPCODE_JAL:
                begin

                    reference_register_write(
                        rd,
                        current_pc + 32'd4
                    );


                    next_pc =
                        current_pc +
                        immediate_j;

                end


                // =================================================
                // JALR
                // =================================================

                OPCODE_JALR:
                begin

                    if (
                        funct3 == 3'b000
                    ) begin

                        reference_register_write(
                            rd,
                            current_pc + 32'd4
                        );


                        // RISC-V clears bit 0 of JALR target.

                        next_pc =
                            (
                                rs1_value +
                                immediate_i
                            )
                            &
                            32'hFFFFFFFE;

                    end
                    else begin

                        $error(
                            "REFERENCE MODEL: invalid JALR funct3=%b PC=%h",
                            funct3,
                            current_pc
                        );

                    end

                end


                // =================================================
                // LUI
                // =================================================

                OPCODE_LUI:
                begin

                    reference_register_write(
                        rd,
                        immediate_u
                    );

                end


                // =================================================
                // AUIPC
                // =================================================

                OPCODE_AUIPC:
                begin

                    reference_register_write(
                        rd,
                        current_pc +
                        immediate_u
                    );

                end


                // =================================================
                // NOP / unsupported opcode
                // =================================================

                default:
                begin

                    // ------------------------------------------------
                    // Treat unknown instruction as architectural
                    // no-operation for the current generated program.
                    //
                    // If later we deliberately test illegal
                    // instruction behaviour, that should have its own
                    // dedicated test section.
                    // ------------------------------------------------

                end

            endcase


            // ----------------------------------------------------
            // Guarantee architectural x0.
            // ----------------------------------------------------

            reference_registers[0] =
                32'h00000000;

        end

    endtask

        // ============================================================
    // EXECUTE REFERENCE PROGRAM
    //
    // The program is terminated architecturally when:
    //
    // reference PC reaches program_length * 4.
    //
    // Since generated branches and jumps are forward-only,
    // execution should naturally reach the end.
    // ============================================================

    task automatic execute_reference_control_flow_program;

        input integer program_length;


        logic [31:0] reference_pc;

        logic [31:0] next_reference_pc;

        logic [31:0] executed_instruction;


        integer executed_instruction_count;

        integer maximum_execution_steps;


        begin

            reference_pc =
                32'h00000000;


            executed_instruction_count =
                0;


            maximum_execution_steps =
                program_length *
                REFERENCE_MAX_STEPS_MULTIPLIER;


            // ----------------------------------------------------
            // Execute while PC points inside active program region.
            // ----------------------------------------------------

            while (

                (reference_pc <
                 (program_length * 4))

                &&

                (executed_instruction_count <
                 maximum_execution_steps)

            ) begin


                execute_reference_instruction(

                    reference_pc,

                    next_reference_pc,

                    executed_instruction

                );


                // ------------------------------------------------
                // Optional trace.
                //
                // Keep commented during large regressions.
                // ------------------------------------------------

                /*
                $display(
                    "REF EXEC | STEP=%0d PC=%h INSTR=%h NEXT_PC=%h",
                    executed_instruction_count,
                    reference_pc,
                    executed_instruction,
                    next_reference_pc
                );
                */


                reference_pc =
                    next_reference_pc;


                executed_instruction_count =
                    executed_instruction_count + 1;

            end


            // ----------------------------------------------------
            // Safety failure.
            // ----------------------------------------------------

            if (
                executed_instruction_count >=
                maximum_execution_steps
            ) begin

                $error(
                    "REFERENCE MODEL EXECUTION LIMIT EXCEEDED | STEPS=%0d MAX=%0d PC=%h",
                    executed_instruction_count,
                    maximum_execution_steps,
                    reference_pc
                );

                fail_count =
                    fail_count + 1;

            end


            // ----------------------------------------------------
            // Program should not stop because of an unexpected
            // invalid PC inside the program.
            // ----------------------------------------------------

            if (
                reference_pc <
                (program_length * 4)
            ) begin

                $error(
                    "REFERENCE MODEL DID NOT REACH PROGRAM END | PC=%h END=%h",
                    reference_pc,
                    program_length * 4
                );

                fail_count =
                    fail_count + 1;

            end

        end

    endtask

        // ============================================================
    // EXECUTE REFERENCE PROGRAM
    //
    // The program is terminated architecturally when:
    //
    // reference PC reaches program_length * 4.
    //
    // Since generated branches and jumps are forward-only,
    // execution should naturally reach the end.
    // ============================================================

    task automatic execute_reference_control_flow_program;

        input integer program_length;


        logic [31:0] reference_pc;

        logic [31:0] next_reference_pc;

        logic [31:0] executed_instruction;


        integer executed_instruction_count;

        integer maximum_execution_steps;


        begin

            reference_pc =
                32'h00000000;


            executed_instruction_count =
                0;


            maximum_execution_steps =
                program_length *
                REFERENCE_MAX_STEPS_MULTIPLIER;


            // ----------------------------------------------------
            // Execute while PC points inside active program region.
            // ----------------------------------------------------

            while (

                (reference_pc <
                 (program_length * 4))

                &&

                (executed_instruction_count <
                 maximum_execution_steps)

            ) begin


                execute_reference_instruction(

                    reference_pc,

                    next_reference_pc,

                    executed_instruction

                );


                // ------------------------------------------------
                // Optional trace.
                //
                // Keep commented during large regressions.
                // ------------------------------------------------

                /*
                $display(
                    "REF EXEC | STEP=%0d PC=%h INSTR=%h NEXT_PC=%h",
                    executed_instruction_count,
                    reference_pc,
                    executed_instruction,
                    next_reference_pc
                );
                */


                reference_pc =
                    next_reference_pc;


                executed_instruction_count =
                    executed_instruction_count + 1;

            end


            // ----------------------------------------------------
            // Safety failure.
            // ----------------------------------------------------

            if (
                executed_instruction_count >=
                maximum_execution_steps
            ) begin

                $error(
                    "REFERENCE MODEL EXECUTION LIMIT EXCEEDED | STEPS=%0d MAX=%0d PC=%h",
                    executed_instruction_count,
                    maximum_execution_steps,
                    reference_pc
                );

                fail_count =
                    fail_count + 1;

            end


            // ----------------------------------------------------
            // Program should not stop because of an unexpected
            // invalid PC inside the program.
            // ----------------------------------------------------

            if (
                reference_pc <
                (program_length * 4)
            ) begin

                $error(
                    "REFERENCE MODEL DID NOT REACH PROGRAM END | PC=%h END=%h",
                    reference_pc,
                    program_length * 4
                );

                fail_count =
                    fail_count + 1;

            end

        end

    endtask

        // ============================================================
    // RANDOM CONTROL FLOW TEST FLOW
    // ============================================================

    clear_reference_state();

    clear_program_memory();

    build_random_control_flow_program(
        RANDOM_PROGRAM_LENGTH
    );


    execute_reference_control_flow_program(
        RANDOM_PROGRAM_LENGTH
    );


    reset_dut();


    run_dut_until_program_complete(
        RANDOM_PROGRAM_LENGTH
    );


    compare_final_architectural_state();


        // ============================================================
    // SECTION 22
    // DUT PROGRAM COMPLETION AND PIPELINE DRAIN
    // ============================================================


    // ------------------------------------------------------------
    // The DUT contains a pipelined datapath and the IF stage has
    // delayed synchronous instruction fetching.
    //
    // Therefore reaching the end of the program does NOT mean all
    // instructions have completed.
    // ------------------------------------------------------------

    localparam integer PIPELINE_DRAIN_CYCLES = 20;


    // ------------------------------------------------------------
    // Simulation safety limit.
    //
    // This is deliberately much larger than program length because
    // the DUT may incur:
    //
    // - two-cycle instruction fetch behaviour
    // - pipeline filling
    // - pipeline draining
    // - load-use stalls
    // - control-flow redirects
    // ------------------------------------------------------------

    localparam integer DUT_MAX_CYCLES_MULTIPLIER = 20;

        // ============================================================
    // CHECK WHETHER A PC IS OUTSIDE THE ACTIVE PROGRAM
    // ============================================================

    function automatic logic program_pc_finished;

        input logic [31:0] pc_value;

        input integer      program_length;

        begin

            if (
                pc_value >=
                (program_length * 4)
            ) begin

                program_pc_finished =
                    1'b1;

            end
            else begin

                program_pc_finished =
                    1'b0;

            end

        end

    endfunction

        // ============================================================
    // WAIT FOR ONE DUT CLOCK CYCLE
    // ============================================================

    task automatic wait_dut_cycle;

        begin

            @(posedge clk);

            // ----------------------------------------------------
            // Allow sequential DUT logic and testbench-connected
            // memory models to settle before the next check.
            // ----------------------------------------------------

            #1;

        end

    endtask

        // ============================================================
    // RUN DUT UNTIL PROGRAM COMPLETES
    // ============================================================

    task automatic run_dut_until_program_complete;

        input integer program_length;


        integer cycle_count;

        integer maximum_cycles;

        integer drain_count;

        logic program_end_seen;


        begin

            cycle_count =
                0;

            drain_count =
                0;

            program_end_seen =
                1'b0;


            maximum_cycles =
                (program_length *
                 DUT_MAX_CYCLES_MULTIPLIER)
                +
                PIPELINE_DRAIN_CYCLES;


            // ----------------------------------------------------
            // DUT EXECUTION LOOP
            // ----------------------------------------------------

            while (
                cycle_count <
                maximum_cycles
            ) begin


                wait_dut_cycle();


                cycle_count =
                    cycle_count + 1;


                // ------------------------------------------------
                // First observation of PC outside active program.
                //
                // We do NOT immediately terminate because older
                // instructions may still be:
                //
                // - in decode
                // - in execute
                // - in memory
                // - waiting for writeback
                //
                // Also the modified IF path may contain delayed
                // synchronous fetch state.
                // ------------------------------------------------

                if (
                    !program_end_seen
                ) begin

                    if (
                        program_pc_finished(
                            PCF,
                            program_length
                        )
                    ) begin

                        program_end_seen =
                            1'b1;

                        drain_count =
                            0;

                    end

                end


                // ------------------------------------------------
                // Pipeline drain period.
                // ------------------------------------------------

                else begin

                    drain_count =
                        drain_count + 1;


                    if (
                        drain_count >=
                        PIPELINE_DRAIN_CYCLES
                    ) begin

                        break;

                    end

                end

            end


            // ----------------------------------------------------
            // Completion diagnostics
            // ----------------------------------------------------

            if (
                !program_end_seen
            ) begin

                $error(
                    "DUT PROGRAM EXECUTION TIMEOUT | PROGRAM_WORDS=%0d MAX_CYCLES=%0d FINAL_PC=%h",
                    program_length,
                    maximum_cycles,
                    PCF
                );

                fail_count =
                    fail_count + 1;

            end


            if (
                cycle_count >=
                maximum_cycles
            ) begin

                $error(
                    "DUT MAXIMUM EXECUTION CYCLES REACHED | CYCLES=%0d MAX=%0d PC=%h",
                    cycle_count,
                    maximum_cycles,
                    PCF
                );

                fail_count =
                    fail_count + 1;

            end


            $display(
                "DUT PROGRAM COMPLETE | PROGRAM_WORDS=%0d CYCLES=%0d FINAL_PC=%h",
                program_length,
                cycle_count,
                PCF
            );

        end

    endtask

        // ============================================================
    // RANDOM CONTROL-FLOW PROCESSOR TEST
    // ============================================================

    clear_reference_state();

    clear_data_memory();

    clear_program_memory();


    // ------------------------------------------------------------
    // Generate identical initial memory/program state.
    // ------------------------------------------------------------

    initialize_random_data_memory();


    build_random_control_flow_program(
        RANDOM_PROGRAM_LENGTH
    );


    // ------------------------------------------------------------
    // Execute architectural golden model.
    // ------------------------------------------------------------

    execute_reference_control_flow_program(
        RANDOM_PROGRAM_LENGTH
    );


    // ------------------------------------------------------------
    // Reset DUT before architectural execution.
    // ------------------------------------------------------------

    reset_dut();


    // ------------------------------------------------------------
    // Execute DUT.
    // ------------------------------------------------------------

    run_dut_until_program_complete(
        RANDOM_PROGRAM_LENGTH
    );


    // ------------------------------------------------------------
    // Final architectural comparison.
    // ------------------------------------------------------------

    compare_final_register_state();

    compare_final_memory_state();

        // ============================================================
    // SECTION 23
    // ARCHITECTURAL SCOREBOARD
    // ============================================================


    integer register_compare_count;
    integer register_mismatch_count;

    integer memory_compare_count;
    integer memory_mismatch_count;

        // ============================================================
    // READ DUT ARCHITECTURAL REGISTER
    //
    // IMPORTANT:
    //
    // Replace ONLY the marked line with the exact verified DUT
    // register-file storage path from the integrated processor RTL.
    //
    // Do not create multiple scoreboard accesses throughout the TB.
    // ============================================================

    function automatic [31:0] dut_register_read;

        input integer register_index;

        begin

            if (
                register_index == 0
            ) begin

                dut_register_read =
                    32'h00000000;

            end
            else begin

                // ------------------------------------------------
                // RTL PATH ADAPTER
                //
                // Replace this identifier/path with the actual
                // register-file array path verified from your RTL.
                // ------------------------------------------------

                dut_register_read =
                    dut.register_file_instance.reg_array[
                        register_index
                    ];

            end

        end

    endfunction

    // ============================================================
    // COMPARE ONE ARCHITECTURAL REGISTER
    // ============================================================

    task automatic compare_single_register;

        input integer register_index;

        logic [31:0] expected_value;

        logic [31:0] actual_value;


        begin

            expected_value =
                reference_register_read(
                    register_index[4:0]
                );


            actual_value =
                dut_register_read(
                    register_index
                );


            register_compare_count =
                register_compare_count + 1;


            if (
                actual_value !==
                expected_value
            ) begin

                $error(
                    "REGISTER MISMATCH | X%0d | EXPECTED=%h | GOT=%h",
                    register_index,
                    expected_value,
                    actual_value
                );


                register_mismatch_count =
                    register_mismatch_count + 1;

            end

        end

    endtask

    // ============================================================
    // COMPARE COMPLETE ARCHITECTURAL REGISTER FILE
    // ============================================================

    task automatic compare_final_register_state;

        integer register_index;

        integer local_mismatch_count;


        begin

            local_mismatch_count =
                0;


            $display(
                ""
            );

            $display(
                "------------------------------------------------"
            );

            $display(
                "CHECKING FINAL REGISTER STATE"
            );

            $display(
                "------------------------------------------------"
            );


            for (
                register_index = 0;

                register_index < 32;

                register_index =
                register_index + 1
            ) begin

                compare_single_register(
                    register_index
                );

            end


            // ----------------------------------------------------
            // Architectural x0 sanity check.
            //
            // This is intentionally explicit even though x0 was
            // already compared above.
            // ----------------------------------------------------

            if (
                dut_register_read(0) !==
                32'h00000000
            ) begin

                $error(
                    "ARCHITECTURAL ERROR: DUT x0 IS NOT ZERO | VALUE=%h",
                    dut_register_read(0)
                );

                register_mismatch_count =
                    register_mismatch_count + 1;

            end


            // ----------------------------------------------------
            // Calculate mismatches produced during this comparison.
            // ----------------------------------------------------

            local_mismatch_count =
                register_mismatch_count;


            if (
                local_mismatch_count == 0
            ) begin

                $display(
                    "REGISTER SCOREBOARD: PASS"
                );

            end
            else begin

                $display(
                    "REGISTER SCOREBOARD: FAIL | MISMATCHES=%0d",
                    local_mismatch_count
                );

            end


            $display(
                "------------------------------------------------"
            );

        end

    endtask

    task automatic compare_final_register_state;

        integer register_index;

        integer mismatch_count_before;

        integer mismatch_count_after;


        begin

            mismatch_count_before =
                register_mismatch_count;


            $display("");

            $display(
                "------------------------------------------------"
            );

            $display(
                "CHECKING FINAL REGISTER STATE"
            );

            $display(
                "------------------------------------------------"
            );


            for (
                register_index = 0;

                register_index < 32;

                register_index =
                register_index + 1
            ) begin

                compare_single_register(
                    register_index
                );

            end


            // ----------------------------------------------------
            // Explicit x0 assertion.
            // ----------------------------------------------------

            assert (
                dut_register_read(0) ==
                32'h00000000
            )
            else begin

                $error(
                    "ASSERTION FAILED: DUT x0 changed | VALUE=%h",
                    dut_register_read(0)
                );

                register_mismatch_count =
                    register_mismatch_count + 1;

            end


            mismatch_count_after =
                register_mismatch_count;


            if (
                mismatch_count_after ==
                mismatch_count_before
            ) begin

                $display(
                    "REGISTER SCOREBOARD: PASS"
                );

            end
            else begin

                $display(
                    "REGISTER SCOREBOARD: FAIL | NEW_MISMATCHES=%0d",
                    mismatch_count_after -
                    mismatch_count_before
                );

            end


            $display(
                "------------------------------------------------"
            );

        end

    endtask

    // ============================================================
    // READ DUT DATA MEMORY WORD
    //
    // Replace ONLY the marked RTL hierarchy path after checking
    // the actual processor integration.
    // ============================================================

    function automatic [31:0] dut_memory_read_word;

        input integer word_index;

        begin

            // ----------------------------------------------------
            // RTL MEMORY PATH ADAPTER
            // ----------------------------------------------------

            dut_memory_read_word =
                dut.data_memory_instance.memory[
                    word_index
                ];

        end

    endfunction

        // ============================================================
    // COMPARE ONE DATA MEMORY WORD
    // ============================================================

    task automatic compare_single_memory_word;

        input integer word_index;


        logic [31:0] expected_value;

        logic [31:0] actual_value;


        begin

            expected_value =
                reference_data_memory[
                    word_index
                ];


            actual_value =
                dut_memory_read_word(
                    word_index
                );


            memory_compare_count =
                memory_compare_count + 1;


            if (
                actual_value !==
                expected_value
            ) begin

                $error(
                    "MEMORY MISMATCH | WORD=%0d | BYTE_ADDR=%h | EXPECTED=%h | GOT=%h",
                    word_index,
                    word_index * 4,
                    expected_value,
                    actual_value
                );


                memory_mismatch_count =
                    memory_mismatch_count + 1;

            end

        end

    endtask

        // ============================================================
    // COMPARE COMPLETE DATA MEMORY
    // ============================================================

    task automatic compare_final_memory_state;

        integer memory_index;

        integer mismatch_count_before;

        integer mismatch_count_after;


        begin

            mismatch_count_before =
                memory_mismatch_count;


            $display("");

            $display(
                "------------------------------------------------"
            );

            $display(
                "CHECKING FINAL DATA MEMORY STATE"
            );

            $display(
                "------------------------------------------------"
            );


            for (
                memory_index = 0;

                memory_index < DATA_MEM_DEPTH;

                memory_index =
                memory_index + 1
            ) begin

                compare_single_memory_word(
                    memory_index
                );

            end


            mismatch_count_after =
                memory_mismatch_count;


            if (
                mismatch_count_after ==
                mismatch_count_before
            ) begin

                $display(
                    "MEMORY SCOREBOARD: PASS"
                );

            end
            else begin

                $display(
                    "MEMORY SCOREBOARD: FAIL | NEW_MISMATCHES=%0d",
                    mismatch_count_after -
                    mismatch_count_before
                );

            end


            $display(
                "------------------------------------------------"
            );

        end

    endtask

        // ============================================================
    // COMPLETE ARCHITECTURAL SCOREBOARD
    // ============================================================

    task automatic compare_final_architectural_state;

        integer total_register_mismatches_before;

        integer total_memory_mismatches_before;

        integer total_register_mismatches_after;

        integer total_memory_mismatches_after;


        begin

            total_register_mismatches_before =
                register_mismatch_count;


            total_memory_mismatches_before =
                memory_mismatch_count;


            // ----------------------------------------------------
            // Register comparison.
            // ----------------------------------------------------

            compare_final_register_state();


            // ----------------------------------------------------
            // Memory comparison.
            // ----------------------------------------------------

            compare_final_memory_state();


            total_register_mismatches_after =
                register_mismatch_count;


            total_memory_mismatches_after =
                memory_mismatch_count;


            // ----------------------------------------------------
            // Final architectural result.
            // ----------------------------------------------------

            if (

                (total_register_mismatches_after ==
                 total_register_mismatches_before)

                &&

                (total_memory_mismatches_after ==
                 total_memory_mismatches_before)

            ) begin

                $display("");

                $display(
                    "================================================"
                );

                $display(
                    "ARCHITECTURAL SCOREBOARD: PASS"
                );

                $display(
                    "================================================"
                );

            end
            else begin

                $display("");

                $display(
                    "================================================"
                );

                $display(
                    "ARCHITECTURAL SCOREBOARD: FAIL"
                );

                $display(
                    "REGISTER MISMATCHES = %0d",
                    total_register_mismatches_after -
                    total_register_mismatches_before
                );

                $display(
                    "MEMORY MISMATCHES   = %0d",
                    total_memory_mismatches_after -
                    total_memory_mismatches_before
                );

                $display(
                    "================================================"
                );

            end

        end

    endtask

        // ============================================================
    // SECTION 24
    // DIRECTED FULL PROCESSOR TESTS
    // ============================================================


    task automatic run_directed_processor_test;

        input integer program_length;

        input string  test_name;


        integer fail_before;


        begin

            fail_before =
                fail_count
                +
                register_mismatch_count
                +
                memory_mismatch_count;


            $display("");
            $display("================================================");
            $display("DIRECTED PROCESSOR TEST");
            $display("TEST = %s", test_name);
            $display("PROGRAM WORDS = %0d", program_length);
            $display("================================================");


            // ----------------------------------------------------
            // Execute independent architectural reference model.
            // ----------------------------------------------------

            execute_reference_program(
                program_length
            );


            // ----------------------------------------------------
            // Reset processor before DUT execution.
            //
            // Program memory and initial data memory remain loaded.
            // ----------------------------------------------------

            reset_dut();


            // ----------------------------------------------------
            // Execute processor.
            // ----------------------------------------------------

            run_dut_until_program_complete(
                program_length
            );


            // ----------------------------------------------------
            // Compare final architectural state.
            // ----------------------------------------------------

            compare_final_architectural_state();


            // ----------------------------------------------------
            // Test result.
            // ----------------------------------------------------

            if (
                (
                    fail_count
                    +
                    register_mismatch_count
                    +
                    memory_mismatch_count
                )
                ==
                fail_before
            ) begin

                $display(
                    "******** DIRECTED TEST PASSED: %s ********",
                    test_name
                );

                pass_count =
                    pass_count + 1;

            end
            else begin

                $display(
                    "******** DIRECTED TEST FAILED: %s ********",
                    test_name
                );

                fail_count =
                    fail_count + 1;

            end

        end

    endtask

        // ============================================================
    // DIRECTED TEST:
    // BASIC ALU DATAFLOW
    // ============================================================

    task automatic test_directed_alu_dataflow;

        integer program_length;


        begin

            prepare_directed_program();


            // x1 = 10
            instruction_memory[0] =
                encode_addi(
                    5'd1,
                    5'd0,
                    10
                );


            // x2 = 20
            instruction_memory[1] =
                encode_addi(
                    5'd2,
                    5'd0,
                    20
                );


            // x3 = x1 + x2
            instruction_memory[2] =
                encode_add(
                    5'd3,
                    5'd1,
                    5'd2
                );


            // x4 = x3 - x1
            instruction_memory[3] =
                encode_sub(
                    5'd4,
                    5'd3,
                    5'd1
                );


            // x5 = x4 XOR x2
            instruction_memory[4] =
                encode_xor(
                    5'd5,
                    5'd4,
                    5'd2
                );


            program_length =
                5;


            run_directed_processor_test(
                program_length,
                "BASIC ALU DATAFLOW"
            );

        end

    endtask

        // ============================================================
    // DIRECTED TEST:
    // CONSECUTIVE RAW DEPENDENCIES
    // ============================================================

    task automatic test_directed_raw_dependency;

        integer program_length;


        begin

            prepare_directed_program();


            instruction_memory[0] =
                encode_addi(
                    5'd1,
                    5'd0,
                    5
                );


            // Immediately consumes x1
            instruction_memory[1] =
                encode_addi(
                    5'd2,
                    5'd1,
                    7
                );


            // Immediately consumes x2
            instruction_memory[2] =
                encode_add(
                    5'd3,
                    5'd2,
                    5'd1
                );


            // Immediately consumes x3
            instruction_memory[3] =
                encode_sub(
                    5'd4,
                    5'd3,
                    5'd2
                );


            // Immediately consumes x4
            instruction_memory[4] =
                encode_add(
                    5'd5,
                    5'd4,
                    5'd3
                );


            program_length =
                5;


            run_directed_processor_test(
                program_length,
                "CONSECUTIVE RAW DEPENDENCY"
            );

        end

    endtask

        // ============================================================
    // DIRECTED TEST:
    // LOAD-USE DEPENDENCY
    // ============================================================

    task automatic test_directed_load_use;

        integer program_length;


        begin

            prepare_directed_program();


            // ----------------------------------------------------
            // DATA MEMORY INITIALIZATION
            // ----------------------------------------------------

            data_memory[0] =
                32'd100;


            // ----------------------------------------------------
            // PROGRAM
            // ----------------------------------------------------


            // x1 = 0
            instruction_memory[0] =
                encode_addi(
                    5'd1,
                    5'd0,
                    0
                );


            // x2 = MEM[x1 + 0]
            instruction_memory[1] =
                encode_lw(
                    5'd2,
                    5'd1,
                    0
                );


            // Immediately consume loaded x2.
            //
            // x3 = x2 + 1
            instruction_memory[2] =
                encode_addi(
                    5'd3,
                    5'd2,
                    1
                );


            // Another dependent operation.
            instruction_memory[3] =
                encode_add(
                    5'd4,
                    5'd3,
                    5'd2
                );


            program_length =
                4;


            run_directed_processor_test(
                program_length,
                "LOAD USE HAZARD"
            );

        end

    endtask

        // ============================================================
    // DIRECTED TEST:
    // STORE DATA DEPENDENCY
    // ============================================================

    task automatic test_directed_store_dependency;

        integer program_length;


        begin

            prepare_directed_program();


            // x1 = base address 0
            instruction_memory[0] =
                encode_addi(
                    5'd1,
                    5'd0,
                    0
                );


            // x2 = 55
            instruction_memory[1] =
                encode_addi(
                    5'd2,
                    5'd0,
                    55
                );


            // Immediately store generated x2.
            instruction_memory[2] =
                encode_sw(
                    5'd2,
                    5'd1,
                    0
                );


            // Read back.
            instruction_memory[3] =
                encode_lw(
                    5'd3,
                    5'd1,
                    0
                );


            program_length =
                4;


            run_directed_processor_test(
                program_length,
                "STORE DATA DEPENDENCY"
            );

        end

    endtask

        // ============================================================
    // DIRECTED TEST:
    // TAKEN BRANCH
    // ============================================================

    task automatic test_directed_taken_branch;

        integer program_length;


        begin

            prepare_directed_program();


            // x1 = 10
            instruction_memory[0] =
                encode_addi(
                    5'd1,
                    5'd0,
                    10
                );


            // x2 = 10
            instruction_memory[1] =
                encode_addi(
                    5'd2,
                    5'd0,
                    10
                );


            // BEQ x1, x2, +8
            //
            // Skip instruction at PC+4.
            instruction_memory[2] =
                encode_beq(
                    5'd1,
                    5'd2,
                    8
                );


            // WRONG PATH
            //
            // x3 = 99
            instruction_memory[3] =
                encode_addi(
                    5'd3,
                    5'd0,
                    99
                );


            // TARGET
            //
            // x3 = 42
            instruction_memory[4] =
                encode_addi(
                    5'd3,
                    5'd0,
                    42
                );


            program_length =
                5;


            run_directed_processor_test(
                program_length,
                "TAKEN BRANCH"
            );

        end

    endtask

        // ============================================================
    // DIRECTED TEST:
    // NOT TAKEN BRANCH
    // ============================================================

    task automatic test_directed_not_taken_branch;

        integer program_length;


        begin

            prepare_directed_program();


            instruction_memory[0] =
                encode_addi(
                    5'd1,
                    5'd0,
                    10
                );


            instruction_memory[1] =
                encode_addi(
                    5'd2,
                    5'd0,
                    20
                );


            // BEQ x1,x2,+8
            //
            // Must NOT be taken.
            instruction_memory[2] =
                encode_beq(
                    5'd1,
                    5'd2,
                    8
                );


            // Must execute.
            instruction_memory[3] =
                encode_addi(
                    5'd3,
                    5'd0,
                    33
                );


            program_length =
                4;


            run_directed_processor_test(
                program_length,
                "NOT TAKEN BRANCH"
            );

        end

    endtask

        // ============================================================
    // DIRECTED TEST:
    // JAL
    // ============================================================

    task automatic test_directed_jal;

        integer program_length;


        begin

            prepare_directed_program();


            // JAL x1, +8
            //
            // Jump from PC=0 to PC=8.
            instruction_memory[0] =
                encode_jal(
                    5'd1,
                    8
                );


            // WRONG PATH
            instruction_memory[1] =
                encode_addi(
                    5'd2,
                    5'd0,
                    99
                );


            // TARGET
            instruction_memory[2] =
                encode_addi(
                    5'd2,
                    5'd0,
                    42
                );


            program_length =
                3;


            run_directed_processor_test(
                program_length,
                "JAL REDIRECT AND LINK"
            );

        end

    endtask

        // ============================================================
    // DIRECTED TEST:
    // JALR
    // ============================================================

    task automatic test_directed_jalr;

        integer program_length;


        begin

            prepare_directed_program();


            // x1 = 12
            //
            // Target address.
            instruction_memory[0] =
                encode_addi(
                    5'd1,
                    5'd0,
                    12
                );


            // JALR x2, x1, 0
            instruction_memory[1] =
                encode_jalr(
                    5'd2,
                    5'd1,
                    0
                );


            // WRONG PATH
            instruction_memory[2] =
                encode_addi(
                    5'd3,
                    5'd0,
                    99
                );


            // TARGET at PC=12
            instruction_memory[3] =
                encode_addi(
                    5'd3,
                    5'd0,
                    42
                );


            program_length =
                4;


            run_directed_processor_test(
                program_length,
                "JALR REDIRECT AND LINK"
            );

        end

    endtask

        // ============================================================
    // DIRECTED TEST:
    // x0 INVARIANCE
    // ============================================================

    task automatic test_directed_x0_invariance;

        integer program_length;


        begin

            prepare_directed_program();


            // Attempt to write x0.
            instruction_memory[0] =
                encode_addi(
                    5'd0,
                    5'd0,
                    100
                );


            instruction_memory[1] =
                encode_addi(
                    5'd1,
                    5'd0,
                    7
                );


            // Another attempted write.
            instruction_memory[2] =
                encode_add(
                    5'd0,
                    5'd1,
                    5'd1
                );


            // x2 should still see x0 = 0.
            instruction_memory[3] =
                encode_addi(
                    5'd2,
                    5'd0,
                    1
                );


            program_length =
                4;


            run_directed_processor_test(
                program_length,
                "X0 INVARIANCE"
            );

        end

    endtask

        // ============================================================
    // RUN COMPLETE DIRECTED PROCESSOR SUITE
    // ============================================================

    task automatic run_directed_processor_suite;

        begin

            $display("");
            $display("================================================");
            $display("FULL PROCESSOR DIRECTED VERIFICATION");
            $display("================================================");


            test_directed_alu_dataflow();

            test_directed_raw_dependency();

            test_directed_load_use();

            test_directed_store_dependency();

            test_directed_taken_branch();

            test_directed_not_taken_branch();

            test_directed_jal();

            test_directed_jalr();

            test_directed_x0_invariance();


            $display("");
            $display("================================================");
            $display("DIRECTED PROCESSOR SUITE COMPLETE");
            $display("================================================");

        end

    endtask

        // ============================================================
    // SECTION 25
    // RANDOM FULL-PROCESSOR REGRESSION CONTROLLER
    // ============================================================


    // ------------------------------------------------------------
    // Number of independent random programs.
    //
    // Keep this moderate initially for debugging. Increase after
    // the complete end-to-end flow is stable.
    // ------------------------------------------------------------

    localparam integer RANDOM_PROGRAM_TESTS = 100;


    // ------------------------------------------------------------
    // Number of active instructions in each generated program.
    //
    // This must remain within the supported instruction-memory
    // region already defined by the TB.
    // ------------------------------------------------------------

    localparam integer RANDOM_PROGRAM_LENGTH = 50;


    // ------------------------------------------------------------
    // Regression-level counters.
    // ------------------------------------------------------------

    integer random_program_tests_run;

    integer random_program_tests_passed;

    integer random_program_tests_failed;

        // ============================================================
    // RUN ONE RANDOM FULL-PROCESSOR TEST
    // ============================================================

    task automatic run_single_random_processor_test;

        input integer test_number;

        integer fail_count_before;

        integer register_mismatch_before;

        integer memory_mismatch_before;

        integer program_length;


        begin

            program_length =
                RANDOM_PROGRAM_LENGTH;


            // ----------------------------------------------------
            // Capture counters before this program.
            // ----------------------------------------------------

            fail_count_before =
                fail_count;


            register_mismatch_before =
                register_mismatch_count;


            memory_mismatch_before =
                memory_mismatch_count;


            $display("");

            $display(
                "================================================"
            );

            $display(
                "RANDOM PROCESSOR TEST %0d",
                test_number
            );

            $display(
                "PROGRAM LENGTH = %0d",
                program_length
            );

            $display(
                "================================================"
            );


            // ----------------------------------------------------
            // STEP 1
            //
            // Clear the complete architectural environment.
            //
            // Reference state and DUT-visible memories must begin
            // from known state.
            // ----------------------------------------------------

            clear_reference_state();

            clear_data_memory();

            clear_program_memory();


            // ----------------------------------------------------
            // STEP 2
            //
            // Initialize the data memory before program generation.
            //
            // If your random program generator uses load/store
            // instructions, this guarantees deterministic memory
            // contents.
            // ----------------------------------------------------

            initialize_random_data_memory();


            // ----------------------------------------------------
            // STEP 3
            //
            // Build a legal random RV32I program.
            //
            // IMPORTANT:
            //
            // Use the generator created earlier in this TB.
            // Do not create a second random ISA generator here.
            // ----------------------------------------------------

            build_random_program(
                program_length
            );


            // ----------------------------------------------------
            // STEP 4
            //
            // Execute independent architectural reference model.
            //
            // The reference model determines the expected final
            // architectural state.
            // ----------------------------------------------------

            execute_reference_program(
                program_length
            );


            // ----------------------------------------------------
            // STEP 5
            //
            // Reset DUT before execution.
            //
            // The program and initialized data memory remain loaded.
            // ----------------------------------------------------

            reset_dut();


            // ----------------------------------------------------
            // STEP 6
            //
            // Execute DUT until program completion followed by the
            // conservative pipeline drain period.
            // ----------------------------------------------------

            run_dut_until_program_complete(
                program_length
            );


            // ----------------------------------------------------
            // STEP 7
            //
            // Compare DUT architectural state against the reference
            // model.
            // ----------------------------------------------------

            compare_final_architectural_state();


            // ----------------------------------------------------
            // STEP 8
            //
            // Update regression statistics.
            // ----------------------------------------------------

            random_program_tests_run =
                random_program_tests_run + 1;


            if (

                (fail_count ==
                 fail_count_before)

                &&

                (register_mismatch_count ==
                 register_mismatch_before)

                &&

                (memory_mismatch_count ==
                 memory_mismatch_before)

            ) begin

                random_program_tests_passed =
                    random_program_tests_passed + 1;


                pass_count =
                    pass_count + 1;


                $display("");

                $display(
                    "******** RANDOM TEST %0d PASSED ********",
                    test_number
                );

            end

            else begin

                random_program_tests_failed =
                    random_program_tests_failed + 1;


                fail_count =
                    fail_count + 1;


                $display("");

                $display(
                    "******** RANDOM TEST %0d FAILED ********",
                    test_number
                );

            end

        end

    endtask

        // ============================================================
    // RUN RANDOM FULL-PROCESSOR REGRESSION
    // ============================================================

    task automatic run_random_processor_regression;

        integer test_number;


        begin

            random_program_tests_run =
                0;

            random_program_tests_passed =
                0;

            random_program_tests_failed =
                0;


            $display("");

            $display(
                "================================================"
            );

            $display(
                "RANDOM FULL-PROCESSOR REGRESSION START"
            );

            $display(
                "TOTAL PROGRAMS = %0d",
                RANDOM_PROGRAM_TESTS
            );

            $display(
                "PROGRAM LENGTH = %0d",
                RANDOM_PROGRAM_LENGTH
            );

            $display(
                "================================================"
            );


            for (

                test_number = 0;

                test_number < RANDOM_PROGRAM_TESTS;

                test_number =
                test_number + 1

            ) begin

                run_single_random_processor_test(
                    test_number + 1
                );

            end


            $display("");

            $display(
                "================================================"
            );

            $display(
                "RANDOM FULL-PROCESSOR REGRESSION COMPLETE"
            );

            $display(
                "PROGRAMS RUN    = %0d",
                random_program_tests_run
            );

            $display(
                "PROGRAMS PASSED = %0d",
                random_program_tests_passed
            );

            $display(
                "PROGRAMS FAILED = %0d",
                random_program_tests_failed
            );

            $display(
                "================================================"
            );

        end

    endtask

    // ============================================================
    // SECTION 26
    // RANDOM PROGRAM REPRODUCIBILITY
    // ============================================================


    integer regression_seed;

    integer current_random_test;

    integer first_failed_random_test;

    integer failed_program_length;


    initial begin

        regression_seed =
            32'h5A17_C0DE;

        current_random_test =
            -1;

        first_failed_random_test =
            -1;

        failed_program_length =
            0;

    end

    // ============================================================
    // DUMP CURRENT PROGRAM
    // ============================================================

    task automatic dump_current_program;

        input integer program_length;

        integer instruction_index;


        begin

            $display("");

            $display(
                "================================================"
            );

            $display(
                "PROGRAM DUMP"
            );

            $display(
                "PROGRAM LENGTH = %0d",
                program_length
            );

            $display(
                "================================================"
            );


            for (

                instruction_index = 0;

                instruction_index < program_length;

                instruction_index =
                instruction_index + 1

            ) begin

                $display(
                    "PC=%08h | INST[%0d]=%08h",
                    instruction_index * 4,
                    instruction_index,
                    instruction_memory[
                        instruction_index
                    ]
                );

            end


            $display(
                "================================================"
            );

        end

    endtask

        // ============================================================
    // SAVE CURRENT PROGRAM
    // ============================================================

    task automatic save_current_program;

        input string file_name;


        begin

            $writememh(
                file_name,
                instruction_memory
            );


            $display(
                "PROGRAM SAVED TO %s",
                file_name
            );

        end

    endtask

        // ============================================================
    // SAVE ACTIVE PROGRAM ONLY
    // ============================================================

    task automatic save_active_program;

        input string  file_name;

        input integer program_length;


        begin

            if (
                program_length > 0
            ) begin

                $writememh(
                    file_name,
                    instruction_memory,
                    0,
                    program_length - 1
                );


                $display(
                    "ACTIVE PROGRAM SAVED TO %s",
                    file_name
                );

            end

        end

    endtask

        // ============================================================
    // DUMP REGISTER MISMATCHES
    // ============================================================

    task automatic dump_register_mismatches;

        integer register_index;

        logic [31:0] expected_value;

        logic [31:0] actual_value;


        begin

            $display("");

            $display(
                "------------------------------------------------"
            );

            $display(
                "REGISTER MISMATCH REPORT"
            );

            $display(
                "------------------------------------------------"
            );


            for (

                register_index = 0;

                register_index < 32;

                register_index =
                register_index + 1

            ) begin

                expected_value =
                    reference_register_read(
                        register_index[4:0]
                    );


                actual_value =
                    dut_register_read(
                        register_index
                    );


                if (
                    actual_value !==
                    expected_value
                ) begin

                    $display(
                        "X%0d | EXP=%08h | DUT=%08h",
                        register_index,
                        expected_value,
                        actual_value
                    );

                end

            end


            $display(
                "------------------------------------------------"
            );

        end

    endtask

        // ============================================================
    // DUMP MEMORY MISMATCHES
    // ============================================================

    task automatic dump_memory_mismatches;

        integer memory_index;

        logic [31:0] expected_value;

        logic [31:0] actual_value;


        begin

            $display("");

            $display(
                "------------------------------------------------"
            );

            $display(
                "DATA MEMORY MISMATCH REPORT"
            );

            $display(
                "------------------------------------------------"
            );


            for (

                memory_index = 0;

                memory_index < DATA_MEM_DEPTH;

                memory_index =
                memory_index + 1

            ) begin

                expected_value =
                    reference_data_memory[
                        memory_index
                    ];


                actual_value =
                    dut_memory_read_word(
                        memory_index
                    );


                if (
                    actual_value !==
                    expected_value
                ) begin

                    $display(
                        "WORD=%0d ADDR=%08h | EXP=%08h | DUT=%08h",
                        memory_index,
                        memory_index * 4,
                        expected_value,
                        actual_value
                    );

                end

            end


            $display(
                "------------------------------------------------"
            );

        end

    endtask

        // ============================================================
    // CAPTURE RANDOM TEST FAILURE
    // ============================================================

    task automatic capture_random_failure;

        input integer test_number;

        input integer program_length;


        begin

            $display("");

            $display(
                "################################################"
            );

            $display(
                "RANDOM PROCESSOR TEST FAILURE CAPTURE"
            );

            $display(
                "TEST NUMBER   = %0d",
                test_number
            );

            $display(
                "PROGRAM LENGTH = %0d",
                program_length
            );

            $display(
                "FINAL PC       = %08h",
                PCF
            );

            $display(
                "################################################"
            );


            // ----------------------------------------------------
            // Remember first failure.
            // ----------------------------------------------------

            if (
                first_failed_random_test == -1
            ) begin

                first_failed_random_test =
                    test_number;


                failed_program_length =
                    program_length;

            end


            // ----------------------------------------------------
            // Dump exact machine-code program.
            // ----------------------------------------------------

            dump_current_program(
                program_length
            );


            // ----------------------------------------------------
            // Dump final architectural differences.
            // ----------------------------------------------------

            dump_register_mismatches();

            dump_memory_mismatches();


            // ----------------------------------------------------
            // Save reproducible program image.
            //
            // Use one fixed filename for maximum simulator
            // portability. If multiple failures occur, the latest
            // failing program replaces the previous file.
            // ----------------------------------------------------

            save_active_program(
                "failed_program.hex",
                program_length
            );


            $display("");

            $display(
                "REPRODUCTION FILE: failed_program.hex"
            );

            $display(
                "RERUN THIS PROGRAM WITH THE SAME INITIAL DATA MEMORY"
            );

            $display("");

        end

    endtask

        // ============================================================
    // SECTION 27
    // TOP-LEVEL VERIFICATION SEQUENCE
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // INITIALIZE GLOBAL COUNTERS
        // --------------------------------------------------------

        total_tests                = 0;
        pass_count                 = 0;
        fail_count                 = 0;

        assertion_failures         = 0;

        register_mismatch_count    = 0;
        memory_mismatch_count      = 0;

        random_program_tests_run   = 0;
        random_program_tests_passed = 0;
        random_program_tests_failed = 0;


        $display("");
        $display("================================================");
        $display("       RV32I PROCESSOR VERIFICATION");
        $display("================================================");
        $display("");
        $display("Reference-model based architectural verification");
        $display("Directed + Random instruction programs");
        $display("Functional coverage + Assertions");
        $display("================================================");


        // --------------------------------------------------------
        // INITIAL CLEAN STATE
        // --------------------------------------------------------

        clear_program_memory();

        clear_data_memory();

        clear_reference_state();


        // --------------------------------------------------------
        // RESET DUT
        // --------------------------------------------------------

        $display("");
        $display("Applying initial processor reset...");

        reset_dut();


        // --------------------------------------------------------
        // DIRECTED VERIFICATION
        // --------------------------------------------------------

        $display("");
        $display("================================================");
        $display("RUNNING DIRECTED PROCESSOR TESTS");
        $display("================================================");

        run_directed_processor_suite();


        // --------------------------------------------------------
        // RANDOM REGRESSION
        // --------------------------------------------------------

        $display("");
        $display("================================================");
        $display("RUNNING RANDOM PROCESSOR REGRESSION");
        $display("================================================");

        run_random_processor_regression();


        // --------------------------------------------------------
        // FINAL REPORT
        // --------------------------------------------------------

        $display("");
        $display("");
        $display("================================================");
        $display("     RV32I PROCESSOR VERIFICATION REPORT");
        $display("================================================");

        $display(
            "Total Tests              = %0d",
            pass_count + fail_count
        );

        $display(
            "Passed                   = %0d",
            pass_count
        );

        $display(
            "Failed                   = %0d",
            fail_count
        );

        $display(
            "Assertion Failures       = %0d",
            assertion_failures
        );

        $display(
            "Register Mismatches      = %0d",
            register_mismatch_count
        );

        $display(
            "Memory Mismatches        = %0d",
            memory_mismatch_count
        );

        $display(
            "Random Programs Run      = %0d",
            random_program_tests_run
        );

        $display(
            "Random Programs Passed   = %0d",
            random_program_tests_passed
        );

        $display(
            "Random Programs Failed   = %0d",
            random_program_tests_failed
        );


        // --------------------------------------------------------
        // FINAL PASS / FAIL
        // --------------------------------------------------------

        if (

            (fail_count == 0)

            &&

            (assertion_failures == 0)

            &&

            (register_mismatch_count == 0)

            &&

            (memory_mismatch_count == 0)

        ) begin

            $display("");
            $display("================================================");
            $display("**** PROCESSOR VERIFICATION PASSED ****");
            $display("================================================");

        end

        else begin

            $display("");
            $display("================================================");
            $display("**** PROCESSOR VERIFICATION FAILED ****");
            $display("================================================");

        end


        // --------------------------------------------------------
        // END SIMULATION
        // --------------------------------------------------------

        $display("");

        $finish;

    end


endmodule