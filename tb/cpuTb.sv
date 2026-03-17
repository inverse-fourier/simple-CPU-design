`include "definitions.svh"
`timescale 1ns / 1ps

module cpuTb;

    // --- Signals ---
    logic        clk;
    logic        rst_n;
    logic [15:0] dataIn;
    logic [15:0] dataOut;

    // --- DUT Instantiation ---
    top dut (
        .clk(clk),
        .rst_n(rst_n),
        .dataIn(dataIn),
        .dataOut(dataOut)
    );

    // --- Clock Generation ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --- Instruction Memory Generation ---
    integer mem_file;
    initial begin
        // --- Instruction field variables ---
        integer     mem_file;
        op_t        opcode;
        logic [4:0] dest;
        logic [4:0] source1;
        logic [4:0] source2;
        logic       immMode;
        logic [15:0] addr;

        mem_file = $fopen("instructionData.mem", "w");

        // Test Program for Jumps:
        // 1. MOV R0, #5
        opcode  = MOV;
        dest    = 5'd0;
        immMode = 1'b1;
        addr    = 16'd5;
        $fdisplay(mem_file, "%32b", {opcode, dest, 5'b0, immMode, addr});

        // 2. MOV R1, #-5
        opcode  = MOV;
        dest    = 5'd1;
        immMode = 1'b1;
        addr    = 16'hfffb; // -5 in 2's complement
        $fdisplay(mem_file, "%32b", {opcode, dest, 5'b0, immMode, addr});

        // 3. ADD R2, R0, R1 (sets the zero flag)
        opcode  = ADD;
        dest    = 5'd2;
        source1 = 5'd0;
        source2 = 5'd1;
        immMode = 1'b0;
        $fdisplay(mem_file, "%32b", {opcode, dest, source1, immMode, source2, 11'b0});

        // 4. JMP_ZERO to address 6
        opcode  = JMP_ZERO;
        dest    = 5'b0;
        source1 = 5'b0;
        immMode = 1'b1;
        addr    = 16'd6;
        $fdisplay(mem_file, "%32b", {opcode, dest, source1, immMode, addr});

        // 5. Should be skipped
        opcode = ADD;
        dest = 5'd3;
        source1 = 5'd3;
        immMode = 1'b1;
        addr = 16'd1;
        $fdisplay(mem_file, "%32b", {opcode, dest, source1, immMode, addr});

        // 6. Should be skipped
        opcode = ADD;
        dest = 5'd4;
        source1 = 5'd4;
        immMode = 1'b1;
        addr = 16'd1;
        $fdisplay(mem_file, "%32b", {opcode, dest, source1, immMode, addr});

        // 7. HALT
        opcode = HALT;
        $fdisplay(mem_file, "%32b", {opcode, 27'b0});

        // 8. JUMP to 0 (filler)
        opcode = JUMP;
        addr = 16'd0;
        $fdisplay(mem_file, "%32b", {opcode, dest, source1, immMode, addr});


        $fclose(mem_file);
    end

    // --- Main Test Sequence ---
    initial begin
        // Initialize Data Memory
        for (int i = 0; i < 16; i++) dut.dataMem[i] = 16'h0000;

        // --- VCD Dump ---
        $dumpfile("waveform.vcd");
        $dumpvars(0, cpuTb.dut);

        // --- Reset ---
        rst_n = 1;
        dataIn = 16'b0;
        #2;
        rst_n = 0;
        #10;
        rst_n = 1;
        $display("Reset released. Starting program execution.");

        // Let the simulation run for enough cycles to complete the program.
        // Each instruction takes 5 cycles. We have about 7 instructions.
        // Let's run for 50 cycles to be safe.
        #250;

        // --- Finish Simulation ---
        $display("\nSimulation finished.");
        $finish;
    end

    // --- Monitoring ---
    initial begin
        // Wait for reset to de-assert before printing header
        @(posedge rst_n);
        #1; // Allow one cycle for reset to propagate
        $display("\nTime(ns)| PC | Instr(h) | Cycle |   R0   |   R1   |   R2   |  alu_reg  | statusReg | dataMem[0] | dataMem[1] | dataMem[2]");
        $display("------------------------------------------------------------------------------------------------------------------------------------------");
    end

    always @(posedge clk) begin
        if (rst_n) begin
            // Use $strobe to display values after they have been updated in the current timestep
            $strobe("%7d | %2d | %8h | %5d | %6d | %6d | %6d | %9d | %9b | %10d | %10d | %10d",
                     $time, dut.PC, dut.IR, dut.cycleCount,
                     dut.GPR[0], dut.GPR[1], dut.GPR[2],
                     dut.alu_reg, dut.statusReg, dut.dataMem[0], dut.dataMem[1], dut.dataMem[2]);
        end
    end

endmodule
