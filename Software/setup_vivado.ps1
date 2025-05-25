# MinCPU Vivado Setup Script for Windows PowerShell
# Sets up Vivado environment and tests installation

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "MinCPU Vivado Setup Script (PowerShell)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# Set Vivado installation path
$VivadoRoot = "C:\Xilinx\Vivado\2024.2"
$VivadoBin = "$VivadoRoot\bin"
$VivadoExe = "$VivadoBin\vivado.bat"

Write-Host "Vivado installation path: $VivadoRoot" -ForegroundColor Yellow
Write-Host "Vivado binary path: $VivadoBin" -ForegroundColor Yellow

# Check if Vivado installation exists
if (-not (Test-Path $VivadoRoot)) {
    Write-Host "ERROR: Vivado installation not found at $VivadoRoot" -ForegroundColor Red
    Write-Host "Please verify your Vivado installation path" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

if (-not (Test-Path $VivadoExe)) {
    Write-Host "ERROR: vivado.bat not found at $VivadoExe" -ForegroundColor Red
    Write-Host "Please verify your Vivado installation" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✓ Vivado installation found" -ForegroundColor Green

# Add Vivado to PATH for this session
$env:PATH = "$VivadoBin;$env:PATH"
Write-Host "✓ Added Vivado to PATH for this session" -ForegroundColor Green

# Test Vivado command
Write-Host "Testing Vivado command..." -ForegroundColor Yellow
try {
    & "$VivadoExe" -version
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Vivado command test successful" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Vivado returned non-zero exit code" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: Failed to run Vivado" -ForegroundColor Red
    Write-Host "This might be due to licensing or installation issues" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to continue anyway"
}

# Create permanent environment setup script
Write-Host "Creating permanent environment setup..." -ForegroundColor Yellow

$envScript = @"
# Vivado Environment Setup (PowerShell)
`$env:VIVADO_ROOT = "$VivadoRoot"
`$env:VIVADO_BIN = "$VivadoBin"
`$env:PATH = "$VivadoBin;`$env:PATH"
Write-Host "Vivado environment configured" -ForegroundColor Green
"@

$envScript | Out-File -FilePath "vivado_env.ps1" -Encoding UTF8
Write-Host "✓ Created vivado_env.ps1 for permanent setup" -ForegroundColor Green

# Create batch file equivalent
$batScript = @"
@echo off
REM Vivado Environment Setup (Batch)
set VIVADO_ROOT=$VivadoRoot
set VIVADO_BIN=$VivadoBin
set PATH=$VivadoBin;%PATH%
echo Vivado environment configured
"@

$batScript | Out-File -FilePath "vivado_env.bat" -Encoding ASCII
Write-Host "✓ Created vivado_env.bat for batch compatibility" -ForegroundColor Green

# Test synthesis capability
Write-Host "Testing synthesis capability..." -ForegroundColor Yellow
if (Test-Path "vivado_synth.tcl") {
    Write-Host "Found synthesis script: vivado_synth.tcl" -ForegroundColor Green
    Write-Host "You can now run: make -f Makefile optimize_synthesis" -ForegroundColor Green
} else {
    Write-Host "Synthesis script not found - will be created automatically" -ForegroundColor Yellow
}

# Check for MinCPU hardware files
Write-Host "Checking MinCPU hardware files..." -ForegroundColor Yellow
$hardwareDir = "..\Hardware"
if (Test-Path $hardwareDir) {
    $verilogFiles = Get-ChildItem -Path $hardwareDir -Filter "*.v" | Measure-Object
    Write-Host "✓ Found $($verilogFiles.Count) Verilog files in $hardwareDir" -ForegroundColor Green
} else {
    Write-Host "WARNING: Hardware directory not found at $hardwareDir" -ForegroundColor Yellow
}

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Vivado Setup Complete!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To use Vivado in future PowerShell sessions:" -ForegroundColor White
Write-Host "1. Run: . .\vivado_env.ps1" -ForegroundColor Cyan
Write-Host "2. Or add $VivadoBin to your system PATH" -ForegroundColor Cyan
Write-Host ""
Write-Host "To use Vivado in future Command Prompt sessions:" -ForegroundColor White
Write-Host "1. Run: vivado_env.bat" -ForegroundColor Cyan
Write-Host ""
Write-Host "To test synthesis:" -ForegroundColor White
Write-Host "1. Run: make -f Makefile.vivado check_vivado" -ForegroundColor Cyan
Write-Host "2. Run: make -f Makefile.vivado optimize_synthesis_win" -ForegroundColor Cyan
Write-Host "3. Or run: make -f Makefile.vivado synth_only (for quick test)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Current PowerShell session is ready for Vivado commands." -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan

Read-Host "Press Enter to exit" 