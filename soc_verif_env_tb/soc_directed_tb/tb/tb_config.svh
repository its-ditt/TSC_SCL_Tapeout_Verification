// ============================================================
// Full-SoC directed verification configuration
// ============================================================

localparam time CLK_PERIOD = 10ns;

localparam int PROGRAM_WORDS = 190;
localparam int IMEM_WORDS    = 1024;
localparam int DMEM_WORDS    = 1024;

localparam logic [31:0] DATA_BASE    = 32'h00000100;
localparam logic [31:0] RESULT_BASE  = 32'h00000200;
localparam logic [31:0] EDGE_BASE    = 32'h00000300;
localparam logic [31:0] EDGE_SCRATCH = 32'h00000380;
localparam logic [31:0] DONE_ADDR    = 32'h000003F0;
localparam logic [31:0] DONE_VALUE   = 32'h00000001;

localparam int RESULT_LAST_OFFSET = 164;
localparam int EDGE_LAST_OFFSET   = 64;

localparam int MAX_RUN_CYCLES = 10000;
localparam int REFERENCE_MAX_STEPS = 10000;

localparam int MAIN_SIGNATURE_COUNT = 40;
localparam int EDGE_SIGNATURE_COUNT = 17;

localparam logic [31:0] RV32I_NOP = 32'h00000013;
