`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.05.2026 22:52:32
// Design Name: 
// Module Name: mux_3_1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mux_3_1(
input logic [31:0] a,b,c,
input logic [1:0] s,
output logic [31:0] muxout
    );
    always_comb begin
     case (s)
        2'b00: muxout = a;
        2'b01: muxout = b;
        2'b10: muxout = c;
        default: muxout = 32'b0;   // 🔥 MUST ADD
    endcase
    end
   
endmodule
