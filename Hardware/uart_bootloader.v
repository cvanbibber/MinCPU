/*
 * UART Bootloader for MinCPU
 * Allows loading programs via UART interface
 */

`include "cpu_config.vh"

module uart_bootloader #(
    parameter CLOCK_FREQ = 40000000,  // 40 MHz
    parameter BAUD_RATE = `UART_BAUD_RATE,
    parameter ADDR_WIDTH = `ADDR_WIDTH,
    parameter DATA_WIDTH = `DATA_WIDTH
) (
    input  wire                    clk,
    input  wire                    rst_n,
    
    // UART interface
    input  wire                    uart_rx,
    output wire                    uart_tx,
    
    // Memory interface
    output reg  [ADDR_WIDTH-1:0]  mem_addr,
    output reg  [DATA_WIDTH-1:0]  mem_wdata,
    output reg                     mem_we,
    output reg                     mem_req,
    input  wire                    mem_ready,
    
    // Control interface
    input  wire                    bootloader_enable,
    output reg                     boot_complete,
    output reg                     boot_error,
    
    // Status
    output reg  [31:0]             bytes_loaded,
    output reg  [31:0]             load_address
);

    // UART parameters
    localparam BAUD_DIV = CLOCK_FREQ / BAUD_RATE;
    localparam BAUD_BITS = $clog2(BAUD_DIV);
    
    // Bootloader states
    typedef enum logic [3:0] {
        BOOT_IDLE,
        BOOT_WAIT_MAGIC,
        BOOT_WAIT_SIZE,
        BOOT_WAIT_ADDR,
        BOOT_LOAD_DATA,
        BOOT_VERIFY,
        BOOT_COMPLETE,
        BOOT_ERROR
    } boot_state_t;
    
    boot_state_t current_state, next_state;
    
    // UART receiver signals
    wire [7:0] rx_data;
    wire rx_valid;
    wire rx_ready;
    
    // UART transmitter signals
    reg [7:0] tx_data;
    reg tx_valid;
    wire tx_ready;
    
    // Bootloader registers
    reg [31:0] magic_word;
    reg [31:0] program_size;
    reg [31:0] program_addr;
    reg [31:0] byte_count;
    reg [31:0] word_buffer;
    reg [1:0]  byte_index;
    
    // Timeout counter
    reg [31:0] timeout_counter;
    
    // UART receiver instance
    uart_rx #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rx(uart_rx),
        .data(rx_data),
        .valid(rx_valid),
        .ready(rx_ready)
    );
    
    // UART transmitter instance
    uart_tx #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_tx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tx(uart_tx),
        .data(tx_data),
        .valid(tx_valid),
        .ready(tx_ready)
    );
    
    // State machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= BOOT_IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = current_state;
        
        case (current_state)
            BOOT_IDLE: begin
                if (bootloader_enable) begin
                    next_state = BOOT_WAIT_MAGIC;
                end
            end
            
            BOOT_WAIT_MAGIC: begin
                if (timeout_counter >= `BOOTLOADER_TIMEOUT) begin
                    next_state = BOOT_ERROR;
                end else if (magic_word == `BOOTLOADER_MAGIC) begin
                    next_state = BOOT_WAIT_SIZE;
                end
            end
            
            BOOT_WAIT_SIZE: begin
                if (timeout_counter >= `BOOTLOADER_TIMEOUT) begin
                    next_state = BOOT_ERROR;
                end else if (byte_count >= 4) begin
                    next_state = BOOT_WAIT_ADDR;
                end
            end
            
            BOOT_WAIT_ADDR: begin
                if (timeout_counter >= `BOOTLOADER_TIMEOUT) begin
                    next_state = BOOT_ERROR;
                end else if (byte_count >= 4) begin
                    next_state = BOOT_LOAD_DATA;
                end
            end
            
            BOOT_LOAD_DATA: begin
                if (timeout_counter >= `BOOTLOADER_TIMEOUT) begin
                    next_state = BOOT_ERROR;
                end else if (bytes_loaded >= program_size) begin
                    next_state = BOOT_VERIFY;
                end
            end
            
            BOOT_VERIFY: begin
                next_state = BOOT_COMPLETE;
            end
            
            BOOT_COMPLETE: begin
                if (!bootloader_enable) begin
                    next_state = BOOT_IDLE;
                end
            end
            
            BOOT_ERROR: begin
                if (!bootloader_enable) begin
                    next_state = BOOT_IDLE;
                end
            end
        endcase
    end
    
    // Output logic and register updates
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            magic_word <= 32'h0;
            program_size <= 32'h0;
            program_addr <= 32'h0;
            byte_count <= 32'h0;
            bytes_loaded <= 32'h0;
            word_buffer <= 32'h0;
            byte_index <= 2'h0;
            timeout_counter <= 32'h0;
            
            mem_addr <= 32'h0;
            mem_wdata <= 32'h0;
            mem_we <= 1'b0;
            mem_req <= 1'b0;
            
            boot_complete <= 1'b0;
            boot_error <= 1'b0;
            
            tx_data <= 8'h0;
            tx_valid <= 1'b0;
            
            load_address <= 32'h0;
        end else begin
            // Default values
            mem_we <= 1'b0;
            mem_req <= 1'b0;
            tx_valid <= 1'b0;
            
            case (current_state)
                BOOT_IDLE: begin
                    magic_word <= 32'h0;
                    program_size <= 32'h0;
                    program_addr <= 32'h0;
                    byte_count <= 32'h0;
                    bytes_loaded <= 32'h0;
                    byte_index <= 2'h0;
                    timeout_counter <= 32'h0;
                    boot_complete <= 1'b0;
                    boot_error <= 1'b0;
                    load_address <= 32'h0;
                end
                
                BOOT_WAIT_MAGIC: begin
                    timeout_counter <= timeout_counter + 1;
                    if (rx_valid && rx_ready) begin
                        magic_word <= {magic_word[23:0], rx_data};
                        timeout_counter <= 32'h0;
                    end
                end
                
                BOOT_WAIT_SIZE: begin
                    timeout_counter <= timeout_counter + 1;
                    if (rx_valid && rx_ready) begin
                        word_buffer <= {word_buffer[23:0], rx_data};
                        byte_count <= byte_count + 1;
                        timeout_counter <= 32'h0;
                        if (byte_count == 3) begin
                            program_size <= {word_buffer[23:0], rx_data};
                            byte_count <= 32'h0;
                            word_buffer <= 32'h0;
                        end
                    end
                end
                
                BOOT_WAIT_ADDR: begin
                    timeout_counter <= timeout_counter + 1;
                    if (rx_valid && rx_ready) begin
                        word_buffer <= {word_buffer[23:0], rx_data};
                        byte_count <= byte_count + 1;
                        timeout_counter <= 32'h0;
                        if (byte_count == 3) begin
                            program_addr <= {word_buffer[23:0], rx_data};
                            load_address <= {word_buffer[23:0], rx_data};
                            byte_count <= 32'h0;
                            word_buffer <= 32'h0;
                            byte_index <= 2'h0;
                        end
                    end
                end
                
                BOOT_LOAD_DATA: begin
                    timeout_counter <= timeout_counter + 1;
                    if (rx_valid && rx_ready) begin
                        word_buffer <= {word_buffer[23:0], rx_data};
                        byte_index <= byte_index + 1;
                        bytes_loaded <= bytes_loaded + 1;
                        timeout_counter <= 32'h0;
                        
                        // Write complete word to memory
                        if (byte_index == 3) begin
                            mem_addr <= program_addr;
                            mem_wdata <= {word_buffer[23:0], rx_data};
                            mem_we <= 1'b1;
                            mem_req <= 1'b1;
                            program_addr <= program_addr + 4;
                            byte_index <= 2'h0;
                            word_buffer <= 32'h0;
                        end
                    end
                end
                
                BOOT_VERIFY: begin
                    // Send completion acknowledgment
                    tx_data <= 8'hAA; // Success code
                    tx_valid <= 1'b1;
                end
                
                BOOT_COMPLETE: begin
                    boot_complete <= 1'b1;
                end
                
                BOOT_ERROR: begin
                    boot_error <= 1'b1;
                    // Send error code
                    tx_data <= 8'hFF; // Error code
                    tx_valid <= 1'b1;
                end
            endcase
        end
    end
    
    // Ready signal for UART receiver
    assign rx_ready = (current_state != BOOT_IDLE) && (current_state != BOOT_COMPLETE) && (current_state != BOOT_ERROR);

endmodule

// Simple UART receiver module
module uart_rx #(
    parameter CLOCK_FREQ = 40000000,
    parameter BAUD_RATE = 115200
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,
    output reg  [7:0] data,
    output reg        valid,
    input  wire       ready
);

    localparam BAUD_DIV = CLOCK_FREQ / BAUD_RATE;
    localparam HALF_BAUD_DIV = BAUD_DIV / 2;
    
    typedef enum logic [2:0] {
        RX_IDLE,
        RX_START,
        RX_DATA,
        RX_STOP
    } rx_state_t;
    
    rx_state_t state;
    reg [15:0] baud_counter;
    reg [2:0] bit_counter;
    reg [7:0] shift_reg;
    reg rx_sync[2:0];
    
    // Synchronize RX input
    always @(posedge clk) begin
        rx_sync[0] <= rx;
        rx_sync[1] <= rx_sync[0];
        rx_sync[2] <= rx_sync[1];
    end
    
    wire rx_stable = rx_sync[2];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= RX_IDLE;
            baud_counter <= 16'h0;
            bit_counter <= 3'h0;
            shift_reg <= 8'h0;
            data <= 8'h0;
            valid <= 1'b0;
        end else begin
            valid <= 1'b0;
            
            case (state)
                RX_IDLE: begin
                    if (!rx_stable) begin  // Start bit detected
                        state <= RX_START;
                        baud_counter <= HALF_BAUD_DIV;
                    end
                end
                
                RX_START: begin
                    baud_counter <= baud_counter - 1;
                    if (baud_counter == 0) begin
                        if (!rx_stable) begin  // Validate start bit
                            state <= RX_DATA;
                            baud_counter <= BAUD_DIV;
                            bit_counter <= 3'h0;
                        end else begin
                            state <= RX_IDLE;  // False start
                        end
                    end
                end
                
                RX_DATA: begin
                    baud_counter <= baud_counter - 1;
                    if (baud_counter == 0) begin
                        shift_reg <= {rx_stable, shift_reg[7:1]};
                        bit_counter <= bit_counter + 1;
                        baud_counter <= BAUD_DIV;
                        if (bit_counter == 7) begin
                            state <= RX_STOP;
                        end
                    end
                end
                
                RX_STOP: begin
                    baud_counter <= baud_counter - 1;
                    if (baud_counter == 0) begin
                        if (rx_stable) begin  // Valid stop bit
                            data <= shift_reg;
                            valid <= 1'b1;
                        end
                        state <= RX_IDLE;
                    end
                end
            endcase
        end
    end

endmodule

// Simple UART transmitter module
module uart_tx #(
    parameter CLOCK_FREQ = 40000000,
    parameter BAUD_RATE = 115200
) (
    input  wire       clk,
    input  wire       rst_n,
    output reg        tx,
    input  wire [7:0] data,
    input  wire       valid,
    output reg        ready
);

    localparam BAUD_DIV = CLOCK_FREQ / BAUD_RATE;
    
    typedef enum logic [2:0] {
        TX_IDLE,
        TX_START,
        TX_DATA,
        TX_STOP
    } tx_state_t;
    
    tx_state_t state;
    reg [15:0] baud_counter;
    reg [2:0] bit_counter;
    reg [7:0] shift_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= TX_IDLE;
            baud_counter <= 16'h0;
            bit_counter <= 3'h0;
            shift_reg <= 8'h0;
            tx <= 1'b1;
            ready <= 1'b1;
        end else begin
            case (state)
                TX_IDLE: begin
                    tx <= 1'b1;
                    ready <= 1'b1;
                    if (valid) begin
                        shift_reg <= data;
                        state <= TX_START;
                        baud_counter <= BAUD_DIV;
                        ready <= 1'b0;
                    end
                end
                
                TX_START: begin
                    tx <= 1'b0;  // Start bit
                    baud_counter <= baud_counter - 1;
                    if (baud_counter == 0) begin
                        state <= TX_DATA;
                        baud_counter <= BAUD_DIV;
                        bit_counter <= 3'h0;
                    end
                end
                
                TX_DATA: begin
                    tx <= shift_reg[0];
                    baud_counter <= baud_counter - 1;
                    if (baud_counter == 0) begin
                        shift_reg <= {1'b0, shift_reg[7:1]};
                        bit_counter <= bit_counter + 1;
                        baud_counter <= BAUD_DIV;
                        if (bit_counter == 7) begin
                            state <= TX_STOP;
                        end
                    end
                end
                
                TX_STOP: begin
                    tx <= 1'b1;  // Stop bit
                    baud_counter <= baud_counter - 1;
                    if (baud_counter == 0) begin
                        state <= TX_IDLE;
                    end
                end
            endcase
        end
    end

endmodule 