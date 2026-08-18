`timescale 1ns / 1ps

module Pc_Module(
    input logic clk,rst,
    input logic StallF,
    input logic [31:0] Pc_next,
    output logic [31:0] Pc
);

always_ff @(posedge clk or negedge rst)
    if(!rst)
        Pc <= 32'h00000000;
    else if (!StallF)
        Pc <= Pc_next;
    else Pc <= Pc;
    
endmodule
