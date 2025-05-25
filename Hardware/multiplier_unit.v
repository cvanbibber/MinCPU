/*
 * RV32M Multiplier/Divider Unit for MinCPU
 * Implements MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU
 * Optimized for area efficiency with reasonable performance
 */

module multiplier_unit #(
    parameter DATA_WIDTH = 32
) (
    input  wire                      clk,
    input  wire                      rst_n,
    
    // Control Interface
    input  wire                      req,
    input  wire [2:0]                funct3,
    input  wire                      funct7_bit5,
    output reg                       ready,
    output reg                       valid,
    
    // Data Interface
    input  wire [DATA_WIDTH-1:0]     operand_a,
    input  wire [DATA_WIDTH-1:0]     operand_b,
    output reg  [DATA_WIDTH-1:0]     result,
    
    // Performance monitoring
    output wire [15:0]               cycle_count
);

    // RV32M Operation Encoding
    localparam OP_MUL    = 3'b000;  // MUL
    localparam OP_MULH   = 3'b001;  // MULH  
    localparam OP_MULHSU = 3'b010;  // MULHSU
    localparam OP_MULHU  = 3'b011;  // MULHU
    localparam OP_DIV    = 3'b100;  // DIV
    localparam OP_DIVU   = 3'b101;  // DIVU
    localparam OP_REM    = 3'b110;  // REM
    localparam OP_REMU   = 3'b111;  // REMU
    
    // State machine for multi-cycle operations
    typedef enum logic [2:0] {
        IDLE,
        MUL_EXEC,
        DIV_SETUP,
        DIV_EXEC, 
        RESULT_READY
    } state_t;
    
    state_t current_state, next_state;
    
    // Operation registers
    reg [2:0]  operation;
    reg [63:0] product;
    reg [31:0] dividend, divisor, quotient, remainder;
    reg [5:0]  div_counter;
    reg        div_sign;
    
    // Cycle counter for performance monitoring
    reg [15:0] cycle_counter;
    assign cycle_count = cycle_counter;
    
    // Input conditioning for signed operations
    wire signed [31:0] signed_a = $signed(operand_a);
    wire signed [31:0] signed_b = $signed(operand_b);
    wire [31:0] abs_a = (signed_a < 0) ? -signed_a : signed_a;
    wire [31:0] abs_b = (signed_b < 0) ? -signed_b : signed_b;
    
    // Fast single-cycle multiplier for simple cases
    wire [63:0] fast_product = operand_a * operand_b;
    wire [63:0] fast_signed_product = signed_a * signed_b;
    wire [63:0] fast_mixed_product = signed_a * operand_b;
    
    // Division by zero detection
    wire div_by_zero = (operand_b == 32'h0);
    
    //=================================================================
    // State Machine Control
    //=================================================================
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            cycle_counter <= 16'h0;
        end else begin
            current_state <= next_state;
            if (current_state != IDLE) begin
                cycle_counter <= cycle_counter + 1;
            end else begin
                cycle_counter <= 16'h0;
            end
        end
    end
    
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (req) begin
                    case (funct3)
                        OP_MUL, OP_MULH, OP_MULHSU, OP_MULHU: 
                            next_state = MUL_EXEC;
                        OP_DIV, OP_DIVU, OP_REM, OP_REMU:
                            next_state = div_by_zero ? RESULT_READY : DIV_SETUP;
                    endcase
                end
            end
            
            MUL_EXEC: begin
                next_state = RESULT_READY;  // Single cycle for multiply
            end
            
            DIV_SETUP: begin
                next_state = DIV_EXEC;
            end
            
            DIV_EXEC: begin
                if (div_counter == 6'd32) begin
                    next_state = RESULT_READY;
                end
            end
            
            RESULT_READY: begin
                next_state = IDLE;
            end
        endcase
    end
    
    //=================================================================
    // Multiplication Logic (Single Cycle)
    //=================================================================
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 64'h0;
            operation <= 3'h0;
        end else if (current_state == IDLE && req) begin
            operation <= funct3;
            case (funct3)
                OP_MUL, OP_MULH: 
                    product <= fast_signed_product;
                OP_MULHSU:
                    product <= fast_mixed_product;
                OP_MULHU:
                    product <= fast_product;
            endcase
        end
    end
    
    //=================================================================
    // Division Logic (Multi-Cycle Restoring Division)
    //=================================================================
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dividend <= 32'h0;
            divisor <= 32'h0;
            quotient <= 32'h0;
            remainder <= 32'h0;
            div_counter <= 6'h0;
            div_sign <= 1'b0;
        end else begin
            case (current_state)
                DIV_SETUP: begin
                    // Setup for division
                    case (funct3)
                        OP_DIV: begin
                            dividend <= abs_a;
                            divisor <= abs_b;
                            div_sign <= (signed_a < 0) ^ (signed_b < 0);
                        end
                        OP_REM: begin
                            dividend <= abs_a;
                            divisor <= abs_b;
                            div_sign <= (signed_a < 0);
                        end
                        OP_DIVU, OP_REMU: begin
                            dividend <= operand_a;
                            divisor <= operand_b;
                            div_sign <= 1'b0;
                        end
                    endcase
                    quotient <= 32'h0;
                    remainder <= 32'h0;
                    div_counter <= 6'h0;
                end
                
                DIV_EXEC: begin
                    // Restoring division algorithm
                    remainder <= (remainder << 1) | dividend[31];
                    dividend <= dividend << 1;
                    
                    if (remainder >= divisor) begin
                        remainder <= remainder - divisor;
                        quotient <= (quotient << 1) | 1'b1;
                    end else begin
                        quotient <= quotient << 1;
                    end
                    
                    div_counter <= div_counter + 1;
                end
            endcase
        end
    end
    
    //=================================================================
    // Result Selection and Output
    //=================================================================
    
    always @(*) begin
        ready = (current_state == IDLE);
        valid = (current_state == RESULT_READY);
        
        case (operation)
            OP_MUL:    result = product[31:0];
            OP_MULH:   result = product[63:32];
            OP_MULHSU: result = product[63:32];
            OP_MULHU:  result = product[63:32];
            
            OP_DIV: begin
                if (div_by_zero) begin
                    result = 32'hFFFFFFFF;  // Per RISC-V spec
                end else begin
                    result = div_sign ? -quotient : quotient;
                end
            end
            
            OP_DIVU: begin
                if (div_by_zero) begin
                    result = 32'hFFFFFFFF;  // Per RISC-V spec
                end else begin
                    result = quotient;
                end
            end
            
            OP_REM: begin
                if (div_by_zero) begin
                    result = operand_a;  // Per RISC-V spec
                end else begin
                    result = div_sign ? -remainder : remainder;
                end
            end
            
            OP_REMU: begin
                if (div_by_zero) begin
                    result = operand_a;  // Per RISC-V spec
                end else begin
                    result = remainder;
                end
            end
            
            default: result = 32'h0;
        endcase
    end
    
endmodule

//=================================================================
// Compact Multiplier for Area-Optimized Designs
//=================================================================

module compact_multiplier #(
    parameter DATA_WIDTH = 32
) (
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire                      start,
    input  wire [DATA_WIDTH-1:0]     multiplicand,
    input  wire [DATA_WIDTH-1:0]     multiplier,
    output reg  [2*DATA_WIDTH-1:0]   product,
    output reg                       done
);

    reg [5:0] counter;
    reg [31:0] partial_product;
    reg [31:0] shifted_multiplicand;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 64'h0;
            counter <= 6'h0;
            done <= 1'b0;
            partial_product <= 32'h0;
            shifted_multiplicand <= 32'h0;
        end else if (start && counter == 6'h0) begin
            // Initialize
            partial_product <= multiplier;
            shifted_multiplicand <= multiplicand;
            product <= 64'h0;
            counter <= 6'h1;
            done <= 1'b0;
        end else if (counter > 6'h0 && counter <= 6'd32) begin
            // Perform one step of multiplication
            if (partial_product[0]) begin
                product[63:32] <= product[63:32] + shifted_multiplicand;
            end
            
            // Shift for next iteration
            product <= product >> 1;
            partial_product <= partial_product >> 1;
            shifted_multiplicand <= shifted_multiplicand << 1;
            
            counter <= counter + 1;
            
            if (counter == 6'd32) begin
                done <= 1'b1;
                counter <= 6'h0;
            end
        end else if (done) begin
            done <= 1'b0;
        end
    end

endmodule 