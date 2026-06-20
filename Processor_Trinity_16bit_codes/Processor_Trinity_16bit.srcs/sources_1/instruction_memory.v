
//  Module  : instruction_memory.v
//  Project : Custom 16-bit Processor
//  Desc    : Instruction Memory (ROM) - stores the program.
//            256 × 16-bit words (expandable via parameter).
//
//  Instruction Encoding (16-bit):
//  ┌──────────┬──────┬──────┬──────┬──────────┐
//  │ [15:12]  │[11:9]│ [8:6]│ [5:3]│  [2:0]   │
//  │  Opcode  │  Rd  │  Rs1 │  Rs2 │ (unused) │
//  └──────────┴──────┴──────┴──────┴──────────┘
//
//  Special Encodings:
//  LDI: [15:12]=1000 | [11:9]=Rd | [8:0]=Immediate (9-bit)
//  JMP: [15:12]=1100 | [11:0]=Target Address (12-bit)
//  BZ : [15:12]=1101 | [11:0]=Target Address
//  BNZ: [15:12]=1110 | [11:0]=Target Address
//  HALT:[15:12]=1111 | [11:0]=don't care
// ============================================================

module instruction_memory #(
    parameter MEM_DEPTH = 256,          // Number of instructions
    parameter INIT_FILE = ""            // Optional .mem init file
) (
    input  wire [11:0] addr,            // PC address
    output wire [15:0] instruction      // Fetched instruction
);

    // ----------------------------------------------------------
    // ROM Array
    // ----------------------------------------------------------
    reg [15:0] mem [0:MEM_DEPTH-1];

    integer i;

    // ----------------------------------------------------------
    // Memory Initialization
    // ----------------------------------------------------------
    initial begin
        // Zero out all memory first
        for (i = 0; i < MEM_DEPTH; i = i + 1)
            mem[i] = 16'h0000;         // Default: NOP (maps to ADD R0,R0,R0)

        // --- Load from file if provided ---
        if (INIT_FILE != "")
            $readmemb(INIT_FILE, mem);
        else begin
            // --------------------------------------------------------
            // Interactive Calculator Program (MMIO)
            // --------------------------------------------------------
            // Init
            mem[0]  = 16'h80FF; // LDI R0, 255 (Switches/LEDs)
            mem[1]  = 16'h82FE; // LDI R1, 254 (Enter Button)
            mem[2]  = 16'h8C00; // LDI R6, 0   (Constant 0)

            // Wait for A (Press)
            mem[3]  = 16'h9440; // LD R2, [R1]
            mem[4]  = 16'hB0B0; // CMP R2, R6
            mem[5]  = 16'hD003; // BZ 3
            mem[6]  = 16'h9600; // LD R3, [R0]
            
            // Wait for A (Release)
            mem[7]  = 16'h9440; // LD R2, [R1]
            mem[8]  = 16'hB0B0; // CMP R2, R6
            mem[9]  = 16'hE007; // BNZ 7

            // Wait for B (Press)
            mem[10] = 16'h9440; // LD R2, [R1]
            mem[11] = 16'hB0B0; // CMP R2, R6
            mem[12] = 16'hD00A; // BZ 10
            mem[13] = 16'h9800; // LD R4, [R0]
            
            // Wait for B (Release)
            mem[14] = 16'h9440; // LD R2, [R1]
            mem[15] = 16'hB0B0; // CMP R2, R6
            mem[16] = 16'hE00E; // BNZ 14

            // Wait for Op (Press)
            mem[17] = 16'h9440; // LD R2, [R1]
            mem[18] = 16'hB0B0; // CMP R2, R6
            mem[19] = 16'hD011; // BZ 17
            mem[20] = 16'h9A00; // LD R5, [R0]
            
            // Wait for Op (Release)
            mem[21] = 16'h9440; // LD R2, [R1]
            mem[22] = 16'hB0B0; // CMP R2, R6
            mem[23] = 16'hE015; // BNZ 21

            // Compute: Add?
            mem[24] = 16'hB170; // CMP R5, R6 (Op == 0?)
            mem[25] = 16'hE01C; // BNZ 28 (If not 0, try sub)
            mem[26] = 16'h0EE0; // ADD R7, R3, R4
            mem[27] = 16'hC023; // JMP 35 (Output)

            // Compute: Sub?
            mem[28] = 16'h8401; // LDI R2, 1
            mem[29] = 16'hB150; // CMP R5, R2 (Op == 1?)
            mem[30] = 16'hE021; // BNZ 33 (If not 1, try mul)
            mem[31] = 16'h1EE0; // SUB R7, R3, R4
            mem[32] = 16'hC023; // JMP 35 (Output)

            // Compute: Mul (Default)
            mem[33] = 16'h8402; // LDI R2, 2
            mem[34] = 16'h2EE0; // MUL R7, R3, R4

            // Output
            mem[35] = 16'hAE00; // ST R7, [R0]
            mem[36] = 16'hC003; // JMP 3 (Loop back to A)
        end
    end

    // ----------------------------------------------------------
    // Asynchronous Read (combinational ROM)
    // ----------------------------------------------------------
    assign instruction = mem[addr];

endmodule