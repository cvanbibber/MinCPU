/*
 * RV32C Compressed Instruction Decoder for MinCPU
 * Converts 16-bit compressed instructions to 32-bit standard RISC-V instructions
 * Supports all RV32C instruction formats for improved code density
 */

module compressed_decoder (
    input  wire [15:0] compressed_instr,
    input  wire        is_compressed,
    output wire [31:0] expanded_instr,
    output wire        illegal_instr,
    output wire        valid_expansion
);

    // Extract fields from compressed instruction
    wire [1:0]  opcode = compressed_instr[1:0];
    wire [2:0]  funct3 = compressed_instr[15:13];
    wire [4:0]  rd_rs1 = compressed_instr[11:7];
    wire [4:0]  rs2 = compressed_instr[6:2];
    wire [2:0]  rd_prime = compressed_instr[4:2];
    wire [2:0]  rs1_prime = compressed_instr[9:7];
    wire [2:0]  rs2_prime = compressed_instr[4:2];
    
    // Expand 3-bit register encodings to 5-bit (x8-x15 -> 01xxx)
    wire [4:0] rd_expanded = {2'b01, rd_prime};
    wire [4:0] rs1_expanded = {2'b01, rs1_prime};
    wire [4:0] rs2_expanded = {2'b01, rs2_prime};
    
    // Immediate field extraction and sign extension
    wire [31:0] ci_imm, css_imm, ciw_imm, cl_imm, cs_imm, cb_imm, cj_imm;
    
    // CI-type immediate (for ADDI, LI, etc.)
    assign ci_imm = {{26{compressed_instr[12]}}, compressed_instr[12], compressed_instr[6:2]};
    
    // CSS-type immediate (for stack-relative stores)
    assign css_imm = {24'b0, compressed_instr[8:7], compressed_instr[12:9], 2'b00};
    
    // CIW-type immediate (for ADDI4SPN)
    assign ciw_imm = {22'b0, compressed_instr[10:7], compressed_instr[12:11], compressed_instr[5], compressed_instr[6], 2'b00};
    
    // CL-type immediate (for loads)
    assign cl_imm = {25'b0, compressed_instr[5], compressed_instr[12:10], compressed_instr[6], 2'b00};
    
    // CS-type immediate (for stores) 
    assign cs_imm = {25'b0, compressed_instr[5], compressed_instr[12:10], compressed_instr[6], 2'b00};
    
    // CB-type immediate (for branches)
    assign cb_imm = {{23{compressed_instr[12]}}, compressed_instr[12], compressed_instr[6:5], compressed_instr[2], compressed_instr[11:10], compressed_instr[4:3], 1'b0};
    
    // CJ-type immediate (for jumps)
    assign cj_imm = {{20{compressed_instr[12]}}, compressed_instr[12], compressed_instr[8], compressed_instr[10:9], compressed_instr[6], compressed_instr[7], compressed_instr[2], compressed_instr[11], compressed_instr[5:3], 1'b0};
    
    // Main decoder logic
    reg [31:0] decoded_instr;
    reg        illegal_decode;
    
    always @(*) begin
        decoded_instr = 32'h00000013; // Default to NOP (ADDI x0, x0, 0)
        illegal_decode = 1'b0;
        
        if (!is_compressed) begin
            // Pass through 32-bit instructions unchanged
            decoded_instr = {compressed_instr, 16'h0}; // This would be handled differently in real implementation
        end else begin
            case (opcode)
                2'b00: begin // Quadrant 0
                    case (funct3)
                        3'b000: begin // C.ADDI4SPN
                            if (ciw_imm == 0) begin
                                illegal_decode = 1'b1; // Reserved encoding
                            end else begin
                                // ADDI rd', x2, nzuimm
                                decoded_instr = {ciw_imm[11:0], 5'd2, 3'b000, rd_expanded, 7'b0010011};
                            end
                        end
                        
                        3'b001: begin // C.FLD (RV32DC) - Not implemented
                            illegal_decode = 1'b1;
                        end
                        
                        3'b010: begin // C.LW
                            // LW rd', offset(rs1')
                            decoded_instr = {cl_imm[11:0], rs1_expanded, 3'b010, rd_expanded, 7'b0000011};
                        end
                        
                        3'b011: begin // C.FLW (RV32FC) - Not implemented  
                            illegal_decode = 1'b1;
                        end
                        
                        3'b100: begin // Reserved
                            illegal_decode = 1'b1;
                        end
                        
                        3'b101: begin // C.FSD (RV32DC) - Not implemented
                            illegal_decode = 1'b1;
                        end
                        
                        3'b110: begin // C.SW
                            // SW rs2', offset(rs1')
                            decoded_instr = {cs_imm[11:5], rs2_expanded, rs1_expanded, 3'b010, cs_imm[4:0], 7'b0100011};
                        end
                        
                        3'b111: begin // C.FSW (RV32FC) - Not implemented
                            illegal_decode = 1'b1;
                        end
                    endcase
                end
                
                2'b01: begin // Quadrant 1
                    case (funct3)
                        3'b000: begin // C.ADDI
                            if (rd_rs1 == 0 && ci_imm == 0) begin
                                // C.NOP
                                decoded_instr = 32'h00000013;
                            end else if (rd_rs1 != 0) begin
                                // ADDI rd, rd, nzimm
                                decoded_instr = {ci_imm[11:0], rd_rs1, 3'b000, rd_rs1, 7'b0010011};
                            end else begin
                                illegal_decode = 1'b1; // rd=x0 with nzimm!=0
                            end
                        end
                        
                        3'b001: begin // C.JAL (RV32C only)
                            // JAL x1, offset
                            decoded_instr = {cj_imm[20], cj_imm[10:1], cj_imm[11], cj_imm[19:12], 5'd1, 7'b1101111};
                        end
                        
                        3'b010: begin // C.LI
                            // ADDI rd, x0, imm  
                            decoded_instr = {ci_imm[11:0], 5'd0, 3'b000, rd_rs1, 7'b0010011};
                        end
                        
                        3'b011: begin // C.ADDI16SP / C.LUI
                            if (rd_rs1 == 5'd2) begin // C.ADDI16SP
                                if (ci_imm == 0) begin
                                    illegal_decode = 1'b1; // nzimm=0 is reserved
                                end else begin
                                    // ADDI x2, x2, nzimm
                                    wire [31:0] sp_imm = {{22{compressed_instr[12]}}, compressed_instr[12], compressed_instr[4:3], compressed_instr[5], compressed_instr[2], compressed_instr[6], 4'b0000};
                                    decoded_instr = {sp_imm[11:0], 5'd2, 3'b000, 5'd2, 7'b0010011};
                                end
                            end else if (rd_rs1 != 0) begin // C.LUI
                                if (ci_imm == 0) begin
                                    illegal_decode = 1'b1; // nzimm=0 is reserved
                                end else begin
                                    // LUI rd, nzimm
                                    wire [31:0] lui_imm = {{14{compressed_instr[12]}}, compressed_instr[12], compressed_instr[6:2], 12'b0};
                                    decoded_instr = {lui_imm[31:12], rd_rs1, 7'b0110111};
                                end
                            end else begin
                                illegal_decode = 1'b1; // rd=x0 is reserved
                            end
                        end
                        
                        3'b100: begin // Arithmetic operations
                            case (compressed_instr[11:10])
                                2'b00: begin // C.SRLI
                                    // SRLI rd', rd', shamt
                                    wire [5:0] shamt = {compressed_instr[12], compressed_instr[6:2]};
                                    decoded_instr = {6'b0, shamt, rs1_expanded, 3'b101, rs1_expanded, 7'b0010011};
                                end
                                
                                2'b01: begin // C.SRAI
                                    // SRAI rd', rd', shamt
                                    wire [5:0] shamt = {compressed_instr[12], compressed_instr[6:2]};
                                    decoded_instr = {6'b010000, shamt, rs1_expanded, 3'b101, rs1_expanded, 7'b0010011};
                                end
                                
                                2'b10: begin // C.ANDI
                                    // ANDI rd', rd', imm
                                    decoded_instr = {ci_imm[11:0], rs1_expanded, 3'b111, rs1_expanded, 7'b0010011};
                                end
                                
                                2'b11: begin // More arithmetic
                                    if (compressed_instr[12] == 0) begin
                                        case (compressed_instr[6:5])
                                            2'b00: begin // C.SUB
                                                // SUB rd', rd', rs2'
                                                decoded_instr = {7'b0100000, rs2_expanded, rs1_expanded, 3'b000, rs1_expanded, 7'b0110011};
                                            end
                                            2'b01: begin // C.XOR
                                                // XOR rd', rd', rs2'
                                                decoded_instr = {7'b0, rs2_expanded, rs1_expanded, 3'b100, rs1_expanded, 7'b0110011};
                                            end
                                            2'b10: begin // C.OR
                                                // OR rd', rd', rs2'
                                                decoded_instr = {7'b0, rs2_expanded, rs1_expanded, 3'b110, rs1_expanded, 7'b0110011};
                                            end
                                            2'b11: begin // C.AND
                                                // AND rd', rd', rs2'
                                                decoded_instr = {7'b0, rs2_expanded, rs1_expanded, 3'b111, rs1_expanded, 7'b0110011};
                                            end
                                        endcase
                                    end else begin
                                        // Reserved for RV64C
                                        illegal_decode = 1'b1;
                                    end
                                end
                            endcase
                        end
                        
                        3'b101: begin // C.J
                            // JAL x0, offset
                            decoded_instr = {cj_imm[20], cj_imm[10:1], cj_imm[11], cj_imm[19:12], 5'd0, 7'b1101111};
                        end
                        
                        3'b110: begin // C.BEQZ
                            // BEQ rs1', x0, offset
                            decoded_instr = {cb_imm[12], cb_imm[10:5], 5'd0, rs1_expanded, 3'b000, cb_imm[4:1], cb_imm[11], 7'b1100011};
                        end
                        
                        3'b111: begin // C.BNEZ
                            // BNE rs1', x0, offset
                            decoded_instr = {cb_imm[12], cb_imm[10:5], 5'd0, rs1_expanded, 3'b001, cb_imm[4:1], cb_imm[11], 7'b1100011};
                        end
                    endcase
                end
                
                2'b10: begin // Quadrant 2
                    case (funct3)
                        3'b000: begin // C.SLLI
                            if (rd_rs1 != 0) begin
                                // SLLI rd, rd, shamt
                                wire [5:0] shamt = {compressed_instr[12], compressed_instr[6:2]};
                                decoded_instr = {6'b0, shamt, rd_rs1, 3'b001, rd_rs1, 7'b0010011};
                            end else begin
                                illegal_decode = 1'b1; // rd=x0 is reserved
                            end
                        end
                        
                        3'b001: begin // C.FLDSP (RV32DC) - Not implemented
                            illegal_decode = 1'b1;
                        end
                        
                        3'b010: begin // C.LWSP
                            if (rd_rs1 != 0) begin
                                // LW rd, offset(x2)
                                wire [31:0] lwsp_imm = {24'b0, compressed_instr[3:2], compressed_instr[12], compressed_instr[6:4], 2'b00};
                                decoded_instr = {lwsp_imm[11:0], 5'd2, 3'b010, rd_rs1, 7'b0000011};
                            end else begin
                                illegal_decode = 1'b1; // rd=x0 is reserved
                            end
                        end
                        
                        3'b011: begin // C.FLWSP (RV32FC) - Not implemented
                            illegal_decode = 1'b1;
                        end
                        
                        3'b100: begin // C.JR / C.MV / C.EBREAK / C.JALR / C.ADD
                            if (compressed_instr[12] == 0) begin
                                if (rs2 == 0) begin // C.JR
                                    if (rd_rs1 != 0) begin
                                        // JALR x0, rs1, 0
                                        decoded_instr = {12'b0, rd_rs1, 3'b000, 5'd0, 7'b1100111};
                                    end else begin
                                        illegal_decode = 1'b1; // rs1=x0 is reserved
                                    end
                                end else begin // C.MV
                                    if (rd_rs1 != 0) begin
                                        // ADD rd, x0, rs2
                                        decoded_instr = {7'b0, rs2, 5'd0, 3'b000, rd_rs1, 7'b0110011};
                                    end else begin
                                        illegal_decode = 1'b1; // rd=x0 is reserved
                                    end
                                end
                            end else begin
                                if (rs2 == 0) begin
                                    if (rd_rs1 == 0) begin // C.EBREAK
                                        decoded_instr = 32'h00100073; // EBREAK
                                    end else begin // C.JALR
                                        // JALR x1, rs1, 0
                                        decoded_instr = {12'b0, rd_rs1, 3'b000, 5'd1, 7'b1100111};
                                    end
                                end else begin // C.ADD
                                    if (rd_rs1 != 0) begin
                                        // ADD rd, rd, rs2
                                        decoded_instr = {7'b0, rs2, rd_rs1, 3'b000, rd_rs1, 7'b0110011};
                                    end else begin
                                        illegal_decode = 1'b1; // rd=x0 is reserved
                                    end
                                end
                            end
                        end
                        
                        3'b101: begin // C.FSDSP (RV32DC) - Not implemented
                            illegal_decode = 1'b1;
                        end
                        
                        3'b110: begin // C.SWSP
                            // SW rs2, offset(x2)
                            wire [31:0] swsp_imm = {24'b0, compressed_instr[8:7], compressed_instr[12:9], 2'b00};
                            decoded_instr = {swsp_imm[11:5], rs2, 5'd2, 3'b010, swsp_imm[4:0], 7'b0100011};
                        end
                        
                        3'b111: begin // C.FSWSP (RV32FC) - Not implemented
                            illegal_decode = 1'b1;
                        end
                    endcase
                end
                
                2'b11: begin // 32-bit instructions - should not happen here
                    illegal_decode = 1'b1;
                end
            endcase
        end
    end
    
    assign expanded_instr = decoded_instr;
    assign illegal_instr = illegal_decode;
    assign valid_expansion = is_compressed && !illegal_decode;
    
endmodule

//=================================================================
// Instruction Fetch Unit with Compressed Instruction Support
//=================================================================

module fetch_unit_with_compression (
    input  wire        clk,
    input  wire        rst_n,
    
    // PC Interface
    input  wire [31:0] pc,
    output reg  [31:0] instruction,
    output reg         valid,
    output reg  [31:0] next_pc,
    
    // Memory Interface
    output wire [31:0] mem_addr,
    output wire        mem_req,
    input  wire [31:0] mem_data,
    input  wire        mem_ready
);

    reg [31:0] current_pc;
    reg [15:0] held_parcel;
    reg        parcel_valid;
    
    wire [15:0] lower_parcel = mem_data[15:0];
    wire [15:0] upper_parcel = mem_data[31:16];
    
    // Determine if instruction is compressed
    wire lower_is_compressed = (lower_parcel[1:0] != 2'b11);
    wire upper_is_compressed = (upper_parcel[1:0] != 2'b11);
    
    // Compressed decoder instance
    wire [31:0] expanded_lower, expanded_upper;
    wire        illegal_lower, illegal_upper;
    wire        valid_expansion_lower, valid_expansion_upper;
    
    compressed_decoder decoder_lower (
        .compressed_instr(lower_parcel),
        .is_compressed(lower_is_compressed),
        .expanded_instr(expanded_lower),
        .illegal_instr(illegal_lower),
        .valid_expansion(valid_expansion_lower)
    );
    
    compressed_decoder decoder_upper (
        .compressed_instr(upper_parcel),
        .is_compressed(upper_is_compressed),
        .expanded_instr(expanded_upper),
        .illegal_instr(illegal_upper),
        .valid_expansion(valid_expansion_upper)
    );
    
    assign mem_addr = current_pc;
    assign mem_req = rst_n;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_pc <= 32'h00001000;
            instruction <= 32'h00000013; // NOP
            valid <= 1'b0;
            next_pc <= 32'h00001000;
            held_parcel <= 16'h0;
            parcel_valid <= 1'b0;
        end else if (mem_ready) begin
            if (!parcel_valid) begin
                // No held parcel, process from memory
                if (lower_is_compressed) begin
                    instruction <= expanded_lower;
                    next_pc <= current_pc + 2;
                    held_parcel <= upper_parcel;
                    parcel_valid <= 1'b1;
                end else begin
                    instruction <= mem_data;
                    next_pc <= current_pc + 4;
                    parcel_valid <= 1'b0;
                end
                valid <= 1'b1;
            end else begin
                // Use held parcel
                if (held_parcel[1:0] != 2'b11) begin
                    // Held parcel is compressed
                    compressed_decoder decoder_held (
                        .compressed_instr(held_parcel),
                        .is_compressed(1'b1),
                        .expanded_instr(instruction),
                        .illegal_instr(),
                        .valid_expansion()
                    );
                    next_pc <= current_pc + 2;
                    held_parcel <= lower_parcel;
                    // Keep parcel_valid = 1
                end else begin
                    // Need to combine held parcel with lower parcel for 32-bit instruction
                    instruction <= {lower_parcel, held_parcel};
                    next_pc <= current_pc + 4;
                    held_parcel <= upper_parcel;
                    // Keep parcel_valid = 1
                end
                valid <= 1'b1;
            end
            
            current_pc <= next_pc;
        end else begin
            valid <= 1'b0;
        end
    end

endmodule 