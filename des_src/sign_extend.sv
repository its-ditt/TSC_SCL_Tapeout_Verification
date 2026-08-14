`timescale 1ns / 1ps

module sign_extend(
    input logic [31:0]Instr,
    output logic [31:0] ImmExtend
);

always_comb
begin
    case(Instr[6:0])
       
    //I - Type load
    7'b0000011: ImmExtend = {{20{Instr[31]}},Instr[31:20]};
    
    //I - Type like addi,subi
    7'b0010011: ImmExtend = {{20{Instr[31]}},Instr[31:20]};
        
    //I - Type JALR
    7'b1100111: ImmExtend = {{20{Instr[31]}},Instr[31:20]};
       
    //S - Type Store
    7'b0100011: ImmExtend = {{20{Instr[31]}},Instr[31:25],Instr[11:7]};
        
    //SB - Type Branch
    7'b1100011: ImmExtend = {{19{Instr[31]}},Instr[31],Instr[7],Instr[30:25],Instr[11:8],1'b0};
        
    //J  - Type JAL
    7'b1101111: ImmExtend = {{12{Instr[31]}},Instr[19:12],Instr[20],Instr[30:21],1'b0};
        
    //U - Type LUI 
    7'b0110111: ImmExtend = {Instr[31:12],12'b0};
        
    //U - Type AUIPC
    7'b0010111: ImmExtend = {Instr[31:12],12'b0};
        
    default   : ImmExtend = 32'b00;
    endcase
end
endmodule
