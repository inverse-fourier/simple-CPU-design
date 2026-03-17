`include "definitions.svh"
`timescale 1ns/1ps 

module top(
    input   logic           clk,
    input   logic           rst_n,
    input   logic [15:0]    dataIn,
    output  logic [15:0]    dataOut
);

    // 1. ---- Storage Eements ---- //
    logic [31:0]    instMem [15:0];     // Instruction memory
    logic [15:0]    dataMem [15:0];     // Data memory]
    logic [15:0]    GPR     [31:0];         // General Purpose Registers]
    logic [15:0]    SGPR;               // Special Purpose Register

    // statusReg bits: [3]:Carry, [2]:Zero, [1]:Overflow, [0]:Sign
    logic [3:0]     statusReg;    

    // Temporary latches for Carry/Overflow (calculated only during Execute)
    logic           c_latch, ov_latch;

    // 2. ---- Pipeline/state Registers
    logic [31:0]    IR;                 // Instruction Register
    logic [3:0]     PC;                 // Program Counter
    logic [2:0]     cycleCount;         // Cycle Counter
    logic [15:0]    op_a,op_b;          // Latched Operands
    logic [15:0]    alu_reg;            // Latched ALU Result
    logic [31:0]    mul_reg;            // Latched Multiplier Result

    // --- ALU Combinational wires
    logic [15:0] aluResultWire;
    logic [31:0] mulResultWire;
    logic carryWire;
    logic overflowWire;

    initial begin : READ_INSTRUCTIONS
        #1; // Delay to allow testbench to write the memory file
        $readmemb("instructionData.mem", instMem,  0, 3);
    end : READ_INSTRUCTIONS

    localparam logic [2:0] FETCH = 0 , DECODE = 1, EXECUTE = 2, MEMORY = 3, WRITEBACK = 4;

    op_t instr_op;
    assign instr_op = op_t'(IR[31:27]);

    // 3. --- Combinational ALU core (For Mathematics)
    always_comb begin : ALU_CORE
        aluResultWire   = 16'h0000;
        mulResultWire   = 32'h00000000;
        carryWire       = 1'b0;
        overflowWire    = 1'b0;

        case(instr_op)
            MOV     :   aluResultWire = op_b;
            MOVSGPR :   aluResultWire = SGPR;

            ADD     :   begin
                        {carryWire,aluResultWire} = op_a + op_b;
                        overflowWire = (op_a[15] == op_b[15]) && (op_a[15] != aluResultWire[15]);
            end

            SUB     :   begin
                        {carryWire,aluResultWire} = op_a - op_b;
                        overflowWire = (op_a[15] != op_b[15]) && (op_a[15] == aluResultWire[15]);
            end

            MUL     :   begin
                        mulResultWire = op_a * op_b;
                        aluResultWire = mulResultWire[15:0];
            end

            OR_op   :   aluResultWire = op_a | op_b; 
            AND_op  :   aluResultWire = op_a & op_b; 
            XOR_op  :   aluResultWire = op_a ^ op_b;
            XNOR_op :   aluResultWire = ~(op_a ^ op_b);
            NAND_op :   aluResultWire = ~(op_a & op_b); 
            NOR_op  :   aluResultWire = ~(op_a | op_b); 
            NOT_op  :   aluResultWire = ~op_a; 
            default :   aluResultWire = 16'h0000;

        endcase 

    end : ALU_CORE


    // 4. ---- Segregated State Machine ----

    always_ff @( posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // --- Control State Reseter --- //
            cycleCount  <= FETCH;
            PC          <= 4'h0;
            IR          <= 32'h00000000;

            // --- Internal Pipeline Registers Reset --- //
            op_a        <= 16'h0000;
            op_b        <= 16'h0000;
            alu_reg     <= 16'h0000;
            mul_reg     <= 32'h00000000;

            // Status latches reset
            c_latch      <= 0;
            ov_latch     <= 0;

            // --- Architecture State Reset --- //
            dataOut     <= 16'h0000;
            statusReg   <= 4'h0;
            SGPR        <= 16'h0000;

            for(int i = 0 ; i < 32 ; i++) GPR[i] <= 16'h0000;

        end else begin
            case (cycleCount)
                // Cycle 0 : FETCH
                FETCH : begin
                    IR          <= instMem[PC];
                    cycleCount  <= DECODE;
                end

                // Cycle 1 : DECODE
                DECODE : begin 
                    op_a        <= GPR[`rsrc1(IR)];
                    op_b        <= `imm_mode(IR) ? `isrc(IR) : GPR[`rsrc2(IR)];
                    cycleCount  <= EXECUTE;
                end 

                // Cycle 2 : EXECUTE (ALU)
                EXECUTE : begin
                    alu_reg <= aluResultWire;
                    mul_reg <= mulResultWire;       
                    c_latch <= carryWire;
                    ov_latch <= overflowWire;
                    
                    cycleCount <= MEMORY;
                end 

                // Cycle 3 : MEMORY
                MEMORY : begin  
                    case(instr_op)
                        IN      : dataMem[`isrc(IR)] <= dataIn;
                        OUT     : dataOut <= dataMem[`isrc(IR)];
                        LOAD    : alu_reg <= dataMem[`isrc(IR)];
                        STORE   : dataMem[`isrc(IR)] <= GPR[`rsrc1(IR)];
                    endcase
                    cycleCount <= WRITEBACK;
                end 

                // Cycle 4 : WRITEBACK
                WRITEBACK : begin
                    if(isWriteBackInstruction(instr_op)) begin 
                        GPR[`rdst(IR)] <= alu_reg;

                        // UPDATE STATUS REGISTER DIRECTLY
                        // [3]: Carry (latched)
                        // [2]: Zero (check 32-bit for MUL, 16-bit for others)
                        // [1]: Overflow (latched)
                        // [0]: Sign (check bit 31 for MUL, 15 for others)
                        statusReg[3] <= c_latch;
                        statusReg[2] <= (instr_op == MUL) ? (mul_reg == 32'h0) : (alu_reg == 16'h0);
                        statusReg[1] <= ov_latch;
                        statusReg[0] <= (instr_op == MUL) ? mul_reg[31] : alu_reg[15];
                    end 
            
                    if(instr_op == MUL) SGPR <= mul_reg[31:16];

                    // PC Update Logic
                    case(instr_op)
                        JUMP            :                   PC <= `isrc(IR);
                        JMP_CARRY       : if(statusReg[3])  PC <= `isrc(IR); else PC <= PC + 1;
                        JMP_NO_CARRY    : if(!statusReg[3]) PC <= `isrc(IR); else PC <= PC + 1;
                        JMP_ZERO        : if(statusReg[2])  PC <= `isrc(IR); else PC <= PC + 1;
                        JMP_NO_ZERO     : if(!statusReg[2]) PC <= `isrc(IR); else PC <= PC + 1;
                        JMP_SIGN        : if(statusReg[0])  PC <= `isrc(IR); else PC <= PC + 1;
                        JMP_NO_SIGN     : if(!statusReg[0]) PC <= `isrc(IR); else PC <= PC + 1;
                        JMP_OVERFLOW    : if(statusReg[1])  PC <= `isrc(IR); else PC <= PC + 1;
                        JMP_NO_OVERFLOW : if(!statusReg[1]) PC <= `isrc(IR); else PC <= PC + 1;
                        HALT            :                   PC <= PC;
                        default         :                   PC <= PC + 1;
                    endcase
                    
                    cycleCount <= FETCH;
                end 
            endcase
        end 
    end 

    // Helper function to identify instructions that write to GPR
    function automatic logic isWriteBackInstruction(op_t op);
        case(op)
            // Arithmetic & Move
            ADD, SUB, MUL, MOV, MOVSGPR, 
            // Memory Load
            LOAD, 
            // Logical Operations (All must be here)
            AND_op, OR_op, XOR_op, NOT_op, NAND_op, NOR_op, XNOR_op: 
                return 1'b1;
            
            default: 
                return 1'b0;
        endcase
    endfunction     

endmodule




