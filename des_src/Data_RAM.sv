`timescale 1ns / 1ps
module SPRAM_1024x36 (
    input  logic         CE,     // clock (rising edge)
    input  logic         CSB,    // active-low chip select
    input  logic         WEB,    // active-low write enable
    input  logic         OEB,    // active-low output enable
    input  logic [9:0]   A,      // address
    input  logic [35:0]  I,      // write data
    output logic [35:0]  O       // read data (registered)
);

    // memory array
    logic [35:0] mem [1024];
    logic OEB_delay;
    // registered read data (internal, before OEB tri-state mux)
    logic [35:0] dout_reg;

    // synchronous read/write logic
    always_ff @(posedge CE) begin
        OEB_delay <= OEB;
        if (!CSB) begin
            if (!WEB)
                mem[A] <= I;        // write cycle
            else
                dout_reg <= mem[A]; // read cycle - registered
        end
        // if CSB=1 (deselected), dout_reg holds
    end

    // output enable mux - tri-state when OEB=1
    assign O = (!OEB_delay) ? dout_reg : 36'bz;

endmodule