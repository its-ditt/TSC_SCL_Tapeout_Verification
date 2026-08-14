`timescale 1ns / 1ps

module decode_stage(

    input logic clk,
    input logic rst,

    input logic RegWriteW,
    input logic [31:0] ResultW,
    input logic [4:0] RdW,
    
    input logic [31:0] InstrD,
    input logic [31:0] PCD,
    input logic [31:0] PcPlus4D,

    input logic StallD,
    input logic FlushD,

    output logic RegWriteE,
    output logic [1:0] ResultSrcE,
    output logic MemWriteE,
    output logic MemReadE,
    output logic jumpE,
    output logic BranchE,
    output logic [3:0] ALUControlE,
    output logic [1:0] ALUSrcAE,
    output logic ALUSrcBE,

    output logic [31:0] RD1E,
    output logic [31:0] RD2E,
    
    output logic [31:0] PCE,
    output logic [31:0] PcPlus4E,

    output logic [4:0] RdE,
    output logic [4:0] RS1E,
    output logic [4:0] RS2E,

    output logic [31:0] ImmExtendE,

    output logic [4:0] RS1D,
    output logic [4:0] RS2D,

    output logic [2:0] funct3E
);

//////////////////////////////////////////////////////
// Internal Decode Signals
//////////////////////////////////////////////////////

logic RegWriteD;
logic MemWriteD;
logic MemReadD;
logic jumpD;
logic BranchD;
logic [1:0] ALUSrcAD;
logic ALUSrcBD;

logic [1:0] ResultSrcD;
logic [3:0] ALUControlD;

logic [31:0] RD1D;
logic [31:0] RD2D;
logic [31:0] ImmExtendD;

logic [4:0] RdD;

//////////////////////////////////////////////////////
// Instruction Fields
//////////////////////////////////////////////////////

assign RdD  = InstrD[11:7];
assign RS1D = InstrD[19:15];
assign RS2D = InstrD[24:20];

//////////////////////////////////////////////////////
// Control Unit
//////////////////////////////////////////////////////

control_unit_top control (

    .op(InstrD[6:0]),
    .funct3(InstrD[14:12]),
    .funct7(InstrD[30]),

    .RegWriteD(RegWriteD),
    .ResultSrcD(ResultSrcD),
    .MemWriteD(MemWriteD),
    .jumpD(jumpD),
    .BranchD(BranchD),
    .ALUControlD(ALUControlD),
    .ALUSrcAD(ALUSrcAD),
    .ALUSrcBD(ALUSrcBD),
    .MemReadD(MemReadD)
);

//////////////////////////////////////////////////////
// Register File
//////////////////////////////////////////////////////

registerfile register_file (

    .clk(clk),
    .rst(rst),

    .A1(InstrD[19:15]),
    .A2(InstrD[24:20]),

    .A3(RdW),

    .WD3(ResultW),
    .WE3(RegWriteW),

    .RD1(RD1D),
    .RD2(RD2D)
);

//////////////////////////////////////////////////////
// Immediate Extend
//////////////////////////////////////////////////////

sign_extend extend (

    .Instr(InstrD),
    .ImmExtend(ImmExtendD)
);

//////////////////////////////////////////////////////
// ID/EX Pipeline Register
//////////////////////////////////////////////////////

always_ff @(posedge clk or negedge rst)
begin

    if(!rst)
    begin

        RegWriteE   <= 0;
        ResultSrcE  <= 0;
        MemWriteE   <= 0;
        jumpE       <= 0;
        BranchE     <= 0;
        ALUControlE <= 0;
        ALUSrcAE    <= 0;
        ALUSrcBE    <= 0;

        RD1E        <= 0;
        RD2E        <= 0;
        PCE         <= 0;

        RdE         <= 0;
        RS1E        <= 0;
        RS2E        <= 0;

        ImmExtendE  <= 0;
        PcPlus4E    <= 0;

        funct3E     <= 0;
        MemReadE    <= 0;
      
    end

    // Flush
    else if(FlushD)
    begin

        RegWriteE   <= 0;
        ResultSrcE  <= 0;
        MemWriteE   <= 0;
        jumpE       <= 0;
        BranchE     <= 0;
        ALUControlE <= 0;
        ALUSrcAE    <= 0;
        ALUSrcBE    <= 0;

        RD1E        <= 0;
        RD2E        <= 0;
        PCE         <= 0;

        RdE         <= 0;
        RS1E        <= 0;
        RS2E        <= 0;

        ImmExtendE  <= 0;
        PcPlus4E    <= 0;

        funct3E     <= 0;
        MemReadE    <= 0;
      
      end

    // Normal operation
    else if(!StallD)
    begin

        RegWriteE   <= RegWriteD;
        ResultSrcE  <= ResultSrcD;
        MemWriteE   <= MemWriteD;
        MemReadE    <= MemReadD;
        jumpE       <= jumpD;
        BranchE     <= BranchD;
        ALUControlE <= ALUControlD;
        ALUSrcAE     <= ALUSrcAD;
        ALUSrcBE     <= ALUSrcBD;

        RD1E        <= RD1D;
        RD2E        <= RD2D;
        PCE         <= PCD;

        RdE         <= RdD;
        RS1E        <= RS1D;
        RS2E        <= RS2D;

        ImmExtendE  <= ImmExtendD;
        PcPlus4E    <= PcPlus4D;

        funct3E     <= InstrD[14:12];

    end

end

endmodule