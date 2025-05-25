# MinCPU Basic Synthesis Script for Vivado
# Synthesizes MinCPU with RV32I only (excludes SystemVerilog modules)

puts "Starting MinCPU basic synthesis (RV32I only)..."
puts "Vivado version: [version]"

# Create project
puts "Creating project..."
create_project mincpu_basic ./build_basic -part xc7z020clg400-1 -force

# Add core source files (excluding SystemVerilog modules)
puts "Adding core source files..."
add_files {
    ../Hardware/risc_v_cpu_optimized.v
    ../Hardware/control_unit.v
    ../Hardware/register_file.v
    ../Hardware/alu_optimized.v
    ../Hardware/immediate_gen_optimized.v
    ../Hardware/branch_unit_optimized.v
    ../Hardware/instruction_memory.v
    ../Hardware/data_memory.v
    ../Hardware/cpu_config.vh
}

# Set top module to the CPU core
puts "Setting top module to risc_v_cpu_optimized..."
set_property top risc_v_cpu_optimized [current_fileset]

# Run synthesis
puts "Running synthesis..."
synth_design -top risc_v_cpu_optimized -part xc7z020clg400-1 -directive AreaOptimized_high

# Create timing constraints after synthesis
puts "Creating timing constraints..."
create_clock -period 25.0 -name sys_clk [get_ports clk]
set_input_delay -clock sys_clk 2.0 [all_inputs]
set_output_delay -clock sys_clk 2.0 [all_outputs]
set_clock_uncertainty 0.5 [get_clocks sys_clk]

# Generate reports
puts "Generating reports..."
report_utilization -file basic_utilization.rpt
report_timing_summary -file basic_timing.rpt

# Display summary
puts "Basic synthesis complete!"
puts "Check basic_utilization.rpt and basic_timing.rpt for details"

# Show quick summary
puts "\n=== BASIC SYNTHESIS SUMMARY ==="
puts "Configuration: RV32I Core Only"
puts "Utilization:"
report_utilization

puts "\nTiming:"
report_timing_summary

puts "\n=== MinCPU basic synthesis completed successfully! ==="
exit 