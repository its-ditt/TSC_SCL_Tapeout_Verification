# RV32I Directed Program Build Instructions

## Purpose

Use these instructions whenever `program.S` is changed.

The assembler generates three files from one assembly source:

```text
program.hex
program.lst
program_image.svh
```

The `.S` file is the only file that should be edited manually.

---

## 1. Required directory structure

Keep the verification environment arranged like this:

```text
soc_directed_tb/
├── programs/
│   ├── rv32i_directed.S
│   ├── program.hex
│   ├── program.lst
│   └── program_image.svh
│
├── tb/
│   ├── tb_soc_top.sv
│   ├── tb_config.svh
│   ├── program_image.svh
│   └── ...
│
└── tools/
    └── assemble_rv32i.py
```

`program_image.svh` is generated. Do not edit it manually.

---

## 2. Edit the assembly program

Open:

```text
programs/rv32i_directed.S
```

Write the RV32I instructions supported by the project's assembler.

The current assembler supports:

```text
R-type:
add sub sll slt sltu xor srl sra or and

I-type ALU:
addi slli slti sltiu xori srli srai ori andi

Loads:
lb lh lw lbu lhu

Stores:
sb sh sw

Branches:
beq bne blt bge bltu bgeu

Jumps:
jal jalr

Upper immediate:
lui auipc

Pseudo/instruction helpers:
nop
la
```

Comments can use:

```text
# comment
```

or:

```text
; comment
```

Labels are supported:

```asm
loop:
    addi x5, x5, 1
    bne  x5, x6, loop
```

Memory operands use:

```text
offset(register)
```

Example:

```asm
lw x10, 0(x20)
sw x11, 4(x20)
```

---

## 3. Assemble the program

From the `soc_directed_tb` directory run:

### Windows CMD

```bat
python tools\assemble_rv32i.py programs\rv32i_directed.S programs\program.hex
```

### Windows PowerShell

```powershell
python .\tools\assemble_rv32i.py .\programs\rv32i_directed.S .\programs\program.hex
```

### WSL / Linux

```bash
python3 tools/assemble_rv32i.py programs/rv32i_directed.S programs/program.hex
```

---

## 4. What the assembler generates

The command above automatically creates:

```text
programs/program.hex
programs/program.lst
programs/program_image.svh
```

### `program.hex`

One 32-bit instruction word per line in hexadecimal.

Example:

```text
10000a13
20000a93
3f000b13
00a00093
```

This is useful as a conventional memory/program image and for inspecting the encoded program.

### `program.lst`

Human-readable listing showing:

```text
PC        MACHINE CODE        SOURCE
```

Example:

```text
00000000  10000a13  addi x20 x0 256
```

Use the listing to find the PC address of any instruction when debugging the waveform.

### `program_image.svh`

SystemVerilog representation of the same instruction image:

```systemverilog
initial begin
    program_words[0] = 32'h10000a13;
    program_words[1] = 32'h20000a93;
    ...
end
```

The SoC testbench uses this embedded image as its canonical program source.

---

## 5. Copy `program_image.svh` into the TB directory

The assembler creates it in `programs/`.

The SoC TB includes the copy from `tb/`, so after every assembly run copy the generated file:

### Windows CMD

```bat
copy /Y programs\program_image.svh tb\program_image.svh
```

### PowerShell

```powershell
Copy-Item .\programs\program_image.svh .\tb\program_image.svh -Force
```

### WSL / Linux

```bash
cp programs/program_image.svh tb/program_image.svh
```

Do not manually edit either copy.

---

## 6. Verify the generated files

After assembly, check the word count.

For example:

```text
assembled 190 words (760 bytes)
```

The important number is the number of generated instruction words.

`program.hex`, `program.lst`, and `program_image.svh` must all represent the same instruction sequence.

If the assembler reports:

```text
190 words
```

then:

```text
program.hex         = 190 instruction lines
program_image.svh  = program_words[0] ... program_words[189]
program.lst         = 190 encoded instruction entries
```

If these counts do not agree, stop before running simulation.

---

## 7. Add/update the SystemVerilog image in Vivado

In Vivado:

```text
Simulation Sources
└── tb
    ├── tb_soc_top.sv
    ├── tb_config.svh
    ├── program_image.svh
    ├── tb_program_loader.svh
    ├── tb_axi_monitor.svh
    ├── tb_processor_monitor.svh
    ├── tb_reference_model.svh
    ├── tb_scoreboard.svh
    ├── tb_assertions.svh
    └── tb_coverage.svh
```

Make sure Vivado is using the **newly generated**:

```text
tb/program_image.svh
```

After changing it, use:

```text
Reset Simulation Run
```

or otherwise force Vivado to recompile the changed simulation source.

---

## 8. Important: `program_image.svh` is the TB program source

The current SoC TB should use:

```text
program_image.svh
        |
        +----> reference-side expected program
        |
        +----> real byte-loader stimulus
                  |
                  v
             byte_loader
                  |
                  v
             instruction SRAM
                  |
                  v
                CPU
```

The TB must **not** directly initialize the DUT instruction SRAM during the actual load test.

The loader must exercise the real SoC path.

---

## 9. Do not edit generated files

Do not manually modify:

```text
program.hex
program.lst
program_image.svh
```

When the assembly changes:

```text
edit .S
   ↓
run assembler
   ↓
regenerate all outputs
   ↓
copy program_image.svh into tb/
   ↓
compile simulation
   ↓
run simulation
```

Any manual change will be overwritten on the next assembly.

---

## 10. Recommended workflow for every new test program

For a completely new program:

### Step 1

Create or replace:

```text
programs/rv32i_directed.S
```

### Step 2

Assemble:

```bash
python3 tools/assemble_rv32i.py programs/rv32i_directed.S programs/program.hex
```

### Step 3

Copy the generated image:

```bash
cp programs/program_image.svh tb/program_image.svh
```

### Step 4

Check `program.lst`.

Use it to identify:

- instruction PC
- machine code
- branch targets
- jump targets
- memory-access instructions
- locations of edge-case tests

### Step 5

Compile the simulation.

### Step 6

Run the SoC directed test.

### Step 7

If the program changes its signature addresses or adds/removes edge-case tests, update the **scoreboard expectations and edge-case descriptions** accordingly.

Do not modify the reference model merely to make a failing DUT pass.

---

## 11. Example complete command sequence

From the project root:

### Windows PowerShell

```powershell
python .\tools\assemble_rv32i.py .\programs\rv32i_directed.S .\programs\program.hex

Copy-Item .\programs\program_image.svh .\tb\program_image.svh -Force
```

### WSL / Linux

```bash
python3 tools/assemble_rv32i.py programs/rv32i_directed.S programs/program.hex
cp programs/program_image.svh tb/program_image.svh
```

Expected output:

```text
assembled <N> words (<N*4> bytes)
output: programs/program.hex
listing: programs/program.lst
```

Then check that:

```text
programs/program.hex
programs/program.lst
tb/program_image.svh
```

are updated before launching Vivado simulation.

---

## 12. Common problems

### `python is not recognized`

Try:

```bash
python3 tools/assemble_rv32i.py ...
```

or verify that Python is installed and available in PATH.

### `bad register`

Use only:

```text
x0 ... x31
```

### `I/S immediate out of range`

The immediate must fit the RV32I 12-bit signed range:

```text
-2048 to +2047
```

### `branch immediate invalid`

The branch offset must:

```text
be even
fit the RV32I branch range
```

### `JAL immediate invalid`

The jump offset must:

```text
be even
fit the RV32I JAL range
```

### `unknown instruction`

The mnemonic is not supported by the project's assembler.

### Vivado still runs the old program

Check:

```text
tb/program_image.svh
```

and ensure it was regenerated and added to the current simulation fileset.

Then reset/recompile the simulation.

---

## 13. Golden rule

There is only **one source file to edit**:

```text
programs/rv32i_directed.S
```

Everything else is generated:

```text
                 rv32i_directed.S
                         |
                         v
              assemble_rv32i.py
                 /       |       \
                v        v        v
        program.hex  program.lst  program_image.svh
                                      |
                                      v
                              tb/program_image.svh
                                      |
                                      v
                                  SoC TB
```
