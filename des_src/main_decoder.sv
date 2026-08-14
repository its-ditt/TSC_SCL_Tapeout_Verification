`timescale 1ns / 1ps

module main_decoder(
input logic [6:0]op,
output logic [1:0]ResultSrc,
output logic MemWrite,
output logic [1:0] ALUSrcA,
output logic ALUSrcB,
output logic RegWrite,
output logic jump,
output logic Branch,
output logic [1:0]ALUOp,
output logic MemRead
);

always_comb begin

    RegWrite = 0;
    MemWrite = 0;
    ALUSrcA = 2'b00;
    ALUSrcB   = 0;
    ResultSrc= 2'b00;
    Branch   = 0;
    jump     = 0;
    ALUOp    = 2'b00;
    MemRead   = 1'b0; 
    case(op)

// R-type
    7'b0110011: begin
        RegWrite = 1;
        ALUSrcA   = 2'b00;
        ALUSrcB   = 0;
        ALUOp    = 2'b10;
    end

// I-type (addi, etc.)
    7'b0010011: begin
        RegWrite = 1;
        ALUSrcA   = 2'b00;
        ALUSrcB   = 1;
        ALUOp    = 2'b10;
    end

// LOAD
    7'b0000011: begin
        RegWrite = 1;
        ALUSrcA   = 2'b00;
        ALUSrcB   = 1;
        ResultSrc= 2'b01;
        ALUOp    = 2'b00;
        MemRead   = 1'b1;
    end

// STORE
    7'b0100011: begin
        MemWrite = 1;
        ALUSrcA   = 2'b00;
        ALUSrcB   = 1;
        ALUOp    = 2'b00;
        MemRead   = 1'b0;   // ADDED
    end

// BRANCH
    7'b1100011: begin
        Branch   = 1;
        ALUOp    = 2'b01;
        ALUSrcA   = 2'b00;
        ALUSrcB   = 0;
        RegWrite = 0 ;
    end

// JAL
    7'b1101111: begin
        RegWrite = 1;
        ResultSrc= 2'b10;   // PC+4
        jump     = 1;
    end
    
// JALR
    7'b1100111: begin
        RegWrite  = 1;
        ALUSrcB    = 1;        // target = rs1 + imm
        ResultSrc = 2'b10;   // write PC+4 into rd
        jump      = 1;
    end

//AUIPC
    7'b0010111: begin
        RegWrite  = 1;
        ALUSrcA   = 2'b01;      //SrcA is PC
        ALUSrcB    = 1;         //SrcB is imm
        ResultSrc = 2'b00;      // write the alu result in register
    end

    7'b0110111: begin
        RegWrite  = 1;
        ALUSrcA   = 2'b10;      //SrcA is 32'b00
        ALUSrcB    = 1;         //SrcB is imm
        ResultSrc = 2'b00;      // write the alu result in register
    end
    default: begin
        RegWrite = 0;
        MemWrite = 0;
        ALUSrcA = 2'b00;
        ALUSrcB   = 0;
        ResultSrc= 2'b00;
        Branch   = 0;
        jump     = 0;
        ALUOp    = 2'b00;
        MemRead   = 1'b0; 
    end
    endcase

end
   
endmodule
