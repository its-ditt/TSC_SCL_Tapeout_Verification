`timescale 1ns / 1ps

module Execute_stage(

    input logic clk,
    input logic rst,

//////////////////////////////////////////////////////
// Control Signals from Decode Stage
//////////////////////////////////////////////////////

input logic RegWriteE,
input logic [1:0] ResultSrcE,
input logic MemWriteE,
input logic jumpE,
input logic BranchE,
input logic [3:0] ALUControlE,
input logic [1:0] ALUSrcAE,
input logic ALUSrcBE,

//////////////////////////////////////////////////////
// Data Signals from Decode Stage
//////////////////////////////////////////////////////

input logic [31:0] RD1E,
input logic [31:0] RD2E,
input logic [31:0] PCE,

input logic [4:0] RdE,

input logic [31:0] ImmExtendE,
input logic [31:0] PcPlus4E,

//////////////////////////////////////////////////////
// Forwarding Inputs
//////////////////////////////////////////////////////

input logic [31:0] ResultW,
input logic [1:0] ForwardAE,
input logic [1:0] ForwardBE,

input logic [31:0] ALUResultM_forward,

//////////////////////////////////////////////////////
// Flush
//////////////////////////////////////////////////////

input logic FlushE,


input logic StallE,

//////////////////////////////////////////////////////
// Branch Function
//////////////////////////////////////////////////////

input logic [2:0] funct3E,

//////////////////////////////////////////////////////
// Outputs to Memory Stage
//////////////////////////////////////////////////////

output logic RegWriteM,
output logic [1:0] ResultSrcM,
output logic MemWriteM,

output logic [31:0] ALUResultM,
output logic [31:0] WriteDataM,

output logic [4:0] RdM,

output logic [31:0] PcPlus4M,

output logic [2:0] funct3M,

//////////////////////////////////////////////////////
// Branch Outputs
//////////////////////////////////////////////////////

output logic [31:0] PcTargetE,
output logic PcSrcE,


input logic MemReadE,
output logic MemReadM

);

//////////////////////////////////////////////////////
// Internal Signals
//////////////////////////////////////////////////////
logic [31:0] PcPlusImm;
logic [31:0] SrcAE;
logic [31:0] SrcBE;

logic [31:0] ForwardAData;
logic [31:0] ForwardBData;


logic [31:0] ALUOut;
logic zeroE;
logic less_thanE;

logic BranchTaken;

//////////////////////////////////////////////////////
// Forwarding MUX A
//////////////////////////////////////////////////////

mux_3_1 mux_hazard_1 (

    .a(RD1E),
    .b(ResultW),
    .c(ALUResultM_forward),
    .s(ForwardAE),

    .muxout(ForwardAData)
);

//////////////////////////////////////////////////////
// Forwarding MUX B
//////////////////////////////////////////////////////

mux_3_1 mux_hazard_2 (

    .a(RD2E),
    .b(ResultW),
    .c(ALUResultM_forward),
    .s(ForwardBE),

    .muxout(ForwardBData)
);

//////////////////////////////////////////////////////
// ALU Source MUX
//////////////////////////////////////////////////////

mux_3_1 alua_src_mux (
    .a(ForwardAData),
    .b(PCE),
    .c(32'b0),
    .s(ALUSrcAE),
    
    .muxout(SrcAE)
    );


MUX_2_1 alub_src_mux (

    .a(ForwardBData),
    .b(ImmExtendE),
    .sel(ALUSrcBE),

    .c(SrcBE)
);

//////////////////////////////////////////////////////
// ALU
//////////////////////////////////////////////////////

ALU alu (

    .SrcAE(SrcAE),
    .SrcBE(SrcBE),
    .ALUControlE(ALUControlE),

    .ALUResult(ALUOut),
    .zeroE(zeroE),
    .less_thanE(less_thanE)
);

//////////////////////////////////////////////////////
// PC Target Adder
//////////////////////////////////////////////////////

Adder pc_adder (

    .PCE(PCE),
    .ImmExtendE(ImmExtendE),

    .PcTargetE(PcPlusImm)
);

//////////////////////////////////////////////////////
// Branch Logic
//////////////////////////////////////////////////////

always_comb
begin
    BranchTaken = 1'b0;
    if(BranchE)
    begin

        case(funct3E)

            3'b000: BranchTaken = (zeroE);        // BEQ
            3'b001: BranchTaken = (!zeroE);       // BNE
            3'b100: BranchTaken = (less_thanE);  // BLT
            3'b101: BranchTaken = (!less_thanE); // BGE
            3'b110: BranchTaken = (less_thanE);  // BLTU
            3'b111: BranchTaken = (!less_thanE); // BGEU

            default:
                BranchTaken = 1'b0;
        endcase
    end
end

assign PcTargetE =
       (jumpE && ALUSrcBE)
       ? (ALUOut & 32'hFFFFFFFE)
       : PcPlusImm;

//////////////////////////////////////////////////////
// PC Source Decision
//////////////////////////////////////////////////////

assign PcSrcE = BranchTaken | jumpE;

//////////////////////////////////////////////////////
// EX/MEM Pipeline Register
//
// Priority (highest to lowest):
//   1. rst        - async reset to zero
//   2. StallM     - hold current values (APB not ready)
//   3. FlushE     - insert bubble (branch/jump taken)
//   4. normal     - latch new EX outputs
//
// WHY this priority order:
//   - StallM beats FlushE: if a branch resolves at the
//     same cycle an APB transaction is in progress, we
//     must NOT flush the MEM stage contents - the memory
//     op is mid-flight on the bus. Hold everything until
//     pready, THEN the flush will naturally not apply
//     anymore (PcSrcE will have been cleared by then).
//
//   - FlushE beats normal: a taken branch/jump must
//     squash whatever is in the EX stage before it
//     reaches MEM and writes registers or memory.
//////////////////////////////////////////////////////

always_ff @(posedge clk or negedge rst)
begin

    if(!rst)
    begin
        // --- 1. Async reset ---
        RegWriteM   <= 1'b0;
        ResultSrcM  <= 2'b00;
        MemWriteM   <= 1'b0;
        MemReadM    <= 1'b0;
        ALUResultM  <= 32'd0;
        WriteDataM  <= 32'd0;
        RdM         <= 5'd0;
        PcPlus4M    <= 32'd0;
        funct3M     <= 3'd0;
    end

    
    else if(FlushE)
    begin
        // --- 3. Branch/jump flush: insert NOP bubble ---
        // Control signals zeroed so nothing writes to
        // memory or registers from this slot.
        RegWriteM   <= 1'b0;
        ResultSrcM  <= 2'b00;
        MemWriteM   <= 1'b0;
        MemReadM    <= 1'b0;
        ALUResultM  <= 32'd0;
        WriteDataM  <= 32'd0;
        RdM         <= 5'd0;
        PcPlus4M    <= 32'd0;
        funct3M     <= 3'd0;
    end
    
    
    else if(StallE)
    begin
        // bus stall: freeze EX/MEM register ---
        // All outputs hold their current values.
        // Do NOT write anything - implicit in always_ff.
        RegWriteM   <= RegWriteM;
        ResultSrcM  <= ResultSrcM;
        MemWriteM   <= MemWriteM;
        MemReadM    <= MemReadM;
        ALUResultM  <= ALUResultM;
        WriteDataM  <= WriteDataM;
        RdM         <= RdM;
        PcPlus4M    <= PcPlus4M;
        funct3M     <= funct3M;
    end


    else
    begin
        // --- 4. Normal operation: latch EX stage outputs ---
        RegWriteM   <= RegWriteE;
        ResultSrcM  <= ResultSrcE;
        MemWriteM   <= MemWriteE;
        MemReadM    <= MemReadE;
        ALUResultM  <= ALUOut;
        WriteDataM  <= ForwardBData;  // forwarded store data
        RdM         <= RdE;
        PcPlus4M    <= PcPlus4E;
        funct3M     <= funct3E;
    end

end

endmodule
