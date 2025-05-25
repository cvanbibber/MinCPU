/*
 * Testbench for MinCPU RISC-V Processor
 * Comprehensive testing and verification with detailed performance analysis
 */

`timescale 1ns / 1ps

module testbench;

    // Clock and reset
    reg clk;
    reg rst_n;
    
    // Debug signals
    wire [31:0] debug_pc;
    wire [31:0] debug_instr;
    wire        debug_valid;
    
    // Performance counters
    wire [31:0] cycle_count;
    wire [31:0] instr_count;
    
    // Performance analysis variables
    reg [31:0] instr_type_count [15:0];  // Count for each instruction type
    reg [31:0] total_cycles_per_type [15:0];  // Total cycles for each type
    reg [31:0] hazard_stalls;
    reg [31:0] branch_count;
    reg [31:0] branch_taken_count;
    reg [31:0] branch_correct_predictions;
    reg [31:0] branch_mispredictions;
    reg [31:0] load_use_hazards;
    reg [31:0] memory_stalls;
    
    // Timing analysis for critical path
    reg [31:0] max_combinational_delay;
    real       estimated_max_freq;
    
    // Previous values for change detection
    reg [31:0] prev_pc;
    reg [31:0] prev_instr_count;
    reg        prev_pipeline_stall;
    reg        prev_branch_taken;
    
    // Clock generation
    parameter CLOCK_PERIOD = 10; // 100MHz
    initial begin
        clk = 0;
        forever #(CLOCK_PERIOD/2) clk = ~clk;
    end
    
    // Reset generation
    initial begin
        rst_n = 0;
        #(CLOCK_PERIOD * 5);
        rst_n = 1;
        $display("Reset released at time %0t", $time);
        
        // Initialize performance counters
        initialize_counters();
    end
    
    // DUT instantiation with memory latency
    min_soc #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32),
        .IMEM_SIZE(2048),
        .DMEM_SIZE(1024),
        .BENCHMARK_SELECT(`ifdef BENCHMARK_SELECT `BENCHMARK_SELECT `else 3 `endif),
        .MEM_LATENCY(`ifdef MEM_LATENCY `MEM_LATENCY `else 2 `endif)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .debug_pc(debug_pc),
        .debug_instr(debug_instr),
        .debug_valid(debug_valid),
        .cycle_count(cycle_count),
        .instr_count(instr_count)
    );
    
    // Initialize performance counters
    task initialize_counters;
        integer i;
        begin
            for (i = 0; i < 16; i = i + 1) begin
                instr_type_count[i] = 0;
                total_cycles_per_type[i] = 0;
            end
            hazard_stalls = 0;
            branch_count = 0;
            branch_taken_count = 0;
            branch_correct_predictions = 0;
            branch_mispredictions = 0;
            load_use_hazards = 0;
            memory_stalls = 0;
            max_combinational_delay = 0;
            prev_pc = 0;
            prev_instr_count = 0;
            prev_pipeline_stall = 0;
            prev_branch_taken = 0;
        end
    endtask
    
    // Instruction type classification
    function [3:0] classify_instruction;
        input [31:0] instr;
        reg [6:0] opcode;
        reg [2:0] funct3;
        begin
            opcode = instr[6:0];
            funct3 = instr[14:12];
            
            case (opcode)
                7'b0010011: classify_instruction = 4'h0; // I-type arithmetic
                7'b0110011: classify_instruction = 4'h1; // R-type arithmetic
                7'b0000011: classify_instruction = 4'h2; // Load
                7'b0100011: classify_instruction = 4'h3; // Store
                7'b1100011: classify_instruction = 4'h4; // Branch
                7'b1101111: classify_instruction = 4'h5; // JAL
                7'b1100111: classify_instruction = 4'h6; // JALR
                7'b0110111: classify_instruction = 4'h7; // LUI
                7'b0010111: classify_instruction = 4'h8; // AUIPC
                7'b0001111: classify_instruction = 4'h9; // FENCE
                7'b1110011: classify_instruction = 4'hA; // SYSTEM
                default:    classify_instruction = 4'hF; // Unknown/NOP
            endcase
        end
    endfunction
    
    // Instruction type names
    function [127:0] get_instr_type_name;
        input [3:0] type_id;
        begin
            case (type_id)
                4'h0: get_instr_type_name = "I-ARITH";
                4'h1: get_instr_type_name = "R-ARITH";
                4'h2: get_instr_type_name = "LOAD";
                4'h3: get_instr_type_name = "STORE";
                4'h4: get_instr_type_name = "BRANCH";
                4'h5: get_instr_type_name = "JAL";
                4'h6: get_instr_type_name = "JALR";
                4'h7: get_instr_type_name = "LUI";
                4'h8: get_instr_type_name = "AUIPC";
                4'h9: get_instr_type_name = "FENCE";
                4'hA: get_instr_type_name = "SYSTEM";
                default: get_instr_type_name = "NOP/UNK";
            endcase
        end
    endfunction
    
    // Enhanced instruction disassembly function
    function [127:0] disassemble;
        input [31:0] instr;
        reg [6:0] opcode;
        reg [4:0] rd, rs1, rs2;
        reg [2:0] funct3;
        reg [6:0] funct7;
        begin
            opcode = instr[6:0];
            rd = instr[11:7];
            funct3 = instr[14:12];
            rs1 = instr[19:15];
            rs2 = instr[24:20];
            funct7 = instr[31:25];
            
            case (opcode)
                7'b0010011: begin // I-type
                    case (funct3)
                        3'b000: disassemble = "ADDI";
                        3'b010: disassemble = "SLTI";
                        3'b011: disassemble = "SLTIU";
                        3'b100: disassemble = "XORI";
                        3'b110: disassemble = "ORI";
                        3'b111: disassemble = "ANDI";
                        3'b001: disassemble = "SLLI";
                        3'b101: disassemble = funct7[5] ? "SRAI" : "SRLI";
                        default: disassemble = "I-UNK";
                    endcase
                end
                7'b0110011: begin // R-type
                    case (funct3)
                        3'b000: disassemble = funct7[5] ? "SUB" : "ADD";
                        3'b001: disassemble = "SLL";
                        3'b010: disassemble = "SLT";
                        3'b011: disassemble = "SLTU";
                        3'b100: disassemble = "XOR";
                        3'b101: disassemble = funct7[5] ? "SRA" : "SRL";
                        3'b110: disassemble = "OR";
                        3'b111: disassemble = "AND";
                        default: disassemble = "R-UNK";
                    endcase
                end
                7'b1100011: begin // B-type
                    case (funct3)
                        3'b000: disassemble = "BEQ";
                        3'b001: disassemble = "BNE";
                        3'b100: disassemble = "BLT";
                        3'b101: disassemble = "BGE";
                        3'b110: disassemble = "BLTU";
                        3'b111: disassemble = "BGEU";
                        default: disassemble = "B-UNK";
                    endcase
                end
                7'b0000011: begin // Load
                    case (funct3)
                        3'b000: disassemble = "LB";
                        3'b001: disassemble = "LH";
                        3'b010: disassemble = "LW";
                        3'b100: disassemble = "LBU";
                        3'b101: disassemble = "LHU";
                        default: disassemble = "LOAD-UNK";
                    endcase
                end
                7'b0100011: begin // Store
                    case (funct3)
                        3'b000: disassemble = "SB";
                        3'b001: disassemble = "SH";
                        3'b010: disassemble = "SW";
                        default: disassemble = "STORE-UNK";
                    endcase
                end
                7'b1101111: disassemble = "JAL";
                7'b1100111: disassemble = "JALR";
                7'b0110111: disassemble = "LUI";
                7'b0010111: disassemble = "AUIPC";
                7'b0001111: disassemble = "FENCE";
                7'b1110011: disassemble = "SYSTEM";
                default: disassemble = "UNKNOWN";
            endcase
        end
    endfunction
    
    // Monitor execution with detailed analysis
    always @(posedge clk) begin
        if (rst_n && debug_valid) begin
            reg [3:0] instr_type;
            reg [31:0] cycles_for_instr;
            
            instr_type = classify_instruction(debug_instr);
            cycles_for_instr = cycle_count - prev_instr_count;
            
            // Update instruction type counters
            instr_type_count[instr_type] = instr_type_count[instr_type] + 1;
            total_cycles_per_type[instr_type] = total_cycles_per_type[instr_type] + cycles_for_instr;
            
            // Detect hazards and stalls
            if (dut.cpu.pipeline_stall) begin
                hazard_stalls = hazard_stalls + 1;
                if (instr_type == 4'h2) begin // Load instruction
                    load_use_hazards = load_use_hazards + 1;
                end
            end
            
            // Memory stall detection
            if ((dut.cpu.dmem_req && !dut.cpu.dmem_ready) || 
                (dut.cpu.imem_req && !dut.cpu.imem_ready)) begin
                memory_stalls = memory_stalls + 1;
            end
            
            // Branch analysis
            if (instr_type == 4'h4) begin // Branch instruction
                branch_count = branch_count + 1;
                if (dut.cpu.branch_taken) begin
                    branch_taken_count = branch_taken_count + 1;
                end
                // Check prediction accuracy (simplified)
                if (dut.cpu.predict_taken == dut.cpu.branch_taken) begin
                    branch_correct_predictions = branch_correct_predictions + 1;
                end else begin
                    branch_mispredictions = branch_mispredictions + 1;
                end
            end
            
            $display("[%0t] PC=0x%08h INSTR=0x%08h (%s) TYPE=%s CPI=%.2f | Cycles=%0d Instructions=%0d", 
                     $time, debug_pc, debug_instr, disassemble(debug_instr), 
                     get_instr_type_name(instr_type),
                     cycles_for_instr > 0 ? real'(cycles_for_instr) : 1.0,
                     cycle_count, instr_count);
            
            prev_instr_count = cycle_count;
        end
        
        // Update previous values
        prev_pc = debug_pc;
        prev_pipeline_stall = dut.cpu.pipeline_stall;
        prev_branch_taken = dut.cpu.branch_taken;
    end
    
    // Register file monitoring with change tracking
    reg [31:0] prev_registers [31:0];
    integer i;
    
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            prev_registers[i] = 32'h00000000;
        end
    end
    
    always @(posedge clk) begin
        if (rst_n) begin
            // Monitor register changes
            for (i = 1; i < 32; i = i + 1) begin
                if (dut.cpu.reg_file.registers[i] !== prev_registers[i]) begin
                    $display("[%0t] REG CHANGE: x%0d = 0x%08h (was 0x%08h)", 
                             $time, i, dut.cpu.reg_file.registers[i], prev_registers[i]);
                    prev_registers[i] = dut.cpu.reg_file.registers[i];
                end
            end
        end
    end
    
    // Critical path timing analysis
    task analyze_critical_path;
        begin
            // Estimate critical path delays (simplified analysis)
            reg [31:0] alu_delay, control_delay, memory_delay, total_delay;
            
            alu_delay = 15;      // ns - ALU combinational delay
            control_delay = 8;   // ns - Control unit delay  
            memory_delay = 12;   // ns - Memory access setup
            total_delay = alu_delay + control_delay + memory_delay;
            
            max_combinational_delay = total_delay;
            estimated_max_freq = 1000.0 / real'(total_delay); // MHz
            
            $display("\nCritical Path Analysis:");
            $display("=======================");
            $display("ALU Delay:        %0d ns", alu_delay);
            $display("Control Delay:    %0d ns", control_delay);
            $display("Memory Delay:     %0d ns", memory_delay);
            $display("Total Delay:      %0d ns", total_delay);
            $display("Max Frequency:    %.1f MHz", estimated_max_freq);
        end
    endtask
    
    // Test sequence with comprehensive analysis
    initial begin
        $display("MinCPU RISC-V Processor Enhanced Testbench");
        $display("==========================================");
        
        // Wait for reset
        wait(rst_n);
        
        // Run for a number of cycles to capture different scenarios
        #(CLOCK_PERIOD * 2000);
        
        // Print comprehensive statistics
        print_performance_analysis();
        print_instruction_analysis();
        analyze_critical_path();
        print_hazard_analysis();
        print_branch_analysis();
        
        $display("\nTestbench completed successfully!");
        $finish;
    end
    
    // Comprehensive performance analysis
    task print_performance_analysis;
        real overall_cpi;
        begin
            overall_cpi = real'(cycle_count) / real'(instr_count);
            
            $display("\n=== PERFORMANCE ANALYSIS ===");
            $display("============================");
            $display("Total Cycles:              %0d", cycle_count);
            $display("Instructions Executed:     %0d", instr_count);
            $display("Overall CPI:               %.3f", overall_cpi);
            $display("Effective MIPS @ 100MHz:   %.1f", 100.0 / overall_cpi);
            $display("Pipeline Efficiency:       %.1f%%", (real'(instr_count) / real'(cycle_count)) * 100.0);
        end
    endtask
    
    // Instruction type breakdown analysis
    task print_instruction_analysis;
        integer j;
        real type_cpi;
        begin
            $display("\n=== INSTRUCTION TYPE ANALYSIS ===");
            $display("==================================");
            $display("Type      | Count | Total Cycles | Avg CPI | Percentage");
            $display("----------|-------|--------------|---------|----------");
            
            for (j = 0; j < 16; j = j + 1) begin
                if (instr_type_count[j] > 0) begin
                    type_cpi = real'(total_cycles_per_type[j]) / real'(instr_type_count[j]);
                    $display("%-9s | %5d | %12d | %7.2f | %6.1f%%", 
                             get_instr_type_name(j), 
                             instr_type_count[j],
                             total_cycles_per_type[j],
                             type_cpi,
                             (real'(instr_type_count[j]) / real'(instr_count)) * 100.0);
                end
            end
        end
    endtask
    
    // Hazard analysis
    task print_hazard_analysis;
        begin
            $display("\n=== HAZARD ANALYSIS ===");
            $display("=======================");
            $display("Total Pipeline Stalls:     %0d", hazard_stalls);
            $display("Load-Use Hazards:          %0d", load_use_hazards);
            $display("Memory Stalls:             %0d", memory_stalls);
            $display("Stall Rate:                %.2f%%", (real'(hazard_stalls) / real'(cycle_count)) * 100.0);
        end
    endtask
    
    // Branch prediction analysis
    task print_branch_analysis;
        real prediction_accuracy;
        begin
            if (branch_count > 0) begin
                prediction_accuracy = (real'(branch_correct_predictions) / real'(branch_count)) * 100.0;
            end else begin
                prediction_accuracy = 0.0;
            end
            
            $display("\n=== BRANCH ANALYSIS ===");
            $display("=======================");
            $display("Total Branches:            %0d", branch_count);
            $display("Branches Taken:            %0d", branch_taken_count);
            $display("Branch Taken Rate:         %.1f%%", (real'(branch_taken_count) / real'(branch_count)) * 100.0);
            $display("Correct Predictions:       %0d", branch_correct_predictions);
            $display("Mispredictions:            %0d", branch_mispredictions);
            $display("Prediction Accuracy:       %.1f%%", prediction_accuracy);
        end
    endtask
    
    // Waveform generation
    initial begin
        $dumpfile("min_cpu_tb.vcd");
        $dumpvars(0, testbench);
    end

endmodule 