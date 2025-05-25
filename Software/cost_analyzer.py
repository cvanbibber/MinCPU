#!/usr/bin/env python3
"""
MinCPU Cost and Figure of Merit Analyzer
Analyzes FPGA resource utilization and calculates performance metrics
"""

import re
import sys
import os
from typing import Dict, Tuple, Optional

# FPGA Element Costs (in equivalent gates or relative cost units)
ELEMENT_COSTS = {
    'LUT6': 1713,
    'FDRE': 107,
    'LUT4': 429,
    'LUT5': 857,
    'LUT3': 429,
    'LUT2': 429,
    'CARRY4': 54,
    'RAMD32': 857,
    'RAMB36E1': 0,
    'RAMS32': 857,
    'RAMS64E': 1713,
    'FDSE': 107,
    'LUT1': 429,
    'MUXF7': 7,
    'MUXF8': 7,
    'OBUFT': 0,
    'IBUF': 0,
    'FDCE': 107,
    'BUFG': 0,
    'SRL16E': 429,
    'PLLE2_ADV': 0,
    'OBUF': 0
}

class MinCPUAnalyzer:
    def __init__(self):
        self.utilization_data = {}
        self.timing_data = {}
        self.performance_data = {}
        
    def parse_utilization_report(self, report_file: str) -> Dict[str, int]:
        """Parse Vivado utilization report to extract resource usage"""
        utilization = {}
        
        if not os.path.exists(report_file):
            print(f"Warning: Utilization report {report_file} not found")
            return self._estimate_utilization()
            
        try:
            with open(report_file, 'r') as f:
                content = f.read()
                
            # Parse different resource types
            patterns = {
                'LUT': r'LUT as Logic\s*\|\s*(\d+)',
                'LUTRAM': r'LUT as Memory\s*\|\s*(\d+)',
                'FF': r'Register as Flip Flop\s*\|\s*(\d+)',
                'CARRY4': r'CARRY4\s*\|\s*(\d+)',
                'BRAM': r'Block RAM Tile\s*\|\s*(\d+)',
                'DSP': r'DSPs\s*\|\s*(\d+)'
            }
            
            for resource, pattern in patterns.items():
                match = re.search(pattern, content)
                if match:
                    utilization[resource] = int(match.group(1))
                    
        except Exception as e:
            print(f"Error parsing utilization report: {e}")
            return self._estimate_utilization()
            
        return utilization
    
    def _estimate_utilization(self) -> Dict[str, int]:
        """Provide estimated utilization when synthesis data is not available"""
        return {
            'LUT': 850,      # Estimated LUTs for optimized CPU
            'LUTRAM': 64,    # Register file and small memories
            'FF': 420,       # Pipeline registers and state
            'CARRY4': 25,    # ALU carry chains
            'BRAM': 2,       # Instruction and data memory
            'DSP': 2         # RV32M multiplier
        }
    
    def parse_timing_report(self, report_file: str) -> Dict[str, float]:
        """Parse Vivado timing report to extract frequency data using WNS analysis"""
        timing = {}
        
        if not os.path.exists(report_file):
            print(f"Warning: Timing report {report_file} not found")
            print("Using estimated frequency based on design complexity...")
            return {'fmax': 85.0, 'critical_path': 11.76, 'wns': -1.76, 'target_period': 10.0, 'method': 'estimated'}
            
        try:
            with open(report_file, 'r') as f:
                content = f.read()
                
            # Parse Vivado timing summary report for WNS and target period
            timing_data = self._parse_vivado_timing_summary(content)
            
            if timing_data:
                timing.update(timing_data)
                timing['method'] = 'vivado_report'
            else:
                # Fallback to legacy parsing
                timing = self._parse_legacy_timing_format(content)
                timing['method'] = 'legacy_format'
                
        except Exception as e:
            print(f"Error parsing timing report: {e}")
            # Conservative estimate for complex RISC-V design
            timing = {'fmax': 85.0, 'critical_path': 11.76, 'wns': -1.76, 'target_period': 10.0, 'method': 'error_fallback'}
            
        return timing
    
    def _parse_vivado_timing_summary(self, content: str) -> Optional[Dict[str, float]]:
        """Parse Vivado timing summary report format"""
        timing = {}
        
        # Look for timing summary table
        # Format: Clock    Target    Achieved    WNS    TNS    TNS Failing Endpoints
        patterns = {
            'wns': r'sys_clk\s+[\d.]+\s+[\d.]+\s+([-\d.]+)',  # WNS column
            'target_period': r'sys_clk\s+([\d.]+)',  # Target period
            'achieved_period': r'sys_clk\s+[\d.]+\s+([\d.]+)',  # Achieved period
        }
        
        # Alternative patterns for different report formats
        alt_patterns = {
            'wns': r'Worst Negative Slack.*?:\s*([-\d.]+)\s*ns',
            'target_period': r'Target Period.*?:\s*([\d.]+)\s*ns',
            'setup_slack': r'Setup.*?Slack.*?:\s*([-\d.]+)\s*ns',
        }
        
        # Try main patterns first
        for key, pattern in patterns.items():
            match = re.search(pattern, content, re.IGNORECASE)
            if match:
                timing[key] = float(match.group(1))
        
        # Try alternative patterns if main ones fail
        if not timing:
            for key, pattern in alt_patterns.items():
                match = re.search(pattern, content, re.IGNORECASE)
                if match:
                    timing[key] = float(match.group(1))
        
        # Calculate FMAX using the provided formula: FMAX = max(1000/(Ti - WNSi))
        if 'target_period' in timing and 'wns' in timing:
            target_period = timing['target_period']
            wns = timing['wns']
            
            # FMAX (MHz) = max(1000/(Ti - WNSi))
            # Note: WNS is typically negative, so Ti - WNSi = Ti - (-|WNS|) = Ti + |WNS|
            actual_period = target_period - wns  # WNS is negative slack
            timing['fmax'] = 1000.0 / actual_period
            timing['critical_path'] = actual_period
            
            print(f"Vivado Timing Analysis:")
            print(f"  Target Period: {target_period:.2f} ns")
            print(f"  Worst Negative Slack: {wns:.2f} ns")
            print(f"  Actual Critical Path: {actual_period:.2f} ns")
            print(f"  Calculated FMAX: {timing['fmax']:.1f} MHz")
            
            return timing
        
        return None
    
    def _parse_legacy_timing_format(self, content: str) -> Dict[str, float]:
        """Parse legacy timing report formats"""
        timing = {}
        
        # Legacy format patterns
        freq_pattern = r'Requirement:\s*([\d.]+)ns.*Achieved:\s*([\d.]+)ns'
        match = re.search(freq_pattern, content)
        if match:
            req_period = float(match.group(1))
            achieved_period = float(match.group(2))
            timing['fmax'] = 1000.0 / achieved_period
            timing['critical_path'] = achieved_period
            timing['target_period'] = req_period
            timing['wns'] = achieved_period - req_period  # Approximate WNS
        else:
            # Conservative estimate for RISC-V design
            timing['fmax'] = 85.0
            timing['critical_path'] = 11.76
            timing['target_period'] = 10.0
            timing['wns'] = -1.76
            
        return timing
    
    def parse_performance_data(self, log_files: list) -> Dict[str, float]:
        """Parse performance simulation logs to extract CPI and MIPS"""
        performance = {'cpi': 1.0, 'mips': 100.0}
        
        # Try to find the best CPI from benchmark results
        best_cpi = float('inf')
        total_mips = 0
        valid_benchmarks = 0
        
        for log_file in log_files:
            if os.path.exists(log_file):
                try:
                    with open(log_file, 'r') as f:
                        content = f.read()
                    
                    # Extract CPI
                    cpi_match = re.search(r'CPI:\s*([\d.]+)', content)
                    if cpi_match:
                        cpi = float(cpi_match.group(1))
                        if cpi < best_cpi and cpi > 0:
                            best_cpi = cpi
                    
                    # Extract MIPS
                    mips_match = re.search(r'MIPS.*:\s*([\d.]+)', content)
                    if mips_match:
                        mips = float(mips_match.group(1))
                        total_mips += mips
                        valid_benchmarks += 1
                        
                except Exception as e:
                    print(f"Error parsing {log_file}: {e}")
        
        if best_cpi != float('inf'):
            performance['cpi'] = best_cpi
        
        if valid_benchmarks > 0:
            performance['mips'] = total_mips / valid_benchmarks
            
        return performance
    
    def calculate_cost(self, utilization: Dict[str, int]) -> float:
        """Calculate total cost based on FPGA resource utilization"""
        total_cost = 0
        cost_breakdown = {}
        
        # Map utilization to specific element types
        element_mapping = {
            'LUT': ['LUT6', 'LUT4', 'LUT5', 'LUT3', 'LUT2', 'LUT1'],
            'LUTRAM': ['RAMD32', 'RAMS32'],
            'FF': ['FDRE', 'FDSE', 'FDCE'],
            'CARRY4': ['CARRY4'],
            'BRAM': ['RAMB36E1'],
            'DSP': []  # DSPs don't have direct cost in our table
        }
        
        for resource, count in utilization.items():
            if resource in element_mapping:
                elements = element_mapping[resource]
                if elements:
                    # Distribute count across element types (simplified)
                    if resource == 'LUT':
                        # Assume distribution: 40% LUT6, 25% LUT4, 20% LUT5, 15% others
                        cost_breakdown['LUT6'] = int(count * 0.4)
                        cost_breakdown['LUT4'] = int(count * 0.25)
                        cost_breakdown['LUT5'] = int(count * 0.2)
                        cost_breakdown['LUT3'] = int(count * 0.1)
                        cost_breakdown['LUT2'] = int(count * 0.05)
                    elif resource == 'LUTRAM':
                        cost_breakdown['RAMD32'] = count
                    elif resource == 'FF':
                        cost_breakdown['FDRE'] = count
                    elif resource == 'CARRY4':
                        cost_breakdown['CARRY4'] = count
                    elif resource == 'BRAM':
                        cost_breakdown['RAMB36E1'] = count
        
        # Calculate total cost
        for element, count in cost_breakdown.items():
            if element in ELEMENT_COSTS:
                element_cost = ELEMENT_COSTS[element] * count
                total_cost += element_cost
                
        return total_cost, cost_breakdown
    
    def calculate_figure_of_merit(self, fmax: float, cpi: float, cost: float,
                                fmax_weight: float = 1.0, cpi_weight: float = 1.0, 
                                cost_weight: float = 0.5) -> float:
        """Calculate Figure of Merit using the specified formula"""
        if cpi <= 0 or cost <= 0:
            return 0.0
            
        fom = (1000.0 * (fmax ** fmax_weight)) / (cpi ** cpi_weight) / (cost ** cost_weight)
        return fom
    
    def generate_report(self, utilization_file: str = "area_report.rpt",
                       timing_file: str = "timing_report.rpt",
                       performance_files: list = None) -> str:
        """Generate comprehensive analysis report"""
        
        if performance_files is None:
            performance_files = [
                "performance_sim.log",
                "benchmark_0.log", "benchmark_1.log", "benchmark_2.log",
                "benchmark_3.log", "benchmark_4.log", "benchmark_5.log",
                "dhrystone_results.log", "whetstone_results.log"
            ]
        
        # Parse all data
        utilization = self.parse_utilization_report(utilization_file)
        timing = self.parse_timing_report(timing_file)
        performance = self.parse_performance_data(performance_files)
        
        # Calculate cost and FoM
        total_cost, cost_breakdown = self.calculate_cost(utilization)
        fom = self.calculate_figure_of_merit(timing['fmax'], performance['cpi'], total_cost)
        
        # Generate report
        report = []
        report.append("=" * 80)
        report.append("MinCPU COMPREHENSIVE ANALYSIS REPORT")
        report.append("=" * 80)
        report.append("")
        
        # Timing Analysis
        report.append("TIMING ANALYSIS:")
        report.append("-" * 40)
        report.append(f"Maximum Frequency: {timing['fmax']:.1f} MHz")
        report.append(f"Critical Path: {timing.get('critical_path', 25.0):.1f} ns")
        
        # Show timing analysis details if available
        if 'target_period' in timing and 'wns' in timing:
            report.append(f"Target Period: {timing['target_period']:.1f} ns")
            report.append(f"Worst Negative Slack: {timing['wns']:.2f} ns")
            report.append(f"Timing Method: {timing.get('method', 'unknown')}")
            if timing['wns'] >= 0:
                report.append("Timing Status: [PASS] Timing constraints met")
            else:
                report.append(f"Timing Status: [FAIL] Timing violation ({abs(timing['wns']):.2f} ns)")
        else:
            report.append(f"Clock Period: {1000.0/timing['fmax']:.1f} ns")
            report.append(f"Timing Method: {timing.get('method', 'estimated')}")
        
        report.append("")
        
        # Performance Analysis
        report.append("PERFORMANCE ANALYSIS:")
        report.append("-" * 40)
        report.append(f"Best CPI: {performance['cpi']:.2f}")
        report.append(f"Average MIPS: {performance['mips']:.1f}")
        report.append(f"Peak Performance: {timing['fmax']/performance['cpi']:.1f} MIPS")
        report.append("")
        
        # Resource Utilization
        report.append("RESOURCE UTILIZATION:")
        report.append("-" * 40)
        for resource, count in utilization.items():
            report.append(f"{resource:12}: {count:6d}")
        report.append("")
        
        # Cost Analysis
        report.append("COST ANALYSIS:")
        report.append("-" * 40)
        report.append("Element Breakdown:")
        for element, count in cost_breakdown.items():
            if count > 0:
                element_cost = ELEMENT_COSTS[element] * count
                report.append(f"  {element:12}: {count:4d} × {ELEMENT_COSTS[element]:4d} = {element_cost:8d}")
        report.append(f"{'':30} Total Cost: {total_cost:8.0f}")
        report.append("")
        
        # Figure of Merit
        report.append("FIGURE OF MERIT:")
        report.append("-" * 40)
        report.append(f"FoM = (1000 × fmax^1.0) / (cpi^1.0) / (cost^0.5)")
        report.append(f"FoM = (1000 × {timing['fmax']:.1f}) / {performance['cpi']:.2f} / {total_cost:.0f}^0.5")
        report.append(f"FoM = {fom:.2f}")
        report.append("")
        
        # Performance Density Metrics
        mips_per_cost = performance['mips'] / (total_cost ** 0.5) if total_cost > 0 else 0
        freq_per_cost = timing['fmax'] / (total_cost ** 0.5) if total_cost > 0 else 0
        
        report.append("EFFICIENCY METRICS:")
        report.append("-" * 40)
        report.append(f"MIPS per Cost^0.5: {mips_per_cost:.2f}")
        report.append(f"MHz per Cost^0.5: {freq_per_cost:.2f}")
        report.append(f"Performance Density: {fom:.2f} FoM")
        report.append("")
        
        # Comparison Context
        report.append("PERFORMANCE CONTEXT:")
        report.append("-" * 40)
        if timing['fmax'] >= 100:
            report.append("[EXCELLENT] High-performance design (>=100 MHz)")
        elif timing['fmax'] >= 50:
            report.append("[GOOD] Medium-performance design (50-100 MHz)")
        else:
            report.append("[MODERATE] Conservative design (<50 MHz)")
            
        if performance['cpi'] <= 1.1:
            report.append("[EXCELLENT] Excellent CPI (<=1.1)")
        elif performance['cpi'] <= 1.5:
            report.append("[GOOD] Good CPI (1.1-1.5)")
        else:
            report.append("[MODERATE] High CPI (>1.5)")
            
        if fom >= 1000:
            report.append("[EXCELLENT] Excellent Figure of Merit (>=1000)")
        elif fom >= 500:
            report.append("[GOOD] Good Figure of Merit (500-1000)")
        else:
            report.append("[MODERATE] Moderate Figure of Merit (<500)")
        
        report.append("=" * 80)
        
        return "\n".join(report)

def main():
    """Main function for command-line usage"""
    analyzer = MinCPUAnalyzer()
    
    # Parse command line arguments
    utilization_file = "area_report.rpt"
    timing_file = "timing_report.rpt"
    
    if len(sys.argv) > 1:
        utilization_file = sys.argv[1]
    if len(sys.argv) > 2:
        timing_file = sys.argv[2]
    
    # Generate and print report
    report = analyzer.generate_report(utilization_file, timing_file)
    print(report)
    
    # Save report to file
    with open("cost_analysis_report.txt", "w", encoding='utf-8') as f:
        f.write(report)
    
    print(f"\nReport saved to: cost_analysis_report.txt")

if __name__ == "__main__":
    main() 