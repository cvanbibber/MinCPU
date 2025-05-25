#!/usr/bin/env python3
"""
UART Loader for MinCPU
Uploads compiled C programs to the MinCPU via UART bootloader interface
"""

import sys
import os
import time
import serial
import struct
import argparse

class MinCPUUARTLoader:
    def __init__(self, port, baud_rate=115200, timeout=5):
        """
        Initialize UART loader
        
        Args:
            port: Serial port (e.g., 'COM3' on Windows, '/dev/ttyUSB0' on Linux)
            baud_rate: UART baud rate (default: 115200)
            timeout: Communication timeout in seconds
        """
        self.port = port
        self.baud_rate = baud_rate
        self.timeout = timeout
        self.serial_port = None
        
        # Protocol constants
        self.MAGIC_WORD = 0xDEADBEEF
        self.SUCCESS_CODE = 0xAA
        self.ERROR_CODE = 0xFF
        self.DEFAULT_LOAD_ADDR = 0x1000  # Default instruction memory base
        
    def connect(self):
        """Connect to the serial port"""
        try:
            self.serial_port = serial.Serial(
                port=self.port,
                baudrate=self.baud_rate,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                timeout=self.timeout
            )
            print(f"Connected to {self.port} at {self.baud_rate} baud")
            return True
        except serial.SerialException as e:
            print(f"Error connecting to {self.port}: {e}")
            return False
    
    def disconnect(self):
        """Disconnect from the serial port"""
        if self.serial_port and self.serial_port.is_open:
            self.serial_port.close()
            print("Disconnected from serial port")
    
    def send_bytes(self, data):
        """Send bytes to the serial port"""
        if not self.serial_port or not self.serial_port.is_open:
            raise Exception("Serial port not connected")
        
        self.serial_port.write(data)
        self.serial_port.flush()
    
    def receive_byte(self):
        """Receive a single byte from the serial port"""
        if not self.serial_port or not self.serial_port.is_open:
            raise Exception("Serial port not connected")
        
        data = self.serial_port.read(1)
        if len(data) == 0:
            raise Exception("Timeout waiting for response")
        
        return data[0]
    
    def send_magic_word(self):
        """Send the magic word to initiate bootloader"""
        print("Sending magic word...")
        magic_bytes = struct.pack('<I', self.MAGIC_WORD)  # Little-endian
        self.send_bytes(magic_bytes)
        time.sleep(0.1)  # Allow bootloader to process
    
    def send_program_size(self, size):
        """Send the program size"""
        print(f"Sending program size: {size} bytes")
        size_bytes = struct.pack('<I', size)  # Little-endian
        self.send_bytes(size_bytes)
        time.sleep(0.1)
    
    def send_load_address(self, address):
        """Send the load address"""
        print(f"Sending load address: 0x{address:08x}")
        addr_bytes = struct.pack('<I', address)  # Little-endian
        self.send_bytes(addr_bytes)
        time.sleep(0.1)
    
    def send_program_data(self, data):
        """Send the program data"""
        print(f"Sending program data ({len(data)} bytes)...")
        
        # Send data in chunks to avoid overwhelming the bootloader
        chunk_size = 64
        for i in range(0, len(data), chunk_size):
            chunk = data[i:i+chunk_size]
            self.send_bytes(chunk)
            
            # Progress indication
            progress = (i + len(chunk)) / len(data) * 100
            print(f"\rProgress: {progress:.1f}%", end='', flush=True)
            
            # Small delay between chunks
            time.sleep(0.01)
        
        print()  # New line after progress
    
    def wait_for_response(self):
        """Wait for bootloader response"""
        print("Waiting for bootloader response...")
        try:
            response = self.receive_byte()
            if response == self.SUCCESS_CODE:
                print("✓ Upload successful!")
                return True
            elif response == self.ERROR_CODE:
                print("✗ Upload failed!")
                return False
            else:
                print(f"✗ Unexpected response: 0x{response:02x}")
                return False
        except Exception as e:
            print(f"✗ Error waiting for response: {e}")
            return False
    
    def load_binary_file(self, filename):
        """Load binary file into memory"""
        if not os.path.exists(filename):
            raise FileNotFoundError(f"Binary file '{filename}' not found")
        
        with open(filename, 'rb') as f:
            data = f.read()
        
        print(f"Loaded binary file: {filename}")
        print(f"  Size: {len(data)} bytes")
        return data
    
    def upload_program(self, binary_file, load_address=None):
        """
        Upload a program to MinCPU via UART bootloader
        
        Args:
            binary_file: Path to the binary file
            load_address: Memory address to load the program (default: 0x1000)
        
        Returns:
            True if successful, False otherwise
        """
        if load_address is None:
            load_address = self.DEFAULT_LOAD_ADDR
        
        try:
            # Load the binary file
            program_data = self.load_binary_file(binary_file)
            
            # Pad to word boundary
            while len(program_data) % 4 != 0:
                program_data += b'\x00'
            
            print(f"\nStarting upload to MinCPU...")
            print(f"  File: {binary_file}")
            print(f"  Size: {len(program_data)} bytes")
            print(f"  Load address: 0x{load_address:08x}")
            print()
            
            # Send bootloader protocol sequence
            self.send_magic_word()
            self.send_program_size(len(program_data))
            self.send_load_address(load_address)
            self.send_program_data(program_data)
            
            # Wait for response
            success = self.wait_for_response()
            
            if success:
                print(f"\n🎉 Program uploaded successfully!")
                print(f"   MinCPU should now be running your program.")
            else:
                print(f"\n❌ Upload failed. Check connections and try again.")
            
            return success
            
        except Exception as e:
            print(f"\n❌ Upload error: {e}")
            return False
    
    def test_connection(self):
        """Test the UART connection"""
        print("Testing UART connection...")
        try:
            # Try to send some data and see if we get echo or response
            test_data = b'AT\r\n'
            self.send_bytes(test_data)
            time.sleep(0.5)
            
            # Check if there's any response
            self.serial_port.timeout = 1
            response = self.serial_port.read(100)
            self.serial_port.timeout = self.timeout
            
            if len(response) > 0:
                print(f"✓ Received response: {response}")
                return True
            else:
                print("⚠ No response received (bootloader may be waiting)")
                return True  # Still consider it connected
                
        except Exception as e:
            print(f"✗ Connection test failed: {e}")
            return False

def main():
    parser = argparse.ArgumentParser(description='MinCPU UART Loader')
    parser.add_argument('binary_file', help='Binary file to upload (.bin)')
    parser.add_argument('-p', '--port', required=True, help='Serial port (e.g., COM3, /dev/ttyUSB0)')
    parser.add_argument('-b', '--baud', type=int, default=115200, help='Baud rate (default: 115200)')
    parser.add_argument('-a', '--address', type=lambda x: int(x, 0), default=0x1000, 
                        help='Load address (default: 0x1000)')
    parser.add_argument('-t', '--test', action='store_true', help='Test connection only')
    parser.add_argument('--timeout', type=float, default=5, help='Communication timeout (seconds)')
    
    args = parser.parse_args()
    
    # Create loader instance
    loader = MinCPUUARTLoader(args.port, args.baud, args.timeout)
    
    try:
        # Connect to serial port
        if not loader.connect():
            sys.exit(1)
        
        if args.test:
            # Test connection only
            if loader.test_connection():
                print("✓ Connection test passed")
            else:
                print("✗ Connection test failed")
                sys.exit(1)
        else:
            # Upload the program
            if not loader.upload_program(args.binary_file, args.address):
                sys.exit(1)
        
    except KeyboardInterrupt:
        print("\n\n⚠ Upload interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        sys.exit(1)
    finally:
        loader.disconnect()

if __name__ == "__main__":
    main() 