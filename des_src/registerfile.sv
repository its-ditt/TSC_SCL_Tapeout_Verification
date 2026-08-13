`timescale 1ns / 1ps

module registerfile(

    input  logic        clk,
    input  logic        rst,

    input  logic        WE3,
    input  logic [4:0]  A1,
    input  logic [4:0]  A2,
    input  logic [4:0]  A3,

    input  logic [31:0] WD3,

    output logic [31:0] RD1,
    output logic [31:0] RD2

);

    // 32 Registers of 32-bit each
logic [31:0] reg_file [31:0];

integer i;

    // Write Logic + Reset
always_ff @(posedge clk or negedge rst) begin

        // Active LOW asynchronous reset
    if(!rst) begin

        for(i = 0; i < 32; i = i + 1)
            reg_file[i] <= 32'd0;

    end

        // Write operation
    else if(WE3 && (A3 != 5'd0)) begin
        reg_file[A3] <= WD3;
    end

end

    // Read Port 1 with forwarding
assign RD1 = (A1 == 5'd0) ? 32'd0 :
             ((WE3 && (A3 == A1) && (A3 != 5'd0)) ? WD3 :
                  reg_file[A1]);

    // Read Port 2 with forwarding
assign RD2 = (A2 == 5'd0) ? 32'd0 :
             ((WE3 && (A3 == A2) && (A3 != 5'd0)) ? WD3 :
             reg_file[A2]);

endmodule