`timescale 1ns / 1ps
// ======================================================
// AXI Manager Module
// + AXI Manager
// + AXI4-Lite Version
//
// ------------------------------------------------------
// Function
// + Receives simple requests from the CPU: addr, data, we, re
// --> Converts them into AXI signals: AW, W, B, AR, R
//
// ------------------------------------------------------
// The AXI channels are controlled by an FSM
// ======================================================

module AXI_Manager #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input logic                      clk,
    input logic                      rst_n,

    // =============== CPU Interface ===============
    input logic [ADDR_WIDTH - 1:0]   mem_addr,
    input logic [DATA_WIDTH - 1:0]   mem_wdata,
    input logic [DATA_WIDTH/8 - 1:0] mem_wstrb,        // Byte enables from the CPU (for SB/SH/SW)
    input logic                      mem_we,
    input logic                      mem_re,
    output logic [DATA_WIDTH - 1:0]  mem_rdata,
    output logic                     mem_ready,       // Indicates that a transaction has completed

    // =============== AXI Write Address ===============
    output logic [ADDR_WIDTH - 1:0]  axi_awaddr,
    output logic                     axi_awvalid,
    input  logic                     axi_awready,

    // =============== AXI Write Data ===============
    output logic [DATA_WIDTH - 1:0]  axi_wdata,
    output logic [DATA_WIDTH/8 - 1:0] axi_wstrb,    // Indicates which bytes of WDATA are valid and should be written (32/8 = 4 bytes)
    output logic                     axi_wvalid,
    input  logic                     axi_wready,

    // =============== AXI Write Response ===============
    input  logic [1:0]               axi_bresp,
    input  logic                     axi_bvalid,
    output logic                     axi_bready,

    // =============== AXI Read Address ===============
    output logic [ADDR_WIDTH - 1:0] axi_araddr,
    output logic                    axi_arvalid,
    input  logic                    axi_arready,

    // =============== AXI Read Data ===============
    input  logic [DATA_WIDTH - 1:0] axi_rdata,
    input  logic [1:0]              axi_rresp,
    input  logic                    axi_rvalid,
    output logic                    axi_rready
);

    // =============== FSM STATE ===============
    localparam [2:0] IDLE         = 3'b000;
    localparam [2:0] WRITE_CHAN   = 3'b001;     // Write Channel Race Condition
    localparam [2:0] WRITE_RESP   = 3'b010;
    localparam [2:0] READ_ADDR    = 3'b011;
    localparam [2:0] READ_DATA    = 3'b100;
    
    logic [2:0] state;

    // =============== MAIN FSM ===============
    logic aw_done;        // Indicates that the AW channel handshake has completed
    logic w_done;         // Indicates that the W channel handshake has completed
    always_ff @(posedge clk or negedge rst_n) begin
        
        if (!rst_n) begin
            state       <= IDLE;
            
            axi_wdata   <= 0;
            axi_awaddr  <= 0;
            axi_awvalid <= 0;
            axi_wvalid  <= 0;
            axi_bready  <= 0;
            axi_araddr  <= 0;
            axi_arvalid <= 0;
            axi_rready  <= 0;
            axi_wstrb   <= 0;

            aw_done     <= 0;
            w_done      <= 0;

            mem_ready   <= 0;
            mem_rdata   <= 0;
        end

        // DEFAULT
        else begin
            mem_ready   <= 0;

            case (state)

                // =============== IDLE ===============
                IDLE: begin
                    // WRITE ADDRESS
                    if (mem_we) begin
                        // Setup write
                        axi_awaddr  <= mem_addr;
                        axi_awvalid <= 1;

                        axi_wdata   <= mem_wdata;
                        axi_wvalid  <= 1;

                        axi_wstrb   <= mem_wstrb;       // Byte enables from CPU (SB/SH/SW)

                        aw_done     <= 0;
                        w_done      <= 0;

                        state       <= WRITE_CHAN;
                    end

                    // READ ADDRESS
                    else if (mem_re) begin
                        // Setup read
                        axi_araddr  <= mem_addr;
                        axi_arvalid <= 1;

                        state       <= READ_ADDR;
                    end
                end

                // =============== WRITE ADDRESS + WRITE DATA ===============
                /*
                    WRITE_CHAN: Handles the AW and W channels in parallel.
                
                    + In AXI, AW and W are independent channels, so their
                    handshakes may occur in the same cycle or in different cycles.
                
                    + The FSM transitions to the Write Response state only
                    after both the AW and W handshakes have completed.
                */
                WRITE_CHAN: begin
                    // AW Handshake
                    if (axi_awvalid && axi_awready) begin
                        axi_awvalid <= 0;
                        aw_done     <= 1;
                    end

                    // W Handshake
                    if (axi_wvalid && axi_wready) begin
                        axi_wvalid  <= 0;
                        w_done      <= 1;
                    end

                    if ((aw_done || (axi_awvalid && axi_awready)) && (w_done || (axi_wvalid && axi_wready))) begin
                        axi_bready  <= 1;
                        state       <= WRITE_RESP;       // Indicates that the master is ready to receive the write response from the slave
                    end
                end

                // =============== WRITE RESPONSE ===============
                WRITE_RESP: begin
                    if (axi_bvalid && axi_bready) begin
                        axi_bready  <= 0;

                        mem_ready   <= 1;
                        state       <= IDLE;
                    end
                end

                // =============== READ ADDR ===============
                READ_ADDR: begin
                    if (axi_arready && axi_arvalid) begin
                        axi_arvalid <= 0;

                        axi_rready  <= 1;           // Indicates that the master is ready to receive read data from the slave
                        state       <= READ_DATA;
                    end
                end

                // =============== READ DATA ===============
                READ_DATA: begin
                    if (axi_rvalid) begin
                        mem_rdata   <= axi_rdata;

                        axi_rready  <= 0;
                        mem_ready   <= 1;

                        state       <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end

    end

endmodule