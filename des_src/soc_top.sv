module soc_top( 
    input  logic        clk,
    input  logic        rst_n,
    output logic [31:0] debug_out,
//Byte Loading
    input  logic        load_mode,    // 1 = boot-load mode, 0 = run mode both rst_n and load can cause the core to reset
    input  logic [7:0]  data_in,
    input  logic        byte_strobe  //Tells the loader when to sample the input byte
); 

//Pipeline Instruction Bus
logic [31:0] INSTR_ADDR; 
logic [35:0] INSTR; //36 bits because of macro, first 4 bits dropped before injection into processor

//Byte loader
logic        core_rst_n;
logic [11:0] ldr_waddr;
logic [31:0] ldr_wdata;
logic        ldr_we;

//Imem Macro
logic [ 9:0] IMEM_ADDR;
logic [31:0] IMEM_WDATA;
logic        IMEM_WE;

//AXI
logic        MEM_WRITE;
logic        MEM_READ;
logic        MEM_READY;
logic [31:0] MEM_ADDR;
logic [31:0] MEM_WDATA;
logic [ 3:0] MEM_WSTRB;
logic [31:0] MEM_RDATA;


byte_loader instr_in(
    .ext_clk     (clk),
    .ext_rst_n   (rst_n),
    .load_mode   (load_mode),
    .data_in     (data_in),
    .byte_strobe (byte_strobe),
    
    .core_rst_n  (core_rst_n),
    .instr_waddr (ldr_waddr),
    .instr_wdata (ldr_wdata),
    .instr_we    (ldr_we)
);

mem_port_mux instr_mux(
    .load_mode   (load_mode),
    .ldr_addr    (ldr_waddr),
    .ldr_we      (ldr_we),
    .ldr_wdata   (ldr_wdata),
    .core_addr   (INSTR_ADDR),
    .mem_addr    (IMEM_ADDR),
    .mem_we      (IMEM_WE),
    .mem_wdata   (IMEM_WDATA)

);

pipeline_top cpu (

    .clk(clk),
    .rst_n(core_rst_n),
    .debug_out(debug_out),
     
     //AXI
    .MEM_WRITE   (   MEM_WRITE),
    .MEM_READ    (    MEM_READ),
    .MEM_READY   (   MEM_READY),
    .MEM_ADDR    (    MEM_ADDR),
    .MEM_WDATA   (   MEM_WDATA),
    .MEM_WSTRB   (   MEM_WSTRB),
    .MEM_RDATA   (   MEM_RDATA),
    
    //Imem Macro
    .INSTR_ADD(INSTR_ADDR),
    .INSTR(INSTR[31:0])
);

// ========================================
// AXI SUBSYSTEM
// ========================================
AXI_TOP axi_top (

    .clk            (clk),
    .rst_n          (rst_n),

    .mem_addr       (MEM_ADDR),
    .mem_wdata      (MEM_WDATA),
    .mem_wstrb      (MEM_WSTRB),

    .mem_we         (MEM_WRITE),
    .mem_re         (MEM_READ),

    .mem_rdata      (MEM_RDATA),
    .mem_ready      (MEM_READY)

);

//Data_RAM Imem(
//    .clk        (clk),
//    .addr       (IMEM_ADD),
//    .write_data (IMEM_WDATA),
//    .wstrb      (4'b1111),
//    .read_en    (~IMEM_WE),
//    .write_en   (IMEM_WE),
//    .read_data  (INSTR)
//);

SPRAM_1024x36 Imem( //All Signals active low
    .A          (IMEM_ADDR),
    .CE         (clk),
    .WEB        (~IMEM_WE),
    .OEB        (IMEM_WE),  
    .CSB        (1'b0),
    .I          ({4'b0000,IMEM_WDATA}), //4 padding bits + 32bits of Instruction
    .O          (INSTR)
);
endmodule