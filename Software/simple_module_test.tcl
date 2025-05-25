# Simple Module Synthesis Test
# Tests individual MinCPU modules

puts "Testing individual MinCPU modules..."
puts "Vivado version: [version]"

# Create project
puts "Creating project..."
create_project module_test ./build_modules -part xc7z020clg400-1 -force

# Test ALU module
puts "Testing ALU module..."
add_files {../Hardware/alu_optimized.v}
set_property top alu_optimized [current_fileset]
synth_design -top alu_optimized -part xc7z020clg400-1

puts "ALU synthesis successful!"
report_utilization

# Test register file
puts "\nTesting register file..."
remove_files [get_files]
add_files {../Hardware/register_file.v}
set_property top register_file [current_fileset]
synth_design -top register_file -part xc7z020clg400-1

puts "Register file synthesis successful!"
report_utilization

# Test immediate generator
puts "\nTesting immediate generator..."
remove_files [get_files]
add_files {../Hardware/immediate_gen_optimized.v}
set_property top immediate_gen_optimized [current_fileset]
synth_design -top immediate_gen_optimized -part xc7z020clg400-1

puts "Immediate generator synthesis successful!"
report_utilization

# Test branch unit
puts "\nTesting branch unit..."
remove_files [get_files]
add_files {../Hardware/branch_unit_optimized.v}
set_property top branch_unit_optimized [current_fileset]
synth_design -top branch_unit_optimized -part xc7z020clg400-1

puts "Branch unit synthesis successful!"
report_utilization

puts "\n=== ALL MODULE TESTS PASSED ==="
puts "Vivado synthesis is working correctly!"
puts "Individual modules can be synthesized successfully."
puts ""
puts "Next steps:"
puts "1. Fix interface mismatches between CPU and control unit"
puts "2. Convert SystemVerilog modules to standard Verilog"
puts "3. Re-run full CPU synthesis"

exit 