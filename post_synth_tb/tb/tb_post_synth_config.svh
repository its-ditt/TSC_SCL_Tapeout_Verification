// ============================================================
// Post-synthesis gate-level verification configuration
// ============================================================
`ifndef TB_POST_SYNTH_CONFIG_SVH
`define TB_POST_SYNTH_CONFIG_SVH

localparam time CLK_PERIOD = 20ns; // 50 MHz

localparam int PROGRAM_WORDS = 190;
localparam int DMEM_WORDS    = 1024;

localparam logic [31:0] DONE_ADDR  = 32'h000003F0;
localparam logic [31:0] DONE_VALUE = 32'h00000001;

localparam int MAX_RUN_CYCLES = 10000;

localparam logic [31:0] RV32I_NOP = 32'h00000013;

`ifndef POSTSYN_SDF_FILE
`define POSTSYN_SDF_FILE "top_streamed_wrapper_chip.sdf"
`endif

// The synthesized hierarchy observed in the supplied Genus netlist is:
// tb_post_synth.dut -> soc_top_wrapper dut -> soc_top dut
`ifndef SOC_HIER
`define SOC_HIER dut.dut
`endif

`endif
