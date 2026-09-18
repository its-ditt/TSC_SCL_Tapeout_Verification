`timescale 1ns / 1ps
// ============================================================================
// Module AXI_TOP
// ----------------------------------------------------------------------------
// AXI4-Lite + APB4 SoC Subsystem
//
// Architecture
// ----------------------------------------------------------------------------
// CPU memory interface
//        |
//        v
// AXI_Manager
//        |
//        v
// AXI_Interconnect
//   |                       
//   |                      
//   v                     
// AXI_RAM 
//
// Memory Map
// ----------------------------------------------------------------------------
// 0x0000_0000 - 0x0000_0FFF : RAM  (AXI)
//
// Reset convention
// ----------------------------------------------------------------------------
// rst_n = 0 : synchronous reset active
// rst_n = 1 : normal operation
// ============================================================================

module AXI_TOP #(

    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(

    input clk, 
    input rst_n,

    input [ADDR_WIDTH - 1:0]    mem_addr,
    input [DATA_WIDTH - 1:0]    mem_wdata,
    input [DATA_WIDTH/8 - 1:0]  mem_wstrb,
    input                       mem_we,
    input                       mem_re,
    output [DATA_WIDTH - 1:0]   mem_rdata,
    output                      mem_ready
);

    // ==============================================
    // AXI MANAGER INTERFACE
    // ==============================================

    // ================= WRITE ADDRESS ==============
    logic [ADDR_WIDTH - 1:0] m_axi_awaddr;
    logic                    m_axi_awvalid;
    logic                    m_axi_awready;

    // ================= WRITE DATA ==============
    logic [DATA_WIDTH - 1:0] m_axi_wdata;
    logic [DATA_WIDTH/8-1:0] m_axi_wstrb;
    logic                    m_axi_wvalid;
    logic                    m_axi_wready;

    // ================= WRITE RESPONSE ==============
    logic [1:0]              m_axi_bresp;
    logic                    m_axi_bvalid;
    logic                    m_axi_bready;

    // ================= READ ADDRESS ==============
    logic [ADDR_WIDTH - 1:0] m_axi_araddr;
    logic                    m_axi_arvalid;
    logic                    m_axi_arready;

    // ================= READ DATA ==============
    logic [DATA_WIDTH - 1:0] m_axi_rdata;
    logic [1:0]              m_axi_rresp;
    logic                    m_axi_rvalid;
    logic                    m_axi_rready;

    // ==============================================
    // RAM SLAVE AXI
    // ==============================================
    logic [ADDR_WIDTH - 1:0] ram_axi_awaddr;
    logic                    ram_axi_awvalid;
    logic                    ram_axi_awready;

    logic [DATA_WIDTH - 1:0] ram_axi_wdata;
    logic [DATA_WIDTH/8-1:0] ram_axi_wstrb;
    logic                    ram_axi_wvalid;
    logic                    ram_axi_wready;

    logic [1:0]              ram_axi_bresp;
    logic                    ram_axi_bvalid;
    logic                    ram_axi_bready;

    logic [ADDR_WIDTH - 1:0] ram_axi_araddr;
    logic                    ram_axi_arvalid;
    logic                    ram_axi_arready;

    logic [DATA_WIDTH - 1:0] ram_axi_rdata;
    logic [1:0]              ram_axi_rresp;
    logic                    ram_axi_rvalid;
    logic                    ram_axi_rready;

    // =========================================================================
    // AXI MANAGER
    // =========================================================================

    AXI_Manager manager (

        .clk                (clk),
        .rst_n              (rst_n),

        .mem_addr           (mem_addr),
        .mem_wdata          (mem_wdata),
        .mem_wstrb          (mem_wstrb),
        .mem_we             (mem_we),
        .mem_re             (mem_re),
        .mem_rdata          (mem_rdata),
        .mem_ready          (mem_ready),

        // WRITE ADDRESS
        .axi_awaddr         (m_axi_awaddr),
        .axi_awvalid        (m_axi_awvalid),
        .axi_awready        (m_axi_awready),

        // WRITE DATA
        .axi_wdata          (m_axi_wdata),
        .axi_wstrb          (m_axi_wstrb),
        .axi_wvalid         (m_axi_wvalid),
        .axi_wready         (m_axi_wready),

        // WRITE RESPONSE
        .axi_bresp          (m_axi_bresp),
        .axi_bvalid         (m_axi_bvalid),
        .axi_bready         (m_axi_bready),

        // READ ADDRESS
        .axi_araddr         (m_axi_araddr),
        .axi_arvalid        (m_axi_arvalid),
        .axi_arready        (m_axi_arready),
        
        // READ DATA
        .axi_rdata          (m_axi_rdata),
        .axi_rresp          (m_axi_rresp),
        .axi_rvalid         (m_axi_rvalid),
        .axi_rready         (m_axi_rready)
    );

    // =========================================================================
    // AXI RAM SLAVE
    // =========================================================================
    AXI_RAM_Slave ram_slave (

        .clk                 (clk),
        .rst_n               (rst_n),

        .s_axi_awaddr       (m_axi_awaddr),
        .s_axi_awvalid      (m_axi_awvalid),
        .s_axi_awready      (m_axi_awready),

        .s_axi_wdata        (m_axi_wdata),
        .s_axi_wstrb        (m_axi_wstrb),
        .s_axi_wvalid       (m_axi_wvalid),
        .s_axi_wready       (m_axi_wready),

        .s_axi_bresp        (m_axi_bresp),
        .s_axi_bvalid       (m_axi_bvalid),
        .s_axi_bready       (m_axi_bready),

        .s_axi_araddr       (m_axi_araddr),
        .s_axi_arvalid      (m_axi_arvalid),
        .s_axi_arready      (m_axi_arready),

        .s_axi_rdata        (m_axi_rdata),
        .s_axi_rresp        (m_axi_rresp),
        .s_axi_rvalid       (m_axi_rvalid),
        .s_axi_rready       (m_axi_rready)
    ); 
endmodule