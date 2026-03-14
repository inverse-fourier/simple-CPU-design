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
        mem_file = $fopen("instructionData.mem", "w");

        // Test Program:
        // 1. LOAD R0, [0]
        $fdisplay(mem_file, "%32b", {LOAD, 5'd0, 5'd0, 1'b1, 16'd0});
        // 2. LOAD R1, [1]
        $fdisplay(mem_file, "%32b", {LOAD, 5'd1, 5'd0, 1'b1, 16'd1});
        // 3. ADD R2, R0, R1
        $fdisplay(mem_file, "%32b", {ADD, 5'd2, 5'd0, 1'b0, 5'd1, 11'b0});
        // 4. STORE R3, [2]
        $fdisplay(mem_file, "%32b", {STORE, 5'd0, 5'd2, 1'b1, 16'd2});

        $fclose(mem_file);
    end

    // --- Main Test Sequence ---
    initial begin
        // Initialize Data Memory
        for (int i = 0; i < 16; i++) dut.dataMem[i] = 16'h0000;
        dut.dataMem[0] = 16'h7fff;
        dut.dataMem[1] = 16'h0001;

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
        // Each instruction takes 5 cycles. 7 instructions * 5 cycles = 35 cycles.
        // Add some margin.
        #200;

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
