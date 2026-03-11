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
        // 1. MOV R1, #10
        $fdisplay(mem_file, "%32b", {MOV, 5'd1, 5'd0, 1'b1, 16'd10});
        // 2. MOV R2, #20
        $fdisplay(mem_file, "%32b", {MOV, 5'd2, 5'd0, 1'b1, 16'd20});
        // 3. ADD R3, R1, R2  (R3 = R1 + R2 = 30)
        $fdisplay(mem_file, "%32b", {ADD, 5'd3, 5'd1, 1'b0, 5'd2, 11'b0});
        // 4. SUB R4, R3, R1  (R4 = R3 - R1 = 20)
        $fdisplay(mem_file, "%32b", {SUB, 5'd4, 5'd3, 1'b0, 5'd1, 11'b0});
        // 5. MUL R5, R1, R2 (R5 = R1 * R2 = 200)
        $fdisplay(mem_file, "%32b", {MUL, 5'd5, 5'd1, 1'b0, 5'd2, 11'b0});
        // 6. STORE R5, [10] (Store 200 at address 10)
        $fdisplay(mem_file, "%32b", {STORE, 5'd0, 5'd5, 1'b1, 16'd10});
        // 7. LOAD R6, [10] (Load value from address 10 into R6)
        $fdisplay(mem_file, "%32b", {LOAD, 5'd6, 5'd0, 1'b1, 16'd10});

        $fclose(mem_file);
    end

    // --- Main Test Sequence ---
    initial begin
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
        $display("\nTime(ns)| PC | Instr(h) | Cycle |  R1  |  R2  |  R3  |  R4  |  R5  |  R6  | alu_reg | statusReg");
        $display("-------------------------------------------------------------------------------------------------");
    end

    always @(posedge clk) begin
        if (rst_n) begin
            // Use $strobe to display values after they have been updated in the current timestep
            $strobe("%7d | %2d | %8h | %5d | %2h | %2h | %2h | %2h | %2h | %2h | %7h | %4b",
                     $time, dut.PC, dut.IR, dut.cycleCount,
                     dut.GPR[1], dut.GPR[2], dut.GPR[3], dut.GPR[4], dut.GPR[5], dut.GPR[6],
                     dut.alu_reg, dut.statusReg);
        end
    end

endmodule
