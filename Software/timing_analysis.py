#!/usr/bin/env python3
"""
Critical Path Timing Analysis for MinCPU
Analyzes Verilog modules to estimate maximum operating frequency
"""

import re
import os
import sys
from typing import Dict, List, Tuple

class TimingAnalyzer:
    def __init__(self):
        # Typical gate delays (in picoseconds) for modern FPGA
        self.gate_delays = {
            'and2': 150,     # 2-input AND gate
            'or2': 150,      # 2-input OR gate
            'xor2': 200,     # 2-input XOR gate
            'mux2': 300,     # 2-input multiplexer
            'mux4': 450,     # 4-input multiplexer
            'mux8': 600,     # 8-input multiplexer
            'add1': 400,     # 1-bit adder
            'lut4': 350,     # 4-input LUT
            'lut6': 400,     # 6-input LUT
            'carry': 50,     # Carry chain delay
            'ff_setup': 100, # Flip-flop setup time
            'ff_prop': 200,  # Flip-flop propagation delay
            'ram_access': 2000,  # Block RAM access time
            'route': 100     # Routing delay per hop
        }
        
        self.module_paths = {}
        self.critical_paths = []
    
    def analyze_file(self, filename: str) -> Dict[str, int]:
        """Analyze a Verilog file and estimate delays for each module"""
        delays = {}
        
        if not os.path.exists(filename):
            return delays
            
        with open(filename, 'r') as f:
            content = f.read()
        
        # Extract module definitions
        modules = re.findall(r'module\s+(\w+).*?endmodule', content, re.DOTALL)
        
        for module_match in re.finditer(r'module\s+(\w+).*?endmodule', content, re.DOTALL):
            module_name = module_match.group(1)
            module_content = module_match.group(0)
            delay = self.estimate_module_delay(module_name, module_content)
            delays[module_name] = delay
            
        return delays
    
    def estimate_module_delay(self, module_name: str, content: str) -> int:
        """Estimate the critical path delay through a module"""
        delay = 0
        
        # Count different types of operations
        operations = {
            'arithmetic': len(re.findall(r'[+\-]', content)),
            'logical': len(re.findall(r'[&|^~]', content)),
            'shifts': len(re.findall(r'<<|>>', content)),
            'comparisons': len(re.findall(r'[<>=!]+', content)),
            'multiplexers': len(re.findall(r'\?|\bcase\b', content)),
            'assignments': len(re.findall(r'<=|=', content))
        }
        
        # Estimate delays based on module type
        if module_name == 'alu':
            delay = self.estimate_alu_delay(content)
        elif module_name == 'control_unit':
            delay = self.estimate_control_delay(content)
        elif module_name == 'register_file':
            delay = self.estimate_regfile_delay(content)
        elif 'memory' in module_name:
            delay = self.gate_delays['ram_access']
        else:
            # Generic estimation based on operations
            delay = (operations['arithmetic'] * self.gate_delays['add1'] +
                    operations['logical'] * self.gate_delays['and2'] +
                    operations['multiplexers'] * self.gate_delays['mux4'] +
                    operations['comparisons'] * self.gate_delays['lut4'])
        
        return delay
    
    def estimate_alu_delay(self, content: str) -> int:
        """Estimate ALU critical path delay"""
        # ALU has multiple operations, find worst case
        delays = {
            'add_sub': 32 * self.gate_delays['add1'] + 31 * self.gate_delays['carry'],  # 32-bit adder
            'logical': self.gate_delays['lut4'],  # Single LUT for logical ops
            'shift': 5 * self.gate_delays['mux2'],  # 5-stage barrel shifter
            'compare': self.gate_delays['add1'] * 32 + self.gate_delays['lut4'],  # Subtract + compare
            'mux_select': self.gate_delays['mux8']  # Output selection
        }
        
        # Worst case: addition + output mux
        critical_delay = delays['add_sub'] + delays['mux_select']
        return critical_delay
    
    def estimate_control_delay(self, content: str) -> int:
        """Estimate control unit delay"""
        # Control unit is mostly combinational logic
        # Count case statements and logical operations
        case_count = len(re.findall(r'\bcase\b', content))
        
        # Instruction decode: opcode -> control signals
        decode_delay = self.gate_delays['lut6'] * 2  # Two levels of LUTs
        
        # Control signal generation
        control_delay = case_count * self.gate_delays['lut4']
        
        return decode_delay + control_delay
    
    def estimate_regfile_delay(self, content: str) -> int:
        """Estimate register file delay"""
        # Register file read is typically one Block RAM access
        return self.gate_delays['ram_access'] // 2  # Distributed RAM is faster
    
    def analyze_critical_paths(self, modules_dir: str = '.') -> List[Tuple[str, int]]:
        """Analyze critical paths through the entire design"""
        verilog_files = [f for f in os.listdir(modules_dir) if f.endswith('.v')]
        all_delays = {}
        
        for vfile in verilog_files:
            file_delays = self.analyze_file(os.path.join(modules_dir, vfile))
            all_delays.update(file_delays)
        
        # Define critical paths through the pipeline
        critical_paths = [
            # Path 1: Instruction fetch and decode
            ('IF_path', [
                ('instruction_memory', all_delays.get('instruction_memory', 2000)),
                ('immediate_gen', all_delays.get('immediate_gen', 500)),
                ('control_unit', all_delays.get('control_unit', 800)),
                ('routing', 200)
            ]),
            
            # Path 2: Execute stage (ALU path)
            ('EX_ALU_path', [
                ('register_file', all_delays.get('register_file', 1000)),
                ('alu', all_delays.get('alu', 3500)),
                ('routing', 150)
            ]),
            
            # Path 3: Memory access
            ('MEM_path', [
                ('register_file', all_delays.get('register_file', 1000)),
                ('alu', all_delays.get('alu', 3500)),  # Address calculation
                ('data_memory', all_delays.get('data_memory', 2000)),
                ('routing', 200)
            ]),
            
            # Path 4: Branch/jump calculation
            ('BRANCH_path', [
                ('register_file', all_delays.get('register_file', 1000)),
                ('branch_unit', all_delays.get('branch_unit', 600)),
                ('immediate_gen', all_delays.get('immediate_gen', 500)),
                ('alu', all_delays.get('alu', 3500)),  # Address calculation
                ('routing', 150)
            ])
        ]
        
        # Calculate total delay for each path
        path_delays = []
        for path_name, components in critical_paths:
            total_delay = sum(delay for _, delay in components)
            path_delays.append((path_name, total_delay))
            
            print(f"\n{path_name}:")
            for comp_name, comp_delay in components:
                print(f"  {comp_name:20s}: {comp_delay:6d} ps")
            print(f"  {'Total':20s}: {total_delay:6d} ps")
        
        return path_delays
    
    def calculate_max_frequency(self, critical_delay_ps: int) -> float:
        """Calculate maximum frequency given critical path delay"""
        # Add setup time and safety margin
        setup_time = self.gate_delays['ff_setup']
        safety_margin = 500  # 500ps safety margin
        
        total_delay = critical_delay_ps + setup_time + safety_margin
        
        # Convert to frequency (MHz)
        period_ns = total_delay / 1000.0
        frequency_mhz = 1000.0 / period_ns
        
        return frequency_mhz
    
    def generate_timing_report(self, modules_dir: str = '.'):
        """Generate comprehensive timing analysis report"""
        print("=" * 60)
        print("MinCPU Critical Path Timing Analysis")
        print("=" * 60)
        
        # Analyze individual modules
        verilog_files = [f for f in os.listdir(modules_dir) if f.endswith('.v')]
        all_delays = {}
        
        print("\nModule Delay Analysis:")
        print("-" * 40)
        
        for vfile in verilog_files:
            file_delays = self.analyze_file(os.path.join(modules_dir, vfile))
            all_delays.update(file_delays)
            
            for module, delay in file_delays.items():
                print(f"{module:20s}: {delay:6d} ps ({delay/1000:.2f} ns)")
        
        # Analyze critical paths
        print("\nCritical Path Analysis:")
        print("-" * 40)
        
        path_delays = self.analyze_critical_paths(modules_dir)
        
        # Find worst case
        worst_path, worst_delay = max(path_delays, key=lambda x: x[1])
        
        print(f"\nWorst Case Critical Path: {worst_path}")
        print(f"Critical Path Delay: {worst_delay} ps ({worst_delay/1000:.2f} ns)")
        
        # Calculate maximum frequency
        max_freq = self.calculate_max_frequency(worst_delay)
        
        print(f"\nFrequency Analysis:")
        print("-" * 40)
        print(f"Setup Time:        {self.gate_delays['ff_setup']:6d} ps")
        print(f"Safety Margin:     {500:6d} ps")
        print(f"Total Cycle Time:  {worst_delay + self.gate_delays['ff_setup'] + 500:6d} ps")
        print(f"Maximum Frequency: {max_freq:6.1f} MHz")
        
        # Performance projections
        print(f"\nPerformance Projections:")
        print("-" * 40)
        cpi_estimates = [1.2, 1.5, 2.0]  # Different CPI scenarios
        
        for cpi in cpi_estimates:
            mips = max_freq / cpi
            print(f"CPI {cpi:.1f}:  {mips:6.1f} MIPS @ {max_freq:.1f} MHz")
        
        # Area estimation
        self.estimate_area()
        
        return max_freq, worst_delay
    
    def estimate_area(self):
        """Estimate FPGA resource usage"""
        print(f"\nArea Estimation (Xilinx 7-series):")
        print("-" * 40)
        
        # Rough estimates based on module complexity
        area_estimates = {
            'ALU': {'LUTs': 250, 'FFs': 0, 'DSP': 0},
            'Register File': {'LUTs': 200, 'FFs': 1024, 'DSP': 0},
            'Control Unit': {'LUTs': 150, 'FFs': 10, 'DSP': 0},
            'Pipeline Regs': {'LUTs': 50, 'FFs': 128, 'DSP': 0},
            'PC Logic': {'LUTs': 100, 'FFs': 32, 'DSP': 0},
            'Immediate Gen': {'LUTs': 80, 'FFs': 0, 'DSP': 0},
            'Branch Unit': {'LUTs': 50, 'FFs': 0, 'DSP': 0},
            'Memory Interface': {'LUTs': 100, 'FFs': 20, 'DSP': 0},
            'Debug Logic': {'LUTs': 70, 'FFs': 64, 'DSP': 0}
        }
        
        total_luts = sum(est['LUTs'] for est in area_estimates.values())
        total_ffs = sum(est['FFs'] for est in area_estimates.values())
        total_bram = 2  # Instruction and data memory
        
        print(f"{'Component':15s} | {'LUTs':5s} | {'FFs':5s} | {'DSP':3s}")
        print("-" * 40)
        
        for comp, resources in area_estimates.items():
            print(f"{comp:15s} | {resources['LUTs']:5d} | {resources['FFs']:5d} | {resources['DSP']:3d}")
        
        print("-" * 40)
        print(f"{'TOTAL':15s} | {total_luts:5d} | {total_ffs:5d} | {0:3d}")
        print(f"Block RAMs: {total_bram}")
        
        # Compare to typical FPGA sizes
        fpga_sizes = {
            'XC7A35T': {'LUTs': 20800, 'FFs': 41600, 'BRAM': 50},
            'XC7A50T': {'LUTs': 32600, 'FFs': 65200, 'BRAM': 150},
            'XC7A100T': {'LUTs': 63400, 'FFs': 126800, 'BRAM': 135}
        }
        
        print(f"\nFPGA Utilization:")
        print("-" * 40)
        for fpga, resources in fpga_sizes.items():
            lut_util = (total_luts / resources['LUTs']) * 100
            ff_util = (total_ffs / resources['FFs']) * 100
            bram_util = (total_bram / resources['BRAM']) * 100
            print(f"{fpga}: LUT {lut_util:4.1f}% | FF {ff_util:4.1f}% | BRAM {bram_util:4.1f}%")

def main():
    analyzer = TimingAnalyzer()
    
    # Determine the hardware directory
    hw_dir = '.' if os.path.exists('./risc_v_cpu.v') else './Hardware'
    
    if not os.path.exists(os.path.join(hw_dir, 'risc_v_cpu.v')):
        print("Error: Cannot find MinCPU Verilog files")
        print("Please run this script from the Hardware directory or project root")
        sys.exit(1)
    
    # Generate timing report
    max_freq, critical_delay = analyzer.generate_timing_report(hw_dir)
    
    # Output summary for automation
    print(f"\n" + "=" * 60)
    print(f"SUMMARY: Max Frequency = {max_freq:.1f} MHz, Critical Delay = {critical_delay/1000:.2f} ns")

if __name__ == "__main__":
    main() 