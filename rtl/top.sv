`include "definitions.svh"
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
    logic [7:0] StatusReg;     // Status Register [3:Carry, 2:Overflow 1:Zero, 0:Sign]

    // Intermediate signals
    logic [15:0] alu_out;
    logic [31:0] mul_temp;
    logic [16:0] carry_check;
    logic ov_flag,s_flag,z_flag,c_flag;
    logic update_flags;


    // --- 4. Operands ---
    logic [15:0] op_a,op_b;
    assign op_a = GPR[`rsrc1(IR)];
    assign op_b = (`imm_mode(IR)) ? `isrc(IR) : GPR[`rsrc2(IR)];

    // --- 5. Combinational ALU ---
    // Logic calculates based on current inputs
    // [Image of ALU with control unit and registers]
    always_comb begin
        // Default assignments to prevent latches
        alu_out  = 16'b0;
        mul_temp = 32'b0;
        carry_check = 17'b0;
        ov_flag = 1'b0;
        update_flags = 1'b1; //Most instructions update flags
        

        case (instr_op)

            /*********** Arithematic instructions ***********/
            MOVSGPR: begin 
                alu_out = SGPR;
                update_flags = 1'b0;
            end 
            
            MOV:     begin 
                alu_out = op_b;
                update_flags = 1'b0;
            end 
            
            ADD:     begin
                carry_check = {1'b0,op_a} + {1'b0,op_b};
                alu_out = carry_check[15:0];
                ov_flag = (op_a[15] == op_b[15]) & (op_a[15] != alu_out[15]);
            end 
            
            SUB:     begin
                carry_check = {1'b0,op_a} - {1'b0,op_b};
                alu_out = carry_check[15:0];
                ov_flag = (op_a[15] != op_b[15]) & (op_a[15] != alu_out[15]);
            end 
            
            MUL: begin
                mul_temp = (`imm_mode(IR)) ? (GPR[`rsrc1(IR)] * `isrc(IR)) : (GPR[`rsrc1(IR)] * GPR[`rsrc2(IR)]);
                alu_out  = mul_temp[15:0];
            end

            /********** Logical instructions ***********/
            OR_op:   alu_out = op_a | op_b;

            AND_op:  alu_out = op_a & op_b;

            XOR_op:  alu_out = op_a ^ op_b;

            XNOR_op: alu_out = ~(op_a ^ op_b);

            NAND_op: alu_out = ~(op_a & op_b);

            NOR_op:  alu_out = ~(op_a | op_b);
            
            NOT_op:  alu_out = ~op_a;
            
            default: begin 
                alu_out = 16'b0;
                update_flags = 1'b0;
            end 
        endcase

        s_flag = alu_out[15];
        z_flag = (alu_out == 16'b0);
        c_flag = carry_check[16];
    end

    // --- 7. Sequential Register File ---
    // Values are "saved" only on the rising clock edge
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all 32 registers and SGPR
            for (int i = 0; i < 32; i++) GPR[i] <= 16'h0000;
            SGPR <= 16'h0000;
            StatusReg <= 4'b0000;
        end else begin
            // Write ALU result to the destination register
            GPR[`rdst(IR)] <= alu_out;
            
            // If the instruction was a Multiply, update the Special Register
            if (instr_op == MUL) SGPR <= mul_temp[31:16];

            // Update Status Register
            if(update_flags) StatusReg <= {ov_flag,s_flag,z_flag,c_flag};

        end
    end

endmodule

