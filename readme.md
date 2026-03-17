# Simple CPU Design

This is a simple CPU design implemented in SystemVerilog. The CPU has a 5-stage instruction cycle.

## Microarchitecture

The processor has a 5-stage instruction cycle. The stages are:

| Stage       | Description                                                                                             |
|-------------|---------------------------------------------------------------------------------------------------------|
| FETCH       | Fetches the next instruction from the instruction memory using the address in the Program Counter (PC). |
| DECODE      | Decodes the instruction, reads the operands from the register file.                                     |
| EXECUTE     | Performs the arithmetic or logical operation using the ALU.                                             |
| MEMORY      | Accesses the data memory for load and store operations.                                                 |
| WRITEBACK   | Writes the result of the operation back to the register file.                                           |

### Diagram

```
      +---------------------------------------------------------------------------------+
      |                                     CPU                                         |
      |                                                                                 |
      |  +-----------+   +---------------+   +---------------+   +-----------+   +---------+  |
      |  |           |   |               |   |               |   |           |   |         |  |
      |  |  FETCH    |-->|    DECODE     |-->|    EXECUTE    |-->|  MEMORY   |-->|WRITEBACK|  |
      |  |           |   | (Read Regs)   |   |     (ALU)     |   |(Load/Store)|   |(WriteReg)|  |
      |  +-----+-----+   +------+--------+   +------+--------+   +-----+-----+   +----+----+  |
      |        |                 |                 |                 |              |         |
      |        |                 |                 |                 |              |         |
      |  +-----v-----+   +-------v-------+   +-----v---------+   +-----v-----+   +----v----+  |
      |  |Inst Memory|   | Register File |   |     ALU       |   |Data Memory|   |Register |  |
      |  +-----------+   +---------------+   +---------------+   +-----------+   |  File   |  |
      |        ^                                                                +---------+  |
      |        |                                                                      ^       |
      |  +-----+-----+                                                                |       |
      |  |     PC    |<---------------------------------------------------------------+       |
      |  +-----------+                                                                        |
      |                                                                                 |
      +---------------------------------------------------------------------------------+
```

## Instruction Set

The instruction set is defined in `headers/definitions.svh`. It includes:
- Arithmetic instructions (ADD, SUB, MUL)
- Logical instructions (AND, OR, XOR, etc.)
- Memory instructions (LOAD, STORE, IN, OUT)
- Jump instructions (JUMP, JMP_ZERO, etc.)
- a HALT instruction.

## How to Run

This project includes a Makefile that allows you to compile and run the simulation.

- `make compile`: Compiles the SystemVerilog source files.
- `make run`: Runs the simulation.
- `make view`: Opens the waveform in GTKWave.
- `make clean`: Cleans up the build artifacts.

```
