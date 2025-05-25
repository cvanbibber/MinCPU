@echo off
REM Simple compilation script for MinCPU C programs
REM Usage: compile.bat [program_name]

set PROGRAM=%1
if "%PROGRAM%"=="" set PROGRAM=hello

echo Compiling %PROGRAM% for MinCPU RISC-V processor...

REM Toolchain configuration
set CROSS_PREFIX=riscv64-unknown-elf-
set ARCH=rv32imc
set ABI=ilp32
set CFLAGS=-march=%ARCH% -mabi=%ABI% -O2 -g -Wall -Wextra -fno-builtin -nostdlib -nostartfiles -ffunction-sections -fdata-sections

echo.
echo Step 1: Compiling C source...
%CROSS_PREFIX%gcc %CFLAGS% -c %PROGRAM%.c -o %PROGRAM%.o
if errorlevel 1 goto error

echo Step 2: Assembling startup code...
%CROSS_PREFIX%gcc %CFLAGS% -c start.S -o start.o
if errorlevel 1 goto error

echo Step 3: Linking executable...
%CROSS_PREFIX%gcc -march=%ARCH% -mabi=%ABI% -T mincpu.ld -nostdlib -nostartfiles -Wl,--gc-sections -Wl,-Map=%PROGRAM%.map start.o %PROGRAM%.o -o %PROGRAM%.elf
if errorlevel 1 goto error

echo Step 4: Creating binary file...
%CROSS_PREFIX%objcopy -O binary %PROGRAM%.elf %PROGRAM%.bin
if errorlevel 1 goto error

echo Step 5: Creating disassembly...
%CROSS_PREFIX%objdump -D -S %PROGRAM%.elf > %PROGRAM%.dump
if errorlevel 1 goto error

echo Step 6: Generating Verilog memory files...
python bin2verilog.py %PROGRAM%.bin %PROGRAM%_imem.v %PROGRAM%_dmem.v
if errorlevel 1 goto error

echo.
echo Compilation successful!
echo Generated files:
echo   %PROGRAM%.elf      - Executable ELF file
echo   %PROGRAM%.bin      - Raw binary file  
echo   %PROGRAM%.dump     - Disassembly listing
echo   %PROGRAM%_imem.v   - Instruction memory Verilog
echo   %PROGRAM%_dmem.v   - Data memory Verilog
echo   %PROGRAM%.map      - Memory map file

echo.
echo Program statistics:
%CROSS_PREFIX%size %PROGRAM%.elf

goto end

:error
echo.
echo ERROR: Compilation failed!
exit /b 1

:end 