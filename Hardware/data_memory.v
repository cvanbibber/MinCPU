/*
 * Data Memory for MinCPU RISC-V Processor
 * Read/Write memory for data storage
 * Supports byte, halfword, and word accesses
 */

module data_memory #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter MEM_SIZE = 1024,  // Number of 32-bit words
    parameter MEM_LATENCY = 1   // Memory access latency in cycles
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] wdata,
    output reg  [DATA_WIDTH-1:0] rdata,
    input  wire [3:0]            byte_enable,
    input  wire                  we,
    input  wire                  req,
    output reg                   ready
);

    // Memory array - byte addressable
    reg [7:0] memory [0:MEM_SIZE*4-1];
    wire [ADDR_WIDTH-1:0] byte_addr;
    wire [1:0] addr_offset;
    
    // Latency simulation
    reg [2:0] latency_counter;
    reg       access_pending;
    reg       pending_we;
    reg [ADDR_WIDTH-1:0] pending_addr;
    reg [DATA_WIDTH-1:0] pending_wdata;
    reg [3:0] pending_be;
    
    assign byte_addr = addr;
    assign addr_offset = addr[1:0];
    
    // Initialize memory to zero
    integer i;
    initial begin
        for (i = 0; i < MEM_SIZE*4; i = i + 1) begin
            memory[i] = 8'h00;
        end
        latency_counter = 0;
        access_pending = 0;
        ready = 0;
        rdata = 0;
    end
    
    // Memory access logic with latency simulation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rdata <= 32'h00000000;
            ready <= 1'b0;
            latency_counter <= 0;
            access_pending <= 1'b0;
        end else begin
            // Handle new memory request
            if (req && !access_pending) begin
                // Start new memory access
                access_pending <= 1'b1;
                ready <= 1'b0;
                latency_counter <= MEM_LATENCY - 1;
                pending_we <= we;
                pending_addr <= byte_addr;
                pending_wdata <= wdata;
                pending_be <= byte_enable;
            end
            // Handle ongoing memory access
            else if (access_pending) begin
                if (latency_counter == 0) begin
                    // Complete the memory access
                    if (pending_addr < MEM_SIZE*4-3) begin // Ensure word access is within bounds
                        if (pending_we) begin
                            // Write operation
                            if (pending_be[0]) memory[pending_addr]   <= pending_wdata[7:0];
                            if (pending_be[1]) memory[pending_addr+1] <= pending_wdata[15:8];
                            if (pending_be[2]) memory[pending_addr+2] <= pending_wdata[23:16];
                            if (pending_be[3]) memory[pending_addr+3] <= pending_wdata[31:24];
                        end else begin
                            // Read operation
                            rdata <= {memory[pending_addr+3], memory[pending_addr+2], 
                                     memory[pending_addr+1], memory[pending_addr]};
                        end
                    end else begin
                        // Out of bounds access
                        rdata <= 32'h00000000;
                    end
                    ready <= 1'b1;
                    access_pending <= 1'b0;
                end else begin
                    // Continue waiting
                    latency_counter <= latency_counter - 1;
                    ready <= 1'b0;
                end
            end else begin
                ready <= 1'b0;
            end
        end
    end

endmodule 