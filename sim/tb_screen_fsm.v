`timescale 1ns/1ps
`include "lab4_defs.vh"

module tb_screen_fsm;
    reg clk = 1'b0;
    reg rst_n = 1'b1;
    reg click = 1'b0;
    reg blank_start = 1'b0;
    wire [1:0] ctrl_state;
    wire [1:0] display_state;
    integer i;
    always #10 clk = ~clk;
    screen_fsm dut (.clk(clk), .rst_n(rst_n), .click(click), .ctrl_state(ctrl_state));
    display_commit commit_dut (
        .clk(clk), .rst_n(rst_n), .blank_start(blank_start),
        .ctrl_state(ctrl_state), .display_state(display_state)
    );
    task press;
        begin
            @(negedge clk); click = 1'b1;
            @(negedge clk); click = 1'b0;
        end
    endtask
    task reset_now;
        begin
            #3 rst_n = 1'b0;
            #1;
            if (ctrl_state !== `SCREEN_BAR || display_state !== `SCREEN_BAR)
                $fatal(1, "reset was not asynchronous");
            @(negedge clk); rst_n = 1'b1;
        end
    endtask
    initial begin
        $dumpfile("build/screen_fsm.vcd"); $dumpvars(0, tb_screen_fsm);
        reset_now;
        press;
        if (ctrl_state !== `SCREEN_MUST) $fatal(1, "BAR -> MUST failed");
        if (display_state !== `SCREEN_BAR) $fatal(1, "display changed before blank");
        @(negedge clk); blank_start = 1'b1;
        @(negedge clk); blank_start = 1'b0;
        if (display_state !== `SCREEN_MUST) $fatal(1, "blank commit failed");
        press;
        if (ctrl_state !== `SCREEN_END) $fatal(1, "MUST -> END failed");
        press;
        if (ctrl_state !== `SCREEN_BAR) $fatal(1, "END -> BAR failed");
        for (i=0; i<3; i=i+1) begin
            reset_now;
            repeat (i) press;
            @(negedge clk); click = 1'b1;
            reset_now; // Reset wins even with click asserted.
            click = 1'b0;
        end
        // Illegal state recovery is a controller unit test, not a board stimulus.
        @(negedge clk); dut.ctrl_state = 2'b11;
        @(negedge clk);
        if (ctrl_state !== `SCREEN_BAR) $fatal(1, "illegal-state recovery failed");
        $display("PASS tb_screen_fsm: cycle/reset/blank-commit/illegal state");
        $finish;
    end
endmodule
