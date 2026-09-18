// ============================================================
// Instruction Memory Loader
// ============================================================

task automatic load_program(input string filename);

    $display("==============================================");
    $display("Loading instruction memory");
    $display("Program : %s", filename);
    $display("==============================================");

    // Initialize entire instruction memory with NOPs
    for (int i = 0; i < IMEM_WORDS; i++)
        instruction_memory[i] = 32'h00000013;

    // Load program from HEX file
    $readmemh(filename, instruction_memory);
$display("First instruction = %08h", instruction_memory[0]);

    $display("Instruction memory loaded successfully");
    $display("==============================================");

endtask