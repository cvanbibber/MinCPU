# Vivado Setup Guide for MinCPU on Windows

This guide will help you set up Vivado for command line synthesis with the MinCPU project on Windows.

## Prerequisites

- **Vivado installed** at `C:\Xilinx\Vivado\2024.2` (or similar version)
- **Valid Vivado license** (WebPACK license is sufficient for xc7z020)
- **Windows 10/11** with PowerShell or Command Prompt
- **Make utility** (Git Bash, MSYS2, or standalone make)

## Quick Setup (Recommended)

### Option 1: PowerShell Setup (Recommended)
```powershell
# Navigate to Software directory
cd Software

# Run PowerShell setup script
.\setup_vivado.ps1

# Test the setup
make -f Makefile.vivado check_vivado
```

### Option 2: Command Prompt Setup
```batch
# Navigate to Software directory
cd Software

# Run batch setup script
setup_vivado.bat

# Test the setup
make -f Makefile.vivado check_vivado
```

## Manual Setup

If the automatic scripts don't work, follow these manual steps:

### Step 1: Verify Vivado Installation
1. Check that Vivado is installed at `C:\Xilinx\Vivado\2024.2`
2. Verify that `C:\Xilinx\Vivado\2024.2\bin\vivado.bat` exists
3. Test Vivado from Command Prompt:
   ```batch
   "C:\Xilinx\Vivado\2024.2\bin\vivado.bat" -version
   ```

### Step 2: Add Vivado to PATH

#### Temporary (Current Session Only)
```batch
# Command Prompt
set PATH=C:\Xilinx\Vivado\2024.2\bin;%PATH%

# PowerShell
$env:PATH = "C:\Xilinx\Vivado\2024.2\bin;$env:PATH"
```

#### Permanent (System-wide)
1. Open **System Properties** → **Advanced** → **Environment Variables**
2. Add `C:\Xilinx\Vivado\2024.2\bin` to your **System PATH**
3. Restart your terminal

### Step 3: Test Vivado Access
```batch
vivado -version
```

## Using Vivado with MinCPU

### Basic Synthesis Commands

```bash
# Navigate to Software directory
cd Software

# Check Vivado installation
make -f Makefile.vivado check_vivado

# Run quick synthesis (no place & route)
make -f Makefile.vivado synth_only

# Run full synthesis with optimization
make -f Makefile.vivado optimize_synthesis_win

# Analyze results
make -f Makefile.vivado analyze_results
```

### Alternative: Using Original Makefile

If you prefer to use the original Makefile with Vivado properly configured:

```bash
# After setting up Vivado environment
vivado_env.bat  # or . .\vivado_env.ps1 in PowerShell

# Use original Makefile
make -f Makefile optimize_synthesis
```

## Expected Results

### Successful Setup Output
```
================================================================
MinCPU Vivado Setup Script
================================================================
Vivado installation path: C:\Xilinx\Vivado\2024.2
Vivado binary path: C:\Xilinx\Vivado\2024.2\bin
✓ Vivado installation found
✓ Added Vivado to PATH
Testing Vivado command...
Vivado v2024.2 (64-bit)
✓ Vivado command test successful
✓ Created vivado_env.bat for permanent setup
================================================================
Vivado Setup Complete!
================================================================
```

### Successful Synthesis Output
```
Checking Vivado installation...
Looking for Vivado at: C:/Xilinx/Vivado/2024.2
✓ Found Vivado at C:/Xilinx/Vivado/2024.2/bin/vivado.bat
Running Windows-optimized synthesis flow...
Target: 40 MHz on xc7z020clg400-1
Starting Vivado synthesis...
Synthesis complete. Check synthesis_win.log for details.
Timing report generated: timing_report_win.rpt
Area report generated: area_report_win.rpt
```

## Troubleshooting

### Common Issues

#### 1. "Vivado not found" Error
```
✗ Vivado not found at C:/Xilinx/Vivado/2024.2/bin/vivado.bat
```

**Solutions:**
- Verify Vivado installation path
- Check if you have a different Vivado version (2024.1, 2023.2, etc.)
- Update the path in `setup_vivado.bat` or `Makefile.vivado`

#### 2. "Command not found" Error
```
'vivado' is not recognized as an internal or external command
```

**Solutions:**
- Run `setup_vivado.bat` or `setup_vivado.ps1`
- Manually add Vivado to PATH
- Use full path: `"C:\Xilinx\Vivado\2024.2\bin\vivado.bat"`

#### 3. License Issues
```
ERROR: [Common 17-69] Command failed: This design contains one or more cells for which bitstream generation is not permitted
```

**Solutions:**
- Ensure you have a valid Vivado license
- For xc7z020, WebPACK license should be sufficient
- Check license server configuration

#### 4. Synthesis Errors
```
ERROR: [Synth 8-439] module 'performance_analyzer' not found
```

**Solutions:**
- Verify all Hardware files are present
- Run `make -f Makefile check_sources` first
- Check that `cpu_config.vh` is properly configured

### Different Vivado Versions

If you have a different Vivado version, update the paths:

#### For Vivado 2024.1:
```batch
# In setup_vivado.bat, change:
set VIVADO_ROOT=C:\Xilinx\Vivado\2024.1

# In Makefile.vivado, change:
VIVADO_ROOT = C:/Xilinx/Vivado/2024.1
```

#### For Vivado 2023.2:
```batch
# In setup_vivado.bat, change:
set VIVADO_ROOT=C:\Xilinx\Vivado\2023.2

# In Makefile.vivado, change:
VIVADO_ROOT = C:/Xilinx/Vivado/2023.2
```

## Performance Expectations

### Synthesis Results (Expected)
- **LUTs**: ~850-950 (1.6-1.8% of xc7z020)
- **Flip-Flops**: ~400-500 (0.4-0.5% of xc7z020)
- **BRAMs**: 2-3 (1.4-2.1% of xc7z020)
- **Max Frequency**: 40-50 MHz
- **Synthesis Time**: 2-5 minutes

### Timing Analysis
- **Critical Path**: ~20-25 ns
- **Setup Slack**: Should be positive for 40 MHz
- **Hold Violations**: Should be zero

### Area Analysis
- **Total Area**: ~0.8-1.0 mm²
- **Performance Density**: 40-50 MIPS/mm²
- **Resource Efficiency**: Very good for educational CPU

## Advanced Usage

### Custom Synthesis Scripts

You can create custom synthesis scripts for specific optimizations:

```tcl
# custom_synth.tcl
create_project -in_memory -part xc7z020clg400-1
read_verilog {../Hardware/*.v}
synth_design -top performance_analyzer -directive AreaOptimized_high
opt_design -directive ExploreArea
place_design -directive ExtraPostPlacementOpt
route_design -directive Explore
report_utilization
report_timing_summary
```

### Batch Processing

For automated builds:

```batch
@echo off
call vivado_env.bat
make -f Makefile.vivado clean
make -f Makefile.vivado optimize_synthesis_win
make -f Makefile.vivado analyze_results
```

## Integration with Development Workflow

### Complete Development Flow

1. **Setup Environment**:
   ```batch
   setup_vivado.bat
   ```

2. **Hardware Simulation**:
   ```bash
   make -f Makefile performance_analysis
   ```

3. **Synthesis and Implementation**:
   ```bash
   make -f Makefile.vivado optimize_synthesis_win
   ```

4. **Analysis**:
   ```bash
   make -f Makefile.vivado analyze_results
   ```

5. **Iterate and Optimize**:
   - Modify `cpu_config.vh` for different configurations
   - Re-run synthesis to compare results

## Support and Resources

### Documentation
- **Vivado User Guide**: UG835 (Vivado Design Suite User Guide)
- **Synthesis Guide**: UG901 (Vivado Design Suite User Guide: Synthesis)
- **Implementation Guide**: UG904 (Vivado Design Suite User Guide: Implementation)

### MinCPU Specific
- Check `README.md` for general project information
- See `PERFORMANCE_ANALYSIS.md` for detailed benchmarks
- Review `cpu_config.vh` for configuration options

### Getting Help
1. Check synthesis logs: `synthesis_win.log`
2. Review timing reports: `timing_report_win.rpt`
3. Analyze area reports: `area_report_win.rpt`
4. Run `make -f Makefile.vivado help` for command reference

---

**Note**: This guide assumes Vivado 2024.2 installation. Adjust paths accordingly for different versions. The MinCPU project is designed to work with Vivado WebPACK license and targets the xc7z020 FPGA (Pynq-Z1 board). 