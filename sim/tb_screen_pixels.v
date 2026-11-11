`timescale 1ns/1ps
`include "lab4_defs.vh"

module tb_screen_pixels;
    reg [9:0] pix_x;
    reg [9:0] pix_y;
    reg [1:0] display_state;
    wire [15:0] pix_data;
    screen_pixels dut (.*);
    task probe;
        input [1:0] screen;
        input [9:0] x;
        input [9:0] y;
        input [15:0] expected;
        begin
            display_state=screen; pix_x=x; pix_y=y; #1;
            if (pix_data !== expected)
                $fatal(1, "pixel state=%0d x=%0d y=%0d expected=%h got=%h",
                       screen, x, y, expected, pix_data);
        end
    endtask
    initial begin
        $dumpfile("build/screen_pixels.vcd"); $dumpvars(0, tb_screen_pixels);
        probe(`SCREEN_BAR, 10'd0,   10'd0,   16'hFFFF);
        probe(`SCREEN_BAR, 10'd79,  10'd479, 16'hFFFF);
        probe(`SCREEN_BAR, 10'd80,  10'd0,   16'hFFE0);
        probe(`SCREEN_BAR, 10'd160, 10'd0,   16'h07FF);
        probe(`SCREEN_BAR, 10'd240, 10'd0,   16'h07E0);
        probe(`SCREEN_BAR, 10'd320, 10'd0,   16'hF81F);
        probe(`SCREEN_BAR, 10'd400, 10'd0,   16'hF800);
        probe(`SCREEN_BAR, 10'd480, 10'd0,   16'h001F);
        probe(`SCREEN_BAR, 10'd639, 10'd479, 16'h0000);
        probe(`SCREEN_MUST,10'd144, 10'd208, 16'hFFFF);
        probe(`SCREEN_MUST,10'd160, 10'd208, 16'h0000);
        probe(`SCREEN_MUST,10'd208, 10'd208, 16'h0000);
        probe(`SCREEN_MUST,10'd495, 10'd208, 16'hFFFF);
        probe(`SCREEN_END, 10'd192, 10'd208, 16'hFFFF);
        probe(`SCREEN_END, 10'd208, 10'd216, 16'h0000);
        probe(`SCREEN_END, 10'd288, 10'd208, 16'hFFFF);
        probe(`SCREEN_END, 10'd384, 10'd208, 16'hFFFF);
        probe(`SCREEN_END, 10'd440, 10'd208, 16'h0000);
        probe(`SCREEN_END, 10'd192, 10'd272, 16'h0000);
        probe(`SCREEN_BAR, 10'd640, 10'd0,   16'h0000);
        $display("PASS tb_screen_pixels: bars/glyph bits/gaps/boundaries");
        $finish;
    end
endmodule
