# Simple Vivado Test Script
# Tests basic synthesis capability

puts "Starting Vivado synthesis test..."
puts "Vivado version: [version]"

# Test if we can create a project
puts "Testing project creation..."
create_project -in_memory -part xc7z020clg400-1

# Test if we can read a simple Verilog file
puts "Testing Verilog parsing..."

# Create a simple test module
set test_verilog {
module test_module (
    input clk,
    input rst_n,
    input [7:0] data_in,
    output reg [7:0] data_out
);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        data_out <= 8'h00;
    else
        data_out <= data_in + 1;
end

endmodule
}

# Write test file
set fp [open "test_module.v" w]
puts $fp $test_verilog
close $fp

# Read the test file
read_verilog test_module.v

# Test synthesis
puts "Testing synthesis..."
synth_design -top test_module -part xc7z020clg400-1

# Report results
puts "Synthesis successful!"
report_utilization

# Clean up
file delete test_module.v

puts "Vivado test completed successfully!"
exit 