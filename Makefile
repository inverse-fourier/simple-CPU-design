# Makefile for SystemVerilog CPU Simulation

# --- Tools ---
SIMULATOR := iverilog
RUNTIME   := vvp
VIEWER    := gtkwave

# --- Project Structure ---
RTL_DIR     := rtl
TB_DIR      := tb
INCLUDE_DIR := headers
BUILD_DIR   := build
WAVEFORM_DIR = waveforms

SRC_FILES   := $(RTL_DIR)/top.sv
TB_FILES    := $(TB_DIR)/cpuTb.sv

# --- Simulation Targets ---
TARGET        := $(BUILD_DIR)/sim.out
WAVEFORM_FILE := $(WAVEFORM_DIR)/waveform.vcd

# --- Compiler Flags (for Icarus Verilog) ---
# -g2012 enables SystemVerilog 2012 features.
# -I specifies the include directory for headers.
IVERILOG_FLAGS := -g2012 -I $(INCLUDE_DIR)

# --- Targets ---

.PHONY: all compile run view clean

# Default target: clean, compile, run, and view
all: view

# Compile the SystemVerilog source files
compile: $(TARGET)

$(TARGET): $(SRC_FILES) $(TB_FILES)
	@mkdir -p $(BUILD_DIR)
	@echo "Compiling with $(SIMULATOR)..."
	$(SIMULATOR) $(IVERILOG_FLAGS) -o $@ $(SRC_FILES) $(TB_FILES)

# Run the compiled simulation
run: compile
	@echo "Running simulation..."
	$(RUNTIME) $(TARGET)
	@mv -f waveform.vcd $(WAVEFORM_FILE)

# View the generated waveforms
view: run
	@echo "Opening waveforms in $(VIEWER)..."
	$(VIEWER) $(WAVEFORM_FILE) &

# Clean up generated files
clean:
	@echo "Cleaning up build artifacts..."
	@rm -rf $(BUILD_DIR) 