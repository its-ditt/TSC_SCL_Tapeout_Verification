`timescale 1ns / 1ps

module MUX_2_1(
    input logic [31:0] a,b,
    input logic sel,
    output logic [31:0] c
);

assign c = (sel)?b:a;

endmodule
