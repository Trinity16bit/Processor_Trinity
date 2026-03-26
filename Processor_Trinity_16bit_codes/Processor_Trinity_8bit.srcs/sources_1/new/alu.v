// ============================================================
//  Module  : alu.v
//  Project : Custom 16-bit Processor (Based on ISA Table)
//  Desc    : Arithmetic Logic Unit - heart of the processor
//            Supports: ADD, SUB, MUL, DIV, AND, OR, XOR,
//                      MOV (passthrough A), LDI (passthrough B),
//                      LD/ST (address calc A+0), CMP (SUB no write)
// ============================================================

module alu (
    input  wire [15:0] A,           // Operand A (Rs1 data)
    input  wire [15:0] B,           // Operand B (Rs2 data OR Immediate)
    input  wire [3:0]  alu_op,      // ALU operation (matches opcode)

    output reg  [15:0] result,      // Computation result
    output reg         zero_flag,   // 1 if result == 0
    output reg         carry_flag,  // 1 if carry/borrow occurred
    output reg         neg_flag,    // 1 if result is negative (MSB)
    output reg         overflow_flag // 1 if signed overflow occurred
);

    // ----------------------------------------------------------
    // ALU Operation Codes (mapped to instruction opcodes)
    // ----------------------------------------------------------
    localparam OP_ADD  = 4'b0000;
    localparam OP_SUB  = 4'b0001;
    localparam OP_MUL  = 4'b0010;
    localparam OP_DIV  = 4'b0011;
    localparam OP_AND  = 4'b0100;
    localparam OP_OR   = 4'b0101;
    localparam OP_XOR  = 4'b0110;
    localparam OP_MOV  = 4'b0111;   // Passthrough A
    localparam OP_LDI  = 4'b1000;   // Passthrough B (Immediate)
    localparam OP_LD   = 4'b1001;   // A + 0 (address calculation)
    localparam OP_ST   = 4'b1010;   // A + 0 (address calculation)
    localparam OP_CMP  = 4'b1011;   // SUB (flags updated, result discarded by CU)

    // Internal wide registers for carry/mul
    reg [16:0] wide_result;   // 17-bit for carry detection
    reg [31:0] mul_result;    // 32-bit for full multiply

    // ----------------------------------------------------------
    // Combinational ALU Logic
    // ----------------------------------------------------------
    always @(*) begin
        // Default all outputs
        result        = 16'h0000;
        carry_flag    = 1'b0;
        overflow_flag = 1'b0;
        wide_result   = 17'h0;
        mul_result    = 32'h0;

        case (alu_op)

            OP_ADD: begin
                wide_result   = {1'b0, A} + {1'b0, B};
                result        = wide_result[15:0];
                carry_flag    = wide_result[16];
                // Signed overflow: +ve + +ve = -ve OR -ve + -ve = +ve
                overflow_flag = (~A[15] & ~B[15] & result[15]) |
                                ( A[15] &  B[15] & ~result[15]);
            end

            OP_SUB, OP_CMP: begin
                wide_result   = {1'b0, A} - {1'b0, B};
                result        = wide_result[15:0];
                carry_flag    = wide_result[16];  // Borrow flag
                // Signed overflow: +ve - -ve = -ve OR -ve - +ve = +ve
                overflow_flag = (~A[15] &  B[15] &  result[15]) |
                                ( A[15] & ~B[15] & ~result[15]);
            end

            OP_MUL: begin
                mul_result = {{16{A[15]}}, A} * {{16{B[15]}}, B};
                result     = mul_result[15:0];  // Lower 16 bits (per ISA)
            end

            OP_DIV: begin
                // Guard against divide-by-zero → return 0xFFFF as sentinel
                result = (B != 16'h0) ? (A / B) : 16'hFFFF;
            end

            OP_AND: result = A & B;
            OP_OR:  result = A | B;
            OP_XOR: result = A ^ B;

            OP_MOV: result = A;           // Passthrough A (A + 0)
            OP_LDI: result = B;           // Passthrough B (0 + Imm)

            OP_LD:  result = A;           // Address = Rs (base addr, A+0)
            OP_ST:  result = A;           // Address = Rs (base addr, A+0)

            default: result = 16'h0000;
        endcase

        // ----------------------------------------------------------
        // Flags: always computed from final result
        // ----------------------------------------------------------
        zero_flag = (result == 16'h0000);
        neg_flag  = result[15];
    end

endmodule