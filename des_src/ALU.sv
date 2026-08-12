`timescale 1ns/1ps

module ALU(
    input logic [31:0]SrcAE,
    input logic [31:0]SrcBE,
    input logic [3:0]ALUControlE,
    output logic [31:0]ALUResult,
    output logic zeroE,
    output logic less_thanE
);

always_comb begin

case(ALUControlE)

4'b0000:ALUResult=SrcAE+SrcBE;
4'b0001:ALUResult=SrcAE-SrcBE;

4'b0010:ALUResult=SrcAE&SrcBE;
4'b0011:ALUResult=SrcAE|SrcBE;
4'b0100:ALUResult=SrcAE^SrcBE;

4'b0101:ALUResult=SrcAE<<SrcBE[4:0];
4'b0110:ALUResult=SrcAE>>SrcBE[4:0];
4'b0111:ALUResult=$signed(SrcAE)>>>SrcBE[4:0];

4'b1000:ALUResult= (SrcAE<SrcBE)?32'd1:32'd0;

4'b1001:ALUResult= ($signed(SrcAE)<$signed(SrcBE))
?32'd1:32'd0;

default:ALUResult=32'h00000000;

endcase

zeroE=(ALUResult==32'd0);
less_thanE = ALUResult[0];
end

endmodule