`timescale 1ns / 1ps

module inst_memory(
    input logic clk,
    input logic rst_n,
    input  logic [31:0] A,
    
    //Imem Macro Signals
    output logic [31:0] INSTR_ADD, 
    input  logic [31:0] INSTR,     
    
    output logic [31:0] RD
);

assign INSTR_ADD = A;    

logic allow_instr;

always_ff @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        allow_instr <= 1'b0;
    else
        allow_instr = 1'b1;
end
    
assign RD = (allow_instr)? INSTR: 32'h13;

endmodule
