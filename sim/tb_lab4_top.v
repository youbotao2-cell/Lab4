`timescale 1ns/1ps
`include "lab4_defs.vh"

module tb_lab4_top;
    reg sys_clk = 1'b0;
    reg sys_rst_n = 1'b1;
    reg key_in = 1'b1;
    wire hsync;
    wire vsync;
    wire [15:0] rgb;
    integer clicks = 0;
    integer pixel_steps = 0;
    integer frame_pixels = 0;
    integer active_pixels = 0;
    integer completed_frames = 0;
    integer steps_before_reset_hold;
    reg [1:0] previous_display = `SCREEN_BAR;
    reg previous_blank = 1'b0;
    reg previous_reset = 1'b0;
    always #10 sys_clk = ~sys_clk;
    lab4_top #(.DEBOUNCE_CYCLES(8)) dut (.*);

    always @(posedge sys_clk) begin
        if (dut.u_timing.pixel_phase) begin
            pixel_steps = pixel_steps + 1;
            frame_pixels = frame_pixels + 1;
            if (dut.active_video) active_pixels = active_pixels + 1;
            if (dut.u_timing.h_count == 10'd799 && dut.u_timing.v_count == 10'd524) begin
                if (frame_pixels != 420000 || active_pixels != 307200)
                    $fatal(1, "raster total=%0d active=%0d", frame_pixels, active_pixels);
                completed_frames = completed_frames + 1;
                frame_pixels=0; active_pixels=0;
            end
        end
        previous_blank = dut.blank_start;
        previous_reset = !dut.ctrl_rst_n;
        #1;
        if (dut.click) clicks = clicks + 1;
        if (dut.display_state !== previous_display && !previous_blank && !previous_reset)
            $fatal(1, "display selection changed during scan");
        previous_display = dut.display_state;
        if (!dut.active_video && rgb !== 16'h0000)
            $fatal(1, "RGB not black outside active video");
    end
    task click_and_wait;
        input [1:0] expected;
        integer timeout_cycles;
        begin
            @(negedge sys_clk); key_in=1'b0;
            repeat (24) @(negedge sys_clk);
            if (dut.ctrl_state !== expected) $fatal(1, "wrong control state");
            timeout_cycles=0;
            while (dut.display_state !== expected && timeout_cycles < 850000) begin
                @(negedge sys_clk); timeout_cycles=timeout_cycles+1;
            end
            if (dut.display_state !== expected) $fatal(1, "frame commit timeout");
            @(negedge sys_clk); key_in=1'b1;
            repeat (24) @(negedge sys_clk);
        end
    endtask
    initial begin
        $dumpfile("build/lab4_top.vcd");
        $dumpvars(0, sys_clk, sys_rst_n, key_in, dut.click,
                     dut.ctrl_state, dut.display_state, dut.ctrl_rst_n);
        #3 sys_rst_n=1'b0;
        #30 sys_rst_n=1'b1;
        repeat (24) @(negedge sys_clk);
        click_and_wait(`SCREEN_MUST);
        click_and_wait(`SCREEN_END);
        click_and_wait(`SCREEN_BAR);
        if (clicks != 3) $fatal(1, "three physical presses did not yield 3 clicks");
        @(negedge sys_clk); key_in=1'b0;
        repeat (24) @(negedge sys_clk);
        #3 sys_rst_n=1'b0;
        #1;
        if (dut.ctrl_state !== `SCREEN_BAR || dut.display_state !== `SCREEN_BAR)
            $fatal(1, "async top reset failed");
        steps_before_reset_hold = pixel_steps;
        repeat (1600) @(negedge sys_clk);
        if (pixel_steps - steps_before_reset_hold != 800)
            $fatal(1, "raster stopped during user reset");
        sys_rst_n=1'b1;
        repeat (24) @(negedge sys_clk);
        if (dut.ctrl_state !== `SCREEN_BAR) $fatal(1, "held key retriggered after reset");
        wait (completed_frames >= 3);
        $display("PASS tb_lab4_top: cycle/frame commit/raster/reset");
        $finish;
    end
    initial begin
        #100000000;
        $fatal(1, "top simulation timeout");
    end
endmodule
