# Full-SoC RV32I Directed Verification Environment

This environment is intentionally written against the **current SoC RTL contract** and is designed to remain usable after RTL corrections.

## Verification philosophy

The TB does **not** compensate for known RTL weaknesses. Expected behavior is defined independently by:

1. a simple architectural RV32I reference model,
2. actual byte-loader behavior,
3. actual instruction SRAM timing,
4. AXI transaction monitoring,
5. interface assertions, and
6. final architectural state comparison.

Therefore a current RTL defect should appear as a TB failure rather than being masked by the testbench.

## Structure

- `tb/tb_soc_top.sv` — simulation top and phase control
- `tb/tb_config.svh` — addresses, sizes, limits
- `tb/tb_program_loader.svh` — drives the real `byte_loader` pins
- `tb/tb_reference_model.svh` — non-cycle-accurate architectural model
- `tb/tb_axi_monitor.svh` — CPU-memory and AXI transaction checks
- `tb/tb_processor_monitor.svh` — fetch/forward/control checks
- `tb/tb_scoreboard.svh` — final register/memory/AXI scoreboard
- `tb/tb_assertions.svh` — fundamental SVA checks
- `tb/tb_coverage.svh` — basic functional coverage
- `tb/program_image.svh` — compiled program words, avoiding runtime `$readmemh` path dependence
- `programs/rv32i_directed.S` — readable assembly source
- `programs/program.hex` — generated 32-bit instruction words
- `programs/program.lst` — generated address/hex listing
- `tools/assemble_rv32i.py` — small assembler for the supported RV32I subset plus `nop`/`la` pseudoinstructions

## Program flow

The directed program exercises:

- all 10 supported R-type ALU operations,
- all 9 supported I-type ALU operations,
- LUI/AUIPC,
- SW/SH/SB,
- LW/LH/LHU/LB/LBU,
- RAW forwarding,
- load-use stall,
- BEQ/BNE/BLT/BGE/BLTU/BGEU,
- JAL including link and wrong-path suppression,
- JALR including link, target and wrong-path suppression,
- final completion marker.

## Important TB property

The instruction program reaches the processor only through:

`byte_loader -> mem_port_mux -> instruction SRAM -> IF -> pipeline`

The TB does not directly write the SRAM array as part of normal execution.

The test first verifies the loaded SRAM contents, then releases `load_mode`, then waits for a real CPU-generated completion store at `0x3F0`.
