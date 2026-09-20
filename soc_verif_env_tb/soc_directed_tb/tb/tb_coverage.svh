// ============================================================
// Fundamental functional coverage
// ============================================================

covergroup soc_coverage @(posedge clk);
    option.per_instance = 1;

    cp_opcode : coverpoint dut.cpu.InstrD[6:0] iff (dut.core_rst_n && !load_mode) {
        bins R_TYPE     = {7'b0110011};
        bins I_TYPE     = {7'b0010011};
        bins LOAD       = {7'b0000011};
        bins STORE      = {7'b0100011};
        bins BRANCH     = {7'b1100011};
        bins JAL        = {7'b1101111};
        bins JALR       = {7'b1100111};
        bins LUI        = {7'b0110111};
        bins AUIPC      = {7'b0010111};
    }

    cp_funct3 : coverpoint dut.cpu.InstrD[14:12] iff (dut.core_rst_n && !load_mode) {
        bins values[] = {[0:7]};
    }

    cp_forward_a : coverpoint dut.cpu.ForwardAE iff (dut.core_rst_n && !load_mode) {
        bins rf = {2'b00};
        bins wb = {2'b01};
        bins mem = {2'b10};
    }

    cp_forward_b : coverpoint dut.cpu.ForwardBE iff (dut.core_rst_n && !load_mode) {
        bins rf = {2'b00};
        bins wb = {2'b01};
        bins mem = {2'b10};
    }

    cp_stall_f : coverpoint dut.cpu.StallF_hz iff (dut.core_rst_n && !load_mode) {
        bins no_stall = {0};
        bins stall    = {1};
    }

    cp_stall_d : coverpoint dut.cpu.StallD_hz iff (dut.core_rst_n && !load_mode) {
        bins no_stall = {0};
        bins stall    = {1};
    }

    cp_stall_e : coverpoint dut.cpu.StallE_hz iff (dut.core_rst_n && !load_mode) {
        bins no_stall = {0};
        bins stall    = {1};
    }

    cp_cpu_mem : coverpoint {dut.cpu.MEM_READ, dut.cpu.MEM_WRITE} iff (dut.core_rst_n && !load_mode) {
        bins idle  = {2'b00};
        bins read  = {2'b10};
        bins write = {2'b01};
    }

    cp_wstrb : coverpoint dut.cpu.MEM_WSTRB iff (dut.cpu.MEM_WRITE) {
        bins byte0 = {4'b0001};
        bins byte1 = {4'b0010};
        bins byte2 = {4'b0100};
        bins byte3 = {4'b1000};
        bins half_lo = {4'b0011};
        bins half_hi = {4'b1100};
        bins word = {4'b1111};
    }

    cp_axi_burst_state : coverpoint dut.axi_top.manager.state {
        bins idle = {3'b000};
        bins write = {3'b001};
        bins write_resp = {3'b010};
        bins read_addr = {3'b011};
        bins read_data = {3'b100};
    }

    cp_load_byte_count : coverpoint dut.instr_in.byte_cnt iff (load_mode) {
        bins b0 = {0};
        bins b1 = {1};
        bins b2 = {2};
        bins b3 = {3};
    }

    cross_load_store : cross cp_opcode, cp_cpu_mem;
    cross_forwarding  : cross cp_opcode, cp_forward_a, cp_forward_b;
endgroup

soc_coverage cov = new();
