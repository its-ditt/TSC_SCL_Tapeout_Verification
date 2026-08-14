module data_mem_stage(
    input  logic        clk,
    input  logic        rst,
    input  logic        RegWriteM,
    input  logic [ 1:0] ResultSrcM,
    input  logic        MemWriteM,
    input  logic        MemReadM,
    input  logic [31:0] ALUResultM,
    input  logic [31:0] WriteDataM,
    input  logic [ 2:0] funct3M,
    input  logic [ 4:0] RdM,
    input  logic [31:0] PcPlus4M,
    output logic [31:0] ReadDataW,
    output logic        RegWriteW,
    output logic [ 1:0] ResultSrcW,
    output logic [31:0] ALUResultW,
    output logic [ 4:0] RdW,
    output logic [31:0] PcPlus4W,
    output logic        data_bus_stall,      // ADD THIS PORT

    //AXI INTERFACE 

    output logic        MEM_WRITE,
    output logic        MEM_READ,
    input  logic        MEM_READY,
    output logic [31:0] MEM_ADDR,
    output logic [31:0] MEM_WDATA,
    output logic [ 3:0] MEM_WSTRB,
    input  logic [31:0] MEM_RDATA
   
   
);


logic [31:0] ReadDataM;


jtsc_dmem data_mem (
    .clk(clk),
    .rst(rst),
    .A(ALUResultM),
    .WD(WriteDataM),
    .MemWrite(MemWriteM),
    .MemRead(MemReadM),
    .funct3M(funct3M),
    .RD(ReadDataM),
    .StallMem(data_bus_stall),

    //AXI
    .MEM_WRITE(MEM_WRITE),
    .MEM_READ(MEM_READ),
    .MEM_READY(MEM_READY),
    .MEM_ADDR(MEM_ADDR),
    .MEM_WDATA(MEM_WDATA),
    .MEM_WSTRB(MEM_WSTRB),
    .MEM_RDATA(MEM_RDATA)
//    .axi_err(axi_err)
    );
    
    
always_ff @(posedge clk or negedge rst)
begin
    if (!rst)
    begin
        RegWriteW  <= 0;
        ResultSrcW <= 0;
        ALUResultW <= 0;
        ReadDataW  <= 32'd0;
        RdW        <= 0;
        PcPlus4W   <= 0;
    end

    else if (data_bus_stall)
    begin
        
    end

    else
    begin
        RegWriteW  <= RegWriteM;
        ResultSrcW <= ResultSrcM;
        ALUResultW <= ALUResultM;
        ReadDataW  <= ReadDataM;
        RdW        <= RdM;
        PcPlus4W   <= PcPlus4M;
    end
end
endmodule