/*
 * MinCPU Configuration Header
 * Allows easy reconfiguration of CPU parameters
 */

`ifndef CPU_CONFIG_VH
`define CPU_CONFIG_VH

// ========================================
// CPU Core Configuration
// ========================================

// Data and address widths
`define DATA_WIDTH 32
`define ADDR_WIDTH 32
`define REG_ADDR_WIDTH 5

// Reset vector
`define RESET_PC 32'h00001000

// Pipeline configuration
`define PIPELINE_STAGES 2
`define ENABLE_FORWARDING 1  // 0=disabled, 1=enabled (optimized implementation)

// ========================================
// ISA Feature Configuration
// ========================================

// Base instruction set
`define ENABLE_RV32I 1       // Base integer instructions (always required)
`define ENABLE_RV32M 1       // Multiplication/Division (implemented in multiplier_unit.v)
`define ENABLE_RV32C 1       // Compressed instructions (implemented in compressed_decoder.v)

// System instructions
`define ENABLE_SYSTEM_INSTR 1  // ECALL, EBREAK, CSR
`define ENABLE_FENCE_INSTR 1   // FENCE instructions

// ========================================
// Memory Configuration
// ========================================

// Instruction memory
`define IMEM_SIZE 2048       // Number of 32-bit words (8KB)
`define IMEM_ADDR_WIDTH 32
`define IMEM_BASE_ADDR 32'h00001000

// Data memory
`define DMEM_SIZE 2048       // Number of 32-bit words (8KB) 
`define DMEM_ADDR_WIDTH 32
`define DMEM_BASE_ADDR 32'h00010000

// Memory access modes
`define ENABLE_BYTE_ACCESS 1  // Byte (8-bit) memory access
`define ENABLE_HALF_ACCESS 1  // Halfword (16-bit) memory access
`define ENABLE_WORD_ACCESS 1  // Word (32-bit) memory access

// Memory loading configuration
`define ENABLE_UART_BOOTLOADER 1  // Enable UART-based program loading
`define ENABLE_STATIC_PROGRAM 1   // Enable compile-time program loading
`define DEFAULT_PROGRAM_MODE 0    // 0=static, 1=UART bootloader

// ========================================
// Performance Features
// ========================================

// Branch prediction
`define ENABLE_BRANCH_PRED 1    // 0=always not-taken, 1=static predictor
`define BRANCH_PRED_TYPE 0      // 0=static, 1=dynamic

// Optimization features
`define ENABLE_CRITICAL_PATH_OPT 1  // Enable optimized modules
`define ENABLE_FAST_ALU 1           // Use alu_optimized.v
`define ENABLE_FAST_BRANCH 1        // Use branch_unit_optimized.v
`define ENABLE_FAST_IMMED 1         // Use immediate_gen_optimized.v

// Performance counters
`define ENABLE_PERF_COUNTERS 1
`define PERF_COUNTER_WIDTH 32

// ========================================
// I/O and Peripherals
// ========================================

// UART configuration
`define UART_BASE_ADDR 32'h10000000
`define UART_DATA_ADDR 32'h10000000
`define UART_STATUS_ADDR 32'h10000004
`define UART_CONTROL_ADDR 32'h10000008
`define UART_BAUD_RATE 115200

// Bootloader configuration
`define BOOTLOADER_TIMEOUT 1000000  // Clock cycles to wait for UART
`define BOOTLOADER_MAGIC 32'hDEADBEEF  // Magic word to enter bootloader

// ========================================
// Debug and Verification
// ========================================

// Debug interface
`define ENABLE_DEBUG_INTERFACE 1
`define DEBUG_REG_COUNT 8

// Assertions and verification
`define ENABLE_ASSERTIONS 1
`define ENABLE_COVERAGE 0

// Simulation configuration
`define SIMULATION_TIMEOUT 100000  // Clock cycles
`define ENABLE_WAVEFORM_DUMP 1

// ========================================
// Hardware Optimization
// ========================================

// Register file implementation
`define REG_FILE_TYPE 0         // 0=behavioral, 1=structural

// ALU implementation selection
`define ALU_TYPE 1              // 0=basic alu.v, 1=optimized alu_optimized.v

// Clock and reset
`define CLOCK_DOMAIN_CROSSING 0  // 0=single clock, 1=multiple clocks
`define RESET_TYPE 0            // 0=async reset, 1=sync reset

// ========================================
// Area Optimization Flags
// ========================================

// Resource sharing
`define SHARE_ALU_RESOURCES 0   // 0=dedicated resources, 1=shared (may reduce performance)
`define SHARE_MEM_RESOURCES 0   // 0=dedicated, 1=shared

// Optional features for area reduction
`define ENABLE_DETAILED_EXCEPTIONS 0  // Detailed exception handling
`define ENABLE_PRIVILEGE_MODES 0      // User/Supervisor modes
`define ENABLE_VIRTUAL_MEMORY 0       // Virtual memory (not implemented)

// ========================================
// Technology-Specific Settings
// ========================================

// FPGA-specific optimizations
`define TARGET_FPGA 1           // 0=ASIC, 1=FPGA
`define FPGA_FAMILY "XILINX"    // "XILINX", "INTEL", "LATTICE", "GENERIC"
`define FPGA_PART "xc7z020clg400-1"  // Target FPGA part

// Memory implementation
`define USE_BLOCK_RAM 1         // Use FPGA block RAM for large memories
`define USE_DISTRIBUTED_RAM 0   // Use FPGA distributed RAM for small memories

// DSP utilization
`define USE_DSP_MULTIPLIERS 1   // Use DSP blocks for multiplication
`define USE_CARRY_CHAINS 1      // Use dedicated carry chains

// ========================================
// Benchmark Configuration
// ========================================

// Available benchmarks for instruction_memory.v
`define BENCHMARK_BASIC 0       // Basic arithmetic operations
`define BENCHMARK_MEMORY 1      // Memory-intensive workload
`define BENCHMARK_BRANCH 2      // Branch-prediction intensive
`define BENCHMARK_MIXED 3       // Mixed workload (default)
`define BENCHMARK_FIBONACCI 4   // Fibonacci calculation
`define BENCHMARK_BUBBLE 5      // Bubble sort algorithm
`define BENCHMARK_C_PROGRAM 6   // User C program (from bin2verilog.py)
`define BENCHMARK_DHRYSTONE 7   // Dhrystone industry benchmark
`define BENCHMARK_WHETSTONE 8   // Whetstone industry benchmark

`define DEFAULT_BENCHMARK `BENCHMARK_MIXED

// Benchmark-specific configuration
`define DHRYSTONE_ITERATIONS 1000   // Number of Dhrystone iterations
`define WHETSTONE_ITERATIONS 100    // Number of Whetstone iterations

// ========================================
// Derived Parameters (Do not modify)
// ========================================

// Calculate memory address bits
`define IMEM_ADDR_BITS $clog2(`IMEM_SIZE)
`define DMEM_ADDR_BITS $clog2(`DMEM_SIZE)

// Pipeline control
`define PIPELINE_DEPTH (`PIPELINE_STAGES)

// ISA string generation
`ifdef ENABLE_RV32I
    `define ISA_BASE "RV32I"
`else
    `error "RV32I base instruction set must always be enabled"
`endif

`ifdef ENABLE_RV32M
    `define ISA_WITH_M {`ISA_BASE, "M"}
`else
    `define ISA_WITH_M `ISA_BASE
`endif

`ifdef ENABLE_RV32C
    `define ISA_STRING {`ISA_WITH_M, "C"}
`else
    `define ISA_STRING `ISA_WITH_M
`endif

// Feature validation
`ifndef ENABLE_RV32I
    `error "RV32I base instruction set is required"
`endif

`ifdef ENABLE_RV32M
    `ifdef ENABLE_FAST_ALU
        `define USE_MULTIPLIER_UNIT 1
    `else
        `define USE_MULTIPLIER_UNIT 0
        `warning "RV32M enabled but fast ALU disabled - multiplication will be slow"
    `endif
`else
    `define USE_MULTIPLIER_UNIT 0
`endif

`ifdef ENABLE_RV32C
    `define USE_COMPRESSED_DECODER 1
`else
    `define USE_COMPRESSED_DECODER 0
`endif

// Performance optimization validation
`ifdef ENABLE_CRITICAL_PATH_OPT
    `ifndef ENABLE_FAST_ALU
        `warning "Critical path optimization enabled but fast ALU disabled"
    `endif
    `ifndef ENABLE_FAST_BRANCH
        `warning "Critical path optimization enabled but fast branch unit disabled"
    `endif
    `ifndef ENABLE_FAST_IMMED
        `warning "Critical path optimization enabled but fast immediate generator disabled"
    `endif
`endif

`endif // CPU_CONFIG_VH 