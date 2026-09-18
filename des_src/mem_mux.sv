// Arbitrates a single-port memory's address/we/wdata inputs between the
// boot loader and the core, based on load_mode. Since the core is held
// in reset for the full duration of load_mode, there's never real
// contention -- this is just a clean mux, not real arbitration logic.
//
// Instantiate one of these per memory (instruction memory, data memory).

module mem_port_mux #(
)(
    input  logic                    load_mode,

    // loader side
    input  logic [11:0]   ldr_addr,
    input  logic          ldr_we,
    input  logic [31:0]   ldr_wdata,

    // core side (fetch-stage read port for instr mem)
    input  logic [31:0]   core_addr,

    // memory-facing signals -> wire these to the actual SRAM macro
    output logic [ 9:0]   mem_addr, //Because mem is 1024 word wise locations so we have to drop 2 bits used for bytes
    output logic          mem_we,
    output logic [31:0]   mem_wdata
);

    assign mem_addr  = load_mode ? ldr_addr[11:2] : core_addr[11:2];  
    assign mem_we    = load_mode ? ldr_we    : 1'b0;
    assign mem_wdata = ldr_wdata;

endmodule