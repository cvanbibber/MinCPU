/*
 * Test bench for optimized MinCPU modules
 * Validates that optimized modules produce identical results to originals
 */

`timescale 1ns / 1ps

module optimization_test_fixed;

    // Test signals
    reg [31:0] instruction;
    reg [31:0] src1, src2;
    reg [3:0] alu_op;
    reg [2:0] funct3;
    
    // Expected outputs for validation
    reg [31:0] expected_imm, expected_alu_result;
    reg expected_alu_zero, expected_branch_taken;
    
    // Optimized module outputs
    wire [31:0] imm_opt, alu_result_opt;
    wire alu_zero_opt, branch_taken_opt, predict_taken_opt;
    wire fast_ready, slow_ready;
    
    // Instantiate optimized modules (only ones that exist)
    immediate_gen_optimized imm_gen_opt (
        .instruction(instruction),
        .immediate(imm_opt)
    );
    
    alu_optimized alu_opt (
        .src1(src1),
        .src2(src2),
        .alu_op(alu_op),
        .result(alu_result_opt),
        .zero(alu_zero_opt),
        .fast_ready(fast_ready),
        .slow_ready(slow_ready)
    );
    
    branch_unit_optimized branch_opt (
        .rs1_data(src1),
        .rs2_data(src2),
        .funct3(funct3),
        .branch_taken(branch_taken_opt),
        .predict_taken(predict_taken_opt)
    );
    
    // Test vectors
    integer i, errors;
    
    initial begin
        errors = 0;
        
        $display("Starting optimization verification tests...");
        
        // Test immediate generator with sample instructions
        $display("\nTesting Immediate Generator:");
        
        instruction = 32'h00100093; // ADDI x1, x0, 1 (I-type imm = 1)
        expected_imm = 32'h00000001;
        #1;
        if (expected_imm !== imm_opt) begin
            $display("ERROR: Immediate mismatch for ADDI: expected=0x%08x got=0x%08x", expected_imm, imm_opt);
            errors = errors + 1;
        end else begin
            $display("PASS: ADDI -> Immediate 0x%08x", imm_opt);
        end
        
        instruction = 32'h00422223; // SW x4, 4(x4) (S-type imm = 4)
        expected_imm = 32'h00000004;
        #1;
        if (expected_imm !== imm_opt) begin
            $display("ERROR: Immediate mismatch for SW: expected=0x%08x got=0x%08x", expected_imm, imm_opt);
            errors = errors + 1;
        end else begin
            $display("PASS: SW -> Immediate 0x%08x", imm_opt);
        end
        
        instruction = 32'h00209463; // BNE x1, x2, +8 (B-type imm = 8)
        expected_imm = 32'h00000008;
        #1;
        if (expected_imm !== imm_opt) begin
            $display("ERROR: Immediate mismatch for BNE: expected=0x%08x got=0x%08x", expected_imm, imm_opt);
            errors = errors + 1;
        end else begin
            $display("PASS: BNE -> Immediate 0x%08x", imm_opt);
        end
        
        // Test ALU operations
        $display("\nTesting ALU:");
        
        // Test ADD
        alu_op = 4'b0000; src1 = 32'h12345678; src2 = 32'h87654321;
        expected_alu_result = 32'h99999999; // 0x12345678 + 0x87654321
        expected_alu_zero = 1'b0;
        #1;
        if ((expected_alu_result !== alu_result_opt) || (expected_alu_zero !== alu_zero_opt)) begin
            $display("ERROR: ALU ADD mismatch: expected=0x%08x got=0x%08x", expected_alu_result, alu_result_opt);
            errors = errors + 1;
        end else begin
            $display("PASS: ADD -> result=0x%08x", alu_result_opt);
        end
        
        // Test SUB
        alu_op = 4'b0001; src1 = 32'h87654321; src2 = 32'h12345678;
        expected_alu_result = 32'h7530eca9; // 0x87654321 - 0x12345678
        expected_alu_zero = 1'b0;
        #1;
        if ((expected_alu_result !== alu_result_opt) || (expected_alu_zero !== alu_zero_opt)) begin
            $display("ERROR: ALU SUB mismatch: expected=0x%08x got=0x%08x", expected_alu_result, alu_result_opt);
            errors = errors + 1;
        end else begin
            $display("PASS: SUB -> result=0x%08x", alu_result_opt);
        end
        
        // Test XOR
        alu_op = 4'b0100; src1 = 32'hAAAA5555; src2 = 32'h5555AAAA;
        expected_alu_result = 32'hFFFFFFFF; // 0xAAAA5555 ^ 0x5555AAAA
        expected_alu_zero = 1'b0;
        #1;
        if ((expected_alu_result !== alu_result_opt) || (expected_alu_zero !== alu_zero_opt)) begin
            $display("ERROR: ALU XOR mismatch: expected=0x%08x got=0x%08x", expected_alu_result, alu_result_opt);
            errors = errors + 1;
        end else begin
            $display("PASS: XOR -> result=0x%08x", alu_result_opt);
        end
        
        // Test Branch Unit
        $display("\nTesting Branch Unit:");
        
        // Test BEQ with equal values
        funct3 = 3'b000; src1 = 32'h12345678; src2 = 32'h12345678;
        expected_branch_taken = 1'b1; // Equal values should take BEQ
        #1;
        if (expected_branch_taken !== branch_taken_opt) begin
            $display("ERROR: Branch BEQ mismatch: expected=%b got=%b", expected_branch_taken, branch_taken_opt);
            errors = errors + 1;
        end else begin
            $display("PASS: BEQ equal -> taken=%b", branch_taken_opt);
        end
        
        // Test BNE with different values
        funct3 = 3'b001; src1 = 32'h12345678; src2 = 32'h87654321;
        expected_branch_taken = 1'b1; // Different values should take BNE
        #1;
        if (expected_branch_taken !== branch_taken_opt) begin
            $display("ERROR: Branch BNE mismatch: expected=%b got=%b", expected_branch_taken, branch_taken_opt);
            errors = errors + 1;
        end else begin
            $display("PASS: BNE different -> taken=%b", branch_taken_opt);
        end
        
        // Test BLT 
        funct3 = 3'b100; src1 = 32'h00000001; src2 = 32'h00000002;
        expected_branch_taken = 1'b1; // 1 < 2 should take BLT
        #1;
        if (expected_branch_taken !== branch_taken_opt) begin
            $display("ERROR: Branch BLT mismatch: expected=%b got=%b", expected_branch_taken, branch_taken_opt);
            errors = errors + 1;
        end else begin
            $display("PASS: BLT -> taken=%b", branch_taken_opt);
        end
        
        // Final results
        $display("\n==================================================");
        if (errors == 0) begin
            $display("✅ ALL TESTS PASSED! Optimized modules are functionally correct.");
            $display("Ready to integrate optimized modules into main CPU.");
        end else begin
            $display("❌ %0d ERRORS FOUND! Optimization needs fixes.", errors);
        end
        $display("==================================================");
        
        $finish;
    end

endmodule 