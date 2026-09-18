// ============================================================
// Data Memory Model
// TB #1: ISA instruction execution
// ============================================================
//
// DUT-side interface:
//   MEM_WRITE  : write request
//   MEM_READ   : read request
//   MEM_READY  : memory response/ready
//   MEM_ADDR   : byte address
//   MEM_WDATA  : write data
//   MEM_WSTRB  : byte write strobes
//   MEM_RDATA  : read data
//
// This is a simple always-ready processor-side memory model.
// It is intentionally NOT an AXI protocol model.
// ============================================================


// ------------------------------------------------------------
// Initialize data memory
// ------------------------------------------------------------
task automatic init_data_memory();

    for (int i = 0; i < DMEM_WORDS; i++)
        data_memory[i] = 32'h00000000;

endtask

// ------------------------------------------------------------
// Memory is always ready in TB #1.
// This keeps the first test focused on ISA functionality,
// not memory/bus stalls.
// ------------------------------------------------------------
assign MEM_READY = 1'b1;

// ------------------------------------------------------------
// Write operation
//
// MEM_ADDR is byte addressed.
// MEM_WSTRB selects individual byte lanes of MEM_WDATA.
// ------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin
        // Memory contents are initialized separately by
        // init_data_memory().
    end
    else if (MEM_WRITE) begin

        if (MEM_ADDR[31:2] < DMEM_WORDS) begin

            if (MEM_WSTRB[0])
                data_memory[MEM_ADDR[31:2]][7:0]   <= MEM_WDATA[7:0];

            if (MEM_WSTRB[1])
                data_memory[MEM_ADDR[31:2]][15:8]  <= MEM_WDATA[15:8];

            if (MEM_WSTRB[2])
                data_memory[MEM_ADDR[31:2]][23:16] <= MEM_WDATA[23:16];

            if (MEM_WSTRB[3])
                data_memory[MEM_ADDR[31:2]][31:24] <= MEM_WDATA[31:24];

        end

    end

end

// ------------------------------------------------------------
// Read operation
//
// The DUT's load logic performs the byte/halfword extraction
// and sign/zero extension. Therefore this model returns the
// complete aligned 32-bit memory word.
// ------------------------------------------------------------
always_comb begin

    MEM_RDATA = 32'h00000000;

    if (MEM_READ) begin

        if (MEM_ADDR[31:2] < DMEM_WORDS)
            MEM_RDATA = data_memory[MEM_ADDR[31:2]];

    end

end
