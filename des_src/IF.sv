`timescale 1ns / 1ps

module IF(

input logic clk,
input logic rst,

//Imem Macro
output logic [31:0] INSTR_ADD,
input  logic [31:0] INSTR,

// Branch/Jump control
input logic PcSrcE,
input logic StallF,
input logic [31:0] PcTargetE,


// Outputs to Decode stage
output logic [31:0] InstrD,
output logic [31:0] PcD,
output logic [31:0] PcPlus4D

);

//////////////////////////////////////////////////////
// Internal Signals
//////////////////////////////////////////////////////

logic [31:0] PCF;


logic [31:0] InstrF;
logic [31:0] PcPlus4F;

logic [31:0] PC_BranchNext;

//////////////////////////////////////////////////////
// Delay Signals to match with Synchronous Read Instruction
//////////////////////////////////////////////////////
logic PcSrcE_delay;
logic [31:0] PcD_delay;
logic [31:0] PcPlus4D_delay;
logic FlushIF;
assign FlushIF = PcSrcE | PcSrcE_delay;
//////////////////////////////////////////////////////
// Branch/Jump MUX
//////////////////////////////////////////////////////

MUX_2_1 branch_mux(

    .a(PcPlus4F),
    .b(PcTargetE),
    .sel(PcSrcE),

    .c(PC_BranchNext)
);

//////////////////////////////////////////////////////
// Program Counter
//////////////////////////////////////////////////////

Pc_Module Pc(

    .clk(clk),
    .rst(rst),

    .Pc_next(PC_BranchNext),
    .Pc(PCF),

    .StallF(StallF)

);

//////////////////////////////////////////////////////
// Instruction Memory
//////////////////////////////////////////////////////

inst_memory inst_mem(

    .A(PCF),
    .INSTR_ADD(INSTR_ADD),
    .INSTR(INSTR),
    .RD(InstrF)

);

//////////////////////////////////////////////////////
// PC + 4
//////////////////////////////////////////////////////

Pc_adder pc_adder(

    .PcF(PCF),
    .PcF_4(PcPlus4F)

);
//STALLM check
logic StallF_reg;
logic [31:0] sINSTR;
always_ff @(posedge clk or negedge rst)
begin
    if(!rst)
        PcSrcE_delay <= 1'b0;
    else begin
        PcSrcE_delay <= PcSrcE;
        StallF_reg   <= StallF;   
    end
    
    if(StallF && (~StallF_reg))
        sINSTR <= InstrF;
end
//////////////////////////////////////////////////////
// IF/ID Pipeline Register
//////////////////////////////////////////////////////

always_ff @(posedge clk or negedge rst)
begin

    if(!rst)
    begin

        InstrD         <= 32'h00000013; // NOP
        PcD            <= 32'd0;
        PcPlus4D       <= 32'd4;
        PcD_delay      <= 32'd0;
        PcPlus4D_delay <= 32'd0;
    end

    //////////////////////////////////////////////////
    // Flush on branch/jump OR interrupt
    //////////////////////////////////////////////////

else if(FlushIF)

    begin

        InstrD         <= 32'h00000013; // bubble
        PcD            <= 32'd0;
        PcPlus4D       <= 32'd4;
        PcD_delay      <= 32'd0;
        PcPlus4D_delay <= 32'd0;    
    end

    //////////////////////////////////////////////////
    // Stall -> hold current values
    //////////////////////////////////////////////////

    else if(StallF)
    begin

        InstrD         <= InstrD;
        PcD_delay      <= PcD_delay;
        PcPlus4D_delay <= PcPlus4D_delay;
        PcD            <= PcD;
        PcPlus4D       <= PcPlus4D;
    end
    
    //////////////////////////////////////////////////
    // Normal update
    ////////////////////////////////////////////////// 
    
    else if ((~StallF) && StallF_reg)
    begin
        InstrD <= sINSTR;
        PcD_delay      <= PCF;
        PcPlus4D_delay <= PcPlus4F;
        PcD            <= PcD_delay;
        PcPlus4D       <= PcPlus4D_delay;
    end
    else
    begin
        InstrD         <= InstrF;
        PcD_delay      <= PCF;
        PcPlus4D_delay <= PcPlus4F;
        PcD            <= PcD_delay;
        PcPlus4D       <= PcPlus4D_delay;
    end
        
        
    //////////////////////////////////////////////////
    // Stall -> hold current values
    //////////////////////////////////////////////////

end

endmodule