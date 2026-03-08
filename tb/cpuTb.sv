`include "definitions.svh"
`timescale 1ns / 1ps

module cpuTb;

    // --- Waveform Dumping ---
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, cpuTb.dut);
    end

    // --- Signals ---
    logic        clk;
    logic        rst_n;
    logic [31:0] IR;

    // --- DUT Instantiation ---
    top dut (
        .clk(clk),
        .rst_n(rst_n),
        .IR(IR)
    );

    // --- Clock Generation ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --- Stimulus Task ---
    task apply_instruction(input [31:0] instr);
        op_t opcode;
        @(negedge clk);
        IR = instr;
        opcode = op_t'(instr[31:27]);
        $display("\nApplied instruction: %s", opcode.name());
    endtask

    // --- Main Test Sequence ---
    initial begin
        // --- Reset ---
        rst_n = 1;
        IR = 32'b0;
        #2;
        rst_n = 0;
        #10;
        rst_n = 1;
        $display("Reset released");

        // --- Test Instructions ---
        // 1. MOV R1, #10
        apply_instruction({MOV, 5'd1, 5'd0, 1'b1, 16'd10});

        // 2. MOV R2, #20
        apply_instruction({MOV, 5'd2, 5'd0, 1'b1, 16'd20});
        
        // 3. ADD R3, R1, R2  (R3 = R1 + R2 = 30)
        apply_instruction({ADD, 5'd3, 5'd1, 1'b0, 5'd2, 11'b0});
        
        // 4. SUB R4, R3, R1  (R4 = R3 - R1 = 20)
        apply_instruction({SUB, 5'd4, 5'd3, 1'b0, 5'd1, 11'b0});
        
        // 5. MUL R5, R1, R2 (R5 = R1 * R2 = 200)
        apply_instruction({MUL, 5'd5, 5'd1, 1'b0, 5'd2, 11'b0});
        
        // 6. MOVSGPR R6 (Move from SGPR to R6)
        apply_instruction({MOVSGPR, 5'd6, 22'b0});

        // 7. OR R1, #40
        apply_instruction({OR_op, 5'd1, 5'd0, 1'b1, 16'd40});

        // 8. AND R2, #20
        apply_instruction({AND_op, 5'd2, 5'd0, 1'b1, 16'd20});

        // 9. XOR R3, R1, R2
        apply_instruction({XOR_op, 5'd3, 5'd1, 1'b0, 5'd2, 11'b0});

        // 10. XNOR R4, R3, R1
        apply_instruction({XNOR_op, 5'd4, 5'd3, 1'b0, 5'd1, 11'b0});

        // 11. NAND R5, R1, R2
        apply_instruction({NAND_op, 5'd5, 5'd1, 1'b0, 5'd2, 11'b0});

        // 12. NOR R6, R1, R2
        apply_instruction({NOR_op, 5'd6, 5'd1, 1'b0, 5'd2, 11'b0});

        // 13. NOT R1
        apply_instruction({NOT_op, 5'd1, 5'd0, 1'b1, 16'd4000});
        // Add some delay to let the last instruction complete
        #20;

        // --- Finish Simulation ---
        $display("Simulation finished.");
        $finish;
    end

    // --- Monitoring ---
    initial begin
        // Wait for reset to de-assert before printing header
        @(posedge rst_n);
        $display("\n      Time | R1(h) | R2(h) | R3(h) | R4(h) | R5(h) | R6(h) | ALU_OUT(h) | SGPR(h)");
        $display("-----------|-------|-------|-------|-------|-------|-------|------------|---------");
    end

    always @(posedge clk) begin
        if (rst_n) begin
            // Use $strobe to display values after they have been updated in the current timestep
            $strobe("T=%8t | %5h | %5h | %5h | %5h | %5h | %5h | %10h | %7h",
                     $time, dut.GPR[1], dut.GPR[2], dut.GPR[3], dut.GPR[4], dut.GPR[5], dut.GPR[6], dut.alu_out, dut.SGPR);
        end
    end

endmodule


