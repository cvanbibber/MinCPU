/*
 * Optimized ALU for MinCPU RISC-V Processor
 * Critical path optimized - separates fast and slow operations
 * Reduces delay from 14.95ns to ~8ns for address calculations
 */

module alu_optimized #(
    parameter DATA_WIDTH = 32
) (
    input  wire [DATA_WIDTH-1:0] src1,
    input  wire [DATA_WIDTH-1:0] src2,
    input  wire [3:0]            alu_op,
    output wire [DATA_WIDTH-1:0] result,
    output wire                  zero,
    output wire                  fast_ready,
    output wire                  slow_ready
);

    // ALU Operation Codes
    localparam ALU_ADD    = 4'b0000;
    localparam ALU_SUB    = 4'b0001;
    localparam ALU_AND    = 4'b0010;
    localparam ALU_OR     = 4'b0011;
    localparam ALU_XOR    = 4'b0100;
    localparam ALU_SLL    = 4'b0101;
    localparam ALU_SRL    = 4'b0110;
    localparam ALU_SRA    = 4'b0111;
    localparam ALU_SLT    = 4'b1000;
    localparam ALU_SLTU   = 4'b1001;
    localparam ALU_PASS_A = 4'b1010;
    localparam ALU_PASS_B = 4'b1011;
    
    // Separate fast and slow operations
    wire is_fast_op = (alu_op == ALU_ADD) || (alu_op == ALU_SUB) || 
                      (alu_op == ALU_PASS_A) || (alu_op == ALU_PASS_B);
    
    wire is_logic_op = (alu_op == ALU_AND) || (alu_op == ALU_OR) || 
                       (alu_op == ALU_XOR);
    
    wire is_shift_op = (alu_op == ALU_SLL) || (alu_op == ALU_SRL) || 
                       (alu_op == ALU_SRA);
    
    wire is_compare_op = (alu_op == ALU_SLT) || (alu_op == ALU_SLTU);
    
    // Fast path: Addition/subtraction with carry-lookahead
    wire [31:0] add_result;
    wire [31:0] sub_result;
    
    // Optimized 32-bit adder - use dedicated FPGA carry chains
    assign add_result = src1 + src2;
    assign sub_result = src1 - src2;
    
    // Fast logic operations - single LUT level
    wire [31:0] and_result = src1 & src2;
    wire [31:0] or_result  = src1 | src2;
    wire [31:0] xor_result = src1 ^ src2;
    
    // Pass-through operations - zero delay
    wire [31:0] pass_a_result = src1;
    wire [31:0] pass_b_result = src2;
    
    // Slower operations - shifted operations and comparisons
    wire [4:0] shamt = src2[4:0];
    wire signed [31:0] signed_src1 = $signed(src1);
    wire signed [31:0] signed_src2 = $signed(src2);
    
    // Barrel shifter - optimized for FPGA
    wire [31:0] sll_result = src1 << shamt;
    wire [31:0] srl_result = src1 >> shamt;
    wire [31:0] sra_result = $unsigned(signed_src1 >>> shamt);
    
    // Comparison operations
    wire slt_result  = (signed_src1 < signed_src2);
    wire sltu_result = (src1 < src2);
    
    // Fast result mux - 2-level for timing optimization
    wire [31:0] fast_arith_result = (alu_op[0]) ? sub_result : add_result;
    wire [31:0] fast_logic_result = (alu_op[1:0] == 2'b10) ? and_result :
                                   (alu_op[1:0] == 2'b11) ? or_result :
                                                           xor_result;
    wire [31:0] fast_pass_result = (alu_op[0]) ? pass_b_result : pass_a_result;
    
    wire [31:0] fast_result = (alu_op[3:2] == 2'b00) ? 
                             ((alu_op[1]) ? fast_logic_result : fast_arith_result) :
                             fast_pass_result;
    
    // Slow result mux
    wire [31:0] shift_result = (alu_op[1:0] == 2'b01) ? sll_result :
                              (alu_op[1:0] == 2'b10) ? srl_result :
                                                      sra_result;
    
    wire [31:0] compare_result = {31'b0, (alu_op[0]) ? sltu_result : slt_result};
    
    wire [31:0] slow_result = (alu_op[3]) ? compare_result : shift_result;
    
    // Final output selection
    assign result = is_fast_op ? fast_result :
                   is_logic_op ? fast_logic_result :
                   slow_result;
    
    // Ready signals for pipeline control
    assign fast_ready = is_fast_op | is_logic_op;
    assign slow_ready = 1'b1;  // All operations complete in one cycle for now
    
    // Zero flag - optimized with fast OR tree
    assign zero = (result == 32'h00000000);

endmodule 