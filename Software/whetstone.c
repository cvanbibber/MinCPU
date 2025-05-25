/*
 * Simplified Whetstone Benchmark for MinCPU
 * Based on the Whetstone Benchmark
 * Adapted for embedded RISC-V systems without FPU using fixed-point arithmetic
 */

// Fixed-point arithmetic configuration (Q16.16 format)
#define FIXED_SCALE 65536
#define FIXED_ONE (1 * FIXED_SCALE)
#define FIXED_HALF (FIXED_SCALE / 2)

// Convert integer to fixed-point
#define TO_FIXED(x) ((x) * FIXED_SCALE)
// Convert fixed-point to integer (truncate)
#define FROM_FIXED(x) ((x) / FIXED_SCALE)

// Fixed-point multiply
int fp_mul(int a, int b) {
    long long result = ((long long)a * (long long)b) >> 16;
    return (int)result;
}

// Fixed-point divide
int fp_div(int a, int b) {
    if (b == 0) return 0;
    long long result = ((long long)a << 16) / (long long)b;
    return (int)result;
}

// Fixed-point square root approximation (Newton's method)
int fp_sqrt(int x) {
    if (x <= 0) return 0;
    
    int guess = x >> 1;  // Initial guess
    for (int i = 0; i < 10; i++) {  // 10 iterations
        if (guess == 0) break;
        guess = (guess + fp_div(x, guess)) >> 1;
    }
    return guess;
}

// Fixed-point sine approximation (Taylor series)
int fp_sin(int x) {
    // sin(x) ≈ x - x³/6 + x⁵/120 - x⁷/5040
    // Scale down input to avoid overflow
    x = x >> 2;
    
    int x2 = fp_mul(x, x);
    int x3 = fp_mul(x2, x);
    int x5 = fp_mul(x3, x2);
    
    int result = x;
    result -= fp_div(x3, TO_FIXED(6));
    result += fp_div(x5, TO_FIXED(120));
    
    return result;
}

// Fixed-point cosine approximation
int fp_cos(int x) {
    // cos(x) ≈ 1 - x²/2 + x⁴/24 - x⁶/720
    x = x >> 2;
    
    int x2 = fp_mul(x, x);
    int x4 = fp_mul(x2, x2);
    int x6 = fp_mul(x4, x2);
    
    int result = FIXED_ONE;
    result -= fp_div(x2, TO_FIXED(2));
    result += fp_div(x4, TO_FIXED(24));
    result -= fp_div(x6, TO_FIXED(720));
    
    return result;
}

// Fixed-point exponential approximation
int fp_exp(int x) {
    // exp(x) ≈ 1 + x + x²/2 + x³/6 + x⁴/24
    x = x >> 2;
    
    int x2 = fp_mul(x, x);
    int x3 = fp_mul(x2, x);
    int x4 = fp_mul(x3, x);
    
    int result = FIXED_ONE;
    result += x;
    result += fp_div(x2, TO_FIXED(2));
    result += fp_div(x3, TO_FIXED(6));
    result += fp_div(x4, TO_FIXED(24));
    
    return result;
}

// Fixed-point logarithm approximation
int fp_log(int x) {
    if (x <= 0) return 0;
    
    // For x near 1: log(x) ≈ (x-1) - (x-1)²/2 + (x-1)³/3
    int x_minus_1 = x - FIXED_ONE;
    x_minus_1 = x_minus_1>> 1;  // Scale to avoid overflow
    
    int x2 = fp_mul(x_minus_1, x_minus_1);
    int x3 = fp_mul(x2, x_minus_1);
    
    int result = x_minus_1;
    result -= fp_div(x2, TO_FIXED(2));
    result += fp_div(x3, TO_FIXED(3));
    
    return result;
}

// Global variables for Whetstone
int E1[4];
int T, T1, T2;
int J, K, L;

// Module 1: Simple identifiers
void MODULE1(void) {
    E1[0] = 1;
    E1[1] = -1;
    E1[2] = -1;
    E1[3] = -1;
    
    for (int i = 0; i < 100; i++) {
        E1[0] = (E1[0] + E1[1] + E1[2] - E1[3]) * T;
        E1[1] = (E1[0] + E1[1] - E1[2] + E1[3]) * T;
        E1[2] = (E1[0] - E1[1] + E1[2] + E1[3]) * T;
        E1[3] = (-E1[0] + E1[1] + E1[2] + E1[3]) * T;
    }
}

// Module 2: Array elements
void MODULE2(void) {
    static int E2[101];
    
    E2[0] = 1;
    E2[1] = -1;
    E2[2] = -1;
    E2[3] = -1;
    
    for (int i = 0; i < 50; i++) {
        for (int j = 0; j < 25; j++) {
            E2[j] = E2[j] + E2[j+1] + E2[j+2] + E2[j+3];
        }
    }
}

// Module 3: Array as parameter
void MODULE3(int E3[]) {
    for (int i = 0; i < 50; i++) {
        for (int j = 0; j < 25; j++) {
            E3[j] = (E3[j] + E3[j+1] + E3[j+2] + E3[j+3]) / 4;
        }
    }
}

// Module 4: Conditional jumps
void MODULE4(void) {
    J = 1;
    
    for (int i = 0; i < 50; i++) {
        if (J == 1) {
            J = 2;
        } else {
            J = 3;
        }
        
        if (J > 2) {
            J = 0;
        } else {
            J = 1;
        }
        
        if (J < 1) {
            J = 1;
        } else {
            J = 0;
        }
    }
}

// Module 5: Omitted (integer arithmetic)

// Module 6: Integer arithmetic
void MODULE6(void) {
    J = 1;
    K = 2;
    L = 3;
    
    for (int i = 0; i < 100; i++) {
        J = J * (K - J) * (L - K);
        K = L * K - (L - J) * K;
        L = (L - K) * (K + J);
        
        E1[L - 2] = J + K + L;
        E1[K - 2] = J * K * L;
    }
}

// Module 7: Trigonometric functions (using fixed-point)
void MODULE7(void) {
    int X = TO_FIXED(1);  // 1.0 in fixed-point
    int Y = TO_FIXED(1);  // 1.0 in fixed-point
    
    for (int i = 0; i < 25; i++) {
        X = T * fp_sin(Y) + T * fp_cos(X);
        Y = T * fp_cos(X) + T * fp_sin(Y);
    }
}

// Module 8: Procedure calls
int P8(int X) {
    return TO_FIXED(1) + X;
}

void MODULE8(void) {
    int X = TO_FIXED(1);
    
    for (int i = 0; i < 100; i++) {
        X = P8(X);
    }
}

// Module 9: Array references
void MODULE9(void) {
    static int E9[101];
    
    for (int i = 0; i < 101; i++) {
        E9[i] = TO_FIXED(1);
    }
    
    for (int i = 0; i < 25; i++) {
        for (int j = 0; j < 25; j++) {
            E9[j] = E9[j+1] + E9[j+2] + E9[j+3];
        }
    }
}

// Module 10: Integer arithmetic
void MODULE10(void) {
    J = 2;
    K = 3;
    
    for (int i = 0; i < 100; i++) {
        J = J + K;
        K = J + K;
        J = K - J;
        K = K - J - J;
    }
}

// Module 11: Standard functions (using fixed-point approximations)
void MODULE11(void) {
    int X = TO_FIXED(1);
    
    for (int i = 0; i < 25; i++) {
        X = fp_sqrt(fp_exp(fp_log(X)));
    }
}

// Number of benchmark loops
#define LOOPS 100

int main() {
    int loop_count;
    
    // Initialize T values for fixed-point arithmetic
    T = FIXED_ONE;
    T1 = TO_FIXED(5) / 10;  // 0.5
    T2 = T + T1;            // 1.5
    
    // Main benchmark loop
    for (loop_count = 0; loop_count < LOOPS; loop_count++) {
        
        // Execute all modules
        MODULE1();
        
        static int E3[101];
        for (int i = 0; i < 101; i++) E3[i] = TO_FIXED(1);
        MODULE3(E3);
        
        MODULE4();
        MODULE6();
        MODULE7();
        MODULE8();
        MODULE9();
        MODULE10();
        MODULE11();
        
        // Additional computation to simulate more complex operations
        for (int i = 0; i < 10; i++) {
            int temp1 = fp_mul(T1, T2);
            int temp2 = fp_div(temp1, T);
            int temp3 = fp_sin(temp2);
            int temp4 = fp_cos(temp3);
            int temp5 = fp_sqrt(temp4 > 0 ? temp4 : -temp4);
            T = fp_exp(fp_log(temp5 > 0 ? temp5 : FIXED_ONE));
        }
    }
    
    // Return the number of loops completed
    return LOOPS;
} 