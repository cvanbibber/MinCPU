/*
 * Register File for MinCPU RISC-V Processor
 * 32 x 32-bit registers (x0-x31)
 * x0 is hardwired to zero
 * 2 read ports, 1 write port
 */

module register_file #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5
) (
    input  wire                  clk,
    input  wire                  rst_n,
    
    // Read ports
    input  wire [ADDR_WIDTH-1:0] rs1_addr,
    input  wire [ADDR_WIDTH-1:0] rs2_addr,
    output wire [DATA_WIDTH-1:0] rs1_data,
    output wire [DATA_WIDTH-1:0] rs2_data,
    
    // Write port
    input  wire [ADDR_WIDTH-1:0] rd_addr,
    input  wire [DATA_WIDTH-1:0] rd_data,
    input  wire                  reg_we
);

    // Register file storage
    reg [DATA_WIDTH-1:0] registers [31:1]; // x1-x31, x0 is special
    
    // Initialize registers to zero
    integer i;
    initial begin
        for (i = 1; i < 32; i = i + 1) begin
            registers[i] = 32'h00000000;
        end
    end
    
    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers to zero
            for (i = 1; i < 32; i = i + 1) begin
                registers[i] <= 32'h00000000;
            end
        end else if (reg_we && rd_addr != 5'b00000) begin
            // Write to register (x0 cannot be written)
            registers[rd_addr] <= rd_data;
        end
    end
    
    // Read logic (combinational)
    assign rs1_data = (rs1_addr == 5'b00000) ? 32'h00000000 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'b00000) ? 32'h00000000 : registers[rs2_addr];

endmodule 