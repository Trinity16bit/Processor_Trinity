// ============================================================
//  Module  : processor_top.v
//  Project : Custom 16-bit Processor (Single-Cycle)
//  Desc    : Top-Level Integration - wires all submodules:
//              ├── program_counter
//              ├── instruction_memory
//              ├── control_unit
//              ├── register_file
//              ├── alu
//              ├── flag_register
//              └── data_memory
//
//  Instruction Format (16-bit):
//  ┌──────────┬──────┬──────┬──────┬──────────┐
//  │ [15:12]  │[11:9]│ [8:6]│ [5:3]│  [2:0]   │
//  │  Opcode  │  Rd  │  Rs1 │  Rs2 │ (unused) │
//  └──────────┴──────┴──────┴──────┴──────────┘
//  LDI: [15:12]=opcode | [11:9]=Rd | [8:0]=Imm9
//  JMP/BZ/BNZ: [15:12]=opcode | [11:0]=Address
//  ST: [11:9]=Rs(data) | [8:6]=Rd(addr_reg)   ← special!
//
//  Datapath Summary:
//  ┌─────┐    ┌──────┐    ┌─────┐    ┌─────┐
//  │ PC  │───▶│ IMEM │───▶│ CU  │───▶│ RF  │
//  └─────┘    └──────┘    └─────┘    └──┬──┘
//                                  A ───┘│Rs1
//                                  B ───▶│Rs2/Imm
//                              ┌───┴───┐
//                              │  ALU  │
//                              └───┬───┘
//                           result │
//                     ┌────────────┴──────────┐
//                     │  Flags  │   DMEM addr │
//                     └─────────┘      │      │
//                                  ┌───▼───┐  │
//                                  │ DMEM  │  │
//                                  └───┬───┘  │
//                                      │mem   │alu
//                                   ┌──▼──────▼──┐
//                                   │   MUX WB   │
//                                   └──────┬──────┘
//                                          │→ RF Rd
// ============================================================

module processor_top (
    input  wire clk,
    input  wire rst,

    // Debug outputs (for simulation / external observation)
    output wire [11:0] debug_pc,
    output wire [15:0] debug_instr,
    output wire        debug_halt,
    output wire        debug_zero_flag
);

    // ==========================================================
    // INTERNAL SIGNAL DECLARATIONS
    // ==========================================================

    // --- Program Counter ---
    wire [11:0] pc;
    wire        branch_taken;

    // --- Instruction ---
    wire [15:0] instruction;
    wire [3:0]  opcode  = instruction[15:12];
    wire [2:0]  rd_addr = instruction[11:9];
    wire [2:0]  rs1_addr= instruction[8:6];
    wire [2:0]  rs2_addr= instruction[5:3];
    wire [11:0] jmp_target = instruction[11:0];
    wire [8:0]  imm9    = instruction[8:0];         // 9-bit immediate (LDI)
    wire [15:0] imm_sext= {{7{imm9[8]}}, imm9};    // Sign-extended to 16-bit

    // --- Control Signals ---
    wire        reg_write;
    wire        alu_src;
    wire [3:0]  alu_op;
    wire        mem_read;
    wire        mem_write;
    wire        mem_to_reg;
    wire        flag_write_cu;  // from CU (for CMP)
    wire        jump;
    wire        branch_z;
    wire        branch_nz;
    wire        halt;

    // --- Register File ---
    wire [15:0] rs1_data;
    wire [15:0] rs2_data;
    wire [15:0] rd_data;        // Extra read port (used for ST)
    wire [15:0] write_data;     // Writeback mux output → Rd

    // --- ALU ---
    wire [15:0] alu_a;
    wire [15:0] alu_b;
    wire [15:0] alu_result;
    wire        alu_zero;
    wire        alu_carry;
    wire        alu_neg;
    wire        alu_overflow;

    // --- Flags ---
    wire        flag_zero;      // Stored zero flag
    wire        flag_carry;
    wire        flag_neg;
    wire        flag_overflow;
    wire        flag_write_en;  // Combined: CU flag_write OR reg-writing ALU ops

    // --- Data Memory ---
    wire [15:0] dmem_read_data;

    // ==========================================================
    // DATAPATH LOGIC
    // ==========================================================

    // ----------------------------------------------------------
    // 1. ALU Input Muxes
    // ----------------------------------------------------------

    // A-input: always Rs1 data
    //   • For ST: rs1_addr = [8:6] = address register → ALU computes address
    //   • For LD: rs1_addr = [8:6] = address register → ALU computes address
    //   • For MOV: rs1_addr = [8:6] = source register → ALU passthrough A
    assign alu_a = rs1_data;

    // B-input: Rs2 OR Sign-Extended Immediate (mux controlled by alu_src)
    //   • alu_src = 0 → Rs2 (R-type)
    //   • alu_src = 1 → Immediate (LDI)
    assign alu_b = alu_src ? imm_sext : rs2_data;

    // ----------------------------------------------------------
    // 2. Writeback Mux: ALU result vs. Memory data
    // ----------------------------------------------------------
    //   • mem_to_reg = 0 → write ALU result (most instructions)
    //   • mem_to_reg = 1 → write memory read data (LD)
    assign write_data = mem_to_reg ? dmem_read_data : alu_result;

    // ----------------------------------------------------------
    // 3. Branch Logic: decides if branch is taken
    // ----------------------------------------------------------
    //   • BZ:  branch if zero flag is SET
    //   • BNZ: branch if zero flag is CLEAR
    assign branch_taken = (branch_z  &&  flag_zero) ||
                          (branch_nz && !flag_zero);

    // ----------------------------------------------------------
    // 4. Flag Write Enable
    // ----------------------------------------------------------
    //   • CU forces flag_write for CMP (no reg_write but flags must update)
    //   • For arithmetic/logic ops, flags update whenever reg_write is active
    //     (except data movement: MOV, LDI, LD, ST - controlled by CU not setting flag_write)
    //   • Simplified: CU controls flag_write explicitly
    assign flag_write_en = flag_write_cu ||
                           (reg_write && (opcode <= 4'b0110));  // ADD-XOR always update flags

    // ----------------------------------------------------------
    // 5. ST instruction data memory connections
    //    ST Rs, [Rd]: Mem[Rd_reg_val] = Rs_reg_val
    //    - addr   = ALU result (computed from rs1_data = Rd address register value)
    //    - wdata  = rd_data   (value of register pointed by [11:9] = Rs in ST)
    //
    //    Encoding: ST [11:9]=Rs(data_source), [8:6]=Rd(addr_register)
    //    So: rs1_data = registers[rs1_addr] = registers[[8:6]] = address
    //        rd_data  = registers[rd_addr]  = registers[[11:9]] = data to store
    // ----------------------------------------------------------

    // ==========================================================
    // MODULE INSTANTIATIONS
    // ==========================================================

    // ----------------------------------------------------------
    // Program Counter
    // ----------------------------------------------------------
    program_counter u_pc (
        .clk          (clk),
        .rst          (rst),
        .halt         (halt),
        .jump         (jump),
        .branch_taken (branch_taken),
        .jump_target  (jmp_target),
        .pc           (pc)
    );

    // ----------------------------------------------------------
    // Instruction Memory (ROM)
    // ----------------------------------------------------------
    instruction_memory #(
        .MEM_DEPTH (256),
        .INIT_FILE ("")
    ) u_imem (
        .addr        (pc),
        .instruction (instruction)
    );

    // ----------------------------------------------------------
    // Control Unit (Instruction Decoder)
    // ----------------------------------------------------------
    control_unit u_cu (
        .opcode     (opcode),
        .reg_write  (reg_write),
        .alu_src    (alu_src),
        .alu_op     (alu_op),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .mem_to_reg (mem_to_reg),
        .flag_write (flag_write_cu),
        .jump       (jump),
        .branch_z   (branch_z),
        .branch_nz  (branch_nz),
        .halt       (halt)
    );

    // ----------------------------------------------------------
    // Register File (8 × 16-bit)
    // ----------------------------------------------------------
    register_file u_rf (
        .clk        (clk),
        .rst        (rst),
        .reg_write  (reg_write),
        .rd_addr    (rd_addr),
        .write_data (write_data),
        .rs1_addr   (rs1_addr),
        .rs2_addr   (rs2_addr),
        .rs1_data   (rs1_data),
        .rs2_data   (rs2_data),
        .rd_data    (rd_data)
    );

    // ----------------------------------------------------------
    // ALU
    // ----------------------------------------------------------
    alu u_alu (
        .A            (alu_a),
        .B            (alu_b),
        .alu_op       (alu_op),
        .result       (alu_result),
        .zero_flag    (alu_zero),
        .carry_flag   (alu_carry),
        .neg_flag     (alu_neg),
        .overflow_flag(alu_overflow)
    );

    // ----------------------------------------------------------
    // Flag Register
    // ----------------------------------------------------------
    flag_register u_flags (
        .clk         (clk),
        .rst         (rst),
        .flag_write  (flag_write_en),
        .zero_in     (alu_zero),
        .carry_in    (alu_carry),
        .neg_in      (alu_neg),
        .overflow_in (alu_overflow),
        .zero        (flag_zero),
        .carry       (flag_carry),
        .neg         (flag_neg),
        .overflow    (flag_overflow)
    );

    // ----------------------------------------------------------
    // Data Memory (SRAM)
    // ----------------------------------------------------------
    data_memory #(
        .MEM_DEPTH (256)
    ) u_dmem (
        .clk        (clk),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .addr       (alu_result),       // ALU computes the effective address
        .write_data (rd_data),          // ST: rd_data = Rs (data register value)
        .read_data  (dmem_read_data)
    );

    // ==========================================================
    // DEBUG OUTPUT ASSIGNMENTS
    // ==========================================================
    assign debug_pc        = pc;
    assign debug_instr     = instruction;
    assign debug_halt      = halt;
    assign debug_zero_flag = flag_zero;

endmodule