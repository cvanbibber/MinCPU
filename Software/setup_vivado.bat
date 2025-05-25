@echo off
REM MinCPU Vivado Setup Script for Windows
REM Sets up Vivado environment and tests installation

echo ================================================================
echo MinCPU Vivado Setup Script
echo ================================================================

REM Set Vivado installation path
set VIVADO_ROOT=C:\Xilinx\Vivado\2024.2
set VIVADO_BIN=%VIVADO_ROOT%\bin

echo Vivado installation path: %VIVADO_ROOT%
echo Vivado binary path: %VIVADO_BIN%

REM Check if Vivado installation exists
if not exist "%VIVADO_ROOT%" (
    echo ERROR: Vivado installation not found at %VIVADO_ROOT%
    echo Please verify your Vivado installation path
    pause
    exit /b 1
)

if not exist "%VIVADO_BIN%\vivado.bat" (
    echo ERROR: vivado.bat not found at %VIVADO_BIN%
    echo Please verify your Vivado installation
    pause
    exit /b 1
)

echo ✓ Vivado installation found

REM Add Vivado to PATH for this session
set PATH=%VIVADO_BIN%;%PATH%

echo ✓ Added Vivado to PATH

REM Test Vivado command
echo Testing Vivado command...
"%VIVADO_BIN%\vivado.bat" -version

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to run Vivado
    echo This might be due to licensing or installation issues
    pause
    exit /b 1
)

echo ✓ Vivado command test successful

REM Create permanent environment setup script
echo Creating permanent environment setup...
echo @echo off > vivado_env.bat
echo REM Vivado Environment Setup >> vivado_env.bat
echo set VIVADO_ROOT=%VIVADO_ROOT% >> vivado_env.bat
echo set VIVADO_BIN=%VIVADO_BIN% >> vivado_env.bat
echo set PATH=%VIVADO_BIN%;%%PATH%% >> vivado_env.bat
echo echo Vivado environment configured >> vivado_env.bat

echo ✓ Created vivado_env.bat for permanent setup

REM Test synthesis capability
echo Testing synthesis capability...
if exist "vivado_synth.tcl" (
    echo Found synthesis script: vivado_synth.tcl
    echo You can now run: make -f Makefile optimize_synthesis
) else (
    echo Synthesis script not found - will be created automatically
)

echo ================================================================
echo Vivado Setup Complete!
echo ================================================================
echo.
echo To use Vivado in future sessions:
echo 1. Run: vivado_env.bat
echo 2. Or add %VIVADO_BIN% to your system PATH
echo.
echo To test synthesis:
echo 1. Run: make -f Makefile optimize_synthesis
echo 2. Or run: vivado_env.bat ^&^& make -f Makefile optimize_synthesis
echo.
echo Current session is ready for Vivado commands.
echo ================================================================

pause 