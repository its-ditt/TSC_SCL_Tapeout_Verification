`timescale 1ns / 1ps

module Pc_adder(
    input logic [31:0] PcF,
    output logic [31:0] PcF_4
);

assign PcF_4 = (PcF + 32'h00000004);

endmodule
