"# MinCPU Timing Constraints" 
"create_clock -period [expr 1000.0/40] -name sys_clk [get_ports clk]" 
"set_input_delay -clock sys_clk 2.0 [all_inputs]" 
"set_output_delay -clock sys_clk 2.0 [all_outputs]" 
