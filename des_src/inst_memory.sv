`timescale 1ns / 1ps

module inst_memory(
    input  logic [31:0] A,
    
    //Imem Macro Signals
    output logic [31:0] INSTR_ADD, //In Simulation this will be one cycle earlier
    input  logic [31:0] INSTR,     //When compared with INSTR
    
    output logic [31:0] RD
);
    
    
assign INSTR_ADD = A;    
assign RD = INSTR;

endmodule
