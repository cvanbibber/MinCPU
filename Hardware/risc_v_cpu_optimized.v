/*
 * Optimized MinCPU RISC-V Processor - High Performance Version
 * Targets 100MHz operation on Xilinx xc7z020-1clg400c FPGA
 * Integrates optimized critical path modules
 */

module risc_v_cpu_optimized #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter REG_FILE_ADDR_WIDTH = 5
) (
    input  wire                      clk,
    input  wire                      rst_n,
    
    // Instruction Memory Interface
    output wire [ADDR_WIDTH-1:0]     imem_addr,
    output wire                      imem_req,
    input  wire [DATA_WIDTH-1:0]     imem_data,
    input  wire                      imem_ready,
    
    // Data Memory Interface  
    output wire [ADDR_WIDTH-1:0]     dmem_addr,
    output wire [DATA_WIDTH-1:0]     dmem_wdata,
    output wire [3:0]                dmem_wstrb,
    output wire                      dmem_req,
    output wire                      dmem_we,
    input  wire [DATA_WIDTH-1:0]     dmem_rdata,
    input  wire                      dmem_ready,
    
    // Performance Monitoring
    output wire [31:0]               cycle_count,
    output wire [31:0]               instr_count,
    output wire [31:0]               stall_count,
    output wire [31:0]               branch_count,
    output wire [31:0]               branch_taken_count
);

    // Pipeline registers with enhanced timing
    reg [DATA_WIDTH-1:0] if_pc, id_pc;
    reg [DATA_WIDTH-1:0] if_instruction, id_instruction;
    reg                  if_valid, id_valid;
    
    // Pipeline control signals
    wire stall_if, stall_id, flush_if, flush_id;
    wire pipeline_ready;
    
    // Instruction decode signals
    wire [6:0]  opcode;
    wire [4:0]  rd, rs1, rs2;
    wire [2:0]  funct3;
    wire [6:0]  funct7;
    wire [31:0] immediate;
    
    // Control signals from optimized control unit
    wire        reg_write;
    wire [1:0]  reg_write_src;
    wire        alu_src;
    wire [3:0]  alu_op;
    wire        mem_read, mem_write;
    wire [2:0]  mem_size;
    wire        branch, jump;
    wire        branch_condition;
    wire        fast_ready, slow_ready;
    
    // Register file signals
    wire [DATA_WIDTH-1:0] rs1_data, rs2_data, rd_data;
    
    // ALU signals
    wire [DATA_WIDTH-1:0] alu_src1, alu_src2, alu_result;
    wire                  alu_zero;
    
    // Branch signals  
    wire                  branch_taken, predict_taken;
    wire [DATA_WIDTH-1:0] branch_target, jump_target;
    wire [DATA_WIDTH-1:0] next_pc;
    
    // Memory interface signals
    wire [DATA_WIDTH-1:0] mem_result;
    wire [3:0]            mem_strobe;
    
    // Performance counters
    reg [31:0] cycle_counter;
    reg [31:0] instr_counter; 
    reg [31:0] stall_counter;
    reg [31:0] branch_counter;
    reg [31:0] branch_taken_counter;
    
    // Assign performance outputs
    assign cycle_count = cycle_counter;
    assign instr_count = instr_counter;
    assign stall_count = stall_counter;
    assign branch_count = branch_counter;
    assign branch_taken_count = branch_taken_counter;

    //=================================================================
    // IF STAGE: Instruction Fetch with Optimized PC Logic
    //=================================================================
    
    // PC management with enhanced branch prediction
    reg [DATA_WIDTH-1:0] pc_reg;
    wire pc_enable = pipeline_ready && imem_ready && !stall_if;
    
    // Fast PC increment (parallel with branch calculation)
    wire [DATA_WIDTH-1:0] pc_plus_4 = pc_reg + 4;
    
    // Branch target calculation in parallel
    assign branch_target = id_pc + immediate;
    assign jump_target = (opcode == 7'b1101111) ? id_pc + immediate :  // JAL
                        (opcode == 7'b1100111) ? alu_result :           // JALR  
                        pc_plus_4;
    
    // Next PC selection with optimized mux
    assign next_pc = (flush_id) ? branch_target :
                    (jump && id_valid) ? jump_target :
                    pc_plus_4;
    
    // PC register with fast enable
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_reg <= 32'h00001000; // Start at program memory base
        end else if (pc_enable) begin
            pc_reg <= next_pc;
        end
    end
    
    // Instruction memory interface
    assign imem_addr = pc_reg;
    assign imem_req = !stall_if && rst_n;
    
    // IF/ID Pipeline Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            if_pc <= 32'h00001000;
            if_instruction <= 32'h00000013; // NOP
            if_valid <= 1'b0;
        end else if (flush_if) begin
            if_pc <= 32'h00001000;
            if_instruction <= 32'h00000013;
            if_valid <= 1'b0;
        end else if (pc_enable) begin
            if_pc <= pc_reg;
            if_instruction <= imem_data;
            if_valid <= imem_ready;
        end
    end

    //=================================================================
    // ID STAGE: Instruction Decode with Optimized Modules
    //=================================================================
    
    // ID pipeline register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            id_pc <= 32'h00001000;
            id_instruction <= 32'h00000013;
            id_valid <= 1'b0;
        end else if (flush_id) begin
            id_pc <= 32'h00001000;
            id_instruction <= 32'h00000013;
            id_valid <= 1'b0;
        end else if (!stall_id) begin
            id_pc <= if_pc;
            id_instruction <= if_instruction;
            id_valid <= if_valid;
        end
    end
    
    // Instruction field extraction
    assign opcode = id_instruction[6:0];
    assign rd     = id_instruction[11:7];
    assign funct3 = id_instruction[14:12];
    assign rs1    = id_instruction[19:15];
    assign rs2    = id_instruction[24:20];
    assign funct7 = id_instruction[31:25];
    
    // Optimized immediate generation (critical path optimized)
    immediate_gen_optimized imm_gen (
        .instruction(id_instruction),
        .immediate(immediate)
    );
    
    // Enhanced control unit 
    control_unit ctrl_unit (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .reg_write(reg_write),
        .reg_write_src(reg_write_src),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_size(mem_size),
        .branch(branch),
        .jump(jump)
    );
    
    // Register file with fast access
    register_file reg_file (
        .clk(clk),
        .rst_n(rst_n),
        .rs1_addr(rs1),
        .rs2_addr(rs2),
        .rd_addr(rd),
        .rd_data(rd_data),
        .reg_write(reg_write && id_valid),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );
    
    // ALU source selection
    assign alu_src1 = rs1_data;
    assign alu_src2 = alu_src ? immediate : rs2_data;
    
    // Optimized ALU (critical path reduced)
    alu_optimized alu (
        .src1(alu_src1),
        .src2(alu_src2),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(alu_zero),
        .fast_ready(fast_ready),
        .slow_ready(slow_ready)
    );
    
    // Optimized branch unit (critical path reduced)
    branch_unit_optimized branch_unit (
        .rs1_data(rs1_data),
        .rs2_data(rs2_data), 
        .funct3(funct3),
        .branch_taken(branch_taken),
        .predict_taken(predict_taken)
    );
    
    // Branch condition evaluation
    assign branch_condition = branch && branch_taken;
    
    //=================================================================
    // Memory Interface with Optimized Access
    //=================================================================
    
    // Memory address and write data
    assign dmem_addr = alu_result;
    assign dmem_wdata = rs2_data;
    assign dmem_req = (mem_read || mem_write) && id_valid;
    assign dmem_we = mem_write;
    
    // Memory byte enable generation
    memory_byte_enable mem_be_gen (
        .addr(alu_result[1:0]),
        .mem_size(mem_size),
        .byte_enable(mem_strobe)
    );
    assign dmem_wstrb = mem_strobe;
    
    // Memory result processing
    memory_load_unit mem_load (
        .addr(alu_result[1:0]),
        .mem_size(mem_size),
        .mem_data(dmem_rdata),
        .load_result(mem_result)
    );
    
    //=================================================================
    // Write-back and Pipeline Control
    //=================================================================
    
    // Write-back multiplexer
    wire [DATA_WIDTH-1:0] pc_plus_4_wb = id_pc + 4;
    
    assign rd_data = (reg_write_src == 2'b00) ? alu_result :
                    (reg_write_src == 2'b01) ? mem_result :
                    (reg_write_src == 2'b10) ? pc_plus_4_wb :
                    32'h00000000;
    
    // Pipeline control logic
    assign stall_if = !imem_ready || stall_id;
    assign stall_id = (mem_read || mem_write) && !dmem_ready;
    assign flush_if = branch_condition || (jump && id_valid);
    assign flush_id = branch_condition || (jump && id_valid);
    assign pipeline_ready = fast_ready && slow_ready;
    
    //=================================================================
    // Performance Monitoring
    //=================================================================
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_counter <= 32'h0;
            instr_counter <= 32'h0;
            stall_counter <= 32'h0;
            branch_counter <= 32'h0;
            branch_taken_counter <= 32'h0;
        end else begin
            // Increment cycle counter every clock
            cycle_counter <= cycle_counter + 1;
            
            // Count completed instructions
            if (id_valid && !stall_id) begin
                instr_counter <= instr_counter + 1;
            end
            
            // Count stall cycles
            if (stall_if || stall_id) begin
                stall_counter <= stall_counter + 1;
            end
            
            // Count branches
            if (branch && id_valid) begin
                branch_counter <= branch_counter + 1;
                if (branch_taken) begin
                    branch_taken_counter <= branch_taken_counter + 1;
                end
            end
        end
    end

endmodule

// Memory byte enable generation module
module memory_byte_enable (
    input  wire [1:0] addr,
    input  wire [2:0] mem_size,
    output reg  [3:0] byte_enable
);
    always @(*) begin
        case (mem_size)
            3'b000: // LB/SB
                case (addr)
                    2'b00: byte_enable = 4'b0001;
                    2'b01: byte_enable = 4'b0010; 
                    2'b10: byte_enable = 4'b0100;
                    2'b11: byte_enable = 4'b1000;
                endcase
            3'b001: // LH/SH
                case (addr[1])
                    1'b0: byte_enable = 4'b0011;
                    1'b1: byte_enable = 4'b1100;
                endcase
            3'b010: // LW/SW
                byte_enable = 4'b1111;
            default:
                byte_enable = 4'b1111;
        endcase
    end
endmodule

// Memory load unit for handling different load sizes
module memory_load_unit (
    input  wire [1:0]  addr,
    input  wire [2:0]  mem_size,
    input  wire [31:0] mem_data,
    output reg  [31:0] load_result
);
    always @(*) begin
        case (mem_size)
            3'b000: // LB (sign extend)
                case (addr)
                    2'b00: load_result = {{24{mem_data[7]}}, mem_data[7:0]};
                    2'b01: load_result = {{24{mem_data[15]}}, mem_data[15:8]};
                    2'b10: load_result = {{24{mem_data[23]}}, mem_data[23:16]};
                    2'b11: load_result = {{24{mem_data[31]}}, mem_data[31:24]};
                endcase
            3'b001: // LH (sign extend)
                case (addr[1])
                    1'b0: load_result = {{16{mem_data[15]}}, mem_data[15:0]};
                    1'b1: load_result = {{16{mem_data[31]}}, mem_data[31:16]};
                endcase
            3'b010: // LW
                load_result = mem_data;
            3'b100: // LBU (zero extend)
                case (addr)
                    2'b00: load_result = {24'h0, mem_data[7:0]};
                    2'b01: load_result = {24'h0, mem_data[15:8]};
                    2'b10: load_result = {24'h0, mem_data[23:16]};
                    2'b11: load_result = {24'h0, mem_data[31:24]};
                endcase
            3'b101: // LHU (zero extend)
                case (addr[1])
                    1'b0: load_result = {16'h0, mem_data[15:0]};
                    1'b1: load_result = {16'h0, mem_data[31:16]};
                endcase
            default:
                load_result = mem_data;
        endcase
    end
endmodule 