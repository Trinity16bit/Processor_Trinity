// ============================================================
//  Module  : control_unit.v
//  Project : Custom 16-bit Processor
//  Desc    : Control Unit - Instruction Decoder.
//            Takes 4-bit opcode, generates all control signals
//            for the datapath (ALU, memory, registers, PC).
//
//  Truth Table:
//  ┌──────┬────────┬─────────┬──────────┬──────────┬────────────┬──────┬───────┬──────────┬──────┐
//  │Opcode│ Mnem.  │reg_write│ alu_src  │ mem_read │ mem_write  │ jump │branch │flag_write│ halt │
//  ├──────┼────────┼─────────┼──────────┼──────────┼────────────┼──────┼───────┼──────────┼──────┤
//  │ 0000 │ ADD    │    1    │ REG(0)   │    0     │     0      │  0   │   0   │    0     │  0   │
//  │ 0001 │ SUB    │    1    │ REG(0)   │    0     │     0      │  0   │   0   │    0     │  0   │
//  │ 0010 │ MUL    │    1    │ REG(0)   │    0     │     0      │  0   │   0   │    0     │  0   │
//  │ 0011 │ DIV    │    1    │ REG(0)   │    0     │     0      │  0   │   0   │    0     │  0   │
//  │ 0100 │ AND    │    1    │ REG(0)   │    0     │     0      │  0   │   0   │    0     │  0   │
//  │ 0101 │ OR     │    1    │ REG(0)   │    0     │     0      │  0   │   0   │    0     │  0   │
//  │ 0110 │ XOR    │    1    │ REG(0)   │    0     │     0      │  0   │   0   │    0     │  0   │
//  │ 0111 │ MOV    │    1    │ REG(0)   │    0     │     0      │  0   │   0   │    0     │  0   │
//  │ 1000 │ LDI    │    1    │ IMM(1)   │    0     │     0      │  0   │   0   │    0     │  0   │
//  │ 1001 │ LD     │    1    │ REG(0)   │    1     │     0      │  0   │   0   │    0     │  0   │
//  │ 1010 │ ST     │    0    │ REG(0)   │    0     │     1      │  0   │   0   │    0     │  0   │
//  │ 1011 │ CMP    │    0    │ REG(0)   │    0     │     0      │  0   │   0   │    1     │  0   │
//  │ 1100 │ JMP    │    0    │ REG(0)   │    0     │     0      │  1   │   0   │    0     │  0   │
//  │ 1101 │ BZ     │    0    │ REG(0)   │    0     │     0      │  0   │  BZ   │    0     │  0   │
//  │ 1110 │ BNZ    │    0    │ REG(0)   │    0     │     0      │  0   │  BNZ  │    0     │  0   │
//  │ 1111 │ HALT   │    0    │ REG(0)   │    0     │     0      │  0   │   0   │    0     │  1   │
//  └──────┴────────┴─────────┴──────────┴──────────┴────────────┴──────┴───────┴──────────┴──────┘
// ============================================================

module control_unit (
    input  wire [3:0] opcode,           // Instruction opcode [15:12]

    // --- Register File Control ---
    output reg        reg_write,        // 1 = write result to Rd

    // --- ALU Control ---
    output reg        alu_src,          // 0 = Rs2, 1 = Immediate
    output reg  [3:0] alu_op,           // Passes opcode directly to ALU

    // --- Memory Control ---
    output reg        mem_read,         // 1 = read data memory (LD)
    output reg        mem_write,        // 1 = write data memory (ST)
    output reg        mem_to_reg,       // 0 = ALU result, 1 = mem data → Rd

    // --- Flag Register Control ---
    output reg        flag_write,       // 1 = update flags (CMP)

    // --- PC / Branch Control ---
    output reg        jump,             // 1 = unconditional JMP
    output reg        branch_z,         // 1 = BZ instruction (CU issues, PC checks)
    output reg        branch_nz,        // 1 = BNZ instruction

    // --- Special ---
    output reg        halt              // 1 = HALT processor
);

    // ----------------------------------------------------------
    // Opcode Parameters (matching ISA table)
    // ----------------------------------------------------------
    localparam OP_ADD  = 4'b0000;
    localparam OP_SUB  = 4'b0001;
    localparam OP_MUL  = 4'b0010;
    localparam OP_DIV  = 4'b0011;
    localparam OP_AND  = 4'b0100;
    localparam OP_OR   = 4'b0101;
    localparam OP_XOR  = 4'b0110;
    localparam OP_MOV  = 4'b0111;
    localparam OP_LDI  = 4'b1000;
    localparam OP_LD   = 4'b1001;
    localparam OP_ST   = 4'b1010;
    localparam OP_CMP  = 4'b1011;
    localparam OP_JMP  = 4'b1100;
    localparam OP_BZ   = 4'b1101;
    localparam OP_BNZ  = 4'b1110;
    localparam OP_HALT = 4'b1111;

    // ----------------------------------------------------------
    // Combinational Decode Logic
    // ----------------------------------------------------------
    always @(*) begin
        // --- Safe Defaults (prevent latches) ---
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        alu_op     = opcode;    // ALU uses same opcode directly
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        flag_write = 1'b0;
        jump       = 1'b0;
        branch_z   = 1'b0;
        branch_nz  = 1'b0;
        halt       = 1'b0;

        case (opcode)

            // ------ Arithmetic & Logic Operations ------
            OP_ADD, OP_SUB, OP_MUL, OP_DIV,
            OP_AND, OP_OR,  OP_XOR: begin
                reg_write  = 1'b1;      // Write ALU result to Rd
                alu_src    = 1'b0;      // B = Rs2
            end

            // ------ MOV Rd, Rs1 → Rd = Rs1 ------
            OP_MOV: begin
                reg_write  = 1'b1;
                alu_src    = 1'b0;      // B unused (A passthrough)
            end

            // ------ LDI Rd, Imm → Rd = Imm ------
            OP_LDI: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;      // B = Immediate (sign-extended)
            end

            // ------ LD Rd, [Rs] → Rd = Mem[Rs] ------
            OP_LD: begin
                reg_write  = 1'b1;      // Write memory data to Rd
                alu_src    = 1'b0;      // A = Rs (address register)
                mem_read   = 1'b1;      // Read from data memory
                mem_to_reg = 1'b1;      // Writeback: memory data (not ALU)
            end

            // ------ ST Rs, [Rd] → Mem[Rd] = Rs ------
            // Note: [11:9]=Rs_data, [8:6]=Rd_addr(addr), see top module
            OP_ST: begin
                reg_write  = 1'b0;      // Don't write to register
                alu_src    = 1'b0;      // A = Rs1 (address register)
                mem_write  = 1'b1;      // Write to data memory
            end

            // ------ CMP Rs1, Rs2 → Flags = Rs1 - Rs2 (no write) ------
            OP_CMP: begin
                reg_write  = 1'b0;      // Result discarded
                flag_write = 1'b1;      // Force update flags explicitly
                alu_src    = 1'b0;
            end

            // ------ JMP Addr → PC = Addr ------
            OP_JMP: begin
                jump       = 1'b1;
            end

            // ------ BZ Addr → if (Z==1) PC = Addr ------
            OP_BZ: begin
                branch_z   = 1'b1;
            end

            // ------ BNZ Addr → if (Z==0) PC = Addr ------
            OP_BNZ: begin
                branch_nz  = 1'b1;
            end

            // ------ HALT → Stop clock ------
            OP_HALT: begin
                halt       = 1'b1;
            end

            // ------ Unknown → NOP ------
            default: begin
                reg_write  = 1'b0;
            end

        endcase
    end

endmodule