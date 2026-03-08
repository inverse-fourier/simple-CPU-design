`timescale 1ns / 1ps

module top (
    input  logic        clk,    // System Clock
    input  logic        rst_n,  // Active-low Reset
    input  logic [31:0] IR      // Instruction Register
);

    // --- 2. Extract Fields using casting to our new type ---
    op_t        instr_op;
    assign      instr_op = op_t'(IR[31:27]); // Casting bits to our Enum type

    // --- 3. Internal Storage ---
    logic [15:0] GPR [31:0];   // General Purpose Registers
    logic [15:0] SGPR;         // Special Multiplier Register
    
    // Intermediate signals
    logic [15:0] alu_out;
    logic [31:0] mul_temp;

    // --- 4. Combinational ALU ---
    // Logic calculates based on current inputs
    // [Image of ALU with control unit and registers]
    always_comb begin
        // Default assignments to prevent latches
        alu_out  = 16'b0;
        mul_temp = 32'b0;

        case (instr_op)
            MOVSGPR: alu_out = SGPR;
            
            MOV:     alu_out = (`imm_mode(IR)) ? `isrc(IR) : GPR[`rsrc1(IR)];
            
            ADD:     alu_out = (`imm_mode(IR)) ? (GPR[`rsrc1(IR)] + `isrc(IR)) : (GPR[`rsrc1(IR)] + GPR[`rsrc2(IR)]);
            
            SUB:     alu_out = (`imm_mode(IR)) ? (GPR[`rsrc1(IR)] - `isrc(IR)) : (GPR[`rsrc1(IR)] - GPR[`rsrc2(IR)]);
            
            MUL: begin
                mul_temp = (`imm_mode(IR)) ? (GPR[`rsrc1(IR)] * `isrc(IR)) : (GPR[`rsrc1(IR)] * GPR[`rsrc2(IR)]);
                alu_out  = mul_temp[15:0];
            end
            
            default: alu_out = 16'b0;
        endcase
    end

    // --- 5. Sequential Register File ---
    // Values are "saved" only on the rising clock edge
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all 32 registers and SGPR
            for (int i = 0; i < 32; i++) GPR[i] <= 16'h0000;
            SGPR <= 16'h0000;
        end else begin
            // Write ALU result to the destination register
            GPR[`rdst(IR)] <= alu_out;
            
            // If the instruction was a Multiply, update the Special Register
            if (instr_op == MUL) begin
                SGPR <= mul_temp[31:16];
            end
        end
    end

endmodule