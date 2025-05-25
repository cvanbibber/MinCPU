/*
 * Instruction Memory for MinCPU RISC-V Processor
 * Supports both static benchmark programs and dynamic UART loading
 */

`include "cpu_config.vh"

module instruction_memory #(
    parameter DATA_WIDTH = `DATA_WIDTH,
    parameter ADDR_WIDTH = `ADDR_WIDTH,
    parameter MEM_SIZE = `IMEM_SIZE,  // Number of 32-bit words
    parameter BENCHMARK_SELECT = `DEFAULT_BENCHMARK  // Select which benchmark to load
) (
    input  wire                  clk,
    input  wire                  rst_n,
    
    // CPU interface
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire                  req,
    output reg  [DATA_WIDTH-1:0] data,
    output reg                   ready,
    
    // Bootloader interface (optional)
    input  wire [ADDR_WIDTH-1:0] boot_addr,
    input  wire [DATA_WIDTH-1:0] boot_wdata,
    input  wire                  boot_we,
    input  wire                  boot_req,
    output reg                   boot_ready,
    
    // Control signals
    input  wire                  bootloader_mode,
    input  wire                  load_static_program
);

    // Memory array
    reg [DATA_WIDTH-1:0] memory [0:MEM_SIZE-1];
    wire [ADDR_WIDTH-3:0] word_addr; // Divide by 4 for word addressing
    wire [ADDR_WIDTH-3:0] boot_word_addr;
    
    assign word_addr = addr[ADDR_WIDTH-1:2];
    assign boot_word_addr = boot_addr[ADDR_WIDTH-1:2];
    
    // Memory initialization control
    reg static_program_loaded;
    
    // Initialize memory
    initial begin
        static_program_loaded = 1'b0;
        load_static_program_task();
    end
    
    // Load static program task
    task load_static_program_task;
        integer i, addr_offset;
        begin
            // Initialize all memory to NOPs
            for (i = 0; i < MEM_SIZE; i = i + 1) begin
                memory[i] = 32'h00000013; // ADDI x0, x0, 0 (NOP)
            end
            
            // Load test data for benchmarks
            memory[0] = 32'hdeadbeef;     // Test data at address 0
            memory[1] = 32'hcafebabe;     // Test data at address 4  
            memory[2] = 32'h12345678;     // Test data at address 8
            memory[4] = 32'h87654321;     // Test data at address 16
            memory[5] = 32'habcdef01;     // Test data at address 20
            memory[6] = 32'h01234567;     // Test data at address 24
            memory[8] = 32'h00000008;     // Test data for loads
            memory[9] = 32'h00000010;   
            memory[10] = 32'h00000018;
            memory[11] = 32'h00000020;
            memory[12] = 32'h00000005;
            memory[13] = 32'h00000003;
            memory[14] = 32'h00000007;
            memory[15] = 32'h00000001;
            
            // Load the selected benchmark program (starting at 0x1000 = word address 1024)
            addr_offset = (`IMEM_BASE_ADDR - 32'h00000000) / 4; // Calculate offset for base address
            
            case (BENCHMARK_SELECT)
                `BENCHMARK_BASIC: begin
                    $display("Loading BASIC ARITHMETIC benchmark...");
                    load_basic_benchmark(addr_offset);
                end
                
                `BENCHMARK_MEMORY: begin
                    $display("Loading MEMORY INTENSIVE benchmark...");
                    load_memory_benchmark(addr_offset);
                end
                
                `BENCHMARK_BRANCH: begin
                    $display("Loading BRANCH PREDICTION benchmark...");
                    load_branch_benchmark(addr_offset);
                end
                
                `BENCHMARK_MIXED: begin
                    $display("Loading MIXED WORKLOAD benchmark...");
                    load_mixed_benchmark(addr_offset);
                end
                
                `BENCHMARK_FIBONACCI: begin
                    $display("Loading FIBONACCI benchmark...");
                    load_fibonacci_benchmark(addr_offset);
                end
                
                `BENCHMARK_BUBBLE: begin
                    $display("Loading BUBBLE SORT benchmark...");
                    load_bubble_benchmark(addr_offset);
                end
                
                `BENCHMARK_C_PROGRAM: begin
                    $display("Loading C PROGRAM from external file...");
                    // Will be loaded by bootloader or include file
                    `ifdef C_PROGRAM_FILE
                        `include `C_PROGRAM_FILE
                    `else
                        $display("No C program file specified. Use bootloader to load program.");
                    `endif
                end
                
                `BENCHMARK_DHRYSTONE: begin
                    $display("Loading DHRYSTONE benchmark...");
                    load_dhrystone_benchmark(addr_offset);
                end
                
                `BENCHMARK_WHETSTONE: begin
                    $display("Loading WHETSTONE benchmark...");
                    load_whetstone_benchmark(addr_offset);
                end
                
                default: begin
                    $display("Loading DEFAULT benchmark (mixed)...");
                    load_mixed_benchmark(addr_offset);
                end
            endcase
            
            static_program_loaded = 1'b1;
            $display("Instruction Memory initialized with benchmark %0d", BENCHMARK_SELECT);
        end
    endtask
    
    // Individual benchmark loading tasks
    task load_basic_benchmark;
        input integer addr_offset;
        begin
            // Initialize test values
            memory[addr_offset+0]  = 32'h00100093;  // ADDI x1, x0, 1    (x1 = 1)
            memory[addr_offset+1]  = 32'h00200113;  // ADDI x2, x0, 2    (x2 = 2)
            memory[addr_offset+2]  = 32'hfff00193;  // ADDI x3, x0, -1   (x3 = -1)
            memory[addr_offset+3]  = 32'h7ff00213;  // ADDI x4, x0, 2047 (x4 = 2047)
            
            // Arithmetic operations
            memory[addr_offset+4]  = 32'h002081b3;  // ADD  x3, x1, x2   (x3 = 1 + 2 = 3)
            memory[addr_offset+5]  = 32'h40208233;  // SUB  x4, x1, x2   (x4 = 1 - 2 = -1)
            memory[addr_offset+6]  = 32'h002092b3;  // SLL  x5, x1, x2   (x5 = 1 << 2 = 4)
            memory[addr_offset+7]  = 32'h0020a333;  // SLT  x6, x1, x2   (x6 = 1 < 2 = 1)
            memory[addr_offset+8]  = 32'h0020b3b3;  // SLTU x7, x1, x2   (x7 = 1 < 2 = 1)
            
            // Logical operations
            memory[addr_offset+9]  = 32'h0020c433;  // XOR  x8, x1, x2   (x8 = 1 ^ 2 = 3)
            memory[addr_offset+10] = 32'h0020d4b3;  // SRL  x9, x1, x2   (x9 = 1 >> 2 = 0)
            memory[addr_offset+11] = 32'h4020d533;  // SRA  x10, x1, x2  (x10 = 1 >>> 2 = 0)
            memory[addr_offset+12] = 32'h0020e5b3;  // OR   x11, x1, x2  (x11 = 1 | 2 = 3)
            memory[addr_offset+13] = 32'h0020f633;  // AND  x12, x1, x2  (x12 = 1 & 2 = 0)
            
            // Immediate operations
            memory[addr_offset+14] = 32'h00a08693;  // ADDI x13, x1, 10  (x13 = 1 + 10 = 11)
            memory[addr_offset+15] = 32'h00a0a713;  // SLTI x14, x1, 10  (x14 = 1 < 10 = 1)
            memory[addr_offset+16] = 32'h00a0b793;  // SLTIU x15, x1, 10 (x15 = 1 < 10 = 1)
            memory[addr_offset+17] = 32'h00a0c813;  // XORI x16, x1, 10  (x16 = 1 ^ 10 = 11)
            memory[addr_offset+18] = 32'h00a0e893;  // ORI  x17, x1, 10  (x17 = 1 | 10 = 11)
            memory[addr_offset+19] = 32'h00a0f913;  // ANDI x18, x1, 10  (x18 = 1 & 10 = 0)
            
            // Loop back for continuous testing
            memory[addr_offset+20] = 32'hfe5ff06f;  // JAL  x0, -28      (jump back to start)
        end
    endtask
    
    task load_memory_benchmark;
        input integer addr_offset;
        begin
            // Sequential memory access pattern
            memory[addr_offset+0]  = 32'h00000093;  // ADDI x1, x0, 0    (x1 = address offset)
            memory[addr_offset+1]  = 32'h01000113;  // ADDI x2, x0, 16   (x2 = increment)
            memory[addr_offset+2]  = 32'h06400193;  // ADDI x3, x0, 100  (x3 = loop count)
            
            // Load-use hazard intensive loop
            memory[addr_offset+3]  = 32'h0000a203;  // LW   x4, 0(x1)    Load from memory
            memory[addr_offset+4]  = 32'h00420213;  // ADDI x4, x4, 4    Use loaded value immediately (hazard!)
            memory[addr_offset+5]  = 32'h0040a223;  // SW   x4, 4(x1)    Store back to memory
            memory[addr_offset+6]  = 32'h0040a283;  // LW   x5, 4(x1)    Load what we just stored
            memory[addr_offset+7]  = 32'h00528293;  // ADDI x5, x5, 5    Another load-use hazard
            memory[addr_offset+8]  = 32'h0050a423;  // SW   x5, 8(x1)    Store result
            
            // Update loop variables
            memory[addr_offset+9]  = 32'h00208093;  // ADDI x1, x1, 2    Increment address
            memory[addr_offset+10] = 32'hfff18193;  // ADDI x3, x3, -1   Decrement counter
            memory[addr_offset+11] = 32'hfe319ae3;  // BNE  x3, x0, -12  Branch if not zero
            
            memory[addr_offset+12] = 32'hfc5ff06f;  // JAL  x0, -60      Jump back to start
        end
    endtask
    
    task load_branch_benchmark;
        input integer addr_offset;
        begin
            // Pattern 1: Alternating taken/not-taken
            memory[addr_offset+0]  = 32'h00100093;  // ADDI x1, x0, 1    (x1 = 1)
            memory[addr_offset+1]  = 32'h00000113;  // ADDI x2, x0, 0    (x2 = 0)
            memory[addr_offset+2]  = 32'h01900193;  // ADDI x3, x0, 25   (x3 = loop count)
            
            memory[addr_offset+3]  = 32'h00209463;  // BNE  x1, x2, +8   Branch if x1 != x2 (taken)
            memory[addr_offset+4]  = 32'h00108093;  // ADDI x1, x1, 1    Not taken path
            memory[addr_offset+5]  = 32'h0080006f;  // JAL  x0, +8       Skip taken path
            memory[addr_offset+6]  = 32'hfff08093;  // ADDI x1, x1, -1   Taken path (alternates x1)
            memory[addr_offset+7]  = 32'h00000013;  // NOP
            
            memory[addr_offset+8]  = 32'hfff18193;  // ADDI x3, x3, -1   Decrement counter
            memory[addr_offset+9]  = 32'hfe319ae3;  // BNE  x3, x0, -16  Loop back
            
            memory[addr_offset+10] = 32'hfc5ff06f;  // JAL  x0, -40      Jump back to start
        end
    endtask
    
    task load_mixed_benchmark;
        input integer addr_offset;
        begin
            // Initialization
            memory[addr_offset+0]  = 32'h00a00093;  // ADDI x1, x0, 10   (x1 = 10)
            memory[addr_offset+1]  = 32'h00500113;  // ADDI x2, x0, 5    (x2 = 5)
            memory[addr_offset+2]  = 32'h00000193;  // ADDI x3, x0, 0    (x3 = 0, accumulator)
            memory[addr_offset+3]  = 32'h00000213;  // ADDI x4, x0, 0    (x4 = 0, address)
            
            // Mixed operations loop
            memory[addr_offset+4]  = 32'h002201b3;  // ADD  x3, x4, x2   Add to accumulator
            memory[addr_offset+5]  = 32'h00422223;  // SW   x4, 4(x4)    Store address to memory
            memory[addr_offset+6]  = 32'h0041a283;  // LW   x5, 4(x4)    Load back (load-use hazard)
            memory[addr_offset+7]  = 32'h00529293;  // ADDI x5, x5, 5    Use loaded value
            memory[addr_offset+8]  = 32'h002182b3;  // ADD  x5, x3, x2   More arithmetic
            memory[addr_offset+9]  = 32'h0051c333;  // XOR  x6, x3, x5   Logical operation
            memory[addr_offset+10] = 32'h40530333;  // SUB  x6, x6, x5   Subtraction
            
            // Conditional operations
            memory[addr_offset+11] = 32'h00335463;  // BGE  x6, x3, +8   Branch if x6 >= x3
            memory[addr_offset+12] = 32'h00130313;  // ADDI x6, x6, 1    Taken path
            memory[addr_offset+13] = 32'h0080006f;  // JAL  x0, +8       Skip not-taken
            memory[addr_offset+14] = 32'hfff30313;  // ADDI x6, x6, -1   Not-taken path
            memory[addr_offset+15] = 32'h00000013;  // NOP
            
            // Loop control
            memory[addr_offset+16] = 32'h00420213;  // ADDI x4, x4, 4    Increment address
            memory[addr_offset+17] = 32'hfff08093;  // ADDI x1, x1, -1   Decrement counter
            memory[addr_offset+18] = 32'hfe109ae3;  // BNE  x1, x0, -20  Loop back
            
            memory[addr_offset+19] = 32'hfc5ff06f;  // JAL  x0, -80      Jump back to start
        end
    endtask
    
    task load_fibonacci_benchmark;
        input integer addr_offset;
        begin
            memory[addr_offset+0]  = 32'h00100093;  // ADDI x1, x0, 1    (x1 = fib(1) = 1)
            memory[addr_offset+1]  = 32'h00100113;  // ADDI x2, x0, 1    (x2 = fib(2) = 1)  
            memory[addr_offset+2]  = 32'h01400193;  // ADDI x3, x0, 20   (x3 = count)
            memory[addr_offset+3]  = 32'h00000213;  // ADDI x4, x0, 0    (x4 = temp)
            
            // Fibonacci loop
            memory[addr_offset+4]  = 32'h002081b3;  // ADD  x3, x1, x2   x3 = fib(n-1) + fib(n-2)
            memory[addr_offset+5]  = 32'h00010213;  // ADDI x4, x2, 0    x4 = x2 (save old fib(n-1))
            memory[addr_offset+6]  = 32'h00018113;  // ADDI x2, x3, 0    x2 = x3 (new fib(n-1))
            memory[addr_offset+7]  = 32'h00020093;  // ADDI x1, x4, 0    x1 = x4 (new fib(n-2))
            
            // Store results to memory
            memory[addr_offset+8]  = 32'h00322223;  // SW   x3, 4(x4)    Store fibonacci number
            memory[addr_offset+9]  = 32'h00422283;  // LW   x5, 4(x4)    Load it back
            memory[addr_offset+10] = 32'h00528293;  // ADDI x5, x5, 5    Process loaded value
            
            // Loop control
            memory[addr_offset+11] = 32'hfff18193;  // ADDI x3, x3, -1   Decrement counter
            memory[addr_offset+12] = 32'hfe319ae3;  // BNE  x3, x0, -12  Continue if not zero
            
            memory[addr_offset+13] = 32'hfc5ff06f;  // JAL  x0, -60      Jump back to start
        end
    endtask
    
    task load_bubble_benchmark;
        input integer addr_offset;
        begin
            // Initialize array size and pointers
            memory[addr_offset+0]  = 32'h00800093;  // ADDI x1, x0, 8    (x1 = array size)
            memory[addr_offset+1]  = 32'h02000113;  // ADDI x2, x0, 32   (x2 = array base address)
            memory[addr_offset+2]  = 32'h00000193;  // ADDI x3, x0, 0    (x3 = i, outer loop)
            memory[addr_offset+3]  = 32'h00000213;  // ADDI x4, x0, 0    (x4 = j, inner loop)
            
            // Outer loop start
            memory[addr_offset+4]  = 32'h00000213;  // ADDI x4, x0, 0    Reset j = 0
            
            // Inner loop: compare arr[j] and arr[j+1]
            memory[addr_offset+5]  = 32'h004122b3;  // ADD  x5, x2, x4   x5 = base + j
            memory[addr_offset+6]  = 32'h0042a303;  // LW   x6, 4(x5)    x6 = arr[j]
            memory[addr_offset+7]  = 32'h0082a383;  // LW   x7, 8(x5)    x7 = arr[j+1]
            
            // Compare arr[j] > arr[j+1]
            memory[addr_offset+8]  = 32'h0073a463;  // BLT  x7, x6, +8   Branch if arr[j+1] < arr[j] (swap)
            memory[addr_offset+9]  = 32'h0100006f;  // JAL  x0, +16      Skip swap
            
            // Swap elements
            memory[addr_offset+10] = 32'h0072a423;  // SW   x7, 8(x5)    arr[j+1] = arr[j]
            memory[addr_offset+11] = 32'h0062a223;  // SW   x6, 4(x5)    arr[j] = arr[j+1]
            memory[addr_offset+12] = 32'h00000013;  // NOP
            memory[addr_offset+13] = 32'h00000013;  // NOP
            
            // Inner loop control
            memory[addr_offset+14] = 32'h00420213;  // ADDI x4, x4, 4    j += 4 (word increment)
            memory[addr_offset+15] = 32'h40408433;  // SUB  x8, x1, x4   x8 = size - j
            memory[addr_offset+16] = 32'hfe805ae3;  // BGE  x0, x8, -12  Continue inner loop
            
            // Outer loop control  
            memory[addr_offset+17] = 32'h00418193;  // ADDI x3, x3, 4    i += 4
            memory[addr_offset+18] = 32'he8318ae3;  // BLT  x3, x1, -28  Continue outer loop
            
            memory[addr_offset+19] = 32'hfc5ff06f;  // JAL  x0, -80      Jump back to start
        end
    endtask
    
    task load_dhrystone_benchmark;
        input integer addr_offset;
        begin
            // Dhrystone-like benchmark - focuses on string operations and procedure calls
            // Simulates the core operations of the Dhrystone benchmark
            
            // Initialize variables
            memory[addr_offset+0]  = 32'h00100093;  // ADDI x1, x0, 1       (x1 = Int_1_Loc = 1)
            memory[addr_offset+1]  = 32'h00200113;  // ADDI x2, x0, 2       (x2 = Int_2_Loc = 2)
            memory[addr_offset+2]  = 32'h00300193;  // ADDI x3, x0, 3       (x3 = Int_3_Loc = 3)
            memory[addr_offset+3]  = 32'h03e80213;  // ADDI x4, x0, 1000    (x4 = iteration counter)
            memory[addr_offset+4]  = 32'h00000293;  // ADDI x5, x0, 0       (x5 = Array_1_Loc[0])
            memory[addr_offset+5]  = 32'h00500313;  // ADDI x6, x0, 5       (x6 = Array_1_Loc[1])
            
            // Main Dhrystone loop start
            memory[addr_offset+6]  = 32'h00018393;  // ADDI x7, x3, 0       x7 = Int_3_Loc
            
            // Proc_1 simulation (string comparison and assignment)
            memory[addr_offset+7]  = 32'h00208433;  // ADD  x8, x1, x2      x8 = Int_1_Loc + Int_2_Loc
            memory[addr_offset+8]  = 32'h00840433;  // ADD  x8, x8, x8      x8 = x8 * 2 (simulate complex op)
            memory[addr_offset+9]  = 32'h00543533;  // SLTU x10, x8, x5     Compare for string ops
            memory[addr_offset+10] = 32'h00a53533;  // SLTU x10, x10, x10   Invert comparison
            
            // Character operations (simulate string manipulation)
            memory[addr_offset+11] = 32'h04100593;  // ADDI x11, x0, 65     x11 = 'A'
            memory[addr_offset+12] = 32'h00158593;  // ADDI x11, x11, 1     x11 = 'B'
            memory[addr_offset+13] = 32'h00158593;  // ADDI x11, x11, 1     x11 = 'C'
            memory[addr_offset+14] = 32'h40b58633;  // SUB  x12, x11, x11   x12 = 0 (string end)
            
            // Proc_2 simulation (arithmetic and logical operations)
            memory[addr_offset+15] = 32'h00a00693;  // ADDI x13, x0, 10     x13 = Int_Par_Val_1
            memory[addr_offset+16] = 32'h00d08733;  // ADD  x14, x1, x13    x14 = Int_1_Loc + Int_Par_Val_1
            memory[addr_offset+17] = 32'h00271713;  // SLLI x14, x14, 2     x14 = x14 * 4
            memory[addr_offset+18] = 32'h40e687b3;  // SUB  x15, x13, x14   x15 = Int_Par_Val_1 - x14
            
            // Proc_3 simulation (pointer operations)
            memory[addr_offset+19] = 32'h00018813;  // ADDI x16, x3, 0      x16 = &Int_3_Loc
            memory[addr_offset+20] = 32'h00080813;  // ADDI x16, x16, 0     Pointer operation
            memory[addr_offset+21] = 32'h01080893;  // ADDI x17, x16, 16    x17 = x16 + 16
            
            // Function call overhead simulation
            memory[addr_offset+22] = 32'h00c0006f;  // JAL  x0, +12         Jump to subroutine
            memory[addr_offset+23] = 32'h00100913;  // ADDI x18, x0, 1      Subroutine body
            memory[addr_offset+24] = 32'h00290913;  // ADDI x18, x18, 2     More operations
            memory[addr_offset+25] = 32'h00000067;  // JALR x0, x0, 0       Return
            
            // Array operations (simulate Array_1_Loc and Array_2_Loc)
            memory[addr_offset+26] = 32'h002292b3;  // ADD  x5, x5, x2      Array_1_Loc[0] += Int_2_Loc
            memory[addr_offset+27] = 32'h00130313;  // ADDI x6, x6, 1       Array_1_Loc[1] += 1
            memory[addr_offset+28] = 32'h00628333;  // ADD  x6, x5, x6      Array operation
            
            // Enum and record operations (simulate with arithmetic)
            memory[addr_offset+29] = 32'h00100993;  // ADDI x19, x0, 1      Enum_Loc = Ident_1
            memory[addr_offset+30] = 32'h00299993;  // ADDI x19, x19, 2     Enum operation
            memory[addr_offset+31] = 32'h003c8a13;  // ADDI x20, x25, 3     Record.component
            
            // Loop control and iteration
            memory[addr_offset+32] = 32'hfff20213;  // ADDI x4, x4, -1      Decrement counter
            memory[addr_offset+33] = 32'hfc421ae3;  // BNE  x4, x0, -40     Continue if not zero
            
            // Final calculations (simulate Dhrystone result computation)
            memory[addr_offset+34] = 32'h03e80213;  // ADDI x4, x0, 1000    Restore iteration count
            memory[addr_offset+35] = 32'h00421213;  // SLLI x4, x4, 4       x4 = iterations * 16
            memory[addr_offset+36] = 32'h00421213;  // SLLI x4, x4, 4       x4 = iterations * 256
            
            memory[addr_offset+37] = 32'hfa5ff06f;  // JAL  x0, -92         Jump back to start
        end
    endtask
    
    task load_whetstone_benchmark;
        input integer addr_offset;
        begin
            // Whetstone-like benchmark - focuses on floating-point intensive operations
            // Since MinCPU doesn't have FPU, we simulate with fixed-point arithmetic
            
            // Initialize variables for "floating-point" operations (fixed-point)
            memory[addr_offset+0]  = 32'h40000093;  // ADDI x1, x0, 1024    (x1 = 1.0 in Q10 format)
            memory[addr_offset+1]  = 32'h40000113;  // ADDI x2, x0, 1024    (x2 = 1.0 in Q10 format)
            memory[addr_offset+2]  = 32'h20000193;  // ADDI x3, x0, 512     (x3 = 0.5 in Q10 format)
            memory[addr_offset+3]  = 32'h00000213;  // ADDI x4, x0, 0       (x4 = 0.0)
            memory[addr_offset+4]  = 32'h06400293;  // ADDI x5, x0, 100     (x5 = iteration counter)
            
            // Module 1: Simple arithmetic operations
            memory[addr_offset+5]  = 32'h002081b3;  // ADD  x3, x1, x2      x3 = x1 + x2 (addition)
            memory[addr_offset+6]  = 32'h40208233;  // SUB  x4, x1, x2      x4 = x1 - x2 (subtraction)
            memory[addr_offset+7]  = 32'h00209233;  // ADD  x4, x1, x2      x4 = x1 + x2 again
            memory[addr_offset+8]  = 32'h004181b3;  // ADD  x3, x3, x4      x3 = x3 + x4
            
            // Module 2: Multiply operations (using shifts for fixed-point)
            memory[addr_offset+9]  = 32'h00209293;  // ADD  x5, x1, x2      x5 = x1 + x2
            memory[addr_offset+10] = 32'h00229293;  // SLLI x5, x5, 2       x5 = x5 * 4 (simulate multiply)
            memory[addr_offset+11] = 32'h4052d313;  // SRAI x6, x5, 5       x6 = x5 / 32 (normalize)
            memory[addr_offset+12] = 32'h00631333;  // ADD  x6, x6, x6      x6 = x6 * 2
            
            // Module 3: Conditional operations
            memory[addr_offset+13] = 32'h0061a463;  // BLT  x3, x6, +8      if (x3 < x6)
            memory[addr_offset+14] = 32'h006181b3;  // ADD  x3, x3, x6      x3 = x3 + x6
            memory[addr_offset+15] = 32'h0080006f;  // JAL  x0, +8          Skip else
            memory[addr_offset+16] = 32'h40618233;  // SUB  x4, x3, x6      x4 = x3 - x6 (else)
            memory[addr_offset+17] = 32'h00000013;  // NOP
            
            // Module 4: Array operations (simulated)
            memory[addr_offset+18] = 32'h00100393;  // ADDI x7, x0, 1       x7 = array index
            memory[addr_offset+19] = 32'h00239393;  // SLLI x7, x7, 2       x7 = x7 * 4 (word offset)
            memory[addr_offset+20] = 32'h003382b3;  // ADD  x5, x7, x3      Simulate array[i] = value
            memory[addr_offset+21] = 32'h00538423;  // SW   x5, 8(x7)       Store to memory
            memory[addr_offset+22] = 32'h0083a283;  // LW   x5, 8(x7)       Load back
            
            // Module 5: Mathematical functions (polynomial approximations)
            // Simulate sin/cos with polynomial: sin(x) ≈ x - x³/6 + x⁵/120
            memory[addr_offset+23] = 32'h00118433;  // ADD  x8, x3, x1      x8 = x (input angle)
            memory[addr_offset+24] = 32'h008404b3;  // ADD  x9, x8, x8      x9 = 2x
            memory[addr_offset+25] = 32'h009484b3;  // ADD  x9, x9, x9      x9 = 4x
            memory[addr_offset+26] = 32'h40940533;  // SUB  x10, x8, x9     x10 = x - 4x = -3x (approx -x³/6)
            memory[addr_offset+27] = 32'h00a405b3;  // ADD  x11, x8, x10    x11 = x + (-3x) = -2x (sin approx)
            
            // Module 6: Exponential function simulation
            // exp(x) ≈ 1 + x + x²/2 + x³/6
            memory[addr_offset+28] = 32'h40000613;  // ADDI x12, x0, 1024   x12 = 1.0
            memory[addr_offset+29] = 32'h008606b3;  // ADD  x13, x12, x8    x13 = 1 + x
            memory[addr_offset+30] = 32'h00241733;  // SLLI x14, x8, 2      x14 = 4x (approx x²/2)
            memory[addr_offset+31] = 32'h40e6c733;  // SUB  x14, x13, x14   Adjust scaling
            memory[addr_offset+32] = 32'h00e686b3;  // ADD  x13, x13, x14   x13 = exp approximation
            
            // Module 7: Logarithm simulation
            // log(x) ≈ (x-1) - (x-1)²/2 + (x-1)³/3
            memory[addr_offset+33] = 32'hc0040793;  // ADDI x15, x8, -1024  x15 = x - 1
            memory[addr_offset+34] = 32'h00279793;  // SLLI x15, x15, 2     x15 = 4(x-1)
            memory[addr_offset+35] = 32'h40f787b3;  // SUB  x15, x15, x15   Adjust for log
            
            // Module 8: Trigonometric operations
            // cos(x) ≈ 1 - x²/2 + x⁴/24
            memory[addr_offset+36] = 32'h40000813;  // ADDI x16, x0, 1024   x16 = 1.0
            memory[addr_offset+37] = 32'h00241893;  // SLLI x17, x8, 2      x17 = 4x (approx x²/2)
            memory[addr_offset+38] = 32'h41180833;  // SUB  x16, x16, x17   x16 = 1 - x²/2 (cos approx)
            
            // Performance measurement and loop control
            memory[addr_offset+39] = 32'hfff28293;  // ADDI x5, x5, -1      Decrement counter
            memory[addr_offset+40] = 32'hfc5292e3;  // BNE  x5, x0, -44     Continue loop
            
            // Final Whetstone score calculation
            memory[addr_offset+41] = 32'h06400293;  // ADDI x5, x0, 100     Restore iteration count
            memory[addr_offset+42] = 32'h00629293;  // SLLI x5, x5, 6       x5 = iterations * 64 (Whetstone units)
            memory[addr_offset+43] = 32'h00d2d2b3;  // SRL  x5, x5, x13     Normalize by ops/iteration
            
            memory[addr_offset+44] = 32'hf81ff06f;  // JAL  x0, -128        Jump back to start
        end
    endtask
    
    // Runtime memory access logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data <= 32'h00000013; // NOP on reset
            ready <= 1'b0;
            boot_ready <= 1'b0;
        end else begin
            // Default values
            ready <= 1'b0;
            boot_ready <= 1'b0;
            
            // Handle bootloader writes (higher priority)
            if (bootloader_mode && boot_req && boot_we) begin
                if (boot_word_addr < MEM_SIZE) begin
                    memory[boot_word_addr] <= boot_wdata;
                    boot_ready <= 1'b1;
                    $display("Bootloader: Writing 0x%08x to address 0x%08x", boot_wdata, boot_addr);
                end else begin
                    boot_ready <= 1'b1; // Acknowledge but don't write out-of-bounds
                    $display("Bootloader: Write to out-of-bounds address 0x%08x", boot_addr);
                end
            end
            
            // Handle CPU reads
            else if (req) begin
                if (word_addr < MEM_SIZE) begin
                    data <= memory[word_addr];
                end else begin
                    data <= 32'h00000013; // NOP for out-of-bounds access
                end
                ready <= 1'b1;
            end
            
            // Reload static program if requested
            if (load_static_program && !static_program_loaded) begin
                load_static_program_task();
            end
        end
    end

endmodule 