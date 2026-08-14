`timescale 1ns / 1ps
 
module control_unit_top(
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic       funct7,
    
    output logic       RegWriteD,
    output logic [1:0] ResultSrcD,
    output logic       MemWriteD,
    output logic       MemReadD,
    output logic       jumpD,
    output logic       BranchD,
    output logic [3:0] ALUControlD,
    output logic [1:0] ALUSrcAD,
    output logic       ALUSrcBD
);

logic [1:0]ALUOp;

ALU_Decoder alu (
             .op(op[5]),
             .funct3(funct3),
             .funct7(funct7),
             .ALUOp(ALUOp),
             .ALUControl(ALUControlD)
             );
             
main_decoder decoder (
            .op(op),
            .ResultSrc(ResultSrcD),
            .MemWrite(MemWriteD),
            .ALUSrcA(ALUSrcAD),
            .ALUSrcB(ALUSrcBD),
            .RegWrite(RegWriteD),
            .jump(jumpD),
            .Branch(BranchD),
            .ALUOp(ALUOp),
            .MemRead(MemReadD)
            );
endmodule
