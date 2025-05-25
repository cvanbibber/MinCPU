/*
 * Control Unit for MinCPU RISC-V Processor
 * Generates control signals for RV32IMC instructions
 */

module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    
    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        branch,
    output reg        jump,
    output reg        alu_src,
    output reg [3:0]  alu_op,
    output reg [1:0]  wb_sel,
    output reg [1:0]  pc_sel
);

    // RISC-V Opcodes
    localparam OP_LUI     = 7'b0110111;
    localparam OP_AUIPC   = 7'b0010111;
    localparam OP_JAL     = 7'b1101111;
    localparam OP_JALR    = 7'b1100111;
    localparam OP_BRANCH  = 7'b1100011;
    localparam OP_LOAD    = 7'b0000011;
    localparam OP_STORE   = 7'b0100011;
    localparam OP_IMM     = 7'b0010011;
    localparam OP_REG     = 7'b0110011;
    localparam OP_FENCE   = 7'b0001111;
    localparam OP_SYSTEM  = 7'b1110011;
    
    // ALU Operations
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
    
    // Writeback Sources
    localparam WB_ALU     = 2'b00;
    localparam WB_MEM     = 2'b01;
    localparam WB_PC4     = 2'b10;
    localparam WB_IMM     = 2'b11;
    
    // PC Sources
    localparam PC_PLUS4   = 2'b00;
    localparam PC_ALU     = 2'b01;
    localparam PC_IMM     = 2'b10;

    always @(*) begin
        // Default values
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        branch    = 1'b0;
        jump      = 1'b0;
        alu_src   = 1'b0;
        alu_op    = ALU_ADD;
        wb_sel    = WB_ALU;
        pc_sel    = PC_PLUS4;
        
        case (opcode)
            OP_LUI: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = ALU_PASS_B;
                wb_sel    = WB_ALU;
            end
            
            OP_AUIPC: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = ALU_ADD;
                wb_sel    = WB_ALU;
                // Special handling in CPU for PC + immediate
            end
            
            OP_JAL: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                wb_sel    = WB_PC4;
                pc_sel    = PC_IMM;
            end
            
            OP_JALR: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                alu_src   = 1'b1;
                alu_op    = ALU_ADD;
                wb_sel    = WB_PC4;
                pc_sel    = PC_ALU;
            end
            
            OP_BRANCH: begin
                branch = 1'b1;
                alu_src = 1'b0;
                case (funct3)
                    3'b000: alu_op = ALU_SUB;  // BEQ
                    3'b001: alu_op = ALU_SUB;  // BNE
                    3'b100: alu_op = ALU_SLT;  // BLT
                    3'b101: alu_op = ALU_SLT;  // BGE
                    3'b110: alu_op = ALU_SLTU; // BLTU
                    3'b111: alu_op = ALU_SLTU; // BGEU
                    default: alu_op = ALU_SUB;
                endcase
            end
            
            OP_LOAD: begin
                reg_write = 1'b1;
                mem_read  = 1'b1;
                alu_src   = 1'b1;
                alu_op    = ALU_ADD;
                wb_sel    = WB_MEM;
            end
            
            OP_STORE: begin
                mem_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = ALU_ADD;
            end
            
            OP_IMM: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                case (funct3)
                    3'b000: alu_op = ALU_ADD;   // ADDI
                    3'b010: alu_op = ALU_SLT;   // SLTI
                    3'b011: alu_op = ALU_SLTU;  // SLTIU
                    3'b100: alu_op = ALU_XOR;   // XORI
                    3'b110: alu_op = ALU_OR;    // ORI
                    3'b111: alu_op = ALU_AND;   // ANDI
                    3'b001: alu_op = ALU_SLL;   // SLLI
                    3'b101: begin
                        if (funct7[5])
                            alu_op = ALU_SRA;   // SRAI
                        else
                            alu_op = ALU_SRL;   // SRLI
                    end
                    default: alu_op = ALU_ADD;
                endcase
                wb_sel = WB_ALU;
            end
            
            OP_REG: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;
                case (funct3)
                    3'b000: begin
                        if (funct7[5])
                            alu_op = ALU_SUB;   // SUB
                        else
                            alu_op = ALU_ADD;   // ADD
                    end
                    3'b001: alu_op = ALU_SLL;   // SLL
                    3'b010: alu_op = ALU_SLT;   // SLT
                    3'b011: alu_op = ALU_SLTU;  // SLTU
                    3'b100: alu_op = ALU_XOR;   // XOR
                    3'b101: begin
                        if (funct7[5])
                            alu_op = ALU_SRA;   // SRA
                        else
                            alu_op = ALU_SRL;   // SRL
                    end
                    3'b110: alu_op = ALU_OR;    // OR
                    3'b111: alu_op = ALU_AND;   // AND
                    default: alu_op = ALU_ADD;
                endcase
                wb_sel = WB_ALU;
            end
            
            OP_FENCE: begin
                // FENCE instructions - NOP for simple implementation
                reg_write = 1'b0;
            end
            
            OP_SYSTEM: begin
                // ECALL, EBREAK, CSR instructions - simplified
                case (funct3)
                    3'b000: begin
                        // ECALL/EBREAK - NOP for now
                        reg_write = 1'b0;
                    end
                    default: begin
                        // CSR instructions - basic implementation
                        reg_write = 1'b1;
                        alu_src   = 1'b1;
                        alu_op    = ALU_PASS_B;
                        wb_sel    = WB_ALU;
                    end
                endcase
            end
            
            default: begin
                // Invalid instruction - treat as NOP
                reg_write = 1'b0;
                mem_read  = 1'b0;
                mem_write = 1'b0;
                branch    = 1'b0;
                jump      = 1'b0;
            end
        endcase
    end

endmodule 