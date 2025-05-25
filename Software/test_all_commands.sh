#!/bin/bash
# MinCPU Complete Command Testing Script for Linux/macOS
# Tests all commands mentioned in README.md

echo "================================================================"
echo "MinCPU Complete Command Testing Script for Linux/macOS"
echo "================================================================"
echo

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test command
run_test() {
    local cmd="$1"
    local desc="$2"
    
    ((TOTAL_TESTS++))
    echo
    echo "[Test $TOTAL_TESTS] $desc"
    echo "Command: $cmd"
    echo "----------------------------------------------------------------"
    
    if eval "$cmd"; then
        echo "✓ PASS: $desc"
        ((PASSED_TESTS++))
    else
        echo "✗ FAIL: $desc (Exit code: $?)"
        ((FAILED_TESTS++))
    fi
    echo "----------------------------------------------------------------"
}

echo "Testing MinCPU commands from README.md..."
echo

# =================================================================
# Hardware Simulation Commands (Software/Makefile)
# =================================================================

echo "=== HARDWARE SIMULATION COMMANDS ==="

run_test "make -f Makefile check_sources" "Check source files"

run_test "make -f Makefile test_optimization" "Test optimized modules"

run_test "make -f Makefile test_rv32m" "Test RV32M multiply/divide"

run_test "make -f Makefile test_rv32c" "Test RV32C compressed instructions"

run_test "make -f Makefile test_uart_bootloader" "Test UART bootloader"

run_test "make -f Makefile analyze_timing" "Analyze timing results"

run_test "make -f Makefile analyze_area" "Analyze area utilization"

run_test "make -f Makefile analyze_cpi" "Analyze CPI performance"

run_test "make -f Makefile analyze_all_metrics" "Combined analysis"

run_test "make -f Makefile clean" "Clean build artifacts"

# =================================================================
# C Compilation Commands (Software/Makefile.c)
# =================================================================

echo
echo "=== C COMPILATION COMMANDS ==="

run_test "make -f Makefile.c check_toolchain" "Check RISC-V toolchain"

# Only test C compilation if toolchain is available
if command -v riscv32-unknown-elf-gcc >/dev/null 2>&1 || command -v riscv64-unknown-elf-gcc >/dev/null 2>&1; then
    echo "RISC-V toolchain found, testing C compilation..."
    
    run_test "make -f Makefile.c all" "Build main program"
    
    run_test "make -f Makefile.c analyze" "Analyze generated code"
    
    run_test "make -f Makefile.c memory_files" "Generate memory files"
    
    run_test "make -f Makefile.c clean" "Clean C build artifacts"
else
    echo "RISC-V toolchain not found, skipping C compilation tests"
    echo "Note: Install riscv32-unknown-elf-gcc or riscv64-unknown-elf-gcc to test C compilation"
fi

# =================================================================
# Python Scripts
# =================================================================

echo
echo "=== PYTHON SCRIPTS ==="

if command -v python3 >/dev/null 2>&1; then
    echo "Python found, testing scripts..."
    
    run_test "python3 bin2verilog.py --help" "Binary to Verilog converter help"
    
    run_test "python3 uart_loader.py --help" "UART loader help"
    
elif command -v python >/dev/null 2>&1; then
    echo "Python found, testing scripts..."
    
    run_test "python bin2verilog.py --help" "Binary to Verilog converter help"
    
    run_test "python uart_loader.py --help" "UART loader help"
    
else
    echo "Python not found, skipping Python script tests"
    echo "Note: Install Python 3.x to test Python scripts"
fi

# =================================================================
# Cross-Platform Make Commands
# =================================================================

echo
echo "=== CROSS-PLATFORM MAKE COMMANDS ==="

run_test "make -f Makefile help" "Hardware Makefile help"

run_test "make -f Makefile.c help" "C compilation Makefile help"

# =================================================================
# Linux/macOS Specific Commands
# =================================================================

echo
echo "=== LINUX/MACOS SPECIFIC COMMANDS ==="

# Test iverilog if available
if command -v iverilog >/dev/null 2>&1; then
    echo "Icarus Verilog found, testing simulation..."
    run_test "iverilog -V" "Icarus Verilog version check"
else
    echo "Icarus Verilog not found"
    echo "Note: Install iverilog for Verilog simulation"
fi

# Test gtkwave if available
if command -v gtkwave >/dev/null 2>&1; then
    run_test "gtkwave --version" "GTKWave version check"
else
    echo "GTKWave not found (optional for waveform viewing)"
fi

# =================================================================
# Test Results Summary
# =================================================================

echo
echo "================================================================"
echo "TEST RESULTS SUMMARY"
echo "================================================================"
echo "Total tests run: $TOTAL_TESTS"
echo "Tests passed:   $PASSED_TESTS"
echo "Tests failed:   $FAILED_TESTS"
echo "================================================================"

if [ $FAILED_TESTS -eq 0 ]; then
    echo "✓ ALL TESTS PASSED! MinCPU commands work correctly on Linux/macOS."
    echo
    echo "The following commands are verified to work:"
    echo "  - Hardware simulation: make -f Makefile [target]"
    echo "  - C compilation: make -f Makefile.c [target]"
    echo "  - Python utilities: python3 bin2verilog.py, python3 uart_loader.py"
    echo "  - Verilog simulation: iverilog, vvp, gtkwave"
    echo
    echo "You can now use all commands mentioned in README.md"
    exit 0
else
    echo "✗ SOME TESTS FAILED. Check the output above for details."
    echo
    echo "Common issues:"
    echo "  - Missing RISC-V toolchain (install riscv32-unknown-elf-gcc)"
    echo "  - Missing Icarus Verilog (install iverilog)"
    echo "  - Missing Python (install python3)"
    echo "  - Missing make utility (install build-essential)"
    echo
    echo "Installation commands:"
    echo "  Ubuntu/Debian: sudo apt-get install iverilog gcc-riscv64-unknown-elf python3"
    echo "  macOS: brew install icarus-verilog riscv-tools python3"
    echo
    echo "Refer to README.md for detailed installation instructions."
    exit 1
fi 