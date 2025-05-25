/*
 * Simple Hello World program for MinCPU RISC-V processor
 * Demonstrates basic arithmetic and memory operations
 */

// Simple memory-mapped I/O addresses for MinCPU
#define UART_BASE   0x10000000
#define UART_DATA   (*(volatile unsigned int*)(UART_BASE + 0))
#define UART_STATUS (*(volatile unsigned int*)(UART_BASE + 4))

// Simple functions for basic operations
void print_char(char c) {
    // Wait for UART ready (bit 0 of status register)
    while (!(UART_STATUS & 1));
    UART_DATA = c;
}

void print_string(const char* str) {
    while (*str) {
        print_char(*str++);
    }
}

void print_hex(unsigned int value) {
    const char hex_chars[] = "0123456789ABCDEF";
    print_string("0x");
    for (int i = 7; i >= 0; i--) {
        print_char(hex_chars[(value >> (i * 4)) & 0xF]);
    }
}

// Simple arithmetic test function
unsigned int fibonacci(int n) {
    if (n <= 1) return n;
    
    unsigned int a = 0, b = 1, c;
    for (int i = 2; i <= n; i++) {
        c = a + b;
        a = b;
        b = c;
    }
    return b;
}

// Main function
int main() {
    // Initialize variables
    unsigned int test_value = 42;
    unsigned int fib_result;
    
    // Print hello message
    print_string("Hello from MinCPU!\n");
    print_string("RISC-V RV32IMC Processor\n");
    
    // Test arithmetic operations
    print_string("Test value: ");
    print_hex(test_value);
    print_string("\n");
    
    // Test multiplication (RV32M extension)
    unsigned int mult_result = test_value * 3;
    print_string("42 * 3 = ");
    print_hex(mult_result);
    print_string("\n");
    
    // Test division (RV32M extension)
    unsigned int div_result = mult_result / 7;
    print_string("126 / 7 = ");
    print_hex(div_result);
    print_string("\n");
    
    // Test Fibonacci calculation
    print_string("Fibonacci(10) = ");
    fib_result = fibonacci(10);
    print_hex(fib_result);
    print_string("\n");
    
    // Test memory operations
    volatile unsigned int memory_test[4] = {0xDEADBEEF, 0xCAFEBABE, 0x12345678, 0x87654321};
    print_string("Memory test:\n");
    for (int i = 0; i < 4; i++) {
        print_string("  [");
        print_hex(i);
        print_string("] = ");
        print_hex(memory_test[i]);
        print_string("\n");
    }
    
    // Infinite loop to keep program running
    print_string("Program complete. Looping...\n");
    while (1) {
        // Simple delay loop
        for (volatile int i = 0; i < 100000; i++);
        print_char('.');
    }
    
    return 0;
} 