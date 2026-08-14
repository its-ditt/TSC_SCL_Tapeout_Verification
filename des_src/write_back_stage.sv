`timescale 1ns / 1ps

module write_back_stage(
    input logic [1:0] ResultSrcW,

    input logic [31:0] ALUResultW,
    input logic [31:0] ReadDataW,
    input logic [31:0] PcPlus4W,

    output logic [31:0] ResultW
);

always_comb
begin
    case(ResultSrcW)
        2'b00:
            ResultW = ALUResultW;
        2'b01:
            ResultW = ReadDataW;
        2'b10:
            ResultW = PcPlus4W;
        default:
            ResultW = 32'd0;
    endcase
end
endmodule