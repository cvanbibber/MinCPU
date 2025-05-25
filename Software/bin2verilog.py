#!/usr/bin/env python3
"""
Binary to Verilog Memory Converter for MinCPU
Converts compiled binary files to Verilog memory initialization format
"""

import sys
import os
import struct

def bin_to_verilog(bin_file, imem_file, dmem_file):
    """
    Convert binary file to Verilog memory initialization files
    
    Args:
        bin_file: Input binary file path
        imem_file: Output instruction memory Verilog file
        dmem_file: Output data memory Verilog file
    """
    
    if not os.path.exists(bin_file):
        print(f"Error: Binary file '{bin_file}' not found")
        return False
    
    # Read binary file
    with open(bin_file, 'rb') as f:
        binary_data = f.read()
    
    # Pad to word boundary
    while len(binary_data) % 4 != 0:
        binary_data += b'\x00'
    
    # Convert to 32-bit words
    words = []
    for i in range(0, len(binary_data), 4):
        word = struct.unpack('<I', binary_data[i:i+4])[0]  # Little-endian
        words.append(word)
    
    # Generate instruction memory file
    with open(imem_file, 'w') as f:
        f.write("// Instruction Memory Initialization for MinCPU\n")
        f.write("// Generated from: {}\n".format(bin_file))
        f.write("// Total words: {}\n\n".format(len(words)))
        
        f.write("initial begin\n")
        f.write("    // Initialize all memory to NOPs\n")
        f.write("    for (i = 0; i < MEM_SIZE; i = i + 1) begin\n")
        f.write("        memory[i] = 32'h00000013; // ADDI x0, x0, 0 (NOP)\n")
        f.write("    end\n\n")
        
        f.write("    // Load program starting at address 0x1000 (word address 1024)\n")
        base_addr = 1024  # 0x1000 / 4
        
        for i, word in enumerate(words):
            addr = base_addr + i
            f.write("    memory[{}] = 32'h{:08x};\n".format(addr, word))
        
        f.write("\n    $display(\"Loaded {} instructions starting at address 0x1000\");\n".format(len(words)))
        f.write("end\n")
    
    # Generate data memory file (empty for now)
    with open(dmem_file, 'w') as f:
        f.write("// Data Memory Initialization for MinCPU\n")
        f.write("// Generated from: {}\n\n".format(bin_file))
        
        f.write("initial begin\n")
        f.write("    // Initialize data memory to zero\n")
        f.write("    for (i = 0; i < MEM_SIZE; i = i + 1) begin\n")
        f.write("        memory[i] = 32'h00000000;\n")
        f.write("    end\n")
        f.write("end\n")
    
    print(f"Generated Verilog memory files:")
    print(f"  Instruction memory: {imem_file} ({len(words)} words)")
    print(f"  Data memory: {dmem_file}")
    
    return True

def analyze_binary(bin_file):
    """
    Analyze binary file and print statistics
    """
    if not os.path.exists(bin_file):
        print(f"Error: Binary file '{bin_file}' not found")
        return
    
    file_size = os.path.getsize(bin_file)
    word_count = (file_size + 3) // 4  # Round up to word boundary
    
    print(f"\nBinary Analysis:")
    print(f"  File: {bin_file}")
    print(f"  Size: {file_size} bytes")
    print(f"  Words: {word_count}")
    print(f"  Memory usage: {word_count * 4} bytes")

def main():
    if len(sys.argv) != 4:
        print("Usage: python3 bin2verilog.py <binary_file> <imem_output> <dmem_output>")
        print("")
        print("Example:")
        print("  python3 bin2verilog.py hello.bin hello_imem.v hello_dmem.v")
        sys.exit(1)
    
    bin_file = sys.argv[1]
    imem_file = sys.argv[2]
    dmem_file = sys.argv[3]
    
    print("MinCPU Binary to Verilog Converter")
    print("=" * 40)
    
    # Analyze input file
    analyze_binary(bin_file)
    
    # Convert to Verilog
    if bin_to_verilog(bin_file, imem_file, dmem_file):
        print("\nConversion completed successfully!")
    else:
        print("\nConversion failed!")
        sys.exit(1)

if __name__ == "__main__":
    main() 