
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
            // Default test program (can override with INIT_FILE)
            // Computes: R3 = (5 + 3) * 2 - 1
            // --------------------------------------------------------
            //         Opcode Rd  Rs1 Rs2  xx
            mem[0]  = {4'b1000, 3'd0, 9'd5};         // LDI R0, 5
            mem[1]  = {4'b1000, 3'd1, 9'd3};         // LDI R1, 3
            mem[2]  = {4'b1000, 3'd2, 9'd2};         // LDI R2, 2
            mem[3]  = {4'b1000, 3'd4, 9'd1};         // LDI R4, 1
            mem[4]  = {4'b0000, 3'd3, 3'd0, 3'd1, 3'd0}; // ADD R3, R0, R1  ; R3=8
            mem[5]  = {4'b0010, 3'd3, 3'd3, 3'd2, 3'd0}; // MUL R3, R3, R2  ; R3=16
            mem[6]  = {4'b0001, 3'd3, 3'd3, 3'd4, 3'd0}; // SUB R3, R3, R4  ; R3=15
            mem[7]  = {4'b1111, 12'h000};               // HALT
        end
    end

    // ----------------------------------------------------------
    // Asynchronous Read (combinational ROM)
    // ----------------------------------------------------------
    assign instruction = mem[addr];

endmodule