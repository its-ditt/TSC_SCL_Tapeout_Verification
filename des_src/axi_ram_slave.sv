`timescale 1ns / 1ps
// ============================================================================
// Module AXI_RAM_Slave
// ----------------------------------------------------------------------------
// AXI4-Lite RAM Slave
//
// Features
// ----------------------------------------------------------------------------
// + AXI4-Lite compliant
// + Active-LOW reset
// + External Data_RAM 
// + Clean READY generation (combinational)
// + Same-cycle AW/W support
// + Back-to-back transaction safe
//
// Memory Map
// ----------------------------------------------------------------------------
// 00x0000_0000 ~ 0x0000_0FFF
//
// ============================================================================

module AXI_RAM_Slave #(

    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 1024

)(
    input logic                       clk,
    input logic                       rst_n,          // Active LOW

    // =====================================================
    // WRITE ADDRESS CHANNEL
    // =====================================================
    input  logic [ADDR_WIDTH - 1:0]   s_axi_awaddr,
    input  logic                      s_axi_awvalid,
    output logic                      s_axi_awready,

    // =====================================================
    // WRITE DATA CHANNEL
    // =====================================================
    input  logic [DATA_WIDTH - 1:0]   s_axi_wdata,
    input  logic [DATA_WIDTH/8-1:0]   s_axi_wstrb,
    input  logic                      s_axi_wvalid,
    output logic                      s_axi_wready,

    // =====================================================
    // WRITE RESPONSE CHANNEL
    // =====================================================
    output logic [1:0]               s_axi_bresp,
    output logic                     s_axi_bvalid,
    input  logic                     s_axi_bready,

    // =====================================================
    // READ ADDRESS CHANNEL
    // =====================================================
    input  logic [ADDR_WIDTH - 1:0]  s_axi_araddr,
    input  logic                     s_axi_arvalid,
    output logic                     s_axi_arready,

    // =====================================================
    // READ DATA CHANNEL
    // =====================================================
    output logic [DATA_WIDTH - 1:0]  s_axi_rdata,
    output logic [1:0]               s_axi_rresp,
    output logic                     s_axi_rvalid,
    input  logic                     s_axi_rready
);

    // =====================================================
    // AXI RESPONSE
    // =====================================================

    localparam RESP_OKAY   = 2'b00;
    localparam RESP_SLVERR = 2'b10;

    // =====================================================
    // WRITE FSM
    // =====================================================

    localparam WR_IDLE        = 2'd0;
    localparam WR_WAIT_RESP   = 2'd1;
    localparam WR_RMW         = 2'd2;
    logic [1:0] wr_state;

    // =====================================================
    // READ FSM
    // =====================================================

    localparam RD_IDLE   = 1'd0;
    localparam RD_VALID  = 1'd1;

    logic rd_state;

    // =====================================================
    // WRITE CHANNEL REGISTERS
    // =====================================================

    logic [31:0] awaddr_reg;
    logic [31:0] wdata_reg;
    logic [3:0]  wstrb_reg;

    logic        aw_done;
    logic        w_done;
    

    // =====================================================
    // READ CHANNEL REGISTERS
    // =====================================================
    
    logic        rd_err;

    // =====================================================
    // RAM INTERFACE
    // =====================================================

    logic  [31:0] ram_addr;
    logic  [31:0] ram_wdata;
    logic         ram_we;
    logic         ram_re;
    
    logic [31:0] ram_rdata;
    logic [35:0] ram_rdata_ext;

    // =====================================================
    // HANDSHAKE DETECT
    // =====================================================
    logic aw_fire;
    logic w_fire;
    logic ar_fire;
    logic aw_viable;
    logic w_viable;

    assign aw_fire = s_axi_awvalid && s_axi_awready;
    assign w_fire  = s_axi_wvalid && s_axi_wready;
    assign ar_fire = s_axi_arvalid && s_axi_arready;

    assign aw_viable = aw_fire || aw_done;
    assign w_viable  = w_fire  || w_done;
    
// =====================================================
// READY GENERATION
// =====================================================
    assign s_axi_awready = (wr_state == WR_IDLE) && !aw_done;
    assign s_axi_wready  = (wr_state == WR_IDLE) && !w_done;
    assign s_axi_arready = (rd_state == RD_IDLE) && ((wr_state == WR_IDLE && !(aw_viable && w_viable)) || wr_state == WR_WAIT_RESP);
            
    // =====================================================
    // Same Cycle support
    // =====================================================
    logic [31:0] awaddr_now;
    logic [31:0] wdata_now;
    logic [ 3:0] wstrb_now;

    assign awaddr_now = (aw_fire)? s_axi_awaddr : awaddr_reg;
    assign wdata_now  = ( w_fire)? s_axi_wdata  : wdata_reg;
    assign wstrb_now  = ( w_fire)? s_axi_wstrb  : wstrb_reg;
    
    // =====================================================
    // ADDRESS VALID
    // =====================================================

    function automatic addr_valid;
        input [31:0] addr;
        begin
            addr_valid =
                (addr[31:12] == 20'h00000);
        end
    endfunction
    
    // =====================================================
    // DATA RAM
    // =====================================================

//    Data_RAM data_ram (

//        .clk        (clk),
//        .addr       (ram_addr[10:0] ),
//        .write_data (ram_wdata),
//        .wstrb      (4'b1111),
//        .read_en    (ram_re),
//        .write_en   (ram_we),
//        .read_data  (ram_rdata)

//    );


    SPRAM_1024x36 Dmem(
        .A          (ram_addr[11:2]),
        .CE         (clk),
        .WEB        (~ram_we),
        .OEB        (~ram_re),
        .CSB        (~(ram_re | ram_we)),
        .I          ({4'b0000,ram_wdata}),
        .O          (ram_rdata_ext)
    );

logic [31:0] merged_data;

    always_comb begin
        merged_data = ram_rdata_ext[31:0];
        if (wstrb_now[0])
            merged_data[7:0] = wdata_reg[7:0];
        if (wstrb_now[1])
            merged_data[15:8] = wdata_reg[15:8];
        if (wstrb_now[2])
            merged_data[23:16] = wdata_reg[23:16];
        if (wstrb_now[3])
            merged_data[31:24] = wdata_reg[31:24];
    end

    // =====================================================
    // WRITE FSM
    // =====================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= RESP_OKAY;

            awaddr_reg   <= 32'b0;
            wdata_reg    <= 32'b0;
            wstrb_reg    <= 4'b0; 

            aw_done      <= 1'b0;
            w_done       <= 1'b0;

            wr_state     <= WR_IDLE;
        end
        else begin
            // -------------------------------------------------
            // Capture AW
            // -------------------------------------------------
            if (aw_fire) begin
                awaddr_reg <= s_axi_awaddr;
                aw_done    <= 1'b1;
            end

            // -------------------------------------------------
            // Capture W
            // -------------------------------------------------

            if (w_fire) begin
                wdata_reg <= s_axi_wdata;
                wstrb_reg <= s_axi_wstrb;
                w_done    <= 1'b1;
            end

            // -------------------------------------------------
            // FSM
            // -------------------------------------------------

            case (wr_state)
                // =============================================
                // IDLE
                // =============================================
                WR_IDLE: begin
                    if (aw_viable && w_viable) begin
                        // INVALID ADDRESS
                        if (!addr_valid(awaddr_now)) begin
                            s_axi_bresp  <= RESP_SLVERR;
                            s_axi_bvalid <= 1'b1;
                            wr_state <= WR_WAIT_RESP;
                        end
                        // FULL WRITE: ram_we issued this cycle 
                        else if (wstrb_now == 4'b1111) begin
                            s_axi_bresp  <= RESP_OKAY;
                            s_axi_bvalid <= 1'b1;
                            wr_state <= WR_WAIT_RESP;
                        end
                        //PARTIAL WRITES: ram_re issued this cycle
                        else begin
                            wr_state <= WR_RMW;
                        end
                    end
                end
                
                // =============================================
                // RMW: ram_rdata_ext now valid, merged_data
                // computed combinationally, ram_we issued this cycle
                // =============================================
                WR_RMW: begin
                    s_axi_bresp  <= RESP_OKAY;
                    s_axi_bvalid <= 1'b1;
                    wr_state     <= WR_WAIT_RESP;
                end
                
                // =============================================
                // WAIT RESPONSE
                // =============================================
                WR_WAIT_RESP: begin
                    if (s_axi_bvalid && s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        aw_done <= 1'b0;
                        w_done  <= 1'b0;
                        wr_state <= WR_IDLE;
                    end
                end
                default: begin
                    wr_state <= WR_IDLE;
                end
            endcase
        end
    end
    // =====================================================
    // READ FSM
    // =====================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= RESP_OKAY;
            
            rd_err       <= 1'b0;

            rd_state     <= RD_IDLE;
        end
        else begin
            case (rd_state)
                // =============================================
                // IDLE
                // =============================================
                RD_IDLE: begin
                    if (ar_fire) begin                        
                        rd_err       <= !addr_valid(s_axi_araddr);
                        
                        s_axi_rresp  <= addr_valid(s_axi_araddr) ? RESP_OKAY : RESP_SLVERR;
                        s_axi_rvalid <= 1'b1;
                        
                        rd_state     <= RD_VALID;
                    end
                end
                
                // =============================================
                // VALID
                // =============================================
                RD_VALID: begin
                    if (s_axi_rvalid && s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;

                        rd_state     <= RD_IDLE;
                    end
                end
                default: begin
                    rd_state <= RD_IDLE;
                end
            endcase
        end
    end
    // =====================================================
    // RAM CONTROL
    // =====================================================
    always_comb begin
        ram_addr  = 32'b0;
        ram_wdata = 32'b0;
        ram_we    = 1'b0;
        ram_re    = 1'b0;
        
      s_axi_rdata = rd_err ? 32'b0 : ram_rdata_ext[31:0];
    // =============================================
    //FULL WRITE
    //==============================================
        if(wr_state == WR_IDLE && aw_viable && w_viable &&
           addr_valid(awaddr_now) && (wstrb_now == 4'b1111)) begin
            ram_addr  = awaddr_now;
            ram_wdata = wdata_now;
                    
            ram_we = 1'b1;
        end
     // =============================================
     //PARTIAL WRITE
     //==============================================   
        else if (wr_state == WR_IDLE && aw_viable && w_viable &&
                 addr_valid(awaddr_now) && !(&wstrb_now)) begin
            ram_addr = awaddr_now;
            ram_re   = 1'b1;
        end            
        
        else if (wr_state == WR_RMW) begin
            ram_addr  = awaddr_now;
            ram_wdata = merged_data;
            ram_we    = 1'b1;
        end

            // =============================================
            // READ FSM OWNS BUS
            // =============================================
        else if(rd_state == RD_IDLE && ar_fire) begin
            ram_addr = s_axi_araddr;
            ram_re = 1'b1;
        end
    end    
    
endmodule