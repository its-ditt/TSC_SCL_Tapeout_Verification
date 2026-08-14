`timescale 1ns / 1ps

module ALU_Decoder(
    input  logic       op,    //the 5th bit of op to differ R from I type
    input  logic [2:0] funct3,
    input  logic       funct7,//the 5th bit of funct7
    input  logic [1:0] ALUOp,
    output logic [3:0] ALUControl
    );

always_comb begin
    case (ALUOp)
    //load,store,AUIPC,LUI add
    2'b00 : ALUControl = 4'b0000;
    //branch
    2'b01 :
    begin
        case(funct3)
        3'b000: ALUControl = 4'b0001;   //sub for beq
        3'b001: ALUControl = 4'b0001;   //sub for bne
        3'b100: ALUControl = 4'b1001;   //slt for blt
        3'b101: ALUControl = 4'b1001;   //slt for bge
        3'b110: ALUControl = 4'b1000;   //sltu for bltu
        3'b111: ALUControl = 4'b1000;   //sltu for bgeu
        default:ALUControl = 4'b0000;
        endcase
    end
    //R-type /I-type
    2'b10 : 
    begin
        case (funct3)  
        3'b000: 
        begin
            if({op,funct7} == 2'b11)
                ALUControl = 4'b0001;////for sub///
            else 
                ALUControl = 4'b0000;////for add///
        end
        3'b001: ALUControl = 4'b0101;//SLL
        3'b010: ALUControl = 4'b1000;//SLT
        3'b011: ALUControl = 4'b1001;//SLTU
        3'b100: ALUControl = 4'b0100;//XOR
        3'b101: 
        begin 
            if (funct7)
                ALUControl = 4'b0111; //SRA
            else
                ALUControl = 4'b0110;//SRL
        end
        3'b110: ALUControl = 4'b0011;//OR
        3'b111: ALUControl = 4'b0010;//AND 
        default:ALUControl = 4'b0000;
        endcase
    end  
    default:ALUControl = 4'b0000;
    endcase
end
endmodule
