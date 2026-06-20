`timescale 1ns / 1ps

module zedboard_top(
    input  wire clk_100MHz,
    input  wire rst_btn,   // BTNU
    input  wire enter_btn, // BTND
    input  wire [7:0] sw,
    output wire [7:0] led
);

    // --- Debouncer for Enter Button ---
    reg [19:0] debounce_counter = 0;
    reg enter_btn_sampled = 0;
    always @(posedge clk_100MHz) begin
        if (debounce_counter == 999_999) begin
            debounce_counter <= 0;
            enter_btn_sampled <= enter_btn;
        end else begin
            debounce_counter <= debounce_counter + 1;
        end
    end

    // --- Clock Divider (1MHz) ---
    reg [5:0] clk_div_counter = 0;
    reg clk_1MHz = 0;
    always @(posedge clk_100MHz) begin
        if (clk_div_counter == 49) begin
            clk_div_counter <= 0;
            clk_1MHz <= ~clk_1MHz;
        end else begin
            clk_div_counter <= clk_div_counter + 1;
        end
    end

    wire proc_clk;
    BUFG bufg_inst (
       .O(proc_clk),
       .I(clk_1MHz)
    );

    // --- Reset Synchronization ---
    // The reset button is asynchronous, synchronize it to proc_clk
    reg rst_sync_1 = 0;
    reg rst_sync_2 = 0;
    always @(posedge proc_clk or posedge rst_btn) begin
        if (rst_btn) begin
            rst_sync_1 <= 1'b1;
            rst_sync_2 <= 1'b1;
        end else begin
            rst_sync_1 <= 1'b0;
            rst_sync_2 <= rst_sync_1;
        end
    end
    wire proc_rst = rst_sync_2;

    // --- Processor Instantiation ---
    wire [11:0] debug_pc;
    wire [15:0] debug_instr;
    wire debug_halt;
    wire debug_zero_flag;
    
    wire [15:0] proc_out_port;

    processor_top u_processor (
        .clk(proc_clk),
        .rst(proc_rst),
        .in_port(sw),
        .enter_btn(enter_btn_sampled),
        .out_port(proc_out_port),
        .debug_pc(debug_pc),
        .debug_instr(debug_instr),
        .debug_halt(debug_halt),
        .debug_zero_flag(debug_zero_flag)
    );

    // Directly connect processor out_port (lower 8 bits) to LEDs
    assign led = proc_out_port[7:0];

endmodule
