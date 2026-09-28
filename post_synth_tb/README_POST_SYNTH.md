# Post-Synthesis Gate-Level Verification TB

Target: Cadence Genus synthesized netlist supplied as `netlist/top_streamed_wrapper_chip_netlist.v`.

## What this TB does

- Instantiates the actual synthesized top module: `soc_top_wrapper`.
- Drives the real chip-level pins: `clk`, `rst_n`, `load_mode`, `data_in[1:0]`, `qbit_strobe`.
- Loads the same 190-word program image through the real `qbit_loader` path.
- Checks synthesized loader behavior without directly writing the SRAM.
- Monitors synthesized CPU memory requests and the AXI manager handshakes.
- Detects completion from the actual synthesized AXI DONE transaction.
- Checks the known main/edge architectural signatures from the already-passed RTL program.
- Avoids dependence on `SPRAM_1024x36.mem`, so the TB does not require a particular internal array name in the SRAM macro model.
- Keeps the RV32I reference model as a non-gating diagnostic.

## Files still required from the PDK / PD team

1. Standard-cell Verilog simulation models for all cells instantiated by the netlist.
2. IO-cell Verilog simulation models for `pc3d01`, `pc3c01`, `pc3o01` and the power cells present in the netlist.
3. Verilog simulation model for `SPRAM_1024x36`.
4. SDF file for timing-annotated simulation (not required for the first zero-delay gate-level run).

## Hierarchy used

The supplied netlist preserves:

```text
tb_post_synth.dut
  └── soc_top_wrapper dut
        └── soc_top dut
              ├── instr_in (qbit_loader)
              ├── axi_top
              │    ├── manager
              │    └── ram_slave
              └── Imem (SPRAM_1024x36)
```

Inside synthesized `soc_top`, Genus exposes flattened top-level signals such as:

```text
cpu_InstrD
cpu_PcD
cpu_ForwardAE
cpu_ForwardBE
cpu_PcSrcE
cpu_PcTargetE
MEM_ADDR
MEM_WDATA
MEM_WSTRB
MEM_READ
MEM_WRITE
core_rst_n
```

The TB uses these preserved names instead of the old RTL `cpu.*` hierarchy.

## Stage 1: zero-delay functional GLS

Typical Xcelium command pattern:

```bash
xrun -64bit -sv \
  -timescale 1ns/1ps \
  -access +rwc \
  -f filelist_post_synth.f \
  -top tb_post_synth
```

Use the PDK's recommended compile switches/options for its standard-cell and IO simulation libraries.

## Stage 2: SDF-annotated GLS

After Stage 1 passes, put the generated SDF in the run directory and compile with:

```bash
xrun -64bit -sv \
  -timescale 1ns/1ps \
  -access +rwc \
  +define+ENABLE_SDF \
  -f filelist_post_synth.f \
  -top tb_post_synth
```

The TB currently expects:

```text
top_streamed_wrapper_chip.sdf
```

Edit `tb/tb_post_synth_config.svh` if the PD team used a different SDF filename.

## Filelist

`filelist_post_synth.f` contains placeholders for the PDK/library files that are not present in the supplied package.

Do not create substitute behavioral versions of the real SCL cells when the actual PDK models are available.

## Important note

The supplied RTL-to-FV `.do` files are Conformal/LEC inputs. They are not required by this simulation TB.
