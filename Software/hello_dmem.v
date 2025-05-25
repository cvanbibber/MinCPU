// Data Memory Initialization for MinCPU
// Generated from: hello.bin

initial begin
    // Initialize data memory to zero
    for (i = 0; i < MEM_SIZE; i = i + 1) begin
        memory[i] = 32'h00000000;
    end
end
