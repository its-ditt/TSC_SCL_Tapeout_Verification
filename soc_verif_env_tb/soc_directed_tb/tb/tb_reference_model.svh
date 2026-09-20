// ============================================================
// Simple architectural RV32I reference model
// ============================================================
// This model is intentionally NOT cycle-accurate. It models only
// architectural state: PC, x0-x31, and byte-addressed memory.
// ============================================================

function automatic logic [31:0] ref_sx12(input logic [11:0] v);
    ref_sx12 = {{20{v[11]}}, v};
endfunction

function automatic logic [31:0] ref_imm_i(input logic [31:0] insn);
    ref_imm_i = ref_sx12(insn[31:20]);
endfunction

function automatic logic [31:0] ref_imm_s(input logic [31:0] insn);
    ref_imm_s = {{20{insn[31]}}, insn[31:25], insn[11:7]};
endfunction

function automatic logic [31:0] ref_imm_b(input logic [31:0] insn);
    ref_imm_b = {{19{insn[31]}}, insn[31], insn[7],
                 insn[30:25], insn[11:8], 1'b0};
endfunction

function automatic logic [31:0] ref_imm_u(input logic [31:0] insn);
    ref_imm_u = {insn[31:12], 12'b0};
endfunction

function automatic logic [31:0] ref_imm_j(input logic [31:0] insn);
    ref_imm_j = {{11{insn[31]}}, insn[31], insn[19:12],
                 insn[20], insn[30:21], 1'b0};
endfunction

function automatic logic [7:0] ref_get_byte(input logic [31:0] addr);
    ref_get_byte = ref_mem[addr[11:2]][8*addr[1:0] +: 8];
endfunction

function automatic logic [31:0] ref_load_lw(input logic [31:0] addr);
    ref_load_lw = ref_mem[addr[11:2]];
endfunction

function automatic logic [31:0] ref_load_lb(input logic [31:0] addr);
    logic [7:0] b;
    begin
        b = ref_get_byte(addr);
        ref_load_lb = {{24{b[7]}}, b};
    end
endfunction

function automatic logic [31:0] ref_load_lbu(input logic [31:0] addr);
    ref_load_lbu = {24'b0, ref_get_byte(addr)};
endfunction

function automatic logic [31:0] ref_load_lh(input logic [31:0] addr);
    logic [15:0] h;
    begin
        h = ref_mem[addr[11:2]][16*addr[1] +: 16];
        ref_load_lh = {{16{h[15]}}, h};
    end
endfunction

function automatic logic [31:0] ref_load_lhu(input logic [31:0] addr);
    ref_load_lhu = {16'b0, ref_mem[addr[11:2]][16*addr[1] +: 16]};
endfunction

task automatic ref_store_byte(input logic [31:0] addr, input logic [7:0] data);
    begin
        ref_mem[addr[11:2]][8*addr[1:0] +: 8] = data;
        ref_mem_valid[addr[11:2]] = 1'b1;
    end
endtask

task automatic ref_store_half(input logic [31:0] addr, input logic [15:0] data);
    begin
        ref_store_byte(addr, data[7:0]);
        ref_store_byte(addr + 32'd1, data[15:8]);
    end
endtask

task automatic ref_store_word(input logic [31:0] addr, input logic [31:0] data);
    begin
        ref_store_byte(addr + 32'd0, data[7:0]);
        ref_store_byte(addr + 32'd1, data[15:8]);
        ref_store_byte(addr + 32'd2, data[23:16]);
        ref_store_byte(addr + 32'd3, data[31:24]);
    end
endtask

task automatic build_reference_model();
    logic [31:0] pc;
    logic [31:0] insn;
    logic [31:0] next_pc;
    logic [31:0] a, b, result;
    logic [31:0] imm_i, imm_s, imm_b, imm_j, imm_u;
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [4:0] rs1, rs2, rd;
    int steps;
    int i;
    bit done;

    begin
        for (i = 0; i < 32; i++)
            ref_regs[i] = 32'd0;
        for (i = 0; i < DMEM_WORDS; i++) begin
            ref_mem[i] = 32'd0;
            ref_mem_valid[i] = 1'b0;
        end

        ref_error = 1'b0;
        ref_steps = 0;
        pc = 32'd0;
        done = 1'b0;

        for (steps = 0; steps < 10000; steps++) begin
            if (done)
                break;

            if ((pc[1:0] != 2'b00) || (pc[31:2] >= PROGRAM_WORDS)) begin
                $error("REFERENCE MODEL: PC left loaded program: %08h", pc);
                ref_error = 1'b1;
                break;
            end

            insn = program_words[pc[31:2]];
            opcode = insn[6:0];
            funct3 = insn[14:12];
            rs1 = insn[19:15];
            rs2 = insn[24:20];
            rd  = insn[11:7];
            a = (rs1 == 0) ? 32'd0 : ref_regs[rs1];
            b = (rs2 == 0) ? 32'd0 : ref_regs[rs2];
            imm_i = ref_imm_i(insn);
            imm_s = ref_imm_s(insn);
            imm_b = ref_imm_b(insn);
            imm_j = ref_imm_j(insn);
            imm_u = ref_imm_u(insn);
            result = 32'd0;
            next_pc = pc + 32'd4;

            case (opcode)
                7'b0110011: begin // R type
                    case (funct3)
                        3'b000: result = (insn[30]) ? (a - b) : (a + b);
                        3'b001: result = a << b[4:0];
                        3'b010: result = ($signed(a) < $signed(b)) ? 1 : 0;
                        3'b011: result = (a < b) ? 1 : 0;
                        3'b100: result = a ^ b;
                        3'b101: result = insn[30] ? ($signed(a) >>> b[4:0]) : (a >> b[4:0]);
                        3'b110: result = a | b;
                        3'b111: result = a & b;
                        default: begin $error("REFERENCE: unsupported R funct3 %03b", funct3); ref_error = 1'b1; end
                    endcase
                    if (rd != 0) ref_regs[rd] = result;
                end

                7'b0010011: begin // I type ALU
                    case (funct3)
                        3'b000: result = a + imm_i;
                        3'b001: result = a << insn[24:20];
                        3'b010: result = ($signed(a) < $signed(imm_i)) ? 1 : 0;
                        3'b011: result = (a < imm_i) ? 1 : 0;
                        3'b100: result = a ^ imm_i;
                        3'b101: result = insn[30] ? ($signed(a) >>> insn[24:20]) : (a >> insn[24:20]);
                        3'b110: result = a | imm_i;
                        3'b111: result = a & imm_i;
                        default: begin $error("REFERENCE: unsupported I funct3 %03b", funct3); ref_error = 1'b1; end
                    endcase
                    if (rd != 0) ref_regs[rd] = result;
                end

                7'b0000011: begin // Loads
                    case (funct3)
                        3'b000: result = ref_load_lb(a + imm_i);
                        3'b001: result = ref_load_lh(a + imm_i);
                        3'b010: result = ref_load_lw(a + imm_i);
                        3'b100: result = ref_load_lbu(a + imm_i);
                        3'b101: result = ref_load_lhu(a + imm_i);
                        default: begin $error("REFERENCE: unsupported load funct3 %03b", funct3); ref_error = 1'b1; end
                    endcase
                    if (rd != 0) ref_regs[rd] = result;
                end

                7'b0100011: begin // Stores
                    logic [31:0] addr;
                    addr = a + imm_s;
                    case (funct3)
                        3'b000: ref_store_byte(addr, b[7:0]);
                        3'b001: ref_store_half(addr, b[15:0]);
                        3'b010: ref_store_word(addr, b);
                        default: begin $error("REFERENCE: unsupported store funct3 %03b", funct3); ref_error = 1'b1; end
                    endcase
                    if (addr == DONE_ADDR && b == DONE_VALUE)
                        done = 1'b1;
                end

                7'b1100011: begin // Branches
                    case (funct3)
                        3'b000: if (a == b) next_pc = pc + imm_b;
                        3'b001: if (a != b) next_pc = pc + imm_b;
                        3'b100: if ($signed(a) < $signed(b)) next_pc = pc + imm_b;
                        3'b101: if ($signed(a) >= $signed(b)) next_pc = pc + imm_b;
                        3'b110: if (a < b) next_pc = pc + imm_b;
                        3'b111: if (a >= b) next_pc = pc + imm_b;
                        default: begin $error("REFERENCE: unsupported branch funct3 %03b", funct3); ref_error = 1'b1; end
                    endcase
                end

                7'b1101111: begin // JAL
                    if (rd != 0) ref_regs[rd] = pc + 32'd4;
                    next_pc = pc + imm_j;
                end

                7'b1100111: begin // JALR
                    if (rd != 0) ref_regs[rd] = pc + 32'd4;
                    next_pc = (a + imm_i) & 32'hFFFFFFFE;
                end

                7'b0110111: begin // LUI
                    if (rd != 0) ref_regs[rd] = imm_u;
                end

                7'b0010111: begin // AUIPC
                    if (rd != 0) ref_regs[rd] = pc + imm_u;
                end

                default: begin
                    // NOP is the only expected no-op instruction.
                    if (insn != RV32I_NOP) begin
                        $error("REFERENCE: unsupported opcode %02h at PC %08h, instruction %08h",
                               opcode, pc, insn);
                        ref_error = 1'b1;
                        break;
                    end
                end
            endcase

            ref_regs[0] = 32'd0;
            pc = next_pc;
            ref_steps++;
        end

        if (!done) begin
            $error("REFERENCE MODEL: completion marker was not reached");
            ref_error = 1'b1;
        end

        ref_final_pc = pc;
        ref_regs[0] = 32'd0;
    end
endtask
