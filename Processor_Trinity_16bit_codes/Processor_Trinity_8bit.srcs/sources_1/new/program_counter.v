// ============================================================
//  Module  : program_counter.v
//  Project : Custom 16-bit Processor
//  Desc    : Program Counter - tracks the address of the
//            currently executing instruction.
//
//  PC Update Priority (highest → lowest):
//    1. rst    → PC = 0
//    2. halt   → PC holds (clock effectively frozen logically)
//    3. jump   → PC = jump_target
//    4. branch → PC = branch_target (when condition is true)
//    5. normal → PC = PC + 1
// ============================================================

module program_counter (
    input  wire        clk,
    input  wire        rst,

    // Control signals from Control Unit
    input  wire        halt,            // HALT: freeze PC
    input  wire        jump,            // JMP: unconditional jump
    input  wire        branch_taken,    // Branch condition evaluated by top
    input  wire [11:0] jump_target,     // Target address (from instruction[11:0])

    output reg  [11:0] pc               // Current Program Counter
);

    // ----------------------------------------------------------
    // PC Update Logic (synchronous)
    // ----------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 12'h000;
        end else if (halt) begin
            pc <= pc;               // Hold on HALT
        end else if (jump || branch_taken) begin
            pc <= jump_target;      // Jump / Branch taken
        end else begin
            pc <= pc + 12'h001;    // Sequential execution
        end
    end

endmodule