// ============================================================
// Synchronous Instruction Memory Model
// ============================================================

logic [31:0] instr_addr_q;

always_ff @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin
        instr_addr_q <= 32'd0;
        INSTR        <= 32'h00000013;
    end

    else begin
        instr_addr_q <= INSTR_ADD;

        if ((INSTR_ADD[1:0] == 2'b00) &&
            (INSTR_ADD[31:2] < IMEM_WORDS))
            INSTR <= instruction_memory[INSTR_ADD[31:2]];
        else
            INSTR <= 32'h00000013;
    end

end