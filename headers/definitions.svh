`ifndef DEFINITIONS_SVH
`define DEFINITIONS_SVH

// Instruction Opcodes
typedef enum logic [4:0] {
    MOVSGPR = 5'b00000,
    MOV     = 5'b00001,
    ADD     = 5'b00010,
    SUB     = 5'b00011,
    MUL     = 5'b00100
} op_t;

// Instruction Field Macros
`define rdst(instr)      (instr[26:22])
`define rsrc1(instr)     (instr[21:17])
`define imm_mode(instr)  (instr[16])
`define rsrc2(instr)     (instr[15:11])
`define isrc(instr)      (instr[15:0])

`endif // DEFINITIONS_SVH
