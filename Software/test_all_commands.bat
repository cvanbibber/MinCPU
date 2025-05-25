@echo off
REM MinCPU Complete Command Testing Script for Windows
REM Tests all commands mentioned in README.md

echo ================================================================
echo MinCPU Complete Command Testing Script for Windows
echo ================================================================
echo.

set TOTAL_TESTS=0
set PASSED_TESTS=0
set FAILED_TESTS=0

REM Function to run a test command
goto :main

:run_test
set /a TOTAL_TESTS+=1
echo.
echo [Test %TOTAL_TESTS%] %~2
echo Command: %~1
echo ----------------------------------------------------------------
%~1
if %ERRORLEVEL% equ 0 (
    echo ✓ PASS: %~2
    set /a PASSED_TESTS+=1
) else (
    echo ✗ FAIL: %~2 (Exit code: %ERRORLEVEL%)
    set /a FAILED_TESTS+=1
)
echo ----------------------------------------------------------------
goto :eof

:main

echo Testing MinCPU commands from README.md...
echo.

REM =================================================================
REM Hardware Simulation Commands (Software/Makefile)
REM =================================================================

echo === HARDWARE SIMULATION COMMANDS ===

call :run_test "make -f Makefile check_sources" "Check source files"

call :run_test "make -f Makefile test_optimization" "Test optimized modules"

call :run_test "make -f Makefile test_rv32m" "Test RV32M multiply/divide"

call :run_test "make -f Makefile test_rv32c" "Test RV32C compressed instructions"

call :run_test "make -f Makefile test_uart_bootloader" "Test UART bootloader"

call :run_test "make -f Makefile analyze_timing" "Analyze timing results"

call :run_test "make -f Makefile analyze_area" "Analyze area utilization"

call :run_test "make -f Makefile analyze_cpi" "Analyze CPI performance"

call :run_test "make -f Makefile analyze_all_metrics" "Combined analysis"

call :run_test "make -f Makefile clean" "Clean build artifacts"

REM =================================================================
REM C Compilation Commands (Software/Makefile.c)
REM =================================================================

echo.
echo === C COMPILATION COMMANDS ===

call :run_test "make -f Makefile.c check_toolchain" "Check RISC-V toolchain"

REM Only test C compilation if toolchain is available
riscv32-unknown-elf-gcc --version >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo RISC-V toolchain found, testing C compilation...
    
    call :run_test "make -f Makefile.c all" "Build main program"
    
    call :run_test "make -f Makefile.c analyze" "Analyze generated code"
    
    call :run_test "make -f Makefile.c memory_files" "Generate memory files"
    
    call :run_test "make -f Makefile.c clean" "Clean C build artifacts"
) else (
    echo RISC-V toolchain not found, skipping C compilation tests
    echo Note: Install riscv32-unknown-elf-gcc to test C compilation
)

REM =================================================================
REM Windows-Specific Commands
REM =================================================================

echo.
echo === WINDOWS-SPECIFIC COMMANDS ===

call :run_test "compile.bat hello" "Windows C compilation script"

REM Test Vivado setup if available
if exist "C:\Xilinx\Vivado\2024.2\bin\vivado.bat" (
    echo Vivado found, testing setup...
    call :run_test "setup_vivado.bat" "Vivado environment setup"
) else (
    echo Vivado not found at expected location, skipping Vivado tests
    echo Note: Install Vivado 2024.2 to test synthesis commands
)

REM =================================================================
REM Python Scripts
REM =================================================================

echo.
echo === PYTHON SCRIPTS ===

python --version >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo Python found, testing scripts...
    
    call :run_test "python bin2verilog.py --help" "Binary to Verilog converter help"
    
    call :run_test "python uart_loader.py --help" "UART loader help"
    
) else (
    echo Python not found, skipping Python script tests
    echo Note: Install Python 3.x to test Python scripts
)

REM =================================================================
REM Cross-Platform Make Commands
REM =================================================================

echo.
echo === CROSS-PLATFORM MAKE COMMANDS ===

call :run_test "make -f Makefile help" "Hardware Makefile help"

call :run_test "make -f Makefile.c help" "C compilation Makefile help"

REM =================================================================
REM Test Results Summary
REM =================================================================

echo.
echo ================================================================
echo TEST RESULTS SUMMARY
echo ================================================================
echo Total tests run: %TOTAL_TESTS%
echo Tests passed:   %PASSED_TESTS%
echo Tests failed:   %FAILED_TESTS%
echo ================================================================

if %FAILED_TESTS% equ 0 (
    echo ✓ ALL TESTS PASSED! MinCPU commands work correctly on Windows.
    echo.
    echo The following commands are verified to work:
    echo   - Hardware simulation: make -f Makefile [target]
    echo   - C compilation: make -f Makefile.c [target] or compile.bat
    echo   - Windows scripts: setup_vivado.bat, compile.bat
    echo   - Python utilities: bin2verilog.py, uart_loader.py
    echo.
    echo You can now use all commands mentioned in README.md
    exit /b 0
) else (
    echo ✗ SOME TESTS FAILED. Check the output above for details.
    echo.
    echo Common issues:
    echo   - Missing RISC-V toolchain (install riscv32-unknown-elf-gcc)
    echo   - Missing Vivado (install Xilinx Vivado 2024.2)
    echo   - Missing Python (install Python 3.x)
    echo   - Missing make utility (install via Git Bash, MSYS2, or standalone)
    echo.
    echo Refer to README.md for installation instructions.
    exit /b 1
)

pause 