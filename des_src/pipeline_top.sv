
`timescale 1ns / 1ps

module pipeline_top(
    input  logic        clk,
    input  logic        rst_n,
    output logic [31:0] debug_out,

    //AXI
    output logic        MEM_WRITE,
    output logic        MEM_READ,
    input  logic        MEM_READY,
    output logic [31:0] MEM_ADDR,
    output logic [31:0] MEM_WDATA,
    output logic [ 3:0] MEM_WSTRB,
    input  logic [31:0] MEM_RDATA,
    
    //Imem Macro
    output logic [31:0] INSTR_ADD,
    input logic  [31:0] INSTR
);

////////////////////////////////////////////////////////////
// PIPELINE WIRE DECLARATIONS
////////////////////////////////////////////////////////////

////Fetch Stage
        //PC selection//
logic        PcSrcE;
logic [31:0] PcTargetE;
        //IF>ID//
logic [31:0] InstrD, PcD, PcPlus4D;

////Decode Stage Output
        //Control Unit//
logic        RegWriteE;
logic [1:0]  ResultSrcE;
logic        MemWriteE, MemReadE;
logic        jumpE, BranchE;
logic [3:0]  ALUControlE;
logic [1:0]  ALUSrcAE;
logic        ALUSrcBE;

        //Register File//
logic [31:0] RD1E, RD2E, PCE;
logic [4:0]  RdE, RS1E, RS2E;

        //Immediate Extend//
logic [31:0] ImmExtendE;

        //ID>Ex//
logic [31:0] PcPlus4E;
logic [2:0]  funct3E;

////Execute Stage
        //From Hazard Unit//
logic [1:0]  ForwardAE, ForwardBE;

        //EX>Mem pipeline//
logic [31:0] ALUResultM;
logic        MemWriteM, MemReadM;
logic [2:0]  funct3M;
logic [31:0] WriteDataM;
logic [1:0]  ResultSrcM;
logic [31:0] PcPlus4M;
logic        RegWriteM;
logic [4:0]  RdM;

////Memory Stage
        //Mem>WB//
logic [1:0]  ResultSrcW;
logic [31:0] ALUResultW, ReadDataW;
logic [4:0]  RdW;
logic [31:0] PcPlus4W;
logic [31:0] ResultW;

////Hazard Unit 
        //Input//
logic [4:0]  Rs1D, Rs2D;  //From Decode stage
logic        RegWriteW, bus_stall;   //From Mem Stage

        //Output//


logic StallF_hz;   
logic StallD_hz;   
logic StallE_hz;
logic FlushD_hz;   
logic FlushE_hz;   

////////////////////////////////////////////////////////////
// FETCH
////////////////////////////////////////////////////////////

IF fetch(
    .clk(clk),
    .rst_n(rst_n),
    .INSTR_ADD(INSTR_ADD),
    .INSTR(INSTR),
    .PcSrcE(PcSrcE),
    .StallF(StallF_hz),
    .PcTargetE(PcTargetE),
    .InstrD(InstrD),
    .PcD(PcD),
    .PcPlus4D(PcPlus4D)
);

////////////////////////////////////////////////////////////
// DECODE
////////////////////////////////////////////////////////////

decode_stage decode(
    .clk(clk),
    .rst_n(rst_n),
    .RegWriteW(RegWriteW),
    .InstrD(InstrD),
    .PCD(PcD),
    .PcPlus4D(PcPlus4D),
    .ResultW(ResultW),
    .RdW(RdW),
    .StallD(StallD_hz),
    .FlushD(FlushD_hz),
    .RegWriteE(RegWriteE),
    .ResultSrcE(ResultSrcE),
    .MemWriteE(MemWriteE),
    .jumpE(jumpE),
    .BranchE(BranchE),
    .ALUControlE(ALUControlE),
    .ALUSrcAE(ALUSrcAE),
    .ALUSrcBE(ALUSrcBE),
    .RD1E(RD1E),
    .RD2E(RD2E),
    .PCE(PCE),
    .RdE(RdE),
    .RS1E(RS1E),
    .RS2E(RS2E),
    .ImmExtendE(ImmExtendE),
    .PcPlus4E(PcPlus4E),
    .RS1D(Rs1D),
    .RS2D(Rs2D),
    .funct3E(funct3E),
    .MemReadE(MemReadE)

);

////////////////////////////////////////////////////////////
// EXECUTE
////////////////////////////////////////////////////////////

Execute_stage execute(
    .clk(clk),
    .rst_n(rst_n),
    .RegWriteE(RegWriteE),
    .ResultSrcE(ResultSrcE),
    .MemWriteE(MemWriteE),
    .jumpE(jumpE),
    .BranchE(BranchE),
    .ALUControlE(ALUControlE),
    .ALUSrcAE(ALUSrcAE),
    .ALUSrcBE(ALUSrcBE),
    .RD1E(RD1E),
    .RD2E(RD2E),
    .PCE(PCE),
    .RdE(RdE),
    .ImmExtendE(ImmExtendE),
    .PcPlus4E(PcPlus4E),
    .ResultW(ResultW),
    .ForwardAE(ForwardAE),
    .ForwardBE(ForwardBE),
    .FlushE(FlushE_hz),
    .StallE(StallE_hz),
    .funct3E(funct3E), 
    .RegWriteM(RegWriteM),
    .ResultSrcM(ResultSrcM),
    .MemWriteM(MemWriteM),
    .ALUResultM(ALUResultM),
    .WriteDataM(WriteDataM),
    .RdM(RdM),
    .PcPlus4M(PcPlus4M),
    .PcTargetE(PcTargetE),
    .PcSrcE(PcSrcE),
    .ALUResultM_forward(ALUResultM),
    .funct3M(funct3M),
    .MemReadM(MemReadM),
    .MemReadE(MemReadE)
);

////////////////////////////////////////////////////////////
// MEMORY STAGE
////////////////////////////////////////////////////////////

data_mem_stage memory_stage(
    .clk         (         clk),
    .rst_n         (         rst_n),
    .RegWriteM   (   RegWriteM),
    .ResultSrcM  (  ResultSrcM),
    .MemWriteM   (   MemWriteM),
    .MemReadM    (    MemReadM),
    .ALUResultM  (  ALUResultM),
    .WriteDataM  (  WriteDataM),
    .funct3M     (     funct3M),
    .RdM         (         RdM),
    .PcPlus4M    (    PcPlus4M),
    .ReadDataW   (   ReadDataW),
    .RegWriteW   (   RegWriteW),
    .ResultSrcW  (  ResultSrcW),
    .ALUResultW  (  ALUResultW),
    .RdW         (         RdW),
    .PcPlus4W    (    PcPlus4W),
    .data_bus_stall (   bus_stall),
    
    //AXI
    .MEM_WRITE   (   MEM_WRITE),
    .MEM_READ    (    MEM_READ),
    .MEM_READY   (   MEM_READY),
    .MEM_ADDR    (    MEM_ADDR),
    .MEM_WDATA   (   MEM_WDATA),
    .MEM_WSTRB   (   MEM_WSTRB),
    .MEM_RDATA   (   MEM_RDATA)
);  

////////////////////////////////////////////////////////////
// WRITE BACK
////////////////////////////////////////////////////////////

write_back_stage wb(
    .ResultSrcW(ResultSrcW),
    .ALUResultW(ALUResultW),
    .ReadDataW(ReadDataW),
    .PcPlus4W(PcPlus4W),
    .ResultW(ResultW)
);

////////////////////////////////////////////////////////////
// HAZARD UNIT
////////////////////////////////////////////////////////////

hazard_unit ha(
    .rst_n(rst_n),
    .RegWriteM(RegWriteM),
    .RegWriteW(RegWriteW),
    .RdM(RdM),
    .RdW(RdW),
    .Rs1E(RS1E),
    .Rs2E(RS2E),
    .Rs1D(Rs1D),
    .Rs2D(Rs2D),
    .ResultSrcE(ResultSrcE),
    .RdE(RdE),
    .PcSrcE(PcSrcE),
    .bus_stall(bus_stall),
    .ForwardAE(ForwardAE),
    .ForwardBE(ForwardBE),
    .StallF(StallF_hz),      
    .StallD(StallD_hz),  
    .StallE(StallE_hz),    
    .FlushD(FlushD_hz),      
    .FlushE(FlushE_hz)
);

////////////////////////////////////////////////////////////
// DEBUG
////////////////////////////////////////////////////////////

assign debug_out = ResultW;

endmodule