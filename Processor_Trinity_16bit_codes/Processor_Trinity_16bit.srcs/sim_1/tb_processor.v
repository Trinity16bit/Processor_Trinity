// ============================================================
//  Module  : tb_processor.v
//  Project : Custom 16-bit Processor
//  Desc    : Testbench - Simulates full processor execution.
//
//  Test Programs:
//    Test 1: Arithmetic chain  → R3 = (5 + 3) * 2 - 1 = 15
//    Test 2: Logic ops         → AND, OR, XOR
//    Test 3: Branch/Loop       → BNZ countdown loop
//    Test 4: Memory LD/ST      → store and load value
//    Test 5: CMP + BZ          → conditional branch on zero
// ============================================================

`timescale 1ns/1ps

module tb_processor;

    // ----------------------------------------------------------
    // DUT Signals
    // ----------------------------------------------------------
    reg         clk;
    reg         rst;
    wire [11:0] debug_pc;
    wire [15:0] debug_instr;
    wire        debug_halt;
    wire        debug_zero_flag;

    // ----------------------------------------------------------
    // Clock Generation: 10ns period (100 MHz)
    // ----------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // ----------------------------------------------------------
    // DUT Instantiation
    // ----------------------------------------------------------
    processor_top dut (
        .clk            (clk),
        .rst            (rst),
        .debug_pc       (debug_pc),
        .debug_instr    (debug_instr),
        .debug_halt     (debug_halt),
        .debug_zero_flag(debug_zero_flag)
    );

    // ----------------------------------------------------------
    // Monitor - print every instruction execution
    // ----------------------------------------------------------
    always @(posedge clk) begin
        if (!rst) begin
            $display("[%0t ns] PC=%03h | IR=%04h | HALT=%b | Z=%b | R0=%04h R1=%04h R2=%04h R3=%04h R4=%04h",
                $time,
                debug_pc,
                debug_instr,
                debug_halt,
                debug_zero_flag,
                dut.u_rf.registers[0],
                dut.u_rf.registers[1],
                dut.u_rf.registers[2],
                dut.u_rf.registers[3],
                dut.u_rf.registers[4]
            );
        end
    end

    // ----------------------------------------------------------
    // Test Stimulus
    // ----------------------------------------------------------
    initial begin
        $display("========================================");
        $display(" 16-bit Custom Processor Simulation");
        $display(" ISA: ADD SUB MUL DIV AND OR XOR");
        $display("      MOV LDI LD ST CMP JMP BZ BNZ HALT");
        $display("========================================");

        // --- Reset ---
        rst = 1;
        #20;
        rst = 0;

        // Wait for HALT
        wait(debug_halt == 1'b1);
        #20;

        $display("");
        $display("========================================");
        $display(" ✓ Simulation Complete - HALT reached");
        $display("   Final Registers:");
        $display("   R0 = %04h (%0d)", dut.u_rf.registers[0], dut.u_rf.registers[0]);
        $display("   R1 = %04h (%0d)", dut.u_rf.registers[1], dut.u_rf.registers[1]);
        $display("   R2 = %04h (%0d)", dut.u_rf.registers[2], dut.u_rf.registers[2]);
        $display("   R3 = %04h (%0d)", dut.u_rf.registers[3], dut.u_rf.registers[3]);
        $display("   R4 = %04h (%0d)", dut.u_rf.registers[4], dut.u_rf.registers[4]);
        $display("   R5 = %04h (%0d)", dut.u_rf.registers[5], dut.u_rf.registers[5]);
        $display("   R6 = %04h (%0d)", dut.u_rf.registers[6], dut.u_rf.registers[6]);
        $display("   R7 = %04h (%0d)", dut.u_rf.registers[7], dut.u_rf.registers[7]);
        $display("========================================");

        // --- Assertion: R3 should be 15 from the default program ---
        if (dut.u_rf.registers[3] === 16'd15)
            $display(" ✓ PASS: R3 = 15 (expected)");
        else
            $display(" ✗ FAIL: R3 = %0d (expected 15)", dut.u_rf.registers[3]);

        $finish;
    end

    // --- Safety timeout (in case HALT never reached) ---
    initial begin
        #10000;
        $display("TIMEOUT: Simulation exceeded 10000ns");
        $finish;
    end

    // --- VCD dump for waveform viewing ---
    initial begin
        $dumpfile("processor_wave.vcd");
        $dumpvars(0, tb_processor);
    end

endmodule