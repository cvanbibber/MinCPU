# Makefile for C compilation targeting MinCPU RISC-V processor
# Supports RV32IMC instruction set

# Toolchain Configuration
# Use riscv64-unknown-elf toolchain (available on this system)
CROSS_PREFIX = riscv64-unknown-elf-
CC = $(CROSS_PREFIX)gcc
AS = $(CROSS_PREFIX)as
LD = $(CROSS_PREFIX)ld
OBJCOPY = $(CROSS_PREFIX)objcopy
OBJDUMP = $(CROSS_PREFIX)objdump
SIZE = $(CROSS_PREFIX)size

# Alternative toolchain (if riscv32-unknown-elf- becomes available)
# CROSS_PREFIX = riscv32-unknown-elf-
# CC = $(CROSS_PREFIX)gcc
# AS = $(CROSS_PREFIX)as
# LD = $(CROSS_PREFIX)ld

# Target Configuration
ARCH = rv32imc
ABI = ilp32
TARGET_FREQ = 40000000  # 40 MHz

# Compiler Flags
CFLAGS = -march=$(ARCH) -mabi=$(ABI) -O2 -g -Wall -Wextra
CFLAGS += -fno-builtin -nostdlib -nostartfiles
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -DTARGET_FREQ=$(TARGET_FREQ)

# Assembler Flags
ASFLAGS = -march=$(ARCH) -mabi=$(ABI) -g

# Linker Flags
LDFLAGS = -march=$(ARCH) -mabi=$(ABI) -T mincpu.ld -nostdlib -nostartfiles
LDFLAGS += -Wl,--gc-sections -Wl,--print-memory-usage -Wl,-melf32lriscv

# Source Files
C_SOURCES = hello.c
ASM_SOURCES = start.S
LINKER_SCRIPT = mincpu.ld

# Benchmark Sources
DHRYSTONE_SOURCES = dhrystone.c
WHETSTONE_SOURCES = whetstone.c

# Object Files
C_OBJECTS = $(C_SOURCES:.c=.o)
ASM_OBJECTS = $(ASM_SOURCES:.S=.o)
ALL_OBJECTS = $(ASM_OBJECTS) $(C_OBJECTS)

# Benchmark Object Files
DHRYSTONE_OBJECTS = start.o dhrystone.o
WHETSTONE_OBJECTS = start.o whetstone.o

# Output Files
TARGET = hello
ELF_FILE = $(TARGET).elf
BIN_FILE = $(TARGET).bin
HEX_FILE = $(TARGET).hex
MAP_FILE = $(TARGET).map
DUMP_FILE = $(TARGET).dump

# Benchmark Output Files
DHRYSTONE_ELF = dhrystone.elf
DHRYSTONE_BIN = dhrystone.bin
DHRYSTONE_DUMP = dhrystone.dump
DHRYSTONE_IMEM = dhrystone_imem.v
DHRYSTONE_DMEM = dhrystone_dmem.v

WHETSTONE_ELF = whetstone.elf
WHETSTONE_BIN = whetstone.bin
WHETSTONE_DUMP = whetstone.dump
WHETSTONE_IMEM = whetstone_imem.v
WHETSTONE_DMEM = whetstone_dmem.v

# Verilog Memory Files
IMEM_FILE = $(TARGET)_imem.v
DMEM_FILE = $(TARGET)_dmem.v

# Default target
.PHONY: all
all: $(ELF_FILE) $(BIN_FILE) $(HEX_FILE) $(DUMP_FILE) memory_files

# Benchmark targets
.PHONY: benchmarks
benchmarks: dhrystone whetstone

.PHONY: dhrystone
dhrystone: $(DHRYSTONE_ELF) $(DHRYSTONE_BIN) $(DHRYSTONE_DUMP) dhrystone_memory_files

.PHONY: whetstone  
whetstone: $(WHETSTONE_ELF) $(WHETSTONE_BIN) $(WHETSTONE_DUMP) whetstone_memory_files

# Compile C sources
%.o: %.c
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) -c $< -o $@

# Assemble assembly sources
%.o: %.S
	@echo "Assembling $<..."
	$(CC) $(CFLAGS) $(ASFLAGS) -c $< -o $@

# Link to create ELF file
$(ELF_FILE): $(ALL_OBJECTS) $(LINKER_SCRIPT)
	@echo "Linking $(ELF_FILE)..."
	$(CC) $(LDFLAGS) -Wl,-Map=$(MAP_FILE) $(ALL_OBJECTS) -o $@
	$(SIZE) $@

# Link Dhrystone benchmark
$(DHRYSTONE_ELF): $(DHRYSTONE_OBJECTS) $(LINKER_SCRIPT)
	@echo "Linking Dhrystone benchmark..."
	$(CC) $(LDFLAGS) -Wl,-Map=dhrystone.map $(DHRYSTONE_OBJECTS) -o $@
	$(SIZE) $@

# Link Whetstone benchmark
$(WHETSTONE_ELF): $(WHETSTONE_OBJECTS) $(LINKER_SCRIPT)
	@echo "Linking Whetstone benchmark..."
	$(CC) $(LDFLAGS) -Wl,-Map=whetstone.map $(WHETSTONE_OBJECTS) -o $@
	$(SIZE) $@

# Create binary file
$(BIN_FILE): $(ELF_FILE)
	@echo "Creating binary file..."
	$(OBJCOPY) -O binary $< $@

# Create benchmark binary files
$(DHRYSTONE_BIN): $(DHRYSTONE_ELF)
	@echo "Creating Dhrystone binary file..."
	$(OBJCOPY) -O binary $< $@

$(WHETSTONE_BIN): $(WHETSTONE_ELF)
	@echo "Creating Whetstone binary file..."
	$(OBJCOPY) -O binary $< $@

# Create hex file
$(HEX_FILE): $(ELF_FILE)
	@echo "Creating hex file..."
	$(OBJCOPY) -O ihex $< $@

# Create disassembly
$(DUMP_FILE): $(ELF_FILE)
	@echo "Creating disassembly..."
	$(OBJDUMP) -D -S $< > $@

# Create benchmark disassemblies
$(DHRYSTONE_DUMP): $(DHRYSTONE_ELF)
	@echo "Creating Dhrystone disassembly..."
	$(OBJDUMP) -D -S $< > $@

$(WHETSTONE_DUMP): $(WHETSTONE_ELF)
	@echo "Creating Whetstone disassembly..."
	$(OBJDUMP) -D -S $< > $@

# Generate Verilog memory files
.PHONY: memory_files
memory_files: $(BIN_FILE)
	@echo "Generating Verilog memory files..."
	@python bin2verilog.py $(BIN_FILE) $(IMEM_FILE) $(DMEM_FILE) 2>nul || python3 bin2verilog.py $(BIN_FILE) $(IMEM_FILE) $(DMEM_FILE)

.PHONY: dhrystone_memory_files
dhrystone_memory_files: $(DHRYSTONE_BIN)
	@echo "Generating Dhrystone Verilog memory files..."
	@python bin2verilog.py $(DHRYSTONE_BIN) $(DHRYSTONE_IMEM) $(DHRYSTONE_DMEM) 2>nul || python3 bin2verilog.py $(DHRYSTONE_BIN) $(DHRYSTONE_IMEM) $(DHRYSTONE_DMEM)

.PHONY: whetstone_memory_files
whetstone_memory_files: $(WHETSTONE_BIN)
	@echo "Generating Whetstone Verilog memory files..."
	@python bin2verilog.py $(WHETSTONE_BIN) $(WHETSTONE_IMEM) $(WHETSTONE_DMEM) 2>nul || python3 bin2verilog.py $(WHETSTONE_BIN) $(WHETSTONE_IMEM) $(WHETSTONE_DMEM)

# Test compilation with different optimization levels
.PHONY: test_optimization
test_optimization:
	@echo "Testing different optimization levels..."
	@for opt in O0 O1 O2 O3 Os; do \
		echo "Building with -$$opt..."; \
		$(MAKE) clean; \
		$(MAKE) CFLAGS="-march=$(ARCH) -mabi=$(ABI) -$$opt -g -Wall -Wextra -fno-builtin -nostdlib -nostartfiles -ffunction-sections -fdata-sections" all; \
		mv $(ELF_FILE) $(TARGET)_$$opt.elf; \
		$(SIZE) $(TARGET)_$$opt.elf; \
	done

# Check toolchain availability
.PHONY: check_toolchain
check_toolchain:
	@echo "Checking RISC-V toolchain..."
	@which $(CC) > /dev/null 2>&1 || (echo "Error: $(CC) not found. Please install RISC-V toolchain."; exit 1)
	@$(CC) --version | head -1
	@echo "Toolchain check passed."

# Analyze generated code
.PHONY: analyze
analyze: $(DUMP_FILE)
	@echo "Code Analysis:"
	@echo "=============="
	@echo "Text section size:"
	@$(SIZE) $(ELF_FILE) | tail -1 | awk '{print $$1 " bytes"}'
	@echo ""
	@echo "Instruction count estimate:"
	@grep -c "^\s*[0-9a-f]\+:" $(DUMP_FILE) || echo "0"
	@echo ""
	@echo "RV32M instructions used:"
	@grep -E "(mul|div|rem)" $(DUMP_FILE) | wc -l || echo "0"
	@echo ""
	@echo "RV32C instructions used:"
	@grep -E "c\." $(DUMP_FILE) | wc -l || echo "0"

# Analyze benchmark programs
.PHONY: analyze_benchmarks
analyze_benchmarks: dhrystone whetstone
	@echo "Benchmark Analysis:"
	@echo "==================="
	@echo ""
	@echo "Dhrystone Benchmark:"
	@echo "  Text section size: $$($(SIZE) $(DHRYSTONE_ELF) | tail -1 | awk '{print $$1}') bytes"
	@echo "  Instruction count: $$(grep -c "^\s*[0-9a-f]\+:" $(DHRYSTONE_DUMP) || echo "0")"
	@echo "  RV32M instructions: $$(grep -E "(mul|div|rem)" $(DHRYSTONE_DUMP) | wc -l || echo "0")"
	@echo "  RV32C instructions: $$(grep -E "c\." $(DHRYSTONE_DUMP) | wc -l || echo "0")"
	@echo ""
	@echo "Whetstone Benchmark:"
	@echo "  Text section size: $$($(SIZE) $(WHETSTONE_ELF) | tail -1 | awk '{print $$1}') bytes"
	@echo "  Instruction count: $$(grep -c "^\s*[0-9a-f]\+:" $(WHETSTONE_DUMP) || echo "0")"
	@echo "  RV32M instructions: $$(grep -E "(mul|div|rem)" $(WHETSTONE_DUMP) | wc -l || echo "0")"
	@echo "  RV32C instructions: $$(grep -E "c\." $(WHETSTONE_DUMP) | wc -l || echo "0")"

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	@if exist *.o del /q *.o
	@if exist *.elf del /q *.elf
	@if exist *.bin del /q *.bin
	@if exist *.hex del /q *.hex
	@if exist *.map del /q *.map
	@if exist *.dump del /q *.dump
	@if exist *.v del /q *.v
	@if exist $(TARGET)_O*.elf del /q $(TARGET)_O*.elf

# Help target
.PHONY: help
help:
	@echo "MinCPU C Compilation Makefile"
	@echo "============================="
	@echo ""
	@echo "Main Targets:"
	@echo "  all              - Build all output files"
	@echo "  benchmarks       - Build Dhrystone and Whetstone benchmarks"
	@echo "  dhrystone        - Build Dhrystone benchmark"
	@echo "  whetstone        - Build Whetstone benchmark"
	@echo ""
	@echo "Analysis Targets:"
	@echo "  check_toolchain  - Verify RISC-V toolchain installation"
	@echo "  test_optimization - Test different optimization levels"
	@echo "  analyze          - Analyze generated code"
	@echo "  analyze_benchmarks - Analyze benchmark programs"
	@echo "  memory_files     - Generate Verilog memory files"
	@echo ""
	@echo "Utility Targets:"
	@echo "  clean            - Remove build artifacts"
	@echo "  help             - Show this help"
	@echo ""
	@echo "Configuration:"
	@echo "  ARCH=$(ARCH)     - RISC-V architecture"
	@echo "  ABI=$(ABI)       - RISC-V ABI"
	@echo "  TARGET_FREQ=$(TARGET_FREQ) - Target frequency in Hz"
	@echo ""
	@echo "Main Output files:"
	@echo "  $(ELF_FILE)      - Executable ELF file"
	@echo "  $(BIN_FILE)      - Raw binary file"
	@echo "  $(HEX_FILE)      - Intel HEX file"
	@echo "  $(DUMP_FILE)     - Disassembly listing"
	@echo "  $(IMEM_FILE)     - Instruction memory Verilog"
	@echo "  $(DMEM_FILE)     - Data memory Verilog"
	@echo ""
	@echo "Benchmark Output files:"
	@echo "  $(DHRYSTONE_ELF) - Dhrystone benchmark ELF file"
	@echo "  $(DHRYSTONE_BIN) - Dhrystone benchmark binary file"
	@echo "  $(DHRYSTONE_DUMP) - Dhrystone benchmark disassembly"
	@echo "  $(DHRYSTONE_IMEM) - Dhrystone benchmark instruction memory Verilog"
	@echo "  $(DHRYSTONE_DMEM) - Dhrystone benchmark data memory Verilog"
	@echo "  $(WHETSTONE_ELF) - Whetstone benchmark ELF file"
	@echo "  $(WHETSTONE_BIN) - Whetstone benchmark binary file"
	@echo "  $(WHETSTONE_DUMP) - Whetstone benchmark disassembly"
	@echo "  $(WHETSTONE_IMEM) - Whetstone benchmark instruction memory Verilog"
	@echo "  $(WHETSTONE_DMEM) - Whetstone benchmark data memory Verilog"

# Dependencies
$(ALL_OBJECTS): Makefile.c
$(ELF_FILE): $(LINKER_SCRIPT) 