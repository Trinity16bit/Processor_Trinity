// ============================================================
//  Module  : data_memory.v
//  Project : Custom 16-bit Processor
//  Desc    : Data Memory (SRAM) - for LD and ST instructions.
//            256 × 16-bit words (byte-addressable via word addr).
//
//  - Synchronous Write (on posedge clk)
//  - Asynchronous Read (combinational, like a register file)
//
//  Used by:
//    LD Rd, [Rs]  → Rd = Mem[Rs]   (mem_read  = 1)
//    ST Rs, [Rd]  → Mem[Rd] = Rs   (mem_write = 1)
// ============================================================

module data_memory #(
    parameter MEM_DEPTH = 256           // Number of 16-bit words
) (
    input  wire        clk,

    // Control
    input  wire        mem_read,        // Enable read
    input  wire        mem_write,       // Enable write

    // Address & Data
    input  wire [15:0] addr,            // Memory address (word-addressed)
    input  wire [15:0] write_data,      // Data to write (for ST)

    // Output
    output wire [15:0] read_data        // Data read (for LD)
);

    // ----------------------------------------------------------
    // RAM Array: 256 × 16 bits
    // ----------------------------------------------------------
    reg [15:0] mem [0:MEM_DEPTH-1];

    integer i;

    // ----------------------------------------------------------
    // Initialize to zero
    // ----------------------------------------------------------
    initial begin
        for (i = 0; i < MEM_DEPTH; i = i + 1)
            mem[i] = 16'h0000;
    end

    // ----------------------------------------------------------
    // Synchronous Write
    // ----------------------------------------------------------
    always @(posedge clk) begin
        if (mem_write) begin
            mem[addr[7:0]] <= write_data;   // Use lower 8-bits as index
        end
    end

    // ----------------------------------------------------------
    // Asynchronous Read (returns 0 if read disabled)
    // ----------------------------------------------------------
    assign read_data = (mem_read) ? mem[addr[7:0]] : 16'h0000;

endmodule