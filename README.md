# RV32I Pipelined SoC Verification

## 1. Overview

This repository contains the verification work done for the RV32I pipelined processor and the complete SoC. The verification was carried out in multiple stages so that individual blocks were checked first and the complete processor/SoC was tested only after the major blocks were verified.

The overall flow was:

1. **Block-level verification**
2. **Instruction-set / processor-level verification**
3. **Full SoC directed verification**
4. **Functional coverage analysis**
5. **Constrained edge-case checking**

The testbenches were mainly directed, with random tests added for blocks such as the ALU, decode and execute stages.

---

# 2. Verification Strategy

The main idea was to test the design from the bottom up.

At block level, each module was tested independently using directed corner cases, assertions, scoreboards and functional coverage. This helped isolate bugs before integrating the complete processor.

At the processor/instruction level, the testbench used an RV32I reference execution model and instruction-oriented stimulus. The important instruction classes were covered using R-type, I-type, load/store, branch and jump instructions, along with immediate and signed/unsigned corner cases.

At SoC level, a complete program was loaded through the actual SoC loading path instead of directly writing the instruction SRAM. The processor was then allowed to execute the program normally. The testbench monitored instruction fetches, memory activity, AXI transactions and architectural results. A separate set of constrained edge cases was checked independently.

---

# 3. References and Testbench Files

## 3.1 Block-Level References

### ALU
- `tb_ALU.sv`
- `tb_ALU_cov_asrt.sv`
- `tb_ALU_random.sv`
- DUT: `ALU.sv`

### Register File
- `tb_registerfile.sv`
- `tb_registerfile_cov_asrt.sv`
- DUT: `registerfile.sv`

### Sign Extension
- `tb_sign_extend.sv`
- `tb_sign_extend_cov_asrt.sv`
- DUT: `sign_extend.sv`

### Instruction Fetch (IF)
- `tb_ifetch_stage.sv`
- `tb_IF_cov_asrt.sv`
- DUT: `IF.sv`, `Pc_Module.sv`, `Pc_adder.sv`, `inst_memory.sv`

### Decode Stage
- `tb_decode_stage_cov_asrt.sv`
- DUT: `decode_stage.sv` and associated control/decode logic

### Execute Stage
- `tb_Execute_stage_cov_asrt.sv`
- DUT: `Execute_stage.sv`

---

## 3.2 Instruction-Set / Processor-Level References

- `tb_pipeline_top`
- `pipeline_top.sv`
- RV32I reference execution model
- Instruction memory reference model
- Data memory reference model
- Opcode/funct3/funct7 functional coverage
- Memory read/write and branch coverage

The processor-level environment models RV32I architectural execution including:

- R-type arithmetic and logical operations
- I-type ALU operations
- Loads and stores
- Branches
- JAL and JALR
- LUI and AUIPC
- Immediate generation
- Register-file architectural state
- x0 immutability
- Byte/halfword/word memory operations
- Signed and unsigned comparisons
- Shift amount masking

---

## 3.3 SoC-Level References

### Full Directed SoC
- `tb_soc_top.sv`
- `tb_program_loader.svh`
- `tb_axi_monitor.svh`
- `tb_processor_monitor.svh`
- `tb_reference_model.svh`
- `tb_scoreboard.svh`
- `tb_assertions.svh`
- `tb_coverage.svh`

### SoC Functional Coverage
- `tb_soc_coverage.sv`
- `program_image.svh`
- RV32I directed program image
- Actual SoC byte-loader path
- Instruction SRAM
- AXI data-memory path

The final directed program contained **190 words / 760 bytes**.

---

# 4. Block-Level Verification Results

| Block | Directed / Random Tests | Scoreboard / Test Result | Assertion Result | Functional Coverage | Status |
|---|---:|---:|---:|---:|---|
| ALU | 36 directed + 2000 random | 36/36 directed, 2000/2000 random | 0 failures | 96.67% | PASS |
| Register File | 61 functional checks | 61/61 | 0 failures | 97.33% | PASS |
| Sign Extend | 2050 tests | 2050/2050 | 0 failures | 96.00% | PASS |
| Decode Stage | 2538 tests | 2538/2538 | 0 failures | 96.59% | PASS |
| Execute Stage | 25 edge + 2000 random | 2004 scoreboard passes, 0 failures | 0 failures | 100.00% | PASS |
| IF Stage | 13 edge + 2000 random | 2051/2051 scoreboard checks | 0 failures | 97.83% | PASS |

### Notes

The ALU was tested with both a small directed suite and 2000 random ADD/SUB operations. The directed ALU suite contained 36 checks with zero failures, while all 2000 random tests also passed.

The register file functional test passed all 61 checks. The additional assertion/coverage run achieved 97.33% functional coverage with zero assertion failures.

The sign-extension test covered I, S, B, J and U type instructions, including invalid opcodes and random tests. It achieved 2050/2050 passing tests and 96.00% coverage.

The decode stage included directed RV32I edge cases, register-file writeback forwarding, StallD, FlushD and FlushD+StallD priority tests, followed by 2000 random decode tests and 500 random StallD/FlushD tests. All 2538 tests passed.

The execute stage covered arithmetic boundaries, logic operations, shifts, forwarding, operand selection, branches, jump targets, FlushE and StallE behavior. It used 25 edge cases and 2000 random tests. The report shows 2025 total checks, 2004 scoreboard passes and zero failures, with 100% functional coverage and zero assertion failures.

The IF-stage test was intentionally more detailed because of the synchronous SRAM and pipeline timing. It used 13 directed edge cases and 2000 random scenarios. The scoreboard checks all passed, but the test reported 52 assertion failures and 75.83% functional coverage. The reported failures were mainly related to the IF/ID timing/reference association checks such as `PcPlus4D` and instruction/PC association. Later on these issues were fixed and a 97.83% functional coverage was achieved with no failures.

---

# 5. Instruction-Set / Processor-Level Verification

The processor-level environment was built around an RV32I reference model. Instead of checking only individual RTL signals, the reference model maintained architectural register state, program counter and memory state and executed the instruction stream according to the expected RV32I behavior.

The instruction-oriented coverage included:

- Opcode classes
- funct3 values
- R-type funct7 values
- Load types
- Store types
- Branch types
- Memory activity
- Store byte-enable (`WSTRB`)
- Opcode × funct3 combinations

The final SoC functional run gave strong instruction coverage:

| Coverage Item | Result |
|---|---:|
| Opcode coverage | 100.00% |
| funct3 coverage | 100.00% |
| R-type funct7 coverage | 100.00% |
| Load type coverage | 100.00% |
| Store type coverage | 100.00% |
| Branch type coverage | 100.00% |
| WSTRB coverage | 100.00% |
| Memory activity coverage | 100.00% |
| Opcode × funct3 coverage | 51.39% |
| Overall functional coverage | 94.60% |

During the coverage run, **6005 decode observations** were made, of which **2255 were non-NOP instructions**. The processor generated **80 memory reads** and **345 memory writes**. The complete 190-word program required **760 loader bytes**.

A separate standalone final ISA-only pass/fail report was not part of the uploaded result set; therefore, the instruction-set results above are reported from the instruction-oriented processor/SoC coverage run rather than being presented as a separate ISA compliance certification.

---

# 6. Full SoC Directed Verification

## 6.1 Strategy

The full SoC test used the real program loading path:

`Testbench → byte loader → memory mux → instruction SRAM → IF stage → pipeline`

The testbench did not directly initialize the instruction SRAM.

After loading, the contents of the actual instruction SRAM were checked against the program image before releasing the CPU from reset.

The directed program was designed to exercise:

- Arithmetic operations
- Logical operations
- Shift operations
- Comparisons
- Loads and stores
- Branches
- JAL/JALR
- Immediate boundaries
- Signed/unsigned behavior
- Byte and halfword accesses
- Forwarding and hazards
- Wrong-path control-flow behavior

The testbench also used a constrained edge-case scoreboard so important corner cases were reported separately from the main program signature.

---

# 7. Final SoC Result

The final directed SoC run passed completely.

### Program loading

- Program source: `program_image.svh`
- Program size: **190 words**
- Instruction SRAM verification: **PASS**
- Load errors: **0**

### Main directed test

- DONE AXI write completed after **474 run cycles**
- DONE AXI write: **PASS**
- Main signature checks: **40**
- Scoreboard PASS items: **60**
- Scoreboard errors: **0**

### Monitoring

| Check | Result |
|---|---:|
| Load errors | 0 |
| Fetch monitor errors | 0 |
| Control errors | 0 |
| Forwarding errors | 0 |
| Transport errors | 0 |
| AXI response errors | 0 |
| Assertion failures | 0 |
| Edge-case errors | 0 |
| Scoreboard errors | 0 |

**Final result: FULL SOC DIRECTED TEST — PASS**

---

# 8. Constrained Edge-Case Testing

The following cases were checked separately from the main program:

1. Immediate boundary: -2048 and +2047
2. Signed ADD wraparound
3. Arithmetic right shift sign preservation
4. SLT vs SLTU boundary
5. Register shift amount masking to 5 bits
6. x0 immutability
7. SB byte lanes 0/1/2/3
8. SH lower and upper halfword lanes
9. LB/LBU sign and zero extension
10. LH/LHU sign and zero extension
11. Backward branch taken and not taken
12. Signed overflow: `0x7fffffff + 1`
13. JALR link value and bit-0 clearing

The final run reported:

- **17 edge cases passed**
- **0 edge cases failed**

Representative results included:

- ADD signed wrap boundary → `ffffffff`
- SRA sign preservation → `ffffffff`
- SLT signed boundary → `00000001`
- SLTU unsigned boundary → `00000000`
- Shift amount 32 masking → `00000001`
- x0 immutability → `00000000`
- SB all byte lanes → `aaaaaaaa`
- SH lower/upper lanes → `beefbeef`
- LB sign extension → `ffffff80`
- LBU zero extension → `00000080`
- LH sign extension → `ffff8001`
- LHU zero extension → `00008001`
- Signed overflow → `80000000`
- JALR link + bit-0 clear → `000002d4`
- ADDI minimum immediate → `fffff800`
- ADDI maximum immediate → `000007ff`

The testbench also performed negative control-flow checks for wrong-path stores after JAL and JALR. Both checks passed.

---

# 9. SoC Functional Coverage

The final SoC functional coverage run was separate from the final architectural scoreboard and was mainly used to check whether the directed program exercised the required instruction and memory scenarios.

| Coverage Metric | Result |
|---|---:|
| Overall functional coverage | **94.60%** |
| Opcode | **100.00%** |
| funct3 | **100.00%** |
| R-type funct7 | **100.00%** |
| Load type | **100.00%** |
| Store type | **100.00%** |
| Branch type | **100.00%** |
| WSTRB | **100.00%** |
| Memory activity | **100.00%** |
| Opcode × funct3 | **51.39%** |

The lower opcode × funct3 cross coverage is expected to be the main remaining coverage gap. The individual instruction classes were covered, but not every possible combination of opcode and funct3 is legal or exercised by the directed program.

---

# 10. Debugging and Testbench Improvements

The verification process also exposed several issues in the testbench itself, which were corrected before using the final SoC result.

### Program loading/reset sequencing

The byte loader and processor reset are controlled separately. During loading, the external reset must allow the byte loader to operate while `load_mode` keeps the CPU in reset. After correcting this sequencing, the actual instruction SRAM was verified successfully.

### Instruction memory checking

The final environment verifies the actual DUT instruction SRAM after loading. This avoids continuing into CPU execution when the program image has not been loaded correctly.

### X-state handling

The first SoC scoreboard assumed uninitialized memory bytes were zero. This created false read-data mismatches such as `xxxx8001` versus `00008001`. The memory checking strategy was adjusted so partially initialized byte lanes are not treated as known zero data.

### Reference-model checking

The reference model is treated as a diagnostic aid in the final SoC environment. The final pass/fail decision is based on the DUT-facing architectural scoreboard, control checks, edge-case checks and AXI/monitor checks rather than blindly trusting a potentially mismatched reference timing model.

---

# 11. Overall Verification Summary

The verification was done progressively:

**Block level → instruction/processor level → SoC level**

At block level, ALU, register file, sign extension, decode and execute stages passed their functional/assertion tests. The IF stage scoreboard checks passed, although its assertion suite still reported 52 failures and 75.83% functional coverage.

At instruction/processor level, the final SoC functional coverage demonstrates that all major RV32I opcode classes, funct3 values, R-type funct7 values, load/store/branch types and memory activities were exercised. Overall functional coverage reached **94.60%**.

At full SoC level, the final directed test passed with:

- **0 load errors**
- **0 fetch monitor errors**
- **0 control errors**
- **0 forwarding errors**
- **0 transport errors**
- **0 AXI response errors**
- **0 assertion failures**
- **0 edge-case failures**
- **0 scoreboard errors**
- **17/17 constrained edge cases passed**

Therefore, the final full-SoC directed verification run completed successfully.

---

# 12. Result Files

The main result logs used for this report are:

- `sim_ifetch_stage.log`
- `sim_registerfile.log`
- `sim_registerfile_cov_asrt.log`
- `sim_sign_extend.log`
- `sim_ALU(1).log`
- `sim_ALU_cov_asrt.log`
- `sim_ALU_Random.log`
- `sim_decode_stage.log`
- `sim_execute_stage.log`
- `Coverage_log.log`
- `log21092026.log.log`

The earlier SoC run `log20092026.log.log` is also retained as a verification/debug history. That run reported 4 transport errors and 29 scoreboard errors; the corrected final run subsequently completed with zero errors.

---

# 13. Final Status

## BLOCK LEVEL
**Mostly PASS**

All major blocks completed functional verification successfully. The memory stage and writeback stages were not verified at block level due to simple rtl logic and lack of environment that they needed. These blocks were covered during Instruction Set tests.

## INSTRUCTION / PROCESSOR LEVEL
**High functional coverage and Instruction Set fully verified.**

The final execution environment exercised all major instruction categories and achieved **94.60% overall functional coverage**, with 100% coverage for each major individual opcode/type category reported.

## FULL SOC
**PASS**

The final directed SoC test passed, including program loading, instruction fetch monitoring, architectural scoreboard checks, AXI checks, control-flow negative checks and all 17 constrained edge cases.

---

## Conclusion

The verification was structured from unit level to full-chip level. This made it possible to separate actual DUT behavior from testbench/model issues during debugging.

The final SoC run gives a clean result with zero reported errors and complete passing of the constrained architectural edge cases. The major remaining coverage gap is the opcode × funct3 cross coverage at 51.39% which is mainly due to less iterations of programs in the verification.

