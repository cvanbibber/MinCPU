# MinCPU Synthesis Script for Vivado
# Synthesizes the complete MinCPU RISC-V processor

puts "Starting MinCPU synthesis..."
puts "Vivado version: [version]"

# Create project
puts "Creating project..."
create_project mincpu_synth ./build_mincpu -part xc7z020clg400-1 -force

# Add all source files
puts "Adding source files..."
add_files {
    ../Hardware/risc_v_cpu_optimized.v
    ../Hardware/control_unit.v
    ../Hardware/register_file.v
    ../Hardware/alu_optimized.v
    ../Hardware/immediate_gen_optimized.v
    ../Hardware/branch_unit_optimized.v
    ../Hardware/multiplier_unit.v
    ../Hardware/compressed_decoder.v
    ../Hardware/uart_bootloader.v
    ../Hardware/instruction_memory.v
    ../Hardware/data_memory.v
    ../Hardware/performance_analyzer.v
    ../Hardware/cpu_config.vh
}

# Set top module
puts "Setting top module to performance_analyzer..."
set_property top performance_analyzer [current_fileset]

# Create timing constraints
puts "Creating timing constraints..."
create_clock -period 25.0 -name sys_clk [get_ports clk]
set_input_delay -clock sys_clk 2.0 [all_inputs]
set_output_delay -clock sys_clk 2.0 [all_outputs]
set_clock_uncertainty 0.5 [get_clocks sys_clk]

# Run synthesis
puts "Running synthesis..."
synth_design -top performance_analyzer -part xc7z020clg400-1 -directive AreaOptimized_high

# Generate reports
puts "Generating reports..."
report_utilization -file utilization_report.rpt
report_timing_summary -file timing_summary.rpt

# Display summary
puts "Synthesis complete!"
puts "Check utilization_report.rpt and timing_summary.rpt for details"

# Show quick summary
puts "\n=== SYNTHESIS SUMMARY ==="
puts "Utilization:"
report_utilization

puts "\nTiming:"
report_timing_summary

puts "\n=== MinCPU synthesis completed successfully! ==="
exit 