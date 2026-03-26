// ============================================================
//  Module  : flag_register.v
//  Project : Custom 16-bit Processor
//  Desc    : CPU Flag Register - stores processor status flags.
//
//  Flags:
//    Z (Zero)     - result was zero
//    C (Carry)    - carry/borrow out of bit 15
//    N (Negative) - result MSB is 1 (signed negative)
//    V (Overflow) - signed arithmetic overflow occurred
//
//  Updated by:
//    - All ALU operations (always)
//    - CMP explicitly (flag_write = 1 from CU even though reg_write = 0)
//
//  NOT updated by:
//    - LDI, LD, ST, MOV (data movement - no arithmetic meaning)
//    - JMP, BZ, BNZ, HALT (control flow)
//
//  Note: For this ISA, flags are updated on every ALU op.
//        flag_write is asserted by CU to ensure CMP saves flags.
// ============================================================

module flag_register (
    input  wire clk,
    input  wire rst,

    // Write control
    input  wire flag_write,         // 1 = latch new flags

    // Input flags from ALU
    input  wire zero_in,
    input  wire carry_in,
    input  wire neg_in,
    input  wire overflow_in,

    // Stored flag outputs
    output reg  zero,               // Z flag
    output reg  carry,              // C flag
    output reg  neg,                // N flag
    output reg  overflow            // V flag
);

    // ----------------------------------------------------------
    // Synchronous flag latch
    // ----------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            zero     <= 1'b0;
            carry    <= 1'b0;
            neg      <= 1'b0;
            overflow <= 1'b0;
        end else if (flag_write) begin
            zero     <= zero_in;
            carry    <= carry_in;
            neg      <= neg_in;
            overflow <= overflow_in;
        end
    end

endmodule