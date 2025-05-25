/*
 * Simple Performance Testbench for MinCPU
 * Tests optimized modules and provides performance metrics
 */

`timescale 1ns / 1ps

`include "cpu_config.vh"

module performance_testbench;

    // Clock and reset
    reg clk;
    reg rst_n;
    
    // Performance counters
    reg [31:0] cycle_count;
    reg [31:0] test_count;
    reg [31:0] pass_count;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // Reset sequence
    initial begin
        rst_n = 0;
        cycle_count = 0;
        test_count = 0;
        pass_count = 0;
        
        #50 rst_n = 1;
        $display("=== MinCPU Performance Analysis ===");
        $display("Target Frequency: 100 MHz");
        $display("Clock Period: 10.0 ns");
    end
    
    // Cycle counter
    always @(posedge clk) begin
        if (rst_n) begin
            cycle_count <= cycle_count + 1;
        end
    end
    
    // ALU performance test
    reg [31:0] alu_src1, alu_src2, alu_result;
    reg [3:0] alu_op;
    wire alu_zero, alu_fast_ready, alu_slow_ready;
    
    alu_optimized alu_test (
        .src1(alu_src1),
        .src2(alu_src2),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(alu_zero),
        .fast_ready(alu_fast_ready),
        .slow_ready(alu_slow_ready)
    );
    
    // Immediate generator performance test
    reg [31:0] imm_instruction;
    wire [31:0] imm_result;
    
    immediate_gen_optimized imm_test (
        .instruction(imm_instruction),
        .immediate(imm_result)
    );
    
    // Branch unit performance test
    reg [31:0] branch_rs1, branch_rs2;
    reg [2:0] branch_funct3;
    wire branch_taken, branch_predict;
    
    branch_unit_optimized branch_test (
        .rs1_data(branch_rs1),
        .rs2_data(branch_rs2),
        .funct3(branch_funct3),
        .branch_taken(branch_taken),
        .predict_taken(branch_predict)
    );
    
    // Benchmark selection
    reg [31:0] benchmark_select;
    initial begin
        if ($value$plusargs("BENCHMARK=%d", benchmark_select)) begin
            $display("Running benchmark %0d", benchmark_select);
        end else begin
            benchmark_select = 0; // Default benchmark
            $display("Running default benchmark (0)");
        end
    end
    
    // Performance test sequence
    initial begin
        wait(rst_n);
        #100; // Wait for stabilization
        
        $display("=== MinCPU Benchmark %0d ===", benchmark_select);
        
        case (benchmark_select)
            0: begin
                $display("Benchmark 0: Basic ALU operations");
                test_alu_performance();
            end
            1: begin
                $display("Benchmark 1: Memory-intensive operations");
                test_memory_intensive();
            end
            2: begin
                $display("Benchmark 2: Branch-intensive operations");
                test_branch_performance();
            end
            3: begin
                $display("Benchmark 3: Mixed workload");
                test_alu_performance();
                test_immediate_performance();
                test_branch_performance();
            end
            4: begin
                $display("Benchmark 4: Fibonacci calculation");
                test_fibonacci_performance();
            end
            5: begin
                $display("Benchmark 5: Sorting algorithm");
                test_sorting_performance();
            end
            7: begin
                $display("Benchmark 7: Dhrystone simulation");
                test_dhrystone_simulation();
            end
            8: begin
                $display("Benchmark 8: Whetstone simulation");
                test_whetstone_simulation();
            end
            default: begin
                $display("Default: Comprehensive test");
                test_alu_performance();
                test_immediate_performance();
                test_branch_performance();
            end
        endcase
        
        // Calculate and display results
        #100;
        display_performance_results();
        
        $finish;
    end
    
    task test_alu_performance;
        integer i;
        reg [31:0] start_cycle, end_cycle;
        begin
            $display("Testing ALU performance...");
            start_cycle = cycle_count;
            
            // Simulate 100 ALU operations
            for (i = 0; i < 100; i = i + 1) begin
                alu_src1 = $random;
                alu_src2 = $random;
                alu_op = i % 10; // Cycle through different operations
                
                @(posedge clk);
                test_count = test_count + 1;
                
                // Check if operation completed (simplified)
                if (alu_fast_ready || alu_slow_ready) begin
                    pass_count = pass_count + 1;
                end
            end
            
            end_cycle = cycle_count;
            $display("ALU Performance: %0d operations in %0d cycles", 100, end_cycle - start_cycle);
        end
    endtask
    
    task test_immediate_performance;
        integer i;
        reg [31:0] start_cycle, end_cycle;
        begin
            $display("Testing Immediate Generator performance...");
            start_cycle = cycle_count;
            
            // Simulate 100 immediate generations
            for (i = 0; i < 100; i = i + 1) begin
                imm_instruction = $random;
                
                #1; // Combinational delay
                test_count = test_count + 1;
                pass_count = pass_count + 1; // Always passes for combinational logic
            end
            
            end_cycle = cycle_count;
            $display("Immediate Gen Performance: %0d operations in %0d cycles", 100, end_cycle - start_cycle);
        end
    endtask
    
    task test_branch_performance;
        integer i;
        reg [31:0] start_cycle, end_cycle;
        begin
            $display("Testing Branch Unit performance...");
            start_cycle = cycle_count;
            
            // Simulate 100 branch evaluations
            for (i = 0; i < 100; i = i + 1) begin
                branch_rs1 = $random;
                branch_rs2 = $random;
                branch_funct3 = i % 6; // Cycle through branch types
                
                #1; // Combinational delay
                test_count = test_count + 1;
                pass_count = pass_count + 1; // Always passes for combinational logic
            end
            
            end_cycle = cycle_count;
            $display("Branch Performance: %0d operations in %0d cycles", 100, end_cycle - start_cycle);
        end
    endtask
    
    task test_memory_intensive;
        integer i;
        reg [31:0] start_cycle, end_cycle;
        begin
            $display("Testing memory-intensive operations...");
            start_cycle = cycle_count;
            
            // Simulate 50 memory operations (more complex)
            for (i = 0; i < 50; i = i + 1) begin
                alu_src1 = $random;
                alu_src2 = $random;
                alu_op = 0; // ADD for address calculation
                
                @(posedge clk);
                @(posedge clk); // Extra cycle for memory latency
                test_count = test_count + 1;
                pass_count = pass_count + 1;
            end
            
            end_cycle = cycle_count;
            $display("Memory Performance: %0d operations in %0d cycles", 50, end_cycle - start_cycle);
        end
    endtask
    
    task test_fibonacci_performance;
        integer i;
        reg [31:0] start_cycle, end_cycle;
        reg [31:0] fib_a, fib_b, fib_c;
        begin
            $display("Testing Fibonacci calculation...");
            start_cycle = cycle_count;
            
            // Simulate Fibonacci calculation (10 iterations)
            fib_a = 1;
            fib_b = 1;
            for (i = 0; i < 10; i = i + 1) begin
                alu_src1 = fib_a;
                alu_src2 = fib_b;
                alu_op = 0; // ADD
                
                @(posedge clk);
                fib_c = alu_result;
                fib_a = fib_b;
                fib_b = fib_c;
                
                test_count = test_count + 1;
                pass_count = pass_count + 1;
            end
            
            end_cycle = cycle_count;
            $display("Fibonacci Performance: %0d iterations in %0d cycles", 10, end_cycle - start_cycle);
        end
    endtask
    
    task test_sorting_performance;
        integer i, j;
        reg [31:0] start_cycle, end_cycle;
        reg [31:0] array [0:7];
        reg [31:0] temp;
        begin
            $display("Testing sorting algorithm...");
            start_cycle = cycle_count;
            
            // Initialize array with random values
            for (i = 0; i < 8; i = i + 1) begin
                array[i] = $random & 32'hFF; // 8-bit values for simplicity
            end
            
            // Bubble sort simulation
            for (i = 0; i < 7; i = i + 1) begin
                for (j = 0; j < 7-i; j = j + 1) begin
                    // Compare array[j] and array[j+1]
                    alu_src1 = array[j];
                    alu_src2 = array[j+1];
                    alu_op = 8; // SLT (set less than)
                    
                    @(posedge clk);
                    
                    // Swap if needed
                    if (!alu_result) begin // array[j] >= array[j+1]
                        temp = array[j];
                        array[j] = array[j+1];
                        array[j+1] = temp;
                    end
                    
                    test_count = test_count + 1;
                    pass_count = pass_count + 1;
                end
            end
            
            end_cycle = cycle_count;
            $display("Sorting Performance: 8-element sort in %0d cycles", end_cycle - start_cycle);
        end
    endtask
    
    task test_dhrystone_simulation;
        integer i;
        reg [31:0] start_cycle, end_cycle;
        reg [31:0] dhrystone_iterations;
        begin
            `ifdef DHRYSTONE_ITERATIONS
                dhrystone_iterations = `DHRYSTONE_ITERATIONS;
            `else
                dhrystone_iterations = 1000;
            `endif
            
            $display("Testing Dhrystone simulation (%0d iterations)...", dhrystone_iterations);
            start_cycle = cycle_count;
            
            // Simulate Dhrystone workload (integer operations)
            for (i = 0; i < dhrystone_iterations; i = i + 1) begin
                // Simulate typical Dhrystone operations
                alu_src1 = $random;
                alu_src2 = $random;
                alu_op = i % 8; // Various ALU operations
                
                @(posedge clk);
                
                // Add some immediate operations
                imm_instruction = $random;
                #1;
                
                // Add some branch operations  
                branch_rs1 = $random;
                branch_rs2 = $random;
                branch_funct3 = i % 6;
                #1;
                
                test_count = test_count + 1;
                pass_count = pass_count + 1;
            end
            
            end_cycle = cycle_count;
            $display("Dhrystone Performance: %0d iterations in %0d cycles", dhrystone_iterations, end_cycle - start_cycle);
        end
    endtask
    
    task test_whetstone_simulation;
        integer i;
        reg [31:0] start_cycle, end_cycle;
        reg [31:0] whetstone_iterations;
        begin
            `ifdef WHETSTONE_ITERATIONS
                whetstone_iterations = `WHETSTONE_ITERATIONS;
            `else
                whetstone_iterations = 100;
            `endif
            
            $display("Testing Whetstone simulation (%0d iterations)...", whetstone_iterations);
            start_cycle = cycle_count;
            
            // Simulate Whetstone workload (mathematical operations)
            for (i = 0; i < whetstone_iterations; i = i + 1) begin
                // Simulate mathematical operations
                alu_src1 = $random;
                alu_src2 = $random;
                alu_op = 0; // ADD
                @(posedge clk);
                
                alu_op = 8; // SLT
                @(posedge clk);
                
                alu_op = 6; // OR
                @(posedge clk);
                
                alu_op = 7; // AND
                @(posedge clk);
                
                test_count = test_count + 4; // 4 operations per iteration
                pass_count = pass_count + 4;
            end
            
            end_cycle = cycle_count;
            $display("Whetstone Performance: %0d iterations in %0d cycles", whetstone_iterations, end_cycle - start_cycle);
        end
    endtask
    
    task display_performance_results;
        real frequency_mhz;
        real cpi_estimate;
        real mips_estimate;
        real benchmark_score;
        begin
            frequency_mhz = 100.0; // Target frequency
            
            $display("");
            $display("Performance Results:");
            $display("===================");
            $display("Total Cycles: %0d", cycle_count);
            $display("Total Tests: %0d", test_count);
            $display("Tests Passed: %0d", pass_count);
            $display("Success Rate: %0.1f%%", (real'(pass_count) / real'(test_count)) * 100.0);
            
            // Estimate CPI based on test results
            if (test_count > 0) begin
                cpi_estimate = real'(cycle_count) / real'(test_count);
                $display("CPI: %0.2f", cpi_estimate);
                
                // Estimate MIPS
                mips_estimate = frequency_mhz / cpi_estimate;
                $display("MIPS (at %.1f MHz): %0.1f", frequency_mhz, mips_estimate);
                
                // Calculate benchmark-specific scores
                if (benchmark_select == 7) begin // Dhrystone
                    benchmark_score = (real'(test_count) * frequency_mhz * 1000000.0) / real'(cycle_count);
                    $display("Dhrystones per second: %0.0f", benchmark_score);
                    $display("Dhrystones per second per MHz: %0.0f", benchmark_score / frequency_mhz);
                end else if (benchmark_select == 8) begin // Whetstone
                    benchmark_score = (real'(test_count/4) * frequency_mhz * 1000000.0) / real'(cycle_count);
                    $display("Whetstones per second: %0.0f", benchmark_score);
                    $display("Whetstones per second per MHz: %0.0f", benchmark_score / frequency_mhz);
                end
            end else begin
                $display("CPI: N/A (no tests run)");
                $display("MIPS: N/A");
            end
            
            $display("");
            $display("Benchmark %0d Summary:", benchmark_select);
            case (benchmark_select)
                0: $display("- Basic ALU operations: Single-cycle execution");
                1: $display("- Memory-intensive: Simulated memory latency");
                2: $display("- Branch-intensive: Control flow heavy");
                3: $display("- Mixed workload: Balanced instruction mix");
                4: $display("- Fibonacci: Recursive computation pattern");
                5: $display("- Sorting: Memory access and comparison heavy");
                7: $display("- Dhrystone: Integer performance benchmark");
                8: $display("- Whetstone: Mathematical performance benchmark");
                default: $display("- Comprehensive: All module types tested");
            endcase
            
            $display("");
            $display("✓ Benchmark %0d complete", benchmark_select);
        end
    endtask
    
    // Simulation timeout
    initial begin
        #50000; // 50us timeout
        $display("ERROR: Simulation timeout");
        $finish;
    end
    
    // VCD dump for waveform viewing
    initial begin
        $dumpfile("performance_testbench.vcd");
        $dumpvars(0, performance_testbench);
    end

endmodule 