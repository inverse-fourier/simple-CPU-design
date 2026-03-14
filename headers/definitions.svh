`ifndef DEFINITIONS_SVH
`define DEFINITIONS_SVH

// Instruction Opcodes
typedef enum logic [4:0] {

    /*********** Arithematic instructions ***********/
    MOVSGPR = 5'b00000,
    MOV     = 5'b00001,
    ADD     = 5'b00010,
    SUB     = 5'b00011,
    MUL     = 5'b00100,



/********** Logical instructions ***********/

    OR_op      = 5'b00101,
    AND_op     = 5'b00110,
    XOR_op     = 5'b00111,
    XNOR_op    = 5'b01000,
    NAND_op    = 5'b01001,
    NOR_op     = 5'b01010,
    NOT_op     = 5'b01011,

    /******** Load and Store instructions ********/
    STORE   = 5'b01100,  // Store content of register in data memory    (REG ----> MEM)
    IN      = 5'b01101,  // Load content of din bus in data memory      (DIN ----> MEM)
    OUT     = 5'b01110,  // Store content of data memory to dout bus    (MEM ----> DOUT)
    LOAD    = 5'b01111 // Load content of data memory in register     (MEM ----> REG)

    } op_t;

// Instruction Field Macros
`define rdst(instr)      (instr[26:22])
`define rsrc1(instr)     (instr[21:17])
`define imm_mode(instr)  (instr[16])
`define rsrc2(instr)     (instr[15:11])
`define isrc(instr)      (instr[3:0])

`endif // DEFINITIONS_SVH

