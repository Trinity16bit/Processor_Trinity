// ============================================================
//  Module  : register_file.v
//  Project : Custom 16-bit Processor
//  Desc    : Register Bank - 8 general-purpose 16-bit registers
//            R0 - R7
//            - 2 read ports (Rs1, Rs2)
//            - 1 extra read port (Rd) for ST instruction data
//            - 1 synchronous write port (Rd)
//            - R0 is NOT hardwired to zero (all regs general purpose)
// ============================================================

module register_file (
    input  wire        clk,
    input  wire        rst,

    // --- Write Port ---
    input  wire        reg_write,       // Write enable
    input  wire [2:0]  rd_addr,         // Destination register address
    input  wire [15:0] write_data,      // Data to write

    // --- Read Ports ---
    input  wire [2:0]  rs1_addr,        // Source register 1 address
    input  wire [2:0]  rs2_addr,        // Source register 2 address

    // --- Read Outputs ---
    output wire [15:0] rs1_data,        // Source register 1 data
    output wire [15:0] rs2_data,        // Source register 2 data
    output wire [15:0] rd_data          // Rd register data (used in ST)
);

    // ----------------------------------------------------------
    // Register Array: 8 registers × 16 bits
    // ----------------------------------------------------------
    reg [15:0] registers [0:7];

    integer i;

    // ----------------------------------------------------------
    // Synchronous Write (with Reset)
    // ----------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Initialize all registers to 0 on reset
            for (i = 0; i < 8; i = i + 1)
                registers[i] <= 16'h0000;
        end else begin
            if (reg_write)
                registers[rd_addr] <= write_data;
        end
    end

    // ----------------------------------------------------------
    // Asynchronous (Combinational) Read Ports
    // Note: Forwarding not needed - single-cycle processor
    // ----------------------------------------------------------
    assign rs1_data = registers[rs1_addr];
    assign rs2_data = registers[rs2_addr];
    assign rd_data  = registers[rd_addr];   // Extra port for ST

endmodule