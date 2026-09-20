`timescale 1ns / 1ps

module jtsc_dmem(
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] A,
    input  logic [31:0] WD,
    input  logic        MemWrite,
    input  logic        MemRead,
    input  logic [ 2:0] funct3M,
    output logic [31:0] RD,
    output logic        StallMem,

//AXI INTERFACE 

    output logic         MEM_WRITE,
    output logic         MEM_READ,
    input          MEM_READY,
    output logic  [31:0] MEM_ADDR,
    output logic  [31:0] MEM_WDATA,
    output logic  [ 3:0] MEM_WSTRB,
    input  logic  [31:0] MEM_RDATA
);

logic [31:0] mem_wdata;
logic [31:0] load_byte;
logic [31:0] load_half;
logic [3:0] wstrb_reg;
logic req_pending;

assign MEM_WRITE = (|wstrb_reg)? (MemWrite && !req_pending) : 1'b0;
assign MEM_READ = MemRead && !req_pending;
assign MEM_ADDR = A; 
assign MEM_WDATA = mem_wdata;
assign MEM_WSTRB = (MemWrite)? wstrb_reg : 4'b0000;
assign StallMem = (MemRead || MemWrite) && !((MEM_WRITE || MEM_READ || req_pending) && MEM_READY);

////////////////////////////////////////////////////
// SINGLE-CYCLE PULSE GENERATION FOR MEM_WRITE / MEM_READ
///////////////////////////////////////////////////

always_ff @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        req_pending <= 1'b0;
    else begin
        if((MemRead||MemWrite) && !req_pending && !MEM_READY)
            req_pending <= 1'b1;
        else if(req_pending && MEM_READY)
            req_pending <= 1'b0;
    end
end
////////////////////////////////////////////////////
//BYTE ENABLE
///////////////////////////////////////////////////

always_comb
begin 
    wstrb_reg = 4'b0000;
    mem_wdata  = 32'b0;
    if(MemWrite)
    begin
        if(funct3M == 3'b000)
        begin
            wstrb_reg = 4'b0001 << A[1:0];
            mem_wdata = {4{WD[7:0]}};
        end    
        else if (funct3M == 3'b001) 
        begin
            wstrb_reg = 4'b0011 << A[1:0];
            mem_wdata = {2{WD[15:0]}};
        end
        else if(funct3M == 3'b010) 
        begin
            wstrb_reg = 4'b1111;
            mem_wdata = WD;
        end
        else 
        begin
            wstrb_reg = 4'b0000;
            mem_wdata  = 32'b0;
        end
    end
    else wstrb_reg = 4'b0000;
    
    
end   

always_comb begin

    load_byte = MEM_RDATA >> (8*A[1:0]);
    load_half = MEM_RDATA >> (8*A[  0]);

    case(funct3M)

        3'b000: RD = {{24{load_byte[7]}}, load_byte[7:0]};   // LB
        3'b100: RD = {24'b0, load_byte[7:0]};                // LBU
        3'b001: RD = {{16{load_half[15]}}, load_half[15:0]}; // LH
        3'b101: RD = {16'b0, load_half[15:0]};               // LHU
        3'b010: RD = MEM_RDATA;                        // LW
        default: RD = 32'b0;
    endcase
end
endmodule